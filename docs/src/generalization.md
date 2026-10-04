# Extending the Mapper pipeline

A custom covering implements `make_cover(strategy)` and returns original observation indices. A refiner is callable on a subset and returns one integer cluster label per point. A nerve implements `make_graph(X, cover, strategy)` and returns the desired graph or complex. Strategies used with `mapper` must subtype their respective abstract interfaces.

## A fixed cover with no clustering

Sometimes a scientific grouping is already available and only its overlap graph is needed:

```@example mapper_custom
using TDAmapper
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: SimpleNerve
struct FixedCover <: AbstractCover
    members::Covering
end
TDAmapper.make_cover(c::FixedCover) = c.members
function TDAmapper.validate(c::FixedCover)
    all(ids -> all(>(0), ids), c.members) || throw(MapperArgumentError("indices must be positive"))
    nothing
end
X = EuclideanSpace(reshape([0.0, 1.0, 2.0, 3.0], 1, :))
C = FixedCover([[1, 2], [2, 3], [3, 4]])
M = mapper(X, C, Trivial(), SimpleNerve())
M
```

Your cover must also ensure every index belongs to the actual cloud. The example validation checks positivity; a cover that stores the cloud or its length can additionally validate upper bounds. Use each original index once per subset and verify coverage if that is required by the application.

## A custom refiner

```@example mapper_custom
using TDAmapper.Refiners: AbstractRefiner
struct SignRefiner <: AbstractRefiner end
(r::SignRefiner)(X) = [p[1] < 1.5 ? 1 : 2 for p in X]
TDAmapper.validate(::SignRefiner) = nothing
split = mapper(X, C, SignRefiner(), SimpleNerve())
split.C
```

Labels are local to each cover element. The generic refinement maps them back to original indices; labels are not vertex identifiers. Return as many labels as observations in the subset. This example splits by a coordinate threshold; a scientific clustering strategy should instead encode the intended local connectivity.

## A custom nerve

```@example mapper_custom
using TDAmapper.Nerves: AbstractNerve, make_graph
using Graphs: SimpleGraph, add_edge!
struct TwoShared <: AbstractNerve end
TDAmapper.validate(::TwoShared) = nothing
function TDAmapper.Nerves.make_graph(X::MetricSpace, cover::Covering, ::TwoShared)
    g = SimpleGraph(length(cover))
    for i in eachindex(cover), j in (i + 1):length(cover)
        length(intersect(cover[i], cover[j])) >= 2 && add_edge!(g, i, j)
    end
    g
end
custom = mapper(X, C, Trivial(), TwoShared())
custom
```

This reproduces `MinCountNerve(2)` to show the interface. Prefer the built-in strategy when its behavior matches your needs.

## Validation and concurrency

`mapper` calls `validate` on all three strategies before building the cover. Implement informative parameter checks. The generic fallback accepts custom types unless specialized checks are provided, so validation does not automatically establish mathematical cover properties.

Refinement may call your refiner concurrently on different subsets. Keep strategies free from unsynchronized shared mutation. Returning deterministic labels and stable cover ordering makes comparison and debugging easier. See [Strategies and multivariate filters](@ref) before implementing a strategy that may already exist.
