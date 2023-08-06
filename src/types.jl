# the indexes of a subset of points
SubsetIndex = Vector{<:Integer}

Covering = Vector{<:SubsetIndex}

PointCloud = Matrix{<:Real}

struct CoveredPointCloud
    X::PointCloud
    covering::Covering
end

abstract type AbstractMapperGraph end

@kwdef struct MapperGraph
    CX::CoveredPointCloud
    g::Graph
end

# mappper and ball mapper covering
# métodos para criar covering
# métodos para criar grafo



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

function Base.convert(::Type{T}, x::Vector{<:Vector{<:Any}}) where {T <: Covering}
    [convert.(Int32, c) for c ∈ x]
end

function Base.convert(::Type{T}, x::T) where {T <: Covering}
    x
end

# mapper superclass
abstract type AbstractMapper end

# classic mapper
@kwdef struct Mapper <: AbstractMapper
    CX::CoveredPointCloud
    graph::Graph
end

# classic mapper
@kwdef struct BallMapper <: AbstractMapper
    CX::CoveredPointCloud
    L::Vector{<:Integer}
    graph::Graph
end

function Base.show(io::IO, mp::AbstractMapper)
    print(io, "Mapper graph of X")
end
