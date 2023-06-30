using TDAmapper

X = Datasets.circle(1000)
excentricity(X)

# covering
fv = rand(1000)
uniform(fv)

[range(1, 1, length = 10)...] |> collect

# mapper.jl
using TDAmapper

X = Datasets.circle(1000)
fv = excentricity(X)
fv = X[:, 1]
cv = uniform(fv)

mp = mapper(X, fv, cv);
mp
mp.mapper_graph
mp