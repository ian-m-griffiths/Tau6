/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# Polar encoding — the balanced trit ↔ 2-bit translation (with a don't-care state)

**Idea history:** Ian (2026) "one-hot-per-direction" (the ternary cell, `TernaryCell.lean`);
the polar view of a trit as a sign and a magnitude: the three balanced states {−1, 0, +1}
carried on two wires, with the fourth combination (1,1) left NEVER — the don't-care that
makes the encoding injective-but-not-surjective.

**Calibration:** DIRECT — finite combinatorics.

**Status:** PROVED (2026-08-29) — `polarEncode_injective`, `polarEncode_never_eleven`,
`polarEncode_not_surjective`, `polarDecode_encode` (`fin_cases` + `decide`). Zero `sorry`.

NOTE: the names here are `polar*`-prefixed so they coexist with `TernaryCell.lean`'s
`Trit`/`encode` (which use `Bool × Bool`); this file uses `Fin 2 × Fin 2` and adds the
`decode` round-trip that `TernaryCell.lean` lacks. Imported through `Hexagon.lean`.
-/

namespace Hexagon

/-- A balanced trit: the three states {−1, 0, +1}, represented as `Fin 3` (0 = −1, 1 = 0,
    2 = +1). -/
abbrev PolarTrit := Fin 3

/-- The 2-bit encoding: +1→(0,1) = 01, 0→(0,0) = 00, −1→(1,0) = 10. The fourth combination
    (1,1) = 11 is the don't-care, never produced. -/
def polarEncode (t : PolarTrit) : Fin 2 × Fin 2 :=
  if t = 0 then (1, 0)      -- −1
  else if t = 1 then (0, 0) --  0
  else (0, 1)               -- +1

/-- The 2-bit code is never the don't-care `(1, 1)`. -/
theorem polarEncode_never_eleven (t : PolarTrit) : polarEncode t ≠ (1, 1) := by
  fin_cases t <;> decide

/-- The encoding is injective: the 3 valid trits map to 3 distinct codes. -/
theorem polarEncode_injective : Function.Injective polarEncode := by
  intro a b h
  fin_cases a <;> fin_cases b <;> simp [polarEncode] at h ⊢

/-- ... but not surjective onto `Fin 2 × Fin 2`: `(1, 1)` has no preimage (the don't-care). -/
theorem polarEncode_not_surjective : ¬ Function.Surjective polarEncode := by
  intro h
  rcases h (1, 1) with ⟨t, ht⟩
  exact polarEncode_never_eleven t ht

/-- The left-inverse: decode the 3 valid codes back to their trit. `(1,1)` falls through to
    the `−1` branch (it is never produced, so this choice is a don't-care). -/
def polarDecode (c : Fin 2 × Fin 2) : PolarTrit :=
  if c = (0, 0) then 1      -- 0
  else if c = (0, 1) then 2 -- +1
  else 0                   -- −1 (and the unused 11)

/-- Round-trip: `polarDecode (polarEncode t) = t` — decode is the left-inverse of encode. -/
theorem polarDecode_encode (t : PolarTrit) : polarDecode (polarEncode t) = t := by
  fin_cases t <;> decide

end Hexagon
