# Euler Constants × Tau Architecture — survey & mapping

**2026-08-29 — survey of every "Euler" constant against the three energy laws and the
Eisenstein lattice, with per-claim calibration.** Calibration legend: **DIRECT** =
proved/measured/classical-theorem; **ANALOGY** = structural resemblance, not an identity;
**OURS** = our design claim following from DIRECT; **SPECULATION** = untested, flagged.
Primary sources: `proofs/INDEX.md` (the proved ledger), `docs/ENERGY_LAWS.md` (the three
laws), the Lean files under `proofs/lean-src/hexagon/Hexagon/`, plus the cited literature.

---

## 0. Come to terms first — "Euler constants" is NOT a natural family

Before mapping anything, resolve the naming collision (AGENTS.md rule 4). Every object
below carries Euler's *name* (Leonhard Euler, 1707–1783) but they are **different kinds of
mathematical object**, and one of them is not even Euler's convention:

| Object | Kind | Is it a "constant"? |
|---|---|---|
| `e ≈ 2.718281828459045` | transcendental real number (base of natural log) | ✅ real constant |
| `γ ≈ 0.577215664901533` | real number, *irrationality still OPEN* | ✅ real constant |
| Euler characteristic `χ` | integer **topological invariant** (V−E+F / genus) | ⚠️ integer, not a "constant" in the number sense |
| `τ = 2π ≈ 6.2831853` | angle/naming **convention** (Hartl's τ, *not* Euler's — Euler used π) | ⚠️ a convention, not a discovered constant |
| Euler's identity `e^{iτ}=1` | **theorem** (Euler's formula at θ=τ) | ❌ a theorem |
| Euler's totient `φ(n)` | arithmetic **function** (count of coprimes) | ❌ a function |
| Euler–Lagrange | **differential equation** (stationary action) | ❌ an equation |

**Second collision, specific to this survey:** the *modular* `τ` in the Kronecker limit
formula (a lattice shape parameter, a complex number in the upper half-plane) is **not** our
`τ = 2π`. Two unrelated `τ`s. The Kronecker `τ` is the modular parameter `z₂/z₁` of a 2-D
lattice; our `τ` is the full-turn constant. Keep them apart when reading §3.

**Consequence for Ian's framing:** "two Euler constants e and γ" is right at the level of
"two *real-number* constants discovered by Euler that genuinely appear in our laws" — but
there are not two, there are *two kinds of relevance*: `e` (density/rotation) and `γ`
(gauge). The rest (χ, τ, φ, Euler–Lagrange, the identity) are name-collisions worth
*sorting*, not *counting*.

---

## 1. The constant → axis map

The four axes Ian named (density / gauge / topology / rotation) plus the fifth that
Euler–Lagrange actually lives on (variational/action):

| Constant | Value / definition | Axis it maps to | Our law / Lean file | Calibration |
|---|---|---|---|---|
| **e** | 2.71828…, `d/db (b/ln b)=0 ⟺ b=e` | **density** (radix economy); **rotation** (via `e^{iθ}`) | Law 3; `RadixEconomy.lean` | DIRECT (economy); Lean proves only the *integer* comparison |
| **γ** | 0.57721…, `lim(Hₙ−ln n)` | **gauge** (discrete↔continuous correction) | Law 1 (candidate); `ChiSquareGauge.lean` | the γ-as-gauge claim is **ANALOGY** (see §3) |
| **χ** | V−E+F; sphere=2, torus=0 | **topology** | none yet (hex disk `HexDisk.lean` is a count, not χ) | DIRECT (classical), unreferenced in ledger |
| **τ** | 2π | **rotation** (full turn) + **density** (`τ/(4√3)`) | `Packing.lean` (`hexPackingDensity_eq_tau_div`, PROVED) | DIRECT |
| **e^{iτ}=1** (Euler identity) | Euler's formula at θ=τ | **rotation** (full turn = identity) | `omegaPow_six` (ω⁶=1, PROVED) is its discrete shadow | DIRECT as a real identity |
| **φ(n)** | #{k≤n : gcd(k,n)=1} | **rotation/topology** (generators) — *minor* | none; `units_card=6` + φ(6)=2 adjacent | DIRECT, low relevance |
| **Euler–Lagrange** | `d/dt ∂L/∂q̇ = ∂L/∂q` | **variational/action** (NOT density/gauge/topology/rotation) | Law 2 (analogy only); AGENTS.md retires "least-squares = least-action" | ANALOGY |

