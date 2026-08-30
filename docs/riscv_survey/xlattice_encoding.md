# Xlattice — the custom-0 opcode encoding spec

**2026-08-29.** The register/width convention and the exact custom-0 instruction
encodings for the Xlattice extension: the balanced-ternary / geometric-algebra
instruction set mapped onto the RISC-V **custom-0** opcode space. This is the spec
`tinyrv`'s `customs` dispatch will implement next (TAU_RISCV_PLAN.md Phase 2).

Sources of truth (read first, and read them for the *semantics* — this doc only pins the
*encoding*):

- `rtl/cpu.v` — the 11-opcode ternary CPU ISA table (header L1–65) + the exact operand
  datapath. Word = 12 trits = 24 bits = `(a,b)`, 2 bits/trit (`01=+1, 00=0, 10=−1, 11=NEVER`).
- `rtl/ga_ops.v` — TCONJ / TDOT / TWEDGE / TSYMDOT cell semantics + widths.
- `rtl/grad_recon.v` — TGRAD / TRECON (the 7-cell hex pod, div/curl).
- `rtl/trelax.v` — TRELAX (one heat-equation step).
- `docs/GA_INSTRUCTIONS.md` — the GA instruction tiering.
- `docs/compute/field_calculus/synthesis.md`, `heat.md`, `maxwell.md` — TGRAD/TRECON/TRELAX
  calibration.
- `proofs/lean-src/hexagon/Hexagon/*.lean` — one proof per op (citations in §4).

**Calibration legend (repo-wide):** DIRECT = proved/measured/classical; OURS = design claim
following from a DIRECT fact; SPECULATION = untested. Every encoding here is OURS by
construction (custom-0 is unassigned space, ours to define); every *semantic* is cited to a
Lean file or RTL module.

---

## 0. TL;DR

- **One Eisenstein word = one RV32 register, low 24 bits** (`a` = bits[11:0], `b` = bits[23:12],
  2 bits/trit, `11=NEVER` canary), high 8 bits zero. Bit-identical to `cpu.v`'s 24-bit word.
- **All 13 ops live in custom-0 = opcode `0x0B`.** `funct3` selects the operand *format*;
  `funct7` selects the *operation* within the format.
- 2-operand (rd, rs1, rs2): TADD, TSUB, TROT, TMUL, TDOT, TWEDGE, TSYMDOT.
- 1-operand (rd, rs1): TNORM, TCONJ.
- Immediate (rd, imm): LDI.
- **Pod ops read the 7-cell pod from the hex-addressed memory region** (not a register
  window): TGRAD rd, rs1(addr); TRELAX rd, rs1(addr); TRECON rd, rs1(J), rs2(dst-addr).
- **Honest verdict baked in:** these are integer/geometric ops. They lose on compute vs
  binary (the ALU is *not* where the win is — `ThresholdLowerBound.lean`: 1.26×/bit,
  2-threshold tax; TMUL measured +64.8% area). Xlattice exists to move the GA/field-calculus
  work **close to the hex memory**, not to speed up arithmetic (§5).

---

## 1. Data-type convention — how a 12-trit word maps to a register

### 1.1 The datum

An Eisenstein integer is `z = a + bω`, `ω = e^(iπ/3)`, `ω² = ω−1`, stored as the coefficient
pair `(a, b)` (see `Conventions.lean`). The ternary CPU's word is **12 trits = 24 bits**:
`a` in bits `[11:0]` (6 trits), `b` in bits `[23:12]` (6 trits), each trit 2 bits:

| trit | meaning | 2-bit code |
|------|---------|-----------|
| `+1` | positive | `01` |
| ` 0` | null    | `00` |
| `−1` | negative | `10` |
| (never) | canary | `11` — forbidden, latched as `ovf` |

6 balanced trits span `±(3⁶−1)/2 = ±364`. The 2-bit/trit code is the *storage* form
(`TernaryCell.lean` one-hot-per-direction, 2/3 wire-energy); the *value* of a word is the
integer `a` plus `b` scaled by ω, i.e. the pair is read as the balanced integer
`(Σ aᵢ3ⁱ, Σ bᵢ3ⁱ)` (`TernaryCrt.lean` `val`, `tritInt`).

