# One Primitive, Many Gauges — the signed residual as the common core of standard math, and the ternary null that is ours

**A technical orientation paper.** Every claim below is calibrated DIRECT / ANALOGY / OURS /
SPECULATION (legend in §2.3); every "proved" claim has a green Lean build with zero `sorry`,
recorded in `proofs/INDEX.md` (build state 2026-08-28). Lean files live in
`proofs/lean-src/hexagon/Hexagon/`; survey graphs in `docs/graphs/{measure-theory,ternary-circuits}/`;
syntheses in `docs/synthesis/`. Companion cheat-sheet: `GAUGE_VARIANTS.md`.

---

## 0. Abstract

This project's thesis is that a large swath of standard mathematics — statistics,
probability, information theory, geometry, number theory, and digital-circuit energy
analysis — is a family of **isomorphic gauge variants** of a single object: the **signed
residual** `r = O − E`, the count by which two events co-occurred above (or below) the
independence null `E = f(a)f(b)/T`, which is the **product measure** of the marginals. The
gauge-invariant core of that primitive is the dimensionless fold `δ = O/E − 1`; the raw
surplus `r`, the Pearson residual `z`, and the χ² summand `s` are the same invariant read in
four *register* rungs, and probability is the count gauge renormalized to mass 1. The
operational doctrine that follows is **compute in counts, display as ratios only at the
boundary**: store the integer `r`, never normalize away the sign, and treat every "gauge"
(rescale, convention, renormalization) as a cheap, eliminable integer bookkeeping layer — a
stance the measure-theory literature confirms at the theorem level (the counting measure is
the primitive; Haar = normalized counting; the measure itself is Π¹₂-conservative). On the
hardware leg, the same gauge discipline selects **balanced ternary** as the natural radix:
radix economy is maximized at base 3, the Eisenstein (hexagonal) lattice is the
minimum-energy symbol constellation, and the one-hot trit encoding
`01/+1 · 00/0 · 10/−1 · 11/NEVER` carries an **energy-free null** — the `00` state costs
zero energized lines, so information is transmitted by doing nothing. That null is the
genuinely novel piece: the ternary-circuit literature independently re-derives the gate
algebra, the 2-bit trit code (down to the forbidden `11`), and the radix/energy case, but
every "middle state" it builds is a driven level, a parasitic current, or an epistemic
placeholder — nobody proves a null is free. The contribution is therefore a **single
primitive ledger** — one formula, each field's core object derived from it as a gauge
variant, each mapping calibrated, the DIRECT ones proved in Lean — plus the encoding-level
result that the zero-energy information state exists.

---

## 1. The one primitive: `r = O − E`

### 1.1 Definition

For two events/words `a`, `b` with observed co-occurrence count `O = O_ab` over a corpus
total `T`:

- **The null (independence = product measure).** `E = f(a)f(b)/T` — the count you would
  expect if `a` and `b` were independent with marginal totals fixed. This is exactly the
  **product measure** of the marginals: independence of random variables is *defined* as
  the joint law being the product of the marginals (DIRECT, `docs/synthesis/measure-theory.md`
  §2.4, from 1808.01713 Def 3).
- **The primitive.** `r = O − E` — the **signed residual**: *how much more (or less) often
  did these two actually co-occur than if they were independent?* A minus sign means
  repulsion (anti-correlation); plus means attraction. `O` is always recovered as `r + E`.
- **The norm.** `ring² = Σ(O−E)²/E` — the total non-independence in a neighborhood: one
  scalar, the **χ² divergence** (an L2 norm). NOT Fisher information (retired claim — Fisher
  is a matrix ∝ 1/frequency, inverted; see `GAUGE_VARIANTS.md` §3C).

Everything the system stores is this one signed integer per direction. Proved in
`Residual.lean` (INDEX R1): `E` as product of marginals, `sum_E_row` (Σ_b E(a,b) = f(a)),
`sum_residual_eq_zero`, `wedge_antisymm`, `ringSq_nonneg` (χ² ≥ 0).

### 1.2 The three axes — the only three

The residual decomposes exactly three ways (AGENTS.md canonical truth; `GAUGE_VARIANTS.md`
§1D):