**Reading the map.** Only two entries genuinely touch the laws as *identities*: `e` → Law 3
(DIRECT, radix economy) and `τ` → packing density (DIRECT, already in `Packing.lean`).
`γ` → Law 1 is the *hypothesis under test* (§3) and is ANALOGY, not identity. `χ`, `φ`,
Euler–Lagrange are name-collisions that map cleanly onto axes but add no new *number* to the
three laws.

---

## 2. e — radix economy (Law 3). DIRECT, with one honest gap

**The fact.** The cost of a radix-`b` digit is `b` states per digit, and each digit carries
`ln b` nats, so the economy is `b / ln b`. The function `f(b) = b/ln b` has
`f'(b) = (ln b − 1)/(ln b)²`, which vanishes **iff `b = e`**, and it is the global minimum.
So the *real-number* optimum is `e`, and the nearest integer is 3:

```
e = 2.71828   (f(e) = e/ln e = e = 2.71828)
3/ln 3 = 2.73072
2/ln 2 = 2.88539
```

**What our Lean actually proves.** `RadixEconomy.lean` proves `3/ln3 < 2/ln2`
(`ternary_beats_binary`) and `4/ln4 = 2/ln2` (`quaternary_ties_binary`) — the **integer
comparison**, *not* the calculus fact that `e` is the minimizer. The `e`-optimality is
DIRECT (classical one-variable calculus) but **not yet in the ledger**; the Lean statement
is strictly weaker than "3 wins because it's nearest e." Both are true; only the former is
proved here.

**Provability in Lean.** `e`-optimality is provable with mathlib's real derivative machinery
(`HasDerivAt`, `hasDerivAt_log`, `isLocalMin` etc.) — a genuinely new but routine theorem,
not yet written. Calibration: **DIRECT, PROVABLE, UNPROVED**.

**e's second role (rotation).** `e` also enters Euler's formula `e^{iθ}=cos θ + i sin θ`
(mathlib `Complex.exp_mul_I`), which is how `e` reaches the Z₆ rotation (§5). Same number,
two axes.

---

## 3. γ — the gauge-constant hypothesis (Law 1). The heart, and where to be careful

### 3.1 What γ *is* (DIRECT, and already formalized)

γ is the **discrete-vs-continuous correction** for the harmonic series:

```
Hₙ = Σ_{k=1}^n 1/k   (discrete sum)
ln n = ∫₁^n dx/x     (continuous integral)
γ  = lim_{n→∞} (Hₙ − ln n)  ≈ 0.5772156649
```

It is *already in mathlib*: `Real.eulerMascheroniConstant` is defined as
`limUnder atTop eulerMascheroniSeq`, and `Real.tendsto_harmonic_sub_log` proves
`harmonic n − log n → γ`. mathlib also proves `1/2 < γ < 2/3`. So Ian's "second invariant"
number exists as a first-class Lean object **today** — this is the one constant in the survey
that we do not have to re-derive.

Calibration: **DIRECT** (the identity γ = lim(Hₙ−ln n) is a proved mathlib theorem; the
number itself is real but its *irrationality is an open problem* — do not claim γ is
transcendental like e/π).

### 3.2 The honest 2-D lattice analog — Kronecker's first limit formula (DIRECT, cite)

