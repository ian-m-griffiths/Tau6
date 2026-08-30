# Ternary CONTROL / Instruction Encoding — survey

**2026-08-29 — component survey: control layer (Wave 1, item 5 of
`docs/TERNARY_COMPUTE_SURVEY.md`).** The question: 3-level opcodes (ternary-native
control) vs binary-host encoding (our current approach in `rtl/cpu.v` — ternary
datapath, 16-bit binary instruction words). Covers decoder cost, opcode density
(3ⁿ vs 2ⁿ), what the ISA gains from native ternary control, and the tradeoff
between a ternary instruction word and binary-toolchain compatibility.

**Calibration legend:** **DIRECT** = measured/proved (math, RTL synthesis, or
documented hardware); **ANALOGY** = structural resemblance, not identity;
**OURS** = our design claim (follows from DIRECT, but not independently verified);
**SPECULATION** = untested hypothesis, flagged as such.

---

## 0. TL;DR verdict

**Keep binary-host control.** At the current scale (12 opcodes, 8 registers),
native ternary control buys almost nothing and costs more: it needs 2× the
decode thresholds per symbol (our Law-1 reframe, §2), it stores instruction
words *physically larger* because trits are 2 bits/trit in our encoding (§1),
and it throws away the binary toolchain (§4). The `cpu.v` split — **ternary
datapath + binary control** — is the correct hybrid. Ternary-native control
becomes worth re-examining only under three conditions, none of which hold
today (§5): a large register file / opcode space, a real ternary instruction
memory (3-level SRAM/DRAM — the "big open one"), or a ternary 3-way control
signal on the critical path.

---

## 1. Ternary-native vs binary-host: the two encodings already in the repo

The repo already contains **both ends of the spectrum**, which is what makes this
survey concrete rather than hypothetical.

### 1a. Binary-host (`rtl/cpu.v`) — [DIRECT, from source]

```
{op[3:0], rd[2:0], ra[2:0], rb[2:0]}        // RRR: 4+3+3+3 = 13 bits, padded to 16
{LDI = 4'h4, rd[2:0], imm[8:0]}              // LDI: 4+3+9 = 16 bits, 9-bit two's complement
```

- Instruction word: **16 binary bits**, stored in a standard binary ROM
  (`imem[0:IM_DEPTH-1]`, loaded by `$readmemh("rtl/program.hex")`).
- Opcode field: **4 bits = 16 slots**, 6 used (`0` TADD, `1` TSUB, `2` TROT,
  `3` TNORM, `4` LDI, `F` HLT).
- Register fields: 3 bits = 8 registers, **exact** (zero waste).
- Decode: a textbook binary `case(iop)` — the control plane is 100% binary even
  though every datapath value is a 12-trit (24-bit) word.

### 1b. Ternary-native PoC (`rust-mirror/src/ternary.rs`) — [DIRECT, from source]

```
12 trits = [op 3][f1 3][f2 3][f3 3]          // each field 3 trits, ±13 (27 values)
```

- Instruction word: **12 trits**, packed 2 bits/trit into a u32 (24 of 32 bits
  used). The 12 opcodes map to opcode field values `0..=11`.
- Opcode field: **3 trits = 27 slots**, 12 used.
- Register/operand fields: 3 trits each = 27 values, only `0..=7` legal (8 used,
  19 wasted — `decode()` rejects `≥ NREGS`).
- This is the "ternary-native control" side — but note the storage is **still
  binary** (2 bits/trit, `00=−1, 01=0, 10=+1, 11=reserved`). It is a *ternary
  logical encoding over binary storage*, not a physical ternary instruction word.
- The design doc (`TERNARY_PROCESSOR.md` §2.2) sketches a *third* layout —
  `3+4+4+1` (3-trit opcode, two 4-trit operands, 1-trit flag) — explicitly
  flagged [SPECULATION]; `ternary.rs` deviated to `3+3+3+3` so arithmetic ops
  can name a destination *and* two sources.

### 1c. Side-by-side

