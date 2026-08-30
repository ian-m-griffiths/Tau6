# Alternative Primitives — is there a non-junction ternary read that beats binary on compute?

**2026-08-30 — Tau Architecture, ground-up survey.** The settled verdict
(`junction_cost_verdict.md`, `radix_lower_bound.md`, `meta_math.md`) is that the
junction (polarity/diode-direction) encoding wins transport and loses compute, because
**reading a trit is still 2 threshold decisions vs binary's 1** (1.26× proved floor →
2.54× measured receiver → 3.4–4.9× measured gate). This file asks the one question that
verdict leaves open: **is there a *different* physical primitive — not a diode-direction
junction — where the trit is read in ONE step, or where the 3rd state (null) is free to
*read*?** It surveys six families the brief names plus two of our own, and reports
honestly whether any of them breaks the floor.

**Calibration legend** (repo standard):

- **DIRECT** — measured (ngspice log) or proved (Lean) or a textbook identity. Cite the file/number.
- **ANALOGY** — structural resemblance to a DIRECT fact; the shapes match, the objects differ.
- **OURS** — our inference/reframe; follows from DIRECT but is not independently established.
- **SPECULATION** — untested hypothesis, or an order-of-magnitude estimate with no cited source.

---

## 0. The blunt verdict, first

**No primitive reads a trit in ≤1 decision. The 2-decision read is a consequence of
"3 values > 2 values," and it is information-theoretic, not a diode artifact.** But the
reason is subtler than the diode file states, and the subtlety is the whole answer:

- A *decision* (a comparator, a flip-flop, a detector channel) yields at most **1 bit**.
- Naming one of 3 equiprobable states requires **log₂3 ≈ 1.585 bits**.
- Therefore **no physics can read a trit with 1 binary decision** — that would be extracting
  1.585 bits from 1 bit of hardware. **[DIRECT — Shannon; the same counting `meta_math.md`
  §2 already uses, restated per bit.]**

The only candidate escape is a **native 3-outcome measurement** (one physical pass that
splits a signal 3 ways: Stern–Gerlach spin-1, a Coulomb staircase, a Wollaston prism, a
qutrit projective read). That *is* "one measurement," and it is the `m(3)=1 → 0.63×` model
of `radix_lower_bound.md` §1. **But "one measurement" is not "one decision":** a 3-outcome
discriminator must *record which of 3 outcomes happened*, and that recording hardware is
≥2 bits (2 comparators, or 3 detector channels, or a 3-bin slicer). The passive *split* can
be near-free (a prism, a field gradient); the *readout* never is.

So the verdict splits cleanly, and I state it twice because the distinction is the point:

1. **As a decision count: the 2-decision read is physical (information-theoretic), and no
   primitive escapes it.** `3 > 2 ⇒ ⌈log₂3⌉ = 2`, end of story. The 1.26× *floor* survives
   all six families plus both of ours.
2. **As an energy number: the 1.26× is encoding/substrate-specific.** It prices each of the
   2 decisions at one binary-CMOS comparator (kT/C-limited). A coherent, charge-domain, or
   photon-counting read can make *each* decision cheaper than a voltage comparator — so
   ternary could in principle pay `2 × (cheap decision) < 1.585 × (expensive binary
   decision)`. But no such device is fabricable at VLSI, and none reduces the *count* below 2.

**The one-line answer: the 3rd state is never free to read — it is free to *represent*
(no energy on the wire), and every candidate family pays exactly the same 2 discriminations
to tell it apart from ±1, just relocated into a different physical observable.**

---

## 1. What "one decision" means — three things the diode file conflates

Before the survey, disambiguate the word "decision," because the entire question hinges on it.

| quantity | definition | value for a trit | is it physics-independent? |
|---|---|---|---|
| **bits** | information content `log₂b` | **1.585 bits** | yes — Shannon |
| **binary discriminations** | # of yes/no hardware tests (`⌈log₂b⌉`) | **2** | yes — counting |
| **physical measurements** | # of macroscopic device passes | **1 possible** (native 3-way split) | no — device-dependent |

