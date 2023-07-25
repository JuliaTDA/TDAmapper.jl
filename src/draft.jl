
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
f, ax, p = mapper_plot(mp)
f
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


























pos = NetworkLayout.spring(mp.adj_matrix)
x = pos .|> first
y = pos .|> last

xs = Float64[];
ys = Float64[];

adj = mp.adj_matrix
for i ∈ 1:size(adj)[1]
    for j ∈ i:size(adj)[1]
        if adj[i, j] == 1
            push!(xs, x[i], x[j])
            push!(ys, y[i], y[j])
        end
    end
end

v = rand(27)

f = Figure();
ax = Axis(f[1, 1])

linesegments!(xs, ys; linewidth = rand(1:10, 27))
scatter!(x, y, markersize = 25, color = v, colormap = :inferno)
Colorbar(f[1, 2], colormap = :inferno, limits = (minimum(v), maximum(v)))
hidedecorations!(ax); hidespines!(ax)
ax.aspect = DataAspect()

f










using CairoMakie


f = Figure();
Axis(f[1, 1], limits = (0, 1, 0, 1))

rs_h = IntervalSlider(f[2, 1], range = LinRange(0, 1, 1000),
    startvalues = (0.2, 0.8))
rs_v = IntervalSlider(f[1, 2], range = LinRange(0, 1, 1000),
    startvalues = (0.4, 0.9), horizontal = false)

labeltext1 = lift(rs_h.interval) do int
    string(round.(int, digits = 2))
end
Label(f[3, 1], labeltext1, tellwidth = false)
labeltext2 = lift(rs_v.interval) do int
    string(round.(int, digits = 2))
end
Label(f[1, 3], labeltext2,
    tellheight = false, rotation = pi/2)

points = rand(Point2f, 300)

# color points differently if they are within the two intervals
colors = lift(rs_h.interval, rs_v.interval) do h_int, v_int
    map(points) do p
        (h_int[1] < p[1] < h_int[2]) && (v_int[1] < p[2] < v_int[2])
    end
end

scatter!(points, color = colors, colormap = [:black, :orange], strokewidth = 0)

f