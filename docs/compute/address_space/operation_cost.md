# Operation Cost in Address-Space Terms

**2026-08-30.** The average cost per Tau instruction, priced the way the principal
asked for: **address-space cost** — how many hex addresses an instruction touches, how many of
those are free address-arithmetic (rotation/negation/neighbor) vs actual READ (sense) operations,
and how many trits of namespace it occupies. No per-bit energy anywhere.

Sources of truth: `scripts/gen_program_tau.py` (the 35-instruction SoC program),
`scripts/xlattice.py` (GA ops), `scripts/demo.py` (field calculus), `scripts/hexaddr.py`
(address bijection), `rtl/program_tau.hex` + `rtl/tau_soc_tb.v` (the running program),
`docs/GA_INSTRUCTIONS.md`, `docs/TAU_RISCV_STATUS.md`, `docs/NAMESPACE_TABLE.md`,
`docs/FINAL_VERDICT.md`, `docs/compute/eisen_opcode.md`.

Calibration legend: **DIRECT** = proved/measured in-repo; **OURS** = design parameter of this
cost model (stated, with sensitivity).

---

## 0. The answer, up front

> **The average Tau instruction costs ~4.7 address-sense units (register/GA op) and
> ~17.2 units (pod/field op), of which ~93% is the 2-threshold READ+WRITE tax (charged on every
> operand read *and* every value write), ~7% is cheap arithmetic, and 0% is rotation/negation/
> neighbor to *compute* — but their output still pays the write tax. The binary engine doing the
> same work is **cheaper on sense-work (~1.3–1.6×)**, not tied — because a binary read *and* a
> binary write each cost 1.0 vs the ternary 2.0 — and it needs 1.52× the address digits (32 bits
> vs 21 trits) and pays explicit logic for negation and the ÷3/÷9 division. The Eisenstein win is
> *not* in the reads — reads *and* writes both cost the tax — it is in the free address ops, the
> free negation, and the 21-vs-32-trit namespace.**

> **CORRECTIONS APPLIED (from `bench_adversarial.md`):** (i) "32 bits vs 12 trits = 2.67×"
> conflated the *operand* width (12 trits = 24 bits, holding 3¹² = 531,441 values ≈ 19.02 bits
> of information) with the *address* width (the u32 box). The correct comparisons are **address**
> = 21 trits vs 32 bits = **1.52×** (34% fewer symbols) and **value** = 12 trits vs ~19.02 bits =
> 1.585× per symbol; 2.67× (= 8/3) is the *transport energy* ratio, not a namespace ratio. All
> tables below now print 1.52×/1.585×. (ii) The register-write read tax is now charged: a
> register-file write lands a 3-level value exactly as a cell store does, so it pays READ_COST
> like a read. This flips the old "ternary ties binary on sense" conclusion to **binary beats
> ternary ~1.3–1.6× on compute (read+write tax)**; the symbol saving (~1.5×) and the free
> address ops are unchanged.

The single number the principal asked for:

| instruction class | ternary sense-cost | binary sense-cost | namespace (ternary vs binary) |
|---|---:|---:|---|
| register / GA op | **4.7 units** (~93% read+write tax) | ~3.5–6.5 units | 21 trits vs 32 bits (**1.52×**) |
| pod / field op (TGRAD·TRELAX·TRECON) | **17.2 units** (~93% read+write tax) | ~12–17 units | 84 trits vs ~133 bits (**1.585×**) |

---

## 1. The cost model

```
cost(op) = (# reads + # writes) · READ_COST + (# free address ops) · 0 + (# cheap arithmetic ops) · CHEAP
           + (namespace trits in play)
```

### 1.1 The constants

| constant | value | meaning | calibration |
|---|---:|---|---|
| **READ_COST** | **2.0** | the 2-threshold tax: sensing **or landing** one ternary value = 2 threshold discriminations (3-level resolve) vs 1 for binary. Charged on every operand read **and every value write** (register-file write, cell store). Normalized so **1.0 = one binary read/write**. | **DIRECT** (`ThresholdLowerBound.lean` 2/log₂3 = 1.26/bit is the *per-bit* form; the *per-sense* form is exactly 2 thresholds vs 1 — FINAL_VERDICT.md correction 4/5: "2 decisions", "3-level SNR margin forces ~2×"). |
| **CHEAP** | **0.5** | one cheap arithmetic op (norm/conjugate/dot/wedge = one combinational cone over already-sensed trits; no new address touched). = ¼ READ_COST = one binary threshold. | **OURS**. Sensitivity: doubling CHEAP 0.5→1.0 moves the GA average 4.70→5.00 (+6.4%) and the pod average 17.17→18.33 (+6.8%); ranking never changes. |
| **free** | **0** | rotation (TROT = ω^k unit-multiply, a re-index), negation (per-trit wire swap, carry-free), neighbor (`z + ω^k` unit-add). | **DIRECT** semantics (`GA_INSTRUCTIONS.md` §"geometric product is the multiply"; `grad_recon.v` "per-trit wire swap, carry-free"; `hexaddr.py` `neighbor`). RTL caveat §1.3. |
| **namespace trits** | count | the width of the address/value the instruction occupies, in trits (ternary) or bits (binary). | **DIRECT** (`NAMESPACE_TABLE.md`; WORD6 = 6+6 = 12 trits; WORD8 = 16 trits). |

