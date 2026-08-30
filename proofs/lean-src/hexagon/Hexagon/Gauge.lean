/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions
import Hexagon.Rotation

/-!
# Gauge & isotropy — the norm is the area scalar, invariant under the Z₆ rotations

**Idea history:** Ian (2026): "the math that gives us the isotropy, and lets us encode
the gauge and the value as its area as one number… {20,1} is {10,2} by area… the gauge
is just another number, giving cheap multiplication and gauge change."

**Calibration:** DIRECT — the norm `N(a+bω) = a²+ab+b²` is the determinant of the
regular representation (an AREA), and it is invariant under multiplication by the six
units (the Z₆ rotations = isotropy). Gauge change = cheap multiplication by a unit.

**Status:** PROVED (2026-08-28) — `norm_of_unit`, `norm_mul_unit`/`norm_unit_mul`,
`norm_eq_det` (the norm IS the determinant of the regular representation — the area
scalar), and `units_eq_omega_pow` (the six units are exactly `ω^k`, k = 0..5, so gauge
change is a 60° rotation) — all closed by native tactics (`fin_cases`, `decide`,
`ring`); `lake build Hexagon.Gauge` green.
-/

namespace Hexagon

/-- T1b: every unit has norm 1. -/
theorem norm_of_unit (u : Eisenstein) (hu : u ∈ units) : Eisenstein.norm u = 1 := by
  fin_cases hu <;> decide

/-- T1c: the norm is invariant under right multiplication by a unit (isotropy). -/
theorem norm_mul_unit (x u : Eisenstein) (hu : u ∈ units) :
    Eisenstein.norm (x * u) = Eisenstein.norm x := by
  rw [Eisenstein.norm_mul, norm_of_unit u hu]
  ring

/-- T1c′: the norm is invariant under left multiplication by a unit (isotropy). -/
theorem norm_unit_mul (x u : Eisenstein) (hu : u ∈ units) :
    Eisenstein.norm (u * x) = Eisenstein.norm x := by
  rw [Eisenstein.norm_mul, norm_of_unit u hu]
  ring

/-- The regular representation of `a + bω` on the basis `{1, ω}`: multiplication by
    `x` sends `1 ↦ (a, b)` and `ω ↦ (-b, a+b)`; its determinant is the norm (area). -/
def rep (x : Eisenstein) : Matrix (Fin 2) (Fin 2) ℤ :=
  ![![x.a, -x.b], ![x.b, x.a + x.b]]

/-- T1d: `N(x)` = det of the regular representation — the norm IS the area scalar. -/
theorem norm_eq_det (x : Eisenstein) : (Eisenstein.norm x : ℤ) = (rep x).det := by
  rcases x with ⟨a, b⟩
  rw [Matrix.det_fin_two]
  simp [rep, Eisenstein.norm]
  ring

/-- ω = e^(iπ/3) = (0,1): the generator of the six 60° rotations. -/
def omega : Eisenstein := ⟨0, 1⟩

/-- `ω^k` by repeated multiplication (no `Monoid`/`Pow` instance needed yet). -/
def omegaPow (k : ℕ) : Eisenstein := Nat.rec 1 (fun _ acc => acc * omega) k

/-- The values of the first six powers of ω: ω⁰ = 1, ω¹ = ω, ω² = ω−1, ω³ = −1,
    ω⁴ = −ω, ω⁵ = −ω². -/
theorem omegaPow_zero : omegaPow 0 = ⟨1, 0⟩ := by
  decide
theorem omegaPow_one : omegaPow 1 = ⟨0, 1⟩ := by
  decide
theorem omegaPow_two : omegaPow 2 = ⟨-1, 1⟩ := by
  decide
theorem omegaPow_three : omegaPow 3 = ⟨-1, 0⟩ := by
  decide
theorem omegaPow_four : omegaPow 4 = ⟨0, -1⟩ := by
  decide
theorem omegaPow_five : omegaPow 5 = ⟨1, -1⟩ := by
  decide

/-- T1e: the six units are exactly the six powers `ω^k`, k = 0..5 — multiplication by
    ω cycles the gauge values (gauge change is a cheap 60° rotation). -/
theorem units_eq_omega_pow :
    ({⟨1, 0⟩, ⟨0, 1⟩, ⟨-1, 1⟩, ⟨-1, 0⟩, ⟨0, -1⟩, ⟨1, -1⟩} : Finset Eisenstein)
      = ({omegaPow 0, omegaPow 1, omegaPow 2, omegaPow 3, omegaPow 4, omegaPow 5}
          : Finset Eisenstein) := by
  rw [omegaPow_zero, omegaPow_one, omegaPow_two, omegaPow_three, omegaPow_four,
    omegaPow_five]

/-- The units finset is exactly the ω-orbit (same six elements, listed in the
    rotation order of `units`). -/
theorem units_eq_omega_powers :
    units = ({omegaPow 0, omegaPow 1, omegaPow 2, omegaPow 3, omegaPow 4, omegaPow 5}
        : Finset Eisenstein) := by
  rw [omegaPow_zero, omegaPow_one, omegaPow_two, omegaPow_three, omegaPow_four,
    omegaPow_five]
  decide

/-- ω⁶ = 1: the rotation cycle closes back to the identity. -/
theorem omegaPow_six : omegaPow 6 = (1 : Eisenstein) := by
  decide

/-- Multiplication by ω maps units to units (the rotation action on the gauge). -/
theorem mul_omega_mem_units (u : Eisenstein) (hu : u ∈ units) : u * omega ∈ units := by
  exact units_closed_under_mul u omega hu (by decide)

end Hexagon
