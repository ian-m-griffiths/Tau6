/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions
import Hexagon.Rotation

/-!
# Hex isotropy — the 6 directions are uniform (free Z₆ action)

**Idea history:** Ian (2026-08-28): "ram lookup should be isotropic... up down
up-left up-right down-left down-right".

**Calibration:** DIRECT — Z₆ acts on the lattice by translation; every cell has
exactly 6 distinct unit neighbors; the pod is rotation-invariant.

**Status:** PROVED (2026-08-28) — all four theorems closed by native tactics
(`omega`/`decide`/`fin_cases`/`Finset.card_image_of_injective`), zero `sorry`.
-/

namespace Hexagon

open Eisenstein

/-- Translating by the 6 units gives 6 distinct neighbors (translation is injective).
    Hint: `z + u = z + v` is componentwise, so `ext` + `omega`/`ring` give `u = v`. -/
theorem translate_injective (z : Eisenstein) :
    Function.Injective (fun u : Eisenstein => z + u) := by
  intro u v h
  apply Eisenstein.ext
  · have hz := congrArg Eisenstein.a h
    change z.a + u.a = z.a + v.a at hz
    omega
  · have hz := congrArg Eisenstein.b h
    change z.b + u.b = z.b + v.b at hz
    omega

/-- The 6 neighbors of a cell (its unit translations). -/
def neighbors (z : Eisenstein) : Finset Eisenstein := units.image (fun u => z + u)

/-- Every cell has exactly 6 neighbors (isotropic lookup). Hint: use
    `Finset.card_image_of_injective` with `translate_injective`, then `units_card`. -/
theorem neighbors_card (z : Eisenstein) : (neighbors z).card = 6 := by
  unfold neighbors
  rw [Finset.card_image_of_injective units (translate_injective z)]
  exact units_card

/-- A unit translation never fixes a cell (u ≠ 0 for u ∈ units). Hint: if `z + u = z`
    then `u = 0` (injectivity of `+`), but `0 ∉ units`. -/
theorem no_fixed_point (z : Eisenstein) (u : Eisenstein) (hu : u ∈ units) :
    z + u ≠ z := by
  intro h
  have hu0 : u.a = 0 := by
    have hz := congrArg Eisenstein.a h
    change z.a + u.a = z.a at hz
    omega
  have hu1 : u.b = 0 := by
    have hz := congrArg Eisenstein.b h
    change z.b + u.b = z.b at hz
    omega
  have hzero : u = 0 := by
    ext <;> omega
  have hnot : 0 ∉ units := by decide
  exact hnot (by simpa [hzero] using hu)

/-- The pod is rotation-invariant: multiplying the units by a unit permutes them, so
    rotating by any unit gives back the same 6 directions. (This is the mathematical
    content of "changing the angle of lookup at the next fractal level".) Hint:
    `fin_cases hu <;> decide` (finite: 6 units, 36 products), or use
    `units_closed_under_mul` + injectivity of `u * ·`. -/
theorem units_rotate_invariant (u : Eisenstein) (hu : u ∈ units) :
    units.image (fun v => u * v) = units := by
  fin_cases hu <;> decide

end Hexagon
