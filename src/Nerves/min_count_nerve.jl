"""
    MinCountNerve

A nerve implementation that connects two cover elements only if their intersection
has at least `n` elements.

# Fields
- `n::Int`: Minimum number of shared elements required for an edge.
"""
struct MinCountNerve <: AbstractNerve
    n::Int
end

"""
    make_graph(X::MetricSpace, cover::Covering, N::MinCountNerve) -> Graph

Construct a nerve graph where edges require at least `N.n` shared elements.

Point memberships identify overlapping cover elements.
"""
function make_graph(X::MetricSpace, cover::Covering, N::MinCountNerve)
    return _overlap_graph((count, _, _) -> count >= N.n, cover)
end

function TDAmapper.validate(n::MinCountNerve)
    n.n >= 1 || throw(MapperArgumentError("MinCountNerve — n must be >= 1, got $(n.n)"))
    return nothing
end

@testitem "validate MinCountNerve" begin
    using TDAmapper
    using TDAmapper.Nerves
    @test_throws MapperArgumentError validate(MinCountNerve(0))
    @test_throws MapperArgumentError validate(MinCountNerve(-1))
    @test isnothing(validate(MinCountNerve(1)))
    @test isnothing(validate(MinCountNerve(5)))
end
