/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Registers

/-!
# A2 — the fold δ is gauge-invariant; the χ² surprise is NOT (it scales)

**Idea history:** the rebuild's canonical truth: "the invariant is δ = O/E − 1; store δ,
not r"; the register ladder (Registers.lean). The measure-theory synthesis confirmed
"probability = count renormalized" — so the count→prob gauge is a common rescale by a
factor c, and δ survives it while χ² does not.

**Calibration:** DIRECT — a one-line algebra fact with real consequences.

**Status:** PROVED (2026-08-28) — closed by native tactics (`field_simp` + `ring`), no
`sorry` remaining:
1. `fold_gauge_invariant` — the fold δ = O/E − 1 is invariant under the count→prob gauge
   (a common rescale `(O, E) ↦ (c·O, c·E)` with c ≠ 0),
2. `surprise_scales` — the χ² surprise (O−E)²/E is NOT invariant: it scales by c,
3. `fold_eq_surprise_div` — the register-ladder relation surprise = δ²·E (matches
   `Registers.surprise_eq_delta_sq_mul_E`): under the count→prob gauge, δ survives,
   χ² scales — so store δ, not r.
`lake build Hexagon.ChiSquareGauge` green.
-/

namespace Lattice

-- Work with generic O, E : ℚ (the observed and expected counts), a common rescale c ≠ 0.
-- Local generic versions (Registers.lean defines `δ`/`surprise` over a count table
-- `V × V → ℕ`; the gauge statement is a pure-ℚ fact, so it is stated directly here).

/-- The fold δ = O/E − 1: the multiplicative excess of the observed count over the
independence null, re-centred at 0 (the gauge.rs "fold" register, generic ℚ form). -/
def fold (O E : ℚ) : ℚ :=
  O / E - 1

/-- The surprise / χ² term (O−E)²/E: one summand of ring² (generic ℚ form).
Named `surpriseGauge` because `Lattice.surprise` (the count-table form over
`V × V → ℕ`) is already declared in `Registers.lean`; this is the pure-ℚ
gauge statement of the same object. -/
def surpriseGauge (O E : ℚ) : ℚ :=
  (O - E) ^ 2 / E

/-- 1. The fold δ is gauge-invariant: a common rescale (count → probability gauge,
`O ↦ c·O`, `E ↦ c·E`) cancels out of δ = O/E − 1. This is *why* the invariant is
"store δ, not r" — the fold survives the gauge. -/
theorem fold_gauge_invariant (O E c : ℚ) (hc : c ≠ 0) : fold (c * O) (c * E) = fold O E := by
  unfold fold
  field_simp [hc]

/-- 2. The χ² surprise is NOT invariant — it scales by c under the same gauge:
`surpriseGauge(c·O, c·E) = c · surpriseGauge(O, E)`. So the χ² term cannot be stored across
gauges unless the gauge factor is tracked. -/
theorem surprise_scales (O E c : ℚ) (hc : c ≠ 0) :
    surpriseGauge (c * O) (c * E) = c * surpriseGauge O E := by
  unfold surpriseGauge
  field_simp [hc]

/-- 3. Consequence — the "store δ not r" principle: the register-ladder relation
`surpriseGauge = δ² · E` (the generic-ℚ version of `Registers.surprise_eq_delta_sq_mul_E`).
Together with 1 and 2 this pins down exactly what survives the count→prob gauge:
- δ is invariant (theorem 1),
- the surprise rescales by c (theorem 2), and
- the ladder relation shows the surprise is *derived* — δ² rescaled by E — so storing
  δ (or r) loses nothing, while storing the surprise bakes the gauge factor in. -/
theorem fold_eq_surprise_div (O E : ℚ) (hE : E ≠ 0) : surpriseGauge O E = (fold O E)^2 * E := by
  unfold surpriseGauge fold
  field_simp [hE]

end Lattice
