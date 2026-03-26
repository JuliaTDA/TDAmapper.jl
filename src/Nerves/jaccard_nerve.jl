"""
    JaccardNerve

A nerve implementation that connects two cover elements only if their Jaccard
similarity `|A∩B| / |A∪B|` meets or exceeds the threshold.

# Fields
- `threshold::Float64`: Minimum Jaccard similarity required for an edge (between 0 and 1).

# See Also
- [`jaccard_threshold`](@ref): The underlying predicate constructor from MetricSpaces.jl
"""
struct JaccardNerve <: AbstractNerve
    threshold::Float64
end

"""
    make_graph(X::MetricSpace, cover::Covering, N::JaccardNerve) -> Graph

Construct a nerve graph where edges require a minimum Jaccard similarity.
"""
function make_graph(X::MetricSpace, cover::Covering, N::JaccardNerve)
    nerve_1d(cover, jaccard_threshold(N.threshold))
end