### 1.2 The convention (chosen): one word per register, low 24 bits

```
RV32 register (XLEN=32), holding word z = (a, b):

   31           24 23                    12 11                     0
  +---------------+------------------------+------------------------+
  |  0 … 0 (zero) |     b  (6 trits)       |     a  (6 trits)       |
  +---------------+------------------------+------------------------+
       8 spare bits      bits [23:12]            bits [11:0]
```

- `a` (the "real"/scalar field) = `rs[11:0]`.
- `b` (the "imag"/bivector field) = `rs[23:12]`.
- `rs[31:24]` = **zero** on every write; ignored on read (reserved for the `11=NEVER` canary
  or a packed status word).
- **Scalar results** (TNORM, TDOT, TWEDGE, TSYMDOT, TRELAX) are "a-field only, b cleared":
  the value in `rs[11:0]`, `rs[23:12] = 0` (b-field zeroed), exactly as `cpu.v` does
  (`wdata = {12'b0, <scalar>}`).

This is the **recommended** convention. Justification, in order of weight:

1. **1:1 with `cpu.v`.** The RTL word is exactly 24 bits in this exact layout; the emulator
   then mirrors the already-verified datapath bit-for-bit. Diverging from the proven layout
   is where emulator↔RTL drift bugs are born.
2. **Register economy.** A 2-operand GA op `(z, w) ↦ result` needs exactly 2 operand registers
   + 1 result register — the native R-type shape `(rd, rs1, rs2)`. Splitting `(a,b)` across
   *two* registers would need 4 operand + 2 result registers = 6, which overflows the
   3-register R-type and forces a register window or a second instruction per op.
3. **24 ≤ 32.** One word always fits with 8 spare bits — no pairing, no packing games, no
   special `even/odd` register-alignment rules.
4. **Scalars collapse cleanly.** "a-field only" results are just the low 12 bits, still one
   register.

**Rejected alternative** — split `a` in one register, `b` in another: rejected on register
pressure (item 2) and on divergence from `cpu.v` (item 1). Its only merit would be giving
each coefficient 32 bits of headroom, which the ops don't need (full-width GA results are
13 trits = 26 bits; see §1.3).

### 1.3 The two width classes (WORD6 and WORD8)

The GA scalar ops *compute in* more than 6 trits even though they *store* 6. Being explicit
about this now avoids a width bug later:

| class | trits/coeff | bits | range | where it appears |
|-------|-------------|------|-------|------------------|
| **WORD6** | 6 | 24 | ±364 | the standard cell; every operand and every scalar result |
| **WORD8** | 8 | 32 | ±3280 | the TGRAD `(div, curl)` pair; TRECON's `(div, curl)` input |

- WORD6: operands/results of TADD/TSUB/TROT/TMUL/TCONJ/TNORM/TDOT/TWEDGE/TSYMDOT/TRELAX.
- WORD8: `div`/`curl` each sum 4 signed terms of magnitude ≤ 364, so `|div|, |curl| ≤ 1456`,
  which fits 8 trits (±3280) — the "safe width" `SW = NTRITS+2` of `grad_recon.v`/`trelax.v`.
  Two 8-trit coefficients = **32 bits = exactly one full register**, with `div` in
  `bits[15:0]` and `curl` in `bits[31:16]` (2 bits/trit, 8 trits each). No waste.

**Full-width note (honest):** the *exact* results of TMUL (A: 12 trits, B: 13 trits),
TNORM (13 trits), TDOT/TWEDGE/TSYMDOT (13 trits), TCONJ (a+b: 7 trits) do **not** fit a
6-trit coefficient. Following `cpu.v`'s fit convention, each instruction stores the **low 6
trits** of each coefficient and reports overflow via the `ovf`/`ofit` flag — overflow is
**flagged, not trapped**. In the RISC-V mapping this flag is a dedicated **Xlattice status
CSR** (proposed address in §6), not a register bit, because RISC-V has no condition-code
register and `rd` must stay a data word.

