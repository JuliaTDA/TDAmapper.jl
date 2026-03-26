# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TDAmapper.jl implements the Mapper algorithm for Topological Data Analysis (TDA) in Julia. It builds on MetricSpaces.jl to provide classical mapper, ball mapper, and a generic mapper pipeline. The result is always a `Mapper` struct containing the original space, a covering, and a nerve graph.

## Common Commands

```bash
# Run all tests (uses TestItemRunner with @testitem blocks embedded in source files)
julia --project=. -e 'using Pkg; Pkg.test()'

# Load package in REPL for development
julia --project=. -e 'using Revise; using TDAmapper'

# Build documentation (Documenter.jl + VitePress)
julia --project=docs/ docs/make.jl
```

## Architecture

The mapper pipeline follows three stages: **cover** → **refine** → **nerve graph**.

```
mapper(X, cover, refiner, nerve)
  1. make_cover(cover)     → Covering (Vector{Vector{Int}})
  2. refine_cover(X, C, R) → refined Covering (clusters within each element)
  3. make_graph(X, C, N)   → Mapper{S, G} with nerve graph
```

**Core types** (`src/types.jl`):
- `Mapper{S, G}` - Result struct holding metric space `X`, covering `C`, and graph `g`
- `Covering = Vector{Vector{Int}}` - Type alias for index-based coverings

**Two main entry points:**
- `classical_mapper(X, cover, refiner, nerve)` - Filter-based mapper using pullback covers
- `ball_mapper(X, landmarks, epsilon)` - Landmark-based ball covering

**Modular subsystems** (each in its own submodule under `src/`):

| Module | Abstract Type | Implementations | Purpose |
|--------|--------------|-----------------|---------|
| `ImageCovers/` | `AbstractImageCover` | `R1Cover` | Pullback cover via filter function f⁻¹(U) |
| `IntervalCovers/` | `AbstractIntervalCover` | `Uniform` | Generate overlapping intervals on ℝ |
| `DomainCovers/` | `AbstractDomainCover` | `EpsilonBall` | Ball-based cover using NearestNeighbors.jl |
| `Refiners/` | `AbstractRefiner` | `DBscan`, `Trivial` | Cluster within cover elements |
| `Nerves/` | `AbstractNerve` | `SimpleNerve` | Build graph from covering overlaps |

**Key design patterns:**
- Each strategy type is callable (functor pattern): `DBscan(radius=0.1)(X)` returns cluster labels
- `@reexport using MetricSpaces` — all MetricSpaces exports are available to users
- Tests use `@testitem` blocks embedded in source files (TestItems.jl), run via `@run_package_tests`
- Outlier handling in refiners: cluster label 0 gets reassigned to a new cluster

## Dependencies

- **MetricSpaces.jl** - point clouds, distances, sampling, nerve_1d (re-exported)
- **Clustering.jl** - DBSCAN algorithm for refiners
- **NearestNeighbors.jl** - KD-tree range queries for ball mapper
- **Graphs.jl** - graph structure for nerve complexes
- **Reexport.jl** - re-exports MetricSpaces API
