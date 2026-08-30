# Isomorphic Gauge Variants of Standard Math — a cheat-sheet / knowledge-graph map

**Purpose.** A map for an expert in *any* field to get oriented in this project in under a
week. The thesis: many standard-math objects are **isomorphic gauge variants** of one
another — the *same underlying structure read in a different gauge, answering a different
geometric question*. This file names the gauges (subscripts), tables the variants, draws
the relationship graph, translates the sums, and gives the method.

**Honesty legend (the project's calibration labels — see §5).**
Every claim below carries one of:

| Label | Meaning |
|---|---|
| **DIRECT** | Same math, **proved** in this repo's Lean ledger (`lake build` green, listed in `proofs/INDEX.md`) — or standard classical math cited as such |
| **ANALOGY** | Parallel structure, different object (per `survey/SYNTHESIS.md` §2) |
| **OURS** | The project's own object/framing — one side only |
| **SPECULATION** | Unproven on both sides |

All paths are relative to this repo root. The Lean files live under
`proofs/lean-src/hexagon/Hexagon/`; the ledger is `proofs/INDEX.md`.

---

## §1 The naming convention

**Rule: the subscript is the signature — the value whose square defines the
multiplication — and, by extension, the gauge parameter that says *which question the
object answers*.** Write the object's name with the gauge appended:
`X_<gauge>`. The convention is *derived from names the artifacts already use*:
`Signature i² ∈ {−1,+1,0,ω}` (rebuild `gauge_int.rs`, TODO #16, `ox alpha.md` L3109),
the register rungs raw/fold/z/surprise (`gauge.rs`), the `E₆₀`/`E₁₂₀` conventions
(`Conventions.lean` vs mathlib), and τ vs π (`Packing.lean`). The cheat-sheet just makes
the scheme uniform.

### The full list

**A. The four signature algebras** ("the 1+dimensional geometric-property variants" —
the same pattern: a 2-dimensional algebra over ℤ/ℝ whose unit's square is a signature,
with a norm and a unit group). The subscript is literally the signature value:

| Subscript | Signature | Object | The question it answers |
|---|---|---|---|
| `i₋₁` | `i² = −1` | ℂ / Gaussian integers ℤ[i] | *What is an exact 90° rotation?* (elliptic) |
| `i₊₁` | `i² = +1` | split-complex numbers ℝ[j]/(j²−1) | *What is an exact boost (hyperbolic rotation)?* |
| `i₀` | `i² = 0` | dual numbers ℝ[ε]/(ε²) | *What is an infinitesimal?* (nilpotent) |
| `i_ω` | `i² = ω` (ω = e^(iπ/3)) | Eisenstein integers ℤ[ω] | *What is an exact 60° rotation?* — **the proved case** |

**B. Convention gauges** (the same object re-parameterized, not a different object):

| Subscript | Meaning |
|---|---|
| `E₆₀` | Eisenstein with generator ω = e^(iπ/3), norm `a²+ab+b²` — this repo's convention |
| `E₁₂₀` | Eisenstein with generator ω' = e^(2πi/3) = ω², norm `a²−ab+b²` — mathlib / `gauge_int.rs` convention |
| `τ` / `π` | angular-unit gauge: full turn (τ = 2π) vs half turn (π) — Ian's convention is τ |
| `[count]` / `[prob]` | measuring-stick gauge: `E = f(a)f(b)/T` vs `p(a)p(b) = E/T` — a register shift by `T` |

**C. Register gauges** (the one invariant δ = O/E − 1 in four read-outs — subscript =
which rung of the ladder):

| Subscript | Rung | Relation to the invariant |
|---|---|---|
| `r_raw` | raw | `r = O−E = E·δ` (the stored primitive) |
| `δ` | fold | `δ = O/E − 1` — **the gauge-invariant core itself** |
| `z` | z (Pearson) | `z = (O−E)/√E = √E·δ` |
| `s` | surprise | `s = (O−E)²/E = E·δ²` (χ² summand; sign collapsed) |

**D. The three axes** (the residual decomposed — the *only* three):

| Subscript | Axis | Meaning |
|---|---|---|
| `⊥` | correlation/surprise | scalar; surprise ≡ correlation² (one axis, sign = attract/repel) |
| `∧` | wedge | skew `O_ab − O_ba` — temporal orientation, NOT area, NOT a causal arrow |
| `‖` | polarization | radial scale `f(a)/f(b) − f(b)/f(a)` |

**E. The one primitive** (no subscript needed — it *is* the gauge-invariant object):

| Name | Definition |
|---|---|
| `r` | the signed residual `r = O − E`, `E = f(a)f(b)/T`; O recovered as `r + E` |

---

## §2 The variant table

Columns: subscript | object | defining relation ("the sum") | geometric meaning |
field | Lean proof path | status.

| # | Subscript | The object | Defining relation ("the sum") | Geometric meaning | Field | Lean proof path | Status |
|---|---|---|---|---|---|---|---|
| 1 | `i₋₁` | Gaussian integers ℤ[i] ⊂ ℂ | `i² = −1`; `N(a+bi) = a²+b²`; units {±1, ±i} = **Z₄** | exact 90° rotation; Euclidean area (N = squared length) | complex analysis; algebraic number theory; 2D rotation engineering | **none in this repo.** `EuclideanDomain.lean` header cites mathlib `GaussianInt` as its model ("mirrors mathlib `NumberTheory/Zsqrtd/GaussianInt.lean`") — the Gaussian case is standard classical math, not ported here | DIRECT (classical, external); not in ledger |
| 2 | `i₊₁` | split-complex numbers ℝ[j]/(j²−1) | `j² = +1`; zero divisors `(1+j)(1−j) = 0`; `N = a²−b²` | hyperbolic rotation / boost; Minkowski signature | hyperbolic geometry; special relativity (1+1 D) | **none.** Code-level POC `Signature::Minkowski` in the rebuild's `gauge_int.rs` (recorded in `survey/rebuild_map.md`); `survey/porting_map.md` D3: isotropy does **not** hold here | ANALOGY (standard algebra; unproved here) — "gauge variant" status is project framing |
| 3 | `i₀` | dual numbers ℝ[ε]/(ε²) | `ε² = 0`; nilpotent ε; `a + bε` | infinitesimals / tangent direction | automatic differentiation; synthetic differential geometry | **none.** Code-level POC `Signature::Null` in `gauge_int.rs` | ANALOGY (standard algebra; unproved here) |
| 4 | `i_ω` | Eisenstein integers ℤ[ω], ω = e^(iπ/3) | `ω² = ω − 1`; `N(a+bω) = a²+ab+b²`; units {±1, ±ω, ±ω²} = **Z₆**; N = det of the regular rep | exact 60° rotation; hexagonal lattice; N is the **area scalar** (Z₆-invariant, multiplicative) | number theory (ED → UFD); hexagonal packing; geospatial DGGS (H3) | **T0/T1** `Conventions.lean` (`mul_comm`, `norm_mul`); **T3a/T3b** `Rotation.lean` (`units_card`, `units_closed_under_mul`); **G1** `Gauge.lean` (`norm_of_unit`, `norm_mul_unit`, `norm_unit_mul`, `norm_eq_det`, `units_eq_omega_powers`, `omegaPow_six`); **T5** `EuclideanDomain.lean` (`instCommRing`, `instEuclideanDomain` → UFD) | **DIRECT — PROVED** (INDEX T0, T1, T3, T5, G1) |
| 5 | `E₆₀` ⇄ `E₁₂₀` | the **same ring**, two generators | `E₆₀`: ω = e^(iπ/3), N = a²+ab+b²; `E₁₂₀`: ω' = ω² = e^(2πi/3), N' = a²−ab+b²; isomorphism **φ(a,b) = (a, −b)** | the same hex lattice, mirror-flipped basis; ω' = ω² means ℤ[ω'] = ℤ[ω] | conventions/notation (mathlib & `gauge_int.rs` are 120°; this repo is 60°) | `ConventionBridge.lean` (`phi_add`, `phi_mul`, `phi_phi`, `norm_preserved`) | **DIRECT — PROVED** (INDEX C1) |
| 6 | `r_raw` / `δ` / `z` / `s` | the register ladder — **one invariant** `δ = O/E − 1` in four gauges | raw `r = E·δ = O−E`; fold `δ = O/E−1 = r/E`; z `= √E·δ = (O−E)/√E`; surprise `s = E·δ² = (O−E)²/E` (a χ² summand) | the same deviation-from-independence read as: absolute surplus / ratio / noise-units / squared structure (sign destroyed) | statistics (Pearson residual; χ²; z-score) | **R1** `Residual.lean` (`E`, `residual`, `ringSq`, `sum_E_row`, `sum_residual_eq_zero`, `wedge_antisymm`, `ringSq_nonneg`); **R2** `Registers.lean` (`δ_eq_residual_div`, `mul_delta_eq_residual`, `surprise_eq_delta_sq_mul_E`, `surprise_nonneg`, `surprise_sign_collapse`, `wedge_eq_residual_skew`, `sym_plus_skew`) | **DIRECT — PROVED** (INDEX R1, R2) |
| 7 | `[count]` / `[prob]` | count vs probability gauge | count `E = f(a)f(b)/T`; probability `p(a)p(b) = f(a)f(b)/T² = E/T` — a **register shift by T** | the same independence null in counts vs probabilities; benign global rescale (ranking-invariant) | probability theory; statistics | recorded in `LATTICE_MATH.md` ("the same object in a different gauge / register"); no Lean file | DIRECT (arithmetic identity), recorded not proved |
| 8 | `τ` / `π` | full-turn vs half-turn constant | `τ = 2π`; hexagonal packing density `τ/(4√3) = π/(2√3)` | the base unit of rotation is a *circle*, not a semicircle — the density is convention-independent | geometry; physics (τ convention) | `Packing.lean` (`tau`, `hexPackingDensity`, `hexPackingDensity_eq_tau_div`) | **DIRECT — PROVED** (INDEX T6: the number identity; Thue/Fejes-Tóth optimality *cited*, not proved) |
| 9 | `⊥` / `∧` / `‖` | the three axes | scalar: `surprise ≡ correlation²` (r²/E); wedge: `O_ab − O_ba` (skew; E cancels ⇒ `= r_ab − r_ba`); polarization: `f(a)/f(b) − f(b)/f(a)` | scalar structure / skew-temporal orientation / radial scale — the unique decomposition of the residual | statistics; time series (Granger direction); physics (curl/div Helmholtz split) | wedge: `Residual.lean` `wedge_antisymm` + `Registers.lean` `wedge_eq_residual_skew`, `sym_plus_skew`; `surprise ≡ corr²`: port candidate #11 (not yet proved); polarization skew: port candidate #9 (asserted in rebuild `statistics.rs`, **no Lean**) | wedge: **DIRECT PROVED**; polarization: ANALOGY/OURS (code only), unproved |
| 10 | `r` | the one primitive — the signed residual | `r = O − E`, `E = f(a)f(b)/T`; O recovered as `r + E`; ring² = Σ(O−E)²/E (χ² divergence, an L2 norm) | deviation from the independence null — the "actual minus expected" pattern that each field's core object re-reads in its own gauge | **the 11-field survey**: category theory, Granger/transfer entropy, information geometry, logic, maxent, multifractal formalism, operator algebras, quantum algorithms, renormalization group, spectral graph theory, statistical mechanics (`ox alpha.md` L1600–1628) — objects incl. χ² divergence, mutual information (χ² ≈ 2·I at 2nd order, `ox alpha.md` L65), force (`O−E`), excess return | `Residual.lean` (`residual`, `E`, `T`, `ringSq`, `sum_E_row`, `sum_residual_eq_zero`, `wedge_antisymm`, `ringSq_nonneg`); `Registers.lean` | primitive itself: **DIRECT — PROVED**; *each field's object is a gauge variant of it*: **ANALOGY** per-field (see the caution at `ox alpha.md` L1759) |

---

## §3 The relationship graph

Typed, directed edges. **Edge-type legend:** `is-isomorphic-to` (same object, proved
isomorphism) · `is-a-gauge-shift-of` (same invariant, different register/signature) ·
`is-a-convention-bridge-of` (same object, different parameterization) ·
`is-an-analog-of` (parallel structure, different object) · `appears-in-field` ·
`has-units` · `is-the-invariant-of` · `is-the-metric-of` · `is-bijective-to` ·
`is-not` (retired/counter-edge — the project's guardrails). Every edge carries its
calibration in `[...]`.

### A. The core proved graph (DIRECT)

```text
E₆₀ ──is-isomorphic-to──▶ E₁₂₀                     [DIRECT]  φ(a,b)=(a,−b), ConventionBridge.lean
i_ω  ──has-units────────▶ Z₆                        [DIRECT]  Rotation.lean units_card,
                                                              units_closed_under_mul; Gauge.lean
                                                              units_eq_omega_powers
N(i_ω) ──is-the-area-scalar-of──▶ i_ω               [DIRECT]  Gauge.lean norm_eq_det (N = det of
                                                              the regular representation)
δ ──is-the-invariant-of──▶ {r_raw, z, s}            [DIRECT]  Registers.lean δ_eq_residual_div,
                                                              mul_delta_eq_residual,
                                                              surprise_eq_delta_sq_mul_E
s ──is-a-sign-collapsing-gauge-shift-of──▶ r_raw    [DIRECT]  Registers.lean surprise_sign_collapse
r_raw ──is-a-gauge-shift-of──▶ z ──▶ s              [DIRECT]  ×√E then ×δ again; same file
wedge ──is-the-skew-part-of──▶ residual             [DIRECT]  Residual.lean wedge_antisymm;
                                                              Registers.lean wedge_eq_residual_skew
ring² ──is-a──▶ χ² divergence (L2 norm)             [DIRECT]  Residual.lean ringSq, ringSq_nonneg
τ ──is-a-convention-bridge-of──▶ π                  [DIRECT]  Packing.lean (τ = 2π, density equal)
7-hex ──is-bijective-to──▶ balanced-ternary         [DIRECT]  SevenHex.lean hexCells_card,
        triples (q+r+s=0)                                     balanced_iff_mem
hexDist ──is-the-metric-of──▶ honeycomb graph       [DIRECT]  GraphDistance.lean
                                                              honeycomb_dist_eq_hexDist (both
                                                              directions) + Rotation.lean metric lemmas
hex cell ──is-addressable-by──▶ ℕ / u32            [DIRECT]  Bijection.lean hexPairEquiv,
        (Szudzik pairing)                                     toNat_bijective, toNat_lt_two_pow_32
i_ω ──is-a-gauge-shift-of──▶ (rotor group)          [DIRECT]  Z₆ ⊂ SO(2): the even-grade fix
                                                              ψ=(α+βI)U in integer mod-6 arithmetic
```

### B. The project-framing edges (ANALOGY / OURS)

```text
r ──appears-in-field──▶ {χ² divergence, mutual information (χ² ≈ 2·I),
                         force (O−E), excess return, transfer entropy, …}
                                                   [ANALOGY]  the 11-field survey, ox alpha.md
                                                              L1600–1628, L1759; LATTICE_MATH.md
i₋₁, i₊₁, i₀ ──is-an-analog-of──▶ i_ω              [ANALOGY]  same "unit whose square is a
                                                              signature" pattern (gauge_int.rs);
                                                              NOT isomorphic rings (see §6)
i₊₁ ──is-an-analog-of──▶ Minkowski spacetime (1+1D) [ANALOGY]  gauge_int.rs Signature::Minkowski
i₀  ──is-an-analog-of──▶ infinitesimal calculus     [ANALOGY]  gauge_int.rs Signature::Null
z ──is-an-analog-of──▶ Pearson residual             [DIRECT]  Registers.lean δ_eq_residual_div
                                                              (standard statistics, now proved)
i_ω ──realizes-as──▶ the mod-6 spinor (ISA TROT)    [OURS]    TERNARY_PROCESSOR.md §2.2;
                                                              porting_map.md #1 (DIRECT math,
                                                              SPECULATION as ISA encoding)
```

### C. The guardrail edges (counter-edges — what the project explicitly says NOT to claim)

```text
ring² ──is-not──▶ Fisher information               [RETIRED]  LATTICE_MATH.md; AGENTS.md
                                                              canonical truth (Fisher ∝ 1/freq)
wedge ──is-not──▶ GA bivector area                 [RETIRED]  SYNTHESIS.md Q3 (V3 claim retired)
wedge ──is-not──▶ a causal arrow                    [OURS]    causality is Rung-1 association;
                                                              sign/wedge = orientation signal only
hex addressing ──is-not-yet──▶ replaces the         [SPECULATION] INDEX.md row; Bijection.lean
        u32 XOR kernel                                          header (bijection proved; the
                                                              replacement claim is not)
"hex norm = ring" ──is-not──▶                      [FORBIDDEN] proofs/AGENTS.md guardrail 8;
                                                              porting_map.md D1
i₊₁, i₀ ──are-not──▶ isotropic                      [DIRECT]  porting_map.md D3 (isotropy holds
                                                              only for the elliptic signatures)
s ──is-not──▶ injective in δ (sign collapses)       [DIRECT]  Registers.lean surprise_sign_collapse
                                                              + the Bool counterexample
```

---

## §4 What the sums mean

One plain-English sentence per defining relation — the semantic translation an expert
needs. (All DIRECT-proved unless tagged.)

- **`r = O − E`** — *"How much more (or less) often did these two actually co-occur
  than they would if they were independent?"* The signed residual is the primitive; a
  minus sign means repulsion (anti-correlation), plus means attraction.
- **`E = f(a)f(b)/T`** — *"The count you'd expect if the two events were independent,
  with the marginal totals fixed."* The independence null, computed by column balancing
  (proved: `Σ_b E(a,b) = f(a)`, `Residual.lean sum_E_row`).
- **`p(a)p(b) = E/T`** — *"The same expectation read as a probability instead of a
  count — a change of measuring stick (÷T), not a change of meaning."* Ranking-invariant,
  hence a benign gauge shift.
- **`δ = O/E − 1`** — *"The surplus as a ratio: how far above (or below) the
  independence baseline, in multiples of the baseline."* The `−1` is the gauge
  normalization — δ is the invariant that survives every register.
- **`z = (O−E)/√E`** — *"The surplus measured in units of its own typical noise —
  the deviation in standard-deviation units under the null."* The Pearson residual.
- **`s = (O−E)²/E`** — *"The surplus squared and rescaled: how much structure this
  pair contributes to the total χ² — and the sign (attract vs repel) has been thrown
  away."* This is why the χ² magnitude is *order*, not surprise; the sign lives in `r`.
- **`ring² = Σ(O−E)²/E`** — *"The total amount of non-independence in a word's whole
  neighborhood — one scalar norm (χ² divergence / L2), not a matrix and not Fisher
  information."*
- **`ω² = ω − 1` (i_ω)** — *"Rotating by 60° twice is a 120° rotation, which in this
  basis is 'one step forward minus one sideways' — exact integer trigonometry, no
  floats."*
- **`N(a+bω) = a²+ab+b²`** — *"The area the number sweeps out under its own rotation —
  the gauge-invariant size of the number; it doesn't change when you rotate by a unit
  (isotropy)."*
- **`E₆₀ ⇄ E₁₂₀` via φ(a,b) = (a,−b)** — *"The 60° and 120° Eisenstein conventions are
  the same ring seen in a mirror-flipped basis — a notation collision, not a math
  collision."*
- **`τ = 2π`** — *"A full turn is the base unit of rotation; π is the same angle
  halved — the τ/π split is a convention bridge, which is why the packing density
  `τ/(4√3) = π/(2√3)` is the same number either way."*
- **`wedge = O_ab − O_ba`** — *"How much more often a precedes b than b precedes a —
  a skew/orientation (temporal) signal, never a magnitude, never a causal arrow."*
- **`polarization = f(a)/f(b) − f(b)/f(a)`** — *"How lopsided the two base rates are —
  a radial scale about the pair, independent of how they actually co-occur."*
- **`surprise ≡ correlation²`** — *"The χ² summand and the squared correlation are the
  same axis read twice: the sign was already extracted, the magnitude is shared."*
- **`r` in any other field** — *"Take whatever that field calls its 'deviation from the
  null model' (χ² divergence, mutual information, force, excess return…) and you are
  re-reading this same surplus in that field's gauge."* (ANALOGY per-field — see §6.)

---

## §5 How to do this — the method

The procedure that produced the rows above (and the one to follow when a new field
arrives):

1. **Identify the invariant.** For this project it is `δ = O/E − 1` (the fold) — every
   register rung is `δ` rescaled by a power of `E` (`r = E·δ`, `z = √E·δ`, `s = E·δ²`).
   For an external field, ask: *what is the gauge-invariant quantity that survives every
   normalization in that field?*
2. **Rewrite the field's core object as a gauge variant of the invariant.** Show it as a
   register shift, a rescale, or a signature change of `r` — e.g. χ² summand = `E·δ²`,
   Pearson z = `√E·δ`, mutual information ≈ 2nd-order χ², force = `O−E` against the
   inertia null, excess return = actual minus benchmark.
3. **Calibrate at mapping time — DIRECT / ANALOGY / OURS / SPECULATION on the first
   pass, not after.** This is the project's standing discipline: `proofs/AGENTS.md` rule 6
   ("calibration labels ride with every claim"), the claim-label definitions in
   `TERNARY_PROCESSOR.md` header, the four verdicts in `survey/SYNTHESIS.md` §2, and
   `survey/porting_map.md` ("calibrated at mapping time"). The single biggest method gap
   in this project's history was *over-claiming* — every over-claim was caught one pass
   too late (learning-method rule 1, AGENTS.md).
4. **When a field's theorem seems to fail against the invariant, first check whether
   it is a translation/normalization difference, not a refutation.** The project's
   principle (PRINCIPLE, `ox alpha.md` L3060–3064): *"our math is a gauge variant of
   standard math… a 'failed' claim is usually a TRANSLATION/normalisation difference."*
   The escort-transform sign flip is the worked example (a signed gauge variant, not an
   error in their math). **But** keep an expiry criterion (L4708): a gauge-variant
   reading must eventually map to a testable per-pair claim, or it is unfalsifiable.
5. **Prove the DIRECT ones in Lean, with the path and calibration recorded in
   `proofs/INDEX.md`.** The ledger is the contract: a claim is "proved" only when
   `lake build` is green with zero `sorry`. Rust mirrors the proved math for speed
   (`rust-mirror/`, `cargo test` — see `PROVER_NOTES.md`).
6. **Name collisions are the danger.** Before mapping across fields, resolve the
   terminological collisions — "wedge" (skew residual vs Clifford blade vs retired
   bivector-area), "gauge" (three meanings, §6), "register", "causal", "polarization",
   "ternary", "rebuild" (`survey/SYNTHESIS.md` §4; `survey/porting_map.md` C1–C5).

---

## §6 Open questions

1. **The four signatures are NOT all isomorphic — what exactly distinguishes them?**
   `ℤ[i]`, `ℤ[ω]`, split-complex, and dual numbers are *genuinely different rings*
   (different unit groups Z₄ vs Z₆ vs (Z₂)²-ish vs trivial; zero divisors vs nilpotents
   vs domains). The "gauge variant" claim holds at the level of the *pattern* (a
   2-dimensional algebra whose unit's square is a signature, with a norm and a unit
   group) — the one fully proved member is `i_ω`. What the four share and where they
   part (isotropy holds only for the elliptic pair, per `survey/porting_map.md` D3) is
   not yet stated as a theorem. **SPECULATION** beyond the Eisenstein case.
2. **The "gauge" term has (at least) three meanings** — the top collision
   (`survey/porting_map.md` C1):
   1. *gauge = multiplication by a Z₆ unit* — a discrete 60° rotation, norm-preserving
      (this repo's `Gauge.lean`; equals the rebuild's Signature meaning);
   2. *gauge = register* — an R⁺ scale in powers of E, the raw/fold/z/surprise ladder
      (rebuild `gauge.rs`); δ-invariant, and *not* the Z₆ meaning ("gauge change is a
      shift" is true here, false for meaning 1);
   3. *gauge = the unit's signature* — `i² ∈ {−1,+1,0,ω}` as a property of the unit
      (rebuild `gauge_int.rs`, TODO #16). — Plus a related fourth: "gauge = register =
      ring shift" (`d >> n`, RG flow, `LATTICE_MATH.md`) overloads "register" itself
      (C5). Any sentence using "gauge" must say which.
3. **Is a signature-valued gauge real math or a wish?** "Gauge = the unit" (`i² ∈
   {−1,+1,0,ω}` as a *third gauge position* beyond the Abelian R⁺ scale) is the
   conversation's one genuinely new idea — filed as SPECULATION, POC-coded in
   `gauge_int.rs`, and *not* integrated or proved (`survey/SYNTHESIS.md` Q2;
   `survey/oxalpha_lens.md`).
4. **Each 11-field mapping is ANALOGY until proved per-pair.** The individual
   identities (χ²-as-divergence, z-as-Pearson, etc.) are mostly known in their own
   literatures; the novel artifact claimed is the *single-primitive ledger* — one
   formula, every field's version derived from it, each entry calibrated — not any one
   identity (`ox alpha.md` L1628). Which pairs can be upgraded from ANALOGY to DIRECT
   (preserving the field's theorems under the rewrite) is open, and the fluency-trap
   warning applies: seeing the pattern everywhere is not proof (L1759).
5. **The hex↔u32 bijection exists; the replacement claim does not.** `Bijection.lean`
   proves `ℤ² ≃ ℕ` (Szudzik pairing, exact u32 box) — but "hex addressing *replaces*
   the u32 XOR kernel" remains SPECULATION, explicitly BLOCKED in `proofs/INDEX.md`.
6. **T6 is only half proved.** The number identity `τ/(4√3) = π/(2√3)` is proved; the
   geometric derivation and the Thue/Fejes-Tóth optimality are *cited*, not proved.
7. **The third axis has no Lean proof.** Wedge and surprise/correlation are in the
   ledger; polarization skew (`f(a)/f(b) − f(b)/f(a)`) is asserted in rebuild
   `statistics.rs` only — it is port candidate #9 (`survey/porting_map.md`), a
   two-line proof waiting to be written.

---

## Provenance & grounding (files actually read for this map)

`proofs/INDEX.md` (the ledger); `proofs/lean-src/hexagon/Hexagon/{Conventions, Gauge,
EuclideanDomain, Registers, Residual, ConventionBridge, Bijection, Rotation, Packing,
SevenHex, GraphDistance, Euclidean}.lean` (headers + theorem statements);
`proofs/PROVER_NOTES.md`; `LATTICE_MATH.md`; `TERNARY_PROCESSOR.md`; `survey/SYNTHESIS.md`;
`survey/porting_map.md`; `survey/rebuild_map.md`; `survey/oxalpha_graph.md`;
`survey/oxalpha_lens.md`; `rust-mirror/src/{eisenstein.rs, bijection.rs}`; the
11-field list and the gauge-variant principle in `ox alpha.md` (L1600–1628, L1759,
L3060–3064, L3109). Rebuild-side artifacts (`gauge.rs`, `gauge_int.rs`, `statistics.rs`)
are cited via `survey/rebuild_map.md` and `survey/porting_map.md`.
