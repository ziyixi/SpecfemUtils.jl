# symlink scripts so we can call via ~/.specfem/debugScript.jl
println("running SpecfemUtils/build.jl")
scriptsdir = normpath(joinpath(@__DIR__, "..", "scripts"))
targetdir = expanduser("~/.specfem")
if !isdir(targetdir)
    println("creating $targetdir")
    mkdir(targetdir)
end
@show scriptsdir
@show targetdir
for n in readdir(scriptsdir)
    p = joinpath(scriptsdir, n)
    t_jl = joinpath(targetdir, n)
    # remove the ".jl" tag 
    t = join(split(t_jl, ".")[1:end - 1], ".")
    if isfile(p)
        s = "adding $p $t"
        if isfile(t)
            s *= " (overwriting)"
            @show t
            rm(t)
        end
        println(s)
        open(t, "w") do f
            write(f, raw"#!/usr/bin/env bash")
            write(f, "\n")
            write(f, "/usr/bin/env bash \"$p\" \$@")
        end
        chmod(t, 0o755) # all can rx, user can rwx
    end
end