# Changelog

Notable changes to TDAmapper are recorded here.

## v0.1.1 — 5 November 2026

- Allow up to five minutes for Aqua's isolated precompile process to finish on
  Julia 1.12 when optional neural dependencies are present; keep the persistent
  task check enabled.

- Add native MLP filter parameter trees and optional explicit Flux/Lux adapters.
- Generalize optimize_filter to parameter trees and an optional regularizer;
  preserve caller parameters through out-of-place optimization, reject nonfinite
  objectives and omit empty cover elements from the loss graph.

- Prepare the package for its first General registry release.
- Add complete dependency compatibility bounds, an MIT license, and Aqua
  quality checks.
- Remove redundant `Base.convert` methods on vector types that caused type
  piracy; Julia's standard array conversion already provides this behavior.
- Add classical Mapper, Ball Mapper, cover/refiner/nerve implementations,
  Tables integration, soft Mapper, and loop-aware extended persistence.
