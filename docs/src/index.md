
# TDAmapper.jl

**TDAmapper.jl** is a Julia package providing efficient implementations of Mapper-like algorithms from [Topological Data Analysis](https://en.wikipedia.org/wiki/Topological_data_analysis) (TDA). These algorithms transform high-dimensional data into graph representations, revealing the underlying topological structure of datasets.

## Overview

TDAmapper.jl is designed for:

- **Data visualization**: Construct graph representations of complex, high-dimensional data.
- **Shape analysis**: Investigate geometric and topological properties of datasets.
- **Dimensionality reduction**: Extract essential features while preserving topological information.
- **Clustering analysis**: Identify connected components and relationships within data.

## Features

- Multiple algorithms: Classical Mapper, BallMapper, and generalized variants.
- High performance: Optimized Julia implementations.
- Flexibility: Customizable covers, clustering methods, and filtering functions.
- Integration: Compatible with the Julia data science ecosystem.

## Quick Start

### Installation

To install TDAmapper.jl, use Julia's package manager:

```julia
using Pkg
Pkg.add(url="https://github.com/JuliaTDA/TDAmapper.jl")
```

Or in package mode:

```julia
] add https://github.com/JuliaTDA/TDAmapper.jl
```

### Example: Mapper Graph Construction

```julia
using TDAmapper

# Generate a torus point cloud
X = torus(2000)

# Define filter values (e.g., first coordinate)
fv = X[1, :]

# Create a uniform cover with overlap
C = uniform(fv, overlap = 150)

# Compute the mapper graph
mp = mapper(X, fv, C; clustering = cluster_dbscan(radius = 1.0))

# Visualize node values
node_values = node_colors(mp, fv)
mapper_plot(mp, node_values = node_values)
```

## Further Reading

For those new to Julia, consider the following resources:

- [Julia for Optimization and Learning](https://juliateachingctu.github.io/Julia-for-Optimization-and-Learning/stable/)

```@example quick_start
node_values = node_colors(mp, fv)

mapper_plot(mp, node_values = node_values)
```

## New to Julia?

That was too much Julia for you? No problem! You can learn more with some very nice books like these:

- [Julia for Optimization and Learning](https://juliateachingctu.github.io/Julia-for-Optimization-and-Learning/stable/)
