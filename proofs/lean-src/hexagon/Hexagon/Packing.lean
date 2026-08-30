/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# T6 — the hexagonal packing density, in τ (the full-turn constant)

**Idea history:** hexigon_conversation.md (packing/GR aside), plan §3 (packing density).
Ian (2026): use τ not π — "the base unit of rotation is the circle, not the half a
circle." So the density is stated in τ: `τ/(4√3)`.

**Calibration:** DIRECT — a real-number identity. The *optimality* (hexagonal packing
is the densest circle packing) is Thue / Fejes Tóth — cited, not proved here.

**Status:** PROVED (2026-08-28) — the τ form `τ/(4√3) = π/(2√3)` of the density.
The geometric derivation (circle area ÷ fundamental-cell area) and the Thue
optimality proof are deferred (see INDEX.md).
-/

namespace Hexagon

open scoped Real

/-- τ = 2π — the full-turn constant. The base unit of rotation is a circle, not a
    semicircle (Ian's convention: τ, not π). -/
noncomputable def tau : ℝ := 2 * Real.pi

/-- The hexagonal-lattice circle-packing density: circle area ÷ fundamental-cell area.
    In the hex lattice (unit cell = rhombus of two equilateral triangles, area `√3/2`)
    with unit spacing, each circle has radius `1/2` and area `π/4`, giving `π/(2√3)`. -/
noncomputable def hexPackingDensity : ℝ := Real.pi / (2 * Real.sqrt 3)

/-- T6 (τ form): the same density in τ — `τ/(4√3) = π/(2√3)`.
    `τ = 2π`, so `τ/(4√3) = 2π/(4√3) = π/(2√3)`. -/
theorem hexPackingDensity_eq_tau_div : hexPackingDensity = tau / (4 * Real.sqrt 3) := by
  rw [hexPackingDensity, tau]
  ring_nf

end Hexagon
