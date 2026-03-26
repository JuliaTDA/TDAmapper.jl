module IntervalCovers

using ..TDAmapper
using TestItems

abstract type AbstractIntervalCover end

# every AbstractIntervalCover must implement a method:
function (::AbstractIntervalCover)(x::Vector{<:Real})
    @error "Method not implemented for this class!"
end


export AbstractIntervalCover

include("uniform.jl")
export Uniform,
    uniform

include("quantile.jl")
export QuantileCover,
    quantile_cover

include("manual.jl")
export ManualCover,
    manual_cover

include("logarithmic.jl")
export LogarithmicCover,
    logarithmic_cover

include("adaptive.jl")
export AdaptiveCover,
    adaptive_cover

include("dyadic.jl")
export DyadicCover,
    dyadic_cover

end # module