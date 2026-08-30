/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions
import Hexagon.Rotation

/-!
# Pod — the 7-hex pod = norm ≤ 1 = 7 of the 9 axial {-1,0,1}² states

**Idea history:** Ian (2026-08-28): "a trit takes up one cell, then the seven set
count have 7 trits" + "if the ram needs a backup pod... six for redundancy". The pod
is the closed radius-1 ball {0} ∪ Z₆; in axial coords (a,b) each of a,b ranges over
{-1,0,1} (9 = 3² states), and norm N(a+bω) = a²+ab+b² ≤ 1 picks exactly 7, leaving
the two norm-3 points (1,1) and (-1,-1) as the "left the pod" / carry states.

**Calibration:** DIRECT — finite arithmetic over the 9 axial states; the axial
(norm) picture of SevenHex's cube-coordinate result.

**Status:** PROVED (2026-08-28) — all four theorems closed by native tactics
(`decide`/`fin_cases`/`omega`/`nlinarith`/`ring`), zero `sorry`.
-/

namespace Hexagon

open Eisenstein

/-- The 7-hex pod: the 6 units plus the center 0 (the closed radius-1 ball). -/
def pod : Finset Eisenstein := insert ⟨0, 0⟩ units

/-- There are exactly 7 cells in the pod. -/
theorem pod_card : pod.card = 7 := by
  decide

/-- Every pod cell other than the center is a unit (and vice-versa). -/
theorem pod_mem_iff (x : Eisenstein) : x ∈ pod ↔ x = ⟨0, 0⟩ ∨ x ∈ units := by
  simp [pod]

/-- A pod cell has norm 0 (the center) or 1 (a unit). -/
theorem pod_norm_le_one (x : Eisenstein) (hx : x ∈ pod) : norm x ≤ 1 := by
  rw [pod_mem_iff] at hx
  rcases hx with rfl | hx
  · decide
  · fin_cases hx <;> decide

/-- The 9 axial states: a,b ∈ {-1,0,1}. -/
def axialNine : Finset Eisenstein :=
  (({-1, 0, 1} : Finset ℤ).product ({-1, 0, 1} : Finset ℤ)).image (fun p : ℤ × ℤ => ⟨p.1, p.2⟩)

/-- There are 9 axial states. -/
theorem axialNine_card : axialNine.card = 9 := by
  decide

/-- The two "spare" states outside the pod: (1,1) and (-1,-1), both norm 3. -/
def spare : Finset Eisenstein := {⟨1, 1⟩, ⟨-1, -1⟩}

/-- The 9 axial states split as pod + the 2 spare states. -/
theorem axialNine_eq_pod_union_spare : axialNine = pod ∪ spare := by
  decide

/-- The two spare states have norm 3 (one ring outside the pod). -/
theorem spare_norm (x : Eisenstein) (hx : x ∈ spare) : norm x = 3 := by
  fin_cases hx <;> decide

/-- The characterization: norm ≤ 1 iff in the pod. This is the theorem that pins the
    pod to exactly 7 of the 9 axial states. Hint: from `norm x ≤ 1` (a²+ab+b² ≤ 1),
    show a,b ∈ {-1,0,1} — if |a| ≥ 2 or |b| ≥ 2 then norm ≥ 3 (e.g. nlinarith) — then
    `fin_cases` over the 9 possibilities and `decide`. -/
theorem norm_le_one_iff_mem (x : Eisenstein) : norm x ≤ 1 ↔ x ∈ pod := by
  rcases x with ⟨a, b⟩
  constructor
  · intro h
    change a ^ 2 + a * b + b ^ 2 ≤ 1 at h
    have ha : a ∈ ({-1, 0, 1} : Finset ℤ) := by
      by_contra hnot
      have hcase : a ≥ 2 ∨ a ≤ -2 := by
        simp at hnot
        omega
      rcases hcase with ha2 | ha2
      · have hsq : 4 * (a ^ 2 + a * b + b ^ 2) = 3 * a ^ 2 + (2 * b + a) ^ 2 := by ring
        nlinarith
      · have hsq : 4 * (a ^ 2 + a * b + b ^ 2) = 3 * a ^ 2 + (2 * b + a) ^ 2 := by ring
        nlinarith
    have hb : b ∈ ({-1, 0, 1} : Finset ℤ) := by
      by_contra hnot
      have hcase : b ≥ 2 ∨ b ≤ -2 := by
        simp at hnot
        omega
      rcases hcase with hb2 | hb2
      · have hsq : 4 * (a ^ 2 + a * b + b ^ 2) = (2 * a + b) ^ 2 + 3 * b ^ 2 := by ring
        nlinarith
      · have hsq : 4 * (a ^ 2 + a * b + b ^ 2) = (2 * a + b) ^ 2 + 3 * b ^ 2 := by ring
        nlinarith
    fin_cases ha <;> fin_cases hb <;> first | omega | decide
  · intro hx
    exact pod_norm_le_one ⟨a, b⟩ hx

end Hexagon
