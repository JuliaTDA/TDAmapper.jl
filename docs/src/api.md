# API Reference

Strategies live in their named submodules. Import them explicitly, for example `using TDAmapper.Refiners: DBscan`. MetricSpaces' reexported API is documented in its own package guides.

## Pipeline, results, tables, and differentiable filters

```@autodocs
Modules = [TDAmapper]
Order = [:type, :constant, :function]
Public = true
Private = false
```

## Strategy modules

```@docs
TDAmapper
TDAmapper.ImageCovers
TDAmapper.DomainCovers
TDAmapper.Refiners
TDAmapper.Nerves
```

## Image and domain covers

```@autodocs
Modules = [TDAmapper.ImageCovers, TDAmapper.DomainCovers]
Order = [:type, :function]
Public = true
Private = false
```

## Interval covers

```@autodocs
Modules = [TDAmapper.IntervalCovers]
Order = [:type, :function]
Public = true
Private = false
```

## Refinement

```@autodocs
Modules = [TDAmapper.Refiners]
Order = [:type, :function]
Public = true
Private = false
```

## Nerves and simplicial complexes

```@autodocs
Modules = [TDAmapper.Nerves]
Order = [:type, :function]
Public = true
Private = false
```
