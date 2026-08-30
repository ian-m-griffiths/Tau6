# Device physics — what makes a device natively 3-state, and what it costs

**2026-08-29 — Tau Architecture, ground-up survey. ONE question: what is the minimal
physical mechanism that produces 3 stable states, and what does it cost energetically?**

**Calibration legend** (repo standard — mark at mapping time, verify later):

- **DIRECT** — measured, proved, or a textbook identity. Cite the number or the source.
- **ANALOGY** — structural resemblance, not identity. The shapes match; the objects differ.
- **OURS** — our design claim; follows from DIRECT but is not independently established.
- **SPECULATION** — untested hypothesis, or an order-of-magnitude estimate with no cited source.
  Flagged as such, never stated as fact.

---

## 0. The minimal requirement — one statement

A 2-level MOSFET is a device whose free energy has **one** relevant control threshold: below
`V_th` the channel is empty (off), above it the channel is inverted (on). The device's state
variable (channel charge) has a monotonic dependence on the input, so it has exactly **two**
distinguishable, driven states and no other attractor.

A natively 3-state device is one whose **free-energy landscape `F(q)` — as a function of its
state variable `q` (charge, flux, or which branch of its I–V it sits on) — has three local
minima separated by barriers ≫ `k_B T`.** That sentence is the whole answer; every mechanism
below is a different way to *build* a three-minimum landscape.

**[DIRECT] — this is the standard bistability/multistability statement of nonlinear dynamics: a
memory/state device is a driven dissipative system whose fixed points are the minima of `F(q)`,
and a minimum only counts as a *state* if the barrier to the next minimum exceeds the thermal
fluctuation energy (else the state thermally hops away).**

### 0.1 The electrical form — how many stable states can an I–V curve give?

For a 2-terminal device under **voltage bias through a series load** (the normal readout), the
operating point is the intersection of the device curve `I_d(V)` with the load line
`I = (V_supply − V)/R_L`. Perturb the voltage by `δV`: the node current imbalance is
`−(g_d + 1/R_L)·δV`, where `g_d = dI_d/dV` is the device differential conductance. The point is
**stable iff `g_d + 1/R_L > 0`**, i.e. iff `g_d > −1/R_L`. **[DIRECT — linear stability around a
fixed point; textbook.]**

Consequences (the counting rule):

- A **monotonic** I–V (`g_d > 0` everywhere) crosses any load line **once** → **1 stable state**.
- An **N-shaped** I–V (one negative-differential-resistance region, `g_d < 0`) crosses a shallow
  load line **three times**, but the NDR intersection has `g_d + 1/R_L < 0` → **unstable**. That
  leaves **2 stable points = bistable**.
- To get **3 stable** intersections you need the I–V to have **three positive-slope branches
  separated by two NDR regions** — a "double-peak" / double-NDR characteristic. With the right
  `R_L` the load line hits all three rising branches → **tristable**.

