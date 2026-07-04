"""
    persistence_pairs(g, v) -> (birth_idx, death_idx)

Pairing of the 0-dimensional **sublevel** persistence of graph `g` filtered by
node values `v` (edge value = max of its endpoints; elder rule via union-find).
Returns vectors of **node indices** into `v`: each finite class is born at
`v[birth_idx[k]]` and dies at `v[death_idx[k]]`. The single essential class
(global minimum) is dropped. Non-differentiable (pure combinatorics).

Re-expressed as the ascending sweep of [`_persistence_pass`](@ref) (which also
recovers the extended-persistence families); see [`extended_persistence`](@ref).
"""
function persistence_pairs(g, v::AbstractVector)
    return _persistence_pass(g, v; ascending = true).ord_pairs
end

"""
    persistence_diagram(g, v) -> (births, deaths)

0-dimensional sublevel persistence diagram of `g` under node filtration `v`,
as value vectors. Differentiable in `v`: the pairing is computed inside
`@ignore_derivatives` and the values are gathered from `v` by indexing.
"""
function persistence_diagram(g, v::AbstractVector)
    pairs = ChainRulesCore.@ignore_derivatives persistence_pairs(g, v)
    return (births = v[pairs.birth_idx], deaths = v[pairs.death_idx])
end

"""
    total_persistence(g, v) -> Real

Sum of bar lengths of the 0-dimensional sublevel persistence of `g` under node
filtration `v`. Differentiable in `v`. An opt-in 0-dim-only loss for
`optimize_filter` (negate it to *maximize* topological signal).

Note: this is **ordinary 0-dimensional** persistence — it sees multi-minimum
(branch / tent) structure but **not loops** (H₁). On data whose mapper graph has
monotone node values it is identically zero, giving no gradient. Use
[`total_extended_persistence`](@ref) for a loop-aware loss (the default for
[`optimize_filter`](@ref)).
"""
function total_persistence(g, v::AbstractVector)
    d = persistence_diagram(g, v)
    return sum(abs.(d.deaths .- d.births))
end

@testitem "graph persistence — hand-computed barcode" begin
    using TDAmapper
    using Graphs

    g = path_graph(4)                     # edges (1,2),(2,3),(3,4)
    v = [1.0, 4.0, 0.5, 2.0]

    pairs = persistence_pairs(g, v)
    @test pairs.birth_idx == [1]
    @test pairs.death_idx == [2]

    d = persistence_diagram(g, v)
    @test d.births == [1.0]
    @test d.deaths == [4.0]

    @test total_persistence(g, v) ≈ 3.0

    # one local minimum (monotone) ⇒ no finite bars
    @test total_persistence(path_graph(4), [1.0, 2.0, 3.0, 4.0]) == 0.0
end

@testitem "graph persistence — gradient matches finite differences" begin
    using TDAmapper
    using Graphs
    using Zygote
    using FiniteDifferences

    g = path_graph(4)
    v = [1.0, 4.0, 0.5, 2.0]

    gz = Zygote.gradient(vv -> total_persistence(g, vv), v)[1]
    gfd = FiniteDifferences.grad(central_fdm(5, 1), vv -> total_persistence(g, vv), v)[1]

    @test gz ≈ [-1.0, 1.0, 0.0, 0.0] atol = 1e-6
    @test gz ≈ gfd atol = 1e-5
end