| Axis | Symbol | Definition | Meaning | Status |
|---|---|---|---|---|
| **correlation/surprise** | `⊥` | scalar; `surprise ≡ correlation²` | one axis, sign = attract vs repel; χ² magnitude is *order*, not surprise | surprise≡corr² is a port candidate (not yet proved); the sign lives in `r` |
| **wedge** | `∧` | skew `O_ab − O_ba` (E cancels ⇒ `= r_ab − r_ba`) | temporal orientation — how much more a precedes b than b precedes a; NOT bivector area, NOT a causal arrow | **PROVED** (`wedge_antisymm`, `wedge_eq_residual_skew`, `sym_plus_skew`) |
| **polarization** | `‖` | `f(a)/f(b) − f(b)/f(a)` | radial scale — how lopsided the two base rates are, independent of co-occurrence | Rust `statistics.rs` only; no Lean (port candidate #9) |

### 1.3 The register ladder — one invariant, four read-outs

The invariant is the **fold** `δ = O/E − 1` — the surplus as a ratio of the baseline. Every
rung is `δ` rescaled by a power of `E` (`Registers.lean`, INDEX R2 — all PROVED):

| Rung | Relation to the invariant | Reads as | Sign survives? |
|---|---|---|---|
| `r_raw` | `r = O − E = E·δ` | absolute surplus (the stored primitive) | yes |
| `δ` | `δ = O/E − 1` | surplus in multiples of baseline — **the gauge-invariant core** | yes |
| `z` | `z = (O−E)/√E = √E·δ` | surplus in units of its own typical noise (Pearson residual) | yes |
| `s` (χ² summand) | `s = (O−E)²/E = E·δ²` | structure contributed to total χ² | **no** — sign collapsed (`surprise_sign_collapse`); why the χ² magnitude is not "surprise" |

Consequences, all PROVED: `δ` is invariant under the count→prob gauge (a common rescale
`(O,E) ↦ (cO, cE)`), while χ² scales by `c` (`ChiSquareGauge.lean` — `fold_gauge_invariant`,
`surprise_scales`, `fold_eq_surprise_div`): **store δ, not r**. The count↔probability shift
`p(a)p(b) = E/T` is the same object in a different measuring stick (a register shift by `T`,
ranking-invariant).

### 1.4 What the sums mean

Plain-English translations (all DIRECT-proved unless tagged; full list in `GAUGE_VARIANTS.md`
§4):

- `r = O − E` — *how much more/less did these co-occur than independence?*
- `E = f(a)f(b)/T` — *the count expected if independent, marginals fixed* (product measure).
- `δ = O/E − 1` — *the surplus as a multiple of the baseline; the −1 is the gauge
  normalization that survives every register.*
- `s = (O−E)²/E`, `ring² = Σ(O−E)²/E` — *structure contributed to χ² / total
  non-independence of a neighborhood: one L2 norm; the attract/repel sign was thrown away*
  (order, not surprise).
- `ω² = ω − 1`; `N(a+bω) = a²+ab+b²` — *60° twice is 120°, "one step forward minus one
  sideways" — exact integer trigonometry; the area a lattice point sweeps under its own
  rotation, unchanged under unit rotation (isotropy).*
- `wedge = O_ab − O_ba` — *how much more a precedes b than the reverse — orientation, never
  magnitude, never causation.*
- `r` in any other field — *"deviation from the null model" in that field's gauge: χ²
  divergence, mutual information (χ² ≈ 2·I at 2nd order), force, excess return, transfer
  entropy* (ANALOGY per-field, §5).

---

## 2. The gauge-variant map

### 2.1 The naming convention

**The subscript is the signature** — the value whose square defines the multiplication —
and, by extension, the gauge parameter that says *which question the object answers*:
`X_<gauge>`. Four signature algebras (a 2-dimensional algebra whose unit's square is the
signature, with a norm and a unit group): `i₋₁` (i²=−1, Gaussian ℤ[i], exact 90° rotation,
units Z₄), `i₊₁` (i²=+1, split-complex, exact boost, zero divisors), `i₀` (i²=0, dual
numbers, infinitesimals, nilpotents), `i_ω` (i²=ω with ω=e^(iπ/3), **Eisenstein ℤ[ω]**,
exact 60° rotation, units Z₆ — **the proved case**). Convention gauges: `E₆₀` (ω=e^(iπ/3),
norm a²+ab+b² — this repo) ⇄ `E₁₂₀` (ω²=e^(2πi/3), norm a²−ab+b² — mathlib; the same ring,
mirror-flipped, **PROVED** `ConventionBridge.lean` φ(a,b)=(a,−b)); `τ`/`π` (full-turn vs
half-turn; this project uses τ); `[count]`/`[prob]` (register shift by T). Register rungs
`r_raw`/`δ`/`z`/`s` (§1.3); axes `⊥`/`∧`/`‖` (§1.2).

### 2.2 The relationship graph (~26 edges)

Edge types: `is-isomorphic-to` · `is-a-gauge-shift-of` · `is-a-convention-bridge-of` ·
`is-an-analog-of` · `appears-in-field` · `has-units` · `is-the-invariant-of` ·
`is-the-metric-of` · `is-bijective-to` · `is-not` (guardrail). Every edge carries its
calibration in `[...]`. (From `GAUGE_VARIANTS.md` §3; Lean files per edge are in the §3
ledger.)

**A. The core proved graph (DIRECT):**

```text
E₆₀ ──is-isomorphic-to──▶ E₁₂₀               [DIRECT] ConventionBridge.lean
i_ω ──has-units──▶ Z₆                        [DIRECT] Rotation.lean
N(i_ω) ──is-the-area-scalar-of──▶ i_ω        [DIRECT] Gauge.lean (norm_eq_det)
δ ──is-the-invariant-of──▶ {r_raw, z, s}     [DIRECT] Registers.lean
s ──is-a-sign-collapsing-gauge-shift-of──▶ r_raw  [DIRECT] surprise_sign_collapse
r_raw ──is-a-gauge-shift-of──▶ z ──▶ s       [DIRECT] ×√E then ×δ again
wedge ──is-the-skew-part-of──▶ residual      [DIRECT] wedge_antisymm, wedge_eq_residual_skew
ring² ──is-a──▶ χ² divergence (L2 norm)      [DIRECT] Residual.lean
τ ──is-a-convention-bridge-of──▶ π           [DIRECT] Packing.lean
7-hex ──is-bijective-to──▶ balanced-ternary triples  [DIRECT] SevenHex.lean
hexDist ──is-the-metric-of──▶ honeycomb graph  [DIRECT] GraphDistance.lean (both directions)
hex cell ──is-addressable-by──▶ ℕ/u32        [DIRECT] Bijection.lean (Szudzik, u32 box)
i_ω ──is-a-gauge-shift-of──▶ rotor group     [DIRECT] Z₆ ⊂ SO(2), ψ=(α+βI)U, mod-6 arithmetic
```

**B. Project-framing edges (ANALOGY / OURS):**

```text
r ──appears-in-field──▶ {χ² divergence, mutual information (χ² ≈ 2·I), force (O−E),
                         excess return, transfer entropy, …}             [ANALOGY]
i₋₁, i₊₁, i₀ ──is-an-analog-of──▶ i_ω        [ANALOGY] same signature-squared-unit
                                                       pattern; NOT isomorphic rings
i₊₁ ──is-an-analog-of──▶ Minkowski (1+1D)    [ANALOGY]
i₀ ──is-an-analog-of──▶ infinitesimals       [ANALOGY]
z ──is-an-analog-of──▶ Pearson residual      [DIRECT] Registers.lean
i_ω ──realizes-as──▶ mod-6 spinor (ISA TROT) [OURS]   TERNARY_PROCESSOR.md §2.2
```

**C. Guardrail edges (`is-not` — what the project refuses to claim):**

```text
ring² ──is-not──▶ Fisher information         [RETIRED]  Fisher ∝ 1/frequency, inverted
wedge ──is-not──▶ GA bivector area           [RETIRED]
wedge ──is-not──▶ a causal arrow             [OURS]     causality = Rung-1 association
hex addressing ──is-not-yet──▶ replaces the u32 XOR kernel [SPECULATION] — blocked in INDEX
"hex norm = ring" ──is-not──▶                [FORBIDDEN] proofs/AGENTS.md guardrail 8
i₊₁, i₀ ──are-not──▶ isotropic               [DIRECT]   isotropy holds only for the elliptic pair
s ──is-not──▶ injective in δ (sign collapses) [DIRECT]  surprise_sign_collapse + Bool counterexample
```

### 2.3 The calibration legend

| Label | Meaning |
|---|---|
| **DIRECT** | Same math, **proved** in the Lean ledger (`lake build` green, `proofs/INDEX.md`) — or standard classical math cited as such |
| **ANALOGY** | Parallel structure, different object |
| **OURS** | The project's own object/framing — one side only |
| **SPECULATION** | Unproven on both sides |

---

## 3. What is proved — the Lean ledger

`lake build` GREEN (2026-08-28, toolchain v4.33.1, zero `sorry`); the Rust mirror
(`rust-mirror/`, `cargo test`) mirrors the math; the Verilog (`rtl/`) implements the ternary
cell + 12-opcode ISA (TADD/TSUB/TMUL/TROT/TNORM/…), iverilog/yosys-checked. One line per
theorem, from `proofs/INDEX.md`:

| ID | Claim — one line | File |
|---|---|---|
| T0 | ℤ[x]/(x²−x+1) is a commutative ring — the Eisenstein integers | `Conventions.lean` |
| T1 | N(a+bω) = a²+ab+b² is multiplicative | `Conventions.lean` |
| T2a | There are exactly 7 hex cells | `SevenHex.lean` |
| T2b | Balanced-ternary triples (q,r,s), q+r+s=0 ↔ the 7 hex cells | `SevenHex.lean` |
| T3a | The six units ±1, ±ω, ±ω² (exactly six) | `Rotation.lean` |
| T3b | The units form Z₆; rotation = mod-6 angle add | `Rotation.lean` |
| T4 | Cube-coordinate max-norm distance = honeycomb graph distance (both directions) | `GraphDistance.lean` |
| T5 | ℤ[ω] is a Euclidean domain, hence UFD (pure-ℝ route, mirrors mathlib GaussianInt) | `EuclideanDomain.lean` |
| T6 | Hex packing density = τ/(4√3) (= π/(2√3)) — number identity PROVED; geometric derivation + Thue/Fejes-Tóth optimality **cited, not proved** | `Packing.lean` |
| G1 | Isotropy: N(u)=1, N(u·x)=N(x), N = det of the regular rep, units = ω⁰…ω⁵ | `Gauge.lean` |
| R1 | Residual: E marginal (`sum_E_row`), Σ(O−E)=0, wedge skew, χ² ≥ 0 | `Residual.lean` |
| R2 | Register ladder: δ fold, surprise = δ²·E, sign-collapse, sym+skew split | `Registers.lean` |
| C1 | 60° ≅ 120° Eisenstein — the same ring, φ(a,b)=(a,−b) | `ConventionBridge.lean` |
| B1 | hex ↔ ℕ (u32) address bijection (Szudzik pairing; exact u32 box) | `Bijection.lean` |
| FR1 | Fractal hex RAM: 7ⁿ address space, 7↔1 parent-child fiber | `FractalRam.lean` |
| TC1 | Ternary cell: one-hot-per-direction, energy ≤1 line, **null free**, avg 2/3 vs binary 1, `11`=NEVER | `TernaryCell.lean` |
| A1 | Counting measure is Z₆-invariant (Haar); finite-group Haar = normalized counting | `Haar.lean` |
| A2 | The fold δ is gauge-invariant; χ² is not (it scales) — store δ | `ChiSquareGauge.lean` |
| A3 | Energy is a lattice valuation; min+max=sum (the `tadd1` identity) | `ValuationEnergy.lean` |
| B1z | Zipf-weighted energy: expected energy = 1−P(null) < 2/3 when null dominates | `ZipfEnergy.lean` |

Also present, in flight (ROADMAP Batch 2): `RadixEconomy.lean` (log₂3 ≈ 1.585 bits/trit; 3
beats 2) and `Signature.lean` (what distinguishes i² = −1, +1, 0, ω).

---

## 4. The literature — the two synthesis verdicts

Survey method: map each paper to a labeled relation graph, then a lens pass, then synthesis
(`docs/MAP_BRIEF.md`). Inputs: 18 measure-theory + 19 ternary-circuit graphs in
`docs/graphs/`; verdicts in `docs/synthesis/measure-theory.md` and
`docs/synthesis/ternary-circuits.md`. Both syntheses ran before the A1/A2/A3/B1z proofs —
they named those theorems as "next proofs," and the proofs now exist.

### 4.1 Measure theory: CONFIRMED at the theorem level (12/18 DIRECT, 0 contradictions)

- **Counting measure is the primitive.** `ν(A) = Card(A) = Σ δ_ωj` is "the canonical
  integer-valued measure," the one all others are constructed from (1711.04625, 2606.05215,
  1409.2662); the unique translation-invariant measure that survives infinite dimensions
  (2312.04365).
