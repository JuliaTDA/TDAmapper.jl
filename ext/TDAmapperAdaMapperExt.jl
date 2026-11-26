module TDAmapperAdaMapperExt

import TDAmapper as TM
import TDARipserer as PH
using Distances: Euclidean, pairwise
using Graphs: Graph, DijkstraState, add_edge!, dijkstra_shortest_paths, enumerate_paths
using StatsBase: quantile
using TDAmapper: EuclideanSpace, Interval, as_matrix
using TDAmapper.ImageCovers: R1Cover
using TDAmapper.IntervalCovers: Uniform
using TDAmapper.Refiners: DBscan
using TDAmapper.Nerves: SimpleNerve

function _knn_graph(distances, k)
    graph = Graph(size(distances, 1))
    nearest = Float64[]
    for i in axes(distances, 2)
        neighbors = partialsortperm(view(distances, :, i), 1:(k + 1))
        for j in neighbors
            i == j && continue
            add_edge!(graph, i, j)
        end
        k > 0 && push!(nearest, distances[neighbors[2], i])
    end
    return graph, nearest
end

function _path_center(X, paths, graph, distances, s, t)
    # Cache shortest paths by source since several triangles can share vertices.
    state = get!(paths, s) do
        dijkstra_shortest_paths(graph, s, distances)
    end
    path = enumerate_paths(state, t)
    isempty(path) && return nothing
    centroid = sum(i -> X[i], path) / length(path)
    return argmin(i -> (sum(abs2, X[i] - centroid), i), path)
end

function _critical_range(X, lens, graph, distances, paths, triangle)
    a, b, c = sort!(collect(PH.vertices(triangle)))
    edges = ((a, b), (a, c), (b, c))
    lengths = map(edge -> distances[edge...], edges)
    # Rescale first so the entropy calculation works for large lengths.
    relative = lengths ./ maximum(lengths)
    fractions = relative ./ sum(relative)
    entropy = -sum(x -> iszero(x) ? 0.0 : x * log(x), fractions) / log(3)
    if entropy >= 0.975
        points = [a, b, c]
        for (s, t) in edges
            center = _path_center(X, paths, graph, distances, s, t)
            isnothing(center) || push!(points, center)
        end
        return extrema(lens[points])
    end
    s, t = edges[argmax(lengths)]
    lo, hi = minmax(lens[s], lens[t])
    center = _path_center(X, paths, graph, distances, s, t)
    isnothing(center) && return lo, hi
    mid = lens[center]
    if mid < lo
        return mid, hi + (lo - mid)
    elseif mid > hi
        return lo - (mid - hi), mid
    end
    return lo, hi
end

function _adaptive_intervals(lens, ranges, overlap, regular_intervals, max_intervals)
    lo, hi = extrema(lens)
    lo == hi && return [Interval(lo, hi)]
    if isempty(ranges)
        return Uniform(length=regular_intervals, expansion=overlap)(lens)
    end

    regular_width = minimum(b - a for (a, b) in ranges)
    critical_width = regular_width / 3
    critical_width > 0 || throw(ArgumentError("critical range is too narrow to subdivide"))
    merged = Tuple{Float64,Float64}[]
    for (a, b) in sort(ranges)
        if isempty(merged) || a > last(merged)[2]
            push!(merged, (a, b))
        else
            start, stop = last(merged)
            merged[end] = (start, max(stop, b))
        end
    end
    segments = Tuple{Float64,Float64,Bool}[]
    for (a, b) in merged
        lo < a && push!(segments, (lo, a, false))
        push!(segments, (a, b, true))
        lo = b
    end
    lo < hi && push!(segments, (lo, hi, false))

    left, right = Float64[], Float64[]
    critical = Bool[]
    for (a, b, inside) in segments
        count = (b - a) / (inside ? critical_width : regular_width)
        remaining = max_intervals - length(left)
        1 <= remaining && count <= remaining ||
            throw(ArgumentError("adaptive cover exceeds max_intervals"))
        n = max(1, ceil(Int, count))
        points = range(a, b; length=n + 1)
        for i in 1:n
            push!(left, points[i])
            push!(right, points[i + 1])
            push!(critical, inside)
        end
    end
    for i in 1:(length(left) - 1)
        p = if critical[i] != critical[i + 1]
            overlap * critical_width
        else
            overlap * (critical[i] ? critical_width : regular_width) / 2
        end
        right[i] += p
        left[i + 1] -= p
    end
    # Visit the widest interval first for intervals with the same start.
    order = sortperm(eachindex(left); by=i -> (left[i], -right[i]))
    result = Interval{Float64}[]
    for i in order
        if isempty(result) || right[i] > last(result).b
            push!(result, Interval(left[i], right[i]))
        end
    end
    return result
