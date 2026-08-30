/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions
import Hexagon.Euclidean

/-!
# T5 — ℤ[ω] is a Euclidean domain (and hence a UFD)

**Idea history:** plan §5; mirrors mathlib `NumberTheory/Zsqrtd/GaussianInt.lean`.

**Calibration:** DIRECT — classical.

**Status:** PROVED (2026-08-28) — both `instance : CommRing Eisenstein` (all ring
axioms closed by the `ext <;> ring` pattern from PROVER_NOTES.md) and
`instance : EuclideanDomain Eisenstein` (a pure-ℝ division algorithm: quotient =
componentwise `round` in the `(1, ω)` basis, remainder-norm inequality via the
proved `norm_mul` (T1) + `exists_near_int_pair` (Euclidean.lean) — no ℂ
embedding / `normSq` bridge needed). `lake build Hexagon.EuclideanDomain` green.
-/

namespace Hexagon

noncomputable section

open Eisenstein
open scoped Real

/-! ## `simp`-friendly projection lemmas

`ring`/`dsimp` will not unfold the custom `Mul`/`Add`/... instances on the
structure (see PROVER_NOTES.md); `simp` needs these to reduce components. -/

@[simp] theorem a_zero : (0 : Eisenstein).a = 0 := rfl
@[simp] theorem b_zero : (0 : Eisenstein).b = 0 := rfl
@[simp] theorem a_one : (1 : Eisenstein).a = 1 := rfl
@[simp] theorem b_one : (1 : Eisenstein).b = 0 := rfl
@[simp] theorem a_add (x y : Eisenstein) : (x + y).a = x.a + y.a := rfl
@[simp] theorem b_add (x y : Eisenstein) : (x + y).b = x.b + y.b := rfl
@[simp] theorem a_neg (x : Eisenstein) : (-x).a = -x.a := rfl
@[simp] theorem b_neg (x : Eisenstein) : (-x).b = -x.b := rfl
@[simp] theorem a_sub (x y : Eisenstein) : (x - y).a = x.a - y.a := rfl
@[simp] theorem b_sub (x y : Eisenstein) : (x - y).b = x.b - y.b := rfl
@[simp] theorem a_mul (x y : Eisenstein) : (x * y).a = x.a * y.a - x.b * y.b := rfl
@[simp] theorem b_mul (x y : Eisenstein) : (x * y).b = x.a * y.b + x.b * y.a + x.b * y.b := rfl
@[simp] theorem a_natCast (n : ℕ) : (n : Eisenstein).a = (n : ℤ) := rfl
@[simp] theorem b_natCast (n : ℕ) : (n : Eisenstein).b = 0 := rfl
@[simp] theorem a_intCast (n : ℤ) : (n : Eisenstein).a = n := rfl
@[simp] theorem b_intCast (n : ℤ) : (n : Eisenstein).b = 0 := rfl

/-! ## The conjugate `a + bω ↦ (a + b) − bω` (= `a + bω̄`) -/

/-- Conjugation on the Eisenstein integers: `star (a + bω) = (a + b) − bω`. -/
def star (x : Eisenstein) : Eisenstein := ⟨x.a + x.b, -x.b⟩

@[simp] theorem a_star (x : Eisenstein) : (star x).a = x.a + x.b := rfl
@[simp] theorem b_star (x : Eisenstein) : (star x).b = -x.b := rfl

/-- Conjugation preserves the norm: `N(star x) = N(x)`. -/
theorem star_norm (x : Eisenstein) : norm (star x) = norm x := by
  rcases x with ⟨a, b⟩
  change (a + b) ^ 2 + (a + b) * (-b) + (-b) ^ 2 = a ^ 2 + a * b + b ^ 2
  ring

/-- `x * star x = N(x)` (as an Eisenstein integer). -/
theorem star_mul_self (x : Eisenstein) : x * star x = (norm x : Eisenstein) := by
  rcases x with ⟨a, b⟩
  change Eisenstein.mk (a * (a + b) - b * (-b)) (a * (-b) + b * (a + b) + b * (-b)) =
    Eisenstein.mk (a ^ 2 + a * b + b ^ 2) 0
  ext <;> ring

/-! ## T5(1): `CommRing Eisenstein`

All operations are already instances (Conventions.lean); here we supply the
axioms. Every axiom is `ext <;> simp <;> ring` (or `simp [add_comm, add_left_comm]`
for the additive group) after the instances unfold the components. The
`nsmul`/`zsmul`/`npow` recursion fields use the standard `nsmulRec`/`zsmulRec`/
`npowRec` (their recursion equations then hold by `rfl`). -/

