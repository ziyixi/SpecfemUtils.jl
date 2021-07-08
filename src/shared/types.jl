import Geodesy

mutable struct Sem_mesh_data
    nspec::Integer
    nglob::Integer
    xyz_glob::Array{Float32,2}
    ibool::Array{Int32,4}
    idoubling::Array{Int32,1}
    ispec_is_tiso::Array{Bool,1}

    Sem_mesh_data(nspec::Integer, nglob::Integer) = new(
        nspec,
        nglob,
        zeros(Float32, 3, nglob),
        zeros(Int32, NGLLX, NGLLY, NGLLZ, nspec),
        zeros(Int32, nspec),
        zeros(Bool, nspec),
    )
end

mutable struct Sem_mesh_location
    stat::Integer
    eid::Integer

    uvw::Vector{Float32}
    misloc::AbstractFloat
    lagrange::Array{Float32,3}

    Sem_mesh_location() =
        new(-1, -1, zeros(Float32, 3), Inf32, zeros(Float32, NGLLX, NGLLY, NGLLZ))
end

