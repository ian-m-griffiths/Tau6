/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.PolarEncoding
import Hexagon.JunctionPolarity
import Hexagon.JunctionEnergy

/-!
# Polar transport — ternary transport is CONVERSION-FREE and null is the free state

**The principal's insight, formalized.** Polar ternary has exactly 3 states on 2 wires:
`01` (push), `00` (null), `10` (pull). The 4th combination `11` can never happen. So
"transport in ternary" IS "transport a binary word": the trit gates wire straight onto the
binary bus width, with **no translation table, no isqrt, no decode at the transport/storage
layer** — the encoding already *is* binary. And `00` = null = nothing energized = free, so
null-heavy ternary transport beats binary on the wire with zero translation overhead.

**Calibration:** DIRECT — finite combinatorics (`polarEncode` injective + never `11`) and
ℚ algebra (`wordEnergy`/`ternary_wins_iff` from `JunctionEnergy.lean`).

**Reused (NOT re-derived):** `Hexagon.polarEncode_injective` / `polarEncode_never_eleven`
(`PolarEncoding.lean`); `JunctionPolarity.Trit.energy_le_one` /
`energy_eq_zero_iff_null` / `neg_energy` (`JunctionPolarity.lean`); `junctionCost`,
`wordEnergy`, `wordEnergy_eq`, `ternary_wins_iff`, `structural_win_free_null`,
`structural_win_measured_null`, `nullEnergy`, `binaryNatural`, `binaryWordIdeal`
(`JunctionEnergy.lean`). The bits-per-trit `c = log₂ 3` (irrational) is carried as a
*parameter* with rational bounds `19/12 < c < 27/17` (the exact integer facts
`2^19 < 3^12` / `3^17 < 2^27`), exactly as `JunctionEnergy.lean` does.

**Status:** PROVED (2026-08-30) — zero `sorry`; `lake env lean Hexagon/PolarTransport.lean`
green. See the summary comment at the foot of the file.

**Scope caveat (honest).** This module is about TRANSPORT/STORAGE only. The ALU still pays
the one-hot → signed decode at the compute boundary (`polarDecode`); the claim being proved
here is that the *wire* carries the 2-bit code with no conversion overhead and that the null
is free on the wire.
-/

open scoped BigOperators

namespace Hexagon
namespace PolarTransport

/-! ## 1. Conversion-free: a ternary word IS a binary word (no decode on the bus) -/

/-- A ternary transport word of `N` trits (a sequence of balanced `PolarTrit`s). -/
abbrev TernWord (N : ℕ) := Fin N → PolarTrit

/-- A binary transport word of `N` cells, each cell 2 bits — the bus width is `2N`. -/
abbrev BinWord (N : ℕ) := Fin N → Fin 2 × Fin 2

/-- Pointwise polar encoding: the ternary word, wired straight onto the bus. -/
def encodeWord {N : ℕ} (w : TernWord N) : BinWord N := fun i => polarEncode (w i)

/-- The three 2-bit codes, named for readability: null = `00`, push = `01`, pull = `10`. -/
theorem polarEncode_null : polarEncode (1 : PolarTrit) = (0, 0) := by decide
theorem polarEncode_push : polarEncode (2 : PolarTrit) = (0, 1) := by decide
theorem polarEncode_pull : polarEncode (0 : PolarTrit) = (1, 0) := by decide

/-- **CONVERSION-FREE (injectivity).** The polar encoding, lifted pointwise to a whole word,
is injective: two distinct ternary words are carried as two distinct binary words. Transport
loses nothing, so no decode is needed on the bus — the 2-bit code is the wire. -/
theorem encodeWord_injective {N : ℕ} : Function.Injective (encodeWord (N := N)) := by
  intro w v h
  funext i
  exact polarEncode_injective (congr_fun h i)

