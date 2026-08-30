# Per-Gate Test Suite Specification — Native Polar Ternary Gates (fair-fight)

**2026-08-29 — the measurement contract for the native-device gate suite.**
This is the spec that the Batch-1 "test-suite" angle (`docs/TERNARY_GROUND_UP.md`
item 8: "ngspice: per-gate fair-fight test circuit") must implement **once a native
3-state device model exists.** It is a SPECIFICATION, not results: it defines *what
to measure*, *how to make it fair*, *what "pass" means* — it invents no number for
the native device. Every number it cites is an anchor already measured on 2-level
devices and is tagged `[DIRECT — source]`; every claim about how a native device
*will* behave is tagged `[SPECULATION]`; every decision about the harness itself is
`[OURS]`.

**Calibration legend (house standard, `docs/MAP_BRIEF.md`):**

- **DIRECT** — measured or proved (our ngspice/yosys numbers, our Lean proofs).
- **ANALOGY** — parallel structure to something real, not an identity.
- **OURS** — our own design decision for this suite (the harness, the criteria).
- **SPECULATION** — untested hypothesis about the native device, flagged.

---

## 0. Purpose & scope

The two prior gate benchmarks measured polar ternary gates built from **2-level
MOSFETs** and both lost:

- `docs/compute/polar_gates.md` — the *native single-wire* polar gate (demux → logic →
  driver) lost **4.9–14.3× per bit** vs binary. `[DIRECT]`
- `docs/compute/gate_energy.md` — the *2-wire emulated* gate lost **1.21–3.14× per bit**.
  `[DIRECT]`

Both paid the same hidden tax: **a 2-level transistor cannot natively produce 3 states,
so every ternary gate pays a demux (2 sense amps per input wire) + re-encode (push-pull
driver per output wire) before any logic happens.** `[DIRECT — polar_gates.md]` The whole
premise of `docs/TERNARY_GROUND_UP.md` is that **the native 3-state device was never
built**, and a device that thresholds three states *natively* (RTD, multi-threshold
CNTFET, SET) would not pay that tax. `[SPECULATION]`

**This spec defines the test suite that settles that claim.** It is deliberately
device-agnostic: it specifies the *interface* a native device model must satisfy
(§1), the *harness* (§3), the *measurements* (§4), the *traps* (§5), and the
*pass/fail* (§8). The device model is a plug-in.

---

## 1. The native-device contract (the thing we are waiting for)

The suite cannot be written in ngspice until a device model exists. To run §4–§8, the
model must expose, per native device:

| interface item | required for | notes |
|---|---|---|
| a **3-state threshold** transfer curve (I–V or V–V with three distinguishable, latchable states at −V, 0, +V) | energy, idle, delay | without this the gate still needs a 2-threshold demux, and the whole premise fails `[SPECULATION]` |
| per-state **on-resistance / series resistance** (R_push, R_pull, R_null) | energy, peak current, di/dt | drives `∫ V·I dt` and `di/dt` |
| per-state **leakage / static current** at the null level | idle/null power | the null-at-threshold trap (§5.2) lives here |
| a **switching speed** (transit time between states) | propagation delay | |
| an **area-per-device** (µm² per native device) | transistor count / area | count alone is not area — see §4.5 |
| a **named state for null** that is the *default/off* state | null-as-default idle (§6) | Ian's rule: "null = 0 = default = off" |

`[OURS]` for the interface; the existence of a device satisfying it is `[SPECULATION]`.

**What "one gate" means on the native device.** On the 2-level cell, "one gate" =
2·(fan-in) sense amps + logic + 1 driver. On the native device, "one gate" = **the
minimal network of native devices that realizes the truth table**, with *no* demux and
*no* re-encode unless the specific gate needs them. If the realization still needs a
2-level helper (a MOSFET for a drive-strength boost, say), it is counted in the device
count and its energy is attributed to the gate. `[OURS]` The hypothesis under test is
that the count collapses from `polar_gates.md`'s 18/44/44/100 transistors toward the
native minimum. `[SPECULATION]`

---

## 2. Gates under test & their binary references

Four gates (the balanced polar set, matching `circuit/polar_gates.cir`), each with a
**semantic binary reference** and a **floor binary reference**:

