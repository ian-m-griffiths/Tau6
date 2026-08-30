/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions
import Hexagon.Conjugate

/-!
# Dot & Wedge — the scalar/bivector split of the geometric product (TDOT + TWEDGE)

**Idea history:** Ian (2026-08-29) GA instructions `TDOT`/`TWEDGE` (docs/GA_INSTRUCTIONS.md):
the geometric product `z·w̄` splits into a symmetric scalar (dot = correlation) and an
anti-symmetric bivector part (wedge = curl/circulation). The rebuild's wedge is the SKEW part
(Hestenes-Sobczyk: "determined by its curl"), NOT bivector area.

**Calibration:** DIRECT — the standard real/imaginary split on ℤ[ω]; `dot = Re(z·w̄)`,
`wedge = Im(z·w̄)`.

**Status:** PROVED (2026-08-29) — `gp_decomp`, `wedge_antisymm`, `dot_self`, `wedge_self`,
`dot_sq_add_wedge_sq` closed; the original `dot_comm` was FALSE (the raw `a`-coordinate is not
symmetric — `Re(z·w̄) = dot + wedge/2` is half-integral), replaced by the true
`dot_swap : dot z w = dot w z + wedge w z`. Uses `Conjugate.lean`.
-/

namespace Hexagon

open Eisenstein

/-- The dot (symmetric scalar) = the `a`-coordinate of `z · conj w`. -/
def dot (z w : Eisenstein) : ℤ := (z * conj w).a

/-- The wedge (anti-symmetric) = the `b`-coordinate of `z · conj w`. -/
def wedge (z w : Eisenstein) : ℤ := (z * conj w).b

/-- The geometric product decomposes as scalar + bivector: `z·conj w = dot + wedge·ω`.
    Hint: `ext <;> rfl` (dot/wedge ARE the two coordinates). -/
theorem gp_decomp (z w : Eisenstein) : z * conj w = ⟨dot z w, wedge z w⟩ := by
  ext <;> simp [dot, wedge]

/-- The dot is NOT symmetric as defined (`dot z w = (z·conj w).a = Re(z·w̄) − wedge/2`);
    swapping `z` and `w` corrects the asymmetry by exactly the wedge:
    `dot z w = dot w z + wedge w z`. (The original CONTRACT claimed `dot z w = dot w z`,
    which is FALSE — e.g. `z = ⟨1,0⟩, w = ⟨0,1⟩` gives `dot z w = 1` but `dot w z = 0`.) -/
theorem dot_swap (z w : Eisenstein) : dot z w = dot w z + wedge w z := by
  rcases z with ⟨a, b⟩
  rcases w with ⟨c, d⟩
  change (a * (c + d) - b * (-d))
    = (c * (a + b) - d * (-b)) + (c * (-b) + d * (a + b) + d * (-b))
  ring

/-- The wedge is anti-symmetric (sin θ = curl flips sign under swap). Hint: `rcases` + `change`
    + `ring` (or use `conj_mul` + `mul_comm`). -/
theorem wedge_antisymm (z w : Eisenstein) : wedge z w = - wedge w z := by
  rcases z with ⟨a, b⟩
  rcases w with ⟨c, d⟩
  change (a * (-d) + b * (c + d) + b * (-d))
    = -(c * (-b) + d * (a + b) + d * (-b))
  ring

/-- `dot z z = norm z` — the self-dot is the norm (from `mul_conj_eq_norm`). -/
theorem dot_self (z : Eisenstein) : dot z z = norm z := by
  change (z * conj z).a = norm z
  rw [mul_conj_eq_norm]

/-- `wedge z z = 0` — the self-wedge vanishes (no area spanned by a single vector). -/
theorem wedge_self (z : Eisenstein) : wedge z z = 0 := by
  change (z * conj z).b = 0
  rw [mul_conj_eq_norm]

/-- The Pythagorean identity: `dot² + wedge² = N(z)·N(w)` — the full energy decomposition.
    Hint: `norm` is multiplicative (`norm_mul`), and `N(z·conj w) = N(z)·N(conj w) = N(z)·N(w)`;
    unfold `dot`/`wedge` and use `change (…).a^2 + (…).a*(…).b + (…).b^2 = …`
    + `ring`/`nlinarith`. -/
theorem dot_sq_add_wedge_sq (z w : Eisenstein) :
    dot z w ^ 2 + dot z w * wedge z w + wedge z w ^ 2 = norm z * norm w := by
  change norm (z * conj w) = norm z * norm w
  rw [norm_mul, conj_norm]

end Hexagon