- **Probability = renormalized counting.** A measure and a probability differ *only* by the
  unit-mass axiom (2110.00602); finite-group Haar is `µ(E) = |E|/|G|` — counts ÷ total
  (2506.15534); natural density d(A) = count/n is the counting measure in the prob gauge
  (1702.07154).
- **Independence = product measure.** `r = O − E` is by definition the deviation from
  independence-as-product-measure (1808.01713 Def 3).
- **The gauge is cheap — provably.** Full Lebesgue measure added to weak arithmetic is
  Π¹₂-*conservative*: it proves nothing new — a definitional add-on with a computable term
  (1312.1531); engineering twin: 76% of one library's runtime is a normalization constant
  nobody uses — defer it (2110.00602).
- **Un-normalized counts carry the information.** The normalized limit destroys shape
  information; only the raw fixed-scale count reconstructs it (1408.5954); on a lattice the
  additivity structure is integer-parity and counting *creates* gauge freedom (0205648).

Key papers (deep-read): **2506.15534** (Banica — Haar = normalized counting; Lebesgue from
dyadic-lattice counting; Weingarten moments are integers), **1312.1531** (Kreuzer —
Π¹₂-conservativity), **1808.01713** (Lo — independence = product measure), **2110.00602**
(Scherrer & Schauer — unit-mass axiom), **2312.04365** (Velhinho — counting = Haar of a
discrete group), **2209.02345** (Affeldt & Cohen — mathlib already has the routes + Haar;
the finite case is trivial). Trap: 4 of the 18 are *Fundamental Measure Theory* physics
(0205648, 2101.08112, 1207.4950, 2009.09390) where "measure" = geometric valuation — real
but analogical evidence.

