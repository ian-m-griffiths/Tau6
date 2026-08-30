/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Rotation

/-!
# T4 — the honeycomb graph distance equals the cube-coordinate max-norm

**Idea history:** plan §3; SYNTHESIS Q1 (the hex↔u32 address claim stays SPECULATION
until a provable address translation exists — T4 is its metric).

**Calibration:** DIRECT — real math, integer-native.

**Approach (both directions):**

- *Upper bound* (`dist ≤ hexDist`): build the walk explicitly. On balanced cells the
  greedy step `step x b` moves one unit *toward* `b` in a coordinate where `x` is
  beyond `b` and one unit *toward* `b` in a coordinate where `x` is short; balance is
  preserved, the step is an adjacency, and `hexDist` drops by exactly `1` each step.
  So `walkOfLength` produces a walk of length exactly `(hexDist a b).toNat`, and
  `SimpleGraph.dist_le` gives the upper bound.
- *Lower bound* (`hexDist ≤ dist`): every adjacency changes `hexDist` by at most `1`
  (triangle inequality + `hexDist = 1` on edges), so every walk of length `n` satisfies
  `hexDist a b ≤ n` (`hexDist_le_walk_length`); taking the shortest walk
  (`Reachable.exists_walk_length_eq_dist`) gives the lower bound.

**Status:** PROVED (2026-08-28) — `honeycomb_dist_eq_hexDist` closed by native tactics
(omega / ring / simp / exact; no sorry). `lake build` green.
-/

namespace Hexagon

/-- The honeycomb graph on all cells: two cells are adjacent iff both are balanced and
    at cube-coordinate max-norm distance `1` (i.e. `isNeighbor`). -/
def honeycomb : SimpleGraph (ℤ × ℤ × ℤ) where
  Adj a b := balanced a ∧ balanced b ∧ hexDist a b = 1
  symm := ⟨fun a b h => by
    rcases h with ⟨ha, hb, hd⟩
    exact ⟨hb, ha, (hexDist_comm a b).symm.trans hd⟩⟩
  loopless := ⟨fun a h => by
    rcases h with ⟨_, _, hd⟩
    simp [hexDist_self] at hd⟩

/-- Max-norm distance is zero iff the cells coincide. -/
lemma hexDist_eq_zero_iff (x b : ℤ × ℤ × ℤ) : hexDist x b = 0 ↔ x = b := by
  constructor
  · intro h
    ext
    · have h1 : |x.1 - b.1| ≤ 0 := by simpa [h] using abs_fst_sub_le_hexDist x b
      exact sub_eq_zero.mp (abs_eq_zero.mp (le_antisymm h1 (abs_nonneg _)))
    · have h2 : |x.2.1 - b.2.1| ≤ 0 := by simpa [h] using abs_mid_sub_le_hexDist x b
      exact sub_eq_zero.mp (abs_eq_zero.mp (le_antisymm h2 (abs_nonneg _)))
    · have h3 : |x.2.2 - b.2.2| ≤ 0 := by simpa [h] using abs_snd_sub_le_hexDist x b
      exact sub_eq_zero.mp (abs_eq_zero.mp (le_antisymm h3 (abs_nonneg _)))
  · intro hx
    subst x
    exact hexDist_self b

/-- Distinct cells differ in at least one coordinate. -/
lemma exists_gap_ne_zero_of_ne {x b : ℤ × ℤ × ℤ} (hne : x ≠ b) :
    x.1 - b.1 ≠ 0 ∨ x.2.1 - b.2.1 ≠ 0 ∨ x.2.2 - b.2.2 ≠ 0 := by
  by_contra! h
  apply hne
  ext <;> omega

/-- If one coordinate gap is positive and another negative (sum zero), then moving the
    positive gap down by 1 and the negative gap up by 1 lowers the max-norm by exactly 1.
    (The unchanged coordinate is bounded by `max p |q| - 1`, so it never attains the max.) -/