The `m(3)=1 → 0.63×` "native device" model silently equates the third row with the second:
it says "one measurement costs like one binary threshold." That is the error this file
trains on. **A 3-way splitter is one *measurement* but ≥2 *discriminations*, because the
answer "which of 3" carries 1.585 bits and must land on ≥2 bits of recording hardware.**
Every family below confirms this concretely.

Second, separate two different "free null" claims:

- **Free to represent** — holding/moving null deposits no energy (no pulse, no charge, no
  photon). This is real, and the junction/transport file already credits it (0.05 vs 1.20 pJ).
- **Free to read** — resolving null costs no discrimination. **This is false everywhere.**
  To conclude "null" you must distinguish *absence* from *the negative sign*, and that is a
  comparison against a threshold (voltage, charge, count, phase, or a timeout). The 3rd state
  is cheap to hold, never cheap to name.

---

## 2. The six families (plus two of ours)

Each block states: the primitive → the READ mechanism → discrimination steps per trit →
whether null is free → honest energy/complexity vs binary's 1-decision read.

### 2.1 TIME-DOMAIN ternary (PWM / edge-timing / TDC)

- **Primitive.** Encode the trit in *when* an edge arrives relative to a reference clock:
  `+1 = early edge`, `−1 = late edge`, `0 = no edge` (or a 50%-duty no-transition symbol).
  Read with a **time-to-digital converter (TDC)** — flash (delay-line taps → D-flip-flops →
  encoder) or Vernier.
- **READ.** A single arbiter/D-flip-flop compares the data edge to the clock edge → **sign
  in one comparison**. Null is read by *absence*: no edge arrived within the symbol window
  (a "hit" flag or a timeout). A full flash TDC quantizes time into N bins with N−1
  sampling flip-flops; a 3-symbol time code needs 2 taps.
- **Discriminations: 2.** (1) early-vs-late sign test; (2) edge-present vs no-edge timeout.
  A 3-bin TDC is literally 2 flip-flop comparisons. The two decisions are relocated from
  *voltage* to *time*, not removed. **[DIRECT for the flash-TDC architecture — a delay-line
  TDC is N sampling elements → N−1 comparisons; the "2 taps for 3 bins" is arithmetic.]**
- **Null free?** **Free to represent** (no edge = no event = no energy). **Not free to read**:
  "no edge" is concluded only after waiting a full symbol period — a *temporal* threshold,
  and a latency cost binary does not pay.
- **Energy/complexity vs binary.** Time-domain trades voltage noise for **timing jitter**,
  and in deep-submicron CMOS jitter is generally *worse* than the voltage noise it replaces
  (supply-induced jitter, PVT). **[SPECULATION — no repo measurement; the direction of the
  trade is the standard TDC design pressure, ANALOGY to the low-swing jitter floor.]** No
  measured win. Verdict: **relocates, does not reduce; likely loses.**

### 2.2 FREQUENCY / PHASE ternary (PSK with a null)

- **Primitive.** `+1 = carrier at phase 0°`, `−1 = carrier at phase 180°`, `0 = no carrier`
  (binary-PSK plus an off state). Read with a **phase detector / mixer (homodyne)** against a
  local oscillator, or a **phase-locked loop (PLL)** / phase-frequency detector (PFD).
- **READ.** A double-balanced mixer multiplies signal × LO; its DC output is `A·cos(φ)`,
  i.e. `+A` for 0° and `−A` for 180°. The **sign of the mixer output is the trit sign, read
  by ONE comparator against 0**. Null (no carrier) gives mixer output 0 — indistinguishable
  from a weak negative signal by that one comparator, so a **second, amplitude/envelope
  threshold** (or lock-detector in a PLL) separates "off" from "−1".
