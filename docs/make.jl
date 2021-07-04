"""
    make.jl

The Makefile page for the documentation, reference: https://github.com/JuliaGPU/CUDA.jl/blob/master/docs/make.jl
"""

push!(LOAD_PATH, "..")

using Documenter
using SpecfemUtils

const src = "https://github.com/ziyixi/SpecfemUtils.jl"
const dst = "https://ziyixi.github.io/SpecfemUtils.jl/stable/"

function main()
    ci = get(ENV, "CI", "") == "true"

    @info "Generating Documenter.jl site"
    DocMeta.setdocmeta!(
        SpecfemUtils,
        :DocTestSetup,
        :(using SpecfemUtils);
        recursive = true,
    )

    makedocs(
        sitename = "SpecfemUtils.jl",
        authors = "Ziyi Xi",
        repo = "$src/blob/{commit}{path}#{line}",
        format = Documenter.HTML(
            # Use clean URLs on CI
            prettyurls = ci,
            canonical = dst,
        ),
        doctest = true,
        # strict = true,
        modules = [SpecfemUtils],
        pages = Any["Home"=>"index.md", "FAQ"=>"faq.md"],
    )

    if ci
        @info "Deploying to GitHub"
        deploydocs(repo = "github.com/ziyixi/SpecfemUtils.jl.git", push_preview = true)
    end
end

isinteractive() || main()
