/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Residual

/-!
# The rebuild's register ladder — raw / fold / z / surprise, and the gauge transform closure

**Idea history:** the rebuild's `gauge.rs` (register stack raw `E·δ`, fold `δ`, z `√E·δ`,
surprise `E·δ²`) and LATTICE_MATH.md; the porting map flagged this as the top B→A
formalization (settles gauge.rs's "PROVE-THE-MATH #3" untested flag).

**Calibration:** DIRECT — standard statistics (Pearson residual, χ² fold).

**Status:** PROVED (2026-08-28) — the register ladder closed by native tactics
(`field_simp` + `ring`), no `sorry` remaining:
1. `δ_eq_residual_div` (fold δ = O/E − 1 is the Pearson residual r/E) + `mul_delta_eq_residual`
   (raw rung E·δ = r),
2. `surprise_eq_delta_sq_mul_E` (surprise = δ²·E — the register-ladder relation),
3. `surprise_sign_collapse` + `surprise_nonneg` (χ² collapses the residual's sign; plus a
   concrete witness that `surprise a b = surprise b a` fails in general),
4. `wedge_eq_residual_skew` + `sym_plus_skew` (wedge = skew part, citing `wedge_antisymm`
   from `Hexagon.Residual`).
`lake build Hexagon.Registers` green.
-/

namespace Lattice

-- Build on `Hexagon.Residual` (E, residual r = O−E, ringSq, wedge) — nothing here is
-- redefined; the register ladder is expressed in terms of the existing objects. All
-- arithmetic in ℚ, so division by E is exact (the field convention gives 0 when E = 0).

variable {V : Type} [Fintype V] [DecidableEq V]

/-- 1. The fold / lift `δ(a,b) = O(a,b)/E(a,b) − 1`: the multiplicative excess of the
observed count over the independence null, re-centred at 0 (the gauge.rs "fold" register). -/
def δ (O : V × V → ℕ) (f : V → ℕ) (a b : V) : ℚ :=
  (O (a, b) : ℚ) / E f a b - 1

/-- 2. The surprise / χ² term: `(residual)² / E` — one summand of ring², the
register-ladder "surprise" register `E·δ²`. -/
def surprise (O : V × V → ℕ) (f : V → ℕ) (a b : V) : ℚ :=
  (residual O f a b) ^ 2 / E f a b

-- The theorems below need only `[Fintype V]` (for `E` / `residual`), not `[DecidableEq V]`.
omit [DecidableEq V]

/-- 1. The fold is the residual divided by the expected count:
`δ = (O−E)/E = r/E` — the Pearson-residual form of the register. -/
theorem δ_eq_residual_div (O : V × V → ℕ) (f : V → ℕ) (a b : V) (hE : E f a b ≠ 0) :
    δ O f a b = residual O f a b / E f a b := by
  unfold δ residual
  field_simp [hE]

/-- 1b. The raw register's bottom rung: `E·δ = r` — multiplying the fold by the expected
count recovers the signed residual. -/
theorem mul_delta_eq_residual (O : V × V → ℕ) (f : V → ℕ) (a b : V) (hE : E f a b ≠ 0) :
    E f a b * δ O f a b = residual O f a b := by
  unfold δ residual
  field_simp [hE]

/-- 2. The register-ladder relation: surprise = δ²·E — the surprise register is the
square of the fold register rescaled by the expected count. -/
theorem surprise_eq_delta_sq_mul_E (O : V × V → ℕ) (f : V → ℕ) (a b : V) (hE : E f a b ≠ 0) :
    surprise O f a b = (δ O f a b) ^ 2 * E f a b := by
  unfold surprise δ residual
  field_simp [hE]

/-- `E ≥ 0`: the independence null is a nonnegative expected count (needed for the
surprise's nonnegativity). -/
theorem E_nonneg (f : V → ℕ) (a b : V) : 0 ≤ E f a b := by
  unfold E
  apply div_nonneg
  · exact mul_nonneg (by exact_mod_cast Nat.zero_le (f a)) (by exact_mod_cast Nat.zero_le (f b))
  · exact_mod_cast Nat.zero_le (T f)

/-- 3b. The surprise is nonnegative: `r²/E ≥ 0` — squaring collapses the sign of the
residual, so the surprise register never distinguishes attract (`r < 0`) from repel. -/
theorem surprise_nonneg (O : V × V → ℕ) (f : V → ℕ) (a b : V) :
    0 ≤ surprise O f a b := by
  unfold surprise
  apply div_nonneg
  · exact sq_nonneg _
  · exact E_nonneg f a b

-- 4. The wedge is the skew part: `wedge_antisymm` (Hexagon.Residual) already proves
-- `wedge(a,b) = − wedge(b,a)` — referenced here, not re-proved. The statements below
-- are `V`-free or need only the explicit binders, so drop the section variables.

omit [Fintype V] [DecidableEq V]

/-- 3. The surprise of a signed residual `r` against an expected count `e`: `r²/e`. -/
def surpriseOf (r : ℚ) (e : ℚ) : ℚ :=
  r ^ 2 / e

/-- 3. Sign collapse — Surprise is not injective in the sign of the residual:
the surprise of `r` equals the surprise of `−r` ("squaring kills the sign"). This is
why the χ² magnitude is ORDER, not surprise: the sign (attract/repel) lives in the
residual register, not in the surprise register. -/
theorem surprise_sign_collapse (r e : ℚ) : surpriseOf r e = surpriseOf (-r) e := by
  unfold surpriseOf
  ring

/-- 3c. Concrete witness that Surprise is not injective in the pair:
`surprise(a,b) = surprise(b,a)` fails in general (a repulsive pair can masquerade as
an attractive one, or vice versa). On `Bool` with `O(⊤,⊥) = 2`, all other `O = 0`,
and constant `f = 1`: `surprise(⊤,⊥) = 9/2 ≠ 1/2 = surprise(⊥,⊤)`. -/
example : ¬ (∀ O : Bool × Bool → ℕ, ∀ f : Bool → ℕ, ∀ a b : Bool,
    surprise O f a b = surprise O f b a) := by
  push Not
  refine ⟨fun p => if p = (true, false) then 2 else 0, fun _ => 1, true, false, ?_⟩
  unfold surprise residual E
  have hT : (T (fun _ : Bool => 1) : ℚ) = 2 := by
    unfold T
    decide
  rw [hT]
  simp
  norm_num

/-- 4. The wedge is the skew part of the residual as well: since `E` is symmetric in
`a, b`, the skew `r(a,b) − r(b,a)` of the residual equals the skew `O(a,b) − O(b,a)`
of the observed table — the E-terms cancel. -/
theorem wedge_eq_residual_skew (V : Type) [Fintype V] (O : V × V → ℕ) (f : V → ℕ)
    (a b : V) :
    (wedge V O a b : ℚ) = residual O f a b - residual O f b a := by
  unfold wedge residual E
  push_cast
  ring

/-- 4b. The Helmholtz-style split: the observed table decomposes into its symmetric
part `(O(a,b)+O(b,a))/2` plus its antisymmetric (skew / wedge) part
`(O(a,b)−O(b,a))/2`. -/
theorem sym_plus_skew (V : Type) (O : V × V → ℕ) (a b : V) :
    (O (a, b) : ℚ) =
      ((O (a, b) : ℚ) + (O (b, a) : ℚ)) / 2 + ((O (a, b) : ℚ) - (O (b, a) : ℚ)) / 2 := by
  ring

end Lattice
