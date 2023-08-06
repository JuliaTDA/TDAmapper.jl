using TDAmapper
import GeometricDatasets as gd

X = gd.sphere(2000, dim = 4)
X = gd.torus(2000)
# vcat(X; zeros(size(X)[2]))

fv = X[1, :]
mp = mapper(X, fv, uniform(fv, length = 20), clustering = cluster_dbscan(radius = 1))

using Graphs
g = mp.graph
it = vertices(g)
has_edge(g, 1, 2)
eee = edges(g)
ppp = eee |> collect
z = ppp[1]
z.src
z.dst


using GLMakie
using NetworkLayout
using Graphs

layout_function = NetworkLayout.spring
g = mp.graph
pos = layout_function(g)

f = Figure();
ax = Axis(f[1, 1])    

for e ∈ edges(g)
    e.src >= e.dst && continue
    println(e.src, ";", e.dst)
    linesegments!(ax, [pos[e.src], pos[e.dst]], color = :black)
end

scatter!(ax, pos)
hidedecorations!(ax); hidespines!(ax)
ax.aspect = DataAspect()

f

mapper_plot(mp)

using GraphMakie
graphplot(g)




function mapper_plot(
    mp::AbstractMapper, values::Union{Vector{<:Number}, Nothing} = nothing
    ;node_size = nothing
    ,node_scale_function = x -> rescale(x, min = 10, max = 75)
    )
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

    if isnothing(node_size)
        node_size = 
            map(mp.points_in_node) do p
                length(p)
            end |>
            node_scale_function
    end

    if isnothing(values)
        values = zeros(length(x))
    end
    
    f = Figure();
    ax = Axis(f[1, 1])    
    linesegments!(ax, xs, ys)    
    scatter!(ax, x, y, markersize = node_size, color = values)

    hidedecorations!(ax); hidespines!(ax)
    ax.aspect = DataAspect()
    if !(minimum(values) ≈ maximum(values))
        Colorbar(f[1, 2])
    end
    
    return(f)
end