The hypothesis "γ = the discrete-vs-continuous correction = the gauge constant" has a
**known, real 2-D upgrade**, and it is exactly the Kronecker limit formula. For a 2-D
lattice `Λ = ℤ + ℤτ` (Im τ > 0), define the **Epstein zeta function** (the "renormalized
lattice sum of `1/(distance)^{2s}`"):

```
E(τ, s) = Σ_{(m,n)≠(0,0)}  yˢ / |mτ + n|^{2s},   y = Im τ
```

At `s = 1` this sum **diverges** (simple pole). The **Kronecker first limit formula** gives
the Laurent expansion around the pole:

```
E(τ, s) = π/(s−1) + 2π( γ − log 2 − log( √y · |η(τ)|² ) ) + O(s−1)
```

where `η(τ) = q^{1/24} Π_{n≥1}(1−qⁿ)` is the **Dedekind eta function** (source:
[Wikipedia — Kronecker limit formula](https://en.wikipedia.org/wiki/Kronecker_limit_formula)).

**Read the two surviving terms as Ian's "second invariant":**

- The **pole** `π/(s−1)` is the *continuous/density* part — its residue π is (up to the
  normalization) the area of the fundamental domain. This is the "leading dimension."
- The **constant term** `2π(γ − log 2 − log(√y|η(τ)|²))` is the *discrete correction* — the
  finite leftover after the divergent area is subtracted. It splits into:
  - **γ** — the *universal* part: same for **every** 2-D lattice. This is literally the
    same γ as the 1-D harmonic correction, surfacing unchanged in 2-D.
  - **log(√y |η(τ)|²)** — the *shape-dependent* part: how the specific lattice's geometry
    (its modular parameter τ) enters via the Dedekind eta.

So the honest 2-D answer to "is there a lattice analog of γ?" is **yes**:
`γ + (eta-shape term)` is the 2-D discrete-vs-continuous correction, and γ itself is
*lattice-independent* — the universal "difference in dimension" constant, while the
Dedekind-eta term is the *lattice-specific* gauge. Ian's "second invariant" is real, and it
has **two** components (universal γ + shape η), not one.

**For our Eisenstein/hexagonal lattice specifically.** The hex lattice is the order-3 point
of the modular group, shape parameter `ρ = e^{2πi/3}` (our `ω²` in the 60° convention — see
§5; the 60° and 120° points give the same lattice by `ConventionBridge.lean`). At that
point the eta value is a known Gamma-value
([Fungrim 204acd](https://fungrim.org/entry/204acd/)):

```
η(e^{2πi/3}) = e^{−πi/24} · 3^{1/8} · Γ(1/3)^{3/2} / (2π)
⟹ |η(e^{2πi/3})| = 3^{1/8} Γ(1/3)^{3/2} / (2π)   (Γ(1/3) ≈ 2.6789 ⟹ |η| ≈ 0.8006)
```

So the shape-dependent term at our lattice is `log(√(√3/2) · |η(e^{2πi/3})|²)` — a
closed-form constant in Γ(1/3). Γ(1/3) is transcendental (Chudnovsky), so the *shape*
correction is itself transcendental, while the *universal* correction γ is (as far as is
known) not even proved irrational. The two halves of the "second invariant" live at
different depths of the transcendental hierarchy — worth recording, not asserting.

### 3.3 Is "γ = our gauge constant" a real mapping? **ANALOGY, not identity.**

Careful separation of three different things that all use the word "gauge":

| Our notion (from `Gauge.lean`, `Haar.lean`, `ChiSquareGauge.lean`) | γ's notion | Verdict |
|---|---|---|
| counting measure = primitive; probability = renormalized counting (Banica) | discrete sum `Hₙ` vs continuous integral `ln n` | **ANALOGY** — both are "discrete reference vs normalized reference" |
| `δ = O/E − 1` is invariant under common rescale `(O,E)↦(cO,cE)`; χ² scales | γ survives the *cancellation of leading terms* | **ANALOGY**, different gauge group |
| "gauge" = a *finite* discrete↔discrete renormalization (multiply counts by 1/T) | "gauge" = a *discrete→continuous limit* (n→∞) | **ANALOGY**, different limit |

The structural resonance is real and is the strongest in this survey: **γ and our δ are both
"what is left over after a normalization convention is removed"** — γ is what survives
`Hₙ − ln n` as the leading terms cancel; δ is what survives `(O,E)↦(cO,cE)` as the common
factor cancels. Both are "the second invariant." But:

1. γ is a **single real number** (one global correction); our δ is a **per-edge quantity**
   (one value per `(a,b)` pair). They are different *types* of object.
2. γ's gauge is a **limit** (n→∞, the continuum); our δ's gauge is a **finite rescale**.
   There is no theorem identifying them, and none is asserted.
3. The 2-D Kronecker formula shows the honest "second invariant" is *γ plus an η-shape
   term*, not γ alone — so even at the level of the analogy, "γ = the gauge constant" is
   missing the shape-dependent half.

**Calibration of Ian's hypothesis:** the *direction* is right and has a named, cited 2-D
theorem behind it (Kronecker). The *identity* "γ = our gauge constant / the receiver tax"
is **SPECULATION** and stays so until a theorem links γ (or the Kronecker constant term) to
our δ-fold or to the measured receiver floor. See §7 for the numerological traps.

---

## 4. Gauge-invariance verdict per constant (Law 1 hook)

"Gauge-invariant" here means: *unchanged under a change of normalization/measure convention*
— the mathematical sibling of Law 1's "receiver is gauge-agnostic."

| Constant | Dimensionless? | Gauge-invariant under renormalization? | Notes |
|---|---|---|---|
| **e** | ✅ pure number | ✅ canonical (fixed definition; not a normalization-dependent object) | defined once, invariant by definition |
| **γ** | ✅ pure number | ✅ canonical — but it is *itself the gauge leftover*: it is the value that survives the count→integral convention change | the "invariant" that IS the gauge correction |
| **χ** | ✅ integer | ✅ topological — invariant under homeomorphism (a *different* gauge: topology, not measure) | Gauss–Bonnet: `∫K dA = 2πχ = τχ` |
| **τ** | ✅ angle | ⚠️ **it is a gauge *choice***, not an invariant — the π↔τ convention is literally a gauge choice in angle measure (full-turn vs half-turn) | our framework's count↔prob gauge is the same *kind* of move |
| **φ(n)** | ✅ integer count | ✅ canonical | trivial |
| **δ = O/E−1** | ✅ (ratio) | ✅ **proved** (`fold_gauge_invariant`, `ChiSquareGauge.lean`) | the one we actually proved |
| **χ² surprise** | ✅ (ratio) | ❌ **proved NOT invariant** (`surprise_scales`: scales by c) | the "receiver tax" that does not shrink |

**The Law-1 connection (ANALOGY).** Law 1 says the receiver cost is invariant under
transmission-gauge change (swing ∝V²) — the wire shrinks, the measurement stands. The
mathematical constants that are gauge-invariant (δ, e, γ, χ) are the "receiver-like"
objects: the part that never shrinks when you change the normalization. γ is the sharpest
case: it *is* the number that survives the discrete→continuous normalization. So
"receiver = the discrete correction that survives the shrink" is a coherent **ANALOGY** —
but the identification "receiver tax = γ (or γ's Kronecker constant term)" is SPECULATION
until a number ties them (e.g. the measured ~0.08 pJ/trit floor vs. some lattice-zeta
constant). Do not assert the equality.

---

## 5. τ/6 ↔ ω — the angle relationship (rotation). DIRECT

**The identity.** `τ/6 = 2π/6 = π/3 = 60°`, and Euler's formula (mathlib
`Complex.exp_mul_I`) gives

```
e^{iτ/6} = e^{iπ/3} = cos(π/3) + i·sin(π/3) = 1/2 + i√3/2 = ω
```

That is our 60° unit `ω` (the Lean pair `(0,1)`, which in ℂ is `1/2 + i√3/2`). This is a
**DIRECT real-number identity**, not an analogy: `e^{iτ/6} = ω` *is* the definition of ω in
complex form. `ω² = ω − 1` (the `Conventions.lean` relation) is verified by
`(1/2+i√3/2)² = −1/2+i√3/2 = ω − 1`.

**The full-turn closure.** `e^{iτ} = (e^{iτ/6})⁶ = ω⁶ = 1` — and `omegaPow_six` (in
`Gauge.lean`) is the **proved** discrete shadow of exactly this: `ω⁶ = 1`. So the chain
`e^{iτ} = ω⁶ = 1` is: real identity (mathlib `exp_mul_I` + trig special values) ↔ proved
integer identity (`omegaPow_six`). Euler's identity in τ-form is the *continuous* version of
our *proved* `ω⁶=1`.

**Is τ/6 the "natural angle constant"?** Yes, with a precise meaning: τ/6 = π/3 is the
**generator angle** of the Z₆ rotation group — one-sixth of a full turn, the exact angle of
an Eisenstein unit rotation. In τ-convention the six units are `e^{iτ·k/6}`, k=0..5, cleanly
(no factors of 2 to juggle as in `e^{iπk/3}`). So τ/6 is the natural *unit* of the hex
rotation — matching Ian's τ-not-π convention in `Packing.lean`. **DIRECT.**

**The Lean gap (be honest).** Our `Gauge.lean` defines `ω = ⟨0,1⟩` as the abstract pair in
the `Eisenstein` *structure*, and states "ω = e^{iπ/3}" only in the header comment. There is
**no theorem yet** linking `ω` to the complex exponential. The bridge is provable and is
the exact shape of the existing `ConventionBridge.lean`:

1. define the embedding `ι : Eisenstein → ℂ`, `ι(a+bω) = a + b·(1/2 + i√3/2)`;
2. prove `ι` is a ring homomorphism (`ι(ω)² = ι(ω) − 1`, matching `ω² = ω − 1`);
3. prove `ι(ω) = Complex.exp (Complex.I · π/3)` via `exp_mul_I` + the special values
   `cos(π/3) = 1/2`, `sin(π/3) = √3/2` (both in mathlib).

Calibration: **DIRECT, PROVABLE, UNPROVED** (a genuinely new theorem, not in the ledger).

---

## 6. The ledger — what is PROVABLE (DIRECT) vs ANALOGY vs SPECULATION

Mirrors `proofs/INDEX.md`'s calibration column. "Provable" = has (or could have) a
`lake build`-green Lean proof; "PROVED" = already in the ledger.

| Claim | Calibration | Lean status |
|---|---|---|
| `3/ln3 < 2/ln2` (ternary beats binary) | DIRECT | **PROVED** (`RadixEconomy.lean`) |
| `b/ln b` minimized at `b=e` | DIRECT (calculus) | PROVABLE, unproved |
| `γ = lim(Hₙ−ln n)` | DIRECT | **PROVED in mathlib** (`tendsto_harmonic_sub_log`); importable |
| `1/2 < γ < 2/3` | DIRECT | **PROVED in mathlib** |
| `ζ(s) = 1/(s−1) + γ + O(s−1)` | DIRECT | in mathlib (`ZetaAsymp.lean`) — import, verify |
| Kronecker limit formula (2-D γ analog) | DIRECT (cited theorem) | **NOT** in mathlib (modular forms exist; no Dedekind eta / Kronecker limit). Cite only; far out of near-term Lean reach |
| `η(e^{2πi/3}) = e^{−πi/24}·3^{1/8}·Γ(1/3)^{3/2}/(2π)` | DIRECT (cited: Fungrim) | NOT in mathlib; cite only |
| `τ/(4√3) = π/(2√3)` (packing density) | DIRECT | **PROVED** (`Packing.lean`) |
| `e^{iτ/6} = ω` (60° unit) | DIRECT (Euler's formula) | PROVABLE via `exp_mul_I` + ℂ embedding; unproved |
| `ω⁶ = 1` | DIRECT | **PROVED** (`omegaPow_six`, `Gauge.lean`) |
| `units_card = 6`, Z₆ rotation, norm invariant | DIRECT | **PROVED** (`Rotation.lean`, `Gauge.lean`, `Haar.lean`) |
| `δ = O/E−1` gauge-invariant; χ² scales | DIRECT | **PROVED** (`ChiSquareGauge.lean`) |
| χ = V−E+F for a finite cell complex | DIRECT (classical) | PROVABLE (finite combinatorics), unproved here |
| φ(6)=2 (primitive 6th roots = ω, ω⁻¹) | DIRECT | PROVABLE (finite check), unproved here |
| γ = "our gauge constant" (the δ-fold) | **ANALOGY** | no theorem; see §3.3 |
| γ (or Kronecker term) = "the receiver tax" (Law 1) | **SPECULATION** | no number ties them; see §7 |
| "least-squares = least-action" (Euler–Lagrange ↔ Law 2) | **ANALOGY**, and *retired* by AGENTS.md | large-deviations rate function ≠ Euler–Lagrange; do not re-assert |
| any `e + γ = …` identity | **SPECULATION** | flag, see §7 |

**Bottom line of the ledger:** everything we *already proved* is the discrete/rotation layer
(radix comparison, Z₆, ω⁶=1, δ-invariance). The two genuinely new things this survey
surfaces — (a) `b/ln b` minimized at `e`, and (b) the ℂ-embedding `e^{iτ/6}=ω` — are
**DIRECT and provable but unproved**, and are the two highest-value next proofs. The
Kronecker/Dedekind-eta 2-D analog is **DIRECT mathematics but out of Lean reach**; it is
the honest *content* of Ian's "second invariant" and should be carried as a cited theorem,
not a Lean target.

---

## 7. Numerology — explicitly FLAGGED

These are the traps this survey is required to name. **None of the following are asserted;
all are SPECULATION and should not appear in ENERGY_LAWS.md, INDEX.md, or any "proved"
ledger without a theorem:**

- **"e + γ = …" / "e·γ = …" / any closed form combining e and γ.** No known meaningful
  identity links e and γ. γ's irrationality is *open*, so any exact algebraic relation to e
  (transcendental) would be a major result. **SPECULATION.**
- **"γ explains the receiver tax" (Law 1).** The receiver floor is ~0.08–0.09 pJ/trit
  (measured). γ ≈ 0.577 has *no units* and *no* current theorem tying it to joules/trit.
  The structural analogy (§4) is real; the numeric identification is not. **SPECULATION.**
- **"γ = the 2-threshold tax"** (the Law-1 "2-threshold" phrasing). No such identity
  exists; the 2-threshold is a *circuit* design fact, γ is a *number-theory* constant.
  **SPECULATION.**
- **"τ/6 is 'the' angle constant, therefore γ is also an angle."** τ/6 = 60° is DIRECT; γ
  is not an angle and has no 60° relationship. Do not extend the rotation result to γ.
  **SPECULATION.**
- **"Euler characteristic χ ties to the receiver" or "χ counts the Z₆ states."** χ is a
  *topology* invariant (genus/V−E+F); the 6 units are an *algebraic* group. Same name,
  different object. **SPECULATION** if asserted as a link.
- **"e^{iτ}=1 ⟹ the hex cell is a circle."** Euler's identity is a rotation statement; it
  does not turn the hexagon into a circle. The packing density τ/(4√3) already encodes the
  circle/hex relationship without any such move. **SPECULATION** if asserted as a link.

The two identities that *are* legitimate and DIRECT: **`b/ln b` minimized at `e`** (Law 3),
and **`e^{iτ/6} = ω`, `ω⁶ = 1`** (rotation). Everything else in the "Euler" family is either
a name-collision (§0), an analogy (§3.3, §4), or speculation (§7).

---

## Sources

- [Wikipedia — Kronecker limit formula](https://en.wikipedia.org/wiki/Kronecker_limit_formula) — the first limit formula quoted verbatim in §3.2.
- [Fungrim entry 204acd — η(e^{2πi/3})](https://fungrim.org/entry/204acd/) — the Dedekind-eta value at the Eisenstein point.
- [Wikipedia — Euler–Mascheroni constant](https://en.wikipedia.org/wiki/Euler%E2%80%93Mascheroni_constant) — γ definition, irrationality open.
- [Wikipedia — e (mathematical constant)](https://en.wikipedia.org/wiki/E_(mathematical_constant)) — e definition, radix economy.
- [Wikipedia — Dedekind eta function](https://en.wikipedia.org/wiki/Dedekind_eta_function) — η definition, special values.
- [Wikipedia — Euler characteristic](https://en.wikipedia.org/wiki/Euler_characteristic) — χ, Gauss–Bonnet.
- [Wikipedia — Euler's totient function](https://en.wikipedia.org/wiki/Euler%27s_totient_function) — φ(n).
- [Wikipedia — Euler–Lagrange equation](https://en.wikipedia.org/wiki/Euler%E2%80%93Lagrange_equation) — variational principle.
- mathlib `NumberTheory/Harmonic/EulerMascheroni.lean` — `Real.eulerMascheroniConstant`, `tendsto_harmonic_sub_log`, `1/2 < γ < 2/3` (local checkout: `proofs/lean-src/hexagon/.lake/packages/mathlib/`).
- mathlib `Analysis/Complex/Trigonometric.lean` — `Complex.exp_mul_I` (Euler's formula).

*Local framework files cross-referenced: `docs/ENERGY_LAWS.md`, `proofs/INDEX.md`,
`proofs/lean-src/hexagon/Hexagon/{Conventions,Rotation,Gauge,Haar,Packing,ChiSquareGauge,RadixEconomy}.lean`.*
