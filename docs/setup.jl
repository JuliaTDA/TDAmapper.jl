using Pkg

Pkg.activate(@__DIR__)
metricspaces = normpath(joinpath(@__DIR__, "..", "..", "MetricSpaces.jl"))
isdir(metricspaces) || error("Clone MetricSpaces.jl beside TDAmapper.jl before running docs/setup.jl")
Pkg.develop([
    PackageSpec(path=metricspaces),
    PackageSpec(path=normpath(joinpath(@__DIR__, ".."))),
])
Pkg.instantiate()
