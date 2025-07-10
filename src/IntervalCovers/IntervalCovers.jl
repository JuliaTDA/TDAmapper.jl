module IntervalCovers

using ..TDAmapper
using TestItems

abstract type AbstractIntervalCover end

# every AbstractIntervalCover must implement a method:
function (ic::AbstractIntervalCover)(x::Vector{<:Real})
    @error "Method not implemented for this class!"
end


export AbstractIntervalCover

include("uniform.jl")
export Uniform,
    uniform

end # module