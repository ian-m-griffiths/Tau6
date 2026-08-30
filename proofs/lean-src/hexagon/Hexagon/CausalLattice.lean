/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions
import Hexagon.Rotation
import Hexagon.Pod
import Hexagon.HexIsotropy
import Hexagon.Residual

/-!
# The hex causal lattice — temporal precedence / circulation on ℤ[ω]

**Idea history:** Ian (2026-08-29): replace the "diamond lattice" of *How to Simplify
the Causal Graph* (lasttheory.com, Wolfram Physics — the motif `a→b, a→c, b&c→f`) with
the **hexagonal** lattice ℤ[ω]. The causal structure is **temporal precedence**, i.e. the
wedge `O_ab − O_ba` — Rung-1 association, NOT a finished causal arrow (both this project
and the english-project ledger retired the "light-cone causal arrow" over-claim).

**Calibration:** DIRECT (order theory + skew-symmetric algebra). The six Z₆ unit
directions are the directed causal edges; the wedge on a directed edge is the temporal
precedence; the flow is the divergence; the pod is the causal diamond.

**Status:** PROVED (2026-08-29) — native tactics, zero `sorry`.

The four facts (matching Ian's chosen framing):
1. **isotropy**  — every cell has exactly 6 unit-neighbors, a free Z₆ action.
2. **skew**      — the wedge is antisymmetric: reversing a directed edge negates it
                   (this is the `curl`/circulation content of temporal precedence).
3. **conservation** — the center's causal outflow is exactly balanced by the ring's
                   backflow (`Σ(O−E)=0` at the pod).
4. **diamond**   — the pod (center + 6 ring) is the closed radius-1 ball = the causal
                   diamond, Z₆-invariant.
-/

open scoped BigOperators

namespace Hexagon

open Eisenstein

/-- The causal flow (divergence) at a cell: the net wedge flowing OUT along its 6 unit
directions. Positive = source (temporally precedes its neighbors), negative = sink.
Matches the rebuild's `flow(w) = Σ_nb wedge(w, nb)` (`English/Circulation.lean`). -/
def flow (w : Eisenstein → Eisenstein → ℤ) (z : Eisenstein) : ℤ :=
  Finset.sum units (fun u => w z (z + u))

/-- The causal curl (circulation) at a cell: the bivector-weighted (Im) sum of the wedge
over the 6 directions. This is the skew / rotation part — `F1 + F2 − F4 − F5` in
`rtl/grad_recon.v`'s indexing (ω, ω², −ω, −ω²; the two ±1 directions drop out as pure Re). -/
def curl (w : Eisenstein → Eisenstein → ℤ) (z : Eisenstein) : ℤ :=
  w z (z + ⟨0, 1⟩) + w z (z + ⟨-1, 1⟩) - w z (z + ⟨0, -1⟩) - w z (z + ⟨1, -1⟩)

/-- **Fact 1 — isotropy.** Every cell has exactly 6 distinct unit-neighbors (the free Z₆
action); `z + u = z` only for `u = 0`, which is not a unit. -/
theorem causal_isotropy (z : Eisenstein) : (neighbors z).card = 6 :=
  neighbors_card z

/-- **Fact 2 — skew (wedge = curl).** The wedge is antisymmetric: `w a b = −w b a`. This
is the temporal-precedence statement — the directed edge carries an orientation, and its
reverse carries the opposite orientation (Rung-1: a sign, not a finished causal arrow).
Restates `Lattice.wedge_antisymm` specialized to the hex lattice. -/
theorem causal_skew (O : Eisenstein × Eisenstein → ℕ) (a b : Eisenstein) :
    Lattice.wedge Eisenstein O a b = - Lattice.wedge Eisenstein O b a :=
  Lattice.wedge_antisymm Eisenstein O a b

/-- **Fact 3 — conservation (the diamond balance).** The center's causal outflow is
exactly cancelled by the 6 ring cells' backflow, when the wedge is skew. This is the
discrete `Σ(O−E)=0` at the pod: the common cause (center) and the common effects (ring)
balance. -/
theorem diamond_balance (w : Eisenstein → Eisenstein → ℤ)
    (hskew : ∀ a b : Eisenstein, w a b = - w b a) :
    flow w 0 + Finset.sum units (fun u => w u 0) = 0 := by
  unfold flow
  have hzero : Finset.sum units (fun u => w 0 (0 + u)) = Finset.sum units (fun u => w 0 u) := by
    apply Finset.sum_congr rfl
    intro u _
    have hz : 0 + u = u := by
      rcases u with ⟨ua, ub⟩
      change (⟨0 + ua, 0 + ub⟩ : Eisenstein) = ⟨ua, ub⟩
      ext <;> dsimp <;> omega
    rw [hz]
  rw [hzero]
  have hback : Finset.sum units (fun u => w u 0) = - Finset.sum units (fun u => w 0 u) := by
    calc
      Finset.sum units (fun u => w u 0) = Finset.sum units (fun u => - w 0 u) := by
        apply Finset.sum_congr rfl
        intro u _
        exact hskew u 0
      _ = - Finset.sum units (fun u => w 0 u) := by rw [Finset.sum_neg_distrib]
  rw [hback]
  ring

/-- **Fact 4 — the pod is the causal diamond.** The pod (center + 6 ring) is the closed
radius-1 ball — exactly 7 cells — and it is Z₆-invariant: rotating by any unit permutes the
6 directions. This is the hex analog of the Wolfram diamond motif, with the pod as the
common cause + common effect neighborhood. -/
theorem pod_is_causal_diamond :
    pod.card = 7 ∧ (∀ u : Eisenstein, u ∈ units → units.image (fun v => u * v) = units) := by
  constructor
  · exact pod_card
  · intro u hu
    exact units_rotate_invariant u hu

/-- Every pod cell other than the center is a unit, and every pod cell has norm ≤ 1 — the
causal diamond is the set of cells at causal distance ≤ 1 from the center. -/
theorem causal_diamond_norm_le_one (x : Eisenstein) (hx : x ∈ pod) : norm x ≤ 1 :=
  pod_norm_le_one x hx

end Hexagon
