# Differentiable Mapper benchmarks

From the ecosystem workspace, with Julia ≥1.10:

```sh
julia --project=TDAmapper.jl/benchmarks -e 'using Pkg; Pkg.develop([PackageSpec(path="MetricSpaces.jl"),PackageSpec(path="TDAmapper.jl")]); Pkg.instantiate()'
julia --project=TDAmapper.jl/benchmarks TDAmapper.jl/benchmarks/differentiable.jl
```

Seed **20261003** generates noisy circles with 100, 300 and 1000 points. Each
case measures soft-Mapper construction, an extended-persistence gradient on a
fixed graph, and three optimization epochs that rebuild the graph each step.
The script checks the gradient against central finite differences with absolute
tolerance **1e-6**, relative tolerance **1e-5**, before timing.

Compilation/warmup is excluded. BenchmarkTools requests 20 samples with a
one-second budget, `evals=1`, single-threaded BLAS; CSV records actual sample
counts, medians, memory, allocations, Julia/package versions and thread counts.
`differentiable_baseline.csv` is a local reference rather than a portable
performance threshold. Keep hardware/thread settings fixed for comparisons.
The companion `.metadata` file records CPU, operating system, architecture,
Git revision, working-tree state and BenchmarkTools/AD package versions.

The timed gradient holds graph membership and combinatorics fixed, as the
current optimization API does within each step. The stored soft membership
matrix is not part of that derivative. These timings do not establish the
performance or gradient of the faithful Monte Carlo Differentiable Mapper
construction; this distinction is documented in `soft_mapper`.

The older `suite.jl` benchmarks classical/ball Mapper separately and uses its
own data generation; use `differentiable.jl` for the seeded P1 baseline.
