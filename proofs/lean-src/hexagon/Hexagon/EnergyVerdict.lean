/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# The energy verdict — with the REAL measured numbers, ternary wins uniformly

**Idea history:** the ngspice fair-fight measured (circuit/ENERGY_RESULTS.md): push/pull =
1.20 pJ, null = 0.05 pJ (receiver only, 24× cheaper), binary = 0.748 pJ/bit. Because null is
a DATA-BEARING symbol, the uniform average is (1.20+1.20+0.05)/3 = 0.8167 pJ/trit, and a
trit carries log₂3 ≈ 1.585 bits. To avoid irrational log₂3, use the integer fact
3² = 9 ≥ 8 = 2³: TWO trits carry at least as much information as THREE bits. Then the
verdict is a pure ℚ inequality.

**Calibration:** DIRECT — the measured numbers plugged into the proven model.

**Status:** PROVED — see below.
-/

namespace Hexagon

/-- Uniform average energy per trit (push, pull cost Et; null costs En). -/
def trit_uniform (Et En : ℚ) : ℚ := (Et + Et + En) / 3

/-- Binary bit energy (measured): 0.748 pJ/bit. -/
def binary_bit : ℚ := 748 / 1000

/-- Two trits carry ≥ three bits of information: 3² = 9 ≥ 8 = 2³. -/
theorem two_trits_ge_three_bits : (3 ^ 2 : ℕ) ≥ (2 ^ 3 : ℕ) := by norm_num

/-- The measured per-trit uniform cost: (1.20 + 1.20 + 0.05)/3 = 49/60 pJ. -/
theorem measured_trit_uniform : trit_uniform (6 / 5) (1 / 20) = 49 / 60 := by
  norm_num [trit_uniform]

/-- The verdict: 2 trits (uniform, real numbers) cost strictly less than 3 binary bits —
    i.e. ternary wins on energy per bit of information, at uniform distribution. -/
theorem ternary_wins_uniform :
    (2 : ℚ) * trit_uniform (6 / 5) (1 / 20) < (3 : ℚ) * binary_bit := by
  norm_num [trit_uniform, binary_bit]

/-- And the margin: 2 trits = 49/30 ≈ 1.633 pJ vs 3 bits = 2.244 pJ → ~27% cheaper per
    bit-of-information group. (The per-bit figure is ~31% better: 0.515 vs 0.748.) -/
theorem ternary_margin :
    (3 : ℚ) * binary_bit - (2 : ℚ) * trit_uniform (6 / 5) (1 / 20) = 229 / 375 := by
  norm_num [trit_uniform, binary_bit]

end Hexagon
