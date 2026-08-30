# Meta-Assumptions — the hidden premises every proof and argument leans on

**2026-08-29 — the "find the load-bearing assumptions" pass.** This file does to the
*whole ternary corpus* what `meta_critique.md` did to the batch-1 plan: it asks, for each
major conclusion, **what must be true that is never stated, and does real hardware violate
it?** It is a *critique of the conclusions*, not a re-derivation of the results. Every
number cited is already measured/proved in the corpus; no new ngspice/yosys/Lean work was
run for this file.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured/proved (our ngspice/yosys/Lean numbers, or a textbook identity).
- **ANALOGY** — parallel structure, not identity (the shapes match, the objects differ).
- **OURS** — our own inference/design claim; follows from DIRECT but not independently established.
- **SPECULATION** — untested hypothesis, flagged as such.

**One-line answer up front:** every "ternary wins" conclusion and every "ternary loses"
conclusion is load-bearing on a *different* unstated premise, and the two sets of premises
are **mutually inconsistent**. The transport win assumes the null is free-and-frequent and
the binary baseline is a handicapped ±1 V bipolar link. The compute-loss assumes energy is
uniform-per-threshold and the receiver is a level-coded 2-comparator sampler. Real hardware
(adiabatic recovery, diode direction receivers, multi-threshold devices) violates the
*compute-loss* premises directly, while the *transport-win* premises are violated by the
corpus's own measured caveats (LEVEL=1 models, real offsets, speed tax, single-ended binary).
The verdict is therefore **far more fragile than either headline admits.**

---

## 0. The master table — conclusion → hidden assumption → status

| # | conclusion (who says it) | hidden assumption | calibration | violated by | collapses if it fails? |
|---|---|---|---|---|---|
| A1 | transport 9.2× win (`ENERGY_LAWS`, verdict) | **"per bit" is the right metric**, and bits/wire is the scarce resource | OURS | energy-delay product (adiabatic is L-bound 48–100 Mtrit/s, 5–10× slow) | YES — per joule-of-*work* the win shrinks or vanishes |
| A2 | all "N× vs binary" numbers | **binary baseline is a ±1 V *bipolar* 2 V swing** (its natural single-ended swing is 1 V) | DIRECT (harness convention) / flagged but not in the headline | single-ended 0→VDD binary (~2× cheaper) | YES — every "N× better" roughly halves |
| A3 | transport win, `EnergyVerdict` | **the null is frequent AND free** (0.05 pJ, data-bearing) | free = DIRECT (measured); frequent = SPECULATION (workload) | real data that isn't null-dominated | YES — at uniform the win is 1.45×, not 9.2×; ±1 trit is 1.6× *worse* than a bit |
| A4 | all measured champions (0.081/0.092 pJ/bit) | **LEVEL=1: no leakage, no body diodes, no mismatch** | DIRECT (model) | silicon offsets σ≈5–20 mV | YES — corpus's own number: floor rises to 0.22–0.35 pJ/bit |
| A5 | `ThresholdLowerBound.lean` ⇒ "ternary compute can't win" | **energy ∝ threshold-count, uniform per-threshold cost** | the math DIRECT; the *energy* mapping ANALOGY/OURS | multi-threshold device (RTD knee, FeFET, CNTFET chirality) where the 2nd threshold is ~free | YES — "(b−1)/ln b increasing" stops implying "binary wins energy" |
| A6 | same theorem | **resolution = (b−1) *ordered* thresholds (a level-coded quantizer)** | OURS (model choice) | diode/direction receiver: 3 states by rail-*selection*, not 2 ordered thresholds | YES — the (b−1) model doesn't describe the actual receiver |
| A7 | thermodynamics direction (verdict) | **Landauer floor is the *binding* cost** | DIRECT (the identity) / the *relevance* is OURS | the measured receiver floor is 28,000× above Landauer | PARTIAL — proves a lower-bound equality, predicts nothing about the practical win/loss |
| A8 | thermodynamics direction | **no reversible/adiabatic recovery** (erasure-only) | DIRECT (Landauer statement) | LC-resonant reset recovers −0.225 pJ (measured) | PARTIAL — recovery ≠ erasure, so Landauer doesn't forbid it; the "no win" is not thermodynamic |
| A9 | fabrication direction (verdict) | **"no device" = "no *CMOS-PDK drop-in* today"** | DIRECT (survey) / the leap to "fundamental" is OURS | RTD/FeFET/IG-FinFET have native 3-state physics | YES as a *fundamental* claim — it's an availability statement, not a physics statement |
| A10 | circuit direction (verdict, "1.5–2×/bit") | **the 3-level noise-margin + 2-threshold cost is unavoidable** | the number itself is OURS/SPECULATION (`device_circuit.md` §7.2) | a direction receiver or a single-load-line tristable read | YES — it's a scaling argument, not a measurement |
| A11 | "null is meta-stable" (`polar_gates`, verdict) | **the gate uses a *level* receiver** (2 SAs vs 0 V) | DIRECT for that receiver / OURS as a general claim | diode direction receiver (comm cell already does it) | YES — meta-stability is a topology artifact, not a ternary fact |
| A12 | "2.54× receiver tax" (`gate_energy`, `device_physics`) | **2 sense amps is the minimum** | DIRECT (measured) / the *minimality* is OURS | a 1-decision receiver (rail-selection + passive arrival gate) | YES — 2 SAs is one topology's cost, not a lower bound |
| A13 | Law 1 "receiver is the invariant floor" | **the receiver cost is ~fixed / not shrinkable** | DIRECT (measured, 3×) / the *generality* is OURS | eval-window/tail-current trade (0.052 @1 ns vs 0.087 @2 ns) | PARTIAL — it's gauge-agnostic in V, not fundamental in absolute |
| A14 | Law 3 "3 wins because nearest e" | **radix-economy (digit count) and free-null (circuit artifact) are the same axis** | the two facts are each DIRECT; the *bundle* is OURS | any odd balanced radix has a free null (PWM-5 does) | YES — "nearest e" is a namespace fact, not an energy fact |
| A15 | architecture "cheap edge / converter collapses" | **the converter stays cheap because of the 2-wire no-drive-null encoding** | OURS / ANALOGY | a *true 3-level analog* wire ↔ binary re-introduces level synthesis (218 devices) | YES — flagged in `meta_critique` §3d, not resolved |

