# Field Calculus — the Maxwell↔heat synthesis

**2026-08-29 — research/synthesis doc (not a proof, not a measurement).** One task: name and
calibrate the calculus that `∇F = J` (the invertible geometric derivative) and
`∂u/∂t = α∇²u` (heat/diffusion) jointly define, and say whether it is a *new computation class*
or the abstraction the residual lattice **already runs on**.

Calibration legend (repo-wide, unchanged): **DIRECT** = classical theorem / proved in the Lean
ledger / measured; **ANALOGY** = structural resemblance, different object; **OURS** = our design
claim that *follows from* a DIRECT fact but is unmeasured; **SPECULATION** = untested hypothesis.

Sources read first: `geometric_algebra.md` (∇F=J invertible),
`jacobian-determinant-matrix.md` (Helmholtz = scalar/bivector), `DotWedge.lean` (our just-proved
dot/wedge split), plus `GA_INSTRUCTIONS.md`, `einstein_calculus.md`, `computer_science.md`, and
the full `proofs/INDEX.md` ledger.

---

## 0. TL;DR (verdict up front)

**The two equations are the SAME operator at two orders, and "first order / second order" is the
right framing *only once you add the one word that does the work — invertibility*.**

- `∇F = J` and `∂u/∂t = α∇²u` share the geometric derivative ∇. Maxwell is **first order in ∇**
  and **invertible** (∇ has a multivector Green's function); heat is **second order in ∇** and
  **non-invertible** as a forward flow (the heat semigroup `e^{tα∇²}` is a contraction that
  destroys information). `∇² = ∇·∇ = Δ` is a **DIRECT GA identity** (the square of the vector
  derivative *is* the Laplacian), so "heat = the square of Maxwell's derivative" is literally
  true. The precise unification is the **square-root factorization**: the geometric derivative
  ∇ *is* the Dirac operator, `∇ = √∇²` — first order is the square root, second order is the
  square. That single fact is what explains *both* the order *and* the invertibility contrast.

- **The name: the field calculus** — the calculus of **one invertible derivative and its two
  orders**: ∇ (derivative + reconstruction, lossless) and ∇² (relaxation/dissipation, lossy).
  Mnemonic: **"∇ reconstructs, ∇² relaxes."**

- **Helmholtz is our dot/wedge, DIRECT and PROVED.** `F = −∇φ + ∇×A` (irrotational + solenoidal)
  *is* the scalar/bivector (grade-0 / grade-2) split of the geometric product, and the reason it
  matters is that **invertibility of ∇ requires both grades** — div alone and curl alone each
  drop a grade and are separately non-invertible. Our `DotWedge.lean` proves the split
  (`gp_decomp`), the antisymmetry (`wedge_antisymm`), the self-vanishing wedge (`wedge_self = 0`
  = the "curl grad = 0" analog), and the energy identity `dot² + dot·wedge + wedge² = N(z)N(w)`.

- **Verdict: NOT a new computation class.** The math is classical GA/vector calculus; and the
  residual lattice **already runs on it** — `r = O−E` is the (discrete) derivative, the wedge is
  the curl, `Σ(O−E) = 0` is the source conservation, and the split is proved. What is genuinely
  new-ish is **OURS**: encoding derivative / reconstruction / relaxation as *native instructions*
  on the ternary Eisenstein substrate. That is a **new instruction abstraction**, not a new
  class of hardware (the same verdict `einstein_calculus.md` reached, and for the same reason).

- **Two category-errors to keep out** (both already caught in-survey): (1) the graph Laplacian
  `L = D − W` **≠** the residual `O − E` (`computer_science.md`), so the heat operator's ∇² is
  the Laplacian *of the field*, a third object, not the residual and not the adjacency matrix;
  (2) the smooth/discrete gap — `∇F = J` is a smooth-manifold object, the residual is a discrete
  difference (`jacobian-determinant-matrix.md` honest calibration), so "residual = ∇F" is
  **ANALOGY**, not identity.

---

## 1. How ∇F = J and ∂u/∂t = α∇²u relate in GA

### 1.1 The two facts, precisely

**Fact A — `∇F = J` is one equation and it is invertible.** In GA, all of Maxwell's equations
collapse to a single equation `∇F = J`, where ∇ is the **vector (geometric) derivative**, F is
the electromagnetic field (a bivector, `F = E + iB`), and J is the source (4-current). The
geometric derivative has a **multivector Green's function** (the Cauchy kernel), so the equation
is solved by `F = ∇⁻¹J` — a *lossless reconstruction* of the field from the source. Divergence
and curl **separately** have no such inverse (div drops the rotational part, curl drops the
gradient part); only the *full* ∇ — both grades at once — is invertible. **[DIRECT — Hestenes–
Sobczyk 1984, via `geometric_algebra.md`]**

**Fact B — `∇² = ∇·∇ = Δ`, the square of the derivative is the Laplacian.** Because the wedge is
antisymmetric, `∇∧∇ = 0` (the mixed second partials kill the bivector part), so the square of
the vector derivative collapses to the scalar Laplacian: `∇∇ = ∇·∇ + ∇∧∇ = ∇·∇ = ∇² = Δ`. The
heat operator `α∇²u` is therefore *literally the square of the derivative that appears in
Maxwell*, applied to a scalar field u. **[DIRECT — standard GA; `∇∧∇ = 0` (the "curl grad = 0" identity)
is the derivative-level instance of the *same* antisymmetry whose self-product case is our
`wedge_self : wedge z z = 0`]**

**Fact C — the square-root factorization.** The vector derivative acting on spinors *is* the
Dirac operator D, and the Clifford relation `γᵏγʲ + γʲγᵏ = 2gᵏʲ` gives `D² = ∇²`. So ∇ is the
**square root of the Laplacian** — first-order Maxwell is the Dirac/square-root equation, and
second-order heat is the Laplace/square equation. **[DIRECT — Hestenes–Sobczyk]**

### 1.2 Is "Maxwell = first order, heat = second order" the right framing?

**Right at the operator level; incomplete as stated.** Three refinements:

1. **"Order" is order in ∇ (space), not in time.** Heat is *first* order in `∂/∂t` and *second*
   order in ∇; Maxwell is *zeroth* order in t (a static constraint) and *first* order in ∇. The
   honest sentence is: "Maxwell is first order in ∇ (a constraint); heat is first order in t and
   second order in ∇ (an evolution)."

2. **The word that does the work is "invertible," not "order."** ∇ is invertible (reconstruction
   is lossless); `e^{tα∇²}` for t>0 is *not* invertible (it's a contraction semigroup — high
   spatial frequencies decay, information is irreversibly lost). So "two orders" is shorthand for
   a *sign change in the information behavior*: order-1 reconstructs, order-2 dissipates. Same
   operator, opposite arrow on information.

3. **The precise unification is the square-root framing.** "Maxwell is the square root, heat is
   the square" states the order *and* the invertibility contrast in one clause: `∇ = √∇²`. This
   is the cleanest and the correct one-liner.

**Bottom line:** "first order / second order" is the right *operator-level* framing, but it must
carry the invertibility rider, else it hides the actual content — that the field calculus is one
derivative that is *reversible at order 1* and *irreversible at order 2*.

### 1.3 The two-attractor reading (OURS, consistent with canonical truth)

AGENTS.md canonical truth: **"attractor is two opposite zeros"** — feedback equilibrium `O→E`
(noise) vs topic center `div=0` (max structure). The two orders land on the two zeros:

- **Relaxation (∇², heat)** drives the field *toward* `O→E` — the residual decays to zero, the
  field relaxes to equilibrium/noise. This is the dissipative, null attractor.
- **Reconstruction (∇, Maxwell)** solves `∇F = J`; its *source-free* points (`∇F = 0`, i.e.
  `div F = 0` and `curl F = 0` — harmonic) are exactly the `div=0` topic centers, the structural
  attractor.

So the field calculus's two orders reproduce the two opposite zeros of the canonical attractor.
**[OURS — a reading, consistent with the canonical truth; not proved as a dynamics]**

---

## 2. The joint field calculus — the operation set a processor could run

The calculus is generated by **one operator and its two powers**, plus the **grade split** that
makes the first power invertible.

| # | Operation | Symbol | What it is | Calibration |
|---|---|---|---|---|
| 1 | **derivative** | `∇` | the vector derivative; on the lattice, the residual `r = O−E` (a signed difference) | DIRECT as math; ANALOGY as "residual = ∇F" (discrete vs smooth) |
| 2 | **grade split** | `∇F = ∇·F + ∇∧F` | divergence (scalar) + curl (bivector) — the dot/wedge split | DIRECT, PROVED (`gp_decomp`, `DotWedge.lean`) |
| 3 | **reconstruction** | `∇⁻¹` | the inverse derivative / Green's function: field ↔ source, lossless | DIRECT (GA); the *discrete* inverse is OURS/untested (gauge freedom) |
| 4 | **relaxation** | `∇²`, `e^{t∇²}` | one heat iteration `u ← u + α∇²u`; the diffusion semigroup | DIRECT as math; the lattice's ∇² object is OURS/undefined |
| 5 | **source / rotation extraction** | `∇·`, `∇∧` | the two grade projections of the derivative | DIRECT (subset of #2) |
| 6 | **square root** | `√∇²` | the Dirac/Clifford factorization ∇ = √∇² (the spinor) | DIRECT (GA); SPECULATION as a datapath |

**The one structural fact that ties it together:** invertibility lives in the *grade split*. Div
alone (grade 0) and curl alone (grade 2) each lose a grade and are non-invertible; the full
multivector derivative (both grades) is invertible. So the dot/wedge split is **not bookkeeping**
— it is *the* reason reconstruction is possible. **[DIRECT — Hestenes–Sobczyk; our half is the
proved `gp_decomp`]**

### 2.1 The residual lattice already runs on it (the map)

| Lattice object | Field-calculus reading | Calibration | Proof |
|---|---|---|---|
| `r = O−E` (signed residual) | the field / the (discrete) derivative ∇ | DIRECT (a difference); ANALOGY (as a smooth derivative) | `Residual.lean` `sum_residual_eq_zero` |
| `wedge = O_ab − O_ba` | the curl ∇∧F (bivector / skew part) | DIRECT (antisymmetry); NOT bivector area, NOT causal | `Residual.lean` `wedge_antisymm`, `Registers.lean` `wedge_eq_residual_skew` |
| `Σ(O−E) = 0` | the source conservation / divergence balance | DIRECT (telescopes) | `Residual.lean` `sum_residual_eq_zero` |
| `δ = r/E` | the gauge-invariant (normalized) derivative | DIRECT | `Registers.lean` `δ_eq_residual_div`, `ChiSquareGauge.lean` |
| `sym + skew` split | the Helmholtz decomposition | DIRECT | `Registers.lean` `sym_plus_skew` |
| `ring² = Σ(O−E)²/E` | the field's L2 norm / energy (`‖F‖²`) | DIRECT as a norm; NOT Fisher info | `Residual.lean` `ringSq_nonneg` |
| `dot² + dot·wedge + wedge² = N(z)N(w)` | the energy decomposition `(a·b)² + (a∧b)² = |a|²|b|²` | DIRECT (Lagrange/Pythagoras) | `DotWedge.lean` `dot_sq_add_wedge_sq` |

The **one genuinely new piece** the field calculus adds over the already-documented
`einstein_calculus.md` (delta / telescope / second difference): it names **reconstruction** (the
telescope *is* ∇⁻¹, and it is *invertible*, not merely a summing identity) and **relaxation**
(the second difference *is* ∇², the heat/dissipation operator, a non-invertible semigroup). The
field calculus = the Einstein calculus + **invertibility** + **the diffusion reading of the
second order**.

---

## 3. The instruction set it implies

Mapped onto the existing opcode table (`eisen_opcode.md`: `TADD=0, TSUB=1, TROT=2, TNORM=3,
LDI=4, TMUL=5, HLT=F`), extending `GA_INSTRUCTIONS.md`. No instruction-word format change —
opcodes `6`–`E` are unassigned.

### Tier 1 — the grade split (already specified, now proved)

| Opcode | Semantics | Status |
|---|---|---|
| `TCONJ` | conjugate `a+bω ↦ (a+b)−bω` | `Conjugate.lean` PROVED |
| `TDOT` | scalar part `Re(z·w̄)` = correlation = the ∇· (div/source) grade | `DotWedge.lean` PROVED |
| `TWEDGE` | bivector/skew part `Im(z·w̄)` = curl = the ∇∧ grade | `DotWedge.lean` PROVED (`wedge_antisymm`, `wedge_self`) |

### Tier 2 — the field-calculus core (new; the "reconstruct + relax" pair)

| Opcode | Semantics | Calibration |
|---|---|---|
| `TGRAD` | the geometric derivative `∇` — the directed-edge residual / one Jacobian step | DIRECT (GA); ANALOGY on the lattice (discrete) |
| `TLAPL` | the Laplacian `∇² = ∇·∇` — the square of the derivative (the heat operator's spatial part) | DIRECT (∇²=Δ); the *discrete* ∇² object is OURS/undefined |
| `TRELAX` | **one heat iteration** `u ← u + α·∇²u` — the relaxation/dissipation step | DIRECT (forward Euler of heat); OURS as an opcode |
| `TRECON` | the invertible reconstruction `F = ∇⁻¹J` — the directed integral / fundamental-theorem inverse | DIRECT (GA Green's function); the discrete inverse is OURS/untested |
| `TDIV` / `TCURL` | the two grade projections of `TGRAD` (source / rotation extraction) | DIRECT; subset of TDOT/TWEDGE applied to ∇F |

### Tier 3 — the square-root factorization (speculative, higher cost)

| Opcode | Semantics | Calibration |
|---|---|---|
| `TSPINOR` | `ψ = ρ^{1/2}e^{Iβ/2}R` (Lasenby) — the ∇ = √∇² factorization, the even-grade rotor | DIRECT (GA); SPECULATION as a datapath |
| `THODGE` | the Hodge dual `I·v` — the vector↔bivector transition | DIRECT (GA); SPECULATION as a datapath |

**Note on the honest costing discipline:** `TMUL` was *measured* at **+64.8% area**
(`eisen_opcode.md`). `TGRAD`/`TLAPL`/`TRELAX`/`TRECON` have **no RTL, no area, no energy** —
they are ISA *names*, not datapaths, until measured. Do not read "native instruction" as "cheap."

---

## 4. Helmholtz = the scalar/bivector split = our dot/wedge

**Yes — this is the same split, and we proved our half.**

- **Helmholtz** (`jacobian-determinant-matrix.md`, finding 4): `F = −∇φ + ∇×A` decomposes a
  vector field into **irrotational** (gradient of scalar potential φ) + **solenoidal** (curl of
  vector potential A), exact because `curl grad = 0` and `div curl = 0`. **[DIRECT — classical]**

- **GA restates it as the grade split of the derivative:** `∇F = ∇·F + ∇∧F` — the scalar/div
  part (grade 0, the "dot", the irrotational gradient source) + the bivector/curl part (grade 2,
  the "wedge", the solenoidal rotation). The two always-zero identities are the antisymmetry that
  makes the split exact. **[DIRECT]**

- **Our `DotWedge.lean` proves exactly this algebra** on the Eisenstein product `z·w̄`:

  | GA / Helmholtz statement | Our proved theorem | Meaning |
  |---|---|---|
  | `ab = a·b + a∧b` (scalar + bivector) | `gp_decomp : z·conj w = ⟨dot, wedge⟩` | the geometric product *is* the two-coordinate split |
  | `a∧b = −b∧a` (curl flips sign) | `wedge_antisymm : wedge z w = −wedge w z` | the wedge is the skew/curl part |
  | `a∧a = 0` (no self-area) | `wedge_self : wedge z z = 0` | a single vector spans no bivector |
  | `(a·b)² + (a∧b)² = |a|²|b|²` (Lagrange) | `dot_sq_add_wedge_sq : dot²+dot·wedge+wedge² = N(z)N(w)` | the full energy decomposition |
  | `F = sym + skew` (Helmholtz split) | `sym_plus_skew : O = (O+Oᵀ)/2 + (O−Oᵀ)/2` (`Registers.lean`) | the field splits into symmetric + antisymmetric |

**Calibration: DIRECT.** The correspondence is one grade-level down from a subtle point, so be
precise: Helmholtz decomposes a *vector field* F via *two potentials* (scalar φ, vector A); our
`DotWedge` decomposes a *single geometric product* `z·w̄` into its scalar + bivector coordinates.
They are the **same grade split** (grade-0 scalar / irrotational vs grade-2 bivector / solenoidal)
applied at different places — ours on the product, Helmholtz's on the derivative of a field.
The algebra is identical; the *uniqueness-of-decomposition* theorem (Helmholtz) is the smooth
guarantee that our discrete split is a finite analogue of. **[DIRECT for the algebra, PROVED in
`DotWedge.lean`]**

---

## 5. Calibrated verdict — new computation class, or the abstraction the lattice already runs?

**The verdict: it is the abstraction the residual lattice already runs on, made explicit — NOT a
new computation class.** The genuinely new thing is a *new instruction abstraction*, and only
that part is OURS/SPECULATION.

| Level of the claim | What it is | Calibration |
|---|---|---|
| `∇² = Δ` (heat's operator is Maxwell's derivative squared) | standard GA; the vector derivative squares to the Laplacian | **DIRECT** |
| `∇` invertible (multivector Green's function; div/curl not, separately) | Hestenes–Sobczyk; the crux of "lossless reconstruction" | **DIRECT** |
| `∇ = √∇²` (Dirac/Clifford square-root factorization) | Clifford relation `γᵏγʲ+γʲγᵏ = 2gᵏʲ` | **DIRECT** |
| Helmholtz = grade-0 + grade-2 split | classical vector calculus | **DIRECT** |
| Our dot/wedge = that split | `gp_decomp`, `wedge_antisymm`, `wedge_self`, `dot_sq_add_wedge_sq` | **DIRECT, PROVED** |
| `r = O−E` is the (discrete) derivative; wedge is curl; `Σr=0` is source conservation | residual as a signed difference / skew / telescope | **DIRECT** (the algebra); **ANALOGY** (as a smooth ∇F) |
| "Residual lattice runs the field calculus" | the lattice's objects *are* the derivative/split/source | **OURS** (follows from DIRECT; a naming, not a theorem) |
| Derivative/reconstruction/relaxation as *native instructions* (`TGRAD`/`TRECON`/`TRELAX`) | a new ISA abstraction on the ternary substrate | **OURS** (design claim, unmeasured) |
| "A new computation class" | the calculus is 100+ year old GA + finite differences | **SPECULATION → false as stated** |
| Any area/energy/speed win from the native ops | no datapath exists; `TMUL` cost +64.8% is the cautionary precedent | **SPECULATION** |

**The two category errors that would have silently over-claimed it** (both pre-caught):

1. **`L = D − W` ≠ `O − E`** (`computer_science.md`). The graph Laplacian (degree minus
   adjacency) is a *different matrix* from the residual (observed minus independence
   expectation). So "heat's ∇² runs on the lattice" must mean the Laplacian **of the field**, a
   third object — not the residual `O−E` and not the adjacency matrix. Conflating them is the
   exact mistake the survey already corrected.
2. **Smooth vs discrete** (`jacobian-determinant-matrix.md` §Honest calibration). `∇F = J` and
   `∇²` are smooth-manifold operators; the residual is a finite difference. The decomposition
   (det/curl/scale) is a **theorem**; its application to the lattice walk is **ours to test**,
   not a free identity.

**The honest bottom line:** Maxwell and heat are one calculus — the calculus of a single
invertible geometric derivative and its square — and the residual lattice already *is* that
calculus at the derivative/split/source level. "Field calculus" is the *right name* for what the
lattice already computes; it is not a new physics of computation, and whether a native
`TGRAD`/`TRECON`/`TRELAX` instruction set buys anything in silicon is unmeasured and must survive
the same costing every datapath structure in this project has been put through.

---

## TODO / not covered / caveats

1. **The discrete ∇² is undefined.** What is the Laplacian *of the residual field* on the
   Eisenstein lattice — the honeycomb graph Laplacian, the second finite difference, or the
   `ring²` norm? None is formalized; `TRELAX`/`TLAPL` name an object we have not yet specified.
   (`computer_science.md` correction: it must NOT be `L = D−W` and must NOT be `O−E`.)
2. **The discrete ∇⁻¹ is untested, and it has a gauge freedom.** `Σ(O−E) = 0` means the discrete
   derivative has a nullspace (column balancing); the smooth ∇⁻¹ invertibility does not transfer
   automatically. The gauge-invariant object is `δ = r/E` (`ChiSquareGauge.lean`), so "invertible
   reconstruction" on the lattice is reconstruction **up to a gauge** — not yet shown to be the
   clean GA inverse.
3. **Time axis.** Heat is an evolution in `∂/∂t`; the lattice's "time" is the directional edge
   `a→b` (temporal precedence), not a parametrized time. "Relaxation" needs a defined iteration
   parameter, exactly the gap `einstein_calculus.md` §2.1 flagged for "delta as time derivative."
4. **No measured datapath.** `TGRAD`/`TLAPL`/`TRELAX`/`TRECON` have no RTL/area/energy, unlike
   `TMUL` (+64.8%). The instruction list is ISA-level naming, not silicon.
5. **Relax is lossy, reconstruct is lossless — they are opposites.** Do not present the "field
   calculus" as one reversible operation; the two orders point opposite ways on information.
   (The heat semigroup `e^{tα∇²}` is non-invertible for t>0.)
6. **Not formalized in Lean:** nothing here adds a new theorem. Candidate statements for a
   `Hexagon/FieldCalculus.lean`: `laplacian_eq_deriv_sq` (∇² = ∇·∇, i.e. `dot_self`-style), the
   discrete "relax" step `relax u α = u + α·laplacian u`, and the reconstruction-up-to-gauge.
   None is started.
7. **The square-root factor** (`∇ = √∇²`, the Dirac/spinor reading) is cited as classical GA but
   has not been re-derived against our `ω = e^{iπ/3}` embedding (`OmegaEmbedding.lean`); the
   `TSPINOR`/`THODGE` tier remains SPECULATION.
8. **Sources:** the survey corpus for the *heat/diffusion* side (sibling agent b) had not landed
   at the time of writing — this synthesis leans on the GA side (`geometric_algebra.md`) and the
   Jacobian side (`jacobian-determinant-matrix.md`). The heat semigroup / parabolic-theory claims
   are stated from classical material, not from a re-read source; a dedicated heat survey should
   back-fill them.

---

## Sources

**Project-internal (DIRECT / OURS / PROVED):**
- `geometric_algebra.md` — ∇F=J invertible (multivector Green's function); wedge = skew/curl (Hestenes–Sobczyk); spinor `ψ=(α+βI)U`; MDD/torsion disambiguation.
- `jacobian-determinant-matrix.md` — Helmholtz = scalar/bivector decomposition; det/curl/scale split; the smooth-vs-discrete honest calibration.
- `DotWedge.lean` — `gp_decomp`, `wedge_antisymm`, `dot_self`, `wedge_self`, `dot_sq_add_wedge_sq`, `dot_swap` (PROVED).
- `Residual.lean` — `r = O−E`, `sum_E_row`, `sum_residual_eq_zero`, `wedge_antisymm`, `ringSq_nonneg` (PROVED).
- `Registers.lean` — `δ_eq_residual_div`, `surprise_eq_delta_sq_mul_E`, `sym_plus_skew`, `wedge_eq_residual_skew` (PROVED).
- `Conjugate.lean`, `Conventions.lean`, `OmegaEmbedding.lean` — the Eisenstein multiply/norm/conjugate/embedding (PROVED).
- `GA_INSTRUCTIONS.md` — the TDOT/TWEDGE/TGRAD/TSPINOR/THODGE instruction tiering.
- `einstein_calculus.md` — the delta/telescope/second-difference discrete calculus (the field calculus extends it).
- `computer_science.md` — the `L = D−W ≠ O−E` category-error correction.
- `eisen_opcode.md` — the opcode table and the TMUL +64.8% area costing discipline.
- `proofs/INDEX.md` — the claim→file→status ledger.

**External (DIRECT, classical):**
- Hestenes, D. & Sobczyk, G. — *Clifford Algebra to Geometric Calculus* (1984): ∇F=J invertible; the wedge as skew part/curl; the spinor `ψ=(α+βI)U`.
- Lasenby, A. — spinor `ψ = ρ^{1/2}e^{Iβ/2}R` (weighted rotor).
- Classical vector calculus (Helmholtz decomposition; `curl grad = 0`, `div curl = 0`), and the Dirac/Clifford square-root `D² = ∇²` — cited via the surveys above, not re-derived here.