instance instAddCommGroup : AddCommGroup Eisenstein := by
  refine
    { sub := fun a b => a + -b
      nsmul := @nsmulRec Eisenstein ⟨0⟩ ⟨(· + ·)⟩
      zsmul := @zsmulRec Eisenstein ⟨0⟩ ⟨(· + ·)⟩ ⟨Neg.neg⟩ (@nsmulRec Eisenstein ⟨0⟩ ⟨(· + ·)⟩)
      add_assoc := ?_
      zero_add := ?_
      add_zero := ?_
      neg_add_cancel := ?_
      add_comm := ?_ } <;>
  intros <;>
  ext <;>
  simp [add_comm, add_left_comm]

instance instAddGroupWithOne : AddGroupWithOne Eisenstein :=
  { instAddCommGroup with
    natCast := Nat.cast
    intCast := Int.cast }

instance instCommRing : CommRing Eisenstein := by
  refine
    { instAddGroupWithOne with
      npow := @npowRec Eisenstein ⟨1⟩ ⟨(· * ·)⟩
      add_comm := ?_
      left_distrib := ?_
      right_distrib := ?_
      zero_mul := ?_
      mul_zero := ?_
      mul_assoc := ?_
      one_mul := ?_
      mul_one := ?_
      mul_comm := ?_ } <;>
  intros <;>
  ext <;>
  simp <;>
  ring

/-! ## The norm is nonnegative, positive-definite

`N(a + bω) = a² + ab + b² = ((a + b)² + a² + b²) / 2 ≥ 0`, and `N = 0` only at `0`
(positive-definite quadratic form). These give `norm_pos` used below. -/

theorem norm_nonneg (x : Eisenstein) : 0 ≤ norm x := by
  rcases x with ⟨a, b⟩
  change 0 ≤ a ^ 2 + a * b + b ^ 2
  nlinarith [sq_nonneg (a + b), sq_nonneg a, sq_nonneg b]

theorem norm_eq_zero_iff (x : Eisenstein) : norm x = 0 ↔ x = 0 := by
  rcases x with ⟨a, b⟩
  constructor
  · intro h
    change (a ^ 2 + a * b + b ^ 2 = 0) at h
    have ha : a ^ 2 = 0 := by
      nlinarith [h, sq_nonneg (a + b), sq_nonneg a, sq_nonneg b]
    have hb : b ^ 2 = 0 := by
      nlinarith [h, sq_nonneg (a + b), sq_nonneg a, sq_nonneg b]
    have ha' : a = 0 := sq_eq_zero_iff.mp ha
    have hb' : b = 0 := sq_eq_zero_iff.mp hb
    ext <;> simp [ha', hb']
  · intro h
    rw [h]
    simp [Eisenstein.norm]

theorem norm_pos {x : Eisenstein} (hx : x ≠ 0) : 0 < norm x := by
  have hn : norm x ≠ 0 := by
    intro hn0
    exact hx ((norm_eq_zero_iff x).mp hn0)
  exact lt_of_le_of_ne (norm_nonneg x) (Ne.symm hn)

/-! ## Division with remainder (the pure-ℝ route)

Quotient: round the coordinates of `x / y = (x · star y) / N(y)` in the `(1, ω)`
basis. Remainder: `x % y = x − y · (x / y)`.

The key identity (a pure polynomial identity, no ℂ needed):
`N(x − y·q) · N(y) = N(x·star y − q·N(y))`, which follows from multiplicativity
of the norm + `x · star x = N(x)`. -/

instance : Div Eisenstein :=
  ⟨fun x y =>
    ⟨round (((x * star y).a : ℝ) / (norm y : ℝ)), round (((x * star y).b : ℝ) / (norm y : ℝ))⟩⟩

theorem div_def (x y : Eisenstein) :
    x / y = Eisenstein.mk (round (((x * star y).a : ℝ) / (norm y : ℝ)))
      (round (((x * star y).b : ℝ) / (norm y : ℝ))) :=
  rfl

theorem a_div (x y : Eisenstein) :
    (x / y).a = round (((x * star y).a : ℝ) / (norm y : ℝ)) := rfl

theorem b_div (x y : Eisenstein) :
    (x / y).b = round (((x * star y).b : ℝ) / (norm y : ℝ)) := rfl

instance : Mod Eisenstein :=
  ⟨fun x y => x - y * (x / y)⟩