### 4.2 Ternary circuits: CONFIRMED (gates/code/radix/energy), CORRECTED (energy is conditional), the null is OURS

- **Gate algebra.** The MVL min/max/neg table IS our `tand`/`tor`/`tneg`, down to the digit
  set {−1,0,+1} (2309.01615 fabricated silicon; 1807.06419; 2211.04542; 2211.12176;
  1502.05748). The memristor-CMOS half-adder carry and MUL tables ARE our `tadd1`/`tmul`
  (2309.01615).
- **The 2-bit trit code, independently re-derived three times.** PDR verification's 01X
  two-rail code (2105.09169 §IV-D), the CNFET converter's "This Case Does Not Exist"
  (2211.04542 Table 5.4), and don't-care `x` slots in automated synthesis all reproduce our
  `01/+1 · 00/0 · 10/−1 · 11/NEVER` — including the forbidden `11` (`TernaryCell.lean`
  `encode_never_both`).
- **Radix economy.** Cost b/ln b is minimized at b = e; the best integer is 3 —
  log₂3 ≈ 1.585 bits/trit, 12 bits → 7 trits = 41.7% fewer wires (1807.06419, 2211.04542,
  2204.01000). Caveat, kept: binary wins for non-power-of-3 symbol counts — radix economy is
  range-conditional (1807.06419 itself).
