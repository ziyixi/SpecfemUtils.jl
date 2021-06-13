using MPI
using NCDatasets

function main()
    MPI.Init()

    comm = MPI.COMM_WORLD 
    command_args = parse_commandline()   
    run_interp(comm,command_args)
    
    MPI.Barrier(comm)
    MPI.Finalize()
end

function array_split_mpi(input_array::AbstractArray{T}, num_split::Integer, rank::Integer)::AbstractArray{T} where T <: Integer
    div_result = div(length(input_array), num_split)
    mod_result = mod(length(input_array), num_split)
    startindex = 0
    endindex = 0
    if rank <= mod_result
        startindex = (div_result + 1) * (rank - 1) + 1
        endindex = startindex + div_result
    else 
        startindex = (div_result + 1) * mod_result + div_result * (rank - mod_result - 1) + 1
        endindex = startindex + div_result - 1
    end
    return input_array[startindex:endindex]
end

function get_coor(rank::Integer,command_args::CmdArgs)
    rank_lat = rank % command_args.latnproc + 1
    rank_lon = div(rank , command_args.latnproc)+1
    coor_lat = array_split_mpi(1:command_args.latnpts, command_args.latnproc, rank_lat)
    coor_lon = array_split_mpi(1:command_args.lonnpts, command_args.lonnproc, rank_lon)
    return coor_lat,coor_lon
end


function generate_profile_points(rank::Integer, command_args::CmdArgs)
    # get ranges for the three directions
    coor_lat,coor_lon=get_coor(rank,command_args)

    # * init rθϕ_new
    ngll_new_this_rank = length(coor_lat) * length(coor_lon) * command_args.vnpts

    xyz_new = zeros(Float32, 3, ngll_new_this_rank)
    # * fill in deplatlon_new of this rank
    latnpts_this_rank = length(coor_lat)
    lonnpts_this_rank = length(coor_lon)
    for (vindex, dep) in enumerate(range(command_args.dep1, stop=command_args.dep2, length=command_args.vnpts))
        for (latindex, lat) in enumerate(range(command_args.lat1, stop=command_args.lat2, length=command_args.latnpts)[coor_lat])
            for (lonindex, lon) in enumerate(range(command_args.lon1, stop=command_args.lon2, length=command_args.lonnpts)[coor_lon])
                id = (vindex - 1) * latnpts_this_rank * lonnpts_this_rank + (latindex - 1) * lonnpts_this_rank + lonindex
                if command_args.flag_ellipticity
                    xyz_new[:,id] = latlondep2xyz(lat, lon, dep)
                else
                    xyz_new[:,id] = latlondep2xyz_sphere(lat, lon, dep)
                end
            end
        end
    end
    return xyz_new
end


function write_to_netcdf(model_interp::Array{Float32,4},command_args::CmdArgs)
    ds = Dataset(command_args.output_file,"c")
    defDim(ds,"lon",command_args.lonnpts)
    defDim(ds,"lat",command_args.latnpts)
    defDim(ds,"dep",command_args.vnpts)

    lon=collect(range(command_args.lon1, stop=command_args.lon2, length=command_args.lonnpts))
    lat=collect(range(command_args.lat1, stop=command_args.lat2, length=command_args.latnpts))
    dep=collect(range(command_args.dep1, stop=command_args.dep2, length=command_args.vnpts))
    lonatts = Dict("longname" => "Longitude", "units" => "degrees east")
    latatts = Dict("longname" => "Latitude", "units" => "degrees north")
    depatts = Dict("longname" => "Depth", "units" => "km")
    v=defVar(ds,"lon",Float32,("lon",),attrib=lonatts)
    v[:]=lon
    v=defVar(ds,"lat",Float32,("lat",),attrib=latatts)
    v[:]=lat
    v=defVar(ds,"dep",Float32,("dep",),attrib=depatts)
    v[:]=dep

    model_interp_reverse_axis=permutedims(model_interp,[3,2,1,4])
    for (index,each_tag) in enumerate(command_args.model_tags)
        # julia has the reversed axis for netcdf
        v = defVar(ds,each_tag,Float32,("dep","lat","lon"),fillvalue = 9999999.f0)
        v[:,:,:]=model_interp_reverse_axis[:,:,:,index]
    end

    close(ds)
    
end


