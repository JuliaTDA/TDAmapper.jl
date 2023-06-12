using Graphs; 
using Colors; using ColorSchemes;
using CairoMakie
using GraphMakie
using NetworkLayout

# Ploting

colorscale = function(v)
    min_val = minimum(v)
    max_val = maximum(v)
    range_val = max_val - min_val
    
    if (range_val ≈ 0) range_val = 1 end
    
    color_vec = get.(Ref(cgrad(:inferno)), (v .- min_val) ./ range_val)    

    return(color_vec)   
end

function rescale(x; min = 0, max = 1)
    dif = max - min
    if dif ≈ 0
        return replace(z -> mean([min, max]), float.(x))
    end

    y = (x .- minimum(x)) / (maximum(x) - minimum(x)) .* (dif) .+ min
    return y
end