/-- **CONVERSION-FREE (no `11`).** No cell of a transported ternary word is ever `(1, 1)`:
the 4th combination is unreachable, so the image is a proper subset of the binary words — a
ternary word on the bus is literally a binary word (with a don't-care state it never uses). -/
theorem encodeWord_never_eleven {N : ℕ} (w : TernWord N) (i : Fin N) :
    encodeWord w i ≠ (1, 1) :=
  polarEncode_never_eleven (w i)

/-- The image of the polar encoding is exactly the three non-`11` codes: the transport uses
only `{00, 01, 10}` out of the four 2-bit patterns, with `11` excluded. -/
theorem polarEncode_image (c : Fin 2 × Fin 2) :
    (∃ t : PolarTrit, polarEncode t = c) ↔ c = (0, 0) ∨ c = (0, 1) ∨ c = (1, 0) := by
  constructor
  · rintro ⟨t, ht⟩
    fin_cases t
    · right; right; simpa [polarEncode] using ht.symm
    · left; simpa [polarEncode] using ht.symm
    · right; left; simpa [polarEncode] using ht.symm
  · rintro (rfl | rfl | rfl)
    · exact ⟨1, polarEncode_null⟩
    · exact ⟨2, polarEncode_push⟩
    · exact ⟨0, polarEncode_pull⟩

/-! ## 2. Null is free: word energy = the number of non-null trits -/

/-- A word of `N` one-hot channel-trits (`Option Channel`: `none` = null, `some` = ±1). -/
abbrev JWord (N : ℕ) := Fin N → JunctionPolarity.Trit

/-- Transport energy of a channel-trit word: total energized wires. -/
def wordEnergyJ {N : ℕ} (w : JWord N) : ℕ := ∑ i : Fin N, JunctionPolarity.Trit.energy (w i)

/-- The number of non-null trits in a channel-trit word. -/
def nonNullCount {N : ℕ} (w : JWord N) : ℕ :=
  (Finset.univ.filter (fun i : Fin N => w i ≠ JunctionPolarity.Trit.null)).card

/-- Each trit's energy is its non-null indicator: `0` iff null, `1` otherwise (so `00` = 0
wires, `01`/`10` = exactly one wire). -/
lemma energy_eq_ne_null (t : JunctionPolarity.Trit) :
    JunctionPolarity.Trit.energy t = (if t ≠ JunctionPolarity.Trit.null then (1 : ℕ) else 0) := by
  cases t with
  | none => decide
  | some c => cases c <;> decide

/-- **NULL IS FREE.** A word's transport energy is exactly its number of non-null trits: the
null (`00`) contributes zero energized wires (`energy_eq_zero_iff_null`) while every ±1
contributes exactly one (`energy_le_one`), so the total energized-wire count is the count of
non-null trits. -/
theorem wordEnergyJ_eq_nonNullCount {N : ℕ} (w : JWord N) :
    wordEnergyJ w = nonNullCount w := by
  unfold wordEnergyJ nonNullCount
  rw [Finset.sum_congr rfl (fun i _ => energy_eq_ne_null (w i))]
  exact Finset.sum_boole (fun i => w i ≠ JunctionPolarity.Trit.null) (Finset.univ : Finset (Fin N))

/-- The balanced-trit form (the `JunctionEnergy` `Word` model): with a FREE null (`e = 0`),
a 12-trit word's transport energy is `12 - nullCount` — again exactly the number of non-null
trits. -/
theorem wordEnergy_zero_eq (w : Word) : wordEnergy 0 w = (12 : ℚ) - (nullCount w : ℚ) := by
  rw [wordEnergy_eq]
  ring

/-! ## 3. The win is conversion-free (transport only) -/

