/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions

/-!
# Offset grid — the hex lattice as offset square columns (brick wall)

**Idea history:** Ian (2026-08-28): "a hexagon can be modeled by columns of squares
that are 0.5 off from each other... we can address as a rectangle".

**Calibration:** DIRECT — axial coordinates are already ℤ×ℤ (the rectangle); the
"0.5 off" brick wall is the checkerboard embedding (a,b) ↦ (2a+b, b), whose image
is exactly the pairs with matching parity. This is the standard hex-grid "offset
coordinates" (odd-r).

**Status:** PROVED (2026-08-28) — all theorems closed by native tactics
(`omega` + `ext` + `simp`); `lake build` green.
-/

namespace Hexagon

open Eisenstein

/-- The brick-wall ("offset") embedding of the hex lattice into the square grid:
    axial (a,b) sits at (col,row) = (2a+b, b) — adjacent rows shift by one column,
    so every other square is used, offset by one per row. -/
def offset (x : Eisenstein) : ℤ × ℤ := (2 * x.a + x.b, x.b)

/-- The inverse on the image: from (c,b) with c ≡ b (mod 2), recover a = (c-b)/2. -/
def offsetInv (c b : ℤ) (_h : c % 2 = b % 2) : Eisenstein :=
  ⟨(c - b) / 2, b⟩

/-- The offset map is injective (the hex lattice embeds into the square grid).
    Hint: `2a+b = 2a'+b'` and `b = b'` give `2a = 2a'` then `a = a'` by `omega`/`ring`. -/
theorem offset_injective : Function.Injective (fun x : Eisenstein => offset x) := by
  intro x y h
  unfold offset at h
  have hf : 2 * x.a + x.b = 2 * y.a + y.b := congrArg Prod.fst h
  have hs : x.b = y.b := congrArg Prod.snd h
  have ha : x.a = y.a := by omega
  ext <;> assumption

/-- The image is exactly the checkerboard: (c,b) is a hex cell iff c ≡ b (mod 2).
    Hint: forward — `c - b = 2a`; backward — take `a = (c-b)/2` and use the mod
    hypothesis via `omega` or `Int.ediv_mul_cancel`. -/
theorem offset_image_iff (c b : ℤ) :
    (∃ x : Eisenstein, offset x = (c, b)) ↔ c % 2 = b % 2 := by
  constructor
  · rintro ⟨x, hx⟩
    unfold offset at hx
    have hf : 2 * x.a + x.b = c := congrArg Prod.fst hx
    have hs : x.b = b := congrArg Prod.snd hx
    omega
  · intro h
    refine ⟨offsetInv c b h, ?_⟩
    unfold offset offsetInv
    change (2 * ((c - b) / 2) + b, b) = (c, b)
    ext <;> omega

/-- `offsetInv` is a right inverse of `offset` on the checkerboard. Hint: unfold both,
    then `omega` (using `h : c % 2 = b % 2` to drop the /2) or `Int.ediv_mul_cancel`. -/
theorem offset_offsetInv (c b : ℤ) (h : c % 2 = b % 2) :
    offset (offsetInv c b h) = (c, b) := by
  unfold offset offsetInv
  change (2 * ((c - b) / 2) + b, b) = (c, b)
  ext <;> omega

/-- Round-trip on the hex side: every hex cell is recovered from its offset image
    (left inverse). This plus `offset_offsetInv` makes `offset` a bijection onto the
    checkerboard — the hex grid IS the offset square grid. -/
theorem offsetInv_offset (x : Eisenstein) :
    offsetInv (offset x).1 (offset x).2 (by
      -- the parity condition holds on the image
      simp [offset]) = x := by
  rcases x with ⟨a, b⟩
  unfold offset offsetInv
  change Eisenstein.mk ((2 * a + b - b) / 2) b = Eisenstein.mk a b
  have h1 : (2 * a + b - b) / 2 = a := by omega
  exact Eisenstein.ext h1 rfl

end Hexagon
