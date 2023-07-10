"""
    epsilon_net(X, ϵ; distance)

Cover the PointCloud X with balls of radius ϵ. 
Returns the vector of indexes of X that are the ball's centers.
"""
function epsilon_net(X::PointCloud, ϵ::Number; metric = Euclidean())
    n = size(X)[2]

    covered = repeat([0], n)
    landmarks = Int32[]

    all_covered = false
    prog = ProgressUnknown("Searching neighborhood of point number")
    balltree = BallTree(X, metric)

    while all_covered == false
        # select the first non-covered index
        current_center = findfirst(==(0), covered)
        # add it to the landmarks set
        push!(landmarks, current_center)

        # get the elements currently covered by the epsilon ball around the current_center
        currently_covered = inrange(balltree, X[:, current_center], ϵ)
        
        # update the covered indexes
        covered[currently_covered] .= 1

        # check if all points are covered
        all_covered = minimum(covered) ≈ 1

        # change the progress meter
        ProgressMeter.next!(prog)
    end

    ProgressMeter.finish!(prog);

    return landmarks
end