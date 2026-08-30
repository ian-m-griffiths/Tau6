# RISC-V Unprivileged ISA — Encoding Reference for the Xlattice Custom Extension

**Source:** `docs/riscv spec/riscv-unprivileged.pdf`
— *The RISC-V Instruction Set Manual, Volume I: Unprivileged Architecture, Version 20260120 (Official Release, 2026-01-20).*

**Cross-checked against:** `venv/lib/python3.13/site-packages/tinyrv/opcodes.py`
(`opcodes` dict + `mask_match_rv32` / `mask_match_rv64`; `match`/`mask` values quoted
below are taken from that file and agree with the PDF's Table 72 and instruction listings).

This file is the authoritative copy-paste reference for assigning `Xlattice` opcodes.
All encodings are for the **32-bit base instruction format** (`inst[1:0] = 11`), RV32/RV64.

---

## 1. RV32I base instruction formats (Spec §2.2, §2.3)

Four core formats (R/I/S/U), plus two immediate variants (B/J). All 32 bits.
Bits are numbered `inst[31]` (MSB) … `inst[0]` (LSB). Register specifiers sit in
the same position in every format; the sign bit of every immediate is in bit 31.

| Format | `inst[31:25]` | `inst[24:20]` | `inst[19:15]` | `inst[14:12]` | `inst[11:7]` | `inst[6:0]` |
|--------|---------------|---------------|---------------|---------------|--------------|-------------|
| **R**  | funct7        | rs2           | rs1           | funct3        | rd           | opcode      |
| **I**  | imm[11:0]     | (high 12 bits of the immediate)       | rs1           | funct3        | rd           | opcode      |
| **S**  | imm[11:5]     | rs2           | rs1           | funct3        | imm[4:0]     | opcode      |
| **B**  | imm[12], imm[10:5] | rs2      | rs1           | funct3        | imm[4:1], imm[11] | opcode |
| **U**  | imm[31:12]    | (high 20 bits of the immediate)       | (—)           | (—)           | rd           | opcode      |
| **J**  | imm[20], imm[10:1], imm[11], imm[19:12] | (—) | (—)      | (—)           | rd           | opcode      |

Precise bit-level layout (from §2.2/§2.3 diagrams; fields confirmed against
`opcodes.py` `arg_bits` for `imm12`/`jimm20`/`bimm12hi`/`bimm12lo`):

- **R-type:** `funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]`
- **I-type:** `imm[11:0][31:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]`
- **S-type:** `imm[11:5][31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | imm[4:0][11:7] | opcode[6:0]`
- **B-type:** `imm[12]=inst[31], imm[10:5]=inst[30:25], rs2[24:20], rs1[19:15],
  funct3[14:12], imm[4:1]=inst[11:8], imm[11]=inst[7], opcode[6:0]`
- **U-type:** `imm[31:12][31:12] | rd[11:7] | opcode[6:0]`
- **J-type:** `imm[20]=inst[31], imm[10:1]=inst[30:21], imm[11]=inst[20],
  imm[19:12]=inst[19:12], rd[11:7], opcode[6:0]`

Notes (Spec §2.3):
- S vs B differ only in that the B-format immediate encodes branch offsets in
  multiples of 2 (imm[0] is implicitly 0).
- U vs J differ only in that the 20-bit immediate is shifted left by 12 (U) or by 1 (J).

---

## 2. Base opcode map (Spec §36, Table 72, "RISC-V base opcode map, inst[1:0]=11")

Rows are `inst[6:5]`, columns are `inst[4:2]`; the low two bits `inst[1:0]=11`.
`opcode = inst[6:0]`. The `111` column (`inst[4:2]=111`) marks the
`>32b` / `reserved` long-instruction space.

| inst[6:5] \ inst[4:2] | 000 | 001 | 010 | 011 | 100 | 101 | 110 | 111 (>32b) |
|---|---|---|---|---|---|---|---|---|
| **00** | LOAD `0x03` | LOAD-FP `0x07` | **custom-0 `0x0B`** | MISC-MEM `0x0F` | OP-IMM `0x13` | AUIPC `0x17` | OP-IMM-32 `0x1B` | reserved |
| **01** | STORE `0x23` | STORE-FP `0x27` | **custom-1 `0x2B`** | AMO `0x2F` | OP `0x33` | LUI `0x37` | OP-32 `0x3B` | reserved |
| **10** | MADD `0x43` | MSUB `0x47` | NMSUB `0x4B` | NMADD `0x4F` | OP-FP `0x53` | OP-V `0x57` | **custom-2 `0x5B`** | reserved |
| **11** | BRANCH `0x63` | JALR `0x67` | reserved | JAL `0x6F` | SYSTEM `0x73` | OP-VE `0x77` | **custom-3 `0x7B`** | reserved |

Base opcode field values (7-bit, hex + binary):

| Name | opcode | Name | opcode |
|------|--------|------|--------|
| LOAD    | `0x03` = `0000011` | OP-FP   | `0x53` = `1010011` |
| LOAD-FP | `0x07` = `0000111` | OP-V    | `0x57` = `1010111` |
| **custom-0** | `0x0B` = `0001011` | **custom-2** | `0x5B` = `1011011` |
| MISC-MEM| `0x0F` = `0001111` | BRANCH  | `0x63` = `1100011` |
| OP-IMM  | `0x13` = `0010011` | JALR    | `0x67` = `1100111` |
| AUIPC   | `0x17` = `0010111` | JAL     | `0x6F` = `1101111` |
| OP-IMM-32 | `0x1B` = `0011011` | SYSTEM  | `0x73` = `1110011` |
| STORE   | `0x23` = `0100011` | OP-VE   | `0x77` = `1110111` |
| STORE-FP| `0x27` = `0100111` | **custom-3** | `0x7B` = `1111011` |
| **custom-1** | `0x2B` = `0101011` |         | |
| AMO     | `0x2F` = `0101111` |         | |
| OP      | `0x33` = `0110011` |         | |
| LUI     | `0x37` = `0110111` |         | |
| OP-32   | `0x3B` = `0111011` |         | |
| MADD    | `0x43` = `1000011` |         | |
| MSUB    | `0x47` = `1000111` |         | |
| NMSUB   | `0x4B` = `1001011` |         | |
| NMADD   | `0x4F` = `1001111` |         | |

---

## 3. ALU op funct3 / funct7 (Spec §2.4.1, §2.4.2)

### OP-IMM (`opcode = 0x13`) — register-immediate

| Instruction | funct3 | funct7 (I-immediate bits 31:25) |
|-------------|--------|---------------------------------|
| ADDI  | `000` = `0x0` | — (imm[11:0]) |
| SLTI  | `010` = `0x2` | — |
| SLTIU | `011` = `0x3` | — |
| XORI  | `100` = `0x4` | — |
| ORI   | `110` = `0x6` | — |
| ANDI  | `111` = `0x7` | — |
| SLLI  | `001` = `0x1` | `0000000` (shamt[4:0]) |
| SRLI  | `101` = `0x5` | `0000000` (shamt[4:0]) |
| SRAI  | `101` = `0x5` | `0100000` (shamt[4:0]) |

### OP (`opcode = 0x33`) — register-register

| Instruction | funct3 | funct7 |
|-------------|--------|--------|
| ADD  | `000` = `0x0` | `0000000` = `0x00` |
| SUB  | `000` = `0x0` | `0100000` = `0x20` |
| SLL  | `001` = `0x1` | `0000000` = `0x00` |
| SLT  | `010` = `0x2` | `0000000` = `0x00` |
| SLTU | `011` = `0x3` | `0000000` = `0x00` |
| XOR  | `100` = `0x4` | `0000000` = `0x00` |
| SRL  | `101` = `0x5` | `0000000` = `0x00` |
| SRA  | `101` = `0x5` | `0100000` = `0x20` |
| OR   | `110` = `0x6` | `0000000` = `0x00` |
| AND  | `111` = `0x7` | `0000000` = `0x00` |

Exact `match`/`mask` from `opcodes.py` (confirming the above):

```
add    match=0x00000033 mask=0xFE00707F   sub    match=0x40000033 mask=0xFE00707F
sll    match=0x00001033 mask=0xFE00707F   slt    match=0x00002033 mask=0xFE00707F
sltu   match=0x00003033 mask=0xFE00707F   xor    match=0x00004033 mask=0xFE00707F
srl    match=0x00005033 mask=0xFE00707F   sra    match=0x40005033 mask=0xFE00707F
or     match=0x00006033 mask=0xFE00707F   and    match=0x00007033 mask=0xFE00707F
addi   match=0x00000013 mask=0x0000707F   slti   match=0x00002013 mask=0x0000707F
sltiu  match=0x00003013 mask=0x0000707F   xori   match=0x00004013 mask=0x0000707F
ori    match=0x00006013 mask=0x0000707F   andi   match=0x00007013 mask=0x0000707F
slli   match=0x00001013 mask=0xFC00707F   srli   match=0x00005013 mask=0xFC00707F
srai   match=0x40005013 mask=0xFC00707F
```

### BRANCH (`0x63`), LOAD (`0x03`), STORE (`0x23`) funct3

| BRANCH | funct3 | LOAD | funct3 | STORE | funct3 |
|--------|--------|------|--------|-------|--------|
| BEQ  | `000` = `0x0` | LB  | `000` = `0x0` | SB | `000` = `0x0` |
| BNE  | `001` = `0x1` | LH  | `001` = `0x1` | SH | `001` = `0x1` |
| BLT  | `100` = `0x4` | LW  | `010` = `0x2` | SW | `010` = `0x2` |
| BGE  | `101` = `0x5` | LBU | `100` = `0x4` | | |
| BLTU | `110` = `0x6` | LHU | `101` = `0x5` | | |
| BGEU | `111` = `0x7` | | | | |

### SYSTEM (`0x73`) funct3

| Instruction | funct3 | imm (bits 31:20) | match (from opcodes.py) |
|-------------|--------|------------------|--------------------------|
| ECALL  | `000` = `0x0` | `0x000` | `0x00000073` |
| EBREAK | `000` = `0x0` | `0x001` | `0x00100073` |
| CSRRW  | `001` = `0x1` | csr | `0x00001073` |
| CSRRS  | `010` = `0x2` | csr | `0x00002073` |
| CSRRC  | `011` = `0x3` | csr | `0x00003073` |
| CSRRWI | `101` = `0x5` | csr | `0x00005073` |
| CSRRSI | `110` = `0x6` | csr | `0x00006073` |
| CSRRCI | `111` = `0x7` | csr | `0x00007073` |

MISC-MEM (`0x0F`): FENCE funct3=`000`, FENCE.I funct3=`001`.

---

## 4. CUSTOM instruction space — exact reserved encodings

### 4.1 The four custom major opcodes (Spec §36, Table 72)

The four custom-0…custom-3 major opcodes are the **legal** custom space in the
32-bit base instruction format. Spec text (Table 72 caption):

> "Opcodes marked as reserved should be avoided for custom instruction-set
> extensions as they might be used by future standard extensions. Major opcodes
> marked as custom-0 through custom-3 will be avoided by future standard
> extensions and are recommended for use by custom instruction-set extensions
> within the base 32-bit instruction format." — §36, Table 72.

| Custom opcode | 7-bit opcode | bits [6:5] | bits [4:2] | encodings available |
|---------------|--------------|------------|------------|---------------------|
| **custom-0** | `0x0B` = `0001011` | `00` | `010` | `2^25` (bits [31:7] free) |
| **custom-1** | `0x2B` = `0101011` | `01` | `010` | `2^25` (bits [31:7] free) |
| **custom-2** | `0x5B` = `1011011` | `10` | `110` | `2^25` (bits [31:7] free) |
| **custom-3** | `0x7B` = `1111011` | `11` | `110` | `2^25` (bits [31:7] free) |

Total legal custom space in the base 32-bit format: **4 × 2^25 = 2^27 = 134,217,728**
encodings. Within each custom opcode, `inst[31:7]` (25 bits) is entirely
unallocated — we own the whole `funct7 + rs2 + rs1 + funct3 + rd` region, so we
may impose any field layout (R/I/S/B/U-shaped or fully custom) we want.

> "RISC-V has been designed to support extensive customization and
> specialization. … we divide each RISC-V instruction-set encoding space (and
> related encoding spaces such as the CSRs) into three disjoint categories:
> standard, reserved, and custom. Standard extensions and encodings are defined
> by RISC-V International; any extensions not defined by RISC-V International are
> non-standard. … Reserved encodings are currently not defined but are saved for
> future standard extensions; once thus used, they become standard encodings.
> **Custom encodings shall never be used for standard extensions and are made
> available for vendor-specific non-standard extensions. Non-standard extensions
> are either custom extensions, that use only custom encodings, or non-conforming
> extensions, that use any standard or reserved encoding.**" — §1.3 (ISA Overview).

> "Perhaps more importantly, by condensing our base ISA into a subset of the
> 32-bit instruction word, we leave more space available for non-standard and
> custom extensions. In particular, the base RV32I ISA uses less than 1/8 of the
> encoding space in the 32-bit instruction word." — §1.5 (Base Instruction-Length Encoding).

### 4.2 Custom HINT space (Spec §2.9)

> "Table 5 lists all RV32I HINT code points. 91% of the HINT space is reserved
> for standard HINTs. The remainder of the HINT space is designated for custom
> HINTs: no standard HINTs will ever be defined in this subspace." — §2.9.

Custom HINTs are `rd=x0` integer-computational instructions (and FENCE with null
pred/fm) whose register/immediate operands encode the hint; they must not alter
architectural state. (§2.9 note: `slli x0, x0, 0x1f` and `srai x0, x0, 7` were
previously custom HINTs but are now standard HINTs used for semihosting.)

### 4.3 Compressed (RV32C) custom space (Spec §28)

> "For RV32C, shamt[5] must be zero; the code points with shamt[5]=1 are
> designated for custom extensions." — §28 (C.SLLI/C.SRLI/C.SRAI encodings).

This is a 16-bit custom space within the compressed extension, relevant only if
we adopt the C extension.

### 4.4 The standard "May-Be-Operations" route (Spec §10, Zimop / Zcmop)

For extensions whose instructions should **no-op (write x[rd]=0) instead of
trapping** when the extension is absent, RISC-V reserves 40 MOPs in the SYSTEM
major opcode rather than requiring the custom opcodes:

- **Zimop** (§10): 32 × `MOP.R.n` (reads `rs1`, writes `rd`) + 8 × `MOP.RR.n`
  (reads `rs1`+`rs2`, writes `rd`), encoded in SYSTEM `0x73`.
- **Zcmop** (§10.1): 8 × 16-bit `C.MOP.n` (n odd, 1–15), in the reserved
  `C.LUI xn, 0` space.

Exact SYSTEM-opcode encodings (from `opcodes.py`, mask `0xFFF0707F`/`0xFE00707F`):

```
mop_r_0   match=0x81C04073   mop_rr_0 match=0x82004073
mop_r_N   match=0x81C04073 mask=0xB3C0707F   # generic MOP.R pattern
mop_rr_N  match=0x82004073 mask=0xB200707F   # generic MOP.RR pattern
c_mop_1   match=0x00006081 mask=0x0000FFFF    # C.MOP.n, n odd in {1..15}
```

> "These MOPs are encoded in the SYSTEM major opcode in part because it is
> expected their behavior will be modulated by privileged CSR state." — §10.

Use the custom-0/1/2/3 opcodes when we want the decoder to **trap** on an
unimplemented `Xlattice` instruction; use MOP redefinition when we want an
**ignorable** instruction. Both are legal; they are not the same space.

---

## 5. Standard extension letters (so we know what NOT to collide with)

Canonical order/names from Spec §37.11 (Table 74) and §1.3/§37.3. One line each:

| Letter | Name | Covers |
|--------|------|--------|
| **I** | Base integer | RV32I/RV64I: integer compute, loads/stores, control flow (the base; not an "extension"). |
| **E** | Reduced base | RV32E/RV64E: 16-register reduced base. |
| **M** | Integer Multiply/Divide | MUL/MULH/DIV/REM etc.; implies `Zmmul`. |
| **A** | Atomics | LR/SC + AMO (atomic read-modify-write). |
| **F** | Single-Precision Float | FP registers + single-precision ops/loads/stores; implies `Zicsr`. |
| **D** | Double-Precision Float | Double-precision ops; implies `F`. |
| **Q** | Quad-Precision Float | 128-bit quad-precision; implies `D`. |
| **C** | Compressed | 16-bit compressed instructions. |
| **B** | Bit Manipulation | `Zba`/`Zbb`/`Zbs` (bitmanip family). |
| **P** | Packed-SIMD | Packed SIMD (legacy). |
| **V** | Vector | Vector operations (RV64V / RV32V, 1.0). |
| **H** | Hypervisor | Hypervisor extension; implies `D`. |
| **G** | General | Shorthand for `IMAFDZicsr_Zifencei` (not a single extension). |
| **Z\*** | Additional standard (unprivileged) | `Zifencei`, `Zicsr`, `Zicntr`, `Zihpm`, `Zihintntl`, `Zimop`, `Zicond`, `Zawrs`, `Zacas`, `Zabha`, `Zalasr`, `Ztso`, `Zfh`/`Zfhmin`, `Zfa`, `Zfinx`/`Zdinx`/`Zhinx`/`Zhinxmin`, `Zba`/`Zbb`/`Zbs`, `Zmmul`, `Zilsd`/`Zclsd`, … (§37.5). |
| **Ss\*** | Supervisor-level | Supervisor-mode extensions (Volume II). |
| **Sh\*** | Hypervisor-level | Hypervisor-mode extensions. |
| **Sm\*** | Machine-level | Machine-mode extensions. |

First letter after `Z` conventionally indicates the related single-letter
category (`IMAFDQLCBKJTPVH`), e.g. `Zfa` ↔ `F`, `Zba` ↔ `B` (§37.5).

---

## 6. Non-standard extension rules (Spec §37.9, §1.3)

### Naming — `X` prefix (Spec §37.9)

> "Non-standard extensions are named by using a single "X" followed by the
> alphanumeric name. The name must end with an alphabetic character. The second
> letter from the end cannot be numeric if the last letter is "p". For example,
> "Xhwacha" names the Hwacha vector-fetch ISA extension." — §37.9.

> "Non-standard extensions must be listed after all standard extensions, and,
> like other multi-letter extensions, must be separated from other multi-letter
> extensions by an underscore. For example, an ISA with non-standard extensions
> Argle and Bargle may be named "RV64IZifencei_Xargle_Xbargle". … If multiple
> non-standard extensions are listed, they should be ordered alphabetically."
> — §37.9.

**So our extension is named `Xlattice`** and an ISA string is, e.g.
`RV32IMXlattice` or `RV32IM_Xlattice` (underscores optional between extensions;
`Xlattice` goes last, after all standard extensions — §37.4/§37.9).

### Categorization & decoder interaction (Spec §1.3)

> "An extension may be categorized as either standard, custom, or non-conforming."
> — §1.3.

- **Custom extension** = uses *only* custom encodings (custom-0/1/2/3, custom
  HINTs, the RV32C `shamt[5]=1` space). This is the only fully-safe, never-collides
  class — standard extensions are *prohibited* from ever using these opcodes.
- **Non-conforming extension** = uses *any* standard or reserved encoding. Legal
  but risky: a future standard extension may claim a reserved encoding you used.
- **Reserved** encodings: behavior on decode is **UNSPECIFIED** (may trap or be
  reused as a non-conforming extension) — §2.2: "The behavior upon decoding a
  reserved instruction is UNSPECIFIED. Some platforms may require that opcodes
  reserved for standard use raise an illegal-instruction exception. Other
  platforms may permit reserved opcode space be used for non-conforming extensions."

**Rule we adopt:** `Xlattice` is a **custom extension** — every `Xlattice`
instruction is placed in custom-0 (`0x0B`), custom-1 (`0x2B`), custom-2 (`0x5B`),
and/or custom-3 (`0x7B`), never in standard/reserved opcodes. The decoder treats
the four custom opcodes as four disjoint 25-bit namespaces; the base ISA traps
them as illegal unless `Xlattice` is implemented.

### Custom CSRs

> "Custom extensions might add CSRs for which accesses have side effects on
> either reads …" — §6.1.1 (CSR access ordering). Custom CSR address space is
> defined in the Privileged spec (Volume II) — out of scope here, but `Xlattice`
> CSRs must use the custom CSR ranges, not standard CSR numbers.

---

## 7. Quick assignment checklist for Xlattice

1. Every `Xlattice` 32-bit instruction uses one of `0x0B / 0x2B / 0x5B / 0x7B`
   as its 7-bit opcode — **never** `0x13`, `0x33`, `0x73`, or any reserved opcode.
2. Bits `[31:7]` of each custom opcode are 25 free bits; define our own
   `funct7`/`funct3` sub-fields (we are not bound to the standard R/I/S/B/U
   layout, but reusing it keeps the decoder uniform).
3. Name the extension **`Xlattice`**; append after all standard extensions in the
   ISA string (`RV32IM_Xlattice`, versioned as `Xlattice1p0` if needed — §37.10).
4. Custom CSRs (if any) go in the custom CSR ranges (Privileged spec), not
   standard CSR numbers.
5. Decide trap-vs-ignore semantics per instruction: trap = custom opcode;
   ignore (write `rd=0`) = Zimop `MOP.R.*`/`MOP.RR.*` redefinition (§10).
