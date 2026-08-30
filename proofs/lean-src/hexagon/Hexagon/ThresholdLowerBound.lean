/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# B2″ — compute threshold lower bound: binary minimizes thresholds-per-bit

**Idea history:** the companion to `RadixMin.lean`. To distinguish `b` ordered levels
you need `b − 1` thresholds, and a radix-`b` symbol carries `ln b` information, so the
threshold cost per bit is `f(b) = (b − 1) / ln b`. This file proves `f` is strictly
increasing for `b > 1`, hence **binary (b = 2) minimizes thresholds-per-bit**, and ternary
(b = 3) is `(2/ln 3)/(1/ln 2) = 2·ln 2/ln 3 ≈ 1.26×` worse. This is the formal
"2-threshold tax": on a substrate where each threshold costs uniformly, ternary compute
cannot beat binary per bit.

**Calibration:** DIRECT — a `Real.log` / `Real.exp` calculus inequality.

**Status:** PROVED (2026-08-29) — `deriv_threshold_per_bit` (quotient rule), the positivity
`deriv_threshold_per_bit_pos` (from `Real.log_lt_sub_one_of_pos` at `x = b⁻¹`), monotonicity
`threshold_per_bit_mono` (via `strictMonoOn_of_deriv_pos`), the integer lower bound
`binary_min_threshold_per_bit`, and the strict corollary `ternary_worse_than_binary` all
green, zero `sorry`. Route: `HasDerivAt.div` + `Real.hasDerivAt_log`, then `field_simp`/`ring`
and `linarith`.
-/

namespace Hexagon

open scoped Real

/-- The derivative of `b ↦ (b − 1) / log b` is `(log b − 1 + b⁻¹) / (log b)²`
    (for `b > 0`, `b ≠ 1`). -/
theorem deriv_threshold_per_bit {b : ℝ} (hb : 0 < b) (hb1 : b ≠ 1) :
    deriv (fun x => (x - 1) / Real.log x) b =
      (Real.log b - 1 + b⁻¹) / (Real.log b)^2 := by
  have hlog : Real.log b ≠ 0 := Real.log_ne_zero_of_pos_of_ne_one hb hb1
  have hder : HasDerivAt (fun x => (x - 1) / Real.log x)
      ((1 * Real.log b - (b - 1) * b⁻¹) / (Real.log b)^2) b := by
    exact ((hasDerivAt_id b).sub_const 1).div (Real.hasDerivAt_log (ne_of_gt hb)) hlog
  rw [hder.deriv]
  congr 1
  field_simp [ne_of_gt hb]
  ring

/-- The strict log bound `1 − b⁻¹ < log b` for `1 < b`, derived from
    `log x < x − 1` applied at `x = b⁻¹` (which is in `(0,1)`, so `b⁻¹ ≠ 1`). -/
private lemma one_sub_inv_lt_log {b : ℝ} (hb : 1 < b) : 1 - b⁻¹ < Real.log b := by
  have hb0 : 0 < b := by linarith
  have h_inv : 0 < b⁻¹ := inv_pos.2 hb0
  have h_inv_ne : b⁻¹ ≠ 1 := by
    intro h
    have hb_eq : b = 1 := by
      rw [← mul_inv_cancel₀ (ne_of_gt hb0), h, mul_one]
    linarith
  have hlog_inv : Real.log b⁻¹ < b⁻¹ - 1 := Real.log_lt_sub_one_of_pos h_inv h_inv_ne
  rw [Real.log_inv] at hlog_inv
  linarith

/-- The derivative of `b ↦ (b − 1) / log b` is strictly positive for `b > 1`: both the
    numerator `log b − 1 + b⁻¹` (which is `log b − (1 − b⁻¹) > 0`) and the denominator
    `(log b)²` are positive. -/
theorem deriv_threshold_per_bit_pos {b : ℝ} (hb : 1 < b) :
    0 < deriv (fun x => (x - 1) / Real.log x) b := by
  have hb0 : 0 < b := by linarith
  have hb1 : b ≠ 1 := by linarith
  rw [deriv_threshold_per_bit hb0 hb1]
  have h_main : 1 - b⁻¹ < Real.log b := one_sub_inv_lt_log hb
  apply div_pos
  · linarith
  · exact pow_pos (Real.log_pos hb) 2