private lemma max3_shift (p q r : ℤ) (hp : 0 < p) (hq : q < 0) (hsum : p + q + r = 0) :
    max (|p - 1|) (max (|q + 1|) (|r|)) = max (|p|) (max (|q|) (|r|)) - 1 := by
  by_cases hpq : 0 ≤ p + q
  · have hr : |r| = p + q := by
      have hr' : r = -(p + q) := by omega
      rw [hr', abs_neg, abs_of_nonneg hpq]
    rw [abs_of_nonneg (by omega : 0 ≤ p - 1), abs_of_nonpos (by omega : q + 1 ≤ 0),
        abs_of_pos hp, abs_of_neg hq, hr]
    omega
  · have hpq' : p + q < 0 := lt_of_not_ge hpq
    have hr : |r| = -(p + q) := by
      have hr' : r = -(p + q) := by omega
      rw [hr', abs_neg, abs_of_neg hpq']
    rw [abs_of_nonneg (by omega : 0 ≤ p - 1), abs_of_nonpos (by omega : q + 1 ≤ 0),
        abs_of_pos hp, abs_of_neg hq, hr]
    omega

/-- The greedy step toward `b` from a balanced `x ≠ b`: pick a coordinate where `x`
    is beyond `b` (move it one unit down) and one where `x` is short (move it one unit
    up). The branch structure covers all six sign patterns of the gap triple. -/
def step (x b : ℤ × ℤ × ℤ) : ℤ × ℤ × ℤ :=
  if _h1 : x.1 > b.1 then
    if _h2 : x.2.1 < b.2.1 then ⟨x.1 - 1, x.2.1 + 1, x.2.2⟩
    else ⟨x.1 - 1, x.2.1, x.2.2 + 1⟩
  else if _h2 : x.2.1 > b.2.1 then
    if _h3 : x.1 < b.1 then ⟨x.1 + 1, x.2.1 - 1, x.2.2⟩
    else ⟨x.1, x.2.1 - 1, x.2.2 + 1⟩
  else if _h3 : x.1 < b.1 then ⟨x.1 + 1, x.2.1, x.2.2 - 1⟩
  else ⟨x.1, x.2.1 + 1, x.2.2 - 1⟩

/-- The greedy step preserves balance. -/
lemma balanced_step (x b : ℤ × ℤ × ℤ) (hx : balanced x) (_hb : balanced b) (_hne : x ≠ b) :
    balanced (step x b) := by
  by_cases h1 : x.1 > b.1
  · by_cases h2 : x.2.1 < b.2.1
    · dsimp [step]
      rw [if_pos h1, if_pos h2]
      dsimp [balanced] at *
      omega
    · dsimp [step]
      rw [if_pos h1, if_neg h2]
      dsimp [balanced] at *
      omega
  · by_cases h2 : x.2.1 > b.2.1
    · by_cases h3 : x.1 < b.1
      · dsimp [step]
        rw [if_neg h1, if_pos h2, if_pos h3]
        dsimp [balanced] at *
        omega
      · dsimp [step]
        rw [if_neg h1, if_pos h2, if_neg h3]
        dsimp [balanced] at *
        omega
    · by_cases h3 : x.1 < b.1
      · dsimp [step]
        rw [if_neg h1, if_neg h2, if_pos h3]
        dsimp [balanced] at *
        omega
      · dsimp [step]
        rw [if_neg h1, if_neg h2, if_neg h3]
        dsimp [balanced] at *
        omega

/-- The greedy step is an adjacency in `honeycomb` (moves a unit in two coordinates). -/
lemma adj_step (x b : ℤ × ℤ × ℤ) (hx : balanced x) (hb : balanced b) (hne : x ≠ b) :
    honeycomb.Adj x (step x b) := by
  refine ⟨hx, balanced_step x b hx hb hne, ?_⟩
  by_cases h1 : x.1 > b.1
  · by_cases h2 : x.2.1 < b.2.1
    · dsimp [step]
      rw [if_pos h1, if_pos h2]
      simp [hexDist]
    · dsimp [step]
      rw [if_pos h1, if_neg h2]
      simp [hexDist]
  · by_cases h2 : x.2.1 > b.2.1
    · by_cases h3 : x.1 < b.1
      · dsimp [step]
        rw [if_neg h1, if_pos h2, if_pos h3]
        simp [hexDist]
      · dsimp [step]
        rw [if_neg h1, if_pos h2, if_neg h3]
        simp [hexDist]
    · by_cases h3 : x.1 < b.1
      · dsimp [step]
        rw [if_neg h1, if_neg h2, if_pos h3]
        simp [hexDist]
      · dsimp [step]
        rw [if_neg h1, if_neg h2, if_neg h3]
        simp [hexDist]

/-- The greedy step lowers the distance to `b` by exactly one. -/
lemma hexDist_step_decr (x b : ℤ × ℤ × ℤ) (hx : balanced x) (hb : balanced b) (hne : x ≠ b) :
    hexDist (step x b) b = hexDist x b - 1 := by
  have hx' : x.1 + x.2.1 + x.2.2 = 0 := hx
  have hb' : b.1 + b.2.1 + b.2.2 = 0 := hb
  by_cases h1 : x.1 > b.1
  · by_cases h2 : x.2.1 < b.2.1
    · dsimp [step]
      rw [if_pos h1, if_pos h2]
      dsimp [hexDist]
      have hp : 0 < x.1 - b.1 := by omega
      have hq : x.2.1 - b.2.1 < 0 := by omega
      rw [show x.1 - 1 - b.1 = (x.1 - b.1) - 1 by ring]
      rw [show x.2.1 + 1 - b.2.1 = (x.2.1 - b.2.1) + 1 by ring]
      exact max3_shift (x.1 - b.1) (x.2.1 - b.2.1) (x.2.2 - b.2.2) hp hq (by omega)
    · dsimp [step]
      rw [if_pos h1, if_neg h2]
      dsimp [hexDist]
      have hp : 0 < x.1 - b.1 := by omega
      have hq : x.2.2 - b.2.2 < 0 := by omega
      rw [show x.1 - 1 - b.1 = (x.1 - b.1) - 1 by ring]
      rw [show x.2.2 + 1 - b.2.2 = (x.2.2 - b.2.2) + 1 by ring]
      simpa [max_comm, max_left_comm, max_right_comm, max_assoc] using
        max3_shift (x.1 - b.1) (x.2.2 - b.2.2) (x.2.1 - b.2.1) hp hq (by omega)
  · by_cases h2 : x.2.1 > b.2.1
    · by_cases h3 : x.1 < b.1
      · dsimp [step]
        rw [if_neg h1, if_pos h2, if_pos h3]
        dsimp [hexDist]
        have hp : 0 < x.2.1 - b.2.1 := by omega
        have hq : x.1 - b.1 < 0 := by omega
        rw [show x.2.1 - 1 - b.2.1 = (x.2.1 - b.2.1) - 1 by ring]
        rw [show x.1 + 1 - b.1 = (x.1 - b.1) + 1 by ring]
        simpa [max_comm, max_left_comm, max_right_comm, max_assoc] using
          max3_shift (x.2.1 - b.2.1) (x.1 - b.1) (x.2.2 - b.2.2) hp hq (by omega)
      · dsimp [step]
        rw [if_neg h1, if_pos h2, if_neg h3]
        dsimp [hexDist]
        have hp : 0 < x.2.1 - b.2.1 := by omega
        have hq : x.2.2 - b.2.2 < 0 := by omega
        rw [show x.2.1 - 1 - b.2.1 = (x.2.1 - b.2.1) - 1 by ring]
        rw [show x.2.2 + 1 - b.2.2 = (x.2.2 - b.2.2) + 1 by ring]
        simpa [max_comm, max_left_comm, max_right_comm, max_assoc] using
          max3_shift (x.2.1 - b.2.1) (x.2.2 - b.2.2) (x.1 - b.1) hp hq (by omega)
    · by_cases h3 : x.1 < b.1
      · dsimp [step]
        rw [if_neg h1, if_neg h2, if_pos h3]
        dsimp [hexDist]
        have hp : 0 < x.2.2 - b.2.2 := by omega
        have hq : x.1 - b.1 < 0 := by omega
        rw [show x.2.2 - 1 - b.2.2 = (x.2.2 - b.2.2) - 1 by ring]
        rw [show x.1 + 1 - b.1 = (x.1 - b.1) + 1 by ring]
        simpa [max_comm, max_left_comm, max_right_comm, max_assoc] using
          max3_shift (x.2.2 - b.2.2) (x.1 - b.1) (x.2.1 - b.2.1) hp hq (by omega)
      · dsimp [step]
        rw [if_neg h1, if_neg h2, if_neg h3]
        dsimp [hexDist]
        have hg : x.2.1 - b.2.1 < 0 ∧ 0 < x.2.2 - b.2.2 := by
          have hne' : x.1 - b.1 ≠ 0 ∨ x.2.1 - b.2.1 ≠ 0 ∨ x.2.2 - b.2.2 ≠ 0 :=
            exists_gap_ne_zero_of_ne hne
          rcases hne' with hg1 | hg2 | hg3
          · omega
          · constructor <;> omega
          · constructor <;> omega
        rcases hg with ⟨hq, hp⟩
        rw [show x.2.1 + 1 - b.2.1 = (x.2.1 - b.2.1) + 1 by ring]
        rw [show x.2.2 - 1 - b.2.2 = (x.2.2 - b.2.2) - 1 by ring]
        simpa [max_comm, max_left_comm, max_right_comm, max_assoc] using
          max3_shift (x.2.2 - b.2.2) (x.2.1 - b.2.1) (x.1 - b.1) hp hq (by omega)

/-- A walk from `x` to `b` of length exactly `n`, given `hexDist x b = n`: apply the
    greedy step `n` times (each step reduces the remaining distance by exactly one). -/
def walkOfLength (n : ℕ) (x b : ℤ × ℤ × ℤ) (hx : balanced x) (hb : balanced b)
    (hn : hexDist x b = (n : ℤ)) : { p : honeycomb.Walk x b // p.length = n } := by
  induction n generalizing x with
  | zero =>
      have hxeq : x = b := (hexDist_eq_zero_iff x b).mp hn
      subst x
      exact ⟨SimpleGraph.Walk.nil, by simp⟩
  | succ n ih =>
      have hne : x ≠ b := by
        intro hxeq
        subst x
        have hz : hexDist b b = 0 := hexDist_self b
        omega
      let y := step x b
      have hy : balanced y := balanced_step x b hx hb hne
      have hdecr : hexDist y b = hexDist x b - 1 := hexDist_step_decr x b hx hb hne
      have hn' : hexDist y b = (n : ℤ) := by
        rw [hdecr]
        omega
      obtain ⟨q, hq⟩ := ih y hy hn'
      exact ⟨SimpleGraph.Walk.cons (adj_step x b hx hb hne) q, by simp [hq]⟩

/-- The greedy walk from `a` to `b`. -/
def greedyWalk (a b : ℤ × ℤ × ℤ) (ha : balanced a) (hb : balanced b) : honeycomb.Walk a b :=
  (walkOfLength (hexDist a b).toNat a b ha hb (Int.toNat_of_nonneg (hexDist_nonneg a b)).symm).1

/-- The greedy walk has length exactly `hexDist a b`. -/
lemma greedyWalk_length (a b : ℤ × ℤ × ℤ) (ha : balanced a) (hb : balanced b) :
    (greedyWalk a b ha hb).length = (hexDist a b).toNat :=
  (walkOfLength (hexDist a b).toNat a b ha hb (Int.toNat_of_nonneg (hexDist_nonneg a b)).symm).2

/-- Lower bound: every walk of length `n` from `x` to `b` has `hexDist x b ≤ n`
    (each edge changes the distance by at most 1). -/
lemma hexDist_le_walk_length {x b : ℤ × ℤ × ℤ} (p : honeycomb.Walk x b) :
    hexDist x b ≤ (p.length : ℤ) := by
  exact SimpleGraph.Walk.rec
    (motive := fun u v p => hexDist u v ≤ (p.length : ℤ))
    (fun {u} => by simp [hexDist_self])
    (fun {u v w} h p ih => by
      calc
        hexDist u w ≤ hexDist u v + hexDist v w := hexDist_triangle u v w
        _ = 1 + hexDist v w := by rw [h.2.2]
        _ ≤ 1 + (p.length : ℤ) := by omega
        _ = ((SimpleGraph.Walk.cons h p).length : ℤ) := by
          rw [SimpleGraph.Walk.length_cons]
          push_cast
          omega)
    p

/-- Upper bound on the graph distance: `honeycomb.dist a b ≤ hexDist a b`. -/
lemma honeycomb_dist_le_hexDist (a b : ℤ × ℤ × ℤ) (ha : balanced a) (hb : balanced b) :
    (honeycomb.dist a b : ℤ) ≤ hexDist a b := by
  have hp : honeycomb.dist a b ≤ (hexDist a b).toNat := by
    simpa [greedyWalk_length] using (SimpleGraph.dist_le (greedyWalk a b ha hb))
  have hp' : (honeycomb.dist a b : ℤ) ≤ ((hexDist a b).toNat : ℤ) := by exact_mod_cast hp
  simpa [Int.toNat_of_nonneg (hexDist_nonneg a b)] using hp'

/-- Lower bound on the graph distance: `hexDist a b ≤ honeycomb.dist a b`. -/
lemma honeycomb_dist_ge_hexDist (a b : ℤ × ℤ × ℤ) (ha : balanced a) (hb : balanced b) :
    hexDist a b ≤ (honeycomb.dist a b : ℤ) := by
  have hr : honeycomb.Reachable a b := (greedyWalk a b ha hb).reachable
  obtain ⟨q, hq⟩ := hr.exists_walk_length_eq_dist
  have hle : hexDist a b ≤ (q.length : ℤ) := hexDist_le_walk_length q
  simpa [hq] using hle

/-- **T4**: on balanced cells, the honeycomb graph distance equals the cube-coordinate
    max-norm `hexDist`. -/
theorem honeycomb_dist_eq_hexDist (a b : ℤ × ℤ × ℤ) (ha : balanced a) (hb : balanced b) :
    (honeycomb.dist a b : ℤ) = hexDist a b :=
  le_antisymm (honeycomb_dist_le_hexDist a b ha hb) (honeycomb_dist_ge_hexDist a b ha hb)

end Hexagon
