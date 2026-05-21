using Graphs

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

Intersection-size checks are performed in parallel using `Threads.@threads` over all
`(i, j)` pairs with `i < j`, writing to a pre-allocated `BitMatrix` before edges
are added serially.
"""
function make_graph(X::MetricSpace, cover::Covering, N::MinCountNerve)
    n = length(cover)
    pairs = [(i, j) for i in 1:n for j in (i+1):n]

    has_edge = falses(n, n)
    Threads.@threads for k in eachindex(pairs)
        i, j = pairs[k]
        if !isempty(cover[i]) && !isempty(cover[j]) &&
                length(intersect(cover[i], cover[j])) >= N.n
            has_edge[i, j] = true
        end
    end

    g = SimpleGraph(n)
    for i in 1:n, j in (i+1):n
        has_edge[i, j] && add_edge!(g, i, j)
    end
    g
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
