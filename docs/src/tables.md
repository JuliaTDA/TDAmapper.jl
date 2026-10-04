# Tables and node interpretation

The optional Tables.jl extension connects observation tables to point clouds and node summaries. Load `Tables` or a package such as DataFrames to activate it; it is not required for the core Mapper algorithms.

## Keep geometry and metadata in one aligned table

The following column table needs no DataFrames dependency:

```@example mapper_tables
using TDAmapper, Tables
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: Trivial
using Statistics: mean, std
observations = (
    x=[0.0, 0.1, 1.0, 1.1],
    y=[1.0, 1.1, 2.0, 2.1],
    response=[10.0, 12.0, 30.0, 32.0],
    group=["a", "a", "b", "b"],
)
X = euclidean_space(observations; cols=[:x, :y], standardize=true)
M = classical_mapper(X, R1Cover(first.(X), Uniform(length=3, expansion=0.5)), Trivial())
summary = node_statistics(M, observations; stats=(mean, std))
@assert length(summary.node) == length(M.C)
summary
```

The `cols` argument specifies which columns define geometry and their coordinate order. Explicit selection avoids accidentally including an outcome or numeric identifier as a geometric feature. Without it, all columns whose element type is `<: Real` are selected. String columns and columns admitting `missing` are excluded; explicitly requesting a missing-valued or nonnumeric column throws an `ArgumentError`. Impute or drop missing values first, preserving row alignment.

`standardize=true` centers and scales selected columns by their sample standard deviation; nearly constant columns are only centered. This transformation is performed on the supplied table, rather than fitted as a reusable training-data transformer. Fit preprocessing separately for predictive evaluation.

## Understand the summary columns

`node_statistics` requires exactly one table row per point in `M.X`. Its returned NamedTuple is a Tables.jl column table with one row per node:

| Column | Meaning |
|---|---|
| `node` | Node index |
| `size` | Number of member observations |
| `response_mean`, `response_std`, etc. | Requested reducer on numeric values of member rows |
| `response_z`, etc. | Node mean minus global mean, divided by global sample standard deviation |

All numeric table columns are summarized, not just the columns used for geometry. The `_z` values compare each node mean with the observation distribution; they are not a standard error or significance test. A constant global column receives a zero z-score. Node groups overlap, so their summaries are correlated and their sizes cannot be summed as independent observations. A singleton's sample `std` can be `NaN`; empty nodes can make reducers undefined. Inspect node sizes first.

To work with DataFrames, use `DataFrame(summary)`. To summarize categories, inspect member rows directly:

```@example mapper_tables
category_counts = [Dict(g => count(==(g), observations.group[ids])
    for g in unique(observations.group[ids])) for ids in M.C]
```

## Make interpretation traceable

Select a node, inspect `M.C[v]`, and return to the original records at those indices. Compare unusual node summaries with neighboring nodes and the overall distribution. A striking color on a small node may represent only one observation. Record the filter and cover choices alongside the figure so readers can understand how that group was produced.
