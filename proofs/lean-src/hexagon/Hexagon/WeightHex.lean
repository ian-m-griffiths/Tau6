/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions
import Hexagon.Rotation

/-!
# B3 — the hex weight and the bound √N ≤ wtHex ≤ N (Eisenstein codes paper Thm 11)

**Idea history:** arXiv:2412.18328 "On Codes over Eisenstein Integers" (mapped DIRECT in the
ternary-circuits synthesis); its hex weight wtHex and Theorem 11 bound it against the
Euclidean norm √N (our norm N = a²+ab+b²).

**Calibration:** DIRECT — the paper's own theorem, now proved here.

**Paper definition (graph N7, §II.C Eq. (4)):** `wtHex(α) = min over the six unit-basis
reps of |a₁|+|a₂|` = the minimum number of unit steps in the six π/3 directions; the
hex distance is `dHex(α,θ) = wtHex(α−θ)`. Theorem 11 (graph N8, §II.C) states
`√N(α) ≤ wtHex(α) ≤ N(α)`. We use the 60° gauge `ω = e^(iπ/3)`, `N(a+bω) = a²+ab+b²`
(their 120° ρ-gauge is the same ring — the bridge `(a,b) ↦ (a,−b)` is ConventionBridge C1);
the six unit-multiples are the `units` of Rotation.lean.

**Formalized here (deviation note):** `wtHex x` is the minimum over the six unit-multiples
`u·x` of `|(u·x).a| + |(u·x).b|`. Since wtHex is integer-valued and ≥ 0, the paper's
`√N ≤ wtHex` is stated in the integer form `N ≤ wtHex²` (`norm_le_wtHex_sq`), and the full
paper form `√N ≤ wtHex ≤ N` is given over ℝ in `thm11`. The proof: the lower bound is the
pointwise identity `N(x) ≤ (|a|+|b|)²` (valid for every associate, since units have norm 1
and N is multiplicative); the upper bound picks, by sign case analysis on `a·b`, the winning
unit among `1, ω, ω²` (`|a|+|b| ≤ N` when `ab ≥ 0`; `l1(ω·x) = |a| ≤ N` when `ab < 0` and
`|b| ≤ |a|`; `l1(ω²·x) = |b| ≤ N` when `ab < 0` and `|a| < |b|`). Sanity check against the
paper's Remark 12: `wtHex(4+4ρ) = wtHex(3+4ρ) = 4` with norms 16 ≠ 13 — reproduced by this
definition (associates of `(0,4)` and `(−1,4)`), and the converse `N-equal ⇒ wtHex-equal`
is NOT claimed here.

**Status:** PROVED (2026-08-28) — `norm_le_wtHex_sq` (√N ≤ wtHex as N ≤ wtHex²),
`wtHex_le_norm` (wtHex ≤ N), and the ℝ-form `thm11` closed by native tactics
(`nlinarith`/`omega`/`ring` + `Finset.min'`). `lake build` green, zero `sorry`.
-/

namespace Hexagon

open Eisenstein

/-- ω = e^(iπ/3) as an Eisenstein integer `(0,1)`. -/
def omegaUnit : Eisenstein := ⟨0, 1⟩

/-- ω² = ω − 1 as an Eisenstein integer `(−1,1)`. -/
def omegaSq : Eisenstein := ⟨-1, 1⟩

/-- The hex/L1 size `|a|+|b|` of `a + bω` (unit steps in two basis directions). -/
def l1 (x : Eisenstein) : ℤ := |x.a| + |x.b|

/-- `1 · x = x` for our ω-multiplication (no `Monoid` instance exists yet). -/
lemma eisenstein_one_mul (x : Eisenstein) : (⟨1, 0⟩ : Eisenstein) * x = x := by
  rcases x with ⟨a, b⟩
  change Eisenstein.mk (1 * a - 0 * b) (1 * b + 0 * a + 0 * b) = Eisenstein.mk a b
  ext <;> norm_num