- **Discriminations: 2.** (1) coherent sign test; (2) carrier-present amplitude test. The
  mixer output is a single bipolar analog signal `{+A, 0, −A}` → a 3-level slicer is 2
  thresholds. **[DIRECT — homodyne/coherent detection mixes to a DC sign; the "off ≠ −1"
  degeneracy is arithmetic.]**
- **Null free?** Free to represent (no carrier = no radiated/stored energy). Not free to
  read: amplitude/envelope detection is a second threshold, and it needs an integration time
  ≥ one carrier period.
- **Energy/complexity vs binary.** This is the one family with a *genuine* energy lever the
  junction lacks: **coherent gain**. A phase comparison runs near the **shot-noise limit**,
  so the *per-decision* energy can be far below a kT/C voltage comparator. **[DIRECT for
  coherent-vs-direct detection being shot-noise-limited (homodyne near-optimum PSK receiver);
  the "2 cheap decisions < 1.585 expensive decisions" reading is SPECULATION.]** But it pays
  a local-oscillator/PLL (continuous power), ≥1 carrier-period latency, and still 2
  discriminations. Verdict: **does not break the count; the only family with a plausible
  per-decision energy advantage.**

### 2.3 MAGNETIC / spin ternary (up / down / none)

- **Primitive.** `+1 = magnetization up`, `−1 = down`, `0 = no magnetization` (or a third
  polarization state in a multiferroic / AFE cell). Read via **magnetoresistance** —
  **MTJ/TMR/GMR**: resistance depends on relative layer orientation, giving a bipolar,
  3-level resistance signal.
- **READ.** One resistance measurement through a sense amplifier. Up and down are the two
  ends of the TMR loop; "none" (no free layer moment, or a third stable minimum) is a
  *third, middle* resistance value. The three levels are binned by **2 thresholds**.
