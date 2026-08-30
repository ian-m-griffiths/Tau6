# Hybrid RTL — the binary TGRAD reduction, runnable and verified

**2026-08-30.** This is the missing `hybrid_rtl.md` sibling named in `hybrid_verdict.md`
("the six `hybrid/*.md` siblings named in the brief … are **not on disk**"). It delivers the
**runnable prototype** for the hybrid cut's compute half: a *binary* implementation of the
TGRAD div/curl reduction that reproduces the *ternary* `tgrad_cell` result, so the claim
"compute stays binary" is no longer a design note but a tested module.

**Calibration legend** (house standard): **DIRECT** = measured/proved/verbatim from `rtl/`;
**DERIVED** = arithmetic on DIRECT numbers; **OURS** = design claim following from DIRECT.

---

## 0. The answer, up front

> **`rtl/binary_tgrad.v` decodes the ternary-encoded field values to signed integers and
> computes `div = F0−F2−F3+F5`, `curl = F1+F2−F4−F5` with six plain 2's-complement adds. In
> iverilog lockstep it reproduces `tgrad_cell` bit-for-bit (15/15 assertions, `F0=+3, F1=+9 →
> div=3, curl=9`). The binary full adder is 1.92× cheaper in energy (4.33× in area) than the
> balanced-ternary `tadd1`, so the reduction's adder tree is ~1.3–2× cheaper in binary — but the
> honest module-level number is that the *standalone* binary module is ~2× larger once the
> ternary→binary decode is included, exactly the boundary tax `conversion_cost.md` already
> priced.**

---

## 1. What was built

### 1.1 `rtl/binary_tgrad.v` — the binary reduction

Same TGRAD spec as `grad_recon.v` L25–33 (`div = Σ_k Re(ωᵏ)F_k = F0−F2−F3+F5`,
`curl = Σ_k Im(ωᵏ)F_k = F1+F2−F4−F5`), but the datapath is binary:

1. **decode** each 6-trit field value to a signed 2's-complement integer with the repo's
   existing `t2b` (`rtl/converters.v` — the O(n) Horner `r = 3r + dᵢ` value conversion that
   already sits on the hybrid boundary, `conversion_cost.md` §1–2). 6 instances.
2. **reduce** with six signed adds in two 3-adder trees, mirroring `tgrad_cell`'s
   `u_d01/u_d23/u_div` and `u_c01/u_c23/u_cur`:
   ```
   d01 = f0 − f2 ;  d23 = f5 − f3 ;  div  = d01 + d23     (3 adds)
   c01 = f1 + f2 ;  c23 = f4 + f5 ;  curl = c01 − c23     (3 adds)
   ```
3. **width**: `|F| ≤ 364`, so `|div|,|curl| ≤ 4·364 = 1456 < 2048 = 2¹¹` → a signed 12-bit
   word is lossless at full range, the same "12-bit signed adds" width `emulation_field.md` §0
   assigns to the binary TGRAD. The center cell is accepted for drop-in interface parity and
   ignored (Σ_k ωᵏ = 0, the additive gauge — identical to `tgrad_cell`).

No trit gates, no carry-free negation trick: every arithmetic op is a plain 2's-complement
add/subtract. Verilog-2001, iverilog-clean (`-Wall` silent), synthesizable (yosys 0.52 → sky130
below).

### 1.2 `rtl/binary_tgrad_tb.v` — lockstep against the ternary tree

The testbench drives the **same pod** into `tgrad_cell` (ternary) and `binary_tgrad` (binary)
and asserts both agree with the integer formula *and with each other* — five pods × three
assertions:

