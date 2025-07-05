abstract type AbstractMapperGraph end

# mapper superclass
abstract type AbstractMapper end

# classic mapper
@kwdef struct Mapper <: AbstractMapper
    X::MetricSpace
    C::Covering
    g::Graph
end

# classic mapper
@kwdef struct BallMapper <: AbstractMapper
    X::MetricSpace
    L::Vector{<:Integer}
    graph::Graph
end

function Base.convert(::Type{T}, x::Vector{<:Vector{<:Any}}) where {T <: Covering}
    [convert.(Int32, c) for c ∈ x]
end

function Base.convert(::Type{T}, x::T) where {T <: Covering}
    x
end

import Graphs
function Base.show(io::IO, M::AbstractMapper)
    print(io, "Mapper graph with $(Graphs.nv(M.g)) vertices and $(Graphs.ne(M.g)) edges")
end
