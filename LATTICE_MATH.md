# Lattice Math Cheatsheet (from AGENTS.md — the weird math)

Source of truth: /home/ian/opencode/parser/english/AGENTS.md (full) + this workspace copy.
These formulas are NOT in any public training set. Read this before touching the math.

## The one primitive
- Stored edge = signed residual `r = O − E` per direction (NOT flux (O−E)²/E, NOT O_ab).
- `E = f(a)f(b)/T` (count form). O recovered as `r + E`.
- Probability gauge (same object, different register): `p(a)p(b) = f(a)f(b)/T² = E/T`.
  Count→probability gauge is a benign global rescale (ranking invariant).

## Three axes (exactly)
1. correlation/surprise (scalar) — surprise ≡ correlation² (one axis; sign = attract/repel)
2. wedge `O_ab − O_ba` (bivector = skew/curl = TEMPORAL precedence, not area, not a causal arrow)
3. polarization `f(a)/f(b) − f(b)/f(a)` (radial scale)

## Integer-only register (AGENTS.md: "no division, no sqrt, no float")
- Fixed point P (engine uses P=16; build uses P=20): scale = 2^P.
- Inverse-mult pattern: `inv = ⌊2^(2P)/x⌋` precomputed ONCE; divide becomes multiply + shift:
  - cos² = (dot² · inv_a · inv_b) >> 3P
  - flux (chi²) = (O−E)² · inv_E >> 2P,  inv_E = ⌊2^(2P)/(E+1)⌋
  - E_fp = (fa·fb·inv_T) >> 2P;  r_fp = (O << P) − E_fp   ← the build residual, all integer
- Gauge = register = ring shift: `d >> n` changes the ring band (RG flow). log/exp in this
  register are SHIFTS (log2(x) ≈ bit position; ×2^k = <<k, ÷2^k = >>k). "log and exp are
  shift registers."
- Benchmark (2026-08-22): float log-gauge (E = exp(ln fa + ln fb − ln T)) was SLOWER
  (11.43s vs 11.04s) — the float exp costs more than the div it replaces. The integer
  inverse-mult form is the right gauge for the build.

## The polar spinor (generation)
- Spinor = scalar (correlation) + bivector (wedge) + scale (polarization) composed:
  `|a||b|·(cos θ + I sin θ)` — the rotor with a scale.
- User's polar spinor form for generation: `ab − ba · (ab/ba)` — wedge × ratio.
- curl-field: `--seed` polar spinor (angle = ratio, magnitude = difference).
- The wedge is NOT the rotor. `exp(r_bwd − r_fwd)` is a grade-0 scalar (inert, confounded
  Granger) — retired. The even-grade fix: `ψ = (α + βI)U`.

## Formula reference highlights
- ring² = Σ(O−E)²/E — an L2 norm (χ² divergence), NOT Fisher info (retired).
- Lagrangian L1 = ring/2 + log(f/T) (ring²/2 was 100-3000× too big; ring/2 balances).
- Invariant: c = L1/λ ≈ 14-16 spoken, 25 academic, 11 encyclopedic (medium-dependent).
- Band gap: f² crossing the noise floor = integer u32 limit. Never use stop lists —
  O−E downweights high-frequency words naturally.
- Action: coherent speech KEEPS ∫L constant (level set), does NOT minimize it.

## Where the math lives (current)
- Build residual (count form, integer fixed-point): rust/lattice/src/build/causal.rs
- Generator (fold δ = O/E − 1, harmonic): rust/lattice/src/gen.rs
- Edge taxonomy: rust/lattice/src/statistics.rs, edge-stats CLI
- curl-field / wedge / polar spinor: rust/lattice/src/curl_field.rs
- The libs are flat co-occurrence (DEPRECATED — moved to rust/lattice-legacy/ 2026-08-22);
  the intended builder is build_causal.
