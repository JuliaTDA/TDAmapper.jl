# module GraphMethods

include("Mapper.jl");
include("plots.jl");

# definir função filtro
X = rand(Float32, 1000, 2)

m = mapper(X)
G = m.mapper_graph
m.data

node_size = map(m.clustered_pb_ids) do ids
    size(ids)[1]
end

node_values = map(m.clustered_pb_ids) do ids
    mean(m.filter_values[ids])
end

cls = colorscale(node_values);

# 2d
f, ax, p = 
    graphplot(
        G
        ,node_size = rescale(node_size, min = 25, max = 80)
        ,node_color = cls
        # ,ilabels = m.node_origin
        ,layout = Spring(dim = 2)
        );
hidedecorations!(ax); hidespines!(ax)
ax.aspect = DataAspect()
display(f)
f

f, ax, p = 
    graphplot(
        G, node_size = log.(node_size)*10
        , node_color = cls #, ilabels = node_origin
        ,layout = Spring(dim = 3)
        );
f

# Ball Mapper
X = rand(Float32, 1000, 2)
ϵ = 0.1
landmarks = epsilon_net(X, ϵ = 0.1)
n = length(landmarks)
covering = empty_covering(n)

Xᵗ = X |> transpose

p = Progress(n)    
Base.Threads.@threads for i = 1:n
    distances = colwise(Euclidean(), X[landmarks[i], :], Xᵗ)
    covering[i] = epsilon_neighbors(distances, 0.1)    
    next!(p)
end

covering

adj_matrix = adj_matrix_from_covering(covering)

ballmapper_graph = Graph(adj_matrix)
fig, ax, p = 
    graphplot(
        ballmapper_graph                
        );
fig


g(x; y = 1, z) = x + y + z
g(1)