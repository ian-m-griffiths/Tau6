# Optimization n-gram — V/I/R tradeoffs & natural adiabatic artifacts of a native 3-state device

**2026-08-29 — Batch 1, item 7 of `docs/TERNARY_GROUND_UP.md` ("Optimization — V, I, R,
and the natural adiabatic artifacts of the native device").**

**Calibration legend (house standard, `docs/MAP_BRIEF.md`):**

- **DIRECT** — measured or proved (our ngspice/yosys/Lean numbers, or a citable textbook/literature fact).
- **ANALOGY** — parallel structure to something real, but the mapping is not an identity.
- **OURS** — our own design claim, carried from project files.
- **SPECULATION** — untested hypothesis, flagged as such.

**One-line answer up front:** every number we *have* is for a **2-level MOSFET** cell, not a
native 3-state device — the native device is unbuilt and unmeasured, so this file's V/I/R map
is **DIRECT on the measured CMOS cell + first-principles physics**, and **SPECULATION where it
crosses into the native device**. The three laws (`docs/ENERGY_LAWS.md`) already give the
partial derivatives of the n-gram: **Law 1** makes the receiver (measurement) a fixed cost
gauge-agnostic in V; **Law 2** makes the cheap direction of the (V,t) plane the
**anti-diagonal** (down in I, up in t) because the loss is **I²R**; **Law 3** says 3 is the
radix that buys the most bits per symbol. The native device changes *which terms are free
parameters* (V stops being a dial you turn and becomes a material property), but it does **not**
change the two things that actually set the floor: the measurement (receiver) cost and the
I²R resistive cost.

---

## 0. What "native 3-state device" means here, and what is NOT measured

`TERNARY_GROUND_UP.md` states the premise bluntly: *"the native 3-state device was never
built."* Every measured number in `circuit/ENERGY_RESULTS.md`, `docs/ENERGY_LAWS.md`,
`docs/compute/gate_energy.md`, `docs/compute/polar_gates.md`, and `docs/compute/receiver_cheap.md`
is a **2-level MOSFET** (ngspice LEVEL=1, sky130 binary standard cells) driving a
**voltage-mode ternary wire** (push = +V, null = 0, pull = −V) through a diode/MOSFET-rectifier
receiver and (in the adiabatic rows) an LC tank.

A **native** 3-state device (RTD/NDR, multi-threshold CNTFET, SET, memristor, multi-gate
FinFET 3-point) is the search *target* (items 1–5 of `TERNARY_GROUND_UP.md`). The distinction
matters for the whole n-gram:

- **In the measured cell, V is a free parameter** you dial down (low-swing: `VDDR` 1.0 → 0.65 →
  0.20 V in `lowswing_sweep.cir`). The three states are *chosen by the rail voltage you drive*.
- **In a native device, V is a material property** — the state spacing is set by the physics
  (RTD peak-to-valley voltages, CNTFET threshold spacing by chirality, SET Coulomb-blockade
  gap), not by a bias you tune per-cycle. The V-optimization problem therefore *moves from
  circuit biasing to device engineering*. **[SPECULATION — no native device measured]**

This reframing is the single most important structural result of the n-gram: **the measured
low-swing lever (∝V²) does not port verbatim to a native device**, because in a native device
the state spacing is not a knob.

---

## 1. The V/I/R map

The energy of one transition decomposes as (all terms measured in `circuit/ENERGY_RESULTS.md`
unless noted):

```
E_transition ≈ ½·C·V²          (line charge, ∝ V² — the only term the encoding "should" pay)
             + (Vrail−Vline)·I·t  (driver channel loss, the I·V·t term)
             + I²·R·t            (wire + diode-leg resistive loss, ∝ I²)
             + Vf·Q              (diode/rectifier forward drop, fixed per charge packet)
             + E_rec             (receiver/measurement, ~fixed per symbol — Law 1)
```

The three laws map onto these terms one-for-one.

### 1.1 V (the swing): 3 levels vs 2

**DIRECT (measured, `lowswing_sweep.cir` + `ENERGY_RESULTS.md`).** Wire energy falls ∝V²:
the fair-fight ternary link goes 0.816 → 0.145 pJ/trit as `VDDR` falls 1.00 → 0.65 V, bottoming
at **0.092 pJ/bit** (SA receiver, 1 ns eval). The V² law is confirmed; the *minimum* is set not
by V² but by two V-floors:

1. **The device Vt wall** — with `VTO=0.4` drivers the push is physically dead below
   `VDDR ≈ 0.5 V` (`Vov ≤ 0.1`, LEVEL=1 hard cutoff). Reaching lower swings needs VT-engineered
   drivers, and even those die at 0.10 V.
2. **The receiver resolution cliff** — the sense amp resolves down to rail ≈ 20 mV (OK at
   22 mV, marginal at 14 mV, ±4 mV null baseline). Below that, the swing doesn't resolve.

**3 levels vs 2 (the swing accounting).** Ternary's two non-null states sit at ±V (a full
**2V** bipolar swing for a +1↔−1 flip), while binary single-ended sits at 0→V (a **1V**
swing). But ternary's third state is **null = 0**, which costs **~0.05 pJ** (DIRECT measured —
and that 0.05 is rail-equalization/keeper cost, not a drive cost). Uniform-average: ternary
(1.20 + 1.20 + 0.05)/3 = 0.817 pJ/trit = **0.515 pJ/bit**, vs binary **0.748**. Ternary wins
*on average* **only because the null is free and data-bearing** — the ±1 trits are each
*more* expensive than a binary bit (1.2 pJ vs 0.75 pJ). **[DIRECT]**