| pod (F0..F5) | ternary div/curl | binary div/curl | expect |
|---|---|---|---|
| `(3, 9, 0, 0, 0, 0)`  *(the `tau_field_tb.v` field)* | 3, 9 | 3, 9 | 3, 9 |
| `(7, 7, 7, 7, 7, 7)`  *(additive gauge)* | 0, 0 | 0, 0 | 0, 0 |
| `(3, −9, 5, −2, 4, 1)` *(mixed signs)* | 1, −9 | 1, −9 | 1, −9 |
| `(364, 364, −364, −364, 364, −364)` | 728, 0 | 728, 0 | 728, 0 |
| `(364, 364, −364, −364, −364, 364)` | 1456, 0 | 1456, 0 | 1456, 0 |

## 2. Test result

```bash
cd /home/ian/dsh/projects/lattice
iverilog -o /tmp/bintgrad.out rtl/converters.v rtl/ternary_gates.v rtl/grad_recon.v \
  rtl/binary_tgrad.v rtl/binary_tgrad_tb.v && vvp /tmp/bintgrad.out
```

```
binary_tgrad_tb: lockstep ternary vs binary TGRAD reduction
  pod(3,9,0,0,0,0): ternary div/curl = 3,9  binary = 3,9  (expect 3,9)
  pod(7,7,7,7,7,7): ternary div/curl = 0,0  binary = 0,0  (expect 0,0)
  pod(3,-9,5,-2,4,1): ternary div/curl = 1,-9  binary = 1,-9  (expect 1,-9)
  pod(364,364,-364,-364,364,-364): ternary div/curl = 728,0  binary = 728,0  (expect 728,0)
  pod(364,364,-364,-364,-364,364): ternary div/curl = 1456,0  binary = 1456,0  (expect 1456,0)
ALL ASSERTIONS PASSED — binary_tgrad reproduces tgrad_cell.
```

**Result: PASS, 15/15 assertions.** The binary reduction reproduces the ternary field-calculus
result exactly, including at the `div = 1456` full-range ceiling (no 12-bit overflow).

---

## 3. The honest comparison

**This prototype demonstrates *correctness*, not energy.** No energy is measured here; the cost
numbers below are the repo's existing measurements, cited with their source.

### 3.1 Per-adder (the number the task quotes) — binary wins 1.92× energy / 4.33× area

**DIRECT** (`docs/compute/field_calculus/trelax_measured.md` §2, §5.2; `conversion_cost.md` §4):

| cell | energy / toggle | transistors | sky130 cells / area |
|---|---|---|---|
| balanced-ternary `tadd1` | **0.355 fJ** | 192 T | 25 / 146.4 µm² |
| binary `bin_fa` | **0.185 fJ** | 58 T | 2 / 33.8 µm² |
| **ratio** | **1.92×** | **3.31×** | **4.33×** |

**Word-level area** (`rtl/word_fairfight.txt`, equal-information: 6 trits = 729 states vs
10 bits = 1024 states): `wf_tadd6` (6× `tadd1`) = **969.68 µm² / 167 cells** vs `wf_badd10`
(10× `bin_fa`) = **258.998 µm² / 48 cells** → **3.74× area, 3.94×/bit**. (Note: this file is
*area*, not energy; the *1.92× energy* figure lives in `trelax_measured.md`.)

### 3.2 Per-reduction — the 1.92× is diluted by width, to ~1.3× energy

The 6-add reduction uses a different adder *count* in each base: ternary `tgrad_cell` runs
6 adders at **8 trits** = **48 `tadd1`** (`grad_recon.v` L62), binary runs 6 adders at
**12 bits** = **72 `bin_fa`**. So the per-*adder* 1.92× does not survive intact:

| | adders | energy (DIRECT per-cell × count) |
|---|---|---|
| ternary TGRAD | 48 `tadd1` | 48 × 0.355 fJ = **17.0 fJ** |
| binary TGRAD | 72 `bin_fa` | 72 × 0.185 fJ = **13.3 fJ** |
| **saving** | | **~3.7 fJ / reduction → 1.28× cheaper** (DERIVED) |

