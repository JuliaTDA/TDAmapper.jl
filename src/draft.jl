using TDAmapper

X = Datasets.circle(1000)
excentricity(X)

# covering
fv = rand(1000)
uniform(fv)

[range(1, 1, length = 10)...] |> collect

# mapper.jl
using TDAmapper

X = Datasets.circle(1000)
fv = excentricity(X)
fv = X[:, 1]
cv = uniform(fv)

mp = mapper(X, fv, cv);
mp
mp.mapper_graph
mp

mp.clustering(X)

# filters

function umap_projection(
    X::PointCloud
    ; n_neighbors::Integer = 15, metric::SemiMetric = Euclidean()
    , min_dist::Real = 0.1
    )
    umap(X, 2)[1, :]
end

using UMAP
X = rand(10, 1000)

# balls 
using NearestNeighbors
data = rand(3, 10^4)

# Create trees
kdtree = KDTree(data; leafsize = 10)
balltree = BallTree(data, Minkowski(3.5); reorder = false)
brutetree = BruteTree(data)


using NearestNeighbors
data = rand(3, 10^4)
r = 0.05
point = rand(3)

balltree = BallTree(data)
idxs = inrange(balltree, point, r, true)

point
data[:, idxs]
# 4-element Array{Int64,1}:
#  317
#  983
# 4577
# 8675


# sampling
using TDAmapper
using NearestNeighbors
X = rand(2, 10^4)
ϵ = 0.1
ids = epsilon_net(X, ϵ)
Y = X[:, ids]
using Plots
scatter(X[1, :], X[2, :])
scatter!(Y[1, :], Y[2, :], color = :red)

# plots
using TDAmapper
import GeometricDatasets as gd

X = gd.sphere(2000)
# X = randn(2, 2000)
fv = excentricity(X)
fv = X[1, :]
cv = uniform(fv, overlap = 100)
# cv = spaced(fv; )

mp = mapper(X, fv, cv; clustering = x -> cluster_dbscan(x; radius = 0.5));

mp.mapper_graph

using GraphMakie
using CairoMakie

CairoMakie.activate!()
ff, aa, pp = mapper_plot(mp)
Colorbar(f[1, 2], p)
f[1, 1]



fig = Figure()
ax = Axis(fig[1, 1])
hm = heatmap!(ax, randn(20, 20))
hm = pp
Colorbar(fig[1, 2], hm)
fig


using JSServe; using WGLMakie
Page(exportable=true, offline=true)
WGLMakie.activate!()
set_theme!(resolution=(800, 600))

mapper_plot(mp, dim = 3)

# first empty bin
using TDAmapper
using Plots
using Distances
using Clustering
using StatsPlots

X = hcat(
    randn(2, 1000)
    ,randn(2, 1000) .+ 10
)

scatter(X[1, :], X[2, :])

dists = pairwise(Euclidean(), X, dims = 2)

hc = hclust(dists, branchorder=:optimal)
plot(hc, xticks=false)

cutree(hc, h = 1)
plot(cutree)

bin_vector(dists, num_bins = 10) |> println


function cluster_empty_bin(X::PointCloud; n_bins::Integer = 10, minimum_points_per_bin::Integer = 1)

end





























using CairoMakie

fig, ax, hm = heatmap(randn(20, 20))
Colorbar(fig[1, 2], hm)
fig



