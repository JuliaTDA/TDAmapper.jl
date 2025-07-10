# TDAmapper.jl

Mapper-like algorithms from Topological Data Analysis.

## Installation

In Julia, type

```julia
] add https://github.com/JuliaTDA/TDAmapper.jl https://github.com/JuliaTDA/GeometricDatasets.jl
```

The `]` character mark the command to be executed in Julia package mode.

## First usage

Load the packages

```@example quick_start
using TDAmapper;
import GeometricDatasets as gd;
```

create a torus

```@example quick_start
X = gd.torus(2000)
```

define the filter values

```@example quick_start
fv = X[1, :];
```

and the cover

```@example quick_start
C = uniform(fv, overlap = 150);
```

Calculate the mapper

```@example quick_start
mp = mapper(X, fv, C; clustering = cluster_dbscan(;radius = 1))
```

and plot the results

```@example quick_start
node_values = node_colors(mp, fv)

mapper_plot(mp, node_values = node_values)
```

## New to Julia?

That was too much Julia for you? No problem! You can learn more with some very nice books like these:

- [Julia for Optimization and Learning](https://juliateachingctu.github.io/Julia-for-Optimization-and-Learning/stable/)
