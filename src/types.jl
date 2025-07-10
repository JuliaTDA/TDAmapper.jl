abstract type AbstractCover end

# All coverings return Vector{Vector{Int}} - indices into the original space
function make_cover(c::AbstractCover, args...)
    error("make_cover not implemented for $(typeof(C)). " *
          "Please implement: make_cover(::$(typeof(C))) -> Vector{Vector{Int}}")
end

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
    C::Covering
    g::Graph
end

@kwdef struct GeneralMapper <: AbstractMapper
    X::MetricSpace    
    C::Covering
    g::Graph
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