**[DIRECT — consequence of the stability condition. This is exactly what the RTD multi-state
memory patents describe: a *2-peak* RTD gives 3 stable states (US 5,280,445 "Multi-dimensional
memory cell using resonant tunneling diodes"; US 5,128,894 "Multi-value memory cell using
resonant tunnelling diodes").]**

So the minimal physical requirement, stated in two equivalent ways:

1. **Energy form:** `F(q)` has three minima with barriers `≫ k_B T`.
2. **I–V form:** the device characteristic is non-monotonic with **two** NDR segments (or two
   coupled bistable elements are stacked), so three stable load-line crossings exist.

A single NDR region only ever gives **2** stable states, however you bias it. **One NDR →
bistability; two NDRs (or two stacked bistables) → tristability.** That asymmetry is the core of
"hysteresis vs tristability" (§4).

---

## 1. Mechanism A — Negative differential resistance (NDR): the RTD

### 1.1 Why a resonant-tunneling diode has an N-shaped I–V

An RTD is a **double-barrier quantum well**: two thin tunnel barriers (e.g. AlAs) sandwich a
narrow quantum well (e.g. InGaAs). The well has a quantized subband energy `E_1`. Electrons from
the emitter transmit when their energy matches `E_1` (resonant tunneling — energy + transverse
momentum conserved). **[DIRECT — textbook double-barrier RTD physics; e.g. Mizuta & Tanoue,
*The Physics and Applications of Resonant Tunnelling Diodes*, CUP 1995.]**

As bias rises, `E_1` is pulled down relative to the emitter conduction band:

1. Current **rises** as more emitter electrons come into resonance.
2. **Peak** when `E_1` lines up with the emitter band edge — every available emitter electron up
   to the Fermi level can resonate.
3. **NDR region:** push `E_1` below the emitter band edge and the resonant channel is **cut off
   from below** — the transmission at `E_1` is still ~unity, but there are no longer any
   carriers at that energy. Current **falls** as bias rises → `dI/dV < 0`.
4. **Valley**, then current rises again via non-resonant (higher-subband/thermionic) leakage.

**The NDR is caused by cutting the *supply* of resonant carriers, not by reducing the
transmission probability.** That distinction is why the region is sharp and repeatable.
**[DIRECT — standard mechanism.]**

### 1.2 From N-shape to 3 states

Per §0.1, the N-shape + load line gives **bistability** (the classic tunnel-diode flip-flop).
For **three** states the literature uses either a **double-peak RTD** (two stacked resonances →
two NDR regions → three rising branches) or **two series RTDs**. A 2-peak RTD is the clean
"natively ternary" device: its three rising branches are, literally, the three digits.
**[DIRECT for the mechanism; the multi-peak-RTD = M-valued-state construction is the standard
result in the RTD-logic literature, and the two patents above are explicit implementations.]**

There is also a documented complication worth recording honestly: a **single** double-barrier
structure can exhibit **intrinsic bistability** — charge that accumulates in the well
self-consistently shifts the resonance (electrostatic feedback), which shifts the current, which
feeds back — producing two stable current branches *within* the device, independent of the
external circuit. Combined with the load line this can yield **three** stable branches
(tristability) in a nominally single-NDR device. **[DIRECT — this is the subject of the cited
tristability papers: "Extrinsic tristability as the cause of bistability in resonant-tunneling
diodes" (1992); "A new technique for directly probing the intrinsic tristability and its
temperature dependence in a resonant tunneling diode" (Solid-State Electronics, 1994).]** The
clean §0.1 counting rule (two NDRs → three stable) remains the *predictable* minimal recipe;
intrinsic-bistability tristability is an emergent three-branch structure that is harder to
design against.

### 1.3 Energy accounting

- **Speed is the RTD's real number:** switching times of **1.5 ps** have been measured
  (Shimizu & Nagatsuma, "In0.53Ga0.47As/AlAs resonant tunnelling diodes with switching time of
  1.5 ps"). **[DIRECT — cited.]** Peak-to-valley current ratios (PVCR) of InGaAs/AlAs RTDs are
  typically **3–10** (higher PVCR ≈ cleaner states). **[DIRECT — widely reported range; cite
  the material-system literature.]**
- **Switching energy:** the energy to move the device from one stable branch to the next is on
  the order of the stored charge moved through the voltage swing, `~½ C_node ΔV²`. Typical RTD
  operating points are `~0.5 V` at `~mA`, and with `C ~ fF` this lands in the
  **sub-fJ to fJ per switch** range. **[SPECULATION — order-of-magnitude estimate from the
  cited 1.5 ps × typical bias; no single cited energy number. Treat as a scaling, not a
  measurement.]**
- **The honest cost that is easy to miss:** an NDR region is an *active* element — `dI·dV < 0`
  means the device **supplies** power there. You must feed it DC bias current *continuously* to
  hold any state, including the "idle" one. The transient switching energy can be fJ-scale, but
  the **static** dissipation (bias × current) is the price of a negative resistor, and it is not
  recovered. **[DIRECT — definition of NDR as a negative resistor; the static-power consequence
  is standard RTD-logic criticism, flagged as such.]**

---

## 2. Mechanism B — Multi-threshold (two thresholds → three levels)

### 2.1 What a threshold is, and why two of them make three states

A FET's channel is a monotonic function of gate voltage with a single `V_th`. "Two thresholds"
means the device has **two independently controllable turn-on points**, so the output current has
**three distinguishable plateaus**: off (below `V_th1`), intermediate (between `V_th1` and
`V_th2`), on (above `V_th2`). **[DIRECT — definitional.]**

Physical ways to get two thresholds:

- **Dual-gate / double-gate FET:** two gates whose weighted sum sets the effective threshold;
  the two gates give two control inputs → three combined current levels. **[DIRECT — standard
  device physics.]**
- **CNTFET with engineered bandgap:** a carbon-nanotube channel's bandgap scales inversely with
  nanotube diameter, so a CNT of chosen chirality/diameter sets `V_th`; two series/parallel CNTs
  (or a CNT with non-uniform doping/band structure) give multiple thresholds. **[DIRECT — CNT
  bandgap ∝ 1/diameter is textbook; "engineer the bandgap to set V_th" is the standard CNTFET
  design lever.]**
- **Work-function / multi-`V_th` engineering:** different gate metals set different thresholds;
  two devices with two `V_th`s side by side = one 3-level receiver. **[DIRECT — standard CMOS
  multi-V_th technique.]**

### 2.2 The crucial distinction: driven levels, not self-held states

Multi-threshold gives **three distinguishable, *driven* states**, not three *stable attractors*.
There are no NDRs and no barriers; the "state" is held open by the input voltage and collapses
the moment the input leaves. This is exactly what a **combinational ternary gate** needs — it
must not latch. **[DIRECT — this is the standard multi-valued-CMOS definition, and it is why
multi-threshold and NDR are *complementary*, not equivalent: one is logic, the other is
memory.]**

### 2.3 Energy accounting

- The driver pays the ordinary `½CV²` to charge the node through the swing — but now the swing is
  partitioned into **3 levels instead of 2**, so the gap between adjacent levels is **`V_swing/2`
  instead of `V_swing`**. **[DIRECT — arithmetic.]**
- To hold a fixed error probability against thermal noise (`σ ∝ √(kT/C)`), halving the level gap
  forces you to **raise the swing or raise C** — i.e. spend *more* energy per bit, not less.
  **[DIRECT — this is the same SNR argument as PAM-4 vs NRZ in wire signaling; the multi-level
  "density" is paid in noise margin.]**
- The receiver must resolve **3 levels = 2 thresholds = 2 comparators** vs binary's 1. The
  sibling measurement (`docs/compute/gate_energy.md`) found this costs **2.54×** per evaluation,
  *more* than the `log₂3 = 1.585×` density the extra level buys — the 2-threshold tax exceeds
  the entire radix-economy gain **before any gate logic is counted**. **[DIRECT within this
  project — measured; generalization to "ternary CMOS loses per bit" is OURS.]**

**Bottom line for this mechanism:** two thresholds are cheap to *describe* and expensive to
*resolve*. The minimal physical requirement (a device with two turn-on points) is easy; the
energetic requirement (resolving three levels with the same fidelity as two) is the whole game,
and it currently loses.

---

## 3. Mechanism C — Quantized charge (SET / Coulomb blockade)

### 3.1 The physics

A single-electron transistor is a small conducting **island** coupled to source/drain by two weak
tunnel junctions and to a gate by a capacitance `C_g`. Its total capacitance `C_Σ` sets a
**charging energy**

```
E_C = e² / 2C_Σ
```

— the Coulomb energy to put one extra electron on the island. When `E_C ≫ k_B T` **and** the
tunnel resistance `R_T ≫ R_Q = h/e² ≈ 25.8 kΩ` (so the island's electron number is not quantum-
smeared), the electron number on the island is **quantized**: `n = …, −1, 0, +1, …`. Each
integer `n` is a distinct, self-held charge state, and the gate voltage simply walks the ladder
(Coulomb staircase / Coulomb oscillations). **[DIRECT — standard SET physics: Grabert & Devoret,
*Single Charge Tunneling*, 1992; Likharev.]**

### 3.2 Why this is the *native* multi-state device

The Coulomb ladder gives **many** discrete states for free — the device is not "ternary", it is
**M-valued with M ≈ the usable range of `n`**. You get 3 states (or 4, or 5…) by simply choosing
the gate window. No NDR, no threshold engineering: the *discreteness of charge* is the state
ladder. This is the cleanest answer to "what is the minimal physical mechanism for 3 stable
states" — **quantization of a conserved charge on a capacitor**, gated by `E_C ≫ k_B T`.
**[DIRECT — Coulomb blockade; the multi-valued-logic-on-SET construction is a whole literature
(e.g. "Design of multi-valued logic cells using single-electron devices").]**

### 3.3 Energy accounting

- **State separation:** `E_C = e²/2C_Σ`. For `C_Σ = 1 aF`: `E_C = 1.28×10⁻²⁰ J = 80 meV
  = 3.1 k_B T` at 300 K. For `C_Σ = 0.1 aF` (≈ 1 nm island): `E_C ≈ 0.8 eV`. **[DIRECT —
  arithmetic from `e = 1.602×10⁻¹⁹ C`, `k_B T(300K) = 25.85 meV`.]**
- **Switching energy per electron:** `~ E_C` — i.e. **aJ (10⁻¹⁸ J) to zJ (10⁻²¹ J)** per
  charge-state change, the *only* mechanism here that operates anywhere near the Landauer scale.
  **[DIRECT — the charging energy is the energy to change `n` by one; this is standard.]**
- **The two costs that kill it for logic:**
  1. **Temperature.** `E_C ≫ k_B T` is a *hard* requirement. At 300 K you need sub-aF
     (≈ nm) islands — near the fabrication limit; at practical island sizes the clean single-
     electron regime is **cryogenic** (mK–few K). **[DIRECT — standard SET operating condition.]**
  2. **Speed.** `R_T ≫ 25.8 kΩ` forces MΩ-scale junctions and nA-scale currents; the RC time
     with a fF load is ns–µs. The device is **thermodynamically beautiful and electrically
     slow**. **[DIRECT — consequence of the `R_T ≫ R_Q` requirement.]**

**Bottom line:** SET is the mechanism that proves 3-state can be *native and nearly-free
energetically*, at the price of speed and temperature. It is the thermodynamic existence proof,
not the logic building block.

---

## 4. Hysteresis / bistability vs tristability

The terms collapse to one counting question: **how many minima?**

| property | # minima | # NDR segments | states | example |
|---|---|---|---|---|
| monotonic | 1 | 0 | 1 | ordinary FET under one bias |
| **bistable / hysteretic** | 2 | **1** | 2 | single RTD + load; tunnel-diode flip-flop |
| **tristable** | 3 | **2** (or stacked bistables) | 3 | 2-peak RTD; two series RTDs; SET with 3 allowed `n` |
| M-stable | M | M−1 | M | SET (many `n`); multi-peak RTD |

**[DIRECT — this is §0.1 restated; the "one NDR = 2 states, two NDRs = 3 states" is the
load-line stability counting, not an analogy.]**

Two points to keep straight:

1. **Hysteresis is the *signature* of bistability, not a separate phenomenon.** A hysteretic
   I–V loop is what you measure when a 2-minimum system is swept back and forth — the loop area
   is the energy dissipated per cycle. **[DIRECT — definition.]**
2. **Bistability is not a stepping stone to tristability by "adding one more level."** You
   cannot get 3 stable states from one 2-minimum device by any bias choice; you must *stack* a
   second NDR/bistable element (or use a device with two NDRs). The number of NDR segments, not
   the number of "levels", sets the number of stable states. **[DIRECT — consequence of the
   counting rule; the multi-peak-RTD literature is built on exactly this.]**

---

## 5. The thermodynamics — the honest answer

### 5.1 The Landauer floor is per **bit**, not per digit

Erasing one bit costs at least `k_B T ln 2`. At 300 K:

```
k_B T ln 2 = 2.87 × 10⁻²¹ J = 2.87 zJ = 17.9 meV
k_B T ln 3 = 4.55 × 10⁻²¹ J = 4.55 zJ = 28.4 meV     (one trit)
```

**[DIRECT — Landauer 1961; the numbers are arithmetic from `k_B = 1.380649×10⁻²³ J/K`.]**

The generalization to radix `r` (the directly relevant citation here) is that the minimum energy
to erase **one `r`-valued digit is `k_B T ln r`** — see "Generalization of the Landauer Principle
for Computing Devices Based on Many-Valued Logic", *Entropy* 21(12):1150 (2019). So a trit
costs `k_B T ln 3`, which is exactly **`log₂3 = 1.585` × `k_B T ln 2`** — because a trit *is*
1.585 bits.

**Therefore, per bit, 3-state and 2-state are identical at the floor.** `k_B T ln 3 / 1.585
bits = k_B T ln 2 per bit`, exactly. **[DIRECT — `ln 3 / ln 2 = log₂ 3 = 1.58496…`.]**

### 5.2 The radix-economy saving is cancelled in the thermodynamic limit

The celebrated radix-economy result — the cost of representing a number in radix `b` scales as
`b/ln b`, minimized at `b = e`, with `3/ln 3 = 2.731 < 2/ln 2 = 2.885` — is a statement about
**digit count**, not energy. To represent `N` equiprobable values you need `log_b N` digits, each
costing `k_B T ln b` to erase, so the total reset cost is

```
(log_b N) · (k_B T ln b) = k_B T ln N    —  independent of b
```

**[DIRECT — pure arithmetic; the two `ln b` factors cancel.]** This is the crux of the honest
answer: **the digit-count advantage of base 3 is exactly offset by the higher per-digit erasure
cost. The Landauer cost of resetting a register of `N` values is `k_B T ln N`, radix-
independent.** There is no thermodynamic free lunch in base 3. **[DIRECT.]**

### 5.3 So does a native 3-state device beat 2-state per bit?

**At the fundamental limit: no — it is exactly tied (per bit).** At any practical operating
point: **no — it currently loses**, for reasons that are physics, not engineering taste:

1. **Multi-level needs more SNR.** Three levels in a fixed swing sit `V_swing/2` apart, so to
   hold a fixed bit-error rate against `kT/C` noise you raise the swing or the capacitance —
   both cost energy. **[DIRECT — Shannon/SNR; PAM-4 vs NRZ.]**
2. **The receiver tax.** Resolving 3 levels = 2 thresholds = 2 comparators; measured 2.54× the
   receiver energy, which exceeds the 1.585× density gain. **[DIRECT within this project —
   `docs/compute/gate_energy.md`.]**
3. **The circuit cost.** The arXiv paper "Ternary circuits: why R=3 is not the optimal radix for
   computation" (arXiv:1908.06841) makes the independent point that the gate-level complexity of
   ternary circuits erases the radix saving — consistent with the sibling measurement.
   **[DIRECT — cited source's thesis.]**
4. **Retention floors the barrier height.** A state only survives if its barrier `ΔE ≫ k_B T`;
   via the Arrhenius retention `τ ≈ τ₀·exp(ΔE/k_B T)` with `τ₀ ~ 10⁻¹³ s`, a 10-year
   non-volatile memory needs `ΔE ≈ 40–50 k_B T`, and even *holding a state through one clock
   cycle* needs `~10 k_B T`. Three wells don't change this — they add a second barrier to
   maintain. **[DIRECT — Arrhenius formula is standard; the `τ₀ ~ 10⁻¹³ s` attempt-frequency
   is the flagged assumption; the 40–50 k_B T / 10-year figure is the standard order-of-magnitude
   consequence.]**

### 5.4 What 3-state is *actually* good for (honest positives)

- **Representation/namespace economy, not per-bit energy.** Fewer digits per value = fewer
  pins, fewer wires, fewer clock cycles to move or index a number. This is an **interconnect and
  opcode-density** win, which the comm side of this project already exploits (`0.081 pJ/bit`
  floor on the wire, `docs/ENERGY_LAWS.md`). **[DIRECT — radix economy is a counting fact;
  "wires/cycles, not joules" is OURS/consistent with the sibling docs.]**
- **Specific device physics.** RTDs switch in ~ps at ~fJ (speed-dense, but DC-hungry); SETs
  switch per-electron at aJ-scale (ultimately cheap, but slow + cryogenic). These are real
  *native* advantages — they are advantages of the **mechanism**, not of the number 3.
  **[DIRECT for the cited numbers; "advantage belongs to the mechanism, not the radix" is
  OURS.]**

---

## 6. Per-mechanism energy accounting (summary table)

| mechanism | what makes 3 states | state separation | switch energy (order) | speed | conditions | calibration |
|---|---|---|---|---|---|---|
| **NDR (RTD, 2-peak / 2× series)** | 2 NDR segments → 3 rising branches | `~ ½ C ΔV²` between branches (fF × ~0.5 V → fJ) | **sub-fJ–fJ** (est.) | **~1.5 ps** (measured) | needs DC bias (active device) | state-count DIRECT; switch energy SPECULATION (order-of-magnitude); speed DIRECT (cited) |
| **Multi-threshold (dual-gate FET / CNTFET)** | 2 thresholds → 3 driven levels | `V_swing/2` gap (½ of binary) | `½CV²` × (extra SNR to recover margin) | CMOS clock | room temp | DIRECT; 2.54× receiver tax DIRECT (measured) |
| **Quantized charge (SET)** | Coulomb ladder of integer `n` | `E_C = e²/2C_Σ` (aF → 80 meV) | **~E_C per electron: aJ–zJ** | ns–µs (MΩ junctions) | **cryogenic** unless nm island | DIRECT (standard) |
| **Landauer floor (any)** | — | barrier ≫ `k_B T` | `k_B T ln 3`/trit = 4.55 zJ = 1.585 bits | — | 300 K | DIRECT (Landauer + generalization) |

**[Calibration: every number above is DIRECT from the physics/arithmetic cited, *except* the
RTD switch-energy, which is an explicit order-of-magnitude estimate from the cited 1.5 ps ×
typical bias and is not a sourced measurement.]**

---

## 7. Verdict in one paragraph

The **minimal physical requirement** for three stable states is a free-energy landscape with
**three minima separated by barriers ≫ `k_B T`** — equivalently, in the electrical picture, a
device characteristic with **two NDR segments** (or two stacked bistable elements) so the load
line has three stable crossings. The three known mechanisms are three ways to build that
landscape: NDR (RTD), multi-threshold (two turn-on points), and charge quantization (SET). The
**energetic cost** splits cleanly: at the *Landauer floor* a trit costs `k_B T ln 3 = 4.55 zJ`,
which is exactly 1.585 bits' worth — **3-state is per-bit identical to 2-state, never cheaper**,
because `log₂ 3 = 1.585` means the higher per-digit cost and the digit-count saving cancel
(`k_B T ln N` is radix-independent). Above the floor, 3-state **loses** per bit (noise margin,
the 2-threshold receiver tax, device immaturity); it wins only as a **representation/interconnect
economy**, and in the specific device physics (RTD speed, SET near-single-electron energy) —
wins that belong to the mechanism, not to the number three.

---

## 8. TODO / not covered / caveats

- **RTD switching energy is an estimate, not a measurement.** I could not find a single clean,
  citable "E_switch = X fJ" number for a tristable RTD cell; §1.3/§6 flag the sub-fJ–fJ figure
  as an order-of-magnitude scaling from the cited 1.5 ps × typical bias. A proper literature
  sweep of RTD/MOBILE memory-cell energy (e.g. the MOnostable-BIstable Logic Element family)
  should replace it.
- **PVCR range cited loosely.** "3–10 (up to ~30)" is the widely-reported InGaAs/AlAs range but
  I did not pin a single authoritative measurement; worth one primary-source check.
- **Intrinsic vs extrinsic tristability is not fully disentangled here.** §1.2 records that a
  single RTD can show 3 branches via intrinsic bistability (cited 1992/1994 papers) but I did not
  resolve whether that 3rd state is usable/logic-grade; flag for the memory-cell subagent.
- **The SET "native ternary" is really native M-valued.** I treated the Coulomb ladder as a
  generic M-state mechanism; whether 3 specific `n` states give a *better* logic family than 2 or
  4 is unexamined.
- **The SNR argument is stated, not quantified.** The exact energy-to-keep-BER-constant curve
  for 3-level vs 2-level detection (the PAM-4-vs-NRZ gap) is a known result I did not reproduce
  with a number; it should be computed or cited before "3-level needs X× energy" is claimed in
  any downstream doc.
- **Landauer is the *erasure* floor only.** Reversible (adiabatic) computing can in principle
  push switching below `k_B T ln 2` (energy recovery); whether ternary interacts with adiabatic
  logic differently than binary is **not** covered and could change the "no per-bit win" verdict
  in the reversible regime.
- **Static/leakage cost of NDR is named but not quantified.** The DC bias needed to hold an
  active NDR state is the biggest unmeasured term in the RTD column.
- **No quantum-coherent / superconducting (e.g. phase-qubit / RSFQ multi-level) treatment.** A
  flux-quantum or phase-slip device is another genuine native-3-state mechanism (flux minima)
  that the brief did not ask for and that is entirely out of scope here.
- **Cross-check against sibling docs pending.** This file's verdict should be reconciled with
  `docs/compute/gate_energy.md` (measured) and `docs/compute/trit_tricks.md` (radix-economy
  framing) — they agree, but the reconciliation is not yet written in one place.

---

## Sources

- **Landauer, R. (1961),** "Irreversibility and Heat Generation in the Computing Process", *IBM
  J. Res. Dev.* 5:183 — `k_B T ln 2` per erased bit.
- **"Generalization of the Landauer Principle for Computing Devices Based on Many-Valued
  Logic",** *Entropy* 21(12):1150 (2019) — minimum erasure energy per `r`-valued digit is
  `k_B T ln r`. https://www.mdpi.com/1099-4300/21/12/1150
- **"Ternary circuits: why R = 3 is not the Optimal Radix for Computation",** arXiv:1908.06841 —
  gate-level cost erases the radix-economy saving. http://arxiv.org/pdf/1908.06841
- **Shimizu & Nagatsuma,** "In0.53Ga0.47As/AlAs resonant tunnelling diodes with switching time
  of 1.5 ps" — RTD switching speed.
- **"Extrinsic tristability as the cause of bistability in resonant-tunneling diodes" (1992)** and
  **"A new technique for directly probing the intrinsic tristability and its temperature
  dependence in a resonant tunneling diode",** *Solid-State Electronics* (1994),
  doi:10.1016/0038-1101(94)90336-0 — single-RTD tristability.
- **US 5,280,445** "Multi-dimensional memory cell using resonant tunneling diodes" and
  **US 5,128,894** "Multi-value memory cell using resonant tunnelling diodes" — 2-peak RTD =
  3 stable states.
- **Mizuta & Tanoue,** *The Physics and Applications of Resonant Tunnelling Diodes*, CUP 1995 —
  double-barrier RTD physics, NDR from resonant-supply cut-off.
- **Grabert & Devoret,** *Single Charge Tunneling*, 1992; **Likharev** — SET / Coulomb blockade:
  `E_C = e²/2C_Σ`, `R_Q = h/e² ≈ 25.8 kΩ`, quantized `n`.
- **"Design of multi-valued logic cells using single-electron devices"** (Univ. of Windsor
  thesis) — SET as an M-valued logic substrate.
- **In-tree (project):** `docs/compute/gate_energy.md` (measured 2.54× receiver tax),
  `docs/compute/trit_tricks.md` (radix-economy ledger, calibration legend),
  `docs/ENERGY_LAWS.md` (comm floor).