This is the same verdict as `emulation_field.md` §1 ("net reduction ≈ parity to 1.5× worse for
ternary") and `trelax_measured.md` §5.2 ("1.2–1.5× the binary equivalent"): the binary adder is
**1.92× cheaper per gate**, and the reduction is **~1.3× cheaper overall**, because binary needs
12 bits where ternary needs 8 trits.

### 3.3 Module-level (this session, yosys 0.52 → sky130) — the decode is the honest cost

Synthesized this session with the same flow as `word_fairfight.sh`
(`read_verilog …; hierarchy -top …; proc; opt; flatten; techmap; abc -liberty rtl/sky130_fd_sc_hd.lib;
stat -liberty …`):

| module | cells | area | what it is |
|---|---|---|---|
| `tgrad_cell` | 895 | **5 489.01 µm²** | ternary reduction, no decode (native trits) |
| `t2b` (one) | 155 | 1 431.37 µm² | ternary→binary value decode |
| `binary_tgrad` | 1 093 | **11 277.07 µm²** | 6× `t2b` + 6 signed adds |

Two honest reads, both true:

1. **The reduction adder tree itself is ~2× cheaper in binary.** Stripping the decode,
   `binary_tgrad`'s arithmetic ≈ 11 277 − 6×1 431 ≈ **2 689 µm²**, vs `tgrad_cell`'s **5 489 µm²**
   → the binary adder tree is **~2.04× smaller** (DERIVED), consistent with the 1.92× energy /
   4.33× area per-gate ratios.
2. **The standalone module is ~2× larger in binary** (11 277 vs 5 489 µm², **2.06×**), because the
   ternary tree operates *natively* on the stored trits and pays **no decode**, while the binary
   tree must first convert six ternary-encoded values to signed integers (6 × 1 431 µm² ≈
   8 588 µm² of the total).

This is exactly the boundary tax `conversion_cost.md` §4–5 priced: the value decode is an **O(n),
one-time-per-operand** cost (155 cells / 1.4 kµm² each), while the 1.92× adder advantage is a
**per-add** saving that compounds. For a *single isolated* TGRAD the decode dominates and flips
the total; for a *pipeline* of ops on already-decoded values the decode amortizes and the binary
adder tree wins. Neither `hybrid_verdict.md`'s "no compute win" nor this file's "1.92× per adder"
is contradicted — they are the same number read at two different amortization horizons.

---

## 4. What the hybrid cut buys (one line)

> **A binary full adder is 1.92× cheaper in energy (4.33× in area) than the balanced-ternary
> `tadd1`, and the six-add TGRAD reduction is the *same* six signed adds in both bases — so
> `rtl/binary_tgrad.v` reproduces `tgrad_cell`'s div/curl exactly (iverilog lockstep, 15/15)
> while its adder tree runs ~1.3× cheaper in energy and ~2× smaller in area — the one honest
> asterisk being that the ternary→binary decode (6× `t2b` ≈ 8.6 kµm²) makes the *standalone*
> binary module ~2× larger until that boundary conversion is amortized over a stream of ops.**

---

## Sources

- `rtl/binary_tgrad.v`, `rtl/binary_tgrad_tb.v` — this prototype (new).
- `rtl/grad_recon.v` — the ternary `tgrad_cell` being reproduced (48 `tadd1`).
- `rtl/converters.v` — the `t2b` value decode (Horner `r = 3r + dᵢ`).
- `rtl/word_fairfight.txt` — word-level adder area (wf_tadd6 vs wf_badd10, 3.74×/3.94×).
- `docs/compute/field_calculus/trelax_measured.md` — measured `tadd1`/`bin_fa` (1.92×/3.31×/4.33×).
- `docs/compute/address_space/emulation_field.md` — "the reduction is 6 signed adds in both bases".
- `docs/compute/hybrid/conversion_cost.md`, `hybrid_verdict.md` — the boundary-decode amortization
  and the hybrid referee's framing.
