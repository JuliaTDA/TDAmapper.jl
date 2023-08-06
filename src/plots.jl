"""
Given a numeric vector `v`, create a color vector
"""
function colorscale(v)
    min_val = minimum(v)
    max_val = maximum(v)
    range_val = max_val - min_val
    
    if (range_val ≈ 0) range_val = 1 end
    
    color_vec = get.(Ref(cgrad(:inferno)), (v .- min_val) ./ range_val)    

    return(color_vec)   
end

"""
Rescale a vector to be between `min` and `max`
"""
function rescale(x; min = 0, max = 1)
    dif = max - min
    if dif ≈ 0
        return replace(z -> mean([min, max]), float.(x))
    end

    y = (x .- minimum(x)) / (maximum(x) - minimum(x)) .* (dif) .+ min
    return y
end

function rescale(; min = 0, max = 1)
    x -> rescale(x; min = min, max = max)
end

# function mapper_plot(mp::Mapper; values = mp.filter_values, dim = 2)

#     colors = map(mp.clustered_pb_ids) do pb
#         values[pb] |> maximum
#     end |> colorscale
    
#     node_sizes = rescale(map(length, mp.clustered_pb_ids), min = 10, max = 80)
    
#     g = mp.mapper_graph
    
#     f, ax, p = graphplot(
#         g, node_color = colors, node_size = node_sizes
#         ,layout = NetworkLayout.Spring(dim = dim)
#         # , nlabels = string.(mp.node_origin)
#         );
#     hidedecorations!(ax); hidespines!(ax)
#     ax.aspect = DataAspect()

#     return f, ax, p     
# end

# !! https://beautiful.makie.org/dev/examples/generated/2d/linesegments/RRGraph/
# https://docs.makie.org/stable/examples/plotting_functions/linesegments/

"""
    mapper_plot
"""
function mapper_plot(
    mp::AbstractMapper, values::Vector{<:AbstractString}
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
    
    dfs = @pipe DataFrame(x = x, y = y, class = values, row = 1:length(x)) |> 
        groupby(_, :class) |> 
        collect

    f = Figure();
    ax = Axis(f[1, 1])

    linesegments!(ax, xs, ys)

    if isnothing(node_size)
        node_size = 
            map(mp.points_in_node) do p
                length(p)
            end |>
            node_scale_function
    end

    for df ∈ dfs
        scatter!(ax, df.x, df.y, markersize = node_size[df.row], label = df.class[1])
    end

    Legend(f[1, 2], ax, merge = true)

    hidedecorations!(ax); hidespines!(ax)
    ax.aspect = DataAspect()
    
    return(f)    
end

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

function _mapper_plot(
    mp::Mapper
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
            @pipe mp.points_in_node |>
            map(length, _) |>
            node_scale_function
    end
    
    f = Figure();
    ax = Axis(f[1, 1])
    linesegments!(ax, xs, ys)
    scatter!(ax, x, y, markersize = 25, color = values)

    hidedecorations!(ax); hidespines!(ax)
    ax.aspect = DataAspect()
    Colorbar(f[1, 2])
    return(f)
end

function node_colors(mp::AbstractMapper, v::Vector{<:Union{Number, AbstractString}}; f::Function = maximum)
    v = map(mp.points_in_node) do id
        mp.X[:, id] |> f
    end

    return v
end