---

## 2. The custom-0 encoding space (the facts)

From **riscv-unprivileged, ch. 33 (Custom Instructions)** — note: no prior
`docs/riscv_survey/unprivileged.md` survey exists yet; the source PDF is
`docs/riscv spec/riscv-unprivileged.pdf`. The facts used here:

- RISC-V reserves four opcodes for custom extensions:
  **custom-0 = `0x0B`**, custom-1 = `0x2B`, custom-2 = `0x5B`, custom-3 = `0x7B`.
- We use **custom-0 = `0b0001011`**. Everything inside it — `funct7`, `rs2`, `rs1`,
  `funct3`, `rd` — is ours to define; nothing inside custom-0 collides with the base ISA.
- The 32-bit instruction formats (RV32, little-endian bit numbering):

```
R-type (all our two/one-operand and pod ops):
  31           25 24      20 19      15 14    12 11       7 6         0
  +--------------+----------+----------+--------+----------+-----------+
  |    funct7    |   rs2    |   rs1    | funct3 |    rd    |  opcode   |
  |     7 bits   |  5 bits  |  5 bits  | 3 bits |  5 bits  |  0x0B     |
  +--------------+----------+----------+--------+----------+-----------+

I-type (LDI only):
  31                            20 19      15 14    12 11       7 6         0
  +-------------------------------+----------+--------+----------+-----------+
  |          imm[11:0]            |   rs1    | funct3 |    rd    |  opcode   |
  |          12 bits              |  5 bits  | 3 bits |  5 bits  |  0x0B     |
  +-------------------------------+----------+--------+----------+-----------+
```

Register fields (`rd`, `rs1`, `rs2`) are 5-bit register indices (`x0`…`x31`). `x0` reads as
the Eisenstein zero `(0,0)` and, as `rd = x0`, discards the result.

---

## 3. Opcode assignment

### 3.1 The scheme

- **`funct3` = operand format** (how many operands and of what kind).
- **`funct7` = operation** within a format.

| funct3 | format | operand shape | ops |
|:------:|--------|---------------|-----|
| `000` | **R2** | `rd, rs1, rs2` (two Eisenstein words) | TADD, TSUB, TROT, TMUL, TDOT, TWEDGE, TSYMDOT |
| `001` | **R1** | `rd, rs1` (one Eisenstein word) | TNORM, TCONJ |
| `010` | **I**  | `rd, imm[11:0]` | LDI |
| `011` | **POD·rd** | `rd, rs1 = pod address` (7-cell gather) | TGRAD, TRELAX |
| `100` | **POD·wr** | `rd, rs1 = J, rs2 = dest address` (7-cell scatter) | TRECON |

### 3.2 The exact 32-bit encodings

`base` is the 32-bit value with all register/immediate fields zero — it pins `funct7`,
`funct3`, and `opcode`. To assemble a real instruction, OR in `rs2<<20 | rs1<<15 | rd<<7`
(R-type) or `imm<<20 | rs1<<15 | rd<<7` (I-type).

| op | format | funct3 | funct7 | operands | base (fields=0) |
|----|:------:|:------:|:------:|----------|----------------:|
| TADD   | R2 | `000` | `0000000` | `rd = rs1 + rs2` | `0x0000000B` |
| TSUB   | R2 | `000` | `0000001` | `rd = rs1 − rs2` | `0x0200000B` |
| TROT   | R2 | `000` | `0000010` | `rd = ω^rs2·rs1` | `0x0400000B` |
| TMUL   | R2 | `000` | `0000011` | `rd = rs1 × rs2` | `0x0600000B` |
| TDOT   | R2 | `000` | `0000100` | `rd = dot(rs1,rs2)` | `0x0800000B` |
| TWEDGE | R2 | `000` | `0000101` | `rd = wedge(rs1,rs2)` | `0x0A00000B` |
| TSYMDOT| R2 | `000` | `0000110` | `rd = symdot(rs1,rs2)` | `0x0C00000B` |
| TNORM  | R1 | `001` | `0000000` | `rd = N(rs1)` | `0x0000100B` |
| TCONJ  | R1 | `001` | `0000001` | `rd = conj(rs1)` | `0x0200100B` |
| LDI    | I  | `010` | —        | `rd = (imm, 0)` | `0x0000200B` |
| TGRAD  | POD·rd | `011` | `0000000` | `rd = (div, curl) from pod@rs1` | `0x0000300B` |
| TRELAX | POD·rd | `011` | `0000001` | `rd = relax(pod@rs1)` | `0x0200300B` |
| TRECON | POD·wr | `100` | `0000000` | `pod@rs2 ← recon(rs1)` | `0x0000400B` |