- **Discriminations: 2.** Up/down is a single sign-of-resistance test; "none" needs a
  second threshold to sit between the two. A 3-level MRAM read is a 3-bin slicer.
  **[DIRECT — TMR/GMR readout is a resistance comparison; the "third magnetic state = middle
  resistance" is ANALOGY, and the third state's stability is SPECULATION.]**
- **Null free?** Free to represent only if "none" is a genuinely stable zero-moment state;
  in practice a nulled MTJ is a **saddle** (it relaxes to up or down), exactly the
  "threshold-sitting" pathology `null_default.md` §2 diagnosed for voltage. Not free to
  read (needs the middle threshold).
- **Energy/complexity vs binary.** Adds a third *unreliable* state (endurance, retention,
  read disturb) on top of the same 2-threshold count. No count advantage, and the 3rd
  state's physics is worse than a voltage null. Verdict: **loses; the null is the weakest
  state, not the free one.**

### 2.4 CHARGE-DOMAIN ternary (net charge +Q / 0 / −Q)

- **Primitive.** Encode the trit as **net signed charge on a node** — a charge integrator,
  or a **single-electron transistor (SET)** whose Coulomb-ladder conductance depends on the
  island charge `n ∈ {−1, 0, +1}`.
- **READ.** A charge-to-voltage integrator accumulates `Q` onto a capacitor → `V = Q/C ∈
  {+V, 0, −V}`, a single **signed** analog output; the sign is ONE comparator against 0.
  A SET reads charge directly: the drain current is a periodic function of gate charge
  (Coulomb oscillations), so `n = −1, 0, +1` sit at 3 distinct current levels.
- **Discriminations: 2.** Sign against 0 is one test; null (zero charge) is a second
  threshold around 0 (a measure-zero point — you need a dead-zone `|V| < V_th`, exactly the
  `null_default.md` dead-zone). A SET's 3 current levels are binned by 2 thresholds.
  **[DIRECT — charge integration gives a signed voltage; SET conductance is Coulomb-periodic.
  The "null = zero-crossing needs a dead-zone" is DIRECT/`null_default.md` §3.2.]**
- **Null free?** Free to represent (zero charge = no charge moved). Not free to read (the
  zero-crossing is a saddle unless you add a dead-zone — and the dead-zone *halves* the
  signal window, `null_default.md` §TODO).
- **Energy/complexity vs binary.** Charge is the conserved signed quantity, so a single-DOF
  charge register erases at `kT ln 3` — **tied** with binary (`meta_math.md` §3). That is a
  real, if neutral, fact. But the SET read is **cryogenic, single-electron-slow, and needs an
  electrometer**; a CMOS charge integrator still needs 2 thresholds + reset. Verdict:
  **thermodynamically honest (tie), practically loses (cryo/slow); count stays 2.**

### 2.5 OPTICAL ternary (polarization H / V / none, or intensity ± / 0)

- **Primitive.** `+1 = H polarization`, `−1 = V polarization`, `0 = no photon` (or intensity
  `+I / 0 / −I`). Read with a **Wollaston prism / polarizing beam splitter + balanced
  photodetector**.
- **READ.** The Wollaston prism **passively** splits H→detector A, V→detector B; a balanced
  detector's difference current is `+I / 0 / −I`. **Sign = which detector fired** — one
  differential comparison. **Null = neither fired** — absence of a click.
- **Discriminations: 2.** (1) A-vs-B (which detector, one differential test); (2)
  click-vs-no-click (presence). In the single-photon regime "no click" is read by waiting a
  full symbol window with a coincidence/timeout gate. **[DIRECT — a Wollaston prism splits
  H/V to two spatial modes; "no photon = no click" needs a timing window.]**
- **Null free?** The *closest* any family gets. Free to represent (no photon = no energy in
  the detector). Read is free *in energy* (a no-click deposits nothing) but **not free in
  time**: you must wait the full symbol period to conclude "no photon," and the sign
  detector must still be armed. So: **energy-free, latency-costly, still 1 of the 2
  discriminations.**
- **Energy/complexity vs binary.** In the photon-counting regime detection is
  **shot-noise-limited**, like phase detection — potentially very cheap per decision. But
  you pay a photon source, 2 detectors, and a timing gate; and the 2 discriminations
  remain. Verdict: **does not break the count; ties phase as the most promising on
  per-decision energy, with the single cleanest "free null" (no energy deposited).**

### 2.6 QUANTUM qutrit (3-level system)

- **Primitive.** A 3-level system (e.g. a superconducting **transmon qutrit**, a trapped-ion
  `m = −1, 0, +1` manifold, a spin-1). `+1/0/−1` are the three levels. Read by **single-shot
  projective measurement**.
- **READ.** Two standard readouts, both 2 discriminations:
  - **Dispersive:** the cavity frequency shifts to 1 of 3 discrete values → the demodulated
    I/Q signal has **3 blobs**, binned by **2 thresholds** in the phase plane.
  - **State-dependent fluorescence:** a cycling transition is bright for one level, dim for
    a second, dark for the third → either **3 distinguishable count levels (2 thresholds)**,
    or **2 sequential measurement rounds** (check bright/dark, repump, check again).
- **Discriminations: 2.** "Single-shot" means *no averaging* is needed; it does **not** mean
  1 bit. The measurement is still a 3-outcome read requiring ≥2 bits of discrimination.
  **[DIRECT — dispersive qutrit readout produces 3 cavity shifts; state-dependent
  fluorescence is a 3-level count. The "single-shot ≠ 1 decision" point is OURS.]**
- **Null free?** **No — the middle level is the *hardest* to discriminate** (the dim state
  in fluorescence, the middle blob in dispersive read), not the free one. It is the opposite
  of free.
- **Energy/complexity vs binary.** Dominated by coherent-control overhead (microwave pulses,
  cryogenics, resonator pumping) that dwarfs the read. No count advantage, maximal
  complexity. Verdict: **loses on every axis; single-shot ≠ 1-decision is the instructive
  fact.**

### 2.7 (ours) SPATIAL-MODE ternary — Stern–Gerlach spin-1 (the purest "1 measurement")

- **Primitive.** A **spin-1 particle** (3 m-levels) through an inhomogeneous field splits
  into **three spatial beams** in a single pass: `m = +1, 0, −1 → 3 positions`.
- **READ.** The trit is read by **position**: 3 detectors (or a position-sensitive array
  with 3 pixels) at the 3 landing spots. The *measurement* is genuinely ONE physical pass —
  the canonical "native 3-outcome detector" that `meta_math.md` T-new-2 names.
- **Discriminations: 2 (as bits) — realized as 3 detector channels.** One pass extracts
  log₂3 bits, but you still need **3 spatial readout channels** (≥2 bits of detector
  hardware) to record which beam fired. This is the clearest disproof of "1 measurement =
  1 binary threshold's cost."
- **Null free?** Free to *split* (the m=0 beam is undeflected — a passive, zero-cost split).
  Not free to *read* (it needs its own detector pixel). **Represented for free, read for
  the cost of a 3rd channel.**
- **Energy/complexity vs binary.** 3 detectors, a field gradient, and a beam of spin-1
  particles — no VLSI path at all. Verdict: **the cleanest demonstration that the passive
  3-way split is cheap but the 3-way *readout* is not; unwinnable as an implementation.**

### 2.8 (ours) SUPERCONDUCTING flux / single-flux-quantum (RSFQ) ternary

- **Primitive.** A **Josephson-junction pulse** carries a **signed single flux quantum**
  (SFQ / SFQ⁻); `+1 = +pulse`, `−1 = −pulse`, `0 = no pulse`. The event-domain sibling of
  the diode-direction junction, on Josephson physics.
- **READ.** A SQUID / junction comparator detects the pulse; **sign = polarity of the
  switching**, read by one threshold; **null = no pulse**, read by a clocked presence check
  (an SFQ gate that toggles only on a pulse).
- **Discriminations: 2.** (1) polarity sign; (2) pulse-present. Identical in structure to the
  diode junction — signed event vs no event — just with Josephson speed/energy.
- **Null free?** Free to represent (no pulse = no energy). Not free to read (presence check).
- **Energy/complexity vs binary.** RSFQ is fast (100s of GHz) and low-energy per pulse
  (~10⁻¹⁹ J/pulse), but **cryogenic (4 K)**, and the 2 discriminations are the *same* count
  as the diode junction. Verdict: **the event-domain framing does not change the count; only
  the energy scale (and temperature) moves.**

---

## 3. Ranked table

Rank = "how close to breaking the 2-decision floor," i.e. how cheaply each makes the 2
discriminations. Lower rank = more promising. No family reaches 1 decision.

| rank | primitive | read mechanism | discriminations/trit | null free to represent? | null free to read? | vs binary's 1-decision read |
|---|---|---|---|---|---|---|
| 1 | **Optical polarization** (H/V/none) | Wollaston split + balanced detector | 2 (which-detector + presence) | **yes** (no photon) | **energy-yes, latency-no** | per-decision near shot-noise; **2 cheap decisions** — plausible per-bit win, no count win |
| 1 | **Phase/coherent** (0°/180°/off) | homodyne mixer + envelope | 2 (sign + amplitude) | **yes** (no carrier) | no (envelope threshold) | coherent gain; needs LO/PLL; 2 decisions |
| 2 | **Charge-domain** (SET/integrator) | charge→voltage, Coulomb staircase | 2 (sign + zero dead-zone) | **yes** (zero charge) | no (zero-crossing saddle) | `kT ln 3` erasure = tie; cryo/slow; 2 thresholds |
| 3 | **Time-domain** (PWM/TDC) | flash TDC / arbiter | 2 (early-late + timeout) | **yes** (no edge) | no (full-symbol wait) | trades voltage noise for jitter; likely loses |
| 4 | **Spatial-mode** (Stern–Gerlach) | 3 beams → 3 detectors | 2 bits → **3 channels** | yes (m=0 undeflected) | no (3rd pixel) | purest 1-measurement; 3-channel readout; no VLSI |
| 5 | **RSFQ flux** (signed pulse/none) | SQUID polarity + presence | 2 (sign + presence) | **yes** (no pulse) | no (presence) | same count as junction; cryogenic |
| 6 | **Magnetic/spin** (up/down/none) | TMR/GMR resistance | 2 (sign + middle) | **no** (3rd state = saddle) | no | null is the *weakest* state; 2 thresholds |
| 7 | **Qutrit** (3-level) | dispersive / fluorescence | 2 (3-bin) | **no** (middle = dim/hardest) | no | single-shot ≠ 1-decision; control overhead dwarfs read |

**Reading the table.** Every family is **2 discriminations** — none is 1. The families
differ only in (a) whether the null is a *stable free state* (optical/phase/charge/time:
yes; magnetic/qutrit: no) and (b) how cheap each of the 2 decisions is (coherent/photon
counting: near shot-noise; CMOS/TDC/SET: kT/C or worse). The floor is **uniform across
physics**: relocating the 2 decisions from voltage to time/phase/charge/photon/spin does
not remove one of them.

---

## 4. Verdict — is the 1.26× floor physical, or encoding-specific?

**Both, at different levels, and the distinction is the deliverable.**

1. **The 2-decision read is physical — it is information-theoretic and survives every
   physics surveyed.** Naming one of 3 equiprobable states needs `log₂3 ≈ 1.585` bits; a
   single binary decision yields 1 bit; hence `⌈log₂3⌉ = 2` decisions, **regardless of
   whether the observable is voltage, time, phase, charge, photon, spin, or flux.** The
   "native 3-outcome measurement" is one *measurement*, not one *decision*: it extracts
   1.585 bits, and recording that outcome costs ≥2 bits of detector hardware (2 comparators,
   or 3 detector channels, or a 3-bin slicer) in every device class named above.
   **[DIRECT — the bit counting is Shannon; the "≥2 bits of readout hardware per 3-way
   split" is the empirical fact confirmed by Stern–Gerlach (3 detectors), Wollaston (2
   detectors + timeout), SET (3 current levels), qutrit (3 blobs).]**

