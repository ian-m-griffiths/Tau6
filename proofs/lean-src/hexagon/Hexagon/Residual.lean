/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# The rebuild's residual math — E = f(a)f(b)/T, r = O−E, ring = χ², wedge = skew

**Idea history:** the lattice rebuild (LATTICE_MATH.md, AGENTS.md canonical truth): the
stored primitive is the signed residual `r = O − E`, `E = f(a)f(b)/T` (the independence
null); three axes (correlation/surprise, wedge `O_ab−O_ba`, polarization); `ring² = Σ(O−E)²/E`
= a χ² divergence / L2 norm. ox alpha.md flagged the column-balancing identity as the key
bug fix ("forgot column balancing").

**Calibration:** DIRECT — standard statistics / linear algebra.

**Status:** PROVED (2026-08-28) — all four claims closed by native tactics
(`Finset.sum` distributivity + field/ring lemmas), no `sorry` remaining:
1. `sum_E_row` (the marginal / column-balancing identity `Σ_b E(a,b) = f(a)`),
2. `sum_residual_eq_zero` (total residual `Σ_a Σ_b (O−E) = 0` under the row-sum
   condition), 3. `wedge_antisymm` (the wedge `O_ab−O_ba` is skew),
4. `ringSq_nonneg` (ring² = χ² is a sum of nonnegative terms).
`lake build Hexagon.Residual` green.
-/

open scoped BigOperators

namespace Lattice

-- Minimal formal model over a finite vocabulary V: frequencies f : V → ℕ, total
-- T = Σ f, observed O : V × V → ℕ, expected E(a,b) = f(a)f(b)/T, residual r = O − E.
-- All arithmetic on the counts is carried in ℚ so division by T is exact.

/-- The wedge `O(a,b) − O(b,a)`: the skew part of the ordered bigram counts
(temporal precedence / curl), kept in integers. No finiteness is needed. -/
def wedge (V : Type) (O : V × V → ℕ) (a b : V) : ℤ :=
  (O (a, b) : ℤ) - (O (b, a) : ℤ)

/-- 3. The wedge is skew (antisymmetric): `wedge(a,b) = − wedge(b,a)`. -/
theorem wedge_antisymm (V : Type) (O : V × V → ℕ) (a b : V) :
    wedge V O a b = - wedge V O b a := by
  unfold wedge
  ring

variable {V : Type} [Fintype V] [DecidableEq V]

/-- The total word count `T = Σ_v f(v)`. -/
def T (f : V → ℕ) : ℕ :=
  ∑ v : V, f v

/-- The independence null: the expected bigram count `E(a,b) = f(a)f(b)/T`, in ℚ so
division is exact (when `T = 0` the field's division-by-zero convention gives `E = 0`). -/
def E (f : V → ℕ) (a b : V) : ℚ :=
  (f a : ℚ) * (f b : ℚ) / (T f : ℚ)

/-- The stored primitive: the signed directed residual `r(a,b) = O(a,b) − E(a,b)`. -/
def residual (O : V × V → ℕ) (f : V → ℕ) (a b : V) : ℚ :=
  (O (a, b) : ℚ) - E f a b

/-- ring² at `a`: the χ² divergence `Σ_b (O(a,b)−E(a,b))² / E(a,b)` (an L2 norm of
the residual, NOT Fisher information — see LATTICE_MATH.md). -/
def ringSq (O : V × V → ℕ) (f : V → ℕ) (a : V) : ℚ :=
  ∑ b : V, ((O (a, b) : ℚ) - E f a b) ^ 2 / (E f a b)

-- The theorems below need only `[Fintype V]` (for `Finset.univ`), not `[DecidableEq V]`.
omit [DecidableEq V]

/-- 1. The marginal / column-balancing identity: `Σ_b E(a,b) = f(a)`.
The expected matrix's row sums equal the frequencies — the identity ox alpha.md
flagged as the rebuild's key bug fix — provided the total `T ≠ 0`. -/
theorem sum_E_row (f : V → ℕ) (a : V) (hT : T f ≠ 0) :
    (∑ b : V, E f a b) = (f a : ℚ) := by
  unfold E
  rw [← Finset.sum_div]
  rw [← Finset.mul_sum]
  rw [show (∑ b : V, (f b : ℚ)) = (T f : ℚ) by
    rw [T]
    exact (Nat.cast_sum (Finset.univ : Finset V) f).symm]
  exact mul_div_cancel_right₀ (f a : ℚ) (by exact_mod_cast hT)

/-- 2. The total residual is zero: `Σ_a Σ_b (O(a,b) − E(a,b)) = 0`, given O's row
sums equal the frequencies and `T ≠ 0`. By symmetry, Σ O = Σ E = T. -/
theorem sum_residual_eq_zero (f : V → ℕ) (O : V × V → ℕ) (hT : T f ≠ 0)
    (h_row : ∀ a : V, ∑ b : V, O (a, b) = f a) :
    (∑ a : V, ∑ b : V, ((O (a, b) : ℚ) - E f a b)) = 0 := by
  have hO : (∑ a : V, ∑ b : V, (O (a, b) : ℚ)) = ∑ a : V, (f a : ℚ) := by
    apply Finset.sum_congr rfl
    intro a _
    rw [← Nat.cast_sum, h_row a]
  have hE : (∑ a : V, ∑ b : V, E f a b) = ∑ a : V, (f a : ℚ) := by
    apply Finset.sum_congr rfl
    intro a _
    exact sum_E_row f a hT
  simp_rw [Finset.sum_sub_distrib]
  rw [hO, hE]
  ring

/-- 4a. Each summand of ring² is nonnegative: a square divided by an `E ≥ 0`.
(No `T ≠ 0` hypothesis needed: `E = 0` when `T = 0`, and `0 ≤ 0`.) -/
theorem ringSq_term_nonneg (f : V → ℕ) (O : V × V → ℕ) (a b : V) :
    0 ≤ ((O (a, b) : ℚ) - E f a b) ^ 2 / (E f a b) := by
  apply div_nonneg (sq_nonneg _)
  unfold E
  apply div_nonneg
  · exact mul_nonneg (by exact_mod_cast Nat.zero_le (f a)) (by exact_mod_cast Nat.zero_le (f b))
  · exact_mod_cast Nat.zero_le (T f)

/-- 4. ring² is nonnegative: every term is `x² / E` with `E ≥ 0`. -/
theorem ringSq_nonneg (f : V → ℕ) (O : V × V → ℕ) (a : V) :
    0 ≤ ringSq O f a := by
  unfold ringSq
  exact Finset.sum_nonneg (fun b _ => ringSq_term_nonneg f O a b)

end Lattice
