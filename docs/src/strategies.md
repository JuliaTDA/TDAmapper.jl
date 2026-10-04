# Strategies and multivariate filters

The strategy submodules let you mix cover, refinement, and nerve choices. Their public constructors and fields are collected in the [API Reference](@ref).

## Interval covers

| Type | Main constructor parameters | Behavior |
|---|---|---|
| `Uniform` | `length`, `expansion` | Equally spaced centers and equal widths |
| `QuantileCover` | `n_intervals`, `expansion` | Boundaries from sample quantiles; roughly balances counts |
| `AdaptiveCover` | `n_intervals`, `expansion`, `n_bins` | Histogram approximation to density-adapted boundaries |
| `LogarithmicCover` | `n_intervals`, `expansion` | Log-spaced boundaries after shifting the minimum to 1 |
| `DyadicCover` | `max_depth`, `min_points`, `expansion` | Recursive subdivision where enough observations exist |
| `ManualCover` | Breakpoints or explicit `Interval` objects | Fixed scientifically meaningful levels |

`QuantileCover` can give repeated boundaries for repeated filter values; balanced counts are approximate. A fixed `ManualCover` is useful when comparing several samples using the same filter scale; ensure it covers all intended values. Adaptive covers recompute boundaries from each sample, so they answer a different comparison question.

```@example mapper_cover_choices
using TDAmapper
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform, QuantileCover, ManualCover
f = [0.0, 0.1, 0.2, 0.3, 2.0, 4.0]
uniform_sets = make_cover(R1Cover(f, Uniform(length=3, expansion=0.3)))
quantile_sets = make_cover(R1Cover(f, QuantileCover(n_intervals=3, expansion=0.3)))
manual_sets = make_cover(R1Cover(f, ManualCover([0.0, 0.25, 1.0, 4.0]; expansion=0.2)))
(; uniform_sizes=length.(uniform_sets), quantile_sizes=length.(quantile_sets), manual_sets)
```

## Two-dimensional filters

`R2Cover` takes one `(f₁, f₂)` tuple per observation and makes a product of two interval covers. Empty product cells are omitted.

```@example mapper_two_filters
using TDAmapper
using TDAmapper.ImageCovers: R2Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: SimpleNerve
X = EuclideanSpace([[Float64(i), Float64(j)] for i in 0:2 for j in 0:2])
f = [(p[1], p[2]) for p in X]
C = R2Cover(f, Uniform(length=3, expansion=0.4), Uniform(length=3, expansion=0.4))
M = classical_mapper(X, C, Trivial(), SimpleNerve())
@assert Set(vcat(M.C...)) == Set(eachindex(X))
M
```

The convenience form `classical_mapper(X, p -> (p[1], p[2]), cover1, cover2, refiner, nerve)` computes tuples and builds the same product-cover pipeline. Two filters may separate patterns hidden by one; they also multiply the potential number of cells and reduce observations available per cell. Use enough data to support the extra resolution.

## Refiners

| Type | Main parameters | Role |
|---|---|---|
| `Trivial` | None | Retain the initial cover without clustering |
| `DBscan` | `radius`, `min_neighbors`, `min_cluster_size`, `metric` | Density/connectivity grouping |
| `Hierarchical` | `linkage`, `threshold`, `metric` | Cut a dendrogram at a height |
| `SingleLinkage`, `CompleteLinkage`, `AverageLinkage`, `WardLinkage` | `threshold`, `metric` | Convenience hierarchical constructors |
| `FirstEmptyBin` | `num_bins`, `metric` | Single-linkage cut selected by a merge-height histogram gap |
| `KMeans` | `k`, `maxiter`, `metric` | Fixed-count centroid clusters |
| `KMedoids` | `k`, `maxiter`, `metric` | Fixed-count representative-observation clusters |
| `OPTICSRefiner` | `min_neighbors`, `metric` | OPTICS-inspired adaptive-neighbor connectivity |
| `SpectralRefiner` | `k`, `n_neighbors`, `metric` | Neighbor-graph spectral grouping |

Refiners act on the original geometry inside each cover element, not on the filter values alone. Fixed-count methods cap `k` at the pullback size; they can impose a split even when geometry supplies no distinct groups. K-means and spectral clustering involve randomized initialization; seed the RNG and verify sensitivity. Ward linkage assumes Euclidean variance geometry; its implementation uses the squared-distance convention expected by the clustering backend.

Clustering label 0 is generally retained as one additional outlier cluster per cover element. Do not assume noise has been discarded. For many small pullbacks, a simple refiner is easier to interpret than a complex estimator.

## Nerve rules

| Type | Edge or simplex condition |
|---|---|
| `SimpleNerve()` | At least one shared observation |
| `MinCountNerve(n)` | At least `n` shared observations |
| `PercentageNerve(p)` or `PercentageNerve(p, :and)` | Fraction at least `p` of either member set; `:and` requires both |
| `JaccardNerve(t)` | Shared count / union count at least `t` |
| `SimplicialNerve(max_dim)` | A common observation among every set in the simplex |

```@example mapper_complex
using TDAmapper
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: ManualCover
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: SimplicialNerve, n_vertices, n_edges, n_triangles
X = EuclideanSpace(reshape([0.0, 1.0, 2.0], 1, :))
C = R1Cover(first.(X), ManualCover([Interval(-1.0, 1.5), Interval(0.5, 2.5), Interval(0.5, 1.5)]))
M = mapper(X, C, Trivial(), SimplicialNerve(2))
@assert n_triangles(M.g) == 1
(; vertices=n_vertices(M.g), edges=n_edges(M.g), triangles=n_triangles(M.g))
```

A simplicial result stores dimension `d` simplices in `M.g.simplices[d+1]`. Its graph edges alone do not determine its filled simplices. The enumeration cost grows rapidly with cover count and maximum dimension; keep that dimension small unless higher simplices are required.
