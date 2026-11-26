# Maintain a maximum spanning forest of the edges seen in ascending birth
# order. The weight of an edge is the smaller of its two vertex heights.
# At every lower cutoff d, the forest edges of weight ≥ d span exactly the
# components of the graph restricted to that band of heights. A closing
# edge thus adds one band cycle for every d up to the minimum on its forest
# path (including its endpoints). That cutoff is the extended death.
function _close_loop!(forest, heights, a, b)
    parents = Graphs.bfs_parents(forest, a)
    death = heights[a] <= heights[b] ? a : b
    weakest_edge = (a, b)
    node = b
    while node != a
        parent = parents[node]
        lower = heights[node] <= heights[parent] ? node : parent
        if heights[lower] < heights[death]
            death = lower
            weakest_edge = (node, parent)
        end
        node = parent
    end
    if weakest_edge != (a, b)
        Graphs.rem_edge!(forest, weakest_edge...)
        Graphs.add_edge!(forest, a, b)
    end
    return death
end

"""
    _persistence_pass(g, v; ascending, pair_loops=false)

One union-find sweep over the edges of `g` filtered by node values `v`. Pure
combinatorics (non-differentiable); everything is returned as **node indices**
into `v` so the caller can gather differentiable values.

- `ascending=true`: edge value `= max(v[u], v[w])`, processed ascending, elder
  rule with component birth `= min` value. `ord_pairs` `= (birth_idx, death_idx)`
  of the positive-persistence merges (the existing [`persistence_pairs`] pairing:
  birth `=` younger component's min node, death `=` higher endpoint of the merging
  edge). `neg_nodes` `=` higher-endpoint node of each **negative** edge (cycle
  creator ⇒ H₁ birth). `roots` `=` final union-find root per node; `comp_min` /
  `comp_max` `=` node index achieving the min / max value in the component of each
  root.
- `ascending=false`: edge value `= min(v[u], v[w])`, processed descending;
  `neg_nodes` `=` lower-endpoint node of each negative edge (H₁ death). The other
  outputs are unused by callers.
"""
function _persistence_pass(g, v::AbstractVector; ascending::Bool, pair_loops::Bool=false)
    n = length(v)
    parent = collect(1:n)
    function find(x)
        while parent[x] != x
            parent[x] = parent[parent[x]]
            x = parent[x]
        end
        return x
    end

    # per-root elder value/node (min for ascending, max for descending) and
    # per-root extremes of the whole component (by absolute node value).
    birth_node = collect(1:n)
    comp_min = collect(1:n)   # node index of the component minimum value
    comp_max = collect(1:n)   # node index of the component maximum value

    es = collect(Graphs.edges(g))
    if ascending
        evals = [max(v[Graphs.src(e)], v[Graphs.dst(e)]) for e in es]
        order = sortperm(evals)
    else
        evals = [min(v[Graphs.src(e)], v[Graphs.dst(e)]) for e in es]
        order = sortperm(evals; rev = true)
    end

    birth_idx = Int[]
    death_idx = Int[]
    neg_nodes = Int[]
    loop_deaths = Int[]
    forest = pair_loops ? Graphs.SimpleGraph(n) : nothing
    for k in order
        e = es[k]
        a = Graphs.src(e)
        b = Graphs.dst(e)
        ra = find(a)
        rb = find(b)
        if ra == rb
            # negative edge: closes a cycle. Ascending ⇒ H₁ born at the higher
            # endpoint; descending ⇒ H₁ dies at the lower endpoint.
            if ascending
                push!(neg_nodes, v[a] >= v[b] ? a : b)
                if pair_loops
                    push!(loop_deaths, _close_loop!(forest, v, a, b))
                end
            else
                push!(neg_nodes, v[a] <= v[b] ? a : b)
            end
            continue
        end
        if pair_loops
            Graphs.add_edge!(forest, a, b)
        end
        # positive edge: merge the two components (elder rule).
        if ascending
            older, younger = v[birth_node[ra]] <= v[birth_node[rb]] ? (ra, rb) : (rb, ra)
            if evals[k] > v[birth_node[younger]]
                dnode = v[a] >= v[b] ? a : b      # endpoint realizing the edge value
                push!(birth_idx, birth_node[younger])
                push!(death_idx, dnode)
            end
        else
            older, younger = v[birth_node[ra]] >= v[birth_node[rb]] ? (ra, rb) : (rb, ra)
        end
        parent[younger] = older               # elder keeps its birth_val/birth_node
        v[comp_min[younger]] < v[comp_min[older]] && (comp_min[older] = comp_min[younger])
        v[comp_max[younger]] > v[comp_max[older]] && (comp_max[older] = comp_max[younger])
    end

    roots = [find(i) for i in 1:n]
    return (ord_pairs = (birth_idx = birth_idx, death_idx = death_idx),
            neg_nodes = neg_nodes, loop_deaths = loop_deaths,
            roots = roots,
            comp_min = comp_min,
            comp_max = comp_max)
