"""
    MLPFilter(widths; activation=tanh)

A small explicit-parameter feed-forward Mapper filter. `widths` includes input
and output sizes and must end in 1. Parameters are a NamedTuple of layer weight
matrices/bias vectors, returned by `initial_parameters(filter; rng)`. The output
layer is linear. This filter differentiates through its parameters, holding input
points fixed, and works with `optimize_filter` using the Zygote/Optimisers extension.
"""
struct MLPFilter{F}
    widths::Vector{Int}
    activation::F
    function MLPFilter(widths;activation=tanh)
        w=collect(Int,widths)
        length(w)>=2 && all(>(0),w) && last(w)==1 || throw(ArgumentError("positive widths ending in one required"))
        new{typeof(activation)}(w,activation)
    end
end

"""Xavier-normal MLP parameters, with explicit RNG and optional floating-point type."""
function initial_parameters(f::MLPFilter;rng=Random.default_rng(),T=Float64)
    T<:AbstractFloat || throw(ArgumentError("T must be a floating-point type"))
    layers=Tuple((weight=T.(Random.randn(rng,b,a).*sqrt(2/(a+b))),bias=zeros(T,b))
        for (a,b) in zip(f.widths[1:end-1],f.widths[2:end]))
    return (layers=layers,)
end

function (f::MLPFilter)(X,parameters::NamedTuple)
    P=ChainRulesCore.@ignore_derivatives reduce(hcat,collect(X))
    size(P,1)==first(f.widths) || throw(ArgumentError("input dimension differs from filter"))
    length(parameters.layers)==length(f.widths)-1 || throw(ArgumentError("wrong number of parameter layers"))
    for (i,layer) in enumerate(parameters.layers)
        P=layer.weight*P .+ layer.bias
        i<length(parameters.layers) && (P=f.activation.(P))
    end
    return vec(P)
end

"""
    flux_filter(model)

Return `(filter, parameters)` for a Flux model with one output per input point.
Requires Flux and Optimisers. Trainable parameters are flattened explicitly;
nontrainable model structure is retained by Optimisers.destructure. Use stateless
Dense/Chain models: dropout, batch normalization and mutable recurrent state are
not supported by this adapter.
"""
function flux_filter end

"""
    lux_filter(model; rng=Random.default_rng())

Return `(filter, parameters)` from Lux.setup, with explicit parameter trees and
a fixed inference-mode state. Models changing that state are rejected; this
prevents hidden state updates across Mapper graph rebuilds. Requires Lux.
"""
function lux_filter end
