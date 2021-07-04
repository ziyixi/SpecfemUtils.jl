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

struct CmdArgs
    nproc_mesh::Integer
    mesh_dir::String
    model_dir::String
    model_tags::Vector{String}
    output_file::String
    lon1::AbstractFloat
    lon2::AbstractFloat
    lat1::AbstractFloat
    lat2::AbstractFloat
    dep1::AbstractFloat
    dep2::AbstractFloat
    lonnpts::Integer
    latnpts::Integer
    vnpts::Integer
    lonnproc::Integer
    latnproc::Integer
    ANGULAR_WIDTH_XI_IN_DEGREES_VAL::AbstractFloat
    ANGULAR_WIDTH_ETA_IN_DEGREES_VAL::AbstractFloat
    NEX_XI_VAL::Integer
    NEX_ETA_VAL::Integer
    flag_ellipticity::Bool
    progress::Bool

    CmdArgs(parsed_dict::Dict) = begin
        nproc_mesh = parsed_dict["nproc_mesh"]
        mesh_dir = parsed_dict["mesh_dir"]
        model_dir = parsed_dict["model_dir"]
        model_tags = split(parsed_dict["model_tags"], ",")
        output_file = parsed_dict["output_file"]
        lon1, lon2, lat1, lat2, dep1, dep2 =
            [parse(Float32, i) for i in split(parsed_dict["region"], "/")]
        lonnpts, latnpts, vnpts =
            [parse(Int32, i) for i in split(parsed_dict["npts"], "/")]
        lonnproc, latnproc =
            [parse(Int32, i) for i in split(parsed_dict["process"], "/")]
        mesh_info_list = split(parsed_dict["mesh_info"], "/")
        ANGULAR_WIDTH_XI_IN_DEGREES_VAL, ANGULAR_WIDTH_ETA_IN_DEGREES_VAL =
            [parse(Float32, i) for i in mesh_info_list[1:2]]
        NEX_XI_VAL, NEX_ETA_VAL = [parse(Int32, i) for i in mesh_info_list[3:end]]
        flag_ellipticity = parsed_dict["flag_ellipticity"]
        progress = parsed_dict["progress"]
        new(
            nproc_mesh,
            mesh_dir,
            model_dir,
            model_tags,
            output_file,
            lon1,
            lon2,
            lat1,
            lat2,
            dep1,
            dep2,
            lonnpts,
            latnpts,
            vnpts,
            lonnproc,
            latnproc,
            ANGULAR_WIDTH_XI_IN_DEGREES_VAL,
            ANGULAR_WIDTH_ETA_IN_DEGREES_VAL,
            NEX_XI_VAL,
            NEX_ETA_VAL,
            flag_ellipticity,
            progress,
        )
    end

    CmdArgs() = new()
end


const specfem_ellip =
    Geodesy.Ellipsoid(a = "6378137.0", f_inv = "299.8", name = :specfem_ellip)
struct WGS_SPECFEM <: Geodesy.Datum end
Geodesy.ellipsoid(::Union{WGS_SPECFEM,Type{WGS_SPECFEM}}) = specfem_ellip
const wgs_specfem = WGS_SPECFEM()
