/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions
import Hexagon.Rotation
import Hexagon.Gauge

/-!
# A1 — the counting measure is Haar for the Z₆ action (isotropy at the measure level)

**Idea history:** measure-theory synthesis: "translation invariance/Haar = isotropy Z₆";
the counting measure is the base; this is the flag theorem. Gauge.lean already proved the
NORM is invariant under units (`norm_mul_unit`); this file proves the COUNTING MEASURE is
invariant — the measure-theoretic form of isotropy.

**Calibration:** DIRECT — finite group Haar = normalized counting measure.

**Status:** PROVED (2026-08-28) — `unit_inv`, `mul_unit_bijective`, `sum_invariant`,
`measure_invariant_card`, `sum_invariant_of_invariant`, `units_counting_normalized` —
all closed by native tactics (`fin_cases`, `decide`, `ring`, `Finset.sum_*`);
zero `sorry`; `lake build Hexagon.Haar` green.

**Note on `sum_invariant`:** the naive statement `∑ x ∈ S, f (u * x) = ∑ x ∈ S, f x`
is FALSE for an arbitrary finite set `S` (it silently changes the domain of summation:
the left side sums over the image `u • S`, not over `S`). The true statement is the
change-of-variables form below — summing `f (u * x)` over `x ∈ S` equals summing `f`
over the image `u • S`. On a set stable under the action (`u • S ⊆ S`, e.g. the unit
group itself — see `units_closed_under_mul`) the naive form recovers:
`sum_invariant_of_invariant`.

**Note on the inverse table:** the six units are `⟨1,0⟩, ⟨-1,0⟩, ⟨0,1⟩, ⟨0,-1⟩,
⟨-1,1⟩, ⟨1,-1⟩`. The inverse pairs (all checked by `decide`) are `±1 ↔ ±1`,
`ω = ⟨0,1⟩ ↔ −ω² = ⟨1,-1⟩`, and `ω² = ⟨-1,1⟩ ↔ −ω = ⟨0,-1⟩`. (Beware:
`⟨-1,1⟩ · ⟨1,-1⟩ = ⟨0,1⟩ = ω`, not 1 — the inverse of `ω²` is `−ω = ⟨0,-1⟩`.)
-/

namespace Hexagon

open Eisenstein
open scoped BigOperators

/-- ω-multiplication is associative (the Eisenstein integers form a ring). -/
theorem mul_assoc (x y z : Eisenstein) : x * (y * z) = (x * y) * z := by
  rcases x with ⟨a, b⟩
  rcases y with ⟨c, d⟩
  rcases z with ⟨e, f⟩
  change Eisenstein.mk (a * (c * e - d * f) - b * (c * f + d * e + d * f))
      (a * (c * f + d * e + d * f) + b * (c * e - d * f) + b * (c * f + d * e + d * f))
    = Eisenstein.mk ((a * c - b * d) * e - (a * d + b * c + b * d) * f)
      ((a * c - b * d) * f + (a * d + b * c + b * d) * e + (a * d + b * c + b * d) * f)
  ext <;> ring

/-- `1` is a left identity for ω-multiplication. -/
theorem one_mul (x : Eisenstein) : (1 : Eisenstein) * x = x := by
  rcases x with ⟨a, b⟩
  change Eisenstein.mk (1 * a - 0 * b) (1 * b + 0 * a + 0 * b) = Eisenstein.mk a b
  ext <;> ring

/-- A1.1: every unit has a multiplicative inverse that is also a unit (Z₆ is a group). -/
theorem unit_inv (u : Eisenstein) (hu : u ∈ units) :
    ∃ v : Eisenstein, v ∈ units ∧ u * v = 1 ∧ v * u = 1 := by
  fin_cases hu <;> first
    | exact ⟨⟨1, 0⟩, by decide, by decide, by decide⟩
    | exact ⟨⟨-1, 0⟩, by decide, by decide, by decide⟩
    | exact ⟨⟨0, 1⟩, by decide, by decide, by decide⟩
    | exact ⟨⟨0, -1⟩, by decide, by decide, by decide⟩
    | exact ⟨⟨-1, 1⟩, by decide, by decide, by decide⟩
    | exact ⟨⟨1, -1⟩, by decide, by decide, by decide⟩