**The native-device version.** In a native device the swing is the device's own state spacing
(RTD valley-to-valley, CNTFET threshold gap), and the *noise margin* is the spacing *between*
device states, not a rail you can lower. The low-swing ∝V² lever becomes a **device-parameter
lever** (tune the heterostructure / chirality / gate count), with the same two floors relocated:
a native device still needs its state spacing to exceed the *receiver's* resolution, and its
own "on" overdrive to exceed its own threshold. **[SPECULATION]**

### 1.2 I (the current): I²R is the loss, not V²

**DIRECT (measured, Law 2 + `pwm5_2d.cir`).** The mechanism of the (V,t) plane is **I²R**:
`E_drv ≈ VDD·Q`, so equal detectability ≈ equal charge ≈ equal energy — but a short pulse crams
the same charge into less time → higher peak current → more I²R in the 100 Ω wire and the diode
legs. The measured win is the **long-LOW vs short-HIGH** corner: at equal rail detectability
the long-low symbol is **~14% cheaper** (0.967 vs 1.130 pJ) — and at equal *area* (the toy
V·t metric) it's a wash. The V² model predicts the *direction* (time is the cheaper axis) but
not the magnitude; the real term is `Q²R/t`, which falls as t grows. **[DIRECT]**

Consequence for the n-gram: **I is the enemy, t is the friend, at fixed Q.** This is radix-
independent — it applies identically to binary and ternary. Ternary's only I-specific wrinkle
is that a ±1 flip moves **2V of charge** (vs binary's 1V), so at equal swing a ternary flip
pays ~2× the I²R of a binary flip. **[OURS — follows from the bipolar encoding]**

**The native-device version.** I becomes the device's switching current (RTD peak current
`Ip`, CNTFET drive current). A native device whose switching current is low *at the same
resolved state spacing* wins the I²R term directly. The measured `N=4` parallel-MOSFET-diode
win (**0.562 pJ**, best fast charge-transfer) is the Ron÷N lever applied to the rectifier; in
a native device the analogous lever is **paralleling device channels** to cut Ron. **[ANALOGY —
rectifier paralleling → native-device channel paralleling]**

### 1.3 R (the resistance): Ron of the diode/driver channel

**DIRECT (measured + `circuit/PHYSICAL_NOTES.md`).** The receiver's forward/pull legs should be
**MOSFET rectifiers** (diode-connected MOSFET, or synchronous rectifier), optionally **paralleled
for `R_on/N`** — not junction diodes, which have negative temperature coefficient and
thermal-runaway under paralleling. Measured: N=4 paralleled MOSFET-diodes = **0.562 pJ** (best
fast regime); the ~60% resistor-drop term and ~26% diode-`Vf` term in the original 5.36 pJ
baseline are *both* attacked by this swap. **[DIRECT]**

