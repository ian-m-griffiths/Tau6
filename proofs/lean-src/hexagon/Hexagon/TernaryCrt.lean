/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.PolarGate
import Hexagon.CrtHex

/-!
# Ternary CRT + trit-shift ÷3 — the two rebuild anchors of `trit_tricks.md`

This file proves the two highest-value open targets from the trit-tricks survey
(`docs/compute/trit_tricks.md`, 2026-08-29, Wave 1 subagent 3):

1. **The ternary CRT instance** (the "XOR → hex" bridge, survey rows #2/#10). A
   balanced-ternary number's value mod 6 is determined by the *digit-sum parity*
   (mod 2) and the *least trit* (mod 3): `n mod 6 = (t₀, S mod 2)` is the Z₆ angle
   the whole hex layer runs on.
2. **The trit-shift ÷3 truncation** (the 3-adic analog of the `d >> 1` RG flow, survey
   row #6/#8): dropping the least trit divides the value by 3.

**Idea history:** `trit_tricks.md` rows #2 (`parity(n) = parity(S)` because `3ⁱ ≡ 1
(mod 2)`), #10 (`n mod 3 = t₀` because `3ⁱ ≡ 0 (mod 3)` for `i ≥ 1`), #6/#8 (`d >> 1`
= ring÷2 in binary; the ternary analog is ÷3 = ring÷3); the CRT pair
`n mod 6 = (t₀, S mod 2)`; the CRT inverse `3a + 4b` already in `CrtHex.crtInv`.

**Calibration:** DIRECT — classical modular arithmetic (CRT, `2·3 = 6` coprime) and
base-3 positional arithmetic. The digit list is *little-endian*: index `i` is the `3ⁱ`
place, so `ds 0` is the least-significant trit. The balanced reading of each trit is
`PolarGate.tritInt` (digit `0` = balanced `0`, `1` = `+1`, `2` = `−1`).

**Convention on `%`:** Lean's `%` on `ℤ` is the *Euclidean* remainder (always in
`[0, |n|)` for `n > 0`), so `tritInt t % 3` is the residue `2, 0, 1` for `t = −1, 0,
+1` — exactly the residue representation of `PolarGate.lean`. `Int.ModEq n a b` is
*definitionally* `a % n = b % n`, which is the workhorse of every proof here.

**Edge case:** the theorems that name `ds 0` are stated for `Fin (n + 1)` (so the least
trit always exists); `val`/`digitSum`/`val_mod_two` are stated for every `n` (including
the empty `n = 0` list, where both sides are `0`).

**Status:** PROVED (2026-08-29) — `val_add_shift3`, `val_mod_three`, `val_mod_two`,
`val_crt` (+ `crt_assembly`), `shift3_of_null`, `div3_truncation`. Zero `sorry`.
-/

namespace Hexagon

open PolarGate

/-! ## The digit-list value and the ÷3 shift -/

/-- The integer value of a balanced-ternary digit list, little-endian: index `i` is the
    `3ⁱ` place, so `val ds = Σᵢ tritInt (ds i) · 3ⁱ`. -/
def val {n : ℕ} (ds : Fin n → Fin 3) : ℤ :=
  ∑ i : Fin n, tritInt (ds i) * (3 : ℤ) ^ (i : ℕ)

/-- The balanced digit sum `Σᵢ tritInt (ds i)` (the signed "popcount", survey row #1). -/
def digitSum {n : ℕ} (ds : Fin n → Fin 3) : ℤ :=
  ∑ i : Fin n, tritInt (ds i)

/-- The trit right-shift ÷3: drop the least-significant trit (`ds 0`). -/
def shift3 {n : ℕ} (ds : Fin (n + 1) → Fin 3) : Fin n → Fin 3 :=
  fun i => ds i.succ

/-! ## The base-3 expansion (the shared truncation law) -/

/-- `val ds = tritInt (ds 0) + 3 * val (shift3 ds)`: the base-3 expansion. This is the
    *true truncation law* — the whole value is the least trit plus `3 ·` the shifted
    value, exactly mirroring `x = x % 3 + 3·(x / 3)` on the trit level. -/
theorem val_add_shift3 {n : ℕ} (ds : Fin (n + 1) → Fin 3) :
    val ds = tritInt (ds 0) + 3 * val (shift3 ds) := by
  dsimp [val, shift3]
  rw [Fin.sum_univ_succ]
  simp only [Fin.val_zero, pow_zero, mul_one, Fin.val_succ, pow_succ]
  rw [Finset.mul_sum]
  congr 1
  apply Finset.sum_congr rfl
  intro i hi
  ring

/-! ## Target 1 — the ternary CRT instance (`n mod 6 = (t₀, S mod 2)`) -/

/-- `val ds mod 3` is the least trit: only `ds 0` survives, because `3ⁱ ≡ 0 (mod 3)`
    for every `i ≥ 1`. -/
theorem val_mod_three {n : ℕ} (ds : Fin (n + 1) → Fin 3) :
    val ds % 3 = tritInt (ds 0) % 3 := by
  rw [val_add_shift3]
  exact Int.add_mul_emod_self_left (tritInt (ds 0)) 3 (val (shift3 ds))

/-- `val ds mod 2` is the digit-sum parity: `3ⁱ ≡ 1 (mod 2)` for every `i`, so each
    weighted trit contributes only its balanced sign. -/
theorem val_mod_two {n : ℕ} (ds : Fin n → Fin 3) :
    val ds % 2 = digitSum ds % 2 := by
  dsimp [val, digitSum]
  exact Int.ModEq.sum (s := (Finset.univ : Finset (Fin n)))
    (f := fun i => tritInt (ds i) * (3 : ℤ) ^ (i : ℕ))
    (g := fun i => tritInt (ds i)) (n := 2) (by
      intro i hi
      have h3 : (3 : ℤ) ≡ 1 [ZMOD 2] := by norm_num
      have hp : (3 : ℤ) ^ (i : ℕ) ≡ (1 : ℤ) ^ (i : ℕ) [ZMOD 2] := Int.ModEq.pow (i : ℕ) h3
      simpa using (Int.ModEq.refl (tritInt (ds i))).mul hp)

/-- CRT lift: congruent mod 2 and mod 3 implies congruent mod 6 (`2` and `3` are coprime). -/
lemma modEq_six_of_two_three {x y : ℤ} (h2 : x ≡ y [ZMOD 2]) (h3 : x ≡ y [ZMOD 3]) :
    x ≡ y [ZMOD 6] := by
  have hd2 : (2 : ℤ) ∣ y - x := Int.modEq_iff_dvd.mp h2
  have hd3 : (3 : ℤ) ∣ y - x := Int.modEq_iff_dvd.mp h3
  have hd2n : 2 ∣ (y - x).natAbs := by simpa using (Int.natAbs_dvd_natAbs.mpr hd2)
  have hd3n : 3 ∣ (y - x).natAbs := by simpa using (Int.natAbs_dvd_natAbs.mpr hd3)
  have hd6n : 6 ∣ (y - x).natAbs :=
    Nat.Coprime.mul_dvd_of_dvd_of_dvd (by norm_num : Nat.Coprime 2 3) hd2n hd3n
  have hd6 : (6 : ℤ) ∣ y - x := by simpa using (Int.natAbs_dvd_natAbs.mp hd6n)
  exact Int.modEq_of_dvd hd6

/-- The CRT inverse `3a + 4b`: `x mod 6 = (3·(x mod 2) + 4·(x mod 3)) mod 6`. Mod 2 this
    is `3·a + 4·b ≡ 1·a + 0 ≡ a`; mod 3 it is `0 + 1·b ≡ b` — the same `crtInv` already
    used in `CrtHex.lean`. -/
theorem crt_assembly (x : ℤ) : x % 6 = (3 * (x % 2) + 4 * (x % 3)) % 6 := by
  apply modEq_six_of_two_three
  · have hx2 : x ≡ x % 2 [ZMOD 2] := (Int.mod_modEq x 2).symm
    have hsum' : 3 * (x % 2) + 4 * (x % 3) ≡ x % 2 [ZMOD 2] := by
      have hmul1 : 3 * (x % 2) ≡ 1 * (x % 2) [ZMOD 2] :=
        (by norm_num : (3 : ℤ) ≡ 1 [ZMOD 2]).mul (Int.ModEq.refl (x % 2))
      have hmul2 : 4 * (x % 3) ≡ 0 * (x % 3) [ZMOD 2] :=
        (by norm_num : (4 : ℤ) ≡ 0 [ZMOD 2]).mul (Int.ModEq.refl (x % 3))
      simpa using hmul1.add hmul2
    exact hx2.trans hsum'.symm
  · have hx3 : x ≡ x % 3 [ZMOD 3] := (Int.mod_modEq x 3).symm
    have hsum' : 3 * (x % 2) + 4 * (x % 3) ≡ x % 3 [ZMOD 3] := by
      have hmul1 : 3 * (x % 2) ≡ 0 * (x % 2) [ZMOD 3] :=
        (by norm_num : (3 : ℤ) ≡ 0 [ZMOD 3]).mul (Int.ModEq.refl (x % 2))
      have hmul2 : 4 * (x % 3) ≡ 1 * (x % 3) [ZMOD 3] :=
        (by norm_num : (4 : ℤ) ≡ 1 [ZMOD 3]).mul (Int.ModEq.refl (x % 3))
      simpa using hmul1.add hmul2
    exact hx3.trans hsum'.symm

/-- **The CRT assembly.** `val ds mod 6` is recovered from the two free residues — the
    digit-sum parity `digitSum ds % 2` and the least trit `tritInt (ds 0) % 3` — by the
    CRT inverse `3a + 4b`. This is the "XOR → hex" bridge: a balanced-ternary number's
    Z₆ angle is exactly `(t₀, S mod 2)`. -/
theorem val_crt {n : ℕ} (ds : Fin (n + 1) → Fin 3) :
    val ds % 6 = (3 * (digitSum ds % 2) + 4 * (tritInt (ds 0) % 3)) % 6 := by
  rw [crt_assembly (val ds)]
  rw [val_mod_two ds, val_mod_three ds]

/-! ## Target 2 — the trit-shift ÷3 truncation -/

/-- A balanced trit divisible by 3 is the null trit: `tritInt t ∈ {−1, 0, +1}` and `3` is
    the only multiple of 3 in that range. -/
lemma tritInt_eq_zero_of_dvd_three (t : Fin 3) (h : (3 : ℤ) ∣ tritInt t) : tritInt t = 0 := by
  fin_cases t <;> simp [tritInt] at h ⊢

/-- Dropping a null least trit divides the value by 3 exactly: if `ds 0 = 0` then
    `val ds = 3 * val (shift3 ds)`, so `val (shift3 ds) = val ds / 3`. -/
theorem shift3_of_null {n : ℕ} (ds : Fin (n + 1) → Fin 3) (h : tritInt (ds 0) = 0) :
    val (shift3 ds) = val ds / 3 := by
  have hds : val ds = 3 * val (shift3 ds) := by
    rw [val_add_shift3 ds, h, zero_add]
  rw [hds]
  exact (Int.mul_ediv_cancel_left (val (shift3 ds)) (by norm_num : (3 : ℤ) ≠ 0)).symm

/-- **÷3 truncation.** When `val ds` is a multiple of 3, `val ds / 3` is exactly the
    value of the shifted list — integer division drops the least trit. (That `3 ∣ val ds`
    forces `ds 0` to be null is `val_mod_three` / `tritInt_eq_zero_of_dvd_three`.) -/
theorem div3_truncation {n : ℕ} (ds : Fin (n + 1) → Fin 3) (h : (3 : ℤ) ∣ val ds) :
    val (shift3 ds) = val ds / 3 := by
  have h0 : tritInt (ds 0) = 0 := by
    apply tritInt_eq_zero_of_dvd_three
    have h1 : (3 : ℤ) ∣ 3 * val (shift3 ds) := ⟨val (shift3 ds), by ring⟩
    have hsub : (3 : ℤ) ∣ val ds - 3 * val (shift3 ds) := Int.dvd_sub h h1
    simpa [val_add_shift3 ds] using hsub
  exact shift3_of_null ds h0

end Hexagon
