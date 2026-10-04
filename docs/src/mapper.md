# Classical Mapper

## A filter shows one aspect of a cloud

A Reeb graph identifies connected pieces at each level of a continuous scalar function. Mapper approximates this idea on observed data: use overlapping intervals instead of exact levels, and clustering instead of connected components of a continuous space.

The pipeline has three stages:

1. Cover the filter range and pull each interval back to observation indices.
2. Cluster each pullback using distances in the original observation geometry.
3. Join the refined subsets when they share observations.

The filter controls what aspect is viewed; clustering decides what is locally connected. A coordinate, mean eccentricity, density score, or measured outcome can all serve as filters. The appropriate choice depends on the question.

## Follow a circle through each stage

```@example mapper_circle
using TDAmapper
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: DBscan, refine_cover
using TDAmapper.Nerves: SimpleNerve, make_graph
using Graphs: nv, ne
angles = range(0, 2π; length=121)[1:end-1]
X = EuclideanSpace([[cos(t), sin(t)] for t in angles])
f_X = first.(X)
cover_strategy = Uniform(length=8, expansion=0.4)
image_cover = R1Cover(f_X, cover_strategy)
raw = make_cover(image_cover)
(; intervals=image_cover.U, pullback_sizes=length.(raw))
```

`f_X[i]` belongs to observation `i`. Intervals are closed, so endpoints can belong to adjacent intervals even when the expansion is zero. For `Uniform`, let $\Delta=(\max f-\min f)/(\text{length}-1)$. Interval centers are spaced by $\Delta$ and each interval has width $\Delta(1+\text{expansion})$. Thus `expansion=0.4` means 40% extra width relative to that spacing, **not** a 40% overlap fraction of the final interval width.

```@example mapper_circle
refiner = DBscan(radius=0.15)
refined = refine_cover(X, raw, refiner)
g = make_graph(X, refined, SimpleNerve())
M = classical_mapper(X, image_cover, refiner)
@assert M.C == refined
@assert nv(g) == nv(M.g) && ne(g) == ne(M.g)
(; raw_sets=length(raw), refined_sets=length(refined), graph=M.g)
```

The filter's middle intervals contain two arcs: one above and one below the horizontal axis. Euclidean clustering splits them; near the extreme coordinates the arcs connect. Each cover element is clustered independently, and the resulting subsets still refer to the original observation indices.

## Read nodes as groups, edges as shared observations

```@example mapper_circle
sizes = length.(M.C)
node_filter_means = [sum(f_X[ids]) / length(ids) for ids in M.C]
covered = Set(vcat(M.C...))
@assert covered == Set(eachindex(X))
(; smallest_node=minimum(sizes), largest_node=maximum(sizes),
   node_filter_means)
```

Node size measures membership, not independent sample count. An edge between nodes indicates overlap; it is not a direct distance between node centroids. Plot layout is another representation and does not encode the original geometry automatically.

## Clustering, noise, and empty sets

`DBscan` defaults to `min_neighbors=1` and `min_cluster_size=1`, which is permissive and useful for connectivity demonstrations. Increasing these changes the meaning of a cluster. In this package, cluster label 0 is reassigned to **one additional outlier group per pullback**; those observations are retained. Widely separated noise points can therefore occur together in a node. Inspect noise behavior before interpreting such a node as a connected group.

Most refiners omit empty pullbacks through the generic refinement path. `Trivial()` keeps the raw cover unchanged, so empty pullbacks may remain as empty isolated vertices. Exclude them when computing a mean yourself.

## Change the viewpoint

Use `R1Cover(eccentricity(X), cover_strategy)` for global centrality, or `R1Cover(distance_to_measure(X, X; k=5), cover_strategy)` for a local isolation score. Keep the geometry and clustering fixed initially so you can see what changing the filter does. Two-dimensional filters and alternative cover designs are described in [Strategies and multivariate filters](@ref).

A circle need not produce the same graph for every parameter setting. A coarse cover, excessive overlap, or a clustering radius larger than the separation between arcs can change the summary. The useful question is which structures persist under sensible neighboring choices.
