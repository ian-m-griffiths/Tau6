# Gate Area: Ternary vs Binary (SkyWater 130nm)

**Question answered here:** does a ternary gate cost more silicon than a binary
gate — the *area* half of "does ternary compute beat binary given the
2-threshold tax?" (The *energy* half is the companion test.)

**Method.** Each gate is synthesized **in isolation** (each is its own top
module in `rtl/gate_area_cells.v`, so yosys cannot constant-fold or merge
anything), then mapped into the SkyWater 130nm high-density library with
`abc -liberty rtl/sky130_fd_sc_hd.lib` and measured with `stat -liberty`.
This is the **exact same flow** the CPU report (`rtl/yosys_report.sh`) uses, so
the numbers are directly comparable to the 24,314 µm² CPU figure. Script:
`rtl/gate_area.sh` (full log + TSV in `rtl/gate_area.txt`).

Trit encoding (from `rtl/trit_functions.vh`): **2 wires per trit**,
one-hot-per-direction — `2'b01 = +1`, `2'b00 = 0`, `2'b10 = −1`, `2'b11 = NEVER`.

## Measured per-gate area and cell count

| gate | type | function | cells | area (µm²) |
|------|------|----------|------:|-----------:|
| `tneg`  | ternary | NOT (negation) — a wire swap | **0** | **0.0000** |
| `tmin`  | ternary | MIN (meet) | 2 | 12.5120 |
| `tmax`  | ternary | MAX (join) | 2 | 12.5120 |
| `tadd1` | ternary | mod-3 sum (full adder → `{cout,sum}`) | **25** | **146.3904** |
| `not`   | binary  | NOT | 1 | 3.7536 |
| `nand2` | binary  | NAND | 1 | 3.7536 |
| `nor2`  | binary  | NOR | 1 | 3.7536 |
| `badd1` | binary  | full adder (reference) | 2 | 33.7824 |

Cell breakdowns (measured):

* `tmin` / `tmax` = one `and2_0` (push = `a0&b0` / `a1&b1`) + one
  `lpflow_inputiso1p_1` (pull = `a1|b1` / `a0|b0`). That isolation cell's
  liberty function is literally `(A)|(SLEEP)`, so abc uses its SLEEP pin as a
  second input — it *is* a 2-input OR of the same 6.256 µm² area as `or2_1`.
  So `tmin`/`tmax` = 1 AND2 + 1 OR2 = 2 cells.
* `tadd1` = 25 cells (16 distinct types: `a21oi`, `a22oi`, `a222oi`, `a32oi`,
  `nand2`×4, `nand2b`×2, `nand3`×3, `nor2`×2, `nor3`, `nor4`×2, `o211ai`,
  `o22ai`, `o31ai`, `xnor2`, `and2_0`, `lpflow_inputiso1p`) — the *naive
  boolean* full-adder from `trit_functions.vh` (the header there says exactly
  this: the boolean form is "the naive gate-level cell"; the earlier
  case-on-integer-sum form was even bigger).
* `badd1` = `maj3_1` + `xor3_1` (sky130's dedicated `fa_1` full-adder cell at
  20.0192 µm² is a multi-output gate that the default abc script does not use;
  the CPU flow has the same behaviour, so 33.7824 is the apples-to-apples
  number under this flow).

## The area ratio

Per-gate **ternary ÷ binary** area:

| ternary gate | binary reference | ratio |
|--------------|------------------|------:|
| `tneg` (NOT) | `not` | **0.00×** — ternary NOT is free |
| `tmin` (MIN) | `nand2` | **3.33×** |
| `tmax` (MAX) | `nor2` | **3.33×** |
| `tadd1` (sum) | `badd1` | **4.33×** |

The `tmin`/`tmax` penalty is **exactly 2.00×** against the semantically
matching binary gates (AND2 / OR2, 6.256 µm² each) — that is the 2-threshold
tax in its purest form: a ternary MIN is one AND2 threshold (the `+` line) plus
one OR2 threshold (the `−` line), so it costs two binary gates. Measured
against the cheapest binary gate (NAND/NOR/INV at 3.7536 µm²) it is 3.33×,
because sky130's AND2/OR2 are themselves built from two base cells.

The mod-3 sum (`tadd1`) is the expensive one: **4.33×** the binary full adder
in this flow (and would be **7.31×** against sky130's dedicated `fa_1` cell if
abc used it). This is the 2-threshold tax *plus* the fact that a balanced
full adder must simultaneously threshold for both carry directions *and* both
sum directions.

## Honest verdict

**Ternary does NOT win on area.** The only win is trivial:

1. **Ternary NOT is free (0.00 µm², 0 cells)** — in the one-hot-per-direction
   encoding, negation is a wire permutation (`+1 ↔ −1`), so the inverter costs
   nothing. That is a genuine, Lean-proved structural advantage, but a free
   inverter is not enough to carry the rest of the library.

2. **Every non-trivial ternary gate loses.** MIN/MAX cost 2.00× a binary
   AND/OR (the 2-threshold tax, measured cleanly) and 3.33× a binary
   NAND/NOR. The mod-3 sum costs 4.33× a binary full adder (25 cells vs 2).

3. **The tax is worse than 2× once information density is counted.** A trit is
   log₂3 = 1.585 bits carried on **2 wires** = 0.792 bits/wire, versus 1 bit
   on 1 wire for binary. Ternary therefore needs 1.26× as many wires to carry
   the same information, *on top of* a 2.00–4.33× per-gate area penalty. There
   is no gate class where the 1.585-bit-per-trit density compensates for a
   2.00–4.33× area multiplier.

**Bottom line:** on a 130nm CMOS standard-cell library with this 2-wire trit
encoding, ternary gates are **2.0–4.3× larger** per gate than their binary
equivalents, and the encoding wastes 26% of the wires. The 2-threshold tax is
real and measured, not hypothetical. Ternary only starts to make sense when the
*transistor* is native multi-valued (a device that thresholds 3 states on one
wire) — it does not win as an encoding laid on top of a binary standard-cell
library.

*Numbers cited are all measured by `rtl/gate_area.sh` (yosys 0.52 +
`sky130_fd_sc_hd__tt_025C_1v80`); see `rtl/gate_area.txt` for the full log.*
