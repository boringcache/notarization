# IOTA cache validation

Qualified for validation of Cargo target and native compiler reuse across the Linux Rust and Move checks. [Cold and warm run](https://github.com/boringcache/notarization/actions/runs/34321934857).

One v1.21.0 is pinned to `90111526eb218a7f1e119ac2b29f765bd4d82734` and uses GitHub OIDC. One manages Cargo target/dependency archives; the public sccache adapter provides native compiler caching for the whole workload. The baseline uses GitHub archive caching with sccache.

Both providers use upstream source `06968cbc306df046ddd0ece11a2a7c048280a8c5`, Rust 1.98.0, the committed validation lockfile, and the same local IOTA sandbox. They run per-member feature checks, release builds, Rust tests, Move tests and native examples. Cache-destructive intermediate cleans are removed for both providers.

The first build exposed a repository constraint: its Rust build scripts update tracked Move history files, so typed Cargo target publication is withheld. The revised integration uses ordinary Cargo archives, matching the baseline’s restore semantics, plus native sccache. It preserves the generated files and lets Cargo validate freshness. The earlier run remains useful for workload diagnosis, but does not prove target publication. The revised cold/warm comparison is pending.

Scope is Linux native CI. Windows, wasm and a later upstream revision are not measured by this workflow. Results will include total workload time, restore/publication costs and storage evidence; they will not assume every phase is faster than GitHub.
