/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# Polar gate — the balanced ternary gate semantics (unary + binary over `Fin 3`)

**Idea history:** the "polar ternary gate" of the hex architecture — a gate whose value is a
*balanced* trit {−1, 0, +1}. Its unary part is the Z₆ hex rotation restricted to the 3-cycles
(`rot1`/`rot2`, the Z₃ subgroup), plus negation and identity; its binary part is the balanced
lattice (`tmin`/`tmax`) and the field arithmetic of F₃ (`tsum`/`tprod`). The "field-pair
completeness anchor" (distributivity of `tprod` over `tsum`) is what turns the carrier into F₃.
plan §3.

**Calibration:** DIRECT — finite combinatorics over Z/3.

**Status:** PROVED (2026-08-29) — all identities below closed by `fin_cases`/`decide`/`rfl`.
Zero `sorry`.

**Convention note (read first).** The task brief's digit mapping "0=−1, 1=0, 2=+1" is
*inconsistent* with the required identities: `tsum t 0 = t` forces digit `0` to be the
additive identity (balanced 0), and `tsum (neg t) t = 0` forces `neg` to be the Z/3 additive
inverse (so `neg 1 = 2`, i.e. `+1 ↦ −1`). The consistent mapping — the one this file uses, and
the one matching the brief's own "2+2 ≡ 1 (mod 3)" parenthetical literally — is the **residue**
mapping:

* digit `0` = balanced `0` (the additive identity),
* digit `1` = balanced `+1`,
* digit `2` = balanced `−1`.

Under it, `+`/`*`/`−` on `Fin 3` are exactly the field F₃ = Z/3, and the balanced min/max use
the value order −1 < 0 < +1 (digit order `2 < 0 < 1`). The `tritInt` map below records the
reading; `neg` is then the balanced sign-flip, and `tsum 1 1 = 2` is "+1 + +1 = −1".
-/

namespace Hexagon

namespace PolarGate

/-- A balanced trit, carried on `Fin 3` as Z/3: digit `0` = balanced 0 (additive identity),
    `1` = +1, `2` = −1. -/
abbrev Trit := Fin 3

/-- A unary gate: one trit in, one trit out. -/
abbrev unaryGate := Trit → Trit

/-- A binary gate: two trits in, one trit out. -/
abbrev binaryGate := Trit → Trit → Trit

/-- The balanced integer reading of a trit (residue representation: `2 ↦ −1`). -/
def tritInt (t : Trit) : ℤ :=
  match t.val with
  | 0 => 0
  | 1 => 1
  | _ => -1

/-- Negation: the Z/3 additive inverse = the balanced sign-flip (−1 ↔ +1, 0 fixed). -/
def neg : unaryGate := fun t => -t

/-- The identity gate. -/
def ident : unaryGate := fun t => t

/-- The 3-cycle `rot1`: +120° (add 1 mod 3) — `0 ↦ 1 ↦ 2 ↦ 0`. -/
def rot1 : unaryGate := fun t => t + 1

/-- The 3-cycle `rot2`: +240° = −120° (add 2 mod 3) — `0 ↦ 2 ↦ 1 ↦ 0`, the inverse of `rot1`. -/
def rot2 : unaryGate := fun t => t + 2

/-- Balanced minimum (value order −1 < 0 < +1). -/
def tmin : binaryGate := fun a b => if tritInt a ≤ tritInt b then a else b

/-- Balanced maximum (value order −1 < 0 < +1). -/
def tmax : binaryGate := fun a b => if tritInt a ≤ tritInt b then b else a

/-- Balanced sum, mod 3: `(+1)+(+1) = −1` (carry), i.e. `tsum 2 2 = 1`. -/
def tsum : binaryGate := fun a b => a + b

/-- Balanced product, mod 3 (the multiplication of F₃). -/
def tprod : binaryGate := fun a b => a * b

/-! ## 1. The unary part — negation, identity, and the Z₃ 3-cycles -/

