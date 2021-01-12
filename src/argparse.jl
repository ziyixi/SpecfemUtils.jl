using ArgParse

function parse_commandline()::CmdArgs
    s = ArgParseSettings(prog="SpecfemMeshInterpreter", description="""Interpolate the mesh files of Specfem3D Globe and generate the evenly spaced Netcdf file.""")
    @add_arg_table! s begin
        """--nproc_mesh"""
        help = "number of slices of the mesh"
        arg_type = Int
        required = true
        """--mesh_dir"""
        help = "directory holds proc*_reg1_solver_data.bin"
        arg_type = String
        required = true
        """--model_dir"""
        help = "directory holds proc*_reg1_<model_tag>.bin"
        arg_type = String
        required = true
        """--model_tags"""
        help = "comma delimited string, e.g. vsv,vsh,rho"
        arg_type = String
        required = true
        """--output_file"""
        help = "output netcdf file path"
        arg_type = String
        required = true
        """--region"""
        help = "lon1/lon2/lat1/lat2/dep1/dep2, where lon1<lon2, lat1<lat2 and dep1<dep2, define the boundary of the mesh"
        arg_type = String
        required = true
        """--npts"""
        help = "lonnpts/latnpts/vnpts, define the number of interpolation points at each axis"
        arg_type = String
        required = true
        """--process"""
        help = "lonnproc/latnproc for process numbers used in each axis"
        arg_type = String
        required = true
        """--mesh_info"""
        help = "ANGULAR_WIDTH_XI_IN_DEGREES_VAL/ANGULAR_WIDTH_ETA_IN_DEGREES_VAL/NEX_XI_VAL/NEX_ETA_VAL, info from DATA/Par_file"
        arg_type = String
        required = true
        """--flag_ellipticity"""
        help = "if the mesh is ellipticity"
        action = :store_true
        """--progress"""
        help = "if show the progress bar"
        action = :store_true
    end
    parsed_dict = parse_args(s)
    return CmdArgs(parsed_dict)
end