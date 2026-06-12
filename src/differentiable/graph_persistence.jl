"""
    persistence_pairs(g, v) -> (birth_idx, death_idx)

Pairing of the 0-dimensional **sublevel** persistence of graph `g` filtered by
node values `v` (edge value = max of its endpoints; elder rule via union-find).
Returns vectors of **node indices** into `v`: each finite class is born at
`v[birth_idx[k]]` and dies at `v[death_idx[k]]`. The single essential class
(global minimum) is dropped. Non-differentiable (pure combinatorics).
"""
function persistence_pairs(g, v::AbstractVector)
    n = length(v)
    parent = collect(1:n)
    function find(x)
        while parent[x] != x
            parent[x] = parent[parent[x]]
            x = parent[x]
        end
        return x
    end

    birth_val = collect(float.(v))    # per-root: min value in the component
    birth_node = collect(1:n)         # per-root: node index achieving that min

    es = collect(Graphs.edges(g))
    evals = [max(v[Graphs.src(e)], v[Graphs.dst(e)]) for e in es]
    order = sortperm(evals)

    birth_idx = Int[]
    death_idx = Int[]
    for k in order
        e = es[k]
        a = Graphs.src(e)
        b = Graphs.dst(e)
        ra = find(a)
        rb = find(b)
        ra == rb && continue
        # elder rule: the component with the larger birth value is the younger one and dies
        older, younger = birth_val[ra] <= birth_val[rb] ? (ra, rb) : (rb, ra)
        if evals[k] > birth_val[younger]
            dnode = v[a] >= v[b] ? a : b      # endpoint realizing the edge value
            push!(birth_idx, birth_node[younger])
            push!(death_idx, dnode)
        end
        parent[younger] = older               # older keeps its (smaller) birth_val/birth_node
    end
    return (birth_idx = birth_idx, death_idx = death_idx)
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
filtration `v`. Differentiable in `v`. Default loss for `optimize_filter`
(negate it to *maximize* topological signal).
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
