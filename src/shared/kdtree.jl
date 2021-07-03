using NearestNeighbors
using FastGaussQuadrature

function sem_mesh_locate_kdtree2(mesh_data::Sem_mesh_data, npoint::Integer, xyz::Array{Float32,2},  nnearest::Integer, max_search_dist::AbstractFloat, max_misloc::AbstractFloat)::Vector{Sem_mesh_location}
    # * init result
    location_result = Vector{Sem_mesh_location}(undef, npoint)
    for i in 1:npoint
        location_result[i] = Sem_mesh_location()
    end
    hlagx = zeros(Float32, NGLLX)
    hlagy = zeros(Float32, NGLLY)
    hlagz = zeros(Float32, NGLLZ)

    xigll = Float32.(gausslobatto(5)[1])
    yigll = xigll
    zigll = xigll

    # get index of anchor points in the GLL element
    iax, iay, iaz = anchor_point_index()

    # get anchor and center points of each GLL element 
    nspec = mesh_data.nspec
    xyz_elem = zeros(Float32, 3, nspec)
    xyz_anchor = zeros(Float32, 3, NGNOD, nspec)

    for ispec = 1:nspec
        for ia = 1:NGNOD
            iglob = mesh_data.ibool[iax[ia], iay[ia], iaz[ia], ispec]
            xyz_anchor[:,ia,ispec] = mesh_data.xyz_glob[:,iglob]
        end
        # the last anchor point is the element center
        xyz_elem[:,ispec] = xyz_anchor[:,NGNOD,ispec]
    end

    # * build kdtree
    kdtree = KDTree(xyz_elem)
    # * locate each point

    # loop points
    for ipoint = 1:npoint
        xyz1 = xyz[:,ipoint]
        # * get the n nearest elements in the mesh
        idxs, _ = knn(kdtree, xyz1, nnearest)

        # * test each neighbour elements to see if target point is located inside
        for inn = 1:nnearest
            ispec = idxs[inn]
            # skip the element a certain distance away
            dist = sqrt(sum((xyz_elem[:,ispec] .- xyz1).^2))
            if dist > max_search_dist
                continue
            end
            # locate point to this element
            uvw1, misloc1, flag_inside = xyz2cube_bounded(xyz_anchor[:,:,ispec], xyz1)
            if flag_inside == true
                location_result[ipoint].stat = 1
                location_result[ipoint].eid = ispec
                location_result[ipoint].misloc = misloc1
                location_result[ipoint].uvw = uvw1
                break
            else
                if (misloc1 < max_misloc) && (misloc1 < location_result[ipoint].misloc)
                    location_result[ipoint].stat = 0
                    location_result[ipoint].eid = ispec
                    location_result[ipoint].misloc = misloc1
                    location_result[ipoint].uvw = uvw1
                end
            end
        end

        # * set interpolation weights on GLL points if located
        if location_result[ipoint].stat != -1
            lagrangeCoefficient!(location_result[ipoint].uvw[1], xigll, hlagx)
            lagrangeCoefficient!(location_result[ipoint].uvw[2], yigll, hlagy)
            lagrangeCoefficient!(location_result[ipoint].uvw[3], zigll, hlagz)

            for igllz = 1:NGLLZ
                for iglly = 1:NGLLY
                    for igllx = 1:NGLLX
                        location_result[ipoint].lagrange[igllx,iglly,igllz] = hlagx[igllx] * hlagy[iglly] * hlagz[igllz]
                    end
                end
            end
        end
    end
    return location_result
end