| Property | `cpu.v` (binary-host) | `ternary.rs` (ternary-native PoC) |
|---|---|---|
| Instruction word | 16 binary bits | 12 trits = **24 physical bits** @2 bits/trit |
| Opcode field | 4 bits = 16 slots, 6 used | 3 trits = 27 slots, 12 used |
| Register field | 3 bits = 8 (**exact**) | 3 trits = 27 values, 8 used (**19 wasted**) |
| Immediate | 9-bit two's complement (LDI) | 3-trit signed (TROT k / TBR k / NEIGH dir / TCVT dir) |
| Decoder | binary `case`, one-hot | trit unpack → 3-trit signed field reads |
| Instruction store | binary ROM (`$readmemh`) | trits packed in u32 (`Vec<Word>`) |
| Toolchain | standard hex/assembler | manual `Instr::encode` (no assembler) |

**Key honest observation [DIRECT arithmetic, OUR framing]:** the "ternary-native"
word is *not shorter* in the thing that matters for control — physical bits. The
1.585 bits/trit density win is a *logical* information count, but our trit code
costs **2 physical bits per trit**, so a 12-trit word occupies 24 physical bits
vs the 16-bit binary word for a *superset* of the same opcode space. Ternary
control only gets physically smaller if the instruction memory is itself ternary
(1 wire/trit push-pull-null, or a 3-level cell) — which does not exist yet (§2).

**File correction:** the task brief names `rust-mirror/src/isa.rs`; there is no
such file. The ISA (`Instr` enum, `encode`/`decode`, the 12-opcode table) lives
in `rust-mirror/src/ternary.rs`; `machine.rs` is its cycle/energy-instrumented
twin.

---

## 2. Decoder cost (energy/area)

### 2a. What is measured for the binary-host decoder — [DIRECT, SkyWater 130nm]

From `docs/REAL_SKY130_SYNTHESIS.md` (yosys + real sky130 liberty):

- `cpu` total: **26,713 µm²**, 3,970 cells, 214 FFs (sequential = 20.05%).
- Top cells are all standard binary gates (`nand2_1` 450, `nor2_1` 395,
  `a21oi_1` 278, `o21ai_0` 271, `a22oi_1` 207, …). There is **no ternary gate
  anywhere in the control path** — the opcode decode is ordinary binary logic.
- Fully-mapped netlist (write-muxes + ROM decode expanded): **29,333 µm²**,
  i.e. **+9.8%** is the register-file write-mux + instruction-ROM decode logic.
  This is the closest measured proxy for "control-decode overhead" the project
  has.

**What is NOT measured:** the decoder's own area/energy in isolation (yosys
reports the whole core, not the `case(iop)` cone). Any statement that "the
decoder is X% of the core" is [SPECULATION]. What is solid: the decode logic is
a small part of a core whose area is dominated by the ALU datapath (tnorm/mul)
and register write-muxes.

### 2b. Why a ternary decoder would cost *more*, not less — [OURS, via Law 1]

`docs/TERNARY_COMPUTE_SURVEY.md` sharpens Law 1 into a compute-side statement:

> every ternary gate pays a **2-threshold** measurement tax per cycle, forever;
> a binary gate pays **1 threshold**.

Applied to the **decode** stage specifically (our extension, [OURS]):

- A binary opcode bit is resolved by **1** threshold (is it 0 or 1?).
- A ternary opcode trit is resolved by **2** thresholds (is it −1, 0, or +1? —
  you must distinguish the middle from both extremes).
- Radix economy says ternary needs `1/log₂3 ≈ 0.631×` as many symbols as binary
  for the same information [DIRECT, `3/ln3 < 2/ln2`].
- Total decode threshold events for the *same* instruction information:
  binary `1.0 × 1 = 1.0`; ternary `0.631 × 2 = 1.26` → **≈26% more threshold
  events**, *before* the 2-bits/trit storage penalty.

So native ternary control is **strictly costlier to decode** for the same
logical content. The density win (1.585 vs 1.0 bits/symbol) does not come close
to paying for the 2× per-symbol receiver tax. Calibration: the `1.585` factor
and `0.631` are [DIRECT] arithmetic; the "2 thresholds per ternary gate" is
[OURS] (our design claim, not measured silicon); therefore the `1.26` is [OURS]
derived, not measured.

