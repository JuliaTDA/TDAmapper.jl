# metric space
# abstract type AbstractPointCloud end
PointCloud = Matrix{<:Real} #<: AbstractPointCloud

# ids of coverings
CoveringIds = Vector{<:Vector{<:Integer}}

# real intervals
# abstract type AbstractInterval end
struct Interval #<: AbstractInterval
    a::Float32
    b::Float32
    Interval(a, b) = a <= b ? new(a, b) : error("we can't have a > b!")
end

function Base.in(x::Real, i::Interval)
    i.a <= x <= i.b
end

# interval intersection
function intersect(i::Interval, j::Interval)
    (i.a <= j.a <= i.b) || (i.a <= j.b <= i.b)
end

function Base.convert(::Type{T}, x::Vector{<:Vector{<:Any}}) where {T <: CoveringIds}
    [convert.(Int32, c) for c ∈ x]
end

function Base.convert(::Type{T}, x::T) where {T <: CoveringIds}
    x
end

# mapper superclass
abstract type AbstractMapper end

# classic mapper
@kwdef struct Mapper #<: AbstractMapper
    X::PointCloud
    filter_values::Vector{<:Number}
    covering_intervals::Vector{<:Interval}
    clustering::Function
    clustered_pb_ids
    node_origin
    adj_matrix
    mapper_graph::Graph
end

function Base.show(io::IO, mp::Mapper)
    print(io, "Mapper graph of X")
end
