using FortranFiles

function sem_mesh_read(basedir::String, iproc::Integer)::Sem_mesh_data
    f = sem_io_open_file_for_read(basedir, iproc, "solver_data") 
    nspec, nglob = read(f, Int32, Int32)

    mesh_data = Sem_mesh_data(nspec, nglob)
    read(f, mesh_data.xyz_glob[1,:])
    read(f, mesh_data.xyz_glob[2,:])
    read(f, mesh_data.xyz_glob[3,:])
    read(f, mesh_data.ibool)
    read(f, mesh_data.idoubling)
    read(f, mesh_data.ispec_is_tiso)

    close(f)

    # separate crustal mesh layers for REGIONAL_MOHO_MESH 
    # 3-layer crust: 10(third layer), 11, 12(shallowest layer)
    if REGIONAL_MOHO_MESH
        num = 0
        for ispec = 1:nspec
            if mesh_data.idoubling[ispec] == IFLAG_CRUST
                id = num - fld(num, 3) * 3
                mesh_data.idoubling[ispec] = 10 * IFLAG_CRUST + id
                num = num + 1
            end
        end
    end

    # separate mesh layers across 410-km
    # 40: above 410, 41: below 410
    for ispec = 1:nspec
        if mesh_data.idoubling[ispec] == IFLAG_670_220
            iglob = mesh_data.ibool[MIDX, MIDY, MIDZ, ispec]
            # element center coordinate
            xyz_center = mesh_data.xyz_glob[:,iglob]
            depth = (1.0f0 - sqrt(sum(mesh_data.xyz_glob[:,iglob].^2))) * R_EARTH_KM
            # this is dangerous due to 410 undulation
            # depth < 410 ? mesh_data.idoubling(ispec) = 10 * IFLAG_670_220 : mesh_data.idoubling(ispec) = 10 * IFLAG_670_220 + 1
            if depth < 410
                mesh_data.idoubling[ispec] = 10 * IFLAG_670_220
            else
                mesh_data.idoubling[ispec] = 10 * IFLAG_670_220 + 1
            end
        end
    end
    return mesh_data
end

function sem_io_open_file_for_read(basedir::String, iproc::Integer, tag::String)::FortranFile
    filename = "$(basedir)/proc$(lpad(string(iproc), 6, '0'))_reg1_$(tag).bin"
    f = FortranFile(filename)
    return f
end

function sem_io_open_file_for_write(basedir::String, iproc::Integer, tag::String)::FortranFile
    filename = "$(basedir)/proc$(lpad(string(iproc), 6, '0'))_reg1_$(tag).bin"
    f = FortranFile(filename, "w")
    return f
end

function sem_io_read_gll_file_1!(basedir::String, iproc::Integer, model_name::String, model_gll::AbstractArray{Float32,4})
    f = sem_io_open_file_for_read(basedir, iproc, model_name)
    read(f, model_gll)
    close(f)
    return nothing
end

function sem_io_read_gll_file_n!(basedir::String, iproc::Integer, model_names::Vector{String}, nmodel::Integer, model_gll::AbstractArray{Float32,5})
    for imodel = 1:nmodel
        sem_io_read_gll_file_1!(basedir, iproc, model_names[imodel], @view(model_gll[imodel,:,:,:,:]))
    end
    return nothing
end

function sem_io_write_gll_file_1(basedir::String, iproc::Integer, model_name::String, model_gll::AbstractArray{Float32,4})
    f = sem_io_open_file_for_write(basedir, iproc, model_name)
    write(f, model_gll)
    close(f)
    return nothing
end

function sem_io_write_gll_file_n(basedir::String, iproc::Integer, model_names::Vector{String}, nmodel::Integer, model_gll::AbstractArray{Float32,5})
    for imodel = 1:nmodel
        sem_io_write_gll_file_1(basedir, iproc, model_names[imodel], model_gll[imodel,:,:,:,:])
    end
    return nothing
end