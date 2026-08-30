# Native 3-state devices — the anti-ambipolar transistor (AAT) and anti-ferroelectric HZO

**2026-08-29 — Tau Architecture, ground-up deep-dive.** ONE question, Ian's: *"For every
charge we have 3 states — forward, backward, null — so there has to be a complex transistor
that's cheaper."* The candidate is the **anti-ambipolar transistor** (AAT — one device, a
non-monotonic transfer curve → a ternary inverter from 1 device + 1 load) and the
**anti-ferroelectric Hf₀.₅Zr₀.₅O₂** (AFE HZO — the CMOS-compatible film whose P–E loop has
three polarization states). This file executes `meta_transistor.md` §6.1 (the highest-value
test: "pull the AAT primary sources and extract the numbers") and §6.3 (the AFE cell), and
answers the four questions: the AAT physics, the AFE physics, the fabrication reality, and
the **per-op energy vs a binary CMOS inverter** (whether it can hit the `0.63×` per-bit
bound).

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured/proved in-repo, or a citable literature/textbook identity.
- **ANALOGY** — parallel structure, not identity.
- **OURS** — our design claim; follows from DIRECT but not independently established.
- **SPECULATION** — untested hypothesis, or an order-of-magnitude estimate with no cited source.

---

## 0. The blunt verdict, first

**The AAT is the *mechanism* Ian asked for — one device resolves 3 states in one
measurement, and it is real and demonstrated.** But it is **not** the cheaper "complex
transistor," and the honest reason is three independent physics facts, not manufacturing
taste:

1. **The AAT inverter's middle state is a resistive divider, not a dead zone.** The ternary
   inverter is built as **AAT (pull-down) + a load (pull-up) in series**, and the third
   ("logic ½") output is produced where the two devices' currents are comparable — a
   **voltage divider with both devices conducting**. So the AAT re-introduces the *exact*
   static-current (shoot-through) failure that `device_circuit.md` §3.2 says the depletion
   window was supposed to kill. It removes the **2-threshold *device* tax** (band alignment
   makes the two "knees" free) but **not** the **static-current tax** and **not** the
   **3-level noise-margin tax** and **not** the **2-decision *information* tax**. **[DIRECT
   mechanism from the primary papers; the "which tax survives" split is OURS.]**
2. **No AAT paper reports a switching energy.** I verified this in the primary sources. The
   demonstrated devices are either (a) **organic, VDD = 14 V, μm-scale, nA-current** (e.g.
   Panigrahi/Hayakawa *Adv. Mater. Technol.* 2023) or (b) **2D, VDD = 0.1–0.5 V but switching
   at 1 Hz with pA–nA currents** (Lai/Ho *Device* 2024). Neither is energy-competitive with a
   6.94 fJ, 1 V, GHz-class CMOS inverter; both are **orders of magnitude worse per useful
   operation**, by a factor set by static current × slow switching, not by `½CV²`. **[DIRECT
   for the cited numbers; the energy comparison is OURS — see §3.]**
3. **The `0.63×` per-bit bound is a *density* ceiling, not an energy one, and no device
   reaches it.** `0.63× = 1/log₂3` is the radix-economy fact "one trit = 1.585 bits." It
   becomes an energy win *only if* one ternary operation costs the same as one binary
   operation. The AAT does not (static current), and — independent of the AAT — the Landauer
   floor is `k_B T ln 3` per trit = `k_B T ln 2` per bit (**tied, never cheaper**, §5.1), and
   the 3-level SNR penalty forces ≥ ~2× energy per level above the floor (§5.3). **[DIRECT —
   `device_physics.md` §5; the "AAT fails the energy test" conclusion is OURS.]**

**Bottom line:** the AAT/AFE/RFET answer to "no native device exists" is real — the
*mechanism* exists and is demonstrated. But it is a **mechanism**, not a part: the AAT is a
non-fabricable lab device that loses on energy, and the AFE is a memory-class (passive,
no-gain) 3-state element that cannot restore or fan out. The program's fabrication verdict
(`meta_critique.md` §3e) and its energy verdict (`device_circuit.md` §7.2, ~1.5–2×/bit)
**both survive**. What changes is only that the go/no-go question is now answered for the
right *reason*: the AAT fails on **static current + SNR + information**, not on "no such
device."

---

## 1. The AAT physics — the non-monotonic transfer curve

### 1.1 What "anti-ambipolar" means, precisely

An ordinary MOSFET has a **monotonic** transfer curve: drain current rises (roughly
monotonically) as gate voltage rises. An **ambipolar** transistor conducts with *both*
carrier types — holes at strongly negative gate bias, electrons at strongly positive gate
bias — so its transfer curve is **V-shaped**: high at both extremes, a *minimum* in the
middle. **[DIRECT — textbook ambipolar conduction.]**

An **anti-ambipolar transistor** is the *inverse*: a **series (or hetero-) stack of a
p-type and an n-type channel** so that current flows only where **both** carrier populations
are simultaneously populated. At strongly negative gate bias the n-side is depleted (off);
at strongly positive gate bias the p-side is depleted (off); in between, both sides conduct,
so the transfer curve **rises to a peak and falls back on both sides** — a **hump (Λ
shape)** with a region of **negative differential transconductance (NDT, `g_m = dI/dV_g < 0`)
on the falling side**. **[DIRECT — this is the standard definition; the hump is the
complement of ambipolar conduction, `meta_transistor.md` §1.1.]**

Two concrete realizations I read in the primary sources:

- **Organic lateral heterojunction** (C8-BTBT p-type / PTCDI-C8 n-type, Panigrahi et al.
  *Adv. Mater. Technol.* 2023, doi:10.1002/admt.202301049): the transfer (at VDS = −14 V) is
  off from 0 to −7 V, rises to a **peak `I_p = 220 nA` at `V_g = −9.3 V`**, then **NDT** from
  −9.3 to −10.4 V (current *falls* from 220 nA to a **valley `I_v = 87 nA`** as the PTCDI-C8
  channel depletes), then rises again (hole conduction, `I_on = 326 nA` at −14 V). Peak
  `g_m` (NDT) = **0.3 μS**. **[DIRECT — measured numbers from the paper's Fig. 1.]**
- **Mixed-dimensional 1D GaAsSb / 2D MoS₂ heterotransistor** (Lai, Ho et al. *Device* 2,
  100184, 2024, doi:10.1016/j.device.2023.100184): the AAT is an n-MoS₂ FET + GaAsSb/MoS₂
  p–n junction + p-GaAsSb FET in series-resistance mode, with a **peak-to-valley ratio
  (PVR) > 10³**. **[DIRECT.]**

The two "knees" of the hump (the turn-on and the turn-off) are set by **band alignment** of
the n/p junction, *not* by two implanted threshold voltages. That is the entire point of the
"complex transistor" claim: **two thresholds come free from band structure.** **[DIRECT —
`meta_transistor.md` §1.1, §4.2; mechanism confirmed in the primary papers.]**

### 1.2 How the hump becomes a ternary inverter — one device + one load

The ternary inverter is the AAT wired as a **pull-down driver** in series with a **load**
(a resistor, or more commonly a second transistor used as an active pull-up). The output
node sits between them, so

```
V_out = the voltage where I_AAT(V_in) = I_load(V_out)
```

— i.e. `V_out` is set by the **resistance ratio** of the two series elements, which is a
*non-monotonic* function of `V_in` because the AAT's resistance is non-monotonic. **[DIRECT —
both primary papers state the inverter is "a series circuit of an AAT and a load
transistor" and that `V_out` is "determined by the resistance ratio."]**

The three input ranges map to three output levels **[DIRECT — Fig. 4 of the *Device* 2024
paper; Fig. 1 of the 2023 *Adv. Mater. Technol.* paper]**:

| input range | AAT vs load | output |
|---|---|---|
| low `V_in` (n-side of AAT off) | AAT resistance ≫ load | **logic 1 = VDD** |
| mid `V_in` (both on; NDT region) | currents comparable → **divider** | **logic ½ (intermediate)** |
| high `V_in` (p-side / load exhausted) | AAT resistance ≪ load | **logic 0 = GND** |

This is a **standard ternary inverter** (STI): `{0 → 2, ½ → 1, 1 → 0}` — one active AAT,
one load, **no engineered threshold flavor, no depletion device, no sense amp, no
re-encode driver**. **[DIRECT — demonstrated in the primary papers; "one device + one load"
is the `meta_transistor.md` §1.1 framing, and the papers use a *load transistor*, i.e.
"two transistors" total — see §1.3.]**

### 1.3 The one thing the "1 device + 1 resistor" phrasing hides

`meta_transistor.md` said "1 device + 1 load resistor." The primary papers build it as **1
AAT + 1 load *transistor*** — two devices. The distinction is *not* cosmetic: a resistor
load would draw even more static current than a load transistor (and a load transistor is
the only way to get the low VDD the *Device* paper achieves). So the honest count is **2
devices**, and either way **both devices conduct at the middle state** — the load never
turns off when the AAT is on. **[DIRECT — both papers' circuit diagrams; the "2 devices, not
1" correction to the §1.1 phrasing is OURS.]**

The middle state is **not a dead zone**. In the *Device* paper: "the resistance ratio
between the pull-up and pull-down transistors is nearly constant → a unique intermediate
logic state comes into being"; in the 2023 organic paper: "This caused VDD to be divided
between them, resulting in the logic ½ state." **A divider has static current.** This is
the same shoot-through/meta-stable-null failure the corpus already measured for the
unipolar STI (`device_circuit.md` §3.2), and the AAT does **not** escape it — the null is a
*held* level, not a *self-held* attractor, and it is held *with* current. **[DIRECT — the
papers' own mechanism descriptions; the "same shoot-through as the STI" identification is
OURS, but the mechanism text is DIRECT.]**

### 1.4 The measured inverter figures (what "near-perfect" actually means)

- **Organic** (2023): VDD = **14 V**, logic ½ at **4.3 V** (vs ideal 7 V — *not* balanced),
  voltage gains **59 V/V and 26 V/V** (unbalanced), improved by UV + geometry optimization
  to **≈41 V/V on both transitions** with an SNM of **1.2 V** on the logic-½ state.
  **[DIRECT — paper Fig. 1/3.]**
- **2D GaAsSb/MoS₂** (2024): VDD = **0.1–0.5 V** (the middle state appears even at 0.1 V —
  a record low), a flat middle plateau over a **~8 V input window**, and a **1 Hz** dynamic
  test. PVR > 10³. **[DIRECT — paper Fig. 4.]**
- **MoTe₂ homojunction STI** (the paper `meta_transistor.md` named): "near-perfect standard
  ternary inverter" — see §1.5 and the caveats; the subagent extraction of its exact gain /
  margin / supply is the one number this file still owes (`meta_transistor.md` TODO #1).

The honest read: the AAT *mechanism* is clean and the inverter *works* — but the
demonstrated devices are either **high-voltage (14 V)** or **slow (1 Hz)**, and all of them
have a **static-current middle state**. "Near-perfect" refers to the *voltage-gain balance
and noise margin*, not to energy or speed. **[DIRECT for the numbers; the interpretation is
OURS.]**

### 1.5 The MoTe₂ homojunction STI paper (the one `meta_transistor.md` named)

"Near-Perfect Standard Ternary Inverter Based on MoTe₂ Homojunction Anti-Ambipolar
Transistor" — **Zhang, …, Pan, *Adv. Funct. Mater.* 2025, 35(29), art. 2424728,
doi:10.1002/adfm.202424728** (Tianjin Univ.). Key facts extracted:

- The homojunction is a **lateral, area-selective p/n doping on a single MoTe₂ flake** — not
  a vertical heterojunction and not phase/thickness-engineered. **[DIRECT.]**
- **Peak-to-valley ratio (PVR) > 10³**, and the intermediate state's input window is
  **exactly ⅓ of the input range** — this is the "near-perfect" in the title. **[DIRECT —
  abstract.]**
- **Gain, noise margins, load resistance, and VDD are NOT reported in the accessible
  abstract** (paywalled body). So I still cannot quote the MoTe₂ inverter's voltage gain or
  supply — the one number `meta_transistor.md` TODO #1 asked for that remains open.
  **[Explicit NOT-REPORTED.]**

The fastest AAT found anywhere is the **p-WSe₂/n-MoTe₂** device (Wang et al., *Nanoscale*
2025, doi:10.1039/d5nr01914a): **VDD = 0.7 V, 3 MHz** — CMOS-*like* voltage but still ~10³×
slower than GHz CMOS, and still the same ratioed divider topology. **[DIRECT — abstract.]**

---

## 2. The AFE HZO physics — the double-hysteresis loop and its "3 states"

### 2.1 What the AFE P–E loop actually is

A **ferroelectric** (FE) has a single-hysteresis P–E loop with **two** remnant states
`±P_r`. An **antiferroelectric** (AFE) has a **double-hysteresis** P–E loop: at zero field
the ground state has **zero net polarization** (the two sublattices are anti-parallel, or the
tetragonal phase is non-polar), and an applied field induces a **field-driven transition to
a ferroelectric state** at the coercive field `±E_c`. The loop therefore traces
`−P_r → 0 → +P_r` — **three distinguishable polarization states**. **[DIRECT — standard
antiferroelectricity; Kittel's two-sublattice model.]**

For HfO₂/ZrO₂ specifically: the **orthorhombic `Pca2₁`** phase is FE (two minima), the
**tetragonal `P4₂/nmc`** phase is AFE (field-induced FE), and **Hf₀.₅Zr₀.₅O₂** sits on the
boundary — the Zr fraction, film thickness, annealing, and capping tune which phase wins.
This is why HZO is *the* CMOS-relevant AFE: it is the **same high-k dielectric already in
every logic gate**, just stabilized in a different phase. **[DIRECT — the HfO₂ FE/AFE phase
diagram is a large, settled literature; `device_literature.md` §2.8 and `meta_transistor.md`
§1.2.]**

### 2.2 The "3 minima" claim — TRUE with a calibration caveat

`meta_transistor.md` §1.2 wrote "AFE = 3 stable polarization states … 3 minima, standard
ferroelectrics textbook." That is **DIRECT** for the *count of distinguishable states* and
for the *double-hysteresis memory mechanism*, but it **over-states the free-energy picture**
if read literally as "a zero-field triple well." The honest statement:

- At **zero field**, a clean AFE has **one** ground state (`P = 0`). The `±P_r` states are
  **field-induced ferroelectric states** that persist as *remnant* states after the field is
  removed (metastable, held by the induced-FE coupling). In the **Kittel two-sublattice
  model** (`f = (α/2)(P_a²+P_b²) + (β/4)(P_a⁴+P_b⁴) + (γ/6)(P_a⁶+P_b⁶) + g·P_a·P_b −
  E(P_a+P_b)`, Lum et al., *J. Phys.: Condens. Matter* 34 415702, 2022,
  doi:10.1088/1361-648X/ac7e99): the AFE coupling is **`g > 0`** (penalizes parallel
  sublattices), and the *staggered* order parameter `P_stag = P_a − P_b` condenses first
  (its quadratic coefficient `(α−g)/4` turns negative before `(α+g)/4`), giving the AFE
  phase `P_phys = P_a+P_b = 0`, `P_stag ≠ 0`. There is **one** zero-field minimum in `P`;
  the `±P_r` states are the **first-order AFE→FE transition's** double-hysteresis remnant,
  not degenerate wells. **[DIRECT — Kittel model as derived in the cited paper.]**
- **For HZO specifically, the honest caveat:** the "AFE" double hysteresis is a
  **field-induced non-polar tetragonal (`P4₂/nmc`) ↔ polar orthorhombic (`Pca2₁`) phase
  transition**, which many authors call "field-induced ferroelectric" rather than a true
  two-sublattice AFE. The Kittel model is the *framework*, not a literal description of the
  fluorite t↔o transition. **[DIRECT — the standard HfO₂ phase-transition picture; flagged
  by the AFE subagent.]**
- A **static multi-well** in a single HZO film requires **FE and AFE phases coexisting
  (coupled)** — that is the actual result of "Multiple Polarization States in Hf₁₋ₓZrₓO₂
  Thin Films by Ferroelectric and Antiferroelectric Coupling" (Zeng et al., *Adv. Mater.*
  2024, doi:10.1002/adma.202411463), which reports **3-bit/cell (8 states)** in Zr-rich HZO
  (x = 0.65–0.75) via a triple-peak coercive field (FE switching + reversible AFE–FE
  transition), stable to 125 °C and 10⁸ cycles. **[DIRECT — the cited paper.]**
- **No barrier-height number is published.** The TUFFC retention `>10⁴ s @ 65 °C` is
  indirect evidence the `±P` states sit behind a barrier ≫ `k_B T`: an Arrhenius estimate
  (`τ ≈ τ₀·e^(ΔE/kT)`, `τ₀ ~ 0.1–1 ns`) gives `ΔE ≈ 30–35 k_B T ≈ ~1 eV`. **[SPECULATION —
  my inference from the retention number, flagged; no source quotes an eV.]**
- The **memory** realizes 3 states *because of the hysteresis*, not because of three static
  wells: you write `+P_r`, `−P_r`, or leave `0` (the AFE ground state), and read all three.
  This is a **storage** answer, not a **logic** answer — no gain, no restoration, no fan-out.
  **[DIRECT for the storage mechanism; the "storage ≠ logic" split is `device_literature.md`
  §2.8/§3, reaffirmed.]**

So the honest calibration of `meta_transistor.md` §1.2 is: **DIRECT** as "a CMOS-compatible
film whose hysteresis gives 3 distinguishable polarization states"; **OVERSTATED** as
"3 free-energy minima at zero field." The fix matters because the "native 3-state" ideal the
brief wanted is a *memory part* here, not a transistor. **[OURS — the re-calibration; the
physics is DIRECT.]**

### 2.3 The multilevel memory demonstration (and what it does not show)

- **"Multipeak Coercive Electric-Field-Based Multilevel Cell Nonvolatile Memory With
  Antiferroelectric-Ferroelectric FETs"** (Liao, Hsiang, Lou, …, Lee, *IEEE TUFFC* 69(6)
  2214–2221, 2022, **doi:10.1109/TUFFC.2022.3165047** — note: the DOI `…3164805` circulating
  in `meta_transistor.md` is **wrong**; it resolves to an unrelated acoustics paper): an
  AFE-FE **field-effect transistor** whose FE+AFE domain mixture produces a **multipeak
  coercive field**, giving **4-level (2-bit) nonvolatile MLC** — *more* than the native 3.
  Reported: write `|V_P/E| = 4 V`, endurance **>10⁵ cycles**, retention **>10⁴ s @ 65 °C**.
  It is a **3-terminal FET** (gate), so it *does* have read gain and can fan out — but its
  stored states are still polarization levels read by a transistor threshold, not a
  restoring 3-state *logic* primitive. **Write/read energy and variability: NOT REPORTED.**
  **[DIRECT — paper; the NOT-REPORTED flags are explicit.]**
- **"Bilayer-Based Antiferroelectric HfZrO₂ Tunneling Junction … Multilevel Nonvolatile
  Memory"** (*IEEE EDL* 42(10) 1464–1467, 2021, doi:10.1109/LED.2021.3107940): a 2-terminal
  AFE tunnel junction (FE HZO + Al₂O₃), "multilevel," current ratio >100×, endurance 10⁸
  cycles. **Passive storage (2-terminal), no gain.** Exact level count and write energy NOT
  in the abstract. **[DIRECT.]**
- **"Multiple Polarization States in Hf₁₋ₓZrₓO₂"** (Zeng et al., *Adv. Mater.* 2024,
  doi:10.1002/adma.202411463): **8 states (3-bit/cell)** via FE+AFE coupling — the strongest
  native multi-state AFE-HZO result, but a *capacitor* (passive), not a transistor.
  **[DIRECT.]**
- **"Understanding fatigue and recovery mechanisms in Hf₀.₅Zr₀.₅O₂ capacitors"**
  (*Nanoscale* 2025, doi:10.1039/d4nr04861j): the AFE↔FE cycling is the fatigue mechanism;
  endurance >10⁹ cycles only with engineered recovery cycling, BEOL-compatible HZO
  capacitors. This bears directly on whether the *field-induced* `±P_r` states are endurant
  enough for a product — they are the states that wake up and fatigue. **[DIRECT.]**

**The storage-vs-logic line, stated once:** the AFE-FE *FET* has a gate (gain), but its
3-or-4 states are *stored polarizations* to be *read*, not restoring logic levels; the
capacitor/tunnel-junction variants are passive. AFE HZO is a **memory mechanism**, not a
"3-state logic transistor." This **strengthens the storage half** of `device_literature.md`
§2.8 and does **not** touch the logic wall. **[OURS — synthesis of DIRECT paper facts.]**

---

## 3. The key number — per-op energy of an AAT ternary inverter vs a binary CMOS inverter

### 3.1 The reference points (all DIRECT, in-repo)

- **Binary CMOS inverter (fair baseline):** **6.94 fJ/toggle**, single-ended 0→1 V
  (`fair_binary.md` §4 — `ngspice`, NOT gate). Binary NAND 11.36 fJ, NOR 8.65 fJ.
- **The radix-economy density:** one trit = `log₂3 = 1.585` bits; equivalently
  `1/log₂3 = 0.631` symbols per bit. **[DIRECT.]**
- **The `0.63×` per-bit bound:** ternary delivers `1.585×` the bits per *symbol*, so if a
  ternary operation costs the *same energy as one binary operation*, ternary costs
  `1/1.585 = 0.63×` per bit. That is the "free lunch" ceiling Ian's question gestures at.
- **The break-even:** ternary beats binary per bit iff `E_ternary/toggle < 1.585 × E_binary`,
  i.e. **`< 1.585 × 6.94 fJ = 11.0 fJ/toggle`**. Above 11 fJ, ternary *loses* per bit even
  with the density advantage. **[DIRECT — arithmetic.]**
- **The decision-count floor (independent of the device):** resolving 3 states needs
  `⌈log₂3⌉ = 2` binary decisions, so per bit the *decision* cost floor is
  `2/log₂3 = 1.262×` binary (`meta_math.md` §6). The AAT is precisely the "single native
  3-way decision" that *could* dodge this — see §3.3.

### 3.2 What the AAT inverter actually costs

**There is no measured switching energy for any AAT ternary inverter.** I verified this
directly: the primary papers report voltage, gain, current, PVR — and no fJ/toggle. The
2024 *Device* paper says it outright: for AATs "the **frequency characteristic and energy
efficiency are rarely explored**." **[DIRECT — quote from the paper; the absence is itself a
finding.]**

So the honest per-op number is an **order-of-magnitude bound**, not a measurement, and it is
dominated by **static current**, not `½CV²`:

1. **The AAT inverter is a *ratioed* inverter — this is the whole energy story.** An AAT +
   load in series is structurally an NMOS-style **ratioed** inverter: the output is a
   voltage divider between two devices that can both conduct. The middle state is the
   divider's equilibrium (both devices on, §1.3), and the load conducts whenever the AAT is
   on. **Complementary CMOS was invented precisely to eliminate this static current** (one
   device always off); the AAT ternary inverter gives that elimination back. **[DIRECT —
   the ratioed-vs-complementary contrast is textbook; the AAT inverter's ratioed structure is
   DIRECT from the papers' circuit diagrams.]**
2. **Demonstrated devices are slow or high-voltage.** Organic: VDD = **14 V**, nA currents,
   100–250 μm channels — even the ideal `½CV²` of a 1 pF node at 14 V is **~100 fJ/toggle**
   (≈14× the 6.94 fJ binary), and the static current (nA × 14 V ≈ nW) adds fJ (per μs) to
   pJ (per ms) *per cycle* before a useful bit is counted. 2D GaAsSb/MoS₂: VDD = 0.1–0.5 V
   but a **1 Hz** dynamic test with pA–nA currents — so its energy-**delay** is ~10⁹× worse
   than GHz CMOS regardless of the toggle energy. **[DIRECT for VDD/current/speed; the
   integration/energy-delay argument is OURS/SPECULATION — flagged, no measured number
   exists.]**
3. **Net:** for every demonstrated device `E_AAT(toggle) ≫ 11 fJ` (the break-even), and its
   **energy-delay** is orders of magnitude worse (slow switching × static current). The AAT
   does **not** cost ~1× a binary op; it costs `≫ 1.585×`. **[OURS — bound from DIRECT
   anchors.]**

### 3.3 Why it cannot hit `0.63×` per bit — three independent reasons

Even setting aside that the AAT is unfabricable (§4), the `0.63×` bound is unreachable, and
for reasons that are **physics, not engineering taste**:

1. **The Landauer floor is per-bit tied, never cheaper.** Erasing a trit costs
   `k_B T ln 3 = 4.55 zJ` = `1.585 × k_B T ln 2`. Per *bit* that is `k_B T ln 2 = 2.87 zJ`
   — **exactly identical to binary** (`device_physics.md` §5.1). At the thermodynamic limit
   there is no `0.63×`; the radix-economy saving and the higher per-digit cost cancel
   (`k_B T ln N` is radix-independent). The `0.63×` can only live **far above** the floor,
   in the `½CV²` regime — and that is exactly where the next two reasons bite.
   **[DIRECT.]**
2. **The 3-level SNR penalty cancels the density.** Three levels in one swing sit
   `V_swing/2` apart (unipolar) or require a split `±V` supply (balanced), so to hold the
   same bit-error rate against `kT/C` noise you spend ~2× the energy per level — which is
   precisely the `1.585×` density you were trying to cash in (`device_physics.md` §2.3,
   §5.3; `device_circuit.md` §7.2). **[DIRECT.]**
3. **The AAT adds static current on top.** Even in the idealized picture where (1) and (2)
   were somehow neutralized, the AAT inverter's divider mid-state and always-on load are a
   static-power term that complementary binary does not pay. **[DIRECT mechanism; OURS
   conclusion.]**

**Net:** the `0.63×` per-bit bound is a **density/namespace fact**, not an achievable energy
fact. The AAT resolves the *device-threshold* tax (two knees free from band alignment) but
**not** the static-current tax, the SNR tax, or the information tax. On energy it does not
tie a binary inverter, let alone hit `0.63×`. **[OURS — the three-way decomposition; every
term is DIRECT from the cited files.]**

---

## 4. The fabrication question — MoTe₂/2D AAT vs AFE HZO

### 4.1 The 2D MoTe₂ / AAT path: **research-demo only, and ~10–15 years behind even the 2D logic roadmap**

The AAT demonstrations are **exfoliated 2D flakes / transferred nanowires / evaporated
organic films**, on SiO₂/Si research substrates, single devices or a handful of devices.
There is **no wafer-scale AAT, no AAT in any PDK, and no 2D-semiconductor transistor in any
commercial product**. **[DIRECT.]**

The 2D-materials program *is* real, but it is about **unipolar MoS₂/WS₂/WSe₂**, not the n/p
hetero-/homojunctions an AAT needs:
- **IMEC/ASML/TSMC, June 2026:** first **300 mm integration of 2D transistors at 50 nm
  contacted-poly pitch** (complementary nFET/pFET) — "industry-ready" 2D *unipolar* FETs.
- **Intel (IEDM 2025):** "manufacturable" 2D transistors with high-NA EUV.
- **Roadmap:** 2D materials enter production logic only at the **A2 (≈2 Å) node, ~2041**;
  sub-1 nm nodes "won't arrive before 2034."

**[DIRECT — TechPowerUp/Heise/IMEC-roadmap citations.]** And a **correction to the premise
worth recording:** the 2019 **RV16X-NANO** (Hills et al., *Nature* 572, 595) is a
**carbon-nanotube** chip, *not* a 2D-material chip — it benchmarks CNT integration, not the
MoTe₂/2D question. **[DIRECT.]**

MoTe₂ specifically: **wafer-scale MOCVD MoTe₂ exists but only for spintronics (spin-orbit
torque), not FET PDKs.** The AAT's *extra* blockers beyond the unfinished 2D-FET problem:
(i) controlled n/p doping of a 2D homojunction at wafer scale (MoTe₂ is ambipolar and hard
to dope stably); (ii) **threshold/transfer-curve variability — the ternary "1" level sits at
the hump maximum, a narrow current window exquisitely sensitive to `V_th` spread, a yield
killer**; (iii) contact resistance / Fermi-level pinning; (iv) BEOL thermal budget + gate
dielectric; (v) **no array, no yield, no reliability data — everything is single/few-device.**
**[DIRECT for the state of the art; the blocker *ranking* is SPECULATION, flagged.]**

The papers themselves concede it: the 2024 *Device* paper notes organic/2D AATs have
"**large VDD values**" and "**instability**" that "**restrict the deployment of these MVL
devices for practical applications**." **[DIRECT — quote.]**

### 4.2 The AFE HZO path: **fab-adjacent memory, ~5–10 years ahead of the AAT — but not logic**

**The one fact that matters:** HfO₂/ZrO₂ is **the** CMOS high-k gate dielectric, and its
**ferroelectric sibling is entering production now** — CEA-Leti/GlobalFoundries demonstrated
embedded **FeRAM in 22FDX at IEDM 2024**, and Ferroelectric Memory Company (Dresden) is
ramping **FeRAM "DRAM+" (2025)**. AFE HZO is a *material variant on that identical ALD +
1T-1C/FeFET platform*, so it is **~5–10 years closer to fab than any 2D AAT**. **[DIRECT —
CEA/GF IEDM 2024; TrendForce 2025; the "~5–10 years" is the fabrication subagent's
readiness estimate, SPECULATION.]**

**But three honest limits:** (i) that production is **FE**, not AFE — no foundry ships
AFE-HZO multilevel memory (production FRAM is PZT; HfO₂-FeRAM is demo/R&D); (ii) AFE is a
**memory** answer — a capacitor/tunnel-junction has no gain, and even the AFE-FE *FET*'s
states are stored polarizations to be *read*, not restoring logic; (iii) **AFE as *logic*
has no demonstrated path** — the only "AFE gate" in the literature is negative-capacitance
(steep-subthreshold-swing) gate stacks, research only. **[DIRECT.]**

`device_literature.md` §2.8/§3 already drew the storage/logic line; AFE **strengthens the
storage half** without touching the logic wall. **[DIRECT — reaffirmed.]**

### 4.3 Verdict table

| device | mechanism resolves 3 states in one measurement? | fabricable at VLSI? | can restore/fan out? |
|---|---|---|---|
| **AAT (MoTe₂ / organic / GaAsSb-MoS₂)** | **yes** (one hump) | **no** (exfoliated/transferred, no wafer scale) | yes (it's a transistor) — but mid state draws static current |
| **AFE HZO** | **yes** (double hysteresis, +P/0/−P) | **closer** (CMOS film, memory programs) | **no** (passive storage; FET form = read only) |
| multi-Vt CMOS / CNTFET (the `device_literature.md` front-runner) | no (2 engineered thresholds) | **yes** (the only one) | yes |

**[Calibration: AAT row DIRECT mechanism + SPECULATION fab; AFE row DIRECT physics + DIRECT
memory demonstration, SPECULATION for any logic role; multi-Vt row DIRECT.]**

---

## 5. The honest verdict — is this the "complex transistor" that makes ternary cheaper?

**No.** The AAT is the *purest* live counterexample to "one device per threshold" — it
genuinely resolves 3 states in one measurement, from band alignment, with no engineered
threshold, no depletion, no sense amp. If "does a single device resolve 3 states" were the
whole question, the answer would be **yes, and it is called the AAT.** **[DIRECT.]**

But "cheaper" is the question, and on cost the AAT fails three independent tests:

1. **Energy:** its middle state is a static-current divider, no AAT reports a switching
   energy, and every demonstrated AAT is orders of magnitude above the 11 fJ break-even.
   It is `≫ 1.585×` a binary op, not `~1×`. **[DIRECT + OURS bound.]**
2. **Information:** even a perfect, static-free AAT carries `1.585` bits through `2`
   decision boundaries (the downstream still resolves 3 levels), and erases `k_B T ln 3`
   per trit — per bit, **tied** at the floor, never `0.63×`. **[DIRECT — `meta_math.md`
   §6, `device_physics.md` §5.]**
3. **Fabrication:** it is not VLSI-fabricable, and the fab-adjacent AFE HZO is memory, not
   logic. **[DIRECT.]**

So the correct, defensible program statement is the one `meta_transistor.md` §8.9 already
landed on: **"does a fabricable device resolve 3 states cheaper than 2 CMOS thresholds on
Tau's chosen 1-D amplitude code — or change the code to a non-amplitude degree of freedom
that is still fabricable?"** The AAT answers the *mechanism* half with a **yes**, and the
*fabrication + energy* half with a **no**. The `0.63×` per-bit bound stays a density fact,
not an energy fact. Ternary compute remains a **representation/interconnect economy**, not a
per-bit-energy economy — and the AAT does not overturn that. **[OURS — the synthesis; every
number above is DIRECT.]**

---

## 6. Calibration ledger

| claim | calibration |
|---|---|
| AAT transfer = non-monotonic hump with NDT, from series n/p band alignment | **DIRECT** — primary papers (2023/2024) + `meta_transistor.md` §1.1 |
| ternary inverter = AAT + load in series; mid state is a resistance-ratio divider | **DIRECT** — both papers' Fig. 1/4 mechanism text |
| mid state draws static current (not a dead zone) | **DIRECT** mechanism ("VDD divided between them"); "same failure as the unipolar STI" is **OURS** |
| organic AAT: VDD 14 V, I_p 220 nA, I_v 87 nA, gain 26–59 V/V, SNM 1.2 V | **DIRECT** — Panigrahi 2023, doi:10.1002/admt.202301049 |
| 2D AAT: VDD 0.1–0.5 V, PVR > 10³, 1 Hz test, ~8 V plateau | **DIRECT** — Lai 2024 *Device*, doi:10.1016/j.device.2023.100184 |
| no AAT switching energy is reported anywhere | **DIRECT** — verified in primary sources; the 2024 paper states "energy efficiency … rarely explored" |
| AFE HZO double hysteresis = +P/0/−P; orthorhombic FE vs tetragonal AFE (t↔o field-induced) | **DIRECT** — Kittel model (Lum 2022) + HfO₂ phase literature |
| "3 free-energy minima at zero field" | **OVERSTATED as stated** — 1 ground state (P=0) + 2 field-induced metastable FE remnant states; a static multi-well needs FE/AFE *coupling* (Zeng 2024, 8-state) |
| AFE is memory-class; AFE-FE FET has read gain but stores polarizations (not restoring logic) | **DIRECT** — `device_literature.md` §2.8/§3 + TUFFC 2022 (4-level FET) |
| binary inverter 6.94 fJ/toggle; break-even 11.0 fJ/toggle | **DIRECT** — `fair_binary.md` §4 + arithmetic |
| `0.63× = 1/log₂3`; `1.262× = 2/log₂3`; Landauer tied per bit | **DIRECT** — `trit_tricks.md`, `meta_math.md` §6, `device_physics.md` §5 |
| AAT does not hit 0.63× / costs ≫1.585× | **OURS** — bound from DIRECT anchors; no measurement exists |
| 2D MoTe₂ AAT = research-demo only (no PDK, no array); AFE HZO = fab-adjacent memory (~5–10 yr ahead), FE sibling in production | **DIRECT** (2024–2026 status) + **SPECULATION** (blocker ranking, readiness gap) |

---

## Sources

**AAT primary**

- Panigrahi, D., Hayakawa, R., Aimi, J., & Wakayama, Y. (2023). "Performance Enhancement of
  Organic Ternary Logic Circuits through UV Irradiation and Geometry Optimization." *Adv.
  Mater. Technol.* doi:10.1002/admt.202301049 — C8-BTBT/PTCDI-C8 AAT + PTCDI-C8 load, VDD
  14 V, I_p 220 nA, NDT `g_m` 0.3 μS, gain 26–59 V/V (→41 V/V), SNM 1.2 V.
- Lai, Z., Ho, J. C., et al. (2024). "Multifunctional anti-ambipolar electronics enabled by
  mixed-dimensional 1D GaAsSb/2D MoS₂ heterotransistors." *Device* 2, 100184.
  doi:10.1016/j.device.2023.100184 — AAT + GaAsSb p-FET ternary inverter, VDD 0.1–0.5 V,
  PVR > 10³, 1 Hz dynamic test; states the AAT "frequency characteristic and energy
  efficiency are rarely explored."
- Zhang, …, Pan (2025). "Near-Perfect Standard Ternary Inverter Based on MoTe₂ Homojunction
  Anti-Ambipolar Transistor." *Adv. Funct. Mater.* 35(29), art. 2424728.
  **doi:10.1002/adfm.202424728** — lateral doping homojunction, PVR > 10³, mid-state width =
  ⅓ input range.
- Wang, et al. (2025). "Multifunctional applications of 2D anti-ambipolar transistors:
  frequency doubling and multi-valued inverter design." *Nanoscale* 17(32).
  doi:10.1039/d5nr01914a — p-WSe₂/n-MoTe₂, VDD 0.7 V, 3 MHz.
- Panigrahi, D., Hayakawa, R., et al. (2020). "Optically Controlled Ternary Logic Circuits
  Based on Organic Antiambipolar Transistors." *Adv. Electron. Mater.*
  doi:10.1002/aelm.202000940.
- Kim & Hayakawa. "Fundamentals of Organic Anti-Ambipolar Ternary Inverters." *Adv.
  Electron. Mater.* 2020. doi:10.1002/aelm.201901200.
- Zhu & Mori (2022). "Output and Negative-Region Characteristics in Organic Anti-Ambipolar
  Transistors." *Adv. Electron. Mater.* doi:10.1002/aelm.202200783.
- Inbaraj, et al. (2021). "A Bi-Anti-Ambipolar Field Effect Transistor." *ACS Nano*.
  doi:10.1021/acsnano.1c00762 — vertical InSe/WSe₂, PVR ≈ 10⁴, quaternary inverter.

**AFE / HZO**

- Liao, Hsiang, Lou, Lin, …, Lee (2022). "Multipeak Coercive Electric-Field-Based Multilevel
  Cell Nonvolatile Memory With Antiferroelectric-Ferroelectric Field-Effect Transistors
  (FETs)." *IEEE TUFFC* 69(6), 2214–2221. **doi:10.1109/TUFFC.2022.3165047** (the
  `…3164805` DOI in `meta_transistor.md` is wrong).
- "Bilayer-Based Antiferroelectric HfZrO₂ Tunneling Junction With … Multilevel Nonvolatile
  Memory." *IEEE EDL* 42(10), 1464–1467, 2021. doi:10.1109/LED.2021.3107940.
- Zeng, Yin, Liu, Ju, et al. (2024). "Multiple Polarization States in Hf₁₋ₓZrₓO₂ Thin Films
  by Ferroelectric and Antiferroelectric Coupling." *Adv. Mater.* doi:10.1002/adma.202411463.
- Li, Majumdar, et al. (2025). "Understanding fatigue and recovery mechanisms in
  Hf₀.₅Zr₀.₅O₂ capacitors." *Nanoscale*. doi:10.1039/d4nr04861j.
- Lum, Lim, Chew (2022). "Revisiting the Kittel's model of antiferroelectricity: phase
  diagrams, hysteresis loops and electrocaloric effect." *J. Phys.: Condens. Matter* 34,
  415702. doi:10.1088/1361-648X/ac7e99.

**Fabrication / 2D-materials status**

- Hills, G., et al. (2019). "Modern microprocessor built from complementary carbon nanotube
  transistors." *Nature* 572, 595–602. (RV16X-NANO — CNT, not 2D.)
- IMEC/ASML/TSMC 300 mm 2D-transistor integration (50 nm CPP), June 2026; IMEC 2026–2041
  roadmap (2D logic at the A2 node ~2041).

**In-tree anchors**

- `meta_transistor.md` — §1.1/§1.2 (AAT + AFE as the missed mechanisms), §6.1/§6.3 (the tests
  this file runs), §8.9 (the re-worded go/no-go).
- `device_physics.md` — §0 (3 minima), §2.2 (driven vs self-held), §5 (Landauer + SNR).
- `device_circuit.md` — §3.2 (shoot-through vs depletion trade), §7.2 (1.5–2×/bit).
- `meta_math.md` — §6 (g(3) = 1.262×, T-new-2 escape condition).
- `fair_binary.md` — §4 (binary NOT 6.94 fJ/toggle, the baseline this file compares against).
- `trit_tricks.md` / `control.md` — the `0.63× = 1/log₂3` density framing.

*Every quantitative number in this file is either an in-repo measurement (`fair_binary.md`,
`device_physics.md`, `meta_math.md`) or a value read from a cited primary source. The
per-op energy comparison in §3 is an explicit order-of-magnitude bound, flagged as OURS,
because no AAT switching energy has ever been published.*

---

## TODO / not covered / caveats

1. **The MoTe₂ homojunction STI paper is identified but its gain/margin/supply are still
   paywalled.** It is Zhang, …, Pan, *Adv. Funct. Mater.* 2025, 35(29), 2424728,
   doi:10.1002/adfm.202424728 — lateral doping homojunction, PVR > 10³, mid-state width = ⅓
   input range (§1.5). But **voltage gain, noise margin, load resistance, and VDD are NOT in
   the accessible abstract** (Wiley paywall; direct fetch Cloudflare-blocked). Before quoting
   the MoTe₂ inverter's gain/SNM/supply downstream, the full text must be pulled
   (`meta_transistor.md` TODO #1 is *narrowed*, not closed).
2. **No AAT switching energy exists to cite — this is a finding, not a gap I could fill.**
   The per-op comparison in §3 is an *order-of-magnitude bound* from VDD/current/speed, not a
   measurement. Anyone who wants a real number must build a compact model and run
   `test_suite_spec.md` — which is currently impossible for an NDT device (`device_circuit.md`
   TODO #1, `meta_critique.md` A8).
3. **The AFE "3 minima" re-calibration (§2.2) is my inference from the Kittel/Landau
   structure, not a reproduced phase diagram.** I did not compute barrier heights or
   verify whether the `±P_r` remnant states of *pure* AFE HZO are retained long enough to
   count as "stable" (the `meta_transistor.md` TODO #2 is still open). The Zeng et al.
   "multiple polarization states via FE/AFE coupling" paper is the primary to pull next.
4. **The AAT static-current claim is mechanism-DIRECT, not measured.** "Both devices
   conduct at the middle state" is stated by the papers (it's how the divider works), but I
   did not find a measured standby/mid-state current number for the ternary inverter as a
   circuit. The `meta_transistor.md` TODO #1 question ("is the mid level a dead zone?") is
   now answered *mechanistically* — **no, it is a divider** — but the *magnitude* of the
   static current is unmeasured.
5. **Fabrication specifics are partially SPECULATION.** "2D AAT has no VLSI path" is the
   settled state of the art (DIRECT — IMEC/ASML/TSMC 300 mm 2D FETs are unipolar
   MoS₂/WS₂/WSe₂, ~2041 A2-node roadmap, no MoTe₂ PDK), but the *specific blocker ranking*
   (n/p homojunction doping variability vs `V_th`-spread-at-the-hump vs contact resistance) is
   my ordering, not a cited roadmap. The fabrication subagent's report is incorporated in §4;
   the ranking itself remains SPECULATION.
6. **`0.63×` vs `1.262×` is a genuine two-bounds subtlety, stated but not unified.** §3
   treats `0.63×` as the density ceiling and `1.262×` as the decision floor; they are
   *different* bounds (density vs decision count), and this file argues the AAT fails both.
   A dedicated pass could state the exact condition under which a "single native 3-way
   decision" (AAT) *would* beat the `1.262×` floor — that is `meta_math.md` T-new-2, and it
   remains an untested *if*, not a measured *yes*.
7. **No reversible/adiabatic treatment.** `device_physics.md` TODO flags that reversible
   logic can in principle go below `k_B T ln 2`; whether an AAT or AFE interacts with
   adiabatic ternary differently than binary is **not** covered and could in principle change
   the "no per-bit win" verdict — but it would not make an *unfabricable* device fabricable.
8. **RFET is the conceptual sibling and is only name-checked here.** The reconfigurable-
   polarity FET's three states are `n/off/p` — the *sign* of the majority carrier, literally
   "polarity is value." It is arguably the *better* conceptual match to Tau than the AAT, and
   it is out of scope for this file (see `meta_transistor.md` §1.3).

---
