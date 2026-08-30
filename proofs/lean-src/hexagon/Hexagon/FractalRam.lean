/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# Fractal hex RAM — the 7ⁿ address space, 7↔1 parent-child, isomorphic lookup

**Idea history:** hexigon_conversation.md fractal memory 7ⁿ (L11971–12123); DGGS / H3
aperture-7 (TERNARY_PROCESSOR.md); Ian (2026): "ram has the hexagon and isomorphic lookup,
can do the fractal addressing and lookup."

**Calibration:** DIRECT — finite combinatorics (base-7 digit strings).

**Status:** PROVED (2026-08-28, FractalRam subagent) — no `sorry` anywhere in this file.
Item 1 `FractalAddress` (the address type, `Fin n → Fin 7`); item 2 `fractalAddress_card`
(the 7ⁿ law); item 3 `parent` + `parent_fiber_card` (each parent has exactly 7 children,
via the `parentFiberEquiv` ≃ `Fin 7` bijection); item 4 `level_succ_card` (7·7ⁿ = 7ⁿ⁺¹,
proved both via `Fintype.card_pi` and via the fiber sum `level_succ_card_fiber`); item 5
`levelOneEquiv` (level-1 addresses ≃ `Fin 7`, matching `hexCells_card` in SevenHex.lean).
`lake build Hexagon.FractalRam` green (native tactics only: `simp`/`rw`/`omega`/`funext`/
`congr`/`ext`/`rcases`/`by_cases`).
-/

open scoped BigOperators

namespace Hexagon

-- A level-n address = a base-7 digit string of length n; there are 7ⁿ of them.
-- The parent of a level-(n+1) address is its level-n prefix (drop the last digit);
-- each parent has exactly 7 children (append one of the 7 digits). The "lookup" is the
-- address → cell bijection.

/-- 1. A level-`n` fractal address: a base-7 digit string of length `n`, i.e. a function
    from the `n` digit positions to the 7 digits. There are `7ⁿ` of them. -/
abbrev FractalAddress (n : ℕ) := Fin n → Fin 7

/-- 2. The 7ⁿ law: there are exactly `7 ^ n` level-`n` addresses.
    (`Fintype.card_pi`/`Fintype.card_fin` reduce |Fin n → Fin 7| = 7^n.) -/
theorem fractalAddress_card (n : ℕ) : Fintype.card (FractalAddress n) = 7 ^ n := by
  simp

/-- 3a. The parent of a level-`(n+1)` address is its level-`n` prefix: drop the last
    digit. (The index proof: `i.1 < n` and `n < n+1`, so `i.1 < n+1`.) -/
def parent {n : ℕ} (a : FractalAddress (n + 1)) : FractalAddress n :=
  fun i => a ⟨i, Nat.lt_trans i.2 (Nat.lt_succ_self n)⟩

/-- The last (highest-index) digit of a level-`(n+1)` address. -/
def lastDigit {n : ℕ} (a : FractalAddress (n + 1)) : Fin 7 := a ⟨n, Nat.lt_succ_self n⟩

/-- Append digit `d` to the level-`n` address `p`: the level-`(n+1)` address that agrees
    with `p` on the first `n` digits and has last digit `d`. -/
def child {n : ℕ} (p : FractalAddress n) (d : Fin 7) : FractalAddress (n+1) :=
  fun i => if h : i.1 < n then p ⟨i.1, h⟩ else d

/-- Dropping the last digit of `child p d` gives back `p`: the child relation is a
    section of `parent`. -/
theorem parent_child {n : ℕ} (p : FractalAddress n) (d : Fin 7) : parent (child p d) = p := by
  funext i
  simp [parent, child, i.2]

/-- The last digit of `child p d` is `d`. -/
theorem child_lastDigit {n : ℕ} (p : FractalAddress n) (d : Fin 7) : lastDigit (child p d) = d := by
  simp [lastDigit, child]

/-- Two children of the same parent that agree on the last digit are equal. -/
theorem child_ext {n : ℕ} (p : FractalAddress n) {d1 d2 : Fin 7} (h : child p d1 = child p d2) :
    d1 = d2 := by
  have h' := congrArg lastDigit h
  simpa [child_lastDigit] using h'

/-- `child (parent a) (lastDigit a)` reconstructs `a`: every address is its own parent
    extended by its own last digit. -/
theorem child_parent {n : ℕ} (a : FractalAddress (n + 1)) : child (parent a) (lastDigit a) = a := by
  funext i
  by_cases h : i.1 < n
  · simp [child, parent, h]
  · rw [child, dif_neg h]
    rw [lastDigit]
    have hi_lt : i.1 < n + 1 := i.2
    have hi : i.1 = n := by omega
    congr 1
    ext
    exact hi.symm

