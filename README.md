# TDAmapper.jl

[![Build Status](https://github.com/JuliaTDA/TDAmapper.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaTDA/TDAmapper.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliatda.github.io/TDAmapper.jl/)

Mapper graphs, Ball Mapper, interchangeable strategies, tabular interpretation, and differentiable graph-persistence objectives in Julia.

## Installation

Use sibling source checkouts; these packages may not resolve through the General registry. From their parent directory:

```julia
using Pkg
Pkg.activate("tda-tutorial")
Pkg.develop(path="MetricSpaces.jl")
Pkg.develop(path="TDAmapper.jl")
Pkg.instantiate()
```

See the getting-started guide for repository-URL installation and version requirements.

## A first example

```julia
using TDAmapper
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: DBscan
angles = range(0, 2π; length=121)[1:end-1]
X = EuclideanSpace([[cos(t), sin(t)] for t in angles])
C = R1Cover(first.(X), Uniform(length=8, expansion=0.4))
M = classical_mapper(X, C, DBscan(radius=0.15))
M.C[1]                    # original observation indices in the first node
M.g                       # Graphs.jl nerve graph
L = farthest_points_sample_ids(X, 12)
B = ball_mapper(X, L, 0.6)
```

The pipeline is **cover → refine → nerve**. `M.X` holds the original observations; `M.C[v]` contains their indices for node `v`; `M.g` records cover overlap. Memberships overlap, so nodes are not a disjoint partition. Strategy constructors live in submodules. Dataset generators require `using MetricSpaces.Datasets`; plotting is supplied separately by TDAplots.

## Guides and reference

- [Getting started](docs/src/getting_started.md), [Classical Mapper](docs/src/mapper.md), and [Ball Mapper](docs/src/ballmapper.md): runnable first workflows and mathematical conventions.
- [Strategies and two filters](docs/src/strategies.md): all built-in covers, refiners, and nerve rules.
- [Custom strategies](docs/src/generalization.md): implement each pipeline interface.
- [Tables and node interpretation](docs/src/tables.md): preserve row alignment and summarize original records.
- [Differentiable Mapper](docs/src/differentiable.md) and [nonlinear filters](docs/src/neural_filters.md): objectives, optional adapters, and learning limitations.
- [Parameter selection](docs/src/parameters.md) and [API reference](docs/src/api.md).

The [documentation site](https://juliatda.github.io/TDAmapper.jl/) renders these guides. The source Markdown links above also work in a checkout.

## Development

Use `julia --project=. -e 'using Pkg; Pkg.test()'` for package tests. The troubleshooting/parameter guide explains how to prepare the docs environment and build it locally. Documentation builds do not publish unless CI or `JULIATDA_DOCS_DEPLOY=true` enables deployment.

Contributions, reproducible bug reports, and example improvements are welcome. License: MIT.
