# Operator-Algebras + Category-Theory — the 2-pass survey, calibrated to the ternary lattice

**Date:** 2026-08-29.
**Sources (read end-to-end):**
- `/home/ian/opencode/parser/english/docs/surveys/operator-algebras.md` (21 papers, C*/von Neumann).
- `/home/ian/opencode/parser/english/docs/surveys/category-theory.md` (57 papers, 11 conceptual).
**Method:** the two-pass deep-dive — Pass 1 (MAP) reads each doc end-to-end and extracts its
*own* claims and self-verdicts; Pass 2 (LENS) re-checks each claim against **our** framework and
calibrates at mapping time. This is the focused per-doc expansion of `MAP.md` §2.5/§2.6, and it
corrects two of `MAP.md`'s over-smooth "DIRECT" rows (see §3.2 and §4.2).

**Calibration convention** (identical to `MAP.md`; re-anchored to the ternary lattice, not the
rebuild's `(Z₂)³²` Boolean hypercube):

| Label | Meaning here |
|---|---|
| **DIRECT** | equation-level identity; holds for a 3-state / hex lattice too (radix-agnostic) |
| **ANALOGY** | same *shape*, different object — usually base-2-specific, or the categorical shell without the concrete instantiation |
| **OURS** | we derived / implemented / proved it independently — already in `proofs/` or the RTL |
| **SPECULATION** | unproven on both sides |

---

## 1. Pass 1 — MAP (what the two docs actually claim)

### 1.1 `operator-algebras.md`

The subject: C*-algebras and von Neumann algebras — "the algebra of the thing between variables
and constants." Operators generalize scalars (self-adjoint = generalized real) and vectors
(projections = hypercube vertices); the C*-identity `‖a*a‖ = ‖a‖²` makes norm = spectral radius,
so metric = algebra.

Its seven claims, with its **own** verdicts:

| # | Claim | Its own verdict |
|---|---|---|
| O1 | rotor sandwich `x→RxR⁻¹` = inner *-automorphism `Ad(u)(x)=uxu*` | PROVEN formula; **over-claim as content** — rebuild's `R=exp(r_bwd−r_fwd)` is grade-0 scalar ⇒ `Ad(R)` = identity (scalar commutes with everything) |
| O2 | Clifford algebra = C*-algebra (`ℂℓₙ ≅` matrix algebras, Bott); "ring = the C*-norm" | PROVEN (Bott); **ANALOGY** (C*-norm = operator norm on observables; ring = Hilbert-space norm on a state; meet only via GNS) |
| O3 | dual numbers `ℂ[ε]/(ε²)` = a *-algebra NOT a C*-algebra (nilpotent, no C*-norm) | PROVEN; "one branch" → **two layers**: semisimple base + nilpotent tangent (a ringed space) |
| O4 | Hodge dual ≠ modular conjugation; Tomita `J` is anti-linear, maps to the **commutant** `M'` | ANALOGY, likely wrong (commutant is the match for the anti-lattice, not the Hodge star) |
| O5 | Bogoliubov inequality `E_ρ[U] ≤ ΔF ≤ E_{ρ₀}[U]` = "physics = information" as a *theorem* | PROVEN formula in the papers; **we lack β, dynamics, and the bound** (we compute a gradient, not an inequality) |
| O6 | Boolean hypercube = **both** `ℂ^{2³²}` (commutative) and `Cℓ₀,₃₂ ≅ M_{2¹⁶}(ℝ)` (noncommutative) | PROVEN; `ℂ^{2³²}` = the **Cartan subalgebra inside Cℓ₀,₃₂**; the conditional expectation onto it = decoherence |
| O7 | Takesaki's theorem: state-preserving conditional expectation ⟺ modular flow leaves the subalgebra invariant | STRONG ANALOGY (makes "the frame must come from outside" checkable) |

### 1.2 `category-theory.md`

The subject: categories (objects + morphisms + composition), monoidal/tensor structure,
directed categories, direction functors, the Rosetta Stone, linear logic, dilatations.

Its claims and verdicts:

| # | Claim | Its own verdict |
|---|---|---|
| K1 | the **wedge = the value of a "direction functor"** (2608.07380): direction = affine/Chasles quotient = the directed difference; built from a reflexive+transitive **but not symmetric** relation = the **monoid** (non-group) case | PROVEN (structural) — "verbatim the wedge `O_ab−O_ba`: keep the sign, drop symmetry" |
| K2 | the **geometric product = the mixor of a linearly distributive category** (2608.13012): two monoidal products — symmetric smash `∧` and non-symmetric substitution `◦` — linked by the mixor; scalar `a·b` ↔ `∧`, bivector `a∧b` ↔ `◦`, geometric product ↔ mixor | PROVEN (2608.13012) |
| K3 | the residual edge = the **internal hom of a Lawvere metric space** (2608.01915): enriched over the quantale `[0,∞]`, `Hom(a,b)` = surprise edge, composition = triangle inequality, converse-failure = the wedge | PROVEN (as structure) |
| K4 | register/gauge shift = a **lossy adjunction** (2608.12030 levels of inference: isomorphism → strong adj → weak adj → nothing) | PROVEN-as-organization |
| K5 | RETIRE: "geometric product = composition" (it is *monoidal*, not categorical) | FALSE as claimed |
| K6 | RETIRE: "one-branch collapse = the Rosetta Stone" (downloaded paper is the *Other Minds* Rosetta Stone, not Baez–Stay) | mis-labeled |
| K7 | RETIRE: "the lattice IS a category" (it is a **Lawvere metric space**; no composition on composable pairs, no identities) | ANALOGY |
| K8 | Yoneda: an object is determined up to iso by the totality of its relations; a word's meaning = its neighborhood | the "single most important sentence" |

---

## 2. The lens (our side, one block) — what "calibrate against OUR lattice" means here

The four anchors the task names, plus the two directly-adjacent facts they need:

- **Geometric product = Eisenstein multiply `TMUL`** — `(a+bω)(c+dω) = (ac−bd) + (ad+bc+bd)ω`,
  `ω²=ω−1`. Lean `Conventions.lean` (`mul_comm` T0, `norm_mul` T1); RTL `rtl/cpu.v` opcode `5`
  (`TMUL`, `w²=w−1`), proven bit-identical (SAT) and instruction-identical (iverilog) in
  `docs/compute/eisen_opcode.md`.
- **Wedge = skew `DotWedge.lean`** — `wedge z w = (z·conj w).b` (the ω-coefficient);
  `wedge_antisymm` (`wedge z w = −wedge w z`), `gp_decomp` (`z·conj w = ⟨dot, wedge⟩`),
  `dot_swap` (`dot z w = dot w z + wedge w z`). Plus the correction `SymDot.lean`: the *true*
  symmetric scalar is `symdot = N(z+w)−N(z)−N(w) = 2·dot + wedge` (the naive `Re(z·w̄)` is
  half-integral — `dot_comm` is **FALSE**).
- **`Z₆ ≅ Z₂×Z₃` `CrtHex.lean`** — the six units ±1, ±ω, ±ω² = a sign (±1) × a 3-cycle (1,ω,ω²);
  `signCycleMul` bijective; angle index `Fin 6 ≃ Fin 2 × Fin 3` via `(n mod 2, n mod 3)`.
- **ℂ-embedding `OmegaEmbedding.lean`** — `ω ↦ e^{iπ/3}` is an injective ring homomorphism
  `φ : ℤ[ω] → ℂ` (`phi_add`, `phi_mul`, `phi_injective`); `ω = cos(π/3) + I·sin(π/3)`.
- **`Conjugate.lean`** (TCONJ) — `conj(a,b) = (a+b,−b)`, an involution + ring automorphism, and
  `z·z̄ = N(z)` (`mul_conj_eq_norm`). This is the **\*-structure** that makes `ℤ[ω]` a
  *\*-algebra*: the conjugation is the involution, `N(z)` is the squared C*-norm.
- **`Rotation.lean` + `Gauge.lean` + `HexIsotropy.lean`** — the six units form `Z₆`
  (`units_card`, `units_closed_under_mul`); isotropy `N(u·x)=N(x)`, `N(u)=1`,
  `units_eq_omega_powers`; each hex cell has exactly 6 distinct unit neighbors (free Z₆ action).

**The one fact that reframes everything below:** `ℤ[ω]` is **commutative** (`mul_comm` is a
proved theorem). The ℂ-embedding lands the lattice in the **even subalgebra** `Cℓ⁺₂ ≅ ℂ`
(scalar + bivector, commutative), *not* in the full (noncommutative) `Cℓ₂`. Every "inner
automorphism" claim below must be read against that commutativity.

---

## 3. Pass 2 — LENS (the five mappings, calibrated)

### 3.1 Clifford algebra = C*-algebra → **DIRECT (algebra), and tighter than the rebuild's**

The rebuild proves `ℂℓₙ ≅` matrix algebras (Bott) and flags "ring = C*-norm" as an ANALOGY
(a Hilbert-space norm on a state vector vs an operator norm on observables). For us the claim
tightens from ANALOGY to **DIRECT**, because our object is 2-dimensional:

- `ℤ[ω]` is a commutative **\*-ring**: involution = `conj` (`Conjugate.lean`), norm
  `N(z) = z·z̄` (`mul_conj_eq_norm`), multiplicative (`norm_mul`).
- `OmegaEmbedding.lean` embeds it into `ℂ = M₁(ℂ)` — the **trivial 1×1 matrix algebra = the
  simplest C*-algebra**. In `M₁(ℂ)` the operator norm, the spectral radius, and the absolute
  value **coincide**, so `‖z‖ = √N(z) = |φ(z)|` **is** the C*-norm, and the C*-identity
  `‖z*z‖ = ‖z‖²` holds (`‖z*z‖ = √N(z·z̄) = √(N(z)N(z̄)) = N(z) = ‖z‖²`).
- The **"ring = C*-norm" ambiguity the rebuild flagged (state-norm vs operator-norm) collapses in
  2D**, because `ℂ` is simultaneously the state space and the observable algebra. The rebuild's
  *statistical* "ring = χ² divergence" remains a **different object** (ANALOGY, ours-not-yours):
  our `N(z) = a²+ab+b²` is an *algebraic* norm, not the χ² residual.

**Net:** `DIRECT` — `ℤ[ω] ⊂ ℂ = M₁(ℂ)` is a concrete C*-subalgebra; `Conjugate.lean` +
`OmegaEmbedding.lean` + `norm_mul` already give the *\*-algebra with its C*-norm. What is **not**
yet stated as a Lean theorem: the literal C*-identity `‖z*z‖ = ‖z‖²` (trivial but unstated) and
the `CStarSubalgebra`/norm-closure instance (needs the completion `ℂ`, which we have via `phi`).

### 3.2 Rotor = inner \*-automorphism → **the formula is DIRECT; the *act* is relocated — our rotor acts, but not as an inner automorphism**

This is the deepest calibration and it **corrects `MAP.md` O1**, which too quickly recorded
"rotor sandwich = inner \*-automorphism — DIRECT, radix-agnostic." It is not that simple:

- **The rebuild's bug (O1):** `R = exp(r_bwd−r_fwd)` is a grade-0 **scalar**, so `Ad(R)(x)=RxR⁻¹=x`
  — inert, because a scalar commutes with everything.
- **Our situation is different, and better, but for a subtle reason.** Our rotor is the unit
  `ω^k ∈ Z₆`. It is genuinely **even-grade** — ω, ω², −ω, −ω² have a nonzero b-coordinate (a
  nonzero bivector part); only ±1 are scalars. So we are **not** in the grade-0 bug: the rotor
  is a genuine bivector-generator, and it **acts** (TROT, `Rotation.lean`, `Gauge.lean`
  `norm_unit_mul`).
- **But the sandwich `x ↦ uxu⁻¹` is trivial on our lattice**, because `ℤ[ω]` is **commutative**
  (`mul_comm`): `uxu⁻¹ = uu⁻¹x = x` for every unit `u`. So "rotor = inner \*-automorphism" does
  **not** literally hold on the even subalgebra where our lattice lives.
- **Where the inner automorphism is non-trivial:** the **full** Clifford algebra `Cℓ₂`
  (grade-1 vectors + bivectors, noncommutative). There `u ∈ Cℓ⁺₂ ≅ ℂ` (a rotor) conjugates a
  grade-1 vector `v ↦ uvu⁻¹` by a genuine rotation. Our Lean/RTL lattice is built on `ℤ[ω]`
  (the even subalgebra), **not** on the full `Cℓ₂` — so that non-trivial conjugation is **not
  in the current proof surface**.
- **The precise re-statement:** our rotation is **left multiplication** by a unit
  (`TROT: rd = ω^k·ra`), i.e. the **regular action of Z₆ on the lattice as a ℤ-module** — an
  *outer*/module automorphism, not an *inner* conjugation. In the 2D even subalgebra, "rotation"
  and "inner automorphism" decouple: the former is a genuine one-sided action we have; the latter
  needs the noncommutative full `Cℓ₂` we do not (yet) build.

**Net:** `DIRECT` (the even-grade rotor and its action are real and proved); **relocated** (the
"inner automorphism" reading is trivial on the commutative even subalgebra and lives in the
unbuilt full `Cℓ₂`). See §4.2 for the full answer to the task's Q2.

### 3.3 Boolean hypercube = `ℂ^{2³²}` inside `Cℓ₀,₃₂` → **ANALOGY (base-2); our Cartan story is degenerate in 2D**

- The rebuild's sharp statement is **base-2 by construction**: the `2³²`-dimensional complex
  space and the `Cℓ₀,₃₂ ≅ M_{2¹⁶}(ℝ)` envelope exist only for the 32-qubit Boolean hypercube.
- Our lattice is 2-dimensional and lands in `Cℓ⁺₂ ≅ ℂ` — which is **already commutative**. So
  the "commutative Cartan diagonal inside a noncommutative Clifford algebra" split has **no room
  in 2D**: the "Cartan" would be the whole even subalgebra, and the noncommutative envelope is
  the full `Cℓ₂` (≅ `M₂(ℝ)` for signature (2,0), or ≅ `ℍ` for signature (0,2) — the even
  subalgebra is `ℂ` either way).
- The honest ternary analogue is therefore **not** `ℂ^{2³²} ⊂ Cℓ₀,₃₂` but
  **`ℤ[ω] ⊂ Cℓ⁺₂ ≅ ℂ ⊂ Cℓ₂`** — a two-step inclusion whose "decoherence/conditional-expectation"
  content is much weaker than the rebuild's (there is no `2³²`-fold Cartan diagonal; the
  classical/quantum split is a 2D degenerate case).

