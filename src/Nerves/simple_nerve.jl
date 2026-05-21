using Graphs

"""
    SimpleNerve

A basic nerve implementation that computes the 1-dimensional nerve of a covering.

The `SimpleNerve` struct represents the standard nerve construction for mapper algorithms,
where two elements of the covering are connected by an edge if their intersection is non-empty.

# See Also
- [`make_graph`](@ref): Constructs the nerve graph from a covering
- [`AbstractNerve`](@ref): Parent abstract type
"""
struct SimpleNerve <: AbstractNerve end

"""
    make_graph(X::MetricSpace, cover::Covering, N::SimpleNerve) -> Graph

Construct the 1-dimensional nerve graph of a covering using the SimpleNerve algorithm.

# Arguments
- `X::MetricSpace`: The metric space containing the data points
- `cover::Covering`: A covering of the metric space as a vector of index vectors
- `N::SimpleNerve`: The nerve algorithm instance

# Returns
- `Graph`: A graph where vertices correspond to cover elements and edges connect
  overlapping cover elements

# Description
This function implements the classical nerve construction: two cover elements are
connected by an edge if and only if their intersection is non-empty. This creates
the 1-skeleton of the nerve complex.

Intersection checks are performed in parallel using `Threads.@threads` over all
`(i, j)` pairs with `i < j`. Results are written to a pre-allocated `BitMatrix`
(each thread writes to a distinct cell — no locks needed), then edges are added
serially to the graph.

# Examples
```julia
using TDAmapper
X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
cover = [[1, 3], [2, 3]]  # Two overlapping clusters
nerve = SimpleNerve()
graph = make_graph(X, cover, nerve)
```
"""
function make_graph(X::MetricSpace, cover::Covering, N::SimpleNerve)
    n = length(cover)
    pairs = [(i, j) for i in 1:n for j in (i+1):n]

    has_edge = falses(n, n)
    Threads.@threads for k in eachindex(pairs)
        i, j = pairs[k]
        if !isempty(cover[i]) && !isempty(cover[j]) && !isempty(intersect(cover[i], cover[j]))
            has_edge[i, j] = true
        end
    end

    g = SimpleGraph(n)
    for i in 1:n, j in (i+1):n
        has_edge[i, j] && add_edge!(g, i, j)
    end
    g
end

TDAmapper.validate(::SimpleNerve) = nothing

@testitem "validate SimpleNerve" begin
    using TDAmapper
    using TDAmapper.Nerves
    @test isnothing(validate(SimpleNerve()))
end