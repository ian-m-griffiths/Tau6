/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions

/-!
# T7 — the hex ↔ ℕ (u32) address bijection: axial/Eisenstein coordinates ↔ naturals

**Idea history:** the SPECULATION "hex addressing replaces the u32 XOR kernel"
(AGENTS.md §Quantum Properties; PROVER_NOTES "Remaining" — "blocked until someone
defines the bijection"); hexigon_conversation.md L10005–10105 (7-hex ↔ balanced
ternary) — this file lifts that to a bijection of the *whole* lattice `ℤ² ≃ ℕ`, so
every hex cell (Eisenstein integer, axial pair) gets a natural-number address.

**Calibration:** the bijection itself is DIRECT (standard: sign-fold `ℤ → ℕ` + a
pairing `ℕ×ℕ → ℕ`); the upgrade claim "hex addressing *replaces* the u32 XOR
kernel" remains SPECULATION — not proved here, this file only establishes the
addressing bijection (the first step toward evaluating it, per PROVER_NOTES).

**The formula.** Sign-folding `ℤ → ℕ`: `fold(z) = if z < 0 then 2·|z| − 1 else 2·|z|`,
so `0, 1, −1, 2, −2, … ↦ 0, 1, 2, 3, 4, …` (exact: the fold maps `[−2¹⁵, 2¹⁵−1]`
bijectively onto all of `[0, 2¹⁶−1]`). Inverse: `unfold(n) = if n even then n/2 else
−(n+1)/2` (division done in ℕ, then cast — all round-trip arithmetic is ℕ).

