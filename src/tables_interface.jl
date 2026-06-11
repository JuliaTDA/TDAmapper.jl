# Function stubs for the Tables.jl integration.
#
# The methods for these functions live in the `TDAmapperTablesExt` package
# extension (see `ext/TDAmapperTablesExt.jl`). The extension loads
# automatically whenever Tables.jl is available in the active environment, so
# users only need to `using Tables` (or load any Tables.jl-compatible package
# such as DataFrames.jl) alongside TDAmapper to gain access to these methods.

"""
    euclidean_space(table; cols=nothing, standardize=false) -> EuclideanSpace

Build an [`EuclideanSpace`](@ref) from any
[Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible table, turning
each row into a point.

This is a function *stub*: the actual method is provided by the
`TDAmapperTablesExt` package extension, which loads automatically once
Tables.jl is present in the environment. To use it, make sure a Tables.jl
source is available, e.g.

```julia
using TDAmapper
using DataFrames   # brings Tables.jl into the environment

df = DataFrame(x = randn(100), y = randn(100), label = rand(["a", "b"], 100))
X = euclidean_space(df)            # uses the two numeric columns
```

# Arguments
- `table`: any Tables.jl-compatible source (e.g. a `DataFrame`, a named tuple
  of vectors, a vector of named tuples, ...).

# Keyword Arguments
- `cols=nothing`: a `Vector{Symbol}` selecting which columns become coordinates.
  When `nothing` (the default), every column whose element type is `<: Real`
  is selected. Columns that may hold `missing` values (i.e. element type
  `Union{Missing, <:Real}`) are **excluded** from the default selection. If
  such a column is requested explicitly an `ArgumentError` is thrown.
- `standardize=false`: when `true`, each selected column is centered to mean `0`
  and scaled to standard deviation `1`. Columns whose standard deviation is
  approximately `0` are only centered (not scaled).

# Returns
- An `EuclideanSpace` with one point per table row and one coordinate per
  selected column.

# See Also
- [`node_statistics`](@ref): summarise table columns over the nodes of a mapper.
"""
function euclidean_space end

"""
    node_statistics(M::AbstractMapper, table; stats=(mean,)) -> NamedTuple

Summarise the columns of a Tables.jl-compatible `table` over the nodes of a
mapper `M`, producing one row per mapper node.

This is a function *stub*: the actual method is provided by the
`TDAmapperTablesExt` package extension, which loads automatically once
Tables.jl is present in the environment. To use it, make sure a Tables.jl
source is available, e.g.

```julia
using TDAmapper
using DataFrames   # brings Tables.jl into the environment
using Statistics   # for `mean`, `std`, ...

M  = mapper(...)
df = DataFrame(...)                       # one row per point in `M.X`
ns = node_statistics(M, df; stats=(mean, std))
DataFrame(ns)                             # the result is a Tables.jl column table
```

The `table` must have exactly `length(M.X)` rows (one per point of the
underlying metric space); otherwise an `ArgumentError` is thrown.

# Arguments
- `M::AbstractMapper`: a mapper whose covering `M.C` defines the nodes.
- `table`: any Tables.jl-compatible source with one row per point of `M.X`.

# Keyword Arguments
- `stats=(mean,)`: a tuple of reducing functions applied per node to each
  numeric column.

# Returns
- A `NamedTuple` of equal-length vectors (a Tables.jl column table) with one row
  per mapper node. Columns are:
    - `node`: the node index `1:length(M.C)`.
    - `size`: the number of points in each node.
    - `\$(c)_\$(nameof(f))`: for each numeric column `c` of `table` and each
      function `f` in `stats`, `f` applied to that column restricted to the
      node's point indices.
    - `\$(c)_z`: for each numeric column `c`, the per-node z-score of the mean,
      `(node_mean - global_mean) / global_std`, set to `0.0` when the global
      standard deviation is approximately `0`.

# See Also
- [`euclidean_space`](@ref): build a metric space from a table.
"""
function node_statistics end

