# Analog × Polar Ternary — technique map, prior art, honest fit, testable ideas

**2026-08-29 — `docs/TERNARY_GROUND_UP.md` batch 2, the "analog" angle.** ONE question:
can ANALOG computing (continuous, current-mode, differential) combine with the polar
ternary method (1 voltage magnitude × 2 directions, push/pull/null, diode rectified) —
analog's cheap continuous ops + polar's direction-based 3 states + differential noise
rejection?

**Companion files, same wave:**
- `device_circuit.md` — the *voltage-mode* native cells whose wall this file tries to route around.
- `device_physics.md` — Law 1 (two thresholds → three levels) and the SNR cost, which current-mode does **not** dodge.
- `null_default.md` — the "no-pulse = null" dead-zone scheme; this file's Idea B is its current-domain sibling.
- `circuit/ENERGY_RESULTS.md` / `circuit/ENERGY_IDEAS.md` — the measured comm cell (diode receivers, null free) and the ranked technique survey.
- `circuit/polar_gates.cir` / `circuit/receiver_cheap.cir` — the netlist conventions every sketch below reuses verbatim.

**This file is a SURVEY + DESIGN TARGET, not a measurement.** Every netlist below is a
sketch (not run); every quantitative claim is anchored to a cited repo measurement, a
textbook identity, or an explicitly tagged OURS/SPECULATION estimate. Nothing invents a
measured number.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):
- **DIRECT** — measured/proved in-repo, or a citable literature/textbook identity.
- **ANALOGY** — parallel structure, not identity (e.g. binary CML/DCVS generalized to polar).
- **OURS** — our design claim; a specific net/estimate derived here, not yet simulated.
- **SPECULATION** — untested hypothesis, flagged as such.

---

## 0. One-line answer

**Analog/current-mode makes exactly *two* of polar ternary's costs cheaper — the *sum*
(Kirchhoff's current law adds signed currents for free) and the *null* (zero current is
the natural analog resting state, a dead zone, not the 0-V saddle that killed
`polar_gates.cir`) — and it leaves the other two costs alone: the *2-threshold
quantization* (Law 1) and the *drive* (a static current source draws tail current in every
state, or a current mirror pays mismatch). Net: current-mode moves the wall from
"demux + driver" to "quantizer + tail," it does **not** remove the wall, and it does **not**
reverse the standing "ternary gate loses per bit" verdict. Its two real, citable wins are
(a) the balanced-ternary `⊕` (mod-3 sum) as a near-free KCL sum + a carry decision, and
(b) the fact that a 3-level `{−1,0,+1}` quantizer is *already* standard analog practice —
every 3-level delta-sigma DAC is a balanced-ternary machine.**

---

## 1. Technique map — the five analog families × polar ternary

| family | what it is | how it maps to polar `{+I, 0, −I}` | calibration |
|---|---|---|---|
| **Current-mode logic / CMMVL** | digit = a *current* level (unsigned `{0,I,2I,…}` or signed `{−I,0,+I}`); logic = steering/mirroring currents | the *sign* of the current is the trit sign; magnitude is ~fixed (`±I`), so push/pull/null = `+I`/`−I`/`0` current | DIRECT (the CMMVL literature, §2) |
| **Differential current-mode / SCL (source-coupled)** | two complementary rails, a tail current steered between them; common-mode rejection | push/pull *already is* a two-direction pair; the diode rectifier turns one wire into two rails that can be read differentially (§4) | DIRECT (SCL/CML) / OURS (single-wire version, §4, Idea C) |
| **Analog computation (KCL add, translinear/Gilbert multiply)** | summation on a node is free (Kirchhoff); multiplication = translinear/Gilbert cell | the mod-3 sum's *digit-sum* part `σ = a + b` is a wire junction; only the mod-3 *wrap* (carry) remains logic | DIRECT (KCL is an identity; Gilbert cell is textbook) |
| **Charge-domain computing** | digit = a *charge packet* (CCD/bucket-brigade/charge redistribution); add/subtract packets for free, no static current | polar's "no-pulse = null" is already charge-domain; charge is a conserved, *signed* quantity, and idle = no packet = no power | ANALOGY (transport cell already is this); DIRECT (charge-domain literature) |
| **Delta-sigma (ΔΣ)** | oversample + noise-shape a coarse quantizer | a **3-level quantizer `{−1,0,+1}` is literally balanced ternary**; the null is the middle tap of the quantizer | DIRECT (3-level ΔΣ DAC/ADC is standard practice) |

The two load-bearing observations for the rest of the file:

