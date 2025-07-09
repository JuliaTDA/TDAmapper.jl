module IntervalCoverings

using ..TDAmapper
using TestItems

abstract type AbstractIntervalCovering end

export AbstractIntervalCovering

include("uniform.jl")
export Uniform,
    uniform

end