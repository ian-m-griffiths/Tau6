/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions

/-!
# The 60° ↔ 120° Eisenstein convention bridge — they are the SAME ring

**Idea history:** the rebuild's `gauge_int.rs` uses ω' = e^(2πi/3) (120°, norm a²−ab+b²),
while this project's `Conventions.lean` uses ω = e^(iπ/3) (60°, norm a²+ab+b²). Ian (2026):
"the 120 may be bad… I think it is just a normalisation difference… would be great if
it's all the same."

**The math:** ω' = ω² = ω − 1, so ℤ[ω'] = ℤ[ω] (the same ring, different generator). The
isomorphism is φ(a,b) = (a, −b): it interchanges the 60° and 120° multiplications and
preserves the norm.

**Calibration:** DIRECT — a ring isomorphism.

**Status:** PROVED (2026-08-28) — `phi_add`, `phi_mul`, `phi_phi`, `norm_preserved` all
closed by the `rcases` + `change` + `ext <;> ring` pattern (native tactics, no `sorry`).
`phi_mul` is the crux: φ interchanges the 60° and 120° multiplications, so the two
conventions are the same ring. `lake build Hexagon.ConventionBridge` green.
-/

namespace Hexagon

open Eisenstein

/-- The 120° multiplication: (a+bω')(c+dω') = (ac−bd) + (ad+bc−bd)ω', ω'² = −ω'−1. -/
def mul120 (x y : Eisenstein) : Eisenstein :=
  ⟨x.a * y.a - x.b * y.b, x.a * y.b + x.b * y.a - x.b * y.b⟩

/-- The 120° norm: N'(a+bω') = a² − ab + b². -/
def norm120 (x : Eisenstein) : ℤ := x.a ^ 2 - x.a * x.b + x.b ^ 2

/-- The isomorphism φ(a,b) = (a, −b). -/
def phi (x : Eisenstein) : Eisenstein := ⟨x.a, -x.b⟩

/-- φ is an additive homomorphism: φ(x + y) = φx + φy. -/
theorem phi_add (x y : Eisenstein) : phi (x + y) = phi x + phi y := by
  rcases x with ⟨a, b⟩
  rcases y with ⟨c, d⟩
  change Eisenstein.mk (a + c) (-(b + d)) = Eisenstein.mk (a + c) (-b + -d)
  ext <;> ring

/-- φ interchanges the 60° and 120° multiplications: φ(x·y) = φx ⋆ φy. -/
theorem phi_mul (x y : Eisenstein) : phi (x * y) = mul120 (phi x) (phi y) := by
  rcases x with ⟨a, b⟩
  rcases y with ⟨c, d⟩
  change Eisenstein.mk (a * c - b * d) (-(a * d + b * c + b * d))
      = Eisenstein.mk (a * c - (-b) * (-d)) (a * (-d) + (-b) * c - (-b) * (-d))
  ext <;> ring

/-- φ is an involution, hence bijective: φ(φx) = x. -/
theorem phi_phi (x : Eisenstein) : phi (phi x) = x := by
  rcases x with ⟨a, b⟩
  change Eisenstein.mk a (-(-b)) = Eisenstein.mk a b
  ext <;> ring

/-- The norm is preserved: N(x) = N'(φx) (N60 = N120 ∘ φ). -/
theorem norm_preserved (x : Eisenstein) : Eisenstein.norm x = norm120 (phi x) := by
  rcases x with ⟨a, b⟩
  change a ^ 2 + a * b + b ^ 2 = a ^ 2 - a * (-b) + (-b) ^ 2
  ring

end Hexagon
