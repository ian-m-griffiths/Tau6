/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.TernaryCell
import Hexagon.EnergyModel
import Hexagon.ThresholdLowerBound

/-!
# Junction energy — the normalized cost model of the polarity-junction encoding

The **energy cost model** behind the transport thesis (`scripts/transport.py`): a trit is
carried one-hot on two wires (push / pull), so at most ONE channel is energized per state,
and the null state energizes neither. This file builds the *normalized* cost model — the
theorems are about the **ratio**, not pJ:

* a ±1 trit (one channel energized) costs **1**;
* a null trit costs **e** with `0 ≤ e < 1` (measured: `e = 0.05/1.20 = 1/24`; ideal: `e = 0`).

**Idea history:** Ian (2026) "one-hot-per-direction" ternary cell (`TernaryCell.lean`);
the measured fair-fight numbers (`circuit/ENERGY_RESULTS.md` CORRECTION 1): +−1 trit =
1.20 pJ, null = 0.05 pJ, binary natural single-ended = 0.512 pJ/bit (`scripts/transport.py`).
The transport thesis: null-heavy data is cheaper (champion 0.081 pJ/bit vs 0.512 binary
natural), but — the HONEST caveat — the free-null saving is **conditional** on null-heavy
data; at uniform traffic (nulls = 1/3) the ternary link only ~ties binary.

**Calibration:** DIRECT — pure ℚ algebra (`field_simp`/`nlinarith`/`norm_num`/`ring`) plus
exact ℕ information-counting; the only non-rational ingredient (`log₂ 3`, irrational) is
pinned by exact integer facts and carried as a *hypothesis* on the parameter `c` (see below).

**Status:** PROVED (2026-08-30) — zero `sorry`; every theorem below checks with
`lake env lean Hexagon/JunctionEnergy.lean`.
-/

namespace Hexagon

/-! ## 1. The normalized per-trit energy — a function of the channel state -/

/-- Normalized per-trit energy: a ±1 trit energizes one channel and costs `1`; the null
state energizes nothing (or almost nothing) and costs `e`, with `0 ≤ e < 1`.
`e = 0` is "null is free"; the measured ratio is `e = 0.05/1.20 = 1/24`. -/
def junctionCost (e : ℚ) : Trit → ℚ
  | .pos  => 1
  | .neg  => 1
  | .zero => e

/-- `junctionCost e .pos = 1`. -/
theorem junctionCost_pos (e : ℚ) : junctionCost e .pos = 1 := by
  simp [junctionCost]

/-- `junctionCost e .neg = 1`. -/
theorem junctionCost_negval (e : ℚ) : junctionCost e .neg = 1 := by
  simp [junctionCost]

/-- `junctionCost e .zero = e`. -/
theorem junctionCost_zero (e : ℚ) : junctionCost e .zero = e := by
  simp [junctionCost]

/-- A null costs strictly less than a ±1 trit iff `e < 1`. -/
theorem junctionCost_null_lt (e : ℚ) (he : e < 1) : junctionCost e .zero < junctionCost e .pos := by
  simpa [junctionCost] using he

/-- For `0 ≤ e`, every trit costs at least `0`. -/
theorem junctionCost_nonneg (e : ℚ) (he : 0 ≤ e) (t : Trit) : 0 ≤ junctionCost e t := by
  cases t <;> simp [junctionCost, he]

/-- For `e ≤ 1`, every trit costs at most `1`. -/
theorem junctionCost_le_one (e : ℚ) (he : e ≤ 1) (t : Trit) : junctionCost e t ≤ 1 := by
  cases t <;> simp [junctionCost, he]

/-! ## 2. Word energy — the sum of per-trit energies over a 12-trit word -/

/-- A 12-trit word. -/
abbrev Word := Fin 12 → Trit

/-- The number of null trits in a word. -/
def nullCount (w : Word) : ℕ :=
  (Finset.univ.filter (fun i : Fin 12 => w i = .zero)).card

