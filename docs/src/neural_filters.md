# Nonlinear Mapper filters

A linear filter sees a projection; a nonlinear filter can express a more complex scalar viewpoint. TDAmapper's small feed-forward model keeps structure and parameters separate, so training changes an explicit parameter tree rather than mutating a hidden model state.

## Create and evaluate a filter

```@example mapper_mlp
using TDAmapper, Random
X = EuclideanSpace([[0.0, 1.0], [1.0, 0.0], [1.0, 1.0], [0.0, 0.0]])
f = MLPFilter([2, 4, 1])
ps = initial_parameters(f; rng=MersenneTwister(7))
values = f(X, ps)
@assert length(values) == length(X)
@assert all(isfinite, values)
(; values, layers=length(ps.layers), first_weight_shape=size(ps.layers[1].weight))
```

Widths include the input and output dimensions and must end in 1. Hidden layers use `tanh` by default; the final layer is linear. `initial_parameters` uses Xavier-normal weights and zero biases, with an explicit RNG and optional floating-point type. Input geometry is fixed while differentiation follows the parameters.

## Train a parameter tree

Load Zygote and Optimisers to activate `optimize_filter`:

```julia
using Zygote, Optimisers
out = optimize_filter(X, ps; filter=f, n_epochs=5,
    optimizer=Optimisers.Adam(0.01),
    regularizer=p -> sum(sum(abs2, layer.weight) for layer in p.layers) * 1e-3)
learned_values = f(X, out.θ)
```

This snippet demonstrates the interface, not a meaningful learning task for four points. Minimizing the default graph-persistence objective can shrink filter amplitude, and a weight penalty does not prevent collapse by itself. A target-fit regularizer, output-variance constraint, or another task-specific objective may be needed. Choose that objective explicitly and compare it with a linear filter baseline.

As explained in [Differentiable Mapper and graph persistence](@ref), graph membership and clustering are held fixed within a differentiation step, then rebuilt. The result is a piecewise objective, not a globally smooth Mapper. Training copies the caller's parameters and performs out-of-place optimizer updates. Inspect loss history, amplitude, graph coverage, initialization sensitivity, and the observations behind learned nodes.

## Flux and Lux adapters

The optional Flux adapter requires both Flux and Optimisers:

```julia
using Flux, Optimisers
model = Flux.Chain(Flux.Dense(2 => 4, tanh), Flux.Dense(4 => 1))
adapted = flux_filter(model)
values = adapted.filter(X, adapted.parameters)
```

It accepts deterministic Dense layers or nested Chains of Dense layers and returns flattened explicit parameters. Dropout, mutable recurrence, and normalization layers are not supported by this adapter.

The Lux adapter requires Lux and preserves its native parameter tree:

```julia
using Lux, Random
model = Lux.Chain(Lux.Dense(2 => 4, tanh), Lux.Dense(4 => 1))
adapted = lux_filter(model; rng=MersenneTwister(7))
values = adapted.filter(X, adapted.parameters)
```

Lux states are fixed in inference mode. A model that changes that state is rejected, preventing hidden updates across graph rebuilds. Both adapters require one scalar output per input observation and can be passed to `optimize_filter` with their explicit parameter container.

## Evaluate the learned viewpoint

Compare a learned filter with a linear filter on the same observations, preprocessing, cover, and refiner. Plot scalar values as well as graph summaries; a smaller loss can simply reflect a smaller output scale. For a target-based experiment, use held-out evaluation and fit scaling on training data. The umbrella repository's `examples/p2/nonlinear_mapper.jl` provides a seeded radial-target comparison with an intercept-aware linear baseline and an extended-persistence penalty.

The [API Reference](@ref) contains `MLPFilter`, parameter initialization, and adapter docstrings. The optional adapter/training blocks are ordinary Julia snippets so the core docs build requires no machine-learning backend; they are validated separately in an environment containing the optional dependencies.
