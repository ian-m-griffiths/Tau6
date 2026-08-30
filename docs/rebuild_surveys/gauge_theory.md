# Gauge Theory — 2-pass survey of the rebuild's gauge folder, mapped to the Tau Architecture (ternary lattice)

**Surveyed by:** research agent, 2026-08-29.
**Source (read end-to-end):** `/home/ian/opencode/parser/english/docs/surveys/gauge theory/` — 14 files
(`approaches`, `foundations`, `gauge_on_graphs`, `geometric_algebra`, `geometric_gauge`,
`gravitation`, `group_theory`, `higher_gauge`, `intro_1910`, `intro_9705`, `problem_of_gauge`,
`teaching`, `tensor_gauge`, `why_gauge`) **plus** `/home/ian/opencode/parser/english/docs/surveys/chat-session-gauge-unification.md`.
**Our side (read for the lens):** `Haar.lean`, `ChiSquareGauge.lean`, `ConventionBridge.lean`
(and, for the cross-check, `Gauge.lean`, `Registers.lean`, `Residual.lean`, `proofs/INDEX.md`,
`GAUGE_VARIANTS.md`, `HEXAGON_LATTICE_PLAN.md`).

**Path note (do not chase ghosts):** the task said `docs/GAUGE_VARIANTS.md` and
`docs/HEXAGON_LATTICE_PLAN.md`. Both actually live at the **repo root**
`/home/ian/dsh/projects/lattice/`, not under `docs/`. Cross-check used the real files.

**Calibration convention** (house standard, applied at mapping time — learning-method rule 1):

| Label | Meaning |
|---|---|
| **DIRECT** | Same math — proved in this repo's Lean ledger (`lake build` green) or standard classical math cited as such |
| **ANALOGY** | Same shape, correct job, wrong object |
| **OURS** | Our framing only — one side has no counterpart |
| **SPECULATION** | Unproven on both sides |

---

## PASS 1 — MAP (what the rebuild's gauge actually is)

### 1.0 The 14 files, one line each (map stage — description only)

