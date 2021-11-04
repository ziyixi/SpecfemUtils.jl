#!/usr/bin/env julia
@show get(ENV, "JULIA_PROJECT", nothing)
@show get(ENV, "JULIA_LOAD_PATH", nothing)
using SpecfemUtils
println("your other scripts should work! ")