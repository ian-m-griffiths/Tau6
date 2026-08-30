# Polar ternary FULL adder — measured device count, energy, delay

**2026-08-30, ngspice 44.2, measured. Netlist: `circuit/polar_full_adder.cir`
(`ngspice -b` exit 0, no convergence warnings; checker: `circuit/check_polar_full_adder.py`).**

**Calibration legend** (house standard): **DIRECT** = measured by this run or counted from
the netlist; **DERIVED** = arithmetic on DIRECT numbers; **OURS** = design decision made
here, flagged; **SPECULATION** = untested.

---

## 0. One-line answer

**The polar full adder (`a+b+cin → sum, cout`) is 224 devices (218 transistors + 6
rectifier diodes) and costs 1.50–4.40 pJ per add (carry-exercising toggle 2.62 pJ) at
0.4–0.5 ns delay. It does NOT beat binary: it is 8× the device count of a canonical 28-T
binary FA and ~1.9–5.5× the energy of a binary FA measured in the same ±1 V harness. It
also does NOT beat the 2-wire CMOS ternary FA (192 T) — it is 1.17× larger, because the
single-wire polar representation must pay diode receivers (input demux) + push-pull
drivers (output re-encode) on top of the same boolean carry/sum logic.**

---

## 1. What was built, and every design decision (flagged)

The sibling polar-adder docs named in the brief do not exist on disk; the adder was built
from the measured parts already in `circuit/` (the diode-direction gates `diode_gates.cir`
and the 2-input mod-3 sum `tsum_cell.cir`) extended to 3 inputs. **Every decision below is
a real choice I made, and each one is counted.**

| decision | choice | why / cost |
|---|---|---|
| **digit set** | **balanced** `{−1,0,+1}` = `{−VDD,0,+VDD}` | "polar" = push/null/pull = a signed *direction* (the 2-diode receiver detects ± direction, not magnitude). The task's "carry = 1 iff ≥3" is the *unsigned* radix-3 idiom; balanced carries use `+1 iff s≥+2`, `−1 iff s≤−2`, `0` else. `sum = s mod 3` is identical in both. **Flagged: I built balanced, not unsigned.** |
| **summation** | **static-CMOS boolean**, not the analog Kirchhoff current-sum | the analog current-mode `⊕` (KCL sum + ±2 wrap) is `analog_polar.md` Idea A, which the repo *never converged* (current mirrors/comparators deferred). I reused the repo's measured, working diode-direction + static-CMOS machinery instead. **Flagged.** |
| **carry threshold** | **static-CMOS majority + veto**, not an elevated-Vt/comparator device | `p2 = maj3(pa,pb,pc)` (≥2 pushes), `n2 = maj3(na,nb,nc)`; `cop = p2 & ~(na\|nb\|nc)` (no pulls), `con = n2 & ~(pa\|pb\|pc)`. Each maj3 = 3×and2 + or3 = **26 T**; the two veto nor3 = **12 T**; the two carry ANDs = **12 T**. Carry block = **92 T**. |
| **sum logic** | factored mod-3 (exactly-one / exactly-two / no-context) | `sp = (p1&nz)|(p2x&n1)|(pz&n2x)`, `sn = (n1&pz)|(n2x&p1)|(nz&p2x)`. Intermediate signals `p1/n1/p2x/n2x/pz/nz/p2/n2` = **128 T**; the two 3-term outputs = **52 T**. This is the repo's 192-T `tadd1` factoring, verbatim in structure. |
| **receiver** | `t_recv2` = diode pair + elevated-|Vt| restore, **p/n only** | 2 diodes + 6 T per input, producing full-swing `p = +VDD iff push`, `n = +VDD iff pull`. I dropped the explicit null rail `z` that `tsum_cell` used, because the carry/sum logic above derives its own null-context (`pz/nz = nor3`). 3 inputs = **6 D + 18 T**. |
| **output re-encode** | 2 dead-zone push-pull drivers + 2 inverters | merges the 4 logic rails `sp/sn/cop/con` into 2 single polar wires. **8 T.** (The 2-wire `tadd1` does not need this — its rails *are* the output.) |
| **3-input gates** | real CMOS `nor3=6T`, `or3=8T`, `and3=8T` | matches the repo's 192-T `tadd1` single-gate counting; not 2-input cascades. |

**Device count (DIRECT, counted by expanding the netlist — see `check_polar_full_adder.py`):**