/-- The coordinates of `ω·x`: `ω(a+bω) = −b + (a+b)ω`. -/
lemma omega_mul_coords (x : Eisenstein) :
    (omegaUnit * x).a = -x.b ∧ (omegaUnit * x).b = x.a + x.b := by
  rcases x with ⟨a, b⟩
  change (Eisenstein.mk (0 * a - 1 * b) (0 * b + 1 * a + 1 * b)).a = -b ∧
         (Eisenstein.mk (0 * a - 1 * b) (0 * b + 1 * a + 1 * b)).b = a + b
  constructor <;> norm_num

/-- The coordinates of `ω²·x`: `ω²(a+bω) = −(a+b) + aω`. -/
lemma omegaSq_mul_coords (x : Eisenstein) :
    (omegaSq * x).a = -x.a - x.b ∧ (omegaSq * x).b = x.a := by
  rcases x with ⟨a, b⟩
  change (Eisenstein.mk (-1 * a - 1 * b) (-1 * b + 1 * a + 1 * b)).a = -a - b ∧
         (Eisenstein.mk (-1 * a - 1 * b) (-1 * b + 1 * a + 1 * b)).b = a
  constructor <;> norm_num

lemma omega_mem_units : omegaUnit ∈ units := by
  simp [units, omegaUnit]

lemma omegaSq_mem_units : omegaSq ∈ units := by
  simp [units, omegaSq]

/-- The image of the six units under `u ↦ l1 (u·x)` is nonempty. -/
lemma units_image_nonempty (x : Eisenstein) :
    (units.image (fun u => l1 (u * x))).Nonempty := by
  refine ⟨l1 x, ?_⟩
  exact Finset.mem_image.mpr ⟨(⟨1, 0⟩ : Eisenstein), by simp [units],
    congrArg l1 (eisenstein_one_mul x)⟩

/-- The hex weight `wtHex(x) = min over the six unit-multiples u·x of |(u·x).a| + |(u·x).b|`
    (paper N7, §II.C Eq. (4): minimum unit steps in the six π/3 directions). -/
def wtHex (x : Eisenstein) : ℤ :=
  (units.image (fun u => l1 (u * x))).min' (units_image_nonempty x)

/-- `l1` is nonnegative. -/
lemma l1_nonneg (x : Eisenstein) : 0 ≤ l1 x := by
  unfold l1
  exact add_nonneg (abs_nonneg _) (abs_nonneg _)

/-- The hex weight is nonnegative. -/
lemma wtHex_nonneg (x : Eisenstein) : 0 ≤ wtHex x := by
  unfold wtHex
  have hmem : (units.image (fun u => l1 (u * x))).min' (units_image_nonempty x) ∈
      units.image (fun u => l1 (u * x)) := Finset.min'_mem _ _
  rcases (Finset.mem_image.mp hmem) with ⟨u, hu, h⟩
  rw [← h]
  exact l1_nonneg (u * x)

/-- The minimum is attained: `wtHex x ≤ l1 (u·x)` for every unit `u`. -/
theorem wtHex_le_l1 (x u : Eisenstein) (hu : u ∈ units) : wtHex x ≤ l1 (u * x) := by
  unfold wtHex
  exact Finset.min'_le (units.image (fun u => l1 (u * x))) (l1 (u * x))
    (Finset.mem_image.mpr ⟨u, hu, rfl⟩)

/-- Each of the six units has norm 1. -/
lemma norm_of_mem_units (u : Eisenstein) (hu : u ∈ units) : Eisenstein.norm u = 1 := by
  fin_cases hu <;> norm_num [Eisenstein.norm]

/-- Multiplying by a unit preserves the norm. -/
lemma norm_units_mul (u : Eisenstein) (hu : u ∈ units) (x : Eisenstein) :
    Eisenstein.norm (u * x) = Eisenstein.norm x := by
  rw [norm_mul, norm_of_mem_units u hu]
  ring

/-- The norm is always nonnegative. -/
lemma norm_nonneg (x : Eisenstein) : 0 ≤ Eisenstein.norm x := by
  rcases x with ⟨a, b⟩
  change 0 ≤ a ^ 2 + a * b + b ^ 2
  nlinarith [sq_nonneg (2 * a + b)]

