# Null-as-default — the power scheme where 0 V is the resting state

**2026-08-29 — ground-up batch 1, the "null-as-default" angle.** This is a *design* doc,
not a measurement. No number here is invented: every quantity is either cited from an
existing `circuit/` log (DIRECT) or explicitly marked OURS/SPECULATION as an untested
estimate.

**Calibration legend** (repo standard):

- **DIRECT** — measured (ngspice log) or proved (Lean) or a textbook identity. Cite the file.
- **ANALOGY** — structural resemblance, not identity.
- **OURS** — our design claim; follows from DIRECT but is not independently established.
- **SPECULATION** — untested hypothesis; flagged as such, never stated as fact.

---

## 1. Ian's rule, stated as a circuit property

> "The null state should be set to be the default, so power is only used when needed."

In a balanced-ternary cell the null (0) is the *middle* state. Ian's rule, translated to
silicon, is a precise engineering target:

- **RESTING / idle = null = 0 V = no current.** The driver's two output devices are both
  off (high-impedance), the wire sits at 0 V through a passive return, and the receiver
  draws (ideally) zero current because nothing is arriving.
- **Power is drawn only when a push (+1) or pull (−1) is actually transmitted.** A non-null
  symbol is a *pulse of charge*, and only that pulse costs energy.

That is: **power ∝ data activity**, with the null (the *most common* symbol in balanced
ternary, the "default") costing nothing. **[OURS — this is the goal, restated.]**

The driver already meets this. The receiver does not. That asymmetry is the whole problem,
and section 3 is the fix.

---

## 2. Where the current gate fails Ian's rule (the DIRECT diagnosis)

The native polar gate (`circuit/polar_gates.cir`, `docs/compute/polar_gates.md`) reads a
3-level wire with **two clocked sense amps comparing the wire against 0 V**:

```
push SA:  fire ⇔ wire > 0
pull SA:  fire ⇔ wire < 0
null   :  neither fires  ⇒  the wire sits AT the threshold of BOTH amps
```

Three measured facts are the diagnosis:

1. **Null sits at the threshold, and a threshold-sitting amp is a saddle, not a state.**
   `polar_gates.md` (DIRECT): *"a held-null input lifts MAX/SUM's E_gate to 2.3–3.1× MIN's,
   which holds a clean +1"* — the null-input sense amp draws **continuous shoot-through
   current for the whole 10 ns eval**. MIN (E_gate **1522.6 fJ/toggle**, one input held
   clean +1) vs MAX (**3428.3 fJ/toggle**, one input held null) vs SUM (**4709.6 fJ/toggle**,
   one input held null): the null input adds **~1.9 pJ/toggle** of pure metastability waste.
   The kickback (~0.18 V into the high-impedance null wire) can tip the latch to a false
   "push".

2. **A 0-vs-0 amp costs *more* than a latching amp.** `gate_energy.md` (DIRECT): the ternary
   idle-wire sense amp "stays balanced for the whole eval and draws *more* than a cleanly-
   latching amp, so 2 amps cost 2.54×, not 2×."

3. **The driver is already null-as-default.** `polar_gates.cir` `driver` subckt (DIRECT, 2 T):
   null = `(gp=+VDD, gn=−VDD)` → both PMOS and NMOS off, wire returns to 0 V via `Rterm`.
   Zero gate drive, zero channel current. **The driver was never the wall** — the receiver
   is.

So the honest state of the art: **null is free on the wire (comm cell, 0.05 pJ) but is the
most expensive thing in the gate (≈1.9 pJ/toggle shoot-through + a full receiver eval every
cycle), because the gate *levelsamples* the wire at 0 V on a free-running clock.** Two
separate causes, two separate fixes.

---

## 3. The design — null-as-default receiver

The fix has three coordinated parts. Each is individually necessary, none is sufficient
alone.

### 3.1 Re-encode null as *absence* (no-pulse = null), not as a 0-V *level*

**The core idea.** Stop treating a trit as a 3-valued voltage level `{−V, 0, +V}` sampled
every cycle. Treat it as an **event**: a return-to-zero pulse on one wire.

| trit | wire event | energy |
|---|---|---|
| **+1 (push)** | a positive charge pulse, then return to 0 | one pulse's worth |
| **−1 (pull)** | a negative charge pulse, then return to 0 | one pulse's worth |
| **0 (null)** | **no pulse at all** — the wire never leaves 0 V | **nothing to transmit, nothing to detect** |

**[OURS — this is exactly the comm cell's AC-polarity protocol, promoted from transport to
compute.]** The comm cell already *is* "no-pulse = null" — that is precisely why its null
measures 0.05 pJ (DIRECT, `circuit/ENERGY_RESULTS.md`, CORRECTION 1 & 2): null is "nothing
to transmit," and the diode rectifier delivers no charge, so nothing burns. The gate's job
is to inherit that property instead of throwing it away at the demux.

### 3.2 The receiver: a *passive charge integrator* + a *dead-zone*, not 2× zero-threshold level samplers

Replace the "wire vs 0" level sampler with a front-end that only *energizes* when a pulse
delivers charge:

1. **Passive rectifier (verbatim `tcell4`, DIRECT).** A diode (or diode-connected MOSFET)
   leg per polarity steers push current onto `C_push` and pull current onto `C_pull`. A null
   pulse delivers **zero charge**, so both caps stay at 0 V and no diode conducts. The
   front-end has **no bias current in idle** — it is passive.

2. **Dead-zone — the trip points move off 0 V (the fix for the meta-point).** The caps are
   read against explicit thresholds `±V_th`, with `V_th > 0`:

   ```
   push  ⇔ V(C_push) > +V_th
   pull  ⇔ V(C_pull) > +V_th   (mirrored on the negative side)
   null  ⇔ both rails < V_th    ← a guaranteed OFF state, a full V_th from each trip point
   ```

   The null no longer sits *at* a threshold; it sits a full `V_th` *below* both. The
   "saddle at 0 V" is gone. `polar_gates.md`'s own caveat — "the diode rectifier moves the
   meta-point to the rails and leaves the push rail at 0 V for both pull and null" — is
   exactly what the dead-zone repairs: **0 V is now "off", not "at the trip point".**

   **Choice of `V_th` (OURS, anchored to DIRECT):** the lowswing sweep measured the stock SA
   resolving at rail asserts of **22 mV** (FAIR, VDDR=0.65 V) down to **~15 mV**, with
   real-process offset σ ≈ **5–20 mV**. So `V_th ≈ 50–100 mV` gives a ≥5×-offset dead-band
   while keeping the pulse swing in the already-measured cheap regime. (A Schmitt/hysteresis
   input does the same job for a level encoding.)

3. **Data-gated sense amp (unchanged 7-T SA, but its clock is `arm_push OR arm_pull`).**
   The SA — its 0.052–0.087 pJ/trit cost is DIRECT (`receiver_cheap.md`, `lowswing_sweep.md`)
   — fires **only when a rail has crossed `V_th`**. A null symbol arms neither rail, the SA
   clock never rises, **no tail current, no eval, ~0 receiver energy.**

### 3.3 The crux Ian's rule forces: *null is only free if the cell is self-timed (or data-gated)*

A synchronous pipeline fires every sense amp every clock edge, so a null symbol would still
pay one eval (the receiver floor 0.052–0.087 pJ) — null-as-default would fail *structurally*,
not electrically. The dead-zone alone fixes the shoot-through but not the "measure every
cycle regardless" cost. Therefore:

- **"Power only when needed" is the definition of self-timed (event-driven) logic.** The
  stage must evaluate only when a pulse arrives, and signal completion only when it emits a
  pulse. A null output emits *nothing*, so the downstream stage is not armed and the network
  idles. **[OURS / ANALOGY to Micropipeline-style completion; SPECULATION until built.]**
- **Practical compromise for a clocked chip:** keep the global clock but **clock-gate the
  receiver** behind the cheap passive charge detector ("did any charge arrive?" — a diode +
  a cap, effectively free). This recovers *most* of the win without abandoning synchronous
  design. **[OURS — the charge detector is the passive front-end of 3.2; unmeasured.]**

---

## 4. Idle vs active power — the estimate

All energy numbers are per-trit, one symbol. Sources are DIRECT unless tagged.