end

"""
    _extended_pairs(g, v) -> (ord0, ext0, ext1)

Extended-persistence pairing of the graph `g` under node filtration `v`, as node
indices into `v` (pure combinatorics; call inside `@ignore_derivatives`).

- `ord0` — ascending ordinary 0-dim pairs (branches).
- `ext0` — one bar per connected component, `(min-node, max-node)` (per-component
  spread).
- `ext1` — loops, paired by the maximum spanning forest on each ascending
  prefix. For the total-length loss only, two union-find sweeps give the two
  endpoint multisets without building that forest.
"""
function _extended_pairs(g, v::AbstractVector; pair_loops::Bool=true)
    asc = _persistence_pass(g, v; ascending=true, pair_loops)
    ord0 = asc.ord_pairs

    rs = unique(asc.roots)
    ext0 = (birth_idx = [asc.comp_min[r] for r in rs],
            death_idx = [asc.comp_max[r] for r in rs])

    if pair_loops
        order = sortperm(v[asc.neg_nodes]; rev=true)
        ext1 = (birth_idx=asc.neg_nodes[order], death_idx=asc.loop_deaths[order])
    else
        desc = _persistence_pass(g, v; ascending=false)
        ext1 = (birth_idx=asc.neg_nodes, death_idx=desc.neg_nodes)
    end

    return (ord0 = ord0, ext0 = ext0, ext1 = ext1)
end

"""
    extended_persistence(g, v) -> (ord0, ext0, ext1)

Extended-persistence diagram of the graph `g` under node filtration `v`. Each
family is a differentiable `(births, deaths)` pair of value vectors gathered from
`v`; the discrete pairing is computed inside `@ignore_derivatives`.

- `ord0` — ordinary 0-dim (branches), births ≤ deaths.
- `ext0` — per-component spread, `births = min` value, `deaths = max` value.
- `ext1` — loops (H₁), `births = high` value, `deaths = low` value (born high,
  die low, so the bar length is `births − deaths`).
"""
function extended_persistence(g, v::AbstractVector)
    p = ChainRulesCore.@ignore_derivatives _extended_pairs(g, v)
    return _extended_values(p, v)
end

function _extended_values(p, v)
    ord0 = (births = v[p.ord0.birth_idx], deaths = v[p.ord0.death_idx])
    ext0 = (births = v[p.ext0.birth_idx], deaths = v[p.ext0.death_idx])
    ext1 = (births = v[p.ext1.birth_idx], deaths = v[p.ext1.death_idx])
    return (ord0 = ord0, ext0 = ext0, ext1 = ext1)
end

"""
    total_extended_persistence(g, v; dims=(0, 1)) -> Real

Total extended persistence of the graph `g` under node filtration `v` — the
loop-aware default loss for [`optimize_filter`](@ref). Differentiable in `v`
(negate to *maximize* topological signal).

Sum of bar lengths over the selected homology `dims`:

- `0` → Ord0 + Ext0 (branches and per-component spread),
- `1` → Ext1 (loops / H₁), computed as `Σbirths − Σdeaths`
  from the endpoint multisets without building the individual pairs.

Unlike ordinary [`total_persistence`](@ref), this sees loops: on data whose
mapper graph is a cycle it is strictly positive, giving a usable gradient where
0-dim persistence is identically zero.
"""
function total_extended_persistence(g, v::AbstractVector; dims = (0, 1))
    p = ChainRulesCore.@ignore_derivatives _extended_pairs(g, v; pair_loops=false)
    ep = _extended_values(p, v)
    dim0 = sum(ep.ord0.deaths .- ep.ord0.births) + sum(ep.ext0.deaths .- ep.ext0.births)
    dim1 = sum(ep.ext1.births) - sum(ep.ext1.deaths)
    return (0 in dims ? dim0 : zero(dim0)) + (1 in dims ? dim1 : zero(dim1))
end

@testitem "extended persistence — ring (hand-computed Ord0/Ext0/Ext1)" begin
    using TDAmapper
    using Graphs

    # 4-node ring with heights [0,1,2,1]: Ord0 = 0, Ext0 = 2, Ext1 = 2.
    g = cycle_graph(4)
    v = [0.0, 1.0, 2.0, 1.0]
    ep = extended_persistence(g, v)

    ord0 = isempty(ep.ord0.births) ? 0.0 : sum(ep.ord0.deaths .- ep.ord0.births)
    ext0 = sum(ep.ext0.deaths .- ep.ext0.births)
    ext1 = sum(ep.ext1.births) - sum(ep.ext1.deaths)

    @test ord0 ≈ 0.0
    @test ext0 ≈ 2.0
    @test ext1 ≈ 2.0
    @test total_extended_persistence(g, v) ≈ 4.0
    @test total_extended_persistence(g, v; dims = (1,)) ≈ 2.0
    @test total_extended_persistence(g, v; dims = (0,)) ≈ 2.0