/-- `|a| ≤ a²` for every integer `a`. -/
lemma abs_le_sq (a : ℤ) : |a| ≤ a ^ 2 := by
  by_cases ha : a = 0
  · simp [ha]
  · have hpos : 0 < |a| := abs_pos.mpr ha
    have hone : 1 ≤ |a| := by omega
    have hsq : |a| ^ 2 = a ^ 2 := sq_abs a
    nlinarith [hsq, hone, abs_nonneg a]

/-- Pointwise lower bound: `N(x) ≤ (|a|+|b|)²` for every `x = a + bω`.
    Equivalently `√N(x) ≤ l1(x)`; since the norm is multiplicative and units have
    norm 1, this holds for every associate, which gives the `√N ≤ wtHex` side. -/
lemma norm_le_l1_sq (x : Eisenstein) : Eisenstein.norm x ≤ (l1 x) ^ 2 := by
  rcases x with ⟨a, b⟩
  change a ^ 2 + a * b + b ^ 2 ≤ (|a| + |b|) ^ 2
  have hsq : (|a| + |b|) ^ 2 = a ^ 2 + b ^ 2 + 2 * |a * b| := by
    rw [add_sq, sq_abs, sq_abs]
    rw [show 2 * |a| * |b| = 2 * (|a| * |b|) by ring]
    rw [← abs_mul]
    ring
  rw [hsq]
  have hab : a * b ≤ |a * b| := le_abs_self (a * b)
  have hab0 : 0 ≤ |a * b| := abs_nonneg (a * b)
  nlinarith

/-- When `ab ≥ 0` the unrotated representative already has `l1 x = |a|+|b| ≤ N(x)`. -/
lemma l1_le_norm_of_mul_nonneg (x : Eisenstein) (h : 0 ≤ x.a * x.b) :
    l1 x ≤ Eisenstein.norm x := by
  rcases x with ⟨a, b⟩
  change |a| + |b| ≤ a ^ 2 + a * b + b ^ 2
  have ha : |a| ≤ a ^ 2 := abs_le_sq a
  have hb : |b| ≤ b ^ 2 := abs_le_sq b
  have hab : 0 ≤ a * b := h
  nlinarith

/-- The first coordinate is bounded by the norm: `|a| ≤ N(a,b)`. -/
lemma abs_a_le_norm (x : Eisenstein) : |x.a| ≤ Eisenstein.norm x := by
  rcases x with ⟨a, b⟩
  change |a| ≤ a ^ 2 + a * b + b ^ 2
  by_cases ha0 : a = 0
  · subst a
    simp
    nlinarith [sq_nonneg b]
  · by_cases h2 : 2 ≤ |a|
    · have h30 : 0 ≤ 3 * |a| - 4 := by nlinarith [h2]
      have h31 : 0 ≤ |a| * (3 * |a| - 4) := mul_nonneg (abs_nonneg a) h30
      have h32 : 0 ≤ 3 * a ^ 2 - 4 * |a| := by
        rw [← sq_abs a]
        nlinarith [h31]
      have hsq : (2 * b + a) ^ 2 + 3 * a ^ 2 - 4 * |a| = 4 * (a ^ 2 + a * b + b ^ 2 - |a|) := by
        ring
      nlinarith [sq_nonneg (2 * b + a), h32, hsq]
    · have h1 : |a| = 1 := by
        have hpos : 0 < |a| := abs_pos.mpr ha0
        have hle1 : |a| ≤ 1 := by omega
        have hge1 : 1 ≤ |a| := by omega
        exact le_antisymm hle1 hge1
      have ha_sq : a ^ 2 = 1 := by nlinarith [h1, sq_abs a]
      have hgoal : 0 ≤ a * b + b ^ 2 := by
        rcases (eq_or_eq_neg_of_abs_eq h1) with ha1 | ha1
        · rw [ha1]
          norm_num
          by_cases hb : 0 ≤ b
          · nlinarith [sq_nonneg b, hb]
          · have hb0 : b ≤ 0 := by omega
            have hb1 : b + 1 ≤ 0 := by omega
            have hp : 0 ≤ b * (b + 1) := by nlinarith
            nlinarith [hp]
        · rw [ha1]
          norm_num
          by_cases hb : 0 ≤ b
          · by_cases hb0 : b = 0
            · simp [hb0]
            · have hb1 : 1 ≤ b := by omega
              have hp : 0 ≤ b * (b - 1) := by nlinarith
              nlinarith [hp]
          · have hb0 : b ≤ 0 := by omega
            have hb1 : b - 1 ≤ 0 := by omega
            have hp : 0 ≤ b * (b - 1) := by nlinarith
            nlinarith [hp]
      nlinarith [h1, ha_sq, hgoal, abs_nonneg a]