/-- 3b. The fiber of `parent` over `p` — the set of all level-`(n+1)` children of `p` —
    is in bijection with `Fin 7`: every child is `p` extended by one of the 7 last digits. -/
def parentFiberEquiv {n : ℕ} (p : FractalAddress n) :
    {a : FractalAddress (n+1) // parent a = p} ≃ Fin 7 where
  toFun a := lastDigit a.1
  invFun d := ⟨child p d, parent_child p d⟩
  left_inv := by
    intro a
    rcases a with ⟨a, ha⟩
    apply Subtype.ext
    change child p (lastDigit a) = a
    rw [← ha]
    exact child_parent a
  right_inv := by
    intro d
    exact child_lastDigit p d

/-- 3. Each parent has exactly 7 children (the fiber-card law). -/
theorem parent_fiber_card {n : ℕ} (p : FractalAddress n) :
    Fintype.card {a : FractalAddress (n+1) // parent a = p} = 7 := by
  calc
    Fintype.card {a : FractalAddress (n+1) // parent a = p} = Fintype.card (Fin 7) :=
      Fintype.card_congr (parentFiberEquiv p)
    _ = 7 := Fintype.card_fin 7

/-- 4a. The fractal growth law 7·7ⁿ = 7ⁿ⁺¹ (via `Fintype.card_pi`). -/
theorem level_succ_card (n : ℕ) :
    Fintype.card (FractalAddress (n+1)) = 7 * Fintype.card (FractalAddress n) := by
  simp only [Fintype.card_pi, Fintype.card_fin, Finset.prod_const, Finset.card_univ]
  rw [pow_succ, Nat.mul_comm]

/-- The level-`(n+1)` addresses are the disjoint union over level-`n` parents of their
    child fibers — the "fractal" decomposition behind the growth law. -/
def addressSigmaEquiv (n : ℕ) :
    FractalAddress (n+1) ≃
      (Σ p : FractalAddress n, {a : FractalAddress (n+1) // parent a = p}) where
  toFun a := ⟨parent a, a, rfl⟩
  invFun s := s.2.1
  left_inv := by
    intro a
    rfl
  right_inv := by
    intro s
    rcases s with ⟨p, a, h⟩
    cases h
    rfl

/-- 4b. The fractal growth law, fiber-sum form: summing the 7-children fibers over all
    parents counts every level-`(n+1)` address exactly once, so 7·7ⁿ = 7ⁿ⁺¹. -/
theorem level_succ_card_fiber (n : ℕ) :
    Fintype.card (FractalAddress (n+1)) = 7 * Fintype.card (FractalAddress n) := by
  calc
    Fintype.card (FractalAddress (n+1)) =
        Fintype.card (Σ p : FractalAddress n, {a : FractalAddress (n+1) // parent a = p}) :=
      Fintype.card_congr (addressSigmaEquiv n)
    _ = ∑ p : FractalAddress n, Fintype.card {a : FractalAddress (n+1) // parent a = p} := by
      simp
    _ = ∑ _p : FractalAddress n, (7 : ℕ) := by
      simp [parent_fiber_card]
    _ = 7 * Fintype.card (FractalAddress n) := by
      rw [Finset.sum_const, Fintype.card]
      rw [Nat.nsmul_eq_mul, Nat.mul_comm]

/-- `Fin 1` has a single element — the digit position `0`. -/
theorem fin_one_eq_zero (i : Fin 1) : i = 0 := by
  rcases i with ⟨m, hm⟩
  ext
  omega

/-- 5. The level-1 bijection: a level-1 address is just one digit, so
    `FractalAddress 1 ≃ Fin 7`. `Fin 7` is exactly the digit alphabet, and
    `Hexagon.SevenHex.hexCells_card : hexCells.card = 7` (SevenHex.lean) shows those
    7 digits index the 7 cells of the unit hexagon. -/
def levelOneEquiv : FractalAddress 1 ≃ Fin 7 where
  toFun a := a 0
  invFun d := fun _ => d
  left_inv := by
    intro a
    funext i
    rw [fin_one_eq_zero i]
  right_inv := by
    intro d
    rfl

/-- The level-1 address space has exactly 7 elements — the 7 hex cells
    (`hexCells_card` in SevenHex.lean proves `hexCells.card = 7`). -/
theorem levelOne_card : Fintype.card (FractalAddress 1) = 7 := by
  simp

end Hexagon
