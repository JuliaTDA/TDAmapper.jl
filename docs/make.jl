using TDAmapper
using Documenter
using DocumenterVitepress

DocMeta.setdocmeta!(TDAmapper, :DocTestSetup, :(using TDAmapper); recursive=true)

makedocs(;
    checkdocs = :exports,
    modules = [TDAmapper],
    authors = "Guilherme Vituri <56522687+vituri@users.noreply.github.com> and contributors",
    sitename = "TDAmapper.jl",
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/JuliaTDA/TDAmapper.jl", # this must be the full URL!
        devbranch = "main",
        devurl = "dev",
    ),
    pages = [
        "Home" => "index.md",
        "Getting started" => "getting_started.md",
        "The algorithms" => [
            "Mapper" => "mapper.md",
            "BallMapper" => "ballmapper.md",
            "Strategies and multivariate filters" => "strategies.md",
            "Custom strategies" => "generalization.md",
            "Differentiable Mapper" => "differentiable.md",
            "Nonlinear filters" => "neural_filters.md",
        ],
        "Tables and node interpretation" => "tables.md",
        "Parameter selection" => "parameters.md",
        "Examples" => [
            "Diabetes Dataset" => "examples/diabetes.md",
        ],
        "API Reference" => "api.md",
    ],
    warnonly = [:missing_docs, :cross_references],
)

if get(ENV, "CI", "false") == "true" || get(ENV, "JULIATDA_DOCS_DEPLOY", "false") == "true"
    DocumenterVitepress.deploydocs(;
        repo = "github.com/JuliaTDA/TDAmapper.jl",
        devbranch = "main",
        target = "build", # this is where Vitepress will generate the final website
        push_preview = true,
    )
end
