module TDAmapperLuxExt
using TDAmapper
using ChainRulesCore
import Lux
import Random

struct LuxMapperFilter{M,S}
    model::M
    state::S
end
function TDAmapper.lux_filter(model;rng=Random.default_rng())
    parameters,state=Lux.setup(rng,model)
    return (filter=LuxMapperFilter(model,Lux.testmode(state)),parameters=parameters)
end
function (f::LuxMapperFilter)(X,parameters)
    P=ChainRulesCore.@ignore_derivatives reduce(hcat,collect(X))
    y,newstate=Lux.apply(f.model,P,parameters,f.state)
    unchanged=ChainRulesCore.@ignore_derivatives isequal(newstate,f.state)
    unchanged || throw(ArgumentError("Lux model changed its fixed inference state"))
    size(y)==(1,length(X)) || throw(ArgumentError("Lux filter must produce one scalar per point"))
    return vec(y)
end
end