**Net:** `ANALOGY` — the *shape* (a commutative subalgebra recovered as a conditional
expectation's image) transfers, but the *object* (`ℂ^{2³²}`, 32 qubits) is base-2 and has no
direct ternary twin. `MAP.md` §5's "Cartan inclusion `ℂ ⊂ Cℓ₀,₂`" is the right *idea* but should
be labeled the **degenerate 2D analogue**, not a direct port.

### 3.4 Wedge = a "direction functor" → **DIRECT structure, and it generalizes to ternary (not base-2)** — see §4.1

The categorical content (direction = the non-symmetric monoid, "keep the sign, drop symmetry")
is **radix-agnostic**. The *value* of the direction upgrades from the rebuild's signed integer
(`O_ab−O_ba`, a Z₂ sign) to our Z₆ angle. `CrtHex.lean` is exactly the theorem that decomposes
the ternary direction into the inherited base-2 sign (Z₂) × the new ternary 3-cycle (Z₃). Full
answer in §4.1.

### 3.5 Geometric product = the mixor of a linearly distributive category → **DIRECT at the algebra level (proved); ANALOGY at the categorical level (unbuilt), with one structural caveat**

- **DIRECT (proved):** the geometric product splits into a symmetric scalar + a skew bivector,
  in one product. `DotWedge.lean` `gp_decomp` (`z·conj w = ⟨dot, wedge⟩`), the Pythagorean
  identity `dot² + dot·wedge + wedge² = N(z)N(w)` (`dot_sq_add_wedge_sq`), and the *corrected*
  symmetric part `symdot = 2·dot + wedge` (`SymDot.lean`). This is the "scalar ↔ ∧, bivector ↔ ◦"
  two-component split, realized by the single `TMUL`.
- **ANALOGY (unbuilt):** the *categorical* "mixor of a linearly distributive category" (an
  isomix structure over Γ-sets, 2608.13012) is **not** formalized for `ℤ[ω]`. We have the two
  operations (the symmetric `symdot`, the skew `wedge`) but no category of `ℤ[ω]`-modules with a
  proven distributivity/mixor natural transformation.
- **Structural caveat (corrects `MAP.md` K2's flat "DIRECT"):** a linearly distributive category
  needs **two monoidal** (associative, unital, algebra-valued) products. We have **one**: the
  geometric product itself (`TMUL`, the associative-unital-commutative ring product,
  `mul_comm`/`norm_mul`). The "scalar ↔ `∧` / bivector ↔ `◦`" split is **not** two monoidal
  products — `dot`/`symdot` and `wedge` are the two *coordinate projections* of that one product,
  and both return a scalar (`ℤ`), not a lattice element, so neither is an algebra multiplication:
  `symdot z w = N(z+w)−N(z)−N(w)` is the symmetric **bilinear form** (the norm's polarization),
  and `wedge z w = (z·conj w).b` is the anti-symmetric **bilinear form** (a 2-form / the curl
  functional; `wedge_antisymm`, `wedge z z = 0`). The "bivector ↔ non-symmetric monoidal product
  `◦`" leg is therefore shaky even in the rebuild's own mapping: an anti-symmetric bilinear form
  is not a monoidal product. The clean, *proved* statement is "the geometric product decomposes
  into a symmetric and a skew component in one product" (`gp_decomp`, `dot_swap`,
  `symdot_eq_two_dot_add_wedge`); the "mixor of a linearly distributive category" (a *two*-product
  structure) is an **ANALOGY** that does not literally instantiate on `ℤ[ω]` without additional
  unbuilt structure.

---

## 4. The three questions, answered

### 4.1 Does "the wedge = a direction functor" generalize to the ternary lattice (Z₆ directions), or is it base-2?

**It generalizes — it is not base-2. The base-2 wedge is the Z₂ sub-factor of our Z₆ wedge.**

- The *functor* (2608.07380/2608.09428) is **base-free**: direction = the affine/Chasles
  quotient = the directed difference, built from a relation that is reflexive + transitive but
  **not** symmetric. That is a property of *any* directed structure, three-state or two-state.
- The *value* of the direction is what changes. In the rebuild the wedge `O_ab−O_ba ∈ ℤ` carries
  its direction as a **sign** (the 2-valued orientation; the survey's own "keep the sign, drop
  symmetry"). That is base-2.
- In our lattice the wedge `wedge z w = (z·conj w).b` (`DotWedge.lean`) is the ω-coefficient of
  the geometric product, and the direction between two lattice points is the **angle** — which
  of the six units `ω^k ∈ Z₆` relates them. The direction is **Z₆-valued (6 directions)**, the
  hex lattice's native orientability (`HexIsotropy.lean`: every cell has exactly 6 distinct unit
  neighbors).
- **`CrtHex.lean` is precisely the generalization theorem:** `Z₆ ≅ Z₂×Z₃`. The `Z₂` factor is
  the **sign** = the rebuild's base-2 direction (inherited verbatim — "keep the sign, drop
  symmetry" survives as the `n mod 2` coordinate); the `Z₃` factor (the 3-cycle `1, ω, ω²`) is
  the **ternary-new** content the binary wedge cannot see (`n mod 3`). The direction functor's
  monoid/group distinction — the survey's "reversal null = symmetric/group vs non-symmetric/monoid"
  — becomes, on our side, the distinction "wedge = 0 (collinear, symmetric) vs wedge ≠ 0 (one of
  6 orientations)."

**Net:** `DIRECT` (the functor structure transfers) **+ OURS** (the Z₃ cycle is a genuinely
ternary direction content; `CrtHex.lean`, `Rotation.lean`, `HexIsotropy.lean` are its Lean
proofs). The only base-2 residue is the rebuild's *instantiation* (a ±1 sign); our instantiation
is the Z₆ angle, and CRT shows the ±1 sign is exactly its `Z₂` factor.

### 4.2 Is "rotor = inner automorphism" fixed by our even-grade spinor `ψ=(α+βI)U`?

**Half fixed, and the fix relocates the claim.** (Full detail in §3.2.)

- **The even-grade fix is realized (DIRECT).** The rebuild's rotor was a grade-0 scalar and did
  not act. Our rotor is the unit `ω^k`, a genuine even-grade element: via
  `OmegaEmbedding.lean`, `ω = e^{iπ/3} = cos(π/3) + I·sin(π/3)`, so every Eisenstein integer
  `a+bω` **is** the spinor `ψ = α + βI` (α = a + b/2, β = b√3/2), and its polar part
  `ψ = ρ·ω^k` is `ψ = (α+βI)U` with `U = ω^k` the even versor (rotor) and `α+βI` the
  scalar+bivector factor. The grade structure is `Z₆ ≅ Z₂×Z₃` (`CrtHex.lean`). So we are **not**
  in the grade-0 bug: the rotor genuinely rotates (`TROT`, `Rotation.lean`, `Gauge.lean`).
- **But it is not an *inner* automorphism (relocated).** `ℤ[ω]` is commutative (`mul_comm`), so
  the sandwich `x ↦ uxu⁻¹ = x` is the identity for every unit — the "inner automorphism" is
  trivial on the even subalgebra where the lattice lives. Our rotation is **left multiplication**
  (`TROT`), the regular/outer action of `Z₆` on the lattice, not a conjugation.
- **The genuinely non-trivial inner automorphism lives in the full `Cℓ₂`** (noncommutative,
  grade-1 vectors + bivectors), which we have **not** built: `OmegaEmbedding.lean` only realizes
  the commutative even subalgebra `≅ ℂ`. So "rotor = inner \*-automorphism" is **true in Cℓ₂**,
  **trivial in our current lattice**, and realizing the non-trivial version is a build of the
  full Clifford algebra — a TODO, not a done fact.
- **Caveat — the Spin double-cover.** In full `Cℓ₂` a vector rotation by angle θ uses the
  **half-angle** rotor `R = e^{Iθ/2}`. Our Z₆ units, used one-sided, rotate a lattice point
  (even element) by `60°·k`; used two-sided as vector rotators they would rotate by `120°·k`.
  The *Spin* double-cover for 60° vector rotations is `Z₁₂` (12th roots of unity), which is
  **not** in `ℤ[ω]`. So our `Z₆` is the **rotation-operator group**, not the Spin cover — the
  half-angle convention needs a `√ω` that the lattice does not contain. Flag, don't paper over.

**Net:** the *spinor* `ψ=(α+βI)U` **is** realized by our lattice (DIRECT, `OmegaEmbedding.lean` +
`CrtHex.lean`), and our rotor **does** act (fixing the rebuild's inert-rotor bug); but "rotor =
**inner** automorphism" must be downgraded to "rotor = a genuine even-grade rotation realized by
left multiplication," with the inner-automorphism reading relocated to an unbuilt full `Cℓ₂`.

### 4.3 What Lean-provable structure do we already have?

Already **proved** (zero `sorry`, `lake build` green per `proofs/INDEX.md`) and directly
relevant to the Clifford/C*-algebra + direction-functor structure:

| Structure | File(s) | Theorems |
|---|---|---|
| The \*-ring (Clifford/C*-algebra base) | `Conventions.lean` | `mul_comm` (T0), `norm_mul` (T1) |
| The \*-involution + C*-norm seed | `Conjugate.lean` | `conj_involutive`, `conj_mul`, `conj_norm`, `mul_conj_eq_norm` |
| The ℂ-embedding (→ `M₁(ℂ)`, the C*-envelope) | `OmegaEmbedding.lean` | `omega_sq_rel`, `phi_add`, `phi_mul`, `phi_omega`, `phi_injective` |
| The geometric product = scalar + bivector split | `DotWedge.lean`, `SymDot.lean` | `gp_decomp`, `wedge_antisymm`, `dot_self`, `wedge_self`, `dot_sq_add_wedge_sq`, `dot_swap`, `symdot_comm`, `symdot_self`, `symdot_eq_two_dot_add_wedge`, `symdot_nonneg` |
| The Z₆ rotor group (the even-grade versor) | `Rotation.lean`, `Gauge.lean` | `units_card`, `units_closed_under_mul`, `norm_of_unit`, `norm_mul_unit`, `norm_unit_mul`, `units_eq_omega_powers`, `norm_eq_det` |
| The spinor's grade structure Z₆ ≅ Z₂×Z₃ | `CrtHex.lean` | `signCycleMul_surjective/_injective`, `signCycle_card`, `mod6_iff_mod2_mod3`, `modPair_bijective` |
| The direction (6 unit neighbors, free Z₆) | `HexIsotropy.lean`, `Rotation.lean` | `translate_injective`, `neighbors_card`, `no_fixed_point`, `units_rotate_invariant`, `isNeighbor`, `hexDist_*` |
| The wedge-as-skew (the direction's "keep the sign") | `Residual.lean` | `wedge_antisymm`, `sum_residual_eq_zero`, `sum_E_row`, `ringSq_nonneg` |
| The dual-number (nilpotent second layer) | `Signature.lean` | `dual_nilpotent`, `dualUnits_card`, `split_zero_divisor`, `signatures_distinguished` |
| The register/gauge ladder (lossy-adjunction substrate) | `Registers.lean`, `ChiSquareGauge.lean` | `δ_eq_residual_div`, `surprise_eq_delta_sq_mul_E`, `fold_gauge_invariant`, `surprise_scales` |

**Not yet proved** (the genuine gaps this survey surfaces):

1. **The C*-identity as a statement.** `‖z*z‖ = ‖z‖²` with `‖z‖ = √N(z)` is trivial but
   unstated; likewise no `CStarSubalgebra`/norm-closure instance. Lean-provable in an afternoon.
2. **The full Clifford algebra `Cℓ₂`** (grade-1 vectors + bivectors, noncommutative). This is
   what would make "rotor = inner \*-automorphism" literal. **Not built** — and it is the
   prerequisite for §4.2's relocation to become a theorem rather than a TODO.
3. **The direction functor as a functor** (not just the wedge's anti-symmetry). We proved the
   *value* (`wedge_antisymm`) and the *group* (`Z₆`, `CrtHex.lean`), but not the functorial
   statement (direction as the Chasles quotient, the monoid-vs-group distinction). Category
   theory is **entirely unformalized** in our Lean.
4. **The Lawvere-metric-space reading** (`Hom(a,b)` = surprise edge, triangle inequality =
   composition, converse-failure = wedge). The metric facts exist (`hexDist_triangle` etc. in
   `Rotation.lean`) but not the enriched-category statement.
5. **The mixor / linearly-distributive structure** — no category of `ℤ[ω]`-modules, no
   distributivity natural transformation.

---

## 5. Proved vs analogy vs ours vs speculation (roll-up for these two docs)

| Claim | Calibration (vs OUR ternary lattice) |
|---|---|
| Clifford algebra = C*-algebra | **DIRECT** — `ℤ[ω] ⊂ ℂ = M₁(ℂ)`, \*-structure + C*-norm already in Lean (§3.1) |
| "ring = the C*-norm" (rebuild's statistical χ²) | **ANALOGY** — our `N(z)=a²+ab+b²` is algebraic, not the χ² residual; the rebuild's "ring" is a different object |
| rotor sandwich = inner \*-automorphism | **DIRECT formula, RELOCATED act** — trivial on the commutative `ℤ[ω]`; our rotor acts by left-mult (TROT); the inner automorphism lives in the unbuilt full `Cℓ₂` (§3.2, §4.2) |
| even-grade spinor `ψ=(α+βI)U` = the grade-0 rotor fix | **DIRECT, realized** — `OmegaEmbedding.lean` + `CrtHex.lean`; our rotor is genuinely even-grade and acts (§4.2) |
| Boolean hypercube = `ℂ^{2³²}` inside `Cℓ₀,₃₂` | **ANALOGY (base-2)** — the 2³²/32-qubit Cartan story has no ternary twin; our 2D analogue is degenerate (§3.3) |
| dual numbers = nilpotent second layer (ringed space) | **DIRECT** — `Signature.lean` `dual_nilpotent`, `dualUnits_card` |
| Hodge dual ≠ modular conjugation; anti-lattice = commutant | **ANALOGY** — unproven on both sides; radix-agnostic |
| Bogoliubov inequality = "physics = information" as a theorem | **SPECULATION / program** — we still lack β, dynamics, a bound (same gap as the rebuild) |
| Takesaki: "frame from outside" is checkable | **ANALOGY** — no modular theory built on either side |
| wedge = the value of a direction functor | **DIRECT (structure) + OURS (Z₃ cycle)** — generalizes to Z₆ via `CrtHex.lean` (§3.4, §4.1) |
| geometric product = mixor of a linearly distributive category | **DIRECT (the product + its symmetric/skew decomposition, proved) / ANALOGY (the categorical two-product mixor, unbuilt)** — `dot`/`wedge` are scalar-valued bilinear forms, not two monoidal products (§3.5) |
| residual edge = internal hom of a Lawvere metric space | **ANALOGY (unformalized)** — metric facts proved, enriched-category statement not |
| register/gauge shift = a lossy adjunction | **ANALOGY (unformalized)** — `Registers.lean`/`ChiSquareGauge.lean` prove the gauge facts, not the adjunction |
| Yoneda (meaning = the totality of relations) | **OURS** — operationalized by the lattice lookup; not a Lean theorem |
| "geometric product = composition" / "lattice IS a category" | **RETIRED identically** — monoidal not categorical; a Lawvere metric space, not a category |

---

## 6. Actionable upgrades (Lean-provable now, ordered)

1. **State and prove the C*-identity `‖z*z‖ = ‖z‖²`** (with `‖z‖ = √N(z)`) as a theorem on
   `ℤ[ω]`, and (optionally) a `NormedStarAlgebra`/`CStar` instance on the `φ`-image in `ℂ`.
   One afternoon; makes "Clifford = C*-algebra" a *theorem in our repo*, not a citation.
2. **Build the full `Cℓ₂`** (grade-1 vectors `e₁,e₂`, the bivector `I=e₁e₂`, the sandwich
   `v ↦ uvu⁻¹`). This is the single change that turns §4.2's "relocated" into a proved
   inner-automorphism theorem, and it is the prerequisite for the Spin `Z₁₂` double-cover.
3. **Promote the wedge from a scalar `ℤ` to a functor-valued direction** (the rebuild's own
   #1 upgrade, `category-theory.md`): state the direction functor's value as `Z₆` (not `ℤ`),
   with `CrtHex.lean`'s `mod6_iff_mod2_mod3` as the monoid/group split. This is the "keep the
   sign, drop symmetry" promotion, and its Lean form is largely in hand (`CrtHex.lean` +
   `HexIsotropy.lean`).
4. **Formalize the Lawvere-metric reading**: `Hom(a,b) = surprise edge`, composition = triangle
   inequality (reuse `hexDist_triangle`), converse-failure = `wedge_antisymm`. Buys the Yoneda
   principle and the lossy-adjunction gradient for register shifts.
5. **Decide the mixor's two-product leg**: record the geometric product `TMUL` as the single
   monoidal (associative, unital) product, and `symdot`/`wedge` as its symmetric/skew scalar-valued
   **bilinear-form** projections (not two monoidal products), so any future "linearly distributive"
   instance is not built on the false "dot/wedge = two monoidal products" leg.

---

## 7. One-sentence bottom line

The two surveys split cleanly against the ternary lattice: **category theory transfers almost
verbatim (radix-agnostic) and its "wedge = direction functor" *generalizes* to our Z₆ via
`CrtHex.lean` — the binary sign is just the Z₂ factor — while operator algebra transfers at the
algebra level (our `ℤ[ω] ⊂ ℂ = M₁(ℂ)` *is* a C*-algebra, and our even-grade rotor *does* act,
fixing the rebuild's grade-0 bug) but its two base-2 or noncommutative crown jewels — the
`ℂ^{2³²}` Cartan and the *inner*-automorphism sandwich — do not port: the Cartan is degenerate
in 2D and the inner automorphism is trivial on our commutative lattice, leaving rotation as a
left-multiplied `Z₆` action and the full `Cℓ₂` as the one unbuilt prerequisite.**

---

## TODO / not covered / caveats

- **Only the `.md` write-ups were read end-to-end; the PDFs were not opened.** Every "PROVEN" in
  the two surveys is the rebuild's two-stage subagent's claim, quoted from the paper's write-up,
  not re-derived from the PDF. Before promoting any *equation* (Bott's `ℂℓₙ ≅ M` table, the
  Bogoliubov bound, the direction-functor construction 2608.07380/2608.09428, the Γ-set mixor
  2608.13012, the Lawvere doctrine 2608.01915) to a Tau claim, open the source PDF under
  `/home/ian/opencode/parser/english/docs/{operator algebras,category theory}/`.
- **`category-theory.md`'s "57 papers, 11 conceptual" is a filtered set.** The 11 conceptual
  claims were extracted by the rebuild's subagents; the other 46 papers were not characterized
  here. Only the five cited arXiv IDs (2608.07380, 2608.09428, 2608.13012, 2608.01915, 2608.12030)
  are load-bearing; the rest are unread.
- **`MAP.md` O1 and K2 were over-smooth.** This survey **corrects** them: O1 "rotor sandwich =
  inner \*-automorphism → DIRECT" is refined to "formula DIRECT, act relocated (commutative ring)";
  K2 "geometric product = mixor → DIRECT" is refined to "product + symmetric/skew decomposition
  DIRECT, categorical two-product mixor ANALOGY (dot/wedge are scalar bilinear forms, not two
  monoidal products)." The master map should be updated to match.
- **The C*-identity `‖z*z‖=‖z‖²` and the full `Cℓ₂` are unproved/unbuilt** (gaps 1 and 2 of
  §4.3). "Clifford = C*-algebra" is therefore a *citation-backed* claim here, not yet a *Lean
  theorem* in our repo — do not write it as proved.
- **Signature ambiguity in `Cℓ₂`.** The full noncommutative envelope is `Cℓ₂ ≅ M₂(ℝ)` for
  signature (2,0) but `Cℓ₀,₂ ≅ ℍ` for signature (0,2); only the even subalgebra `ℂ` is
  signature-independent. §3.3's "ℂ ⊂ Cℓ₂" is deliberately left uncommitted to a signature until
  the full Clifford algebra is actually built.
- **The Spin double-cover `Z₁₂ ⊄ ℤ[ω]`** (§4.2 caveat) means "Z₆ rotor" is a rotation-operator
  statement, not a Spin statement. Any claim that our rotor is "the" Spin(2) rotor must first
  resolve the half-angle convention; do not import the rebuild's "R = exp(θ/2)" verbatim.
- **"DIRECT" is inherited self-assessment.** The DIRECT/ANALOGY labels here are my re-anchoring of
  the rebuild's *own* verdicts against the ternary lattice; I did not re-verify the underlying
  math of any survey against its PDF. Everything marked DIRECT still belongs on the "we should
  test" list before it becomes a Tau claim (same caveat as `REBUILD_SURVEY.md` §5 and `MAP.md`).
- **Category theory is entirely unformalized in our Lean.** §4.3's "not yet proved" list (full
  `Cℓ₂`, the direction functor, the Lawvere space, the mixor) is the honest scope of what a
  category-theory formalization effort would have to build from scratch; none of it exists yet.
