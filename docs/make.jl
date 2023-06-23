using Documenter, TDAmapper

makedocs(
    sitename="TDAmapper.jl"
    ,pages = [
        "Introduction" => "index.md"
        ,"The theory" => "theory.md"
        ,"Examples" => "examples.md"
        ,"How-to" => "how-to.md"
        ,"Reference" => "reference.md"
    ]
    ,doctest = false
    )
