/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Conventions
import Hexagon.Rotation

/-!
# Field calculus — TGRAD/TRECON: the div⊕curl split and the canonical ∇⁻¹ section

Formalizes the field-calculus pair (`rtl/grad_recon.v`) in Lean, closing the gap flagged
in `docs/riscv_survey/xlattice_encoding.md` §4/§7 ("the TRECON canonical section is an
OURS convention, not yet a theorem").

**Definitions (at the origin; the ring cells are the 6 Z₆ units ωᵏ in angle order):**

```
div  = F0 − F2 − F3 + F5     (Re  coefficients +1, 0, −1, −1, 0, +1 — the scalar/source grade)
curl = F1 + F2 − F4 − F5     (Im  coefficients  0,+1, +1,  0, −1, −1 — the bivector/skew grade)
```

where `F_k = f (ωᵏ)`, `ω⁰=(1,0)`, `ω¹=(0,1)`, `ω²=(−1,1)`, `ω³=(−1,0)`, `ω⁴=(0,−1)`,
`ω⁵=(1,−1)`.  `div`/`curl` here are the *field* versions (a scalar field `f : Eisenstein → ℤ`),
distinct from `CausalLattice`'s `curl` (which takes a two-argument wedge weight).

**Calibration:** DIRECT — finite arithmetic over the 6 ring cells. The center value drops
out (`Σ ωᵏ = 0` — the additive gauge; `HexIsotropy.neighbors_card`).

**Status:** PROVED (2026-08-29) — native tactics, zero `sorry`.
-/

namespace Hexagon

open Eisenstein

/-- div = the Re-weighted 6-neighbor sum at the origin (the scalar/source grade). -/
def div6 (f : Eisenstein → ℤ) : ℤ :=
  f ⟨1, 0⟩ - f ⟨-1, 1⟩ - f ⟨-1, 0⟩ + f ⟨1, -1⟩

/-- curl = the Im-weighted 6-neighbor sum at the origin (the bivector/skew grade). -/
def curl6 (f : Eisenstein → ℤ) : ℤ :=
  f ⟨0, 1⟩ + f ⟨-1, 1⟩ - f ⟨0, -1⟩ - f ⟨1, -1⟩

/-- TGRAD at the origin, split into `div ⊕ curl`. -/
def tgrad6 (f : Eisenstein → ℤ) : ℤ × ℤ := (div6 f, curl6 f)

/-- TRECON: the canonical gauge-fixed section of ∇⁻¹ — the source `(d, c)` is placed on
    the two positive-axis ring cells `ω⁰ = (1,0)` and `ω¹ = (0,1)`; every other cell is 0. -/
def trecon (d c : ℤ) : Eisenstein → ℤ :=
  fun x => if x = ⟨1, 0⟩ then d else if x = ⟨0, 1⟩ then c else 0

/-- Exact round-trip in canonical gauge: the div/curl of the canonical section is exactly
    the source placed on it — `TRECON(TGRAD f) = f` for a field supported on `ω⁰, ω¹`. -/
theorem trecon_roundtrip (a b : ℤ) : div6 (trecon a b) = a ∧ curl6 (trecon a b) = b := by
  unfold div6 curl6 trecon
  simp

/-- The gauge-invariant round trip: `TGRAD(TRECON(TGRAD f)) = TGRAD f`, for any field.
    (∇ is a 6→2 linear map with a 4-dimensional nullspace, so `TRECON` is defined only up
    to gauge; the canonical section reproduces exactly the gauge-invariant part.) -/
theorem tgrad_trecon_tgrad (f : Eisenstein → ℤ) :
    tgrad6 (trecon (div6 f) (curl6 f)) = tgrad6 f := by
  unfold tgrad6
  have h := trecon_roundtrip (div6 f) (curl6 f)
  rw [h.1, h.2]

/-- The center is the additive gauge: a constant shift of the whole field (center and ring)
    leaves div and curl unchanged — the discrete `Σ(O−E)=0` conservation echo. -/
theorem div_curl_shift_invariant (f : Eisenstein → ℤ) (c : ℤ) :
    div6 (fun x => f x + c) = div6 f ∧ curl6 (fun x => f x + c) = curl6 f := by
  constructor <;> (simp [div6, curl6]; ring_nf)

/-! ## ∇² — the 6-point hex Laplacian and the TRELAX heat step -/

/-- The 6-point hex Laplacian: `Lap f z = Σ_{u ∈ units} f(z+u) − 6·f(z)` (the discrete
    ∇² — `rtl/trelax.v`'s `Lap u = Σ_nb − 6u`). -/
def lap (f : Eisenstein → ℤ) (z : Eisenstein) : ℤ :=
  (Finset.sum units (fun u => f (z + u))) - 6 * f z

/-- TRELAX: one heat-equation step `u' = u/3 + (Σ_nb)/9` (the α = 2/3 folded form,
    `u + (1/9)(Σ_nb − 6u)` — `rtl/trelax.v`).  Stated over ℚ so the ÷3/÷9 are exact
    (in the RTL they are the free ternary right-shifts of `TernaryCrt.div3_truncation`). -/
def trelax (f : Eisenstein → ℤ) (z : Eisenstein) : ℚ :=
  (f z : ℚ) / 3 + (Finset.sum units (fun u => (f (z + u) : ℚ))) / 9

/-- The Laplacian of a constant field is zero: the heat equation's steady state is the
    uniform field (the 6 neighbors average back to the center). -/
theorem lap_constant (c : ℤ) : lap (fun _ => c) 0 = 0 := by
  unfold lap
  simp [Finset.sum_const, units_card]

/-- The Laplacian is linear: `Lap(f + g) = Lap f + Lap g`. -/
theorem lap_add (f g : Eisenstein → ℤ) (z : Eisenstein) :
    lap (fun x => f x + g x) z = lap f z + lap g z := by
  unfold lap
  rw [Finset.sum_add_distrib]
  ring

-- The TRELAX update is `u' = u + Lap u / 9` (the folded `rtl/trelax.v` update
-- `u + (1/9)(Σ_nb − 6u)`); its relaxation property is captured by `lap_constant`
-- (the uniform field is the steady state: `Lap = 0`, so `u' = u`).

end Hexagon