- **Eisenstein energy.** Same-cardinality constellations on the Eisenstein lattice need ≤
  square-lattice energy (2412.18328 Table IV — the same fact as our T6 packing density
  τ/(4√3) ≈ 0.9069); the paper's ring machinery (norm, Z₆, ED, hex weight) is our proved
  math in the 120° gauge, bridged by C1.
- **CORRECTED:** "ternary saves energy" is conditional. Naive 3-level design is an energy
  *liability* (divider transistors, 2211.04542); AND/OR ternary gates can lose on
  power–delay product (2211.12176); every physical "middle state" in the corpus is a driven
  level, a parasitic minority current, or an epistemic placeholder — the closest cousin
  ("0 input costs no drive power", 2111.01558) still distinguishes outputs by microwave
  power pumped in.
- **OURS: the energy-free null.** `TernaryCell.lean` proves energy ≤ 1 line, `00` = no
  energized line (energy 0, information by doing nothing), average 2/3 vs binary 1, and the
  Zipf-weighted version (B1z) pushes the real saving far below 2/3 when null dominates. No
  corpus paper *proves* an energy bound on its middle state — they measure power, they never
  prove a null is free. Honest caveat: this is an *encoding-level* claim; the one-wire
  push/pull/null cell + 2-diode receiver is **ngspice-simulated and measured** (not
  fabricated in silicon) — see `circuit/ENERGY_RESULTS.md` (the fair-fight table, incl.
  CORRECTION 1+2). ROADMAP E1's ∫V·I validation is DONE.