| ternary gate | truth table (on {−1,0,+1}, order −1<0<+1) | semantic binary ref | floor binary ref |
|---|---|---|---|
| **NOT** (negation) | −1→+1, 0→0, +1→−1 | binary NOT (inverter, 2 T) | — |
| **MIN** (meet / AND) | lesser trit | binary AND (6 T) | binary NAND (4 T) |
| **MAX** (join / OR) | greater trit | binary OR (6 T) | binary NOR (4 T) |
| **mod-3 sum** (F₃ +, "ternary XOR") | (a+b) mod 3, balanced: +1+1→−1, +1+0→+1, +1−1→0, 0+0→0, 0−1→−1, −1−1→+1 | binary XOR (≈6–12 T) | binary full adder (≈12 T) |

`[DIRECT — docs/compute/gates.md truth tables; our `trit_functions.vh`]`

**Two binary controls are required, not one** — this is a fairness point the prior
runs only half-covered:

1. **Real binary baseline (primary).** The binary gate built from standard 2-level
   MOSFETs (sky130 / `LEVEL=1`), measured at the *same* ±VDD rails and *same* load as
   the ternary gate. This is "binary as the incumbent actually exists." `[OURS]`
2. **Same-device 2-state control (secondary).** The *same* native device used in
   2-state mode (two of its three states) to build the binary gate. This isolates
   **"is the win the radix, or the device?"** — a ternary gate can "beat binary" purely
   because the native device is faster/cheaper than MOSFETs, in which case the radix
   claim is not the explanation. `[OURS]`

The headline verdict (§8) is always against the **real binary baseline (1)**; the
same-device control (2) is reported as a diagnostic.

---

## 3. The measurement harness (fair-fight testbench)

The harness is the `ternary_fairfight.cir` / `polar_gates.cir` discipline, generalized
to the native device. **Real driver, real receiver, no ideal sources, full rise/fall
cycles.** `[OURS — carried from `circuit/ENERGY_RESULTS.md`'s fair-fight method]`

### 3.1 Rails, load, receiver, driver — identical for both sides

- **Rails:** both ternary and binary run on **±VDD = ±1.0 V** (the harness default; the
  device model may set its own VDD, but it must be *identical* for ternary and binary).
  Ternary: −1 = −VDD, 0 = 0 V, +1 = +VDD. Binary: 0 = −VDD, 1 = +VDD (the "share the
  rails" convention of `polar_gates.cir`, generous to ternary because binary's natural
  swing is 1 V not 2 V). `[OURS]`
- **Load:** the output of *every* gate (ternary and binary) drives the same `Rwire` +
  `CL` + `Rterm` network into the next stage. Defaults carried from the comm cell:
  `Rwire = 100 Ω`, `CL = 10 fF` (≈ one next-gate input), `Rterm = 100 kΩ` null-return.
  `[OURS]`
- **Receiver:** the *same* threshold element reads both outputs. Binary uses **1
  threshold**; ternary uses **however many the native device needs natively** (the
  claim under test: 1, not 2). The receiver's energy is attributed to `E_rec` and
  reported separately, so the "threshold-count tax" is visible as its own line item.
  `[OURS]`
- **Driver:** the gate's own output stage. No ideal current sources, no ideal voltage
  ramps. If the native device *is* its own driver (e.g., an RTD oscillator-stage
  output), that's fine — but then the binary control must be built the same way, or the
  comparison is not controlled. `[OURS]`

### 3.2 Energy accounting (the two-bucket rule)

Carried verbatim from `polar_gates.cir` / `gate_energy.cir`:

- **E_gate** = the gate's own supply energy: input thresholding + logic + output
  driver, over one **full output cycle**.
- **E_rec** = the output receiver's supply energy (the *next* stage's thresholding),
  firing once per transition.
- **E_total = E_gate + E_rec**, and **per-toggle = E_total / 2** (one full cycle =
  two toggles).
- Energy is `∫ V·I dt` via a behavioral source `V = -(V(vdd)·I(VSUP) + V(vss)·I(VSS))`
  integrated over the cycle window. No ideal source may *absorb* returned charge and
  credit it as recovery unless the modeled supply genuinely accepts it (power-clock).
  `[DIRECT — ENERGY_RESULTS.md CORRECTION 1: ideal-source flattery was ~90–95% on the
  ramp scheme]`

### 3.3 The toggle definition & full-cycle rule

- A **full cycle** is a *return* transition: state A → state B → state A. **Per-toggle
  = full-cycle energy / 2.** A single edge is never a toggle. (§5.1 is the reason.)
- **Coverage.** Every gate is exercised over its full transition matrix, not one
  cherry-picked toggle:
  - all **3 output values** for ternary (0, +1, −1) and both directions of each edge;
  - at least one **full-swing +1↔−1** transition (the most expensive);
  - the **null↔±1** half-swing transitions (the cheapest);
  - a **null-hold idle** window (§6).