/-- The second coordinate is bounded by the norm (rotate the previous lemma by ω). -/
lemma abs_b_le_norm (x : Eisenstein) : |x.b| ≤ Eisenstein.norm x := by
  have h := abs_a_le_norm (omegaUnit * x)
  rw [omega_mul_coords x |>.1, norm_units_mul omegaUnit omega_mem_units x] at h
  simpa [abs_neg] using h

/-- For opposite-sign integers with `|b| ≤ |a|`, `|a+b| = |a| − |b|`. -/
lemma abs_add_eq_sub_of_opposite (a b : ℤ) (hab : a * b < 0) (hba : |b| ≤ |a|) :
    |a + b| = |a| - |b| := by
  by_cases ha : 0 < a
  · have hb : b < 0 := by
      rcases (mul_neg_iff.mp hab) with h | h
      · exact h.2
      · omega
    have ha_abs : |a| = a := abs_of_pos ha
    have hb_abs : |b| = -b := abs_of_neg hb
    have hab_nonneg : 0 ≤ a + b := by
      nlinarith [ha_abs, hb_abs, hba]
    have hab_abs : |a + b| = a + b := abs_of_nonneg hab_nonneg
    rw [ha_abs, hb_abs, hab_abs]
    ring
  · have ha_le : a ≤ 0 := le_of_not_gt ha
    have hab_ne : a * b ≠ 0 := ne_of_lt hab
    have ha_ne : a ≠ 0 := (mul_ne_zero_iff.mp hab_ne).1
    have ha_neg : a < 0 := lt_of_le_of_ne ha_le ha_ne
    have hb_pos : 0 < b := by
      rcases (mul_neg_iff.mp hab) with h | h
      · omega
      · exact h.2
    have ha_abs : |a| = -a := abs_of_neg ha_neg
    have hb_abs : |b| = b := abs_of_pos hb_pos
    have hab_nonpos : a + b ≤ 0 := by
      nlinarith [ha_abs, hb_abs, hba]
    have hab_abs : |a + b| = -(a + b) := abs_of_nonpos hab_nonpos
    rw [ha_abs, hb_abs, hab_abs]
    ring

/-- `l1 (ω·x) = |b| + |a+b|`. -/
lemma l1_omega (x : Eisenstein) : l1 (omegaUnit * x) = |x.b| + |x.a + x.b| := by
  have hc := omega_mul_coords x
  rw [l1, hc.1, hc.2, abs_neg]

/-- `l1 (ω²·x) = |a| + |a+b|`. -/
lemma l1_omegaSq (x : Eisenstein) : l1 (omegaSq * x) = |x.a| + |x.a + x.b| := by
  have hc := omegaSq_mul_coords x
  rw [l1, hc.1, hc.2]
  rw [show -x.a - x.b = -(x.a + x.b) by ring]
  rw [abs_neg]
  ac_rfl

/-- Theorem 11 (paper N8, lower bound), integer form of `√N ≤ wtHex`:
    `N(x) ≤ wtHex(x)²`. -/
