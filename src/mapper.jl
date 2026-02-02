"""
    mapper(X::MetricSpace, C::AbstractCover, R::AbstractRefiner, N::AbstractNerve) -> Mapper

A generic mapper implementation that combines covering, refinement, and nerve construction.

# Arguments
- `X::MetricSpace`: The input metric space containing the data points
- `C`: A covering strategy (must implement `make_cover`)
- `R`: A refinement strategy (must be callable on metric spaces)
- `N`: A nerve construction strategy (must implement `make_graph`)

# Returns
- `Mapper`: A mapper object containing the metric space, refined covering, and graph

# Description
This function implements a generic mapper algorithm by:
1. Creating an initial covering using `make_cover(C)`
2. Refining the covering using `refine_cover(X, raw_cover, R)`
3. Constructing a graph using `make_graph(X, cover, N)`

This provides a flexible framework for implementing different mapper variants
by combining different covering, refinement, and nerve strategies.

# Examples
```julia
using TDAmapper
using TDAmapper.ImageCovers, TDAmapper.Refiners, TDAmapper.Nerves

X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
f_X = [1.0, 2.0, 1.5]  # Filter values
C = R1Cover(f_X=f_X, U=[Interval(0.5, 1.5), Interval(1.0, 2.5)])
R = Trivial()
N = SimpleNerve()

M = mapper(X, C, R, N)
```

# See Also
- [`classical_mapper`](@ref): Specialized mapper for image covers
- [`ball_mapper`](@ref): Specialized for ball mappers
"""
function mapper(
    X::MetricSpace,
    C::AbstractCover,
    R::Refiners.AbstractRefiner,
    N::Nerves.AbstractNerve
)
    raw_cover = make_cover(C)
    cover = refine_cover(X, raw_cover, R)
    g = make_graph(X, cover, N)

    Mapper(X=X, C=cover, g=g)
end

@testitem "mapper integration" begin
    using TDAmapper
    using TDAmapper.ImageCovers, TDAmapper.IntervalCovers
    using TDAmapper.Refiners, TDAmapper.Nerves
    using Graphs

    # Test basic mapper pipeline
    X = [[0.0], [1.0], [2.0], [3.0], [4.0]] |> EuclideanSpace
    f_X = [0.0, 1.0, 2.0, 3.0, 4.0]
    C = R1Cover(f_X, Uniform(length=3, expansion=0.5))
    R = Trivial()
    N = SimpleNerve()

    M = mapper(X, C, R, N)

    @test M isa Mapper
    @test M.X == X
    @test length(M.C) > 0
    @test Graphs.nv(M.g) == length(M.C)

    # Test mapper with DBscan refiner
    X2 = sphere(20)  # Circle with 20 points
    f_X2 = [p[1] for p in X2]  # x-coordinate as filter
    C2 = R1Cover(f_X2, Uniform(length=5, expansion=0.3))
    R2 = DBscan(radius=0.5)

    M2 = mapper(X2, C2, R2, SimpleNerve())
    @test M2 isa Mapper
    @test Graphs.nv(M2.g) > 0

    # Test reproducibility - same input should give same output
    M3 = mapper(X2, C2, R2, SimpleNerve())
    @test Graphs.nv(M2.g) == Graphs.nv(M3.g)
    @test Graphs.ne(M2.g) == Graphs.ne(M3.g)
end
