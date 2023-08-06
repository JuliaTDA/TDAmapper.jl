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

"""
    mapper_plot
"""
function mapper_plot(
    mp::AbstractMapper
    ;node_positions = nothing
    ,node_size = nothing
    ,node_values = nothing
    ,edge_size = nothing
    )

    if isnothing(node_positions)
        node_positions = NetworkLayout.spring(mp.graph)
    end

    dim = node_positions[1] |> length

    if isnothing(node_size)
        node_size = @pipe map(length, mp.CX.covering) |> rescale(min = 10, max = 75)
    end

    if isnothing(node_values)
        node_values = map(mp.CX.covering) do id
            mp.CX.X[1, id] |> mean
        end
    end

    if isnothing(edge_size)
        edge_size = 1
    end

    # start figure
    f = Figure();
    if dim == 2
        ax = Axis(f[1, 1])
    else
        ax = Axis3(f[1, 1])
    end    

    # plot edges
    for e ∈ edges(mp.graph)
        e.src >= e.dst && continue
        linesegments!(ax, [node_positions[e.src], node_positions[e.dst]], color = :black, linewidth = edge_size)
    end

    # if node_values is a string, plot and add the legend
    if node_values isa Vector{<:AbstractString}

        # gambiarra!!
        dfs = @pipe DataFrame(
            pos = node_positions, class = node_values, row = 1:length(node_positions)
            ,node_size = node_size
            ) |> 
        groupby(_, :class) |> 
        collect

        if dim == 2
            for df ∈ dfs
                scatter!(ax, df.pos .|> first, df.pos .|> last, markersize = df.node_size, label = df.class[1])
            end
        else 
            for df ∈ dfs
                scatter!(ax, df.pos .|> first, df.pos .|> (x -> x[2]), df.pos .|> last, markersize = df.node_size, label = df.class[1])
            end
        end        

        Legend(f[1, 2], ax, merge = true)
    else # else, plot the usual values
        scatter!(ax, node_positions, markersize = node_size, color = node_values)
        Colorbar(f[1, 2])
    end

    hidedecorations!(ax); hidespines!(ax)
    
    # ax.aspect = DataAspect()
    f
end

function node_colors(mp::AbstractMapper, v::Union{Nothing, Vector{<:Number}} = nothing ; f::Function = mean)
    if isnothing(v) 
        v = mp.CX.X[1, :]
    end

    v2 = map(mp.CX.covering) do id
        v[id] |> f
    end

    return v2
end

function node_colors(mp::AbstractMapper, v::Vector{<:AbstractString}; f::Function = string_count)
    v2 = map(mp.CX.covering) do id
        v[id] |> f
    end

    return v2
end

function string_count(s; max_ties = 3)
    counting = Dict(i => length(filter(x -> x == i, s)) for i ∈ unique(s))
    n_max = maximum(counting)[2]
    uniques = findall(c -> values(c) == n_max, counting)

    v = @pipe uniques[1:clamp(length(uniques), 1, max_ties)] |>
        sort |>
        join(_, "/")

    return v
end