### 1.2 What each term prices

- **READ (and WRITE)** = *sensing or landing a value*: one address touch that must resolve the
  stored value (read) or resolve/land a 3-level value into storage (write). Both pay the
  2-threshold tax. A register operand read, a cell gather, a cell store, **and a register-file
  write (`rd` destination)** all touch an address and resolve/land a 3-level value → each =
  READ_COST. The write side is the correction applied here: the old draft waived the tax on
  register writes while charging it on cell stores (TRECON); a written ternary value is sensed
  exactly as a read one is, so it pays the same 2.0.
- **Free address ops** = the three Eisenstein unit operations. They *move you in the address
  space without sensing anything*: rotation is re-indexing the same 12-trit word, negation is a
  wire swap, neighbor is adding a unit vector. Cost 0 by construction.
- **Cheap arithmetic** = norm/conjugate/dot/wedge (and add/sub). They combine values already in
  registers — no new address, no sense — so they cost a small constant, not the tax.
- **Namespace trits** = the address-width footprint, reported in trits. This is the *second axis*:
  it is not a sense cost, it is how many symbols the instruction's address occupies. Ternary and
  binary are compared on it directly: **21 trits vs 32 bits** for the u32 address box (1.52×), or
  **12 trits vs ~19.02 bits** for the value information (1.585×).

The two axes (sense-work and namespace) are reported separately below because the principal's
question "where does the advantage show up" is answered by *contrasting* them, not by adding
them.

### 1.3 Honest caveat on "free neighbor"

