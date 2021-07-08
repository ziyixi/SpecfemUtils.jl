using ArgParse

function parse_commandline()::CmdArgs
    s = ArgParseSettings(
        prog = "MeshConvert",
        description = """Convert one mesh to another for the same model.""",
    )
    @add_arg_table! s begin
        "--nproc_old"
        help = "number of slices of the old mesh"
        arg_type = Int
        required = true
        "--old_mesh_dir"
        help = "directory holds proc*_reg1_solver_data.bin"
        arg_type = String
        required = true
        "--old_model_dir"
        help = "directory holds proc*_reg1_<model_tag>.bin"
        arg_type = String
        required = true
        "--nproc_new"
        help = "number of slices of the new mesh"
        arg_type = Int
        required = true
        "--new_mesh_dir"
        help = "directory holds proc*_reg1_solver_data.bin"
        arg_type = String
        required = true
        "--new_model_dir"
        help = "directory for new model files as background model"
        arg_type = String
        required = true
        "--model_tags"
        help = "comma delimited string, e.g. vsv,vsh,rho"
        arg_type = String
        required = true
        "--output_dir"
        help = "output directory for interpolated model files"
        arg_type = String
        required = true
        """--mesh_info"""
        help = "ANGULAR_WIDTH_XI_IN_DEGREES_VAL/ANGULAR_WIDTH_ETA_IN_DEGREES_VAL/NEX_XI_VAL/NEX_ETA_VAL, info from DATA/Par_file"
        arg_type = String
        required = true
    end
    parsed_dict = parse_args(s)
    return CmdArgs(parsed_dict)
end
