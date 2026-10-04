"""
    TDAmapperZygoteExt

Package extension providing the [`optimize_filter`](@ref) method. Loads
automatically once both Zygote.jl and Optimisers.jl are available
(`using Zygote, Optimisers`).
"""
module TDAmapperZygoteExt

using TDAmapper
using TDAmapper: optimize_filter, total_extended_persistence, node_filtration, LinearFilter
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: SimpleNerve
import Zygote
import Optimisers
import Graphs

"""
    optimize_filter(X, θ₀; filter=LinearFilter(), loss=total_extended_persistence,
                    cover=Uniform(), refiner=Trivial(), nerve=SimpleNerve(),
                    optimizer=Optimisers.Adam(), n_epochs=200,
                    regularizer=θ -> 0.0) -> (θ, history)

Gradient-tune an explicit parameter vector or tree `θ` to minimize
`loss(g, v(θ)) + regularizer(θ)` over the
Mapper graph. Each epoch rebuilds the graph combinatorics at the current `θ`
(held fixed within the step) and backpropagates the loss through the node
filtration into `θ`. Empty cover elements are omitted from the loss graph, since
they have no node mean. Returns the optimized `θ` and the per-epoch loss `history`.

The default loss is [`total_extended_persistence`](@ref) — loop-aware
(Ord0/Ext0/Ext1), so filter optimization has a gradient even where ordinary
0-dim persistence is identically zero (e.g. a circular dataset whose mapper
graph is a loop). Pass `loss = total_persistence` for the ordinary 0-dim-only
behavior, and negate any loss to *maximize*
(e.g. `loss = (g, v) -> -total_extended_persistence(g, v)`).
"""
function TDAmapper.optimize_filter(X::MetricSpace, θ₀;
        filter = LinearFilter(), loss = total_extended_persistence,
        cover = Uniform(), refiner = Trivial(), nerve = SimpleNerve(),
        optimizer = Optimisers.Adam(), n_epochs::Integer = 200,
        regularizer = θ -> 0.0)
    n_epochs > 0 || throw(ArgumentError("n_epochs must be positive"))
    θ = θ₀ isa AbstractVector ? collect(float.(θ₀)) : deepcopy(θ₀)
    state = Optimisers.setup(optimizer, θ)
    history = Float64[]
    for _ in 1:n_epochs
        f_X = collect(float.(filter(X, θ)))           # concrete values for combinatorics
        length(f_X)==length(X) && all(isfinite,f_X) ||
            throw(ArgumentError("filter must return one finite scalar per input point"))
        M = TDAmapper.mapper(X, R1Cover(f_X, cover), refiner, nerve)
        nonempty = findall(c -> !isempty(c), M.C)
        members = M.C[nonempty]
        g = first(Graphs.induced_subgraph(M.g, nonempty))
        L = θ_ -> loss(g, node_filtration(members, filter(X, θ_))) + regularizer(θ_)
        out = Zygote.withgradient(L, θ)
        isfinite(out.val) || throw(ArgumentError("filter objective must remain finite"))
        push!(history, out.val)
        grad = out.grad[1]
        grad === nothing && break
        state, θ = Optimisers.update(state, θ, grad)
    end
    return (θ = θ, history = history)
end

end # module
