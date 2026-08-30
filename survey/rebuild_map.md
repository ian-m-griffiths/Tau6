# Rebuild Project Knowledge Map

Source: `/home/ian/opencode/parser/english/` (the "english parser / semantic-lattice memory engine").
Scope: the Rust engine `rust/lattice/` (source of truth, `.latx` binary), the AGENTS.md "Canonical Truth"
section, and TODOS.md. All module claims below are from reading the code; doc claims are marked as docs.
There is **no THEORY.md** in this project — the canonical math lives in `AGENTS.md` L3–45
("## Canonical Truth (2026-08-18) — read this first").

Crate layout: `rust/lattice/Cargo.toml` — lib name `lattice`, binary `lattice-cli`
(`required-features = ["cli"]`). Features: default `native`; `lang-tools` (ported Python analysis
tools, compiled OUT by default); `python` (pyo3); `wasm` (wasm-bindgen). `lib.rs` exposes ~34 modules.

---

## §1 Module inventory (`rust/lattice/src/`)

| Module | Role | Status | Key types / functions |
|---|---|---|---|
| `gauge.rs` (255 ln) | Register/gauge stack as integer IDs. All four registers are the same invariant `δ = O/E−1 = (O−E)/E` scaled by a power of E: raw `E·δ`, fold `δ`, z `√E·δ`, surprise `E·δ²`. Includes the transform table (recover δ → re-scale to any gauge) and a gauge-carrying sum. | **Implemented + tested** (6 tests, incl. group-closure = PROVE-THE-MATH #3, `register_group_is_closed_under_composition` L223) | `Register` (Raw/Fold/Z/Surprise, `id()`, `kp()`, `keeps_sign()`, `cheapest()`), `GaugeSum::in_register`, `delta_from()`, `transform()` |
| `gauge_int.rs` (389 ln) | Integer pair `(a,b)` + a gauge that is the unit's own multiplication-table signature. Four signatures: Gaussian (`i²=−1`), **Eisenstein (`ω²=−ω−1`, 60° triangular)**, Minkowski (`j²=+1`), Null (`ε²=0`). Five magnitude/norm forms + integer sqrt + quadrant sign-separation. | **Proof-of-concept code** (TODOS #16, "PROOF-OF-CONCEPT DONE", 10 tests). NOT integrated into the pipeline — CLI demo (`gauge-int`) only; "next: integrate into simd/cosine" is TODO | `Signature`, `GaugeInt{a:i64,b:i64,sig}`, `mul()` (i128), `norm_sq()`, `conjugate()`, `rotate()`, `NormForm` (Gaussian/Eisenstein/Hexagonal/Branchless/SignedTriangle), `isqrt()`, `quadrant()`/`from_quadrant()` |
| `clifford.rs` (311 ln) | Standalone Clifford algebra Cℓ₀,ₙ for the even-grade spinor. Blades = u32 bitmasks over the Boolean hypercube (XOR = blade product, parity = sign). | **Implemented but NOT wired into the residual graph** ("standalone module… for now it is just the algebra + tests"). TODOS #13 split: algebra DONE, spinor wiring TODO | `Blade=u32`, `Multivector(HashMap<u32,f32>)` (geom/wedge/reverse/involute/even_part), `rotor()`, `rotate()`, `spinor_from_primitives(area, wedge)`, lean `Rotor{scalar,bivector}` (`magnitude()`, `angle()`) |
| `isa.rs` (176 ln) | Semantic ISA — a register machine over the 12 lattice opcodes: LKP/FMT/DO/WEDGE/RING/DEC programs (`;`-separated) run against a `.latx`. | **Implemented + tested**; `run` CLI command (TODOS A7 "DONE (core)") | `Op` enum, `parse()`, `Machine{a,r,last_wedge}`, `run()` |
| `build/causal.rs` (446 ln) | **Production builder** — raw text → `.latx` causal DAG (bytes → subwords → words → compounds → concept edges). Signed directional O−E residual (N7), integer fixed-point P=20 via inverse-multiply (`residual_fp`, zero division/float), u32 word interning (84% build time was string hashing), directional co-occurrence so the wedge survives. Port of `scripts/smush_causal.py`. | **Implemented + tested; production** (`build` CLI). Replaces deprecated `build_flat` (moved to `rust/lattice-legacy/`) | `residual_fp(o,fa,fb,inv_t)`, `build_causal()`, `make_byte_stream()`, `CausalBuild` (u32-native, no string adjacency), `common.rs` (cleaning D3/D7), `build/mod.rs` |
| `statistics.rs` (143 ln) | Edge-statistics taxonomy: reconstruct the three axes from stored primitives `{r_ab, r_ba, f(a), f(b), T}`. E = f(a)f(b)/T is symmetric → wedge `O_ab−O_ba` reduces to `r_ab−r_ba`. | **Implemented + tested**; `edge-stats` CLI (C3) | `EdgeStats` (corr_ab/corr_ba, surprise_ab, wedge, polarization, signed_mutual, quadrant), `edge_stats()` |
| `simd.rs` (104 ln) | SSE2 SWAR prototype for log-space int16 gauge sums (8×i16 per `_mm_add_epi16`). | **Implemented + tested**, but explicitly NOT a build speedup (build is HashMap-bound, profiling 2026-08-21); targets the query path (C5/A8/R12) | `sum_i16_scalar`, `sum_i16_sse2`, `benchmark()` |
| `curl_field.rs` (335 ln) | Directed curl/div field from stored residuals — the TRUE wedge-based curl (supersedes `anti_symmetric.rs`'s symmetrized heuristic). Helmholtz split: `flow(w)=Σ(r_w→nb − r_nb→w)` (skew: SOURCE/SINK/center) + `sym` (symmetric correlation density). Polar spinor: `(angle=O_ab/O_ba, magnitude=O_ab−O_ba)`; even-grade spinor `E + i·w`. | **Implemented + tested**; `curl-field` CLI (C2, live) | `CurlField{flow,sym,edges}`, `build_curl_field()`, `EdgeCurl{wedge,ratio,log_angle}`, `polar_spinor()`, `spinor()` (→ `clifford::Rotor`), `polar_neighbors()`, `vector_field()`, `positions()` |
| `gen.rs` (592 ln) | Functional port of `scripts/lattice_gen.py` measured phrase generation: candidate distribution = DIRECTED forward residual `r(w→nb)` (attraction only), weighted by polar spinor (direction ratio × log-strength), harmonic fold term `δ=r/E`, topic/arrow/temporal axes from target chain, GLUE list, softmax at `temp`. | **Implemented + tested**; `generate` CLI (C1, live). R9 note: the measured-bigrams grammar channel still needs a raw-corpus bigram store (not in `.latx`) | `generate(idx, seed, target_words, steps, temp, rng, use_spinor)`, `tokenize()`, GLUE/CONNECTORS consts |
| `latx.rs` (772 ln) | `.latx` binary format reader. v3 format: header "LATX" + section TOC (TAG_*), gzip-compressed vocab, per-word edge offsets, mmap. `lookup_word` = targeted O(vocab+degree) lookup (R7: consult 40s → 8.4s). `LatticeIndex::load` full-load fallback for v1/v2. | **Implemented; core format module** | `LatticeIndex{vocab,layers,edges,compounds,metadata,freqs,total}`, `WordLookup`, `lookup_word()`, `read_header()`, `is_v3()` |
| `lookup.rs` (86 ln) | `lattice-lookup` scoring: surprise filter (square + mean-threshold, rank by χ² `r²/E`) and `--least` mode (argmin correlation = most-repelled). | **Implemented + tested** (R4/D9, live) | `scored_neighbors(wl, least)` |
| `store.rs` (153 ln) | `store-text` write path: role-tagged co-occurrence (window 6, forward direction only) → JSON nodes → `.latx` append via down-operator. The plugin write path in Rust. | **Implemented + tested**; `store-text` CLI (D7 partial) | `tokenize()` (byte-native), `build_nodes()`, `store_text()` |
| `ring_index.rs` (247 ln) | Ring-sorted fractal index: power iteration + deflation eigenvectors over the cosine matrix; words sorted by (ring band, eigen angle); query = window ±K + cosine filter. | **Implemented + tested**; `ring-index` CLI | `eigenvectors()`, `build_ring_index()`, `query_by_ring()`, `RingEntry` |
| `anti_symmetric.rs` (191 ln) | Anti-symmetric derivative field (port of `scripts/anti_symmetric.py`): D(A,B) = ring_A × cos × angle_sign on **symmetrized** vectors; divergence = topic critical points. | **Implemented + tested**, but **superseded by `curl_field.rs`** (its header: curl_field "unlike anti_symmetric.rs which builds a heuristic ring×cos×angle_sign field on the SYMMETRIZED vectors") | `dominant_eigenvector()`, `build_gradient_field()`, `word_info/gradient/divergence` |
| `do_operator.rs` (140 ln) | Rung-2 intervention: sever `w`'s incoming edges (parents), backdoor adjustment `do(w→nb) = r(w→nb) − Σ_p r(p→nb)·r(p→w)/Σ r(p'→w)`. | **Implemented + tested**; `do-operator` CLI (TODOS #11 A "DONE") | `parents()`, `backdoor()`, `do_effect()`, `do_operator_report()` |
| `wedge_sense.rs` (268 ln) | Bivector sense decomposition of polysemous words: cosine bisection into two sense clusters, wedge bivector between centroids = the anti-symmetric plane separating meanings. Shared vector/cosine primitives used by many modules. | **Implemented + tested**; `wedge-sense` CLI | `Vector`, `symmetric_vectors()`, `norms()`, `cosine()`, `wedge_bivector()`, `wedge_stats()`, `SenseDecomposition`, `compute_sense_decomposition()` |
| `fractal_lut.rs` (279 ln) | Fractal LUT bit-descent, O(log n) argmin: hybrid signatures (high bits = ring band, low bits = topic angle), kernel `G[d]=avg cosine at XOR distance d`, bit-impact profile, greedy bit-flip descent vs brute force. | **Implemented + tested**; `fractal-lut` CLI | `XorShift64` (deterministic PRNG), `build_signatures_hybrid()`, `build_kernel()`, `bit_impacts()`, `find_opposite_fractal()`, `find_opposite_bruteforce()` |
| `cosine.rs` (279 ln) | Integer cosine² via inverse-mult (P=16, `cos² = (d²·inv_a·inv_b)>>3P`), scalar i64 dot + AVX2 8×f32 FMA + rayon parallel scan. | **Implemented + tested**; `query` CLI (PCA-index path, legacy) | `cos2_scalar`, `cosine_scalar`, `cosine_best`, `full_scan`, `full_scan_parallel` |
| `entropy.rs` (236 ln) | Bidirectional conditional entropy as universal segmentation operator: `H(a|b)+H(b|a)` — low = compound, high = split. Bit-for-bit port of `scripts/entropy_segmenter.py`. | **Implemented + tested**; `entropy` CLI | `tokenize_simple()`, `build_token_counts()`, `build_byte_counts()`, `bidirectional_surprise()`, `segment_tokens()` |

### Supporting modules (read, not in the requested list)
- `latx_writer.rs` (1427 ln) — the write side: build-latx, append/ingest, prune, merge; v3 format writer (section TOC + per-section CRC-32, FLAG_COMPOUND/FLAG_FREQ). Core.
- `bfs_kernel.rs` (293 ln) — XOR doc-kernel builder O(N + sparse pairs) via inverted index (`doc-kernel-build` CLI).
- `consult.rs` (271 ln) — cross-source consult over libs; `surprise_rank` = the production "square + mean-threshold" filter (C4).
- `format.rs` (338 ln) — `format-topic` kernel + role merge/strip (used by isa.rs).
- `sense_cluster.rs` (384 ln) — sense clustering. `geometry.rs` (74) — ring bands. `topic.rs` (110) — `topic-map`. `join.rs` (140) — cross-source overlap. `context_classifier.rs` (167) — PTB-ish roles. `idx.rs` (154) — legacy PCA index. `ptb.rs`, `subword.rs`, `crc32.rs`, `wasm.rs`, `python.rs` (feature-gated).
- `lang/` (feature `lang-tools`, compiled out by default): eigen, harmonic, spectrum, cluster, tree, entropy_analysis, frame, eigenmatrix — all marked DONE in TODOS.
- `experiments/` — 10 DIAGNOSTIC CLI commands, all DONE per TODOS Tier 1–3: `fluctuation_theorem` (#1 wedge irreversibility, corpus forward-biased 0.88/0.90, conversation 0.525), `cross_fitting` (#2 fold-split bias fix — plug-in `(O−E)²/E` has Poisson bias 1; fix deferred to build-time), `escort` (#4 signed-gauge variant), `loop_polarity` (#5 100% reinforcing — pure attractor), `invariance` (#6 Cho/Peters causal-robustness), `directed_spectrum` (#7 ‖skew‖/‖sym‖ rotational fraction), `legendre` (#8 well-defined), `jacobian` (#9 contraction, |λ|<1), `gramian` (#11B reachability — NON-discriminating, one giant SCC), `eigen_bench` (#15 Jacobi S/W/D split + `--ga` Hermitian spinor; **z register is the natural complex variable**).

---

## §2 The canonical math (with file locations)

Source: `AGENTS.md` L3–45 (Canonical Truth), cross-checked against code.

- **Stored primitive = the signed residual `r = O − E` per direction** — NOT the flux `(O−E)²/E`, NOT `O_ab`. `O` is recovered as `r + E`; `E = f(a)f(b)/T` (count form). (AGENTS.md L13–15; `statistics.rs` L9–13, L61–65; `build/causal.rs` `residual_fp` L49–52.) `p(a)p(b) = f(a)f(b)/T² = E/T` is the same object in a different gauge (register) (AGENTS.md L15).
- **Three axes (exactly):**
  1. correlation/surprise — scalar, one axis (`surprise ≡ correlation²`; surprise = anti-correlation `O<E`, the χ² magnitude is ORDER not surprise, keep the sign) (AGENTS.md L16–17, L24–25; `statistics.rs` L4–7).
  2. wedge `O_ab − O_ba` — bivector = the SKEW part / curl = temporal precedence. **Not** bivector area, **not** a causal arrow (AGENTS.md L17–18, L31–32). `E` symmetric ⇒ wedge = `r_ab − r_ba` (`statistics.rs` L12–13; `curl_field.rs` L1–16).
  3. polarization `f(a)/f(b) − f(b)/f(a)` — radial scale (`statistics.rs` L70–74).
- **The ring is a χ² divergence value = an L2 norm** (`ring² = Σ(O−E)²/E`), NOT Fisher information (a matrix ∝ 1/frequency — inverted) (AGENTS.md L19–20; ring computed in `isa.rs` L119–122 and `curl_field.rs` `positions`).
- **Gauge = register = ring shift.** The register stack is the same invariant `δ = O/E − 1` in four gauges: raw `E·δ`, fold `δ` (THE invariant), z `√E·δ`, surprise `E·δ²` (`gauge.rs` L1–31, L39–48, `Register::kp()`). "The `−1` in `δ = O/E−1` is the gauge normalisation… `r = O−E = E·δ` is the fold in the additive gauge" (`gauge.rs` L12–18). The barrel shift `d >> 1` (ring shift) is a gauge transformation through the renormalization group (docs: AGENTS.md "Quantum Properties" § Boolean hypercube, "Multi-level topic modeling via ring shifts"; TODOS M2/F9).
- **Integer fixed-point register:** P=20 fixed point (`SCALE = 2^20`), inverse-multiply pattern: precompute `inv_T = ⌊2^(2P)/T⌋` once, then `E_fp = (fa·fb·inv_T) >> 2P` and `r_fp = (O << P) − E_fp` — one u128 multiply, two shifts, **zero division, zero float** (`build/causal.rs` L37–52). Same inverse-mult pattern for cosine² (P=16) in `cosine.rs` and the "Integer Operations Reference" (AGENTS.md L1137+).
- **Action / Lagrangian:** coherent speech keeps `∫L` *constant* (a level set), it does NOT minimize it; `T = ring/2` (not `ring²/2`) (AGENTS.md L21–23).
- **Wedge is not the rotor.** The rotor `exp(r_bwd−r_fwd)` is a grade-0 inert scalar (confounded Granger); the combined object is the spinor `|a||b|(cos θ + I sin θ)`; the even-grade fix is `ψ = (α + βI)U` (AGENTS.md L26–29; `clifford.rs` `spinor_from_primitives` L161–165, `Rotor` L182–215).
- **Causality is Rung-1 association** — sign/wedge is an orientation signal, never a causal arrow; "causation vs gravity" collapses to the polarization axis (AGENTS.md L31–32). The do-operator is the first Rung-2 move (`do_operator.rs` L1–12).
- Retired/negative claims to respect when porting: ring ≠ Fisher info; natural gradient ≠ L1; "least squares = least action" is a large-deviations rate function only; the fiber bundle is a trivial fibered SET; attractor = two opposite zeros; band gap = noise-floor cutoff (AGENTS.md L35–45).

---

## §3 What's live vs planned (code vs TODO)

| Item | Status | Evidence |
|---|---|---|
| **gauge registers** (Raw/Fold/Z/Surprise) | **LIVE (code + tests)** — used conceptually everywhere; `edge-stats`/`eigen-bench --register` consume it | `gauge.rs` (whole module); C6 DONE (TODOS L217) |
| **gauge_int** (integer pair + Signature) | **CODE, proof-of-concept only** — self-contained + 10 tests + `gauge-int` CLI demo; NOT wired into simd/cosine or the graph | `gauge_int.rs`; TODOS #16 (L120) "PROOF-OF-CONCEPT DONE… Next: integrate into simd/cosine (step 3) + gauge-as-dimension (step 4)" |
| **Signature axis** | **CODE only inside gauge_int** — the `Signature` enum (Gaussian/Eisenstein/Minkowski/Null) is a compile-time multiplication-table (gauge-as-unit-property), NOT one of the three production axes. No other "signature axis" exists in code or TODOS | `gauge_int.rs` L18–30 |
| **Eisenstein (mod-6 / 60° triangular)** | **CODE (proof-of-concept)** — `Signature::Eisenstein` (`ω²=−ω−1`), `NormForm::Eisenstein` (`a²−ab+b²`), `Hexagonal` (`max(|a|,|b|,|a+b|)`); isotropy confirmed only for elliptic signatures (Gaussian + Eisenstein). **The literal term "mod-6" does NOT appear anywhere in the rebuild project** (searched AGENTS.md, TODOS.md, docs/, sessions/) — if the hexagon project plans a "mod-6 spinor", the only ported artifact is this Eisenstein machinery | `gauge_int.rs` L23–25, L80, L143–149; TODOS #16 findings |
| **Spinor** | **Split:** polar spinor (`angle=O_ab/O_ba`, `magnitude=O_ab−O_ba`) is **LIVE** (`curl_field.rs::polar_spinor`, consumed by `gen.rs` C1). Even-grade Clifford spinor `ψ=(α+βI)U`: algebra library DONE (`clifford.rs`), **wiring into the graph NOT done** (TODOS #13, "SPLIT… a SEPARATE later step — don't use the algebra for everything yet") | `curl_field.rs` L194–214; `gen.rs` L328–357; TODOS #13 L116 |
| **causal** (DAG builder) | **LIVE — production build** (`lattice-cli build`), signed directional O−E, integer fixed point; compounds in `.latx` verified (R8 DONE) | `build/causal.rs`; TODOS R8 |
| **Rebuild of the real libs** (N17/N18 — 23 consult libs + english.latx as directional signed `.latx`) | **TODO — release gate**, not yet done (current libs are still the old symmetric build per TODOS N17 L223; but RELEASE PLAN L137–139 says the stack is already directional and N17 is "MOOT" — conflicting notes; treat lib state as unverified) | TODOS L219–225, L136–139 |
| **do-operator / Rung-2** | **LIVE** (CLI). Companion #11B reachability Gramian **DONE but NON-discriminating** (one giant SCC) | `do_operator.rs`; TODOS #11 L114 |
| **Measured-bigram grammar channel** (R9/A4) | **PARTIAL** — polar-spinor scoring done; raw-corpus bigram store (the grammar layer) not yet in `.latx`; `emit_raw` flag exists on `build` to dump O_ab counts | TODOS R9 L158; `build` CLI `--emit_raw` (main.rs L747) |
| **Experiments (PROVE THE MATH)** | All 10 Tier-1/2/3 items **DONE** (see §1 experiments row) | TODOS L77–120 |

---

## §4 Most PORTABLE primitives (things another project can reuse outright)

1. **Integer fixed-point residual `r = O−E`** — P=20 inverse-multiply, zero division/float; `E = fa·fb/T` with precomputed `inv_T = ⌊2^(2P)/T⌋`, `r_fp = (O<<P) − E_fp`. Drop-in for any counting/co-occurrence engine (`build/causal.rs` L37–52).
2. **The gauge transform table** — `δ = O/E − 1` invariant; 4-register ladder (raw/fold/z/surprise) with `(k,p)` scaling, `delta_from`/`transform`, `GaugeSum` (gauge-carrying sums), group-closure proven by test. Fully self-contained, float-only (`gauge.rs`).
3. **The polar spinor + even-grade rotor** — `(angle = O_ab/O_ba, magnitude = O_ab − O_ba)` and `Rotor{E, w}` with mixing angle `θ = atan2(w, E)`; one-vector form of a directed edge's direction+strength (`curl_field.rs` L190–214; `clifford.rs` L182–215).
4. **Three-axis edge statistics** — full reconstruction `{corr, surprise, wedge, polarization, signed_mutual, quadrant}` from just `{r_ab, r_ba, f_a, f_b, T}` (`statistics.rs`).
5. **Curl/div Helmholtz split on directed residuals** — `flow` (skew: temporal source/sink) and `sym` (correlation density) in one O(E) pass (`curl_field.rs` L69–125).
6. **Do-operator backdoor adjustment** — sever parents, `do = raw − Σ_p r(p→nb)·r(p→w)/Σ|r(p→w)|` (`do_operator.rs`).
7. **XOR-kernel fractal signatures + bit-descent** — hybrid (ring|topic) u32 signatures, `G[d]` kernel, O(log n) greedy argmin (`fractal_lut.rs`).
8. **Integer cosine² inverse-mult (P=16)** with scalar/AVX2/rayon backends (`cosine.rs`).
9. **Bidirectional entropy segmentation** — `H(a|b)+H(b|a)` merge/split operator, bit-for-bit vs Python (`entropy.rs`).
10. **GaugeInt integer algebra** — `(a,b)` pair + signature (Gaussian/Eisenstein/Minkowski/Null), i128-safe mul, norm forms incl. hexagonal norm — the cleanest "integer spinor" building block, though still proof-of-concept (`gauge_int.rs`).
11. **`.latx` v3 binary format + mmap targeted lookup** — section TOC, gzip vocab, per-word edge reads O(vocab+degree) (`latx.rs`); the write side in `latx_writer.rs`.

## Porting cautions
- Keep the **sign** of the residual everywhere; surprise/order = `abs()` later. The wedge `O_ab−O_ba = r_ab−r_ba` requires **directional** (never symmetrized) storage — the old flat/symmetric builders destroyed it (N7/N9 fixes).
- Retired claims to NOT port as facts: ring = Fisher information; rotor = causality; wedge = bivector area; flux `(O−E)²/E` as the stored primitive; "least action" as minimization (AGENTS.md L35–45, "Dead claims" L46–48).
- `anti_symmetric.rs` (symmetrized heuristic) is superseded by `curl_field.rs` (directed) — port the latter.
- Surprise ranking's plug-in `(O−E)²/E` has a known Poisson bias (expected value 1 under the null); the unbiased cross-fit form exists in `experiments/cross_fitting.rs` but the build-time fold-split fix is deferred (TODOS #2).
