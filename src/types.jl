using Graphs: AbstractGraph

# Interval is provided by MetricSpaces via @reexport

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
    Mapper{S<:MetricSpace, G} <: AbstractMapper

Represents the result of a classical or generic mapper algorithm.

# Type Parameters
- `S<:MetricSpace`: The concrete type of the metric space
- `G`: The concrete graph or simplicial-complex result type

# Fields
- `X::S`: The original metric space that was analyzed
- `C::Covering`: The final covering after refinement (as index vectors)
- `g::G`: The mapper graph representing the nerve of the covering

# Description
The `Mapper` struct is used by the `mapper` function to represent the result of mapper algorithms that combine different covering, refinement, and nerve strategies.

The type parameters allow Julia to specialize methods on concrete types for better performance.

# Example
```julia
using TDAmapper
# mapper_result = mapper(X, custom_cover, custom_refiner, custom_nerve)
# println(mapper_result)  # Output: "Mapper graph with N vertices and M edges"
```

# See Also
- [`mapper`](@ref): Function that creates generalized mapper objects
- [`ball_mapper`](@ref): Landmark-ball Mapper implementation
"""
@kwdef struct Mapper{S<:MetricSpace, G} <: AbstractMapper
    X::S
    C::Covering
    g::G
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
    try
        print(io, "Mapper graph with $(Graphs.nv(M.g)) vertices and $(Graphs.ne(M.g)) edges")
    catch
        print(io, "Mapper with $(typeof(M.g))")
    end
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
