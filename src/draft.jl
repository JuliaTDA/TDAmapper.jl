
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

X = gd.torus(1000)
# X = randn(2, 2000)
fv = excentricity(X)
# fv = X[3, :]
cv = uniform(fv, length = 25, overlap = 100)
# cv = spaced(fv; )

using GLMakie
scatter(X[1, :], X[2, :], X[3, :], color = fv)

mp = mapper(X, fv, cv; clustering = x -> cluster_dbscan(x; radius = 1));

using Statistics
using StatsBase

v = map(mp.points_in_node) do ids
    #X[2, ids] |> mean
    fv[ids] |> mean
end

mapper_plot(mp, v)

mapper_plot(mp, rand(["a", "b", "c", "d", "a/b"], 27))

s = rand(["a", "b", "c"], 5)

function string_count(x; max_ties = 3)
    counting = Dict(i => length(filter(x -> x == i, s)) for i ∈ unique(s))
    n_max = maximum(counting)[2]
    uniques = findall(c -> values(c) == n_max, counting)

    v = @pipe uniques[1:clamp(length(uniques), 1, max_ties)] |>
        sort |>
        join(_, "/")

    return v
end

x = rand(["a", "b", "c"], 5)
string_count(x)

scatter!()









# plots
using TDAmapper
import GeometricDatasets as gd

X = gd.torus(1000)
# X = randn(2, 2000)
fv = excentricity(X)
fv = X[1, :]

using GLMakie
scatter(X[1, :], X[2, :], X[3, :], color = fv)

L = rand(1:200, 100) |> unique
bmp = ball_mapper(X, L, ϵ = 1);
bmp

v = calculate_node_colors(bmp, fv)

mapper_plot(bmp, v)


import NetworkLayout
pos = NetworkLayout.spring(bmp.adj_matrix, dim = 3)
pos = NetworkLayout.stress(bmp.adj_matrix, dim = 3)


f = Figure();
ax = Axis3(f[1, 1])    

scatter!(ax, pos, label = rand(["a", "b"], 77))

el1, el2 = (
    [MarkerElement(color = cm[1], marker = :square)]
    ,[MarkerElement(color = cm[end], marker = :square)]
    )
Legend(f[1, 2], [el1, el2], ["label 1", "label 2"])
f

cm = Makie.to_colormap(:viridis); 
startcolor = first(cm); endcolor = last(cm)

adj = bmp.adj_matrix
for i ∈ 1:size(adj)[1]
    for j ∈ i:size(adj)[1]
        if adj[i, j] == 1
            linesegments!(ax, [pos[i], pos[j]])
        end
    end
end

f

scatter(pos)

if isnothing(node_size)
    node_size = 
        map(mp.points_in_node) do p
            length(p)
        end |>
        node_scale_function
end

if isnothing(values)
    values = zeros(x)
end

f = Figure();
ax = Axis(f[1, 1])    
linesegments!(ax, xs, ys)    
scatter!(ax, x, y, markersize = node_size, color = values)

hidedecorations!(ax); hidespines!(ax)
ax.aspect = DataAspect()
Colorbar(f[1, 2])
return(f)

using TDAmapper
mean

