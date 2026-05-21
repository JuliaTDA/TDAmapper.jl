"""
    SimplicialNerve(max_dim::Int=2)

A nerve implementation returning a full `SimplicialComplex` up to dimension `max_dim`.

- `max_dim=1` gives only vertices and edges (same as graph nerves)
- `max_dim=2` also includes triangles (default)
- Higher values include higher-dimensional simplices

Note: complexity is O(n^(max_dim+1)) in the number of cover elements.
"""
struct SimplicialNerve <: AbstractNerve
    max_dim::Int
end

SimplicialNerve() = SimplicialNerve(2)

"""
    _combinations(v, k)

Return all k-element combinations of elements from `v` as a vector of vectors.
"""
function _combinations(v::AbstractVector, k::Int)
    k == 0 && return [Int[]]
    k == 1 && return [[x] for x in v]
    result = Vector{Vector{eltype(v)}}()
    for i in eachindex(v)
        for rest in _combinations(v[(i+1):end], k - 1)
            push!(result, [v[i]; rest])
        end
    end
    result
end

"""
    make_graph(X::MetricSpace, cover::Covering, N::SimplicialNerve) -> SimplicialComplex

Construct a full simplicial complex from a covering up to dimension `N.max_dim`.

For each dimension d from 1 to `max_dim`, enumerate all (d+1)-subsets of cover
element indices and add a d-simplex whenever the intersection of all cover elements
in the subset is non-empty.
"""
function make_graph(::MetricSpace, cover::Covering, N::SimplicialNerve)
    n = length(cover)
    simplices = [[[i] for i in 1:n]]  # vertices (0-simplices)

    for d in 1:N.max_dim
        d_simplices = Vector{Vector{Int}}()
        for combo in _combinations(1:n, d + 1)
            common = cover[combo[1]]
            for idx in combo[2:end]
                common = intersect(common, cover[idx])
                isempty(common) && break
            end
            isempty(common) || push!(d_simplices, combo)
        end
        push!(simplices, d_simplices)
        isempty(d_simplices) && break  # No higher simplices possible
    end

    SimplicialComplex(simplices)
end

function TDAmapper.validate(n::SimplicialNerve)
    n.max_dim >= 1 || throw(MapperArgumentError("SimplicialNerve — max_dim must be >= 1, got $(n.max_dim)"))
    return nothing
end

@testitem "SimplicialNerve" begin
    using TDAmapper
    using TDAmapper.Nerves

    # Build a simple covering manually:
    # 3 cover elements, each a list of point indices
    # cover[1] ∩ cover[2] ≠ ∅  → edge (1,2)
    # cover[1] ∩ cover[3] ≠ ∅  → edge (1,3)
    # cover[2] ∩ cover[3] ≠ ∅  → edge (2,3)
    # cover[1] ∩ cover[2] ∩ cover[3] ≠ ∅  → triangle (1,2,3)
    cover = [[1, 2, 3], [2, 3, 4], [1, 3, 5]]
    X = EuclideanSpace(collect(1.0:5.0))

    sc = make_graph(X, cover, SimplicialNerve())
    @test n_vertices(sc) == 3
    @test n_edges(sc) == 3
    @test n_triangles(sc) == 1
    @test dim(sc) == 2

    # max_dim=1 → edges only, no triangles
    sc1 = make_graph(X, cover, SimplicialNerve(1))
    @test n_vertices(sc1) == 3
    @test n_edges(sc1) == 3
    @test n_triangles(sc1) == 0
    @test dim(sc1) == 1

    # Two elements that overlap → edge exists
    cover2 = [[1, 2], [2, 3]]
    sc2 = make_graph(X, cover2, SimplicialNerve())
    @test n_vertices(sc2) == 2
    @test n_edges(sc2) == 1
    @test n_triangles(sc2) == 0

    # Two elements with no overlap → no edge
    cover3 = [[1, 2], [3, 4]]
    sc3 = make_graph(X, cover3, SimplicialNerve())
    @test n_vertices(sc3) == 2
    @test n_edges(sc3) == 0

    # validate: max_dim=0 throws
    @test_throws MapperArgumentError validate(SimplicialNerve(0))
    @test_throws MapperArgumentError validate(SimplicialNerve(-1))
    @test isnothing(validate(SimplicialNerve(1)))
    @test isnothing(validate(SimplicialNerve(2)))
end