theorem mod_def (x y : Eisenstein) : x % y = x - y * (x / y) :=
  rfl

theorem norm_mul_sub_left (x y q : Eisenstein) :
    norm (x - y * q) * norm y = norm (x * star y - q * (norm y : Eisenstein)) := by
  calc
    norm (x - y * q) * norm y = norm (x - y * q) * norm (star y) := by
      exact congrArg (fun z => norm (x - y * q) * z) (star_norm y).symm
    _ = norm ((x - y * q) * star y) := (norm_mul (x - y * q) (star y)).symm
    _ = norm (x * star y - q * (norm y : Eisenstein)) := by
      congr 1
      calc
        (x - y * q) * star y = x * star y - (y * q) * star y := by rw [sub_mul]
        _ = x * star y - q * (y * star y) := by ring
        _ = x * star y - q * (norm y : Eisenstein) := by rw [star_mul_self]

/-- The covering-radius lemma specialised to the *actual* `round` witnesses
    (the proof of `exists_near_int_pair` already constructs exactly these). -/
private theorem near_int_pair_round (α β : ℝ) :
    ((α - (round α : ℝ)) ^ 2 + (α - (round α : ℝ)) * (β - (round β : ℝ)) +
      (β - (round β : ℝ)) ^ 2) < 1 := by
  set x : ℝ := α - round α
  set y : ℝ := β - round β
  have hx : |x| ≤ (1 / 2 : ℝ) := by simpa [x] using (abs_sub_round α)
  have hy : |y| ≤ (1 / 2 : ℝ) := by simpa [y] using (abs_sub_round β)
  have hx' : -(1 / 2 : ℝ) ≤ x ∧ x ≤ (1 / 2 : ℝ) := abs_le.mp hx
  have hy' : -(1 / 2 : ℝ) ≤ y ∧ y ≤ (1 / 2 : ℝ) := abs_le.mp hy
  have hxy : |x + y| ≤ (1 : ℝ) := by
    calc
      |x + y| ≤ |x| + |y| := abs_add_le x y
      _ ≤ (1 / 2 : ℝ) + (1 / 2 : ℝ) := add_le_add hx hy
      _ = 1 := by norm_num
  have hxy' : -(1 : ℝ) ≤ x + y ∧ x + y ≤ (1 : ℝ) := abs_le.mp hxy
  have hx_sq : x ^ 2 ≤ (1 / 4 : ℝ) := by nlinarith [hx'.1, hx'.2]
  have hy_sq : y ^ 2 ≤ (1 / 4 : ℝ) := by nlinarith [hy'.1, hy'.2]
  have hxy_sq : (x + y) ^ 2 ≤ (1 : ℝ) := by nlinarith [hxy'.1, hxy'.2]
  have hid : x ^ 2 + x * y + y ^ 2 = ((x + y) ^ 2 + x ^ 2 + y ^ 2) / 2 := by ring
  rw [hid]
  nlinarith [hx_sq, hy_sq, hxy_sq]

