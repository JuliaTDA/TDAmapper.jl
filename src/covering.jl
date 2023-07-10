"""
    empty_covering(size)

Create an empty covering of size `size`
"""
function empty_covering(size)
    repeat([Int64[]], size)
end

"""
    uniform(x::Vector{<:Real}; length::Integer = 15, overlap::Real = 100)

Create an uniform covering of filter vector `x`. First we order `x` and then split it in `length` elements, then we create the overlaps.
"""
function uniform(
    x::Vector{<:Real}; length::Integer = 15, overlap::Real = 100
    )

    division = [range(min(x...), max(x...), length = length);]
    radius = (division[2] - division[1]) / 2
    radius_expanded = radius * (1 + overlap / 100)
    return [Interval(i - radius_expanded, i + radius) for i ∈ division]
end

function uniform(
    ;length::Integer = 15, overlap::Real = 100
    )
    return x -> uniform(x; length = length, overlap = overlap)
end

"""
    spaced

Create a space covering of the filter vector `x`.
"""
function spaced(
    x::Union{Vector{<:Real}, Nothing}; 
    length::Integer = 10, expansion::Real = 50, padding::Integer = 2
)  
    n = size(x)[1]

    x_ord = sort(x)
    v = range(1, n, length = length) |> collect .|> floor .|> Int32

    intervals = Interval[]

    for i ∈ eachindex(v)
        x_i = x_ord[v[i]]
        v_j = v[clamp(i - 1, 1, length)]
        v_k = v[clamp(i + 1, 1, length)]
        
        if padding > 0
            v_j = clamp(v_j - padding, 1, length)
            v_k = clamp(v_k + padding, 1, length)
        end

        x_j = x_ord[v_j]
        x_k = x_ord[v_k]

        r_j = (x_i - x_j) * (1 + expansion/100)
        r_k = (x_k - x_i) * (1 + expansion/100)
        
        push!(intervals, Interval(x_i - r_j, x_i + r_k))        
    end

    return intervals
end

function spaced(    
    ;length::Integer = 10, expansion::Real = 50, padding::Integer = 2
)  
    return x -> spaced(x; length = length, expansion = expansion, padding = padding)
end

# spaced(x; expansion = 10, padding = 0)