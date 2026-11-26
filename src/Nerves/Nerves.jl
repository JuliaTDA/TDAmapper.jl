"""
    Nerves

A module containing nerve implementations for constructing graphs from coverings.

The nerve of a covering is a simplicial complex that captures the intersection 
structure of the covering elements. In the context of mapper algorithms, we 
typically use the 1-skeleton (graph) of this nerve.

# Exports
- [`AbstractNerve`](@ref): Abstract base type for nerve implementations
- [`GraphNerve`](@ref): Abstract type for nerves that produce graphs
- [`SimpleNerve`](@ref): Basic nerve implementation
- [`make_graph`](@ref): Function to construct graphs from coverings

# Types
The module defines two abstract types:
- `AbstractNerve`: Base type for all nerve implementations
- `GraphNerve`: Specialized for nerves that produce graph structures

# Interface
All concrete nerve types must implement:
- `make_graph(X::MetricSpace, cover::Covering, N::AbstractNerve) -> Graph`
"""
module Nerves

using MetricSpaces
using Graphs: SimpleGraph, add_edge!
using TestItems
import ..TDAmapper
using ..TDAmapper: Covering, MapperArgumentError

"""
    AbstractNerve

Abstract base type for all nerve implementations.

Nerve implementations define how to construct a simplicial complex (or its skeleton) 
from a covering of a metric space. Concrete subtypes must implement the `make_graph` 
method.
"""
abstract type AbstractNerve end

"""
    GraphNerve

Abstract type for nerve implementations that produce graph structures.

This is a specialized type of `AbstractNerve` for implementations that construct 
the 1-skeleton (graph) of the nerve complex.
"""
abstract type GraphNerve end

"""
    make_graph(X::MetricSpace, cover::Covering, N::AbstractNerve) -> Graph

Construct a graph from a covering using the specified nerve algorithm.

# Arguments
- `X::MetricSpace`: The metric space containing the data points
- `cover::Covering`: A covering of the metric space
- `N::AbstractNerve`: The nerve algorithm to use

# Returns
- `Graph`: The resulting nerve graph

# Description
This is the main interface function that all nerve implementations must provide. 
The specific algorithm used depends on the concrete type of `N`.

# Note
This is an interface method. Concrete implementations must override this method 
for their specific nerve type.
"""
function make_graph(X::MetricSpace, cover::Covering, N::AbstractNerve)
    error("make_graph not implemented for $(typeof(N)). " *
          "Please implement: make_graph(::MetricSpace, ::Covering, ::$(typeof(N))) -> Graph")
end

# Index each point once per set, then count overlaps one row at a time.
function _overlap_graph(accept, cover::Covering)
    memberships = Dict{Int,Vector{Int}}()
    for (i, points) in enumerate(cover), point in points
        sets = get!(Vector{Int}, memberships, point)
        if isempty(sets) || last(sets) != i
            push!(sets, i)
        end
    end

    graph = SimpleGraph(length(cover))
    counts = zeros(Int, length(cover))
    touched = Int[]
    seen = Set{Int}()
    for (i, points) in enumerate(cover)
        empty!(seen)
        for point in points
            point in seen && continue
            push!(seen, point)
            sets = memberships[point]
            for k in (searchsortedlast(sets, i) + 1):length(sets)
                j = sets[k]
                iszero(counts[j]) && push!(touched, j)
                counts[j] += 1
            end
        end
        for j in touched
            accept(counts[j], length(points), length(cover[j])) && add_edge!(graph, i, j)
            counts[j] = 0
        end
        empty!(touched)
    end
    return graph
end

include("simple_nerve.jl")
include("min_count_nerve.jl")
include("percentage_nerve.jl")
include("jaccard_nerve.jl")
include("simplicial_complex.jl")
include("simplicial_nerve.jl")

export AbstractNerve,
    GraphNerve,
    SimpleNerve,
    MinCountNerve,
    PercentageNerve,
    JaccardNerve,
    SimplicialComplex,
    SimplicialNerve,
    n_vertices, n_edges, n_triangles, dim,
    make_graph

end # module