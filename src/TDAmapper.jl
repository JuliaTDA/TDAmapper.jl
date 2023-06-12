# module GraphMethods
module TDAmapper
using BenchmarkTools; using Distances; using ProgressMeter;
import Base.Threads.@threads

include("types.jl");
include("filter.jl");
include("covering.jl");
include("clustering.jl");
include("plots.jl");
include("utils.jl");

function Base.in(x::Real, i::Interval)
    i.a <= x <= i.b
end

# defining interval intersection
function intersect(i::Interval, j::Interval)
    (i.a <= j.a <= i.b) || (i.a <= j.b <= i.b)
end

function pre_image_id(fv::Vector{<:Real}, interval_covering::Vector{<: Interval})
    [findall(x -> x ∈ c, fv) for c ∈ interval_covering]
end

function adj_matrix_from_pb(clustered_pb_ids)
    n = size(clustered_pb_ids)[1]
    adj_matrix = zeros(Int32, n, n)
    @showprogress "Calculating edges" for i ∈ eachindex(clustered_pb_ids)
        @threads for j ∈ eachindex(clustered_pb_ids)
             i >= j && continue
             u, v = clustered_pb_ids[i], clustered_pb_ids[j]
             if !isdisjoint(u, v)
                adj_matrix[i, j], adj_matrix[j, i] = 1, 1            
             end
        end    
    end

    return(adj_matrix)    
end



# Mapper
function mapper(
    X::Matrix; 
    data = nothing
    ,filter_values = nothing
    ,filter_function = excentricity
    ,distance = nothing
    ,distance_function = Euclidean()
    ,covering = nothing
    ,covering_function = x -> uniform(x, 10, 100)
    ,clustering_function = nothing
    )

    if data === nothing
        data = DataFrame(X, :auto) #! checar se X é dataframe antes? #! fazer dispatch separado?
    end

    if filter_values === nothing
        filter_values = X |> excentricity
    end    
 
    if covering === nothing
        covering = covering_function(filter_values)
    end
        
    id_pbs = pre_image_id(filter_values, covering)
    
    clustered_pb_ids, node_origin = split_pre_image(X, id_pbs)
    
    clustered_pb_ids
    
    adj_matrix = adj_matrix_from_pb(clustered_pb_ids)
    
    mapper_graph = Graph(adj_matrix)

    mapper = Mapper(
        X = X
        ,data = data
        ,filter_function = filter_function
        ,filter_values = filter_values
        ,covering = covering, covering_function = covering_function
        ,clustering_function = clustering_function
        ,clustered_pb_ids = clustered_pb_ids
        ,node_origin = node_origin
        ,mapper_graph = mapper_graph
        )
end


# end module
end