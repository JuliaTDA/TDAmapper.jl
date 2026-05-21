using Graphs

"""
    PercentageNerve

A nerve implementation that connects two cover elements only if their intersection
is at least a fraction `p` of one or both sets.

# Fields
- `p::Float64`: Minimum fraction of overlap required (between 0 and 1).
- `mode::Symbol`: `:or` requires the fraction for at least one set; `:and` requires it for both sets.
"""
struct PercentageNerve <: AbstractNerve
    p::Float64
    mode::Symbol
end

PercentageNerve(p::Float64) = PercentageNerve(p, :or)

"""
    make_graph(X::MetricSpace, cover::Covering, N::PercentageNerve) -> Graph

Construct a nerve graph where edges require a minimum percentage overlap.

For mode `:or`, at least one of `|A∩B|/|A|` or `|A∩B|/|B|` must be `>= N.p`.
For mode `:and`, both ratios must be `>= N.p`.

Overlap checks are performed in parallel using `Threads.@threads` over all
`(i, j)` pairs with `i < j`, writing to a pre-allocated `BitMatrix` before edges
are added serially.
"""
function make_graph(X::MetricSpace, cover::Covering, N::PercentageNerve)
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
        r_i = inter / length(a)
        r_j = inter / length(b)
        edge = if N.mode === :or
            max(r_i, r_j) >= N.p
        else  # :and
            min(r_i, r_j) >= N.p
        end
        if edge
            has_edge[i, j] = true
        end
    end

    g = SimpleGraph(n)
    for i in 1:n, j in (i+1):n
        has_edge[i, j] && add_edge!(g, i, j)
    end
    g
end

function TDAmapper.validate(n::PercentageNerve)
    0 < n.p < 1 || throw(MapperArgumentError("PercentageNerve — p must be in (0, 1), got $(n.p)"))
    n.mode in (:or, :and) || throw(MapperArgumentError("PercentageNerve — mode must be :or or :and, got $(n.mode)"))
    return nothing
end

@testitem "validate PercentageNerve" begin
    using TDAmapper
    using TDAmapper.Nerves
    @test_throws MapperArgumentError validate(PercentageNerve(0.0))
    @test_throws MapperArgumentError validate(PercentageNerve(1.0))
    @test_throws MapperArgumentError validate(PercentageNerve(0.5, :wrong))
    @test isnothing(validate(PercentageNerve(0.5)))
    @test isnothing(validate(PercentageNerve(0.3, :and)))
end
