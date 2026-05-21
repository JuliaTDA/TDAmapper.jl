"""
    SimplicialComplex

A simplicial complex stored as lists of simplices grouped by dimension.

`simplices[d+1]` contains all d-dimensional simplices (0-indexed dimension):
- `simplices[1]` = vertices (0-simplices): `[[1], [2], ...]`
- `simplices[2]` = edges (1-simplices): `[[1,2], [1,3], ...]`
- `simplices[3]` = triangles (2-simplices): `[[1,2,3], ...]`
"""
struct SimplicialComplex
    simplices::Vector{Vector{Vector{Int}}}
end

SimplicialComplex(n_verts::Int) = SimplicialComplex([[[i] for i in 1:n_verts]])

"""Number of vertices (0-simplices)."""
n_vertices(sc::SimplicialComplex) = length(sc.simplices[1])

"""Number of edges (1-simplices)."""
n_edges(sc::SimplicialComplex) = length(sc.simplices) >= 2 ? length(sc.simplices[2]) : 0

"""Number of triangles (2-simplices)."""
n_triangles(sc::SimplicialComplex) = length(sc.simplices) >= 3 ? length(sc.simplices[3]) : 0

"""Maximum dimension of simplices in the complex."""
dim(sc::SimplicialComplex) = length(sc.simplices) - 1

function Base.show(io::IO, sc::SimplicialComplex)
    print(io, "SimplicialComplex with $(n_vertices(sc)) vertices, $(n_edges(sc)) edges, $(n_triangles(sc)) triangles (dim=$(dim(sc)))")
end

@testitem "SimplicialComplex" begin
    using TDAmapper
    using TDAmapper.Nerves

    # Construction from vertex count
    sc = SimplicialComplex(4)
    @test n_vertices(sc) == 4
    @test n_edges(sc) == 0
    @test n_triangles(sc) == 0
    @test dim(sc) == 0

    # Construction with edges
    sc2 = SimplicialComplex([[[1], [2], [3]], [[1, 2], [1, 3]]])
    @test n_vertices(sc2) == 3
    @test n_edges(sc2) == 2
    @test n_triangles(sc2) == 0
    @test dim(sc2) == 1

    # Construction with triangles
    sc3 = SimplicialComplex([[[1], [2], [3]], [[1, 2], [1, 3], [2, 3]], [[1, 2, 3]]])
    @test n_vertices(sc3) == 3
    @test n_edges(sc3) == 3
    @test n_triangles(sc3) == 1
    @test dim(sc3) == 2

    # Show method
    io = IOBuffer()
    show(io, sc3)
    s = String(take!(io))
    @test occursin("3 vertices", s)
    @test occursin("3 edges", s)
    @test occursin("1 triangles", s)
    @test occursin("dim=2", s)
end
