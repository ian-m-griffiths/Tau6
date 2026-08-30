/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions

/-!
# Conjugate — the Eisenstein conjugate `a+bω ↦ (a+b)−bω` (TCONJ)

**Idea history:** Ian (2026-08-29) GA instruction `TCONJ` (docs/GA_INSTRUCTIONS.md): the
coordinate mirror `ω̄ = 1−ω`; needed for the dot/wedge split of the geometric product.

**Calibration:** DIRECT — the standard complex-conjugate on ℤ[ω]; the norm is `z·z̄`.

**Status:** PROVED (2026-08-29) — `conj_involutive`, `conj_norm`, `conj_mul`, and
`mul_conj_eq_norm` (`z·z̄ = N(z)`) closed by native tactics (`rcases`/`change`/`ext`/`ring`).
`ω = e^(iπ/3)`, `ω̄ = ω⁻¹ = 1 − ω`, so `conj(a,b) = (a+b, −b)`.
-/

namespace Hexagon

open Eisenstein

/-- The conjugate: `a+bω ↦ (a+b)−bω` (since `ω̄ = 1−ω`). -/
def conj (z : Eisenstein) : Eisenstein := ⟨z.a + z.b, -z.b⟩

/-- The conjugate is an involution. Hint: `rcases` + `ext <;> ring`. -/
theorem conj_involutive (z : Eisenstein) : conj (conj z) = z := by
  rcases z with ⟨a, b⟩
  change Eisenstein.mk ((a + b) + (-b)) (-(-b)) = Eisenstein.mk a b
  ext <;> ring

/-- The conjugate preserves the norm. Hint: `rcases` + `change norm ⟨…⟩ = norm ⟨…⟩` + `ring`. -/
theorem conj_norm (z : Eisenstein) : norm (conj z) = norm z := by
  rcases z with ⟨a, b⟩
  change (a + b) ^ 2 + (a + b) * (-b) + (-b) ^ 2 = a ^ 2 + a * b + b ^ 2
  ring_nf

/-- The conjugate is a ring automorphism: `conj(z·w) = conj z · conj w`. Hint: `rcases`,
    `change Eisenstein.mk … = Eisenstein.mk …` on both sides (Mul instance won't auto-unfold),
    `ext <;> ring`. -/
theorem conj_mul (z w : Eisenstein) : conj (z * w) = conj z * conj w := by
  rcases z with ⟨a, b⟩
  rcases w with ⟨c, d⟩
  change Eisenstein.mk ((a * c - b * d) + (a * d + b * c + b * d))
      (-(a * d + b * c + b * d))
    = Eisenstein.mk ((a + b) * (c + d) - (-b) * (-d))
      ((a + b) * (-d) + (-b) * (c + d) + (-b) * (-d))
  ext <;> ring

/-- `z · conj z = N(z)` — the product with the conjugate is the (real) norm. This is the key
    fact that makes the dot/wedge split work. Hint: `rcases z with ⟨a,b⟩`, `change` the Mul
    to explicit components, `ext <;> ring`. -/
theorem mul_conj_eq_norm (z : Eisenstein) : z * conj z = ⟨norm z, 0⟩ := by
  rcases z with ⟨a, b⟩
  change Eisenstein.mk (a * (a + b) - b * (-b)) (a * (-b) + b * (a + b) + b * (-b))
    = Eisenstein.mk (a ^ 2 + a * b + b ^ 2) 0
  ext <;> ring

end Hexagon
