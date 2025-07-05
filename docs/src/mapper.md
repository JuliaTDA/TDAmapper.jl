# (Classical) mapper

## Some theory

### Reeb graph

In topology, there are many ways by which we try to see what can't be seen, in particular high-dimensional sets. The [Reeb graph](https://en.wikipedia.org/wiki/Reeb_graph) is one of those ways: given a topological space $X$ and a continuous function $f: X \to \mathbb{R}$, we can collapse the connected components of its pre-images to get a graph that reflects the level-sets of $f$.

More formally, we define a relation $\sim$ on $X$ such that $p \sim q$ if-and-only-if $p$ and $q$ belong to the same connected component of $f^{-1}(c)$ for some $c \in \mathbb{R}$.

![The Reeb graph of a torus using the projection on the z-axis.](images/reeb.png)

### The (classical) mapper

The (classical) mapper is an algorithm to create [graphs](https://en.wikipedia.org/wiki/Graph_theory) from [metric spaces](https://en.wikipedia.org/wiki/Metric_space), and can be seen as an "statistical" version of the Reeb graph.

To be able to mimick the Reeb graph, we need to change some objects from the continuous setting to the discrete setting:

- $X = (X, d)$ is now a finite metric space, also called a *point cloud*;
- $f: X \to \mathbb{R}$ can be any function (since $X$ is discrete, $f$ is automatically continuous);
- instead of inverse images of *points* of $\mathbb{R}$, we calculate inverse images of *subsets* of $\mathbb{R}$ (usually intervals);
- instead of connected components (which are trivial in the discrete setting), we use some clustering algorithm (DBSCAN, single linkage, etc.) and consider these clusterings as "connected pieces of $X$".

![Mapper algorithm illustration](images/mapper.png)

The mapper graph can shed light to the geometry of $X$:

- nodes are clusters of points of $X$;
- edges indicate clusters that share points (i.e., overlap in the covering or clustering step).
