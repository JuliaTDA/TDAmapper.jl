using TDAmapper
using TDAmapper.ImageCovers
using TDAmapper.IntervalCovers
using TDAmapper.Refiners
using TDAmapper.Nerves

"""
    classical_mapper(
        X::MetricSpace,
        C::AbstractImageCover,
        R::AbstractRefiner,
        N::GraphNerve    
    ) -> Mapper

Constructs a Mapper object from a metric space using the Mapper algorithm.

# Arguments
- `X::MetricSpace`: The input metric space containing the data points.
- `C`: The image covering strategy.
- `R`: A refiner to apply to the pre-images of the cover intervals.
- `N::GraphNerve`: A nerve function to compute the nerve (graph) of the cover.

# Returns
- `Mapper`: An object containing the covered metric space and the resulting nerve graph.

# Description
This function implements the Mapper algorithm for topological data analysis. It first computes the pullback of the cover intervals via the filter values, clusters the data points in each pre-image, constructs a covered metric space, and then computes the nerve (graph) of the cover. The result is returned as a `Mapper` object.
"""
function classical_mapper(
    X::MetricSpace,
    C=Uniform(),
    R=DBscan(),
    N=SimpleNerve()
)
    mapper(X, C, R, N)
end


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