/-- The null fraction of a word (in `[0,1]`). -/
def nullFraction (w : Word) : ℚ := (nullCount w : ℚ) / 12

/-- Word energy = the sum of the per-trit junction energies. -/
def wordEnergy (e : ℚ) (w : Word) : ℚ :=
  ∑ i : Fin 12, junctionCost e (w i)

/-- `junctionCost e t` as a linear function of the null indicator `[t = .zero]`. -/
lemma junctionCost_eq_one_sub (e : ℚ) (t : Trit) :
    junctionCost e t = 1 - (1 - e) * (if t = .zero then (1 : ℚ) else 0) := by
  cases t <;> simp [junctionCost]

/-- The closed form: a word with `n` nulls costs `12 − n·(1−e)` — each of the `12−n`
active trits costs `1` and each null costs `e`, so the energy is linear in the null count
with slope `−(1−e)`. -/
theorem wordEnergy_eq (e : ℚ) (w : Word) :
    wordEnergy e w = 12 - (nullCount w : ℚ) * (1 - e) := by
  unfold wordEnergy nullCount
  rw [Finset.sum_congr rfl (fun i _ => junctionCost_eq_one_sub e (w i))]
  rw [Finset.sum_sub_distrib, ← Finset.mul_sum]
  rw [Finset.sum_const,
      Finset.sum_boole (s := (Finset.univ : Finset (Fin 12))) (p := fun i => w i = .zero)]
  rw [Finset.card_fin]
  norm_num
  ring

/-! ## 3. Polarity invariance — negation and any push↔pull relabeling change no energy -/

/-- The polarity negation: push ↔ pull, null fixed. This is the "flip push↔pull"
relabeling of the two wires. -/
def negate : Trit → Trit
  | .pos  => .neg
  | .zero => .zero
  | .neg  => .pos

/-- Negation is an involution. -/
theorem negate_negate (t : Trit) : negate (negate t) = t := by
  cases t <;> rfl

/-- Negation is energy-invariant: flipping push↔pull changes no energy (it swaps two
channels that cost the same `1`, and fixes the null). -/
theorem junctionCost_negate (e : ℚ) (t : Trit) : junctionCost e (negate t) = junctionCost e t := by
  cases t <;> simp [junctionCost, negate]

/-- **The general polarity theorem.** *Any* symmetric relabeling of the trit states — i.e.
any permutation `σ : Trit ≃ Trit` that fixes the null state (hence only swaps the two
equal-cost polar states push/pull) — is energy-invariant. The only such relabelings are
`id` and `negate`, so this is exactly the Z₂ group of polarity symmetries. (No
`JunctionPolarity` module exists yet, so the statement lives here.) -/
theorem junctionCost_relabel (e : ℚ) (σ : Trit ≃ Trit) (hσ : σ .zero = .zero) (t : Trit) :
    junctionCost e (σ t) = junctionCost e t := by
  cases t with
  | zero =>
      simp [junctionCost, hσ]
  | pos =>
      have hσp : σ .pos ≠ .zero := by
        intro h
        have h' : (Trit.pos : Trit) = Trit.zero := σ.injective (h.trans hσ.symm)
        cases h'
      cases hpos : σ .pos with
      | zero => exact (hσp hpos).elim
      | pos => simp [junctionCost]
      | neg => simp [junctionCost]
  | neg =>
      have hσn : σ .neg ≠ .zero := by
        intro h
        have h' : (Trit.neg : Trit) = Trit.zero := σ.injective (h.trans hσ.symm)
        cases h'
      cases hneg : σ .neg with
      | zero => exact (hσn hneg).elim
      | pos => simp [junctionCost]
      | neg => simp [junctionCost]

/-- Pointwise negation of a word. -/
def negateWord (w : Word) : Word := fun i => negate (w i)

/-- Word energy is invariant under pointwise polarity negation. -/
theorem wordEnergy_negateWord (e : ℚ) (w : Word) :
    wordEnergy e (negateWord w) = wordEnergy e w := by
  simp [wordEnergy, negateWord, junctionCost_negate]

