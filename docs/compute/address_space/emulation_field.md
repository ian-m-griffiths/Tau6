# Binary Emulation Cost of the Field Calculus — TGRAD / TRECON / TRELAX

**2026-08-30.** The question: on a *binary* machine, how many binary ops do the three
field-calculus primitives (`∇F = J`, `F = ∇⁻¹J`, one heat step) each take — and, crucially,
**does the binary equivalent pay the 6-neighbor address computation (the hex-pod lookup via
axial offset) separately, or is that shared?** This file answers both, honestly: the div/curl
reduction is the *same* 6 signed adds in both bases, and the ternary advantage is confined to
exactly two places — the **isotropic pod lookup** and the **free ÷3/÷9 shifts**.

Calibration legend (subset used here): **DIRECT** = verbatim from `rtl/` / proved in
`proofs/lean-src/hexagon/Hexagon/` / measured in `docs/compute/field_calculus/trelax_measured.md`;
**DERIVED** = counted from the RTL structure, not independently synthesized. This is a sibling of
`operation_cost.md` (sense-cost axis), `instruction_footprint.md` (address-space classification),
and `eisenstein_free_ops.md` (the free/cheap op inventory); it adds the **binary op-count** axis
those files only touch obliquely.

---

## 0. The answer up front

| op | (a) native ternary cost | (b) binary emulation cost | (c) the honest note |
|---|---|---|---|
| **TGRAD** `∇F=(div,curl)` | **6 signed adds** (div 3 + curl 3) @ 8 trits = 48 `tadd1`; 0 shifts/÷ | **6 signed adds** @ 12-bit (div, curl each ≤ ±1456); 0 shifts/÷; + pod lookup (shared) | the reduction is **identical** in both bases. TGRAD has **no ÷ anywhere**, so the ÷3/÷9 win does *not* apply — its only ternary edge is the free isotropic pod, and even that is radix-independent (see §2). |
| **TRECON** `∇⁻¹J` (gauge-fixed) | **0 adds** — wire demux (`div→ω⁰`, `curl→ω¹`, rest 0) + a 4-trit fit check | **0 adds** — same demux + fit check; only the 7 write-back addresses (pod) differ | TRECON is a **scatter, not a reduction**: it is free in *both* bases. The ternary/binary gap on arithmetic is **nil**. |
| **TRELAX** `u'=u/3+Σnb/9` | **6 adds** (5 reduction @ 8 trits + 1 update @ 6 trits) = 46 `tadd1`; **÷3, ÷9 = free trit-shifts (0 gates)** | **6 adds** (5 reduction @ 13-bit + 1 update @ 10-bit); **÷3, ÷9 = real binary division ≈ 4–6 extra ops**; + pod lookup (shared) | the reduction is **identical** (6 adds). The ternary win here is the two **free shifts**: binary pays ~4–6 ALU ops of genuine division for what ternary does with zero gates (§3). |

The **pod lookup** is the one shared cost not visible in the per-op rows. It is computed **once**
per pod and feeds all three ops — exactly how `rtl/hex_field_accel.v` instantiates a single
`hex_pod_addr` and lets TGRAD/TRELAX/TRECON all gather from the same 224-bit `pod` bus [DIRECT,
`hex_field_accel.v` L55–71]. Quantified in §2.

---

## 1. The shared baseline: the reduction is 6 signed adds in BOTH bases

Both TGRAD and TRELAX are, at their core, a **6-neighbor signed sum**, and that sum is the same
arithmetic in binary and ternary:

- **TGRAD** — `div = F0−F2−F3+F5` (4 terms → 3 adds), `curl = F1+F2−F4−F5` (4 terms → 3 adds).
  Total **6 signed adds**. The center cell drops out (`Σωᵏ = 0`, the additive gauge) [DIRECT,
  `grad_recon.v` L25–33; `FieldCalculus.lean` `div6`/`curl6`/`div_curl_shift_invariant`].
- **TRELAX** — `Σnb = n0+n1+n2+n3+n4+n5` (6 terms → 5 adds in a tree) + one update add
  (`u/3 + Σnb/9`). Total **6 adds** [DIRECT, `trelax.v` L23–24, 50–64].
- **TRECON** — **0 adds**. It places `div` on ω⁰ and `curl` on ω¹ and zeroes the rest: a wire
  demux plus a 4-trit overflow fit check (`grad_recon.v` L139–152). The gauge-fixed section is
  exact and integer: `∇(TRECON J) = J` identically [DIRECT, `FieldCalculus.lean`
  `trecon_roundtrip`, `tgrad_trecon_tgrad`].

