# Parameter selection and troubleshooting

Mapper has several interacting scales. A filter-cover width and a clustering radius are measured in different spaces: the first in filter values, the second in the original geometry. Neither has a universal default suitable for all data.

## A practical sensitivity study

1. Select features, handle missing values, and decide on units or standardization.
2. Pick a filter that expresses a question, and inspect its distribution.
3. Choose a modest number of intervals and moderate overlap; inspect pullback sizes.
4. Choose a clustering scale from original-data neighbor distances and inspect clusters within several pullbacks.
5. Compare neighboring parameter values and original observations behind the resulting nodes.

```@example mapper_sensitivity
using TDAmapper
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: DBscan
using Graphs: nv, ne, connected_components
angles = range(0, 2π; length=81)[1:end-1]
X = EuclideanSpace([[cos(t), sin(t)] for t in angles])
results = map(Iterators.product((6, 8), (0.2, 0.4), (0.15, 0.25))) do (resolution, overlap, radius)
    M = classical_mapper(X, R1Cover(first.(X), Uniform(length=resolution, expansion=overlap)),
                         DBscan(radius=radius))
    (; resolution, overlap, radius, nodes=nv(M.g), edges=ne(M.g),
       components=length(connected_components(M.g)),
       covered=length(unique(vcat(M.C...))))
end
vec(results)
```

Record coverage and node sizes as well as counts. Two graphs with equal counts need not represent the same groups. Large nodes can hide multiple structures; many tiny nodes can reflect sparse sampling. A graph that changes drastically under a small, scientifically reasonable adjustment calls for closer inspection.

## Effects of common changes

| Change | Typical effect to inspect |
|---|---|
| More intervals | Smaller pullbacks, finer resolution, more sparse groups |
| More overlap | More duplicated memberships and possible edges |
| Larger clustering radius / linkage threshold | Fewer local groups and potential merging of branches |
| Higher DBSCAN count thresholds | More label-0 observations, retained in an outlier group |
| Stronger nerve overlap threshold | Fewer edges; small-node links can disappear |
| More landmarks in Ball Mapper | Smaller achieved coverage radius but possibly more nodes |
| Larger Ball Mapper radius | More coverage and more overlapping groups |

These are tendencies, not monotonic guarantees for the full pipeline. Geometry, distribution, and boundary placement matter.

## Troubleshooting

| Symptom | Check |
|---|---|
| Package installation cannot resolve MetricSpaces | Develop sibling checkouts or install MetricSpaces by URL first. |
| `Uniform`, `DBscan`, or `R1Cover` is undefined | Import its strategy submodule. |
| `sphere` or `torus` is undefined | Import from `MetricSpaces.Datasets`. |
| `X[1, :]` or `X[:, i]` gives the wrong result | Point clouds are vectors of points; use `first.(X)` or `X[i]`. |
| A graph has isolated empty nodes | `Trivial` retains empty raw pullbacks; inspect `isempty.(M.C)`. |
| Distant points appear in one node | Inspect label-0 reassignment and the refiner's clustering scale. |
| Ball Mapper misses observations | Check the union of node indices and increase radius or improve landmarks if appropriate. |
| `ball_mapper(...; ϵ=...)` fails | Radius is a positional argument: `ball_mapper(X, L, radius)`. |
| Graphs.jl functions fail on `M.g` | A `SimplicialNerve` returns a complex; use `n_vertices`, `n_edges`, etc. |
| `euclidean_space` or `node_statistics` has no method | Load Tables.jl or DataFrames to activate the optional extension. |
| `optimize_filter` has no method | Load both Zygote and Optimisers. |
| Learned filters shrink toward a constant | The minimized persistence objective can collapse amplitude; add justified scale control. |

## Cost and reproducibility

Two-filter covers can have the product of their interval counts in cells. Pairwise nerves compare cover elements, and higher simplicial nerves enumerate larger combinations. Hierarchical/KMedoids/spectral refiners can allocate dense matrices within a pullback. Reduce resolution or use landmarks when those costs dominate.

Record observation ordering, seed, Julia/dependency versions, metric, preprocessing, filter, and all strategy parameters. Parallel refinement requires thread-safe custom strategies. Avoid measuring first-call compilation as steady-state runtime.

## Build the documentation

From the TDAmapper package directory:

```sh
julia docs/setup.jl
julia --project=docs docs/make.jl
```

Run `julia --project=docs docs/make.jl`. Core examples need no downloaded data, plotting backend, or R installation. Tables examples run as part of the build; optional optimization snippets are ordinary Julia blocks because machine-learning dependencies are not required by the basic docs environment. The VitePress renderer needs its Node/npm build dependencies; CI handles deployment.
