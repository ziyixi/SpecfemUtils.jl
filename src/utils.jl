using LinearAlgebra
import Geodesy

function lagrangeCoefficient!(x::AbstractFloat, xigll::Vector{Float32}, hlagx::Vector{Float32})
    hlagx .= 1.f0
    for j in 1:length(xigll)
        for i in 1:length(xigll)
            if i != j
                hlagx[j] *= (x - xigll[i]) / (xigll[j] - xigll[i])
            end
        end
    end
    return nothing
end


function hex_nodes()::Tuple{Array{Int32,1},Array{Int32,1},Array{Int32,1}}
    iaddx = zeros(Int32, NGNOD)
    iaddy = zeros(Int32, NGNOD)
    iaddz = zeros(Int32, NGNOD)

    # corner nodes
    iaddx[1] = 0; iaddy[1] = 0; iaddz[1] = 0
    iaddx[2] = 2; iaddy[2] = 0; iaddz[2] = 0
    iaddx[3] = 2; iaddy[3] = 2; iaddz[3] = 0
    iaddx[4] = 0; iaddy[4] = 2; iaddz[4] = 0
    iaddx[5] = 0; iaddy[5] = 0; iaddz[5] = 2
    iaddx[6] = 2; iaddy[6] = 0; iaddz[6] = 2
    iaddx[7] = 2; iaddy[7] = 2; iaddz[7] = 2
    iaddx[8] = 0; iaddy[8] = 2; iaddz[8] = 2

    # midside nodes (nodes located in the middle of an edge)
    iaddx[9] = 1; iaddy[9] = 0; iaddz[9] = 0
    iaddx[10] = 2; iaddy[10] = 1; iaddz[10] = 0
    iaddx[11] = 1; iaddy[11] = 2; iaddz[11] = 0
    iaddx[12] = 0; iaddy[12] = 1; iaddz[12] = 0
    iaddx[13] = 0; iaddy[13] = 0; iaddz[13] = 1
    iaddx[14] = 2; iaddy[14] = 0; iaddz[14] = 1
    iaddx[15] = 2; iaddy[15] = 2; iaddz[15] = 1
    iaddx[16] = 0; iaddy[16] = 2; iaddz[16] = 1
    iaddx[17] = 1; iaddy[17] = 0; iaddz[17] = 2
    iaddx[18] = 2; iaddy[18] = 1; iaddz[18] = 2
    iaddx[19] = 1; iaddy[19] = 2; iaddz[19] = 2
    iaddx[20] = 0; iaddy[20] = 1; iaddz[20] = 2

    # side center nodes (nodes located in the middle of a face)
    iaddx[21] = 1; iaddy[21] = 1; iaddz[21] = 0
    iaddx[22] = 1; iaddy[22] = 0; iaddz[22] = 1
    iaddx[23] = 2; iaddy[23] = 1; iaddz[23] = 1
    iaddx[24] = 1; iaddy[24] = 2; iaddz[24] = 1
    iaddx[25] = 0; iaddy[25] = 1; iaddz[25] = 1
    iaddx[26] = 1; iaddy[26] = 1; iaddz[26] = 2

    # center node (barycenter of the eight corners)
    iaddx[27] = 1; iaddy[27] = 1; iaddz[27] = 1
    return iaddx, iaddy, iaddz
end


function anchor_point_index()::Tuple{Array{Int32,1},Array{Int32,1},Array{Int32,1}}
    iaddx, iaddy, iaddz = hex_nodes()
    for index in 1:NGNOD
        if iaddx[index] == 0
            iaddx[index] = 1
        elseif iaddx[index] == 1
            iaddx[index] = (NGLLX + 1) / 2
        elseif iaddx[index] == 2
            iaddx[index] = NGLLX
        else
            @error "incorrect value of iaddx"
        end

        if iaddy[index] == 0
            iaddy[index] = 1
        elseif iaddy[index] == 1
            iaddy[index] = (NGLLY + 1) / 2
        elseif iaddy[index] == 2
            iaddy[index] = NGLLY
        else
            @error "incorrect value of iaddy"
        end

        if iaddz[index] == 0
            iaddz[index] = 1
        elseif iaddz[index] == 1
            iaddz[index] = (NGLLZ + 1) / 2
        elseif iaddz[index] == 2
            iaddz[index] = NGLLZ
        else
            @error "incorrect value of iaddz"
        end
    end
    return iaddx, iaddy, iaddz
end


