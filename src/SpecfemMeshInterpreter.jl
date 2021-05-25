module SpecfemMeshInterpreter
include("./constants.jl")
include("./types.jl")
include("./argparse.jl")
include("./readfiles.jl")
include("./utils.jl")
include("./kdtree.jl")
include("./interp.jl")

function julia_main()
    try
        main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

export main,julia_main

end # module