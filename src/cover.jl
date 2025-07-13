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