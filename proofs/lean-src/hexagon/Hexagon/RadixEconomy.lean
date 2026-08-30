/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# B2 — radix economy: ternary is the most efficient integer radix

**Idea history:** 1807.06419 (log₂3 ≈ 1.585 bits/trit); the ternary synthesis "radix
economy" confirmed. Ian: "ternary grows faster than binary." The cost of representing a
number in radix b is `b / ln b` (digits × per-digit states per bit of info); it is minimized
at b = e, and among integers b = 3 wins.

**Calibration:** DIRECT — a `Real.log` inequality.

**Status:** PROVED (2026-08-28) — `ternary_beats_binary`, `quaternary_ties_binary`, and the
bonus `bits_per_trit_gt_one` all green (`lake build Hexagon.RadixEconomy`), zero `sorry`.
Route: `Real.log_pow` (`log 8 = 3 log 2`, `log 9 = 2 log 3`) + `Real.log_lt_log` (8 < 9, both
positive) + `div_lt_div_iff₀` dividing by the positive product `Real.log 2 * Real.log 3`.
-/

namespace Hexagon

open scoped Real

-- `log 8 = 3 log 2`  (8 = 2³, `Real.log_pow`)
private lemma log_8 : Real.log (8 : ℝ) = 3 * Real.log 2 := by
  rw [show (8 : ℝ) = (2 : ℝ) ^ 3 by norm_num]
  rw [Real.log_pow]
  norm_num

-- `log 9 = 2 log 3`  (9 = 3², `Real.log_pow`)
private lemma log_9 : Real.log (9 : ℝ) = 2 * Real.log 3 := by
  rw [show (9 : ℝ) = (3 : ℝ) ^ 2 by norm_num]
  rw [Real.log_pow]
  norm_num

-- `log 4 = 2 log 2`  (4 = 2², `Real.log_pow`)
private lemma log_4 : Real.log (4 : ℝ) = 2 * Real.log 2 := by
  rw [show (4 : ℝ) = (2 : ℝ) ^ 2 by norm_num]
  rw [Real.log_pow]
  norm_num

-- `log 2` is positive since 2 > 1
private lemma log_two_pos : 0 < Real.log 2 := Real.log_pos (by norm_num)

-- `log 3` is positive since 3 > 1
private lemma log_three_pos : 0 < Real.log 3 := Real.log_pos (by norm_num)

-- `3 * log 2 < 2 * log 3`  ⟺  `log 8 < log 9`  ⟺  `8 < 9`
private lemma three_log_two_lt_two_log_three : 3 * Real.log 2 < 2 * Real.log 3 := by
  rw [← log_8, ← log_9]
  exact Real.log_lt_log (by norm_num) (by norm_num)

-- Ternary beats binary:  3 / log 3 < 2 / log 2
-- (divide the inequality above by the positive product `log 2 * log 3`)
theorem ternary_beats_binary : (3 : ℝ) / Real.log 3 < (2 : ℝ) / Real.log 2 := by
  rw [div_lt_div_iff₀ log_three_pos log_two_pos]
  exact three_log_two_lt_two_log_three

-- Quaternary ties binary:  4 / log 4 = 2 / log 2  (since `log 4 = 2 log 2`)
theorem quaternary_ties_binary : (4 : ℝ) / Real.log 4 = (2 : ℝ) / Real.log 2 := by
  rw [log_4]
  field_simp [log_two_pos.ne']
  norm_num

-- Bonus: a trit carries more than one bit:  log₂ 3 = log 3 / log 2 > 1
theorem bits_per_trit_gt_one : (1 : ℝ) < Real.log 3 / Real.log 2 := by
  rw [one_lt_div log_two_pos]
  exact Real.log_lt_log (by norm_num) (by norm_num)

end Hexagon