The numbered deep-dives below are the six the brief named **plus** the ones the brief
didn't (A2, A14, A15 are the highest-value finds beyond the prompt).

---

## 1. "Ternary beats binary per bit" — is *per bit* the right metric?

**The hidden assumption is not just the denominator; it's what the denominator smuggles in.**

Three normalizations are in play and they are *not* interchangeable:

| metric | ternary | binary | who wins |
|---|---|---|---|
| **per bit** (÷log₂3, ÷1) | 0.081 pJ/bit (champion) | 0.748 pJ/bit | ternary, 9.2× |
| **per wire** (bits/wire) | 1.585 bits/wire | 1 bit/wire | ternary, 1.585× (radix economy, DIRECT) |
| **per symbol** (namespace) | 3³² ≈ 1.85×10¹⁵ | 2³² ≈ 4.3×10⁹ | ternary, ~4×10⁵× (namespace) |
| **per joule of *work*** (energy-delay product) | L-bound at 48–100 Mtrit/s | 3–5 GHz CMOS | **not obviously ternary** |

**The load-bearing assumption:** bits/wire is the scarce resource, and the speed cost is
free. The 0.081 pJ/bit champion is **adiabatic** and is **L-bound at 48–100 Mtrit/s** —
`ENERGY_LAWS.md` says so itself ("speed is L-bound at 48–100 Mtrit/s (5–10× the adiabatic
tax)"). Per *joule of work done in a fixed time*, the win is a 9.2× energy saving bought for
a 5–10× latency penalty — which is roughly a wash to a 2× net win, not a 9.2× win.
`meta_critique.md` §3h already says this; it is **not** folded into the headline.

**Calibration: OURS.** "Per bit" is a legitimate metric for interconnect-limited links; it
is the *right* metric only if throughput is not the binding constraint. The corpus never
states an energy-delay-product target, so the "9.2×" is an energy-only figure of merit.

