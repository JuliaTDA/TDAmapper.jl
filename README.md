# TDAmapper.jl

[![Build Status](https://github.com/JuliaTDA/TDAmapper.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaTDA/TDAmapper.jl/actions/workflows/CI.yml?query=branch%3Amain)

Mapper-like algorithms from Topological Data Analysis, implemented in Julia.

## Features

- **Classical Mapper**: Filter function + interval covering + DBSCAN clustering + nerve graph
- **Ball Mapper**: Landmark-based covering with epsilon balls
- **Generic Mapper Pipeline**: Pluggable cover, refiner, and nerve strategies via abstract interfaces
- **Built on MetricSpaces.jl**: Re-exports all metric space operations (point clouds, distances, sampling)

## Installation

```julia
using Pkg
Pkg.add("TDAmapper")
```

## Quick Start

### Classical Mapper

```julia
using TDAmapper
using TDAmapper.ImageCovers, TDAmapper.IntervalCovers, TDAmapper.Refiners

# Generate a point cloud on a circle
X = sphere(1000, dim=2)

# Use x-coordinate as filter function
fv = first.(X)

# Create image covering: 10 overlapping intervals
ic = R1Cover(fv, Uniform(length=10, expansion=0.3))

# Run mapper with DBSCAN clustering
M = classical_mapper(X, ic, DBscan(radius=0.1))

# M.g is the mapper graph, M.C is the covering (index vectors)
println(M)  # "Mapper graph with N vertices and M edges"
```

### Ball Mapper

```julia
using TDAmapper

# Generate data on a torus
X = torus(2000)

# Select 100 landmarks via farthest point sampling
L = farthest_points_sample_ids(X, 100)

# Build ball mapper with radius 0.8
M = ball_mapper(X, L, 0.8)
```

## Architecture

The mapper pipeline has three pluggable stages:

1. **Cover** (`AbstractCover`): How to partition/cover the data
   - `R1Cover`: Pullback of intervals via a filter function
   - `EpsilonBall`: Balls of fixed radius around landmarks

2. **Refiner** (`AbstractRefiner`): How to cluster within each cover element
   - `DBscan`: DBSCAN clustering
   - `Trivial`: No clustering (all points in one cluster)

3. **Nerve** (`AbstractNerve`): How to build the graph
   - `SimpleNerve`: Edge between overlapping cover elements

## Result Type

All mapper functions return a `Mapper` struct:

- `M.X`: The original metric space
- `M.C`: The covering as `Vector{Vector{Int}}` (indices into `M.X`)
- `M.g`: The nerve graph (from Graphs.jl)

## References

- Singh, G., Memoli, F., & Carlsson, G. (2007). Topological Methods for the Analysis of High Dimensional Data Sets and 3D Object Recognition. Eurographics Symposium on Point-Based Graphics.
- Dlotko, P. (2019). Ball Mapper: A Shape Summary for Topological Data Analysis. arXiv:1901.07410.

## See Also

- [MetricSpaces.jl](https://github.com/JuliaTDA/MetricSpaces.jl): Foundation layer for metric spaces and distances
- [TDAplots.jl](https://github.com/JuliaTDA/TDAplots.jl): Visualization of mapper graphs

## License

MIT License
