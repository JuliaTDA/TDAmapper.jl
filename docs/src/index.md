# TDAmapper.jl

Mapper compresses observations into overlapping groups and draws their relationships as a graph. A node represents a group of **original observations**; an edge records that two groups share observations. This lets you inspect branches, connected groups, and cycles while retaining a route back to the data.

TDAmapper implements classical Mapper, Ball Mapper, interchangeable cover/refiner/nerve strategies, table integration, and graph-persistence objectives for learning filters. It reexports MetricSpaces' public geometric operations.

## A circle viewed through its first coordinate

```@example mapper_home
using TDAmapper
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: DBscan
using Graphs: nv, ne
angles = range(0, 2π; length=121)[1:end-1]
X = EuclideanSpace([[cos(t), sin(t)] for t in angles])
C = R1Cover(first.(X), Uniform(length=8, expansion=0.4))
M = classical_mapper(X, C, DBscan(radius=0.15))
@assert nv(M.g) == length(M.C)
(; nodes=nv(M.g), edges=ne(M.g), first_node_members=M.C[1])
```

Intervals in the first coordinate gather nearby levels of the circle. Clustering separates its upper and lower arcs where they are far apart. Shared observations connect adjacent groups. The [Classical Mapper](@ref) tutorial opens each stage and explains the choices.

## Read by goal

| Goal | Guide |
|---|---|
| Install a source checkout and prepare observations | [Getting started](@ref) |
| Understand the cover → cluster → nerve pipeline | [Classical Mapper](@ref) |
| Use landmarks and balls without a filter | [Ball Mapper](@ref) |
| Compare covers, refiners, and overlap rules | [Strategies and multivariate filters](@ref) |
| Build a custom strategy | [Extending the Mapper pipeline](@ref) |
| Read a table and summarize graph nodes | [Tables and node interpretation](@ref) |
| Learn a scalar filter with graph persistence | [Differentiable Mapper and graph persistence](@ref), [Nonlinear Mapper filters](@ref) |
| Diagnose a fragmented or dense graph | [Parameter selection and troubleshooting](@ref) |

A graph is a summary conditioned on your filter, geometry, cover, and clustering parameters. Its drawing and graph cycles alone do not establish properties of an underlying population. Use metadata, sensitivity checks, and the original observations to interpret it.