### 3.3 Per-op semantics + operand classification

Operands are Eisenstein words (§1). `z = rs1 = (a,b)`, `w = rs2 = (c,d)`. All GA ops use
`ω² = ω−1` and the conjugate `ω̄ = 1−ω` (`conj(a,b) = (a+b, −b)`).

| op | class | semantics (verbatim from RTL) | result width | notes |
|----|-------|-------------------------------|--------------|-------|
| **TADD** | 2-op | `rd = (a+c, b+d)` coefficient-wise balanced add | 6+6 trits | `Add` instance |
| **TSUB** | 2-op | `rd = (a−c, b−d)`; negate = per-trit wire swap, carry-free, then add | 6+6 trits | `Sub` instance |
| **TROT** | 2-op | `rd = ω^k·rs1`, `k = rs2[2:0]` (Z₆ angle). `k=0..5` → see table below | 6+6 trits | rs2 is a 3-bit index, not an Eisenstein word |
| **TMUL** | 2-op | `(a+bω)(c+dω) = (ac−bd) + (ad+bc+bd)ω` | A:12, B:13 trits (low 6 kept) | 3-product Karatsuba; `ovf` if wider than 6 trits |
| **TDOT** | 2-op | `dot(z,w) = (z·conj w).a = ac+ad+bd` → a-field | 13 trits (low 6 kept) | NOT symmetric (`dot_swap`) |
| **TWEDGE** | 2-op | `wedge(z,w) = (z·conj w).b = bc−ad` → a-field | 12 trits (low 6 kept) | anti-symmetric (the skew/curl) |
| **TSYMDOT** | 2-op | `symdot = N(z+w)−N(z)−N(w) = 2ac+ad+bc+2bd` → a-field | 13 trits (low 6 kept) | the TRUE symmetric correlation |
| **TNORM** | 1-op | `rd = N(z) = a²+ab+b²` → a-field | 13 trits (low 6 kept) | the norm / area scalar |
| **TCONJ** | 1-op | `rd = (a+b, −b)` | a+b: 7 trits | single operand; rs2 field unused (zero) |
| **LDI** | imm | `rd = (imm_balanced, 0)`; imm[11:0] sign-extended → balanced 6-trit | 6 trits | `ovf` if `|imm| > 364` |
| **TGRAD** | pod·rd | `∇F = (div, curl)`; `div = F0−F2−F3+F5`, `curl = F1+F2−F4−F5` | div/curl: 8 trits each (WORD8) | see §3.4 |
| **TRELAX** | pod·rd | `u' = u/3 + (ΣₖFₖ)/9` (the α=2/3 heat step) | 6 trits (WORD6 a-field) | see §3.4 |
| **TRECON** | pod·wr | canonical-gauge section of ∇⁻¹: `F0'=div, F1'=curl, F2'…F5'=0, center'=0` | pod (7×WORD6) | see §3.4 |

**TROT angle table** (rs2 low 3 bits `k`; `z = (a,b)` — from `cpu.v` L50–57, proved as
`Gauge.lean` `omegaPow_*`):

