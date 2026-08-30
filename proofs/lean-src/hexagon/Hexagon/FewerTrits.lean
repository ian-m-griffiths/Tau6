/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# Fewer trits — ternary needs fewer symbols than binary

**Idea history:** the "ternary needs fewer symbols than binary" theorem: `k−1` trits
already encode `2^k` states for `k ≥ 3`, i.e. `2^k ≤ 3^(k−1)`. This is the *integer* form
of the radix-economy win — the real-number form `3/ln 3 < 2/ln 2` is proved in
`RadixEconomy.lean`, and the per-symbol density `2ⁿ < 3ⁿ` is proved in `TritPacking.lean`.
The namespace/address-space ratio `3ⁿ/2ⁿ` compounds geometrically as `(3/2)ⁿ`.

**Calibration:** DIRECT — integer power inequalities (counting argument: `3^(k−1)` trit
states must cover the `2^k` bit states).

**Status:** PROVED (2026-08-29) — `two_pow_le_three_pow_pred` (induction from `k = 3`,
`norm_num` base + `Nat.mul_le_mul_left`/`right` step + `omega` bookkeeping),
`fewer_trits_than_bits` (`omega`), `three_pow_div_two_pow_mono` (`field_simp`/`ring`).
Zero `sorry`.
-/

namespace Hexagon

/-! ## The headline: k−1 trits ≥ k bits -/

/-- `2^k ≤ 3^(k−1)` for `k ≥ 3`: k−1 trits carry at least as many states as k bits. -/
theorem two_pow_le_three_pow_pred (k : ℕ) (hk : 3 ≤ k) : 2 ^ k ≤ 3 ^ (k - 1) := by
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le hk
  clear hk
  -- goal: 2 ^ (3 + d) ≤ 3 ^ (3 + d - 1)
  induction d with
  | zero => norm_num
  | succ d ih =>
      -- ih : 2 ^ (3 + d) ≤ 3 ^ (3 + d - 1)
      have hpow2 : 3 + Nat.succ d = (3 + d) + 1 := by omega
      have hpow3 : (3 + Nat.succ d) - 1 = (3 + d - 1) + 1 := by omega
      calc
        2 ^ (3 + Nat.succ d) = 2 ^ ((3 + d) + 1) := by rw [hpow2]
        _ = 2 * 2 ^ (3 + d) := by rw [pow_succ']
        _ ≤ 2 * 3 ^ (3 + d - 1) := Nat.mul_le_mul_left 2 ih
        _ ≤ 3 * 3 ^ (3 + d - 1) := Nat.mul_le_mul_right _ (by norm_num : 2 ≤ 3)
        _ = 3 ^ ((3 + d - 1) + 1) := by rw [pow_succ']
        _ = 3 ^ ((3 + Nat.succ d) - 1) := by rw [hpow3]

/-! ## The trivial corollary: k−1 is strictly fewer than k -/

/-- `k−1 < k` for `k ≥ 3`: k−1 trits is strictly fewer symbols than k bits. -/
theorem fewer_trits_than_bits (k : ℕ) (hk : 3 ≤ k) : k - 1 < k := by
  omega

/-! ## The namespace ratio grows geometrically -/

/-- `3^(n+1)/2^(n+1) = (3/2)·(3^n/2^n)`: the ternary-to-binary state ratio compounds by 3/2. -/
theorem three_pow_div_two_pow_mono (n : ℕ) :
    (3 : ℚ) ^ (n + 1) / (2 : ℚ) ^ (n + 1) = ((3 : ℚ) / 2) * ((3 : ℚ) ^ n / (2 : ℚ) ^ n) := by
  rw [pow_succ, pow_succ]
  have h2n : (2 : ℚ) ^ n ≠ 0 := pow_ne_zero n (by norm_num)
  field_simp [h2n]

end Hexagon
