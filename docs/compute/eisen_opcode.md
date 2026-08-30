# Eisenstein-Multiply Opcode (TMUL) — ISA change + measured area

**2026-08-29.** Adds the missing instruction that routes the ternary CPU datapath
through `tmul_eisen_trits` (the 3-product Karatsuba Eisenstein lattice multiplier
in `rtl/tmul_opt.v`). Up to now the CPU had no instruction that used it — only
`TNORM` used the multiply pipeline, and that via `tnorm_trits_opt` (the
2-product norm identity). This document records the exact ISA change, the
equivalence proof, and the measured synthesis area before/after.

Calibration legend: **DIRECT** = measured/proved this session; the rest is
context.

---

## 1. The opcode

`TMUL` is opcode **`5`** (`4'h5`), using the same 3-register format as the other
ALU ops. No instruction-word format change — opcodes `5`–`E` were already
unassigned, so this is a **non-invasive** ISA addition.

```
{op[3:0], rd[2:0], ra[2:0], rb[2:0]}          (16-bit binary host word)

op   name    semantics
0    TADD    rd = ra + rb            coefficient-wise balanced add
1    TSUB    rd = ra - rb
2    TROT    rd = w^k * ra           Z6 gauge change
3    TNORM   rd = N(a_ra, a_rb)      norm scalar -> a-field
4    LDI     rd = (imm, 0)
5    TMUL    rd = ra * rb            Eisenstein lattice multiply (this change)
F    HLT
```

**TMUL `rd, ra, rb`** — treat `ra` as the lattice point `(a,b) = a + b·w` and
`rb` as `(c,d) = c + d·w`, with the 60-degree convention `w² = w − 1`, and
compute

```
(a + b·w)(c + d·w) = A + B·w
    A = a·c − b·d                          (fits 12 trits)
    B = a·d + b·c + b·d = (a+b)(c+d) − a·c (fits 13 trits)
```

The exact products `A` (12 trits) and `B` (13 trits) are wider than a 12-trit
word (6+6). Following the existing `TNORM` fit convention, the instruction
stores the **low 6 trits** of each coefficient and flags overflow:

```
rd_a = low 6 trits of A      rd_b = low 6 trits of B
ovf  = 1  when A or B has any non-null trit above position 5
```

i.e. `rd_a = A[11:0]`, `rd_b = B[11:0]`, `ovf = (|A[23:12]) | (|B[25:12])`.
This is the *same* "compute exactly, return low 6 trits, set `ofit` if wider"
convention `tnorm_trits`/`tnorm_trits_opt` already use (`ofit` is latched into
the CPU's `ovf` output exactly like TNORM's).

**Exactly what changed in `rtl/cpu.v`:**

1. Instantiated `tmul_eisen_trits #(.NTRITS(6))` on `(ra_a, ra_b, rb_a, rb_b)`
   plus a fit-check wire `tmul_ofit = (|tmul_A[23:12]) | (|tmul_B[25:12])`.
2. Added the ALU case `4'h5` writing `{tmul_B[11:0], tmul_A[11:0]}` with
   `wovf = tmul_ofit`.
3. **Re-applied the tnorm norm-identity swap** — changed `tnorm_trits` →
   `tnorm_trits_opt` (from `tmul_opt.v`). The "optimized baseline" of
   24,314 µm² quoted in `TERNARY_COMPUTE_SURVEY.md` comes from this swap, but
   the committed `cpu.v` had reverted to the naive `tnorm_trits` (26,713 µm²).
   Both states are re-measured below so the before/after is unambiguous.
4. Added `rtl/tmul_opt.v` to the read list in `rtl/yosys_report.sh` (both
   `tnorm_trits_opt` and `tmul_eisen_trits` live there).

No change to the register file, the decode, or the single-cycle write path —
the multiplier is a purely combinational ALU cone that is always present (it is
not clock-gated by the opcode), which is exactly what the area delta measures.

---

## 2. Equivalence check

Two independent proofs, both re-run this session (yosys 0.52, iverilog 12.0):

### (a) SAT — combinational bit-identity, all inputs

`miter_eisen` (already in `rtl/miters.v`) and a new `miter_eisen_fit` prove the
multiplier *and* the CPU's exact truncation+flag semantics are bit-identical to
the 4-product reference `tmul_eisen_naive` for **every reachable input** (the
forbidden `2'b11` trit state is excluded via the `invalid` assumption):

```
yosys -p "read_verilog rtl/ternary_gates.v rtl/tmul_opt.v rtl/miters.v; \
          hierarchy -top <miter>; flatten; opt; \
          sat -set invalid 0 -prove diff 0"
```

| miter | claim | result |
|-------|-------|--------|
| `miter_eisen` | `tmul_eisen_trits` == `tmul_eisen_naive` (full 12+13-trit width) | **SUCCESS** — no counterexample (113,209 vars) |
| `miter_eisen_fit` | CPU store `{B[11:0], A[11:0]}` + `ovf` flag == same from naive | **SUCCESS** — no counterexample (112,993 vars) |

### (b) iverilog — CPU lockstep assertion

`cpu_tb.v` runs the CPU against a plain-integer reference model in lockstep.
`program.hex` was extended with one `TMUL` (replacing the redundant identity
`TROT k=0` at address 13):

