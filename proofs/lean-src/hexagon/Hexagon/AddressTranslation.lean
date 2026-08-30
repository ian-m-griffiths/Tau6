/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Mathlib
import Hexagon.Bijection
import Hexagon.TernaryCrt
import Hexagon.CrtHex
import Hexagon.HexDisk

/-!
# Address translation — the hex address refines the binary XOR-kernel address

**Idea history:** the SPECULATION "hex addressing *replaces* the u32 XOR kernel"
(AGENTS.md §Quantum Properties, INDEX.md "blocked on T4 + address-translation theorem").
The rebuild's u32 XOR kernel decomposes an address into two axes:
  * **phase** = parity (`(-1)^popcount`, mod 2) — the angle/`cos` sign;
  * **ring**  = the highest set bit (`log2 d`, `d >> 1` RG flow) — the scale/band.
The hex lattice replaces these with:
  * **angle** = the Z₆ direction (mod 6) — which, by CRT `Z₆ ≅ Z₂ × Z₃`, REFINES parity;
  * **ring**  = the hex disk radius (norm/hexDist), `3r²+3r+1` cells, ÷3 trit-shift = RG flow.

This module proves the *structural* half of the address translation: the hex (angle, ring)
decomposition faithfully translates — and refines — the binary (phase, bit) decomposition.
(It does NOT claim the two kernels are *performance*-equivalent; that stays SPECULATION.)

**Calibration:** DIRECT (modular arithmetic / CRT / combinatorics). The one genuinely-new
theorem is `angle_refines_parity`; the rest assemble the already-proved pieces.

**Status:** PROVED (2026-08-29) — native tactics, zero `sorry`.
-/

namespace Hexagon

open Eisenstein

/-- **Angle translation (the new bit).** The hex angle (mod 6) refines the XOR phase
(mod 2): the parity of `n` is exactly the mod-2 residue of its mod-6 angle. Since
`n ≡ n % 6 (mod 6)` and `2 ∣ 6`, we get `n ≡ n % 6 (mod 2)`, i.e. `n % 2 = (n % 6) % 2`.
The Z₆ angle therefore *subsumes* the binary parity (it is parity × a 3-cycle). -/
theorem angle_refines_parity (n : ℤ) : n % 2 = (n % 6) % 2 := by
  have h6 : n ≡ n % 6 [ZMOD 6] := (Int.mod_modEq n 6).symm
  have hd6 : (6 : ℤ) ∣ (n % 6) - n := Int.modEq_iff_dvd.mp h6
  have hd2 : (2 : ℤ) ∣ (n % 6) - n := dvd_trans (by norm_num : (2 : ℤ) ∣ 6) hd6
  exact Int.modEq_iff_dvd.mpr hd2

/-- **Angle assembly (CRT).** The hex angle (mod 6) is recovered from the two free
residues — the parity (mod 2, the XOR phase) and the 3-cycle (mod 3) — by the CRT inverse
`3a + 4b`. This is `TernaryCrt.crt_assembly`: the Z₆ angle = phase × 3-cycle. -/
theorem hex_angle_assembly (n : ℤ) : n % 6 = (3 * (n % 2) + 4 * (n % 3)) % 6 :=
  crt_assembly n

/-- **Address bijection.** Every hex cell (Eisenstein integer) ↔ a natural/u32 address, so
the hex (angle, ring) decomposition lives on exactly the address space the XOR kernel runs
on. (`Bijection.eisensteinEquiv` — the Szudzik-pairing bijection, proved a bijection.) -/
theorem hex_address_bijective : Function.Bijective eisensteinToNat :=
  eisensteinEquiv.bijective

/-- **Ring translation.** The hex disk grows as the centered hexagonal number `3r²+3r+1`
(1, 7, 19, 37, …), each ring adding `6(r+1)` cells — the hex analog of the binary `2^k`
rings. (`HexDisk.hexDiskCard_succ`.) -/
theorem hex_ring_growth (r : ℕ) : hexDiskCard (r + 1) = hexDiskCard r + 6 * (r + 1) :=
  hexDiskCard_succ r

/-- **The address-translation theorem.** The hex address decomposition faithfully
translates the binary XOR-kernel decomposition:
  * angle ⊇ phase — `n % 2 = (n % 6) % 2` (the Z₆ angle refines the parity);
  * angle = phase × 3-cycle — `n % 6 = (3·(n%2) + 4·(n%3)) % 6` (CRT assembly);
  * address — `eisensteinToNat` is a bijection (same address space);
  * ring — the hex disk grows `3r²+3r+1`, the hex analog of the `2^k` rings.
The hex layer therefore carries everything the XOR kernel's two axes carried, plus the
3-cycle. (Performance equivalence of the *kernels* is NOT claimed here — that is the
still-SPECULATION half, `INDEX.md`.) -/
theorem address_translation :
    (∀ n : ℤ, n % 2 = (n % 6) % 2) ∧
    (∀ n : ℤ, n % 6 = (3 * (n % 2) + 4 * (n % 3)) % 6) ∧
    Function.Bijective eisensteinToNat ∧
    (∀ r : ℕ, hexDiskCard (r + 1) = hexDiskCard r + 6 * (r + 1)) := by
  constructor
  · exact angle_refines_parity
  · constructor
    · exact hex_angle_assembly
    · constructor
      · exact hex_address_bijective
      · exact hex_ring_growth

end Hexagon