| k | ω^k | (a′, b′) |
|---|-----|----------|
| 0 |  1    | `(  a,    b)` |
| 1 |  ω    | `( −b,  a+b)` |
| 2 |  ω−1  | `(−(a+b), a)` |
| 3 | −1    | `( −a,   −b)` |
| 4 | −ω    | `(  b, −(a+b))` |
| 5 |  1−ω  | `( a+b,  −a)` |

### 3.4 The pod ops (TGRAD / TRELAX / TRECON) — operand convention

These three take a **7-cell hex pod** = the closed radius-1 ball `{center} ∪ {6 unit
neighbors}` (`Pod.lean` `pod_card = 7`; `HexDisk.lean`). A pod is 7 × 24 = 168 bits = 7
registers, which would eat 22% of the register file per operand — so they are **memory-region
ops, not register-window ops**. This is the point of the whole extension: the pod is the
natural hex-memory unit, and these ops pull it from hex-addressed memory to stay co-located
with the hex memory (TAU_RISCV_PLAN.md Phase 1 hex MMU, `eisensteinToNat` in
`AddressTranslation.lean`/`Bijection.lean`).

**Convention (chosen):** `rs1` (or `rs2`) holds a **hex address** = an Eisenstein cell
`(a,b)` (a WORD6) naming the pod *center*. The 7 cells are gathered in canonical order:

```
cell 0 = center        = addr
cell k = addr + ω^(k−1),  k = 1..6   (the 6 unit directions, Rotation.lean order:
                                        (1,0),(0,1),(−1,1),(−1,0),(0,−1),(1,−1))
```

This is exactly `grad_recon.v`'s neighbor indexing `F0..F5` (`nb[0]` at the LSB = the ω⁰
direction, then ω¹…ω⁵). The `F_k` field values are WORD6 (low 24 bits of each memory cell).

- **TGRAD `rd, rs1`** — gather pod at `rs1`; compute the directed 6-neighbor sum
  `∇F = Σ_k ω^k·F_k`, split into `div` (Re/source grade) and `curl` (Im/skew grade); write
  `rd = (div, curl)` as **WORD8** (`div` in `[15:0]`, `curl` in `[31:16]`). The center value
  drops out (`Σ_k ω^k = 0`, the gauge; `HexIsotropy.lean`).
- **TRELAX `rd, rs1`** — gather pod at `rs1`; compute one heat step
  `u' = u/3 + (ΣₖFₖ)/9` (the `α = 2/3` folded form `u + (1/9)(ΣFₖ − 6u)`); write
  `rd = u'` as WORD6 a-field (b cleared). The ÷3 / ÷9 are free trit right-shifts
  (`TernaryCrt.lean`). *First-cut emulator:* read-only — the in-place sweep over the pod
  array is a software loop around this op.
- **TRECON `rd, rs1, rs2`** — `rs1 = J = (div, curl)` as WORD8; `rs2 = destination hex
  address`. Writes the **canonical-gauge section** of ∇⁻¹ to the 7 cells at `rs2`:
  `F0' = low 6 trits of div`, `F1' = low 6 trits of curl`, `F2'=F3'=F4'=F5'=0`, `center'=0`.
  `rd = status` (0 = ok; 1 = `ofit`, div or curl wider than 6 trits). Honest statement:
  ∇ is a 6→2 linear map with a 4-dimensional nullspace, so reconstruction is defined **only
  up to gauge**; TRECON implements *one* canonical right-inverse (the source placed on ω⁰,ω¹),
  and `∇(TRECON(∇F)) = ∇F` identically — this section is an OURS convention, **not yet a Lean
  theorem** (see §4, item TRECON).

---

## 4. One-line Lean citation per op

All paths relative to `proofs/lean-src/hexagon/Hexagon/`. `lake build` is green (8748 jobs,
zero `sorry`), so these are checked theorems, not sketches.