theorem norm_le_wtHex_sq (x : Eisenstein) : Eisenstein.norm x ≤ (wtHex x) ^ 2 := by
  unfold wtHex
  have hmem : (units.image (fun u => l1 (u * x))).min' (units_image_nonempty x) ∈
      units.image (fun u => l1 (u * x)) := Finset.min'_mem _ _
  rcases (Finset.mem_image.mp hmem) with ⟨u, hu, h⟩
  rw [← h]
  calc
    Eisenstein.norm x = Eisenstein.norm (u * x) := (norm_units_mul u hu x).symm
    _ ≤ (l1 (u * x)) ^ 2 := norm_le_l1_sq (u * x)

/-- Theorem 11 (paper N8, upper bound): `wtHex(x) ≤ N(x)`. -/
theorem wtHex_le_norm (x : Eisenstein) : wtHex x ≤ Eisenstein.norm x := by
  by_cases h : 0 ≤ x.a * x.b
  · have hle : l1 ((⟨1, 0⟩ : Eisenstein) * x) ≤ Eisenstein.norm x := by
      simpa [eisenstein_one_mul] using (l1_le_norm_of_mul_nonneg x h)
    exact le_trans (wtHex_le_l1 x (⟨1, 0⟩ : Eisenstein) (by simp [units])) hle
  · have hab_neg : x.a * x.b < 0 := by omega
    by_cases hba : |x.b| ≤ |x.a|
    · have hl1 : l1 (omegaUnit * x) = |x.a| := by
        rw [l1_omega]
        have hsub : |x.a + x.b| = |x.a| - |x.b| := abs_add_eq_sub_of_opposite x.a x.b hab_neg hba
        rw [hsub]
        ring
      have hle : l1 (omegaUnit * x) ≤ Eisenstein.norm x := by
        rw [hl1]
        exact abs_a_le_norm x
      exact le_trans (wtHex_le_l1 x omegaUnit omega_mem_units) hle
    · have hab_neg' : x.b * x.a < 0 := by nlinarith [hab_neg]
      have hba' : |x.a| ≤ |x.b| := by omega
      have hl1 : l1 (omegaSq * x) = |x.b| := by
        rw [l1_omegaSq]
        have hsub : |x.a + x.b| = |x.b| - |x.a| := by
          rw [add_comm]
          exact abs_add_eq_sub_of_opposite x.b x.a hab_neg' hba'
        rw [hsub]
        ring
      have hle : l1 (omegaSq * x) ≤ Eisenstein.norm x := by
        rw [hl1]
        exact abs_b_le_norm x
      exact le_trans (wtHex_le_l1 x omegaSq omegaSq_mem_units) hle

/-- Theorem 11 (paper N8, lower bound) over ℝ: `√N(x) ≤ wtHex(x)`. -/
theorem sqrt_norm_le_wtHex (x : Eisenstein) :
    Real.sqrt (Eisenstein.norm x : ℝ) ≤ (wtHex x : ℝ) := by
  have hle : (Eisenstein.norm x : ℝ) ≤ (wtHex x : ℝ) ^ 2 := by
    simpa [Int.cast_pow] using
      (show (Eisenstein.norm x : ℝ) ≤ ((wtHex x) ^ 2 : ℝ) by exact_mod_cast norm_le_wtHex_sq x)
  have hle' : Real.sqrt (Eisenstein.norm x : ℝ) ≤ Real.sqrt ((wtHex x : ℝ) ^ 2) :=
    Real.sqrt_le_sqrt hle
  have hsqrt : Real.sqrt ((wtHex x : ℝ) ^ 2) = (wtHex x : ℝ) := by
    rw [Real.sqrt_sq_eq_abs, abs_of_nonneg]
    exact_mod_cast wtHex_nonneg x
  exact hle'.trans_eq hsqrt

/-- Theorem 11 (paper N8) in the paper's exact form: `√N(x) ≤ wtHex(x) ≤ N(x)`. -/
theorem thm11 (x : Eisenstein) :
    Real.sqrt (Eisenstein.norm x : ℝ) ≤ (wtHex x : ℝ) ∧
      (wtHex x : ℝ) ≤ (Eisenstein.norm x : ℝ) := by
  constructor
  · exact sqrt_norm_le_wtHex x
  · exact_mod_cast wtHex_le_norm x

end Hexagon
