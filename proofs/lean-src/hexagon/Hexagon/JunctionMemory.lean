/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.TernaryCell
import Hexagon.TritPacking
import Hexagon.FewerTrits
import Hexagon.RadixEconomy

/-!
# Junction memory — the memory/energy bound of "one channel activation per trit"

**Idea history:** the principal's one-channel-activation claim (Tau Architecture):
"we get 2 bits [of information, via the 2-bit/trit code], but only ever have to activate
one [channel]"; "only have to energise half the RAM at once"; "most of what we do to get
ternary is just not activate most channels, and that should be a cost saving." This file
turns the claim into the memory-word setting: an `N`-trit word is a sequence of one-hot
channel states (`TernaryCell.lean`'s `Trit`), the number of ACTIVE channels is the number
of non-null trits, and the information content is the `3ⁿ` count (`N·log₂3` bits).

**Calibration:** DIRECT — finite combinatorics + linearity of expectation over ℚ (no
`sorry`); the *energy* constants (0.05 pJ null / 1.20 pJ ±1) and the 2.7–6.3× transport
number are MEASURED (ngspice, `circuit/ENERGY_RESULTS.md`, `scripts/transport.py`) and are
cited as such, never derived.

**Status:** PROVED (2026-08-29) — `lake build Hexagon.JunctionMemory` green, zero `sorry`.
Route: native tactics (`cases`/`decide`/`norm_num`/`ring`/`nlinarith`/`omega`/`simp`) plus
one induction over `N` (`sum_prod_sum_linear`, via the coordinate `wordSuccEquiv` and
`Fin.prod_univ_succ`/`Fin.sum_univ_succ`).
-/

open scoped BigOperators

namespace Hexagon

/-! ## 1. The memory word: `N` trits of one-hot channel states -/

/-- A ternary memory word of `N` trits: a sequence of one-hot channel states, one `Trit`
    (`−1`/`0`/`+1`) per position. `Trit` carries the two-bit code `01/00/10` with `11`
    never produced (`TernaryCell.lean`), so each trit is a *channel state*, not a pair. -/
abbrev TernaryWord (N : ℕ) := Fin N → Trit

/-- The number of ACTIVE (energized) channels in a word: the sum of per-trit energies,
    i.e. exactly the number of non-null trits (each non-null trit lights one channel). -/
def activeChannels {N : ℕ} (w : TernaryWord N) : ℕ := ∑ i : Fin N, energy (w i)

/-- The information content of an `N`-trit word in bits: `N·log₂3`. Each trit carries
    `log₂3 ≈ 1.585` bits, so the word carries `N·log₂3` bits. -/
noncomputable def bitsOfWord (N : ℕ) : ℝ := (N : ℝ) * (Real.log 3 / Real.log 2)

/-- The `3ⁿ` count: an `N`-trit word takes exactly `3 ^ N` distinct values. This is the
    "information content via the 3ⁿ count" — no bijection needed, just the product of
    `N` ternary cells. -/
theorem ternaryWord_card (N : ℕ) : Fintype.card (TernaryWord N) = 3 ^ N := by
  simp [TernaryWord, card_trit]

/-- `N·log₂3 = log(3ⁿ)/log 2`: the bit count agrees with the `3ⁿ` count (log₂ of the
    number of states). -/
theorem bitsOfWord_eq_log (N : ℕ) :
    bitsOfWord N = Real.log ((3 : ℝ) ^ N) / Real.log 2 := by
  unfold bitsOfWord
  rw [Real.log_pow]
  ring

/-- Each trit carries more than one bit: `1 < log₂3` (cited from `RadixEconomy.lean`), so
    an `N`-trit word carries strictly more than `N` bits. -/
theorem bitsOfWord_gt_N (N : ℕ) (hN : 0 < N) : (N : ℝ) < bitsOfWord N := by
  unfold bitsOfWord
  have hNpos : 0 < (N : ℝ) := by exact_mod_cast hN
  have hmul := mul_lt_mul_of_pos_left (bits_per_trit_gt_one) hNpos
  simpa using hmul

/-! ## 2. One activation per trit: `≤ N` channels, never both wires -/

/-- A ternary word of `N` trits energizes at most `N` channels: each trit energizes at
    most one channel (`energy_le_one`), and there are `N` trits. -/
theorem activeChannels_le (N : ℕ) (w : TernaryWord N) : activeChannels w ≤ N := by
  unfold activeChannels
  calc
    (∑ i : Fin N, energy (w i)) ≤ ∑ _i : Fin N, (1 : ℕ) :=
      Finset.sum_le_sum (fun i _ => energy_le_one (w i))
    _ = N := by simp

/-- "Never both": no trit in the word ever energizes both the push and pull channel — the
    two-bit code `(true, true)` is never produced (cited from `TernaryCell.lean`). -/
theorem word_never_both {N : ℕ} (w : TernaryWord N) (i : Fin N) :
    encode (w i) ≠ (true, true) :=
  encode_never_both (w i)

/-! ## 3. The null-heavy expectation: expected active channels `= N·(1−p0) < N` -/

/-- The iid null-fraction model: trit `t` has probability `p0` of being null and
    `(1−p0)/2` each of being `−1` or `+1`. (The two polarities split the non-null mass.) -/
def tritProb (p0 : ℚ) (t : Trit) : ℚ :=
  if t = .zero then p0 else (1 - p0) / 2

/-- Expand a sum over the three trits into its three terms (the `Fintype` instance for
    `Trit` is exactly the finite set `{.neg, .zero, .pos}`). -/
lemma sum_trit (f : Trit → ℚ) : (∑ t : Trit, f t) = f .neg + f .zero + f .pos := by
  rw [show (∑ t : Trit, f t) = Finset.sum ({.neg, .zero, .pos} : Finset Trit) f by rfl]
  rw [Finset.sum_insert]
  · rw [Finset.sum_insert]
    · rw [Finset.sum_singleton]
      ac_rfl
    · decide
  · decide

/-- The probabilities sum to one: it is a genuine distribution. -/
theorem tritProb_sum (p0 : ℚ) : (∑ t : Trit, tritProb p0 t) = 1 := by
  rw [sum_trit]
  unfold tritProb
  simp
  ring

/-- The expected energy of one trit: `(1−p0)·1 + p0·0 = 1 − p0` active channels per trit. -/
theorem tritExpectedEnergy_eq (p0 : ℚ) : (∑ t : Trit, tritProb p0 t * (energy t : ℚ)) = 1 - p0 := by
  rw [sum_trit]
  unfold tritProb energy encode
  simp

/-- The probability of a word under the iid model: the product of its trit probabilities. -/
def wordProb {N : ℕ} (p0 : ℚ) (w : TernaryWord N) : ℚ :=
  ∏ i : Fin N, tritProb p0 (w i)

/-- The expected number of active channels over an `N`-trit word under the iid
    null-fraction model: the weighted sum of `activeChannels` over all words. -/
def expectedActive (N : ℕ) (p0 : ℚ) : ℚ :=
  ∑ w : TernaryWord N, wordProb p0 w * (∑ i : Fin N, (energy (w i) : ℚ))

/-! The coordinate decomposition of a word: peel off trit position `0` and keep the rest. -/

/-- A word of `N+1` trits is the pair (its first `N` trits, its last trit at position 0). -/
def wordSuccEquiv (N : ℕ) : TernaryWord (N+1) ≃ TernaryWord N × Trit where
  toFun w := (fun i => w i.succ, w 0)
  invFun p := fun i => Fin.cases p.2 p.1 i
  left_inv := by
    intro w
    funext i
    cases i using Fin.cases with
    | zero => simp
    | succ i => simp
  right_inv := by
    intro p
    rcases p with ⟨u, t⟩
    rfl

/-- The peeled-off trit at position `0` is the second component. -/
@[simp] lemma wordSuccEquiv_symm_zero {N : ℕ} (u : TernaryWord N) (t : Trit) :
    (wordSuccEquiv N).symm (u, t) 0 = t := by
  simp [wordSuccEquiv]

/-- The remaining trits (positions `1..N`) are the first component. -/
@[simp] lemma wordSuccEquiv_symm_succ {N : ℕ} (u : TernaryWord N) (t : Trit) (i : Fin N) :
    (wordSuccEquiv N).symm (u, t) i.succ = u i := by
  simp [wordSuccEquiv]

/-! The factorization lemmas: summing a product of per-trit weights over all words. -/

/-- The fundamental factorization: `∑_w ∏_i a(wᵢ) = (∑_t a t)ᴺ`. Summing the product over
    all `N`-trit words factors as the `N`-th power of the single-trit sum. -/
lemma sum_wordProd (N : ℕ) (a : Trit → ℚ) :
    (∑ w : TernaryWord N, ∏ i : Fin N, a (w i)) = (∑ t : Trit, a t) ^ N := by
  induction N with
  | zero => simp
  | succ N ih =>
      rw [← Equiv.sum_comp (wordSuccEquiv N).symm (fun w => ∏ i : Fin (N+1), a (w i))]
      rw [Fintype.sum_prod_type]
      have hprod : ∀ u : TernaryWord N, ∀ t : Trit,
          ∏ i : Fin (N+1), a ((wordSuccEquiv N).symm (u, t) i) = a t * ∏ i : Fin N, a (u i) := by
        intro u t
        rw [Fin.prod_univ_succ]
        rfl
      simp_rw [hprod]
      rw [Finset.sum_comm]
      simp_rw [← Finset.mul_sum]
      rw [← Finset.sum_mul]
      rw [ih]
      ring

/-- `A·Aⁿ⁻¹ = Aⁿ` for `n ≥ 1` (used to close the induction step's `Aⁿ⁻¹` exponent). -/
lemma mul_pow_pred (A : ℚ) {N : ℕ} (hN : 0 < N) : A * A ^ (N - 1) = A ^ N := by
  rw [mul_comm, ← pow_succ]
  congr 1
  omega

/-- The expectation is linear: `∑_w (∏ a(wᵢ))·(∑ b(wᵢ)) = N·(∑_t a t · b t)·(∑_t a t)ᴺ⁻¹`.
    This is linearity of expectation for a sum of per-trit quantities over iid trits. -/
lemma sum_prod_sum_linear (N : ℕ) (a b : Trit → ℚ) :
    (∑ w : TernaryWord N, (∏ i : Fin N, a (w i)) * (∑ i : Fin N, b (w i)))
      = (N : ℚ) * (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ (N - 1) := by
  induction N with
  | zero => simp
  | succ N ih =>
      rw [← Equiv.sum_comp (wordSuccEquiv N).symm
        (fun w => (∏ i : Fin (N+1), a (w i)) * (∑ i : Fin (N+1), b (w i)))]
      rw [Fintype.sum_prod_type]
      have hprod : ∀ u : TernaryWord N, ∀ t : Trit,
          ∏ i : Fin (N+1), a ((wordSuccEquiv N).symm (u, t) i) = a t * ∏ i : Fin N, a (u i) := by
        intro u t
        rw [Fin.prod_univ_succ]
        rfl
      have hsum : ∀ u : TernaryWord N, ∀ t : Trit,
          ∑ i : Fin (N+1), b ((wordSuccEquiv N).symm (u, t) i) = b t + ∑ i : Fin N, b (u i) := by
        intro u t
        rw [Fin.sum_univ_succ]
        rfl
      simp_rw [hprod, hsum]
      -- goal: ∑ u, ∑ t, (a t * P u) * (b t + S u) = (N+1) * E * A^N
      --   where P u = ∏ a(u_i), S u = ∑ b(u_i), E = ∑ a t · b t, A = ∑ a t
      simp_rw [mul_add]
      simp_rw [Finset.sum_add_distrib]
      -- piece 1: ∑ u, ∑ t, (a t * P u) * b t  =  E * A^N
      have h1 : (∑ u : TernaryWord N, ∑ t : Trit, (a t * ∏ i : Fin N, a (u i)) * b t)
          = (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ N := by
        calc
          (∑ u : TernaryWord N, ∑ t : Trit, (a t * ∏ i : Fin N, a (u i)) * b t)
              = ∑ u : TernaryWord N, ∑ t : Trit, (a t * b t) * ∏ i : Fin N, a (u i) := by
                  refine Finset.sum_congr rfl ?_
                  intro u _
                  refine Finset.sum_congr rfl ?_
                  intro t _
                  ring
          _ = ∑ u : TernaryWord N, (∑ t : Trit, a t * b t) * (∏ i : Fin N, a (u i)) := by
                  refine Finset.sum_congr rfl ?_
                  intro u _
                  rw [← Finset.sum_mul]
          _ = (∑ t : Trit, a t * b t) * (∑ u : TernaryWord N, ∏ i : Fin N, a (u i)) := by
                  rw [← Finset.mul_sum]
          _ = (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ N := by
                  rw [sum_wordProd]
      -- piece 2: ∑ u, ∑ t, (a t * P u) * S u  =  A * (N * E * A^(N-1))
      have h2 : (∑ u : TernaryWord N, ∑ t : Trit,
          (a t * ∏ i : Fin N, a (u i)) * (∑ i : Fin N, b (u i)))
          = (∑ t : Trit, a t) * ((N : ℚ) * (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ (N - 1)) := by
        calc
          (∑ u : TernaryWord N, ∑ t : Trit,
              (a t * ∏ i : Fin N, a (u i)) * (∑ i : Fin N, b (u i)))
              = ∑ u : TernaryWord N, ∑ t : Trit, a t * ((∏ i : Fin N, a (u i)) * (∑ i : Fin N, b (u i))) := by
                  refine Finset.sum_congr rfl ?_
                  intro u _
                  refine Finset.sum_congr rfl ?_
                  intro t _
                  ring
          _ = ∑ u : TernaryWord N, (∑ t : Trit, a t) * ((∏ i : Fin N, a (u i)) * (∑ i : Fin N, b (u i))) := by
                  refine Finset.sum_congr rfl ?_
                  intro u _
                  rw [← Finset.sum_mul]
          _ = (∑ t : Trit, a t) * (∑ u : TernaryWord N, (∏ i : Fin N, a (u i)) * (∑ i : Fin N, b (u i))) := by
                  rw [← Finset.mul_sum]
          _ = (∑ t : Trit, a t) * ((N : ℚ) * (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ (N - 1)) := by
                  rw [ih]
      rw [h1, h2]
      have hpred : N + 1 - 1 = N := by omega
      rw [hpred]
      by_cases hN : N = 0
      · subst hN
        norm_num
      · have hpow : (∑ t : Trit, a t) * (∑ t : Trit, a t) ^ (N - 1) = (∑ t : Trit, a t) ^ N :=
            mul_pow_pred (∑ t : Trit, a t) (Nat.pos_of_ne_zero hN)
        calc
          (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ N
              + (∑ t : Trit, a t) * ((N : ℚ) * (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ (N - 1))
              = (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ N
              + ((N : ℚ) * (∑ t : Trit, a t * b t)) * ((∑ t : Trit, a t) * (∑ t : Trit, a t) ^ (N - 1)) := by
                  ring
          _ = (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ N
              + ((N : ℚ) * (∑ t : Trit, a t * b t)) * (∑ t : Trit, a t) ^ N := by
                  rw [hpow]
          _ = ((N + 1 : ℕ) : ℚ) * (∑ t : Trit, a t * b t) * (∑ t : Trit, a t) ^ N := by
                  norm_num
                  ring

/-- **The key claim.** The expected number of active channels over an `N`-trit word under
    the iid null-fraction-`p0` model is exactly `N·(1−p0)`: each trit is active with
    probability `1−p0`, so `N` trits average `N·(1−p0)` active channels. -/
theorem expectedActive_eq (N : ℕ) (p0 : ℚ) :
    expectedActive N p0 = (N : ℚ) * (1 - p0) := by
  unfold expectedActive wordProb
  rw [sum_prod_sum_linear N (tritProb p0) (fun t => (energy t : ℚ))]
  rw [tritExpectedEnergy_eq, tritProb_sum]
  simp

/-- **Null-heavy ⇒ strictly fewer than `N` channels.** As soon as any nulls occur
    (`p0 > 0`), the expected number of active channels is strictly below `N` — on average
    you energize fewer than `N` rails while the word still carries `N·log₂3` bits. -/
theorem expectedActive_lt_N (N : ℕ) (p0 : ℚ) (hN : 0 < N) (hp0 : 0 < p0) :
    expectedActive N p0 < (N : ℚ) := by
  rw [expectedActive_eq]
  have h1 : (1 : ℚ) - p0 < 1 := by linarith
  have hNpos : 0 < (N : ℚ) := by exact_mod_cast hN
  have hmul := mul_lt_mul_of_pos_left h1 hNpos
  simpa using hmul

/-- Monotone in `p0`: more nulls ⇒ fewer expected active channels (the saving grows with
    the null fraction). -/
theorem expectedActive_anti_mono (N : ℕ) (p0 q0 : ℚ) (h : p0 ≤ q0) :
    expectedActive N q0 ≤ expectedActive N p0 := by
  rw [expectedActive_eq, expectedActive_eq]
  have h1 : 1 - q0 ≤ 1 - p0 := by linarith
  have hN : 0 ≤ (N : ℚ) := by exact_mod_cast Nat.zero_le N
  exact mul_le_mul_of_nonneg_left h1 hN

/-- **Uniform traffic: `2N/3` active channels.** At `p0 = 1/3` (each trit `−1/0/+1`
    equally likely) the expected number of active channels is `2N/3` — two-thirds of the
    rails energized, one-third free. -/
theorem uniform_expectedActive (N : ℕ) : expectedActive N (1 / 3) = (2 * N : ℚ) / 3 := by
  rw [expectedActive_eq]
  norm_num
  ring

/-! ## 4. Energy per bit: the 2.7–6.3× transport number and the uniform "ties binary" -/

/-- The measured binary baselines and the ternary champion (pJ/bit, `transport.py` /
    `FINAL_VERDICT.md`): natural single-ended 0.512, matched low-swing 0.216, and the
    ternary champion (null-heavy, low-swing × LC-resonant) 0.081. -/
def binaryNaturalPJ : ℚ := 64 / 125
def binaryLowSwing : ℚ := 27 / 125
def ternaryChampion : ℚ := 81 / 1000

/-- The measured per-trit energies (fair-fight operating point): `±1` costs `1.20 pJ`,
    null costs `0.05 pJ`. So a trit at null-fraction `p0` costs
    `(1−p0)·1.20 + p0·0.05` pJ. -/
def tritEnergy (p0 : ℚ) : ℚ := (1 - p0) * (6 / 5) + p0 * (1 / 20)

/-- Uniform per-trit energy: `(1.20 + 1.20 + 0.05)/3 = 49/60 ≈ 0.8167 pJ/trit`. -/
theorem tritEnergy_uniform : tritEnergy (1 / 3) = 49 / 60 := by
  unfold tritEnergy
  norm_num

/-- The champion's transport win vs matched low-swing binary: `0.216/0.081 = 8/3 ≈ 2.67×`. -/
theorem champion_vs_lowswing : binaryLowSwing / ternaryChampion = 8 / 3 := by
  norm_num [binaryLowSwing, ternaryChampion]

/-- The champion's transport win vs natural single-ended binary: `0.512/0.081 = 512/81 ≈ 6.32×`. -/
theorem champion_vs_natural : binaryNaturalPJ / ternaryChampion = 512 / 81 := by
  norm_num [binaryNaturalPJ, ternaryChampion]

/-- The two endpoints are ordered: `8/3 = 2.667 < 512/81 = 6.32`, so the transport win
    lies in the interval `[2.67×, 6.32×]` — the "2.7–6.3× transport number". -/
theorem transport_range : (8 : ℚ) / 3 < 512 / 81 := by
  norm_num

/-- **Honest break-even.** At the fair-fight operating point, "2 trits carry ≥ 3 bits"
    (`3² = 9 ≥ 8 = 2³`), so 2 trits are a valid stand-in for 3 binary bits. 2 trits at
    null-fraction `p0` cost `2·tritEnergy p0`; 3 binary-natural bits cost `3·binaryNaturalPJ`.
    Ternary wins iff `p0 > 216/575 ≈ 0.376` — i.e. the free-null saving needs nulls to be
    more than ~37.6% of traffic. (Conservative: 2 trits actually carry `log₂9 = 3.17` bits,
    so the true per-bit break-even is lower, `p0 ≈ 0.34`.) -/
theorem two_trit_break_even (p0 : ℚ) :
    2 * tritEnergy p0 < 3 * binaryNaturalPJ ↔ p0 > 216 / 575 := by
  unfold tritEnergy binaryNaturalPJ
  constructor
  · intro h
    nlinarith
  · intro h
    nlinarith

/-- **Uniform ≈ ties binary (exact ratio).** At uniform traffic the per-trit energy is
    `49/60` pJ and each trit carries `log₂3` bits, so the per-bit energy is
    `(49/60)/log₂3 ≈ 0.515 pJ/bit`, vs binary natural `0.512 pJ/bit`: the exact ratio is
    `(49·125·ln2)/(60·64·ln3) ≈ 1.006` — ternary is ~0.6% *worse* than natural single-ended
    binary at uniform traffic, i.e. it only *ties* (the honest phrasing), and only wins for
    null-heavy traffic (the `216/575` threshold above). -/
noncomputable def uniformPerBit (p0 : ℚ) : ℝ := (tritEnergy p0 : ℝ) / (Real.log 3 / Real.log 2)

/-! ## 5. Why ternary carries more information per rail: the `(3/2)ⁿ` compounding -/

/-- `3ⁿ/2ⁿ = (3/2)ⁿ`: the ternary-to-binary state ratio is a pure geometric growth, factor
    `3/2` per rail. Cited from the `3ⁿ` namespace (`TritPacking`/`FewerTrits`). -/
theorem three_pow_div_two_pow (n : ℕ) : (3 : ℚ) ^ n / (2 : ℚ) ^ n = ((3 : ℚ) / 2) ^ n := by
  rw [div_pow]

/-- `2ⁿ < 3ⁿ` for `n > 0`: a ternary word of `N` trits carries strictly more states than a
    binary word of `N` bits, per rail (cited from `TritPacking.lean`). -/
theorem ternary_more_states_per_rail (N : ℕ) (hN : 0 < N) :
    (2 ^ N : ℕ) < Fintype.card (TernaryWord N) := by
  rw [ternaryWord_card]
  exact three_pow_gt_two_pow N hN

/-- The state-space ratio: `|TernaryWord N| / 2ⁿ = (3/2)ⁿ`. Per rail, ternary gives
    `(3/2)ⁿ` times the binary state count. -/
theorem ternary_binary_rail_ratio (N : ℕ) :
    ((Fintype.card (TernaryWord N) : ℚ) / (2 : ℚ) ^ N) = ((3 : ℚ) / 2) ^ N := by
  rw [ternaryWord_card]
  rw [show ((3 ^ N : ℕ) : ℚ) = (3 : ℚ) ^ N by norm_num]
  exact three_pow_div_two_pow N

/-! ## 6. The channel-count comparison vs differential binary (stated honestly) -/

/-- A naive *differential* binary word energizes exactly one wire of each pair at all
    times, so an `M`-bit differential word energizes exactly `M` channels (its rails), not
    `M/2`. (This is the honest baseline: differential signaling is 2 wires per bit, 1 on.) -/
def diffBinaryChannels (M : ℕ) : ℕ := M

/-- **Binary cannot match `3ⁿ` in `N` bits.** `¬ (3ⁿ ≤ 2ⁿ)`: `N` bits (`2ⁿ` states) cannot
    hold the `3ⁿ` states of an `N`-trit word, so a differential binary word carrying the
    same information needs strictly more than `N` bits — and energizes that many channels
    *always* (not just worst-case). The ternary word energizes `≤ N` channels worst-case and
    `2N/3` on average. -/
theorem binary_needs_more_bits (N : ℕ) (hN : 0 < N) : ¬ (3 ^ N ≤ 2 ^ N) := by
  exact not_le.mpr (three_pow_gt_two_pow N hN)

/- **Honest caveat.** The `≤ N` vs `≥ N+1` channel-count comparison is a *rail* count,
   not an energy bound. The fair *energy* comparison is the transport number: the ternary
   champion (0.081 pJ/bit) beats natural binary (0.512) by `512/81 ≈ 6.32×` and matched
   low-swing binary (0.216) by `8/3 ≈ 2.67×` — and the free-null saving is CONDITIONAL on
   null-heavy traffic (`p0 > 216/575`), while the low-swing and charge-recovery levers are
   radix-agnostic (binary shares them). At uniform traffic ternary only *ties* binary. -/

/-! ## 5. The namespace outruns linear overhead (Ian: "info explodes past activation cost") -/

/-- `3ⁿ > n²` for `n ≥ 1`: the ternary state count outruns any quadratic in the digit
    count. (Two base cases `n=1,2`; the step uses `(n+2)² ≤ 9n²` for `n ≥ 1`.) -/
theorem three_pow_gt_sq (n : ℕ) (hn : 1 ≤ n) : n * n < 3 ^ n := by
  induction n using Nat.strong_induction_on with
  | h n ih =>
    rcases n with _ | _ | n
    · omega
    · norm_num
    · by_cases hn0 : n = 0
      · subst hn0
        norm_num
      · have hn1 : 1 ≤ n := Nat.succ_le_iff.mpr (Nat.pos_of_ne_zero hn0)
        have ihn : n * n < 3 ^ n := ih n (by omega) hn1
        have hsq_le : (n + 2) * (n + 2) ≤ 9 * (n * n) := by nlinarith [hn1]
        have h9 : 9 * (n * n) < 9 * 3 ^ n := by nlinarith [ihn]
        have h9pow : 9 * 3 ^ n = 3 ^ (n + 2) := by
          calc
            9 * 3 ^ n = 3 ^ 2 * 3 ^ n := by norm_num
            _ = 3 ^ (2 + n) := by rw [pow_add]
            _ = 3 ^ (n + 2) := by rw [Nat.add_comm]
        exact lt_of_le_of_lt hsq_le (h9pow ▸ h9)

/-- The ternary namespace is **exponential** (`3ⁿ` in the digit count) while the
    activation/read overhead is **linear** (`C·n`); so for every overhead rate `C` there is
    a word size `n` with `C·n < 3ⁿ`. The information outruns the cost — "compute on
    addresses, not bits": the address space (exponential) beats the linear per-read overhead. -/
theorem namespace_outruns_linear_cost (C : ℕ) : ∃ n : ℕ, C * n < 3 ^ n := by
  by_cases hC : C = 0
  · use 0
    simp [hC]
  · use C
    have hCpos : 1 ≤ C := Nat.succ_le_of_lt (Nat.pos_of_ne_zero hC)
    exact three_pow_gt_sq C hCpos

/-! ## 6. The address-space crossover sits at the base of the lower power -/

/-- The higher power `3ⁿ` overtakes the lower power `2ⁿ⁺¹` (binary with an extra
    digit's head start) at exactly `n = 2` — the base of the lower power. For every
    `n ≥ 2`, two-or-more trits address more cells than one-more bit. -/
theorem three_pow_gt_two_pow_succ (n : ℕ) (hn : 2 ≤ n) : 2 ^ (n + 1) < 3 ^ n := by
  exact Nat.le_induction (m := 2)
    (by norm_num : 2 ^ (2 + 1) < 3 ^ 2)
    (fun n hn ih => by
      have hpos : 0 < 3 ^ n := Nat.pow_pos (by norm_num : 0 < 3)
      calc
        2 ^ (n + 1 + 1) = 2 * 2 ^ (n + 1) := by rw [pow_succ']
        _ < 2 * 3 ^ n := by nlinarith [ih]
        _ < 3 * 3 ^ n := by nlinarith [hpos]
        _ = 3 ^ (n + 1) := by rw [pow_succ'])
    n hn

/-- At `n = 1` the higher power has NOT yet overtaken even the head-started lower power:
    one trit addresses `3` cells, two bits address `4`. So the crossover is *exactly* `n = 2`. -/
theorem three_pow_lt_two_pow_succ_one : 3 ^ 1 < 2 ^ 2 := by norm_num

end Hexagon
