using RCall
using TidierData
using TDAmapper
using NetworkLayout

df = R"""
if (require("rrcov") == FALSE) {
    install.packages("rrcov")
}

library(rrcov)
data("diabetes")

diabetes
""" |> rcopy

pre_X = @chain df begin
    @select(rw, fpg, glucose, insulin, sspg)
    Matrix
    end

function normalize(x)
    dev = std(x)
    if (std(x) ≈ 0) 
        dev = 1
    end

    (x .- mean(x)) ./ dev
end

df |> names

@chain df begin
    @count(group)
end

X = mapslices(normalize, pre_X, dims = 1)' |> Matrix

fv = excentricity(X)
fv = excentricity(X, kernel_function = x -> exp(-(x^2)) / 5)
# fv = X[4, :]
covering = uniform(fv, overlap = 100, length = 4)
mp = mapper(X, fv, covering, clustering = x -> cluster_dbscan(x, radius = 1))
mp.graph

node_values = node_colors(mp, df.group .|> string)
node_values = node_colors(mp, fv)
node_positions = layout_mds(mp.CX, dim = 2)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)

node_values = node_colors(mp, df.group .|> string)
mapper_plot(mp, node_values = node_values, node_positions = node_positions)



mp = ball_mapper(X, [1:size(X)[2];], ϵ = 1)
mp.graph

node_values = node_colors(mp, df.group .|> string)
node_positions = layout_mds(mp.CX, dim = 2)
# node_positions = spring(mp.graph, dim = 3)

mapper_plot(mp, node_values = node_values, node_positions = node_positions)