| File | Source paper | One-line content |
|---|---|---|
| `approaches.md` | François–Lazzarini–Masson **1404.4604** (mislabeled 1310.4686 on disk) | Three frameworks (Ehresmann / NCG / transitive Lie algebroids) collapse to one master pattern *algebraic → global → geometric*; "gauge = a modeling constraint, not a physical symmetry" |
| `foundations.md` | same 1404.4604, deeper | Register (`E→E/T`) is a **global rescale = "basic" symmetry, NOT gauge**; the density dilation `ρ(a)ρ(b)` is the local U(1)-shaped gauge; curvature candidate = `dρ` across bands |
| `gauge_on_graphs.md` | Jiang 2211.17195 | Connection/curvature/holonomy on a DAG; global register = constant gauge (**DIRECT**); density dilation = Weyl/conformal (**not** gauge); gauge-invariant DOF = cyclomatic number `|E|−|V|+1` |
| `geometric_algebra.md` | Lasenby–Doran–Gull GTG | Geometric product = scalar+bivector; **rotor = gauge transformation, bivector = gauge field**; spinor = even subalgebra; corrections: gauge transform ≠ gauge field, wedge = field strength, grade-0 rotor inert |
| `geometric_gauge.md` | Marsh 2410.00918 | Parallel transport foundational, **metric derived up to scaling = "units is a gauge"**; only the register is an *internal* gauge; ring shift `d>>1` is a *base* coordinate change, NOT a gauge |
| `gravitation.md` | Blagojević–Hehl 1210.3775 | Gravity = gauging Poincaré; "gauge symmetry only in the local frame" = **local equivalence principle** (DIRECT); register = **Weyl/dilatation** gauge (not translation); t3 = broken frame, counter to Weitzenböck |
| `group_theory.md` | Li–Sun–Xiao–Yue 2602.01258 | Our normalization group is **R⁺ / 2^ℤ (Abelian scale = Weyl 1918)**, *not* SU(N); the wedge's non-commutativity is time-ordering, not a gauge commutator |
| `higher_gauge.md` | Baez–Schreiber 0511710 | Wedge is a **1-level "monoid not groupoid"** object, NOT a 2-morphism; fake-curvature-vanishing forces "somewhat abelian"; the bigon/surface layer is missing |
| `intro_1910.md` | Haydys 1910.10436 | Connection → gauge law `A'=g⁻¹Ag+g⁻¹dg` → curvature → holonomy; **δ = ratio = the invariant** (strongest DIRECT match); wedge = antisymmetric part; ring ≠ Chern class |
| `intro_9705.md` | Becchi hep-ph/9705211 | Gauge invariance is **derived from unitarity, not assumed**; δ = ξ-independent observable (DIRECT); **"δ = connection" RETIRED** (δ = holonomy−1); **"register = gauge = ring shift" RETIRED** (external vs internal) |
| `problem_of_gauge.md` | Witten 0812.4512 | The hard part is quantizing the quotient; we have the *classical* invariant δ, missing the group / quotient / quantization datum |
| `teaching.md` | Bomark 2009.02162 | Time-zone/economic models; δ = "only differences matter" (DIRECT); global rescale = register (DIRECT); ρ = exchange rate (DIRECT); but we have **no dynamical gauge field** |
| `tensor_gauge.md` | Chung–Lu 1609.03679 | δ = log-derivative connection (DIRECT); spinor = vierbein exp-map (DIRECT); grade-0 rotor = pure gauge (rank-0/1); three axes = basis tensors (ANALOGY, commuting gap) |
| `why_gauge.md` | Gomes 2203.05339 | `[ϕ]` invariant vs `ϕ` representative = δ vs the four registers (DIRECT); **but** register = *rigid*/global (NOT gauge proper), ρ = *malleable*/local (gauge proper) — the framework has them **labeled backwards** |

### 1.1 The rebuild's gauge: counting-vs-probability, the unit, the register (Q1 answer)

The rebuild (English-parser lattice, base-2 / u32 XOR kernel) carries **three distinct "gauge"
meanings that collide** (already named in `GAUGE_VARIANTS.md` §6.2; the surveys keep rediscovering
the collision and correcting it):

**(a) Counting-vs-probability = the register/measuring-stick gauge.**
Count `E = f(a)f(b)/T` vs probability `p(a)p(b) = f(a)f(b)/T² = E/T`. The shift is a **global
uniform rescale ÷T** (same `T` for every word). This is the *benign* gauge: it leaves δ and the
**ranking** invariant (the four surveys `gauge_on_graphs`, `foundations`, `geometric_gauge`,
`why_gauge`, `intro_1910` all agree it is a *constant* / *rigid* / *global* symmetry — a change of
units, **not** gauge proper in the local/pointwise sense).

