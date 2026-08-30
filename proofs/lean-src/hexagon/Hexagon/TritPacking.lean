/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# Trit packing — the best binary translation for ternary memory

**Idea history:** the ternary-memory survey: a trit needs `log₂3 ≈ 1.585` bits, so the
practical block translations pack 4 trits in 7 bits (81 ≤ 128) and 5 trits in 8 bits
(243 ≤ 256); the naive 2-bit-per-trit code (`TernaryCell.lean`, `PolarEncoding.lean`)
is the `n` trits → `2n` bits bound; and ternary is strictly denser than binary per symbol
(`2ⁿ < 3ⁿ`). 1807.06419 (log₂3 ≈ 1.585 bits/trit).

**Calibration:** DIRECT — integer power inequalities (counting argument: `3ⁿ` states must
fit in `2ᵏ` bit patterns, i.e. `3ⁿ ≤ 2ᵏ`).

**Status:** PROVED (2026-08-29) — `four_trits_fit_seven_bits`, `five_trits_fit_eight_bits`
(`norm_num`), `three_pow_le_two_pow_two_mul` (induction + `norm_num`/`omega`),
`two_pow_le_three_pow` and `three_pow_gt_two_pow` (induction + `Nat.mul_le_mul` /
`Nat.mul_lt_mul_of_pos_right`). Zero `sorry`.
-/

namespace Hexagon

/-! ## Concrete packing facts from the survey -/

/-- 4 trits fit in 7 bits: `3⁴ = 81 ≤ 2⁷ = 128`. -/
theorem four_trits_fit_seven_bits : (3 : ℕ) ^ 4 ≤ (2 : ℕ) ^ 7 := by
  norm_num

/-- 5 trits fit in 8 bits: `3⁵ = 243 ≤ 2⁸ = 256`. -/
theorem five_trits_fit_eight_bits : (3 : ℕ) ^ 5 ≤ (2 : ℕ) ^ 8 := by
  norm_num

/-! ## The general bound: n trits always fit in 2n bits -/

/-- `3^n ≤ 2^(2n)`: n trits always fit in 2n bits (the 2-bit-per-trit code). -/
theorem three_pow_le_two_pow_two_mul (n : ℕ) : 3 ^ n ≤ 2 ^ (2 * n) := by
  induction n with
  | zero => norm_num
  | succ n ih =>
      calc
        3 ^ (n + 1) = 3 * 3 ^ n := by rw [pow_succ']
        _ ≤ 3 * 2 ^ (2 * n) := Nat.mul_le_mul_left 3 ih
        _ ≤ 4 * 2 ^ (2 * n) := Nat.mul_le_mul_right _ (by norm_num : 3 ≤ 4)
        _ = 2 ^ 2 * 2 ^ (2 * n) := by norm_num
        _ = 2 ^ (2 + 2 * n) := by rw [pow_add]
        _ = 2 ^ (2 * (n + 1)) := by
            rw [show 2 * (n + 1) = 2 + 2 * n by omega]

/-! ## Ternary is strictly denser than binary per symbol -/

/-- `2^n ≤ 3^n` for every n (weak form, used for the strict bound). -/
theorem two_pow_le_three_pow (n : ℕ) : 2 ^ n ≤ 3 ^ n := by
  induction n with
  | zero => norm_num
  | succ n ih =>
      calc
        2 ^ (n + 1) = 2 * 2 ^ n := by rw [pow_succ']
        _ ≤ 3 * 3 ^ n := Nat.mul_le_mul (by norm_num : 2 ≤ 3) ih
        _ = 3 ^ (n + 1) := by rw [pow_succ']

/-- `2^n < 3^n` for n > 0: ternary is strictly denser than binary per symbol. -/
theorem three_pow_gt_two_pow (n : ℕ) (hn : 0 < n) : 2 ^ n < 3 ^ n := by
  cases n with
  | zero => omega
  | succ n =>
      calc
        2 ^ (n + 1) = 2 * 2 ^ n := by rw [pow_succ']
        _ ≤ 2 * 3 ^ n := Nat.mul_le_mul_left 2 (two_pow_le_three_pow n)
        _ < 3 * 3 ^ n :=
            Nat.mul_lt_mul_of_pos_right (by norm_num : 2 < 3) (Nat.pow_pos (by norm_num : 0 < 3))
        _ = 3 ^ (n + 1) := by rw [pow_succ']

end Hexagon
