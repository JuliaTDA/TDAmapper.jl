"""
    JaccardNerve

A nerve implementation that connects two cover elements only if their Jaccard
similarity `|A∩B| / |A∪B|` meets or exceeds the threshold.

# Fields
- `threshold::Float64`: Minimum Jaccard similarity required for an edge (between 0 and 1).
"""
struct JaccardNerve <: AbstractNerve
    threshold::Float64
end

"""
    make_graph(X::MetricSpace, cover::Covering, N::JaccardNerve) -> Graph

Construct a nerve graph where edges require a minimum Jaccard similarity.

The Jaccard similarity is computed as `|A∩B| / (|A| + |B| - |A∩B|)`.
Pairs where both cover elements are empty yield no edge.

Point memberships identify overlapping cover elements.
"""
function make_graph(X::MetricSpace, cover::Covering, N::JaccardNerve)
    return _overlap_graph((count, a, b) -> count / (a + b - count) >= N.threshold, cover)
end

function TDAmapper.validate(n::JaccardNerve)
    0 < n.threshold < 1 || throw(MapperArgumentError("JaccardNerve — threshold must be in (0, 1), got $(n.threshold)"))
    return nothing
end

@testitem "validate JaccardNerve" begin
    using TDAmapper
    using TDAmapper.Nerves
    @test_throws MapperArgumentError validate(JaccardNerve(0.0))
    @test_throws MapperArgumentError validate(JaccardNerve(1.0))
    @test_throws MapperArgumentError validate(JaccardNerve(-0.1))
    @test isnothing(validate(JaccardNerve(0.5)))
    @test isnothing(validate(JaccardNerve(0.99)))
end