/-! ## 4. Information content — exact integer pinning of `log₂ 3` -/

/-- `3^12 < 2^20`: a 12-trit word (3¹² values) fits in **20** bits. -/
theorem three_pow_12_lt_two_pow_20 : (3 : ℕ) ^ 12 < (2 : ℕ) ^ 20 := by
  norm_num

/-- `2^19 < 3^12`: **19** bits do NOT suffice for a 12-trit word. So 20 bits is the minimal
binary width carrying the same information as 12 trits. -/
theorem two_pow_19_lt_three_pow_12 : (2 : ℕ) ^ 19 < (3 : ℕ) ^ 12 := by
  norm_num

/-- `3^17 < 2^27`, i.e. `log₂ 3 < 27/17` (since `17·log₂3 < 27`). -/
theorem three_pow_17_lt_two_pow_27 : (3 : ℕ) ^ 17 < (2 : ℕ) ^ 27 := by
  norm_num

/- Together `2^19 < 3^12` and `3^12 < 2^20` pin `log₂ 3` to the open interval
`(19/12, 20/12)`; the tighter bound `log₂ 3 < 27/17` (from `3^17 < 2^27`) is the one the
honest-tie theorem below uses. In this rational model the bits-per-trit `c` is carried as a
*parameter* with these bounds as hypotheses — the only way to stay in ℚ, since `log₂ 3`
itself is irrational. -/

/-! ## 5. The honest bound: conditional win + the break-even null fraction -/

/-- The ideal channel-activation energy of a `B`-bit binary word at uniform traffic: each
bit is one wire energized with probability 1/2, so `B/2` units. (Radix-agnostic: the same
"1 unit = one wire energization" used for the ternary channel.) -/
def binaryWordIdeal (B : ℕ) : ℚ := (B : ℚ) / 2

/-- **Structural win (honest direction (a)).** A 12-trit word and a 20-bit binary word carry
the same information (by `three_pow_12_lt_two_pow_20` and `two_pow_19_lt_three_pow_12`).
When the word is null-heavy — `nullCount > 2/(1−e)`, i.e. null fraction `> 1/(6(1−e))` —
its word energy is STRICTLY below the 20-bit binary word's energy. -/
theorem structural_win (e : ℚ) (he : e < 1) (w : Word)
    (hn : (2 : ℚ) / (1 - e) < (nullCount w : ℚ)) :
    wordEnergy e w < binaryWordIdeal 20 := by
  unfold binaryWordIdeal
  norm_num
  rw [wordEnergy_eq]
  have hden : 0 < 1 - e := by linarith
  have hne : (2 : ℚ) < (nullCount w : ℚ) * (1 - e) := by
    rw [div_lt_iff₀ hden] at hn
    exact hn
  nlinarith

/-- Concrete: with a FREE null (`e = 0`), any 12-trit word with at least 3 nulls (null
fraction ≥ 1/4) beats the 20-bit binary word. -/
theorem structural_win_free_null (w : Word) (hn : 3 ≤ nullCount w) :
    wordEnergy 0 w < binaryWordIdeal 20 := by
  apply structural_win 0 (by norm_num : (0 : ℚ) < 1) w
  have h2n : (2 : ℕ) < nullCount w := by omega
  have h2q : (2 : ℚ) < (nullCount w : ℚ) := by exact_mod_cast h2n
  simpa using h2q

/-- Concrete: with the MEASURED null (`e = 1/24`), any 12-trit word with at least 3 nulls
beats the 20-bit binary word. -/
theorem structural_win_measured_null (w : Word) (hn : 3 ≤ nullCount w) :
    wordEnergy (1 / 24) w < binaryWordIdeal 20 := by
  apply structural_win (1 / 24) (by norm_num : (1 : ℚ) / 24 < 1) w
  have h3q : (3 : ℚ) ≤ (nullCount w : ℚ) := by exact_mod_cast hn
  have hgoal : (2 : ℚ) / (1 - (1 : ℚ) / 24) < (nullCount w : ℚ) := by
    have : (2 : ℚ) / (1 - (1 : ℚ) / 24) = 48 / 23 := by norm_num
    rw [this]
    nlinarith
  exact hgoal

