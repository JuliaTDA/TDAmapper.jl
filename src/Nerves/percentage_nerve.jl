"""
    PercentageNerve

A nerve implementation that connects two cover elements only if their intersection
is at least a fraction `p` of one or both sets.

# Fields
- `p::Float64`: Minimum fraction of overlap required (between 0 and 1).
- `mode::Symbol`: `:or` requires the fraction for at least one set; `:and` requires it for both sets.

# See Also
- [`percentage_intersection`](@ref): The underlying predicate constructor from MetricSpaces.jl
"""
struct PercentageNerve <: AbstractNerve
    p::Float64
    mode::Symbol
end

PercentageNerve(p::Float64) = PercentageNerve(p, :or)

"""
    make_graph(X::MetricSpace, cover::Covering, N::PercentageNerve) -> Graph

Construct a nerve graph where edges require a minimum percentage overlap.
"""
function make_graph(X::MetricSpace, cover::Covering, N::PercentageNerve)
    nerve_1d(cover, percentage_intersection(N.p; mode=N.mode))
end
