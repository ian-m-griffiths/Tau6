# Word-Level Fair Fight: 6-trit vs 10-bit Datapaths (SkyWater 130nm)

**Question answered here:** the per-gate benchmark (`gate_area.md`) compared *one
ternary gate vs one binary gate* and found ternary **2.00×–4.33× larger**. That is
unfair: a trit carries log₂3 ≈ 1.585 bits, so one trit and one bit are not the same
amount of information. This report re-runs the fight at the **word level** on
**equal-information datapaths** — 6 trits = 3⁶ = 729 states vs 10 bits = 2¹⁰ = 1024
states (the nearest binary width) — and normalizes cost **per STATE** and **per BIT**.

**Method.** Each datapath is its own top module in `rtl/word_fairfight_cells.v`,
synthesized in isolation (nothing constant-folds or merges), mapped into the SkyWater
130nm high-density library with `abc -liberty rtl/sky130_fd_sc_hd.lib` and measured
with `stat -liberty` — the **identical flow** to `rtl/gate_area.sh`. Script:
`rtl/word_fairfight.sh` (full log + TSV in `rtl/word_fairfight.txt`). The 10-bit
binary multiplier *was* feasible (367 cells, 0.8 s of abc), so no partial-product
estimate was needed.

Trit encoding (from `rtl/trit_functions.vh`): **2 wires per trit**,
one-hot-per-direction — `2'b01 = +1`, `2'b00 = 0`, `2'b10 = −1`, `2'b11 = NEVER`.

## Normalization definitions

For a 2-operand datapath (adder or multiplier):

| quantity | ternary (6 trits) | binary (10 bits) |
|---|---|---|
| operand states | 3⁶ = 729 | 2¹⁰ = 1024 |
| operand bits (log₂ states) | 6·log₂3 = **9.510** | **10** |
| input state-pairs | 3¹² = 531,441 | 2²⁰ = 1,048,576 |
| total input bits (log₂ pairs) | **19.020** | **20.000** |

