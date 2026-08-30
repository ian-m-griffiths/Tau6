# Emulation Cost — what a binary ALU actually pays to emulate every Tau operation

**2026-08-30.** This is the consolidation. The per-op emulation costs live in four siblings —
`emulation_arithmetic.md` (add/mul/norm/conj/dot/wedge/symdot), `emulation_geometry.md`
(rotation/negation/neighbor/encode/decode/pod), `emulation_field.md` (TGRAD/TRECON/TRELAX) —
and the master table `energy-address-bench.md` prices the *energy* side. This file folds all of
them into **one verdict per op**, and states the point the others only gesture at.

> **Emulating ternary in binary is NOT expensive — it is often CHEAPER than doing it natively.**
> The 1.26–2× penalty everyone fears is on the *ternary* side: the 2-threshold read (`2·ln2/ln3 ≈
> 1.26×`/bit, `ThresholdLowerBound.lean`) plus the measured 1.72×/bit multiplier and 1.92×
> full-adder energy (3.94×/bit adder area). The only things binary emulation actually *loses* are
> (i) **free negation** — a +1 increment, (ii) the **÷3/÷9 free trit-shifts** — real division, and
> (iii) the **exact, lattice-closed 60° rotation** — which axial-coordinate binary gets for free
> anyway. So "binary emulation of ternary" is a **net win on energy**, at the cost of the nice ops
> (negation, ÷3, rotation) being marginally more code.

**Calibration legend** (repo convention, unchanged): **DIRECT** = read verbatim from RTL / proved
in Lean / measured (yosys/ngspice); **DERIVED** = arithmetic on DIRECT numbers. The binary column
is the *same integer polynomial re-counted over two's-complement coefficients* (the algebra does
not know the radix), priced against the **fair binary baseline** — axial coordinates for the hex
geometry, the shared Szudzik/isqrt for encode/decode, and the measured per-bit gate ratios from
`word_fairfight.md` / `trelax_measured.md`.

---

## 0. The one table — every Tau operation, one verdict

Verdict key:

- **TIE** — binary emulation is the same op count, no radix delta.
- **+ε** — binary pays a *small, specific* extra (the +1 increment, the ÷3/÷9 division, the parity check).
- **CHEAPER** — the op-count ties but the 1.72×/1.92× gate is on the *ternary* side, so binary wins per bit.
- **NATIVE** — not emulated; ternary keeps it because it wins here.

