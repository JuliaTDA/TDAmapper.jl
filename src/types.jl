"""
    AbstractCover

Abstract base type for all covering strategies.

A covering strategy defines how to partition or cover a metric space. Concrete 
subtypes must implement the `make_cover` method to generate the actual covering.

# Interface
All concrete cover types must implement:
- `make_cover(c::AbstractCover, args...) -> Vector{Vector{Int}}`

# See Also
- [`make_cover`](@ref): The interface method all covers must implement
"""
abstract type AbstractCover end

"""
    make_cover(c::AbstractCover, args...) -> Vector{Vector{Int}}

Generate a covering from the given cover strategy.

# Arguments
- `c::AbstractCover`: The covering strategy instance
- `args...`: Additional arguments specific to the covering type

# Returns
- `Vector{Vector{Int}}`: A covering represented as a vector of index vectors, 
  where each inner vector contains the indices of points in that cover element

# Description
This is the main interface method that all covering implementations must provide.
The covering is always represented as indices into the original metric space.

# Throws
- `MethodError`: If not implemented for the specific cover type

# Examples
```julia
# This will throw an error for the abstract type
# cover = make_cover(SomeCoverType())
```
"""
function make_cover(c::AbstractCover, args...)
    error("make_cover not implemented for $(typeof(c)). " *
          "Please implement: make_cover(::$(typeof(c))) -> Vector{Vector{Int}}")
end

# mapper superclass
"""
    AbstractMapper

Abstract base type for all mapper implementations.

Mapper objects represent the result of applying a mapper algorithm to a metric space,
containing the original space, covering, and resulting graph structure.

# Common Fields
All mapper implementations typically contain:
- `X::MetricSpace`: The original metric space
- `g::Graph`: The resulting mapper graph
- Additional fields specific to the mapper variant

# Subtypes
- [`Mapper`](@ref): Classical mapper implementation  
- [`BallMapper`](@ref): Ball mapper implementation
- [`GeneralMapper`](@ref): Generic mapper implementation
"""
abstract type AbstractMapper end

"""
    Mapper <: AbstractMapper

Represents the result of the classical mapper algorithm.

# Fields
- `X::MetricSpace`: The original metric space that was analyzed
- `C::Covering`: The final covering after refinement (as index vectors)
- `g::Graph`: The mapper graph representing the nerve of the covering

# Description
The `Mapper` struct encapsulates the result of applying the classical mapper algorithm
to a metric space. It contains both the structural information (covering and graph)
and references to the original data.

# Examples
```julia
using TDAmapper
# Assuming proper setup of covers, refiners, and nerves
# mapper_result = mapper(X, image_cover, refiner, nerve)
# println(mapper_result)  # Shows: "Mapper graph with N vertices and M edges"
```

# See Also
- [`mapper`](@ref): Function that creates Mapper objects
- [`BallMapper`](@ref): Alternative mapper implementation
"""
@kwdef struct Mapper <: AbstractMapper
    X::MetricSpace
    C::Covering
    g::Graph
end

"""
    BallMapper <: AbstractMapper

Represents the result of the ball mapper algorithm.

# Fields  
- `X::MetricSpace`: The original metric space that was analyzed
- `L::Vector{<:Integer}`: The landmark indices used for the ball covering
- `C::Covering`: The ball covering (as index vectors)
- `g::Graph`: The mapper graph representing the nerve of the ball covering

# Description
The `BallMapper` struct encapsulates the result of applying the ball mapper algorithm.
Unlike the classical mapper, it includes the landmark points (`L`) that define the
centers of the balls used in the covering.

# Examples
```julia
using TDAmapper
X = EuclideanSpace([[1.0, 2.0], [3.0, 4.0], [2.0, 3.0]])
L = [1, 3]  # Use points 1 and 3 as landmarks
mapper_result = ball_mapper(X, L, ϵ=1.5)
println(mapper_result)  # Shows: "Mapper graph with N vertices and M edges"
```

# See Also
- [`ball_mapper`](@ref): Function that creates BallMapper objects  
- [`Mapper`](@ref): Classical mapper implementation
"""
@kwdef struct BallMapper <: AbstractMapper
    X::MetricSpace
    L::Vector{<:Integer}
    C::Covering
    g::Graph
end

"""
    GeneralMapper <: AbstractMapper

Represents the result of a generic mapper algorithm.

# Fields
- `X::MetricSpace`: The original metric space that was analyzed
- `C::Covering`: The final covering after refinement (as index vectors)  
- `g::Graph`: The mapper graph representing the nerve of the covering

# Description
The `GeneralMapper` struct is used by the `generic_mapper` function to represent
the result of custom mapper implementations that combine different covering,
refinement, and nerve strategies.

# Examples
```julia
using TDAmapper
# Using custom covering, refinement, and nerve strategies
# mapper_result = generic_mapper(X, custom_cover, custom_refiner, custom_nerve)
# println(mapper_result)  # Shows: "Mapper graph with N vertices and M edges"
```

# See Also
- [`generic_mapper`](@ref): Function that creates GeneralMapper objects
- [`Mapper`](@ref): Classical mapper implementation
"""
@kwdef struct GeneralMapper <: AbstractMapper
    X::MetricSpace
    C::Covering
    g::Graph
end

"""
    Base.convert(::Type{T}, x::Vector{<:Vector{<:Any}}) where {T <: Covering}

Convert a vector of vectors to a Covering type.

This method converts nested vectors to the appropriate Covering format by ensuring
all inner vectors contain Int32 elements.
"""
function Base.convert(::Type{T}, x::Vector{<:Vector{<:Any}}) where {T <: Covering}
    [convert.(Int32, c) for c ∈ x]
end

"""
    Base.convert(::Type{T}, x::T) where {T <: Covering}

Identity conversion for Covering types.

This method handles the case where the input is already of the target Covering type.
"""
function Base.convert(::Type{T}, x::T) where {T <: Covering}
    x
end

import Graphs
"""
    Base.show(io::IO, M::AbstractMapper)

Display a concise summary of a mapper object.

# Arguments
- `io::IO`: The output stream
- `M::AbstractMapper`: The mapper object to display

# Description  
Shows a brief summary including the number of vertices and edges in the mapper graph.
This provides a quick overview of the mapper's complexity.

# Examples
```julia
# Output: "Mapper graph with 15 vertices and 23 edges"
```
"""
function Base.show(io::IO, M::AbstractMapper)
    print(io, "Mapper graph with $(Graphs.nv(M.g)) vertices and $(Graphs.ne(M.g)) edges")
end
