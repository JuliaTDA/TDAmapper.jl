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

include("simple_nerve.jl")
export SimpleNerve

export AbstractArray,
    GraphNerve,
    make_graph

end # module