# IOTA cache validation

Current workflows pin [One v1.30.0](https://github.com/boringcache/one/releases/tag/v1.30.0) at `a610ec5a564efd9b360925056dbade04deb5def6`. Measurements below are from v1.21.0.

**Qualified, with publication errors to investigate.** All four cold and fresh-runner warm Linux workloads passed: feature checks, release builds, 129 Move tests, Rust tests and native examples. [Run and artifacts](https://github.com/boringcache/notarization/actions/runs/34326583419) · [Measurements](boringcache-validation.json).

The measured runs used One v1.21.0 at `90111526eb218a7f1e119ac2b29f765bd4d82734` with GitHub OIDC. One manages target/dependency archives; the public sccache adapter provides native compiler caching. GitHub archives the same directories plus its local compiler cache. Source, Rust 1.98.0, sccache 0.17.0, dependency lockfile and local sandbox are identical.

| Measurement | GitHub | BoringCache |
|---|---:|---:|
| Cold whole job | 64m41s | 64m25s |
| Warm whole job | 28m32s | 29m43s |
| Warm archive restore | 73 s | 37 s |
| Cold archive publication | 45 s | 84 s |

BoringCache read **2.81 GB** during the warm run, including native compiler reads, versus GitHub's **4.90 GB** archive: 42.6% less cache data read. BoringCache published nothing during warm execution. Both providers reduced compiler requests from 4,000 cold to 123 warm. Native Rust hits/misses were 7/18 with BoringCache and 5/20 with GitHub. Cold whole-job speed was similar; GitHub was faster warm in this sample.

The repository's build scripts modify tracked Move history and lock files. Typed Cargo target publication is therefore withheld. This integration archives the directories and lets Cargo check freshness. The 10.87 GB target snapshot published successfully and restored on the fresh runner.

The cold proxy logged **two HTTP 422 metadata write errors for a missing blob**. Strict shutdown and archive publication subsequently succeeded, but the cause and individual blob recovery remain unverified. Warm backend errors were zero. Warm sccache also reports 18 write errors while configured `READ_ONLY`; backend writes were zero. The report retains both tool and backend counters.

These are single samples with fresh tags in a shared workspace. Physical storage savings, later revisions, Windows, wasm and local-machine reuse are not measured. The demonstrated fit is retained Cargo state, lower restore traffic and native integration; the publication errors need investigation before a reliability claim.
