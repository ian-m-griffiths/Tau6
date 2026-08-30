# GA + Info-Geometry — 2-pass survey + calibrated map to the Tau (Eisenstein) lattice

**Date:** 2026-08-29.
**Scope:** the rebuild's GEOMETRIC-ALGEBRA and INFO-GEOMETRY threads, mapped against
*our* lattice (the balanced-ternary processor on the Eisenstein integer ring ℤ[ω]).
**Method:** 2 passes — **Pass 1 (map)** describes the sources only; **Pass 2 (lens)**
calibrates every claim against our lattice at mapping time (per `AGENTS.md` rule 1), with
**DIRECT / ANALOGY / OURS / SPECULATION** on every line.

**Sources read end-to-end** (not skimmed):
- `/home/ian/opencode/parser/english/docs/source_surveys/geometric_algebra.md` (GA survey)
- `/home/ian/opencode/parser/english/docs/surveys/information-geometry.md` (IG survey)
- `/home/ian/opencode/parser/english/docs/source_surveys/information_geometry.md` (IG source survey — the addenda that resolve α=0)
- `/home/ian/opencode/parser/english/docs/surveys/maximum-entropy.md` (fills the Legendre "missing piece" the IG survey flags)

**Sources skimmed** (folder contents characterized; the equations quoted below come from
the survey write-ups, which are the two-stage subagents' digests — open the PDFs before
importing any single equation):
- `docs/info_geometry/information_geometry/` (6 PDFs: 2310.03884 "Working Information
  Theorist", 2608.12379 Fisher-KPP, 2608.13358 φ-divergences, 2608.13363 KL-extropy, the
  "elementary introduction" tarball, "basics of information geometry")
- `docs/info_geometry/gagc and stuff/` (Macdonald, *A Survey of GA & GC* — the primary GA
  reference the GA survey cross-checks against)

**Calibration legend** (repo-wide, unchanged):
- **DIRECT** = proved in our Lean ledger (`lake build` green, zero `sorry`) or classical/cited theorem.
- **ANALOGY** = structural resemblance, different object.
- **OURS** = our design claim that *follows from* a DIRECT fact but is unmeasured/unbuilt.
- **SPECULATION** = untested hypothesis on both sides.

---

## Pass 1 — MAP (description only; no judgment yet)

### 1.1 `geometric_algebra.md` (the GA survey, 15 files)

The rebuild's GA corpus survey. Four findings:

1. **Spinor `ψ=(α+βI)U`** (Hestenes–Sobczyk Eq. 8.11). The rebuild's "rotor"
   `exp(r_bwd − r_fwd) = O_bwd/O_fwd` is only the **scalar/dilatation factor α** (grade-0,
   inert — it doesn't act). The fix: promote to a genuine **even versor** `U`, so
   `ψ = (α + βI)U` with `β` surviving only when `n = 4m` (and `32 = 4·8`, so β survives in
   principle on the rebuild's 32-dim hypercube). Lasenby's `ψ = ρ^{1/2} e^{Iβ/2} R`
   ("spinor = weighted rotor = scale × rotation instruction") is the same statement.
2. **Wedge = skew not area.** `O_ab − O_ba` is NOT a bivector area. Hestenes–Sobczyk: a
   skew transformation has canonical form `f(x) = x·F` for a *unique bivector F*,
   `a∧f = 2F` ("completely determined by its curl"). RETIRE the V3 "wedge = |a∧b|" mapping;
   the wedge's home is the **skew part / curl**.
3. **`∇F = J` is invertible** (GA Maxwell, one equation). The geometric derivative has a
   multivector Green's function; div and curl don't, separately. Formalizes lossless
   reconstruction: residual = `∇F`, recovery = the directed integral.
4. **Schindler's MDD / torsion** = the rigorous "one derivative" (metric-compatible +
   torsion-free ⟺ contorsion χ=0 = Levi-Civita). Torsion = skew of the *connection*, a
   DIFFERENT skew from the transition-matrix skew (finding 2) — don't conflate.

### 1.2 `information-geometry.md` (the IG survey, 6 papers) + its source-survey addenda

The subject: Riemannian geometry on the space of probability distributions — Fisher
information matrix as metric, divergences (KL, χ²) as "distance", dually-flat manifolds,
the α-connection, natural gradient.

Key results (proving and correcting the earlier over-claimed `parallels.md`):

- **PROVEN:** flux `(O−E)²/E` = per-cell Pearson χ² = 2nd-order Taylor of KL
  (`KL = ½χ² + O(δ³)`, i.e. `χ² ≈ 2·KL` near `p≈q`). The best-verified claim in the whole
  mapping. Caveat: χ² is *one of infinitely many* f-divergences sharing the 2nd-order term.
- **WRONG:** "ring = Fisher information" is **INVERTED**. Fisher is a *matrix*
  `g_ij = E[∂ᵢlog p ∂ⱼlog p]`; for a multinomial `g_ii = T/f(w)` — Fisher ∝ 1/frequency.
  The ring is large for *common* words — backwards. The ring is a **χ² divergence value**
  (`ring² = Σ r²`), not Fisher info. Retire "ring = Fisher information."
- **WRONG:** "natural gradient = multiplicative L1" — mirror-descent/Bregman-shaped, not a
  gradient (`∇̃L = G⁻¹∇L` is a contravariant vector; L1 is a scalar).
- **ANALOGY (open):** "rotor = α=0 (Levi-Civita)". α=0 is self-dual but *curved*
  (`R^α = (1−α²)/σ⁴`, so `R(α=0) = 1/σ⁴ ≠ 0`); plus the rotor is grade-0 so it can't be a
  connection.
- **Dually-flat θ/η structure** = the home for the "two bridges" (Lagrangian global
  `E = f(a)f(b)/T` vs Einsteinian local `E·ρ(a)ρ(b)`); the density dilation `ρ` is a would-be
  **mirror map** (`∇φ`); the missing piece was `ρ` not yet a Legendre transform.

The **source-survey addenda** (`source_surveys/information_geometry.md`) then:

- **Crouzeix identity** `∇²φ·∇²φ* = I` = the concrete verifier for the Legendre missing piece.
- **α=0 contradiction RESOLVED** — dual flatness + Legendre + Crouzeix live at **α=±1**, not
  α=0; α=0 = self-dual Levi-Civita = squared Hellinger, *curved*. Retire "rotor = α=0".
- **Two geometries separate:** α=±1 (flat) = the two bridges; α=0 (curved radius-2 sphere
  `φ(p)=2√p`) = the donut/sphere note.
- **Structural vs sampling zero** refines the anti-lattice.
- **Amari–Chentsov `C_ijk = Γ−Γ* = E[∂ᵢl∂ⱼl∂ₖl]` ≠ our wedge** — totally symmetric 3rd-order
  (skewness) vs our anti-symmetric 2nd-order (circulation).

### 1.3 `maximum-entropy.md` (fills the Legendre gap the IG survey flagged)

- **PROVEN:** flux = χ² = α-divergence (α=3) = Tsallis q=2 = Bregman divergence (generator
  `G(t)=(t^α−t)/(α(α−1))`).
- **CORRECTION:** the edge weight is the **α-layer, one rung below KL** (χ² ≈ 2·KL only to
  2nd order).
- **PROVEN:** Zipf is a maximum-entropy distribution (both Shannon+log-rank and escort routes).
- **PROVEN:** wedge deflation = Bregman projection (quadratic generator).
- **FALSE:** ρ = Bregman projection (it's a *reference reweighting*, the KL-layer axiom).
- **The missing piece, now specified:** the Legendre transform of ρ — the potential
  `φ(r) = Σ_{r'≥r} count_{r'}`, ρ = its discrete gradient, and `(ρ, ∇φ*)` is the mirror map
  linking the two bridges. Computable from stored `.latx` primitives.

---

## Pass 2 — LENS (calibrated against OUR Eisenstein/ternary lattice)

Our lattice is **not** the rebuild's `(Z₂)³²` Boolean hypercube. It is the Eisenstein integer
ring ℤ[ω] (ω = e^{iπ/3}, norm N = a²+ab+b², units Z₆), embedded in ℂ — a *2-dimensional,
base-3-native* geometric algebra, not a 32-dimensional base-2 one. Every mapping below is
calibrated against **that** object, and every "Boolean/XOR/2-adic" identity in the source
assumes base-2 and does **not** transfer verbatim.

---

### Task 1 — the spinor fix `ψ=(α+βI)U` → `Z₆≅Z₂×Z₃` and the ℂ-embedding

**Verdict: the fix is already native to our ring. Our ℤ[ω] *is* the even subalgebra of a
2D Clifford algebra, and `ω = e^{iπ/3}` is itself a spinor.** The pieces of `ψ=(α+βI)U`
map as follows, each DIRECT and proved:

| Spinor factor (Hestenes–Sobczyk Eq. 8.11) | Our object | Calibration | Lean proof |
|---|---|---|---|
| `U` — the even versor (rotation) | the **Z₆ unit group** `{±1, ±ω, ±ω²}` = the six 60° rotations, realized as `TROT` (mod-6 angle add) | **DIRECT** | `Rotation.lean` (`units_card=6`, `units_closed_under_mul`); `Gauge.lean` (`units_eq_omega_powers`, `norm_of_unit`) |
| `α` — the scalar / dilatation factor | the **magnitude / radial scale** `√N(z)` (the norm), not a Z₆ element | **DIRECT** | `Conventions.lean` (`norm`, `norm_mul`); `Conjugate.lean` (`z·z̄ = N(z)`) |
| `βI` — the pseudo-scalar part (survives iff n=4m) | the **imaginary/bivector coefficient** — in 2D the pseudo-scalar is `I` (grade 2), so `βI` degenerates to the `Im` part of `a+bω` | **DIRECT** (with a grade caveat below) | `OmegaEmbedding.lean` (`ω = 1/2 + √3/2 i`, `omegaC_eq`) |
| the whole `ψ = (α+βI)U` (scalar⊕pseudoscalar times a rotation) | the **Eisenstein integer** `z = a+bω`, embedded in ℂ = Cℓ⁺₀,₂ (the even subalgebra) | **DIRECT** | `OmegaEmbedding.lean` (`phi_mul` = the geometric product is the complex/Eisenstein product; `phi_injective`) |

**The geometric product = Eisenstein multiply = the complex product.** `TMUL` (the ω-multiply
`(a+bω)(c+dω) = (ac−bd) + (ad+bc+bd)ω`) is in RTL; `phi_mul` proves the ℂ-embedding carries
it to complex multiplication, which *is* the geometric product `ab = a·b + a∧b`. **DIRECT.**
The dot/wedge/symdot split of that product is proved separately (`Conjugate.lean`,
`DotWedge.lean`, `SymDot.lean` — see Task 1b below).

**The `Z₆ ≅ Z₂ × Z₃` (sign × 3-cycle) structure — this is exactly the spinor's grade/rotation
factorization, proved.** `CrtHex.lean`:

- **`Z₂` (the sign)** = `{1, −1}` — the orientation/reflection factor. This is the `±` in the
  spinor's magnitude α (a *signed* scalar: attract vs repel is the sign of `O−E`).
- **`Z₃` (the 3-cycle)** = `{1, ω, ω²}` — the cubic roots of unity, the 120° rotations
  (the "even-grade" subgroup: `ω²` has order 3).
- **CRT bijection** `Fin 6 ≃ Fin 2 × Fin 3`, `n ↦ (n mod 2, n mod 3)`: the angle index
  decomposes into `sign (mod 2)` × `cycle (mod 3)`, with inverse `(a,b) ↦ 3a+4b (mod 6)`.
  Every unit = `±1 · (cycle element)` (`signCycleMul_surjective`, `signCycleMul_injective`).

So the spinor's "grade structure" — *orientation sign* × *rotation* — is realized in integer
mod-6 arithmetic. **DIRECT** (`CrtHex.lean` all five theorems proved). This is the statement
`GAUGE_VARIANTS.md` §3 already records: "i_ω —is-a-gauge-shift-of→ (rotor group) [DIRECT]
Z₆ ⊂ SO(2): the even-grade fix ψ=(α+βI)U in integer mod-6 arithmetic."

**Two come-to-terms / grade caveats (do not silently transfer):**

1. **The rebuild's β is grade-4 in 32 dimensions; ours is grade-2 in 2 dimensions.** "β
   survives iff n=4m; 32=4·8" is a fact about Cℓ₀,₃₂ (the rebuild's Boolean hypercube). Our
   Eisenstein setting is Cℓ₀,₂⁺ ≅ ℂ, whose top grade is the pseudo-scalar `I` (grade 2). There
   is **no** grade-4 blade for β to live in. What transfers is the *role*: the even subalgebra
   is {scalar α} ⊕ {pseudo-scalar βI} = ℂ, and ℤ[ω] ⊂ ℂ is exactly where our integers live.
   The "spinor = scalar + pseudo-scalar" *form* is DIRECT; the "β is a 4-vector-grade
   coefficient" detail is a rebuild-specific grade bookkeeping that has no 2D analogue.
   **ANALOGY at the grade-number level; DIRECT at the "even subalgebra ≅ ℂ" level.**
2. **`α` in the spinor ≠ `α` in the α-connection.** The Hestenes `ψ=(α+βI)U` uses `α` for the
   scalar coefficient; Amari's α-connection uses `α` for the *divergence-family parameter*
   (χ² = α=3). Same letter, unrelated objects — see Task 3. Do not conflate.

#### Task 1b — the dot/wedge/symdot split (the geometric product's scalar⊕bivector halves)

The source says the wedge is the **skew part**, not bivector area. Our ledger proves the split
on the Eisenstein ring (`z·w̄`, the product with the conjugate):

| GA statement | Our proved theorem | File | Meaning |
|---|---|---|---|
| `ab = a·b + a∧b` (scalar + bivector) | `gp_decomp : z·conj w = ⟨dot, wedge⟩` | `DotWedge.lean` | the geometric product IS the two-coordinate split |
| `a∧b = −b∧a` (curl flips sign) | `wedge_antisymm : wedge z w = −wedge w z` | `DotWedge.lean` | wedge = the skew/curl part |
| `a∧a = 0` (no self-area) | `wedge_self : wedge z z = 0` | `DotWedge.lean` | a single vector spans no bivector |
| `(a·b)² + (a∧b)² = |a|²|b|²` (Lagrange) | `dot_sq_add_wedge_sq : dot²+dot·wedge+wedge² = N(z)N(w)` | `DotWedge.lean` | the energy decomposition, **with the Eisenstein cross-term** |
| conjugate needed for the split | `conj(a,b)=(a+b,−b)`, `z·z̄=N(z)` | `Conjugate.lean` | `ω̄ = ω⁻¹ = 1−ω` |
| the *symmetric* integer correlation | `symdot = N(z+w)−N(z)−N(w) = 2·Re(z·w̄) = 2·dot + wedge` | `SymDot.lean` | polarization of the norm, symmetric by construction |

**The subtle, already-caught point:** the raw `dot = Re(z·w̄) − wedge/2` is **half-integral and
NOT symmetric** (`dot_comm` is FALSE; the true statement is `dot_swap : dot z w = dot w z + wedge w z`).
The clean *integer, symmetric* correlation is the **polarization of the norm** `symdot`
(`SymDot.lean`). This is our lattice's exact instance of the survey's "the wedge is the skew
part" — the symmetric and anti-symmetric parts do **not** live in separate clean coordinates
the way `a·b` and `a∧b` do over ℝ, because the Eisenstein norm has the cross-term `ab`.

**On "wedge = skew not area" (come-to-terms):** `Im(z·w̄)` mathematically *is* the signed
parallelogram area of the 2D complex plane. Our project nonetheless RETIRES the "area" reading
and keeps "skew/curl/circulation", because the object the rebuild calls "wedge"
(`O_ab − O_ba`, a *scalar count difference* on a transition matrix) is an orientation signal,
not a geometric area — and `AGENTS.md` canonical truth says so. The **Eisenstein Pythagorean
identity** `dot² + dot·wedge + wedge² = N(z)N(w)` (with the cross-term `dot·wedge`, because
`N = a²+ab+b²`) is the *correct* 60°-lattice generalization of the familiar
`(a·b)² + (a∧b)² = |a|²|b|²`, and it is **DIRECT and proved**. The rebuild's Euclidean
`dot² + wedge²` is the 90° (Gaussian) special case, not the 60° case.

---

### Task 2 — `∇F = J` invertibility (cross-check + consolidate field_calculus)

**Status: already surveyed in our `docs/compute/field_calculus/`; this section only
consolidates and points at it.** The three docs there (`maxwell.md`, `synthesis.md`,
`heat.md`) already did the two-stage calibration; nothing below is new — it is the
cross-check the task asks for.

**Consolidated verdict (from `field_calculus/maxwell.md` + `synthesis.md`):**

- **`∇F = J` invertible in the continuum** — **DIRECT, cited** (Hestenes 1966; Hestenes–Sobczyk
  1984; Doran–Lasenby 2003). `∇` is the first-order "square root of the wave operator"
  (`∇² = □`), with a multivector Green's function (Cauchy kernel); `div` and `curl` separately
  are non-invertible (each kills the other grade). The four-equation split `∇F = ∇·F + ∇∧F`
  is **DIRECT, cited**.
- **`∇² = Δ`** (heat's operator = Maxwell's derivative squared) — **DIRECT** GA identity; the
  "square-root factorization" `∇ = √∇²` = the Dirac operator is **DIRECT, cited**.
- **The discrete echo in our lattice** — the **telescope + sign-collapse pair**:
  - the full signed residual `r = O−E` is **losslessly invertible** (`O = r + E`;
    `sum_residual_eq_zero` is the discrete FTC) — **DIRECT, proved**;
  - the surprise register `r²/E` is a **provably lossy projection**
    (`surprise_sign_collapse`, `Registers.lean`) — **DIRECT, proved**;
  - "the residual *is* `∇F`" — **ANALOGY** (signed scalar per edge is not a bivector field);
    the sym⊕skew decomposition *is* the dot⊕wedge split — **DIRECT, proved**
    (`sym_plus_skew`, `wedge_eq_residual_skew`, `gp_decomp`).
- **`J` in our setup** — **OURS**: `J(a) = div r(a) = Σ_b O(a,b) − f(a)` (row imbalance /
  "semantic charge"), zero on a column-balanced lattice; `Σ_a div r(a) = 0` is
  `sum_residual_eq_zero`. Not measured, not Lean-proved (though the identity
  `div_residual_eq_row_imbalance` is marked "Lean-provable" in `maxwell.md` §5.2).
- **`TGRAD`/`TLAPL`/`TRELAX`/`TRECON`/`TDIV`/`TCURL`** as native instructions — **SPECULATION**
  (no RTL, no area/energy; `TMUL`'s +64.8% area is the cautionary precedent).

**Consolidation (the single line to carry forward):** `∇F = J`'s invertibility is a **cited
continuum theorem** (DIRECT); its discrete echo is **the telescope + sign-collapse pair**
(DIRECT, proved); the "field calculus" is **not** a new computation class — the residual
lattice already runs on it at the derivative/split/source level, and only the *native
instruction* encoding (`TGRAD` et al.) is OURS/SPECULATION. The one genuinely open gap is
that the discrete `∇²` and discrete `∇⁻¹` are **undefined** (gauge freedom, time axis).

---

### Task 3 — info-geometry (Fisher metric, α-connection): separate axis, or via the rotor?

**Verdict: a *third* axis, adjacent to (but distinct from) our energy and gauge axes; it does
NOT connect via the rotor — the "rotor = α-connection" claim is retired. It connects to our
*register* gauge and to the two-bridges split via the Legendre/mirror map.**

First, the axis bookkeeping (this is where "energy" and "gauge" each have to be disambiguated
before the info-geometry can be placed — `GAUGE_VARIANTS.md` §6 already flags the collisions):

| Axis in our project | What it is | Where info-geometry sits |
|---|---|---|
| **Hardware energy** (transmission vs detection; the receiver floor ~0.08 pJ/trit) | measured silicon (`ENERGY_LAWS.md`) | **No info-geometry analogue** — this is the "proper-frame residue (P@50=1.0)" OURS row; measurement dissipation, not manifold geometry. **DISJOINT.** |
| **Statistical/residual "energy"** `ring² = Σ(O−E)²/E` | the χ² divergence / L2 norm (`Residual.lean`) | **This IS the info-geometry object**: flux = χ² = α-divergence(α=3) = Tsallis q=2 = Bregman. **DIRECT/PROVEN.** |
| **Gauge (a) Z₆ unit rotation** | multiply by a unit, `TROT` | **No info-geometry analogue.** |
| **Gauge (b) register ladder** raw/δ/z/surprise = `E·δ`, `δ`, `√E·δ`, `E·δ²` | the δ-invariant fold (`Registers.lean`) | **The info-geometry home.** The Fisher metric lives in the `[prob]` register (`p(a)p(b) = E/T`); χ² is the surprise register. **Overlaps.** |
| **Gauge (c) signature** `i² ∈ {−1,+1,0,ω}` | which algebra | **No info-geometry analogue.** |

**The Fisher metric is a *different object* from our ring, and it lives one register away.**
The IG survey's decisive correction: Fisher `g_ii = T/f(w)` **∝ 1/frequency** (a matrix over
the simplex), while our `ring²` ∝ frequency (a scalar χ² statistic). They are **not** the same
axis — Fisher is the *metric of the probability manifold*, `ring²` is a *divergence value*.
**DIRECT** (the survey's inversion finding). Consequence for us: if we ever compute the true
Fisher metric from the `.latx` (the survey's actionable-upgrade #1: `G_ab = Σ_c δ_ac δ_bc` from
the stored score `δ = O/E − 1`), it is a **matrix** in the `[prob]` register, a genuinely new
object our ledger does not yet hold.

**The α-connection does NOT connect via the rotor — that claim is retired.** The IG survey
flagged "rotor = α=0 (Levi-Civita)" as internally inconsistent (α=0 is *curved*; the rotor is
grade-0 and inert). The source-survey then **resolved** it: dual flatness + the Legendre
transform + Crouzeix live at **α=±1**, not α=0; α=0 is the *curved* self-dual (radius-2
Hellinger sphere). So:

- **"rotor = α-connection" → RETIRED** (both our GA "rotor" and the α=0 connection are the
  wrong objects).
- **The actual connection is the Legendre/mirror map, at α=±1 (flat).** The dually-flat θ/η
  structure is the formal home of our **two bridges** — the Lagrangian global `E = f(a)f(b)/T`
  (natural/θ coordinates) vs the Einsteinian local `E·ρ(a)ρ(b)` (moment/η coordinates). The
  density dilation `ρ` is the would-be mirror map `∇φ`. **ANALOGY** (promising; `ρ` not yet a
  Legendre transform when the IG survey wrote it).
- **The missing piece is now specified** (`maximum-entropy.md`): the potential
  `φ(r) = Σ_{r'≥r} count_{r'}` (ρ is its discrete gradient), its Fenchel conjugate `φ*`, and
  `(ρ, ∇φ*)` is the mirror map. The **Crouzeix identity `∇²φ·∇²φ* = I`** is the one-matrix
  verifier. **Computable, not yet computed** — the single highest-value next step in the whole
  info-geometry thread.

**Two name-collisions to keep straight (come-to-terms, before any claim):**

1. **`α`-connection (Amari) ≠ `α` in `ψ=(α+βI)U` (Hestenes).** The connection's α is the
   divergence-family parameter (χ² = α=3, KL = α=±1, Hellinger = α=0); the spinor's α is the
   scalar coefficient. They are unrelated; the IG survey's "rotor = α=0" was confusing them.
2. **"Energy" is overloaded.** Hardware energy (receiver floor) and residual "energy"
   (ring² = χ²) are different objects; only the latter touches info-geometry. Do not read
   "the Fisher metric connects to our energy" — it connects to the *surprise/register* gauge,
   not to the pJ/bit floor.

**Bottom line for Task 3:** the info-geometry is a **separate axis from the hardware energy**
(no contact), an **overlap with the register/statistical gauge** (χ² = the surprise register,
DIRECT; Fisher = the `[prob]`-register metric, a new matrix), and it connects to the
**two-bridges split via the Legendre/mirror map (α=±1), not via the rotor** — the rotor
connection is retired. The rotor's own (correct) home is Task 1 (the GA spinor = our Z₆/ℂ
structure), which is a *different* thread from the info-geometry one.

---

## Consolidated calibration table (everything in one place)

| Source claim | Verdict for OUR lattice | Proof / doc |
|---|---|---|
| geometric product `ab = a·b + a∧b` = Eisenstein multiply | **DIRECT** (`TMUL`; `phi_mul`) | `Conventions.lean`, `OmegaEmbedding.lean` |
| spinor `ψ=(α+βI)U` = even-grade rotor fix | **DIRECT** (our ℤ[ω] = the even subalgebra Cℓ⁺₀,₂ ≅ ℂ; ω = e^{iπ/3} is a spinor) | `OmegaEmbedding.lean`, `Rotation.lean`, `Gauge.lean` |
| `U` (rotor) = the Z₆ unit group | **DIRECT** (`TROT`, mod-6) | `Rotation.lean` (`units_card`, `units_closed_under_mul`) |
| `Z₆ ≅ Z₂ × Z₃` (sign × 3-cycle) = the spinor's grade/rotation factorization | **DIRECT** | `CrtHex.lean` (all 5 theorems) |
| `α` (scalar/dilatation) = the norm `√N(z)` | **DIRECT** | `Conventions.lean`, `Conjugate.lean` (`z·z̄ = N(z)`) |
| `βI` (pseudo-scalar, survives iff n=4m) | **ANALOGY at grade-number** (ours is grade-2, not grade-4); **DIRECT at "even subalgebra ≅ ℂ"** | `OmegaEmbedding.lean` (`ω = 1/2 + √3/2 i`) |
| dot/wedge/symdot split of the geometric product | **DIRECT** (`gp_decomp`, `wedge_antisymm`, `wedge_self`, `dot_sq_add_wedge_sq`, `symdot`) | `Conjugate.lean`, `DotWedge.lean`, `SymDot.lean` |
| wedge = skew not bivector area | **DIRECT** (retired "area"; wedge = curl/circulation) | `DotWedge.lean`, `Residual.lean` (`wedge_antisymm`), `AGENTS.md` |
| `(a·b)² + (a∧b)² = |a|²|b|²` | **DIRECT, with the Eisenstein cross-term** `dot²+dot·wedge+wedge² = N(z)N(w)` | `DotWedge.lean` |
| `∇F = J` invertible (continuum) | **DIRECT, cited** | `field_calculus/maxwell.md` |
| residual = `∇F`, recovery = directed integral | **ANALOGY** (scalar-per-edge ≠ bivector field); sym⊕skew split **DIRECT** | `field_calculus/maxwell.md` §2 |
| `∇² = Δ`, `∇ = √∇²` (Dirac) | **DIRECT, cited** | `field_calculus/synthesis.md` |
| discrete echo = telescope + sign-collapse | **DIRECT, proved** (`O = r + E`; `sum_residual_eq_zero`; `surprise_sign_collapse`) | `Residual.lean`, `Registers.lean` |
| `TGRAD`/`TLAPL`/`TRELAX`/`TRECON` native instructions | **SPECULATION** (uncosted) | `GA_INSTRUCTIONS.md`, `field_calculus/*` |
| flux `(O−E)²/E` = χ² = 2nd-order Taylor of KL | **DIRECT/PROVEN** | IG survey; `Residual.lean` (`ringSq`) |
| "ring = Fisher information" | **WRONG, INVERTED** (Fisher ∝ 1/freq, matrix; ring = χ² scalar) | IG survey |
| "natural gradient = L1" | **WRONG** (mirror-descent/Bregman-shaped) | IG survey |
| "rotor = α=0 Levi-Civita connection" | **RETIRED** (α=0 curved; rotor grade-0 inert) | IG survey + source survey |
| dual flatness at α=±1 = the two bridges (Lagrangian/Einsteinian) | **ANALOGY** (promising); ρ = mirror map | IG survey + max-ent survey |
| ρ's Legendre transform `φ(r) = Σ_{r'≥r} count_{r'}` | **SPECIFIED, not computed** | max-ent survey |
| Crouzeix `∇²φ·∇²φ* = I` as the Legendre verifier | **DIRECT (cited); not run** | IG source survey |
| `C_ijk = Γ−Γ*` (Amari–Chentsov) ≠ our wedge | **DIRECT (different: symmetric 3rd vs antisymmetric 2nd)** | IG source survey |
| hardware energy (receiver floor) ↔ info-geometry | **DISJOINT** (no analogue) | `ENERGY_LAWS.md` |
| Fisher metric = the `[prob]`-register metric (a matrix) | **ANALOGY→OURS** (new object, not yet computed) | IG survey actionable #1 |

---

## TODO / not covered / caveats

- **PDFs skimmed, not read.** The six `information_geometry/` PDFs and Macdonald's GA&GC were
  characterized via the survey write-ups (the two-stage subagents' digests), which themselves
  flag their own over-claims. Before importing any single *equation* (Crouzeix, `R^α=(1−α²)/σ⁴`,
  `ψ=(α+βI)U`), open the PDF — the surveys do not pin page/equation numbers.
- **Base-2 → base-3 does not transfer verbatim.** Every "Boolean hypercube / XOR / 2-adic /
  n=4m" identity in the GA survey assumes the rebuild's `(Z₂)³²`; our Eisenstein setting is
  2D and base-3-native. The spinor *form* transfers (DIRECT); the grade-number bookkeeping
  (`β` at grade-4) does not (ANALOGY). Re-check each "DIRECT" from the rebuild against a
  3-state lattice, per `REBUILD_SURVEY.md` §5's caveat.
- **The β-grade caveat (Task 1) is stated but not fully closed.** Whether the rebuild's
  grade-4 pseudo-scalar has *any* ternary analogue (e.g. a quaternion/trivector layer — the
  "trivector = quaternion" note in the gauge-unification survey) is open. Our `THODGE`/`TSPINOR`
  tier in `GA_INSTRUCTIONS.md` is explicitly SPECULATION, and the square-root factor
  `∇ = √∇²` has not been re-derived against `ω = e^{iπ/3}` (`OmegaEmbedding.lean`).
- **The Fisher metric is not computed.** The IG survey's #1 upgrade — compute the true
  `G_ab = Σ_c δ_ac δ_bc` (or the multinomial diagonal `g_ii = T/f(w)`) from the `.latx`, and
  test whether `ring²` anti-correlates with `T/f(w)` — is a one-afternoon falsification test
  for "ring = Fisher info" that we have **not** run. It would *upgrade* the "WRONG, INVERTED"
  verdict from a cited argument to a measured one.
- **The Legendre transform of ρ is specified but not computed.** The potential
  `φ(r) = Σ_{r'≥r} count_{r'}` + its Fenchel conjugate + the Crouzeix verifier are concrete
  and computable from stored `.latx` primitives, but no script exists yet. Until it is run,
  "the two bridges = the dually-flat θ/η pair" stays **ANALOGY**, not DIRECT.
- **The discrete `∇²` and `∇⁻¹` remain undefined** (the field_calculus gap): no `TGRAD`
  inverse, no discrete Laplacian *of the residual field*, gauge freedom unhandled, no time
  axis. The "field calculus" is the abstraction the lattice *already runs on*, but only at the
  derivative/split/source level; reconstruction and relaxation as instructions are
  SPECULATION until costed (TMUL +64.8% area is the precedent).
- **`J` (row imbalance = semantic charge) is OURS and unmeasured.** No experiment checks
  whether a column-balanced production `.latx` has `div r = 0` pointwise (the N17 directional
  signed rebuild is still the release gate).
- **Not covered:** the `gauge theory/` sub-surveys (`geometric_algebra.md` = Lasenby rotor =
  gauge transformation) beyond what `GA_INSTRUCTIONS.md` already imports; the operator-algebras
  Clifford = C*-algebra thread; and the torsion/MDD disambiguation (finding 4 of the GA survey)
  — which is a *different* skew from the transition-matrix wedge and is left untouched here.
- **Name collisions remain the top risk** (per `GAUGE_VARIANTS.md` §6): "α" (connection
  parameter vs spinor scalar), "energy" (hardware vs residual), "gauge" (Z₆ rotation vs
  register ladder vs signature), "wedge" (skew residual vs Clifford blade vs retired area).
  Every sentence here that uses one of these has pinned its meaning; do not carry the mapping
  forward without re-pinning.