```
D     TMUL r6, r6, r7     r6 = (0, 35)    [ (5−5w)(−7+7w) = 35w ]
```

hand-verified: `A = 5·(−7) − (−5)·7 = 0`, `B = 5·7 + (−5)(−7) + (−5)·7 = 35`.

```
iverilog -g2001 -s cpu_tb rtl/ternary_gates.v rtl/tmul_opt.v rtl/cpu.v rtl/cpu_tb.v
headline TMUL (5-5w)(-7+7w) = 35w : r6 = (0, 35)    OK
ALL ASSERTIONS PASSED — ternary datapath verified.
```

The reference model gained the opcode-5 case (`A = a·c − b·d`,
`B = a·d + b·c + b·d`) and every register is compared after every instruction —
all 16 steps match, `ovf == 0` as expected (the test vector fits 6 trits).
Broader (full-range + overflow) cell-level coverage is `tmul_opt_tb.v`, re-run
this session and **ALL PASSED, 0 errors**: `tmul_eisen_trits` vs the integer
`(A,B) = (ac−bd, ad+bc+bd)` over 6,561 boundary vectors (9⁴ at the trit
carry/overflow boundaries ±364, ±40, ±13, ±1, 0) + 1,000 random vectors, plus
`tmul_trits_opt`/`tnorm_trits_opt` over 5,721 stride+random vectors.

---

## 3. Measured area (yosys 0.52, `sky130_fd_sc_hd__tt_025C_1v80`)

Same flow as `rtl/yosys_report.sh` FLOW 1/2:
`read_verilog … ; hierarchy -top cpu; proc; opt; flatten; techmap;
abc -liberty rtl/sky130_fd_sc_hd.lib; dfflibmap -liberty rtl/sky130_fd_sc_hd.lib;
stat -liberty rtl/sky130_fd_sc_hd.lib`.

| cpu.v state | cells | Chip area (µm²) | vs optimized |
|-------------|------:|----------------:|-------------:|
| naive `tnorm_trits` (committed baseline) | 3,970 | 26,713.12 | +9.9% |
| `tnorm_trits_opt` (**optimized baseline**) | 3,576 | **24,314.57** | — |
| `tnorm_trits_opt` + **TMUL opcode** (final) | 6,104 | **40,080.94** | **+64.8%** |

**The TMUL instruction adds `40,080.94 − 24,314.57 = 15,766.37 µm²` (+64.8%)
over the optimized CPU** (and +50.0% over the original naive CPU). Overflow is
flagged, not trapped; the fit-check itself is a few OR gates.

### Why it is this large — measured breakdown

The instruction is expensive because `tmul_eisen_trits` is **three** scalar
balanced multipliers (two 6-trit + one 7-trit shift-add), and in a single-cycle
CPU they are always computing. Measured in isolation:

| module (NTRITS=6) | cells | area (µm²) |
|-------------------|------:|-----------:|
| `tmul_sa` (one 6×6-trit scalar multiplier) | 794 | 5,052.35 |
| `tmul_eisen_trits` (3 products) | 3,473 | 21,276.66 |
| `tmul_eisen_naive` (4 products, reference) | 3,968 | 24,907.64 |

The Karatsuba win is real and re-measured: `tmul_eisen_trits` is **−14.6%**
(21,276.66 vs 24,907.64 µm²) against the 4-product naive — matching the figure
in `TERNARY_COMPUTE_SURVEY.md`. But that saving is *relative*; the absolute cost
of *any* Eisenstein multiply instruction is three scalar multipliers.

The CPU delta (+15,766 µm²) is **less** than the standalone cell (21,277 µm²)
because `flatten; opt; abc` shares the `a·c = ra_a·rb_a` product with
`tnorm_trits_opt`'s `a·b = ra_a·rb_a` term (both compute `ra_a × rb_a`): one
6×6 `tmul_sa` (5,052 µm²) is recovered. 21,277 − 5,052 ≈ 16,225, matching the
observed 15,766 within abc's remapping noise.

---

## 4. Honest verdict

1. **The opcode is correct and cheap to add at the ISA level** — one free opcode,
   no format change, proven bit-identical (SAT) and instruction-identical
   (iverilog lockstep) to the reference.

2. **The area cost is real and large**: +64.8% on the optimized CPU. A ternary
   Eisenstein multiply is three scalar balanced multipliers, and this trit
   encoding (2 wires/trit, one-hot-per-direction) already pays 2.0–4.3× per
   gate over binary (`docs/compute/gate_area.md`). So the *instruction* does not
   come close to free — it is the single largest ALU structure in the core.

3. **The Karatsuba identity still earns its keep** — −14.6% versus the naive
   4-product form — but it cannot make a 3-multiplier datapath cheap. If area is
   the metric, the lever is not the multiply identity but *when* the multiplier
   computes (clock-gating / a multi-cycle or shared-MAC datapath), which is a
   follow-up, not this change.

*All numbers above were measured this session with yosys 0.52 and
`rtl/sky130_fd_sc_hd.lib`; the full log is in `rtl/yosys_report.txt` (final
CPU = 40,080.94 µm²).*
