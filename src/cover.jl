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

"""
    empty_cover(size::Integer)

Create a vector of empty integer arrays of length `size`.

# Arguments
- `size::Integer`: The number of empty arrays to create. Must be a non-negative integer.

# Returns
A vector of length `size`, where each element is an empty `Int64` array.

# Throws
- AssertionError: if `size` is negative.
"""
function empty_cover(size::Integer)
    @assert size >= 0 "`size` must be a non-negative integer!"
    repeat([Int64[]], size)
end

@testitem "empty_cover" begin
    @test TDAmapper.empty_cover(0) == []
    @test TDAmapper.empty_cover(1) == [[]]
    @test TDAmapper.empty_cover(3) == [[], [], []]
    @test length(TDAmapper.empty_cover(10)) == 10
end