**(b) The unit = the gauge-invariant core is the fold `δ = (O−E)/E = O/E − 1`.**
The four registers are δ dressed with powers of the area `E`:
`raw = E·δ`, `fold = δ`, `Pearson/z = √E·δ`, `surprise = E·δ²` (χ² summand; sign collapsed).
δ is the "ratio of two same-type quantities" — the ratio cancels the gauge (Haydys: "the ratio of
two sections is a genuine function"). The stored primitive is the **signed residual `r = O−E`**;
δ = r/E is the invariant *derived* from it.

**(c) Gauge = the unit (the algebraic unit's signature) — the chat-session's third position.**
`i² ∈ {−1, +1, 0, ω}` as a property of the *unit of the algebra* (Gaussian / split-complex / dual /
Eisenstein). This is TODO #16 in the rebuild (`gauge_int.rs`, `Signature`), the *genuinely new*
claim, and it is filed **SPECULATION** there (POC-coded, not integrated, not proved).

Plus a fourth overload: **"gauge = register = ring shift `d >> n`"** (RG-flow / barrel-shifter),
which the surveys repeatedly **retire** as mislabeling *external* (base) as *internal* (fiber).

### 1.2 The gauge-as-unit claim (the load-bearing edge)

`chat-session-gauge-unification.md` records the through-line: **least action demands a unit that
can realize it → the edge (difference) is that unit → the triangle is the edge-pair's natural
shape → n-dimensional triangles → one gauge-switchable set computing all of it in pure integers.**
Verbatim climax (turn 18, L9954): *"the gauge would be indistinguishable from the unit and a
property of it … the gauge variants are category theory operators … and geometric primitives."*
Turn 26 (L11070): *"least action has to make up the universe … the triangle is the artifact of the
edges of two integers … an n dimensional triangle … a unified set."*

### 1.3 The square-vs-triangular unification

The chat-session's unification is: **Gaussian integer ℤ[i] (square binary, 4-fold, `i²=−1`) is
dual to Eisenstein ℤ[ω] (triangular, 6-fold, `ω²+ω+1=0` or `ω²−ω+1=0`)**; a single
gauge-switchable set (`Signature i² ∈ {−1,+1,0,ω}`) computes both. The survey itself flags the
open thread honestly: *"whether square and triangular are truly one object (an algebraic map
between a²+b² and a²+ab+b², not just a compile-time flag)"* is **unresolved**.

---

## PASS 2 — LENS (calibrate each claim against OUR gauge)

### 2.0 OUR three Lean anchors (restated, so the calibration is concrete)

| Anchor | File | What is proved (`lake build` green, zero `sorry`) |
|---|---|---|
| Counting measure = primitive Z₆-invariant (Haar) | `Haar.lean` (A1) | `unit_inv` (each unit has a unit inverse), `mul_unit_bijective` (left-mult by a unit is a bijection), `sum_invariant` (change-of-variables), `measure_invariant_card` (`|u•S| = |S|`), `sum_invariant_of_invariant` (naive form on Z₆-stable sets), `units_counting_normalized` (`Σ 1/6 = 1`) |
| δ fold gauge-invariant | `ChiSquareGauge.lean` (A2) | `fold_gauge_invariant` (δ invariant under `(O,E)↦(c·O,c·E)`, c≠0), `surprise_scales` (χ² **scales by c**, NOT invariant), `fold_eq_surprise_div` (surprise = δ²·E) |
| 60° ≅ 120° (same ring) | `ConventionBridge.lean` (C1) | `phi_add`, `phi_mul` (φ interchanges 60°/120° multiplication), `phi_phi` (φ is an involution ⇒ bijective), `norm_preserved` (`N60 = N120 ∘ φ`, φ(a,b)=(a,−b)) |

Supporting (already proved, cited by the three anchors): `Gauge.lean` (G1 — `norm_of_unit`,
`norm_mul_unit`/`norm_unit_mul` isotropy, `norm_eq_det` = norm is the det of the regular rep = the
**area scalar**, `units_eq_omega_powers` = the six units are ω⁰…ω⁵, `omegaPow_six` = ω⁶=1);
`Registers.lean` (R2 — `δ_eq_residual_div`, `mul_delta_eq_residual`, `surprise_eq_delta_sq_mul_E`,
`surprise_sign_collapse`, `wedge_eq_residual_skew`, `sym_plus_skew`); `Residual.lean` (R1 —
`sum_E_row`, `sum_residual_eq_zero`, `wedge_antisymm`, `ringSq_nonneg`); `Signature.lean` (B4 —
the four signatures `i²=−1,+1,0,ω` are **distinguished**: unit counts 4/4/2/6, zero-divisor vs
nilpotent split).

### 2.1 The master calibration table

Every load-bearing claim from the 15 sources, calibrated against OUR gauge.

| # | Rebuild / source claim | OUR object | Verdict | Why |
|---|---|---|---|---|
| 1 | count→prob `E→E/T` is a global uniform rescale leaving δ + ranking invariant | `ChiSquareGauge.fold_gauge_invariant` | **DIRECT** | Proved: δ survives a common rescale c; the χ² term scales by c (`surprise_scales`). Pure algebra, base-independent |
| 2 | δ = O/E − 1 is the invariant core (fold); the four registers are δ·E^p | `Registers.lean` ladder + `ChiSquareGauge` | **DIRECT** | `δ_eq_residual_div`, `mul_delta_eq_residual`, `surprise_eq_delta_sq_mul_E`, `fold_eq_surprise_div` — the ladder is proved over ℚ |
| 3 | `r = O−E` is the stored primitive; E = f(a)f(b)/T; Σ(O−E)=0; wedge skew; χ²≥0 | `Residual.lean` | **DIRECT** | `sum_residual_eq_zero`, `wedge_antisymm`, `ringSq_nonneg`, `sum_E_row` |
| 4 | density dilation `ρ(a)ρ(b)` is the *local* gauge (Weyl/dilatation, abelian R⁺) | (no Lean object yet) | **ANALOGY** | Same transformation *shape* as U(1) link law `U_ab↦g_a U_ab g_b⁻¹`; but our ρ is a measured background CDF, not a gauge field; the **gauge group is abelian R⁺**, and the surveys correctly retire "register = gauge" for the *global* case |
| 5 | "register = gauge = ring shift `d>>n`" | — | **RETIRED** (ours) | Ring shift is *external/base* (2-adic RG blocking); a gauge is *internal/fiber*. Our ternary analog of "cheap gauge change" is **multiply by a Z₆ unit** (`Gauge.lean` `norm_mul_unit`), not a bit-shift |
| 6 | **gauge = the unit** (signature `i² ∈ {−1,+1,0,ω}`) | `Signature.lean` + `Gauge.lean` + `Haar.lean` | **DIRECT** (ours proves it) | This is exactly OUR project's contribution. `Signature.lean` proves the four signatures are distinguished; `Gauge.lean` proves the ω case has Z₆ units and an area-scalar norm; `Haar.lean` proves the counting measure is Z₆-invariant. The rebuild only has this as **SPECULATION** (TODO #16); we have it **PROVED** |
| 7 | GP = scalar + bivector; wedge = antisymmetric/bivector part; rotor = gauge transformation | `DotWedge.lean`, `Conjugate.lean`, `Gauge.lean` | **DIRECT (partial)** | `DotWedge.lean` proves `gp_decomp`, `wedge_antisymm`, `dot_self=N(z)`, `wedge_self=0`, `dot_sq_add_wedge_sq`; `Conjugate.lean` proves `mul_conj_eq_norm`. But the **full GA rotor/even-grade spinor** (Cℓ₀,ₙ) is **base-2** (blade bitmask = cubic Bₙ) — see #11 |
| 8 | spinor = even subalgebra; grade-0 rotor is inert; fix `ψ=(α+βI)U` | mod-6 integer spinor `Z₆ ⊂ SO(2)` | **DIRECT (the one bridge)** | `Gauge.lean` `units_eq_omega_powers` + `omegaPow_six` = the six units are exactly the ω-orbit closing at ω⁶=1 — an **exact integer rotor**; `CrtHex.lean` proves Z₆ ≅ Z₂ × Z₃ (sign × 3-cycle). This is the ONE direct bridge the plan names (§2.6) |
| 9 | ring² = χ² divergence = L2 norm, NOT Fisher info | `Residual.lean` `ringSq_nonneg` | **DIRECT + guardrail** | The definition is proved; the "is-not Fisher / is-not a matrix" part is a **guardrail** (`GAUGE_VARIANTS` §3.C) |
| 10 | "square binary = Gaussian; triangular = Eisenstein; a unified set computes both" | `Signature.lean` + `ConventionBridge.lean` + `OffsetGrid.lean` | **ANALOGY (NOT an isomorphism)** | The four signature algebras are **genuinely different rings** (Z₄ vs Z₆ units; `Signature.lean` `signatures_distinguished`). What *is* proved: (a) the two Eisenstein conventions are the **same ring** (`ConventionBridge` C1); (b) hex grid ≃ offset **square** grid (`OffsetGrid.lean`) — a geometric basis change, not a ring isomorphism; (c) hex↔u32 bijection exists (`Bijection.lean`). "Square and triangular are one object" is **false as stated** — the unification is a *pattern*, not an identity |
| 11 | hex / Aₙ-simplex addresses vs cubic Bₙ hypercube (base-2 blade bitmask) | hex axial (q,r,s), q+r+s=0; SevenHex T2; Bijection B1 | **ANALOGY** | Our ternary lattice is A₂ (hexagon), not Bₙ. The rebuild's clifford.rs is the cubic Bₙ hypercube. Same *idea* (lattice addressing), different root system. `SevenHex.lean` proves 7-hex ↔ balanced ternary; `Bijection.lean` proves hex↔u32. The **replacement** of the u32 XOR kernel is **SPECULATION/BLOCKED** |
| 12 | "gauge symmetry only in the local frame" (held-out P@50 plateau) | rest-frame / proper-frame residue | **OURS** | No Lean counterpart yet; the empirical held-out result is ours, not in any source paper. The papers supply the *vocabulary* (equivalence principle, rigid→malleable) — ANALOGY |
| 13 | "δ is the gauge connection" | δ = holonomy−1, not a connection | **RETIRED** (intro_9705) | δ is a scalar ratio, no index, no inhomogeneous shift. The honest mapping: `O/E` = holonomy, δ = its first-order tangent (`log(1+δ)=δ−δ²/2+…`) |
| 14 | "the register IS a connection / principal bundle" | — | **SPECULATION** | The surveys converge: we have a gauge *group* candidate (R⁺, or Z₆ here) and a gauge *invariant* (δ), but **no connection field, no quotient, no quantization datum** (Witten) — gauge-fixed, not gauge-dynamical |
| 15 | Chern class / characteristic class = ring | — | **OURS / not-a-class** | Ring is a scalar χ² divergence, not a cohomology class. No characteristic class exists in the ledger |
| 16 | Weitzenböck `Δ_A = B_A + Ric + F` | ring (χ²) ↔ Forman-Ricci | **SPECULATION** | No graph-Ricci object computed; the link is untested |
| 17 | holonomy / loop polarity `∏ sign(O−E)` around cycles | (queued, not in ledger) | **ANALOGY / OURS (unbuilt)** | The sources formalize it (Jiang's holonomy, the cocycle); our loop-polarity opcode is **not yet in the Lean ledger** |
| 18 | "gauge = register" is the paper's *modeling constraint* (not Noether symmetry) | `ChiSquareGauge` gauge invariance | **DIRECT (framing)** | The register choice leaves δ invariant — the paper's "descriptive redundancy" verbatim; but *only* the global/rigid part, per `why_gauge` |

### 2.2 The chat-session vs our plan (Q2 — is it the seed?)

**Does the chat-session really derive the Eisenstein/triangular lattice?** Yes — as a *derivation
arc*, not a proof. It runs from gauge symmetry of `(a−a²)/2` through "e is on the base", "gauge =
the unit", Gaussian integer, to **Eisenstein** (turn 25: *"the unit = the equilateral-triangle
distortion; categorically different, not just a speedup"*) and the n-simplex/unified set (turn 26).
The chain is *motivated* ("least action requires such a unit") but every step is the author's
intuition — the survey marks the whole thing SPECULATION-where-new, and its own open threads list
square-vs-triangular-isomorphism and the L2-by-addition claim as **unresolved**.

**Is it the seed of OUR plan?** Partially — it is a *convergent*, independent re-derivation, but
**not the primary seed**. Cross-check:

- `HEXAGON_LATTICE_PLAN.md` cites its sources as `hexigon_conversation.md` (the Tau Architecture
  thread), `survey/SYNTHESIS.md`, `survey/oxalpha_lens.md`, `LATTICE_MATH.md`, ox alpha TODO #16.
  It does **not** cite `chat-session-gauge-unification.md`. The primary seed is the hexigon thread.
- The **content overlaps** at exactly three named joints, all of which the plan already carries:
  (1) **Eisenstein ℤ[ω], ω=e^{iπ/3}, N=a²+ab+b², units Z₆** — plan §3, proved T0/T1/G1;
  (2) **"gauge = the unit" / Signature `i²∈{−1,+1,0,ω}`** — TODO #16, proved `Signature.lean` B4;
  (3) **the mod-6 integer spinor `ψ=(α+βI)U`** — plan §2.6 "the one DIRECT bridge".
- `GAUGE_VARIANTS.md` §6.3 names the chat-session's "gauge = the unit" as *"the conversation's one
  genuinely new idea — filed as SPECULATION, POC-coded in `gauge_int.rs`, not integrated or proved."*

**Verdict:** the chat-session is a **corroborating seed**, not the origin. It independently lands
on the same three objects our plan already formalizes, and it *adds* one item our plan only implies:
the explicit **square-vs-triangular "unified set"** claim — which our ledger refines into (a) the
60°≅120° convention bridge (proved, same ring) and (b) the four-signature family (proved,
**distinguished**, hence *not* one object). Do not cite the chat-session as the origin of the
Eisenstein plan; cite it as the **gauge-as-unit** intuition that `Signature.lean`/`Gauge.lean`/
`Haar.lean` now make precise.

### 2.3 What transfers to our ternary lattice: DIRECT vs base-2 ANALOGY (Q3)

**DIRECT (base-independent — the statistical gauge is already ours, proved):**

- The **fold δ = O/E − 1 is the gauge-invariant core**; the count→prob rescale leaves it invariant
  and scales χ² (`ChiSquareGauge.lean`). No base enters; it transfers verbatim.
- The **register ladder** raw/fold/z/surprise = E·δ, δ, √E·δ, E·δ² (`Registers.lean`), and the
  **signed residual `r=O−E`** as the primitive with wedge skew (`Residual.lean`). Base-independent.
- The **"gauge = the unit" (signature) idea** — but here it *upgrades* from the rebuild's
  SPECULATION to our PROVED `Signature.lean` + `Gauge.lean` + `Haar.lean`. The ternary/Eisenstein
  case (`i²=ω`, Z₆) is our native one.

**ANALOGY (base-2 → ternary translation — same shape, different object):**

- **Ring shift `d >> n` (2-adic barrel shift) → our gauge change = multiply by a Z₆ unit**
  (`Gauge.lean`), and the **7ⁿ fractal hex RAM** (`FractalRam.lean`) is the base-7 analog of the
  base-2 address shift. The *mechanism* (cheap scale/gauge change by an integer op) transfers; the
  *radix* does not (2 vs 3/6/7).
- **Square binary = Gaussian ℤ[i] ↔ triangular = Eisenstein ℤ[ω]** — this is the Aₙ/Bₙ,
  Z₄/Z₆ split (`Signature.lean`). Analog, **not** isomorphic. The "unified set" transfers only as
  a *pattern* (2-dim algebra with a signature), never as an identity.
- **GA rotor / even-grade spinor (Cℓ₀,ₙ, base-2 blade bitmask)** → our **mod-6 integer spinor**
  (Z₆ ⊂ SO(2), `Gauge.lean` + `CrtHex.lean`). This is the plan's *one direct bridge* — but it is a
  *discrete* rotor, not the full Clifford even subalgebra; the bivector/grade structure (`DotWedge`,
  `Conjugate`) is proved in the Eisenstein setting, the full GA is not.
- **u32 XOR kernel (Boolean hypercube (Z₂)³²)** → **hex addressing / balanced ternary**
  (`SevenHex.lean` bijection, `Bijection.lean` hex↔u32). The *replacement* claim stays
  SPECULATION/BLOCKED; only the bijection is proved.

**OURS / SPECULATION (no source counterpart):** held-out P@50 gauge-plateau, "store δ not r" as a
Lean theorem, the multifractal/rest-frame content, Weitzenböck/Forman-Ricci link, Chern class.

---

## 3. Lean-provable identities vs cited theorems (Q4)

### 3.1 Lean-proved (DIRECT, `lake build` green, zero `sorry` — the ones this survey touches)

**Gauge-invariance (the δ/χ² split):**
- `fold_gauge_invariant` — δ = O/E − 1 invariant under `(O,E)↦(c·O,c·E)`, c ≠ 0 (`ChiSquareGauge.lean`).
- `surprise_scales` — χ² surprise `(O−E)²/E` scales by c, i.e. is **not** invariant.
- `fold_eq_surprise_div` — surprise = δ²·E (the ladder relation behind "store δ, not r").
- `surprise_sign_collapse` + `surprise_nonneg` — squaring kills the attract/repel sign (`Registers.lean`).

**The unit / counting measure (Haar):**
- `unit_inv` — every Z₆ unit has a unit inverse; `mul_unit_bijective` — left-mult by a unit is a bijection.
- `sum_invariant`, `measure_invariant_card` (`|u•S|=|S|`), `sum_invariant_of_invariant` (naive form on Z₆-stable sets).
- `units_counting_normalized` — `Σ_{units} 1/6 = 1` (the normalized counting measure is a probability measure).

**Isotropy / the area scalar (the "gauge" the chat-session wanted):**
- `norm_of_unit`, `norm_mul_unit`, `norm_unit_mul` — norm invariant under the six units.
- `norm_eq_det` — N(a+bω) = det of the regular rep = the **area scalar**.
- `units_eq_omega_powers`, `omegaPow_six` — the six units are ω⁰…ω⁵, ω⁶=1 (the mod-6 rotor).
- `units_card`, `units_closed_under_mul` (`Rotation.lean`); `mul_comm`, `norm_mul` (`Conventions.lean`).

**The convention bridge (60° ≅ 120°):**
- `phi_add`, `phi_mul`, `phi_phi`, `norm_preserved` — φ(a,b)=(a,−b) is a ring isomorphism
  interchanging the 60° and 120° multiplications and preserving the norm.

**The register ladder / residual (supporting):**
- `δ_eq_residual_div`, `mul_delta_eq_residual`, `surprise_eq_delta_sq_mul_E`, `wedge_eq_residual_skew`,
  `sym_plus_skew` (`Registers.lean`); `sum_E_row`, `sum_residual_eq_zero`, `wedge_antisymm`,
  `ringSq_nonneg` (`Residual.lean`).

**The signature family (square-vs-triangular as a *pattern*):**
- `gaussianUnits_card` (4), `split_zero_divisor` (i²=+1), `dual_nilpotent` (i²=0), `dualUnits_card` (2),
  `signatures_distinguished` (`Signature.lean`) — the four signatures are genuinely different rings.

### 3.2 Cited as classical (NOT proved in this repo)

- **Thue / Fejes-Tóth** optimality of hexagonal packing — *cited*; only the density **number**
  `τ/(4√3) = π/(2√3)` is proved (`Packing.lean` T6, partial). Geometric derivation deferred.
- **Gaussian integers ℤ[i]** (i²=−1) — standard classical math, cited as the *model* in
  `EuclideanDomain.lean`'s header (mirrors mathlib `GaussianInt`); not ported.
- **split-complex (i²=+1)** and **dual numbers (i²=0)** — standard algebra; `Signature.lean` proves
  only their *finite-ring* distinguishing facts, not the classical analytic structure.
- **The 11-field identities** (χ² ≈ 2·I at 2nd order, force = O−E, excess return, etc.) —
  ANALOGY, cited from `ox alpha.md` L1600–1628 / L1759, **not** proved per-pair.

### 3.3 The one thing to say plainly

The rebuild's gauge folder **validates δ-invariance and gauge-as-unit as real structure** (not
metaphor), but its own surveys repeatedly **retire** three over-claims — "register = gauge" (it's
a global units change), "δ = the connection" (δ is holonomy−1), "gauge = register = ring shift"
(external vs internal). Our ternary lattice is the place where the *remaining* true part —
**"gauge = the unit"** — is actually proved: the Z₆ unit group, the area-scalar norm, the
Z₆-invariant counting measure, and the 60°≅120° convention bridge.

---

## TODO / not covered / caveats

1. **Path discrepancy (noted in provenance):** `GAUGE_VARIANTS.md` and `HEXAGON_LATTICE_PLAN.md`
   are at the repo **root**, not under `docs/`. Anyone re-running this survey should read them
   from `/home/ian/dsh/projects/lattice/`, not `docs/`.
2. **The density dilation `ρ(a)ρ(b)` has no Lean home yet.** The surveys agree it is the genuinely
   local/Weil gauge-shaped object (U(1)-link-law shape), but our ledger has no `Rho.lean`. It is
   the biggest *unported* claim from the gauge folder (ANALOGY, "we should test").
3. **Loop polarity / holonomy is still unbuilt.** `∏ sign(O−E)` around closed cycles (Jiang's
   holonomy, the cocycle) is queued but absent from `proofs/INDEX.md`. It is the concrete
   *curvature* statistic the folder keeps handing us, and the natural next Lean target.
4. **"Square ≅ triangular" is disproven as an isomorphism** by `Signature.lean`
   (`signatures_distinguished`): Gaussian (Z₄) and Eisenstein (Z₆) are different rings. The
   chat-session's "unified set" survives only as a *pattern*. Do not over-claim the unification.
5. **No connection field, no quotient, no quantization datum.** Witten's checklist is unmet: we
   have a gauge invariant (δ) and a gauge group candidate (Z₆ here / R⁺ in the rebuild), but no
   connection, no `A/G` quotient, no bounded-below-energy datum. Our system is gauge-*fixed*, not
   gauge-*dynamical*.
6. **The full GA rotor is base-2.** `DotWedge.lean`/`Conjugate.lean` prove the Eisenstein
   geometric-product *split*, but the even-grade spinor `ψ=(α+βI)U` over Cℓ₀,ₙ is not proved; only
   the discrete mod-6 rotor (Z₆ ⊂ SO(2)) is. The Aₙ-simplex generalisation (chat-session turn 26)
   is entirely unbuilt.
7. **Ring ≠ Fisher / ≠ Chern class / ≠ causal arrow / ≠ metric** — these are *guardrails*
   (retired claims), not theorems; they belong in the calibration ledger, not the proof ledger.
8. **"Hex addressing replaces the u32 XOR kernel" is SPECULATION / BLOCKED** — `Bijection.lean`
   proves the bijection exists, not that it should replace the kernel.
9. **Empirical claims (held-out P@50 = 1.0, gauge plateau, c = L1/λ) are OURS** — no Lean statement
   yet, and no source-paper counterpart; they are the *motivation* for the gauge reading, not its
   proof.
10. **Chat-session ≠ origin.** It corroborates the Eisenstein plan but is not its seed (the
    hexigon thread is). If provenance headers cite it, cite it for the "gauge-as-unit" intuition
    only.