2. **The 1.26× *number* is encoding/substrate-specific — it prices the 2 decisions at one
   kT/C CMOS comparator each.** A coherent (phase/photon-counting) or charge-domain read can
   push the *per-decision* energy below a voltage comparator, so ternary could in principle
   pay `2 × (cheap decision)` vs binary's `1 × (expensive decision)` and win on *energy*
   while still paying 2 decisions. That is the only honest residue of the `0.63×` native
   hope, and it is a **coherent-detection** story, not a **3-state-device** story.
   **[OURS — the reframe; the per-decision energies are SPECULATION (no repo simulation of
   any non-CMOS primitive exists).]**

3. **No primitive reads a trit in ≤1 decision, so the 1.26× floor stands as a lower bound on
   decision count — but it is a *count* bound, not a hard *energy* bound.** The `0.63×`
   native-device model of `radix_lower_bound.md` is wrong not because a 3-way device is
   impossible (Stern–Gerlach proves it possible), but because it prices that 3-way device at
   one binary threshold's cost, whereas a 3-way device costs ≥2 binary thresholds' worth of
   discrimination. The escape criterion of `meta_math.md` T-new-2 — "a single native 3-way
   discrimination costs < 1.262× a binary discrimination" — is therefore **unmeetable by
   information counting plus the empirical cost of a 3rd readout channel.** **[OURS —
   synthesis of the survey.]**