/-- **CONVERSION-FREE CONDITIONAL WIN (transport, free null).** A null-heavy 12-trit word
(at least 3 nulls, null fraction ≥ 1/4, above the free-null break-even) transported as its
polar image — a binary 24-bit word by §1, no decode — energizes strictly fewer channels than
the 20-bit binary word carrying the same information (`3^12 < 2^20`). Zero conversion
overhead: the encoding already IS binary. -/
theorem conversion_free_transport_win (w : Word) (hn : 3 ≤ nullCount w) :
    wordEnergy 0 w < binaryWordIdeal 20 :=
  structural_win_free_null w hn

/-- The same, at the MEASURED null cost (`e = 1/24`): ≥ 3 nulls still beats the 20-bit ideal
binary word. -/
theorem conversion_free_transport_win_measured (w : Word) (hn : 3 ≤ nullCount w) :
    wordEnergy (1 / 24) w < binaryWordIdeal 20 :=
  structural_win_measured_null w hn

/-! ## 4. The whole-word transport bound (the `ternary_wins_iff` break-even) -/

/-- `ternaryPerBit` is antitone in the null fraction `p`: more nulls ⇒ less energy per bit
(requires the null to cost no more than a ±1, i.e. `e ≤ 1`). -/
lemma ternaryPerBit_antitone (e c p q : ℚ) (hc : 0 < c) (he : e ≤ 1) (hpq : q ≤ p) :
    ternaryPerBit e c p ≤ ternaryPerBit e c q := by
  unfold ternaryPerBit
  have hn : (1 - p) + p * e ≤ (1 - q) + q * e := by nlinarith [hpq, he]
  exact div_le_div_of_nonneg_right hn (le_of_lt hc)

/-- **The break-even count is `k = 5` (from `ternary_wins_iff`).** At the measured
`b = binaryNatural = 32/75`, `e = nullEnergy = 1/24`, and bits-per-trit `c = log₂ 3`
(bounded by `19/12 < c`), the `ternary_wins_iff` break-even null fraction
`(1 - b·c)/(1 - e) ≈ 0.338` is below `5/12 ≈ 0.417`, so a 12-trit word with 5 nulls
transports strictly cheaper *per bit* than measured binary natural. -/
theorem five_nulls_beat_binary_natural_perbit {c : ℚ} (hclog : 19 / 12 < c) :
    ternaryPerBit nullEnergy c (5 / 12) < binaryNatural := by
  have hc : 0 < c := by linarith
  rw [ternary_wins_iff nullEnergy c binaryNatural (5 / 12) hc (by norm_num [nullEnergy] : nullEnergy < 1)]
  unfold nullEnergy binaryNatural
  have hden : 0 < (1 : ℚ) - 1 / 24 := by norm_num
  rw [gt_iff_lt]
  rw [div_lt_iff₀ hden]
  have hc' : (4325 : ℚ) / 3072 < c := by
    have hbase : (19 : ℚ) / 12 > 4325 / 3072 := by norm_num
    linarith
  nlinarith

