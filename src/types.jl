using ProtoStructs

# metric space
PointCloud = Matrix{<:Real}

typejoin(PointCloud, Matrix{Integer})
typejoin(Int32, Float16)

# ids of coverings
CoveringIds = Vector{<:Vector{<:Integer}}

# real intervals
struct Interval
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


# vector of intervals
# IntervalCovering = Vector{Interval}

# covered space to use
struct CoveredSpace
    X::PointCloud
    covering_ids::CoveringIds

    # add some check here?

    CoveredSpace(X, covering_ids) = new(X, covering_ids)
end

# criar método específico pra quando coloca mais de um inteiro?
function get_cover_id(CS::CoveredSpace, id::Integer)
    return CS.covering_ids[id]
end

function get_points(CS::CoveredSpace, id::Integer)
    return CS.X[CS.covering_ids[id], :]
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
@kwdef mutable struct Mapper <: AbstractMapper
    X
    data
    filter_function
    filter_values
    covering
    covering_function
    clustering_function
    clustered_pb_ids
    node_origin
    mapper_graph
end







# CS = CoveredSpace([1 2 ; 3 4; 5 6], [[1], [2, 3]])
# get_cover_id(CS, 1)
# get_points(CS, 1)
# convert(CoveringIds, [[], [1]]) isa CoveringIds