function cube2xyz!(anchor_xyz::Array{Float32,2}, uvw::Array{Float32,1}, xyz::Array{Float32,1}, DuvwDxyz::Array{Float32,2})
    # lagrange polynomials of order 3 on [-1,1], with collocation points: -1,0,1 
    lag1 = @. uvw * (uvw - 1.0f0) / 2.0f0
    lag2 = @. 1.0f0 - uvw^2
    lag3 = @. uvw * (uvw + 1.0f0) / 2.0f0

    # derivative of lagrange polynomials
    lag1p = @. uvw - 0.5f0
    lag2p = @. -2.0f0 * uvw
    lag3p = @. uvw + 0.5f0

    # * construct the shape function
    shape3D = Float32[
       # corner center
       lag1[1] * lag1[2] * lag1[3],
       lag3[1] * lag1[2] * lag1[3],
       lag3[1] * lag3[2] * lag1[3],
       lag1[1] * lag3[2] * lag1[3],
       lag1[1] * lag1[2] * lag3[3],
       lag3[1] * lag1[2] * lag3[3],
       lag3[1] * lag3[2] * lag3[3],
       lag1[1] * lag3[2] * lag3[3],
       # edge center
       lag2[1] * lag1[2] * lag1[3],
       lag3[1] * lag2[2] * lag1[3],
       lag2[1] * lag3[2] * lag1[3],
       lag1[1] * lag2[2] * lag1[3],
       lag1[1] * lag1[2] * lag2[3],
       lag3[1] * lag1[2] * lag2[3],
       lag3[1] * lag3[2] * lag2[3],
       lag1[1] * lag3[2] * lag2[3], 
       lag2[1] * lag1[2] * lag3[3],
       lag3[1] * lag2[2] * lag3[3],
       lag2[1] * lag3[2] * lag3[3],
       lag1[1] * lag2[2] * lag3[3],
       # face center
       lag2[1] * lag2[2] * lag1[3],
       lag2[1] * lag1[2] * lag2[3],
       lag3[1] * lag2[2] * lag2[3],
       lag2[1] * lag3[2] * lag2[3],
       lag1[1] * lag2[2] * lag2[3],
       lag2[1] * lag2[2] * lag3[3],
       # body center
       lag2[1] * lag2[2] * lag2[3] ]

    # * derivative of the shape function
    dershape3D = Float32[
        # corner center
        lag1p[1] * lag1[2] * lag1[3]  lag1[1] * lag1p[2] * lag1[3]  lag1[1] * lag1[2] * lag1p[3]
        lag3p[1] * lag1[2] * lag1[3]  lag3[1] * lag1p[2] * lag1[3]  lag3[1] * lag1[2] * lag1p[3]
        lag3p[1] * lag3[2] * lag1[3]  lag3[1] * lag3p[2] * lag1[3]  lag3[1] * lag3[2] * lag1p[3]
        lag1p[1] * lag3[2] * lag1[3]  lag1[1] * lag3p[2] * lag1[3]  lag1[1] * lag3[2] * lag1p[3]
        lag1p[1] * lag1[2] * lag3[3]  lag1[1] * lag1p[2] * lag3[3]  lag1[1] * lag1[2] * lag3p[3]
        lag3p[1] * lag1[2] * lag3[3]  lag3[1] * lag1p[2] * lag3[3]  lag3[1] * lag1[2] * lag3p[3]
        lag3p[1] * lag3[2] * lag3[3]  lag3[1] * lag3p[2] * lag3[3]  lag3[1] * lag3[2] * lag3p[3]
        lag1p[1] * lag3[2] * lag3[3]  lag1[1] * lag3p[2] * lag3[3]  lag1[1] * lag3[2] * lag3p[3]
        # edge center
        lag2p[1] * lag1[2] * lag1[3]  lag2[1] * lag1p[2] * lag1[3]  lag2[1] * lag1[2] * lag1p[3]
        lag3p[1] * lag2[2] * lag1[3]  lag3[1] * lag2p[2] * lag1[3]  lag3[1] * lag2[2] * lag1p[3]
        lag2p[1] * lag3[2] * lag1[3]  lag2[1] * lag3p[2] * lag1[3]  lag2[1] * lag3[2] * lag1p[3]
        lag1p[1] * lag2[2] * lag1[3]  lag1[1] * lag2p[2] * lag1[3]  lag1[1] * lag2[2] * lag1p[3]
        lag1p[1] * lag1[2] * lag2[3]  lag1[1] * lag1p[2] * lag2[3]  lag1[1] * lag1[2] * lag2p[3]
        lag3p[1] * lag1[2] * lag2[3]  lag3[1] * lag1p[2] * lag2[3]  lag3[1] * lag1[2] * lag2p[3]
        lag3p[1] * lag3[2] * lag2[3]  lag3[1] * lag3p[2] * lag2[3]  lag3[1] * lag3[2] * lag2p[3]
        lag1p[1] * lag3[2] * lag2[3]  lag1[1] * lag3p[2] * lag2[3]  lag1[1] * lag3[2] * lag2p[3]
        lag2p[1] * lag1[2] * lag3[3]  lag2[1] * lag1p[2] * lag3[3]  lag2[1] * lag1[2] * lag3p[3]
        lag3p[1] * lag2[2] * lag3[3]  lag3[1] * lag2p[2] * lag3[3]  lag3[1] * lag2[2] * lag3p[3]
        lag2p[1] * lag3[2] * lag3[3]  lag2[1] * lag3p[2] * lag3[3]  lag2[1] * lag3[2] * lag3p[3]
        lag1p[1] * lag2[2] * lag3[3]  lag1[1] * lag2p[2] * lag3[3]  lag1[1] * lag2[2] * lag3p[3]
        # face center
        lag2p[1] * lag2[2] * lag1[3]  lag2[1] * lag2p[2] * lag1[3]  lag2[1] * lag2[2] * lag1p[3]
        lag2p[1] * lag1[2] * lag2[3]  lag2[1] * lag1p[2] * lag2[3]  lag2[1] * lag1[2] * lag2p[3]
        lag3p[1] * lag2[2] * lag2[3]  lag3[1] * lag2p[2] * lag2[3]  lag3[1] * lag2[2] * lag2p[3]
        lag2p[1] * lag3[2] * lag2[3]  lag2[1] * lag3p[2] * lag2[3]  lag2[1] * lag3[2] * lag2p[3]
        lag1p[1] * lag2[2] * lag2[3]  lag1[1] * lag2p[2] * lag2[3]  lag1[1] * lag2[2] * lag2p[3]
        lag2p[1] * lag2[2] * lag3[3]  lag2[1] * lag2p[2] * lag3[3]  lag2[1] * lag2[2] * lag3p[3]
        # body center
        lag2p[1] * lag2[2] * lag2[3]  lag2[1] * lag2p[2] * lag2[3]  lag2[1] * lag2[2] * lag2p[3]
    ]

    # * xyz and Dxyz/Duvw
    xyz = anchor_xyz * shape3D
    DxyzDuvw = anchor_xyz * dershape3D

    # * jacobian = det(Dxyz/Duvw)
    jacobian = det(DxyzDuvw)

    # * adjoint matrix: adj(Dxyz/Duvw)
    DuvwDxyz = inv(DxyzDuvw)

    if jacobian <= 0.f0
        @error "jacobian smaller than 0" jacobian anchor_xyz uvw
    end
    return nothing