### 2c. The missing precondition: ternary instruction memory — [DIRECT gap]

A native ternary instruction word is only physical (and only potentially
shorter) if the **instruction store** is ternary. It is not, anywhere:

- `cpu.v`: `imem` is a binary ROM (`$readmemh`, 16-bit words).
- `ternary.rs`: trits are packed into binary `u32`s.
- **5500FP** (the modern 24-trit balanced-ternary RISC) is implemented **on an
  FPGA** — i.e. ternary emulated in a binary LUT fabric, not physical ternary
  cells [DIRECT, Zenodo/FPGA reports].
- **Setun** (1958) is the only machine with *physical* ternary storage —
  magnetic-core, ternary word + ternary address (5 trits, 243 words/page), a
  small single-address opcode set [DIRECT for shape; counts vary by source].
- `docs/TERNARY_COMPUTE_SURVEY.md` Phase-0 flags the 3-level SRAM/DRAM cell as
  "the big open one" — **there is no ternary memory cell in the project**, so
  there is no physical place to put a ternary opcode.

Conclusion for decoder area/energy: **no ternary decoder exists to measure**, and
our model says building one would raise decode cost. The binary-host decoder is
cheap, synthesizes to ordinary gates, and already works.

---

## 3. Opcode-space density (3ⁿ vs 2ⁿ)

### 3a. The namespace tables — [DIRECT, pure arithmetic]

| Field width n | 2ⁿ opcodes (bits) | 3ⁿ opcodes (trits) | trit advantage |
|---|---|---|---|
| 1 | 2 | 3 | 1.50× |
| 2 | 4 | 9 | 2.25× |
| 3 | 8 | 27 | 3.38× |
| 4 | 16 | 81 | 5.06× |
| 5 | 32 | 243 | 7.59× |
| 6 | 64 | 729 | 11.4× |
| 7 | 128 | 2,187 | 17.1× |
| 8 | 256 | 6,561 | 25.6× |

The 3ⁿ/2ⁿ ratio grows as `(3/2)ⁿ = 1.5ⁿ` — super-exponentially wide namespaces.
This is the *entire* content of "ternary opcodes are denser."

### 3b. But the ISA doesn't need a namespace — [DIRECT, applied to our ISA]

"Slots" only matter relative to **how many you use**:

| Need | binary | ternary |
|---|---|---|
| 6 opcodes (`cpu.v`) | ⌈log₂6⌉ = 3 bits (8 slots, 25% waste) — padded to 4 | ⌈log₃6⌉ = 2 trits (9 slots, 33% waste) |
| 12 opcodes (`ternary.rs`) | ⌈log₂12⌉ = 4 bits (16 slots, 25% waste) | ⌈log₃12⌉ = 3 trits (27 slots, 56% waste) |
| 8 registers | ⌈log₂8⌉ = **3 bits, exact** | ⌈log₃8⌉ = 2 trits (9 slots, 1 wasted) or 3 trits (19 wasted) |
| 27 opcodes | 5 bits (32) | **3 trits, exact** |
| 256 opcodes | **8 bits, exact** | ⌈log₃256⌉ = 6 trits (729) |

The density win only shows up where a *need* lands near a power of 3. Our ISA's
needs land near powers of 2 (8 registers = 2³; 12 opcodes ≈ 2⁴). At these
magnitudes the ternary field is *more* wasteful, not less: 3-trit register
fields throw away 19 of 27 values, while 3 binary bits hit 8 exactly.

### 3c. Radix economy is real but tiny, and it's a *namespace* win — [DIRECT + Law 3]

- `3/ln3 = 2.7307` vs `2/ln2 = 2.8854` — ternary is ~5.4% better radix economy
  [DIRECT, proved in `RadixEconomy.lean`]. `1 trit = log₂3 = 1.585 bits`
  [DIRECT, re-derived in 1807.06419].
