module Refiners
using ..TDAmapper
using TestItems

abstract type AbstractRefiner end
export AbstractRefiner

# function refine(X::MetricSpace, C::Covering, R::AbstractRefiner)
#     #! message about the need to implement this method for every
#     # subtype of AbstractRefiner
# end

include("common.jl")
export create_outlier_cluster,
    refine_cover

include("dbscan.jl")
export DBscan

include("trivial.jl")
export Trivial

end