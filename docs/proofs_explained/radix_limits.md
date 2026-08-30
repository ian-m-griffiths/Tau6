# Radix limits — what the Lean proofs actually prove

This page explains four Lean modules from `proofs/lean-src/hexagon/Hexagon/` that,
together, settle a single question: **for a computing substrate where each distinct
voltage/threshold level costs the same, which number base is best?**

The chain of results reads like a three-act argument:

1. `RadixEconomy.lean` — ternary is the most *efficient* radix for *storing* a number.
2. `RadixMin.lean` — why: radix economy `b / ln b` is minimized at `b = e`, and 3 is the nearest integer.
3. `ThresholdLowerBound.lean` — **but** ternary costs 1.26× more *per bit* when you count the hardware thresholds that distinguish digit levels. This is the decisive, sobering result.
4. `Signature.lean` — the four "signatures" of the underlying 2D algebras, and what separates them.

The punchline, stated plainly before we begin: **ternary wins on paper (radix economy)
and loses in silicon (threshold count).** On any substrate where a threshold costs
uniformly, ternary compute cannot beat binary per bit — and the proof gives the exact
factor: `2·ln 2 / ln 3 ≈ 1.26`.

---

## 1. RadixEconomy.lean

### What it proves

Three main theorems, all about the **radix economy** of a base — the cost of writing
down a number as *number of digits × number of symbols per digit*. For radix `b`, this
cost is `b / ln b`:

- **`ternary_beats_binary`** — `3 / ln 3 < 2 / ln 2`. Ternary is more economical than
  binary: representing a number in base 3 needs fewer digit·symbol "dollars" than in
  base 2. This is the classic "base-3 is the most efficient integer radix" result.
- **`quaternary_ties_binary`** — `4 / ln 4 = 2 / ln 2`. Base 4 is *exactly as
  economical* as base 2 (because `ln 4 = 2 ln 2`, the extra symbol per digit is exactly
  cancelled by having half as many digits). This "ties" fact is what forces the
  integer winner to be 3 rather than 4.
- **`bits_per_trit_gt_one`** — `1 < ln 3 / ln 2`. A trit carries more than one bit of
  information (in fact `log₂ 3 ≈ 1.585` bits). This is the "bonus" fact that makes
  ternary *look* attractive: each symbol packs more information than a bit does.

### Why

The motivation is the long-running "ternary synthesis" thread in the project's idea
history (arXiv 1807.06419 is cited, `log₂ 3 ≈ 1.585` bits/trit). The intuitive claim —
"ternary grows faster than binary" — is true *as a statement about information
density*. A trit holds 1.585× the information of a bit, so for a fixed number of
digits, base 3 reaches bigger numbers. The whole point of the module is to put that
intuition on a checked, provable footing: to show the *storage* side of the story is
solidly ternary-favouring.

> Note the scope discipline here: this module proves **only the radix-economy
> inequality**, not that ternary is "better" for computing. That distinction is exactly
> what `ThresholdLowerBound.lean` exists to draw.

### The method

Pure `Real.log` arithmetic — no calculus needed in this file. The proof strategy is:

1. Rewrite `log 8`, `log 9`, `log 4` as integer multiples of `log 2` / `log 3` using
   `Real.log_pow` (since `8 = 2³`, `9 = 3²`, `4 = 2²`).
2. Turn the target inequality `3 / ln 3 < 2 / ln 2` into `3·ln 2 < 2·ln 3`
   (cross-multiply by the positive product `ln 2 · ln 3` via `div_lt_div_iff₀`).
3. Observe that `3·ln 2 = ln 8` and `2·ln 3 = ln 9`, so the claim reduces to
   `ln 8 < ln 9`, which is `8 < 9` because `ln` is strictly increasing
   (`Real.log_lt_log`).

### Step-by-step (for `ternary_beats_binary`)

1. **Establish the log identities.** Private lemmas `log_8`, `log_9`, `log_4` rewrite
   `ln(2³)`, `ln(3²)`, `ln(2²)` into `3·ln 2`, `2·ln 3`, `2·ln 2` respectively. These
   let the proof move between "log of a number" and "multiple of a log".
