# A tabular workflow with the diabetes dataset

The Reaven–Miller diabetes dataset is a historical example of multivariate exploration. This page describes how to apply the current table workflow to an already loaded dataset. It does not reproduce a published figure or claim a medical interpretation. The general [Tables and node interpretation](@ref) guide runs on a tiny column table without downloading external data.

## Load and validate the observations

If you use the `diabetes` data in R's `rrcov` package, load it through RCall or export it to a table format you already use. R, RCall, and the dataset package are optional external dependencies; installation and downloads should be done explicitly before analysis. Keep the source citation and dataset version with your work.

After loading a Tables-compatible table called `df`, inspect its schema and confirm the numerical columns `rw`, `fpg`, `glucose`, `insulin`, and `sspg`, plus any group labels you intend to display. Handle missing values before selecting these features.

```julia
using TDAmapper, Tables
X = euclidean_space(df; cols=[:rw, :fpg, :glucose, :insulin, :sspg], standardize=true)
```

Selected rows become observations; standardization puts the five features on comparable sample scales. It also changes the geometry, so distance radii must be chosen in the standardized space. Group labels are excluded from geometry and remain aligned to the original rows.

## Construct and inspect a summary

```julia
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: QuantileCover
using TDAmapper.Refiners: DBscan
using Graphs: nv, ne
filter_values = eccentricity(X)
M = classical_mapper(X,
    R1Cover(filter_values, QuantileCover(n_intervals=6, expansion=0.3)),
    DBscan(radius=0.5))
summary = node_statistics(M, df)
(; nodes=nv(M.g), edges=ne(M.g), sizes=length.(M.C))
```

These values illustrate the interface, not validated analysis settings. Inspect nearest-neighbor distances and the groups inside each pullback, then compare neighboring radii and cover settings. You can also use `ball_mapper(X, farthest_points_sample_ids(X, min(20, length(X))), 0.5)` and check its coverage explicitly.

## Interpret with metadata

Compare numerical node summaries and category counts over `df` rows indexed by `M.C[v]`. Small or overlapping groups should be interpreted with care. A graph can suggest an exploratory pattern; it does not provide a diagnosis, causal explanation, or statistically validated classification. Plotting is available separately through TDAplots, using the same node membership indices.
