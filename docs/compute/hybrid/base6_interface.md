# The Base-6 Boundary — the binary↔ternary encoding interface (2 trits ↔ 3 bits)

**2026-08-30.** The *encoding* layer of the hybrid interface. This file is one of the six
`docs/compute/hybrid/` siblings; it owns the **base-6 packing problem** — how a 2-trit (or
12-trit) ternary word is laid down onto binary wires, where the 9-vs-8 state mismatch lives,
which state is the error flag, and how the ternary-RAM → binary-ALU handoff datapath is wired.
It does **not** re-derive the value-vs-address *cost* split (that is `conversion_cost.md`'s job)
nor the per-op emulation table (`emulation_cost.md`) nor the hybrid-vs-pure-binary referee
(`hybrid_verdict.md`) — it cites them and stays at the encoding/boundary level.

**Calibration legend** (house standard): **DIRECT** = proved in Lean / measured (ngspice·yosys) /
verbatim from `rtl/`; **DERIVED** = counted from RTL structure or arithmetic on DIRECT numbers;
**OURS** = our design claim following from DIRECT; **SPECULATION** = untested estimate, flagged.

---

## 0. TL;DR (verdict up front)

**The base-6 boundary is "2 trits ≈ 3 bits" (3² = 9 states vs 2³ = 8 states), and it is the
*tightest* alignment the two radices ever have — but it does not *pack*: 9 > 8, so one of the
nine ternary states must be dropped or flagged.** That spare state is the **error canary**: the
valid 2-trit value `(+1,+1) = +4`, the one 2-trit value that overflows a 3-bit signed field.
The handoff the task names (`signFold → Szudzik → u32`, back via `isqrt → signUnfold`) is the
**address/coordinate** pack — O(n²) — and it is *not* what the compute boundary carries; the
compute boundary carries the **O(n) value pack** (b2t/t2b). Against the field-calculus reduction
(6 signed adds, ternary **1.2–1.97×** worse per the DIRECT anchors below), the O(n²) round-trip
(~40–50 ALU ops) is **~8× the penalty it would avoid and grows faster** — so it does **not** pay
as a "convert-to-binary-to-avoid-ternary-compute" move; it pays only as the *address* handoff at
the memory edge, kept off the operand path. The natural chunk is **6 = lcm(2,3)**: the 2-trit
group (radix 9) and the 3-bit group (radix 8) tile a common width, and the **4-bit/2-trit nibble**
is the waste-minimizing atom, not the 6-bit/3-trit sextet.

---

## 1. The base-6 encoding boundary

### 1.1 The trit code (DIRECT — `rtl/trit_functions.vh` L17–22)

One trit is **two binary wires**, one-hot-per-direction:

| 2-bit code | symbol | meaning |
|---|---|---|
| `01` | **+1** | push rail energized |
| `00` | **0** (null) | nothing energized |
| `10` | **−1** | pull rail energized |
| `11` | **NEVER** | both rails — forbidden, a per-trit canary |

Physical: N trits = **2N bits**. Logical: N trits = **3ᴺ states** = N·log₂3 ≈ **1.585N** info bits.
The whole base-6 story is the gap between "2N wires" and "1.585N bits": the 4th per-trit code
(`11`) is thrown away to buy a balanced radix, and that forfeit is the price of every ternary
win elsewhere.

### 1.2 The atom: 2 trits = 9 states, 3 bits = 8 states (DIRECT — proved)

The crossover the task cites is exact, and it sits at **n = 2**:

- `JunctionMemory.lean` `three_pow_gt_two_pow_succ`: **2ⁿ⁺¹ < 3ⁿ for n ≥ 2** — two or more trits
  out-address one-more-bit.
- `JunctionMemory.lean` `three_pow_lt_two_pow_succ_one`: **3¹ < 2²** — one trit does *not*.

So `3² = 9 > 2³ = 8` is the **first width where ternary beats binary even with binary's extra
digit of head start**, and `9/8 = 1.125` (12.5%) is the tightest capacity margin the two radices
ever have. `6 = lcm(2,3)` is the width at which the **2-trit group** and the **3-bit group** both
tile a whole number of times: **6 trits = 3 × (2 trits)**, and **6 bits = 2 × (3 bits)**. Over
that common width ternary yields `(3²)³ = 729` states and binary `(2³)² = 64` — the base-6
instance of the `(3/2)ⁿ` rail ratio (`three_pow_div_two_pow`), compounding `(9/8)ᴳ` per group.

### 1.3 The 9-vs-8 state map — where the canary lives

A 2-trit **balanced** value `t = 3·t₁ + t₀`, `tᵢ ∈ {−1,0,+1}`, ranges **−4 … +4** (9 values).
A 3-bit **signed** (two's-complement) field ranges **−4 … +3** (8 values). The exact mapping:

| 2-trit value | trit pair (t₁,t₀) | 3-bit signed image | note |
|---|---|---|---|
| −4 | (−1,−1) | `100` (−4) | exact |
| −3 | (−1, 0) | `101` (−3) | exact |
| −2 | (−1,+1) | `110` (−2) | exact |
| −1 | ( 0,−1) | `111` (−1) | exact |
|  0 | ( 0, 0) | `000` ( 0) | exact |
| +1 | ( 0,+1) | `001` (+1) | exact |
| +2 | (+1,−1) | `010` (+2) | exact |
| +3 | (+1, 0) | `011` (+3) | exact |
| **+4** | **(+1,+1)** | **none** | **the 9th state → error canary** |

**[OURS — the specific 2-trit↔3-bit table; the range −4..+4 vs −4..+3 is DIRECT arithmetic.]**
Three distinct "wasted" notions, kept apart so they are not conflated (the one error to avoid):

1. **Per-trit** (physical): `11` is the forbidden 4th code of each trit — 1 of 4 patterns per
   trit discarded. This is the *encoding* waste, charged 1.26× per bit (2 bits for log₂3 bits,
   `ThresholdLowerBound.lean`).
2. **Per-pair** (physical): 2 trits = 4 bits = **16 patterns**, of which **9 are valid** and
   **7 are never** (any trit = `11`). The 7 never-patterns are a free error-detection surface.
3. **Per-pair** (logical, 9→8): of the 9 *valid* values, **8 fit a 3-bit field and 1 does not**.
   That 1 is the **valid** value `(+1,+1) = +4` — *not* the `11` code. It is the "9th state that
   binary's 8 can't represent," and the task's instruction is exactly right: **use it as the
   error/overflow flag** (a 2-trit result that sums to `+4` is out-of-range for a 3-bit signed
   consumer, and the 7 `11`-carrying patterns are the *corruption* canary, detectable for free).

### 1.4 The 12-trit word (DIRECT — `control.md` §1c, `address_space_verdict.md` (a))

Word = **12 trits = 24 physical bits = an Eisenstein integer `a + b·ω`**, with `a, b` each a
**signed 6-trit** field (range ±(3⁶−1)/2 = **±364**). At the base-6 granularity the word is
**6 groups of 2 trits**: `9⁶ = 3¹² = 531,441` states. The container:

| width | states | info bits | smallest binary container | container waste |
|---|---:|---:|---:|---:|
| 2 trits | 9 | 3.170 | 4 bits (16) | 43.75 % |
| 6 trits (a or b) | 729 | 9.510 | 10 bits (1024) | 28.8 % |
| **12 trits (word)** | **531,441** | **19.020** | **20 bits (1,048,576)** | **49.3 %** |

`2¹⁹ = 524,288 < 531,441 < 2²⁰ = 1,048,576`, so the 12-trit word needs **20 bits**, and 20/12 =
**1.667 bits/trit** vs the 1.585 asymptotic — the finite rounding that produces the "1.67×" in
the field-accel bracket (§3). Note the deliberate two-framing the corpus keeps apart
(`address_space_verdict.md`): the **12-trit value word** is *not* the **u32/21-trit address box**;
the value is 12 trits (24 physical bits), the address is 32 bits / 21 trits. This file is about
the value word.

---

## 2. The ternary-RAM → binary-ALU handoff datapath

### 2.1 Two packs, one boundary (cross-ref `conversion_cost.md`)

The task names "ternary word → signFold → Szudzik → u32" as *the* converter. That is the
**address/coordinate** pack. It is not the only pack, and it is not the one the compute boundary
carries:

| pack | what moves | algorithm | cost | fires |
|---|---|---|---|---|
| **VALUE** | stored field value (12-trit number) ↔ signed integer | `tᵢ` decode + Horner `r = 3r + dᵢ` (`rtl/converters.v`) | **O(n)** — 139/170 cells | **every operand the binary ALU touches** |
| **ADDRESS** | Eisenstein cell `(a,b)` ↔ flat u32 | `signFold` + Szudzik pair / `isqrt` + unpair + `signUnfold` (`rtl/hex_encode.v`/`hex_decode.v`) | **O(n²)** — a 16×16 square + a ~16-stage isqrt | **only when a hex *address* crosses** (bus, fault, DMA) |

The rest of this section specifies the ADDRESS pack as the task asks; the VALUE pack's cost is
`conversion_cost.md` §2 (DIRECT: b2t 139 cells/913 µm², t2b 170 cells/1,628 µm², 0 flops).

### 2.2 Encode: ternary word → u32 (DIRECT — `rtl/hex_encode.v`)

```
(a, b)            the two 6-trit (here 16-bit) Eisenstein coordinates of the word
fa = signFold(a)  = a < 0 ? 2|a| − 1 : 2|a|        (Z → N, 0,1,−1,2,−2… ↦ 0,1,2,3,4…)
fb = signFold(b)
u32 = szudzik(fa,fb) = fa < fb ? fb² + fa : fa² + fa + fb     (Nat.pair / Szudzik)
```
Cost: 2 sign-folds (magnitude + conditional) + **1 16×16 square** + 1 compare + 2 adds. The
square is the O(n²) term (combinational n×n multiply).

### 2.3 Decode: u32 → ternary word (DIRECT — `rtl/hex_decode.v`)

```
s   = isqrt(u32)                     the ONE non-trivial op: restoring shift-and-subtract,
                                      ~16 serial stages, no multiplier ("hex_decode.v" L9)
s2  = s·s
(fx, fy) = u32 < s2 + s ? (u32 − s2, s) : (s, u32 − s2 − s)     (Nat.unpair)
a = signUnfold(fx)  = fx even ? fx/2 : −(fx+1)/2
b = signUnfold(fy)
```
Cost: **1 isqrt (~16 serial stages)** + 1 16×16 square + compare + subtracts + 2 sign-unfolds.

### 2.4 The round-trip cost (DERIVED)

A single operand round-trip (ternary word → u32 → consume → u32 → ternary word) is
**~1 isqrt + ~2 squares + ~10–15 adds/compares ≈ 40–50 flat-address ALU ops**. The full pod
(decode once + 6 neighbor re-encodes) is **~1 isqrt + ~6 squares + ~30 adds/compares ≈ 60–100
ops** vs **12 axial adds** in the native `(a,b)` frame — a ~5–8× address-arithmetic multiplier
(DIRECT structure / DERIVED count, `emulation_field.md` §2). The isqrt's `16 stages × O(n)
compare/subtract` = **O(n²)** bit operations is exactly the "~O(n²)" overhead the task names.

---

## 3. Does the O(n²) conversion pay for itself? (vs the 1.67–1.97× ternary penalty)

### 3.1 The compute penalty it "lets us avoid" (all DIRECT)

The field-calculus reduction (`TGRAD` div/curl, `TRELAX` stencil) is **6 signed adds in both
bases** (`emulation_field.md` §1). Ternary's penalty on those adds, with the DIRECT anchors:

| anchor | value | calibration |
|---|---|---|
| balanced full adder `tadd1` vs binary FA | **1.92× energy**, 3.31× transistors, 4.33× area | DIRECT (`trelax_measured.md` §1.3) |
| 6-trit ↔ 10-bit symbol ratio (10/6, 20/12) | **1.667×** | DIRECT (`crossover_curve.md` §3) |
| net per-cell TRELAX reduction vs binary adder tree | **1.2–1.5× worse** | DIRECT (`trelax_measured.md` §5.2) |
| word-level adder (6-trit vs 10-bit) | **3.94×/bit** | DIRECT (`word_fairfight.md`) |

The task's "**1.67–1.97× worse**" brackets exactly the symbol ratio (**1.667**) and the per-gate
energy (**1.92 ≈ 1.97**). The honest net for the *reduction itself* is **1.2–1.5×** (the 1.92×
per-gate is partly offset by binary needing 10 bits where ternary needs 6 trits). Either way the
penalty is a **constant ≤ 2× on a 6-add base**.

### 3.2 The comparison (DERIVED)

At the field-calc width (6 trits ≈ 10 bits):

- The reduction is **6 adds**. Ternary pays `6 × 1.92 = 11.5` binary-add-equivalents; binary pays
  `6`. The penalty avoided by "doing it in binary" is **~5.5 add-equivalents ≈ ~1 fJ**
  (6 × (0.355 − 0.185) fJ ≈ 1.0 fJ, from `trelax_measured.md` §2).
- The conversion round-trip is **~40–50 ALU ops** — an isqrt (16 serial stages) plus two squares
  plus ~a dozen adds/compares.

**The round-trip is ~7–8× the entire reduction and ~8× the penalty it would save**, and it is
**O(n²) against the reduction's O(n)**, so the gap *widens* with width. There is no field-calc
width at which a once-per-operand `isqrt + Szudzik` pays for skipping a 6-add ternary reduction.

### 3.3 The verdict, honestly

**No — the O(n²) conversion does not pay for itself as a "convert-to-binary-to-avoid-ternary-
compute" strategy, and it is not meant to.** Two separate truths, both required for the honest
answer:

1. **As compute avoidance: it loses, always.** The reduction is tiny (6 adds), its ternary penalty
   is a constant ≤ 2× (~1 fJ), and the O(n²) round-trip (~40–50 ops) is ~8× that penalty and grows
   faster. Converting also **throws away the two things ternary actually wins in field calculus**
   — the free `÷3/÷9` trit-shifts (~4–6 real binary divisions per TRELAX step) and the isotropic
   pod (`emulation_field.md` §2–3) — so a convert-to-binary strategy pays the conversion *and*
   forfeits the wins. [OURS, resting on DIRECT §3.1.]

2. **As the address handoff: it is the right cost, paid in the right place.** The `signFold +
   Szudzik + isqrt` path is the **MMU bijection**, not the value path. The hybrid pays it **once
   at the memory/address edge** (ternary RAM hands a flat u32 to the binary bus), never per
   operand in the compute loop — and the discipline that makes this automatic already exists:
   keep `(a,b)` resident, let the ALU consume the cheap **O(n) value pack** (b2t/t2b), and let
   `pair∘fold`/`isqrt` fire only when an *address* crosses (`hex_mmu.md` §2, `conversion_cost.md`
   §5). [OURS, restating DIRECT RTL structure.]

**One line:** *the base-6 handoff is two packs — the O(n) value pack that sits on the compute
boundary (and pays, because it is cheap against the 1.92× binary-ALU saving), and the O(n²)
address pack (`signFold → Szudzik → u32` / `isqrt → signUnfold`) that must stay off it — because
at the field-calculus width the O(n²) round-trip is ~8× the 6-add reduction's ≤2× ternary
penalty, and it only ever gets worse as the width grows.*

---

## 4. The 2×3 = 6 chunk — where the alignment minimizes waste

`6 = 2·3 = lcm(2,3)` is the natural chunk because it is the smallest width at which the **2-trit
group** (the ternary atom) and the **3-bit group** (the binary atom) each tile a whole number of
times. The two candidate byte-aligned chunks, costed:

### 4.1 The physical chunks (2 bits/trit)

| chunk | physical bits | logical states | valid / patterns | never-patterns | container waste |
|---|---|---:|---:|---:|---:|
| **4-bit (2-trit) nibble** | 4 | 9 | 9 / 16 | 7 | 43.75 % |
| **6-bit (3-trit) sextet** | 6 | 27 | 27 / 64 | 37 | 57.8 % |

The **4-bit/2-trit nibble is the waste-minimizing atom**: it is the crossover width itself
(2 trits = 9 > 2³ = 8), its 9th state is the canary (§1.3), and its 7 `11`-carrying patterns are
the corruption surface. The **6-bit/3-trit sextet is *not* minimum-waste** — it is only
byte-convenient (3 trits × 2 bits = 6 bits = half a 12-bit value).

### 4.2 The minimum-waste *logical* packings (DERIVED)

Waste = `(2^⌈N log₂3⌉ − 3ᴺ)/2^⌈N log₂3⌉`, the ceiling rounding on `⌈N log₂3⌉` bits:

| N trits | 3ᴺ | min bits ⌈N log₂3⌉ | container | waste |
|---:|---:|---:|---:|---:|
| 2 | 9 | 4 | 16 | 43.75 % |
| **3** | 27 | **5** | 32 | **15.6 %** |
| 4 | 81 | 7 | 128 | 36.7 % |
| **5** | 243 | **8** | 256 | **5.1 %** |
| 6 | 729 | 10 | 1024 | 28.8 % |
| 12 | 531,441 | 20 | 1,048,576 | 49.3 % |

The waste **oscillates** with the ceiling, and its minima are **3 trits → 5 bits (15.6%)** and
**5 trits → 8 bits (5.1%)** — *not* the 4-bit/6-bit byte chunks. Two consequences:

1. **If the boundary must be byte-aligned**, the 2-trit/4-bit nibble (43.75%) is the right granule
   — it is the crossover atom and it is *less* wasteful than the 3-trit/6-bit sextet (57.8%).
2. **If the goal is minimum waste**, pack 3 trits into a 5-bit field or 5 trits into a byte —
   i.e. do **not** let the 2-bit/trit physical code dictate the logical container.

### 4.3 What "minimizes waste" therefore means here (OURS)

The base-6 atom (**2 trits ≈ 3 bits**) minimizes *capacity* waste (9 vs 8, the tightest radix
margin there is) but not *container* waste (2 trits still need 4 bits because 9 > 8). The
minimum-container-waste packings are the **odd-trit** fields (3→5, 5→8), which the byte-aligned
4-bit/6-bit chunks can only approximate. So the honest chunk rule: **use the 2-trit nibble as the
boundary granule** (crossover + canary + corruption surface all live there), and when a value
must be emitted as a pure binary field, prefer a **5-bit (3-trit)** or **8-bit (5-trit)** container
over the 6-bit sextet.

---

## 5. One-sentence synthesis

**The base-6 boundary is "2 trits ≈ 3 bits" — the tight 9-vs-8 crossover (`three_pow_gt_two_pow_succ`
at n = 2), where the 9th state (`(+1,+1) = +4`) is the error canary and the per-trit `11=NEVER`
code is the corruption canary — and its handoff is *two* packs: the O(n) value pack (b2t/t2b,
139/170 cells) that sits on the compute boundary and pays for itself against the binary ALU's
1.92× adder saving, and the O(n²) address pack (`signFold → Szudzik → u32`, back via
`isqrt → signUnfold`) that must stay off it, because at the field-calculus width that ~40–50-op
round-trip is ~8× the 6-add reduction's ≤2× ternary penalty and it grows faster than the compute
it would avoid.**

---

## Calibration summary

| claim | calibration | source |
|---|---|---|
| trit code 01/00/10/11=NEVER, 2 bits/trit | DIRECT | `rtl/trit_functions.vh` L17–22 |
| 2ⁿ⁺¹ < 3ⁿ for n≥2; 3¹ < 2² (crossover at n=2) | DIRECT (proved) | `JunctionMemory.lean` `three_pow_gt_two_pow_succ`/`three_pow_lt_two_pow_succ_one` |
| 9 vs 8 = 1.125×; 6 = lcm(2,3); (9/8)ᴳ compounding | DIRECT + DERIVED | `crossover_curve.md`; `JunctionMemory.lean` `three_pow_div_two_pow` |
| 2-trit range −4..+4, 3-bit signed −4..+3; +4 = 9th state | DIRECT arithmetic | this file §1.3 |
| word = 12 trits = 24 bits = a+bω; a,b signed 6-trit ±364 | DIRECT | `control.md` §1c; `address_space_verdict.md` (a) |
| 12 trits = 3¹² = 531,441 states = 19.02 info bits → 20-bit container (49.3% waste) | DERIVED | `crossover_curve.md` §3 |
| address pack: signFold+Szudzik (square) / isqrt (16 serial) + unpair + signUnfold | DIRECT | `rtl/hex_encode.v`, `rtl/hex_decode.v` |
| address pack O(n²); single-operand round-trip ~40–50 ops; pod ~60–100 vs 12 axial adds | DERIVED | `emulation_field.md` §2 |
| value pack O(n): b2t 139/913 µm², t2b 170/1,628 µm², 0 flops | DIRECT | `converters.md` §1c |
| ternary FA = 1.92× energy / 3.31× T / 4.33× area of binary FA | DIRECT | `trelax_measured.md` §1.3 |
| net TRELAX reduction 1.2–1.5× worse; symbol ratio 1.667×; word adder 3.94×/bit | DIRECT | `trelax_measured.md` §5.2; `crossover_curve.md` §3; `word_fairfight.md` |
| "1.67–1.97×" brackets symbol ratio (1.667) and per-gate energy (1.92) | DERIVED | this file §3.1 |
| O(n²) round-trip ≈ 8× the 6-add reduction's ≤2× penalty | DERIVED | this file §3.2 |
| 4-bit/2-trit waste 43.75%; 6-bit/3-trit 57.8%; minima 3→5 bits (15.6%), 5→8 bits (5.1%) | DERIVED | this file §4 |

---

## Sources

- `rtl/trit_functions.vh` — the trit encoding (01/00/10/11=NEVER).
- `rtl/hex_encode.v`, `rtl/hex_decode.v` — the O(n²) address pack (signFold+Szudzik / isqrt+signUnfold).
- `rtl/converters.v` — the O(n) value pack (b2t/t2b).
- `proofs/lean-src/hexagon/Hexagon/JunctionMemory.lean` — `three_pow_gt_two_pow_succ`,
  `three_pow_lt_two_pow_succ_one`, `three_pow_div_two_pow` (the crossover and the (3/2)ⁿ ratio).
- `proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean` — the 1.26× 2-bit/trit encoding tax.
- `docs/compute/converters.md` — synthesized b2t/t2b area/energy (DIRECT).
- `docs/compute/field_calculus/trelax_measured.md` — measured `tadd1`/`bin_fa` (1.92×/3.31×/4.33×)
  and the 1.2–1.5× net reduction verdict.
- `docs/compute/word_fairfight.md` — measured adder/multiplier per-bit ratios.
- `docs/compute/address_space/emulation_field.md` — the 60–100-op flat-address pod lookup, the
  free ÷3/÷9 shifts, the isotropic pod.
- `docs/compute/address_space/crossover_curve.md` — the exact ⌈log₃N⌉ vs ⌈log₂N⌉ curve and the
  1.667 bits/trit word ratio.
- `docs/compute/address_space/address_space_verdict.md` — value (12 trits) vs address (21 trits/32
  bits) width distinction.
- Siblings: `docs/compute/hybrid/conversion_cost.md` (value-vs-address cost split),
  `docs/compute/hybrid/emulation_cost.md` (per-op emulation), `docs/compute/hybrid/hybrid_verdict.md`
  (hybrid vs pure-binary referee).
- `scripts/hexaddr.py` — the Python mirror of the proved fold/unfold/Szudzik bijection.