**What collapses:** the headline "9.2× better than binary" collapses to "energy-only, at
~1/5th the speed" — a real but *much* weaker claim. The *per-wire* (1.585×) and *per-symbol*
(namespace) wins are unaffected; they are radix-economy facts and are the honest core.

---

## 2. `ThresholdLowerBound.lean` — the uniform-per-threshold assumption

**The theorem is true; the conclusion is an analogy wearing a proof's clothes.**

The Lean file proves a pure calculus fact: `b ↦ (b−1)/ln b` is strictly increasing on
`(1,∞)`, so binary minimizes *thresholds-per-bit* and ternary is `2·ln2/ln3 ≈ 1.26×` worse.
**DIRECT, zero `sorry`.** But the physical sentence "therefore ternary compute cannot beat
binary per bit" depends on **two unstated premises the proof never states**:

1. **Energy is proportional to threshold-count, with *uniform* per-threshold cost.**
   The function `(b−1)/ln b` treats every additional threshold as costing the same as the
   first. A multi-threshold device **violates this by construction**: in a 2-peak RTD the
   second NDR "knee" is a band-structure feature, not a second, separately-paid comparator;
   in a CNTFET the second chirality threshold is a *chosen diameter*, not an added sense amp;
   in a FeFET the multiple thresholds live in one gate stack. The premise "each threshold
   costs uniformly" is exactly the CMOS 2-sense-amp topology — and `device_physics.md` §0.1
   itself describes the counterexample: a single load line crossing three stable I–V branches
   reads **three states in one bias point**, not `b−1 = 2` separate thresholding measurements.
2. **Resolution is `(b−1)` *ordered* thresholds.** `(b−1)/ln b` is the cost of an *ordered
   M-level quantizer* (a level-coded ADC front-end). The polar cell's receiver is **not**
   ordered level detection: `differential_noise.md` §3.3 establishes that push/pull are a
   *rail-selection* (direction) read, and the null is an *amplitude* read — the "b−1 ordered
   thresholds" model describes neither. The theorem's cost model and the measured receiver
   are different machines.

**Calibration:** the calculus is **DIRECT**; "energy ∝ (b−1) thresholds, uniformly" is
**ANALOGY** at best, **OURS** as the verdict uses it. The verdict table
(`TERNARY_COMPUTE_VERDICT.md`) lists the thresholds row as "**PROVED**
(`ThresholdLowerBound.lean`)" — the *math* is proved, the *energy conclusion* is not.

**What collapses:** "binary minimizes thresholds-per-bit ⇒ binary wins compute" **collapses
in any regime where a second threshold is cheap or a direction receiver reads 3 states in one
decision**. The theorem survives as a true statement about *ordered level-coded quantizers
with uniform thresholds*. It says nothing about RTD/FeFET tristable reads or diode receivers.

---

## 3. Landauer — the erasure floor and the "no reversible recovery" assumption

**The thermodynamics direction of the impossibility is a non-sequitur, and the measured
LC recovery demonstrates why.**

The argument (`device_physics.md` §5.1–5.2, verdict "thermodynamics" row) is:

```
(log_b N)·(k_B T ln b) = k_B T ln N   —  radix-independent
```

so erasing a trit costs `k_B T ln 3 = 1.585×` erasing a bit, "exactly cancelling the density
gain". **The arithmetic is DIRECT.** But the conclusion "no thermodynamic free lunch in base
3" depends on **three unstated premises**:

1. **Erasure is the cost that matters.** The measured receiver floor is **0.0865 pJ/trit =
   86.5 fJ**, which is **~28,000× above `k_B T ln 3 = 4.55 zJ`** (`optimization_ngram.md`
   §3.3 computes exactly this). Landauer is a *lower bound equality*, and it is **not the
   binding floor** — the receiver is. So the thermodynamics direction proves a fact about a
   regime the design doesn't live in. It predicts **nothing** about the measured loss
   (which is a measurement/SNR loss) and **nothing** about the measured win (which is a
   charge-moving + free-null win).