In the **Eisenstein-native** frame (cell = `(a,b) ∈ ℤ[ω]`), the neighbor is literally the unit
add `z + ω^k` — free. The *current* RTL backs cells with u32 Szudzik addresses, so
`hex_pod_addr.v` realizes the neighbor as decode (one `isqrt`) + 6 offset adds + 6 re-encodes —
a combinational block, not literal zero logic. The cost model prices the Eisenstein-native frame
(the principal's stated premise); if you re-price the neighbor at the hex_pod_addr combinational
cost, the pod-op free term goes 0 → ~6·CHEAP, which is already inside the "cheap arithmetic"
column and does not change the conclusion (reads still dominate). Flagged, not hidden.

---

## 2. Pricing the actual instruction mix

### 2.1 The Xlattice instruction set (13 ops) — per-op price

`reads` counts address touches (operand senses + cell gathers); `writes` counts value landings
(register-file destinations + cell stores). `free` = rotation/negation/neighbor units (0 to
compute, but the written output still pays 2.0). `cheap` = norm/conj/dot/wedge/add cones (TMUL =
3, it is three scalar balanced multipliers — `eisen_opcode.md` §3). sense-work = `2·(reads +
writes) + 0.5·cheap` (free adds 0).

| op | reads | writes | free | cheap | namespace | sense-work |
|---|--:|---:|---:|--:|---:|---:|
| LDI (imm) | 0 | 1 | 0 | 0 | 12 trits | 2.0 |
| TROT (rotate ω^k) | 1 | 1 | 1 | 0 | 12 | 4.0 |
| TCONJ (conjugate) | 1 | 1 | 1 (neg) | 1 | 12 | 4.5 |
| TNORM (norm) | 1 | 1 | 0 | 1 | 12 | 4.5 |
| TADD | 2 | 1 | 0 | 1 | 12 | 6.5 |
| TSUB | 2 | 1 | 1 (neg) | 1 | 12 | 6.5 |
| TDOT | 2 | 1 | 0 | 1 | 12 | 6.5 |
| TWEDGE | 2 | 1 | 0 | 1 | 12 | 6.5 |
| TSYMDOT | 2 | 1 | 0 | 1 | 12 | 6.5 |
| TMUL | 2 | 1 | 0 | 3 | 12 | 7.5 |
| TGRAD (pod·rd) | 7 | 1 | 6 (neighbor) | 6 | 84 (7×12) | 19.0 |
| TRELAX (pod·rd) | 7 | 1 | 6 | 1 | 84 | 16.5 |
| TRECON (pod·wr) | 1 | 7 (stores) | 6 | 0 | 84 | 16.0 |

Two observations that fall straight out of the table:

1. **Register ops are READ+WRITE-dominated** — every 2-operand GA op is 4.0 read-units + 2.0
   write-units of a 6.5 total (~92%). The only thing that ever changes the price is the
   read+write count; free ops are 0 to compute and cheap arithmetic is a rounding error.
2. **Pod ops are the expensive ones** — a TGRAD is 7 senses + 1 write (16.0 of tax) versus 3.0 of
   cheap arithmetic. The engine's actual "∇F = J" work costs ~3–4× a register GA op, and ~93% of
   that is reading *and writing* the pod, not computing the derivative.

### 2.2 The GA program actually run (`scripts/xlattice.py` `main()`)

15 instructions: LDI×4, TROT×2, TADD×2, TCONJ×2, TDOT×1, TWEDGE×2, TSYMDOT×2.

| quantity | total | per instruction |
|---|---:|---:|
| reads | 18 | 1.20 |
| writes | 15 | 1.00 |
| cheap ops | 9 | 0.60 |
| free ops | 4 | 0.27 |
| **sense-work** | **70.5** | **4.70 units** |
| — READ share | 36.0 | 51.1 % |
| — WRITE share | 30.0 | 42.6 % |
| — read+write tax share | 66.0 | 93.6 % |
| — cheap share | 4.5 | 6.4 % |
| — free share | 0 | 0 % |
| namespace | 180 trits | 12 trits |

**Average GA instruction = 4.70 sense-units, 93.6% of which is the READ+WRITE tax (51.1% reads,
42.6% writes), 6.4% cheap, 0% free; 12 trits of namespace.**

### 2.3 The field-calculus program (`scripts/demo.py`)

3 pod ops: TGRAD (19.0), TRECON (16.0), TRELAX (16.5).

| quantity | total | per instruction |
|---|---:|---:|
| reads | 15 | 5.00 |
| writes | 9 | 3.00 |
| cheap ops | 7 | 2.33 |
| **sense-work** | **51.5** | **17.17 units** |
| — READ share | 30.0 | 58.3 % |
| — WRITE share | 18.0 | 35.0 % |
| — read+write tax share | 48.0 | 93.2 % |
| — cheap share | 3.5 | 6.8 % |
| namespace | 252 trits | 84 trits |

**Average pod instruction = 17.17 sense-units, 93.2% READ+WRITE (58.3% reads, 35.0% writes),
6.8% cheap; 84 trits of namespace.**

### 2.4 The SoC host program (`scripts/gen_program_tau.py`, 35 instructions)

This is the *binary* PicoRV32 glue that drives the ternary peripherals through memory-mapped
registers: `lui`×2, `addi`×5, `sw`×17, `lw`×10, `beq`×1 (35 total — matches `rtl/program_tau.hex`).
Each `lw`/`sw` touches one 32-bit binary address → 1.0 each (the core is binary, **no** 2-threshold
tax); `lui`/`addi`/`beq` touch no address.

| quantity | total | per instruction |
|---|---:|---:|
| address touches | 27 | 0.77 |
| **sense-work** | **27.0** | **0.77 units** |
| namespace | 35×32 = 1120 bits | 32 bits |

The binary host is cheap per-instruction (0.77) *because* it offloads all the ternary sense to
the peripheral: the 7-cell gather and the 2-threshold resolve happen inside `hex_field_accel`
when a `sw`/`lw` lands on `0x2000`, not in the host instruction. The host number is glue, not the
engine's work — which is exactly the architectural claim (compute stays binary; ternary lives in
the address/memory subsystem).

---

## 3. The binary equivalent of the same workload

A binary engine doing the same field-calculus/GA/neighbor work pays:

**(a) more address digits** — one Eisenstein word is 12 trits = 3¹² = 531,441 values = 19.02 bits
(information), which an RV32 binary engine carries in a **32-bit** register (1.68× waste over the
information floor; 1.585× the 12-trit info width). A 7-cell pod = 84 trits vs 7×19.02 = 133 bits.

