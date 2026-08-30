# Epstein Zeta Function E(τ,s) × Tau Architecture — survey & mapping

**2026-08-29 — survey of the Epstein zeta function (pass 1: the mathematics) and its mapping
against the Eisenstein-lattice system (pass 2), with per-claim calibration.** This is the
**second link** in the chain Γ → γ → Epstein zeta → Kronecker limit formula: it is the honest
2-D "harmonic sum" whose constant term at `s=1` is the 2-D analog of γ. Read it after
`gamma_function.md` (γ = −Γ′(1)) and before `kronecker_limit.md` (which decomposes this doc's
constant term).

Calibration legend: **DIRECT** = proved/measured/classical-theorem; **ANALOGY** = structural
resemblance, not an identity; **OURS** = our design claim following from DIRECT;
**SPECULATION** = untested, flagged as such.

---

## 0. Come to terms first — the *modular* τ is not our τ

Same collision flagged in `euler_constants.md` §0, now load-bearing. The `τ` in the Epstein
zeta `E(τ,s)` is the **modular shape parameter** — a complex number in the upper half-plane
`ℍ = {Im τ > 0}` that parameterizes a 2-D lattice `Λ = ℤ + ℤτ`. It is **not** our
`τ = 2π` (the full-turn constant in `Packing.lean`). Two unrelated τ's; keep them apart.

The lattice `Λ` determined by τ has, in the standard normalization, covolume/area `y = Im τ`
and squared distances `|m + nτ|²`. The Epstein zeta is the **renormalized lattice sum** of
`1/(distance)^{2s}`:

```
E(τ, s) = Σ_{(m,n) ∈ ℤ² \ {(0,0)}}  y^s / |m + nτ|^{2s}
```

