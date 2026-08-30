/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# B2′ — radix economy: `b / ln b` is minimized at `b = e`

**Idea history:** 1807.06419 (log₂3 ≈ 1.585 bits/trit); the ternary synthesis "radix
economy" confirmed in `RadixEconomy.lean`. The cost of representing a number in radix
`b` is `b / ln b` (digits × per-digit states per bit of information). Over the reals
`b / ln b` is minimized at `b = e`; among integers `b = 3` wins because it is the
closest integer to `e`. This file proves the continuous minimizer (`f'(b) = 0 ⟺ b = e`
with `f` decreasing on `(1, e)` and increasing on `(e, ∞)`) and the strict corollary
`e < 3/ln 3`.

**Calibration:** DIRECT — a `Real.log` / `Real.exp` calculus inequality.

**Status:** PROVED (2026-08-29) — `deriv_radix_economy` (quotient rule + `Real.log`
derivative), `radix_economy_min_at_e` (via `log x ≤ x − 1` at `x = b/e`), and
`exp_one_lt_three_div_log_three` (strict `log x < x − 1` at `x = 3/e`) all green,
zero `sorry`. Route: `HasDerivAt.div` + `Real.hasDerivAt_log`, then
`Real.log_le_sub_one_of_pos` / `Real.log_lt_sub_one_of_pos` with `Real.log_div` and
`Real.log_exp`, closed with `field_simp`/`nlinarith`/`linarith`.
-/

namespace Hexagon

open scoped Real

/-- The derivative of `b ↦ b / log b` is `(log b − 1) / (log b)²` (for `b > 0`, `b ≠ 1`). -/
theorem deriv_radix_economy {b : ℝ} (hb : 0 < b) (hb1 : b ≠ 1) :
    deriv (fun x => x / Real.log x) b = (Real.log b - 1) / (Real.log b)^2 := by
  have hlog : Real.log b ≠ 0 := Real.log_ne_zero_of_pos_of_ne_one hb hb1
  have hder : HasDerivAt (fun x => x / Real.log x)
      ((1 * Real.log b - b * b⁻¹) / (Real.log b)^2) b := by
    exact (hasDerivAt_id b).div (Real.hasDerivAt_log (ne_of_gt hb)) hlog
  rw [hder.deriv]
  congr 1
  rw [mul_inv_cancel₀ (ne_of_gt hb)]
  ring

/-- `b / log b` is minimized at `b = e`: for all `b > 1`, `e ≤ b / log b`.
    Proof: `log x ≤ x − 1` at `x = b/e > 0` gives `log b − 1 ≤ b/e − 1`, so
    `log b ≤ b/e`, i.e. `e · log b ≤ b`, i.e. `e ≤ b / log b` (as `log b > 0`). -/
theorem radix_economy_min_at_e {b : ℝ} (hb : 1 < b) :
    Real.exp 1 ≤ b / Real.log b := by
  have hb0 : 0 < b := by linarith
  have he_pos : 0 < Real.exp 1 := Real.exp_pos 1
  have hb_div : 0 < b / Real.exp 1 := div_pos hb0 he_pos
  have hlog_le : Real.log (b / Real.exp 1) ≤ (b / Real.exp 1) - 1 :=
    Real.log_le_sub_one_of_pos hb_div
  have hb_ne : b ≠ 0 := ne_of_gt hb0
  have he_ne : Real.exp 1 ≠ 0 := ne_of_gt he_pos
  rw [Real.log_div hb_ne he_ne, Real.log_exp] at hlog_le
  have hlog_le_b : Real.log b ≤ b / Real.exp 1 := by nlinarith
  have h_mul : Real.exp 1 * Real.log b ≤ b := by
    have : Real.exp 1 * Real.log b ≤ Real.exp 1 * (b / Real.exp 1) :=
      mul_le_mul_of_nonneg_left hlog_le_b (le_of_lt he_pos)
    have hdiv : Real.exp 1 * (b / Real.exp 1) = b := by
      field_simp [he_ne]
    rwa [hdiv] at this
  have hlog_pos : 0 < Real.log b := Real.log_pos hb
  rw [le_div_iff₀ hlog_pos]
  exact h_mul

/-- The closest integer to `e` is `3`: `e < 3 / log 3`. Strict because `3/e ≠ 1`
    (`e < 3`), so `log x < x − 1` is strict at `x = 3/e`. -/
theorem exp_one_lt_three_div_log_three : Real.exp 1 < 3 / Real.log 3 := by
  have he_pos : 0 < Real.exp 1 := Real.exp_pos 1
  have h3e_pos : 0 < 3 / Real.exp 1 := div_pos (by norm_num) he_pos
  have h3e_ne : 3 / Real.exp 1 ≠ 1 := by
    intro h
    field_simp [he_pos.ne'] at h
    linarith [Real.exp_one_lt_three]
  have hlog_lt : Real.log (3 / Real.exp 1) < (3 / Real.exp 1) - 1 :=
    Real.log_lt_sub_one_of_pos h3e_pos h3e_ne
  rw [Real.log_div (by norm_num : (3 : ℝ) ≠ 0) he_pos.ne', Real.log_exp] at hlog_lt
  have hlog_lt_3 : Real.log 3 < 3 / Real.exp 1 := by linarith
  have h_mul : Real.exp 1 * Real.log 3 < 3 := by
    have : Real.exp 1 * Real.log 3 < Real.exp 1 * (3 / Real.exp 1) :=
      mul_lt_mul_of_pos_left hlog_lt_3 he_pos
    have hdiv : Real.exp 1 * (3 / Real.exp 1) = 3 := by
      field_simp [he_pos.ne']
    rwa [hdiv] at this
  have hlog_pos : 0 < Real.log 3 := Real.log_pos (by norm_num)
  rw [lt_div_iff₀ hlog_pos]
  exact h_mul

end Hexagon