@testitem "Tables.jl extension: euclidean_space" begin
    using TDAmapper
    using DataFrames
    using StatsBase: mean, std

    # numeric columns selected, string column excluded by default
    df = DataFrame(x = [1.0, 2.0, 3.0], y = [4.0, 5.0, 6.0],
                   label = ["a", "b", "c"])
    X = euclidean_space(df)
    @test X isa EuclideanSpace
    @test length(X) == 3            # one point per row
    @test length(X[1]) == 2         # only the two numeric columns
    @test X[1] == [1.0, 4.0]
    @test X[2] == [2.0, 5.0]
    @test X[3] == [3.0, 6.0]

    # integer columns are numeric too
    dfi = DataFrame(a = [1, 2, 3], b = [10, 20, 30])
    Xi = euclidean_space(dfi)
    @test length(Xi) == 3
    @test length(Xi[1]) == 2
    @test Xi[1] == [1.0, 10.0]

    # cols selection (and order follows the cols argument)
    dfc = DataFrame(x = [1.0, 2.0, 3.0], y = [4.0, 5.0, 6.0],
                    z = [7.0, 8.0, 9.0])
    Xc = euclidean_space(dfc; cols = [:x, :z])
    @test length(Xc[1]) == 2
    @test Xc[1] == [1.0, 7.0]
    @test Xc[2] == [2.0, 8.0]
    Xr = euclidean_space(dfc; cols = [:z, :x])
    @test Xr[1] == [7.0, 1.0]

    # standardize: mean 0 / std 1; zero-variance column only centered
    dfs = DataFrame(x = [1.0, 2.0, 3.0, 4.0, 5.0],
                    const_col = [2.0, 2.0, 2.0, 2.0, 2.0])
    Xs = euclidean_space(dfs; standardize = true)
    M = stack(Xs)                   # rows = coordinates, cols = points
    @test isapprox(mean(M[1, :]), 0.0; atol = 1e-10)
    @test isapprox(std(M[1, :]), 1.0; atol = 1e-10)
    @test isapprox(mean(M[2, :]), 0.0; atol = 1e-10)
    @test all(isapprox.(M[2, :], 0.0; atol = 1e-10))

    # missing-value columns: excluded by default, error when requested
    dfm = DataFrame(x = [1.0, 2.0, 3.0], m = [1.0, missing, 3.0])
    Xm = euclidean_space(dfm)
    @test length(Xm[1]) == 1
    @test Xm[1] == [1.0]
    @test_throws ArgumentError euclidean_space(dfm; cols = [:x, :m])
end

@testitem "Tables.jl extension: node_statistics" begin
    using TDAmapper
    using DataFrames
    using Tables
    using StatsBase: mean, std
    using Graphs: SimpleGraph

    # 5 points, column a = 1..5; nodes [1,2] and [3,4,5]
    a = [1.0, 2.0, 3.0, 4.0, 5.0]
    X = euclidean_space(DataFrame(a = a))
    M = Mapper(X = X, C = [[1, 2], [3, 4, 5]], g = SimpleGraph(2))

    ns = node_statistics(M, DataFrame(a = a))   # default stats = (mean,)
    @test Tables.istable(ns)
    @test collect(ns.node) == [1, 2]
    @test collect(ns.size) == [2, 3]
    @test ns.a_mean ≈ [1.5, 4.0]

    # z-score: (node_mean - global_mean) / global_std (sample std = sqrt(2.5))
    gstd = std(a)
    @test ns.a_z ≈ [(1.5 - 3.0) / gstd, (4.0 - 3.0) / gstd]
    @test ns.a_z ≈ [-0.9486832980505138, 0.6324555320336759]

    # multiple stats; string columns ignored
    b = [10.0, 20.0, 30.0, 40.0, 50.0]
    df2 = DataFrame(a = a, b = b, label = ["p", "q", "r", "s", "t"])
    ns2 = node_statistics(M, df2; stats = (mean, std))
    cols = keys(ns2)
    @test all(k -> k in cols, (:node, :size, :a_mean, :a_std, :a_z,
                               :b_mean, :b_std, :b_z))
    @test !any(c -> startswith(String(c), "label"), cols)
    @test ns2.a_mean ≈ [1.5, 4.0]
    @test ns2.a_std ≈ [std([1.0, 2.0]), std([3.0, 4.0, 5.0])]
    @test ns2.b_mean ≈ [15.0, 40.0]

    # zero-variance column: z-score is exactly 0.0
    c = fill(7.0, 4)
    Xc = euclidean_space(DataFrame(c = c))
    Mc = Mapper(X = Xc, C = [[1, 2], [3, 4]], g = SimpleGraph(2))
    nsc = node_statistics(Mc, DataFrame(c = c))
    @test all(nsc.c_z .== 0.0)

    # row-count mismatch throws
    bad = DataFrame(a = [1.0, 2.0, 3.0])        # 3 rows, X has 5 points
    @test_throws ArgumentError node_statistics(M, bad)
end
