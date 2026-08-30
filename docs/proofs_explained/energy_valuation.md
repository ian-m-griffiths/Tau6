# The Energy & Valuation Cluster — a plain-English guide to the Lean proofs

This document explains seven modules in the Hexagon formal-verification project
(`proofs/lean-src/hexagon/Hexagon/`). They form one connected story: **how much energy a
ternary (three-state) information cell actually costs**, and the algebraic machinery —
the hex lattice, the Z₆ rotation symmetry, the χ² surprise, the lattice valuation — that
tells you *which* quantities are worth computing and *which register to store them in*.

Each module below follows the same four-part shape:

1. **What it proves** — every main theorem in plain English.
2. **Why** — the intuition and motivation (and where the physics/statistics connection lives).
3. **The method** — the proof strategy.
4. **Step-by-step** — a walkthrough of the 2–3 most important theorems.

Everything quoted here is *proved*: the files carry a `Status: PROVED` header and `lake build`
passes with zero `sorry` (the proving-agent rule is that a file with a `sorry` never earns
"proved"). The arithmetic lives in ℚ (exact rationals) or ℤ (integers), so no floating-point
rounding is ever smuggled into an argument.

---

## 1. `EnergyModel.lean` — the transfer energy splits into recoverable + dissipated parts

### What it proves

The file models the energy of **one physical transfer** in the ternary cell as a sum of three
terms, then proves three structural facts about that sum:

- **`recyclable_le_cap`** — the recyclable energy is at most the capacitive energy. Recycling
  can never hand back more than what was stored in the line capacitance; the diode and resistive
  terms are pure loss that you cannot get back.
- **`naive_dissipates`** — a *naive* cell (one with a real forward diode drop, `Vd > 0`) always
  dissipates strictly more than it stores: `E_cap < E_transfer` no matter what the capacitance holds.
- **`break_even`** — the break-even theorem. A ternary cell with push/pull cost `Et` and free null
  beats a binary baseline `Eb` in expectation **if and only if** the null probability `p0` exceeds
  `1 − Eb/Et`.
- **`real_break_even_needs` / `real_break_even_needs'`** — the same theorem with the real measured
  numbers plugged in: with `Et = 5.361 pJ` and `Eb ≈ 1.19 pJ`, ternary wins only if `p0 > 4171/5361
  ≈ 77.8%`.

### Why

This is where the **transport-vs-compute verdict lives**. The whole ternary-cell project began
with a hardware claim: "a polarity cell that pushes or pulls charge is cheaper than flipping a
binary bit." A circuit simulation (ngspice) *falsified* the naive version — the ternary push/pull
cost 5.36 pJ against 0.75 pJ for a binary bit — but *confirmed* two saving graces: the null (0)
state costs ≈ 0, and charge recycling recovers ≈ 50%.

`EnergyModel.lean` formalizes the *algebra* behind that verdict, independent of any particular
simulation. The insight is a clean separation of a transfer's energy into:

- **Recoverable** — `E_cap = ½·C·V²`, the charge sitting in the wire's capacitance. This is the
  part charge recycling can give back.