/-- `b ↦ (b − 1) / log b` is strictly increasing on `(1, ∞)` (positive derivative). -/
theorem threshold_per_bit_mono :
    StrictMonoOn (fun x => (x - 1) / Real.log x) (Set.Ioi 1) := by
  refine strictMonoOn_of_deriv_pos (convex_Ioi (1 : ℝ)) ?cont ?pos
  · -- continuity of `(x − 1) / log x` on `(1, ∞)`
    apply ContinuousOn.div
    · exact continuousOn_id.sub continuousOn_const
    · apply ContinuousOn.mono Real.continuousOn_log
      intro x hx
      have hxlt : 1 < x := by simpa using hx
      intro h0
      have h0' : x = 0 := by simpa using h0
      linarith
    · intro x hx
      have hxlt : 1 < x := by simpa using hx
      exact Real.log_ne_zero_of_pos_of_ne_one (by linarith) (by linarith)
  · -- derivative strictly positive on the interior (= `(1, ∞)`, which is open)
    intro x hx
    have hx' : 1 < x := by simpa using hx
    exact deriv_threshold_per_bit_pos hx'

/-- The main result: over integer radices `b ≥ 2`, binary (`b = 2`) minimizes
    thresholds-per-bit: `1 / log 2 ≤ (b − 1) / log b`. -/
theorem binary_min_threshold_per_bit {b : ℝ} (hb : 2 ≤ b) :
    (1 : ℝ) / Real.log 2 ≤ (b - 1) / Real.log b := by
  have hmono : MonotoneOn (fun x => (x - 1) / Real.log x) (Set.Ioi 1) :=
    threshold_per_bit_mono.monotoneOn
  have h2mem : (2 : ℝ) ∈ Set.Ioi 1 := by norm_num
  have hbmem : b ∈ Set.Ioi 1 := by
    change 1 < b
    linarith
  have h : (2 - 1 : ℝ) / Real.log 2 ≤ (b - 1) / Real.log b := hmono h2mem hbmem hb
  norm_num at h ⊢
  exact h

/-- Ternary is strictly worse than binary per bit: `2 / log 3 > 1 / log 2` (≈ 1.26×). -/
theorem ternary_worse_than_binary : (2 : ℝ) / Real.log 3 > (1 : ℝ) / Real.log 2 := by
  have h : (2 - 1 : ℝ) / Real.log 2 < (3 - 1 : ℝ) / Real.log 3 :=
    threshold_per_bit_mono (by norm_num : (2 : ℝ) ∈ Set.Ioi 1)
      (by norm_num : (3 : ℝ) ∈ Set.Ioi 1) (by norm_num : (2 : ℝ) < 3)
  norm_num at h ⊢
  exact h

/-- The clean ratio: ternary/binary thresholds-per-bit equals `2·ln 2 / ln 3`. -/
theorem ternary_binary_ratio :
    (2 / Real.log 3) / (1 / Real.log 2) = 2 * Real.log 2 / Real.log 3 := by
  have hlog2 : Real.log 2 ≠ 0 := Real.log_ne_zero_of_pos_of_ne_one (by norm_num) (by norm_num)
  have hlog3 : Real.log 3 ≠ 0 := Real.log_ne_zero_of_pos_of_ne_one (by norm_num) (by norm_num)
  field_simp [hlog2, hlog3]

/-- `2·ln 2 < 2·ln 3` (equivalently `ln 2 < ln 3`, from `2 < 3`). -/
theorem two_mul_log_two_lt_two_mul_log_three : 2 * Real.log 2 < 2 * Real.log 3 := by
  exact mul_lt_mul_of_pos_left
    (Real.log_lt_log (by norm_num : 0 < (2 : ℝ)) (by norm_num : (2 : ℝ) < 3))
    (by norm_num : 0 < (2 : ℝ))

/-- The ratio is `< 2`: ternary is less than twice as bad as binary per bit. -/
theorem ternary_binary_ratio_lt_two : 2 * Real.log 2 / Real.log 3 < 2 := by
  rw [div_lt_iff₀ (Real.log_pos (by norm_num : 1 < (3 : ℝ)))]
  exact two_mul_log_two_lt_two_mul_log_three

end Hexagon
