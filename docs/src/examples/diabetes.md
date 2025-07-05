# The Reaven and Miller diabetes dataset

Let's reproduce the results of [...].

## Dataset

To load the dataset, we will use an R package that contains it, and then convert it to a Julia DataFrame. You will need a working R installation for that.

```@example diabetes
using RCall
using TidierData
using TDAmapper

df = R"""
if (require("rrcov") == FALSE) {
    install.packages("rrcov")
}

library(rrcov)
data("diabetes")

diabetes
""" |> rcopy;
```

```@example diabetes
first(df, 10)
```

Now, let's extract only the numeric columns:

```@example diabetes
pre_X = @chain df begin
    @select(rw, fpg, glucose, insulin, sspg)
    Matrix    
end;
```

and normalize them:

```@example diabetes
function normalize(x)
    dev = std(x)
    if (std(x) ≈ 0) 
        dev = 1
    end
    (x .- mean(x)) ./ dev
end

X = mapslices(normalize, pre_X, dims = 1)' |> Matrix;
```

## Ball mapper

Now we calculate the ball mapper using all nodes, and setting $\epsilon = 0.5$:

```@example diabetes
mp = ball_mapper(X, [1:size(X)[2];], ϵ = 0.5);
```

The resulting graph is the following:

```@example diabetes
node_values = node_colors(mp, df.group .|> string)
node_positions = layout_mds(mp.CX, dim = 3)

mapper_plot(mp, node_values = node_values, node_positions = node_positions)
```

We colored each node by the most common type of diabetes of the points in the node. We can see two branches coming from the center: one going left, with overt type diabetes, and another one going up, with chemical type diabetes.
