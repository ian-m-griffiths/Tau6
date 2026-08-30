/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# T2 — the 7-hex ↔ balanced-ternary bijection (the one-page theorem)

**Idea history:** hexigon_conversation.md L10005–10017 (3³ = 27 triples, constraint
q+r+s=0 leaves exactly 7) and L10105 (the theorem statement, "Balanced Ternary triples
satisfying q+r+s=0 are bijective to the vertices of a hexagonal tiling"); plan §3.

**Calibration:** DIRECT — enumeration-proved by hand in the thread; this file ports it.
The *hardware* reading (one-wire push/pull/null, 2-diode receiver → binary) is hex-mmu
phase 3 — RECORDED in the plan, not proved here.

**Status:** PROVED (2026-08-28) — T2a `hexCells_card` (`decide`) and T2b
`balanced_iff_mem` (`rcases` + `fin_cases` + `decide`) closed by native tactics;
`lake build` green.
-/

namespace Hexagon

/-- The 7 cells of the unit hexagon in cube/axial coordinates (q, r, s):
    q + r + s = 0, each coordinate in {-1, 0, 1}.
    NOTE: Lean n-tuples are nested pairs — the components of `t : ℤ × ℤ × ℤ`
    are `t.1`, `t.2.1`, `t.2.2` (there is no `t.3`). -/
def hexCells : Finset (ℤ × ℤ × ℤ) :=
  {((0, 0, 0)), ((1, 0, -1)), ((0, 1, -1)), ((-1, 1, 0)),
   ((-1, 0, 1)), ((0, -1, 1)), ((1, -1, 0))}

/-- T2a: there are exactly 7 cells. -/
theorem hexCells_card : hexCells.card = 7 := by
  decide

/-- Balanced-ternary condition: the triple sums to zero. -/
def balanced (t : ℤ × ℤ × ℤ) : Prop := t.1 + t.2.1 + t.2.2 = 0

/-- T2b: among the triples over {-1, 0, 1}, exactly the balanced ones are the 7 cells.
    (Prover agent: `fin_cases` the three membership hypotheses, or restate over
    `Fin 3 → ℤ`, then `decide` each branch.) -/
theorem balanced_iff_mem (t : ℤ × ℤ × ℤ)
    (h1 : t.1 ∈ ({-1, 0, 1} : Finset ℤ))
    (h2 : t.2.1 ∈ ({-1, 0, 1} : Finset ℤ))
    (h3 : t.2.2 ∈ ({-1, 0, 1} : Finset ℤ)) :
    balanced t ↔ t ∈ hexCells := by
  rcases t with ⟨a, ⟨b, c⟩⟩
  dsimp [balanced] at *
  fin_cases h1 <;> fin_cases h2 <;> fin_cases h3 <;> decide

end Hexagon
