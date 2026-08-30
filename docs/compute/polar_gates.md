# Native polar ternary gates — energy + transistor count (measured)

**2026-08-29, ngspice 44.2, measured. Netlist: `circuit/polar_gates.cir`
(exit 0, no warnings, no DC shorts — quiet-window energies all < 11 aJ).**

## The question

The prior gate benchmark (`gate_energy.md` / `gate_area.md`) synthesized
"ternary" gates from a **binary** standard-cell library, encoding each trit as
**two** boolean wires (one-hot: `01=+1 00=0 10=−1 11=NEVER`). That is binary
emulation: 3-level logic in 2-level cells, losing 2–4.3× on area and 1.2–3.1×
on energy, wasting a 4th state (0.79 bits/wire).

This report measures the **native** representation we already use for
*communication* (`ternary_cell.cir` / `ternary_fairfight.cir`): **one wire,
three levels** — push = +V, null = 0, pull = −V. 1.585 bits/wire, no wasted 4th
state. Each gate is a self-restoring cell that reads 2 polar inputs and drives
one polar output, reusing the comm cell's **push-pull driver + sense-amp
receiver** topology:

```
[polar wire] → [2 sense amps: 2-threshold demux] → [transistor logic]
             → [push-pull driver] → [polar wire]
```

## Method (fair-fight, same honesty rules as the comm cell)

- **Rails:** everything runs on ±VDD = ±1.0 V. Binary is `0=−1 V, 1=+1 V`;
  ternary is `−1=−1 V, 0=0 V, +1=+1 V`. The **same** sense amp (vs 0 V) is the
  receiver for both — binary uses **1** SA (1 threshold), ternary **2** SAs
  (2 thresholds) — so the "1-vs-2-threshold tax" is isolated at identical rails
  and common mode.
- **Demux:** two PMOS-input clocked sense amps per input wire (push = wire > 0,
  pull = wire < 0, null = neither fired). This is the comm cell's receiver.
- **Output:** the push-pull driver (PMOS→+VDD, NMOS→−VDD), gp = NOT(push),
  gn = pull.
- **Energy:** E_gate = the gate's own supply (input demux SAs + logic + output
  driver); E_rec = the output receiver's supply (1 SA binary / 2 SAs ternary).
  Measured over one **full** output cycle (assert + release), halved for "per
  toggle" (the gates are asymmetric; a full cycle is the only fair toggle).