| operation | binary emulation (fair baseline) | verdict | the honest note |
|---|---|---|---|
| **TADD** `rd=ra+rb` | 2 adds, same polynomial | **CHEAPER** | Op-count **tie** (`0·2·0`); but the balanced adder is **3.94×/bit** the area of the binary ripple (`word_fairfight.txt`) — binary wins. |
| **TSUB** `rd=ra−rb` | 2 adds + 2 two's-complement negates | **CHEAPER** | Only real cost binary pays: **2 increments** (`-x = ~x+1` vs ternary's 0-gate `tneg` wire swap). The 3.94× adder still makes it cheaper net. |
| **TROT** `rd=ωᵏ·ra` | **axial:** 1 add + 1 negate | **TIE** | Axial binary applies the same `{0,±1}` matrix, exact in ℤ. The √3/closure gap exists **only** vs Cartesian `(x,y)` (4 M + 2 A + √3, not exact, not closed) — a strawman baseline, not the fair one. |
| **TNORM** `N=a²+ab+b²` | 2 mul + 1 add (`x²+y²`) | **CHEAPER** | Op-count tie via the ring-agnostic `(a+b)²−ab`; multiplier **1.72×/bit** on the ternary side. (Binary `x²+y²` is *not* the hex norm — it misses `+ab` — but that is an algebra gap, not a cost.) |
| **LDI** `rd=(imm,0)` | load-immediate | **CHEAPER** | 1 write = **1.0 u** vs ternary's **2.0 u** write tax (a 3-level value costs a 2-threshold land). |
| **TMUL** `rd=ra·rb` | Karatsuba, same 3 products | **CHEAPER** | Karatsuba is ring-agnostic (valid over ℤ); the Eisenstein form is *+1 add over complex* (`+bd` from `ω²=ω−1`), and the multiplier is **1.72×/bit** (shift-add) / 2.08× (Karatsuba) on ternary. |
| **TCONJ** `rd=(a+b,−b)` | **1 negate** | **CHEAPER** | Binary complex-conjugate is *less* work than Eisenstein's 1 add + 1 negate. The ternary edge is only the free `−b` (+1 increment). |
| **TDOT** `Re(z·conj w)` | 2 mul + 1 add (2D dot) | **CHEAPER** | Pure op-count tie (`3·2·0`), no negation anywhere; gate ratio → binary cheaper. |
| **TWEDGE** `Im(z·conj w)` | 2 mul + 1 sub (2D cross) | **CHEAPER** | Near-tie; the only delta is the free negate inside the sub (+1 increment). Gate ratio → binary cheaper. |
| **TSYMDOT** `N(z+w)−N(z)−N(w)` | same 4 products + 5 adds | **CHEAPER** | Shares its 4 products with dot/wedge **radix-independently** (`symdot = 2·dot + wedge`, `SymDot.lean`). The master table's "no integer analog" is about the *symmetric-polarization reading*, not the arithmetic (`4M+5A` both sides). |
| **HLT** | no-op | **TIE** | Nothing to emulate. |
| **TGRAD** `∇F=(div,curl)` | 6 signed adds, same reduction | **CHEAPER** | `div = F0−F2−F3+F5`, `curl = F1+F2−F4−F5` is 6 signed adds in **both** bases; the balanced full adder is **1.92× the energy / 3.31× the transistors** of binary (`trelax_measured.md`), and the ternary 7 reads + write pay 2.0 each. Ternary's only edge is the free isotropic pod (shared, see `hex_pod_addr`). |
| **TRECON** `∇⁻¹J` | same demux + fit check | **TIE** | A scatter, not a reduction — **0 adds in both bases**. The gauge-fixed section is exact and integer (`∇(TRECON J) = J` identically). |
| **TRELAX** `u'=u/3+Σnb/9` | 6 adds + **real ÷3, ÷9** | **+ε** | The reduction is identical (6 adds, binary *cheaper* per add), but ternary's `÷3`/`÷9` are **free trit-shifts (0 gates)** and binary pays **~4–6 real division ops** (or a non-terminating reciprocal). This is the *one* arithmetic op where emulation is genuinely more code — and it is still small. |
| **hex_encode** `(a,b)→u32` | same Szudzik pairing | **TIE** | The bijection is binary-native integer arithmetic; both sides pay the same 1 square + compare + add. |
| **hex_decode** `u32→(a,b)` | same isqrt + unpair | **TIE** | The restoring `isqrt` (~16 serial stages) dominates and is radix-neutral; the expensive direction for *both*. |
| **hex_neighbor** `(a,b)+ωᵏ` | 2 adds + **1 parity check** (odd-r offset) | **+ε** | Binary loses **isotropy**: 6 uniform `+unit` neighbors become 2 adds + a row-parity correction. ~1.3×, not a 10× strawman. |
| **hex_pod_addr** (7-cell pod) | decode once + 6×(2 adds + parity) + re-encode | **+ε** | The isotropic pod (12 uniform adds) is a *real* geometry win — but it is **coordinate-system, radix-independent**: a binary store that keeps axial `(a,b)` gets the same free pod. The ~60–100-op penalty is charged to **flat Szudzik addressing**, not to binary *per se*, and it is shared once per pod across TGRAD/TRECON/TRELAX. |
| **ternary_link** (transport) | same width, no null savings | **NATIVE** | The one place emulation does **not** reach parity: ternary's null-carrying link is **2.67× (low-swing) / 6.32× (natural)** the transport energy (`JunctionMemory.lean` `champion_vs_lowswing`/`champion_vs_natural`). Keep native. |

**Tally** (the punchline in one line): **10 CHEAPER** (TADD, TSUB, TNORM, LDI, TMUL, TCONJ, TDOT,
TWEDGE, TSYMDOT, TGRAD), **5 TIE** (TROT, HLT, TRECON, hex_encode, hex_decode), **3 +ε** (TRELAX,
hex_neighbor, hex_pod_addr), **1 NATIVE** (transport). The +ε bucket
is *exactly* the three losses the header names: negation's increment, the ÷3/÷9 division, and the
parity/isotropy correction.

---

## 1. The three buckets, read side by side

### (a) TIE — binary pays the same op count

The **shared-bijection and scatter ops**: hex_encode / hex_decode (Szudzik + isqrt are binary-native
integers already), TRECON (a wire demux, zero arithmetic in both), HLT (a no-op), and — against the
*fair* axial baseline — TROT (the same `{0,±1}` permutation, exact in both). Nothing here is a
ternary win, because nothing here *uses* the radix.

### (b) +ε — binary pays a small, specific extra

Exactly three things, all of them small and all of them already named in the sibling docs:

1. **Negation** — `tneg` is a 0-gate two-wire swap (`gate_tneg` = 0 cells, `gate_area.txt`);
   two's-complement pays `~x + 1`, i.e. **one ripple increment** per negate. It appears in TSUB,
   TCONJ, TWEDGE and the sign flips of TROT, and it is the single cleanest "ternary does it natively"
   fact in the whole ISA.
2. **÷3 / ÷9** — ternary right-shifts (`3 = 10₃`, pure wire re-wiring, `trelax.v` L10–11) are real
   division in base 2, **~4–6 extra ALU ops** per TRELAX step (or a non-terminating reciprocal).
   This is the only arithmetic op whose emulation is *not even exact* in ℤ.
