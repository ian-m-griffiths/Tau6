# Gate energy — ternary vs binary, fair-fight (measured)

**2026-08-29, ngspice 44.2, measured. Netlist: `circuit/gate_energy.cir` (exit 0, no
warnings, no DC shorts — quiet-window energies all < 1 fJ).**

## The question

The comm stack won (`docs/ENERGY_LAWS.md`: 0.081 pJ/bit, null is free *on the wire*).
But compute is not communication: a gate must *resolve* "is this −1, 0, or +1?" every
toggle. The survey (`docs/TERNARY_COMPUTE_SURVEY.md`) sharpened it to one inequality:

> **Does radix economy (3/ln3 ≈ 2.73 → 1.585 bits/trit) beat the per-gate
> 2-threshold receiver tax (2 sense amps vs 1)?**

This report measures it, under the same honesty rules as `ternary_fairfight.cir`:
**real CMOS driver + real PMOS-input clocked sense-amp receiver, energy = ∫V·I dt, no
ideal sources.**

## Method (what "one toggle" means)

Every gate is static CMOS on the RTL's 2-wire encoding (`rtl/trit_functions.vh`:
`01=+1`, `00=0`, `10=−1`, `11=NEVER`). Each gate's output wire drives `Rwire=100 Ω` +
`CL=10 fF` (≈ one next-gate input) into a sense amp. Supplies are per-gate, so energy is
attributed exactly.

- **E_gate** = gate VDD supply energy over one **full output cycle** (0→1→0 for binary,
  null→+1→null for ternary — one wire charges then discharges). This is the
  *combinational-network* cost, i.e. what a gate pays with **no** clocked sense amp.
- **E_rec** = receiver VDDSA supply energy for the sense amp(s) firing **once per
  transition** (twice per cycle). Binary: **1 sense amp** (1 threshold, `wire vs 0`).
  Ternary: **2 sense amps** (push vs 0, pull vs 0) = the **2 thresholds**.
- **Per-toggle = (E_gate + E_rec)/2** — one output transition.

A **full cycle is measured, not one edge**, because the gates are asymmetric: a binary
NAND's output *rise* charges its internal series node (expensive) while its *fall* is
~free; a ternary min's push path is the mirror image (cheap rise, expensive fall). An
assert-only measurement would flatter ternary ~2×. Averaging both edges is the only fair
"per toggle" (verified in `_probe` runs: binary NAND rise 30.9 fJ / fall −8.0 fJ;
ternary min push rise 14.3 fJ / fall 29.9 fJ).

Both receivers use the *same* `wire vs 0` reference, so the "1 vs 2 sense amps" tax is
isolated at identical common mode. (The PMOS input pair dies at VDD/2 common mode —
`pam4.cir` — so a VDD/2 binary threshold is unusable; `wire vs 0` is a valid 1-threshold
detector.)

## The measured table (energy per output transition, fJ)

| gate | logic | E_gate | E_rec | **E_total** | pJ/bit |
|---|---:|---:|---:|---:|---:|
| **binary NOT** | 1 inverter (2T) | 7.93 | 24.35 | **32.28** | 0.0323 |
| **binary NAND** | 4T | 12.60 | 24.35 | **36.96** | 0.0370 |
| **binary NOR** | 4T | 9.72 | 24.36 | **34.08** | 0.0341 |
| ternary NOT (tneg) | **0T (wire swap)** | 0.00 | 61.87 | **61.87** | 0.0390 |
| ternary min (tand) | 12T (AND+OR) | 23.32 | 61.87 | **85.19** | 0.0537 |
| ternary max (tor) | 12T (OR+AND) | 20.86 | 61.87 | **82.73** | 0.0522 |
| ternary mod-3 sum (tsum) | 68T | 121.74 | 61.86 | **183.61** | 0.1158 |

`pJ/bit` = E_total ÷ (1.585 bits/trit for ternary, 1 bit for binary).

Sanity: every gate produced the correct truth-table output at the eval edge (asserted
wire latched ~1.0 V, idle wire balanced at ~mV — `d` columns in the log). Quiet-window
(10–40 ns) gate energies were ≤ 0.001 fJ, i.e. **no DC shorts** — the gates burn energy
only when they toggle.

## The two numbers that answer the question

**1. The 2-threshold receiver tax is 2.54×.**

| receiver | per evaluation |
|---|---:|
| binary — 1 sense amp | 24.35 fJ |
| ternary — 2 sense amps | 61.87 fJ |
| **ratio** | **2.54×** |

