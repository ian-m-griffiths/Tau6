# CPU Integration Status — the working balanced-ternary circuits

This is the "get it working now" ledger: what is wired into `rtl/cpu.v`, what is
verified standalone, and the one honest architectural finding (the field-calculus
pod is a *memory* shape, not a register operand).

Every line below was re-verified this session with iverilog 12.0 and yosys 0.52
(real `rtl/sky130_fd_sc_hd.lib`).

---

## 1. Wired into `cpu.v` (verified running)

`cpu.v` is a single-cycle, 8-register, 16-instruction balanced-ternary CPU.
Word = 12 trits = 24 bits = an Eisenstein integer `a + b·ω` (ω² = ω−1).

| op | name | semantics | Lean proof |
|----|------|-----------|------------|
| 0 | TADD | `ra + rb` (coefficient-wise balanced add) | TernaryCell / ternary_gates.v |
| 1 | TSUB | `ra − rb` (negate = free digit-swap) | ternary_gates.v |
| 2 | TROT | `rd = ωᵏ·ra` (Z₆ gauge change, no multiplies) | Gauge.lean |
| 3 | TNORM | `N(a,b) = a²+ab+b²` → a-field | Gauge.lean / Conventions.lean |
| 4 | LDI | 9-bit two's-complement → balanced trit | ternary_gates.v `s2t6` |
| 5 | TMUL | Eisenstein multiply, w²=w−1 (3 products) | Gauge.lean |
| 6 | TCONJ | `conj(a,b) = (a+b, −b)` | Conjugate.lean L27 |
| 7 | TDOT | `(z·conj w).a = ac+ad+bd` → a-field | DotWedge.lean L32/L49 |
| 8 | TWEDGE | `(z·conj w).b = bc−ad` → a-field | DotWedge.lean L35/L58 |
| 9 | TSYMDOT | `N(z+w)−N(z)−N(w) = 2ac+ad+bc+2bd` | SymDot.lean L33/L57 |
| F | HLT | halt | — |

The GA cells live in `rtl/ga_ops.v` (`tconj_trits`, `ga_split_trits`, plus the
exact-width `tconj`/`tdot`/`twedge`/`tsymdot` + `tnorm_full`).

### Storage is now TERNARY

`cpu.v`'s register file is `tregfile_2r1w` (`rtl/ternary_mem.v`): a 2-read-port +
1-write-port 12-trit word array with the **11=NEVER canary** on all three ports.
`ovf` now also latches the canary — a `2'b11` on any read or write path sets the
fault bit. (The 2-bit/trit encoding is a *standard binary cell*, storage.md §0;
the ternary value is the encoding + the canary, not a 3-level physical cell —
that's the honest statement.)

### Verified

- `cpu_tb.v` — ALL PASS (base ISA + TMUL/TROT/TNORM + 289-pair word checks).
- `cpu_ga_tb.v` — ALL PASS (6561-combo GA cell sweep + 16-instr lockstep;
  `conj_involutive`, `wedge_antisymm`, `symdot_comm` exercised end-to-end).
- `tregfile_2r1w_tb.v` — ALL PASS (reset, 2-port read, we-gate, canary on all ports).
- `ga_ops_tb.v` — 10,561 vectors → **52,805 assertions, 0 failed** (exact-width cells).
- yosys (sky130): **CPU chip area 62,533.72 µm²** (was 61,689.16 before the ternary
  regfile + canary; +844 µm² ≈ +1.4%). Sequential elements unchanged at 5355.14 µm²
  (192 FFs — the regfile was already 8×24 bits; only the canary logic + write mux
  added area).

---

## 2. Verified STANDALONE (not in the register ISA — and why)

These are built, iverilog-verified, and yosys-checked, but they are **pod
datapaths**, not register ALU ops:

| module | file | result |
|--------|------|--------|
| TRELAX | `rtl/trelax.v` | 1 heat step `u/3 + Σnb/9` (6-pt hex Laplacian); `trelax_tb` 7/7 PASS |
| TGRAD | `rtl/grad_recon.v` `tgrad_cell` | ∇F = (div, curl); 28 checks PASS |
| TRECON | `rtl/grad_recon.v` `trecon_cell` | ∇⁻¹ canonical section; round-trip + gauge-invariance PASS |
| ternary memory cells | `rtl/ternary_mem.v` | `tregfile` + `trit_canary` + `pack4/5`; exhaustive 3⁴+3⁵ round-trips PASS |
| ternary FF cells | `rtl/ternary_ff.v` | `tff_latch`/`tff_edge`/`tword_ff`; PASS |

### The finding (honest, not a dodge)

TGRAD/TRECON/TRELAX operate on a **7-cell hex pod** (center + 6 ring at the Z₆
units ωᵏ) — 7 × 6 trits = 42 trits = 84 bits of field per pod. That is a
**memory-resident shape**, not a 2-operand register word. Forcing it through the
8-register / 2-operand / 16-instruction ISA would be Procrustean: it would eat
the entire register file for one pod and misrepresent "the pod *is* the memory"
— the engine's thesis that computation lives in addresses/names, not pulses.

Wiring these in properly needs:
1. a **field RAM** (a `tregfile`-style array over a lattice of cells), and
2. **neighborhood address generation** (the 6 Z₆ offsets of a cell) — i.e. a
   load/store path and an address unit.

That is the lattice-memory engine itself — the next real milestone, not a
"wire it in" step. The pod datapaths above are exactly the per-cell compute it
will need, already built and tested.

### The gauge story (as demanded)

∇ is a 6→2 map with a 4-dimensional nullspace (constant + 3 ring "checkerboard"
modes + the center), so TRECON is defined only **up to gauge**. It implements one
canonical exact-integer section (source on ω⁰,ω¹; everything else 0). Tests cover:
exact round-trip in canonical gauge; the gauge-invariant identity
`TGRAD(TRECON(TGRAD F)) = TGRAD F`; and constant-shift → zero gradient (the
discrete Σ(O−E)=0 conservation). The minimum-norm dipole reconstruction needs ÷6
(non-orthogonal Eisenstein basis, norm a²+ab+b²) — the exact integer section was
chosen instead of a non-ternary divide.

---

## 3. The honest scoreboard (unchanged, now with circuits)

| axis | verdict |
|------|---------|
| names/addresses | ternary wins **exponentially**, (3/2)ⁿ |
| transport | ternary wins ~2.7–6.3× (mostly radix-agnostic low-swing + the free null) |
| compute | ternary loses ~1.26–1.9× per bit (the 2-threshold tax) |

The GA instructions and the field calculus are the *structure* the wins run on;
they do not overturn the compute verdict — the dot/wedge/symdot cell is a 4-product
multiplier, i.e. compute, and it costs (ga_split_trits ≈ 32,944 µm² alone). The
engine's edge remains per-address, not per-op.