end


function xyz2cube_bounded(xyz_anchor::Array{Float32,2}, xyz::Array{Float32,1})::Tuple{Array{Float32,1},AbstractFloat,Bool}
    niter = 5
    uvw = zeros(Float32, 3)
    xyzi = zeros(Float32, 3)
    DuvwDxyz = zeros(Float32, 3, 3)
    flag_inside = true

    for iter in 1:niter
        cube2xyz!(xyz_anchor, uvw, xyzi, DuvwDxyz)
        dxyz = xyz - xyzi
        duvw = DuvwDxyz * dxyz
        uvw = uvw + duvw
        # limit inside the cube
        if any(uvw .< -1 || uvw .> 1)
            @. uvw[uvw < -1] = -1
            @. uvw[uvw > 1] = 1
            if iter == niter
                flag_inside = false
            end
        end
    end
    # calculate the predicted position 
    cube2xyz!(xyz_anchor, uvw, xyzi, DuvwDxyz)
    # residual distance from the target point
    misloc = sqrt(sum((xyz .- xyzi).^2))

    return uvw, misloc, flag_inside
end

function latlondep2xyz(lat::AbstractFloat, lon::AbstractFloat, dep::AbstractFloat)::Vector{AbstractFloat}
    x_lla = Geodesy.LLA(lat, lon, -dep * 1000)
    x_ecef = Geodesy.ECEF(x_lla, wgs_specfem)
    # normalize using R_EARTH
    x = x_ecef.x / R_EARTH
    y = x_ecef.y / R_EARTH
    z = x_ecef.z / R_EARTH
    return [x,y,z]
end

function latlondep2xyz_sphere(lat::AbstractFloat, lon::AbstractFloat, dep::AbstractFloat)::Vector{AbstractFloat}
    r = (R_EARTH_KM - dep) / R_EARTH_KM
    θ = 90 - lat
    ϕ = lon
    z = r * cosd(θ)
    h = r * sind(θ)
    x = h * cosd(ϕ)
    y = h * sind(ϕ)
    return [x,y,z]
end