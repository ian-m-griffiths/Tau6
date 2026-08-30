# Emulation Geometry — what binary pays to fake the Tau hex address/geometry ops

**2026-08-30.** The strongest single case for "ternary/Eisenstein does it natively" is the
**geometry/address** layer: TROT (rotate by ωᵏ = 60°·k), negation, `hex_neighbor` (+unit),
`hex_encode`/`hex_decode` (hex↔u32 Szudzik), and `hex_pod_addr` (the 7-cell pod). This file
prices each one **native-ternary vs the best reasonable binary emulation**, and — the honest
part — separates the two different things "native" can mean: the **Eisenstein basis** (a
coordinate-system win any integer machine can adopt) and the **balanced-ternary radix** (free
negation, no sign bit, the only ternary-specific delta).

**Grounding.** Native costs are read from `rtl/hex_encode.v`, `rtl/hex_decode.v`,
`rtl/hex_pod_addr.v` and the proved theorems in `proofs/lean-src/hexagon/Hexagon/`
(`Gauge.lean`, `Rotation.lean`, `HexIsotropy.lean`, `Conventions.lean`, `Bijection.lean`,
`OffsetGrid.lean`). Binary emulation uses the standard binary tricks the principal named —
**axial coordinates + offset correction** for neighbor, the **actual rotation matrix** for
TROT, and the **same Szudzik pairing** for encode/decode.

**Cost notation.** `A` = add/sub, `M` = multiply/square, `N` = negate, `C` = compare/parity
check, `S` = shift/÷2. In balanced ternary `N` is a per-digit wire swap (free, carry-free);
in two's-complement binary `N` = invert + a ripple increment.

**Calibration legend.**
- **DIRECT** — read from the RTL / proved in Lean (op counts, the {0,±1} matrices, exactness
  and closure facts).
- **DERIVED** — the binary-emulation columns. These are standard textbook binary techniques
  (axial+offset hex grids, the 2×2 rotation matrix, Szudzik pairing), *not* in-repo artifacts,
  so their op counts are an honest synthesis, not a measured number.

---

## 0. The answer up front

> **The only place binary is *forced* off an integer lattice is TROT-as-Cartesian-rotation:
> rotating a point (x,y) by 60° needs cos60°=½ and sin60°=√3/2, i.e. 4 M + 2 A **and the
> irrational √3** — so it is neither exact in ℤ nor closed on the square lattice ℤ². Native
> Eisenstein TROT is a {0,±1} coordinate permutation (1 A + free N), exact in ℤ[ω]. For hex
> ADDRESSING, binary has the axial+offset trick, so the neighbor advantage is *not* "binary
> needs trig" — it is "no offset correction, all 6 neighbors uniform +unit." Encode/decode/
> pod are a Szudzik bijection both sides share, so they are ~a tie. Net: a real ~2–4× op saving
> plus an exactness/closure win on rotation, a ~1.3× + uniformity win on neighbor, one
> increment on negation — not a 10× strawman.**

---

## 1. The table

| op | (a) native ternary cost | (b) best binary emulation | (c) exactness / closure | (d) honest ternary advantage |
|---|---|---|---|---|
| **TROT** (ωᵏ = 60°·k) | **1 A + 1 N** (k=1,2,4,5); **2 N** (k=3); **0** (k=0). 0 M. Coefficients all {0,±1} — a permutation + one shared add (`Gauge.lean` `omegaPow_zero…five`, `Conventions.lean` `Mul`). | Cartesian rotation matrix: **4 M + 2 A + 1 S** (÷2). Entries cos60°=½, sin60°=√3/2. | √3/2 irrational ⇒ (1,0)↦(½, √3/2) ∉ ℤ². **NOT exact in ℤ, NOT closed on ℤ²** (the square lattice has only 4-fold symmetry D₄; it has no 60° rotation). Exact 60° needs ℚ(√3) = ℚ(ω) — the Eisenstein field — or float rounding. | **Exact + closed on ℤ[ω]**; 4 M + 2 A + √3 → 1 A. Largest single saving **and** an exactness win binary cannot match in Cartesian. **DIRECT/DERIVED.** |
| **negation** (−z) | **0 A, 2 N**, 0 carry. Per-digit +↔−, 0→0; `gate_tneg` = 0 cells (`rtl/gate_area.txt`). | Two's-complement: invert + increment per component = **2 ripple increments** (2 N-bit adders). | Both **exact + closed** (ℤ is closed under negation). No √3. | Exactly the +1 increment; the smallest free op and the one **true radix win** (no sign bit, ± symmetric). **DIRECT.** |
| **hex_neighbor** (+unit) | **2 A**, uniform across all 6 (unit offset (da,db) ∈ {0,±1}²; `hex_encode.v` `hex_neighbor`). | Axial (q,r) + offset correction: **2 A + 1 parity check** (odd-r brick-wall; `OffsetGrid.lean` `(a,b)↦(2a+b,b)`, checkerboard `c≡b mod 2`). **Not trig.** | Both **exact + closed on ℤ²** (axial *is* ℤ×ℤ). No √3 — the offset is an integer affine map. | **No offset correction**; all 6 neighbors uniform +unit (isotropy, `HexIsotropy.lean` `neighbors_card = 6`). ~2 A vs 2 A + parity ≈ **1.3× + uniformity** — not a 10× win. **DIRECT.** |
| **hex_encode** (hex→u32 Szudzik) | 2 `sign_fold` (≈2 N + 2 S + 2 cond-sub) + Szudzik pair (1 C + 1 M + 1–2 A) ≈ **1 M + 3 A + 2 N + 1 C**. | **Same Szudzik bijection** (radix-neutral integer arithmetic): 1 M + 3 A + 2×(inv+inc) + 1 C. | Both **exact, bijective, tight in u32** (`Bijection.lean` `pair_lt_two_pow_32`). No √3. | **~Tie** (slight ternary *loss* — the square/multiply pays the measured 1.72×/bit penalty, `word_fairfight.md`). Encode is a shared bijection, **not** a ternary win. **DIRECT.** |
| **hex_decode** (u32→hex) | Szudzik unpair (isqrt + 1 M + 2 A + 1 C) + 2 `sign_unfold` (parity + S + N). isqrt = restoring shift-and-subtract **~16 serial stages** (`hex_decode.v`). | **Same Szudzik unpair** + the same integer isqrt (radix-neutral; binary has hardware int-sqrt / Newton). Same ~16 stages. | Both **exact, bijective** (inverse of encode). No √3. | **~Tie.** The isqrt dominates and is radix-neutral; decode is the *expensive* direction for both. **DIRECT.** |
| **hex_pod_addr** (7-cell pod) | decode center once (1 isqrt) + 6×(2 A) = **12 A** + 6 re-encodes. Pod = {0} ∪ Z₆ (free to enumerate); rotation-invariant (`HexIsotropy.lean` `units_rotate_invariant`). | decode once + 6×(2 A + parity check) + 6 re-encodes (7-pt hex stencil on the offset square grid). | Both **exact + closed**. No √3. | **Isotropy + uniform neighbors** (no per-neighbor parity fix) + rotation-invariance. Op-count delta ≈ 6 parity checks (tiny). **DIRECT.** |

