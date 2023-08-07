using TDAmapper
import GeometricDatasets as gd

using GLMakie
using NetworkLayout
using Graphs


X = gd.sphere(2000, dim = 4)
X = gd.torus(2000)
X = vcat(X, zeros(7, 2000))
# vcat(X; zeros(size(X)[2]))

fv = X[1, :]
mp = mapper(X, fv, uniform(fv, length = 25), clustering = cluster_dbscan(radius = 1))
mp.graph

L = rand(1:size(X)[2], 200) |> unique
mp = ball_mapper(X, L, ϵ = 0.8)
mp.graph

node_values = node_colors(mp, X[1, :])
node_values = node_colors(mp, rand(["a", "b", "c"], size(X)[2]))

node_positions = mds_layout(mp.CX, dim = 2)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)

node_positions = mds_layout(mp.CX, dim = 3)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)

node_positions = spring(mp.graph, dim = 2)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)

node_positions = spring(mp.graph, dim = 3)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)

node_positions = sfdp(mp.graph, dim = 2)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)

node_positions = sfdp(mp.graph, dim = 3)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)

node_positions = spectral(mp.graph, dim = 3)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)

gg(X; maxoutdim = 3)

using MultivariateStats
layout_mds(mp.CX, dim = 3)

node_positions = layout_mds(mp.CX, dim = 3)
node_values = node_colors(mp, X[1, :]) .+ 50
mapper_plot(mp, node_values = node_values, node_positions = node_positions)
scatter(X[1:3, :])

using ManifoldLearning
@doc ManifoldLearning.fit