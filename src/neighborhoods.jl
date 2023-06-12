function epsilon_neighbors(distances, ϵ)
    findall(x -> x < ϵ, distances)
end

function kn_neighbors(distances, k)
    sorted_dist = sort(distances)
    ϵ = sorted_dist[clamp(k + 1, 1, size(distances)[1])]
    findall(x -> x < ϵ, distances)
end
