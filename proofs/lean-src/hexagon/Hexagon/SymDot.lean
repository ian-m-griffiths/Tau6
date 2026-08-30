/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions
import Hexagon.Conjugate
import Hexagon.DotWedge

/-!
# SymDot — the symmetric integer correlation (polarization of the norm)

**Idea history:** Ian (2026-08-29) — `DotWedge.lean` found the raw `dot` (the `.a` coordinate
of `z·conj w`) is NOT symmetric (`dot_swap : dot z w = dot w z + wedge w z`; `Re(z·w̄)` is
half-integral). The clean INTEGER symmetric correlation is the POLARIZATION of the norm:
`symdot z w = N(z+w) − N(z) − N(w) = 2·Re(z·w̄) = 2·dot + wedge`, symmetric by construction.

**Calibration:** DIRECT — the polarization identity of the quadratic form `N = a²+ab+b²`;
its polarization `2·Re(z·w̄)` is the symmetric bilinear form pairing the norm's two slots.

**Status:** PROVED (2026-08-29) — `symdot_comm`, `symdot_self`,
`symdot_eq_two_dot_add_wedge`, `symdot_nonneg` closed by native tactics
(`rcases`/`change`/`ring`/`ring_nf`/`nlinarith`). Uses `Conjugate.lean` + `DotWedge.lean`.
-/

namespace Hexagon

open Eisenstein

/-- The polarization of the norm — the symmetric integer correlation:
    `N(z+w) − N(z) − N(w) = 2·Re(z·w̄) = 2·dot z w + wedge z w`. -/
def symdot (z w : Eisenstein) : ℤ := norm (z + w) - norm z - norm w

/-- `symdot` is symmetric: the polarization of a quadratic form is a symmetric bilinear form.
    (No `AddCommMagma` instance exists yet — the bare `Add` from `Conventions.lean` is enough
    once the operands are `rcases`-ed to ℤ components.) -/
theorem symdot_comm (z w : Eisenstein) : symdot z w = symdot w z := by
  rcases z with ⟨a, b⟩
  rcases w with ⟨c, d⟩
  change (a + c) ^ 2 + (a + c) * (b + d) + (b + d) ^ 2
      - (a ^ 2 + a * b + b ^ 2) - (c ^ 2 + c * d + d ^ 2)
    = (c + a) ^ 2 + (c + a) * (d + b) + (d + b) ^ 2
      - (c ^ 2 + c * d + d ^ 2) - (a ^ 2 + a * b + b ^ 2)
  ring

/-- `symdot z z = 2·N(z)` — the norm is quadratic, so `N(z+z) = N(2·z) = 4·N(z)`. -/
theorem symdot_self (z : Eisenstein) : symdot z z = 2 * norm z := by
  rcases z with ⟨a, b⟩
  change (a + a) ^ 2 + (a + a) * (b + b) + (b + b) ^ 2
      - (a ^ 2 + a * b + b ^ 2) - (a ^ 2 + a * b + b ^ 2)
    = 2 * (a ^ 2 + a * b + b ^ 2)
  ring_nf

/-- The relation `2·Re = 2·(a-coord) + (b-coord)`: `symdot z w = 2·dot z w + wedge z w`.
    Both sides reduce to `2ac + ad + bc + 2bd`. -/
theorem symdot_eq_two_dot_add_wedge (z w : Eisenstein) :
    symdot z w = 2 * dot z w + wedge z w := by
  rcases z with ⟨a, b⟩
  rcases w with ⟨c, d⟩
  change (a + c) ^ 2 + (a + c) * (b + d) + (b + d) ^ 2
      - (a ^ 2 + a * b + b ^ 2) - (c ^ 2 + c * d + d ^ 2)
    = 2 * (a * (c + d) - b * (-d)) + (a * (-d) + b * (c + d) + b * (-d))
  ring_nf

/-- `symdot z z ≥ 0` — the self-correlation is a nonnegative multiple of the norm
    (via `symdot_self`; `N = a²+ab+b² = ((a+b)² + a² + b²)/2 ≥ 0`). -/
theorem symdot_nonneg (z : Eisenstein) : 0 ≤ symdot z z := by
  rw [symdot_self]
  rcases z with ⟨a, b⟩
  change 0 ≤ 2 * (a ^ 2 + a * b + b ^ 2)
  nlinarith [sq_nonneg (a + b), sq_nonneg a, sq_nonneg b]

end Hexagon
