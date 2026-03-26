"""
    MinCountNerve

A nerve implementation that connects two cover elements only if their intersection
has at least `n` elements.

# Fields
- `n::Int`: Minimum number of shared elements required for an edge.

# See Also
- [`min_intersection`](@ref): The underlying predicate constructor from MetricSpaces.jl
"""
struct MinCountNerve <: AbstractNerve
    n::Int
end

"""
    make_graph(X::MetricSpace, cover::Covering, N::MinCountNerve) -> Graph

Construct a nerve graph where edges require at least `N.n` shared elements.
"""
function make_graph(X::MetricSpace, cover::Covering, N::MinCountNerve)
    nerve_1d(cover, min_intersection(N.n))
end