| op | Lean citation (file : theorem — what it proves) |
|----|--------------------------------------------------|
| TADD   | `Conventions.lean` : `instance : Add Eisenstein` (L46) — coefficient-wise balanced add. |
| TSUB   | `Conventions.lean` : `instance : Sub Eisenstein` (L47) — subtract; negation is the carry-free per-trit swap. |
| TROT   | `Gauge.lean` : `units_eq_omega_pow` / `omegaPow_zero..five` (L61–94) — the six units are exactly `ω^k`, k=0..5. |
| TNORM  | `Conventions.lean` : `def norm` (L65) — `N = a²+ab+b²`; `Gauge.lean` : `norm_eq_det` (L51) — the norm is the area scalar. |
| LDI    | `Conventions.lean` : `instance : IntCast` (L54) — `n ↦ (n,0)` is the balanced encoding of an integer; balanced digit extraction = `TernaryCrt.lean` `val`/`tritInt`. |
| TMUL   | `Conventions.lean` : `instance : Mul Eisenstein` (L50) — `(ac−bd)+(ad+bc+bd)ω`; `norm_mul` (L68). |
| TCONJ  | `Conjugate.lean` : `def conj` (L27) — `(a+b, −b)`; `conj_involutive` (L30). |
| TDOT   | `DotWedge.lean` : `def dot` (L32) — `(z·conj w).a`; `dot_swap` (L46) — the raw dot is *not* symmetric. |
| TWEDGE | `DotWedge.lean` : `def wedge` (L35) — `(z·conj w).b`; `wedge_antisymm` (L55) — skew/curl flips sign. |
| TSYMDOT| `SymDot.lean` : `def symdot` (L33) — `N(z+w)−N(z)−N(w)`; `symdot_comm` (L38) — the symmetric polarization. |
| TGRAD  | `CausalLattice.lean` : `flow` (L47) + `curl` (L53) — divergence and circulation of the directed 6-neighbor sum; gauge killed by `Σω^k=0` (`HexIsotropy.lean` `neighbors_card` L45). |
| TRECON | `CausalLattice.lean` : `diamond_balance` (L73) + `Residual.lean` : `sum_residual_eq_zero` (L85) — the gauge/nullspace that makes ∇⁻¹ gauge-fixed; **the canonical section itself is an OURS convention, not yet a theorem.** |
| TRELAX | `TernaryCrt.lean` : `div3_truncation` (L164) — dropping the least trit divides by 3 (the free ÷3/÷9); 6-point stencil = `HexIsotropy.lean` `neighbors_card` (L45). |

---

## 5. Honest note — these are integer/geo ops, and that is not where the win is

This section is not decoration; it is the load-bearing disclaimer, and it must survive every
future costing:

- **Compute stays binary.** A ternary **ALU is the losing layer**: `ThresholdLowerBound.lean`
  proves the 1.26×/bit, 2-threshold tax, and `TMUL` was *measured* at **+64.8% area** over the
  optimized ternary CPU (`docs/compute/eisen_opcode.md` §3). None of the 13 ops here makes
  ternary arithmetic cheaper than binary arithmetic — it makes it *available*, at a cost.
- **The win is addressing + transport, not the ALU.** Ternary wins in exactly two places:
  the `3ⁿ` address namespace (`AddressTranslation.lean`/`TritPacking.lean`/`FractalRam.lean`,
  exponential) and the transport wire (~2.7–6.3× per ngspice). That is the whole thesis of
  TAU_RISCV_PLAN.md: a *stock binary* RISC-V core with a ternary/hex memory subsystem.
- **Xlattice's real job** is to move the GA/field-calculus work — the dot/wedge split, the
  ∇/∇² pair, the reconstruction and the heat step — **close to the hex memory**, so that
  `TGRAD`/`TRECON`/`TRELAX` run as one memory-co-located pod op instead of a string of
  binary load/multiply/add sequences far from the cells. It is an *instruction abstraction*
  (`docs/compute/field_calculus/synthesis.md`: "NOT a new computation class"), not an
  arithmetic-speedup play.
- **Unmeasured.** `TGRAD`/`TRECON`/`TRELAX` have no area/energy numbers yet
  (`synthesis.md` §5, `heat.md` §TODO). Do not read "native instruction" as "cheap" — every
  one of them must survive the same yosys/ngspice fair-fight that already cost TMUL +64.8%.

---

