using TDAmapper
using TDAmapper.ImageCovers
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