3. **Isotropy** — hex_neighbor/pod's 6 uniform `+unit` neighbors become 2 adds + a row-parity check
   on a rectangular array. ~1.3×, and — per `emulation_field.md` §2 — it is a **coordinate** win
   (axial binary gets the isotropic pod too), not a radix win.

### (c) CHEAPER — the penalty is on the ternary side

Every **value-sensing arithmetic** op lands here, for one measured reason: the per-bit gate is
dearer in ternary. `word_fairfight.md` measures the adder at **3.94×/bit** and the multiplier at
**1.72×/bit**; `trelax_measured.md` measures the balanced full adder at **1.92× energy / 3.31×
transistors / 4.33× area**; `ThresholdLowerBound.lean` proves the read is **1.26×/bit**, and the
master table's adversarial correction #2 charges the same 2.0 on *writes*. Summed across the 19
ops, `energy-address-bench.md` §4 reaches the number that anchors this whole file: **binary beats
ternary ~1.3–1.6× on compute.** The emulation is *not* a burden — it is the cheaper path, and the
nice ternary ops (free negation, ÷3, rotation) are "marginally more code" precisely because they
are a handful of +1 increments and divisions riding on top of a datapath that is otherwise cheaper
in binary.

---

## 2. The honest point, spelled out

The question "what does binary emulation cost?" has an answer most people get backwards: **the cost
is negative.** "Emulate ternary in binary" reads like "pay extra to fake something you don't have
natively" — but here the thing being faked (balanced-ternary *compute*) is itself the more
expensive way to compute, because:

- **reading** a 3-level value takes 2 thresholds (1.26×/bit), and **writing** one re-pays that 2.0;
- **adding** it takes a balanced full adder at 1.92× the energy and 3.31× the transistors;
- **multiplying** it takes 1.72×/bit the area.

So the 1.26–2× "emulation penalty" is on the *native* side, not the emulation side. The emulation
loses three concrete things — a +1 increment per negation, ~4–6 divisions per TRELAX step, and one
parity check per neighbor — and all three together are smaller than what binary *gains* by using
the 1-threshold, 2-level datapath. The exact/lattice-closed rotation, the one qualitatively
different thing, is recovered for free the moment binary stores **axial `(a,b)` = ℤ[ω] in disguise**
instead of Cartesian `(x,y)`.

**The honest one-liner:** *binary emulation of ternary is a net win on energy; it costs only
marginally more code for the three "nice" ops (negation, ÷3, rotation), and it loses nothing else.*

---

## 3. What stays native vs what gets emulated

The split falls out of *where* the ternary advantage actually lives — it is in the **namespace and
the transport**, not in the arithmetic.

**KEEP NATIVE (ternary wins, emulation cannot reach parity):**

| keep native | why | calibration |
|---|---|---|
| **Transport** (`ternary_link`) | the null-carrying 12-trit link is **2.67×/6.32×** the transport energy of a binary symbol — a *measured physical* win, not an op-count one. | DIRECT (`JunctionMemory.lean` `champion_vs_lowswing` / `champion_vs_natural`) |
| **The isotropic pod lookup** (`hex_pod_addr`) | 6 uniform `+unit` neighbors, no offset correction, rotation-invariant. This is a *geometry* win — radix-independent (an axial-coordinate binary store gets it too) — so "keep native" means **keep the Eisenstein/axial addressing**, not necessarily the ternary radix. | DIRECT (`HexIsotropy.lean` `neighbors_card`; `hex_encode.v` `hex_neighbor`) |
| **The 3ⁿ namespace** | `21 trits vs 32 bits` (1.52×) for the u32 box, `12 trits vs 19.02 bits` (1.585×) for the value; compounding `(3/2)ⁿ`. This is a *storage/address* win binary cannot emulate at all — it is the whole reason to touch ternary. | DIRECT+DERIVED (`minimal_namespace.md`; `JunctionMemory.lean` `three_pow_gt_two_pow_succ`) |

**BETTER EMULATED (all the value-sensing arithmetic):**

| emulate in binary | why | calibration |
|---|---|---|
| **TADD / TSUB / TMUL / TNORM** | same integer polynomial, and the ternary adder/multiplier is 1.72–3.94×/bit dearer. | DIRECT (`word_fairfight.txt`) |
| **TCONJ / TDOT / TWEDGE / TSYMDOT** | same polynomial (and TCONJ is *less* work in binary); the products are shared radix-independently. | DIRECT (`emulation_arithmetic.md` §2/§5; `SymDot.lean`) |
| **TGRAD / TRELAX** | the 6-neighbor reduction is 6 signed adds in both bases, cheaper per add in binary; TRELAX's only genuine cost is the ÷3/÷9 (fold into a reciprocal-multiply, or re-tune α to a power of two). | DIRECT (`trelax_measured.md`; `grad_recon.v`) |
| **LDI** | a plain load-immediate; the ternary 2.0 write tax makes binary strictly cheaper. | DERIVED (`energy-address-bench.md` §0/§4) |
| **hex_encode / hex_decode** | already binary-native (Szudzik + isqrt) — nothing to emulate. | DIRECT (`Bijection.lean`; `hex_decode.v`) |

