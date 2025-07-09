"""
    empty_covering(size::Integer)

Create a vector of empty integer arrays of length `size`.

# Arguments
- `size::Integer`: The number of empty arrays to create. Must be a non-negative integer.

# Returns
A vector of length `size`, where each element is an empty `Int64` array.

# Throws
- AssertionError: if `size` is negative.
"""
function empty_covering(size::Integer)
    @assert size >= 0 "`size` must be a non-negative integer!"
    repeat([Int64[]], size)
end

@testitem "empty_covering" begin
    @test TDAmapper.empty_covering(0) == []
    @test TDAmapper.empty_covering(1) == [[]]
    @test TDAmapper.empty_covering(3) == [[], [], []]
    @test length(TDAmapper.empty_covering(10)) == 10
end

"""
    uniform(x::Vector{<:Real}; length::Integer = 15, overlap::Real = 100)

Create an uniform covering of filter vector `x`. First we order `x` and then split it in `length` elements, then we create the overlaps.
"""
function uniform(
    x::Vector{<:Real}
    ; length::Integer=10, expansion::Real=0.25
)
    @assert length > 1 "`length` must be greater than 1!"
    
    division = range(extrema(x)..., length=length)
    radius = ((division[2] - division[1]) / 2) * (1 + expansion)

    return [Interval(i - radius, i + radius) for i ∈ division]
end

@testitem "uniform" begin
    using TDAmapper
    x = [0, 1]
    @test_throws AssertionError uniform(x, length = 1)
    
    cover = uniform(x, length = 2, expansion = 0)
    @test cover == [Interval(-0.5, 0.5), Interval(0.5, 1.5)]

    cover = uniform(x, length = 2, expansion = 1)
    @test cover == [Interval(-1.0, 1.0), Interval(0.0, 2.0)]
    
    for expansion ∈ [0:0.1:1;]
        local cover = uniform(x, length = 2, expansion = expansion)
        @test abs(cover[1].b - cover[2].a) ≈ expansion        
    end

    cover = uniform([1,10], length = 10, expansion = 1)
    @test length(cover) == 10
    @test cover[1] == Interval(0.0, 2.0)
end


# function spaced(
#     x::Vector{<:Real}
#     ; length::Integer=10, expansion::Real=50, padding::Integer=2
# )
#     n = size(x)[1]

#     x_ord = sort(x)
#     v = range(1, n, length=length) |> collect .|> floor .|> Int32

#     intervals = Interval[]

#     for i ∈ eachindex(v)
#         x_i = x_ord[v[i]]
#         v_j = v[clamp(i - 1, 1, length)]
#         v_k = v[clamp(i + 1, 1, length)]

#         if padding > 0
#             v_j = clamp(v_j - padding, 1, length)
#             v_k = clamp(v_k + padding, 1, length)
#         end

#         x_j = x_ord[v_j]
#         x_k = x_ord[v_k]

#         r_j = (x_i - x_j) * (1 + expansion / 100)
#         r_k = (x_k - x_i) * (1 + expansion / 100)

#         push!(intervals, Interval(x_i - r_j, x_i + r_k))
#     end

#     return intervals
# end