2. **No reversible/adiabatic recovery.** Landauer's `k_B T ln 2` is the floor for *erasing*
   information; it does **not** bound *reversible* switching or charge *recycling*. The
   corpus's own LC-resonant fair fight measured a **−0.225 pJ reset** — net energy *returned*
   to the power clock (`ENERGY_RESULTS.md` CORRECTION 2). That does **not** violate Landauer
   (recycling charge is not erasing a bit), but it **demonstrates the regime Landauer is
   silent about**, and it is exactly the regime where the "no per-bit win" argument was
   invoked. **The adiabatic lever is radix-agnostic** (`optimization_ngram.md` §2.3: binary
   gets the same tank), so it neither rescues ternary nor condemns it — but it means the
   thermodynamic argument cannot be used to *rule out* a win, because the win was never
   thermodynamic.
3. **The null-as-default reset is an erasure.** Implicitly, "returning a register to null"
   is an erase and therefore bounded by `k_B T ln 3`. But the measured null is **0.05 pJ =
   5×10⁴ zJ**, ~10⁴× above `k_B T ln 3` — so "the null is free" is a *relative-to-±1*
   engineering cheapness, not a thermodynamic erasure floor. The two claims ("null ≈ free"
   and "erasure ≥ k_B T ln 3") are **in tension** if either is read as fundamental; they only
   coexist because "free" means "0.05 pJ, 24× cheaper than a ±1 pulse", not "at the Landauer
   floor".

**Calibration:** the identity is **DIRECT**; "therefore ternary has no thermodynamic win"
is **OURS** and is over-claimed. The honest statement is: *Landauer proves ternary never
beats binary **at the erasure floor** — which nobody disputed and which is 28,000× below
the real floor.*

**What collapses:** the *relevance* of the thermodynamics direction collapses. The verdict's
"four directions all agree" is actually **three** directions that are load-bearing (thresholds,
fabrication, circuit — all circuit/measurement) plus **one** (thermodynamics) that is
decorative. If anything, the LC-recovery measurement *weakens* the "no per-bit win" case by
showing the binding cost is the receiver, which is a *circuit* object, not a thermodynamic one.

---

## 4. Fabrication — "no native device" assumes a CMOS PDK *today*

**The fabrication direction is a current-availability statement, presented as a fundamental one.**

`TERNARY_COMPUTE_VERDICT.md`'s fabrication row says "no drop-in native 3-state device: RTD=III-V,
SET=cryogenic, CNTFET≈15k ceiling; IG-FinFET is the lone lead but needs a load". The **hidden
assumption** is that "drop-in native 3-state device" means **"one transistor → three rail
voltages in a CMOS foundry PDK available today"**. Relax that in either direction and the
conclusion reverses:

- **Relax "today's CMOS PDK":** RTD has *native* 3 stable states (two NDR regions, `device_physics.md`
  §0.1, DIRECT), switches in **1.5 ps** (measured, cited) — but III-V and DC-hungry. SET has
  the cleanest *native discrete* states of anything in the survey (Coulomb ladder, DIRECT). The
  conclusion "no device" is only true for *fabricable-at-VLSI-today*.
- **Relax "must be a restoring transistor":** FeFET is the one device where "multiple thresholds
  in a *single* transistor" is **literally** true (HfO₂, CMOS-compatible, `device_literature.md`
  §2.8, DIRECT) — it is only held back by *maturity*, not physics. Independent-gate FinFET has
  **3 drive states in production today** (`device_literature.md` §2.5, DIRECT) — the survey ranks
  it the pragmatic front-runner.

**The verdict's own device survey contradicts the verdict's one-liner.** `device_literature.md`
concludes the closest *single-device* answers (RTD, SET, QCA, FeFET) are "non-CMOS or immature",
and the closest *production* answer (IG-FinFET) still needs a current→voltage load — but it does
**not** conclude "no device exists". It concludes "no device is a *drop-in one-transistor
three-rail-voltage* part **on a PDK today**". The verdict compresses that into "no drop-in
native 3-state device", which reads as a physics claim.

**Calibration:** the survey is **DIRECT**; the verdict's fabrication row is **DIRECT** only for
"no CMOS drop-in today", **OURS** for "therefore no fundamental win".

**What collapses:** "fabrication kills ternary" collapses to "fabrication kills ternary *on
existing CMOS PDKs, this year*". A FeFET or IG-FinFET restoring inverter would overturn it.
The direction is load-bearing only for a *near-term go/no-go*, not for the thesis.

