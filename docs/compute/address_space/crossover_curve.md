# Address-Size Crossover Curve — ternary vs binary symbol count

*The exact points where ⌈log₃N⌉ trits beats ⌈log₂N⌉ bits for the same N addressable
items. 2026-08-30. Companion runnable: `scripts/address_crossover.py`.*

**Calibration.** Every number here is **DIRECT** (the exact output of integer
ceiling arithmetic — no floats are used to *compute* a trit or bit count) or
**DERIVED** (the labelled consequences of those formulas). Every integer power
inequality is cross-checked against a checked Lean theorem in
`proofs/lean-src/hexagon/Hexagon/`. Where the brief asserts a number that the
exact arithmetic does not support, it is flagged here rather than repeated.

---

## 0. The measuring stick

```
trits(N) = ⌈log₃ N⌉   — smallest k with 3^k ≥ N
 bits(N) = ⌈log₂ N⌉   — smallest j with 2^j ≥ N
```

Computed exactly (see the script):

```
bits(N)  = (N−1).bit_length()          # exact
trits(N) = number of 3^k ≤ N−1         # exact, precomputed powers of 3
```

Because `log₃N = log₂N / log₂3 = log₂N / 1.58496…`, `⌈log₃N⌉ ≤ ⌈log₂N⌉` always:
ternary never needs **more** symbols than binary, and needs **strictly fewer** for
almost every `N ≥ 3`.

---

## 1. The piecewise curve (exact, closed form)

The two symbol-count functions are piecewise constant, so the whole curve over
`N = 1 .. 2³²` is three regions:

```
trits < bits   ⇔   N = 3  OR  N ≥ 5
trits = bits   ⇔   N ∈ {1, 2, 4}
trits > bits   ⇔   never
```

The tie points are the only `N` where `⌈log₃N⌉ = ⌈log₂N⌉`:

| N | trits | bits | why it ties |
|---:|---:|---:|---|
| 1 | 0 | 0 | `2⁰ = 1 = 3⁰` (0 symbols) |
| 2 | 1 | 1 | `2¹ = 2`, `3¹ = 3` — both need exactly 1 symbol |
| 4 | 2 | 2 | `2² = 4`, `3² = 9` — both need exactly 2 symbols |

No other ties exist: for `k ≥ 3`, `3^(k−1) > 2^k`, so the trit-block and bit-block
of equal count never overlap (`FewerTrits.lean` `two_pow_le_three_pow_pred`).

The win regions begin:

```
N = 3        → 1 trit (3 cells)  vs 2 bits (4 cells)    first strict win
N = 5 … 8    → 2 trits (9 cells)  vs 3 bits (8 cells)    the pod's window
N = 9        → 2 trits (9 cells)  vs 4 bits (16 cells)
N = 10 … 16  → 3 trits (27 cells) vs 4 bits (16 cells)
N = 17 … 27  → 3 trits (27 cells) vs 5 bits (32 cells)
…
```

---

## 2. The crossover point — three framings, kept apart

The brief says "first N where ⌈log₃N⌉ first becomes < ⌈log₂N⌉ (answer: N=5)".
Exact integer arithmetic gives a finer picture; the three points are **distinct
facts**, and conflating them is the one error to avoid here.

1. **First strict win: `N = 3`** (DERIVED, exact). `⌈log₃3⌉ = 1`, `⌈log₂3⌉ = 2`,
   so ternary needs strictly fewer symbols at `N = 3` — one trit names three
   items where binary needs two bits. This is the literal answer to "first N
   with trits < bits".

2. **Start of the permanent win region: `N = 5`** (DERIVED, exact). `N = 3` is an
   *isolated* win — it is followed by the tie at `N = 4` (`2 trits = 2 bits`).
   From `N = 5` onward, `trits < bits` holds for **every** `N` (the ties at
   {1, 2, 4} are exhausted), so `N = 5` is the first `N` of the infinite tail
   where ternary wins forever. This is the only reading under which the brief's
   "N = 5" is exact.

