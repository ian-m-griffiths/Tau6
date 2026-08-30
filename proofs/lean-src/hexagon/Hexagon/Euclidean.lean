/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions

/-!
# T5 — ℤ[ω] is Euclidean: the geometric crux (rounding + norm compatibility)

**Idea history:** plan §5 (ℤ[ω] is a Euclidean domain / UFD); mirrors mathlib's
`NumberTheory.Zsqrtd.GaussianInt` (which proves ℤ[i] Euclidean). Ian (2026): the
"measure" here is the *count* — "absolute math" (compute in the counting measure,
display as ratios), not the probability measure that forces everything into [0,1].

**Calibration:** DIRECT — classical. The Euclidean property is what makes the
Eisenstein integers a UFD.

**Status:** the covering-radius (rounding) lemma `exists_near_int_pair` is PROVED
here — the geometric crux of "ℤ[ω] is Euclidean" (every point of the plane is within
norm < 1 of a lattice point). The `EuclideanDomain ℤ[ω]` instance is the next step:
it assembles `exists_near_int_pair` + the already-proved `norm_mul` (T1) into the
division algorithm, mirroring mathlib's `GaussianInt.norm_mod_lt` (an ℂ embedding +
`Complex.normSq` compatibility bridge is the remaining piece — the `ofReal` coercion
over `+` needs an explicit `change`/`simpa` route).
-/

namespace Hexagon

open Eisenstein
open scoped Real

/-- T5b (the covering-radius / rounding lemma): for every pair of reals `α, β`
    (the coordinates of a point in the `1, ω` basis), there are integers `a, b` with
    `(α−a)² + (α−a)(β−b) + (β−b)² < 1` — i.e. the point is within norm < 1 of a
    lattice point. This is the geometric crux of the Euclidean algorithm on ℤ[ω]. -/
theorem exists_near_int_pair (α β : ℝ) :
    ∃ a b : ℤ, ((α - (a : ℝ)) ^ 2 + (α - (a : ℝ)) * (β - (b : ℝ)) + (β - (b : ℝ)) ^ 2) < 1 := by
  refine ⟨round α, round β, ?_⟩
  set x : ℝ := α - round α
  set y : ℝ := β - round β
  have hx : |x| ≤ (1 / 2 : ℝ) := by simpa [x] using (abs_sub_round α)
  have hy : |y| ≤ (1 / 2 : ℝ) := by simpa [y] using (abs_sub_round β)
  have hx' : -(1 / 2 : ℝ) ≤ x ∧ x ≤ (1 / 2 : ℝ) := abs_le.mp hx
  have hy' : -(1 / 2 : ℝ) ≤ y ∧ y ≤ (1 / 2 : ℝ) := abs_le.mp hy
  have hxy : |x + y| ≤ (1 : ℝ) := by
    calc
      |x + y| ≤ |x| + |y| := abs_add_le x y
      _ ≤ (1 / 2 : ℝ) + (1 / 2 : ℝ) := add_le_add hx hy
      _ = 1 := by norm_num
  have hxy' : -(1 : ℝ) ≤ x + y ∧ x + y ≤ (1 : ℝ) := abs_le.mp hxy
  have hx_sq : x ^ 2 ≤ (1 / 4 : ℝ) := by nlinarith [hx'.1, hx'.2]
  have hy_sq : y ^ 2 ≤ (1 / 4 : ℝ) := by nlinarith [hy'.1, hy'.2]
  have hxy_sq : (x + y) ^ 2 ≤ (1 : ℝ) := by nlinarith [hxy'.1, hxy'.2]
  have hid : x ^ 2 + x * y + y ^ 2 = ((x + y) ^ 2 + x ^ 2 + y ^ 2) / 2 := by ring
  rw [hid]
  nlinarith [hx_sq, hy_sq, hxy_sq]

end Hexagon
