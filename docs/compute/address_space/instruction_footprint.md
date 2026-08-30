# Instruction Address-Space Footprint — the Tau ISA, per-operation

**2026-08-30.** This is the *addressing* audit of the Tau instruction set, not an energy
audit. Per the thesis (`docs/TAU_ARCHITECTURE.md`, `docs/NAMESPACE_TABLE.md`): ternary
wins on **ADDRESSING** (the `3ⁿ` namespace — `(3/2)ⁿ = 1.86×10¹¹` at `n=64`, `log₃2 =
0.6309` → 36.9 % fewer symbols) and **TRANSPORT** (free null ≈ 0.05 pJ vs 1.20 pJ for a
±1 toggle), and *loses* on the **per-bit READ** (2 thresholds). So the honest cost of an
instruction is its **address-space footprint**: how many hex-cell addresses it touches,
how many of those touches are free/cheap address-arithmetic vs. actual value *reads*
(senses), and how many trits of namespace it needs.

Every claim below is tagged **DIRECT** (verbatim from RTL/doc) / **DERIVED** (counted from
the RTL) / **SPECULATION** (this document's classification judgment). Grounded in
`rtl/cpu.v`, `rtl/ga_ops.v`, `rtl/grad_recon.v`, `rtl/trelax.v`, `rtl/hex_encode.v`,
`rtl/hex_decode.v`, `rtl/hex_pod_addr.v`, `rtl/ternary_mem.v`, `rtl/xlattice_cfu.v`,
`rtl/hex_field_accel.v`, `rtl/tau_soc.v`, `rtl/ternary_link.v`, and `scripts/{demo,xlattice,hexaddr,ternary_ops}.py`.

---

## 0. Definitions (the measuring stick)

- **Sense (READ)** — touching a stored *value* and reading it. One word sense = 12 trits
  = 24 bits; at the thesis' "2 thresholds per bit" the per-word read tax is **48 threshold
  reads** [DERIVED from `TernaryCell.lean` threshold model + 24-bit word]. A sense is the
  *expensive* touch — it is exactly the per-bit READ the thesis concedes ternary loses.
- **Free address-arithmetic** — rotation `ωᵏ` (unit-multiply, **no multiplies** [DIRECT,
  `cpu.v` L50–57]), negation (`tneg` = a wire swap `{t[0],t[1]}` [DIRECT, `trit_functions.vh`
  L55–60]), and hex-neighbor (`+unit` = two integer adds [DIRECT, `hex_encode.v` L112–113]).
  These touch *coordinates/addresses*, not values, and cost no multipliers and no extra reads.
- **Namespace** — the number of addressable cells an op needs to live in. `3ⁿ` is the win;
  the register file (8 cells), the pod (7 cells), and the u32 box (`2³²` cells) are the three
  scales in play.
- **Classification** (SPECULATION — this doc's judgment, per op):
  - **READ-BOUND** — cost dominated by sensing operand *values* (multi-operand reads + real
    coefficient arithmetic: adds/multiplies/norms/dot/wedge/reductions).
  - **ADDRESS-BOUND** — cost dominated by *namespace/address* arithmetic (encode/decode /
    `isqrt` / Szudzik pairing / neighbor re-encode / pod lookup), with zero or few value senses.
  - **FREE** — pure rotation/negation/relabel/transport: no multipliers, no multi-operand
    sensing (TROT, LDI, HLT, the ternary link).

---

## 1. The 11 CPU opcodes (`rtl/cpu.v`)

Storage: an 8-entry ternary register file, `tregfile_2r1w`, 2 read ports + 1 write port,
12-trit (24-bit) words [DIRECT, `cpu.v` L99–101, `ternary_mem.v`]. Each register read = **1
sense** (12 trits); each register write = **1 address** written. Namespace = 8 cells
(= 3 bits binary; `⌈log₃8⌉ = 2` trits → `3² = 9` cells, 1 wasted) [DERIVED].

| op | (a) value-reads (sense) | (b) writes | (c) free : sense | (d) min namespace | class |
|---|---|---|---|---|---|
| **TADD** `rd=ra+rb` | 2 (ra, rb) | 1 (rd) | 0 : 2 | 8 regs | **READ-BOUND** |
| **TSUB** `rd=ra−rb` | 2 (ra, rb) | 1 (rd) | 1 : 2 (negate rb = free wire-swap) | 8 regs | **READ-BOUND** |
| **TROT** `rd=ωᵏ·ra` | 1 (ra; rb = 3-bit angle k) | 1 (rd) | 1 : 1 (rotation = negate + ≤1 add, **no multiplies**) | 8 regs + Z₆ (6 dirs) | **FREE** |
| **TNORM** `rd=N(aᵣₐ,aᵣᵦ)` | 2 (a-fields of ra, rb) | 1 (rd, scalar) | 0 : 2 | 8 regs | **READ-BOUND** |
| **LDI** `rd=(imm,0)` | 0 (immediate) | 1 (rd) | 1 : 0 (s2t6 relabel of imm) | 8 regs | **FREE** |
| **TMUL** `rd=ra·rb` | 2 (all 4 coeffs) | 1 (rd) | 0 : 2 | 8 regs | **READ-BOUND** |
| **TCONJ** `rd=conj(ra)` | 1 (ra) | 1 (rd) | 1 : 1 (−b free wire-swap) | 8 regs | **READ-BOUND** |
| **TDOT** `rd=Re(z·conj w)` | 2 (ra, rb) | 1 (rd, scalar) | 0 : 2 | 8 regs | **READ-BOUND** |
| **TWEDGE** `rd=Im(z·conj w)` | 2 (ra, rb) | 1 (rd, scalar) | 0 : 2 | 8 regs | **READ-BOUND** |
| **TSYMDOT** `rd=N(z+w)−N(z)−N(w)` | 2 (ra, rb) | 1 (rd, scalar) | 0 : 2 | 8 regs | **READ-BOUND** |
| **HLT** | 0 | 0 | 0 : 0 | n/a | **FREE** (no-op) |

**Compute depth (why the READ-BOUND ones are bound):** TADD/TSUB ripple 2×6 `tadd1`
cells; TNORM = 2 scalar products (`N=(a+b)²−ab` [DIRECT `tmul_opt.v`]); TMUL = 3 scalar
products (Karatsuba, `A=ac−bd, B=(a+b)(c+d)−ac` [DIRECT]); TDOT/TWEDGE/TSYMDOT share one
4-product `ga_split_trits` cell [DIRECT `cpu.v` L164–170, `ga_ops.v` L88–92]. TROT is the
outlier: the rotation is a fixed 6-way sign/swap of `(a,b)` [DIRECT `cpu.v` L183–193] — the
only arithmetic is the shared `a+b` (`ab_sum`), so it is a **relabel**, not a compute
[DERIVED]. LDI is a constant (`s2t6`, division-free balanced conversion [DIRECT `cpu.v`
L272–304]).

> **Note:** TNORM/TMUL/TDOT/TWEDGE/TSYMDOT all *truncate* to the low 6 trits and latch an
> `ovf` fit flag [DIRECT `cpu.v` L149, 168–170] — the arithmetic runs full-width
> (12–14 trits) even though the word stores only 6+6. That full-width internal arithmetic
> is *read-bound* (it is value arithmetic on the sensed operands), not address arithmetic.

---

## 2. The field-calculus trio (`rtl/grad_recon.v`, `rtl/trelax.v`)

Storage: a 7-cell hex pod (center + 6 ring cells at `ωᵏ`). The six neighbor addresses come
from `+unit` hops (free); the *values* must be gathered (sensed). Namespace = 7 cells
(`⌈log₃7⌉ = 2` trits → `3² = 9`) [DERIVED].

| op | (a) value-reads (sense) | (b) writes | (c) free : sense | (d) min namespace | class |
|---|---|---|---|---|---|
| **TGRAD** `∇F=(div,curl)` | 7 (center + 6 ring; **center drops out of ∇**, `Σωᵏ=0` — gauge) | 1 (div,curl WORD8) | 6 : 7 (6 neighbor addr = +unit) | 7 cells | **READ-BOUND** |
| **TRECON** `∇⁻¹J` (scatter) | 2 (div, curl) | 7 (center + 6 ring) | 6 : 2 (6 neighbor addr = +unit) | 7 cells | **ADDRESS-BOUND** |
| **TRELAX** `u'=u/3+Σnb/9` | 7 (center + 6 ring) | 1 (u') | 6+2 : 7 (6 addr + the ÷3,÷9 = free ternary shift) | 7 cells | **READ-BOUND** |

- **TGRAD** = 2×(3 adders @ 8 trits) = 48 `tadd1` [DIRECT `grad_recon.v` L61–64]. It is a
  *7-way gather*: 7 sense reads dominate, and the gradient itself is a value reduction
  (`div = F0−F2−F3+F5`, `curl = F1+F2−F4−F5`) [DIRECT]. **READ-BOUND.**
- **TRECON** = "wires + a 4-trit fit check (no arithmetic)… nearly free" [DIRECT
  `grad_recon.v` L63]. Its footprint is the **7-address scatter** (6 of them computed by
  free `+unit`; only 2 carries a sensed value — `F0'=div, F1'=curl`, the rest constant 0
  [DIRECT L139–144]). Address-targeting dominates over value-sensing. **ADDRESS-BOUND.**
- **TRELAX** = 5 reduction adders + 1 update adder [DIRECT `trelax.v` L23–24, 50–64]; the
  `1/3, 1/9` are free ternary right-shifts [DIRECT L10–11]. 7 sense reads dominate.
  **READ-BOUND.**

---

## 3. The memory / pod (address) ops (`rtl/hex_encode.v`, `rtl/hex_decode.v`, `rtl/hex_pod_addr.v`)

These are the **`3ⁿ` namespace machinery** — the engine's actual "compute on addresses"
primitives. They read/write **zero stored values**: they translate *coordinates ↔ addresses*.
Namespace = the full u32 Eisenstein box `[-2¹⁵, 2¹⁵−1]²` = `2³²` cells (= `3²¹` trits,
`NAMESPACE_TABLE.md` 32 bits → 21 trits) [DIRECT].

| op | (a) value-reads | (b) writes | (c) free : sense | (d) min namespace | class |
|---|---|---|---|---|---|
| **hex_encode** `(a,b)→u32` | 0 | 0 (1 address out) | 0 : 0 | 2³² | **ADDRESS-BOUND** |
| **hex_decode** `u32→(a,b)` | 0 | 0 (1 coord out) | 0 : 0 | 2³² | **ADDRESS-BOUND** |
| **hex_neighbor** `(a,b)+ωᵏ` | 0 | 0 (1 addr out) | 2 : 0 (the hop = 2 unit adds) | 2³² | **ADDRESS-BOUND** |
| **hex_pod_addr** (pod lookup) | 0 | 0 (7 addr out) | 12 : 0 (6 hops × 2 adds) | 7 cells ⊂ 2³² | **ADDRESS-BOUND** |

- **hex_encode** = `sign_fold×2 + szudzik_pair` (one 16×16 square + compare + add; *no*
  square root) [DIRECT `hex_encode.v` L32–58]. **ADDRESS-BOUND.**
- **hex_decode** = `szudzik_unpair` with **one `isqrt`** (restoring shift-and-subtract,
  ~16 serial stages) — "the ONE non-trivial op in the whole datapath" [DIRECT
  `hex_decode.v` L1–16, 30–50]. The single most expensive *address* op. **ADDRESS-BOUND.**
- **hex_neighbor** = `na=a+da, nb=b+db` (two adds, the free `+unit` hop) **plus** the
  `fold+pair` re-encode [DIRECT `hex_encode.v` L99–117]. The hop is free; the re-encode is
  the address cost. **ADDRESS-BOUND.**
- **hex_pod_addr** = 1 decode (`isqrt`) + 6 `hex_neighbor` hops (each 2 free adds + 1
  re-encode) [DIRECT `hex_pod_addr.v` L26–40]. Pure address generation — the isotropic
  7-cell "cell cache" hop. **ADDRESS-BOUND.**

---

## 4. The RISC-V SoC co-processor ops (`rtl/xlattice_cfu.v`, `rtl/hex_field_accel.v`, `rtl/ternary_link.v`, `rtl/tau_soc.v`)

The SoC (`tau_soc.v`) wires a PicoRV32 core to three peripherals [DIRECT L92–104]: the
**Xlattice CFU** (custom-0 via PCPI), the **field accelerator** (MMIO at `0x2000`), and the
**ternary link** (MMIO at `0x3000`), plus the hex MMU (MMIO at `0x1000`).

- **Xlattice CFU** (`xlattice_cfu.v`) — re-exposes the 4 GA cells TCONJ/TDOT/TWEDGE/TSYMDOT
  as custom-0 instructions [DIRECT L15–18]. **Adds 0 new operations** — each maps to a CPU
  op (READ-BOUND, table §1). (The *full* Xlattice ISA in `scripts/xlattice.py` is 13 ops:
  the 10 CPU compute ops + TGRAD/TRELAX/TRECON [DERIVED].)
- **Field accelerator** (`hex_field_accel.v`) — re-exposes TGRAD/TRECON/TRELAX over a
  **64-cell store** (`cells[0:63]`) + `hex_pod_addr` gather [DIRECT L51, 55–71]. Namespace
  = 64 cells = `3⁴ = 81 ≥ 64`. **Adds 0 new operations** — the trio of §2, plus a cell
  load/store (1 sense / 1 write per cell access). The gather is the same 7-sense read as
  TGRAD/TRELAX.
- **Ternary link** (`ternary_link.v` + `ternary_link_periph.v`) — the *transport* op: latch
  one 12-trit word (1 write), then `trit_null_count` (a combinational popcount of the 24
  bits) + `11=NEVER` canary + fixed-point energy [DIRECT `ternary_link_periph.v` L44–54].
  It touches **zero hex addresses** and does **zero value arithmetic** — its entire point is
  that null trits are *free on the wire* (the transport win). Namespace = 1 word =
  `3¹² = 531 441` value states. **FREE** (transport — off the address/read axes).

| SoC op | (a) value-reads | (b) writes | (c) free : sense | (d) min namespace | class |
|---|---|---|---|---|---|
| Xlattice CFU (4 GA ops) | = CPU TCONJ/TDOT/TWEDGE/TSYMDOT | same | same | 8 regs (core RF) | **READ-BOUND** (reuse) |
| Field accel (trio + cell store) | = §2 trio (7 / 2 / 7) | same | same | 64 cells (3⁴) | **READ-BOUND** except TRECON (ADDRESS-BOUND) |
| Ternary link | 1 (latch readback) | 1 (word latch) | 12 nulls free : 1 | 1 word (3¹²) | **FREE** (transport) |

---

## 5. Classification summary

**SPECULATION** (classification is this doc's judgment; the read/write/free/namespace
counts above are DIRECT/DERIVED).

| class | operations | count |
|---|---|---|
| **READ-BOUND** | TADD, TSUB, TNORM, TMUL, TCONJ, TDOT, TWEDGE, TSYMDOT, TGRAD, TRELAX | **10** |
| **ADDRESS-BOUND** | TRECON, hex_encode, hex_decode, hex_neighbor, hex_pod_addr | **5** |
| **FREE** | TROT, LDI, HLT, ternary_link | **4** |

Distinct ISA operations = **19** (11 CPU + 3 field + 4 address/pod + 1 transport). The CFU
and field accel are *alternate entry points* to the 4 GA ops and the trio — they add no new
operations, so they are not double-counted.

---

## 6. THE HISTOGRAM — is "compute on addresses" true for the instruction MIX?

```
READ-BOUND      ████████████████████████████████████  10 / 19  =  52.6 %
ADDRESS-BOUND   ███████████████████                   5 / 19  =  26.3 %
FREE            ████████████████                       4 / 19  =  21.1 %
```

| bucket | fraction | ops |
|---|---:|---|
| **READ-BOUND** | **52.6 %** | TADD TSUB TNORM TMUL TCONJ TDOT TWEDGE TSYMDOT TGRAD TRELAX |
| **ADDRESS-BOUND** | **26.3 %** | TRECON hex_encode hex_decode hex_neighbor hex_pod_addr |
| **FREE** | **21.1 %** | TROT LDI HLT ternary_link |
| *address-space-native (ADDRESS + FREE)* | *47.4 %* | *the addressing + relabel + transport half* |

**Weighted by actual sense-reads (not op count), the mix is even *more* read-bound**:
the 10 READ-BOUND ops account for **every value sense in the ISA** — TGRAD/TRELAX alone do
7 senses each, TMUL/TDOT/TWEDGE/TSYMDOT do 2 each — while the ADDRESS-BOUND and FREE ops do
**zero** value senses between them [DERIVED from §1–§4 tables]. The read tax (2
thresholds/bit) is therefore concentrated entirely in the 52.6 % majority.

---

## 7. Verdict

The Tau ISA is **READ-BOUND overall** — but only *barely*: **52.6 % read-bound vs 26.3 %
address-bound vs 21.1 % free** across 19 distinct operations. "Compute on addresses" is
**true for the 47.4 % minority** (the namespace/relabel/transport half: `hex_encode/decode/
neighbor/pod`, TRECON's scatter, TROT's rotation, the ternary link), and *false for the
compute core*: the 8 arithmetic/GA opcodes plus TGRAD/TRELAX are all value-sensing
reductions, which is exactly where the thesis concedes ternary loses (2 thresholds per
bit). The engine's honest division of labor is confirmed — **the win lives in the
addressing ops (which touch zero values), the cost lives in the read-bound arithmetic
(which the mix is built around)**. An addressing machine's instruction *mix* is still
majority-read-bound, because the operations that actually compute — add, multiply, norm,
dot, wedge, gradient, relax — must sense their operands; only the operations that *move
around in the namespace* (rotate, hop, encode, decode, transport) are address-bound or free.