**(b) explicit rotation/negation/neighbor** — no free unit-multiply. In binary, a 60° rotation of
`(a,b)` in **axial coordinates** is the *same* `{0,±1}` matrix — 1 add + a 2's-complement negate
(≈ tie with ternary; only the increment differs). Only in **Cartesian** `(x,y)` form is it
*irrational* (√3/2 → 4 mul + 2 add, not exact). Negation is a 2's-complement; a hex neighbor is
an explicit `(a+da, b+db)` add (or a Szudzik unpair + add + repack). Each free ternary op becomes
~1 binary cheap op — a small, not decisive, difference.

**(c) cheaper reads *and* writes** — the binary engine still senses the same 2 operands / 7
cells, but each binary read = 1.0 (one threshold) where the ternary read = 2.0 (the tax), and
each binary write = 1.0 where the ternary write = 2.0. So on reads+writes the binary engine is
2× cheaper — and it is exactly this saving (not the address logic) that makes binary win.

Representative side-by-side (sense-work = `(reads+writes)·READ_COST + cheap·CHEAP`):

| workload | ternary | binary | notes |
|---|---:|---:|---|
| TDOT (2-operand dot) | 2·2.0 + 1·2.0 + 1·0.5 = **6.5** | 2·1.0 + 1·1.0 + ~5–7·0.5 = **5.5–6.5** | binary adds explicit conjugate + 3 mul/2 add |
| TGRAD (7-cell ∇) | 7·2.0 + 1·2.0 + 6·0.5 = **19.0** | 7·1.0 + 1·1.0 + ~12–18·0.5 = **14–17** | binary adds explicit neighbor arithmetic + div/curl |
| namespace (word) | **21 trits** | **32 bits** | 1.52× more symbols (address) |
| namespace (pod) | **84 trits** | **~133 bits** | 1.585× more symbols (value info) |

The conclusion is the whole story, and it is honest:

- **Binary beats ternary on sense-work (~1.3–1.6×)** once the read tax is charged on *both* reads
  and writes. The ternary 2-threshold tax is *not* cancelled by the free rotation/negation/
  neighbor — binary buys cheap reads *and* cheap writes, while the free address ops only save the
  ~1 cheap op per transform. (Binary's reads+writes win; ternary's address arithmetic wins; the
  totals land ~1.3–1.6× in binary's favor.)
- **Ternary wins the namespace axis outright** — 21 vs 32 symbols per word (1.52×), 84 vs 133 per
  pod (1.585×). This is the `log₃2 = 0.6309` radix economy and the `(3/2)ⁿ = 1.86×10¹¹` at n=64
  that the whole architecture exists for (`NAMESPACE_TABLE.md`, `TAU_ARCHITECTURE.md`).

**Where the Eisenstein advantage actually shows up:** nowhere in the reads or writes (both pay the
tax — the ternary read/write is 2× a binary one); it shows up in **(i) the free address ops**
(rotation/negation/neighbor cost 0 to compute vs binary's ~1 cheap op each — but the landed output
still pays the write tax), **(ii) the free negation** (0 gates vs invert+increment), and **(iii)
the namespace** (21 trits vs 32 bits = 1.52× fewer symbols, compounding to an exponential at
width).

---

## 4. The average-cost answer (one table)

The principal's question, answered directly:

| question | answer |
|---|---|
| average cost per instruction (ternary, register/GA) | **4.70 sense-units** — 93.6% READ+WRITE (2-threshold tax on reads and writes), 6.4% cheap, 0% free |
| average cost per instruction (ternary, pod/field) | **17.17 sense-units** — 93.2% READ+WRITE, 6.8% cheap, 0% free |
| binary equivalent, same workload | ~3.5–6.5 (GA) / ~14–17 (pod) sense-units — **~1.3–1.6× cheaper** (reads and writes both cost 1.0) |
| namespace per word | **21 trits vs 32 bits (1.52×)**; pod 84 vs ~133 bits (1.585×) |
| where the win is | free rotation/negation/neighbor (compute), free ÷3/÷9, and the 21-trit namespace — **not** the reads or writes |

**One line:** the average Tau instruction costs **~4.7 units (GA) / ~17.2 units (pod)**, and
~93% of that is the 2-threshold READ+WRITE tax, with rotation/negation/neighbor free only to
*compute* (their output still pays the write tax) — so the ternary engine **loses ~1.3–1.6× to
binary on total sense-cost** while carrying the same logical address in **21 trits instead of 32
bits**, which is where its advantage (the `3ⁿ` namespace) actually lives.