end

function TM.ada_mapper(X::EuclideanSpace; lens=nothing, k::Int=min(5, length(X) - 1),
    basepoint=nothing, min_relative_persistence::Real=0.35, overlap::Real=0.2,
    regular_intervals::Int=10, max_intervals::Int=10_000, refiner=nothing,
    nerve=SimpleNerve(), return_details::Bool=false)
    n = length(X)
    n > 0 && !isempty(first(X)) && all(p -> all(isfinite, p), X) && allunique(X) ||
        throw(ArgumentError("AdaMapper needs distinct, finite, nonempty Euclidean points"))
    (n == 1 ? k == 0 : 1 <= k < n) || throw(ArgumentError("invalid number of neighbors"))
    0 <= min_relative_persistence <= 1 ||
        throw(ArgumentError("min_relative_persistence must lie in [0, 1]"))
    isfinite(overlap) && 0 <= overlap < 1 || throw(ArgumentError("overlap must lie in [0, 1)"))
    2 <= regular_intervals <= max_intervals ||
        throw(ArgumentError("require 2 ≤ regular_intervals ≤ max_intervals"))
    isnothing(basepoint) || (basepoint isa Integer && 1 <= basepoint <= n) ||
        throw(ArgumentError("basepoint must index an input point"))

    points = map(p -> Float64.(p), X)
    coordinates = as_matrix(points)
    distances = pairwise(Euclidean(1e-12), coordinates; dims=2)
    for i in 1:n, j in (i + 1):n
        d = distances[j, i]
        isfinite(d) && d > 0 || throw(ArgumentError("distinct points need finite positive distances"))
    end
    graph, nearest = _knn_graph(distances, k)
    paths = Dict{Int,DijkstraState{Float64,Int}}()
    values = if isnothing(lens)
        id = isnothing(basepoint) ? argmin(view(coordinates, 1, :)) : Int(basepoint)
        state = dijkstra_shortest_paths(graph, id, distances)
        paths[id] = state
        all(isfinite, state.dists) ||
            throw(ArgumentError("the default lens requires a connected kNN graph"))
        state.dists
    else
        collect(Float64, lens)
    end
    length(values) == n && all(isfinite, values) ||
        throw(ArgumentError("supply one finite lens value per point"))
    lo, hi = extrema(values)
    isfinite(hi - lo) || throw(ArgumentError("the lens range must be finite"))

    diagram = n >= 3 ? PH.ripserer(distances; dim_max=1)[2] :
        PH.PersistenceDiagram(PH.PersistenceInterval[]; dim=1)
    finite = filter(isfinite, diagram)
    cutoff = min_relative_persistence * maximum(PH.persistence, finite; init=0.0)
    ranges = Tuple{Float64,Float64}[]
    for bar in finite
        PH.persistence(bar) > cutoff || continue
        a, b = _critical_range(points, values, graph, distances, paths, PH.death_simplex(bar))
        a, b = max(a, lo), min(b, hi)
        a < b && push!(ranges, (a, b))
    end
    intervals = _adaptive_intervals(values, ranges, overlap, regular_intervals, max_intervals)
    clustering = if isnothing(refiner)
        DBscan(radius=isempty(nearest) ? 1.0 : 1.5 * quantile(nearest, 0.75))
    else
        refiner
    end
    model = TM.classical_mapper(X, R1Cover(values, intervals), clustering, nerve)
    return return_details ? (mapper=model, lens=values, critical_ranges=ranges, intervals, diagram) : model
end

end
