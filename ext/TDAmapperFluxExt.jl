module TDAmapperFluxExt
using TDAmapper
using ChainRulesCore
import Flux
import Optimisers

struct FluxMapperFilter{R}
    rebuild::R
end
function TDAmapper.flux_filter(model)
    # Limit the public adapter to deterministic feed-forward Dense chains.
    valid(m::Flux.Dense)=true
    valid(m::Flux.Chain)=all(valid,m.layers)
    valid(m)=false
    valid(model) || throw(ArgumentError("Flux adapter supports Dense and nested Dense Chains only"))
    parameters,rebuild=Optimisers.destructure(model)
    return (filter=FluxMapperFilter(rebuild),parameters=parameters)
end
function (f::FluxMapperFilter)(X,parameters)
    P=ChainRulesCore.@ignore_derivatives reduce(hcat,collect(X))
    y=f.rebuild(parameters)(P)
    size(y)==(1,length(X)) || throw(ArgumentError("Flux filter must produce one scalar per point"))
    return vec(y)
end
end
