# Kronecker Limit Formula × Tau Architecture — survey & mapping

**2026-08-29 — survey of the Kronecker first limit formula (pass 1: the mathematics) and its
mapping against the Eisenstein-lattice system (pass 2), with per-claim calibration.** This is
the **third and final link** in the chain Γ → γ → Epstein zeta → Kronecker limit formula: it
*decomposes* the 2-D constant term (from `epstein_zeta.md`) into **universal γ + shape-dependent
Dedekind-eta**, and at our lattice point collapses the shape term to **Γ(1/3)**. Read it after
`gamma_function.md` and `epstein_zeta.md`.

Calibration legend: **DIRECT** = proved/measured/classical-theorem; **ANALOGY** = structural
resemblance, not an identity; **OURS** = our design claim following from DIRECT;
**SPECULATION** = untested, flagged as such.

---

## 0. Come to terms first — "limit formula" means "Laurent constant term", not a limit

The Kronecker limit formula is **not** a formula for `lim_{s→1}` of a convergent series; the
series **diverges** at `s=1` (simple pole). The formula gives the **full Laurent expansion** of
the Epstein zeta `E(τ,s)` around `s=1`:

```
E(τ, s) = π/(s−1) + C(τ) + O(s−1)
```

and then **evaluates the constant term `C(τ)` in closed form**. The "limit formula" is the
name for the *constant term* — the 2-D leftover after the divergent area term `π/(s−1)` is
stripped. This is the exact 2-D upgrade of `Hₙ − ln n → γ`. Source:
[Wikipedia — Kronecker limit formula](https://en.wikipedia.org/wiki/Kronecker_limit_formula).

Also keep the `τ` collision in force (`epstein_zeta.md` §0): this `τ` is the modular parameter,
not our `τ = 2π`.

---

## 1. Pass 1 — survey (the mathematics)

### 1.1 The full first limit formula (DIRECT, cited)

For `τ ∈ ℍ`, `y = Im τ`, and the Epstein zeta

```
E(τ, s) = Σ_{(m,n) ∈ ℤ² \ {(0,0)}}  y^s / |m + nτ|^{2s}
```

the **Kronecker first limit formula** states:

```
E(τ, s) = π/(s−1) + 2π( γ − log 2 − log( √y · |η(τ)|² ) ) + O(s−1)          (KLF-1)
```

where `η(τ) = q^{1/24} ∏_{n≥1} (1 − qⁿ)`, `q = e^{2πiτ}`, is the **Dedekind eta function**.
The constant term is

```
C(τ) = 2π( γ − log 2 − log( √y · |η(τ)|² ) ).
```

Read it as **two surviving terms**, matching `euler_constants.md` §3.2 and
`epstein_zeta.md` §2.3:

- **`π/(s−1)`** — the *density/area* term. Residue `π` = area of the fundamental domain
  (universal across τ). This is the "leading dimension," the continuous part.
- **`C(τ)`** — the *discrete correction*, the finite leftover. It splits into:
  - **`γ`** — *universal*: the same γ as 1-D (`gamma_function.md`), unchanged in 2-D, the
    lattice-independent dimension-correction.
  - **`−log 2 − log(√y |η(τ)|²)`** — *shape-dependent*: how the specific lattice's geometry
    (its modular parameter τ, its covolume `y`, its eta value) enters.

### 1.2 Why the η-term is the shape term (DIRECT, brief mechanism)

Two equivalent stories, both cited (Diamond–Shurman; Chowla–Selberg):

- **Theta/Mellin route.** `E(τ,s)` is the Mellin transform of the lattice theta function
  `θ(τ,t) = Σ e^{−πt|m+nτ|²}`; the theta's `s`-expansion near `t=0` (via Poisson summation)
  has a constant term, and its logarithm is governed by `η` because `η` is (essentially) the
  theta's product side. The `−log|η|²` is the *lattice-shape entropy* of the theta expansion.
- **Chowla–Selberg route.** At a complex-multiplication point, `η(τ)` takes a value that is a
  product of Γ-values at rational arguments (Chowla–Selberg formula). This is the mechanism by
  which `Γ(1/3)` (not just η) enters the constant term.

Either way: `η` carries the *shape*, γ carries the *universal* correction, and KLF-1 is the
theorem that the two are the **only** ingredients.

### 1.3 The second limit formula (context only, not our target)

There is a **second** Kronecker limit formula (DIRECT, cited) that generalizes KLF-1 to sums
twisted by a character / by `e^{2πi(…)` — the non-holomorphic Eisenstein-series avatar — and
specializes to the first at the trivial character. Our three documents use only the **first**;
the second is noted so "the Kronecker formula" is not silently over-claimed.

---

## 2. Pass 2 — mapping against OUR system

### 2.1 It splits the 2-D gauge constant into γ + η. DIRECT (the theorem), OUR framing (the naming)

KLF-1 is exactly the statement Ian's "second invariant" needs, and it is a *named, cited
theorem* (DIRECT), not our conjecture:

```
2-D discrete-vs-continuous correction  =  γ (universal)  +  η-shape term (lattice-specific)
```

γ is the "difference in dimension" constant — the part that survives **any** lattice — while
`−log(√y|η|²)` is the part that records **which** lattice. This is the honest 2-D resolution of
the 1-D question "is there a lattice analog of γ?": **yes, and it is two-component.** The prior
survey (`euler_constants.md` §3.2) reached this; this doc pins it to the exact formula. Our
*claim* is only the naming — that this two-component object is the architecture's "second
invariant." That is **OURS** (follows from DIRECT), not a new theorem.

### 2.2 At the Eisenstein point: the concrete closed form. DIRECT (composition of cited identities)

Set `τ = e^{2πi/3}` (the order-3 CM point; our `ω²` in the 120° convention, the same lattice as
`ω = e^{iπ/3}` by `ConventionBridge.lean` — see `euler_constants.md` §5). Then:

- `y = Im(e^{2πi/3}) = √3/2`, so `√y = (√3/2)^{1/2}`.
- The eta value (DIRECT, [Fungrim 204acd](https://fungrim.org/entry/204acd/), verified verbatim
  against Fungrim source 2026-08-29):

```
η(e^{2πi/3}) = e^{−πi/24} · 3^{1/8} · Γ(1/3)^{3/2} / (2π)
⟹ |η(e^{2πi/3})| = 3^{1/8} · Γ(1/3)^{3/2} / (2π)
```

Substituting into KLF-1, the **shape term** is (DIRECT algebra, no invented numbers):

```
√y · |η|² = (√3/2)^{1/2} · 3^{1/4} Γ(1/3)³ / (4π²)  =  √3 · Γ(1/3)³ / (4√2 · π²)
```

so the **constant term at OUR lattice point** is

```
C(e^{2πi/3}) = 2π( γ − log 2 − log( √3 · Γ(1/3)³ / (4√2 · π²) ) ).
```

This is a **closed form in {γ, π, Γ(1/3), and logarithms of rationals}**. Concretely, with
`Γ(1/3) ≈ 2.67894` and `γ ≈ 0.57722` (both DIRECT decimals), this is a finite, computable
number — the "second invariant" of the hexagonal lattice. **Two components, both named:**

- **γ** — universal (the discrete↔continuous leftover, `gamma_function.md` §2.2).
- **Γ(1/3)** — the transcendental *shape* constant of the hex lattice (via η), the same
  Γ(1/3) from `gamma_function.md` §1.3 / §2.3.

The two halves live at **different depths**: γ's irrationality is still *open*, while Γ(1/3)
is provably *transcendental* (Chudnovsky). The "second invariant" is therefore a
γ-piece (universal, provably-bounded but not even proved irrational) plus a Γ(1/3)-piece
(shape, provably transcendental). Record this asymmetry; do not flatten it.

### 2.3 The phase e^{−πi/24} is absent — and why that matters. DIRECT (from the formula), flag the temptation

Only `|η(τ)|²` appears in `C(τ)`, so the phase `e^{−πi/24}` of η **drops out**. This is
structural, not a coincidence: the phase is the branch ambiguity of the 24th root in
`η = q^{1/24}·∏(1−qⁿ)` (i.e. `η²⁴ = Δ`, the modular discriminant — a *true* modular form with
no phase ambiguity, in mathlib as `ModularForm.Discriminant`). So:

- the **modulus** `|η|` carries *shape/scale* → it enters `C(τ)`;
- the **phase** `e^{−πi/24}` carries *rotation/branch* → it does **not** enter `C(τ)`.

Resist two numerological moves here (both **SPECULATION**, flagged):
- **"24 = 4·6, so the eta phase encodes our Z₆."** 24 is the eta *multiplier/Δ* order (an
  `SL₂(ℤ)` fact), while 6 is the *unit group* `|ℤ[ω]^×|` (an arithmetic fact). Different
  objects; do not equate them.
- **"the phase is our Z₆ rotation."** The Z₆ in `epstein_zeta.md` §2.2 is the *factor* `w=6`
  (units), entering the residue `2π/√3`; the `24` here is a *branch* fact, entering nothing.
  Same word "rotation," two different roles. Keep apart.

What is legitimate (DIRECT): the Z₆ unit group does enter our lattice's zeta, but as the
**factor 6** in `Z(s) = 6ζ_K(s)` (`epstein_zeta.md` §1.3), not through the eta phase.

### 2.4 "The constant term C(e^{2πi/3}) is the receiver tax." SPECULATION (flagged)

`C(e^{2πi/3})` is a **dimensionless** transcendental/log-combination; the receiver floor is
~0.08–0.09 pJ/trit (measured, `ENERGY_LAWS.md`). No theorem connects them. The *structural*
story — the receiver is the invariant that survives the gauge shrink, exactly as `C(τ)`
survives the pole's removal — is the honest content; the *numeric* identification is
SPECULATION until a computed quantity links them. (Same flag as `euler_constants.md` §7 and
`epstein_zeta.md` §2.4.)

---

## 3. Provable-in-Lean ledger for the Kronecker formula

Verified by inspection of `proofs/lean-src/hexagon/.lake/packages/mathlib/` (2026-08-29).
**Important correction to `euler_constants.md` §6:** mathlib *does* now contain a Dedekind eta
— `ModularForm.eta` is **defined** (as the infinite product `q^{1/24}∏(1−qⁿ)`) with
non-vanishing and log-derivative proved (`ModularForms/DedekindEta.lean`), and `Δ = η²⁴` is
defined (`ModularForms/Discriminant.lean`). What remains absent is the *special value* and the
*limit formula*.

| Claim | Calibration | Lean status |
|---|---|---|
| Dedekind eta **defined**, `η(z)=q^{1/24}∏_{n≥1}(1−qⁿ)` | DIRECT | **PROVED** (definition) `ModularForm.eta` (`ModularForms/DedekindEta.lean`) |
| `η` non-vanishing, differentiable on ℍ; `logDeriv η = (πi/12)·E₂` | DIRECT | **PROVED** `eta_ne_zero`, `differentiableAt_eta_…`, `logDeriv_eta_eq_E2` |
| modular discriminant `Δ = η²⁴` | DIRECT | **PROVED** (definition) `ModularForm.Discriminant` |
| `γ = −Γ′(1)` (the universal half) | DIRECT | **PROVED** `eulerMascheroniConstant_eq_neg_deriv` (`gamma_function.md` §3) |
| `ζ(s) = 1/(s−1) + γ + O(s−1)` (1-D analog) | DIRECT | **PROVED** `tendsto_riemannZeta_sub_one_div` (`ZetaAsymp.lean`) |
| **Kronecker first limit formula (KLF-1)** | DIRECT (classical theorem) | **NOT in mathlib**; cite only — far out of near-term Lean reach (needs Epstein zeta + η modular transformation + theta-expansion) |
| **`η(e^{2πi/3}) = e^{−πi/24}·3^{1/8}·Γ(1/3)^{3/2}/(2π)`** | DIRECT (cited: Fungrim 204acd) | **NOT in mathlib**; cite only |
| Chowla–Selberg mechanism behind the CM eta value | DIRECT (cited theorem) | NOT in mathlib; cite only |
| `Γ(1/3)` transcendental | DIRECT (cited: Chudnovsky) | NOT in mathlib; cite only |

**Bottom line.** KLF-1 is a **cited theorem, not a Lean target**: it needs the Epstein zeta
(absent), the η modular transformation, and a theta/Poisson expansion — none in mathlib. The
*ingredients that do exist* are exactly the two halves' generators: `η` (defined) and
`γ = −Γ′(1)` (proved). So the two-component "second invariant" is, in Lean, one **proved**
constant (γ) plus one **defined-but-not-valued** function (η, whose special value is a cited
Fungrim entry). That is the honest formalization frontier.

---

## 4. Cross-references (the chain)

- **Kronecker → γ:** the constant term's universal half is the γ of `gamma_function.md` §2.2
  (proved `γ = −Γ′(1)`), surfacing in 2-D unchanged.
- **Kronecker → Γ:** the shape half is `Γ(1/3)` via `|η(e^{2πi/3})|` (`gamma_function.md`
  §2.3) — Γ is the function behind the last letter of the second invariant.
- **Kronecker → Epstein zeta:** this doc evaluates the *constant term* whose *existence* and
  pole `epstein_zeta.md` §1.1 established; the factor `6 = Z₆` of `epstein_zeta.md` §2.2 lives
  in the residue, not the constant term, so the two docs carry two different Z₆-facts.

---

## Sources

- [Wikipedia — Kronecker limit formula](https://en.wikipedia.org/wiki/Kronecker_limit_formula)
- [Wikipedia — Dedekind eta function](https://en.wikipedia.org/wiki/Dedekind_eta_function)
- [Wikipedia — Chowla–Selberg formula](https://en.wikipedia.org/wiki/Chowla%E2%80%93Selberg_formula)
- [Fungrim entry 204acd — η(e^{2πi/3})](https://fungrim.org/entry/204acd/)
- [DLMF §25.15 — Dirichlet L-functions](https://dlmf.nist.gov/25.15) (Epstein/theta context)
- mathlib (local checkout `proofs/lean-src/hexagon/.lake/packages/mathlib/`): `NumberTheory/ModularForms/{DedekindEta,Discriminant}.lean`, `NumberTheory/Harmonic/{GammaDeriv,ZetaAsymp}.lean`

*Local framework files cross-referenced: `docs/ENERGY_LAWS.md`, `docs/compute/euler_constants.md`,
`proofs/INDEX.md`, and the sibling docs `gamma_function.md` / `epstein_zeta.md`.*
