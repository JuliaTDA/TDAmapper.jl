include("Mapper.jl");
"""
    epsilon_net(X)

Returns a vector of indeces of X
"""
function epsilon_net(X::PointCloud, ϵ::Real; distance = Euclidean())
    n = size(X)[1]
    Xᵗ = transpose_matrix(X);

    covered = repeat([0], n)
    landmarks = Int32[]

    all_covered = false
    prog = ProgressUnknown("Searching neighborhood of point")

    while all_covered == false
        current_center = findfirst(==(0), covered)
        push!(landmarks, current_center)
        
        distances = colwise(Euclidean(), X[current_center, :], Xᵗ)

        close_ids = findall(x -> x < ϵ, distances)

        covered[close_ids] .= 1

        all_covered = size(filter(iszero, covered))[1] == 0

        ProgressMeter.next!(prog)
    end

    ProgressMeter.finish!(prog);

    return landmarks
end

X = rand(30000, 5)
X isa PointCloud
ϵ = 0.3
ids = epsilon_net(X, ϵ)

Y = X[ids, :]