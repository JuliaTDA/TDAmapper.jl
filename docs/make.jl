using TDAmapper
using Documenter
using DocumenterVitepress

DocMeta.setdocmeta!(TDAmapper, :DocTestSetup, :(using TDAmapper); recursive=true)

makedocs(;
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
        "The algorithms" => [
            "Mapper" => "mapper.md",
            "BallMapper" => "ballmapper.md",
            "Generalization" => "generalization.md",
        ],
        "Examples" => [
            "Diabetes Dataset" => "examples/diabetes.md",
        ],
        "API Reference" => "api.md",
    ]
)

DocumenterVitepress.deploydocs(;
    repo = "github.com/JuliaTDA/TDAmapper.jl",
    devbranch = "main",
    target = "build", # this is where Vitepress will generate the final website
    push_preview = true,
)