**Final sentence.** The junction's 2-decision loss is not a junction defect; it is the
cost of `3 ≠ 2^k`, and it reappears verbatim in time, phase, charge, optical, spin, and
qutrit encodings. The 3rd state is free to *represent* but never free to *read*. Ternary
compute will not beat binary on decision count by changing physics; the only door ajar is
coherent/photon-counting detection making *each* of the (still two) decisions cheaper than
a CMOS comparator — a transport-era lever, not a compute-era one, and unproven at VLSI.

---

## 5. Calibration ledger

| claim | calibration |
|---|---|
| 1 decision = 1 bit; naming 1 of 3 states = log₂3 ≈ 1.585 bits ⇒ 2 decisions | DIRECT — Shannon; same counting as `meta_math.md` §2 |
| 1.26× = 2/log₂3 = 2·ln2/ln3 | DIRECT — `ThresholdLowerBound.lean`; `radix_lower_bound.md` §1 |
| 0.63× = 1/log₂3 (native-device model) | DIRECT as arithmetic; the `m=1` premise is the model |
| "1 measurement ≠ 1 decision; a 3-way readout needs ≥2 bits of hardware" | OURS — synthesis; instantiated by Stern–Gerlach (3 detectors), Wollaston (2 + timeout), SET (3 levels), qutrit (3 blobs) |
| flash TDC = N−1 sampling flip-flop comparisons; 3 bins = 2 taps | DIRECT (architecture); the count is arithmetic |
| homodyne mixer gives ±A for 0°/180°, 0 for off → sign in 1 comparator + 1 amplitude threshold | DIRECT (coherent-detection textbook); "off ≠ −1 degeneracy" is arithmetic |
| coherent/homodyne and photon counting are shot-noise-limited | DIRECT (standard PSK/photon-counting result) |
| TMR/GMR up/down/none = 3 resistance levels → 2 thresholds; 3rd magnetic state unstable | DIRECT (readout is a resistance compare); the 3rd-state stability is SPECULATION |
| charge integrator gives signed V = Q/C; SET Coulomb staircase gives 3 current levels | DIRECT (device physics); the "zero-crossing needs dead-zone" is `null_default.md` §3.2 |
| single-DOF charge register erases at kT ln 3 = tied with binary | DIRECT — `meta_math.md` §3 (Landauer generalization, `Entropy` 21(12):1150) |
| Wollaston splits H/V; "no photon = no click" read by timing window | DIRECT (optics); the latency-cost reading is OURS |
| qutrit single-shot ≠ 1 bit; dispersive gives 3 blobs, fluorescence 3 count levels | DIRECT (device readout); the "single-shot ≠ 1 decision" framing is OURS |
| RSFQ signed SFQ pulse / no pulse = same 2-decision count as diode junction | ANALOGY (event-domain is structurally the diode junction); cryo is DIRECT |
| no non-CMOS primitive is simulated in the repo | DIRECT (no `circuit/*.cir` for any family here); all per-decision energies are SPECULATION |

