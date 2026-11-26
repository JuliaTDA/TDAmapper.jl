using Graphs: edges, src, dst, ne, nv
using TDAmapper, TDAmapper.Nerves

@testset "Point-membership nerves" begin
    X = EuclideanSpace([[Float64(i)] for i in 1:100])
    complete = [[1, i + 1] for i in 1:96]
    for (nerve, predicate) in [
        (SimpleNerve(), (a, b, k) -> k > 0),
        (MinCountNerve(1), (a, b, k) -> k >= 1),
        (MinCountNerve(2), (a, b, k) -> k >= 2),
        (JaccardNerve(1 / 3), (a, b, k) -> k / (a + b - k) >= 1 / 3),
        (PercentageNerve(0.5, :or), (a, b, k) -> max(k / a, k / b) >= 0.5),
        (PercentageNerve(0.5, :and), (a, b, k) -> min(k / a, k / b) >= 0.5),
    ]
        if predicate(2, 2, 1)
            graphs = Vector{Int}(undef, 100)
            Threads.@threads for i in eachindex(graphs)
                graphs[i] = ne(make_graph(X, complete, nerve))
            end
            @test graphs == fill(4560, 100)
        end

        cover = [[3, 2, 3, 1], Int[], [3, 2], [5, 6], [6], [1, 2, 3, 4]]
        reference = Set((i, j) for i in eachindex(cover) for j in (i + 1):length(cover)
            if !isempty(cover[i]) && !isempty(cover[j]) &&
            predicate(length(cover[i]), length(cover[j]), length(intersect(cover[i], cover[j]))))
        graph = make_graph(X, cover, nerve)
        @test nv(graph) == length(cover)
        @test Set((src(e), dst(e)) for e in edges(graph)) == reference
        @test nv(make_graph(X, Vector{Int}[], nerve)) == 0
    end
end