The resulting hybrid is exactly the read/write split `instruction_footprint.md` already found
(52.6% read-bound, 47.4% address/free): **run the value-sensing majority on the binary ALU, keep
ternary only for the namespace, the transport, and the isotropic hex addressing.** That is the
design "binary emulation of ternary" points at — and it is cheaper, not more expensive.

---

## 4. Calibration summary

| claim | calibration | source |
|---|---|---|
| 2-threshold read tax = 1.26×/bit (`2·ln2/ln3`), write tax 2.0 vs 1.0 | DIRECT (Lean) + DIRECT (correction) | `ThresholdLowerBound.lean` `ternary_binary_ratio`; `energy-address-bench.md` §0 |
| adder 3.94×/bit (3.74× raw), multiplier 1.72×/bit (shift-add) / 2.08× (Karatsuba) | DIRECT (measured) | `word_fairfight.txt` / `word_fairfight.md` |
| `tadd1` = 1.92× energy / 3.31× T / 4.33× area of `bin_fa`; mod-3 sum 1.42×/bit | DIRECT (measured) | `trelax_measured.md` §2; `energy-address-bench.md` §3 |
| `tneg` = 0 cells (wire swap) vs two's-complement invert+increment | DIRECT (measured) | `gate_area.txt` |
| ÷3/÷9 = free trit-shifts (0 gates) vs ~4–6 binary division ops | DIRECT (RTL) + DERIVED (count) | `trelax.v` L10–11, L61–62; `emulation_field.md` §3 |
| TROT = 1 add + free negate; axial binary = 1 add + negate (tie); Cartesian = 4 M + 2 A + √3 (not exact/closed) | DIRECT | `Gauge.lean`; `emulation_geometry.md` §3 |
| TGRAD/TRELAX = 6 signed adds in both bases (48/46 `tadd1`), TRECON = 0 adds | DIRECT | `grad_recon.v` L61–64; `trelax.v` L23–24 |
| pod = 7 cells, 6 uniform neighbors, rotation-invariant | DIRECT (Lean) | `HexIsotropy.lean` `neighbors_card`, `units_rotate_invariant` |
| flat-address pod overhead ~60–100 ops is addressing-scheme, radix-independent; shared once per pod | DIRECT structure + DERIVED count | `emulation_field.md` §2; `hex_pod_addr.v` |
| namespace 21/32 trits/bits (1.52×), 12/19.02 (1.585×); first strict win N=3 | DIRECT (Lean) + DERIVED | `minimal_namespace.md`; `JunctionMemory.lean` `three_pow_gt_two_pow_succ` |
| transport 2.67× (low-swing) / 6.32× (natural) | DIRECT (Lean) | `JunctionMemory.lean` `champion_vs_lowswing` / `champion_vs_natural` |
| binary beats ternary ~1.3–1.6× on compute (summed over 19 ops) | DERIVED (sum) | `energy-address-bench.md` §4 |

---

## Sources

- `docs/compute/address_space/emulation_arithmetic.md` — the M·A·N per-op table (ties + free-neg deltas).
- `docs/compute/address_space/emulation_geometry.md` — rotation/negation/neighbor/encode/decode/pod, axial fair baseline.
- `docs/compute/address_space/emulation_field.md` — TGRAD/TRECON/TRELAX, the shared pod, the ÷3/÷9 shift.
- `docs/compute/energy-address-bench.md` — the master 19-op energy/address table and the 1.3–1.6× compute verdict.
- `docs/compute/word_fairfight.md` / `rtl/word_fairfight.txt` — measured adder/multiplier per-bit ratios.
- `docs/compute/field_calculus/trelax_measured.md` — measured `tadd1`/`bin_fa` (1.92×/3.31×/4.33×).
- `docs/compute/gate_area.md` / `rtl/gate_area.txt` — `gate_tneg` = 0 cells.
- `docs/compute/address_space/minimal_namespace.md`, `eisenstein_free_ops.md`, `instruction_footprint.md` — namespace, free-op inventory, read/write split.
- `proofs/lean-src/hexagon/Hexagon/` (`ThresholdLowerBound.lean`, `Gauge.lean`, `HexIsotropy.lean`, `JunctionMemory.lean`, `SymDot.lean`, `Bijection.lean`) — the proved radix/geometry/namespace facts.