/-! ### 5b. The fair-fight per-bit comparison and the break-even null fraction

The structural win above prices binary at the *ideal* 1/2 per bit. The MEASURED fair-fight
(`scripts/transport.py`) prices binary natural single-ended at `0.512 pJ/bit`, which in the
normalized model (÷ the 1.20 pJ channel) is `b = 32/75`. Compared **per bit** at the true
information content (`c = log₂ 3 ≈ 1.585` bits per trit), the ternary win is *conditional*:
it exists only for null fractions above a threshold, and that threshold is **strictly above
1/3** — so at uniform traffic there is no win (the honest "≈ ties").
-/

/-- Normalized binary natural bit energy: `0.512 pJ/bit ÷ 1.20 pJ/channel = 32/75`. -/
def binaryNatural : ℚ := 32 / 75

/-- Normalized measured null energy: `0.05 pJ ÷ 1.20 pJ/channel = 1/24`. -/
def nullEnergy : ℚ := 1 / 24

/-- Ternary energy **per bit** at null fraction `p`: per-trit energy `(1−p)·1 + p·e`,
divided by the `c` bits a trit carries. -/
def ternaryPerBit (e c p : ℚ) : ℚ := ((1 - p) + p * e) / c

/-- The break-even null fraction: the unique `p` where ternary per-bit energy equals the
binary baseline `b`. Above it ternary wins, below it binary wins. -/
def breakEven (e c b : ℚ) : ℚ := (1 - b * c) / (1 - e)

/-- **Exact break-even.** For any null cost `e < 1` and any bits-per-trit `c > 0`, the
ternary per-bit energy is strictly below the binary baseline `b` **iff** the null fraction
exceeds `(1 − b·c)/(1 − e)`. This is the honest two-sided bound: the win is *exactly* the
null-heavy regime. -/
theorem ternary_wins_iff (e c b p : ℚ) (hc : 0 < c) (he : e < 1) :
    ternaryPerBit e c p < b ↔ p > (1 - b * c) / (1 - e) := by
  unfold ternaryPerBit
  constructor
  · intro h
    have hmul : (1 - p) + p * e < b * c := by
      rw [div_lt_iff₀ hc] at h
      exact h
    have hlin : (1 - b * c) < p * (1 - e) := by nlinarith
    exact (div_lt_iff₀ (by linarith : 0 < 1 - e)).2 hlin
  · intro h
    have hlin : (1 - b * c) < p * (1 - e) := (div_lt_iff₀ (by linarith : 0 < 1 - e)).1 h
    have hmul : (1 - p) + p * e < b * c := by nlinarith
    rw [div_lt_iff₀ hc]
    exact hmul

/-- **The break-even null fraction is strictly above 1/3** (with the measured `b = 32/75`,
`e = 1/24`, and `c = log₂ 3`, whose upper bound `c < 27/17` is the integer fact `3^17 < 2^27`
proved above). So the ternary win requires strictly *more* nulls than the uniform 1/3. -/
theorem breakEven_above_uniform {c : ℚ} (hclog : c < 27 / 17) :
    breakEven nullEnergy c binaryNatural > (1 / 3) := by
  unfold breakEven nullEnergy binaryNatural
  rw [gt_iff_lt]
  have hden : 0 < (1 : ℚ) - 1 / 24 := by norm_num
  rw [lt_div_iff₀ hden]
  have hnum : ((1 : ℚ) / 3) * (1 - 1 / 24) = 23 / 72 := by norm_num
  rw [hnum]
  nlinarith

