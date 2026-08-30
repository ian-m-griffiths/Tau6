/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Rotation

/-!
# CRT — the six units decompose as a sign × a 3-cycle (Z₆ ≅ Z₂ × Z₃)

**Idea history:** Ian (2026) "the six units are ±1 times the three rotations 1, ω, ω²";
the Chinese Remainder Theorem `Z₆ ≅ Z₂ × Z₃` (2 and 3 are coprime), so every unit is a
SIGN (∈ {±1}) times a 3-cycle element (∈ {1, ω, ω²}); the angle index `n : Fin 6` is
recovered from `n mod 2` (the sign) and `n mod 3` (the cycle). hexigon_conversation.md
(rotation = mod-6 angle arithmetic).

**Calibration:** DIRECT — finite group theory / CRT (classical).

**Status:** PROVED (2026-08-29) — `signCycleMul_injective`, `signCycleMul_surjective`,
`signCycle_card` (`fin_cases` + `decide`), and the CRT bijection `mod6_iff_mod2_mod3`
(`Fin 6 ≃ Fin 2 × Fin 3`, `n ↦ (n % 2, n % 3)`). Zero `sorry`.
-/

namespace Hexagon

open Eisenstein

/-- The sign subgroup: ±1. -/
def sign : Finset Eisenstein := {⟨1, 0⟩, ⟨-1, 0⟩}

/-- The 3-cycle subgroup: {1, ω, ω²} (ω = ⟨0,1⟩, ω² = ω−1 = ⟨-1,1⟩). -/
def cycle : Finset Eisenstein := {⟨1, 0⟩, ⟨0, 1⟩, ⟨-1, 1⟩}

/-- There are two signs. -/
theorem sign_card : sign.card = 2 := by
  decide

/-- There are three cycle elements. -/
theorem cycle_card : cycle.card = 3 := by
  decide

/-- The sign subgroup is contained in the units. -/
theorem sign_subset_units : sign ⊆ units := by
  intro x hx
  fin_cases hx <;> decide

/-- The 3-cycle is contained in the units. -/
theorem cycle_subset_units : cycle ⊆ units := by
  intro x hx
  fin_cases hx <;> decide

/-- The CRT map: `(s, c) ↦ s * c`, from `sign × cycle` into the units. -/
def signCycleMul (sc : {x : Eisenstein // x ∈ sign} × {x : Eisenstein // x ∈ cycle}) :
    {x : Eisenstein // x ∈ units} :=
  ⟨sc.1.1 * sc.2.1,
    units_closed_under_mul _ _ (sign_subset_units sc.1.2) (cycle_subset_units sc.2.2)⟩

/-- The 6 units, as a subtype. -/
theorem unitsSubtype_card : Fintype.card {x : Eisenstein // x ∈ units} = 6 := by
  decide

/-- The CRT map is surjective: every unit is ±1 times a 3-cycle element. -/
theorem signCycleMul_surjective : Function.Surjective signCycleMul := by
  intro u
  rcases u with ⟨u, hu⟩
  fin_cases hu
  · exact ⟨(⟨⟨1, 0⟩, by decide⟩, ⟨⟨1, 0⟩, by decide⟩), by decide⟩
  · exact ⟨(⟨⟨-1, 0⟩, by decide⟩, ⟨⟨1, 0⟩, by decide⟩), by decide⟩
  · exact ⟨(⟨⟨1, 0⟩, by decide⟩, ⟨⟨0, 1⟩, by decide⟩), by decide⟩
  · exact ⟨(⟨⟨-1, 0⟩, by decide⟩, ⟨⟨0, 1⟩, by decide⟩), by decide⟩
  · exact ⟨(⟨⟨1, 0⟩, by decide⟩, ⟨⟨-1, 1⟩, by decide⟩), by decide⟩
  · exact ⟨(⟨⟨-1, 0⟩, by decide⟩, ⟨⟨-1, 1⟩, by decide⟩), by decide⟩

/-- `sign × cycle` has 6 elements — matching the 6 units (`units_card` in Rotation.lean). -/
theorem signCycle_card :
    Fintype.card ({x : Eisenstein // x ∈ sign} × {x : Eisenstein // x ∈ cycle}) = 6 := by
  decide

/-- The CRT map is injective: it is surjective between two 6-element sets, so (by the finite
    pigeonhole principle, `Fintype.bijective_iff_surjective_and_card`) it is bijective. -/
theorem signCycleMul_injective : Function.Injective signCycleMul := by
  have hbi : Function.Bijective signCycleMul := by
    rw [Fintype.bijective_iff_surjective_and_card]
    exact ⟨signCycleMul_surjective, by rw [signCycle_card, unitsSubtype_card]⟩
  exact hbi.1

/-! ## CRT on the angle index: `Fin 6 ≃ Fin 2 × Fin 3` -/

/-- `n ↦ (n mod 2, n mod 3)`: the angle index's sign (mod 2) and cycle (mod 3). -/
def modPair (n : Fin 6) : Fin 2 × Fin 3 :=
  (⟨n.val % 2, Nat.mod_lt _ (by decide)⟩, ⟨n.val % 3, Nat.mod_lt _ (by decide)⟩)

/-- The CRT inverse: `(a, b) ↦ 3a + 4b (mod 6)`. Mod 2 this is `a` (3≡1, 4≡0); mod 3 it is
    `b` (3≡0, 4≡1). -/
def crtInv (p : Fin 2 × Fin 3) : Fin 6 :=
  ⟨(3 * p.1.val + 4 * p.2.val) % 6, Nat.mod_lt _ (by decide)⟩

/-- `mod6_iff_mod2_mod3`: an angle index `n : Fin 6` is determined by `n mod 2` (the sign)
    and `n mod 3` (the cycle) — the CRT bijection `Fin 6 ≃ Fin 2 × Fin 3`. -/
def mod6_iff_mod2_mod3 : Fin 6 ≃ Fin 2 × Fin 3 where
  toFun := modPair
  invFun := crtInv
  left_inv := by
    intro n
    fin_cases n <;> decide
  right_inv := by
    intro p
    rcases p with ⟨p1, p2⟩
    fin_cases p1 <;> fin_cases p2 <;> decide

/-- The angle-index map is bijective. -/
theorem modPair_bijective : Function.Bijective modPair := mod6_iff_mod2_mod3.bijective

end Hexagon