| quantity | value | calibration |
|---|---|---|
| **Idle (resting, proposed scheme)** | **0** in the LEVEL=1 harness | OURS/SPECULATION — see caveat below |
| Idle in silicon (off devices + keeper) | subthreshold + gate leakage, nA–µA-class | SPECULATION — **unmeasured** (LEVEL=1 models no leakage) |
| **Active: receiver, per non-null symbol** | **0.052 pJ** (1 ns eval) – **0.087 pJ** (2 ns eval) | DIRECT — `receiver_cheap.md`, `lowswing_sweep.md` |
| Active: driver line charge (10 fF gate wire @ 1 V) | ~5 fJ (½CV²) | OURS — textbook, negligible |
| Active: gate logic (MIN-class) | ~23 fJ | DIRECT — `gate_energy.md` |
| **Active total, per non-null symbol** | **~0.05–0.1 pJ** (receiver-dominated) | OURS — synthesized from DIRECT floor |
| **Null, per null symbol (proposed)** | **≈ 0** (receiver gated off, driver hi-Z) | OURS — the design's target |
| Null, per null symbol (today's gate) | **≈ 1.9 pJ/toggle shoot-through** + a full eval | DIRECT-derived — `polar_gates.md` E_gate 3428.3 − 1522.6 fJ |
| Null, comm cell (transport reference) | **0.05 pJ** | DIRECT — `ENERGY_RESULTS.md` |

**The one-line estimate:** with the null-as-default receiver, **idle → leakage floor and
null → ≈ 0.05 pJ-class (receiver gated off)**, versus today's gate where a held null is the
*most* expensive state (~1.9 pJ/toggle of shoot-through plus a full receiver eval). The
active (non-null) cost is unchanged at the measured receiver floor — null-as-default reduces
the *average* under null-heavy data, it does **not** reduce the per-non-null cost, and it
does not remove the 2-threshold tax on the symbols that *do* fire.

---

## 5. Can the null be made genuinely free in the gate?

**Verdict: yes — but only by changing *what the receiver does with null*, and only in a
self-timed (or data-gated) cell.** **[OURS/SPECULATION — pending a netlist.]**

- The null's gate cost was never "transmitting null." It was (a) *level-sampling at the
  threshold* (shoot-through, ~1.9 pJ/toggle) and (b) *evaluating on a free-running clock*
  regardless of data. Both are receiver-architecture artifacts, not fundamental to ternary.
  The dead-zone (3.2.2) removes (a); no-pulse + data-gating (3.1, 3.2.3, 3.3) removes (b).
- The comm cell's 0.05 pJ null is not a transport accident — it is "null = no pulse = no
  charge = nothing burns." The gate can inherit that exact property by **not evaluating on
  null**. So the gate's null can be driven to the *same* ≈0.05 pJ class, not just the
  1.9 pJ it costs today.
- **"Exactly zero" is a model artifact, not silicon.** LEVEL=1 has no subthreshold leakage
  (repeated caveat across `circuit/`), so the idealized idle power is 0. In silicon the
  floor is process leakage of the off devices + the keeper/termination bias + the
  completion-detection overhead — none of which we have measured. So the honest claim is
  **"null → leakage floor, ≈ comm-cell null (0.05 pJ), idle → leakage floor"**, not
  "literally zero joules."

---

## 6. Calibration summary

| claim | calibration |
|---|---|
| Driver is already null-as-default (2 T, both off + Rterm) | DIRECT (`polar_gates.cir`) |
| Null is the wall in the gate: ~1.9 pJ/toggle shoot-through, 2.3–3.1× E_gate | DIRECT (`polar_gates.md`) |
| 0-vs-0 amp costs more than a latching amp (2.54× tax) | DIRECT (`gate_energy.md`) |
| Receiver floor 0.052–0.087 pJ/trit; comm null 0.05 pJ | DIRECT (`receiver_cheap.md`, `lowswing_sweep.md`, `ENERGY_RESULTS.md`) |
| "No-pulse = null" event encoding | OURS (promotes the comm protocol to compute) |
| Dead-zone ±V_th (50–100 mV) makes 0 V a full band below the trip points | OURS (V_th anchored to DIRECT resolution/offset floor) |
| Data-gating the SA clock by a passive charge detector | OURS |
| Self-timed completion makes the whole network idle on null | OURS / ANALOGY (Micropipeline); SPECULATION |
| Idle = 0 (harness) / leakage floor (silicon); null ≈ 0.05 pJ in the gate | OURS/SPECULATION — **unmeasured** |

---

## TODO / not covered / caveats

- **Nothing here is measured.** The entire scheme is a design proposal. The next step is a
  `circuit/null_default.cir`: the `tcell4` rectifier + `V_th` dead-zone + data-gated SA, to
  (a) confirm the held-null shoot-through is actually removed, (b) measure the null symbol
  at the receiver floor (does it land near the comm cell's 0.05 pJ?), and (c) measure the
  diode-drop and integrate/reset overhead the rectifier adds.
- **"Idle = 0" is unmeasurable in LEVEL=1** (no subthreshold leakage). Bounding real idle
  power needs a process model with leakage — otherwise the null-as-default win is
  overstated. The honest target is *leakage floor*, not zero.
- **The ~1.9 pJ MAX-vs-MIN delta is an inference, not a controlled A/B.** MIN and MAX are
  different gates (same 44 T, symmetric AND/OR logic, but different truth tables). A
  dedicated same-gate null-vs-+1 input sweep is needed to nail the shoot-through number.
- **The dead-zone halves the usable signal window** (push/pull must now clear ±V_th) and
  interacts with the lowswing sweep's real-offset floor (σ 5–20 mV). It buys metastability
  immunity at a noise-margin price; the exact trade at V_th ≈ 50–100 mV is untested.
- **The rectifier's diode drop is real** — the lowswing sweep measured the demux rail at
  ~0.15× the line swing at low swing. The charge integrator pays a swing tax that a direct
  level comparator would not.
- **Self-timed ternary is a large architectural change, not a drop-in.** Completion
  detection adds latency + its own energy and the handshake overhead is unmeasured. The
  practical near-term version is synchronous **clock-gating** behind the passive charge
  detector, which recovers most but not all of the null win.
- **Does not touch the 2-threshold tax itself** — two SAs still fire on every *non-null*
  symbol. Null-as-default improves the average (null-heavy) cost, not the worst-case
  non-null cost; it does not by itself reverse the polar_gates verdict on plain CMOS.
- **Storage is out of scope.** The ternary latch/FF (`ternary_ff.v`) holds null as "both
  rails discharged" — a *different* null-as-default mechanism (retention vs idle) with its
  own leakage story. The 3-level SRAM/DRAM cell is the survey's open item, not covered here.
- **The `11 = NEVER` spare state is untouched** — it is a separate don't-care that could
  encode a fourth "arm/valid" handshake signal in the event scheme; unexamined here.
