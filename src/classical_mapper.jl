using TDAmapper
using TDAmapper.ImageCovers
using TDAmapper.IntervalCovers
using TDAmapper.Refiners
using TDAmapper.Nerves

"""
    classical_mapper(
        X::MetricSpace,
        C,
        R,
        N
    ) -> Mapper

Constructs a Mapper object from a metric space using the Mapper algorithm.

# Arguments
- `X::MetricSpace`: The input metric space containing the data points.
- `C`: The image covering strategy. There is no default: a covering cannot
  be constructed without filter values, so the caller must supply one (e.g.
  an `R1Cover` or `R2Cover`).
- `R`: A refiner to apply to the pre-images of the cover intervals.
- `N`: A nerve strategy to compute the nerve (graph) of the cover.

# Returns
- `Mapper`: An object containing the covered metric space and the resulting nerve graph.

# Description
This function implements the Mapper algorithm for topological data analysis. It first computes the pullback of the cover intervals via the filter values, clusters the data points in each pre-image, constructs a covered metric space, and then computes the nerve (graph) of the cover. The result is returned as a `Mapper` object.
"""
function classical_mapper(
    X::MetricSpace,
    C,
    R=DBscan(),
    N=SimpleNerve()
)
    mapper(X, C, R, N)
end

"""
    ada_mapper(X::EuclideanSpace; lens=nothing, k=min(5, length(X)-1),
               basepoint=nothing, min_relative_persistence=0.35, overlap=0.2,
               regular_intervals=10, max_intervals=10_000, refiner=nothing,
               nerve=SimpleNerve(), return_details=false)

Build a Mapper graph with a one-dimensional cover refined around persistent
loops, following [Khourashahi et al. (2026)](https://arxiv.org/abs/2606.04464).
Load TDARipserer to activate this method.

The input needs distinct finite Euclidean points. The default lens is weighted
shortest-path distance from a first-coordinate extreme in the symmetric
`k`-nearest-neighbor graph. Use `basepoint` to select another input point, or
supply one finite `lens` value per point. The default lens needs a connected
graph. A custom lens allows disconnected inputs.

Finite Rips H₁ bars with persistence greater than the chosen fraction of the
maximum are localized using their death triangles. The cover uses the shortest
nondegenerate critical range to set regular widths and one third of that width
in loop-critical regions. Without a critical range it uses a uniform cover.
`refiner` defaults to DBSCAN with a radius derived from nearest-neighbor
distances. Equal distances and shortest paths are resolved by vertex order.

When `return_details=true`, return the Mapper, lens, critical ranges, final
cover, and H₁ diagram as a named tuple.

```julia
using TDAmapper, TDARipserer
X = EuclideanSpace([[cos(t), sin(t)] for t in range(0, 2π; length=41)[1:40]])
result = ada_mapper(X; return_details=true)
result.mapper
```
"""
function ada_mapper end


"""
    classical_mapper(X, f::Function, cover1, cover2, R=DBscan(), N=SimpleNerve())

2D mapper variant. `f(x)` must return a 2-tuple `(f₁, f₂)`.
"""
function classical_mapper(
    X::MetricSpace,
    f::Function,
    cover1::AbstractIntervalCover,
    cover2::AbstractIntervalCover,
    R=DBscan(),
    N=SimpleNerve()
)
    f_X = [f(x) for x in X]
    C = R2Cover(f_X, cover1, cover2)
    mapper(X, C, R, N)
end


@testitem "classical_mapper 2D" begin
    using TDAmapper
    using TDAmapper.ImageCovers, TDAmapper.IntervalCovers, TDAmapper.Refiners

    X = [[float(i), float(j)] for i in 1:5, j in 1:5] |> vec |> EuclideanSpace
    f = x -> (x[1], x[2])
    M = classical_mapper(X, f, Uniform(length=3, expansion=0.3), Uniform(length=3, expansion=0.3))
    @test M isa Mapper
    @test length(M.C) > 0
end


@testitem "classical_mapper" begin
    using TDAmapper
    using MetricSpaces.Datasets: sphere
    using TDAmapper.ImageCovers, TDAmapper.Refiners, TDAmapper.IntervalCovers
    import Graphs

    X = sphere(1000, dim=2)
    fv = first.(X)
    image_covering = R1Cover(fv, Uniform(length=3, expansion=0.25))
    clustering = DBscan(radius=0.1)

    M = classical_mapper(X, image_covering, clustering)
    g = M.g
    @test M.X == X
    @test Graphs.nv(g) == 4
    @test Graphs.ne(g) == 4

    X = [[1, 0], [0, 1], [1, 2], [2, 1]] .|> float |> EuclideanSpace
    fv = first.(X)
    image_covering = R1Cover(fv, Uniform(length=3))
    clustering = DBscan(radius=0.1)

    
    M = classical_mapper(X, image_covering, clustering)
    g = M.g
    @test M.X == X
    @test Graphs.nv(M.g) == 4
    @test Graphs.ne(M.g) == 0
end