R enters the energy **twice**: as `I²R·t` (resistive heating, shrinks with Ron) and as the
**Vf·Q** term of the rectifier drop (a fixed cost per charge packet, does *not* shrink with Ron).
Lowering Ron helps the first term; only a lower-drop device (Schottky-like, or a synchronous
rectifier that replaces the diode with a switch) helps the second. **[DIRECT]**

**The native-device version.** Ron is the device's own on-resistance (RTD series resistance,
CNTFET channel resistance) plus its contact/series parasitics. This is the one lever that
ports *cleanly*: whatever the device, Ron is a material/geometry parameter and lower Ron → lower
I²R, with no encoding penalty. **[ANALOGY]**

### 1.4 The n-gram as a coupled tuple

The optimization space is the tuple **(V, I, R, t)** coupled by the three laws:

| axis | what it buys | what it costs | law | calibration |
|---|---|---|---|---|
| **V ↓** | wire energy ∝V² | noise margin, device overdrive | Law 1 (receiver gauge-agnostic: V↓ leaves receiver standing) | DIRECT |
| **I ↓** | I²R loss ∝I² | must keep Q=∫I dt for detectability → t ↑ | Law 2 (the I²R diagonal) | DIRECT |
| **t ↑** | resistive loss ∝ 1/t | speed (5–10× adiabatic tax) | Law 2 (anti-diagonal) | DIRECT |
| **R ↓** | I²R loss ∝R, Ron/N paralleling | device area, capacitance | — | DIRECT |
| **radix 3** | 1.585 bits/symbol (density) | 2 thresholds vs 1 (receiver tax 2.54×) | Law 3 (nearest e) | DIRECT |

The measured champion (**0.081 pJ/bit**, `lowswing_resonant.cir` case B1) is the point where
**V ↓ (0.28 V rail)** and **R/Z0 ↓ (LC tank recovery)** compose, and what remains is the
**receiver** (~0.0865 pJ/trit, 2/3 of the total). **[DIRECT]**

---

## 2. The adiabatic analysis — "natural adiabatic artifacts"

### 2.1 What "adiabatic" means and what was actually measured

Adiabatic charging theory: ramping a line through its resistance R with ramp time T dissipates
`E ≈ (RC/T)·½CV²`, so **E → 0 as T → ∞** — there is **no CV² floor** for *charging*; the floor
is set by how slow you're willing to be, and by the receiver. **[DIRECT — `ENERGY_IDEAS.md` §1.4,
with the TUM/Zyvex citations]**

What the fair-fight harness measured (`ternary_adiabatic_fairfight.cir` + `lowswing_resonant.cir`):

1. **The slow-ramp driver is DEAD.** A real FET generating the ramp burns `(Vrail−Vline)·I` for
   the *whole* ramp (channel loss 1.3–3 pJ/phase), and a fixed DC rail never accepts the
   "returned" charge. Result: **2.5–2.6 pJ/trit — ~2× worse than even the non-adiabatic
   fair fight (1.20 pJ)**. The earlier 0.165–0.30 pJ "adiabatic win" was ~90–95% ideal-source
   flattery. **[DIRECT]**
2. **The LC-resonant scheme SURVIVES.** Real half-bridge switches + real receiver: **0.210 pJ/trit
   (L=40 µH) / 0.266 pJ/trit (L=9.4 µH)** = 0.13–0.17 pJ/bit; the reset phase **recovers −0.225 pJ
   (measured)** — the ring energy genuinely oscillates in the LC tank and only the R/Z0 loss
   escapes. **[DIRECT]**