/-- **Honest tie at uniform.** At uniform traffic (`p = 1/3`), the ternary per-bit energy is
strictly ABOVE the binary natural per-bit energy — so there is *no* win at uniform; the win
is conditional on null-heavy data (`c < 27/17` is `3^17 < 2^27`). -/
theorem at_uniform_not_cheaper {c : ℚ} (hc : 0 < c) (hclog : c < 27 / 17) :
    ternaryPerBit nullEnergy c (1 / 3) > binaryNatural := by
  unfold ternaryPerBit nullEnergy binaryNatural
  have hnum : ((1 : ℚ) - (1 : ℚ) / 3) + ((1 : ℚ) / 3) * (1 / 24) = 49 / 72 := by norm_num
  rw [hnum]
  rw [gt_iff_lt]
  rw [lt_div_iff₀ hc]
  nlinarith

/-- **The tie is tight** (honest "≈"): at uniform traffic the excess over binary natural is
less than `1/100` of a channel energization (≈ 0.003 pJ/bit, under 1% of the 0.512 pJ/bit
baseline). Uses the lower bound `c > 19/12` (`2^19 < 3^12`). -/
theorem uniform_tie_gap {c : ℚ} (hc : 0 < c) (hclog : 19 / 12 < c) :
    ternaryPerBit nullEnergy c (1 / 3) - binaryNatural < 1 / 100 := by
  unfold ternaryPerBit nullEnergy binaryNatural
  have hnum : ((1 : ℚ) - (1 : ℚ) / 3) + ((1 : ℚ) / 3) * (1 / 24) = 49 / 72 := by norm_num
  rw [hnum]
  have hlin : (49 : ℚ) / 72 < (32 / 75 + 1 / 100) * c := by nlinarith
  have hdiv : (49 : ℚ) / 72 / c < 32 / 75 + 1 / 100 := by
    rw [div_lt_iff₀ hc]
    exact hlin
  nlinarith

/-- **The win is real somewhere** (the other side of the two-sided bound): at null fraction
`p = 1/2` (half the trits null — genuinely null-heavy) the ternary per-bit energy is strictly
BELOW the binary natural baseline (`c > 19/12` is `2^19 < 3^12`). Combined with
`at_uniform_not_cheaper`, this brackets the truth: no win at 1/3, a strict win at 1/2. -/
theorem win_at_null_half {c : ℚ} (hc : 0 < c) (hclog : 19 / 12 < c) :
    ternaryPerBit nullEnergy c (1 / 2) < binaryNatural := by
  unfold ternaryPerBit nullEnergy binaryNatural
  have hnum : ((1 : ℚ) - (1 : ℚ) / 2) + ((1 : ℚ) / 2) * (1 / 24) = 25 / 48 := by norm_num
  rw [hnum]
  rw [div_lt_iff₀ hc]
  nlinarith

/-! ## 6. The compute caveat — this model does NOT capture the 2-threshold sensing cost -/

/-- The compute-side cost per bit (threshold-sensing) is a radix-dependent constant `C` —
it does not depend on the data's null fraction. (This is the `(b−1)/ln b` axis proved in
`ThresholdLowerBound.lean`: `Hexagon.ternary_worse_than_binary` shows ternary is ≈ 1.26×
worse than binary per bit there.) -/
def computeCost (C : ℚ) : ℚ := C

/-- Total per-bit cost = transport (null-fraction-dependent, this module) + compute
(radix-dependent only, `ThresholdLowerBound.lean`). -/
def totalPerBit (e c p C : ℚ) : ℚ := ternaryPerBit e c p + computeCost C

/-- **The compute caveat (honest, formal).** The channel-activation model in this file
prices only the TRANSPORT/static cost (how many wires are energized). It does NOT price the
2-threshold sensing needed to READ a trit (three levels ⇒ two thresholds). That sensing cost
is a separate, radix-only term that is ADDITIVE and null-fraction-invariant: the null-heavy
saving touches ONLY the transport term, so it can neither be erased by, nor erase, the
compute penalty. Formally, the total-cost saving between two null fractions is exactly the
transport saving. -/
theorem transport_saving_does_not_erase_compute (e c p q C : ℚ) :
    totalPerBit e c p C - totalPerBit e c q C = ternaryPerBit e c p - ternaryPerBit e c q := by
  unfold totalPerBit computeCost
  ring

end Hexagon
