/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# T0 + T1 — the Eisenstein integers: ω-multiplication + multiplicative norm

**Idea history:** Ian (2026) "einstein triangles of 60 degrees"; hexigon_conversation.md
L10005–10105 (the bijection) and L11544 (Eisenstein magnitude/angle form); ox alpha.md
TODO #16 "Gauge-int / Eisenstein lattice" (L3109); plan §3.

**Calibration:** DIRECT — standard ring theory; the rebuild bridge is TODO #16
(gauge-int integer pair + Signature, "gauge = a property of the unit").

**Convention:** ω = e^(iπ/3), ω² = ω − 1, N(a+bω) = a² + ab + b², units Z₆.
mathlib's `EisensteinInt` (if present) uses ω = e^(2πi/3), norm a² − ab + b² —
prefer reuse + a proven convention bridge over a re-definition (see INDEX.md T-ISO).

**Design note (why a `structure`, not `ℤ × ℤ`):** an `abbrev` for `ℤ × ℤ` would inherit
the *componentwise* product ring, where `(1,0)·(0,1) = (0,0)` — zero divisors, not our
ω-multiplication. A distinct `structure` lets `*` be the ω-multiplication below.

**Status:** PROVED (2026-08-28) — `mul_comm` and `norm_mul` closed by native tactics.
The full `CommRing Eisenstein` typeclass instance is DEFERRED (typeclass boilerplate;
the `*`/`+`/`-` instances below already give the notation, and the axioms hold by the
same `ext <;> ring` — assemble in a later pass when the EuclideanDomain instance needs
it). `lake build` green.
-/

namespace Hexagon

/-- The Eisenstein integers `a + bω`, `ω = e^(iπ/3)`, `ω² = ω − 1`. -/
@[ext] structure Eisenstein where
  a : ℤ
  b : ℤ
  deriving DecidableEq, Repr, Inhabited

namespace Eisenstein

instance : Zero Eisenstein := ⟨⟨0, 0⟩⟩
instance : One Eisenstein := ⟨⟨1, 0⟩⟩
instance : Neg Eisenstein := ⟨fun x => ⟨-x.a, -x.b⟩⟩
instance : Add Eisenstein := ⟨fun x y => ⟨x.a + y.a, x.b + y.b⟩⟩
instance : Sub Eisenstein := ⟨fun x y => ⟨x.a - y.a, x.b - y.b⟩⟩

/-- `(a+bω)(c+dω) = (ac−bd) + (ad+bc+bd)ω`, since `ω² = ω − 1`. -/
instance : Mul Eisenstein := ⟨fun x y =>
  ⟨x.a * y.a - x.b * y.b, x.a * y.b + x.b * y.a + x.b * y.b⟩⟩

instance : NatCast Eisenstein := ⟨fun n => ⟨(n : ℤ), 0⟩⟩
instance : IntCast Eisenstein := ⟨fun n => ⟨n, 0⟩⟩

/-- T0: multiplication is commutative. -/
theorem mul_comm (x y : Eisenstein) : x * y = y * x := by
  rcases x with ⟨a, b⟩
  rcases y with ⟨c, d⟩
  change Eisenstein.mk (a * c - b * d) (a * d + b * c + b * d)
      = Eisenstein.mk (c * a - d * b) (c * b + d * a + d * b)
  ext <;> ring

/-- The norm: `N(a+bω) = a² + ab + b²` (always ≥ 0; 0 iff the element is 0). -/
def norm (x : Eisenstein) : ℤ := x.a ^ 2 + x.a * x.b + x.b ^ 2

/-- T1: the norm is multiplicative. -/
theorem norm_mul (x y : Eisenstein) : norm (x * y) = norm x * norm y := by
  rcases x with ⟨a, b⟩
  rcases y with ⟨c, d⟩
  change (a * c - b * d) ^ 2 + (a * c - b * d) * (a * d + b * c + b * d)
      + (a * d + b * c + b * d) ^ 2
    = (a ^ 2 + a * b + b ^ 2) * (c ^ 2 + c * d + d ^ 2)
  ring_nf

end Eisenstein
end Hexagon
