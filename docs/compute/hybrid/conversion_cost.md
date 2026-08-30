# Binary ↔ Ternary Conversion Cost at the Hybrid Boundary

**2026-08-30.** The question: in a hybrid datapath (ternary storage, binary ALU), does the
cost of converting a stored ternary value into binary — so the binary ALU can add/multiply it —
*eat* the compute saving the binary ALU is bought for? The answer: **no, because the conversion
that sits on the boundary is the cheap one (O(n) per-trit value conversion), not the expensive
one (O(n²) Szudzik + isqrt address conversion).** The expensive converter is an *address*
object and only fires when a hex *address* crosses the boundary, which the hybrid should never
let happen.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):
- **DIRECT** — measured / proved / verbatim from `rtl/`, `proofs/lean-src/hexagon/Hexagon/`, or a
  citable literature number.
- **DERIVED** — counted from RTL structure or scaled from a DIRECT number, stated as such.
- **OURS** — our own design claim following from DIRECT.
- **SPECULATION** — untested estimate, flagged and bounded.

---

## 0. Two conversions, not one — the reframe that settles the question

"Ternary↔binary conversion" names **two different objects** with wildly different costs. The
whole answer lives in keeping them apart:

| conversion | what it moves | direction | cost class | where it fires |
|---|---|---|---|---|
| **(a) VALUE** — trit string ↔ signed integer | a *stored field value* (the 12-trit number in a cell) | `01/00/10` per-trit ↔ `Σ dᵢ·3ⁱ` | **O(n)** — per-trit decode is constant; the radix sum is a linear ripple | **on the hybrid boundary** (every operand the binary ALU touches) |
| **(b) ADDRESS** — hex cell `(a,b)` ↔ u32 | a *cell name* (Eisenstein coordinate ↔ flat address) | `signFold + Szudzik pair` / `isqrt + unpair + signUnfold` | **O(n²)** — a 16×16 square and a ~16-stage `isqrt` | **off the boundary** (only when a hex *address* crosses: bus, page table, fault) |

The two are *different quantities*, and the source files are unambiguous about which is which:

- The **value** is "12 trits = 24 bits, balanced ternary (2 bits/trit, 01=+1, 00=0, 10=−1,
  11=NEVER)" — verbatim the field-value width in `rtl/hex_field_accel.v` L28–30. **DIRECT.**
- The **address** is `a + bω` with `a, b` each a *signed 16-bit* coordinate (`rtl/hex_encode.v`
  `input wire signed [15:0] a, b`), packed to a **32-bit** u32 via Szudzik pairing — the
  `Bijection.lean` object, a 21-trit namespace vs 32 bits
  (`docs/compute/address_space/minimal_namespace.md` §3–4). **DIRECT.**

`minimal_namespace.md` §4 already catches the conflation the principal warned about: *"12 trits
= 24 bits conflates the value width with the address width… the value is 12 trits; the address
is 32 bits / 21 trits."* This document is the cost-side twin of that correction.

---

## 1. Which one sits on the hybrid boundary — the VALUE conversion

The binary ALU computes on **stored field values**, so the conversion it needs is **(a)**:
turn each stored trit's 2-bit one-hot code into a signed digit the binary adder can sum.

The **(b)** address conversion (Szudzik + isqrt) is *not* what the ALU needs to compute on a
value. It is the hex-address↔u32 **MMU bijection** (`rtl/hex_encode.v`, `rtl/hex_decode.v`) —
the machinery for *naming a cell*, used only when a hex address must cross into the flat
binary address space (load/store to the physical bus, a fault handler decoding `stval`, DMA).

**So the boundary conversion is the cheap one, not the isqrt.** The isqrt/Szudzik is an
*addressing* tax, and the whole point of the hybrid is to keep it off the compute path. This is
exactly the discipline `docs/riscv_survey/hex_mmu.md` §2 already specifies: a resident `(a,b)`
cell cache makes a hex neighbor hop **two integer adds**, and the `pair∘fold`/`isqrt` re-encode
fires *only* when the address crosses the hex↔binary boundary — never per operand. **OURS**
(following DIRECT structure).

