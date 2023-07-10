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