* **area per state** = area ÷ input state-pairs (the task's "÷ number of input
  state-pairs").
* **area per bit** = area ÷ log₂(input state-pairs).

Note the deliberate asymmetry: 10 bits carry 1.05× the information of 6 trits, and
1.97× the state-pairs. The **per-bit** number is the fairest (it corrects for the
1.05× information edge); the **per-state** number penalizes ternary twice (once for
smaller area *and* once for carrying fewer states).

## Measured 4-way table (+ 1 honesty row)

| datapath | family | cells | area (µm²) | area/state (µm²) | area/bit (µm²) |
|---|---|---|---:|---:|---:|
| `wf_tadd6` — 6-trit ripple adder (6×`tadd1`) | ternary | 167 | 969.680 | 0.00182462 | 50.983 |
| `wf_badd10` — 10-bit ripple adder (10×binary FA) | binary | 48 | 258.998 | 0.00024700 | 12.950 |
| `wf_tmul6` — 6-trit mult (`tmul_trits_opt`, Karatsuba) | ternary | 1096 | 6618.848 | 0.01245453 | 348.002 |
| `wf_bmul10` — 10-bit shift-add mult | binary | 367 | 3344.458 | 0.00318952 | 167.223 |
| `wf_tmul6_sa` — 6-trit mult (`tmul_sa`, plain shift-add) | ternary | 855 | 5472.749 | 0.01029794 | 287.743 |

The extra row `wf_tmul6_sa` is the **plain shift-add** ternary multiplier, measured
because the task pairs the Karatsuba ternary multiplier against a *simple* shift-add
binary multiplier. At N=6 the Karatsuba variant is actually the **larger** of the two
ternary multipliers (6618.848 vs 5472.749 µm², +20.9%), consistent with
`arithmetic.md`'s "+28%" note — so `wf_tmul6_sa` is the structurally fair match to
`wf_bmul10`. Both are reported.

## The ratios (ternary ÷ binary)

| fight | raw area | area/state | area/bit |
|---|---:|---:|---:|
| **adder** (6-trit vs 10-bit) | **3.744×** | **7.387×** | **3.937×** |
| **multiplier** (Karatsuba vs shift-add) | 1.979× | 3.905× | 2.081× |
| **multiplier** (shift-add vs shift-add) | **1.636×** | **3.229×** | **1.721×** |

Per-gate reference (from `gate_area.txt`): `tadd1`/`badd1` = 146.3904/33.7824 =
**4.333×**; `tmin`/`tmax` vs binary AND/OR = 2.00×. So the per-gate penalty band was
**2.00×–4.33×**.

## Honest verdict

**The normalization does NOT flip the verdict — binary still wins on area in every
case — but it reshapes the magnitude by datapath.**

1. **Adder: no help, slightly worse per state.** The ternary ripple adder is 3.74×
   the raw area and **3.94× per bit** — barely moved from the 4.33× per-gate figure.
   The "fair fight" discount (6 trits vs 10 bits = 0.6× fewer digits) is almost
   exactly cancelled by the fact that a binary operand carries 1.05× the information.
   Per *state* it gets worse still (**7.39×**), because the 10-bit word exposes 1.97×
   more input state-pairs per µm². This is what the per-gate number predicted: an
   adder *is* N full-adders, so the word-level ratio ≈ the full-adder ratio ×
   (digit-count ratio), and the balanced-ternary carry is the single most expensive
   cell in the library.

2. **Multiplier: the density tax largely melts.** The ternary shift-add multiplier is
   only **1.64×** the raw area of the 10-bit shift-add, **1.72× per bit**, **3.23× per
   state**. This is the one place the 1.585-bit/trit density genuinely works: a
   multiplier's cost is dominated by the *partial-product accumulation*, and 6×6 trit
   products over 12 trits beat 10×10 bit products over 20 bits enough to pull the
   penalty down from the 4.33× per-gate figure to ~1.7× per bit — below even the 2.00×
   "pure 2-threshold tax" floor from the MIN/MAX gates. (Using the specified Karatsuba
   multiplier instead: 1.98× raw, 2.08× per bit — still roughly half the adder's
   penalty.)

3. **A measured ripple detail worth recording.** The binary ripple adder came out
   *cheaper per bit than its isolated full adder* (258.998 µm²/10 = 25.90 µm² vs the
   isolated `badd1` at 33.78 µm²): abc maps each of the 10 carries to a single `maj3_1`
   majority cell and the 10 sums to cheap 3-input `nand3`/`nor3`/`o21ai` cells —
   smaller than the isolated FA's `maj3`+`xor3` pair. The ternary ripple did **not**
   get that sharing — it came out *dearer* per trit than the isolated `tadd1`
   (969.680/6 = 161.6 µm² vs 146.39 µm²), because the balanced carry's four output
   rails entangle the digits and give abc nothing to collapse. So the word-level fight
   is, if anything, *harder* on ternary than the per-gate fight suggested for the
   adder. (*And this is without sky130's dedicated multi-output `fa_1` full-adder cell
   at 20.019 µm² — abc's default script does not use it, exactly as in `gate_area.md`.
   If it did, the binary adder would be smaller still, moving the ratio further
   *against* ternary: 3.94× per bit is the conservative, ternary-favorable bound.*)

**Bottom line.** Ternary's area penalty is real and survives normalization: **~3.9×
per bit for the adder, ~1.7× per bit for the (shift-add) multiplier** — binary wins
everywhere. The single honest silver lining is that the multiplier's 1.72× is close
to the information-density bound (a trit carries 1.585 bits on 2 wires = 0.792
bits/wire vs binary's 1.0, so ternary needs 1.26× as many wires for the same
information *before* any gate cost), so on the *multiply* path the 2-threshold tax is
almost fully paid off by density. It is not
paid off on the add path, and nowhere does the normalization flip the verdict.
Ternary does not win on area; it wins (per `arithmetic.md`) on **structure** — free
negation, exact Z₆ rotation, symmetric rounding — not on gates, and this word-level
benchmark is the measured proof of that.

*All numbers measured by `rtl/word_fairfight.sh` (yosys 0.52 +
`sky130_fd_sc_hd__tt_025C_1v80`); see `rtl/word_fairfight.txt` for the full log and
the per-module cell breakdowns.*