/-- The remainder norm decreases: `N(x % y) < N(y)` for `y ≠ 0`. -/
theorem norm_mod_lt (x : Eisenstein) {y : Eisenstein} (hy : y ≠ 0) :
    norm (x % y) < norm y := by
  let n : ℤ := norm y
  let p : ℤ := (x * star y).a
  let s : ℤ := (x * star y).b
  let Q : ℤ := (p - (x / y).a * n) ^ 2 + (p - (x / y).a * n) * (s - (x / y).b * n) +
    (s - (x / y).b * n) ^ 2
  let qr : ℝ := ((p : ℝ) / (n : ℝ) - (x / y).a) ^ 2 +
    ((p : ℝ) / (n : ℝ) - (x / y).a) * ((s : ℝ) / (n : ℝ) - (x / y).b) +
    ((s : ℝ) / (n : ℝ) - (x / y).b) ^ 2
  have hn0 : n ≠ 0 := by
    dsimp [n]
    intro hn
    exact hy ((norm_eq_zero_iff y).mp hn)
  have hnr : (n : ℝ) ≠ 0 := by
    exact_mod_cast hn0
  have hnp : 0 < (n : ℝ) := by
    dsimp [n]
    exact_mod_cast norm_pos hy
  -- integer identity: N(x − y·(x/y)) · N(y) = Q
  have hmain : norm (x - y * (x / y)) * n = Q := by
    dsimp [n, Q, p, s]
    rw [norm_mul_sub_left]
    change ((x * star y).a - ((x / y).a * norm y - (x / y).b * 0)) ^ 2 +
        ((x * star y).a - ((x / y).a * norm y - (x / y).b * 0)) *
          ((x * star y).b - ((x / y).a * 0 + (x / y).b * norm y + (x / y).b * 0)) +
        ((x * star y).b - ((x / y).a * 0 + (x / y).b * norm y + (x / y).b * 0)) ^ 2 =
      ((x * star y).a - (x / y).a * norm y) ^ 2 +
        ((x * star y).a - (x / y).a * norm y) * ((x * star y).b - (x / y).b * norm y) +
        ((x * star y).b - (x / y).b * norm y) ^ 2
    ring
  -- cast to reals and factor the remainder norm through the rounding error
  have hQℝ : (Q : ℝ) = (n : ℝ) ^ 2 * qr := by
    dsimp [Q, qr, p, s]
    field_simp [hnr]
    push_cast
    ring
  -- the rounding error has norm < 1, by the covering-radius lemma
  have hqr : qr < 1 := by
    simpa [qr, p, s, n, a_div, b_div] using
      near_int_pair_round ((p : ℝ) / (n : ℝ)) ((s : ℝ) / (n : ℝ))
  have hm : (norm (x % y) : ℝ) * (n : ℝ) = (n : ℝ) * ((n : ℝ) * qr) := by
    rw [mod_def]
    have hc : (norm (x - y * (x / y)) : ℝ) * (n : ℝ) = (Q : ℝ) := by
      exact_mod_cast hmain
    rw [hc, hQℝ]
    ring
  have hdiv : (norm (x % y) : ℝ) = (n : ℝ) * qr := by
    apply mul_left_cancel₀ hnr
    rw [mul_comm (n : ℝ) (norm (x % y) : ℝ)]
    exact hm
  have hreal : (norm (x % y) : ℝ) < (norm y : ℝ) := by
    rw [hdiv]
    calc
      (n : ℝ) * qr < (n : ℝ) * 1 := mul_lt_mul_of_pos_left hqr hnp
      _ = (norm y : ℝ) := by simp [n]
  exact (@Int.cast_lt ℝ _ _ _ _).1 hreal

theorem natAbs_norm_mod_lt (x : Eisenstein) {y : Eisenstein} (hy : y ≠ 0) :
    (norm (x % y)).natAbs < (norm y).natAbs := by
  have hlt : norm (x % y) < norm y := norm_mod_lt x hy
  exact Int.ofNat_lt.1 (by
    have h1 : 0 ≤ norm (x % y) := norm_nonneg (x % y)
    have h2 : 0 ≤ norm y := le_of_lt (norm_pos hy)
    rw [← Int.natAbs_of_nonneg h1, ← Int.natAbs_of_nonneg h2] at hlt
    exact hlt)

theorem norm_le_norm_mul_left (x : Eisenstein) {y : Eisenstein} (hy : y ≠ 0) :
    (norm x).natAbs ≤ (norm (x * y)).natAbs := by
  rw [norm_mul, Int.natAbs_mul]
  have hny : 0 < (norm y).natAbs := Int.natAbs_pos.mpr (by
    intro hn
    exact hy ((norm_eq_zero_iff y).mp hn))
  exact le_mul_of_one_le_right (Nat.zero_le _) (Nat.succ_le_of_lt hny)

instance instNontrivial : Nontrivial Eisenstein :=
  ⟨⟨0, 1, by decide⟩⟩

/-! ## T5(2): `EuclideanDomain Eisenstein`

Mirrors `GaussianInt.instEuclideanDomain`: the well-founded relation is
`(Int.natAbs ∘ norm)`; `remainder_lt` is `natAbs_norm_mod_lt`; `mul_left_not_lt`
follows from multiplicativity of the norm. -/

instance : EuclideanDomain Eisenstein :=
  { instCommRing, instNontrivial with
    quotient := (· / ·)
    remainder := (· % ·)
    quotient_zero := by
      intro a
      rw [div_def]
      simp [Hexagon.star, Eisenstein.norm]
      rfl
    quotient_mul_add_remainder_eq := by
      intro a b
      rw [mod_def]
      ring
    r := fun a b => (Int.natAbs (norm a)) < (Int.natAbs (norm b))
    r_wellFounded := (measure (Int.natAbs ∘ norm)).wf
    remainder_lt := natAbs_norm_mod_lt
    mul_left_not_lt := fun a b hb0 => not_lt_of_ge <| norm_le_norm_mul_left a hb0 }

end

end Hexagon
