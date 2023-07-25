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

"""
    mapper_plot
"""
function mapper_plot(mp::Mapper; values = mp.filter_values, dim = 2)

    colors = map(mp.clustered_pb_ids) do pb
        values[pb] |> maximum
    end |> colorscale
    
    node_sizes = rescale(map(length, mp.clustered_pb_ids), min = 10, max = 80)
    
    g = mp.mapper_graph
    
    f, ax, p = graphplot(
        g, node_color = colors, node_size = node_sizes
        ,layout = NetworkLayout.Spring(dim = dim)
        # , nlabels = string.(mp.node_origin)
        );
    hidedecorations!(ax); hidespines!(ax)
    ax.aspect = DataAspect()

    return f, ax, p     
end

# https://beautiful.makie.org/dev/examples/generated/2d/linesegments/RRGraph/