Converges for `Re(s) > 1` (DIRECT; the exponent `2s` is why `s=1` is the critical "2-D
harmonic series" point). Sources: [Wikipedia — Epstein zeta function](https://en.wikipedia.org/wiki/Epstein_zeta_function),
[DLMF §25.15](https://dlmf.nist.gov/25.15).

---

## 1. Pass 1 — survey of the Epstein zeta (the mathematics)

### 1.1 Meromorphic continuation and the s=1 pole (DIRECT, cited)

`E(τ,s)` extends to a **meromorphic function on all of ℂ**, with a **single simple pole at
`s = 1`**, residue `π` (independent of τ), and satisfies a functional equation relating
`s ↔ 1−s` with a Γ-factor (the completed `Λ(τ,s) = π^{-s} Γ(s) E(τ,s)` is symmetric). The
residue `π` is, up to normalization, the **area of the fundamental domain** — it is the
*continuous/density* (leading-dimension) term, not the discrete correction. Calibration:
DIRECT classical theorem; **NOT in mathlib** (no Epstein zeta file exists — verified §3).

The residue `π` is the honest 2-D replacement for the *divergent leading term* `ln n` in the
1-D story. In 1-D, `Hₙ − ln n → γ` subtracts the diverging integral; in 2-D, `E(τ,s)` diverges
at `s=1` with residue `π/(s−1)`, and the *constant term* of that Laurent expansion (the 2-D
leftover) is what the Kronecker formula computes — `kronecker_limit.md` is entirely about
that leftover.

### 1.2 At OUR lattice point: τ = e^{iπ/3}, the Eisenstein (hexagonal) lattice (DIRECT)

Set `τ = ω = e^{iπ/3}` (our 60° unit, norm `a²+ab+b²`, per `proofs/INDEX.md`). Then
`y = Im ω = √3/2` and `|m + nω|² = m² + mn + n²`. So OUR lattice's Epstein zeta is

```
E(ω, s) = (√3/2)^s · Z(s),    Z(s) = Σ_{(m,n) ∈ ℤ² \ {(0,0)}}  1/(m²+mn+n²)^s
```

where `Z(s)` is the **un-normalized hexagonal lattice sum** — literally "the 2-D harmonic sum"
over our norm `a²+ab+b²`. This is the object Ian's "second invariant" wants to be.

### 1.3 The factorization: it IS the Dedekind zeta of ℚ(√−3), up to the unit count 6 (DIRECT)

The hexagonal lattice `ℤ[ω]` is the ring of integers of the imaginary quadratic field
`K = ℚ(√−3)`. Its **Dedekind zeta function** factors (DIRECT, standard — class number `h=1`,
discriminant `D=−3`):

```
ζ_K(s) = ζ(s) · L(s, χ₋₃)
```

where `χ₋₃` is the nontrivial Dirichlet character mod 3 (`χ₋₃(n) = 0, +1, −1` for `n ≡ 0, 1, 2
mod 3`), and `ζ(s)` is the Riemann zeta. The Dedekind zeta sums over **ideals**; because
`ℤ[ω]` is a PID (`EuclideanDomain.lean` PROVED) with unit group `Z₆` (`units_card = 6` PROVED,
`Rotation.lean`), summing over ideals = summing over nonzero lattice points **modulo the 6
units**, so:

```
Z(s) = Σ_{z ∈ ℤ[ω] \ {0}} 1/N(z)^s  =  6 · ζ_K(s)  =  6 ζ(s) L(s, χ₋₃)          (DIRECT)
```

The factor **6 is the number of units `w = 6`** — the same `Z₆` we proved. This is the
deepest DIRECT correspondence in the three-document chain (§2.2). The residue at `s=1`
consistently checks: `ζ_K` has residue `2πh/(w√|D|) = π/(3√3)`, so `Z(s)` has residue
`6·π/(3√3) = 2π/√3`, and `E(ω,s) = (√3/2)^s Z(s)` has residue `(√3/2)(2π/√3) = π` — matching
the universal residue of §1.1. (DIRECT, class-number formula + arithmetic.)

### 1.4 Is the Eisenstein-point Epstein zeta expressible in Γ(1/3) / η? — the honest answer

**No for the function, yes for its special data.** The *function* `E(ω,s) = 6ζ(s)L(s,χ₋₃)` is
built from the Riemann zeta and a Dirichlet L-function — **no Γ(1/3) anywhere** for general
`s` (DIRECT). Γ(1/3) enters only through **special values / derivative data**:

1. **Via the Kronecker constant term** (the content of `kronecker_limit.md`): the constant
   term of `E(τ,s)` at `s=1` is `2π(γ − log 2 − log(√y|η(τ)|²))`, and at `τ = e^{2πi/3}`,
   `|η| = 3^{1/8} Γ(1/3)^{3/2}/(2π)` (Fungrim 204acd). So the **shape** part of the 2-D
   constant is `log(√(√3/2) · 3^{1/4} Γ(1/3)³/(4π²))` — a closed form in `Γ(1/3)` (DIRECT,
   composition of cited identities).
2. **Via Chowla–Selberg** (named mechanism, cited): the Epstein zeta *at a CM point* (like
   `ω`, a complex-multiplication point) has special values expressible through products of
   Γ-values at rational arguments. This is the theorem *behind* the η-value in (1). Calibration:
   DIRECT as a named theorem; its specific output for us is precisely the Fungrim 204acd value.

So the answer to "is the Eisenstein-point Epstein zeta expressible in terms of Dedekind η /
Γ(1/3)?" is: **the zeta function factorizes as `6ζ(s)L(s,χ₋₃)` (no Γ(1/3)), but its
s=1 constant term — the "second invariant" — is a closed form in Γ(1/3) through η** (DIRECT).
Do **not** claim `E(ω,s) = [Γ(1/3) formula]` for general `s`; that would be SPECULATION.

---

## 2. Pass 2 — mapping against OUR system

### 2.1 At τ = e^{iπ/3} it is OUR lattice's zeta. DIRECT (the identification), OURS (the naming)

`E(ω,s)` is defined from exactly the objects we own: `ω = e^{iπ/3}`, the norm `a²+ab+b²`
(`Conventions.lean`, PROVED multiplicative), and the unit group `Z₆`. "The Eisenstein-point
Epstein zeta is our lattice's zeta" is a **DIRECT** identification of the mathematical object
with our lattice — no analogy required. What is *ours* is the *claim of relevance*: that
`E(ω,s)` (or its Kronecker constant term) is the "second invariant" the architecture should
carry. That is **OURS** (a design claim following from DIRECT), not a theorem.

### 2.2 The factor 6 = Z₆ = our gauge. DIRECT — the sharpest mapping in the chain

The identity `Z(s) = 6 ζ_K(s)` is *exactly* the "counting measure vs renormalized measure"
distinction that `Haar.lean` and the Banica gauge formalize, but at the level of the **zeta
function**:

| Level | Counting-measure object (primitive) | Renormalized object (÷ units) | Factor | Our Lean |
|---|---|---|---|---|
| measure on ℤ[ω] | counting measure (all points) | probability / unit-normalized measure | `1/6` (or `1/T`) | `Haar.lean` (`measure_invariant_card`, `units_counting_normalized` PROVED) |
| zeta function | Epstein `Z(s)` = sum over **all** nonzero points | Dedekind `ζ_K(s)` = sum over **ideals** = points **mod Z₆** | `6 = |Z₆|` | none yet (§3) — but the `6` is `units_card` (PROVED) |

Both rows have the **same `6`** (the same abstract `Z₆`), and "divide by the unit group order"
is the same operation. So our proved `units_card = 6` / counting-measure-Z₆-invariance is the
**exact finite shadow** of the number-theoretic fact that the Epstein zeta is 6 times the
Dedekind zeta. Calibration: the *core* (both are "count all points vs count points modulo the
6 units") is **DIRECT**; calling it "the same gauge" is **ANALOGY** resting on that DIRECT core.
This is the strongest, most checkable correspondence in all three documents — and it is
*independent* of any numerology: the number 6 is not a coincidence, it is `w = |ℤ[ω]^×|`.

### 2.3 The honest 2-D "second invariant" replacing 1-D γ. ANALOGY (correct direction, two components)

The 1-D picture `Hₙ − ln n → γ` upgrades to 2-D as follows (DIRECT components):

| 1-D | 2-D | Calibration |
|---|---|---|
| divergent leading term `ln n` | simple pole `π/(s−1)` (residue = area) | DIRECT |
| finite leftover `γ` | **constant term** of the Laurent expansion | DIRECT (it exists) |
| γ is *universal* (no lattice) | constant term = `2π(γ − log 2 − log(√y|η|²))` = **γ (universal) + η (shape)** | DIRECT (Kronecker, `kronecker_limit.md`) |

So "the 2-D γ" is **not a single number** — it is `γ` *plus* a shape term in the Dedekind eta.
γ survives into 2-D **unchanged** (the universal dimension-correction), while the lattice's
specific geometry enters only through `η(τ)`. At our `τ = e^{2πi/3}`, the shape term collapses
to `Γ(1/3)` (Fungrim 204acd). This is the precise content of Ian's "second invariant," and it
has **two** halves, matching `euler_constants.md` §3.2. The claim "γ replaces/augments our δ as
*the* invariant" is **ANALOGY**; the claim "the 2-D invariant is γ + η(τ), concretely
γ + Γ(1/3)-term at our point" is **DIRECT** (Kronecker + Fungrim), and its *relevance* to the
receiver floor is **SPECULATION** (§4).

### 2.4 "The Eisenstein-point Epstein zeta = the receiver tax." SPECULATION (flagged)

Same trap as `euler_constants.md` §7. `E(ω,s)`'s constant term is a **dimensionless**
number; the receiver floor is ~0.08–0.09 pJ/trit (measured, `ENERGY_LAWS.md`). No theorem maps
one to the other, and none is asserted. The *structural* resonance (the receiver is the part
that survives a gauge change, exactly as γ and the η-term survive the leading term's removal)
is the real content; the *numeric* identification is SPECULATION until a quantity is computed.

---

## 3. Provable-in-Lean ledger for the Epstein zeta

Verified by inspection of `proofs/lean-src/hexagon/.lake/packages/mathlib/` (2026-08-29).

| Claim | Calibration | Lean status |
|---|---|---|
| `ℤ[ω]` is a Euclidean domain / PID | DIRECT | **PROVED** (`EuclideanDomain.lean`) — the PID precondition for "ideals = points mod units" |
| unit group = `Z₆`, `units_card = 6` | DIRECT | **PROVED** (`Rotation.lean`) — the `w=6` in the factor `Z(s)=6ζ_K(s)` |
| counting measure is Z₆-invariant | DIRECT | **PROVED** (`Haar.lean`) — the measure-level shadow of "÷ units" |
| `riemannZeta` defined; differentiable away from 1 | DIRECT | **PROVED** (`LSeries/RiemannZeta.lean`) |
| Dirichlet L-series machinery (`L(s,χ)`) | DIRECT | **PROVED** (exists: `LSeries/Dirichlet`, `EulerProduct/DirichletLSeries`) |
| `ζ(s) = 1/(s−1) + γ + O(s−1)` | DIRECT | **PROVED** (`ZetaAsymp.lean`) |
| **Epstein zeta `E(τ,s)`** (definition, continuation, residue π) | DIRECT (classical) | **NOT in mathlib** (0 files mention "Epstein"); would be a new definition |
| **`Z(s) = 6 ζ(s) L(s, χ₋₃)`** at the hexagonal point | DIRECT (classical) | **NOT in mathlib**; *in principle* formalizable (pieces all exist: `riemannZeta`, `LSeries.Dirichlet`, `EuclideanDomain`, `units_card`) but is a genuine research-grade proof (class-number/Dirichlet factorization), not a near-term target |
| `L(1, χ₋₃) = π/(3√3)`, residue `2π/√3` | DIRECT (class-number formula) | NOT in mathlib; cite |
| Chowla–Selberg special values at CM points | DIRECT (cited theorem) | NOT in mathlib; cite only |
| `Γ(1/3)` transcendental | DIRECT (cited) | NOT in mathlib; cite |

**Bottom line.** The Epstein zeta itself, its meromorphic continuation, its residue, the
factorization `6ζ(s)L(s,χ₋₃)`, and the `Γ(1/3)` special value are **DIRECT mathematics but out
of Lean reach** — none of them are in mathlib. What *is* proved (and importable) are the
*ingredients our lattice contributes*: the Euclidean domain, the unit count `6`, and the
counting-measure Z₆-invariance — i.e. our side of the `Z(s) = 6ζ_K(s)` bridge is proved, the
zeta side is cited.

---

## 4. Cross-references (the chain)

- **Epstein → Γ:** the shape half of the Eisenstein-point zeta is `Γ(1/3)` via
  `|η(e^{2πi/3})| = 3^{1/8}Γ(1/3)^{3/2}/(2π)` — see `gamma_function.md` §2.3. Γ is the function
  behind this doc's "second invariant."
- **Epstein → γ:** the constant term at `s=1` carries γ *unchanged* from 1-D
  (`gamma_function.md` §2.2) into 2-D — γ is the lattice-independent half.
- **Epstein → Kronecker:** this doc states *that* the constant term exists; `kronecker_limit.md`
  states *what it equals* and how it splits into γ + η.

---

## Sources

- [Wikipedia — Epstein zeta function](https://en.wikipedia.org/wiki/Epstein_zeta_function)
- [Wikipedia — Dedekind zeta function](https://en.wikipedia.org/wiki/Dedekind_zeta_function)
- [Wikipedia — Dirichlet L-function](https://en.wikipedia.org/wiki/Dirichlet_L-function)
- [DLMF §25.15 — Dirichlet L-functions](https://dlmf.nist.gov/25.15)
- [World Scientific ch. 7 — The Hexagonal Lattice and the Epstein Zeta Function](https://www.worldscientific.com/doi/10.1142/9789814699877_0007)
- [Chowla–Selberg formula (Wikipedia)](https://en.wikipedia.org/wiki/Chowla%E2%80%93Selberg_formula)
- [Fungrim 204acd — η(e^{2πi/3})](https://fungrim.org/entry/204acd/)
- mathlib (local checkout `proofs/lean-src/hexagon/.lake/packages/mathlib/`): `NumberTheory/LSeries/{RiemannZeta,Dirichlet}.lean`, `NumberTheory/EulerProduct/DirichletLSeries.lean`, `NumberTheory/Harmonic/ZetaAsymp.lean`; our `Hexagon/{EuclideanDomain,Rotation,Haar}.lean`

*Local framework files cross-referenced: `docs/ENERGY_LAWS.md`, `docs/compute/euler_constants.md`,
`proofs/INDEX.md`, and the sibling docs `gamma_function.md` / `kronecker_limit.md`.*