## 6. Implementation notes (tinyrv `customs`)

The `tinyrv` seams this plugs into (TAU_RISCV_PLAN.md Phase 2): `opcodes`/`decode` key on
`opcode == 0x0B`, and `customs` dispatches on `(funct3, funct7)`:

```python
def xlattice(cpu, ir):
    f7, rs2, rs1, f3, rd = rv.decode_r(ir)          # custom-0 R-type fields
    if   (f3, f7) == (0b000, 0b0000000): TADD(rd, rs1, rs2)
    elif (f3, f7) == (0b000, 0b0000001): TSUB(rd, rs1, rs2)
    elif (f3, f7) == (0b000, 0b0000010): TROT(rd, rs1, rs2)      # k = rs2 & 7
    elif (f3, f7) == (0b000, 0b0000011): TMUL(rd, rs1, rs2)
    elif (f3, f7) == (0b000, 0b0000100): TDOT(rd, rs1, rs2)
    elif (f3, f7) == (0b000, 0b0000101): TWEDGE(rd, rs1, rs2)
    elif (f3, f7) == (0b000, 0b0000110): TSYMDOT(rd, rs1, rs2)
    elif (f3, f7) == (0b001, 0b0000000): TNORM(rd, rs1)
    elif (f3, f7) == (0b001, 0b0000001): TCONJ(rd, rs1)
    elif  f3        == 0b010:             LDI(rd, imm=ir >> 20)   # sign-extend 12-bit
    elif (f3, f7) == (0b011, 0b0000000): TGRAD(rd, rs1)           # pod@rs1 → (div,curl)
    elif (f3, f7) == (0b011, 0b0000001): TRELAX(rd, rs1)          # pod@rs1 → u'
    elif (f3, f7) == (0b100, 0b0000000): TRECON(rd, rs1, rs2)     # J=rs1 → pod@rs2
```

Conventions the emulator must honor (all mirroring `cpu.v`):

1. **Word store:** write only `bits[23:0]`, zero `bits[31:24]`; read only `bits[23:0]`.
2. **2-bit/trit arithmetic:** `01/00/10` are the only legal trit codes; `11` is a canary
   that latches `ovf` (never produced, never silently consumed).
3. **Fit convention:** every GA op computes exactly, stores the low 6 trits per coefficient,
   and sets `ovf` when any higher trit is non-null (the 13-trit / 7-trit results of
   TMUL/TNORM/TDOT/TWEDGE/TSYMDOT/TCONJ). Scalar ops zero the b-field.
4. **Pod gather/scatter:** canonical order §3.4; `TGRAD`/`TRELAX` read 7 WORD6 cells via the
   hex MMU; `TRECON` writes 7 WORD6 cells. `TGRAD` returns WORD8; `TRELAX` returns WORD6.
5. **Status CSR:** overflow + `11=NEVER` canary report to an Xlattice status CSR (a dedicated
   CSR address in the custom range), mirroring `cpu.v`'s latched `ovf`/canary outputs.
6. **LDI range:** 12-bit sign-extended immediate must satisfy `|imm| ≤ 364`; larger values
   set `ovf` (they do not fit 6 balanced trits).

---

## 7. Open items (to close before/while implementing)

- **Overflow CSR address** — pick a concrete custom CSR number for the Xlattice status word.
- **`TRELAX` in-place write** — decide whether the op writes `u'` back to the center cell
  (read-modify-write) or stays read-only (the current `trelax.v` is a pure combinational
  cell; the in-place sweep is then a software loop).
- **`TRECON` status in `rd`** — confirm `rd = 0/1` status convention vs. a CSR.
- **Pod order ↔ address arithmetic** — nail the `addr + ω^k` neighbor computation against
  `AddressTranslation.lean`'s `eisensteinToNat` (the hex MMU is Phase 1).
- **Lean gap** — the TRECON canonical section and the discrete ∇²/TRELAX step are named in
  `synthesis.md` TODO #1/#2/#6 but not yet formalized; add `FieldCalculus.lean` when funding
  Phase 5.
