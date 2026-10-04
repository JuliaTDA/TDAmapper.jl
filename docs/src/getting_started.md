# Getting started

## Install sibling source checkouts

These packages are developed together and may not resolve through the General registry. From a directory containing sibling `MetricSpaces.jl` and `TDAmapper.jl` checkouts, run:

```julia
using Pkg
Pkg.activate("mapper-tutorial")
Pkg.develop(path="MetricSpaces.jl")
Pkg.develop(path="TDAmapper.jl")
Pkg.instantiate()
```

TDAmapper requires Julia 1.9 or later. To install without checkouts, first add `MetricSpaces` using its repository URL, then add `TDAmapper` using its URL. Installing only TDAmapper can fail if its MetricSpaces dependency is unavailable from your registries. Keep the manifest for reproducible dependency versions.

## Prepare the geometry

```@example mapper_prepare
using TDAmapper
X = EuclideanSpace([[0.0, 0.0], [0.1, 0.0], [1.0, 1.0], [1.1, 1.0]])
A = as_matrix(X)
@assert size(A) == (2, 4)
(; observations=length(X), coordinates=length(X[1]))
```

`X[i]` is observation `i`; coordinate matrices use **columns as observations**. Use `EuclideanSpace(Matrix(permutedims(A_rows)))` for row-oriented numerical data. Keep any labels or outcome measurements in this exact order. Choose numeric features, handle missing values, and decide on scaling before creating a graph. The table extension handles conversion from Tables.jl sources; see [Tables and node interpretation](@ref).

Dataset generators have a separate namespace:

```@example mapper_prepare
using MetricSpaces.Datasets: grid
grid(3; dim=2)
```

`using TDAmapper` reexports MetricSpaces operations, but does not import all dataset generator names.

## Import strategy types explicitly

```@example mapper_prepare
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: SimpleNerve
C = R1Cover(first.(X), Uniform(length=3, expansion=0.5))
M = mapper(X, C, Trivial(), SimpleNerve())
M
```

The strategy types live in submodules. `mapper` takes a covering strategy, a refiner, and a nerve strategy as positional arguments. `classical_mapper` provides defaults for the latter two; `ball_mapper` supplies a ball cover and no refinement.

## Inspect a result

```@example mapper_prepare
using Graphs: nv, ne, connected_components
@assert nv(M.g) == length(M.C)
covered = sort(unique(vcat(M.C...)))
(; node_sizes=length.(M.C), edges=ne(M.g),
   components=length(connected_components(M.g)), covered)
```

`M.X` is the original cloud, `M.C[v]` contains its indices for node `v`, and `M.g` is the nerve result. A point can belong to multiple nodes, so summing node sizes can exceed the original sample count. Inspect `X[M.C[v]]` to examine a node's observations. With `SimplicialNerve`, `M.g` is a `SimplicialComplex`; use its own counting helpers instead of Graphs.jl functions.

## Plotting and next steps

TDAmapper constructs the summary; TDAplots supplies visualization. Start with the executable [Classical Mapper](@ref) or [Ball Mapper](@ref) tutorial before styling a graph. [Parameter selection and troubleshooting](@ref) explains how to investigate a graph that looks surprising.