- **Inputs are ideal voltage sources** (the previous stage's output is
  abstracted; its cost is symmetric to this gate's own output driver). This is
  exactly `gate_energy.cir`'s convention, so the numbers are directly
  comparable to `gate_energy.md`.
- **Toggle = cheapest ternary toggle (null ↔ +1)** — generous to ternary; a
  +1↔−1 toggle swings the full ±V and costs ~2× the wire energy.
- **LEVEL=1 models, no body diodes, no device mismatch** — generous to ternary
  (its 2-threshold receiver has 2× the offset budget).

The gates are **dynamic / pipelined**: the input sense amps hold their resolved
value for the eval phase (10 ns = a ~100 MHz gate cycle), the logic + driver
produce a stable output, and the output SAs sample it one pipeline stage later.

## The measured table

**Energy per toggle** (fJ; one full cycle = assert + release, divided by 2):

| gate | E_gate | E_rec | **E_total** | transistors |
|---|---:|---:|---:|---:|
| **binary NOT** | 57.0 | 133.6 | **190.6** | 2 (1 cell, 3.75 µm²) |
| **binary NAND** | 81.9 | 133.7 | **215.6** | 4 (1 cell, 3.75 µm²) |
| **polar NOT (negation)** | 1086.2 | 379.2 | **1465.3** | 18 |
| **polar MIN** | 1522.6 | 175.1 | **1697.7** | 44 |
| **polar MAX** | 3428.3 | 174.9 | **3603.2** | 44 |
| **polar mod-3 sum** | 4709.6 | 175.1 | **4884.8** | 100 |

Transistor breakdowns (counted from the netlist; transistor count is the area
proxy since no ternary liberty exists):

- `sensamp` = 7 T (2 PMOS diff pair + 1 PMOS tail + 2 NMOS cross-couple +
  2 NMOS precharge); `receiver` = 2 sensamps = 14 T; `driver` = 2 T.
- **polar NOT** = 2 sensamps (14) + 1 inv (2) + driver (2) = **18 T**. The
  negation *logic* is a free swap of push↔pull (0 T), but the gate must still
  **resolve** the 3-level input (14 T) and **re-encode** the output (4 T).
- **polar MIN / MAX** = 4 sensamps (28) + and2 (6) + or2 (6) + inv (2) +
  driver (2) = **44 T**.
- **polar mod-3 sum** = 4 sensamps (28) + 2 nor2 (8) + 6 and2 (36) + 2 or3
  (24) + inv (2) + driver (2) = **100 T**. This is the 2-input F₃ addition
  (the "ternary XOR", the completeness ingredient). The 3-input balanced full
  adder (with carry) is a follow-up: it must additionally threshold for both
  carry directions, so it is larger still.

Truth-table checkpoints (measured 1 ns after the output SA eval):

| gate | input toggle | output (rise / fall) | receiver (rise / fall) |
|---|---|---|---|
| binary NOT | +1→−1→+1 | +1.000 / −1.000 ✓ | +1.0 / −0.94 ✓ |
| binary NAND | +1→−1→+1 | +1.000 / −1.000 ✓ | +1.0 / −0.94 ✓ |
| polar NOT | null→+1→null | −0.996 / ~0 ✓ | push −0.94, pull +0.80 ✓ |
| polar MIN | null→+1→null | +0.996 / ~0 ✓ | push +1.0, pull −1.0 ✓ |
| polar MAX | null→+1→null | +0.996 / ~0 ✓ | push +1.0, pull −1.0 ✓ |
| polar mod-3 sum | null→+1→null | +0.996 / ~0 ✓ | push +1.0, pull −1.0 ✓ |

Every gate produced the correct output **wire** level on both edges. The one
wrinkle is the receiver on a **null** output (see below).

## The honest ratio

Per-toggle (native ternary ÷ binary):

| ternary vs binary | per toggle | **per bit** (÷1.585) |
|---|---:|---:|
| polar NOT vs NOT | 7.7× | **4.9× worse** |
| polar MIN vs NAND | 7.9× | **5.0× worse** |
| polar MAX vs NAND | 16.7× | **10.5× worse** |
| polar mod-3 sum vs NAND† | 22.7× | **14.3× worse** |

† the mod-3 sum's true binary analog is a 1-bit XOR/full-adder (~6–12 T ≈
2–3× NAND), so the 14.3× per-bit figure is against the *cheapest* 2-input
binary gate and understates the loss against a fair XOR by ~2–3×; against a
binary full adder (2 cells, 33.78 µm²) the transistor ratio is **100 T ÷ ~12 T
≈ 8.3×**.

Transistor ratio: **negation 9×, MIN/MAX 11×, mod-3 sum ~8×** a binary gate.

**These ratios are conservative (generous to ternary).** Binary here runs on
±1 V (2 V swing) to share the ternary rails for a controlled comparison; binary's
natural single-ended 0–1 V (1 V swing, what `gate_energy.md` used at
32.3 fJ/toggle) is ~2× cheaper, which would roughly double every loss above.

## The finding that matters: the null is the wall

The native single-wire representation has a cost the 2-wire emulation never paid,
and it shows up at the receiver:

1. **A 3-level wire cannot drive static CMOS.** A MOSFET gate is a *binary*
   threshold — it distinguishes 2 levels, not 3. So every native gate boundary
   must first **demux** the 3-level wire into two 2-level rails with a clocked
   sense-amp pair, then **re-encode** with a push-pull driver. That is 14 T of
   receiver + 4 T of driver per wire, *before any logic*. Binary needs none of
   it (a binary wire drives the next gate's MOSFET directly). This is why
   **even the free gate — negation, 0 transistors of logic — costs 18 T and
   4.9× a binary inverter per bit**: the free logic cannot outrun the demux +
   re-encode.

2. **The null is meta-stable.** The null wire (0 V) sits *exactly* at the sense
   amp's threshold, so the receiver sits at a saddle point: it draws continuous
   shoot-through current for the whole eval phase (measured: a held-null input
   lifts MAX/SUM's E_gate to 2.3–3.1× MIN's, which holds a clean +1), and its
   kickback (~0.18 V into the high-impedance null wire) can tip the latch to a
   false "push". Binary never sits at a threshold — its two rails are always
   driven full-swing. The comm cell's diode rectifier (`ternary_cell.cir`)
   does not fix this: it just moves the meta-point to the rails and adds a
   static rail load, leaving the push rail at 0 V for *both* "pull" and "null".

3. **Native is worse than the emulation, not better.** Against the prior
   2-wire static-CMOS benchmark (`gate_energy.md`: tneg 61.9 fJ, min 85.2 fJ,
   max 82.7 fJ, sum 183.6 fJ per toggle, measured on 0–1 V rails), the native
   single-wire gates are **20–44× more expensive** (1465–4885 fJ/toggle), and
   still ~10–12× after correcting the emulation's 1 V swing up to the native
   ±1 V rails. The emulation's static CMOS needed a clocked sense amp only at
   the output (the "2-threshold tax" demonstration); the native gate needs the
   clocked demux at *every* input plus the push-pull driver at *every* output.

## The honest verdict

**No — native single-wire polar ternary does NOT beat binary, and it does not
even beat the 2-wire emulation it was meant to replace.**

The radix economy (3/ln 3 ≈ 2.73, 1.585 bits/wire) is a property of the **wire**
(the transport link, where the null is *free* — nothing to transmit). It does
not transfer to the **gate**, because a gate must *resolve and hold* all three
levels every cycle, and that means:

- **2 sense amps per input wire** (the 2-threshold tax, in its native form) —
  binary pays 0 at the input, 1 at the output.
- **a push-pull driver per output wire** — binary's inverter *is* its driver.
- **a meta-stable null** that draws continuous current and erodes noise margin —
  binary has no third level to sit on a threshold.

Measured per-bit losses: **negation +4.9×, MIN +5.0×, MAX +10.5×, mod-3 sum
+14.3×** (and ~2× more if binary is allowed its natural 1 V swing). On
transistors: **9–11×** per gate. There is no gate class where the 1.585-bit
density compensates.

The reframe's premise — "the 2-wire benchmark was emulation, measure the native
cell" — is correct, and measuring the native cell settles it *against* native
ternary: the win at the link (0.081 pJ/bit, null free *on the wire*) is a
transport win, and the moment you ask the same cell to *compute*, the null that
was free becomes the most expensive thing in the circuit. Ternary compute is a
**transistor-technology bet** (a device that thresholds 3 states natively, e.g.
multi-Vt / CNTFET / memristor), not a CMOS cell-topology bet. On plain CMOS,
binary wins at the gate, and the 2-wire static encoding — emulation and all —
was already the right choice for the logic layer.

## Caveats (same class as every fair fight in `circuit/`)

- **LEVEL=1 models, no body diodes, no mismatch.** Real SA offsets (σ ≈ 5–20 mV)
  make the null meta-stability *worse*, not better, and would need wider input
  pairs → more receiver energy → a wider ternary loss.
- **The null cost scales with eval time.** 10 ns hold = ~100 MHz; the comm
  cell's 2 ns eval would cut the meta-stable null current ~5×, but cannot remove
  it, and a gate must hold its output for the cycle.
- **±1 V rails for binary are generous to ternary** (2 V swing vs binary's
  natural 1 V). The verdict is robust under this; it only strengthens otherwise.
- **The 3-input balanced full adder (with carry) is a follow-up.** The 2-input
  mod-3 sum measured here is the F₃ field addition; the carry output needs two
  more thresholds and adds transistors, so the full adder loses by at least the
  measured 8.3×.

## Files

- `circuit/polar_gates.cir` — the fair-fight netlist (fully commented;
  `ngspice -b` runs clean, exit 0): sense-amp receiver, push-pull driver,
  native polar NOT/MIN/MAX/mod-3-sum cells, binary NOT/NAND controls, per-gate
  energy + truth-table measurements.
- `circuit/polar_gates.log` — the measurements (E_gate, E_rec, per-toggle,
  wire + receiver-latch checkpoints, quiet-window DC-short checks).

*Every number above is measured by `circuit/polar_gates.cir` (ngspice 44.2) or
counted from its netlist; nothing is invented.*
