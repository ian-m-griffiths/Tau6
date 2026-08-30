/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.TernaryCell

/-!
# A3 — the ternary cell energy is a lattice valuation; min+max = sum

**Idea history:** measure-theory synthesis / 1903.06044 "Lattice Valuations": our per-trit
energy (number of energized lines, 0 for null) IS a lattice valuation (monotone + modular),
and Lemma 212 `min + max = sum` is the identity our `tadd1` adder cell relies on.

**Calibration:** DIRECT — finite lattice theory.

**Status:** PROVED — every theorem below is checked by `lake build Hexagon.ValuationEnergy`
(2026-08-28, native tactics `cases`/`decide`/`norm_num`/`simp`/`rw`, no `sorry`).

**Correction to the draft spec (monotonicity):** the draft asked for `energy_monotone` w.r.t.
the balanced order `neg < zero < pos`. That statement is FALSE: the energy runs 1 → 0 → 1, so
`trit_le .neg .zero` yet `energy .neg = 1 > 0 = energy .zero` (recorded below as
`energy_not_monotone_balanced`). The corrected theorem we prove: energy IS monotone w.r.t. the
*cost* order — the null state is the unique bottom and both polarities sit above it, i.e. the
inclusion order on the one-hot wire subsets `∅ ⊆ {push}`, `∅ ⊆ {pull}` (that is what "the
energy is monotone" means in the hardware sense). Modularity — the valuation identity
`energy_min_max` — holds for the balanced order exactly as drafted, and Lemma 212
`min + max = sum` holds for the underlying balanced integers {-1, 0, +1}.
-/

namespace Hexagon

/-! ## The balanced order on trits: neg < zero < pos (i.e. −1 < 0 < +1) -/

/-- The balanced integer value of a trit: `neg ↦ −1`, `zero ↦ 0`, `pos ↦ +1`. -/
def tritVal : Trit → ℤ
  | .neg => -1
  | .zero => 0
  | .pos => 1

/-- The balanced total order on trits: `neg < zero < pos` (mirrors the integer order on
the values {-1, 0, +1}). -/
def trit_le (t u : Trit) : Prop := tritVal t ≤ tritVal u

/-- Min under the balanced trit order, by cases over the 3×3 pairs —
mirrors integer `min` on the values {-1, 0, +1}. -/
def trit_min : Trit → Trit → Trit
  | .neg, _ => .neg
  | .zero, .neg => .neg
  | .zero, .zero => .zero
  | .zero, .pos => .zero
  | .pos, u => u

/-- Max under the balanced trit order, by cases over the 3×3 pairs —
mirrors integer `max` on the values {-1, 0, +1}. -/
def trit_max : Trit → Trit → Trit
  | .neg, u => u
  | .zero, .neg => .zero
  | .zero, .zero => .zero
  | .zero, .pos => .pos
  | .pos, _ => .pos

/-! ## 1. Lemma 212 — `min + max = sum`, the identity our `tadd1` adder cell relies on -/

/-- Lemma 212 (the `tadd1` identity): for integers, `min a b + max a b = a + b`.
Mathlib's `min_add_max` already states this for any linearly ordered additive semigroup
(`@[simp]` in `Mathlib/Algebra/Order/Monoid/Unbundled/MinMax.lean`); we restate it for `ℤ`
under the project name. -/
theorem min_add_max (a b : ℤ) : min a b + max a b = a + b := by
  exact _root_.min_add_max a b

/-- Trit-level `min` mirrors integer `min` under the balanced embedding {-1, 0, +1}. -/
theorem tritVal_min (t u : Trit) : tritVal (trit_min t u) = min (tritVal t) (tritVal u) := by
  cases t <;> cases u <;> decide

/-- Trit-level `max` mirrors integer `max` under the balanced embedding {-1, 0, +1}. -/
theorem tritVal_max (t u : Trit) : tritVal (trit_max t u) = max (tritVal t) (tritVal u) := by
  cases t <;> cases u <;> decide

/-- Lemma 212 for the balanced trits {-1, 0, +1}: `min + max = sum` on the trit values —
the `tadd1` identity at the trit level, derived from the integer form. -/
theorem tritVal_min_add_max (t u : Trit) :
    tritVal (trit_min t u) + tritVal (trit_max t u) = tritVal t + tritVal u := by
  rw [tritVal_min, tritVal_max]
  exact min_add_max (tritVal t) (tritVal u)

/-! ## 2. The energy is modular — the valuation property -/

/-- The energy is a lattice valuation: `energy (min t u) + energy (max t u) = energy t + energy u`
(modularity, in the 1903.06044 sense) — checked over the 3×3 = 9 trit pairs. -/
theorem energy_min_max (t u : Trit) :
    energy (trit_min t u) + energy (trit_max t u) = energy t + energy u := by
  cases t <;> cases u <;> decide

/-- The energy is the absolute value of the balanced value: 0 for null, 1 for either polarity. -/
theorem energy_eq_natAbs (t : Trit) : energy t = (tritVal t).natAbs := by
  cases t <;> decide

/-! ## 3. The energy is monotone — w.r.t. the *cost* order (null is the bottom) -/

/-- The *cost* order on trits: the null state is the unique bottom and the two polarities sit
above it — the inclusion order on the one-hot wire subsets `∅ ⊆ {push}` and `∅ ⊆ {pull}`.
(NOT the balanced order — see `energy_not_monotone_balanced` below.) -/
def trit_cost_le (t u : Trit) : Prop := t = .zero ∨ u ≠ .zero

/-- The energy is monotone w.r.t. the cost order: if `t` sits no higher than `u` in the
wire-subset sense then `energy t ≤ energy u`. (The balanced-order version of this claim is
false — see `energy_not_monotone_balanced`.) -/
theorem energy_monotone (t u : Trit) (h : trit_cost_le t u) : energy t ≤ energy u := by
  unfold trit_cost_le at h
  rcases h with rfl | hu
  · rw [energy_zero]
    exact Nat.zero_le (energy u)
  · cases u with
    | neg =>
        rw [energy_neg]
        exact energy_le_one t
    | zero =>
        exact False.elim (hu rfl)
    | pos =>
        rw [energy_pos]
        exact energy_le_one t

/-- Corollary: the null state is the unique energy minimum (it costs 0, everything else 1). -/
theorem energy_zero_le (t : Trit) : energy .zero ≤ energy t := by
  exact energy_monotone .zero t (Or.inl rfl)

/-- **The draft monotonicity claim is false as stated:** with the balanced order
`neg < zero < pos` the energy is NOT monotone — it runs 1 → 0 → 1. Counterexample:
`trit_le .neg .zero` holds but `energy .neg = 1 > 0 = energy .zero`. -/
theorem energy_not_monotone_balanced :
    ¬ (∀ t u : Trit, trit_le t u → energy t ≤ energy u) := by
  intro h
  have hneg : trit_le .neg .zero := by norm_num [trit_le, tritVal]
  have hle : energy .neg ≤ energy .zero := h .neg .zero hneg
  norm_num [energy, encode] at hle

end Hexagon
