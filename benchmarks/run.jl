include("suite.jl")

results = run(SUITE, verbose=true)
BenchmarkTools.save(joinpath(@__DIR__, "baseline.json"), results)
println("Baseline saved to benchmarks/baseline.json")