/-- A1.2: left multiplication by a unit is a bijection of the lattice (isotropy). -/
theorem mul_unit_bijective (u : Eisenstein) (hu : u ∈ units) :
    Function.Bijective (fun x : Eisenstein => u * x) := by
  rcases unit_inv u hu with ⟨v, _, hleft, hright⟩
  constructor
  · intro a₁ a₂ h
    change u * a₁ = u * a₂ at h
    calc
      a₁ = 1 * a₁ := (one_mul a₁).symm
      _ = (v * u) * a₁ := by rw [hright]
      _ = v * (u * a₁) := (mul_assoc v u a₁).symm
      _ = v * (u * a₂) := by rw [h]
      _ = (v * u) * a₂ := mul_assoc v u a₂
      _ = 1 * a₂ := by rw [hright]
      _ = a₂ := one_mul a₂
  · intro b
    refine ⟨v * b, ?_⟩
    change u * (v * b) = b
    rw [mul_assoc, hleft, one_mul]

/-- A1.3: the counting measure is invariant under the Z₆ action — a finite sum of
    `f (u * x)` over `x ∈ S` equals the same sum of `f` over the image `u • S`. -/
theorem sum_invariant (u : Eisenstein) (hu : u ∈ units) (S : Finset Eisenstein)
    (f : Eisenstein → ℕ) :
    (∑ x ∈ S, f (u * x)) = ∑ x ∈ S.image (fun x => u * x), f x := by
  exact (Finset.sum_image (by
    intro x hx y hy hxy
    exact (mul_unit_bijective u hu).1 hxy)).symm

/-- A1.3′: the cardinality (counting measure) of a finite set is unchanged by the
    action of a unit: `|u • S| = |S|`. -/
theorem measure_invariant_card (u : Eisenstein) (hu : u ∈ units) (S : Finset Eisenstein) :
    (S.image (fun x => u * x)).card = S.card := by
  exact Finset.card_image_of_injOn (by
    intro x hx y hy hxy
    exact (mul_unit_bijective u hu).1 hxy)

/-- A1.3″: on a set `S` stable under the action (`u • S ⊆ S`, a finite union of
    orbits), the naive translation-invariance statement holds. -/
theorem sum_invariant_of_invariant (u : Eisenstein) (hu : u ∈ units) (S : Finset Eisenstein)
    (hclosed : ∀ x ∈ S, u * x ∈ S) (f : Eisenstein → ℕ) :
    (∑ x ∈ S, f (u * x)) = ∑ x ∈ S, f x := by
  have hsub : S.image (fun x => u * x) ⊆ S := by
    intro y hy
    rcases Finset.mem_image.mp hy with ⟨x, hx, rfl⟩
    exact hclosed x hx
  have heq : S.image (fun x => u * x) = S := by
    exact Finset.eq_of_subset_of_card_le hsub (by rw [measure_invariant_card u hu S])
  calc
    (∑ x ∈ S, f (u * x)) = ∑ x ∈ S.image (fun x => u * x), f x := sum_invariant u hu S f
    _ = ∑ x ∈ S, f x := by rw [heq]

/-- A1.4: the normalized counting measure on the six units is a probability measure:
    each unit gets equal weight `1/6`, and the weights sum to 1. (Translation
    invariance of this measure follows from `sum_invariant_of_invariant`: the unit
    action permutes the set `units` — see `units_closed_under_mul` — so
    `∑ u ∈ units, w (g * u) = ∑ u ∈ units, w u` for any weight function `w`.) -/
theorem units_counting_normalized : (∑ _u ∈ units, (1 / 6 : ℚ)) = 1 := by
  rw [Finset.sum_const, units_card, nsmul_eq_mul]
  norm_num

end Hexagon
