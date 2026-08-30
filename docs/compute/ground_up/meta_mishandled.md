# Meta-Audit — Everywhere Ternary Was Mis-Handled As Binary

**2026-08-29 — the "binary default" hunt across the whole ternary-compute corpus.**
ONE question: where did a **binary default** leak into the ternary model — the wrong
representation, the wrong receiver, the wrong transmission, the wrong substrate, or the
wrong metric — and what does each mis-modeling *re-measured* change?

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`), applied to **both** the
mis-modeled spot *and* its correction:

- **DIRECT** — measured/proved in-repo, or a citable literature/textbook identity.
- **ANALOGY** — parallel structure, not identity.
- **OURS** — this audit's own synthesis/design claim (follows from DIRECT, not independently established).
- **SPECULATION** — untested hypothesis, flagged.

---

## 0. The meta-finding in one paragraph

The corpus already contains **both models**, side by side, and it wrote its final verdict
from the wrong one.

- **The CORRECT model** is stated in the origin doc (`TERNARY_PROCESSOR.md` §1.2) and
  realized in the *transport* netlists: polar ternary is **SIGN + MAGNITUDE — one voltage
  magnitude × two current directions** (`push` = current OUT, `pull` = current IN,
  `null` = no current), read by **two antiparallel diodes** (a *direction* detector, not a
  level comparator), and the null is an *absence*, the default rest state, costing ~0.
  `circuit/ternary_cell.cir`, `circuit/ternary_transistor.cir`, `circuit/diode_gates.cir`,
  `circuit/README.md`, `docs/compute/ground_up/analog_polar.md` §0 all say this.
  **[DIRECT]**

- The **WRONG model** is what the *compute* netlists and every verdict doc actually used:
  polar ternary as **"three ordered voltage levels {−V, 0, +V} on one wire"**, read by
  **two clocked sense amps comparing the wire against 0 V** (a *level* receiver), built from
  **multi-Vt 2-level MOSFETs**. `circuit/polar_gates.cir`, `circuit/gate_energy.cir`,
  `circuit/receiver_cheap.cir`, `docs/compute/gate_energy.md`, `docs/compute/polar_gates.md`,
  `docs/compute/gates.md`, `docs/ENERGY_LAWS.md`, `docs/TERNARY_COMPUTE_VERDICT.md`.
  **[DIRECT — the netlists/docs are unambiguous]**

The headline verdict — *"ternary transport wins 9.2×, ternary compute loses 4.9–14.3× per
bit, build the hybrid"* — is therefore **a comparison of two different objects**: the wire
win was measured on the **diode-direction** cell (null free), while the gate loss was
measured on the **sense-amp level** cell (null meta-stable, 2-threshold tax). The two
verdicts were never run through the same receiver. **The single highest-value correction:
re-measure the *gate* with the diode-direction receiver that the *wire* already uses —
`circuit/diode_gates.cir` is that netlist, it was run (`diode_gates.log` exists), and its
result was never folded into any verdict doc.** **[OURS — synthesis; the two netlists and
the un-integrated log are DIRECT]**

---

## 1. The two models, side by side (the reference table)

| axis | **correct (polar) model** | **binary-default leak** | correct model lives in |
|---|---|---|---|
| representation | 1 voltage **magnitude** × 2 **directions** (sign + magnitude) | "3 ordered voltage levels {−V,0,+V}" | `TERNARY_PROCESSOR.md` §1.2; `diode_gates.cir` header; `analog_polar.md` §0 |
| receiver | **diode direction** (which of two antiparallel legs conducts); null = neither | **sense amp vs 0 V** (level compare; 2 thresholds); null sits ON the threshold | `ternary_cell.cir`; `ternary_transistor.cir`; `diode_gates.cir`; `PHYSICAL_NOTES.md` |
| transmission | push/pull is a **signed single-ended** signal; differential only via the **two diode rails read as a difference** | "one wire" sold as *the* win with **no** common-mode rejection | `differential_noise.md`; `analog_polar.md` §4 |
| substrate | a device with **3 free-energy minima** (2 NDRs / Coulomb ladder / 3 current states) | **multi-Vt CMOS** (2-level MOSFET with tuned thresholds = "the ternary device") | `device_physics.md` §0–§4; `device_literature.md` §2.5/§2.8 |
| null | **absence of drive** = default/off, data-bearing, ~free | "the middle level at 0 V" — the center of a 3-level scale | `null_default.md` §1, §3.1; `README.md` |
| metric | **per-wire** (transport) vs **per-state** (namespace) vs **per-gate** (compute) — three separate numbers | everything collapsed to "per bit" (÷1.585), conflating the three | `word_fairfight.md` (the per-state/per-bit split, the one place it's kept straight) |

**[The "correct model" column is DIRECT (it is the project's own recorded encoding +
netlists); the "leak" column is DIRECT (each leak is verbatim in the cited file).]**

---

## 2. Dimension 1 — REPRESENTATION: "3 ordered voltage levels" instead of sign + magnitude

This is the *root* leak — every other mis-modeling descends from it. Once a trit is
described as "3 ordered levels", the receiver *must* be 2 level thresholds, the noise
model *must* be V_swing/4 spacing, and multi-Vt CMOS *must* look like the natural device.
All three downstream errors are forced by this one framing choice.

### 2.1 Where it's wrong

- `circuit/polar_gates.cir` (header + §RAILS): *"ONE wire carrying THREE levels — push = +V,
  null = 0, pull = −V … 3-level signal"*. **DIRECT** (netlist text).
- `docs/compute/gate_energy.md` §Method: *"Ternary: 2 sense amps (push vs 0, pull vs 0) =
  the 2 thresholds"* — the 3-level reading made literal. **DIRECT**.
- `docs/compute/ground_up/device_circuit.md` §0: *"push/null/pull on one wire is a
  one-dimensional ordered code (−V < 0 < +V). Any 3 ordered levels need two decision
  boundaries."* **DIRECT**.
- `docs/compute/ground_up/device_physics.md` §2.3: *"the swing is partitioned into 3 levels
  instead of 2, so the gap between adjacent levels is V_swing/2."* **DIRECT**.
- `docs/compute/gates.md` §1: *"A level-coded ternary gate resolves 3 voltage levels →
  2 thresholds (two comparators)."* **DIRECT**.
- `docs/compute/ground_up/differential_noise.md` §3.1: *"a single wire carrying three levels
  {+V, 0, −V}."* **DIRECT** (this doc is otherwise the *most* self-aware, yet it still takes
  "3 levels" as the base description).
- `docs/compute/storage.md` (whole "(A) analog 3-level cell" column), `optimization_ngram.md`
  §1.1, `test_suite_spec.md` §4.6 — all inherit the "3 levels" base.

### 2.2 The correct model

**Polar ternary is 1 voltage magnitude × 2 directions.** A trit is the *sign of the driven
current* (or the *polarity of the excursion*), not a position on an ordered voltage scale.
The three symbols are `+I`, `−I`, `0` — a **signed single-ended** value with a zero, not
three ranked levels. **[DIRECT — `TERNARY_PROCESSOR.md` §1.2 "polarity of the AC-like
behavior… receiver reads the direction, not the absolute level"; `diode_gates.cir` header
"1 voltage MAGNITUDE x 2 DIRECTIONS, not '3 ordered levels needing 2 thresholds'";
`analog_polar.md` §0 "1 voltage magnitude × 2 directions, push/pull/null, diode rectified"]**

The key structural consequence: with sign+magnitude, **push and pull are not two voltages
on one scale — they live on two different rails** (opposite diode legs), so they are
maximally separated, and the null is not a "middle level" but the *absence of either
direction*. `differential_noise.md` §3.3 already concedes this: *"the two outer symbols are
separated by the full 2·V of the swing in the direction axis… a rail-selection decision,
not a 3-level voltage comparison."* **[DIRECT]**

### 2.3 What re-measuring it changes

The "3 ordered levels" description *invents* the 2-threshold receiver and the V_swing/4
margin. Re-describing the same cell as sign+magnitude removes both:

1. The **"2-threshold tax" is a description artifact, not a physics fact.** Two ranked
   levels need 2 boundaries; a sign + a magnitude need *one* direction decision (which rail)
   + *one* presence decision (did charge arrive). The direction decision is ~free (diode
   rectification); only the presence decision remains. **[OURS — follows from the netlists]**
2. The **"halved noise margin" is the wrong noise model.** V_swing/4 spacing applies to 3
   ordered levels; for sign+magnitude the binding margin is null-vs-signal (the diode-drop
   dead band ≈ 0.3 V ≈ *comparable to or better than* the naive V_swing/4 = 0.25 V), not
   push-vs-pull (which are on separate rails and cannot be confused).
   **[DIRECT for the numbers — `differential_noise.md` §3.2 measured diode VTO=0.30 vs 0.25 V; OURS for the reframe]**

**Re-test:** re-write the *description* of the same `ternary_cell.cir` as sign+magnitude
and re-derive the noise/receiver budget (§9.1). No new netlist needed — it's a
re-interpretation of an existing measured cell.

---

## 3. Dimension 2 — RECEIVER: sense-amp level detection instead of diode direction

### 3.1 Where it's wrong

- `circuit/polar_gates.cir` `sensamp` subckt + header: *"two PMOS-input sense amplifiers
  comparing the wire against 0 V: one detects 'wire > 0' (push), the other 'wire < 0'
  (pull); null = neither fired."* **DIRECT** — this is the level receiver, and it is the
  *only* receiver the gate netlist uses.
- `circuit/gate_energy.cir` / `docs/compute/gate_energy.md`: the measured **"2.54× receiver
  tax"** (1 sense amp 24.35 fJ → 2 sense amps 61.87 fJ) is 100% a sense-amp number. **DIRECT**.
- `circuit/receiver_cheap.cir` / `docs/compute/receiver_cheap.md`: the **"receiver floor
  0.0865 pJ/trit"** and all 8 variants (wider pair, low-Vt, parallel amps) are sense-amp
  variants — the diode-direction receiver is never in the sweep. **DIRECT**.
- `docs/ENERGY_LAWS.md` Law 1: *"the receiver is gauge-agnostic… 2 thresholds vs 1"* — Law 1
  **is** the level-receiver assumption promoted to a law (see §7.1). **DIRECT**.
- `docs/compute/converters.md` §1a: *"Polarity/one-hot demux (ours): the 2-diode receiver…
  Two threshold comparisons against 0 / diode turn-on"* — folds the diode *into* the
  "2 threshold" framing, hiding that a diode leg is not a threshold comparison at all. **OURS — the mis-description; the diode demux is DIRECT**.
- `docs/compute/ground_up/null_default.md` §3.2: its fix keeps the *level* readout (caps read
  against thresholds ±V_th) — it converts direction→charge→level instead of reading direction
  directly. The direction is thrown away and re-derived by amplitude. **[OURS]**

### 3.2 The correct model

**DIODE DIRECTION detection.** Two antiparallel diode legs split the one wire into
`rA` = "push rail" (charges on positive excursion) and `rB` = "pull rail" (charges on
negative excursion); null = neither leg conducts (no current → no charge → nothing fires).
There is **no 0-V comparator, no clock, no receiver supply, and no threshold the null can
sit on** — the null sits a full diode-drop *below* both trip points (a dead zone, not a
saddle). **[DIRECT — `ternary_cell.cir` (D1 x→rA, D2 rB→x), `ternary_transistor.cir`
(diode-connected MOSFET rectifiers), `diode_gates.cir` (`dd_recv`), `PHYSICAL_NOTES.md`
(parallel-MOSFET rectifier rule)]**

### 3.3 What re-measuring it changes

`circuit/diode_gates.cir` *was run* (`diode_gates.log` exists) and was never integrated:

- **The null metastability disappears.** `diode_gates.log` quiet-window (held-null idle)
  energies `eq_4…eq_8` = 1.5–3.8×10⁻¹⁹ J ≈ **0 aJ** — versus `polar_gates.cir`'s measured
  **~1.9 pJ/toggle** null shoot-through. The direction receiver's null is free *in the gate*,
  exactly the property the sense-amp gate could not deliver. **[DIRECT — both logs]**
- **The "2.54× receiver tax" vanishes as a line item.** A diode receiver has no supply and no
  clock; its cost is the driver-side diode drop (already inside E_gate), not a separate E_rec.
  The whole "receiver is 2/3 of the 0.081 pJ/bit floor" thesis (`ENERGY_LAWS.md`) is a
  property of the **sense-amp** receiver, not of "the receiver" in general. **[OURS — from the two netlists]**
- **The per-toggle loss shrinks but does not flip.** Measured (same ±1 V rails, same 130 nm
  LEVEL=1 discipline): `dd_not` ≈ **1.03 pJ/toggle** vs `polar NOT` **1.47 pJ** (≈1.42×
  cheaper) and vs binary NOT **52.7 fJ** (still ≈20× worse per toggle) — the residual loss is
  now the **elevated-Vt dead-zone driver + diode drop**, not the receiver. **[DIRECT — `diode_gates.log`, `polar_gates.log`]**

So the honest re-measurement result is **not** "diode receiver makes ternary gates win per
toggle." It is: *"the 4.9–14.3×/bit compute loss was measured on the wrong receiver; the
right receiver eliminates the null cost and the receiver tax, leaving a ~20×/toggle
driver/device loss — and the correct metric (per-active-symbol, §6) is still open."*
**[OURS/SPECULATION — the per-active-symbol metric is unmeasured]**

**Re-tests (§9.2):** (a) promote `diode_gates.log` into a doc and fold its numbers into the
verdict; (b) A/B the *same* gate logic behind a sense-amp receiver vs a diode-direction
receiver on identical rails/loads; (c) inject a common-mode offset and compare error.

---

## 4. Dimension 3 — TRANSMISSION: single-ended sold as the win, differential discarded

### 4.1 Where it's wrong

- `docs/ENERGY_LAWS.md` / `docs/TERNARY_COMPUTE_VERDICT.md`: *"ternary transport wins 9.2×…
  the polar **single wire** is the correct transport representation."* **DIRECT**.
- `docs/compute/gates.md` §6a: the wire win is credited to *"the single-wire link"* and
  *"1.585 bits/wire"*. **DIRECT**.
- `circuit/ENERGY_RESULTS.md`: *"single-wire AC-polarity ternary cell."* **DIRECT**.
- `docs/compute/ground_up/differential_noise.md` §3.1 is the counter-doc — it already proves
  the cell *"gets zero common-mode rejection… a balanced constellation is not balanced
  transmission"* — but its verdict is never propagated back into `ENERGY_LAWS.md`. **DIRECT (the analysis) / the non-propagation is the leak**.

### 4.2 The correct model

A push/pull signal on one wire is **signed single-ended**; it has **no** common-mode
rejection by itself (there is no second wire to subtract). It becomes *partially*
differential only through the two **diode rails read as a difference**:
`V(rA) − V(rB) = {+V, 0, −V}`, which rejects common-mode noise up to the diode-pair
matching ratio. A *fully* differential form is two wires (MLT-3/LVDS), which costs
2 wires/trit = 0.79 bits/wire — **below binary**. **[DIRECT — `differential_noise.md` §1, §4;
`analog_polar.md` §4.2 "the diode pair already half-has a differential read"]**

### 4.3 What re-measuring it changes

The 0.081 pJ/bit transport number is a **single-ended, no-common-mode-disturbance**
measurement. Two un-run measurements change the picture:

1. **Common-mode injection on the existing cell:** the single-ended read passes ground
   bounce/supply ripple through ~1:1; the difference read (`rA−rB`) rejects it by the diode
   matching ratio. This is `analog_polar.md` Idea C and `differential_noise.md` §8's
   "10-line perturbation" — **never run**. **[OURS — the CMRR number is the unmeasured output]**
2. **The honest "1.585 bits/wire" caveat:** the transport win assumes one wire per trit. A
   differential rebuild doubles the wire count and gives back the radix-economy win. The
   claim "single wire is the win" is therefore *conditional on the link being able to live
   with zero CMRR* — which the verdict never states. **[OURS]**

**Re-test (§9.3):** `analog_polar.cir` Idea C (inject a common-mode source, measure
`err_single-ended / err_differential` = CMRR) — immediately runnable in the existing LEVEL=1
harness.

---

## 5. Dimension 4 — SUBSTRATE: multi-Vt 2-level MOSFET presented as the native 3-state device

### 5.1 Where it's wrong

- `docs/compute/ground_up/device_circuit.md` §1–§5: the entire "native polar FET" is a
  **4-threshold inventory** (N_hi Vtn=+1.5, P_hi Vtp=−1.5, depN, depP) — i.e. four flavors of
  **2-level MOSFET**, presented as "the native cell." Its own §0 admits the mechanism is
  "two transistor thresholds," yet §7 claims it "removes the demux + driver overhead."
  **[DIRECT — the file is internally contradictory on this point; OURS — flagging it]**
- `docs/compute/ground_up/device_literature.md` §2.2 (multi-Vt CNTFET) and §2.5 (IG-FinFET)
  rank "tuned-threshold 2-level transistors" as *"the native ternary transistor."* §2.5 is
  the one honest caveat: the IG-FinFET's 3 states are *current* states needing a load.
  **[DIRECT]**
- `circuit/diode_gates.cir`: uses `N_HI`/`P_HI` (VTO=±1.1) elevated-Vt devices to build the
  dead zone — still multi-Vt on 2-level devices (here for a dead zone, not "3 levels", but
  the same substrate leak). **[DIRECT]**
- `docs/compute/ground_up/minimal_gates.md` §4b: *"on the closest native 3-state device in
  the corpus"* — the "closest native device" is CNTFET (multi-Vt), i.e. not native. **[OURS]**

### 5.2 The correct model

A **native** 3-state device is one whose free-energy landscape `F(q)` has **three minima**
separated by barriers ≫ kT — electrically, an I–V with **two NDR segments** (2-peak RTD),
the Coulomb ladder (SET), or three genuine drive-current states (IG-FinFET). **Multi-Vt
CMOS/CNTFET has no third minimum** — it is a 2-level transistor with a *tuned threshold*,
giving "three driven levels, not three self-held states" (the device's own §2.2 admits this).
`meta_critique.md` §3e already names it: *"multi-Vt CMOS is the 2-threshold tax in device
form."* **[DIRECT — `device_physics.md` §0–§4, `device_literature.md` §2.2's own caveat, `meta_critique.md` §3e]**

### 5.3 What re-measuring it changes

- The "~1.5–2× per bit still loses" estimate (`device_circuit.md` §7.2) is for **multi-Vt
  CMOS** — the 2-threshold tax relocated, not removed. It must not be quoted as "native
  ternary loses" (it is "level-coded multi-Vt CMOS loses"). **[OURS]**
- The *actual* native-device measurement — a 2-peak RTD / SET / IG-FinFET gate on a real
  compact model — **does not exist** (`test_suite_spec.md` §1: no model). So the verdict
  docs' "no native device wins" is *unmeasured*, not *measured*, for every device except the
  multi-Vt one that was never native in the first place. **[DIRECT — the absence of a model is explicit in the corpus]**
- The correct native-ternary device for *polar* encoding should be a device whose **state is
  the current direction** (a reconfigurable-polarity FET — `Yeom 2025` / `2309.01615`), not a
  level-coder. The corpus ranks the wrong property. **[OURS]**

**Re-test (§9.4):** the `test_suite_spec.md` native-device contract, but with the *direction*
receiver and a real 3-minimum model — not a LEVEL=1 MOSFET with tweaked VTO. Until then,
label all multi-Vt numbers "multi-Vt CMOS", never "native ternary."

---

## 6. Dimension 5 — METRIC: per-gate vs per-state vs per-wire, collapsed into "per bit"

### 6.1 Where it's wrong

The verdict collapses three orthogonal quantities into one "per bit" (÷1.585):

- **per-WIRE (transport):** `ENERGY_LAWS.md` 0.081 pJ/bit; "1.585 bits/wire". Measured on the
  *diode* cell, null free. **DIRECT**.
- **per-STATE (namespace/density):** `word_fairfight.md` "area/state"; `storage.md` "bits/cell".
  For the 2-bit encoding this is **0.79 bits/wire = a 26% LOSS**. **DIRECT**.
- **per-GATE (compute):** `gate_energy.md` / `gate_area.md` "E/toggle", "area/gate". Measured
  on the *sense-amp* cell. **DIRECT**.

The leak: **the transport win and the compute loss were measured on different receivers and
presented as one coherent "per bit" story.** `docs/ENERGY_LAWS.md` and
`docs/TERNARY_COMPUTE_VERDICT.md` conclude "ternary wire wins, binary gate wins" without ever
noting that the wire was measured with the direction receiver and the gate with the level
receiver. **[OURS — the conflation; the individual numbers are DIRECT]**

Secondary metric leaks:

- `docs/compute/gate_energy.md` §6a: *"1.585 bits/trit on 2 wires = 0.79 bits/wire"* applies a
  **per-wire** (transport) metric to a **logic network** (the gate), mixing units. **OURS**.
- `docs/ENERGY_LAWS.md` Law 3: *"3 wins because nearest e"* is a per-symbol radix-economy
  (transport) statement used to justify a *compute* program whose own verdict is per-bit.
  **OURS**.

### 6.2 The correct model

Three separate ledgers, never summed:

| metric | object | ternary's honest number | receiver that measured it |
|---|---|---|---|
| per-WIRE | transport link | **0.081 pJ/bit — wins 9.2×** | diode direction (null free) |
| per-STATE | storage density | **0.79 bits/wire — loses 26%** (2-bit encoding) | n/a (it *is* binary) |
| per-GATE | compute op | **4.9–14.3×/bit — loses** (sense amp) vs **~20×/toggle but null-free** (diode, un-integrated) | sense-amp vs diode-direction |

**[OURS — the three-way split; the individual rows are DIRECT from the cited files]**

### 6.3 What re-measuring it changes

- The **one decisive un-measured number**: the gate fair-fight under **activity-weighted**
  (per-active-symbol) energy, with the **diode-direction** receiver. The sense-amp gate draws
  ~1.9 pJ on every *held null* (so null-heavy data is its *worst* case); the diode gate idles
  at ~0 (so null-heavy data is its *best* case). A null-as-default, self-timed, direction-
  receiver gate could beat binary on *average* while losing per-toggle — the exact result
  `null_default.md` §4 argues and no one measured. **[OURS/SPECULATION]**
- The **"26% wire overhead"** penalty (`gate_area.md`, `storage.md`) is a *2-bit-encoding*
  artifact, not a ternary fact: it vanishes the moment the trit is carried on **one** wire
  with a direction receiver (1.585 bits/wire). The corpus computed the gate area with the
  *2-bit encoding* and then used that to argue ternary loses — but the encoding is the
  thing under question. **[OURS]**

**Re-test (§9.5):** a word-level fair fight (`word_fairfight_cells.v` style) where the trit
is the **1-wire direction code** through `diode_gates.cir`-style cells, costed per active
symbol under a null-heavy traffic histogram, not per toggle.

---

## 7. Cross-cutting leaks (beyond the five named dimensions)

### 7.1 "Law 1 — the receiver is gauge-agnostic / 2-threshold tax" is itself a binary default

`docs/ENERGY_LAWS.md` Law 1 states the "2-threshold tax" as an invariant of *ternary*, not of
the *sense-amp level receiver*. But "resolve 3 states = 2 thresholds" is true only for the
**ordered-levels** reading. A **direction** receiver resolves sign with ~zero thresholding
(diode legs) and presence with one dead-band — there are not "2 level comparisons against 0."
Law 1 is *the level receiver's cost, wearing a law's clothes.* **[OURS — the sharpest single point of this audit; the component facts (sense-amp cost 2.54×, diode idle ≈0) are DIRECT]**

Consequence: every doc that cites "Law 1" as *the reason* ternary compute loses
(`gates.md`, `device_physics.md`, `device_circuit.md`, `meta_critique.md`, `converters.md`,
`TEST — the verdict itself`) is propagating the sense-amp receiver's cost as a radix fact.

### 7.2 The null is "the middle level" — the default that reverses the null's meaning

Correct: null = **absence of drive** (no current), the *default/off* state, the most common
symbol, and it is *not* "between" anything. The corpus keeps re-importing the level framing:
`device_circuit.md` §0 ("null = 0 V, the middle"), `device_physics.md` §2.3, `storage.md`
(mid-rail), `differential_noise.md` §3.2 ("the null IS the zero of the difference… you cannot
read the null by reading the sign"). That last claim is *true of a level reading and false of
a direction reading*: with diodes, "null = neither leg fired" is read by the *same* mechanism
that reads push/pull, and the diode-drop dead band is what distinguishes it. **[OURS — the
correction; `differential_noise.md` §3.2 is DIRECT-as-level-analysis]**

### 7.3 MLT-3 / PAM-3 as "the 3-level analogy" — a come-to-terms failure

`TERNARY_PROCESSOR.md` §1.3 and `differential_noise.md` cite MLT-3/PAM-3/4 as the "three-level
line code" precedent. Those are **level** codes (3 ranked voltages). Polar ternary is
**sign+magnitude**. The corpus repeatedly cites level-code precedent to *justify* the level
receiver, collapsing the two. (`differential_noise.md` handles MLT-3 carefully; `TERNARY_PROCESSOR.md`
§1.3 groups them loosely.) **[OURS — the disambiguation; the level-vs-polarity distinction is DIRECT]**

### 7.4 The two-bucket E_gate / E_rec accounting is a level-receiver construct

`polar_gates.cir`, `gate_energy.cir`, and `test_suite_spec.md` §3.2 split energy into E_gate
(gate supply) + E_rec (receiver supply). This split only exists when the receiver is an
*active clocked sense amp with its own supply*. A diode-direction receiver has **no E_rec** —
its cost is the driver's delivered charge (inside E_gate). So the headline "2.54× receiver
tax" line item is an artifact of the accounting convention, which in turn presupposed the
sense amp. `diode_gates.cir`'s header says exactly this and its log has no E_rec column.
**[DIRECT — the netlists; OURS — flagging the presupposition]**

### 7.5 "The 2-bit encoding is the correct compute representation" — the rationalization

`docs/TERNARY_COMPUTE_VERDICT.md` §Architecture: *"the 2-bit encoding (01/00/10) is the
correct compute representation (it IS binary storage/logic)."* Honest, but it *forecloses*
the question by declaring the binary emulation "correct" before the direction-receiver gate
was measured. The 2-bit encoding is the correct representation *of the binary-substrate
fallback*, not of ternary compute. The whole ground-up program exists precisely because this
was an unmeasured assumption. **[OURS]**

---

## 8. Master table — every mis-modeled spot

Legend: **R**=representation, **Rx**=receiver, **T**=transmission, **S**=substrate, **M**=metric, **X**=cross-cutting.

| # | WHERE (file, section) | WRONG (the leak) | CORRECT model | RE-TEST | dim | calib |
|---|---|---|---|---|---|---|
| 1 | `rtl/trit_functions.vh`; `rtl/ternary_gates.v` hdr; `rtl/ternary_ff.v`; `rtl/converters.v`; `rtl/cpu.v` | trit = **2 bits** `01=+1 00=0 10=−1 11=NEVER` — binary emulation, 0.79 bits/wire | trit = **1 wire**, sign+magnitude, direction | measure a 1-wire trit through `diode_gates.cir` cells; word-level cost | R | DIRECT |
| 2 | `circuit/polar_gates.cir` (sensamp + header) | **sense amp vs 0 V** (level receiver); null ON the threshold | **diode direction** (2 antiparallel legs); null = neither | A/B same gate: sense-amp vs diode receiver, same rails/load | Rx | DIRECT |
| 3 | `circuit/gate_energy.cir`; `docs/compute/gate_energy.md` | **2.54× receiver tax** measured on sense amps, presented as ternary tax | no receiver supply with diodes; tax is sense-amp-specific | re-run with diode receiver; delete/relabel E_rec | Rx | DIRECT |
| 4 | `circuit/receiver_cheap.cir`; `docs/compute/receiver_cheap.md` | receiver floor 0.0865 pJ/trit = **sense-amp floor**, called "the floor" | diode receiver has no such floor; null free | add a diode-direction variant to the sweep | Rx | DIRECT |
| 5 | `docs/ENERGY_LAWS.md` Law 1 | **"2-threshold tax" as a law of ternary** | it's the level receiver's cost | restate Law 1 per receiver topology | X | OUR/SPEC |
| 6 | `docs/ENERGY_LAWS.md`; `docs/TERNARY_COMPUTE_VERDICT.md` | **"single wire is the correct transport representation"** sold w/o CMRR caveat | signed single-ended; differential only via 2 diode rails | inject common-mode; measure CMRR of 1-rail vs 2-rail read | T | OUR |
| 7 | `docs/compute/gates.md` §1/§6; `docs/compute/ground_up/device_physics.md` §2.3; `device_circuit.md` §0 | **"3 ordered levels → 2 thresholds → V_swing/4"** | sign + magnitude (1 voltage × 2 directions) | re-describe cell; re-derive margin (direction + presence) | R | DIRECT |
| 8 | `docs/compute/ground_up/device_circuit.md` §1–§5 | **multi-Vt (4 threshold flavors) = "the native cell"** | native = 3 free-energy minima (2 NDRs / Coulomb / 3 current states) | real 3-minimum compact model; relabel multi-Vt results | S | DIRECT |
| 9 | `docs/compute/ground_up/device_literature.md` §2.2/§2.5 | **multi-Vt CNTFET / IG-FinFET = "native ternary transistor"** | multi-Vt = tuned 2-level device; IG-FinFET 3 states are current states needing a load | rank by "state is direction" not "level count" | S | DIRECT |
| 10 | `docs/compute/storage.md` (A) column | **3-level SRAM = Vdd/4 margin** as the ternary cell | (A) is the *level* cell; (B) is binary; the *polar* cell is neither | measure a direction-coded storage cell (differential 2-rail) | R | DIRECT |
| 11 | `docs/compute/gate_area.md`; `word_fairfight.md` | **2-wire encoding's 26% wire overhead** used to argue ternary loses | overhead is a 2-bit-encoding artifact, not ternary | re-cost gates on the 1-wire direction code | M | OUR |
| 12 | `docs/compute/ground_up/differential_noise.md` §3.1–3.2 | takes "3 levels" and "null = middle" as base, even while flagging single-endedness | null = absence; direction read needs no level compare | (its own §8) common-mode injection + direction-margin sweep | R/X | DIRECT |
| 13 | `docs/compute/ground_up/null_default.md` §3.2 | "fix" re-encodes null as **absence but reads it as a level** (caps vs ±V_th) | read the direction directly (diode rails), no level re-derivation | run `diode_gates.cir` as the null-as-default receiver | Rx | OUR |
| 14 | `docs/compute/converters.md` §1a | describes the diode demux as "2 thresholds" | diode legs are direction detectors, not thresholds | re-cost layer-A with the direction receiver | Rx | OUR |
| 15 | `docs/TERNARY_COMPUTE_VERDICT.md` §Architecture | declares 2-bit encoding "correct compute representation" pre-measurement | open question; the direction gate was unmeasured at verdict time | fold `diode_gates.log` into the verdict | X | OUR |
| 16 | `circuit/diode_gates.cir` (header still "?? fJ/toggle") | the *correct* model's own measured result was never written back | — | promote `diode_gates.log` → doc; update header | M | DIRECT |
| 17 | `docs/compute/ground_up/test_suite_spec.md` §3.2/§8.2 | E_gate/E_rec split + "receiver tax line item" presuppose the sense amp | diode receiver has no E_rec | add a "passive receiver" column to the spec | X | OUR |

**[Each "WRONG" cell is verbatim in the cited file (DIRECT); "CORRECT" cells are DIRECT where they cite a netlist/origin doc, OUR/SPEC where they are this audit's reframe.]**

---

## 9. The re-test list (each leak → the specific measurement that settles it)

Every item is runnable in the **existing LEVEL=1 ngspice harness** except 9.4 (needs a
device model). None has been run.

1. **Representation re-derivation (R).** Take `ternary_cell.cir` verbatim; re-describe the
   symbol as {+I, 0, −I} sign+magnitude; re-derive the noise margin as (null-vs-signal dead
   band) + (direction robustness), not V_swing/4. Output: the corrected margin table that
   replaces `device_physics.md` §2.3's "halved margin." *(No new sim — re-interpretation.)*
2. **Receiver A/B (Rx).** Same gate truth table (NOT/MIN/MAX/sum) behind (a) the
   `polar_gates.cir` 2-sense-amp receiver and (b) the `diode_gates.cir` diode-direction
   receiver, identical rails/loads/toggle. Output: the *receiver-attributed* portion of the
   4.9–14.3× loss, isolated. *(Mostly exists; needs the A/B in one file.)*
3. **Null-idle head-to-head (Rx).** Held-null energy for the sense-amp gate vs the diode
   gate. (Already measured in two logs: 1.9 pJ vs ≈0 aJ — just needs to be *published* side
   by side.)
4. **Common-mode CMRR (T).** `analog_polar.md` Idea C / `differential_noise.md` §8: inject a
   common-mode source on the wire; measure `err_single-ended / err_differential`. Output: the
   actual CMRR of the 1-wire cell and whether "single wire" survives as a transport claim.
5. **Native-device contract (S).** `test_suite_spec.md` §1, but with a device whose *state is
   the current direction* (reconfigurable-polarity FET / 2-peak RTD quantizer), and a real
   compact model — not a LEVEL=1 MOSFET with tweaked VTO. Output: the first native-ternary
   gate number that isn't multi-Vt.
6. **Activity-weighted gate metric (M).** `word_fairfight_cells.v`-style word fight where the
   trit is the 1-wire direction code through diode cells, costed per **active symbol** under
   a null-heavy histogram (Zipf / idle-lane traffic), not per toggle. Output: the average
   (not worst-case) compute cost — the number that decides null-as-default.
7. **Metric ledger (M).** Publish the three-way table (§6.2) as the canonical ledger so no
   future doc sums per-wire, per-state, and per-gate into one "per bit."

**[OURS — the list; each test's feasibility is DIRECT from the existing netlists]**

---

## 10. What was already caught vs what this audit adds

**Already caught in-corpus (credit where due):**

- `differential_noise.md` already proves the cell is single-ended (zero CMRR) and that
  "balanced constellation ≠ balanced transmission" (§4.1, leak #12). **It is the best doc in
  the corpus and its finding never propagated.**
- `analog_polar.md` §4.2 already identifies the diode-pair as a partial differential read.
- `null_default.md` §2 already diagnoses the sense-amp null metastability.
- `meta_critique.md` §3e already says "multi-Vt CMOS is the 2-threshold tax in device form."
- `diode_gates.cir` already *states and builds* the correct model (sign+magnitude, diode
  direction) — its header is the single clearest statement in the corpus.

**What this audit adds (the gaps):**

1. The **systematic map** of every spot, not just the ones the corpus self-flagged (§8).
2. The finding that **the verdict was computed on the wrong receiver and never integrated the
   right one** — `diode_gates.log` is the smoking gun (measured, un-published).
3. **Law 1 is itself a binary default** (§7.1) — the "2-threshold tax" is the level receiver's
   cost wearing a law's clothes, and it is the load-bearing premise of the entire
   "compute loses" conclusion.
4. The **metric conflation** (§6) — per-wire win vs per-gate loss are different receivers and
   different units.
5. The **re-test list** (§9) that turns each leak into a concrete, runnable measurement.

---

## TODO / not covered / caveats

- **This audit re-read the corpus and its logs; it ran nothing new.** Every number quoted is
  from an existing `.md`/`.cir`/`.log`. The re-tests in §9 are *specified*, not executed —
  executing §9.2–9.7 is the highest-value next step, and only §9.4 is blocked on a device model.
- **The diode-direction gate still loses ~20×/toggle on the LEVEL=1 harness** (1032 fJ vs
  52.7 fJ binary NOT). The correct-model correction does **not** by itself flip the per-toggle
  verdict; it removes the null cost and the receiver tax and *re-opens* the metric. I am not
  claiming "diode receiver ⇒ ternary gates win" — only "the 4.9–14.3× number was measured
  wrong, and the re-measure changes the *structure* of the loss."
- **The per-active-symbol / self-timed win is SPECULATION until §9.6 runs.** A null-as-default
  gate that idles at ~0 wins on average *iff* the traffic is null-heavy; that is a workload
  claim, not a circuit claim. `null_default.md` argues it; nothing measures it.
- **`diode_gates.log`'s release residual (vw_4_f ≈ +0.12 V)** shows the elevated-Vt dead-zone
  null is not perfectly clean in that implementation (the wire does not return exactly to 0
  through the 100 kΩ Rterm against the 10 kΩ next-stage keepers). The "null ≈ free" claim in
  §3.3 is the *idle* (quiet-window) energy, which is ≈0; the *dynamic* return-to-null has a
  residual that needs a dedicated measurement before "null is free in the diode gate" is
  stated unconditionally. **[DIRECT from the log — flagged honestly]**
- **The 2-bit encoding is not "wrong" for its actual job.** It is the correct storage/logic
  substrate *given* a binary standard-cell library (`cpu.v`). The leak is only when it is
  presented as *the* ternary compute representation, or when its 26% wire overhead is used to
  argue "ternary loses" as if the overhead were intrinsic. The hybrid `cpu.v` may still be the
  right architecture; this audit only shows the *evidence for that conclusion* was measured
  on the wrong receiver.
- **"Native 3-state device" was never measured** (no compact model) — so the verdict docs'
  "no native device wins" is an *absence of evidence* turned into *evidence of absence* for
  every candidate except the multi-Vt one that was never native. The fabrication go/no-go
  question (`meta_critique.md` §3e) is still open and still the program's gate.
- **Common-mode rejection is the one quantitatively-unmeasured claim in the whole corpus**
  (CMRR of the 1-wire cell vs its 2-rail difference read). §9.4 is the cheapest high-value
  test and should run before "single wire is the transport win" is quoted again.
- **Scope:** this audit covered the *circuit/transport/gate* model. It did **not** re-audit the
  Eisenstein-integer math docs (`eisen_opcode.md`, `arithmetic.md`, `control.md`,
  `gamma_function.md`, `epstein_zeta.md`, `kronecker_limit.md`, `euler_constants.md`,
  `einstein_calculus.md`) for the *separate* question of whether the *math* layer was mis-handed
  as binary — that is a distinct hunt (e.g. "mod-6 Z₆ vs mod-2 parity" analogies) and is left
  as a follow-up. The 2-bit *encoding* in `arithmetic.md`/`control.md` is the same leak as #1,
  but the *math* (norm, units, F₃) is not re-audited here.