Not 2×: the ternary's idle-wire sense amp (reading 0 vs 0) stays balanced for the whole
eval and draws *more* than a cleanly-latching amp, so 2 amps cost 2.54×, not 2×.

**2. The radix-economy density is 1.585×** (log₂3 bits per trit vs 1 bit per binary output).

**2.54× tax > 1.585× gain. The receiver tax alone is larger than the entire density
saving — before the gate logic is even counted.**

## The toggle-energy ratio (ternary / binary, matched function)

| ternary vs binary | per toggle | **per bit** |
|---|---:|---:|
| tneg vs NOT | 1.92× | **1.21× worse** |
| min vs NAND | 2.31× | **1.45× worse** |
| max vs NOR | 2.43× | **1.53× worse** |
| mod-3 sum vs NAND† | 4.97× | **3.14× worse** |

† the mod-3 sum has no binary gate in the requested set; its true analog is a 1-bit
XOR/full-adder (~6–8T ≈ 1.5–2× NAND), so the 3.14× per-bit figure is *against the
cheapest 2-input binary gate* and overstates the loss — against a fair XOR it is ~2×.
Either way it loses.

## The honest verdict

**No — ternary gates do NOT win on energy, in this circuit family.** The 2-threshold
receiver tax (2.54×) plus the heavier gate logic (12–68T vs 4T) overwhelms the
radix-economy density (1.585×). Measured per-bit losses: **negation +21%, min +45%,
max +53%, mod-3 sum +214%** (and ~+50–100% even against a fair XOR).

The decomposition shows *where* it dies:

1. **The receiver is the wall, exactly as Law 1 predicts.** Even the *free* gate —
   ternary NOT, a 0-transistor wire swap, the single best thing balanced ternary has —
   still **loses 21% per bit** (61.87 fJ ÷ 1.585 = 39.0 vs binary NOT's 32.3 fJ/bit),
   because it must drive a 2-threshold receiver. The measurement cost is the invariant
   part; the free logic can't outrun it.
2. **Even with the sense amp removed** (the honest combinational gate-to-gate case, where
   the "receiver" is just the next gate's input capacitance), the ternary logic alone
   loses: min 1.17×, max 1.35×, sum 6.1× per bit — because 12–68 transistors of
   static CMOS cost more than binary's 4, and the density (1.585×) can't cover it.
   Only tneg wins there (0 transistors).
3. **The radix economy belongs to the single-wire link, not the 2-wire gate network.**
   The 2-wire encoding puts 3 states on **2** wires = 0.79 bits/wire — *below* binary's
   1 bit/wire. `3/ln3 < 2/ln2` is a statement about a **single** 3-level wire (the AC-
   polarity cell / a 3-level voltage), not about 2 boolean wires. The 2-wire ternary
   gate pays binary's wire cost twice and never gets the economy back.

## Caveats (same class as every fair fight in `circuit/`)

- **LEVEL=1 models, no body diodes, no device mismatch.** Sense-amp offsets are ignored,
  which is *generous to ternary*: the 2-threshold receiver has 2× the offset budget of
  the 1-threshold receiver. Real offsets (σ ≈ 5–20 mV) would need wider SA input pairs →
  more receiver energy → a wider ternary loss.
- **The toggle measured is the cheapest ternary toggle** (null↔+1, one wire swings).
  A +1↔−1 transition swings both wires and costs ~2× the wire energy, widening the loss.
- **Uniform sizing** (PMOS 4u/NMOS 2u per stage, series stacks doubled). Re-optimizing
  per gate shifts the fJ by ~10–20% but cannot move a 2.5× receiver gap.
- **The clocked sense amp is a line receiver.** In a real combinational network there is
  no clock; the "receiver" is the next gate's static input (row 2 above is that story).
  The 2.54× sense-amp tax is the *literal* answer to "1 vs 2 thresholds"; the
  combinational case (1.17–6.1× logic-only) is the *physical* one. Both lose.
- **Voltage-mode ternary (1 wire, 3 levels) is NOT what was measured.** That scheme
  *does* get the radix economy on one wire, but pays a genuinely 2-comparator receiver
  (and a noise margin hit) to resolve 3 levels — the same receiver tax this report
  quantifies, just moved from "2 wires" to "2 comparators". Worth a follow-up netlist,
  but the inequality under test is unchanged: the extra threshold costs more than the
  extra level returns.

## Files

- `circuit/gate_energy.cir` — the fair-fight netlist (fully commented; `ngspice -b`
  runs clean, exit 0).
- `circuit/gate_energy.log` — the measurements (per-gate E_gate, E_rec, per-toggle,
  latch differentials, quiet-window DC-short checks).