1. **KCL addition is genuinely free, and it is exactly the operation the voltage-mode
   cell found hardest.** `device_circuit.md` §5.1 showed the mod-3 sum cannot be a clean
   static 3-branch network because "mid-detection lives only in the 0 V rail, extreme-
   detection lives only in the ±Vdd rails." In current mode there is **no such split**: the
   digit sum is just `I_a + I_b` on one node. That is the single most concrete thing analog
   buys. **[DIRECT — Kirchhoff's current law is a conservation identity, not an analogy.]**

2. **Zero current is the *native* analog rest state.** Voltage-mode's null is a *level* —
   `0 V` — and a comparator biased at 0 V sits at a saddle (`polar_gates.cir`'s metastable
   null, measured `~1.9 pJ/toggle` shoot-through). Current-mode's null is an *absence* —
   `0 A` — which sits a full `I_th` *below* any trip point. The dead-zone that
   `null_default.md` §3.2 had to *add* as a fix is **built in** to the current
   representation. **[OURS — this is the claim; the mechanism is the same argument as
   `null_default.md`, relocated to the current domain; not yet measured.]**

---

## 2. Prior art — the current-mode MVL body (citable, and what it actually is)

There **is** a known body on current-mode multi-valued logic; it is one of the older and
better-established MVL families. The honest characterisation of it:

**The canonical references (DIRECT):**

- **K. W. Current, "Current-mode CMOS multiple-valued logic circuits," IEEE J.
  Solid-State Circuits, vol. 29, no. 2, pp. 95–107, 1994.** The standard survey. Its core
  circuit: a current mirror produces `r` weighted currents; a threshold detector selects a
  level; the output is a current. The paper is explicit that current-mode buys *high speed
  and easy summation* at the cost of *static power and noise margin*. **[DIRECT.]**
- **M. Kameyama, T. Hanyu, T. Higuchi, "Design and implementation of quaternary NMOS
  integrated circuits for pipelined image processing," IEEE J. Solid-State Circuits,
  vol. SC-22, no. 1, pp. 20–27, 1987.** The Tohoku-group origin: quaternary current-mode
  NMOS for pipelined arithmetic. **[DIRECT.]**
- **T. Hanyu, M. Kameyama, "A 200 MHz pipelined multiplier using 1.5 V-supply
  multiple-valued MOS current-mode circuits with dual-rail source-coupled logic," IEEE
  J. Solid-State Circuits, vol. 30, no. 11, pp. 1239–1245, 1995.** Dual-rail current-mode
  (source-coupled) — the differential version. **[DIRECT.]**
- **S. Kawahito, M. Kameyama, T. Higuchi, "Multiple-valued radix-2 signed-digit
  arithmetic circuits for high-performance VLSI systems," IEEE J. Solid-State Circuits,
  vol. 25, no. 1, 1990.** **Signed-digit** current-mode arithmetic — the closest literature
  cousin to Ian's polar idea, because it carries *signed* values in current, not unsigned
  levels. **[DIRECT.]**
- **Current-mode *ternary* specifically** exists as a smaller, newer subset: e.g. CNTFET
  current-mode ternary full adders — "New Current-Mode Ternary Full Adder Circuits Based
  on Carbon Nanotube Field Effect Transistor Technology" (J. Comput. Theor. Nanosci.,
  2016) and "Two state-of-the-arts current-mode ternary full adders based on CNTFET
  technology" (IJRES, Moradi et al.). **[DIRECT citations; ANALOGY for our purposes — they
  are level-coded `{0,1,2}`, not balanced/polar, per the re-assertion rule in
  `docs/synthesis/ternary-circuits.md` §1.]**
- **Dual-rail current-mode *differential* logic** (asynchronous MVL): "Asynchronous
  multiple-valued VLSI system based on dual-rail current-mode differential logic"
  (Kameyama group, KAKENHI 12480064 report). **[DIRECT.]**
- In-tree: **2211.12176** (Unutulmaz & Ünsalan) is already in the corpus as "differential
  threshold logic gate" — its core is a *clocked current-imbalance comparator* whose output
  is a binary `sgn(Σwᵢxᵢ + ε) + 1` decision; i.e. **current-mode threshold logic**, the
  same family. **[DIRECT — `docs/graphs/ternary-circuits/2211.12176…md`, `device_circuit.md` §5.2.]**

**Three honest caveats about this body (why "there is prior art" is only half the story):**