function run_interp(comm::MPI.Comm,command_args::CmdArgs)
    rank = MPI.Comm_rank(comm)
    nrank = MPI.Comm_size(comm)
    root = 0
    isroot = rank == root    

    # * interpolate old mesh/model onto new mesh
    # typical element size at surface for old mesh
    typical_size = deg2rad(max(command_args.ANGULAR_WIDTH_XI_IN_DEGREES_VAL / command_args.NEX_XI_VAL, command_args.ANGULAR_WIDTH_ETA_IN_DEGREES_VAL / command_args.NEX_ETA_VAL)) * R_UNIT_SPHERE
    max_search_dist = 10.0f0 * typical_size
    max_misloc = typical_size / 4.0f0

    # get xyz_new
    xyz_new = generate_profile_points(rank,command_args)
    ngll_new_this_rank = size(xyz_new)[2]

    # * initialize variables for interpolation
    location_1slice = Array{Sem_mesh_location}(undef, ngll_new_this_rank)
    stat_final = zeros(Int32, ngll_new_this_rank)
    misloc_final = zeros(Float32, ngll_new_this_rank)

    stat_final .= -1
    misloc_final .= 9999.f0

    nmodel = length(command_args.model_tags)

    # for mpi gather in the future
    max_ngll_new_this_rank=MPI.Allreduce(ngll_new_this_rank,max, comm)
    model_interp_this_rank_tosend=zeros(Float32,nmodel, max_ngll_new_this_rank)
    model_interp_this_rank=@view(model_interp_this_rank_tosend[:,1:ngll_new_this_rank])
    model_interp_this_rank .= 9999999.f0

    # * for progress
    if command_args.progress
        iproc_finished=[0]
        win_iproc_finished = MPI.Win_create(iproc_finished, comm)
        MPI.Win_fence(0, win_iproc_finished)
    end


    # * loop for all points in xyz_new
    for iproc_old = 0:command_args.nproc_mesh - 1
        mesh_old = sem_mesh_read(command_args.mesh_dir, iproc_old)
        nspec_old = mesh_old.nspec
        min_dist = Inf32

        # test if the new and old mesh slices are separated apart
        for ispec = 1:nspec_old
            iglob = mesh_old.ibool[MIDX,MIDY,MIDZ,ispec]
            old_x = mesh_old.xyz_glob[1,iglob]
            old_y = mesh_old.xyz_glob[2,iglob]     
            old_z = mesh_old.xyz_glob[3,iglob]
            dist_this_spec = sqrt(minimum(@. (xyz_new[1,:] - old_x)^2 + (xyz_new[2,:] - old_y)^2 + (xyz_new[3,:] - old_z)^2))
            min_dist = min(min_dist, dist_this_spec)
        end
        if min_dist > max_search_dist
            if command_args.progress
                MPI.Win_lock(MPI.LOCK_EXCLUSIVE, rank, 0, win_iproc_finished)
                iproc_finished[1]+=1
                MPI.Win_unlock(rank,win_iproc_finished)
            end
            continue
        end

        # * main computation part
        # read old model
        model_gll_old = zeros(Float32, nmodel, NGLLX, NGLLY, NGLLZ, nspec_old)
        sem_io_read_gll_file_n!(command_args.model_dir, iproc_old, command_args.model_tags, nmodel, model_gll_old)

        # locate points in this mesh slice
        nnearest = 10
        location_1slice=sem_mesh_locate_kdtree2(mesh_old,ngll_new_this_rank,xyz_new,nnearest,max_search_dist,max_misloc)

        for igll = 1:ngll_new_this_rank
            if (stat_final[igll] == 1 && location_1slice[igll].stat == 1)
                # multi-located
                continue
            end
            # for point located inside one element in the first time or closer to one element than located before
            if location_1slice[igll].stat == 1 || (location_1slice[igll].stat == 0 && location_1slice[igll].misloc < misloc_final[igll])
                for imodel = 1:nmodel
                    model_interp_this_rank[imodel,igll] = sum(location_1slice[igll].lagrange .* model_gll_old[imodel,:,:,:,location_1slice[igll].eid])
                end
                stat_final[igll] = location_1slice[igll].stat
                misloc_final[igll] = location_1slice[igll].misloc
            end
        end
        # * for progress
        if command_args.progress
            MPI.Win_lock(MPI.LOCK_EXCLUSIVE, rank, 0, win_iproc_finished)
            iproc_finished[1]+=1
            MPI.Win_unlock(rank,win_iproc_finished)
            all_iproc_finished=iproc_finished[1]
            # get iproc_finished from other processes, update all_iproc_finished
            for each_rank in 0:(nrank-1)
                if each_rank!=rank
                    MPI.Win_lock(MPI.LOCK_EXCLUSIVE, each_rank, 0, win_iproc_finished)
                    received=similar(iproc_finished)
                    MPI.Get(received, each_rank, win_iproc_finished)
                    MPI.Win_unlock(each_rank,win_iproc_finished)
                    all_iproc_finished+=received[1]
                end
            end
            @info "[current rank: $(rank)] finished $(all_iproc_finished)/$(nrank*command_args.nproc_mesh)"
        end

    end
    MPI.Barrier(comm)
    if command_args.progress
        MPI.free(win_iproc_finished)
    end

    # * combine model_interp_this_rank_tosend
    all_model_interp_this_rank_tosend = MPI.Gather(model_interp_this_rank_tosend, root, comm)
    all_ngll_new_this_rank=MPI.Gather(ngll_new_this_rank, root, comm)
    # * combine all_model_interp_this_rank_tosend into a single model_interp array
    # * model_interp should be a 3D array here, as we will convert model_interp_this_rank to a 2D array
    if isroot
        # reshape to (nmodel,max_ngll_new_this_rank*nrank)
        all_model_interp_this_rank_tosend_2D=reshape(all_model_interp_this_rank_tosend,nmodel,div(length(all_model_interp_this_rank_tosend) , nmodel))
        model_interp=zeros(Float32,command_args.lonnpts,command_args.latnpts,command_args.vnpts,nmodel)
        for each_rank in 0:(length(all_ngll_new_this_rank)-1)
            each_index=each_rank+1
            each_coor_lat,each_coor_lon=get_coor(each_rank,command_args)
            # get the view of this rank
            each_model_interp=@view(model_interp[each_coor_lon,each_coor_lat,:,:]) 
            each_model_interp_this_rank_tosend=@view(all_model_interp_this_rank_tosend_2D[:,(each_rank*max_ngll_new_this_rank+1):(each_rank+1)*max_ngll_new_this_rank])
            id=1
            for vindex in 1:command_args.vnpts
                for latindex in 1:length(each_coor_lat)
                    for lonindex in 1:length(each_coor_lon)
                        each_model_interp[lonindex,latindex,vindex,:]=each_model_interp_this_rank_tosend[:,id]
                        id+=1
                    end
                end
            end
        end
        # * write model_interp to a netcdf file
        write_to_netcdf(model_interp,command_args)
    end
end