---

## 5. "Null is meta-stable" — the level-receiver assumption (and the diode that removes it)

**The meta-stability result is a property of *one receiver topology*, not of the null or of ternary.**

`polar_gates.md`'s finding — a held-null input lifts E_gate 2.3–3.1× (shoot-through, ~1.9 pJ/toggle,
kickback ~0.18 V) — is the backbone of "the null is free on the wire, not in the gate". The
**hidden assumption** is that the gate must read the trit as **a voltage level sampled against 0 V**
(two clocked sense amps). Under that receiver the null sits *exactly on the threshold* — a saddle.

But the transport cell (`tcell4`) already uses a **different receiver** — a diode/rectifier pair
— and `differential_noise.md` §3.2–3.3 spells out what changes:

- With a **direction (diode) receiver**, the null is **"neither rail charged"**, a state a full
  diode-drop (`VTO ≈ 0.3 V`) *below* both trip points — a **dead zone**, not a saddle. The diode
  drop gives the null a dead-band *comparable to or better than* the naive `V_swing/4` margin
  (`differential_noise.md` §3.2, DIRECT reading of the netlist).
- The direction read "which rail charged?" is a **rail-selection** decision, not a 2-threshold
  voltage comparison — the outer symbols live on *different rails*, maximally separated in the
  direction axis (§3.3).

`null_default.md` §3.2–3.3 turns this into the design claim: dead-zone trip points ±V_th +
data-gated sense amp ⇒ the null never fires a comparator. **That is OURS/SPECULATION — it is
*unmeasured* for the gate.** The point for *this* file: the "null is meta-stable" conclusion is
**load-bearing on "the gate uses a level receiver"**, which is a design choice, not a law. The
comm cell proves the diode receiver makes null free *on the wire* (0.05 pJ, DIRECT); whether the
gate can inherit it is the open question, and the verdict's confident "null is not free in the
gate" over-states an unmeasured claim.

**Calibration:** the shoot-through measurement is **DIRECT** (for the 2-level-MOSFET level
receiver); "therefore the null is *intrinsically* meta-stable in any gate" is **OURS** and
**violated by a direction receiver** (demonstrated in transport, SPECULATION for compute).

**What collapses:** "null meta-stability kills null-as-default compute" collapses. It survives
as "null meta-stability kills the *2-sense-amp level-sampler* gate" — which is what was actually
measured. The diode/direction receiver is the single most concrete mechanism in the whole corpus
that could make the gate's null ≈ the wire's null, and it is **untested** in the gate.

---

## 6. The "2.54× receiver tax" — is 2 sense amps the minimum?

**The 2.54× is a measured cost of one topology, presented as near a lower bound.**

`gate_energy.md` measured the ternary idle-wire sense amp "stays balanced for the whole eval and
draws more than a cleanly-latching amp, so 2 amps cost 2.54×, not 2×". `device_physics.md` §2.3
and Law 1 then generalize this into "resolving 3 levels = 2 thresholds = 2 comparators", a cost
that "exceeds the entire radix-economy gain before any gate logic". The **hidden assumption**:
**two sense amps is the minimum receiver for 3 states.**

It is not, in three ways the corpus already contains:

1. **A direction receiver reads 3 states with ~1 decision + 1 amplitude gate.** The diode pair
   reads push/pull by rail *selection* (one direction decision) and null by "neither rail charged"
   — `null_default.md` §3.2.3 makes the amplitude gate *passive and free* (a charge detector that
   arms the SA only on arrival). That is a **1-decision receiver**, not a 2-threshold one. It is
   OURS/SPECULATION for the gate, but it is the *transport* cell's actual receiver, so it is not
   hypothetical hardware.
2. **The 2.54× ratio is a ratio of two specific designs**, not a radix invariant. The binary
   reference (1 SA, 24.35 fJ) is itself an un-optimized baseline; `receiver_cheap.md` shows the
   ternary SA can be (partially) tuned, and every redesign measured *worse* — but "worse for *that*
   SA" ≠ "2 is the floor".