1. **Most of it is radix-4, not radix-3.** Quaternary current-mode maps `{0,1,2,3}` onto
   2-bit binary and onto a clean 4-level current ladder, so it became the workhorse.
   Ternary current-mode is a minority. The classic CMMVL ladder is **unsigned** `{0,I,2I,…}`.
   **[DIRECT — this is visible in Current 1994 and the Tohoku papers' choice of radix-4.]**
2. **The *signed/balanced* current representation (closest to polar) lives in the
   signed-digit arithmetic line (Kawahito 1990), not the mainstream CMMVL.** So "current-mode
   ternary" mostly means "three unsigned current levels," not "sign × magnitude in current."
   Ian's polar encoding is the *balanced* version, which the literature touches only via
   signed-digit arithmetic. **[ANALOGY — the mechanism carries over; the convention must be
   re-asserted.]**
3. **The literature's own verdict is the one `ENERGY_IDEAS.md` §1.6 already reached for
   the comm cell:** current-mode is a *speed and low-swing* idiom, not an *energy* idiom —
   static CML/CMMVL draws bias current in every state, including idle. Current 1994 says so
   in its own paper. So the prior art does **not** hand us a null-free current-mode gate;
   it hands us a fast, noise-margin-limited one. **[DIRECT — the survey's own text.]**

---

## 3. The honest fit — does current-mode make the 3 polar states cheaper?

Decompose the polar gate's measured cost into its parts, and ask which parts current-mode
removes.

### 3.1 What current-mode genuinely makes cheaper (two items, both real)

**Item 1 — the sum.** `σ = a + b` is a wire junction. The voltage-mode mod-3 sum was the
*expensive* cell (100 T measured baseline, `~45` CNFET TLG native, `device_circuit.md` §5)
because the digit sum had to be rebuilt from per-level detections. In current mode the sum
itself is **free**; only the *wrap* remains (see §3.2). **[DIRECT for KCL; OURS for "this
removes the sum-construction cost."]**

**Item 2 — the null.** `0 A` is a dead zone, not a saddle. The measured `~1.9 pJ/toggle`
held-null shoot-through (`null_default.md` §2, `polar_gates.md`) is a *voltage-threshold*
artifact: a comparator must sit at 0 V. A current comparator sits at `0 A` with trip points
at `±I_th`; a null input delivers no current, so nothing is ever compared against anything.
This is `null_default.md`'s dead-zone as a *native property of the representation* rather
than an added fix. **[OURS — the strongest single claim in Ian's favor; untested.]**

### 3.2 What current-mode does *not* make cheaper (two items, both fatal to a win)

**Item 3 — the 2-threshold (Law 1) tax is *relocated*, not removed.** This is the sharpest
honest point, and it is easy to state precisely for the `⊕` gate. Let `a, b ∈ {−1,0,+1}` and
`σ = a + b ∈ {−2,−1,0,+1,+2}`. The mod-3 sum (carry dropped) is:

```
σ = +2  →  s = −1          (wrap down: +1 ⊕ +1 = −1)
σ = −2  →  s = +1          (wrap up:  −1 ⊕ −1 = +1)
σ ∈ {−1,0,+1}  →  s = σ    (no wrap)
```

KCL gives you `σ` for free, **but `σ = ±2` must still be *measured* to know whether to
wrap** — and distinguishing `σ = +2` from `σ = +1` (or `−2` from `−1`) is a threshold
decision. Two of them (one per sign). So current-mode makes the *summation* free and
leaves the *measurement* exactly as expensive as `device_physics.md` Law 1 says it is:
`log₂3 = 1.585` bits of decision through two boundaries. The wrap is the balanced carry,
and the carry is where the information lives. **[DIRECT — the wrap map is arithmetic (the
table above is computed, not asserted); "the wrap decision is a 2-threshold measurement" is
OURS as a *cost* claim but follows from Law 1 in `device_physics.md` §2.3.]**

Concretely: the current-mode `⊕` is **free KCL sum + a carry detector (2 current
thresholds at `±3I₀/2`) + a current-steering correction (subtract `3I₀` when the carry
fires)**. That is cheaper than the 100 T voltage gate, but the carry detector is the same
two-boundary measurement — current-mode did not reduce "two boundaries" to "one," any more
than multi-Vt did (`device_circuit.md` §0).

**Item 4 — the drive: static current-mode violates "null = no power."** A *static*
current-mode gate holds a current level with a bias current that flows in **every** state,
including null. That is the exact opposite of Ian's null-as-default rule
(`null_default.md` §1), and it is the CMMVL literature's own admitted cost (Current 1994).
There are two escapes, and each has a price:
- **charge-packet (dynamic) current mode** — like the comm cell's own charge-transfer
  driver (`ENERGY_IDEAS.md` §1.1) — only moves charge on activity, so null is free; but
  then the "gate" must be *self-timed/clocked* like MOBILE, and it inherits the
  completion-detection tax `null_default.md` §3.3 already flagged.
- **current mirrors for multiplication** — the mod-3 *product* `⊗` and any scaling needs
  ratioed mirrors, which are **mismatch-limited** (a fraction of a level), i.e. the same
  ~2×-worse-than-binary offset story as 3 voltage levels (`device_circuit.md` §7,
  `meta_critique.md` §3g).

**[DIRECT — static current-mode draws idle bias (the survey's own statement); OURS — the
two escapes and their prices, following `null_default.md` and `ENERGY_IDEAS.md` §1.6.]**

### 3.3 The net

| cost in the measured polar gate | current-mode? |
|---|---|
| demux + driver overhead (clock, 2 sense amps, re-encode) | unchanged — a current quantizer still needs 2 thresholds + an output driver |
| metastable null (≈1.9 pJ/toggle) | **removed natively** (0 A dead zone) — Item 2 |
| digit-sum construction (`⊕` hardest cell) | **removed** (KCL free) — Item 1 |
| 2-threshold information cost (Law 1) | **kept** (the wrap/carry) — Item 3 |
| static current / mirror mismatch | **added** unless charge-packet — Item 4 |

**Verdict:** current-mode trades two costs (sum, null) for two costs (tail current,
mismatch) and keeps the one that matters (the 2-threshold measurement). It is a **better
polar gate, not a winning one.** The honest bottom line matches `device_circuit.md` §7.3:
the only way ternary *compute* wins is to resolve 3 states in fewer than 2 measurements or
make the null free *inside the gate* — current-mode delivers the second (null free) but
explicitly not the first. **[OURS — synthesis; each leg is DIRECT/OURS as tagged above.]**

---

## 4. The noise tradeoff — does push/pull reject enough common-mode noise?

Ian's hope: "differential noise rejection." Three separate questions hide in that phrase;
answer each honestly.

### 4.1 A single signed current is *single-ended*, not differential

Push/pull on **one** wire is `±I` referenced to 0 — a *signed single-ended* signal. There
is no second wire to subtract against, so there is **no common-mode rejection by itself**.
A common-mode disturbance (supply ripple, substrate bounce, a temperature gradient) pushes
the wire *and* the reference together, and a single-ended comparator passes the sum
through. **[DIRECT — definitional: CMRR needs a differential *pair*.]**

### 4.2 The polar cell already half-*has* a differential read — the diode pair

This is the useful, non-obvious point. The comm cell's **2-diode receiver**
(`circuit/ENERGY_RESULTS.md`, `tcell4`) already turns one wire into **two rails**: a push
pulse charges `C_push` (via `D1`), a pull pulse charges `C_pull` (via `D2`), a null charges
neither. So the two rails give:

```
push →  V(C_push)=+V,  V(C_pull)=0   ⇒   V(C_push) − V(C_pull) = +V
pull →  V(C_push)=0,   V(C_pull)=+V  ⇒   difference = −V   (re-referenced)
null →  both 0                       ⇒   difference =  0
```

Reading the **difference** `V(C_push) − V(C_pull)` yields a clean signed 3-level signal
with genuine common-mode rejection — *on one wire*. A common-mode glitch on the wire
charges both caps equally and subtracts out, limited only by how well `D1` and `D2` track
each other (diode matching → CMRR). **[OURS — this specific "one wire, two half-wave
rails, read the difference" construction; the *parts* are DIRECT (the diode pair is the
comm cell's own receiver; differential subtraction is the standard LVDS/SLVS mechanism
already cited in `ENERGY_IDEAS.md` §1.2).]**

**The honest caveats** (carried from `polar_gates.cir`'s own diagnosis): the diode pair is
not a *perfect* differential splitter. The push rail sits at 0 V for **both** pull and null
(`polar_gates.cir` header), and the diodes are half-wave, so the rejection only acts on
common-mode noise during the conducting half of each symbol; the null-state rejection is
mismatch-limited and the two rails do not mirror each other exactly. So this is *partial*
CMRR, not the full differential-pair CMRR of a true SCL receiver. **[DIRECT — the rail
asymmetry is stated in `polar_gates.cir`; OURS — that the difference-read recovers some
CMRR despite it.]**

### 4.3 Current-mode is noise-*worse* per level, and the levels are closer

The generic fact: for a fixed energy budget, current-mode has a *lower* signal-to-noise
ratio per level than voltage-mode. Two mechanisms (both textbook):
- current noise at the sense node is channel thermal noise `4kTγg_m Δf` (and shot noise
  `2qI Δf` if shot-limited); the signal is `I`, so SNR scales `∝ I/√Δf` and you pay `I²R`
  for `I`.
- three levels sit `V_swing/2` apart instead of `V_swing` (`device_physics.md` §5.3), so at
  fixed BER you raise swing or capacitance — the multi-level SNR tax.

Differential push/pull rejects the **common-mode** component of noise (which is often the
dominant component — supply/substrate coupling), but it does **not** reject the
**differential** component (device thermal/mismatch noise), and the *levels themselves*
are still 2× closer than binary's. So "differential" and "ternary" pull in opposite
directions: differential removes common-mode noise, ternary halves the per-level margin.
**[DIRECT — the noise identities and the SNR/half-swing argument are standard; the
"opposite directions" synthesis is OURS.]**

### 4.4 Where the combination actually works: delta-sigma (a DIRECT prior art, not ours)

The one place analog *does* make a 3-level `{−1,0,+1}` representation work against noise is
**delta-sigma modulation**: oversample, noise-shape the quantizer error out of band, and a
3-level (ternary) quantizer/DAC is *standard*. Every 3-level ΔΣ DAC is a machine whose
quantizer output is exactly balanced ternary — and it survives precisely because the
coarse 3-level noise is shaped, not because the levels are quiet. **[DIRECT — 3-level ΔΣ
quantizers are standard practice; the "= balanced ternary" identification is a
re-labeling, not a mechanism claim.]**

**The honest noise verdict, in one line:** differential push/pull rejects common-mode noise
**only through a differential read** — either a second wire (defeats the transport win) or
the diode-pair difference-read of §4.2 (partial CMRR, one wire, mismatch-limited) — and it
does nothing about the *differential* noise or the 2×-closer levels. Current-mode's
energy-cheapness and its noise-limitedness are the *same fact seen twice* (you spend `I²R`
to get `I`), so analog-ternary does not become "viable" on noise grounds; it becomes
viable *only* where the noise can be shaped away (ΔΣ) or where the null dominance makes
the average activity tiny (the transport cell's already-measured win).

---

## 5. Testable ideas (3), with ngspice sketches

All three are expressible in the existing **LEVEL=1** harness (current sources, current
mirrors, the diode pair, the 7-T sense amp) — **no NDR/RTD model is needed**, which is why
these are *immediately* testable unlike the multi-Vt cells of `device_circuit.md`. Each
sketch reuses the repo's models verbatim. **None of these has been run**; each is a design
target with an explicit pass/fail measurement.

Shared models (verbatim from `circuit/`):

```spice
.model NMOS1  NMOS(LEVEL=1 VTO=0.4  KP=200u LAMBDA=0.05 TOX=2n)
.model PMOS1  PMOS(LEVEL=1 VTO=-0.4 KP=100u LAMBDA=0.05 TOX=2n)
.model DIDEAL D (IS=1e-14 RS=50 CJO=0.2p TT=2n N=1.0)
```

---

### Idea A — signed-current mod-3 sum: "KCL makes the sum free; does the wrap still cost Law 1?"

**The test.** The `⊕` gate's voltage-mode hardness (`device_circuit.md` §5.1, the mid⊗extreme
cross-rail obstruction) should vanish in current mode: the digit sum is a wire junction. The
question is whether the *wrap* (`σ = ±2 → ∓1`) is still a 2-threshold measurement. Build the
sum node + a 2-threshold current carry detector + a current-steering correction, and measure
(a) the truth table, (b) the wrap-detector energy vs the 100 T baseline, (c) the null-null
idle current (does it stay ~0, or does the detector bias leak?).

**The circuit (skeleton; mirror/quantizer net deferred like `device_circuit.md` §5.2 deferred the TLG):**

```spice
* analog_polar_sum.cir -- SKETCH (not run)
* Mod-3 sum:  sigma = Ia + Ib (KCL, FREE);  s = sigma mod 3.
* Wrap (balanced carry):  +2 -> -1,  -2 -> +1  (|sigma| > 3*I0/2).
.param I0   = 10u
.param ITHR = 15u        ; carry threshold = 3*I0/2

* -- the free part: one wire junction. I(sum) = I_a + I_b by KCL. --
Ia sum 0 DC 0
Ib sum 0 DC 0
* In a full cell Ia/Ib are push/pull current sources: +I0 (push), 0 (null), -I0 (pull).

* -- wrap detect: two current comparators, trip at +ITHR and -ITHR --
* (net deferred: a diode-connected sense transistor + reference current, feeding the
*  repo 7-T latch; same "exact net in 2211.12176, not re-derived here" honesty as
*  device_circuit.md §5.2.)
* +carry fires iff I(sum) > +ITHR ;  -carry fires iff I(sum) < -ITHR.

* -- wrap correction: steer -3*I0 back through the sum when +carry fires, +3*I0 when
*    -carry fires -> out current is sigma mod 3 (a 3:1 current mirror). --

* measurements that would settle it:
.tran 1n 200n
.meas tran e_carry  INTEG (V(vdd)*I(VDD) + V(vss)*I(VSS)) FROM=10n TO=190n  ; wrap-detector energy
.meas tran i_idle   AVG I(VDD) FROM=10n TO=50n                                ; null-null idle current
* truth table: sweep Ia,Ib over {-I0,0,+I0} and read the output current sign/magnitude
```

**Pass/fail.** *Refutes Law 1* if the wrap can be decided with **one** measurement (it
cannot, by construction — this sketch's value is to make that failure *measured* and put a
number on the still-needed 2-threshold energy). *Wins* if `e_carry` ≪ the 100 T baseline's
`E_gate` AND `i_idle ≈ 0` (leakage floor). **[OURS — the net; the "free sum, priced wrap"
prediction is the §3.2 argument made into a measurement.]**

---

### Idea B — null-as-zero-current receiver: is the 1.9 pJ/toggle null shoot-through *native*-dead in current domain?

**The test.** `null_default.md` §2 measured the voltage-mode null as the *most* expensive
gate state (`~1.9 pJ/toggle` shoot-through) because a 0-V-sitting comparator is a saddle.
Current-mode's null is `0 A`, a full `I_th` *below* every trip point. Reproduce the polar
gate's held-null, but read the rail through a **current dead-zone** (`|I| < I_th ⇒ nothing
fires`), and measure whether the shoot-through term disappears.

**The circuit (skeleton):**

```spice
* analog_polar_null.cir -- SKETCH (not run)
* Polar wire -> charge integrator (the comm cell's tcell4, verbatim) -> current dead-zone.
.param ITH = 5u
* charge integrator: push/pull pulses steer charge onto Cpush/Cpull through D1/D2.
*   null pulse delivers ZERO charge -> both rails at 0 -> no current to compare.

* current dead-zone read: the repo 7-T sensamp is CLOCK-GATED by "did charge arrive?".
* A passive current sense (mirror) produces a trigger only when |I_rail| > ITH;
* otherwise the sensamp clock never rises (the null_default.md §3.2.3 data-gate).

* measurements that would settle it:
.meas tran e_null  INTEG V(pwr) FROM=100n TO=150n   ; held-null window energy (expect ~leakage)
.meas tran e_push  INTEG V(pwr) FROM=10n  TO=60n    ; push window energy (reference)
* ratio e_null / e_push should drop from the measured ~0.5x (voltage null vs push) toward ~0.
```

**Pass/fail.** *Wins* if `e_null/e_push → 0` (null genuinely below the active floor, unlike
the voltage gate where a held null ≈ a held ±1). *Caveat to watch*: the charge integrator's
diode drop and the dead-zone's `±I_th` still tax the non-null symbols — the same swing tax
`null_default.md`'s TODO already flags. **[OURS — the net; the null-vs-push energy ratio is
the measurement, not an asserted number.]**

---

### Idea C — single-wire differential read: how much common-mode rejection does the diode pair *already* give?

**The test.** The §4.2 claim: reading `V(C_push) − V(C_pull)` (the two half-wave rails of the
comm cell's own diode receiver) gives a signed 3-level signal with partial common-mode
rejection *on one wire*. Inject a common-mode disturbance and measure the input-referred
error of (a) the current single-ended read (each rail vs 0) and (b) the difference read —
the CMRR is the ratio.

**The circuit (skeleton, verbatim cell):**

```spice
* analog_polar_cmrr.cir -- SKETCH (not run)
* Comm cell (verbatim tcell4) + an injected common-mode source on the wire.
.param VCM = 50m            ; common-mode disturbance amplitude
* tcell4: Rw wire -> x, Cx x->0, D1 x->rA, D2 rB->x, RLA/RLB 1Meg, CLA/CLB 0.2p.

* (a) single-ended: the repo sensamp reads rA vs 0 (push) and rB vs 0 (pull).
* (b) differential: a simple PMOS diff pair (or the repo sensamp re-referenced) reads
*     (rA - rB) directly -- one signal, three levels {+V,0,-V}.

* common-mode injection: a voltage/current source coupling onto the wire (node x),
*   e.g. VCM coupled through a small cap, or a common current into both rails.

* measurements that would settle it:
.meas tran err_se  FIND V(rA) AT=...     ; single-ended rail shift under VCM (should ~= VCM)
.meas tran err_dif FIND V(rA)-V(rB) AT=... ; differential read shift under VCM (should ~= 0)
* CMRR = err_se / err_dif  (the figure of merit; not a number until measured)
```

**Pass/fail.** *Wins* if `err_dif ≪ err_se` (the difference read suppresses the common-mode
disturbance by the diode-pair's tracking ratio) *and* the energy of the differential read
is comparable to the two single-ended sense amps it replaces. *Refutes* if diode mismatch
makes the two rails track poorly (CMRR ≈ 1) — which would close the case that "differential
rejection needs a real second wire." **[OURS — the net; CMRR is the measured output, not
pre-asserted.]**

---

## 6. Calibration ledger

| claim | calibration |
|---|---|
| KCL: signed currents sum for free on one node | **DIRECT** — Kirchhoff's current law |
| `⊕` = free sum + wrap; wrap map `+2→−1, −2→+1` | **DIRECT** — arithmetic (table computed in §3.2) |
| the wrap/carry is a 2-threshold measurement (Law 1 persists) | **OURS** — follows from `device_physics.md` §2.3 |
| null = 0 A is a native dead zone, not a 0-V saddle | **OURS** — mechanism; unmeasured |
| measured null shoot-through ≈1.9 pJ/toggle; polar `⊕` = 100 T | **DIRECT** — `polar_gates.md` / `null_default.md` |
| CMMVL body exists (Current 1994, Tohoku group, signed-digit) | **DIRECT** — §2 citations |
| CMMVL is mostly radix-4, unsigned levels; ternary is a minority | **DIRECT** — visible in the cited surveys |
| static current-mode draws idle bias (violates null-as-default) | **DIRECT** — Current 1994's own cost statement |
| charge-packet/dynamic mode recovers null-free at self-timing cost | **OURS/ANALOGY** — `null_default.md` §3.3, `ENERGY_IDEAS.md` §1.6 |
| single signed current is single-ended (no free CMRR) | **DIRECT** — definitional |
| diode-pair difference-read gives partial 1-wire CMRR | **OURS** — parts DIRECT (the diode pair, differential subtraction) |
| current noise `4kTγg_mΔf` / shot `2qIΔf`; 3-level SNR tax `V/2` gap | **DIRECT** — textbook identities; `device_physics.md` §5.3 |
| 3-level ΔΣ quantizer = balanced ternary (standard practice) | **DIRECT** — re-labeling of a standard block |
| three netlist sketches | **OURS** — design targets, **not run** |

---

## Sources

**Current-mode MVL (DIRECT citations):**
- K. W. Current, "Current-mode CMOS multiple-valued logic circuits," IEEE J. Solid-State
  Circuits, 29(2):95–107, 1994.
  https://ieeexplore.ieee.org/document/272112
- M. Kameyama, T. Hanyu, T. Higuchi, "Design and implementation of quaternary NMOS
  integrated circuits for pipelined image processing," IEEE JSSC, SC-22(1):20–27, 1987.
- T. Hanyu, M. Kameyama, "A 200 MHz pipelined multiplier using 1.5 V-supply multiple-valued
  MOS current-mode circuits with dual-rail source-coupled logic," IEEE JSSC, 30(11):1239–1245, 1995.
  https://manuscript.isc.ac/Inventory/49/1075867.htm
- S. Kawahito, M. Kameyama, T. Higuchi, "Multiple-valued radix-2 signed-digit arithmetic
  circuits for high-performance VLSI systems," IEEE JSSC, 25(1), 1990.
  https://www.semanticscholar.org/paper/288632340ce32de2db9ca17420d2704415725fff
- "New Current-Mode Ternary Full Adder Circuits Based on Carbon Nanotube Field Effect
  Transistor Technology," J. Comput. Theor. Nanosci., 13(1), 2016.
  https://www.ingentaconnect.com/content/asp/jctn/2016/00000013/00000001/art00049
- Moradi et al., "Two state-of-the-arts current-mode ternary full adders based on CNTFET
  technology," Int. J. Reconfigurable and Embedded Systems (IJRES).
  https://ijres.iaescore.com/index.php/IJRES/article/view/19485
- "Asynchronous multiple-valued VLSI system based on dual-rail current-mode differential
  logic" (Kameyama group; KAKENHI 12480064 report).
  https://kaken.nii.ac.jp/en/report/KAKENHI-PROJECT-12480064/124800642002kenkyu_seika_hokoku_gaiyo/
- "IMPLEMENTATION OF MULTIVALUED LOGIC GATES USING FULL CURRENT-MODE CMOS CIRCUITS."
  https://www.emo.org.tr/ekler/6428eecbe0f7dff_ek.pdf

**Analog building blocks:**
- Gilbert cell (four-quadrant translinear multiplier).
  https://en.wikipedia.org/wiki/Gilbert_cell
- Charge-domain parallel processing network — US 4,464,726.
  https://patents.google.com/patent/US4464726

**In-tree (DIRECT anchors):**
- `circuit/ENERGY_RESULTS.md` — the measured comm cell, diode receivers, null-free transport.
- `circuit/ENERGY_IDEAS.md` §1.6 — the in-repo "current-mode = speed not energy" verdict.
- `circuit/polar_gates.cir` — the measured null metastability, the 100 T mod-3 sum baseline.
- `docs/compute/ground_up/device_circuit.md` §5.1 — the mod-3 sum's voltage-mode hardness.
- `docs/compute/ground_up/device_physics.md` §2.3, §5.3 — Law 1 (2 thresholds) and the SNR tax.
- `docs/compute/ground_up/null_default.md` — the dead-zone + data-gating scheme this file's
  Idea B makes current-domain.
- `docs/graphs/ternary-circuits/2211.12176v1 Implementation and Applications of a Ternary
  Threshold Logic Gate.md` — the in-corpus current-mode threshold gate.

*Every quantitative anchor in this file is a cited repo measurement, a textbook identity,
or an explicitly tagged OURS/SPECULATION estimate. No number was invented, and none of the
three netlist sketches has been run.*

---

## TODO / not covered / caveats

1. **Nothing here is simulated.** All three sketches are design targets. Unlike
   `device_circuit.md` (blocked on a missing device model), these are **immediately
   runnable** in the existing LEVEL=1 harness — current sources, mirrors, the diode pair,
   and the 7-T sense amp all model fine. The single highest-value next step is to run
   **Idea B** (null shoot-through), because it is the cheapest test of the one claim
   (null-as-zero-current is natively free) that would actually move the verdict.
2. **The current-mirror / current-comparator nets in Ideas A and C are deferred**, exactly
   as `device_circuit.md` §5.2 deferred the TLG internals: drawing a specific mirror
   topology from memory risks fabricating a net. Pull Current 1994 and `2211.12176` and
   draw their comparator/mirror cells before claiming any device count.
3. **Static vs dynamic current-mode is the fork that decides everything**, and it is not
   resolved here. Static current-mode (the CMMVL mainstream) has idle bias and therefore
   fails null-as-default *by construction*; charge-packet/dynamic mode keeps the null free
   but needs self-timing. The survey does not pick; it flags the fork (`null_default.md`
   §3.3 is the in-repo statement of the trade).
4. **Mismatch is unquantified.** Current mirrors for `⊗` (mod-3 product) and the 3:1 wrap
   correction need ratio accuracy to a fraction of a level; `meta_critique.md` §3g's
   ~2×-worse-than-binary offset story applies unchanged, and no mirror-matching number is
   cited here.
5. **The noise analysis is mechanism-level, not a measured SNR.** CMRR, input-referred
   noise, and the common-mode-rejection figure for the diode-pair read are all stated as
   mechanisms; no dB number is invented. Idea C is the measurement that would produce one.
6. **Delta-sigma is cited as prior art, not developed.** A 3-level ΔΣ quantizer is balanced
   ternary, but this file does not sketch a ΔΣ loop (it is a converter architecture, not a
   polar *gate*), and its energy/speed is not compared to the transport cell. That is a
   separate survey.
7. **Charge-domain is named but not sketched.** Charge-packet polar (push = +Q, pull = −Q,
   null = no packet) is arguably the *best* fit for null-as-free (packets only cost when
   moved), but it needs a CCD/switch-cap topology that this file does not draw; it is the
   obvious Idea D.
8. **Does not touch the transport verdict.** The comm cell's 0.081 pJ/bit win is already
   measured and already *is* a differential-ish, low-swing, null-free scheme; this file is
   about whether analog helps the *gate* (compute), and its honest answer is "a better
   polar gate, not a winning one." The transport side needs no analog rescue.
9. **No synthesis/mapping path** for a current-mode gate — the same wall CNTFET hit at
   ~15K transistors (`meta_critique.md` §3f) applies to any non-CMOS current-mode family.
   A per-gate win without a liberty/yosys story is unactionable.
