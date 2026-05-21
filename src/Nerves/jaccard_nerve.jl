using Graphs

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

Similarity checks are performed in parallel using `Threads.@threads` over all
`(i, j)` pairs with `i < j`, writing to a pre-allocated `BitMatrix` before edges
are added serially.
"""
function make_graph(X::MetricSpace, cover::Covering, N::JaccardNerve)
    n = length(cover)
    pairs = [(i, j) for i in 1:n for j in (i+1):n]

    has_edge = falses(n, n)
    Threads.@threads for k in eachindex(pairs)
        i, j = pairs[k]
        a, b = cover[i], cover[j]
        if isempty(a) || isempty(b)
            continue
        end
        inter = length(intersect(a, b))
        union_size = length(a) + length(b) - inter
        if union_size > 0 && inter / union_size >= N.threshold
            has_edge[i, j] = true
        end
    end

    g = SimpleGraph(n)
    for i in 1:n, j in (i+1):n
        has_edge[i, j] && add_edge!(g, i, j)
    end
    g
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