- **Headline energy** = the **uniform-average per-toggle** over the reachable output
  toggles (default input distribution: uniform over the 3 trit values). The *cheapest*
  toggle (null↔+1) is reported separately, explicitly flagged **"generous to ternary"**,
  because it swings only one half of the rail. `[OURS]`

---

## 4. Per-gate measurements (the six quantities)

Each gate (ternary) and each binary reference must report all six. None is optional;
a missing row fails the suite's own completeness check. `[OURS]`

### 4.1 Energy per full toggle (E_toggle)

- E_gate, E_rec, E_total, **per-toggle = E_total/2**, over a full cycle. `[OURS]`
- Report per-toggle for (a) the uniform average, (b) the cheapest (null↔+1), (c) the
  worst (full-swing +1↔−1). The pass/fail uses (a). `[OURS]`
- **Normalize per bit: ÷ log₂3 ≈ 1.585 for ternary, ÷1 for binary.** `[DIRECT —
  RadixEconomy.lean; the house normalization]`

### 4.2 Peak current (I_peak)

- `I_peak = max over the transition of |I_supply(t)|`, measured on **both** supplies
  (push supply and pull supply) — the two polarities are not symmetric. `[OURS]`
- Report the larger of push/pull. Units: mA. Anchored by the comm work
  (`lowswing_sweep`: FAIR driver 1.26 mA full-swing, VTENG 1.9–3.5 mA, resonant
  44–95 µA). `[DIRECT — ENERGY_RESULTS.md low-swing/resonant tables]`

### 4.3 di/dt

- `di/dt = max |ΔI/Δt|` over the transition window, on the supply that slews hardest
  (usually turn-*off* — the ground-bounce/L·di/dt term). Measured as the max slope of
  `I_supply(t)` (ngspice `DERIV` where available, else `ΔI/Δt` from the sampled
  waveform). `[OURS]`
- Report **turn-on and turn-off di/dt separately**; the turn-off is the one that
  matters for supply bounce. Units: A/µs. `[OURS]`
- Peak current and di/dt are **constraints, not figures of merit** — see §8.

### 4.4 Idle / null power (P_null)

- `P_null` = (VDD·I_dd + VSS·I_ss) with **all inputs and the output held at null**, in
  steady state. `[OURS]`
- `P_hold` = the same with the output **held at +1** (and separately **−1**), to
  contrast "idle at null" vs "holding a value." The null-as-default claim (§6) requires
  `P_null` ≪ `P_hold`. `[OURS]`
- **Null-at-threshold probe** (mandatory, §5.2): sweep the null level over a small
  window around 0 (e.g. −50 mV … +50 mV) and record supply current at each point.
  A current *spike centered at exactly 0* means the null is meta-stable and `P_null`
  is shoot-through, not leakage. `[OURS]`

### 4.5 Transistor count / area

- **Count** = number of native 3-state devices + any 2-level helpers, per gate.
  Report the count, and a per-input-wire breakdown (threshold elements, logic, output
  stage) so the "where did the tax go" is visible. `[OURS]`
- **Area** = count × **area-per-device** (from the device model). **Area is the
  headline; raw count is a diagnostic** — a native device (RTD, CNTFET) may be
  physically larger than a MOSFET, so "fewer devices" can hide a bigger footprint.
  Until a real area-per-device exists, report count only and mark area **PENDING**.
  `[OURS]`
