/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# Energy model: decomposition + recoverable-vs-dissipated + the break-even null probability

**Idea history:** the ngspice run falsified "naive polarity cell beats binary" (ternary
5.36 pJ/push vs binary 0.75 pJ/bit) but confirmed null is free (~0) and charge recycling
recovers ~50%. This file formalizes the ALGEBRAIC model behind that: a transfer's energy
splits into a recoverable capacitive term and irrecoverable diode/resistive terms, and the
break-even null probability tells us how cheap push/pull must get to beat binary.

**Calibration:** DIRECT — algebra over ℚ/ℝ.

**Status:** PROVED — all theorems below check with `lake build` (Lean v4.33.1 + mathlib,
pure ℚ algebra: `field_simp`/`linarith`/`nlinarith`/`norm_num`; no analysis).
-/

namespace Hexagon

-- Over ℚ (or ℝ): define per-transfer energy as a function of the physical knobs:
--   E_cap   = (1/2) * C * V^2          (recoverable: the charge stored in the line cap)
--   E_diode = I * Vd * t                (irrecoverable: diode drop × current × time)
--   E_res   = I^2 * R * t               (irrecoverable: wire resistance)
--   E_transfer = E_cap + E_diode + E_res

/-- Energy stored in the line capacitance: `(1/2) C V²`. This is the part charge
recycling can hand back — you never recover more than what was stored. -/
def E_cap (C V : ℚ) : ℚ := (1 / 2) * C * V ^ 2

/-- Energy dumped across the diode drop: `I · Vd · t`. Irrecoverable loss. -/
def E_diode (I Vd t : ℚ) : ℚ := I * Vd * t

/-- Energy dissipated in the wire resistance: `I² R t`. Irrecoverable loss. -/
def E_res (I R t : ℚ) : ℚ := I ^ 2 * R * t

/-- Total energy of one transfer: capacitive (recoverable) + diode + resistive. -/
def E_transfer (C V I Vd R t : ℚ) : ℚ := E_cap C V + E_diode I Vd t + E_res I R t

-- 1. E_cap is recoverable, E_diode and E_res are not (charge recycling recovers ≤ E_cap).

/-- The recyclable energy ≤ the stored capacitive energy: the transfer's total is at
least its capacitive part, so recycling can never return more than `E_cap` — the diode
and resistive terms are pure loss. Assumes the physical sign conventions
(`I, Vd, R, t ≥ 0`); without them the loss terms could go negative. -/
theorem recyclable_le_cap (C V I Vd R t : ℚ) (hI : 0 ≤ I) (hVd : 0 ≤ Vd) (hR : 0 ≤ R)
    (ht : 0 ≤ t) : E_cap C V ≤ E_transfer C V I Vd R t := by
  unfold E_transfer E_diode E_res
  have hd : 0 ≤ I * Vd * t := mul_nonneg (mul_nonneg hI hVd) ht
  have hr : 0 ≤ I ^ 2 * R * t := mul_nonneg (mul_nonneg (sq_nonneg I) hR) ht
  linarith

-- 2. A naive cell (Vd > 0) always has E_transfer > E_cap (dissipates more than it stores).

/-- A naive cell with a forward diode drop (`Vd > 0`) and real current/time dissipates
strictly more than it stores: the diode term is strictly positive, so `E_transfer` is
always above `E_cap` no matter what the capacitance holds. (`R ≥ 0` keeps the resistive
term from cancelling the diode loss — resistance can only add loss, never subtract it.) -/
theorem naive_dissipates (C V I Vd R t : ℚ) (hVd : 0 < Vd) (hI : 0 < I) (hR : 0 ≤ R)
    (ht : 0 < t) : E_cap C V < E_transfer C V I Vd R t := by
  unfold E_transfer E_diode E_res
  have hd : 0 < I * Vd * t := mul_pos (mul_pos hI hVd) ht
  have hr : 0 ≤ I ^ 2 * R * t := mul_nonneg (mul_nonneg (sq_nonneg I) hR) (le_of_lt ht)
  nlinarith

-- 3. The break-even theorem: with ternary transfer energy E_t (push/pull) and free null,
--    and a binary baseline E_b per "trit-equivalent" (E_b = log2(3) * E_bit), the ternary
--    AVERAGE over a workload with null probability p0 is E_t * (1 - p0); ternary beats
--    binary iff p0 > 1 - E_b / E_t.  (This is the "how cheap must push/pull get" answer.)

/-- Expected ternary cost per trit under a workload where a null (which costs ~0) occurs
with probability `p0`: push/pull only happens on the other `1 - p0` fraction. -/
def ternary_avg (Et p0 : ℚ) : ℚ := Et * (1 - p0)

/-- Binary baseline cost per trit-equivalent — the identity, kept as a named def so the
comparison reads "ternary average < binary equivalent". -/
def binary_equiv (Eb : ℚ) : ℚ := Eb

/-- **Break-even threshold.** The ternary average `Et·(1−p0)` beats the binary baseline
`Eb` iff the null probability exceeds `1 − Eb/Et`. The direction of the sign flips with
`Et`; `hEt : 0 < Et` is exactly the assumption that fixes it (if `Et ≤ 0` the inequality
is trivially true or reversed). -/
theorem break_even (Et Eb p0 : ℚ) (hEt : 0 < Et) :
    ternary_avg Et p0 < binary_equiv Eb ↔ p0 > 1 - Eb / Et := by
  unfold ternary_avg binary_equiv
  constructor
  · intro h
    -- `Et * (1 - p0) < Eb` with `Et > 0` ⇔ `1 - p0 < Eb / Et`
    have h1 : 1 - p0 < Eb / Et := (lt_div_iff₀ hEt).2 (by nlinarith)
    nlinarith
  · intro h
    -- `p0 > 1 - Eb/Et` ⇔ `1 - p0 < Eb/Et`, then multiply back by the positive `Et`
    have h1 : 1 - p0 < Eb / Et := by nlinarith
    have h2 : (1 - p0) * Et < Eb := (lt_div_iff₀ hEt).1 h1
    nlinarith

/-- The measured numbers: Et = 5361/1000 pJ (5.361 pJ per ternary push/pull from the
ngspice run) and Eb = (log2 3)·0.75 ≈ 1.19 pJ per trit-equivalent (the binary cell is
0.75 pJ/bit and a ternary digit carries log2 3 bits, so use Eb = 119/100). -/
theorem real_break_even_needs (p0 : ℚ) :
    ternary_avg (5361 / 1000) p0 < binary_equiv (119 / 100) ↔
      p0 > 1 - (119 / 100) / (5361 / 1000) := by
  simpa using break_even (5361 / 1000) (119 / 100) p0 (by norm_num)

/-- The numeric value of the break-even null probability: `1 − (119/100)/(5361/1000) =
4171/5361 ≈ 0.7780`, i.e. **~77.8%** of all transfers must be free nulls. -/
lemma real_break_even_threshold : (1 - (119 / 100) / (5361 / 1000) : ℚ) = 4171 / 5361 := by
  norm_num

/-- Same corollary with the threshold reduced to a single ℚ literal: the CURRENT cell
only wins in expectation if `p0 > 4171/5361 ≈ 77.8%`. No realistic workload is that
null-heavy — **that is why we must lower Et** (or recycle enough charge to cut the
effective Et), which is exactly what the ngspice run told us. -/
theorem real_break_even_needs' (p0 : ℚ) :
    ternary_avg (5361 / 1000) p0 < binary_equiv (119 / 100) ↔ p0 > 4171 / 5361 := by
  simpa [real_break_even_threshold] using real_break_even_needs p0

end Hexagon
