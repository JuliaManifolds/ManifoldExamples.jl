#!/usr/bin/env julia
#
#

#
# (a) if docs is not the current active environment, switch to it
# (from https://github.com/JuliaIO/HDF5.jl/pull/1020/) 
if Base.active_project() != joinpath(@__DIR__, "Project.toml")
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.develop(PackageSpec(; path = (@__DIR__) * "/../"))
    Pkg.resolve()
    Pkg.instantiate()
end

# (b) Did someone say render? Then we render!
if "--quarto" ∈ ARGS
    using CondaPkg
    CondaPkg.withenv() do
        @info "Rendering Quarto"
        examples_folder = (@__DIR__) * "/../examples"
        # instantiate the tutorials environment if necessary
        Pkg.activate(examples_folder)
        Pkg.resolve()
        Pkg.instantiate()
        Pkg.build("IJulia") # build IJulia to the right version.
        Pkg.activate(@__DIR__) # but return to the docs one before
        run(`quarto render $(examples_folder)`)
    end
end

# (c) load necessary packages for the docs
using Documenter: DocMeta, HTML, MathJax3, deploydocs, makedocs
using DocumenterCitations

using ManifoldExamples

generated_path = joinpath(@__DIR__, "src")
base_url = "https://github.com/JuliaManifolds/ManifoldExamples.jl/blob/master/"
isdir(generated_path) || mkdir(generated_path)
open(joinpath(generated_path, "contributing.md"), "w") do io
    # Point to source license file
    println(
        io,
        """
        ```@meta
        EditURL = "$(base_url)CONTRIBUTING.md"
        ```
        """,
    )
    # Write the contents out below the meta block
    for line in eachline(joinpath(dirname(@__DIR__), "CONTRIBUTING.md"))
        println(io, line)
    end
end

bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"); style = :alpha)
makedocs(;
    format = HTML(;
        mathengine = MathJax3(),
        prettyurls = get(ENV, "CI", nothing) == "true",
    ),
    sitename = "ManifoldExamples.jl",
    modules = [ManifoldExamples],
    pages = [
        "Home" => "index.md",
        "Examples" => ["Cubic Hermite interpolation" => "examples/hermite.md"],
        "Contributing to ManifoldExamples.jl" => "contributing.md",
        "References" => "src/references.md",
    ],
    plugins = [bib],
)
deploydocs(; repo = "github.com/JuliaManifolds/ManifoldExamples.jl", push_preview = true)
