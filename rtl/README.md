# rtl/ — the balanced-ternary circuits

Verilog for the Tau Architecture's datapath: a single-cycle balanced-ternary CPU, the
geometric-algebra (GA) instructions, the field-calculus pod datapaths, and ternary memory.
Every module is iverilog-tested and yosys-mapped.

**Encoding (2 bits/trit):** `01 = +1` (push), `00 = 0` (null), `10 = −1` (pull), `11 = NEVER`
(never produced — `TernaryCell.lean` `encode_never_both`). A **word = 12 trits = 24 bits** =
an Eisenstein integer `a + b·ω` (ω² = ω−1): `a` = bits [11:0] (6 trits), `b` = bits [23:12].

## Modules

| file | modules | what |
|---|---|---|
| `ternary_gates.v` | `tadd1`, `tadd_trits`, `tnorm_trits`, … | the ternary gate primitives (balanced adder, norm) |
| `tmul_opt.v` | `tmul_sa`, `tmul_eisen_trits`, `tnorm_trits_opt`, `tadd_n`, `tsub_n` | Eisenstein multiply + shift-add multiplier + shared adders |
| `ga_ops.v` | `tconj_trits`, `ga_split_trits`, `tconj`, `tdot`, `twedge`, `tsymdot`, `tnorm_full` | the GA cells (conj / dot / wedge / symdot) |
| `grad_recon.v` | `tgrad_cell`, `trecon_cell` | field calculus: ∇F = div⊕curl, and the canonical ∇⁻¹ section |
| `trelax.v` | `trelax_cell` | one heat-equation step (6-pt hex Laplacian) |
| `ternary_ff.v` | `tff_latch`, `tff_edge`, `tword_ff` | ternary sequential cells |
| `ternary_mem.v` | `tregfile`, `tregfile_2r1w`, `trit_canary`, `tword_canary`, `pack4/5_trits`, `unpack4/5_trits` | ternary register file + 11=NEVER canary + trit packing |
| `cpu.v` | `cpu` | the 11-opcode single-cycle CPU |
| `hex_field_accel.v` | `hex_field_accel` | the TGRAD/TRECON/TRELAX accelerator as a memory-mapped peripheral (0x2000) |
| `ternary_link_periph.v` | `ternary_link_periph` | the ternary transport link, memory-mapped (0x3000): null-count + canary + energy |
| `tau_soc.v` | `tau_soc` | the full SoC: PicoRV32 + RAM + hex MMU + field accel + ternary link + Xlattice CFU |

## ISA (`cpu.v`)

16-bit instruction `{op[3:0], rd[2:0], ra[2:0], rb[2:0]}` (binary host encoding; the *data
path* is ternary). `LDI` is `{4'h4, rd, imm[8:0]}`.

| op | name | semantics | Lean |
|----|------|-----------|------|
| 0 | TADD | `rd = ra + rb` | — |
| 1 | TSUB | `rd = ra − rb` (negation is a free digit-swap) | — |
| 2 | TROT | `rd = ωᵏ·ra`, k = rb (Z₆ gauge change, no multiplies) | `Gauge.lean` |
| 3 | TNORM | `rd = a²+ab+b²` → a-field | `Conventions.lean` |
| 4 | LDI | 9-bit two's-complement → balanced trit | — |
| 5 | TMUL | Eisenstein multiply `(a+bω)(c+dω)` | `Gauge.lean` |
| 6 | TCONJ | `conj(a,b) = (a+b, −b)` | `Conjugate.lean` |
| 7 | TDOT | `(z·conj w).a = ac+ad+bd` → a-field | `DotWedge.lean` |
| 8 | TWEDGE | `(z·conj w).b = bc−ad` → a-field | `DotWedge.lean` |
| 9 | TSYMDOT | `N(z+w)−N(z)−N(w) = 2ac+ad+bc+2bd` → a-field | `SymDot.lean` |
| F | HLT | halt | — |

The register file is `tregfile_2r1w` (2 read ports + 1 write port) with the **11=NEVER
canary** on all three ports, wired into `ovf`.

## Testbenches (all verified PASS)

Run **from the repo root** (`/home/ian/dsh/projects/lattice/`), because `trit_functions.vh`
is included as `rtl/trit_functions.vh`. **Do NOT use `-g2012`** (`program` is an SV keyword).