**What "the same" means and does not mean.** The *count* of adds is identical (6, 6, 0). The
*per-add* cost is not: the balanced-ternary full adder `tadd1` is measured at **1.92× the energy
and 3.31× the transistors** of a binary full adder, while binary needs wider words (12–13 bits vs
8 trits for the full-range reduction) — so the net reduction is **≈ parity to ~1.5× worse for
ternary**, *not* a win [DIRECT, `trelax_measured.md` §5.2]. The honest statement the principal
asked for stands: **the reduction is 6 signed adds in both bases; ternary does not win on it.**

---

## 2. The pod lookup — the address-space cost, and the "is it shared?" answer

This is the cost the question is really about: which 6 cells are the neighbors of a given hex
address, and does the binary machine have to *compute* them.

**Native ternary (Eisenstein `(a,b)` addressing).** The 6 neighbors are the unit translations
`z + ωᵏ`, `k = 0..5`, with the fixed offset table `{(1,0),(0,1),(−1,1),(−1,0),(0,−1),(1,−1)}`
[DIRECT, `grad_recon.v` L16–23; `HexIsotropy.lean` `neighbors`, `neighbors_card`]. The lookup is
**isotropic — 6 uniform `+unit` neighbors, no offset correction** — and costs 6×2 = **12 axial
adds**, no square root, no pairing [DIRECT, `hex_encode.v` `hex_neighbor` L112–113;
`eisenstein_free_ops.md` §1c].

**Binary emulation (flat u32 / Szudzik addressing).** A flat binary address is *not*
translation-invariant: you cannot add the six offsets to the u32 directly. The RTL's own
`hex_pod_addr.v` shows the round trip the flat-address machine must pay [DIRECT,
`hex_pod_addr.v` L26–40; `hex_decode.v` L30–50; `hex_encode.v` L44–117]:

- **decode once:** 1 `isqrt` (restoring shift-and-subtract, ~16 serial stages — "the ONE
  non-trivial op in the whole datapath") + Szudzik unpair (1 16×16 square + compare + subtracts)
  + 2 sign-unfolds;
- **6 re-encodes** (one per neighbor): each = 2 axial adds + 2 sign-folds + 1 Szudzik pair
  (1 square + compare + 2 adds).

Counted: **~1 isqrt + ~6 squares + ~30 adds/compares ≈ 60–100 flat-address ALU ops** per pod
[DERIVED from the RTL]. Versus **12 adds** in the native frame. That ~5–8× address-arithmetic
multiplier *is* the "hex addressing overhead."

**Is it shared? — yes, in two senses, but neither erases it:**

1. **Shared across the three ops — YES.** One `hex_pod_addr` instance serves TGRAD, TRECON and
   TRELAX together (`hex_field_accel.v` L55–71). Run all three on one pod and the ~60–100-op
   lookup amortizes to ~20–33 ops each; run TGRAD alone and you eat the whole lookup. [DIRECT]
2. **Shared with ternary (i.e., free in both) — NO, but not for a radix reason.** The offset
   *table* is identical in both bases; the *computation* differs. In flat u32 space binary must
   isqrt + Szudzik-pair its way in and out of `(a,b)`; in axial `(a,b)` space it is 2 adds per
   neighbor — and **a binary CPU that stores axial `(a,b)` coordinates gets the same free
   isotropic pod** [DIRECT, `eisenstein_free_ops.md` §1c/§2d: the pod win is *radix-independent*].
   The hex-addressing overhead is a **flat-address-vs-axial-coordinate** cost, *not* a
   binary-vs-ternary cost. The repo's binary host pays it only because it indexes cells through
   the Szudzik u32 bijection.

**Honest pod verdict:** the isotropic pod (6 uniform `+unit` neighbors, no row-parity/offset
correction) is a *real* structural win of the hex lattice — but it is a **coordinate-system** win,
capturable by a binary axial-coordinate store, and the ternary radix contributes nothing to it.
The ~60–100-op flat-address overhead is charged to the *addressing scheme*, and it is shared
(once per pod) across the three ops, never re-paid per op.

---

## 3. The ÷3 / ÷9 shift saving — the one genuine *ternary* (radix) win

TRELAX is `u' = u/3 + Σnb/9`, the α=2/3 under-relaxed Jacobi step: `u + (1/9)(Σnb − 6u) =
u/3 + Σnb/9` [DIRECT, `trelax.v` L6–11; `FieldCalculus.lean` `trelax`]. The two coefficients are
`3⁻¹` and `3⁻²`:

| divisor | ternary | binary | saving |
|---|---|---|---|
| `u / 3` | **1-trit right shift** — `u1 = {00, u[2W−1:2]}` — pure wire re-wiring, **0 gates** [DIRECT, `trelax.v` L61] | **÷3**: multiply by reciprocal `⌈2ᵏ/3⌉` + shift + sign correction ≈ **2–3 ALU ops**, or a restoring divider of ~10–13 serial stages | ~2–3 ops → 0 |
| `Σnb / 9` | **2-trit right shift** — `sum[2W+3:4]` — **0 gates** [DIRECT, `trelax.v` L62] | **÷9**: one reciprocal-multiply + shift ≈ **2–3 ops**, or ÷3 twice ≈ **4–6 ops** | ~2–3 (4–6) ops → 0 |

**Per TRELAX step, binary pays ~4–6 extra ALU ops of genuine division** for the two shifts
ternary performs for zero gates. This is the *only* place in the whole trio where the ternary
**radix** (as opposed to the hex geometry) actually wins: `3⁻¹` and `3⁻²` are digit-shifts in
base 3, but are non-power-of-2 divisions in base 2.

**One honest caveat (the binary workaround).** A binary machine *can* recover shift-only updates
by re-tuning α so both coefficients are powers of two — e.g. α=3/4 gives `u' = u/4 + Σnb/8`
(shift, shift). But that is a **different damping factor** (different convergence rate, different
stencil weights), not the specified TRELAX. The ternary's α=2/3 with free ÷3/÷9 is the *natural*
under-relaxed step that stays exact and division-free; binary either pays the divisions or
changes the algorithm. [DERIVED]

---

## 4. The calibration summary

| claim | calibration |
|---|---|
| div = F0−F2−F3+F5, curl = F1+F2−F4−F5 (TGRAD) | DIRECT (`grad_recon.v`; `FieldCalculus.lean` `div6`/`curl6`) |
| TRECON = gauge-fixed section, 0 arithmetic, exact round-trip | DIRECT (`grad_recon.v`; `FieldCalculus.lean` `trecon_roundtrip`) |
| TRELAX = u/3 + Σnb/9 (α=2/3 fold) | DIRECT (`trelax.v`; `FieldCalculus.lean` `trelax`) |
| TGRAD = 48 `tadd1`, TRELAX = 46 `tadd1` (6 adds each) | DIRECT (`grad_recon.v` L61–64; `trelax.v` L23–24) |
| ÷3, ÷9 = free ternary trit-shifts | DIRECT (`trelax.v` L10–11, 61–62; `TernaryCrt.div3_truncation`) |
| ternary FA = 1.92× energy / 3.31× T of binary FA; reduction ≈ parity to 1.5× worse | DIRECT (`trelax_measured.md` §2, §5.2) |
| pod lookup = 1 isqrt + 6 re-encodes ≈ 60–100 flat-address ops | DIRECT structure (`hex_pod_addr.v`/`hex_decode.v`/`hex_encode.v`); DERIVED count |
| native pod = 12 axial adds, isotropic, no offset correction | DIRECT (`hex_encode.v` `hex_neighbor`; `HexIsotropy.lean` `neighbors_card`) |
| binary ÷3/÷9 ≈ 2–3 ALU ops each (reciprocal multiply) | DERIVED (standard constant-division; not synthesized) |
| pod lookup shared once per pod across the three ops | DIRECT (`hex_field_accel.v` L55–71, single `hex_pod_addr` instance) |
| the hex-addressing overhead is flat-address-vs-axial, radix-independent | DIRECT (`eisenstein_free_ops.md` §1c, §2d) |

---

## 5. One line

**Where the ternary advantage actually is in field calculus:** *nowhere in the reduction — the
div/curl and the 6-neighbor sum are six signed adds in binary exactly as in ternary (and at ≈
parity cost, given the measured 1.92× ternary full-adder) — but in the two free ÷3/÷9 trit-shifts
(~4–6 real binary division ops saved per TRELAX step) and the isotropic pod (6 uniform +unit
neighbors with no offset correction, which is a hex-geometry win, radix-independent, and shared
once per pod across TGRAD/TRECON/TRELAX).*

---

## Sources

- `rtl/grad_recon.v`, `rtl/trelax.v`, `rtl/hex_pod_addr.v`, `rtl/hex_decode.v`,
  `rtl/hex_encode.v`, `rtl/hex_field_accel.v` — the datapaths and the device counts.
- `proofs/lean-src/hexagon/Hexagon/FieldCalculus.lean`, `Pod.lean`, `HexIsotropy.lean` — the
  proved div/curl/recon/relax/pod/isotropy facts.
- `docs/compute/field_calculus/trelax_measured.md` — measured `tadd1`/`bin_fa` (1.92×/3.31×/4.33×),
  the 1.2–1.5×-worse reduction verdict, the "÷3/÷9 = free shift" DIRECT.
- `docs/compute/address_space/eisenstein_free_ops.md` — the radix-independent free-op inventory
  (rotation/neighbor/pod), the flat-vs-axial honesty.
- `docs/compute/address_space/instruction_footprint.md`, `operation_cost.md` — the sibling
  address-space classification and sense-cost axes this file complements.
