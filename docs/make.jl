# Inside make.jl
push!(LOAD_PATH,"../src/")

import Pkg; Pkg.add("Documenter");
using Documenter, TDAmapper

makedocs(sitename="My Documentation")

deploydocs(
    repo = "github.com/vituri/TDAmapper.jl.git",
)