3. **The "2-threshold tax" is the same ordered-quantizer assumption as §2.** `ThresholdLowerBound.lean`
   formalizes `(b−1)` thresholds; the diode receiver is not an ordered quantizer. The 2.54× is a
   *measured instance* of the ordered model, not a proof of it.

**Calibration:** 2.54× is **DIRECT** (measured); "2 sense amps is the minimum, hence a
radix-invariant receiver tax" is **OURS**, and **violated by a 1-decision diode receiver**.

**What collapses:** "the 2-threshold tax exceeds the radix-economy gain" collapses as a *general*
law; it survives as a *measured* fact about the level-sampler gate. The go/no-go criterion the
whole program uses — "resolve 3 states in <2 measurements, or free the null in-gate" —
(`meta_critique.md` §1) is exactly right, and this file's job is to note that the direction
receiver is the **one known candidate that satisfies it**, left unmeasured.

---

## 7. Findings beyond the brief (the ones it didn't ask about)

### 7.1 The binary baseline is a ±1 V *bipolar* 2 V swing — the biggest hidden assumption in the transport win

`test_suite_spec.md` §3.1 states it in the open but the headline ignores it: the fair-fight
convention runs **binary on ±VDD = ±1.0 V** ("the 'share the rails' convention, *generous to
ternary because binary's natural swing is 1 V not 2 V*"). So **binary 0.748 pJ/bit is the cost
of a 2 V bipolar link**, not a single-ended 0→VDD CMOS bit. The spec's own TODO (§"binary floor
references") says a **single-ended 0–1 V binary reference is "~2× cheaper" and "would move every
verdict further against ternary"**.

**This is load-bearing for the entire leaderboard.** The 9.2× / 8.1× / 1.86× / 1.45× "vs binary"
columns are all against a 2×-handicapped binary. Against honest single-ended binary, the transport
win is ~2–4×, PAM-4 is a near-tie, and ternary's uniform 0.515 pJ/bit may *lose*. **Calibration:
DIRECT** (the convention is on the record). This is the single most important correction to the
headline, and it is nowhere near the headline.

### 7.2 The "3 is nearest e" argument bundles two independent facts

Law 3 (`ENERGY_LAWS.md`) says "two independent reasons point at 3": (a) radix economy `3/ln3 < 2/ln2`
(DIRECT, `RadixEconomy.lean`/`RadixMin.lean`), and (b) "3 is the smallest odd radix so it has a
free middle digit — the null". **These are not the same axis and only weakly reinforce each other.**

- (a) is a **digit-count / namespace** fact. It says *nothing* about energy. `ENERGY_LAWS.md`
  itself admits this ("the explosion of states buys *namespace*, not *energy*").
- (b) is a **circuit fact** about the balanced, return-to-zero, AC-polarity encoding: the center
  symbol costs ~nothing because it is an *absence*. This is true for **any odd balanced radix** —
  PWM-5 (radix 5) has a null too, and it ties PAM-4 (`ENERGY_RESULTS.md`). The "free middle digit"
  is **not** a consequence of being nearest e; it is a consequence of *balanced symmetric
  return-to-zero*, and its *fraction* (null = 1/3 of symbols) is *maximized* at radix 3 only
  because higher odd radices dilute the null (1/5, 1/7, …). That dilution argument is real but it
  is "smallest odd radix", **not** "nearest e".

**Calibration:** each half is DIRECT; the bundle "nearest e ⇒ free null ⇒ energy win" is **OURS**
and is a conflation. The energy win is the free null (radix-agnostic, strongest at 3); "nearest e"
is the namespace win. Two different wins sharing a digit by coincidence.

### 7.3 The "cheap edge / converter collapses" assumption

The architecture "ternary wire + binary gate + converters" claims the converter "collapses to a
truth-table composition" ("9.5%-of-CPU converter"). This is **load-bearing on the 2-wire one-hot
encoding** (`01/00/10`, no-drive null), where `converters.md` measured the cheap ~9.5% bridge.
`meta_critique.md` §3d flags the hole: a **true 3-level analog wire** (the thing the *native
device* produces) ↔ binary is the **218-device level-synthesis** problem, *not* the cheap one-hot
bridge. The verdict carries the cheap number forward into the native-device architecture without
re-costing it. **Calibration: OURS/ANALOGY.** This is a silent $2×+$ system cost for any *native*
ternary core.

### 7.4 The "receiver is invariant" (Law 1) is gauge-agnostic, not irreducible

Law 1's measured fact (receiver share 13%→61%→67% as swing drops) is **DIRECT** and correct: the
receiver doesn't shrink with V. But the *conclusion* — "the ultimate energy floor is the cost of
extracting information" — smuggles in **"the receiver can't be made cheaper"**, which the same
corpus contradicts: the receiver is **0.052 pJ/trit at 1 ns eval vs 0.0865 pJ at 2 ns** (a
resolution-time trade, `optimization_ngram.md` §3.3), and `receiver_cheap.md` is literally the
open lever. "Gauge-agnostic in V" ≠ "absolute floor". **Calibration:** the measurement DIRECT,
the "floor" OURs.

---

## 8. Which conclusions survive, and which collapse

**Survive intact (the honest core):**

- Radix economy `3/ln3 < 2/ln2`, `b/lnb` minimized at e — a *digit-count* fact (DIRECT, Lean).
- Landauer `k_B T ln N` is radix-independent — a *lower-bound equality* (DIRECT).
- Ternary per-*wire* (1.585 bits/wire) and per-*symbol* (namespace) density beats binary (DIRECT).
- `ThresholdLowerBound.lean`'s calculus: binary minimizes *ordered, uniform-cost* thresholds/bit (DIRECT).
- The measured fact that a **2-level-MOSFET level-sampler** ternary gate loses 4.9–14.3×/bit (DIRECT).
- The null is free *on the wire* (0.05 pJ) with a diode receiver (DIRECT, measured).
- The LC-resonant recovery is real (−0.225 pJ reset) and the slow-ramp driver is dead (DIRECT, measured).

**Collapse as stated (over-claimed):**

- "Ternary transport wins 9.2×" → collapses to "wins ~2–4× vs *single-ended* binary, energy-only,
  at 5–10× the latency" (A1+A2+A4).
- "Ternary compute has no *fundamental* win, four directions agree" → collapses to "no win on
  *today's CMOS PDK with a level receiver*" (A5–A10); the thermodynamics direction is decorative.
- "The null is not free in the gate" → collapses to "not free in the *2-sense-amp level sampler*;
  a diode direction receiver is the untested counterexample" (A11).
- "The 2.54× receiver tax is a radix law" → collapses to "a measured topology cost" (A12).
- "3 wins because nearest e" → collapses to "3 wins namespace by being nearest e, and wins energy
  by having the *free null* of a balanced return-to-zero cell — two separate wins" (A14).

**The uncomfortable symmetry:** the *win* and the *loss* lean on **opposite, mutually
inconsistent premises**. The win assumes null-frequent-and-free + a handicapped binary baseline +
no device mismatch. The loss assumes uniform-per-threshold cost + a level-coded receiver + CMOS
today. **A direction receiver (diode) and a multi-threshold device (RTD/FeFET) each violate the
loss's premises; a single-ended binary baseline and real silicon offsets each violate the win's.**
The corpus has not yet run the one experiment that would arbitrate: *the direction-receiver gate
and the multi-threshold device, against a single-ended binary baseline, with device mismatch on.*

---

## 9. The calibration ledger (this file's own claims)

| claim in this file | calibration |
|---|---|
| binary baseline is ±1 V bipolar, ~2× natural swing | **DIRECT** — `test_suite_spec.md` §3.1 + its own TODO |
| "9.2×" is energy-only at 48–100 Mtrit/s (L-bound) | **DIRECT** — `ENERGY_LAWS.md` caveats |
| uniform-per-threshold cost is assumed by `ThresholdLowerBound` | **DIRECT** (reading the file) / the *violation* by RTD/FeFET is **DIRECT** (`device_physics.md` §0.1, `device_literature.md` §2.8) |
| the (b−1)-threshold model ≠ the diode receiver | **OURS/ANALOGY** — `differential_noise.md` §3.3 |
| Landauer is 28,000× below the measured floor | **DIRECT** — `optimization_ngram.md` §3.3 arithmetic |
| LC recovery doesn't violate Landauer (recycle ≠ erase) | **DIRECT** — standard; **OURS** as applied here |
| "no native device" = "no CMOS PDK today" | **OURS** (reading the verdict against its own survey) |
| direction receiver removes null meta-stability (gate, unmeasured) | **SPECULATION** — `null_default.md`; the *wire* instance is **DIRECT** |
| 2 sense amps is not a proven minimum | **OURS** — 1-decision receiver candidate exists (diode) |
| "nearest e" and "free null" are independent | **OURS** — each half DIRECT |
| converter cost for a *true 3-level* wire is un-costed | **OURS/ANALOGY** — `meta_critique.md` §3d |

---

## TODO / not covered / caveats

**The one experiment that would settle most of this (do it before another doc):**

1. **Single-ended binary control.** Re-run the fair fight with binary on a 0→1 V (1 V) swing,
   not ±1 V. Every "N× vs binary" number re-computed against it. This is the single cheapest,
   highest-leverage correction to the whole leaderboard and it is *already specced* in
   `test_suite_spec.md`'s TODO but never run.
2. **The direction-receiver *gate*.** `null_default.md` §3 is a design, not a netlist. Build
   `circuit/null_default.cir` (dead-zone ±V_th + data-gated SA) and measure whether the gate's
   null lands at the comm cell's 0.05 pJ and whether the meta-stability is actually gone. This is
   the one thing that would directly overturn A11/A12 and part of A5/A6.
3. **A multi-threshold device compact model.** The uniform-threshold assumption (A5) can only be
   tested once an RTD/FeFET/IG-FinFET model exists; until then `ThresholdLowerBound.lean`'s energy
   reading is an analogy. `test_suite_spec.md` §1 is the blocker.
4. **Energy-delay product target.** State a speed floor before any "win" is declared (A1). The
   corpus's own adiabatic tax (5–10×) is the number to fold in.
5. **Real-offset re-run.** The 0.081 pJ/bit champion is a LEVEL=1 no-mismatch number; the
   corpus's own σ≈5–20 mV estimate moves the floor to 0.22–0.35 pJ/bit. The headline should carry
   that range, not the LEVEL=1 point.
6. **Null-frequency on real workloads.** The transport win is conditional on null-heavy data
   (A3); measure the trit distribution of an actual workload (Zipf/null-dominated vs uniform)
   before quoting 9.2×. `ZipfEnergy.lean` proves the algebra; the *empirical* distribution is
   unmeasured.
7. **Native-interface re-cost.** The "cheap converter" is the 2-wire one-hot number; a true
   3-level analog wire pays level synthesis (A15). Cost it before the hybrid architecture claims
   a cheap edge.

**Caveats on this critique itself:**

- **I measured nothing.** Every number is from the existing `docs/`, `circuit/`, `proofs/`
  corpus. The claims "the diode receiver is a 1-decision read" and "a multi-threshold device's
  2nd threshold is ~free" are *mechanism* readings, not measurements — they are the experiments
  items 2 and 3 above, and I have flagged them SPECULATION/OURS accordingly.
- **I assume the corpus's two standing gate verdicts are both right.** `meta_critique.md` itself
  flags this: `polar_gates.md`'s "native is 20–44× worse than emulation" and `gate_area.md`'s
  "2.00–4.33×" must be reconciled before "B2 already lost" is trusted, and this file's §8
  (which conclusions collapse) inherits that dependency.
- **The single strongest lever in the whole corpus — the diode direction receiver — is also the
  single least-tested.** It is demonstrated *on the wire* (DIRECT) and conjectured *for the gate*
  (SPECULATION). Any honest ranking of "what to run next" puts it first, ahead of another device
  survey or another Lean theorem.
- **I do not claim the win is real or the loss is false.** I claim only that *both* are load-
  bearing on premises the corpus has not tested, and that the premises on the loss side are the
  ones real hardware (diode, multi-threshold, adiabatic) is already known to violate.

*This file invents no numbers and runs no netlists; it is a calibration pass over the existing
corpus. The TODO list above is the next batch's feedback loop, and item 1 (single-ended binary)
is the cheapest way to find out whether the "9.2×" headline survives contact with a fair binary.*