Key papers (deep-read): **2412.18328** (Eisenstein codes — the energy table), **2309.01615**
(fabricated balanced-ternary silicon), **2105.09169** (the PDR/MaxSAT verification blueprint
for our RTL), **2211.04542** (PDP-measurement playbook + forbidden-state confirmation),
**1903.06044** (measure & integral as lattice valuations — legitimizes energy-as-counting).

### 4.3 One-sentence verdicts (from the syntheses)

> Measure theory: *the counting measure is the primitive, probability is the same measure
> renormalized to mass 1, the independence null is the product measure, Haar is the isotropy
> that makes a gauge cheap, and the measure itself is provably content-free — so the
> literature licenses computing in counts, with the one object nobody has — Z₆ acting on
> ℤ[ω] as the isotropy group of the counting measure — being precisely the theorem we proved
> next.* (A1, now in the ledger.)

> Ternary circuits: *the literature independently re-derives our gate algebra, our 2-bit
> one-hot trit code (down to the forbidden `11`, re-discovered three times), and the
> radix-economy + Eisenstein energy case for balanced ternary — but every physical "middle
> state" it builds is a driven level, a parasitic current, or an epistemic placeholder, so
> our energy-free null (`00` = no energized line, Lean-proved) is the one thing the corpus
> confirms is missing.* (TC1 + B1z, now in the ledger.)

---

## 5. What's ours vs established — the honest boundary

**The literature already has** (credit them, do not claim): measure-first framing (Sorkin
9401003; Lo 1808.01713), general Haar = normalized counting (2506.15534; 2312.04365), gauge
eliminability (1312.1531), integer-valued optimality (1408.5954),
discreteness-creates-structure (0205648), the Radon–Nikodym ratio object (1409.2662 et al.),
the gate algebra and 2-bit trit code (2309.01615, 1807.06419, 2105.09169, 2211.04542),
radix economy (1807.06419), and the Eisenstein energy advantage (2412.18328). None of the
above is novel; each is cited as DIRECT/ANALOGY in §4.

**Genuinely OURS** (each one side of the ledger only):

1. **The energy-free null.** The `00` state with *proved* zero energy, one-hot-per-direction,
   never-both `11` — no paper proves a null is free (their middle states are all presences).
   This is the novel piece of the whole project.
2. **Z₆ as the isotropy group of the counting measure on ℤ[ω].** General Haar = normalized
   counting is in the literature; the *instance* — the six 60° rotations preserve the
   Eisenstein norm and the counting measure — is ours, and now proved (G1 norm side; A1
   measure side).
3. **The register ladder** `r_raw → δ → z → χ²`. The literature has two-rung dualities
   (count↔prob, measure↔functional); nobody reads one invariant in four multiplicative
   rungs, with sign-collapse as a *theorem* (`surprise_sign_collapse`), not a convention.
