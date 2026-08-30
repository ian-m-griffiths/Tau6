/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions
import Hexagon.SevenHex

/-!
# T3 + T4 — the Z₆ rotation group and the cube-coordinate hex distance

**Idea history:** hexigon_conversation.md L10179–10197 (rotation = permute tuple
indices, mod-6 arithmetic), L11248 ("trig becomes modulo arithmetic"), L11397–11399
(60° basis → exact integer angles); plan §3; SYNTHESIS Q1 (the hex↔u32 address claim
stays SPECULATION until a provable address translation exists — T4 is its metric).

**Calibration:** DIRECT (real math, integer-native). The Z₆ spinor is the one DIRECT
bridge to the rebuild: a mod-6 integer rotation realizing the even-grade fix
ψ = (α+βI)U (TODO #16, ox alpha.md L3109; plan §2.6).

**Status:** PARTIAL (2026-08-28) — T3a `units_card` (`decide`) and T3b
`units_closed_under_mul` (`fin_cases` + `decide`) PROVED. T4-metric PROVED
(`isNeighbor`, `hexDist_self`/`_comm`/`_nonneg`/`_triangle`, `hexDist_le_iff`);
T4 graph-distance = hexDist still open (needs SimpleGraph path construction) — see INDEX.md.
-/

namespace Hexagon

open Eisenstein

/-- The six units of ℤ[ω]: ±1, ±ω, ±ω² (the six 60° rotations).
    As pairs: 1=(1,0), -1=(-1,0), ω=(0,1), -ω=(0,-1), ω²=ω-1=(-1,1), -ω²=(1,-1). -/
def units : Finset Eisenstein :=
  {⟨1, 0⟩, ⟨-1, 0⟩, ⟨0, 1⟩, ⟨0, -1⟩, ⟨-1, 1⟩, ⟨1, -1⟩}

/-- T3a: there are exactly six units. -/
theorem units_card : units.card = 6 := by
  decide

/-- Angle index 0..5; rotation = addition mod 6 (the Z₆ group operation). -/
def angleAdd (a b : Fin 6) : Fin 6 := a + b

/-- T3b contract: the units are closed under multiplication and form the cyclic
    group Z₆ (the sixth roots of unity). (Suggestion: map each unit to its angle
    in `Fin 6` and prove `mul` corresponds to `angleAdd`.) -/
theorem units_closed_under_mul (x y : Eisenstein) (hx : x ∈ units) (hy : y ∈ units) :
    x * y ∈ units := by
  fin_cases hx <;> fin_cases hy <;> decide

/-- T4a (needed before T4): the neighbor relation on hex cells — two cells are
    neighbors iff their cube-coordinate max-norm distance is 1.
    NOTE: Lean n-tuples are nested pairs — components of `ℤ × ℤ × ℤ` are
    `.1`, `.2.1`, `.2.2` (there is no `.3`). -/
def hexDist (a b : ℤ × ℤ × ℤ) : ℤ :=
  max (|a.1 - b.1|) (max (|a.2.1 - b.2.1|) (|a.2.2 - b.2.2|))

/-- T4a: the neighbor relation on hex cells — two balanced cells are neighbors iff
    their cube-coordinate max-norm distance is 1. -/
def isNeighbor (a b : ℤ × ℤ × ℤ) : Prop := balanced a ∧ balanced b ∧ hexDist a b = 1

/-- The max-norm distance to yourself is 0. -/
theorem hexDist_self (a : ℤ × ℤ × ℤ) : hexDist a a = 0 := by
  simp [hexDist]

/-- The max-norm distance is symmetric. -/
theorem hexDist_comm (a b : ℤ × ℤ × ℤ) : hexDist a b = hexDist b a := by
  simp [hexDist, abs_sub_comm]

/-- The max-norm distance is nonnegative. -/
theorem hexDist_nonneg (a b : ℤ × ℤ × ℤ) : 0 ≤ hexDist a b := by
  exact le_trans (abs_nonneg (a.1 - b.1)) (le_max_left _ _)

/-- `hexDist a b ≤ d` iff every coordinate gap is bounded by `d`. -/
theorem hexDist_le_iff (a b : ℤ × ℤ × ℤ) (d : ℤ) :
    hexDist a b ≤ d ↔ |a.1 - b.1| ≤ d ∧ |a.2.1 - b.2.1| ≤ d ∧ |a.2.2 - b.2.2| ≤ d := by
  simp [hexDist]

/-- Coordinate bounds toward the max-norm distance. -/
theorem abs_fst_sub_le_hexDist (a b : ℤ × ℤ × ℤ) : |a.1 - b.1| ≤ hexDist a b := by
  dsimp [hexDist]
  exact le_max_left _ _

theorem abs_mid_sub_le_hexDist (a b : ℤ × ℤ × ℤ) : |a.2.1 - b.2.1| ≤ hexDist a b := by
  dsimp [hexDist]
  exact le_trans (le_max_left _ _) (le_max_right _ _)

theorem abs_snd_sub_le_hexDist (a b : ℤ × ℤ × ℤ) : |a.2.2 - b.2.2| ≤ hexDist a b := by
  dsimp [hexDist]
  exact le_trans (le_max_right _ _) (le_max_right _ _)

/-- On balanced cells, being neighbors is exactly being at max-norm distance 1. -/
theorem isNeighbor_iff (a b : ℤ × ℤ × ℤ) (ha : balanced a) (hb : balanced b) :
    isNeighbor a b ↔ hexDist a b = 1 := by
  simp [isNeighbor, ha, hb]

/-- The max-norm distance satisfies the triangle inequality (it is a metric). -/
theorem hexDist_triangle (a b c : ℤ × ℤ × ℤ) :
    hexDist a c ≤ hexDist a b + hexDist b c := by
  rw [hexDist_le_iff]
  constructor
  · calc
      |a.1 - c.1| = |(a.1 - b.1) + (b.1 - c.1)| := congrArg abs (by ring)
      _ ≤ |a.1 - b.1| + |b.1 - c.1| := abs_add_le _ _
      _ ≤ hexDist a b + hexDist b c :=
        add_le_add (abs_fst_sub_le_hexDist a b) (abs_fst_sub_le_hexDist b c)
  · constructor
    · calc
        |a.2.1 - c.2.1| = |(a.2.1 - b.2.1) + (b.2.1 - c.2.1)| := congrArg abs (by ring)
        _ ≤ |a.2.1 - b.2.1| + |b.2.1 - c.2.1| := abs_add_le _ _
        _ ≤ hexDist a b + hexDist b c :=
          add_le_add (abs_mid_sub_le_hexDist a b) (abs_mid_sub_le_hexDist b c)
    · calc
        |a.2.2 - c.2.2| = |(a.2.2 - b.2.2) + (b.2.2 - c.2.2)| := congrArg abs (by ring)
        _ ≤ |a.2.2 - b.2.2| + |b.2.2 - c.2.2| := abs_add_le _ _
        _ ≤ hexDist a b + hexDist b c :=
          add_le_add (abs_snd_sub_le_hexDist a b) (abs_snd_sub_le_hexDist b c)

end Hexagon