3. **The two levers compose.** Low-swing × LC-resonant (B1): driver-only **0.041 pJ/trit =
   0.026 pJ/bit**, reset still **recovers −0.069 pJ** at low swing, and the recovery *fraction*
   of the push **improves** at low swing (A1 returns 29% vs full-swing's 9.5%). **[DIRECT]**

### 2.2 Does a native 3-state device have a *natural* charge-recovery path (like the LC tank)?

**Honest answer: the LC tank is NOT native to the 3-level structure — it is a circuit-level
reactance that any voltage-mode line can use, binary included.** The ternary cell gets to use
it because the cell is voltage-mode (push/pull/null on a wire with a line capacitance `C_line`
and a power clock that accepts the return). There is nothing 3-state-specific about the tank.
**[DIRECT — the mechanism in `lowswing_resonant.cir` is radix-agnostic]**

A **native** 3-state device has a *different* "natural artifact", and it is **not** adiabatic:

- **NDR latching (RTD).** An RTD switches by crossing the negative-differential-resistance
  region — a positive-feedback *snap* (fold catastrophe), not a reversible charge shuttle. The
  stored charge on the device's own capacitance is **dissipated** on each switch; an RTD
  relaxation oscillator is the opposite of a resonant tank. RTD/NDR logic families (e.g. MOBILE,
  monostable-bistable transition logic elements) are fast and low-*voltage*, but they are
  **dissipative latch elements, not charge-recovery elements**. **[DIRECT — standard NDR device
  physics; MOBILE = US6316965; reconfigurable RTD logic = IEEE reconfigurable-RTD survey]**
- **The one genuinely "adiabatic-like" artifact of 3 states is the null-as-rest, not the
  device.** If the third state is the *true rest state* (0 V, 0 current, off), then idle
  dissipates nothing, and the act of "returning to null" *releases* the stored charge — which
  is exactly the charge a recovery scheme (tank, or charge-recycling bus) would reclaim. So
  **null-as-default and adiabatic recovery are complementary, not the same thing**: the tank is
  the *recovery mechanism*, null is the *"nothing to recover when idle"* state. **[OURS]**

### 2.3 How the 3-level structure changes the adiabatic picture

Three separate effects, none of which makes charging itself more adiabatic:

1. **Adiabatic charging is radix-independent.** `E ≈ (RC/T)·½CV² → 0` does not know how many
   levels the line carries. The 3-level structure neither helps nor hurts the per-event
   reversibility. **[DIRECT]**
2. **3-level changes the *activity* (number of charge events).** Ternary flips less often per
   bit: 0.42 symbol-changes/bit (vs 0.5) and 0.32 flips/bit in the hold-on-null model
   (`ENERGY_IDEAS.md` §1.8/1.9). Adiabatic reduces the *cost per event*; ternary reduces the
   *count of events*. They multiply on **different terms**. **[DIRECT math + ANALOGY]**
3. **But the ternary flip is a 2V swing.** A non-recycled +1↔−1 flip costs ~2·C·V² vs binary's
   C·V². **Recovery is not optional for ternary — it is the mechanism that turns "3 states"
   into a win.** The measured recycling (`ecyc2` halves at baseline, goes **negative** in
   charge-transfer mode) is the evidence. **[DIRECT — `ENERGY_IDEAS.md` §1.9 table]**

Net: the honest adiabatic picture for 3-level is **"fewer, recoverable 2V events"**, not
**"more-reversible 3-level charging"**. The measured 0.081 pJ/bit is exactly that composition.

### 2.4 The null-as-default interaction (idle at 0 current)

If null = 0 V = off, then the V/I/R optimization gets a **free idle**:

- **Idle at 0 current → no static I²R, no DC shorts.** Measured quiet-window energies are
  **< 1 fJ** (`gate_energy.md`) and **< 11 aJ** (`polar_gates.md`) — the gates burn energy only
  when they toggle. **[DIRECT]**
- **Power only on push/pull** (Ian's rule, `TERNARY_GROUND_UP.md` item 6). The resting V=0 lets
  the driver be *fully off* (no leakage if the device's off-state is a true off-state). This is
  the structural reason the null is ~0.05 pJ (24× cheaper than a ±1). **[OURS + DIRECT]**

**The critical honest caveat (the whole point of `polar_gates.md`):** null = 0 V is **free on
the wire, expensive in the gate.** A gate must *resolve* −1/0/+1 every cycle, and a held-null
input sits **exactly on the sense amp's threshold** → continuous shoot-through current, kickback
(~0.18 V into the high-impedance null), and false "push" latches. Binary never sits on a
threshold. **[DIRECT — measured, `polar_gates.md` §"The null is the wall"]**

**The native-device hope this exposes:** a device that *natively* thresholds 3 states resolves
the null **without sitting on a meta-stable saddle** — e.g. an NDR device whose 3 states are
three *stable fixed points* (two wells + the origin), so a null input is a *stable* state, not
a saddle. Whether any candidate device actually delivers that is **the** untested question of
the whole search. **[SPECULATION]**

---

## 3. The honest energy floor

### 3.1 Landauer — the erasure floor (and a unit correction)

Landauer's principle: erasing one bit dissipates ≥ **kT ln 2**. At T = 300 K:

```
kT = 4.142 × 10⁻²¹ J ;  kT ln 2 = 2.87 × 10⁻²¹ J = 2.87 zJ ≈ 18 meV
```

**≈ 2.9 zJ/bit (zeptojoule), i.e. 0.0029 fJ/bit.** **[DIRECT — textbook; verified against the
ar5iv Landauer-limit reference]**

> ⚠️ **Correction to a source.** `ENERGY_IDEAS.md` §2.1 writes "kT·ln2 ≈ 2.9 **aJ**/bit". That
> is a 1000× unit error: `aJ` = 10⁻¹⁸ J, but kT ln 2 = 2.87 × 10⁻²¹ J = 2.87 **zJ**
> (10⁻²¹ J). The correct number is **2.9 zJ**, not 2.9 aJ. This does not change any conclusion
> (it moves the floor *lower* by 3 orders of magnitude), but the source's own "2.9 aJ" is wrong
> as written.

### 3.2 Multi-level: does 3-state lower the floor? No.

The thermodynamic floors are **radix-independent**:

- **Landauer** is per **bit** erased, `kT ln 2`. Erasing a *trit* (1.585 bits) costs
  `kT ln 3 ≈ 4.55 zJ` — the **same per-bit** floor. Multi-level does **not** lower the per-bit
  erasure cost. **[DIRECT]**
- **Shannon / Shannon–von Neumann–Landauer:** the minimum received energy per reliably
  transmitted bit is `E_b/N_0 ≥ ln 2` (= −1.59 dB), i.e. `kT ln 2` per bit. Also radix-
  independent. **[DIRECT]**

The **radix economy** (`3/ln3 < 2/ln2`, Law 3) is about **representational** efficiency — fewer
symbols per bit of *namespace* — **not** about the thermodynamic floor. Law 3's own language
says it: the extra states buy *namespace*, not *joules*. **[DIRECT — `RadixEconomy.lean` +
`ENERGY_LAWS.md` Law 3 consequence]**

Where multi-level *does* move a real number is the **practical** regime, where energy is
dominated by CV² charging + amplitude quantization + receiver thresholds — and there the trade
is measured: PAM-4 (0.401 pJ/bit) beats ternary (0.515), but the 8-level extrapolation
(~0.33 pJ/bit) is only 17% better while **halving** the noise margin and making the receiver
(7 comparators) dominant. **"PAM-4 is near the sweet spot; comparator count and noise margin
are the walls."** **[DIRECT — `ENERGY_RESULTS.md` PAM-4 section]**

### 3.3 The floor ladder (the honest minimum per gate-switch)

| floor | value | binding? | calibration |
|---|---|---|---|
| Landauer (erasure) | **2.9 zJ/bit** (kT ln 2) | not for transport/measurement | DIRECT |
| Shannon E_b/N_0 | **2.9 zJ/bit** (ln 2) | not at practical SNR | DIRECT |
| adiabatic charging | **no CV² floor** (→0 as T→∞) | floor = time + receiver | DIRECT |
| measured receiver (2 ns eval) | **0.0865 pJ/trit** | **the binding wall** | DIRECT (measured) |
| measured receiver (1 ns eval) | 0.052 pJ/trit | alternate wall | DIRECT (measured) |
| **measured champion** | **0.081 pJ/bit** | current best | DIRECT (measured) |
| native 3-state device | **unknown** | the open question | SPECULATION |

The measured champion is **~28,000× above Landauer** (0.081 pJ = 81 fJ = 81,000 zJ vs 2.9 zJ).
So Landauer is **not** the honest floor for this device class — the **receiver (measurement)
floor** is, exactly as Law 1 predicts. The receiver's 0.0865 pJ/trit decomposes to
`(#SAs=2) × (tail current ≈ 30 µA) × (eval 2 ns) × (1.0 V)`, and every tested redesign makes it
worse (wider input pair +7.5–17%, more amps +67–135%, low-Vt +13–16%). **[DIRECT — `receiver_cheap.md`]**

**The honest floor for a *native* 3-state gate** is therefore bracketed, not known:

- **Lower bound:** kT ln 2 per erased bit (≈ 2.9 zJ) — unreachable, but the true thermodynamic
  floor. **[DIRECT]**
- **Upper bound (what a native device must beat):** the measured CMOS-cell floor, **0.081 pJ/bit
  total / 0.0865 pJ/trit receiver** — because that is what the *emulation* already achieves.
  **[DIRECT]**
- **Where a native device could win:** a device that thresholds 3 states **natively** collapses
  the `2 sense amps + demux + push-pull driver` (14 T receiver + 4 T driver per wire, the
  `polar_gates.md` wall) into **one thresholding device per state**. If the device's own
  switching energy per state-resolution is below ~0.05–0.09 pJ/trit, native ternary beats the
  emulation. Whether any candidate device (RTD/CNTFET/SET/memristor) actually clears that bar
  is **unmeasured**. **[SPECULATION — the precise question `TERNARY_GROUND_UP.md` is built to
  answer]**

### 3.4 "Landauer-ish vs multi-level" — the one-sentence answer

The theoretical minimum energy per gate-switch is **kT ln 2 per bit of information erased
(≈ 2.9 zJ at 300 K), and this is the same whether the gate is binary or 3-state** — multi-level
buys you *density and namespace*, never a lower thermodynamic floor. The *practical* floor for
the gate is the **measurement** (2 thresholds vs 1, receiver tax 2.54×, measured 0.0865 pJ/trit),
which is where 3-state actually *loses* until a native device eliminates the threshold count.
**[DIRECT + OURS + SPECULATION]**

---

## 4. Synthesis — the calibrated n-gram

**DIRECT (measured, no invention):**

1. The loss is **I²R**, not V² — the cheap direction in (V,t) is down-in-I/up-in-t (Law 2,
   14% measured).
2. The **receiver** is the invariant floor (Law 1): 0.0865 pJ/trit, 2/3 of the 0.081 pJ/bit
   champion.
3. The **LC tank recovery is real** (reset −0.225 pJ full-swing, −0.069 pJ low-swing) but the
   **slow-ramp driver is dead** (2.5–2.6 pJ, ideal-source flattery exposed).
4. The **null is free on the wire (~0.05 pJ), meta-stable in the gate** (continuous shoot-
   through, kickback) — `polar_gates.md` is the definitive demonstration.
5. Landauer is **2.9 zJ/bit**; the champion is ~28,000× above it, so the thermodynamic floor is
   not the binding one.

**ANALOGY (parallel structure, not identity):**

6. The rectifier's `Ron/N` paralleling lever ports to a native device's channel paralleling.
7. Ternary's "fewer flips per bit" × adiabatic's "cheaper per flip" compose on different terms —
   same structure as bus-invert × charge-recycling, not an identity.

**OURS (design claim, carried from project files):**

8. null-as-default = "power only on push/pull" gives a free idle (0 static current) — the
   structural reason the null is ~24× cheaper than a ±1.
9. A native device's null, if it is a *stable fixed point* (not a saddle), would remove the
   meta-stability tax that killed the CMOS polar gates.

**SPECULATION (untested, flagged):**

10. **The V lever does not port to a native device** — V becomes a material property (state
    spacing), not a bias dial; the optimization moves from circuit to device engineering.
11. A native 3-state device has **no natural LC-style charge recovery** — NDR latching is
    dissipative (a snap, not a shuttle). Its only "natural adiabatic-like" artifact is
    **null-as-rest**, which is a *free-idle* property, not a *recovery* property.
12. A native device that thresholds 3 states **natively** could collapse the 18 T/wire
    receiver+driver overhead below the 0.0865 pJ/trit receiver floor — **if** its per-state
    switching energy clears that bar. This is the test `TERNARY_GROUND_UP.md` exists to run.

---

## 5. Sources

**Measured (DIRECT, ours):**
- `docs/ENERGY_LAWS.md` — the three laws; the 0.081 pJ/bit point; the receiver 13%→61%→67% share.
- `circuit/ENERGY_RESULTS.md` — the full fair-fight table (binary 0.748, ternary 0.515, PAM-4
  0.401, PWM-5 0.550, PWM-5-2D 0.397, LC 0.13–0.17, low-swing 0.092, cuboid 0.081 pJ/bit); the
  PAM-4 comparator wall; the low-swing Vt/resolution floors; the cuboid composition.
- `circuit/ENERGY_IDEAS.md` — adiabatic charging `E≈(RC/T)·½CV²`, charge-recycling, transition-
  activity model, the (miscorrected) Landauer number, source list.
- `docs/compute/gate_energy.md` — 2-threshold receiver tax 2.54× (61.87 vs 24.35 fJ).
- `docs/compute/polar_gates.md` — native single-wire polar gates; the null meta-stability wall;
  18 T receiver+driver per wire.
- `docs/compute/receiver_cheap.md` — the receiver floor 0.0865 pJ/trit and its decomposition.
- `circuit/PHYSICAL_NOTES.md` — MOSFET rectifiers vs junction diodes; Ron/N vs thermal runaway.
- `docs/synthesis/ternary-circuits.md` — the 19-paper survey; every literature "middle state"
  costs energy; Yeom's parasitic-middle counter-to.

**External (DIRECT citations):**
- Landauer limit (kT ln 2) — [ar5iv: Landauer limit of energy dissipation in a magnetostrictive
  particle](https://ar5iv.labs.arxiv.org/html/1506.07897); experimental verification in
  [Science Advances](https://www.science.org/doi/full/10.1126/sciadv.1501492) (via `ENERGY_IDEAS.md`).
- Adiabatic charging `E≈(RC/T)·½CV²` — [TUM model](https://mediatum.ub.tum.de/download/680196/680196.pdf),
  [Zyvex reversible-computing intro](https://www.zyvex.com/nanotech/reversible.html).
- MOBILE (monostable-bistable transition logic element) from RTDs — [US6316965](https://patentimages.storage.googleapis.com/5f/a7/36/e20d25645e7048/US6316965.pdf);
  reconfigurable RTD logic — [IEEE reconfigurable RTD circuit elements](https://www.infona.pl/resource/bwmeta1.element.ieee-art-000004484045);
  NDR compact logic — [Citeseer: compact binary logic with NDR devices](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=86e0f385d22e0d92e77104f0b7a01cb40565f0d2).

*No measured number in this file is invented; every value is either printed in one of the
project's netlists/logs/docs or is a citable textbook/literature constant. The native-device
rows are explicitly marked SPECULATION and contain no numbers.*

---

## TODO / not covered / caveats

1. **The native device is entirely unmeasured.** Every quantitative claim in §1–§3 is for the
   2-level MOSFET cell; the native-device rows are SPECULATION. The single highest-value next
   step is to pick ONE candidate device (RTD is the most literature-mature for 3-state) and run
   its per-state switching energy against the 0.0865 pJ/trit receiver bar.
2. **No V/I/R sweep exists for a native device.** The low-swing sweep (`lowswing_sweep.cir`)
   swept `VDDR` on a CMOS driver; a native device needs its own sweep over *device* parameters
   (state spacing, peak current, Ron) — that is a new netlist class, not a re-run.
3. **The null meta-stability has no native-device answer yet.** Whether a native device's null
   is a *stable* fixed point (killing the `polar_gates.md` shoot-through) or merely a saddle
   relocated to the rails (the diode-rectifier outcome) is an open, decisive question.
4. **Landauer is not computed for the *specific* ternary gate set.** §3.1–3.2 treats the floor
   generically; a per-gate reversibility audit (which of neg/cycle/min/max/mod-3-sum/consensus
   are permutations and therefore Landauer-exempt) is a small but unfiled piece — note that
   neg and cycle are permutations (reversible), while min/max/consensus are not.
5. **The "natural adiabatic artifact" claim (RTD NDR = dissipative snap, not a shuttle) is a
   literature-based inference, not our measurement.** If an NDR device can be driven so the
   fold-crossing returns stored charge (e.g. via an external resonator), the picture changes —
   that is untested.
6. **No leakage/thermal accounting for the native device.** LEVEL=1 models have no subthreshold
   leakage; a real RTD/CNTFET/SET has a leakage-and-off-current story that the whole survey
   (which is generous to the ideal case) does not yet carry.
7. **Source unit error carried:** `ENERGY_IDEAS.md` §2.1's "2.9 aJ" should read "2.9 zJ"; not yet
   corrected upstream (see §3.1).
8. **Not covered:** temperature dependence of the floors; the interaction of a native device
   with the LC tank (could a native 3-state device *itself* act as the tank's nonlinear element?);
   and the device-area/capacitance penalty that a native device's extra terminals would add to
   the `½CV²` term.
