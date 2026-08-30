/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.TernaryCell

/-!
# B1 — Zipf-weighted energy: "small numbers outweigh the big" (the real saving > 1/3)

**Idea history:** Ian's refinement of the uniform 1/3 saving: in real data the null (0)
state dominates (Zipf / power-law), so the energy-free null applies most of the time.
TernaryCell.lean proved the uniform average is 2/3 vs binary 1. This file proves the
WEIGHTED expected energy is far lower when null dominates.

**Calibration:** DIRECT — a finite expectation computation.

**Status:** PROVED — every theorem below is checked by `lake build Hexagon.ZipfEnergy`
(2026-08-28, tactics `rw`/`norm_num`/`linarith`, no `sorry`).
-/

namespace Hexagon

-- TernaryCell.lean (same `namespace Hexagon`) has `Trit` (neg/zero/pos) and `energy`
-- (1 for pos/neg, 0 for zero): `energy_pos`, `energy_zero`, `energy_neg`.

/-- Expected energy of the ternary cell under a probability distribution
`(p_pos, p_zero, p_neg)` on the trits (each `p_* : ℚ`, sum 1). -/
def expected_energy (p_pos p_zero p_neg : ℚ) : ℚ :=
  p_pos * energy .pos + p_zero * energy .zero + p_neg * energy .neg

/-- Expected energy = 1 − P(zero): the expectation is `p_pos + p_neg`, and the
normalization `p_pos + p_zero + p_neg = 1` gives `p_pos + p_neg = 1 - p_zero`. -/
theorem expected_energy_eq_one_minus_pzero (p_pos p_zero p_neg : ℚ)
    (hsum : p_pos + p_zero + p_neg = 1) :
    expected_energy p_pos p_zero p_neg = 1 - p_zero := by
  unfold expected_energy
  rw [energy_pos, energy_zero, energy_neg]
  norm_num
  linarith

/-- Null-dominance ⇒ below uniform: if the null state is more common than in the
uniform distribution (`p_zero > 1/3`), the expected energy drops strictly below the
uniform average `2/3` (from TernaryCell.average_energy). -/
theorem expected_lt_uniform (p_pos p_zero p_neg : ℚ)
    (hsum : p_pos + p_zero + p_neg = 1) (hp : (1 / 3 : ℚ) < p_zero) :
    expected_energy p_pos p_zero p_neg < (2 / 3 : ℚ) := by
  rw [expected_energy_eq_one_minus_pzero p_pos p_zero p_neg hsum]
  linarith

/-- Concrete Zipf-ish instance: `p_zero = 1/2`, `p_pos = p_neg = 1/4` gives expected
energy `1/2` — already better than the uniform `2/3`. -/
theorem expected_concrete : expected_energy (1 / 4) (1 / 2) (1 / 4) = (1 / 2 : ℚ) := by
  unfold expected_energy
  rw [energy_pos, energy_zero, energy_neg]
  norm_num

/-- The concrete instance is strictly below the uniform average: `1/2 < 2/3`. -/
theorem concrete_below_uniform : expected_energy (1 / 4) (1 / 2) (1 / 4) < (2 / 3 : ℚ) := by
  rw [expected_concrete]
  norm_num

end Hexagon