- But `docs/ENERGY_LAWS.md` Law 3 already states the trap for this survey
  explicitly: an explosion of states "buys **namespace**, not **energy** — every
  extra state pays a receiver tax (Law 1) that never shrinks." Opcode density is
  a namespace quantity; decode cost is an energy quantity; the two move in
  **opposite** directions.

**Net:** 3ⁿ > 2ⁿ is true and is the only mathematically clean thing in the
"native ternary control" case — and it is irrelevant at 6/12 opcodes, because
we are not opcode-space-limited.

---

## 4. What native ternary control actually buys — and the toolchain cost

### 4a. The genuine (but small) wins — mostly data, not control

1. **3-way predicate is native in balanced ternary [OURS/ANALOGY].** The sign of
   a balanced value **is** the 3-way outcome: `{−1,0,+1}` ≙
   {below, equal, above}. `TBR`'s "3-way compare & branch" and the null-as-equal
   fall-through (`ternary.rs` `tbr`) are the one place the ternary structure of
   *control* is natural rather than bolted on. But a binary core gets the same
   semantics with two flag bits (Z/N) and a compare — at modest cost, in gates
   that already exist.
2. **Free negation is a datapath property, not a control property.** "No sign
   bit" helps the *data* encoding (TSUB = digit-swap then add); it does nothing
   for the opcode field, which is just small integers.
3. **Ternary immediates for 3-way/m-6 fields [OURS].** `TROT k mod 6`, `NEIGH
   dir mod 6`, `TCVT dir ∈ {+1,−1}`, `TBR k` are all small signed fields that a
   3-trit balanced immediate *expresses* cleanly — but they are small, and
   binary two's-complement immediates express them equally well. `cpu.v` packs
   `TROT k` as a 3-bit register field and `LDI` as a 9-bit immediate with zero
   difficulty.

**Summary of the win:** native ternary control would give a *marginally more
elegant* encoding of the 3-way branch and the signed immediates, and nothing
else. It does **not** shorten the word, **does not** reduce decoder area, and
**does not** reduce decode energy (it increases them, §2).

### 4b. The toolchain tradeoff — [DIRECT for what exists]

- **Binary-host keeps the whole toolchain for free:** a standard assembler,
  disassembler, linker, debugger, and any LLVM/GCC backend can emit `cpu.v`'s
  16-bit words (`program.hex` is a plain hex file). [DIRECT]
- **A ternary-native instruction word needs new tooling.** `ternary.rs` is
  honest about this: "there is deliberately **no assembler or linker** —
  programs are built in Rust with `Instr::encode`." If the 12-trit encoding were
  hardware, that manual codegen would have to become a real assembler.
- **The existence proof is REBEL-6** (32-trit balanced-ternary ISA with an R2R
  compiler pipeline for C, IEEE 2025) — a ternary ISA + C toolchain *is*
  buildable [DIRECT existence]. But `TERNARY_PROCESSOR.md` §5.4 flags exactly
  this as **the single biggest scope item** in the whole design: "REBEL-6's C
  pipeline is the proof it's doable; it's also the biggest scope item."

**Net on the tradeoff:** binary-host control is toolchain-free today; native
ternary control costs a bespoke toolchain for a decoding-energy *increase* at
the current ISA size. The toolchain argument is a decisive tie-breaker against
native ternary control at this scale.

---

## 5. The honest verdict

**Is native ternary control worth it? No — not today, not at this ISA size.**

The strongest, calibrated form of each side:

| | Native ternary control | Binary-host control (current) |
|---|---|---|
| Opcode namespace | 3ⁿ ≫ 2ⁿ [DIRECT] | 2ⁿ ≫ 12 opcodes needed [DIRECT] |
| Word size (physical) | 12 trits = 24 bits [DIRECT] | 16 bits [DIRECT] |
| Decode thresholds | 2/trit → ≈1.26× binary [OURS] | 1/bit = 1.0× [OURS] |
| Decoder gates | needs ternary cells (none exist) | standard binary, already synthesized [DIRECT] |
| Instruction memory | 3-level cell = "the big open one" | binary ROM, works today [DIRECT] |
| Toolchain | bespoke assembler/compiler (REBEL-6-scale) | standard, free [DIRECT] |
| 3-way branch elegance | native {−,0,+} [OURS] | two flags, cheap [ANALOGY] |

