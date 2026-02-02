
# Mapper superclass
"""
    AbstractMapper

Abstract base type for all mapper implementations.

Mapper objects represent the result of applying a mapper algorithm to a metric space, containing the original space, covering, and resulting graph structure.

# Common Fields
All mapper implementations typically contain:
- `X::MetricSpace`: The original metric space
- `g::Graph`: The resulting mapper graph
- Additional fields specific to the mapper variant

# Subtypes
- [`Mapper`](@ref): Generalized mapper implementation
"""
abstract type AbstractMapper end

"""
    Mapper <: AbstractMapper

Represents the result of a classical or generic mapper algorithm.

# Fields
- `X::MetricSpace`: The original metric space that was analyzed
- `C::Covering`: The final covering after refinement (as index vectors)
- `g::Graph`: The mapper graph representing the nerve of the covering

# Description
The `Mapper` struct is used by the `mapper` function to represent the result of mapper algorithms that combine different covering, refinement, and nerve strategies.

# Example
```julia
using TDAmapper
# mapper_result = generic_mapper(X, custom_cover, custom_refiner, custom_nerve)
# println(mapper_result)  # Output: "Mapper graph with N vertices and M edges"
```

# See Also
- [`generic_mapper`](@ref): Function that creates generalized mapper objects
- [`BallMapper`](@ref): BallMapper implementation
"""
@kwdef struct Mapper <: AbstractMapper
    X::MetricSpace
    C::Covering
    g::Graph
end


"""
    Base.convert(::Type{T}, x::Vector{<:Vector{<:Any}}) where {T <: Covering}

Convert a vector of vectors to a `Covering` type.

This method ensures all inner vectors are converted to contain `Int32` elements, suitable for use as a covering.
"""
function Base.convert(::Type{T}, x::Vector{<:Vector{<:Any}}) where {T <: Covering}
    [convert.(Int, c) for c ∈ x]
end


"""
    Base.convert(::Type{T}, x::T) where {T <: Covering}

Identity conversion for `Covering` types.

Returns the input unchanged if it is already of the target `Covering` type.
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
Prints a brief summary including the number of vertices and edges in the mapper graph, providing a quick overview of the graph's complexity.

# Example
```julia
# Output: "Mapper graph with 15 vertices and 23 edges"
```
"""
function Base.show(io::IO, M::AbstractMapper)
    print(io, "Mapper graph with $(Graphs.nv(M.g)) vertices and $(Graphs.ne(M.g)) edges")
end

@testitem "Mapper types" begin
    using TDAmapper
    using Graphs

    # Test Covering type conversion
    x = [[1, 2, 3], [4, 5]]
    c = convert(Covering, x)
    @test c == [[1, 2, 3], [4, 5]]
    @test eltype(c[1]) == Int

    # Test identity conversion
    c2 = convert(Covering, c)
    @test c2 === c

    # Test Mapper struct creation
    X = [1.0, 2.0, 3.0] |> EuclideanSpace
    C = [[1, 2], [2, 3]]
    g = SimpleGraph(2)
    add_edge!(g, 1, 2)

    M = Mapper(X=X, C=C, g=g)
    @test M.X == X
    @test M.C == C
    @test Graphs.nv(M.g) == 2
    @test Graphs.ne(M.g) == 1

    # Test show method
    io = IOBuffer()
    show(io, M)
    output = String(take!(io))
    @test occursin("Mapper graph", output)
    @test occursin("2 vertices", output)
    @test occursin("1 edge", output)
end