/-- **Whole-word form of `k = 5`.** A 12-trit word with at least 5 nulls (null fraction
≥ 5/12, above the `ternary_wins_iff` break-even ≈ 0.338) transports strictly cheaper than
the measured binary-natural word carrying the same `12·c` bits (`c = log₂ 3`, `19/12 < c`).
Transport-only: the ALU decode is not part of this saving. -/
theorem five_nulls_word_win {c : ℚ} (hclog : 19 / 12 < c) (w : Word) (hn : 5 ≤ nullCount w) :
    wordEnergy nullEnergy w < binaryNatural * (12 * c) := by
  rw [wordEnergy_eq]
  unfold nullEnergy binaryNatural
  have hc' : (4325 : ℚ) / 3072 < c := by
    have hbase : (19 : ℚ) / 12 > 4325 / 3072 := by norm_num
    linarith
  have hnq : (5 : ℚ) ≤ (nullCount w : ℚ) := by exact_mod_cast hn
  have hword : 12 - (nullCount w : ℚ) * (23 / 24) ≤ (173 : ℚ) / 24 := by
    nlinarith [hnq]
  have hright : (173 : ℚ) / 24 < (32 : ℚ) / 75 * (12 * c) := by
    rw [show (32 : ℚ) / 75 * (12 * c) = (128 : ℚ) / 25 * c by ring]
    nlinarith [hc']
  rw [show (1 : ℚ) - 1 / 24 = 23 / 24 by norm_num]
  nlinarith

/-! ## 5. Same-wire-count comparison (the "2 bits per trit" 24-wire bus) -/

/-- **Never worse on equal wires.** A 12-trit word occupies 24 wires (2 bits/trit); an ideal
24-bit binary word energizes `24/2 = 12` wires on average. With a FREE null, the ternary word
energizes `12 - nullCount ≤ 12` wires — never more, and strictly fewer the moment any trit is
null. -/
theorem ternary_no_worse_same_wires (w : Word) : wordEnergy 0 w ≤ binaryWordIdeal 24 := by
  unfold binaryWordIdeal
  rw [wordEnergy_eq]
  norm_num

/-- Any null trit already makes ternary strictly cheaper than the ideal 24-bit binary word on
the same 24 wires. -/
theorem beats_binary_same_wires (w : Word) (hn : 0 < nullCount w) :
    wordEnergy 0 w < binaryWordIdeal 24 := by
  unfold binaryWordIdeal
  rw [wordEnergy_eq]
  norm_num
  exact hn

/-- At the MEASURED null cost (`e = 1/24`) vs the MEASURED binary natural word on the same
24 wires, just 2 nulls suffice. -/
theorem two_nulls_beat_24bit_binary_word (w : Word) (hn : 2 ≤ nullCount w) :
    wordEnergy nullEnergy w < binaryNatural * 24 := by
  rw [wordEnergy_eq]
  unfold nullEnergy binaryNatural
  have hnq : (2 : ℚ) ≤ (nullCount w : ℚ) := by exact_mod_cast hn
  rw [show (1 : ℚ) - 1 / 24 = 23 / 24 by norm_num]
  rw [show (32 : ℚ) / 75 * 24 = 256 / 25 by norm_num]
  nlinarith [hnq]

end PolarTransport
end Hexagon

/-!
## Summary of what this module establishes

1. **Conversion-free.** `polarEncode_null/push/pull` (the three codes `00/01/10`),
   `encodeWord_injective` (a ternary word IS a binary word — injective, no decode on the bus),
   `encodeWord_never_eleven` + `polarEncode_image` (the image is exactly `{00, 01, 10}`,
   `11` excluded). Uses `polarEncode_injective` + `polarEncode_never_eleven`.
2. **Null is free.** `energy_eq_ne_null` + `wordEnergyJ_eq_nonNullCount` (transport energy =
   number of non-null trits), `wordEnergy_zero_eq` (the balanced-trit `12 - nullCount` form).
   Uses `energy_eq_zero_iff_null` / `energy_le_one` / `energy_null` (cited) and `wordEnergy_eq`.
3. **The win is conversion-free.** `conversion_free_transport_win` /
   `conversion_free_transport_win_measured` (≥ 3 nulls beats the 20-bit binary word carrying
   the same information), with zero conversion overhead because of (1).
4. **Whole-word bound.** `ternaryPerBit_antitone`, `five_nulls_beat_binary_natural_perbit`
   (the `ternary_wins_iff` break-even ⇒ `k = 5` per bit), `five_nulls_word_win` (≥ 5 nulls
   beats measured binary natural at the same information), and the same-wire-count
   `ternary_no_worse_same_wires` / `beats_binary_same_wires` /
   `two_nulls_beat_24bit_binary_word` (24-wire bus).

**One-line significance:** the ternary transport wire carries the 2-bit polar code with no
translation (it already IS binary), excludes `11` everywhere, and its null state costs zero —
so null-heavy ternary transport is cheaper than binary *and* conversion-free, with the ALU
decode confined to the compute boundary, never the wire.
-/
