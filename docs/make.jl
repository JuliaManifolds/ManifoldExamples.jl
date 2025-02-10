#!/usr/bin/env julia
#
#

if "--help" ∈ ARGS
    println(
        """
docs/make.jl

Render the `Manopt.jl` documentation with optional arguments

Arguments
* `--help`              - print this help and exit without rendering the documentation
* `--prettyurls`        – toggle the prettyurls part to true (which is otherwise only true on CI)
* `--quarto`            – run the Quarto notebooks from the `tutorials/` folder before generating the documentation
  this has to be run locally at least once for the `tutorials/*.md` files to exist that are included in
  the documentation (see `--exclude-examples`) for the alternative.
  If they are generated once they are cached accordingly.
  Then you can spare time in the rendering by not passing this argument.
  If quarto is not run, some tutorials are generated as empty files, since they
  are referenced from within the documentation. These are currently
  `Optimize.md` and `ImplementOwnManifold.md`.
""",
    )
    exit(0)
end

#
# (a) if docs is not the current active environment, switch to it
# (from https://github.com/JuliaIO/HDF5.jl/pull/1020/) 
if Base.active_project() != joinpath(@__DIR__, "Project.toml")
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.develop(PackageSpec(; path=(@__DIR__) * "/../"))
    Pkg.resolve()
    Pkg.instantiate()
end

# (b) Did someone say render?
if "--quarto" ∈ ARGS
    using CondaPkg
    CondaPkg.withenv() do
        @info "Rendering Quarto"
        examples_folder = (@__DIR__) * "/../examples"
        # instantiate the tutorials environment if necessary
        Pkg.activate(examples_folder)
        # For a breaking release -> also set the tutorials folder to the most recent version
        Pkg.develop(PackageSpec(; path=(@__DIR__) * "/../"))
        Pkg.resolve()
        Pkg.instantiate()
        Pkg.build("IJulia") # build `IJulia` to the right version.
        Pkg.activate(@__DIR__) # but return to the docs one before
        return run(`quarto render $(examples_folder)`)
    end
end

# (c) load necessary packages for the docs
using Documenter: DocMeta, HTML, MathJax3, deploydocs, makedocs
using DocumenterCitations

using ManifoldExamples

generated_path = joinpath(@__DIR__, "src")
base_url = "https://github.com/JuliaManifolds/ManifoldExamples.jl/blob/main/"
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

examples_menu = "Examples" => ["Cubic Hermite interpolation" => "examples/hermite.md"]

bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"); style=:alpha)
makedocs(;
    format=HTML(; mathengine=MathJax3(), prettyurls=get(ENV, "CI", nothing) == "true"),
    sitename="ManifoldExamples.jl",
    modules=[ManifoldExamples],
    pages=[
        "Home" => "index.md",
        examples_menu,
        "Contributing to ManifoldExamples.jl" => "contributing.md",
        "References" => "references.md",
    ],
    plugins=[bib],
)
deploydocs(;
    repo="github.com/JuliaManifolds/ManifoldExamples.jl",
    push_preview=true,
    devbranch="main",
)