3. **Capacity crossover: `n = 2 trits`** (DIRECT, Lean). The checked theorems
   compare *capacities* (`3ⁿ` vs `2ⁿ⁺¹`), not per-`N` symbol counts:

   - `JunctionMemory.lean` `three_pow_gt_two_pow_succ`: `2^(n+1) < 3^n` for `n ≥ 2`
     — from two trits up, `n` trits out-address `n+1` bits.
   - `JunctionMemory.lean` `three_pow_lt_two_pow_succ_one`: `3¹ < 2²`
     — one trit (3 cells) does **not** beat two bits (4 cells).

   So the capacity crossover is **exactly `n = 2`**: `2³ = 8 < 9 = 3²`, while
   `3¹ = 3 < 4 = 2²`. Two trits (9 cells) is the first width where ternary
   overtakes binary even with binary's extra digit of head start.

All three are true simultaneously: the first strict win *per item count* is
`N = 3`; the permanent win tail starts at `N = 5`; and the first width where
ternary's capacity beats binary-with-a-head-start is `n = 2` trits.

---

## 3. The asymptotic ratio — 1.585×

As `N → ∞`, the ceiling rounding dies out and the ratio approaches the exact
constant:

```
bits(N)/trits(N) = ⌈log₂N⌉/⌈log₃N⌉ → log₂N / (log₂N / log₂3) = log₂3 ≈ 1.5849625007
```

Convergence brackets the limit from both sides:

| N | trits | bits | bits/trits |
|---:|---:|---:|---:|
| `3¹ = 3` | 1 | 2 | 2.0000 |
| `3⁶ = 729` | 6 | 10 | 1.6667 |
| `3¹² = 531 441` (word) | 12 | 20 | 1.6667 |
| `3²¹ = 1.05×10¹⁰` | 21 | 34 | 1.6190 |
| `2²⁴ = 1.68×10⁷` | 16 | 24 | 1.5000 |
| `2³² = 4.29×10⁹` (u32) | 21 | 32 | 1.5238 |
| ↓ | | | ↓ |
| `N → ∞` | | | **1.58496…** |

i.e. ternary needs `log₃2 ≈ 0.631` symbols per binary symbol — **≈ 37% fewer
symbols** in the limit, or a **≈ 1.585×** binary-symbol-to-ternary-symbol ratio.

---

## 4. Actual Tau structure sizes

| structure | cells `N` | trits ⌈log₃N⌉ | bits ⌈log₂N⌉ | ratio bits/trits | saving |
|---|---:|---:|---:|---:|---:|
| **pod** (hex ball r=1) | 7 | **2** | 3 | 1.500 | 33.3% |
| **hex disk r=2** | 19 | **3** | 5 | 1.667 | 40.0% |
| **hex disk r=3** | 37 | **4** | 6 | 1.500 | 33.3% |
| **field store** (8×8) | 64 | **4** | 6 | 1.500 | 33.3% |
| **word** | 3¹² = 531 441 | **12** | 20 | 1.667 | 40.0% |
| **u32 box** | 2³² = 4 294 967 296 | **21** | 32 | 1.524 | 34.4% |

Read with the `1.585×` limit: every row sits at the finite rounding of that
constant (the script prints a `N±2` fine grid confirming each row is flat across
its neighborhood). The pod — the smallest non-trivial structure — already lives
on the winning side: `7` cells need `2` trits (namespace `9`) but `3` bits
(namespace `8`), exactly the `n = 2` capacity crossover.

---

## 5. Lean theorems cited

| theorem (file) | statement | role here |
|---|---|---|
| `JunctionMemory.lean` `three_pow_gt_two_pow_succ` | `2^(n+1) < 3^n` for `n ≥ 2` | capacity crossover at `n = 2` trits (DIRECT) |
| `JunctionMemory.lean` `three_pow_lt_two_pow_succ_one` | `3¹ < 2²` | no crossover at `n = 1` (DIRECT) |
| `FewerTrits.lean` `two_pow_le_three_pow_pred` | `2^k ≤ 3^(k−1)` for `k ≥ 3` | `k−1` trits ≥ `k` bits — why ties stop at `N = 4` (DIRECT) |
| `FewerTrits.lean` `fewer_trits_than_bits` | `k−1 < k` for `k ≥ 3` | strictly fewer symbols (DIRECT) |
| `FewerTrits.lean` `three_pow_div_two_pow_mono` | `3^(n+1)/2^(n+1) = (3/2)·(3^n/2^n)` | the `(3/2)ⁿ` compounding behind the limit (DIRECT) |

All five are `lake build`-green with zero `sorry` (see `proofs/INDEX.md`,
`proofs/lean-src/hexagon/Hexagon/JunctionMemory.lean`,
`FewerTrits.lean`).