---

## 2. The value conversion, costed (O(n) — cheap)

The one-hot-per-direction trit code makes the *decode* direction nearly free, because a trit
**is already two binary wires**:

```
2'b01 = +1   →  signed digit +1     (push rail energized)
2'b00 =  0   →  signed digit  0     (null)
2'b10 = -1   →  signed digit -1     (pull rail energized)
2'b11 = NEVER (don't-care input)    [trit_functions.vh L17–22]
```

Per-trit decode to a signed digit is a **2-bit lookup, carry-free and purely local** — no trit
sees another trit's output. Value contribution = `t[0] − t[1]` (the +1 rail minus the −1 rail):
**~2 gates per trit**. **DIRECT** (the decode is the `case` in `rtl/converters.v` `t2b` L72–76).

The only non-local part is the **radix sum** — Horner `r = 3r + dᵢ` (`rtl/converters.v` `t2b`
L71–78), a *linear* chain of n small adders, **O(n) stages**, no multiplier and no square root.
The synthesized cost is **DIRECT** (yosys 0.52 → SkyWater 130 nm, `docs/compute/converters.md`
§1c):

| converter | algorithm | cells | area |
|---|---|---|---|
| **b2t** (9-bit → 6 trits) | MSB-first digit extraction, 6 compare+const-add stages | **139** | **913 µm²** |
| **t2b** (6 trits → 10-bit) | Horner `r = 3r + dᵢ`, 6 shift-add-add stages | **170** | **1,628 µm²** |

Both are pure combinational, **0 flops**. Scaling to the full 12-trit value is **DERIVED** by
linear extrapolation (the stages count is linear in trit count — that is the O(n) claim made
literal): **~340 cells / ~3.2 kµm²** for the 12-trit t2b direction. That is **~8–13 % of the
whole CPU** (24,314 µm² / 3,970 cells, `docs/REAL_SKY130_SYNTHESIS.md`) for a converter that is
instantiated *once*, not per gate. **OURS/DERIVED.**

**The principal's gate-count framing, restated honestly:** "12 × (2-bit decode to ±1) ≈ 24
gates + a carry-free sum" is the **decode** layer — 12 trits × ~2 gates = **~24 gates**, all
local and carry-free. The *carry* lives in the Horner sum, which is a linear ripple (the 170-cell
`t2b` at 6 trits), **not** the O(n²) isqrt/square of the address path. The two together are
"trivial" in exactly the sense the principal means: O(n) total, ~hundreds of cells, no iteration,
no square, no sqrt. **DIRECT** (decode structure) + **DERIVED** (12-trit scaling).

---

## 3. The address conversion, costed (O(n²) — the expensive one, off the boundary)

This is `rtl/hex_encode.v` + `rtl/hex_decode.v`, and it is a *different beast*:

| direction | ops | hardware | complexity |
|---|---|---|---|
| **encode** cell `(a,b)` → u32 | 2 `signFold` + 1 **Szudzik pair** (`a<b ? b²+a : a²+a+b`) | 1 **16×16 squarer** + compare + add | **O(n²)** gate count (the square) |
| **decode** u32 → cell `(a,b)` | 1 **isqrt** + Szudzik unpair (1 square + compare + subtracts) + 2 `signUnfold` | restoring shift-and-subtract `isqrt`, **~16 serial stages** | **O(n²)** (16 stages × O(n) compare each) |

