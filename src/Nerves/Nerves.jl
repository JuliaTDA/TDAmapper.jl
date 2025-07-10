module Nerves

using MetricSpaces
abstract type AbstractNerve end

abstract type GraphNerve end

function make_graph(X::MetricSpace, cover::Covering, N::AbstractNerve)
    # message about the need to implement make_graph
end

include("simple_nerve.jl")
export SimpleNerve

export AbstractArray,
    GraphNerve,
    make_graph

end # module