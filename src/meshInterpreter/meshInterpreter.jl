module MeshInterpreter
using MPI

include("./constants.jl")
include("./types.jl")
include("./argparse.jl")
include("../shared/readfiles.jl")
include("./utils.jl")
include("../shared/kdtree.jl")
include("./interp.jl")

"""
    main()

The main entry of the script. Use the command line arguments as the input.
"""
function main()
    MPI.Init()
    comm = MPI.COMM_WORLD
    command_args = parse_commandline()
    run_interp(comm, command_args)

    MPI.Barrier(comm)
    MPI.Finalize()
end

export main

end # module