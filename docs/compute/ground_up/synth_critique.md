# Synthesis — critique / noise / analog batch

**2026-08-29 — Tau Architecture, ground-up batch-2 synthesis agent.** ONE task: bring the
three batch-2 reports to a shared vocabulary, find where they agree, where they fight, and
what the merged untested-question list is. Then name the single experiment that most moves
the go/no-go verdict.

**Inputs (all in this directory):**
- `meta_critique.md` — the go/no-go re-frame: wall = receiver tax (Law 1), not the transistor; fab-path audit; NCL/clocking/interface/EDA/variability gaps.
- `differential_noise.md` — does the polar cell's push/pull reject common-mode noise and rescue the halved margin?
- `analog_polar.md` — can analog/current-mode × polar ternary cheapen the gate; three testable ideas (A/B/C).

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):
- **DIRECT** — measured/proved in-repo, or a citable textbook/standard identity.
- **ANALOGY** — parallel structure, not identity.
- **OURS** — this document's synthesis; follows from DIRECT but not independently established.
- **SPECULATION** — untested hypothesis.

Nothing in this document invents a measured number. The *identification* of overlaps and
disagreements is OURS; every underlying fact carries the calibration of its source file.

---

## 0. The one-line synthesis

**All three reports say the same thing from three directions: the wall is the 2-threshold
measurement (Law 1), and the null — not the transistor, not the wire, not the ±signs — is
where ternary dies.** `meta_critique.md` frames it (receiver tax; free the null *inside the
gate*), `differential_noise.md` proves it from the noise side (the null-vs-outer decision is
the binding one and no differential structure protects it), and `analog_polar.md` proves it
from the analog side (current-mode frees the sum and the null but *relocates* the 2-threshold
tax and adds tail current). The three do **not** contradict each other on the verdict; they
contradict each other on **one sub-claim** (does the single-wire diode-pair read reject
common-mode?), and they expose **one gap in the go/no-go criterion itself** (is "free the null
in-gate" sufficient, given that static current-mode achieves it and still loses?).

---

## 1. Overlap — what all three agree on

### 1.1 Go/no-go

All three converge on the *same* decision criterion, stated most sharply in
`meta_critique.md` §1 and adopted verbatim by `analog_polar.md` §3.3:

> **Ternary compute wins only if some representation resolves 3 states with fewer than 2
> thresholding measurements, or makes the null genuinely free *inside a gate*.**

The agreement runs through every layer:

- **The wall is the measurement, not the device.** `meta_critique.md` §0 (Law 1: the receiver
  is gauge-agnostic; the 2-threshold tax), `differential_noise.md` §3.3 (the null-vs-outer
  read, not push-vs-pull, is what cannot be decoded without a measurement), and
  `analog_polar.md` §3.2 (the wrap/carry is where the information lives and it stays a
  2-threshold decision) all locate the cost in *extracting* the 1.585 bits, not in *storing*
  three states. **[OURS — the common reading; each leg is DIRECT/OURS in its source.]**

- **The wire win does not transfer to the gate.** All three hold the B1/B2/B3 split
  (`meta_critique.md` §1): the transport win (0.081 pJ/bit) is already won on plain CMOS and
  is *irrelevant* to the gate battle. `differential_noise.md` §4.3 and `analog_polar.md` §3.3
  both reach it independently (a native/analog device only matters if it cheapens the gate;
  the wire is already winning). **[DIRECT — `ENERGY_LAWS.md`; the "does not transfer" reading
  is the shared OURS.]**

- **Level-coded / multi-Vt "3-state" devices buy nothing.** A device that stores three levels
  but still needs 2 thresholds to read them is the 2-threshold tax in device form.
  `meta_critique.md` §3e says it about multi-Vt CMOS; `analog_polar.md` §3.2 says the same
  thing about the current-mode carry detector ("current-mode did not reduce two boundaries to
  one, any more than multi-Vt did"). **[DIRECT from corpus / OURS.]**

- **The honest program output, if the criterion fails, is already written.**
  `meta_critique.md` §7: keep the hybrid `cpu.v` (ternary datapath, binary cells), stop
  spending agents on native devices. Neither noise nor analog report disputes this; both
  supply additional evidence *for* it. **[OURS.]**

### 1.2 The noise model

The three reports independently reconstruct the *same* noise model, to the digit:

- **Margin is `V_swing/4`, half of binary's, 6.02 dB.** `differential_noise.md` §2 derives it
  (`20·log10(M−1)`); `analog_polar.md` §4.3 states it (3 levels sit `V_swing/2` apart, 2×
  closer); `meta_critique.md` §3g states it (Vdd/4 vs binary's Vdd/2). **[DIRECT — textbook
  M-PAM.]**

- **Common-mode rejection ≠ signal margin.** All three hold the split
  (`differential_noise.md` §2's table; `analog_polar.md` §4.3; `meta_critique.md` A10
  implicitly): differential signaling removes the *common-mode* floor but the binding term is
  *differential-mode* noise, which differential does **not** reject. "Differential" and
  "ternary" pull in opposite directions. **[DIRECT (the split) / OURS (the synthesis).]**

- **The cell as built is not a differential pair.** A single wire carrying {+V, 0, −V} in time
  has ±symmetry in the *codebook*, not a complementary second wire in the *channel*.
  `differential_noise.md` §3.1 and `analog_polar.md` §4.1 state this in identical terms
  (single-ended, no CMRR by itself). **[DIRECT — netlist reading.]**

- **The null is the least-protected symbol.** It is the *zero of the difference* — no sign, so
  the direction machinery cannot decode it; it is flanked on both sides. `differential_noise.md`
  §3.2 and `analog_polar.md` §4.3 agree. **[DIRECT/OURS.]**

- **Even a true differential rebuild does not widen the margin.** Two wires per trit reject
  common-mode but leave the null at `V_diff/2` — still `V_swing/4` — and give back the one-wire
  transport economy the cell is selling. `differential_noise.md` §4.2–4.3 and `analog_polar.md`
  §4.3 both reach this. **[OURS — design analysis, the differential-mode-noise premise is
  DIRECT.]**

### 1.3 The analog combination

The three reports agree on what analog/current-mode does *and does not* do:

- **Analog makes a *better* polar gate, not a *winning* one.** This is `analog_polar.md` §3.3's
  verdict; `meta_critique.md` §5 ("adiabatic × native-device" is a separate bet, and the device
  must beat *binary-with-adiabatic*, A10) and `differential_noise.md` §4 (differential — analog's
  signature noise move — rescues nothing) both supply the same conclusion from the two adjacent
  directions. **[OURS.]**

- **The two real analog wins are narrow and agreed.** KCL makes the *sum* free (the mod-3 sum,
  the voltage cell's hardest gate — `analog_polar.md` §3.1); zero-current is a *dead zone* for
  the null, not the 0-V saddle that caused the measured ~1.9 pJ/toggle shoot-through
  (`analog_polar.md` §1/§3.1). **[DIRECT (KCL, the shoot-through measurement) / OURS (the
  dead-zone claim).]**

- **The 2-threshold tax survives translation to current.** `analog_polar.md` §3.2: the
  balanced carry (wrap) is still two current thresholds; `meta_critique.md` A4: a device
  doesn't change the *information*, only the voltage. **[OURS.]**

- **The third level's only honest wins are where noise is shaped, or where the null is not
  resolved as information.** `analog_polar.md` §4.4 (3-level ΔΣ quantizer = balanced ternary,
  survives because the error is noise-*shaped*) and `differential_noise.md` §1.2 (MLT-3 uses
  three levels for *spectral shaping*, still carries 1 bit/transition, never attempts 1.585
  bits/trit) are the same observation in two citations. The three reports converge on the
  meta-claim: **ternary survives in transport and converters, and dies in the gate** — exactly
  because the gate is the only place the third level must be *read as information*.
  **[DIRECT — MLT-3 / ΔΣ; OURS — the convergence.]**

---

## 2. Disagreements

Three genuine conflicts (and one gap in the criterion). The first is a physical disagreement
that a measurement can settle; the others are tension-of-emphasis that matter for calibration.

| # | Question | `differential_noise.md` | `analog_polar.md` | Resolution |
|---|---|---|---|---|
| **D1** | Does the **single-wire diode-pair read** (`V(C_push) − V(C_pull)`) reject common-mode noise? | **No.** §3.1: the rails are two *rectified halves*, not a pair. On a push, `rA ≈ +0.25 V`, `rB ≈ 0`; a common-mode line shift `+δ` lifts only the *conducting* rail, so the difference moves by the **full δ** — nothing cancels. **[OURS reading; topology DIRECT]** | **Yes (partial).** §4.2: reading the difference "yields a clean signed 3-level signal with genuine common-mode rejection — on one wire… a common-mode glitch charges both caps equally and subtracts out." **[OURS; parts DIRECT]** | `differential_noise.md` has the careful physics. The half-wave rectifier conducts **one** diode at a time; the "both caps charge equally" premise only holds in a true balanced differential pair. `analog_polar.md`'s *own* caveat ("rejection only acts during the conducting half; null-state rejection mismatch-limited") concedes this. The headline of `analog_polar.md` §4.2 is **overstated**; it is the one place the two files would give a simulator different numbers. **Idea C** is the referee. |
| **D2** | Is the null's dead-band **free margin** or **paid-for threshold**? | §3.2: the diode-drop dead-band (~0.3 V) is a *device threshold* (VTO), varies with process/temperature, and is **paid for** in outer-symbol over-swing (line ≈ 0.70 V to assert a 0.25 V rail). Not robust CMRR. **[OURS + DIRECT]** | §1/§3.1: zero-current is a *native* dead zone — "the strongest single claim in Ian's favor," a full `I_th` below every trip point, built into the representation. **[OURS, unmeasured]** | Not strictly contradictory (voltage VTO vs current 0 A are different domains) but they encode **opposite priors** about whether the null can be made free. The skeptical reading is DIRECT (the over-swing is in the netlist); the optimistic reading is OURS/unmeasured. **Idea B** is the referee. |
| **D3** | **Criterion gap** — is "free the null inside the gate" *sufficient* for a go? | (implicit) adopts the 2-branch criterion without testing it. | §3.3: current-mode **delivers** the null-free branch (0 A dead zone) "but explicitly not the first [<2 measurements]" — yet still concludes "not a winning one," because **Item 4** (static tail current in every state, incl. null) violates null-as-default. | This is the one place the batch exposes a *flaw in the go/no-go criterion*, not a clean fight. `meta_critique.md` §1's OR has two branches; `analog_polar.md` shows the second branch can be **true while the gate still loses on static power**. "Free the null" must be disambiguated into (a) **no shoot-through energy** and (b) **no static power**; the criterion needs the conjunct "AND the gate draws ~0 static current in null." **[OURS — the disambiguation.]** |

**One disagreement that is *not* real, flagged to prevent re-litigating it:** `meta_critique.md`
says "no candidate on the list is known to free the null in-gate" while `analog_polar.md`
claims current-mode *does* free it. These are compatible once D3 is applied: `meta_critique.md`
means "no *fabricable native device*" (the fab-path table), `analog_polar.md` means "a
current-mode *circuit topology* does, at the cost of tail current." They are answering
different halves of the same question. **[OURS.]**

---

## 3. Merged TODO — ranked untested questions

Ranked by **moves-verdict × runnable-now**. "Runnable now" = expressible in the existing
LEVEL=1 ngspice harness (current sources, mirrors, the diode pair, the 7-T sense amp) with **no
missing device model**; "audit" = literature/fab question, no simulator.

| rank | untested question | source(s) | type | calibration |
|---|---|---|---|---|
| **1** | **Null-as-zero-current receiver:** does current-mode make the held-null *natively* free — `e_null/e_push → 0` — **and** does the null state draw ~0 static current? (**Idea B**, + the `i_idle` co-measurement) | `analog_polar.md` #1/#3; `meta_critique.md` #3/#6; `differential_noise.md` (the null is the wall) | **runnable now** | OURS — the single highest-value test; see §4 |
| **2** | **Static vs dynamic current-mode fork:** idle bias (fails null-as-default) vs charge-packet/self-timed (keeps null free, pays completion-detection). | `analog_polar.md` #3; `meta_critique.md` #5/#6 (NCL, clocking) | **runnable now** (co-measured in #1) + audit | OURS/ANALOGY |
| **3** | **The wrap is still 2-threshold (Idea A):** put a *number* on the current-mode carry-detector energy vs the 100 T voltage baseline, and confirm the `σ=±2→∓1` wrap cannot be decided in one measurement. | `analog_polar.md` #2 | **runnable now** | OURS (the "still 2 thresholds" prediction is by construction); the energy number would be new DIRECT |
| **4** | **Diode-pair CMRR (Idea C):** inject a common-mode disturbance and measure single-ended vs difference-read error. Settles **D1** — does the one-wire diode read cancel common-mode at all? | `analog_polar.md` #5; `differential_noise.md` TODO #1 | **runnable now** (~10-line perturbation of `ternary_fairfight.cir`) | OURS → would become DIRECT |
| **5** | **Fab-path go/no-go audit:** yes/no/maybe VLSI-foundry table per device (RTD/CNTFET/SET/memristor/reconfigurable-polarity FET), 2026 PDK, with citation. | `meta_critique.md` #1; §3e | audit | DIRECT (domain history, needs citation) |
| **6** | **Measurement-count per device:** reading 3 states costs 1 or 2 thresholds? If 2, the device does not touch Law 1. | `meta_critique.md` #2 | audit | OURS/SPECULATION |
| **7** | **Charge-domain polar (Idea D):** push=+Q, pull=−Q, null=no packet — the best *fit* for null-as-free (packets cost only when moved); needs a CCD/switch-cap topology not yet drawn. | `analog_polar.md` #7 | design target | ANALOGY/OURS |
| **8** | **3-level ΔΣ quantizer as a full loop:** sketch and cost a ΔΣ loop around the balanced-ternary quantizer; compare energy/speed to the transport cell. (The one place the 3rd level is *known* to work.) | `analog_polar.md` #6; `differential_noise.md` (MLT-3) | design target | DIRECT (the block) / SPECULATION (the comparison) |
| **9** | **NCL completion-detection + area tax:** what does null-as-default pay that NCL already measured? (Predicts whether the ternary-null version loses the same way.) | `meta_critique.md` #5, §3b | audit | DIRECT (domain history, verify) |
| **10** | **Clock + clock-gating energy; static/dynamic device physics; adiabatic composition.** Does the device fight or help resonant/reversible clocking (0.081 pJ/bit was adiabatic)? | `meta_critique.md` #6, A10, §5 | audit + sim | DIRECT/OURS |
| **11** | **Native-device interface energy:** what does a *true 3-level* core pay at its binary boundary (level synthesis vs our no-drive null)? Don't reuse `converters.md`'s 2-wire numbers. | `meta_critique.md` #7, §3d | audit | OURS |
| **12** | **Variability/margin/ECC at Vdd/4:** process/RTN/aging/SEU budget; does the `11=NEVER` canary survive a native 3-level cell; **current-mirror mismatch** for `⊗` and the 3:1 wrap correction. | `meta_critique.md` #10; `analog_polar.md` #4 | audit | OURS/SPECULATION |
| **13** | **Differential-mode noise floor enumeration:** which of `kT/C` on rails (~1.4 mV rms), sense-amp offset (σ 5–20 mV), mismatch, rail coupling actually sets the floor at a given swing? | `differential_noise.md` TODO #4 | sim (has the netlist) | DIRECT/OURS |
| **14** | **Energy-to-hold-BER curve, 3-level vs 2-level:** the exact `kT/C → BER` curve still not computed (the open item `device_physics.md` §8 already flags). | `differential_noise.md` TODO #3 | sim/analysis | SPECULATION |
| **15** | **True differential rebuild fairfight:** net win/loss per bit of a real 2-wire polar-ternary pair (common-mode rejection vs wire-count doubling). | `differential_noise.md` TODO #5 | sim | OURS |
| **16** | **Synthesis/mapping path:** if device X wins per-gate, how do we synthesize a 25K-cell ternary CPU (liberty/yosys/PnR/STA)? The CNTFET-15K wall in general form. | `meta_critique.md` #9; `analog_polar.md` #9 | audit | DIRECT/OURS |
| **17** | **System metric:** state the energy-delay-product target (not pJ/bit) and the speed floor, so "competitive" stops floating. | `meta_critique.md` #8 | coordinator (not an agent) | OURS |
| **18** | **Compact-model existence:** before any native-device ngspice run, do we have a valid SPICE model, or are we running LEVEL=1 MOSFETs against a III-V/SET IV and calling it a measurement? | `meta_critique.md` #4 | audit | DIRECT |

**Reading the ranking:** #1–#4 are the four cheap, immediately-runnable tests that can move the
verdict *this batch* with the existing harness; #5–#6 are the fab-path/measurement-count audits
that kill dead ends before agents run; #7–#18 are the long tail that only matters **if** #1–#6
produce a "yes." `meta_critique.md`'s two already-answered items (truth tables, minimal set) are
cut — nothing in the other two files re-opens them.

---

## 4. The single open question — and the one decisive experiment

### The question

**Can the null be made genuinely free — zero energy *and* zero static current — inside a gate
(not on the wire), in any representation (voltage dead-band, current dead-zone, or charge
packet)?**

This is the one question the batch leaves *half*-open. The other go/no-go branch — "resolve 3
states in fewer than 2 measurements" — is closed against us by construction: `analog_polar.md`
§3.2 shows the current-mode wrap is still two thresholds, `meta_critique.md` §3e shows every
fabricable candidate is level-coded, and no report finds a candidate that reads 3 states in one
measurement. **[OURS/SPECULATION — the "closed against us" is a strong prior, not a proof.]**

The null branch is *not* closed. `analog_polar.md` claims current-mode delivers it (0 A dead
zone) but then admits the gate still loses on static tail current. `meta_critique.md`'s
criterion doesn't distinguish "null free in shoot-through" from "null free in power."
`differential_noise.md` proves the null is the *binding* symbol — which is precisely why, if
it can be made free, the verdict moves. The question, correctly stated, is the **conjunction**
the batch never tested: free **and** no static current, at once. **[OURS — the conjunctive
reframe is this document's central contribution.]**

### The one experiment

**Run `analog_polar.md` Idea B — the null-as-zero-current receiver — with one added
measurement: a null-state idle-current probe.** In the existing LEVEL=1 harness: reproduce the
polar gate's held-null, read the rail through a current dead-zone (`|I| < I_th ⇒ nothing
fires`), and co-measure

```
.meas tran e_null   INTEG V(pwr) FROM=100n TO=150n   ; held-null window energy
.meas tran e_push   INTEG V(pwr) FROM=10n  TO=60n    ; push window energy (reference)
.meas tran i_idle   AVG   I(VDD)  FROM=100n TO=150n  ; null-state static current  ← the addition
```

**Three-way outcome, mapped to the verdict:**

1. **`e_null/e_push → 0` AND `i_idle ≈ 0` (leakage floor)** → the null branch is *live*:
   the binding symbol is free in both senses, the go/no-go criterion's second branch survives
   the static-power objection, and the full fab-path audit (#5) becomes worth its cost. This is
   the only near-term result that could *flip* "dead end" to "keep digging." **[SPECULATION —
   outcome mapping.]**

2. **`e_null/e_push → 0` but `i_idle` sits at the tail-current floor** → the null is free in
   shoot-through but *not* in power; the criterion gains its missing conjunct ("AND no static
   power in null"), and the decisive test moves to the **charge-packet (dynamic) variant —
   Idea D** — because static current-mode is now excluded *by construction* (`analog_polar.md`
   Item 4). **[OURS — this is the D3 gap made into a measurement.]**

3. **Neither holds** → the null branch is dead, and `meta_critique.md` §7's honest output
   stands: keep the hybrid `cpu.v`, stop spending agents on native devices, spend the budget on
   the two already-measured wins (receiver-cheapening, Eisenstein-multiply opcode). **[OURS.]**

**Why *this* experiment and not the fab-path audit or a native-device model:** the fab-path
audit (#5) is a *literature* question whose prior is already "no" and whose output is a table,
not a verdict-moving number; and every native-device simulation is blocked on a missing compact
model (#18). Idea B is the one experiment that (a) is runnable *today* in the LEVEL=1 harness,
(b) probes the exact symbol the three reports agree is the wall, and (c) has an outcome —
outcome 1 — that would be the first *measured* evidence in the whole ground-up corpus that
ternary compute is not a closed question. **[OURS.]**

---

## 5. Calibration ledger (this document's own claims)

| claim | calibration |
|---|---|
| all three locate the wall at the 2-threshold measurement / the null | **OURS** — reading of the three files; each file's leg is DIRECT/OURS |
| the three agree on the go/no-go criterion | **OURS** — `meta_critique.md` §1 states it; `analog_polar.md` §3.3 adopts it verbatim; `differential_noise.md` reaches it from noise |
| the three agree on the noise model (V_swing/4, 6.02 dB, common≠differential) | **DIRECT** (textbook M-PAM) + **OURS** (the convergence) |
| the three agree analog is "better, not winning" | **OURS** |
| ternary survives in transport/ΔΣ, dies in the gate | **OURS** — from DIRECT MLT-3 and ΔΣ citations |
| D1: the diode-pair read does *not* cancel common-mode (full δ on the difference) | **OURS** — resolution of the conflict; topology is DIRECT |
| D2: opposite priors on whether the null can be made free | **OURS** |
| D3: the go/no-go criterion needs the "no static power in null" conjunct | **OURS** — the central contribution |
| the single decisive experiment is Idea B + an `i_idle` probe, with a 3-way outcome map | **OURS/SPECULATION** |

---

## TODO / not covered / caveats

- **No measurement was done.** This is a *synthesis* of three already-written reports; it adds
  no ngspice/yosys/Lean numbers. The four "runnable now" items (#1–#4) are exactly the tests
  that remain unrun, and running them is the batch's next step.
- **The D1 resolution is an argument, not a measurement.** I read `differential_noise.md` §3.1
  as the correct physics (half-wave rectifier conducts one diode at a time ⇒ "both caps charge
  equally" is false), but the referee is Idea C — a ~10-line common-mode injection into
  `ternary_fairfight.cir`. Do not let this synthesis pre-close a question a simulator can
  settle in an afternoon.
- **The "fewer-than-2-measurements branch is closed" is a strong prior, not a proof.** A
  2025–2026 device or a one-measurement *representation* (not on any candidate list) could
  overturn it. `meta_critique.md`'s forward-looking scan caveat stands and should ride inside
  the fab-path audit (#5).
- **The single-experiment outcome map (outcome 1 = "flip the verdict") is SPECULATION.**
  Even a clean `e_null/e_push → 0` with `i_idle ≈ 0` only re-opens the go/no-go question; it
  does not yet beat binary's energy-delay product, does not answer the clock-tree (#10),
  interface (#11), variability (#12), or synthesis (#16) taxes, and does not by itself produce
  a device with a VLSI path. It is a necessary, not sufficient, condition for a go.
- **The three reports were not re-verified against the corpus.** I assume `polar_gates.md`'s
  "~1.9 pJ/toggle null shoot-through," `gate_area.md`'s "2.00–4.33×," and `ENERGY_LAWS.md`'s
  "0.081 pJ/bit" are all internally consistent, as each report asserts. If any two of those
  conflict, the shared "wall = receiver tax" premise needs re-checking before this ranking is
  trusted — the same caveat `meta_critique.md` §TODO already raises about itself.
- **Not covered:** the Eisenstein-multiply opcode and the receiver-cheapening lever (the two
  already-measured wins `meta_critique.md` §7 says to fund instead) are named but not analyzed
  here; they are the *fallback* program, not the ground-up search, and deserve their own
  synthesis if the go/no-go comes back "no."
- **Not covered:** a true ΔΣ loop (#8) and a charge-domain topology (#7) are the only two
  ideas in the batch that have *no netlist at all*, even a sketch; both are flagged as
  "obvious Idea D / separate survey" in their sources and remain pure design targets.
