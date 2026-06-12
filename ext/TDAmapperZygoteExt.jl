"""
    TDAmapperZygoteExt

Package extension providing the [`optimize_filter`](@ref) method. Loads
automatically once both Zygote.jl and Optimisers.jl are available
(`using Zygote, Optimisers`).
"""
module TDAmapperZygoteExt

using TDAmapper
using TDAmapper: optimize_filter, total_persistence, node_filtration, LinearFilter
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: SimpleNerve
import Zygote
import Optimisers

"""
    optimize_filter(X, θ₀; filter=LinearFilter(), loss=total_persistence,
                    cover=Uniform(), refiner=Trivial(), nerve=SimpleNerve(),
                    optimizer=Optimisers.Adam(), n_epochs=200) -> (θ, history)

Gradient-tune the filter parameters `θ` to minimize `loss(g, v(θ))` over the
Mapper graph. Each epoch rebuilds the graph combinatorics at the current `θ`
(held fixed within the step) and backpropagates the loss through the node
filtration into `θ`. Returns the optimized `θ` and the per-epoch loss `history`.
Negate `loss` to *maximize* (e.g. `loss = (g, v) -> -total_persistence(g, v)`).
"""
function TDAmapper.optimize_filter(X::MetricSpace, θ₀::AbstractVector;
        filter = LinearFilter(), loss = total_persistence,
        cover = Uniform(), refiner = Trivial(), nerve = SimpleNerve(),
        optimizer = Optimisers.Adam(), n_epochs::Integer = 200)
    θ = collect(float.(θ₀))
    state = Optimisers.setup(optimizer, θ)
    history = Float64[]
    for _ in 1:n_epochs
        f_X = collect(float.(filter(X, θ)))           # concrete values for combinatorics
        M = TDAmapper.mapper(X, R1Cover(f_X, cover), refiner, nerve)
        members = M.C
        g = M.g
        L = θ_ -> loss(g, node_filtration(members, filter(X, θ_)))
        out = Zygote.withgradient(L, θ)
        push!(history, out.val)
        grad = out.grad[1]
        grad === nothing && break
        state, θ = Optimisers.update!(state, θ, grad)
    end
    return (θ = θ, history = history)
end

end # module
