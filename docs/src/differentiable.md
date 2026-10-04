# Differentiable Mapper and graph persistence

TDAmapper provides scalar filter models and graph-persistence losses with derivatives through node values. It does not differentiate discrete cover membership or clustering decisions. Each optimization step holds a graph fixed, differentiates its node values, and then rebuilds the graph at the updated parameters.

## Inspect a linear filter and soft memberships

```@example mapper_soft
using TDAmapper
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: Trivial
X = EuclideanSpace([[0.0, 0.0], [0.5, 1.0], [1.0, 0.0], [1.5, 1.0]])
θ = [1.0, 0.0]
S = soft_mapper(X, θ; cover=Uniform(length=3, expansion=0.4), refiner=Trivial())
@assert length(S.f_X) == length(X)
@assert size(S.Q, 1) == length(X)
(; filter_values=S.f_X, node_values=S.v, membership_shape=size(S.Q))
```

`LinearFilter()` computes a coordinate dot product with the parameter vector. `S.C` and `S.g` are constructed from hard membership; `S.v` is the mean filter value in each node. `S.Q` stores smoothed interval-membership weights (`points × intervals`) controlled by `sharpness`. These are not cluster-node memberships, are not normalized probabilities, and do **not** enter the current optimization gradient. Increasing sharpness does not make the full pipeline differentiable.

## Ordinary and extended graph persistence

```@example mapper_graph_persistence
using TDAmapper
using Graphs: cycle_graph
G = cycle_graph(4)
v = [0.0, 1.0, 2.0, 1.0]
ordinary = persistence_diagram(G, v)
extended = extended_persistence(G, v)
@assert total_extended_persistence(G, v; dims=(1,)) > 0
(; ordinary, extended, total=total_extended_persistence(G, v))
```

`persistence_pairs` returns indices of finite 0-dimensional birth/death pairs; `persistence_diagram` returns their values. `total_persistence` sums their lifetimes and omits essential components. It can be zero for a loop with a simple scalar filter even when the graph contains a cycle.

`extended_persistence` returns `ord0`, `ext0`, and `ext1` collections. Extended 0-dimensional intervals account for connected component ranges; extended 1-dimensional intervals account for graph loops. Their orientation differs: ordinary/extended 0-dimensional lifetimes use death minus birth, while `ext1` lifetimes use birth minus death. `total_extended_persistence(...; dims=(0, 1))` applies these conventions. These are persistence summaries of the **Mapper graph**, not persistence of the original cloud's Rips complex.

## Optimize an explicit filter

Install and load the optional Zygote and Optimisers dependencies:

```julia
using Pkg
Pkg.add(["Zygote", "Optimisers"])
```

```julia
using TDAmapper, Zygote, Optimisers
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: DBscan
left = [[t, t] for t in 0.0:0.05:1.0]
right = [[2-t, t] for t in 0.0:0.05:1.0]
X = EuclideanSpace(vcat(left, right))
θ0 = [0.0, 1.0]
out = optimize_filter(X, θ0;
    cover=Uniform(length=6, expansion=0.4),
    refiner=DBscan(radius=0.3), n_epochs=10,
    optimizer=Optimisers.Adam(0.01),
    regularizer=θ -> (sum(abs2, θ) - 1)^2)
```

The extension activates only after both `Zygote` and `Optimisers` load. The result contains `out.θ` and `out.history`; the input parameters are copied. Optimization **minimizes** the objective. The default is total extended persistence; pass `loss=total_persistence` for finite ordinary 0-dimensional lifetimes, or a negated loss to maximize a summary. Maximization without scale control can enlarge filter amplitude, and minimization can collapse it. Use an explicit regularizer or a scale-constrained model justified by your task.

The piecewise objective can change abruptly when membership, clustering, or persistence pairings change. Inspect history, learned filter amplitude, node coverage, and sensitivity to initialization. Empty nodes are removed from the optimization graph before node means are evaluated. `soft_mapper` itself retains the construction's cover, so use a cover with nonempty groups when inspecting its means.

For nonlinear filters and Flux/Lux adapters, see [Nonlinear Mapper filters](@ref).
