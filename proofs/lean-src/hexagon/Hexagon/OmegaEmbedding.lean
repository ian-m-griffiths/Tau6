/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions

/-!
# The ℂ-embedding `e^(iπ/3) = ω` — the abstract Eisenstein ring embeds as the 60° lattice

**Idea history:** Ian (2026) "einstein triangles of 60 degrees" (hexigon_conversation.md
L10005–10105, L11544); the diamond motif. The abstract ring `ℤ[ω]` (`Conventions.lean`,
`ω² = ω − 1`, norm `a² + ab + b²`) embeds into `ℂ` by sending `ω ↦ e^(iπ/3) = 1/2 + √3/2·i`:
the two Eisenstein basis vectors `1` and `ω` land on the two unit vectors at a 60° angle, so
`φ(ℤ[ω])` is exactly the 60° lattice (the hexagonal lattice).

**Calibration:** DIRECT — a ring homomorphism `ℤ[ω] → ℂ`.

**Convention note:** the generator here is `ω = e^(iπ/3)` (60°), matching `Conventions.lean`
(norm `a² + ab + b²`); mathlib's `EisensteinInt` uses `ω' = e^(2πi/3)` (120°) — see the
proven bridge in `ConventionBridge.lean`.

**Status:** PROVED (2026-08-29) — `omega_sq_rel` (Euler's formula at `π/3` + `ring`/`norm_num`),
`phi_add` and `phi_mul` (ring homomorphism; `phi_mul` uses `omega_sq_rel`), `phi_omega`, and
`phi_injective` (re/im recovery with `mul_right_cancel₀` and `linarith`) all green, zero `sorry`.
-/

namespace Hexagon

namespace OmegaEmbedding

open Eisenstein
open Complex
open scoped Real

/-- The 60° complex root of unity: `ω = e^(iπ/3)`. This is `Complex.exp (Complex.I * (Real.pi / 3))`
    (equivalently `Complex.exp (Complex.I * Real.pi / 3)`). -/
noncomputable def omegaC : ℂ := Complex.exp (Complex.I * (Real.pi / 3 : ℝ))

/-- Euler's formula at `π/3`: `ω = 1/2 + (√3/2) i`. -/
lemma omegaC_eq : omegaC = (1/2 : ℂ) + ((Real.sqrt 3 / 2 : ℝ) : ℂ) * Complex.I := by
  unfold omegaC
  have harg : Complex.I * (Real.pi / 3 : ℝ) = (Real.pi / 3 : ℝ) * Complex.I := by ring
  rw [harg]
  rw [Complex.exp_ofReal_mul_I]
  rw [Real.cos_pi_div_three, Real.sin_pi_div_three]
  norm_num

/-- `ω² = ω − 1` in ℂ (the defining relation of the Eisenstein ring, realized in ℂ). -/
theorem omega_sq_rel : omegaC ^ 2 = omegaC - 1 := by
  rw [omegaC_eq]
  norm_num [Complex.I_sq]
  ring_nf
  rw [← Complex.ofReal_pow]
  norm_num [Real.sq_sqrt]
  ring

/-- The real part of `ω` is `1/2`. -/
lemma omegaC_re : omegaC.re = (1/2 : ℝ) := by
  rw [omegaC_eq]
  norm_num [Complex.add_re, Complex.mul_re, Complex.I_re, Complex.I_im,
    Complex.ofReal_re, Complex.ofReal_im]

/-- The imaginary part of `ω` is `√3/2`. -/
lemma omegaC_im : omegaC.im = (Real.sqrt 3 / 2 : ℝ) := by
  rw [omegaC_eq]
  norm_num [Complex.add_im, Complex.mul_im, Complex.I_re, Complex.I_im,
    Complex.ofReal_re, Complex.ofReal_im]

/-- The embedding `φ : ℤ[ω] → ℂ`, `φ(a + bω) = a + b·e^(iπ/3)`. -/
noncomputable def phi (x : Eisenstein) : ℂ :=
  (x.a : ℂ) + (x.b : ℂ) * omegaC

/-- `φ` is additive: `φ (x + y) = φ x + φ y`. -/
theorem phi_add (x y : Eisenstein) : phi (x + y) = phi x + phi y := by
  rcases x with ⟨a, b⟩
  rcases y with ⟨c, d⟩
  unfold phi
  change ((a + c : ℤ) : ℂ) + ((b + d : ℤ) : ℂ) * omegaC =
      (((a : ℤ) : ℂ) + ((b : ℤ) : ℂ) * omegaC) + (((c : ℤ) : ℂ) + ((d : ℤ) : ℂ) * omegaC)
  push_cast
  ring

/-- `φ` is multiplicative: `φ (x * y) = φ x * φ y` (uses `ω² = ω − 1`). -/
theorem phi_mul (x y : Eisenstein) : phi (x * y) = phi x * phi y := by
  rcases x with ⟨a, b⟩
  rcases y with ⟨c, d⟩
  unfold phi
  change ((a * c - b * d : ℤ) : ℂ) + ((a * d + b * c + b * d : ℤ) : ℂ) * omegaC =
      (((a : ℤ) : ℂ) + ((b : ℤ) : ℂ) * omegaC) * (((c : ℤ) : ℂ) + ((d : ℤ) : ℂ) * omegaC)
  push_cast
  ring_nf
  rw [omega_sq_rel]
  ring

/-- The abstract `ω = ⟨0, 1⟩` maps to `e^(iπ/3)`. -/
theorem phi_omega : phi ⟨0, 1⟩ = omegaC := by
  unfold phi
  simp

/-- `φ` is injective: `1` and `ω` are `ℤ`-linearly independent in `ℂ` (their images have
    imaginary parts `0` and `√3/2 ≠ 0`, and distinct real parts `1` and `1/2`). -/
theorem phi_injective : Function.Injective phi := by
  intro x y h
  rcases x with ⟨a, b⟩
  rcases y with ⟨c, d⟩
  have him_eq : (b : ℝ) * (Real.sqrt 3 / 2) = (d : ℝ) * (Real.sqrt 3 / 2) := by
    have h' := congrArg Complex.im h
    unfold phi at h'
    simpa [Complex.add_im, Complex.mul_im, Complex.intCast_re, Complex.intCast_im,
      omegaC_im] using h'
  have hb : b = d := by
    have hsqrt_pos : 0 < Real.sqrt 3 := Real.sqrt_pos.2 (by norm_num)
    have hsqrt : (Real.sqrt 3 / 2 : ℝ) ≠ 0 := ne_of_gt (div_pos hsqrt_pos (by norm_num))
    have : (b : ℝ) = (d : ℝ) := mul_right_cancel₀ hsqrt him_eq
    exact_mod_cast this
  subst d
  have hre_eq : (a : ℝ) + (b : ℝ) * (1/2) = (c : ℝ) + (b : ℝ) * (1/2) := by
    have h' := congrArg Complex.re h
    unfold phi at h'
    simpa [Complex.add_re, Complex.mul_re, Complex.intCast_re, Complex.intCast_im,
      omegaC_re] using h'
  have ha : a = c := by
    have : (a : ℝ) = (c : ℝ) := by linarith
    exact_mod_cast this
  subst c
  rfl

end OmegaEmbedding
end Hexagon