4. **The E₆₀ ⇄ E₁₂₀ convention bridge, proved in Lean** — φ(a,b)=(a,−b), a ring
   isomorphism, not just a notation note.
5. **The fractal hex RAM** — 7ⁿ address space with a 7↔1 parent-child fiber, proved
   combinatorially (FR1). (Geospatial DGGS/H3 has the aperture-7 hierarchy as *indexing*;
   the Lean bijection is ours.)
6. **The signed-residual storage discipline** — store `r`, recover `O = r + E`, never
   normalize the sign away, display ratios only at the boundary; each field's core object
   re-read as a gauge variant of `r` in a *single calibrated ledger* rather than one field's
   identity claim. (The identities are old; the ledger as a claimed artifact — with an
   expiry criterion: each mapping must eventually yield a testable per-pair claim — is ours.)

**What we explicitly do NOT claim** (§2.2C guardrails): the ring is not Fisher information;
the wedge is not bivector area and not a causal arrow; hex addressing does not (yet) replace
the u32 XOR kernel; the hex norm is not "the ring"; i₊₁/i₀ are not isotropic; the χ² summand
does not distinguish attract from repel.

---

## 6. Open questions + next proofs (from `ROADMAP.md`)

Batches in order; within a batch everything is parallel.

- **Batch 2 (in flight):** `RadixEconomy.lean` (log₂3 ≈ 1.585; 3 beats 2, 4 ties 2) ·
  `Signature.lean` (what distinguishes i² = −1, +1, 0, ω: unit groups Z₄ / (Z₂)²-ish / {±1}
  / Z₆, zero divisors vs nilpotents vs domains — the four signatures are NOT isomorphic
  rings) · ternary D-latch/FF (2211.12176 App. A.3 — our CPU is sequential with binary FFs)
  · 3-operand balanced-adder design rule (the paper-proved PDP win) · **this document (F1)**.
- **Batch 3 (harder / tooling):** A4 Radon–Nikodym `δ = dμ_obs/dμ_null` on the finite pair
  space (needs mathlib `MeasureTheory` — the cleanest "counts vs probabilities" object) ·
  A5 dyadic-Lebesgue construction (Banica Prop 6.19: "Lebesgue = renormalized counting" as
  a construction; the flagship project) · B3 `√N ≤ wtHex ≤ N` (2412.18328 Thm 11 — closes
  our hex metric to the energy table) · C1 PDR/MaxSAT verification of `cpu.v` with
  `11`-as-don't-care (needs symbiyosys; boolector is installed).
- **Batch 4 (circuit/energy):** E1 ngspice netlist of the AC-polarity cell + 2-diode
  receiver — measure real ∫V·I per push/pull/null transfer to physically validate "null is
  free" · E2 Yosys power pass (PDP methodology from 2211.04542 — report power×delay, not
  cell counts) · D3 ternary instruction encoding (currently binary-host) · D4 `tmul_trits`
  optimization + write-masking + fractal-RAM (7ⁿ) in RTL.
- **Standing open math:** T6's geometric derivation and Thue/Fejes-Tóth optimality (cited,
  not proved) · the polarization axis has no Lean proof yet (port candidate #9, a two-line
  proof) · "hex addressing replaces the u32 XOR kernel" stays SPECULATION until the
  address-translation theorem exists · can the per-field `r`-as-gauge-variant mappings be
  upgraded from ANALOGY to DIRECT (preserving each field's theorems under the rewrite)?
  — with the fluency-trap warning that seeing the pattern everywhere is not proof.

---

## Reading map

1. **This paper** — orientation (you are here).
2. `GAUGE_VARIANTS.md` — the full naming scheme, variant table, "what the sums mean."
3. `docs/synthesis/measure-theory.md` · `docs/synthesis/ternary-circuits.md` — the two
   verdicts; graphs in `docs/graphs/`.
4. `proofs/INDEX.md` — the claim→file→status ledger; `PROVER_NOTES.md` — how the proofs
   were built.
5. `TERNARY_PROCESSOR.md` — the 12-opcode ISA, the one-wire cell, the fractal RAM;
   `ROADMAP.md` — what is next; `STATE_NOTE.md` — resume-here context.