- **Normalize per bit: ÷1.585 (ternary) vs ÷1 (binary).** Note the deliberate change
  from the 2-wire emulation: the native single-wire device carries 1.585 bits/**wire**
  (vs binary's 1), so per-wire normalization now *favors* ternary, unlike the 2-wire
  encoding's 0.79 bits/wire. `[SPECULATION — the premise this suite tests]`

### 4.6 Propagation delay (t_pd)

- `t_pd` = input crossing its threshold (50% of its swing) → output crossing its
  threshold (50% of its swing). For the 3-level signal, thresholds are the −1/0 and
  0/+1 boundaries (±VDD/2 for symmetric rails). `[OURS]`
- Report **t_pd↑ and t_pd↓ separately** (the asymmetry trap applies to delay too), for
  every transition class, plus **worst-case t_pd** (max over classes) as the gate's
  headline delay. `[OURS]`
- If the gate is clocked/pipelined (the `polar_gates.cir` dynamic style), also report
  the **minimum cycle time**. `[OURS]`

---

## 5. The two traps (mandatory; the suite is dishonest without them)

### 5.1 The rise/fall-asymmetry trap (assert-only flatters ~2×)

**The trap.** A real gate's assert edge and release edge are not symmetric: a binary
NAND's *rise* charges its internal series node (expensive) while its *fall* is nearly
free; the ternary MIN's push path is the mirror image. Measuring **only the assert
edge** quotes the cheap (or the expensive) half and misreports the per-toggle energy by
up to ~2× — in whichever direction flatters the claimant. `[DIRECT — gate_energy.md,
measured: binary NAND rise 30.9 fJ / fall −8.0 fJ; ternary min push rise 14.3 fJ /
fall 29.9 fJ]`

**The rule.** `[OURS]`

1. A **full cycle (assert + release) is the only legal "toggle."** Per-toggle =
   full-cycle energy / 2, always.
2. Both edges are reported **individually** (E_rise, E_fall), so the asymmetry is on
   the record, not averaged away silently.
3. No headline number may be an assert-only or a cheapest-edge number; if a cheap edge
   is quoted it must carry the "generous to ternary" flag (§3.3).

### 5.2 The null-at-threshold trap (the meta-stable null)

**The trap.** In the single-wire representation the null (0 V) sits **exactly at the
sense amp's threshold**, so the receiver sits at a saddle: it draws **continuous
shoot-through current for the whole eval phase**, and its kickback can tip the latch to
a false "push". Binary never sits at a threshold — its rails are always driven
full-swing. Measured on the 2-level cell: a held-null input lifted MAX/SUM's E_gate to
**2.3–3.1× MIN's** (which held a clean +1), with ~0.18 V of kickback. `[DIRECT —
polar_gates.md, finding 2]`

**The rule for the native suite.** `[OURS]`

1. The null's *static* cost must be measured at the null level itself (§4.4), not
   assumed free because "nothing is energized."
2. The **null-at-threshold probe** (§4.4) must be run: a current spike centered at
   exactly 0 V is the meta-stable signature. If present, the null is **not** free at
   the gate and the "free null" transport claim does not transfer to compute.
3. The null's **kickback** into a high-impedance predecessor must be measured (the
   output node's excursion when the gate's input is a held null driving the receiver),
   and a false-latch must be treated as a truth-table FAIL, not a tolerance.

The honest statement this trap protects: **the null is free on the wire, not
necessarily in the gate** — a gate must still *resolve and hold* −1/0/+1 every cycle,
and if "resolve null" means "sit on a threshold," the null is the *most expensive*
state, not the cheapest. `[DIRECT — the verdict of `gates.md` §6b and `polar_gates.md`]`

---

## 6. Null-as-default idle (Ian's rule) — how to handle it

`docs/TERNARY_GROUND_UP.md` item 6: **"null = 0 = default = off; power only on
push/pull."** The suite must test this as a *measurable idle contract*, not assume it.
`[OURS]`

Three idle states are distinguished and all three are measured:

| idle state | inputs | output | metric | what it proves |
|---|---|---|---|---|
| **asleep** | null | null | `P_null` | the default is genuinely off |
| **holding ±1** | (any) | latched +1 / −1 | `P_hold` | holding a value costs more than idling |
| **binary idle** | binary input held | binary output held | `P_binary_idle` | the comparison |

**The null-as-default claim PASSES iff** (a) `P_null` ≤ `P_binary_idle` **per bit**
(÷1.585), and (b) `P_null` ≪ `P_hold` — i.e. idling at null is cheaper than holding a
value, so a datapath that *rests at null* genuinely saves power over one that must hold
a bit. `[OURS]`

**Corollary the suite must also measure:** a gate's *output* idle depends on the gate
*upstream*. A NULL at the input of a MIN is a real data value (not a don't-care), so a
"rest at null" datapath exercises every gate's null-handling on every idle cycle. The
suite therefore measures idle power **with null inputs** (the balanced-ternary natural
idle), not just with the output forced to null. `[OURS]`

---

## 7. Fair-fight rules (the explicit checklist)

Every run must satisfy **all** of these, or it is not a fair fight. `[OURS — the
compiled honesty rules of `ENERGY_RESULTS.md`, `gate_energy.md`, `polar_gates.md`]`

1. **Real driver, real receiver, no ideal sources.** No ideal current sources, no ideal
   ramp/LC sources, no ideal comparators, no free sense amps. The driver's channel loss
   is counted; the receiver's supply energy is counted.
2. **Same rails.** Ternary and binary on identical ±VDD; no "ternary low-swing vs binary
   full-swing" unless it is an explicitly separate, labeled experiment.
3. **Same load.** Identical `Rwire`, `CL`, `Rterm` at every output, ternary and binary.
4. **Same receiver, differing only in threshold count.** The comparison isolates the
   "1 vs 2 (or 1 vs n) thresholds" tax at identical common mode.
5. **Full rise/fall cycle.** Per-toggle = full-cycle/2, never a single edge (§5.1).
6. **Energy = ∫ V·I dt; no fictional recovery.** Charge recovery is credited only to a
   supply that accepts it (power-clock), never to an ideal source.
7. **Uniform toggle distribution** for the headline number; cheapest toggle reported
   separately and flagged generous (§3.3).
8. **Device model declared and uniform.** Model level, body-diode presence, and device
   mismatch are stated once, and are *the same* for ternary and binary. If mismatch is
   unmodeled, that is declared and is *generous to ternary* (a 2-threshold receiver has
   2× the offset budget). `[DIRECT — the caveat class in `gate_energy.md`]`
9. **Binary references are explicit.** Both the real-binary baseline and the same-device
   2-state control are reported (§2); the headline is against the real-binary baseline.
10. **The receiver tax is a separate line item.** E_rec is reported independently of
    E_gate so the "where did the win/loss go" is visible, never lumped.

---

## 8. Pass/fail criteria (the log₂3 normalization)

### 8.1 Normalization definitions

- **Per-bit = per-trit ÷ log₂3 = per-trit ÷ 1.585** (ternary); **per-bit = per-symbol ÷ 1**
  (binary). `[DIRECT — `RadixEconomy.lean`]`
- Applied to **energy, area, and idle power** (the per-gate *costs*). **Delay** is not
  divided (a gate's latency is per-gate, not per-information-unit) — instead delay is a
  constraint and the energy verdict is re-checked at matched throughput (§8.3).
  `[OURS]`

### 8.2 Per-metric pass/fail

| metric | PASS iff (ternary vs binary) | normalized? |
|---|---|---|
| **energy per toggle** | `E_toggle_T / 1.585 < E_toggle_B` | yes — the headline |
| **area (transistor count)** | `A_T / 1.585 < A_B` | yes |
| **idle/null power** | `P_null_T / 1.585 ≤ P_idle_B` **and** `P_null ≪ P_hold` | yes |
| **propagation delay** | `t_pd_T ≤ t_pd_B` (iso-throughput) | no — constraint |
| **peak current** | `I_peak_T ≤ I_peak_B` (or ≤ stated EMI budget) | no — constraint |
| **di/dt** | `di/dt_T ≤ di/dt_B` (or ≤ stated L·di/dt budget) | no — constraint |

`[OURS]`

**"Beat binary per bit"** is the energy row and the area row: **PASS = strictly less,
per bit, after ÷log₂3.** A gate that ties or loses per bit FAILS, regardless of how the
cheapest-toggle or the raw per-trit number looks.

### 8.3 Overall gate verdict

A gate **PASSES** iff:

1. **energy-per-bit PASS** (the headline), **and**
2. **area-per-bit PASS**, **and**
3. **idle-per-bit PASS** (null actually idles — §6), **and**
4. **delay PASS** (no slower than binary) — or, if slower, the energy win is
   re-verified as a **energy·delay product** win at matched throughput (a slower-but-
   cheaper gate does not "beat binary" on energy alone; the comparison is at equal
   throughput), **and**
5. **both traps are clean** — full-cycle measured (§5.1) and the null-at-threshold probe
   shows no meta-stable null (§5.2).

Any single FAIL names the failing metric. A FAIL is recorded with the ratio, e.g.
"MIN: energy 0.92 pJ/bit vs binary AND 0.60 pJ/bit → **1.53× worse, FAIL**." `[OURS]`

### 8.4 The report table template

Every gate report ends with this table, filled with measured values (none invented
here):

```text
gate: __________                    binary ref: __________
                 ternary (per trit)   per bit (÷1.585)    binary (per bit)   verdict
E_toggle         ______________       ______________       ______________    PASS/FAIL
area (count)     ______________       ______________       ______________    PASS/FAIL
P_null           ______________       ______________       ______________    PASS/FAIL
t_pd (worst)     ______________       (÷1, constraint)     ______________    PASS/FAIL
I_peak / di/dt   ______________       (÷1, constraint)     ______________    PASS/FAIL
traps: full-cycle? ____   null-at-threshold clean? ____
OVERALL: PASS / FAIL (reason)
```

---

## 9. Calibration summary (OUR / SPECULATION / DIRECT / ANALOGY)

| claim in this spec | calibration |
|---|---|
| the harness topology (rails/load/receiver/buckets/toggle rule) | **OURS** — carried from `circuit/` fair-fight method |
| the six quantities and their definitions | **OURS** — the suite's own contract |
| the fair-fight checklist (§7) | **OURS** — compiled from the existing honest-string caveats |
| the pass/fail thresholds (§8) | **OURS** — "beat binary per bit after ÷1.585" |
| the rise/fall ~2× asymmetry exists | **DIRECT** — `gate_energy.md` measured edges |
| the null-at-threshold meta-stability exists | **DIRECT** — `polar_gates.md` finding 2 (2-level cell) |
| the 2-threshold receiver tax (2.54× / 2.00×) | **DIRECT** — `gate_energy.md` / `gate_area.md` |
| the 4.9–14.3× per-bit losses of the 2-level polar gate | **DIRECT** — `polar_gates.md` |
| a native 3-state device removes the demux+driver tax | **SPECULATION** — the premise of `TERNARY_GROUND_UP.md` |
| a native single-wire device yields 1.585 bits/wire (vs binary 1) | **DIRECT** (radix economy) + **SPECULATION** (that it *wins* the fight) |
| a native device may be physically larger than a MOSFET (area ≠ count) | **ANALOGY** — ported from the CNTFET/RTD literature, not measured |
| null will be free *at the gate* on a native device | **SPECULATION** — the exact thing §5.2 tests |

**The suite's job is to move the SPECULATION rows to DIRECT.** Until it runs, the
verdict remains: ternary gates lost on 2-level devices (DIRECT), and whether a native
device flips that is open (SPECULATION).

---

## 10. Deliverable format (what each gate report must contain)

One netlist per gate (or one netlist with all gates + controls, `polar_gates.cir`
style) plus a `.log` and a `.md` summary. The `.md` must contain: the six quantities
(§4), the two traps' results (§5), the idle table (§6), the fair-fight checklist
attestation (§7), the pass/fail table (§8.4), and — mandatory — a closing
`## TODO / not covered / caveats` section. `[OURS — `TERNARY_GROUND_UP.md` feedback
loop]`

---

## TODO / not covered / caveats

- **No device model exists yet.** The entire suite is blocked on §1's interface: an
  RTD / multi-threshold CNTFET / SET model with a named, latchable 3-state null and a
  per-device area. Until one lands, no row of §8.4 can be filled. This spec is the
  *target*, not a runnable netlist.
- **The gate set is the *2-input* polar set.** The 3-input balanced full adder (with
  the balanced carry — the actual load-bearing arithmetic cell) is out of scope here
  but is the first follow-up; its carry needs two more thresholds and will be the
  hardest cell. `[OURS — flagged in `polar_gates.md`]`
- **mod-3 *product* (`tmul`) is not in the requested set.** It is the other half of the
  complete F₃ pair and must be added to make the completeness claim testable.
- **The binary floor references (NAND/NOR/XOR/FA) use a *static* cell on ±1 V rails**
  (generous to ternary, which can swing 1 V half-rails). A binary single-ended 0–1 V
  reference (~2× cheaper) would move every verdict further against ternary and is a
  second control the suite should add. `[DIRECT — `polar_gates.md` caveat]`
- **Device mismatch / offsets are unmodeled** in the LEVEL=1 harness; real SA offsets
  (σ ≈ 5–20 mV) make the null meta-stability *worse*, so any measured win is an upper
  bound. The suite must eventually re-run with mismatch, else it is optimistic.
- **di/dt extraction** (ngspice `DERIV` vs waveform ΔI/Δt) needs a fixed, documented
  convention before numbers are comparable across runs.
- **Uniform toggle distribution is the default assumption**; a real workload's trit
  distribution (Zipf / null-dominated vs uniform) changes the average. The suite should
  also report the null-dominated average, since that is where the transport-layer win
  lives — but it must not be the headline.
- **Area is count-only until a per-device area exists**; the "fewer devices but bigger
  devices" risk (RTD/CNTFET footprint) is explicitly un-quantified here.
- **"Beat binary per bit" is energy+area only.** Speed, peak current, and di/dt are
  constraints, not figures of merit; a gate that wins energy but needs a power-clock,
  exotic process, or body isolation has un-modeled system cost not captured by §8.