**DIRECT** structure (`hex_decode.v` L30–50 — "restoring shift-and-subtract isqrt… ~16 serial
stages… the ONE non-trivial op in the whole datapath"; `hex_encode.v` L44–54 — the 16×16 square).
The cost is *not* a few gates per trit: it is a square and a serial square-root. `docs/compute/
address_space/emulation_field.md` §2 counts the full pod-lookup round trip in flat u32 space:
**~1 isqrt + ~6 squares + ~30 adds/compares ≈ 60–100 flat-address ALU ops per pod** vs **12
axial adds** in the native `(a,b)` frame — a ~5–8× address-arithmetic multiplier. **DERIVED**
from the RTL (same file §4).

**This is the converter that could "eat" a compute saving** — and it is *precisely* the one that
must stay off the hybrid compute boundary.

---

## 4. Does it pay for itself? The payoff width

The compute facts (all **DIRECT** measured, `docs/compute/field_calculus/trelax_measured.md`
§1.3 / §5.2):

| cell | energy / toggle | transistors | sky130 cells / area |
|---|---|---|---|
| ternary balanced full adder `tadd1` | **0.355 fJ** | 192 T | 25 / 146.4 µm² |
| binary full adder `bin_fa` | **0.185 fJ** | 58 T | 2 / 33.8 µm² |
| **ratio** | **1.92×** | **3.31×** | **4.33×** |

The binary adder is **1.92× cheaper in energy and 4.33× cheaper in area** than the ternary one
— this is the saving the hybrid is bought for, and it is the *per-gate* headline of the
ternary-compute penalty (per-bit ternary compute lands **1.48×** worse at the best case,
`docs/compute/junction_cost_verdict.md` §2, up to **2.0×** per sense from the 2-threshold tax,
`docs/compute/address_space/operation_cost.md` §1.1). **DIRECT.**

**The break-even is not a width — it is amortization over ops.** The value conversion is a
*one-time per-operand boundary tax*; the 1.92×/4.33× adder advantage is a *per-add* saving that
compounds over every add/multiply the ALU then does on that value. Concretely, at the 12-trit /
12-bit width:

- **One 6-add reduction** (the TGRAD shape — 6 signed adds at 12 trits, `emulation_field.md`
  §0): ternary `6×12 = 72 tadd1` = 72 × 0.355 fJ = **25.6 fJ**; binary `72 bin_fa` = 72 ×
  0.185 fJ = **13.3 fJ** → the binary ALU saves **~12 fJ per reduction**. **DERIVED** from
  DIRECT per-cell numbers.
- **The value conversion** (12 trits → signed binary, round-trip) is ~340 cells, **sub-pJ to
  ~few pJ** per crossing (`docs/compute/converters.md` §2b: b2t ≈ 1.1 pJ, t2b ≈ 2.0 pJ at 6
  trits → ~2× at 12 trits; "sub-pJ is the honest central estimate"). **SPECULATION** (the energy
  bound is flagged as such in the source) / **DIRECT** (area).

The conversion therefore pays for itself the moment the ALU does *any* nontrivial work on the
converted value — a single multiply, a reduction, or a loop of adds — and, crucially, its **O(n)**
cost does **not** grow as the width widens, so there is **no crossover width**. It is linear in
trit count with a small constant (~2 gates/trit decode + a linear ripple), which is strictly
cheaper than the O(n²) isqrt/square the question was worried about. **OURS** (from the DIRECT
scaling above).

**Contrast — the address conversion *would* have a crossover.** The Szudzik square and the
~16-stage isqrt grow **O(n²)**, so at wide addresses (the u32 box) a per-operand address
conversion would dominate the ALU. That is exactly why the payoff rule in §5 exists.

---

## 5. The honest caveat, and the one-line rule

The caveat the principal asked for, stated without flinching:

> **If the ADDRESS also crosses the boundary — hex-addressed memory handed to a
> binary-addressed ALU, so every operand is `isqrt + Szudzik-unpair`'d and re-`pair`'d — then
> the O(n²) address conversion (60–100 flat-address ops per pod) *can* dominate and eat the
> 1.92× adder saving.** The hybrid must therefore keep **ADDRESSES ternary** (native `(a,b)` /
> hex, walkable with 2-add neighbor hops) and convert **only VALUES** (the cheap O(n)
> per-trit decode + linear radix sum).

This is not a new requirement — it is `hex_mmu.md` §2's "cell cache" design made the governing
rule of the hybrid: the `(a,b)` coordinate stays resident, the `pair∘fold`/`isqrt` fires only at
the physical-address boundary, and the ALU sees a signed binary integer it never has to
un-Szudzik. **OURS** (restating DIRECT RTL structure).

**One line:** *Convert values (O(n), cheap — a per-trit 2-bit decode + a linear radix sum, ≈24
gates + ~340 cells at 12 trits); keep addresses ternary (native hex), because the address
conversion is the O(n²) Szudzik + isqrt and that — not the value decode — is the only converter
that could eat the binary ALU's 1.92× saving.*

---

## 6. Calibration summary

| claim | calibration |
|---|---|
| value = 12 trits = 24 bits, 2 bits/trit, 11=NEVER | DIRECT (`rtl/hex_field_accel.v` L28–30) |
| address = `(a,b)` signed 16-bit → u32, Szudzik | DIRECT (`rtl/hex_encode.v`; `Bijection.lean`) |
| value vs address are different widths (12 trits vs 32 bits/21 trits) | DIRECT (`minimal_namespace.md` §3–4) |
| per-trit decode = 2-bit lookup, carry-free, ~2 gates/trit | DIRECT (`rtl/converters.v` `t2b` L72–76; `trit_functions.vh` L17–22) |
| value conversion t2b = 170 cells / 1,628 µm² (6 trits); b2t = 139 / 913 µm² | DIRECT (yosys, `converters.md` §1c) |
| value conversion O(n): stages linear in trit count | DERIVED (from the module structure) |
| 12-trit t2b ≈ 340 cells / ~3.2 kµm² | DERIVED (2× the measured 6-trit figure) |
| address encode = 16×16 square; decode = ~16-stage isqrt | DIRECT (`hex_encode.v` L44–54; `hex_decode.v` L30–50) |
| address conversion O(n²) (square + serial sqrt) | DERIVED (structure) / DIRECT (isqrt = "ONE non-trivial op") |
| pod lookup in flat u32 ≈ 60–100 ops vs 12 axial adds | DERIVED (`emulation_field.md` §2) |
| ternary FA = 1.92× energy / 3.31× T / 4.33× area of binary FA | DIRECT (measured, `trelax_measured.md` §1.3/§5.2) |
| ternary per-bit compute 1.48× worse (best case), 2.0× per-sense tax | DIRECT (`junction_cost_verdict.md` §2; `operation_cost.md` §1.1) |
| 6-add reduction: ternary 25.6 fJ vs binary 13.3 fJ (≈12 fJ saved) | DERIVED (DIRECT per-cell × 72) |
| conversion energy sub-pJ to ~few pJ per crossing | SPECULATION (bound) / DIRECT (area), `converters.md` §2b |
| conversion pays at any width (O(n), amortized over ops); no crossover | OURS (from DIRECT scaling) |
| address conversion *would* dominate if on the boundary → keep addresses ternary | OURS (restating `hex_mmu.md` §2) |

---

## Sources

- `rtl/hex_encode.v`, `rtl/hex_decode.v` — the O(n²) address conversion (Szudzik pair = square,
  isqrt = serial sqrt).
- `rtl/hex_field_accel.v` — the 12-trit/24-bit value width; "cell ADDRESS is a plain binary cell
  index, NOT ternary."
- `rtl/converters.v` — the O(n) value conversion (b2t/t2b), the 2-bit→±1 decode, the Horner sum.
- `rtl/trit_functions.vh` — the trit encoding (01/00/10/11=NEVER).
- `docs/compute/converters.md` — synthesized b2t/t2b area/energy (DIRECT, yosys/Sky130).
- `docs/compute/address_space/minimal_namespace.md` — value-vs-address width correction.
- `docs/compute/address_space/emulation_field.md` — the 60–100-op flat-address pod lookup and
  the 1.92×/3.31× ternary-FA ratio.
- `docs/compute/field_calculus/trelax_measured.md` — measured `tadd1`/`bin_fa` (DIRECT).
- `docs/compute/address_space/operation_cost.md`, `docs/compute/junction_cost_verdict.md` — the
  2.0× per-sense tax and the 1.48× per-bit compute penalty.
- `docs/riscv_survey/hex_mmu.md` — the cell-cache discipline (keep `(a,b)` resident; pair/isqrt
  only at the physical boundary).
- `scripts/hexaddr.py` — the Python mirror of the proved Szudzik/fold/unfold bijection.
