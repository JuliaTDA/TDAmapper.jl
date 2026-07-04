"""
    _persistence_pass(g, v; ascending) -> (ord_pairs, neg_nodes, roots, comp_min, comp_max)

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
function _persistence_pass(g, v::AbstractVector; ascending::Bool)
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
    birth_val = collect(float.(v))
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
            else
                push!(neg_nodes, v[a] <= v[b] ? a : b)
            end
            continue
        end
        # positive edge: merge the two components (elder rule).
        if ascending
            older, younger = birth_val[ra] <= birth_val[rb] ? (ra, rb) : (rb, ra)
            if evals[k] > birth_val[younger]
                dnode = v[a] >= v[b] ? a : b      # endpoint realizing the edge value
                push!(birth_idx, birth_node[younger])
                push!(death_idx, dnode)
            end
        else
            older, younger = birth_val[ra] >= birth_val[rb] ? (ra, rb) : (rb, ra)
        end
        parent[younger] = older               # elder keeps its birth_val/birth_node
        v[comp_min[younger]] < v[comp_min[older]] && (comp_min[older] = comp_min[younger])
        v[comp_max[younger]] > v[comp_max[older]] && (comp_max[older] = comp_max[younger])
    end

    roots = [find(i) for i in 1:n]
    return (ord_pairs = (birth_idx = birth_idx, death_idx = death_idx),
            neg_nodes = neg_nodes,
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
- `ext1` — loops (H₁): ascending negative-edge births zipped with descending
  negative-edge deaths, both sorted by value (descending). Counts match
  (`β₁ = E − V + C`); the per-bar pairing is canonical but the **total is exact**.
"""
function _extended_pairs(g, v::AbstractVector)
    asc = _persistence_pass(g, v; ascending = true)
    desc = _persistence_pass(g, v; ascending = false)

    ord0 = asc.ord_pairs

    rs = unique(asc.roots)
    ext0 = (birth_idx = [asc.comp_min[r] for r in rs],
            death_idx = [asc.comp_max[r] for r in rs])

    births = sort(asc.neg_nodes; by = i -> v[i], rev = true)
    deaths = sort(desc.neg_nodes; by = i -> v[i], rev = true)
    ext1 = (birth_idx = births, death_idx = deaths)

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
- `1` → Ext1 (loops / H₁), computed as `Σbirths − Σdeaths`, which is exact and
  independent of the canonical per-bar pairing.

Unlike ordinary [`total_persistence`](@ref), this sees loops: on data whose
mapper graph is a cycle it is strictly positive, giving a usable gradient where
0-dim persistence is identically zero.
"""
function total_extended_persistence(g, v::AbstractVector; dims = (0, 1))
    ep = extended_persistence(g, v)
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
    using MetricSpaces.Datasets: sphere
    using Graphs
    using Zygote, Optimisers            # triggers TDAmapperZygoteExt

    X = sphere(400, dim = 2)            # a circle in ℝ² (β₁ = 1 for any sample)
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