/-- Negation is an involution. -/
theorem neg_neg (t : Trit) : neg (neg t) = t := by
  fin_cases t <;> decide

/-- `neg` is the balanced sign-flip: it negates the balanced integer value. -/
theorem neg_tritInt (t : Trit) : tritInt (neg t) = -tritInt t := by
  fin_cases t <;> decide

/-- The identity gate is the identity. -/
theorem ident_def (t : Trit) : ident t = t := rfl

/-- `rot1` is a 3-cycle (order 3). -/
theorem rot1_three (t : Trit) : rot1 (rot1 (rot1 t)) = t := by
  fin_cases t <;> decide

/-- `rot2` is a 3-cycle (order 3). -/
theorem rot2_three (t : Trit) : rot2 (rot2 (rot2 t)) = t := by
  fin_cases t <;> decide

/-- `rot2` is the inverse of `rot1`. -/
theorem rot2_rot1 (t : Trit) : rot2 (rot1 t) = t := by
  fin_cases t <;> decide

/-- `rot1` is the inverse of `rot2`. -/
theorem rot1_rot2 (t : Trit) : rot1 (rot2 t) = t := by
  fin_cases t <;> decide

/-! ## 2. The binary lattice part — `tmin` / `tmax` -/

/-- Balanced min is commutative. -/
theorem tmin_comm (a b : Trit) : tmin a b = tmin b a := by
  fin_cases a <;> fin_cases b <;> decide

/-- Balanced max is idempotent. -/
theorem tmax_idem (a : Trit) : tmax a a = a := by
  fin_cases a <;> decide

/-- Absorption: `tmin a (tmax a b) = a`. -/
theorem tmin_absorb (a b : Trit) : tmin a (tmax a b) = a := by
  fin_cases a <;> fin_cases b <;> decide

/-- Truth-table sample: `tmin (−1) (+1) = −1`. -/
theorem tmin_neg_pos : tmin 2 1 = 2 := by
  decide

/-- Truth-table sample: `tmax (−1) (+1) = +1`. -/
theorem tmax_neg_pos : tmax 2 1 = 1 := by
  decide

/-! ## 3. The binary field part — `tsum` / `tprod` over F₃ -/

/-- Balanced sum is commutative. -/
theorem tsum_comm (a b : Trit) : tsum a b = tsum b a := by
  fin_cases a <;> fin_cases b <;> decide

/-- `0` is the additive identity of `tsum`. -/
theorem tsum_zero (t : Trit) : tsum t 0 = t := by
  fin_cases t <;> decide

/-- `neg t` is the additive inverse of `t` under `tsum`. -/
theorem tsum_neg (t : Trit) : tsum (neg t) t = 0 := by
  fin_cases t <;> decide

/-- `neg` distributes over `tsum` (it is a group homomorphism). -/
theorem neg_tsum (a b : Trit) : neg (tsum a b) = tsum (neg a) (neg b) := by
  fin_cases a <;> fin_cases b <;> decide

/-- `tprod` is commutative (F₃ is a commutative ring). -/
theorem tprod_comm (a b : Trit) : tprod a b = tprod b a := by
  fin_cases a <;> fin_cases b <;> decide

/-- The F₃ field-pair completeness anchor: `tprod` distributes over `tsum`. -/
theorem tprod_distrib (a b c : Trit) : tprod a (tsum b c) = tsum (tprod a b) (tprod a c) := by
  fin_cases a <;> fin_cases b <;> fin_cases c <;> decide

/-- Truth-table sample: `(+1)+(+1) = −1` (balanced carry). -/
theorem tsum_plus_one : tsum 1 1 = 2 := by
  decide

/-- Truth-table sample: `2 + 2 ≡ 1 (mod 3)` (the brief's anchor, literally). -/
theorem tsum_22 : tsum 2 2 = 1 := by
  decide

end PolarGate

end Hexagon
