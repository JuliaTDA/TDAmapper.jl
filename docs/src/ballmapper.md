# Ball Mapper

Ball Mapper covers a point cloud with balls centered at selected landmark observations, then connects balls that share observed points. It needs a geometry and a radius, but no scalar filter or clustering step.

## Build and inspect a small example

```@example mapper_balls
using TDAmapper
using Graphs: nv, ne
X = EuclideanSpace(reshape([0.0, 0.5, 1.0, 1.5, 2.0], 1, :))
landmarks = [1, 3, 5]
M = ball_mapper(X, landmarks, 0.6)
@assert length(M.C) == length(landmarks)
@assert M.C[1] == [1, 2]
(; landmarks, node_members=M.C, nodes=nv(M.g), edges=ne(M.g))
```

Node `v` corresponds to landmark `landmarks[v]`, and `M.C[v]` contains original observation indices in its ball. The standard construction preserves the landmark order. The radius is the third **positional** argument, not an `ϵ` keyword. Landmarks must be valid indices into `X` and the radius must be positive.

The ball strategy uses NearestNeighbors' range query and includes observations at the radius boundary. This differs from MetricSpaces' `ball_ids`, which uses strict inequality. For floating-point boundary cases, inspect membership explicitly.

## Select landmarks and verify coverage

```@example mapper_balls
using Random
Random.seed!(17)
ids = farthest_points_sample_ids(X, 3)
M2 = ball_mapper(X, ids, 0.6)
covered = Set(vcat(M2.C...))
uncovered = setdiff(Set(eachindex(X)), covered)
@assert isempty(uncovered)
(; ids, uncovered)
```

Use `epsilon_net(X, ε)` for enough centers to cover the cloud at a chosen open-ball radius, or farthest-point sampling for a fixed count. The latter can leave observations uncovered if its achieved coverage radius exceeds your selected radius. A random landmark sample can miss rare components.

## Which nerve is this?

An edge means that a **sampled observation** belongs to both landmark balls. Two ambient balls can intersect without sharing any observed point, in which case this graph has no edge. Conversely, nearby landmark centers alone do not define an edge unless their observed memberships intersect.

This is a nerve of an observed ball cover, not the Vietoris–Rips complex of the landmark centers. Rips tests pairwise distances; the nerve tests shared intersection. Pairwise overlaps do not guarantee a triple intersection or a filled triangle. Use `SimplicialNerve` when higher-dimensional nerve information is required.

## Customize distance, refinement, or overlap

```@example mapper_balls
using TDAmapper.DomainCovers: EpsilonBall
using TDAmapper.Refiners: Trivial
using TDAmapper.Nerves: MinCountNerve
C = EpsilonBall(X=X, L=landmarks, epsilon=0.6)
stronger = mapper(X, C, Trivial(), MinCountNerve(2))
(; ordinary_edges=ne(M.g), stronger_edges=ne(stronger.g))
```

`EpsilonBall(...; metric=...)` is configured through its keyword constructor with a Distances.jl metric object. Pass another refiner or nerve to `mapper` to change the standard Ball Mapper behavior. See [Strategies and multivariate filters](@ref).

Try several radii and record coverage, landmark count, node sizes, and graph components. A tiny radius fragments the graph; a very large one makes many balls overlap. A meaningful geometric scale and original data inspection are more useful than targeting a particular drawing.