Pairing: mathlib's `Nat.pair` (Szudzik pairing) `pair(a,b) = if a < b then b² + a
else a² + a + b`, already proved a bijection by `Nat.pairEquiv` (proofs/AGENTS.md
rule: prefer mathlib's theorem). We deliberately do NOT use the Cantor pairing
`(a+b)(a+b+1)/2 + b`: the Cantor form needs 33 bits to pack two u16 coordinates,
while the Szudzik form packs two u16 values into **exactly** u32
(`(2¹⁶−1)² + (2¹⁶−1) + (2¹⁶−1) = 2³²−1` = `u32::MAX`, which decodes to the corner
`(−2¹⁵, −2¹⁵)`), matching `to_u32 : (i64, i64) → u32` in `rust-mirror/src/bijection.rs`.

**u32 range restriction.** The bijection is `ℤ² ≃ ℕ` — *all* naturals, no bound.
The u32 image is exactly the box `−2¹⁵ ≤ a, b ≤ 2¹⁵−1` (two u16 sign-folds fill u32
exactly): `toNat_lt_two_pow_32` proves every in-box cell addresses below `2³²`, and
`toNat_fin` places the address in `Fin (2³²)`. Coordinates outside the box do NOT fit
a u32; the Rust mirror documents this and tests round-trips inside the range and at
the u32 corners.

**Status:** PROVED (2026-08-28) — `signFold_signUnfold` / `signUnfold_signFold`
(fold↔unfold round-trip), `toNat_ofNat` / `ofNat_toNat` (round-trip = bijection),
`hexPairEquiv`, `toNat_bijective`, the Eisenstein wrappers, and the u32 range bound
`toNat_lt_two_pow_32` (+ `toNat_fin`). `lake build Hexagon.Bijection` green.
-/

namespace Hexagon

/-- Sign-folding `ℤ → ℕ`: `0, 1, −1, 2, −2, … ↦ 0, 1, 2, 3, 4, …`.
    `fold(z) = 2·|z| − 1` for `z < 0`, `fold(z) = 2·|z|` for `z ≥ 0`. -/
def signFold (z : ℤ) : ℕ := if z < 0 then 2 * Int.natAbs z - 1 else 2 * Int.natAbs z

/-- Inverse of `signFold`: `unfold(n) = n/2` for even `n`, `unfold(n) = −(n+1)/2` for odd `n`.
    Division happens in ℕ and is then cast to ℤ, so all round-trip arithmetic is
    natural-number arithmetic (`omega`-friendly). -/
def signUnfold (n : ℕ) : ℤ :=
  if n % 2 = 0 then ((n / 2 : ℕ) : ℤ) else -(((n + 1) / 2 : ℕ) : ℤ)

/-- `natAbs` of the ℤ-division-by-2 of a natural: the cast and the division commute. -/
lemma natAbs_div_two (n : ℕ) : ((n : ℤ) / 2).natAbs = n / 2 := by
  change (((n / 2 : ℕ) : ℤ)).natAbs = n / 2
  exact Int.natAbs_natCast (n / 2)

/-- `natAbs` of the ℤ-division-by-2 of `n + 1`: the cast and the division commute. -/
lemma natAbs_div_two_succ (n : ℕ) : (((n : ℤ) + 1) / 2).natAbs = (n + 1) / 2 := by
  change ((((n + 1) / 2 : ℕ) : ℤ)).natAbs = (n + 1) / 2
  exact Int.natAbs_natCast ((n + 1) / 2)

/-- Round-trip 1: `fold (unfold n) = n` — `signFold` is surjective (has a right inverse). -/
@[simp] theorem signFold_signUnfold (n : ℕ) : signFold (signUnfold n) = n := by
  dsimp [signFold, signUnfold]
  by_cases h1 : n % 2 = 0
  · rw [if_pos h1]
    have hnn : ¬ ((n : ℤ) / 2) < 0 := by omega
    rw [if_neg hnn]
    rw [natAbs_div_two]
    omega
  · rw [if_neg h1]
    have hlt : -(((n : ℤ) + 1) / 2) < 0 := by omega
    rw [if_pos hlt]
    rw [Int.natAbs_neg, natAbs_div_two_succ]
    omega

/-- Round-trip 2: `unfold (fold z) = z` — `signFold` is injective (has a left inverse). -/
@[simp] theorem signUnfold_signFold (z : ℤ) : signUnfold (signFold z) = z := by
  dsimp [signFold, signUnfold]
  by_cases h : z < 0
  · have hk : 1 ≤ Int.natAbs z := by
      have hz : 0 < Int.natAbs z := Int.natAbs_pos.mpr (ne_of_lt h)
      omega
    rw [if_pos h]
    split_ifs with hpar
    · omega
    · have hdiv : (2 * Int.natAbs z - 1 + 1) / 2 = Int.natAbs z := by omega
      change -(((2 * Int.natAbs z - 1 + 1) / 2 : ℕ) : ℤ) = z
      rw [hdiv]
      have hzneg : -↑(Int.natAbs z) = z := by
        cases Int.natAbs_eq z with
        | inl hz => omega
        | inr hz => exact hz.symm
      exact hzneg
  · rw [if_neg h]
    split_ifs with hpar
    · have hdiv : (2 * Int.natAbs z) / 2 = Int.natAbs z := by omega
      change (((2 * Int.natAbs z) / 2 : ℕ) : ℤ) = z
      rw [hdiv]
      exact Int.natAbs_of_nonneg (le_of_not_gt h)
    · omega

/-- The hex-cell address: axial/Eisenstein coordinates `ℤ × ℤ → ℕ`,
    `toNat (a, b) = pair (fold a) (fold b)` (mathlib's Szudzik pairing). -/
def toNat (p : ℤ × ℤ) : ℕ := Nat.pair (signFold p.1) (signFold p.2)

/-- Inverse of `toNat`: `ofNat n = (unfold (unpair n).1, unfold (unpair n).2)`. -/
def ofNat (n : ℕ) : ℤ × ℤ := (signUnfold (Nat.unpair n).1, signUnfold (Nat.unpair n).2)

/-- Round-trip 1: `toNat (ofNat n) = n` — `toNat` is surjective. -/
@[simp] theorem toNat_ofNat (n : ℕ) : toNat (ofNat n) = n := by
  simp [toNat, ofNat]

/-- Round-trip 2: `ofNat (toNat p) = p` — `toNat` is injective. -/
@[simp] theorem ofNat_toNat (p : ℤ × ℤ) : ofNat (toNat p) = p := by
  rcases p with ⟨a, b⟩
  simp [toNat, ofNat]

/-- The bijection as an `Equiv`: axial/Eisenstein coordinates `ℤ × ℤ ≃ ℕ`. -/
def hexPairEquiv : ℤ × ℤ ≃ ℕ :=
  { toFun := toNat, invFun := ofNat, left_inv := ofNat_toNat, right_inv := toNat_ofNat }

/-- `toNat` is a genuine bijection (both directions round-trip). -/
theorem toNat_bijective : Function.Bijective toNat := hexPairEquiv.bijective

/-- The Eisenstein-integer address: `a + bω ↦ pair (fold a) (fold b)`. -/
def eisensteinToNat (x : Eisenstein) : ℕ := toNat (x.a, x.b)

/-- Inverse of the Eisenstein-integer address. -/
def eisensteinOfNat (n : ℕ) : Eisenstein := ⟨(ofNat n).1, (ofNat n).2⟩

@[simp] theorem eisensteinToNat_eisensteinOfNat (n : ℕ) :
    eisensteinToNat (eisensteinOfNat n) = n := by
  simp [eisensteinToNat, eisensteinOfNat]

@[simp] theorem eisensteinOfNat_eisensteinToNat (x : Eisenstein) :
    eisensteinOfNat (eisensteinToNat x) = x := by
  rcases x with ⟨a, b⟩
  simp [eisensteinToNat, eisensteinOfNat]

/-- The bijection on the Eisenstein integers themselves: `ℤ[ω] ≃ ℕ`. -/
def eisensteinEquiv : Eisenstein ≃ ℕ :=
  { toFun := eisensteinToNat, invFun := eisensteinOfNat,
    left_inv := eisensteinOfNat_eisensteinToNat, right_inv := eisensteinToNat_eisensteinOfNat }

/-- Two u16 sign-folds pack into exactly one u32: `pair x y < 2³²` for `x, y < 2¹⁶`.
    (Why the Szudzik pairing and not Cantor: `(2¹⁶−1)² + (2¹⁶−1) + (2¹⁶−1) = 2³²−1`,
    whereas the Cantor pairing of two u16s needs 33 bits.) -/
lemma pair_lt_two_pow_32 {x y : ℕ} (hx : x < 2 ^ 16) (hy : y < 2 ^ 16) :
    Nat.pair x y < 2 ^ 32 := by
  dsimp [Nat.pair]
  by_cases h : x < y
  · rw [if_pos h]
    have hy1 : y ≤ 2 ^ 16 - 1 := by omega
    have hx1 : x ≤ 2 ^ 16 - 2 := by omega
    have hb : y * y + x ≤ (2 ^ 16 - 1) * (2 ^ 16 - 1) + (2 ^ 16 - 2) := by
      nlinarith
    norm_num at hb ⊢
    omega
  · rw [if_neg h]
    have hx1 : x ≤ 2 ^ 16 - 1 := by omega
    have hy1 : y ≤ 2 ^ 16 - 1 := by omega
    have hb : x * x + x + y ≤ (2 ^ 16 - 1) * (2 ^ 16 - 1) + (2 ^ 16 - 1) + (2 ^ 16 - 1) := by
      nlinarith
    norm_num at hb ⊢
    omega

/-- A coordinate in the u32 box `−2¹⁵ ≤ z ≤ 2¹⁵−1` sign-folds below `2¹⁶`
    (the fold maps `[−2¹⁵, 2¹⁵−1]` bijectively onto all of `[0, 2¹⁶−1]`). -/
lemma signFold_lt {z : ℤ} (hz : -2 ^ 15 ≤ z ∧ z ≤ 2 ^ 15 - 1) : signFold z < 2 ^ 16 := by
  norm_num at hz ⊢
  dsimp [signFold]
  by_cases h : z < 0
  · rw [if_pos h]
    have hzneg : z = -↑(Int.natAbs z) := by
      cases Int.natAbs_eq z with
      | inl hz2 => omega
      | inr hz2 => exact hz2
    omega
  · rw [if_neg h]
    have hkz : (Int.natAbs z : ℤ) = z := Int.natAbs_of_nonneg (le_of_not_gt h)
    omega

/-- The u32 range restriction: coordinates in the box `−2¹⁵ ≤ a, b ≤ 2¹⁵−1` address
    below `2³²` (in fact below `2³¹` — the bound is loose, but the point is u32-sized).
    The box is EXACT: it is precisely what two u16 sign-folds cover, and the packing is
    tight (`u32::MAX` decodes to the corner `(−2¹⁵, −2¹⁵)`). Coordinates outside the
    box do not fit in a u32: the bijection is `ℤ² ≃ ℕ` with no bound. -/
theorem toNat_lt_two_pow_32 (a b : ℤ) (ha : -2 ^ 15 ≤ a ∧ a ≤ 2 ^ 15 - 1)
    (hb : -2 ^ 15 ≤ b ∧ b ≤ 2 ^ 15 - 1) : toNat (a, b) < 2 ^ 32 := by
  have hfa : signFold a < 2 ^ 16 := signFold_lt ha
  have hfb : signFold b < 2 ^ 16 := signFold_lt hb
  change Nat.pair (signFold a) (signFold b) < 2 ^ 32
  exact pair_lt_two_pow_32 hfa hfb

/-- Every in-box cell addresses within `Fin (2³²)`: the address is a valid `Fin` value. -/
theorem toNat_fin (a b : ℤ) (ha : -2 ^ 15 ≤ a ∧ a ≤ 2 ^ 15 - 1)
    (hb : -2 ^ 15 ≤ b ∧ b ≤ 2 ^ 15 - 1) : ∃ n : Fin (2 ^ 32), n.val = toNat (a, b) :=
  ⟨⟨toNat (a, b), toNat_lt_two_pow_32 a b ha hb⟩, rfl⟩

end Hexagon
