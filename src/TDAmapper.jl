"""
# TDAmapper.jl

Mapper-like algorithms from Topological Data Analysis.

See https://juliatda.github.io/TDAmapper.jl/ for documentation.
"""
module TDAmapper

using ProgressMeter
using Reexport
@reexport using MetricSpaces

using TestItems
using Graphs
export Graph
using ChainRulesCore

import Base.Threads.@threads

# Error types and validate interface
include("errors.jl")
export MapperArgumentError, MapperDomainError, validate

# Type alias for coverings
const Covering = Vector{Vector{Int}}
export Covering


# Mapper types
include("types.jl")
export AbstractMapper, Mapper

# Tables.jl integration (methods provided by the TDAmapperTablesExt extension)
include("tables_interface.jl")
export euclidean_space, node_statistics

include("cover.jl")
export AbstractCover, make_cover

include("IntervalCovers/IntervalCovers.jl")
export IntervalCovers

include("ImageCovers/ImageCovers.jl")
export ImageCovers

include("DomainCovers/DomainCovers.jl")
export DomainCovers

include("Refiners/Refiners.jl")
export Refiners

include("Nerves/Nerves.jl")
export Nerves

include("mapper.jl")
export mapper

include("classical_mapper.jl")
export classical_mapper

include("ball_mapper.jl")
export ball_mapper

# Differentiable Mapper (Phase 5 Tier G)
include("differentiable/graph_persistence.jl")
export persistence_pairs, persistence_diagram, total_persistence

include("differentiable/soft_cover.jl")
export soft_membership

include("differentiable/filters.jl")
export LinearFilter

include("differentiable/soft_mapper.jl")
export soft_mapper, SoftMapper, node_filtration, optimize_filter

end # module