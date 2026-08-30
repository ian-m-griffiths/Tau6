# Gamma Function Γ(s) × Tau Architecture — survey & mapping

**2026-08-29 — survey of the Gamma function (pass 1: the mathematics) and its mapping
against the Eisenstein-lattice system (pass 2), with per-claim calibration.** This is the
**first link** in the chain Γ → γ → Epstein zeta → Kronecker limit formula. Read it as the
discrete↔continuous bridge that the other two documents (`epstein_zeta.md`,
`kronecker_limit.md`) climb onto.

Calibration legend: **DIRECT** = proved/measured/classical-theorem; **ANALOGY** = structural
resemblance, not an identity; **OURS** = our design claim following from DIRECT;
**SPECULATION** = untested, flagged as such.

---

## 0. Come to terms first — what Γ *is* (and is not)

Γ is the *continuous interpolation of the factorial*, but that phrase hides a choice. State
it precisely (sources: [DLMF §5.2](https://dlmf.nist.gov/5.2),
[Wikipedia — Gamma function](https://en.wikipedia.org/wiki/Gamma_function),
[Fungrim — Gamma function](https://fungrim.org/topic/Gamma_function/)):

| Object | Definition | Kind | Calibration |
|---|---|---|---|
| factorial `n!` | `∏_{k=1}^n k`, the **count** of permutations of `n` objects (`|Sₙ|`) | discrete product (a *cardinality*) | DIRECT |
| Γ(s) | Euler integral `Γ(s)=∫₀^∞ t^{s−1} e^{−t} dt`, `Re(s)>0`, then analytically continued | meromorphic function on ℂ, simple poles at `s=0,−1,−2,…` | DIRECT |
| the offset | `Γ(n) = (n−1)!` **not** `n!` | an **index shift**, not a normalization | DIRECT |
| γ inside Γ | γ appears as the constant in Γ's **Weierstrass product** (below) | γ is *built into* Γ | DIRECT |

**The offset is the whole story.** `Γ(n) = (n−1)!` means Γ interpolates `n!` *shifted by one*.
That `−1` is the same species of correction as `Hₙ − ln n → γ`: a discrete object (product /
sum) and a continuous object (integral / interpolant) differ by a *constant* after the leading
term is removed. Γ is where that constant is *generated*; γ is where it is *measured*.

---

## 1. Pass 1 — survey of Γ (the mathematics)

### 1.1 The three definitions and the bridge to γ

**Euler integral** (DIRECT): `Γ(s) = ∫₀^∞ t^{s−1} e^{−t} dt`, convergent for `Re(s) > 0`,
continued meromorphically to all of ℂ with simple poles at the non-positive integers. This is
mathlib's *definition* (`Complex.Gamma_eq_integral`).

**Weierstrass product** (DIRECT) — where γ physically enters:

```
1/Γ(z) = z · e^{γz} · ∏_{n=1}^∞ (1 + z/n) · e^{−z/n}
```

The Euler–Mascheroni constant γ appears **explicitly** as the coefficient `e^{γz}`. This is
the *mechanism* of the whole chain: Γ's product formula literally carries γ inside it. Taking
the log-derivative (digamma) gives

```
ψ(z) = Γ'(z)/Γ(z) = −γ − 1/z + Σ_{n=1}^∞ (1/n − 1/(z+n))
```

and at `z = 1` the sum telescopes (`Σ(1/n − 1/(n+1)) = 1`), so

```
ψ(1) = −γ  ⟹  Γ'(1) = Γ(1)·ψ(1) = −γ .
```

This is **γ = −Γ′(1)**, the anchor identity of this whole survey. Calibration: **DIRECT**
(classical), and — see §3 — it is **already proved in mathlib** as
`eulerMascheroniConstant_eq_neg_deriv`.

**Euler/Gauss limit** (DIRECT): `Γ(z) = lim_{n→∞} n^z n! / (z(z+1)⋯(z+n))`. mathlib proves
this too (`Complex.GammaSeq_tendsto_Gamma`). It is the "factorial-to-Γ" bridge in its most
literal form: the factorial `n!` appears in the numerator of the approximant.

### 1.2 The functional equations and characterizations

- **Recurrence** (DIRECT): `Γ(z+1) = z Γ(z)`. mathlib: `Complex.Gamma_add_one`. This is the
  *defining* discrete recursion, extended to continuous z.
- **Reflection** (DIRECT): `Γ(z)Γ(1−z) = π/sin(πz)`. mathlib:
  `Complex.Gamma_mul_Gamma_one_sub` (Beta.lean). At `z = 1/2` it gives `Γ(1/2) = √π` (DIRECT,
  mathlib `Complex.Gamma_one_half_eq`).
- **Duplication** (Legendre) (DIRECT): `Γ(z)Γ(z+1/2) = 2^{1−2z} √π · Γ(2z)`. mathlib:
  `Complex.Gamma_mul_Gamma_add_half`.
- **Bohr–Mollerup** (DIRECT): Γ is the **unique** positive, log-convex function on `(0,∞)`
  with `f(1)=1` and `f(x+1)=x f(x)`. mathlib: `eq_Gamma_of_log_convex` (BohrMollerup.lean).
  This is why the "interpolation of the factorial" is *canonical*: there is exactly one
  reasonable continuous factorial, so "the continuous version of n!" is well-posed.

### 1.3 The special value that feeds our Eisenstein point

`Γ(1/3) ≈ 2.67894` (DIRECT decimal; known constant). Unlike `Γ(1/2)=√π` it has **no** closed
form in elementary constants, and — the fact that matters downstream — **Γ(1/3) is
transcendental** (Chudnovsky, cited). It is exactly this value, via the Dedekind-eta value at
the Eisenstein point, that becomes the *shape* half of our "second invariant" (see
`kronecker_limit.md`). Γ(1/3) is the one Γ-value our lattice actually *needs*.

---

## 2. Pass 2 — mapping Γ against OUR system

### 2.1 Γ = the continuous version of the counting measure's *product*. ANALOGY (strong core)

Our "gauge" vocabulary (from `Gauge.lean`, `Haar.lean`, `ChiSquareGauge.lean`, and the Banica
counting-vs-probability distinction) has two different axes. Γ sits on one of them, and only
one:

| Axis | Discrete object | Continuous object | Bridge constant | Our Lean | Calibration |
|---|---|---|---|---|---|
| **discrete ↔ continuous** (the *sum/product* axis) | `n!` (discrete product); `Hₙ` (discrete sum) | Γ (continuous product); `ln n` (continuous integral) | **γ = −Γ′(1)** = `lim(Hₙ−ln n)` | γ in mathlib; δ does NOT live here | Γ↔factorial is the **ANALOGY**; γ here is **DIRECT** |
| **counting ↔ normalized** (the *measure* axis) | counting measure (all points) | probability measure (÷ total / ÷ units) | the Z₆ factor `6` / the `1/T` renormalization | `Haar.lean`, `ChiSquareGauge.lean` (**PROVED**) | DIRECT (ours) |

**The honest reading of Ian's question** — *"is Γ(n)=(n−1)! the 'probability measure' twin of
the factorial?"* — is **no, not quite**: Γ is the **continuous** twin of the factorial, not its
*probability-measure* twin. The `(n−1)` shift is an **index shift**, not a "divide by total"
renormalization. The two axes above are genuinely different moves:

- `n! → Γ` *interpolates* the index (discrete `n` → continuous `s`), and the leftover of that
  interpolation at the derivative is γ. **This is the γ-axis.**
- counting → probability *renormalizes* the measure (multiply by `1/T`, or divide by the unit
  group `Z₆`), and the leftover is our `δ`-fold / the `6` in the Epstein↔Dedekind bridge
  (`epstein_zeta.md` §2.2). **This is the Z₆-axis.**

So "Γ is the probability twin of n!" is **SPECULATION if read as an identity** — but the
*finer* statement is true and is the spine of all three documents: **Γ lives on the γ-axis
(discrete↔continuous), while our proved gauge results live on the Z₆-axis (counting↔units),
and the Kronecker limit formula is where the two axes meet** (§2.3). Calibrate the meeting as
ANALOGY with a DIRECT core (both halves are real theorems; only their *union* into one "second
invariant" number is our claim).

### 2.2 γ = −Γ′(1) as the discrete-vs-continuous correction. DIRECT (proved in mathlib)

The chain `Γ'(1) = −γ` and `lim(Hₙ − ln n) = γ` are **the same γ**, and both are **proved in
mathlib** (see §3). Our framework's use: γ is the number that *survives* when you subtract the
continuous reference (`ln n`, the integral) from the discrete reference (`Hₙ`, the sum) — the
exact structural sibling of our δ = `O/E − 1` "what is left after a normalization convention
is removed" (see `euler_constants.md` §3.3). The resemblance:

| γ's gauge | our δ's gauge | Verdict |
|---|---|---|
| `Hₙ − ln n → γ` (discrete sum minus continuous integral, n→∞) | `δ = O/E − 1` (observed over expected, per edge) | **ANALOGY** — both are "leftover after the leading/trivial term cancels"; γ is one global number, δ is one number per edge |

Calibration: the *direction* is real and is the strongest single mapping in this survey, but
γ and δ are different **types** (one global constant vs a per-pair function) and there is no
theorem identifying them. "γ = our gauge constant" is **ANALOGY**, not identity, exactly as
`euler_constants.md` §3.3 concluded.

### 2.3 Where Γ meets OUR lattice: Γ(1/3) is the shape constant. DIRECT (the fact), OURS (the relevance)

`Γ(1/3)` is not a "nice" constant for a Euclidean-lattice person until you hit the **hexagonal**
lattice, where it appears through the Dedekind-eta value at the Eisenstein point:

```
η(e^{2πi/3}) = e^{−πi/24} · 3^{1/8} · Γ(1/3)^{3/2} / (2π)      (Fungrim 204acd, DIRECT)
```

This one identity — verified verbatim in `kronecker_limit.md` — is the entire reason Γ appears
in our story at all: Γ(1/3) is the *transcendental shape constant* of the hexagonal lattice's
second invariant, the way Γ(1/2)=√π is the shape constant of the square lattice. Γ is thus not
a decoration: **Γ is the function whose value at 1/3 encodes our lattice's η-shape term.** The
claim "our lattice's second invariant needs Γ(1/3)" is **OURS** (follows from DIRECT Fungrim +
DIRECT Kronecker), not speculation.

---

## 3. Provable-in-Lean ledger for Γ

Everything in this section is *already in mathlib* at
`proofs/lean-src/hexagon/.lake/packages/mathlib/Mathlib/Analysis/SpecialFunctions/Gamma/` and
`.../Mathlib/NumberTheory/Harmonic/` (verified by inspection, 2026-08-29). This is the
*strongest* Lean coverage in the whole three-document chain — Γ is the only subject that needs
no new definitions.

| Claim | Calibration | Lean status (file) |
|---|---|---|
| `Γ` defined as Euler integral, `Γ(s)=∫₀^∞ t^{s−1}e^{−t}dt` for Re s>0 | DIRECT | **PROVED** `Complex.Gamma_eq_integral` (Gamma/Basic.lean) |
| `Γ(n+1) = n!` (factorial interpolation) | DIRECT | **PROVED** `Complex.Gamma_nat_eq_factorial`, `Real.Gamma_nat_eq_factorial` (Gamma/Basic.lean) |
| `Γ(s+1) = s Γ(s)` | DIRECT | **PROVED** `Complex.Gamma_add_one` |
| `Γ(1) = 1` | DIRECT | **PROVED** `Complex.Gamma_one` |
| reflection `Γ(z)Γ(1−z)=π/sin(πz)` | DIRECT | **PROVED** `Complex.Gamma_mul_Gamma_one_sub` (Gamma/Beta.lean) |
| duplication `Γ(z)Γ(z+1/2)=2^{1−2z}√π Γ(2z)` | DIRECT | **PROVED** `Complex.Gamma_mul_Gamma_add_half` (Gamma/Beta.lean) |
| `Γ(1/2) = √π` | DIRECT | **PROVED** `Complex.Gamma_one_half_eq` |
| Bohr–Mollerup: Γ unique log-convex interpolation of n! | DIRECT | **PROVED** `eq_Gamma_of_log_convex` (Gamma/BohrMollerup.lean) |
| Euler (Gauss) limit `Γ(z)=lim_{n→∞} n^z n!/(z(z+1)⋯(z+n))` | DIRECT | **PROVED** `Complex.GammaSeq_tendsto_Gamma` (Gamma/Beta.lean; mathlib header "The Euler limit formula") |
| Weierstrass product `1/Γ(z)=z e^{γz} ∏(1+z/n)e^{−z/n}` (γ explicit) | DIRECT | classical; the γ-coefficient is *captured* by `eulerMascheroniConstant_eq_neg_deriv` below, not stated as a separate theorem |
| **`γ = −Γ′(1)`** | DIRECT | **PROVED** `eulerMascheroniConstant_eq_neg_deriv` (Harmonic/GammaDeriv.lean) |
| `Γ'(n+1) = n!·(−γ + Hₙ)` (general derivative) | DIRECT | **PROVED** `deriv Real.Gamma (n+1) = …` (Harmonic/GammaDeriv.lean) |
| digamma `ψ(1)=−γ`, `ψ(1/2)=−2log2−γ` | DIRECT | **PROVED** `Complex.digamma_one`, `Complex.digamma_one_half` (Gamma/Digamma.lean) |
| `γ = lim(Hₙ − ln n)`, `1/2 < γ < 2/3` | DIRECT | **PROVED** `tendsto_harmonic_sub_log`, bounds (Harmonic/EulerMascheroni.lean) |
| `ζ(s) = 1/(s−1) + γ + O(s−1)` | DIRECT | **PROVED** `tendsto_riemannZeta_sub_one_div` (Harmonic/ZetaAsymp.lean) — *the 1-D Kronecker analog* |
| `Γ(1/3)` is transcendental | DIRECT (cited: Chudnovsky) | NOT in mathlib; cite only |

**Bottom line.** The entire Γ→γ half of the chain is **PROVED in mathlib today**. There is
nothing to re-derive: the factorial interpolation, the reflection, Bohr–Mollerup, and the
anchor identity `γ = −Γ′(1)` are all importable theorems. The one Γ fact our lattice needs
that is *not* in mathlib is the *transcendence* of `Γ(1/3)` (cite, don't prove).

---

## 4. Cross-references (the chain)

- **Γ → γ:** `γ = −Γ′(1)` (§1.1) is the discrete↔continuous bridge; it is the *same* γ that
  `epstein_zeta.md` and `kronecker_limit.md` carry into 2-D unchanged.
- **Γ → Epstein zeta:** `epstein_zeta.md` §2.3 — the hexagonal Epstein zeta's *shape* data is
  `Γ(1/3)` via the eta value, so Γ is the function behind the 2-D harmonic sum's constant term.
- **Γ → Kronecker:** `kronecker_limit.md` §2.2 — the Kronecker constant term is
  `2π(γ − log 2 − log(√y|η|²))`, and `|η|² ∝ Γ(1/3)³`, so Γ(1/3) is literally the last letter
  of the 2-D "second invariant".

---

## Sources

- [Wikipedia — Gamma function](https://en.wikipedia.org/wiki/Gamma_function)
- [Wikipedia — Digamma function](https://en.wikipedia.org/wiki/Digamma_function)
- [Wikipedia — Euler–Mascheroni constant](https://en.wikipedia.org/wiki/Euler%E2%80%93Mascheroni_constant)
- [DLMF §5.2 — Gamma: definitions](https://dlmf.nist.gov/5.2); [DLMF §5.5 — reflection & multiplication](https://dlmf.nist.gov/5.5)
- [Fungrim — Gamma function topic](https://fungrim.org/topic/Gamma_function/)
- mathlib (local checkout `proofs/lean-src/hexagon/.lake/packages/mathlib/`): `Analysis/SpecialFunctions/Gamma/{Basic,Beta,BohrMollerup,Deriv,Digamma}.lean`, `NumberTheory/Harmonic/{EulerMascheroni,GammaDeriv,ZetaAsymp}.lean`

*Local framework files cross-referenced: `docs/ENERGY_LAWS.md`, `docs/compute/euler_constants.md`,
`proofs/INDEX.md`, and the sibling docs `epstein_zeta.md` / `kronecker_limit.md`.*