2. **Prove the core inequality** `three_log_two_lt_two_log_three`: `3·ln 2 < 2·ln 3`.
   Both sides are rewritten to `ln 8` and `ln 9`; then `Real.log_lt_log` applies
   because `8 < 9` and both are positive.
3. **Cross-multiply to the desired form.** The goal is `3 / ln 3 < 2 / ln 2`. Using
   `div_lt_div_iff₀` with `log_three_pos` and `log_two_pos` (both logs are positive,
   since 3 > 1 and 2 > 1) turns it into exactly the core inequality. Done.

The other two theorems are the same flavour: `quaternary_ties_binary` substitutes
`ln 4 = 2 ln 2` and cancels via `field_simp`; `bits_per_trit_gt_one` rewrites
`1 < ln 3 / ln 2` into `ln 2 < ln 3` via `one_lt_div`.

---

## 2. RadixMin.lean

### What it proves

The *continuous* version of the story — where radix economy `f(b) = b / ln b` actually
attains its minimum:

- **`deriv_radix_economy`** — for `b > 0, b ≠ 1`, the derivative of `b ↦ b / ln b` is
  `(ln b − 1) / (ln b)²`.
- **`radix_economy_min_at_e`** — for every `b > 1`, `e ≤ b / ln b`. The function
  `b / ln b` is globally minimized at `b = e` (Euler's number). Equivalently, no real
  base beats `e` at radix economy.
- **`exp_one_lt_three_div_log_three`** — `e < 3 / ln 3`. Strict. This is the
  clean corollary that **3 is the closest integer to `e`** (since `e ≈ 2.718`, the
  nearest integer is 3, not 2), which is *why* ternary wins among integer bases.

### Why

`RadixEconomy.lean` proved `3/ln 3 < 2/ln 2` by pure log fiddling, but it never said
*why* 3 is special. This module gives the reason: the economy function has a calculus
minimum, it sits at `e`, and 3 is the integer hugging that minimum. It converts "3
happens to beat 2" into "3 beats 2 *because* 3 is the nearest integer to the true
continuous optimum `e`". That's a stronger, more explanatory claim — and it needs real
calculus (a derivative, monotonicity on either side of `e`).

### The method

Two-pronged calculus:

1. **Derivative computation** via the quotient rule — `HasDerivAt.div` applied to
   `hasDerivAt_id` and `Real.hasDerivAt_log` — closed with `field_simp`/`ring`.
2. **The global minimum** via the elementary inequality `ln x ≤ x − 1` (and its strict
   form `ln x < x − 1` for `x ≠ 1`), applied at `x = b/e`. This is a standard
   log-bound trick: rather than showing monotonicity directly, it squeezes `ln b`
   against `b/e` and multiplies through.

### Step-by-step (for `radix_economy_min_at_e`)

The theorem says: given `b > 1`, show `e ≤ b / ln b`.

1. **Apply the log bound.** `Real.log_le_sub_one_of_pos` gives `ln x ≤ x − 1` for any
   `x > 0`. Substitute `x = b / e` (positive, since `b > 0` and `e > 0`):
   `ln(b/e) ≤ (b/e) − 1`.
2. **Unpack the left side.** `ln(b/e) = ln b − ln e = ln b − 1` (via `Real.log_div`
   and `Real.log_exp`). So the bound becomes `ln b − 1 ≤ b/e − 1`, i.e. `ln b ≤ b/e`.
3. **Multiply through by `e`.** Since `e > 0`, `e·ln b ≤ b`.
4. **Divide by `ln b`.** Since `b > 1`, `ln b > 0`, so `e ≤ b / ln b` — exactly the
   goal (`Real.exp 1` *is* `e`).

`exp_one_lt_three_div_log_three` runs the *strict* twin (`Real.log_lt_sub_one_of_pos`)
at `x = 3/e`. Strictness needs `3/e ≠ 1`, which the proof discharges from
`Real.exp_one_lt_three` (`e < 3`). The result `e < 3/ln 3` is what pins the integer
winner at 3: combined with `radix_economy_min_at_e`, it says 3's cost is *above* the
continuous optimum but — as `RadixEconomy` showed — *below* 2's cost.

---

## 3. ThresholdLowerBound.lean  ← the decisive result

### What it proves

This is the counterweight to the first two modules, and the one that matters for
*actually building* hardware. It changes the cost model from **storage** (radix
economy) to **compute thresholds**: to distinguish `b` ordered voltage levels you need
`b − 1` threshold comparators, and a radix-`b` symbol carries `ln b` information, so
the threshold cost per bit is

```
f(b) = (b − 1) / ln b
```

The module proves:

- **`deriv_threshold_per_bit`** — `f'(b) = (ln b − 1 + b⁻¹) / (ln b)²` for `b > 0, b ≠ 1`.
- **`deriv_threshold_per_bit_pos`** — for `b > 1`, this derivative is strictly positive.
- **`threshold_per_bit_mono`** — `f` is **strictly increasing** on `(1, ∞)`.
- **`binary_min_threshold_per_bit`** — **the main theorem**: for any radix `b ≥ 2`,
  `1 / ln 2 ≤ (b − 1) / ln b`. Binary (`b = 2`) minimizes thresholds-per-bit.
- **`ternary_worse_than_binary`** — `2 / ln 3 > 1 / ln 2`. Ternary is strictly worse
  than binary per bit.
- **`ternary_binary_ratio`** — `(2/ln 3) / (1/ln 2) = 2·ln 2 / ln 3`. The clean ratio.
- **`ternary_binary_ratio_lt_two`** — `2·ln 2 / ln 3 < 2`. Ternary is *less than twice*
  as bad as binary (a precise upper bound on the damage).

Numerically: `2·ln 2 / ln 3 ≈ 2 × 0.6931 / 1.0986 ≈ 1.2619`, so **ternary's
threshold cost per bit is ≈ 1.26× binary's** — the "2-threshold tax."

### Why (the core, honest verdict)

This is the theorem that says the hard thing. The first two modules proved ternary is
the *storage* winner — more information per symbol, cheapest radix economy. But storing
a trit is not the same as *reading* one. A trit is an ordered choice among **three**
levels, and to tell three levels apart you need **two** threshold comparators; a bit
needs only **one**. So every ternary digit costs twice as many thresholds as a binary
digit, while only carrying `log₂ 3 ≈ 1.585` (not 2) bits.

The verdict is an honest one, and it cuts against the project's earlier optimism:
**on a substrate where each threshold costs uniformly, ternary compute cannot beat
binary per bit — by a proved factor of ≈ 1.26×.** There is no escape hatch here; the
monotonicity result says adding a third level *always* costs more per bit than the
information it adds, for every base above 2. Binary is the floor; ternary is the first
loser above the floor.

That last clause matters: `ternary_binary_ratio_lt_two` caps the damage at "less than
2×", which is the precise sense in which the 2-threshold tax is *real but bounded* —
ternary doesn't collapse to twice the cost, it's 1.26×. The result is a genuine
*lower bound* (a floor), not a rough heuristic: it is a proved inequality holding for
every `b ≥ 2`.

### The method

Same calculus toolbox as `RadixMin.lean`, but the sign conclusion flips the story:

1. **Quotient-rule derivative** (`HasDerivAt.div` on `(x−1)` and `ln x`), closed with
   `field_simp`/`ring`.
2. **A strict log inequality** `1 − b⁻¹ < ln b` (private lemma `one_sub_inv_lt_log`),
   obtained from `ln x < x − 1` at `x = b⁻¹` (for `b > 1`, `b⁻¹ ∈ (0,1)`, so the strict
   form applies).
3. **Positivity of the derivative** — numerator `ln b − 1 + b⁻¹ = ln b − (1 − b⁻¹) > 0`
   and denominator `(ln b)² > 0`.
4. **Monotonicity** via `strictMonoOn_of_deriv_pos` on the convex, open set `(1, ∞)`.
5. **Integer conclusion** — monotonicity evaluated at `2` and any `b ≥ 2` gives the
   lower bound, with `norm_num` cleaning the `2 − 1 = 1` residue.

### Step-by-step (the decisive chain)

**Step A — compute the derivative** (`deriv_threshold_per_bit`). For `f(b) = (b−1)/ln b`,
the quotient rule gives `(1·ln b − (b−1)·b⁻¹) / (ln b)²`, which simplifies to
`(ln b − 1 + b⁻¹) / (ln b)²`.

**Step B — show it's positive** (`deriv_threshold_per_bit_pos`, given `b > 1`). The
denominator `(ln b)²` is positive (a square of a nonzero). For the numerator, the proof
establishes `1 − b⁻¹ < ln b`:

- Apply the strict bound `ln x < x − 1` at `x = b⁻¹`: `ln(b⁻¹) < b⁻¹ − 1`.
- `ln(b⁻¹) = −ln b` (`Real.log_inv`), so `−ln b < b⁻¹ − 1`, i.e. `1 − b⁻¹ < ln b`.

Rearranging, `ln b − 1 + b⁻¹ = ln b − (1 − b⁻¹) > 0`. So numerator and denominator are
both positive, hence `f'(b) > 0`.

**Step C — monotonicity** (`threshold_per_bit_mono`). `strictMonoOn_of_deriv_pos` needs
two things: continuity of `f` on `(1, ∞)` (proved by `ContinuousOn.div`, noting `ln x`
never vanishes there) and the strictly positive derivative from Step B on the open
interior. Conclusion: `f` strictly increases on `(1, ∞)`.

**Step D — binary is the minimum** (`binary_min_threshold_per_bit`, given `b ≥ 2`).
Since `f` is monotone on `(1, ∞)`, and both `2` and `b` lie in `(1, ∞)` with `2 ≤ b`,
we get `f(2) ≤ f(b)` — i.e. `(2−1)/ln 2 ≤ (b−1)/ln b`, i.e. `1/ln 2 ≤ (b−1)/ln b`.
Binary's cost is a lower bound for *every* radix ≥ 2.

**Step E — ternary is worse** (`ternary_worse_than_binary`). Monotonicity with `2 < 3`
gives `f(2) < f(3)`, i.e. `1/ln 2 < 2/ln 3` — ternary strictly worse than binary.

**Step F — the exact tax** (`ternary_binary_ratio` and `ternary_binary_ratio_lt_two`).
The ratio `(2/ln 3)/(1/ln 2)` simplifies (`field_simp`) to `2·ln 2 / ln 3 ≈ 1.26`. The
final theorem shows `2·ln 2 / ln 3 < 2` by the trivial `ln 2 < ln 3` (from `2 < 3`),
so the tax is strictly between 1 and 2 — bounded, but strictly greater than 1.

Taken together, Steps D–F are the complete verdict: **binary minimizes thresholds per
bit; ternary pays a proved ≈ 1.26× premium; and that premium is strictly sub-2×.**

---

## 4. Signature.lean

### What it proves

A side-quest that classifies the **four 2D composition algebras** — the four possible
"signatures" of the imaginary unit `i` — and what distinguishes each. All are defined
on integer pairs `(a, b)` with a different multiplication rule:

- **Gaussian** (`i² = −1`, i.e. ℂ / Gaussian integers) — `gaussianMul`,
  `gaussianNorm = a² + b²`.
- **Split-complex** (`j² = +1`) — `splitMul`.
- **Dual numbers** (`ε² = 0`) — `dualMul`.
- **Eisenstein** (`ω² = ω − 1`, i.e. `ω = e^{iπ/3}`) — imported from `Conventions`.

The theorems:

- **`gaussianUnits_card`** — the Gaussian units are `{(1,0),(−1,0),(0,1),(0,−1)}`,
  exactly 4 of them (the cyclic group **Z₄**).
- **`gaussianNorm_unit_eq_one`** — every Gaussian unit has norm `a² + b² = 1` (it sits
  on the unit circle).
- **`split_zero_divisor`** — the split-complex numbers have **zero divisors**:
  `(1,1)·(1,−1) = (0,0)`, with both factors nonzero. So split-complex is *not* an
  integral domain.
- **`dual_nilpotent`** — the dual numbers have a **nilpotent**: `(0,1)² = (0,0)` with
  `(0,1) ≠ (0,0)`.
- **`dualUnits_card`** — the dual units are `{(1,0),(−1,0)}`, exactly 2 (the group **Z₂**).
- **`eisenstein_units_card`** — the Eisenstein units number **6** (the group **Z₆**),
  restated from the already-proved `Hexagon.units_card` (`±1, ±ω, ±ω²`).
- **`signatures_distinguished`** — the comparison assembled: Gaussian 4, dual 2,
  Eisenstein 6.

### Why

This matters for the Tau/hexagon architecture because these four signatures are the
candidate coordinate systems for a 2D lattice of "trits" or "cells" — the
`gauge_int.rs` `Signature` enum (Gaussian / Eisenstein / Minkowski / Null) behind the
rebuild. Before committing to a geometry, you need to know which algebra you are
living in, because they have sharply different algebraic health:

- Gaussian and Eisenstein are **integral domains** (no zero divisors) — the "clean"
  cases where you can do division and Euclidean algorithms.
- Split-complex has **zero divisors** (two nonzero things multiply to zero) — division
  breaks.
- Dual numbers are **nilpotent** (a nonzero element squares to zero) — infinitesimal
  geometry, but again division breaks.

The upshot in the file's own conclusion: **Eisenstein (Z₆) and Gaussian (Z₄) are the
two integral-domain cases** — and of those, Eisenstein has the richer unit group (six
60° rotations vs four 90° rotations). That extra rotational symmetry is precisely what
a *hexagonal* (six-fold) lattice needs, which is why the Eisenstein signature is the
project's favoured choice.

### The method

Finite ring theory, almost entirely decidable by brute force:

- `decide` for the cardinality claims (`gaussianUnits_card`, `dualUnits_card`) — Lean
  just enumerates the finite sets.
- `norm_num` / `fin_cases`-style case-splitting for the algebraic identities
  (`split_zero_divisor`, `dual_nilpotent`) and for `gaussianNorm_unit_eq_one` (split on
  the four possible unit values, then `norm_num`).
- Import of the already-proved Eisenstein unit facts (`Hexagon.units_card`) rather than
  re-proving them.

### Step-by-step (for `split_zero_divisor`)

The theorem claims `splitMul (1,1) (1,−1) = (0,0)`, *and* both inputs are nonzero.

1. **Compute the product.** Unfolding `splitMul`, `(a,b)·(c,d) = (ac + bd, ad + bc)`,
   so `(1,1)·(1,−1) = (1·1 + 1·(−1), 1·(−1) + 1·1) = (0, 0)`. `norm_num` closes this
   instantly.
2. **Show nonzero-ness.** `(1,1) ≠ (0,0)` and `(1,−1) ≠ (0,0)` are both `decide` (the
   pairs are literally unequal).

Two lines of proof, but the content is real: it exhibits an explicit pair of nonzero
elements whose product vanishes — the *definition* of a zero divisor — and thereby
proves the split-complex algebra is not a field, not even an integral domain.

---

## The overall arc

| Module | Cost model | Winner | Key constant |
|---|---|---|---|
| `RadixEconomy.lean` | `b / ln b` (digits × symbols) | **ternary** | `log₂ 3 ≈ 1.585` bits/trit |
| `RadixMin.lean` | same, over reals | **`b = e`**, nearest integer 3 | `e ≈ 2.718` |
| `ThresholdLowerBound.lean` | `(b − 1) / ln b` (thresholds/bit) | **binary** | `2·ln 2/ln 3 ≈ 1.26` |
| `Signature.lean` | (algebra classification, not a cost) | **Eisenstein (Z₆) / Gaussian (Z₄)** | unit groups 6 / 4 / 2 / 6 |

The two middle modules prove a genuine tension and resolve it. Radix economy is
minimized at `e`, so ternary is the best *integer* for *storing* information. But
threshold cost is minimized at `b = 2`, so binary is the best integer for *computing*
per bit — and ternary pays a proved, bounded ≈ 1.26× tax for its third level. The
"1.26× floor" is the mathematical fact that any ternary hardware design must confront:
you can win on storage density, but you cannot win on threshold economics.