---

## 2. The √3 / closure penalty — where it actually bites, and where it doesn't

The asymmetry the principal flagged is real, but it is **narrower than "binary needs trig"**:

- **It bites only on TROT-as-a-Cartesian-rotation.** A 60° rotation of an integer point is not
  an integer operation: `sin60° = √3/2` is irrational, so `(1,0) ↦ (½, √3/2)` leaves ℤ² and
  cannot be represented exactly in integer arithmetic. This is a **closure failure**, not just
  a rounding error: the square lattice ℤ² has only the 4-fold dihedral group D₄ as its
  rotation symmetry — it *has no* 60° rotation. The only integer lattice closed under 60°
  rotation with unit steps is the Eisenstein lattice ℤ[ω] itself (up to scaling). So "exact
  6-fold rotation on the integer lattice" is **genuinely Eisenstein-only** — binary can only
  get it by abandoning Cartesian (x,y) and adopting axial (a,b) = ℤ[ω] in disguise.

- **It does NOT bite on neighbor / encode / decode / pod.** Axial coordinates are ℤ×ℤ, the
  offset embedding `(a,b)↦(2a+b,b)` is an integer affine map, and the Szudzik bijection is
  pure integer arithmetic. All of those stay exactly on an integer lattice in binary — no √3
  anywhere. The binary cost there is a *parity check* (offset correction), not an irrational.

So the honest shape of the finding is: **one op (rotation) where ternary wins exactness +
closure that binary literally cannot replicate in Cartesian; three ops (neighbor, encode,
decode, pod) where it's ~a tie or a small uniformity win; one op (negation) where ternary's
delta is a single increment.**

---

## 3. The honest calibration — basis vs radix, and ~2–4× vs 10×

The op saving in row 1 is **basis-driven, not radix-driven**:

1. **Vs the Cartesian rotation matrix** (binary *forced* to rotate an (x,y) point): the saving
   is large — 4 M + 2 A + √3 collapses to 1 A + free N, i.e. **~2–4×** (more if a multiply is
   priced at its ~3 add-equivalents of area/latency) **plus** the √3/closure win. This is the
   "strongest case" and it is *honest*, but it only holds while binary stays in Cartesian.

2. **Vs axial coordinates** (binary allowed the standard hex trick, storing (a,b) and applying
   the same {0,±1} matrix): the rotation saving **collapses to ~a tie** — both are 1 A. What
   remains ternary-specific is the **free negation** on the `−` entries (no +1 increment) and
   the mod-6 index add on the angle register. This is the calibration the whole doc runs on:
   *the exact {0,±1} rotation is available to any machine that stores Eisenstein/axial
   coordinates; the ternary radix only sweetens the sign flips.*

The same calibration applies to the address ops: axial+offset binary gets the neighbor for
2 A + a parity check (vs 2 A uniform), and Szudzik encode/decode is a shared bijection that
costs both sides the same integer arithmetic (and slightly *less* per bit in binary, since the
16-bit multiply/square is where the measured 1.72×/bit ternary multiplier penalty lives).

**Net, honestly:** ~2–4× (rotation, Cartesian comparison) + ~1.3× (neighbor) + 1 increment
(negation) + ~0 (encode/decode/pod). The exactness/closure win is real but it is **one op**,
and the "10× native" reading is a strawman — for addressing, binary's axial+offset trick
recovers almost everything except *uniformity and the free sign flip*.

---

## 4. One-liner

**What ternary/Eisenstein does natively that binary can't: an exact, lattice-closed 60°
rotation and a 6-uniform neighbor set on its own integer lattice ℤ[ω] — binary can only match
the rotation by switching to axial coordinates (the Eisenstein basis in disguise) and can only
fake the neighbor with a parity-based offset correction, so the honest native win is
exactness + closure + isotropy + a free sign flip, worth ~2–4× on rotation and ~1.3× on
neighbor — not a 10× strawman, and not a win at all on the Szudzik encode/decode, which both
sides share.**
