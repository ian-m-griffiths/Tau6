/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions

/-!
# T3 + T4 — the Z₆ rotation group and the cube-coordinate hex distance

**Idea history:** hexigon_conversation.md L10179–10197 (rotation = permute tuple
indices, mod-6 arithmetic), L11248 ("trig becomes modulo arithmetic"), L11397–11399
(60° basis → exact integer angles); plan §3; SYNTHESIS Q1 (the hex↔u32 address claim
stays SPECULATION until a provable address translation exists — T4 is its metric).

**Calibration:** DIRECT (real math, integer-native). The Z₆ spinor is the one DIRECT
bridge to the rebuild: a mod-6 integer rotation realizing the even-grade fix
ψ = (α+βI)U (TODO #16, ox alpha.md L3109; plan §2.6).

**Status:** STATED-UNPROVED — T3a is `decide`-closable; T3b/T4 need definitions
(unit→angle map; neighbor relation) — see INDEX.md.
-/

namespace Hexagon

open Eisenstein

/-- The six units of ℤ[ω]: ±1, ±ω, ±ω² (the six 60° rotations).
    As pairs: 1=(1,0), -1=(-1,0), ω=(0,1), -ω=(0,-1), ω²=ω-1=(-1,1), -ω²=(1,-1). -/
def units : Finset Eisenstein :=
  {((1, 0)), ((-1, 0)), ((0, 1)), ((0, -1)), ((-1, 1)), ((1, -1))}

/-- T3a: there are exactly six units. -/
theorem units_card : units.card = 6 := by
  decide

/-- Angle index 0..5; rotation = addition mod 6 (the Z₆ group operation). -/
def angleAdd (a b : Fin 6) : Fin 6 := a + b

/-- T3b contract: the units are closed under multiplication and form the cyclic
    group Z₆ (the sixth roots of unity). (Suggestion: map each unit to its angle
    in `Fin 6` and prove `mul` corresponds to `angleAdd`.) -/
theorem units_closed_under_mul (x y : Eisenstein) (hx : x ∈ units) (hy : y ∈ units) :
    mul x y ∈ units := by
  sorry

/-- T4a (needed before T4): the neighbor relation on hex cells — two cells are
    neighbors iff their cube-coordinate max-norm distance is 1.
    NOTE: Lean n-tuples are nested pairs — components of `ℤ × ℤ × ℤ` are
    `.1`, `.2.1`, `.2.2` (there is no `.3`). -/
def hexDist (a b : ℤ × ℤ × ℤ) : ℤ :=
  max (|a.1 - b.1|) (max (|a.2.1 - b.2.1|) (|a.2.2 - b.2.2|))

/-- T4 contract: on balanced cells the max-norm distance equals the honeycomb graph
    distance (shortest path over the neighbor relation). Requires T4a first —
    contract only until then (INDEX.md). -/
theorem hexDist_is_graphDistance : True := by
  trivial

end Hexagon
