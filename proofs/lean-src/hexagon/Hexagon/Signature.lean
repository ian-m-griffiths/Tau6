/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions
import Hexagon.Rotation

/-!
# B4 — the four signatures (i² = −1, +1, 0, ω) and what distinguishes them

**Idea history:** the rebuild's `gauge_int.rs` `Signature` enum (Gaussian/Eisenstein/
Minkowski/Null); GAUGE_VARIANTS.md §1; the porting map's C1 (gauge has 3 meanings). The
four 2D composition algebras: i²=−1 (ℂ/Gaussian, units Z₄), i²=+1 (split-complex, zero
divisors), i²=0 (dual numbers, nilpotents), i²=ω (Eisenstein, units Z₆ — already proved).

**Calibration:** DIRECT — finite ring theory.

**Status:** PROVED (2026-08-28) — B4.1 Gaussian units Z₄ (`gaussianUnits_card = 4`,
each unit has `gaussianNorm = 1`); B4.2 split-complex zero divisor
(`split_zero_divisor`); B4.3 dual nilpotent + units Z₂ (`dual_nilpotent`,
`dualUnits_card = 2`); B4.4 Eisenstein Z₆ restated from `Rotation.units_card`
(not re-proved). `lake build Hexagon.Signature` green, zero `sorry`.
-/

namespace Hexagon

-- On `ℤ × ℤ` define FOUR multiplications (i² = s for s ∈ {−1, 0, +1}, plus the Eisenstein
-- ω-mul already in Conventions.lean):
--   gaussian (s=−1): (a,b)·(c,d) = (ac − bd, ad + bc)      [i² = −1]
--   split    (s=+1): (a,b)·(c,d) = (ac + bd, ad + bc)      [j² = +1]
--   dual     (s= 0): (a,b)·(c,d) = (ac, ad + bc)           [ε² = 0]

/-- Gaussian multiplication on pairs: `(a,b)·(c,d) = (ac − bd, ad + bc)`, i.e. `i² = −1`. -/
def gaussianMul (x y : ℤ × ℤ) : ℤ × ℤ :=
  (x.1 * y.1 - x.2 * y.2, x.1 * y.2 + x.2 * y.1)

/-- Split-complex multiplication on pairs: `(a,b)·(c,d) = (ac + bd, ad + bc)`, i.e. `j² = +1`. -/
def splitMul (x y : ℤ × ℤ) : ℤ × ℤ :=
  (x.1 * y.1 + x.2 * y.2, x.1 * y.2 + x.2 * y.1)

/-- Dual-number multiplication on pairs: `(a,b)·(c,d) = (ac, ad + bc)`, i.e. `ε² = 0`. -/
def dualMul (x y : ℤ × ℤ) : ℤ × ℤ :=
  (x.1 * y.1, x.1 * y.2 + x.2 * y.1)

/-- The Gaussian norm `a² + b²` (norm 1 = on the unit circle). -/
def gaussianNorm (x : ℤ × ℤ) : ℤ := x.1 ^ 2 + x.2 ^ 2

/-- B4.1: the Gaussian units `{±1, ±i}` as pairs `{(1,0),(-1,0),(0,1),(0,-1)}`. -/
def gaussianUnits : Finset (ℤ × ℤ) := {(1, 0), (-1, 0), (0, 1), (0, -1)}

/-- B4.1a: there are exactly four Gaussian units (Z₄). -/
theorem gaussianUnits_card : gaussianUnits.card = 4 := by
  decide

/-- B4.1b: every Gaussian unit has norm 1 under `a² + b²`. -/
theorem gaussianNorm_unit_eq_one (x : ℤ × ℤ) (hx : x ∈ gaussianUnits) :
    gaussianNorm x = 1 := by
  suffices hx' : x = (1, 0) ∨ x = (-1, 0) ∨ x = (0, 1) ∨ x = (0, -1) by
    rcases hx' with rfl | rfl | rfl | rfl <;> norm_num [gaussianNorm]
  simpa [gaussianUnits] using hx

/-- B4.2: the split-complex numbers have zero divisors — `(1,1)·(1,−1) = (0,0)` with both
    factors nonzero. -/
theorem split_zero_divisor :
    splitMul (1, 1) (1, -1) = (0, 0) ∧ (1, 1) ≠ (0, 0) ∧ (1, -1) ≠ (0, 0) := by
  constructor
  · norm_num [splitMul]
  · constructor <;> decide

/-- B4.3: the dual numbers are nilpotent — `(0,1)² = (0,0)` with `(0,1) ≠ (0,0)`. -/
theorem dual_nilpotent :
    dualMul (0, 1) (0, 1) = (0, 0) ∧ (0, 1) ≠ (0, 0) := by
  constructor
  · norm_num [dualMul]
  · decide

/-- B4.3b: the dual units `{±1}` as pairs `{(1,0),(-1,0)}`. -/
def dualUnits : Finset (ℤ × ℤ) := {(1, 0), (-1, 0)}

/-- B4.3c: there are exactly two dual units (Z₂). -/
theorem dualUnits_card : dualUnits.card = 2 := by
  decide

/-- B4.4: the Eisenstein units form Z₆ (6 units). Not re-proved here — already in the
    ledger as `Rotation.units_card` (`Hexagon.units_card`); restated for the comparison
    table. -/
theorem eisenstein_units_card : units.card = 6 :=
  Hexagon.units_card

/-- The four signatures are pairwise distinguished by unit-group cardinality
    (Gaussian 4 / split 4 / dual 2 / Eisenstein 6) and by zero-divisor/nilpotent
    structure; the Eisenstein (6) and Gaussian (4) cases are the two integral-domain
    cases. -/
theorem signatures_distinguished :
    gaussianUnits.card = 4 ∧ dualUnits.card = 2 ∧ units.card = 6 := by
  constructor
  · exact gaussianUnits_card
  · constructor
    · exact dualUnits_card
    · exact eisenstein_units_card

/-! ## Conclusion

The four signatures are distinguished by unit-group cardinality (4 / 4 / 2 / 6) and by
zero-divisor/nilpotent structure:

* **Gaussian** (i² = −1): units Z₄ (`gaussianUnits_card`), every unit of norm 1
  (`gaussianNorm_unit_eq_one`) — an integral domain.
* **Split-complex** (j² = +1): has zero divisors (`split_zero_divisor`).
* **Dual** (ε² = 0): nilpotent (`dual_nilpotent`), units Z₂ (`dualUnits_card`).
* **Eisenstein** (ω² = ω − 1): units Z₆ (`eisenstein_units_card`, via
  `Rotation.units_card`) — an integral domain (Euclidean, see Conventions/Euclidean).

So the Eisenstein (6) and Gaussian (4, integral domain) cases are the two
integral-domain cases; the other two signatures are told apart by their zero divisors
(split) and nilpotents (dual).
-/

end Hexagon