---

## Sources

- `docs/compute/ground_up/meta_math.md` — §2 (representation-independent 1.26×), §3
  (Landauer tie for single-DOF), §4 (direction ≠ free), T-new-2 (the escape criterion).
- `docs/compute/ground_up/radix_lower_bound.md` — the two models (1.26× vs 0.63×) and the
  `m(b)/log₂b` framing.
- `docs/compute/junction_cost_verdict.md` — the settled transport-win/compute-loss verdict.
- `docs/compute/ground_up/null_default.md` — null free to represent, expensive to read
  (threshold-sitting, dead-zone, data-gating).
- `docs/compute/gate_energy.md` — 2.54× receiver tax (2 SAs vs 1); the binary baseline.
- `docs/compute/receiver_cheap.md` — the measured SA receiver floor (0.0865 pJ/trit).
- `proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean` — the proved 1.26×.
- Device classes by name (no repo measurement; calibration above): flash/Vernier TDC;
  PLL / phase-frequency detector / double-balanced mixer; MTJ/TMR/GMR; HfO₂ FE / AFE;
  single-electron transistor (Coulomb blockade); Wollaston prism / balanced photodetector;
  superconducting transmon qutrit (dispersive readout); Stern–Gerlach spin-1; RSFQ / Josephson.