- **Irrecoverable** — `E_diode = I·Vd·t` (dropped across a diode) and `E_res = I²·R·t` (burnt in
  the wire's resistance). These are gone forever.

Once the energy is decomposed this way, "how cheap must push/pull get to beat binary?" becomes a
*one-line algebra question* — and that question's answer is the break-even probability `77.8%`.
That number is the file's verdict: no realistic workload is 78% nulls, so **you must lower `Et`
or recycle enough charge to cut the effective `Et`**.

### The method

Pure ℚ algebra over the rationals. The definitions are closed-form functions of the physical
knobs (`C, V, I, Vd, R, t`), and every theorem is a rearrangement proved by `field_simp`,
`linarith`, `nlinarith`, and `norm_num`. No analysis, no approximations — the sign conventions
(`I, Vd, R, t ≥ 0`) are carried as explicit hypotheses so the loss terms can never "go negative"
and cheat.

### Step-by-step

**`recyclable_le_cap`.** The claim is `E_cap ≤ E_transfer`, i.e. `E_cap ≤ E_cap + E_diode +
E_res`. Subtract `E_cap` from both sides and what remains to show is `0 ≤ E_diode + E_res`. But
`E_diode = I·Vd·t` is a product of three non-negatives, and `E_res = I²·R·t` is a product of a
square (`I² ≥ 0`) with two non-negatives. So both are `≥ 0`, and `linarith` closes it. The
physical reading: you can never recover more than you stored, because the two loss terms can only
add to the total, never subtract from it.

**`naive_dissipates`.** Now `Vd > 0` and `I > 0` and `t > 0` are *strict*. Then `E_diode =
I·Vd·t` is strictly positive (a product of three positives), while `E_res ≥ 0` (the `R ≥ 0`
assumption stops the resistive term from cancelling the diode loss). So `E_transfer = E_cap +
(positive) + (non-negative) > E_cap`. `nlinarith` finishes it. Reading: a real diode makes the
cell *fundamentally* lossy — it dissipates more than it stores, full stop.

**`break_even`.** Define the ternary average `ternary_avg = Et·(1 − p0)` (you only push/pull on
the non-null fraction of the workload) and the binary baseline `binary_equiv = Eb`. The theorem
is an *if-and-only-if*: `Et·(1 − p0) < Eb ⟺ p0 > 1 − Eb/Et`. One direction divides both sides of
`Et·(1−p0) < Eb` by the positive `Et` to get `1 − p0 < Eb/Et`, which rearranges to the target;
the other direction reverses it. The `hEt : 0 < Et` hypothesis is exactly what fixes the sign of
the division — flip it and the inequality direction would flip too. Reading: this is the *entire
verdict as algebra* — the break-even null probability is `1 − Eb/Et`, and every cost model reduces
to "is `p0` above or below that line?"

---

## 2. `WeightHex.lean` — the hex weight is sandwiched by the norm: √N ≤ wtHex ≤ N

### What it proves

This file reconstructs **Theorem 11** from the Eisenstein-codes paper (arXiv:2412.18328,
"On Codes over Eisenstein Integers"), a bound on the *hex weight* of an Eisenstein integer:

- **`norm_le_wtHex_sq`** — the integer form of the lower bound: `N(x) ≤ wtHex(x)²`. (Since
  `wtHex ≥ 0`, this is exactly the paper's `√N(x) ≤ wtHex(x)` without needing real square roots.)
- **`wtHex_le_norm`** — the upper bound: `wtHex(x) ≤ N(x)`.
- **`sqrt_norm_le_wtHex`** — the lower bound in its ℝ form, `√N(x) ≤ wtHex(x)`.
- **`thm11`** — the paper's statement verbatim over ℝ: `√N(x) ≤ wtHex(x) ≤ N(x)`.

Supporting lemmas include `norm_le_l1_sq` (the pointwise identity `N ≤ (|a|+|b|)²`),
`l1_le_norm_of_mul_nonneg`, `abs_a_le_norm`, `abs_b_le_norm`, and `abs_add_eq_sub_of_opposite`.

### Why

The Eisenstein integers are the numbers `a + bω` with `ω = e^(iπ/3)` (a 60° rotation). They live
on a **triangular lattice** — which is exactly the geometry of the Hexagon project, since
hexagons tile a triangular lattice. Two distances coexist on this lattice, and the whole point of
Theorem 11 is that they agree up to a factor:

- The **norm** `N(a+bω) = a²+ab+b²` — the *area* of the cell the number generates (it's the
  determinant of multiplication-by-`x`). This is the "Euclidean" notion of size.
- The **hex weight** `wtHex(x)` — the *minimum number of unit steps* you must walk, in the six
  directions of the lattice, to get from 0 to `x`. This is the "Manhattan / grid-walking" notion
  of distance: how many edges you actually traverse.

The bound `√N ≤ wtHex ≤ N` says the two notions track each other: the hex-walking distance is
never less than the straight-line (Euclidean) distance `√N`, and never more than the area `N`.
That sandwich is what makes the hex distance a *useful* metric — it's a cheap integer surrogate
for a real-valued Euclidean length. The file reproduces the paper's sanity check (Remark 12):
`wtHex(4+4ρ) = wtHex(3+4ρ) = 4` despite the norms `16 ≠ 13` — the weight is *not* a function of
the norm alone.

### The method

The hex weight is defined as a **minimum over the six units** (the six 60° rotations `±1, ±ω,
±ω²`): `wtHex(x) = min over the six units u of |(u·x).a| + |(u·x).b|`. Because multiplying by a
unit is a rotation, this is "among the six rotations of `x`, pick the one whose coordinates sum
smallest in absolute value." The proof then splits cleanly:

- **Lower bound** (`√N ≤ wtHex`): a pointwise identity `N(x) ≤ l1(x)²` holds for *every* associate
  (units have norm 1 and the norm is multiplicative, so rotation doesn't change `N`). Taking the
  minimum over units preserves the inequality.
- **Upper bound** (`wtHex ≤ N`): a **sign case analysis on `a·b`**. If `ab ≥ 0`, the unrotated
  representative already satisfies `|a|+|b| ≤ N`. If `ab < 0` (opposite signs), the `a+b` term
  cancels partially, so you rotate by `ω` or `ω²` to make one coordinate drop out, landing on
  `|a| ≤ N` or `|b| ≤ N`.

Tactics are `nlinarith`, `omega`, `ring`, and `Finset.min'` for the finite minimum.

### Step-by-step

**`norm_le_wtHex_sq` (the lower bound).** Unfold `wtHex` to its defining minimum; the minimum is
attained by *some* unit `u`, so `wtHex(x) = l1(u·x)` for that `u`. Now use multiplicativity of the
norm: `N(x) = N(u·x)` (because `N(u) = 1`). Finally apply the pointwise lemma `norm_le_l1_sq` to
`u·x`: `N(u·x) ≤ l1(u·x)²`. Chaining: `N(x) = N(u·x) ≤ l1(u·x)² = wtHex(x)²`. Clean and
structural — the lower bound is "the area never exceeds the squared walking-distance," and
rotation invariance does the heavy lifting.

**`wtHex_le_norm` (the upper bound).** Split on the sign of `a·b`:
- *Case `ab ≥ 0`.* The unrotated coordinates `(a,b)` already give `l1(x) = |a|+|b| ≤ N(x)` via
  `l1_le_norm_of_mul_nonneg`, so the minimum is at most that.
- *Case `ab < 0`.* The coordinates fight each other, so `|a+b|` is smaller than `|a|+|b|`. If
  `|b| ≤ |a|`, rotate by `ω`: `ω·x` has coordinates `(-b, a+b)`, and the helper
  `abs_add_eq_sub_of_opposite` shows `|a+b| = |a|−|b|`, making `l1(ω·x) = |a| ≤ N(x)` (via
  `abs_a_le_norm`). If instead `|a| < |b|`, rotate by `ω²` and symmetrically get `l1(ω²·x) = |b| ≤
  N(x)`. Either way, some rotation lands the weight at or below the norm, and the minimum can only
  be smaller.

**`thm11`.** Just the conjunction of the two bounds over ℝ. The lower bound over ℝ is obtained
from the integer `N ≤ wtHex²` by casting to ℝ and taking monotone square roots
(`Real.sqrt_le_sqrt`), using `wtHex_nonneg` to resolve `√(wtHex²) = wtHex`.

---

## 3. `EnergyVerdict.lean` — with the *real* measured numbers, ternary wins uniformly

### What it proves

The **headline verdict** of the whole energy story, using the fair-fight measured numbers
(push/pull = 1.20 pJ, null = 0.05 pJ, binary = 0.748 pJ/bit):

- **`two_trits_ge_three_bits`** — the integer fact `3² = 9 ≥ 8 = 2³`: two trits carry at least as
  much information as three bits (since a trit carries `log₂3 ≈ 1.585` bits, and `2·log₂3 > 3`).
- **`measured_trit_uniform`** — the uniform average cost is `(1.20 + 1.20 + 0.05)/3 = 49/60 ≈
  0.8167 pJ` per trit.
- **`ternary_wins_uniform`** — the verdict: `2 × 0.8167 < 3 × 0.748`, i.e. two trits cost strictly
  less than three binary bits at uniform distribution.
- **`ternary_margin`** — the exact margin: `3·binary_bit − 2·trit_uniform = 229/375 ≈ 0.611 pJ`,
  i.e. **~27% cheaper** per information group (~31% better per bit: 0.515 vs 0.748).

### Why

`EnergyModel.lean` established the *model* (and its pessimistic 77.8% break-even under the
naive 5.36 pJ cell). `EnergyVerdict.lean` is the *punchline*: once the cell is measured fairly —
and, crucially, once the null state is recognized as **data-bearing** (it costs only 0.05 pJ, the
receiver's cost, a 24× saving over a push/pull) — the picture flips. The uniform average over the
three states is already below binary, *before* any Zipf weighting.

The subtlety is `log₂3`, which is irrational. To keep the proof a pure ℚ inequality (no floating
point, no real analysis), the file replaces "a trit carries `log₂3` bits" with the *integer*
surrogate `3² ≥ 2³`: since `9 ≥ 8`, a group of **two trits** encodes at least as much as a group
of **three bits**. Then "ternary beats binary" becomes the clean rational comparison
`2·(49/60) < 3·(748/1000)`, provable by `norm_num` alone.

### The method

Finite exact rational arithmetic. Every quantity is a ℚ literal; every theorem is a closed-form
`norm_num` reduction of an explicit sum or difference. There is no induction, no case split, no
floating point — the verdict is a single algebraic comparison, and the "information" step is the
pure-integer observation `9 ≥ 8`.

### Step-by-step

**`two_trits_ge_three_bits`.** Trivial but load-bearing: `3^2 = 9` and `2^3 = 8`, so `9 ≥ 8`.
This is what lets the whole argument avoid `log₂3`.

**`measured_trit_uniform`.** `trit_uniform (6/5) (1/20)` unfolds to `(6/5 + 6/5 + 1/20)/3`.
Common-denominator arithmetic gives `49/60`. (1.20 pJ is `6/5`, 0.05 pJ is `1/20`.)

**`ternary_wins_uniform`.** Compute `2 × (49/60) = 49/30 ≈ 1.633` and `3 × (748/1000) = 2.244`.
Since `49/30 < 2.244`, two trits beat three bits. The margin `ternary_margin` subtracts them:
`2244/1000 − 49/30 = 229/375`. Everything reduces by `norm_num`.

---

## 4. `ValuationEnergy.lean` — the ternary energy is a lattice valuation (min + max = sum)

### What it proves

This file proves that the ternary cell's energy function is a **lattice valuation** in the precise
measure-theory sense (monotone + modular), and that the `tadd1` adder identity holds:

- **`min_add_max`** — **Lemma 212**, the `tadd1` identity: `min a b + max a b = a + b` for integers.
- **`tritVal_min` / `tritVal_max`** — the trit-level min/max mirror integer min/max under the
  balanced embedding `{-1, 0, +1}`.
- **`tritVal_min_add_max`** — Lemma 212 at the trit level: `tritVal(min t u) + tritVal(max t u) =
  tritVal t + tritVal u`.
- **`energy_min_max`** — the valuation property (modularity): `energy(min t u) + energy(max t u) =
  energy t + energy u`, checked over all 3×3 = 9 trit pairs.
- **`energy_eq_natAbs`** — the energy is the absolute value of the balanced value: 0 for null, 1
  for either polarity.
- **`energy_monotone`** — energy is monotone w.r.t. the **cost order** (null is the unique bottom).
- **`energy_zero_le`** — corollary: the null state is the unique energy minimum.
- **`energy_not_monotone_balanced`** — a **negative** result: energy is *not* monotone w.r.t. the
  balanced order (`neg < zero < pos`), with an explicit counterexample.

### Why

This is the **valuation-algebra** module. A "lattice valuation" is a function on a lattice
(a partially ordered set with meet `min` and join `max`) satisfying *modularity*:
`v(x ∧ y) + v(x ∨ y) = v(x) + v(y)`. Valuations are the bread and butter of measure theory and
geometry — a measure is a monotone valuation, and the modularity identity is what makes
inclusion–exclusion and Euler-characteristic arguments work. The file shows the ternary cell's
energy is *exactly* such an object.

There are two distinct orderings in play, and the file's most valuable contribution is
**disentangling them**:

- The **balanced order** (`neg < zero < pos`, i.e. `−1 < 0 < +1`) is the *numeric* order the
  trits carry.
- The **cost order** (`∅ ⊆ {push}`, `∅ ⊆ {pull}`) is the *hardware* order — the inclusion order
  on which wires are energized.

The draft spec asked for "energy is monotone," but in the balanced order that's **false** (energy
runs `1 → 0 → 1`). The corrected, proved fact is that energy is monotone in the *cost* order —
the null state is the unique bottom, and both polarities sit above it. Modularity, meanwhile,
holds in the balanced order exactly as drafted, and Lemma 212 (`min + max = sum`) is the identity
the actual `tadd1` adder cell relies on to compute a balanced ternary sum.

### The method

Finite exhaustion over a 3-element type. `Trit` has three constructors (`neg/zero/pos`), so every
claim about `trit_min`/`trit_max`/`energy` is proved by `cases t <;> cases u <;> decide` — i.e. by
checking all 9 pairs. The integer-level `min_add_max` is restated from mathlib's
`_root_.min_add_max`. The monotonicity proof does a small case analysis on the cost order's
disjunction.

### Step-by-step

**`min_add_max` (Lemma 212).** This is just mathlib's existing theorem restated for `ℤ` under the
project's name: `min a b + max a b = a + b` for any linearly ordered additive semigroup. It's the
algebraic identity `min + max = sum` — the exact reason an adder can recover the sum from the
min and max of its two inputs.

**`energy_min_max` (the valuation property).** Unfold `trit_min` and `trit_max`, then `cases t <;>
cases u <;> decide` checks all 9 pairs. For example take `t = .neg`, `u = .pos`: under the balanced
order `min neg pos = neg` and `max neg pos = pos`, so the left side is `energy neg + energy pos =
1 + 1 = 2`, and the right side is also `energy neg + energy pos = 2`. ✓. The point is that *every*
pair satisfies the modularity equation, which is precisely what "the energy is a valuation" means.

**`energy_monotone` (in the cost order) and `energy_not_monotone_balanced`.** The cost order is
defined as `trit_cost_le t u := t = .zero ∨ u ≠ .zero` — either `t` is the bottom, or `u` is not
the bottom (i.e. `u` is one of the two polarities). If `t = .zero`, then `energy t = 0 ≤ energy
u` (any natural is ≥ 0). Otherwise `u ≠ .zero`, so `u` is `neg` or `pos` and `energy u = 1 ≥
energy t` (since `energy ≤ 1` always). Done by case split. Then the *counterexample* theorem: the
balanced-order claim `∀ t u, trit_le t u → energy t ≤ energy u` is disproved by taking `t = .neg`,
`u = .zero` — `trit_le .neg .zero` holds (`−1 ≤ 0`), but `energy .neg = 1 > 0 = energy .zero`.
The proof is `intro h; apply h .neg .zero hneg; norm_num`, contradiction. This negative result is
kept deliberately in the file as a **correction to the draft spec**, so the record is honest about
*why* the monotonicity statement had to be fixed.

---

## 5. `ZipfEnergy.lean` — Zipf-weighted energy: null dominance makes the real saving > 1/3

### What it proves

`TernaryCell.lean` proved the *uniform* average is 2/3 (two states cost 1, null costs 0, so
`2/3` of a wire per trit, a 1/3 saving over binary's 1). This file proves that **when the null
state dominates — as it does under Zipf's law — the expected energy is far lower**:

- **`expected_energy_eq_one_minus_pzero`** — the expected energy equals `1 − p_zero`: the
  expectation is just `p_pos + p_neg`, which normalization turns into `1 − p_zero`.
- **`expected_lt_uniform`** — null-dominance ⇒ below uniform: if `p_zero > 1/3`, the expected
  energy is strictly below the uniform `2/3`.
- **`expected_concrete`** — a concrete Zipf-ish instance `(p_pos, p_zero, p_neg) = (1/4, 1/2,
  1/4)` has expected energy exactly `1/2`.
- **`concrete_below_uniform`** — that concrete instance is strictly below `2/3`.

### Why

This is the **Zipf connection**. Zipf's law says word (and symbol) frequencies follow a power law:
a handful of symbols are *very* common and a long tail is rare. For a ternary digit written to
real hardware, the analog is: the **null (0) state dominates** real data — most of the time you're
storing "nothing new," not pushing or pulling. The uniform-average `2/3` is a *pessimistic*
baseline that assumes each of the three states is equally likely; real, skew, power-law data
spends most of its time in the cheap state.

So the refinement is: instead of the uniform average, compute the **weighted expectation**
`p_pos·1 + p_zero·0 + p_neg·1`. The moment `p_zero > 1/3` (i.e. the null is more common than
uniform), the expectation drops below `2/3` — and the more Zipf-like the distribution (the more
`p_zero` approaches 1), the more dramatic the saving. The concrete instance `(1/4, 1/2, 1/4)`
already lands at `1/2`, a **50% saving** over binary rather than 33%. This is the *quantitative*
reason the ternary cell's advantage grows the more skew the workload is: "small numbers
(high-frequency nulls) outweigh the big ones."

### The method

A finite expectation computation. `expected_energy` is an explicit linear form over the three
probabilities; the key theorem reduces it via the normalization hypothesis `p_pos + p_zero +
p_neg = 1`. All arithmetic is ℚ with `rw`/`norm_num`/`linarith`.

### Step-by-step

**`expected_energy_eq_one_minus_pzero`.** Unfold `expected_energy` to `p_pos·energy(pos) +
p_zero·energy(zero) + p_neg·energy(neg)`, rewrite `energy(pos)=1`, `energy(zero)=0`,
`energy(neg)=1` to get `p_pos·1 + p_zero·0 + p_neg·1 = p_pos + p_neg`. Then the normalization
hypothesis `p_pos + p_zero + p_neg = 1` rearranges (via `linarith`) to `p_pos + p_neg = 1 −
p_zero`. Done. Reading: the expected energy is *entirely determined by the null probability* —
it's just the chance you're *not* in the free state.

**`expected_lt_uniform`.** Substitute the previous result: expected energy `= 1 − p_zero`. The
hypothesis `p_zero > 1/3` immediately gives `1 − p_zero < 1 − 1/3 = 2/3` by `linarith`. Reading:
the instant the null is more common than uniform, you beat the uniform average.

**`expected_concrete` and `concrete_below_uniform`.** Plug in `(1/4, 1/2, 1/4)`: the expectation
is `1/4·1 + 1/2·0 + 1/4·1 = 1/2`, and `1/2 < 2/3` by `norm_num`. This is the tangible "already
50% saving" witness — a single concrete power-law-ish distribution that outperforms the uniform
baseline.

---

## 6. `Haar.lean` — the counting measure is Haar for the Z₆ action (isotropy at measure level)

### What it proves

The Eisenstein lattice has six rotational symmetries — the units `±1, ±ω, ±ω²` — forming the
cyclic group **Z₆**. `Gauge.lean` already proved the *norm* is invariant under these rotations.
This file proves the *measure-theoretic* form of the same isotropy: the **counting measure** is
a **Haar measure** for the Z₆ action.

- **`unit_inv`** — every unit has a multiplicative inverse that is also a unit (Z₆ is a group).
- **`mul_unit_bijective`** — left multiplication by a unit is a bijection of the lattice.
- **`sum_invariant`** — the change-of-variables identity: summing `f(u·x)` over `x ∈ S` equals
  summing `f` over the image set `u·S`.
- **`measure_invariant_card`** — the cardinality (counting measure) of a finite set is unchanged
  by a unit: `|u·S| = |S|`.
- **`sum_invariant_of_invariant`** — on a set *stable* under the action (`u·S ⊆ S`), the naive
  translation-invariance statement `∑_{x∈S} f(u·x) = ∑_{x∈S} f(x)` holds.
- **`units_counting_normalized`** — the normalized counting measure on the six units is a
  probability measure: each unit gets weight `1/6`, summing to 1.

### Why

This is the **Haar / statistical-physics connection**. A Haar measure is the canonical measure
on a group that is *invariant under the group's own action* — the group-theoretic generalization
of "uniform random point." For a finite group (like Z₆), the Haar measure is just the **normalized
counting measure**: every element gets equal weight, and that weight is invariant under left- (or
right-) translation by any group element.

The Hexagon project's isotropy story runs in two registers:

- **Geometric:** the norm `N = a²+ab+b²` is invariant under the six rotations — proved in
  `Gauge.lean` as `norm_mul_unit` / `norm_unit_mul`.
- **Measure-theoretic:** the *counting measure* is invariant under the six rotations — proved
  here. This is the "flag theorem" of the synthesis: translation invariance *is* isotropy, stated
  at the level of measures rather than norms.

The two are different statements. The norm being invariant says *how big* a number is doesn't
change when you rotate it. The counting measure being invariant says *how many* numbers there are
— the density of the lattice — doesn't change when you rotate the whole lattice. The latter is
what lets you do "counting arguments" (probability, averaging, density estimates) uniformly over
the lattice without worrying about which rotation you chose.

There is also a subtle, honest correction embedded in the file: the **naive** statement
`∑_{x∈S} f(u·x) = ∑_{x∈S} f(x)` is *false* for an arbitrary finite set `S` (the left side sums
over the image `u·S`, not `S`). The file proves the *correct* change-of-variables form, and then
recovers the naive form **only** on stable sets (like the unit group itself, which is closed under
multiplication).

### The method

Finite group theory by `fin_cases`/`decide` exhaustion over the six units, plus `Finset.sum_*`
lemmas for the change-of-variables. `mul_unit_bijective` is proved by exhibiting the inverse from
`unit_inv` and using associativity. `sum_invariant` is `Finset.sum_image`, valid because
multiplication by a unit is injective.

### Step-by-step

**`unit_inv` and `mul_unit_bijective`.** `unit_inv` just lists the six units and their inverses,
checked by `fin_cases hu <;> decide`: `±1 ↔ ±1`, `ω = ⟨0,1⟩ ↔ −ω² = ⟨1,−1⟩`, `ω² = ⟨−1,1⟩ ↔ −ω =
⟨0,−1⟩`. (The header warns: `⟨−1,1⟩ · ⟨1,−1⟩ = ⟨0,1⟩ = ω`, not 1 — the inverse of `ω²` is `−ω`.)
Then `mul_unit_bijective` takes that inverse `v` and proves injectivity by the chain
`a₁ = (v·u)·a₁ = v·(u·a₁) = v·(u·a₂) = (v·u)·a₂ = a₂`, and surjectivity by mapping `b ↦ v·b`
(since `u·(v·b) = b`). This is the standard "group element acts by bijection" argument.

**`sum_invariant` and `measure_invariant_card`.** `sum_invariant` is `Finset.sum_image` with the
injectivity supplied by `mul_unit_bijective`: the image `u·S` re-indexes the sum exactly once
because the map is one-to-one, so `∑_{x∈S} f(u·x)` collects the same multiset of `f`-values as
`∑_{y∈u·S} f(y)`. `measure_invariant_card` is the same injectivity applied to
`Finset.card_image_of_injOn`, giving `|u·S| = |S|` — the counting measure is literally unchanged
by the rotation.

**`units_counting_normalized`.** The normalized measure assigns `1/6` to each of the six units.
`Finset.sum_const` turns `∑_{u∈units} 1/6` into `(units.card) · 1/6`, `units_card` says the card
is 6, and `norm_num` gives 1. So the six rotations are a genuine uniform probability space — the
Haar measure in its finite-group clothing.

---

## 7. `ChiSquareGauge.lean` — the fold δ is gauge-invariant; the χ² surprise is NOT

### What it proves

This file settles a "store which register?" question from the lattice rebuild, at the level of a
one-line algebra fact with real consequences:

- **`fold_gauge_invariant`** — the **fold** `δ = O/E − 1` is invariant under the count→probability
  gauge change (a common rescale `(O, E) ↦ (c·O, c·E)`, `c ≠ 0`).
- **`surprise_scales`** — the **χ² surprise** `(O−E)²/E` is *not* invariant: under the same
  rescale it scales by `c`.
- **`fold_eq_surprise_div`** — the register-ladder relation: the surprise equals `δ² · E` (the
  generic-ℚ form of `Registers.surprise_eq_delta_sq_mul_E`).

Together these pin down the principle **"store δ, not r":** δ survives the gauge, χ² does not.

### Why

This is the **χ²-ring connection**, and it answers a concrete engineering question. In the
lattice rebuild, an edge carries an observed count `O` and an expected count `E` (the
independence null `E = f(a)f(b)/T`). Two natural quantities you might *store* for that edge are:

- the **fold** `δ = O/E − 1` (the *multiplicative excess* over the null, re-centered at 0 — the
  Pearson-residual form `r/E`), and
- the **χ² surprise** `(O−E)²/E` (one summand of the ring `ring² = Σ(O−E)²/E`).

But "count" and "probability" are the *same data in different gauges*: a probability is just a
count renormalized by dividing everything by a common total `c`. The question is: which of δ or
χ² **survives** that renormalization? The answer is asymmetric, and it's the whole point of the
file:

- δ is a *ratio* `O/E`, so the common factor `c` cancels — δ is **gauge-invariant**.
- χ² is `(O−E)²/E`, a *difference squared over E*, so under `(O,E) ↦ (c·O, c·E)` it picks up a
  factor of `c` — χ² **scales**.

The consequence is the canonical-truth rule: the invariant is δ, so **store δ, not r** (where "r"
here means the χ²-style surprise magnitude). If you store the surprise, you are baking the gauge
factor `c` into your data, and any comparison across gauges (count vs probability, one corpus vs
another) silently breaks. If you store δ, you lose nothing (the surprise is *derived* from it via
`δ²·E`), and you keep a quantity that means the same thing in every gauge. This is the
measure-theory synthesis "probability = count renormalized" made precise.

### The method

Pure one-line ℚ algebra. `fold` and `surpriseGauge` are defined directly over ℚ (generic
versions of `Registers.δ`/`surprise`), and the three theorems are closed by `field_simp` (with the
`c ≠ 0` / `E ≠ 0` hypotheses) and `ring`. No induction, no case analysis — the entire module is
three algebraic identities.

### Step-by-step

**`fold_gauge_invariant`.** Compute `fold(c·O, c·E) = (c·O)/(c·E) − 1`. The `c` cancels in the
fraction (via `field_simp [hc]`), leaving `O/E − 1 = fold(O, E)`. Reading: δ is a *ratio*, and
ratios are blind to a common rescale — exactly why δ survives the count→probability gauge.

**`surprise_scales`.** Compute `surpriseGauge(c·O, c·E) = (c·O − c·E)²/(c·E) = (c·(O−E))²/(c·E)
= c²·(O−E)²/(c·E) = c·(O−E)²/E = c·surpriseGauge(O,E)`. The `c²` on top only *partially* cancels
the `c` on the bottom, leaving one factor of `c`. Reading: χ² is *not* a ratio — it scales
linearly with the gauge factor, so you cannot compare it across gauges without tracking `c`.

**`fold_eq_surprise_div`.** Unfold both definitions: `(O−E)²/E` vs `(O/E − 1)²·E`. Since
`O/E − 1 = (O−E)/E`, the right side is `(O−E)²/E² · E = (O−E)²/E`, matching the left (`field_simp
[hE]`). Reading: the surprise is **nothing but** the square of the fold, rescaled by `E`. So δ is
the primitive — χ² is derived from it — and storing δ loses nothing while keeping the invariant.

---

## How the seven modules hang together

- **`EnergyModel.lean`** sets up the *model*: recoverable vs dissipated energy, and the
  break-even null probability (77.8% under the naive cell).
- **`EnergyVerdict.lean`** delivers the *verdict* with real numbers: two trits beat three bits by
  ~27% at uniform distribution, *because* the null is data-bearing and cheap.
- **`ZipfEnergy.lean`** says the real saving is *even better*: real data is power-law skew, the
  null dominates, and the expected energy drops toward `1 − p_zero`.
- **`ValuationEnergy.lean`** says the energy is *algebraically well-behaved*: it's a lattice
  valuation (modular), and the `min + max = sum` identity is what the adder cell computes.
- **`WeightHex.lean`** and **`Haar.lean`** give the *geometry and symmetry*: the Eisenstein/hex
  lattice's two distances agree up to a sandwich (`√N ≤ wtHex ≤ N`), and the Z₆ rotations are an
  exact symmetry (Haar counting measure) under which the norm is invariant.
- **`ChiSquareGauge.lean`** closes the loop on *which number to store*: the fold δ is the
  gauge-invariant primitive; the χ² surprise is derived (`δ²·E`) and must not be stored raw.

The through-line is the same instinct repeated at every scale: **pick the quantity that is
invariant (the norm, the counting measure, the fold δ), derive everything else from it, and let
the free/low-cost state (the null) do the real work.**
