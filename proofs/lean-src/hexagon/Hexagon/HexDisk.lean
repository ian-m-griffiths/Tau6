/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib

/-!
# Hex disk — the centered hexagonal number 3r² + 3r + 1 (area grab)

**Idea history:** Ian (2026-08-28): "grab by area, not just scalar and offset".

**Calibration:** DIRECT — the number of hex cells within hex-distance r of a center
is the centered hexagonal number H_r = 1 + 3r(r+1) = 3r² + 3r + 1 (H_0=1, H_1=7,
H_2=19, H_3=37, ...). Ring k has 6k cells (k ≥ 1).

**Status:** PROVED (2026-08-28) — all three theorems closed by native `ring`, zero
`sorry`. (The lattice-count version, counting actual cells with `hexDist ≤ r`, remains
a follow-up target, not yet stated.)
-/

namespace Hexagon

/-- Centered hexagonal number: cells in a radius-r hex disk. -/
def hexDiskCard (r : ℕ) : ℕ := 1 + 3 * r * (r + 1)

/-- radius 1 → 7 (the pod). -/
theorem hexDiskCard_one : hexDiskCard 1 = 7 := by
  decide

/-- radius 2 → 19. -/
theorem hexDiskCard_two : hexDiskCard 2 = 19 := by
  decide

/-- Closed form 1 + 3r(r+1) = 3r² + 3r + 1. Hint: `ring`. -/
theorem hexDiskCard_eq (r : ℕ) : hexDiskCard r = 3 * r ^ 2 + 3 * r + 1 := by
  unfold hexDiskCard
  ring

/-- Each new ring adds 6(r+1) cells: H_{r+1} = H_r + 6(r+1). Hint: `ring`
    (or `ring_nf` if `ring` stalls on the Nat exponent). -/
theorem hexDiskCard_succ (r : ℕ) : hexDiskCard (r + 1) = hexDiskCard r + 6 * (r + 1) := by
  unfold hexDiskCard
  ring

/-- The disk grows quadratically: it is exactly a quadratic in r with no linear
    coefficient beyond 3. (A convenience restatement of `hexDiskCard_eq`.) -/
theorem hexDiskCard_quadratic (r : ℕ) : hexDiskCard r = 1 + 3 * r + 3 * r * r := by
  unfold hexDiskCard
  ring

end Hexagon
