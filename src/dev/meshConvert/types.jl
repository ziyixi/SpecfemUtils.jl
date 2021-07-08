struct CmdArgs
    nproc_old::Integer
    old_mesh_dir::String
    old_model_dir::String
    nproc_new::Integer
    new_mesh_dir::String
    new_model_dir::String
    model_tags::Vector{String}
    output_dir::String
    ANGULAR_WIDTH_XI_IN_DEGREES_VAL::AbstractFloat
    ANGULAR_WIDTH_ETA_IN_DEGREES_VAL::AbstractFloat
    NEX_XI_VAL::Integer
    NEX_ETA_VAL::Integer

    CmdArgs(parsed_dict::Dict) = begin
        nproc_old = parsed_dict["nproc_old"]
        old_mesh_dir = parsed_dict["old_mesh_dir"]
        old_model_dir = parsed_dict["old_model_dir"]
        nproc_new = parsed_dict["nproc_new"]
        new_mesh_dir = parsed_dict["new_mesh_dir"]
        new_model_dir = parsed_dict["new_model_dir"]
        model_tags = split(parsed_dict["model_tags"], ",")
        output_dir = parsed_dict["output_dir"]

        mesh_info_list = split(parsed_dict["mesh_info"], "/")
        ANGULAR_WIDTH_XI_IN_DEGREES_VAL, ANGULAR_WIDTH_ETA_IN_DEGREES_VAL =
            [parse(Float32, i) for i in mesh_info_list[1:2]]
        NEX_XI_VAL, NEX_ETA_VAL = [parse(Int32, i) for i in mesh_info_list[3:end]]

        new(
            nproc_old,
            old_mesh_dir,
            old_model_dir,
            nproc_new,
            new_mesh_dir,
            new_model_dir,
            model_tags,
            output_dir,
            ANGULAR_WIDTH_XI_IN_DEGREES_VAL,
            ANGULAR_WIDTH_ETA_IN_DEGREES_VAL,
            NEX_XI_VAL,
            NEX_ETA_VAL,
        )
    end

    CmdArgs() = new()
end