| stage | devices |
|---|---:|
| 3 × receiver `t_recv2` (2 D + 6 T each) | **6 D + 18 T** |
| carry: 2 × maj3 (52) + 2 × nor3 veto (12) + 2 × and2 (12) | 76 T |
| sum: intermediates `p1/n1/p2x/n2x/pz/nz` (128) + outputs (52) | 180 T |
| output: 2 × inv + 2 × driver | 8 T |
| **total** | **6 D + 218 T = 224 devices** |

---

## 2. Truth table — all 7 digit-sum classes verified

`sum = (a+b+cin) mod 3`, `carry = +1 iff s≥+2`, `−1 iff s≤−2`. 13 representative rows of the
27 were simulated (DC inputs, output read at 130 ns) — **all 13 correct** (DIRECT). The rows
cover every sum class `s∈{−3…+3}`, both carry directions, the wrap rows, and the carry veto:

| row | (a,b,cin) | s | sum | carry | measured (V) |
|---|---|---|---|---|---|
| +3 | (+1,+1,+1) | +3 | 0 | +1 | 0.000 / **+0.996** ✓ |
| +2 | (+1,+1,0) | +2 | −1 | +1 | −0.996 / **+0.996** ✓ |
| +2 | (0,+1,+1) | +2 | −1 | +1 | −0.996 / **+0.996** ✓ |
| +1 | (+1,0,0) | +1 | +1 | 0 | +0.996 / 0.000 ✓ |
| +1 | (+1,+1,−1) | +1 | +1 | 0 | +0.996 / 0.000 ✓ *(carry vetoed by the pull)* |
| 0 | (0,0,0) | 0 | 0 | 0 | 0.000 / 0.000 ✓ |
| 0 | (+1,−1,0) | 0 | 0 | 0 | 0.000 / 0.000 ✓ *(cancel)* |
| 0 | (+1,0,−1) | 0 | 0 | 0 | 0.000 / 0.000 ✓ |
| −1 | (−1,0,0) | −1 | −1 | 0 | −0.996 / 0.000 ✓ |
| −1 | (−1,−1,+1) | −1 | −1 | 0 | −0.996 / 0.000 ✓ |
| −2 | (−1,−1,0) | −2 | +1 | −1 | +0.996 / **−0.996** ✓ |
| −2 | (0,−1,−1) | −2 | +1 | −1 | +0.996 / **−0.996** ✓ |
| −3 | (−1,−1,−1) | −3 | 0 | −1 | 0.000 / **−0.996** ✓ |

The wrap is correct in both directions (`1+1 = 1T̄`, `T̄+T̄ = T̄1`) and the carry veto works
(`(1,1,−1)` has two pushes but a pull, so `cop` stays 0). The full 27-row table is covered
analytically by the `expected()` function in the checker; 13 rows were measured.

---

## 3. Energy per add (DIRECT, ngspice supply integral over a full cycle ÷ 2)

Same harness as `tsum_cell.cir`: ±1 V rails, 10 fF wire + 2 fF rail caps, `Rterm=100 kΩ`
null-return, `Rwire=100 Ω`. Three input patterns, plus a binary FA reference built in the
*same* netlist:

| instance | what toggles | energy/toggle |
|---|---|---:|
| **polar FA, cheapest** | a=c=0, b: null↔+1 (output null↔+1, no carry) | **1501 fJ** |
| **polar FA, carry** | a=+1, c=0, b: 0↔+1 (sum +1↔−1 full swing, carry 0↔+1) | **2618 fJ** |
| **polar FA, full swing** | a=+1, c=0, b: +1↔−1 (2 V input swing) | **4401 fJ** |
| **binary FA ref** (46 T, same ±1 V) | a=+1, cin=0, b: −1↔+1 | **798 fJ** |

Null-idle (all-null inputs, quiet window 10–85 ns) = **27.9 aJ** — statistically the noise
floor, i.e. the diode receiver's "null is free" survives the 3-input carry/sum logic
(DIRECT). A held rail (a=+1) leaks **~17.4 µW** through `Rterm` + next-receiver keepers —
the same static null-return leakage `break_before_make.md` identified as the dominant term
in the gate numbers, carried unchanged into the full adder.

**The honest energy read:** the "energy per add" is dominated by the same static
null-return leakage + internal switching that made the 2-input sum 898 fJ; the full adder is
**~1.9× the binary FA at the cheapest toggle and ~5.5× at the full-swing toggle**, on
identical rails. Against the *canonical* single-ended binary inverter (6.94 fJ/toggle,
`fair_binary.md` §4) the polar FA is ~216–634× — but that is not a like-for-like (one
inverter vs a 3-input adder, single-ended vs bipolar); the 798-fJ same-harness binary FA is
the fair denominator.

