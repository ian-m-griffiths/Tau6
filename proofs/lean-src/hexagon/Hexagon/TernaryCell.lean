/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# The ternary cell — one-hot-per-direction encoding: energy + the reusable overlap

**Idea history:** Ian (2026): two diodes (transistors for leakage), a low-energy push/pull
generator; ternary = the polarity (direction) of electrons; store a bit of each direction so
at most ONE line is energized per state (null = 0) — so static/transfer cost is lower than
binary; the two bits have overlapping parts that can be reused (the "both on" state is never
used).

**Calibration:** DIRECT — finite combinatorics.

**Status:** PROVED — every theorem below is checked by `lake build Hexagon.TernaryCell`
(2026-08-28, native tactics `cases`/`decide`/`norm_num`, no `sorry`).
-/

namespace Hexagon

/-- A balanced trit: −1, 0, +1. -/
inductive Trit where | neg | zero | pos
  deriving DecidableEq, Repr

-- NOTE: `deriving Fintype` is broken in this toolchain (Lean v4.33.1 + mathlib): it emits an
-- ill-typed instance for a bare inductive (`List.Nodup` supplied where `Multiset.Nodup` is
-- required — see the `enumList_nodup` mismatch), so Trit gets an explicit `Fintype` instance:
instance : Fintype Trit :=
  ⟨({.neg, .zero, .pos} : Finset Trit), by
    intro x
    cases x <;> simp⟩

/-- One-hot-per-direction encoding onto two wires: the push-line and the pull-line.
`.pos` energizes the push line, `.neg` the pull line, `.zero` (null) energizes neither. -/
def encode : Trit → Bool × Bool
  | .pos  => (true, false)   -- push energized
  | .zero => (false, false)  -- null: nothing energized
  | .neg  => (false, true)   -- pull energized

/-- ENERGY = number of energized lines (= number of `true`s): 0 iff the null state, else 1. -/
def energy (t : Trit) : ℕ := if encode t = (false, false) then 0 else 1

/-! ## 1. The energy claim: at most one line on, null is free, average 2/3 -/

theorem energy_pos : energy .pos = 1 := by
  decide

theorem energy_zero : energy .zero = 0 := by
  decide

theorem energy_neg : energy .neg = 1 := by
  decide

-- already energy_zero; kept for the name
theorem null_is_free : energy .zero = 0 := energy_zero

/-- At most one line is energized per state. -/
theorem energy_le_one (t : Trit) : energy t ≤ 1 := by
  cases t <;> decide

/-- Sum of energy over the 3 trits: two states cost 1 each, null costs 0. -/
theorem total_energy : (∑ t : Trit, energy t) = 2 := by
  decide

theorem card_trit : Fintype.card Trit = 3 := by
  decide

/-- The exact average: total energy 2 over 3 trits = 2/3 of a wire per trit. -/
theorem average_energy :
    (↑(∑ t : Trit, energy t) / (Fintype.card Trit : ℚ)) = (2 : ℚ) / 3 := by
  rw [total_energy, card_trit]
  norm_num

/-! ## 2. The binary comparison: uniform 2-bit encoding averages 1 wire per state -/

/-- Energy of a plain binary 2-bit word: the number of `true` bits. -/
def binEnergy (b : Bool × Bool) : ℕ := (if b.1 then 1 else 0) + (if b.2 then 1 else 0)

theorem binary_total_energy : (∑ b : Bool × Bool, binEnergy b) = 4 := by
  decide

theorem card_bool_pair : Fintype.card (Bool × Bool) = 4 := by
  decide

/-- Uniform binary 2-bit: total energy 4 over 4 states = 1 wire per state on average. -/
theorem binary_average_energy :
    (↑(∑ b : Bool × Bool, binEnergy b) / (Fintype.card (Bool × Bool) : ℚ)) = (1 : ℚ) := by
  rw [binary_total_energy, card_bool_pair]
  norm_num

/-- The saving: 2/3 < 1, so the ternary cell uses 2/3 the energized lines of binary —
i.e. it saves 1/3 of the energized-line energy. -/
theorem ternary_saves_third : (2 : ℚ) / 3 < 1 := by
  norm_num

/-! ## 3. The overlap/reuse claim: the two wires are constrained, never both on -/

/-- The `(true, true)` "both on" state is never produced: the two wires are constrained
(never both energized), so that state is reusable. -/
theorem encode_never_both (t : Trit) : encode t ≠ (true, true) := by
  cases t <;> decide

/-- The encoding is injective: the 3 trits have 3 distinct images (one-hot-per-direction). -/
theorem encode_injective : Function.Injective encode := by
  intro a b h
  cases a <;> cases b <;> simp [encode] at h ⊢

/-- ... but not surjective onto `Bool × Bool`: `(true, true)` has no preimage, so the 2 bits
overlap and the unused state can be shared/reused. -/
theorem encode_not_surjective : ¬ Function.Surjective encode := by
  intro h
  rcases h (true, true) with ⟨t, ht⟩
  exact encode_never_both t ht

end Hexagon