end

@testitem "extended H1 pairs on two loops with nested height ranges" begin
    using TDAmapper, Graphs
    graph = SimpleGraph(5)
    for (a, b) in ((1, 2), (2, 3), (3, 1), (1, 4), (4, 5), (5, 1))
        add_edge!(graph, a, b)
    end
    heights = [2, 0, 5, 1, 4]
    loops = extended_persistence(graph, heights).ext1
    @test collect(zip(loops.births, loops.deaths)) == [(5, 0), (4, 1)]
    @test total_extended_persistence(graph, heights; dims=(1,)) == 8

    flat = extended_persistence(graph, ones(Int, 5)).ext1
    @test collect(zip(flat.births, flat.deaths)) == [(1, 1), (1, 1)]
end

@testitem "extended persistence — tent vs circle contrast" begin
    using TDAmapper
    using Graphs

    ord0(ep) = isempty(ep.ord0.births) ? 0.0 : sum(ep.ord0.deaths .- ep.ord0.births)
    ext1(ep) = sum(ep.ext1.births) - sum(ep.ext1.deaths)

    # Tent (Λ): a branch structure, no loop ⇒ Ord0 > 0, Ext1 = 0.
    tent = extended_persistence(path_graph(5), [0.0, 1.0, 2.0, 1.0, 0.0])
    @test ord0(tent) > 0
    @test ext1(tent) ≈ 0.0

    # Circle: a loop, single min/max ⇒ Ord0 = 0, Ext1 > 0.
    circle = extended_persistence(cycle_graph(4), [0.0, 1.0, 2.0, 1.0])
    @test ord0(circle) ≈ 0.0
    @test ext1(circle) > 0
end

@testitem "extended persistence — disconnected edges (Ext0 count, empty Ext1)" begin
    using TDAmapper
    using Graphs

    g = SimpleGraph(4)
    add_edge!(g, 1, 2)
    add_edge!(g, 3, 4)                 # two components, β₁ = 0
    v = [0.0, 1.0, 2.0, 5.0]
    ep = extended_persistence(g, v)

    @test length(ep.ext0.births) == 2         # one spread bar per component
    @test isempty(ep.ext1.births)             # no loops
    @test total_extended_persistence(g, v; dims = (1,)) ≈ 0.0
end

@testitem "extended persistence — gradient matches finite differences" begin
    using TDAmapper
    using Graphs
    using Zygote
    using FiniteDifferences

    g = cycle_graph(4)
    v = [0.0, 1.0, 3.0, 2.0]           # distinct node values

    gz = Zygote.gradient(vv -> total_extended_persistence(g, vv), v)[1]
    gfd = FiniteDifferences.grad(central_fdm(5, 1),
                                 vv -> total_extended_persistence(g, vv), v)[1]

    @test gz ≈ gfd atol = 1e-5
end

@testitem "extended persistence — end-to-end optimize_filter on a circle (loop-aware)" begin
    using TDAmapper
    using TDAmapper.IntervalCovers: Uniform
    using TDAmapper.Refiners: DBscan
    using TDAmapper.Nerves: SimpleNerve
    using Graphs
    using Zygote, Optimisers            # triggers TDAmapperZygoteExt

    # Equal angular spacing keeps sampling gaps from opening the Mapper loop.
    X = EuclideanSpace([[cospi(i / 200), sinpi(i / 200)] for i in 0:399])
    θ0 = [0.0, 1.0]                     # height (y) filter
    cover = Uniform(length = 8, expansion = 0.4)
    refiner = DBscan(radius = 0.2)

    # The circle's mapper graph is a loop. Ordinary 0-dim persistence is blind
    # to it (identically zero ⇒ no gradient); the loop-aware extended loss is not.
    sm = soft_mapper(X, θ0; cover = cover, refiner = refiner, nerve = SimpleNerve())
    β1 = ne(sm.g) - nv(sm.g) + length(connected_components(sm.g))
    @test β1 ≥ 1                                               # the loop survives in the graph
    @test total_extended_persistence(sm.g, sm.v; dims = (1,)) > 0     # Ext1 detects it
    @test total_persistence(sm.g, sm.v) < total_extended_persistence(sm.g, sm.v)

    # optimize_filter (default loss = total_extended_persistence) now has a
    # nonzero loss and moves θ — the case that was trivial under 0-dim.
    out = optimize_filter(X, θ0;
                          cover = cover, refiner = refiner, nerve = SimpleNerve(),
                          n_epochs = 40)
    @test length(out.history) == 40
    @test all(isfinite, out.history)
    @test out.history[1] > 0
    @test out.θ != θ0
end