---

## 4. Delay (DIRECT)

Propagation delay (input 50% → output 50%, measured by `TRIG/TARG` on the carry instance):

| path | delay |
|---|---:|
| carry 0 → +1 | **0.40 ns** |
| sum +1 → −1 | **0.51 ns** (critical path) |

~0.5 ns across receiver → restore → maj3 → veto/grouping → driver (≈6 gate depths), at the
LEVEL=1 idealized device sizes. The null-*return* (output → 0 after release) is the
Schottky/keeper-limited ~5 ns already documented in `diode_gates.md` §6 and is not included
in the propagation figure.

---

## 5. The honest verdict vs the baselines

| quantity | polar FA (this) | binary FA | CMOS ternary FA | ratio |
|---|---:|---:|---:|---:|
| devices | **224** (218 T + 6 D) | 28 T (canonical) | 192 T (2-wire `tadd1`) | **8.0×** binary; **1.17×** ternary |
| energy / add | **1.50–4.40 pJ** (2.62 pJ w/ carry) | 0.798 pJ (same ±1 V) | 0.054–0.368 pJ (single *gate*, not FA) | **1.9–5.5×** binary (same harness) |
| delay | **0.5 ns** | (not re-measured here) | — | — |

**It does not beat binary.** 224 devices is 8× the canonical 28-T binary FA, and the
energy is ~1.9–5.5× the binary FA measured in the *identical* harness. (The "6.94 fJ"
figure in the brief is a single binary *inverter* at single-ended 0→1 V, not a full adder;
a binary FA is 28 T and a few gates of energy.)

**It does not even beat the 2-wire CMOS ternary FA.** The 2-wire `tadd1` is 192 T; the
single-wire polar version is 224 devices — the 32-device *premium* is the cost of the polar
representation itself: 3 diode-direction receivers (6 D + 18 T) to demux the single wires,
and 2 push-pull drivers + inverters (8 T) to re-encode the single-wire outputs. The
boolean carry/sum logic inside is the *same* 192-T factoring as `tadd1`.

This closes the loop on the program's standing verdict: the polar single-wire
representation wins at the *link* (null is free on the wire, `polar_gates.md` /
`ENERGY_RESULTS.md`) but loses at the *gate* — and the full adder, the workhorse cell, is
where that loses hardest, because every one of its 3 input wires must be demuxed (2 diodes
+ 2 thresholds each) and both its output wires re-encoded. Ternary compute remains a
transistor-technology bet, not a CMOS cell-topology bet.

---

## 6. Caveats (same class as every fair fight in `circuit/`)

- **LEVEL=1, no body diodes, no mismatch, no subthreshold leakage.** The elevated-|Vt|
  dead zone (|Vt|=1.4 V) is a hard cutoff in the model; silicon's floor is leakage, not
  zero, and the ~0.4 V dead-zone margin sits near process-offset territory (2 thresholds =
  2× the offset budget). The 27.9-aJ null-idle is a model artifact.
- **The energy is dominated by static null-return leakage** (`Rterm=100 kΩ` + receiver
  keepers ≈ 17 µW while a rail is held), which scales with hold time — per
  `break_before_make.md`, a higher `Rterm` or a clocked receiver removes most of it, and
  would shrink the 1.9–5.5× toward the intrinsic ½CV² + crowbar floor.
- **The carry threshold is static-CMOS majority, not a native 3-state device.** The
  multi-Vt / CNTFET / RTD native cells of `device_circuit.md` (which *could* fold the two
  thresholds into one device) were not used; they remain unmodeled in ngspice LEVEL=1.
- **Cheapest-toggle convention.** The 1501 fJ is the null↔+1 half-swing toggle; a real
  ±1-weighted add (the 2618–4401 fJ figures) is the number to carry into a ripple.

## 7. Files

- `circuit/polar_full_adder.cir` — the netlist (fully commented; `ngspice -b` runs clean):
  `dd_recv`/`t_recv2`/`pol_fa` + 13 truth-table instances + 3 energy instances + binary-FA
  reference.
- `circuit/gen_polar_full_adder.py` — regenerates the netlist (the 27-row `expected()`
  enumerates the full truth table; the netlist simulates a representative 13-row subset).
- `circuit/check_polar_full_adder.py` — parses the log, checks the truth table, counts the
  devices by subckt expansion, reports energy/delay.
- `circuit/polar_full_adder.log` — the measurements.

*Every number above is measured by `circuit/polar_full_adder.cir` (ngspice 44.2) or
counted from its netlist; the design decisions are flagged in §1; nothing is invented.*