The single most important asymmetry: **ternary's proven wins are all in the
datapath** (free negation, balanced arithmetic, `TROT`/`TNORM` gauge ops) —
which `cpu.v` already exploits — while **its costs are all in the control
plane** (2-threshold decode, 2-bits/trit instruction storage, ternary cells,
toolchain). The hybrid "ternary datapath + binary control" is therefore not a
compromise; it is the *optimal* point on the spectrum until the preconditions
change.

**Re-examine native ternary control only when any of these become true**
(and none holds today):

1. **The ISA grows to where log₃ genuinely beats log₂** — register files /
   opcode spaces in the hundreds-to-thousands, where a 3-trit field (27) or
   6-trit field (729) stops wasting its namespace. At 8 registers / 12 opcodes,
   binary fields are *more* exact. [DIRECT math]
2. **A ternary instruction memory exists.** The 3-level SRAM/DRAM cell is
   explicitly flagged as the project's "big open one" (`TERNARY_COMPUTE_SURVEY.md`).
   Without it, "ternary-native control" is a logical encoding over binary
   storage — a relabeling, not a physical change. [DIRECT gap]
3. **A ternary 3-way control signal sits on the critical path** — e.g. a
   machine whose branch predicate is genuinely ternary and decode-bound. The
   current `TBR` (3-way compare) is a datapath op, not decode-bound. [SPECULATION]

**Recommendation for the project:** document the binary-host control choice as
*done* (it is the right call), and spend the ternary effort where it pays —
the ternary **datapath** (the pending Eisenstein-multiply `tmul_eisen_trits`
opcode, −14.6% area at N=6, has no instruction yet) and the ternary **memory
cell** (the actual wall). Control is solved; memory is not.

---

## 6. References

**Project-internal (OURS / DIRECT):**
- `rtl/cpu.v` — current CPU: 16-bit binary instruction words, ternary datapath.
- `rust-mirror/src/ternary.rs` — ternary-native 12-trit ISA (`Instr`, `Word::decode`); the `isa.rs` named in the brief does not exist.
- `rust-mirror/src/machine.rs` — cycle/energy-instrumented twin (TROT/TNORM/etc.).
- `docs/ENERGY_LAWS.md` — Law 1 (receiver gauge-agnostic), Law 3 (radix economy; namespace ≠ energy).
- `docs/TERNARY_COMPUTE_SURVEY.md` — the 2-threshold compute reframe; Phase-0 inventory (3-level memory cell = "the big open one").
- `docs/REAL_SKY130_SYNTHESIS.md` — measured area/timing (26,713 µm²; +9.8% write-mux+ROM decode).
- `docs/synthesis/ternary-circuits.md` — 19-paper survey (radix economy log₂3 re-derivations: 1807.06419, 2211.04542, 2204.01000).
- `TERNARY_PROCESSOR.md` §2 — the candidate 12-opcode ISA and its `3+4+4+1` sketch; §5.4 toolchain scope.

**External:**
- [Setun — Wikipedia](https://en.wikipedia.org/wiki/Setun) — 18-trit word, 5-trit address, small single-address opcode set (1958, only serial ternary machine).
- [REBEL-6: 32-trit balanced ternary ISA with R2R compiler pipeline for C — IEEE](https://ieeexplore.ieee.org/document/11038296) — the ternary-ISA + toolchain existence proof.
- [5500FP: 24-Trit Balanced Ternary RISC Processor — Zenodo](https://zenodo.org/records/18881738) — modern ternary RISC, implemented on FPGA (binary substrate).
- [History of Ternary Computers](https://mason.gmu.edu/~drine/History-of-Ternary-Computers.htm) — Setun/ternary background.
- [Not a binary choice: ternary CPU on an FPGA (5500FP) — HN](https://hn.svelte.dev/item/47424198).