```bash
# ternary sequential cells
iverilog -o /tmp/t1.out rtl/ternary_ff.v rtl/ternary_ff_tb.v && vvp /tmp/t1.out

# TRELAX heat step (7/7)
iverilog -o /tmp/t2.out rtl/ternary_gates.v rtl/trelax.v rtl/trelax_tb.v && vvp /tmp/t2.out

# ternary memory (regfile + canary + pack4/5, exhaustive)
iverilog -o /tmp/t3.out rtl/ternary_ff.v rtl/ternary_mem.v rtl/ternary_mem_tb.v && vvp /tmp/t3.out

# field calculus TGRAD + TRECON (28 checks)
iverilog -o /tmp/t4.out rtl/ternary_gates.v rtl/grad_recon.v rtl/grad_recon_tb.v && vvp /tmp/t4.out

# GA cells (52,805 assertions; ~3 min to run)
iverilog -g2001 -s ga_ops_tb -o /tmp/t5.out rtl/tmul_opt.v rtl/ga_ops.v rtl/ga_ops_tb.v && vvp /tmp/t5.out

# the CPU's ternary register file (2R1W + canary)
iverilog -o /tmp/t6.out rtl/ternary_ff.v rtl/ternary_mem.v rtl/tregfile_2r1w_tb.v && vvp /tmp/t6.out

# CPU base ISA
iverilog -o /tmp/t7.out rtl/ternary_gates.v rtl/tmul_opt.v rtl/ga_ops.v rtl/ternary_ff.v \
  rtl/ternary_mem.v rtl/cpu.v rtl/cpu_tb.v && vvp /tmp/t7.out

# CPU GA instructions (opcodes 6-9)
iverilog -o /tmp/t8.out rtl/ternary_gates.v rtl/tmul_opt.v rtl/ga_ops.v rtl/ternary_ff.v \
  rtl/ternary_mem.v rtl/cpu.v rtl/cpu_ga_tb.v && vvp /tmp/t8.out

# the full SoC — PicoRV32 + hex MMU (0x1000) + field accel TGRAD/TRECON/TRELAX (0x2000)
# + ternary transport link (0x3000) + Xlattice CFU (PCPI).  10/10 assertions PASS.
iverilog -o /tmp/t9.out picorv32/picorv32.v rtl/ternary_gates.v rtl/tmul_opt.v rtl/ga_ops.v \
  rtl/xlattice_cfu.v rtl/picorv32_pcpi_xlattice.v rtl/hex_encode.v rtl/hex_decode.v \
  rtl/hex_pod_addr.v rtl/hex_mmu_periph.v rtl/grad_recon.v rtl/trelax.v \
  rtl/hex_field_accel.v rtl/ternary_link.v rtl/ternary_link_periph.v rtl/tau_soc.v \
  rtl/tau_soc_tb.v && vvp /tmp/t9.out
```

Expected tail of each: `ALL … PASSED` (the GA cell suite prints `GA OPS: ALL ASSERTIONS
PASSED` with `10561 vectors, 52805 assertions PASSED, 0 FAILED`).

## Synthesis (yosys)

```bash
bash rtl/yosys_report.sh    # maps cpu.v to the sky130 liberty, writes rtl/yosys_report.txt
```

Current result: **CPU chip area ≈ 62,533.72 µm²** (sequential 8.56%). This is the *gate-area*
estimate of the 8-register core — **not** a chip: no I/O pads, routing overhead, clock tree,
or memory macro.

## Honest caveats

1. **Compute is a measured loss, not a win.** The mod-3 sum `⊕` is the open wall at
   **1.42×/bit**; `ThresholdLowerBound.lean` proves the 2-threshold tax (`2·ln2/ln3 ≈ 1.26×`).
   Ternary wins on *names* (`3ⁿ` vs `2ⁿ`) and *transport*, not per-bit arithmetic.
2. **TGRAD/TRECON/TRELAX are pod datapaths, not register ops.** They operate on a 7-cell hex
   pod (center + 6 ring at the Z₆ units); the pod is a *memory* shape, so these are verified
   standalone (`grad_recon_tb`, `trelax_tb`) and connect to a field-RAM, not the register ALU.
3. **TRECON is defined only up to gauge** — it implements one canonical exact-integer section;
   the minimum-norm inverse needs ÷6 (non-orthogonal Eisenstein basis).
