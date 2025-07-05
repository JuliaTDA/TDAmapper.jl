# Generalization

## What is a mapper algorithm?

We can boil down the two mapper algorithms we saw earlier as follows:

1. (covering step) Given a metric space $(X, d)$, create a covering $C$ of $X$;
2. (nerve step) Using $C$ as vertex set, create a graph.

In the classical mapper context, $C$ is generated using the clustering of pre-images of a function $f: X \to \mathbb{R}$. In the ball mapper scenario, we cover $X$ using $\epsilon$-balls with centers as a subset of $X$.

### Covering step

Let $X$, $L$ and $\epsilon$ be given as in the ball mapper case. For any $l \in L$, define $x_l$ = `X[:, l]`. Examples of how to generalize the covering step:

- Fix $n > 0$ integer. Create a ball $B$ of radius $\epsilon$ around $x_l$. If $B$ contains less than $n$ elements, then we redefine $B$ as the set of $n$ nearest neighbors of $x_l$.
- Fix $\lambda > 0$. Let $d_l$ be the distance between $x_l$ and its closest point. Create a ball $B$ of radius $\lambda * d_1$. Proceed like this to create a covering of $X$.

### Nerve step

There are many alternatives to the nerve construction. Let $a$ and $b$ be two elements of a covering $C$. Let $G = (V, E)$ be a graph with vertex-set $V = C$. Examples of how to generalize the nerve step:

- Fix $k > 0$. Define $(a, b) \in E$ iff $|a \cap b| \geq k$, that is: we will only allow intersections with at least $k$ elements. Setting $k = 1$ will give us the usual nerve graph.

## Creating my own mapper

You can change the 2 steps above within the context of the ball mapper, as can be seen in the docs.

```@docs
ball_mapper_generic
```
