# Polar Memristors / Direction-Encoded Resistive Memory — Honest Audit

**Question asked by the principal:** does a direction-encoded (polarity-dependent) memristor beat the 2-bit/trit ternary cell on STORAGE energy/density — or is it another "0.63× native floor" flattery?

**Discipline:** borrow, don't trust. Every claim below is tagged **DIRECT** (stated by a named source I read), **ANALOGY** (cross-domain mapping, not an identity), **OURS** (this project's already-settled verdict, cited from the task brief), or **SPECULATION** (my own reasoning, not a measured/sourced number).

**Bottom line (read this first):**

1. **"Polar memristor" is not one device class.** The literature splits into **bipolar** / **unipolar** switching (about how SET/RESET voltages are signed) and **self-rectifying** (a diode-like asymmetry used as a *selector* to kill sneak paths). None of these is a "direction-encoded trit cell." **[DIRECT]**
2. The seed patent "polarity-dependent switch" is an **access-transistor selector**, not a trit. The seed "trinary memristor cell" paper is a **magnitude 3-level read circuit**, not direction-encoded. **[DIRECT]**
3. The only real direction-encoded devices (ferroelectric diodes, memdiodes, reconfigurable rectifiers) are **proof-of-concept materials results with zero reported storage energy / density / endurance / variability numbers.** **[DIRECT]**
4. Direction-encoding does **not** sidestep the 2-threshold tax — it *swaps* two magnitude thresholds for a two-polarity probe + comparison, and the "free null" is a property of the **transport axis** (the wire), not of a storage cell that must actively hold and read the null. **[SPECULATION + ANALOGY, argued below]**
5. **Verdict: same answer as every native device.** The one paper that reports honest per-trit numbers (TReMo+) gets its entire density "win" from the information-theoretic 1/log₂3 factor while *assuming the native 3-level cell is free*, and its own write-verification data (12 vs 5 iterations to land the middle state) *is* the 2-threshold tax, repriced as write energy. No direction-encoded device reports beating the 2-bit encoding on the honest (per-bit, endurance-included, variability-included) axis.

---

## 1. What "polar memristor" actually means

### 1.1 Bipolar vs unipolar (the switching *polarity*, not a trit)

Resistive-switching memories are classified by the sign of the write voltage **[DIRECT — [srep36652 intro]](https://www.nature.com/articles/srep36652)**:

- **Bipolar:** SET at one polarity, RESET at the opposite polarity. The TaOₓ devices in the ternary-arithmetic paper are explicitly described as "switched to a low resistive state (LRS) for a positive SET voltage and switched to the high resistive state for a negative RESET voltage."
- **Unipolar (nonpolar):** SET and RESET at the *same* polarity, distinguished by current magnitude (RESET is Joule-heat driven at higher current). Less common today.

These are about **how you write a 2-state bit**. They say nothing about encoding a trit. A bipolar memristor is "polarity-dependent" in the trivial sense that you need both signs to toggle it — this is **not** direction-encoded storage; it is the standard 2-state ReRAM write scheme. **[DIRECT + OURS framing]**

### 1.2 Self-rectifying = a built-in *selector*, not a third state

Self-rectifying memristors (SRMs) add a diode-like I–V asymmetry to the switching stack so that a crossbar cell conducts in only one direction, suppressing sneak-path current without a separate selector transistor. The figures of merit are **rectification ratio**, **nonlinearity**, **endurance**, **retention**, **variability** — and the point is array selectivity, not multi-state storage. **[DIRECT — [Nanomicro Lett SRM review]](https://nmlett.org/index.php/nml/article/view/2328), DOI [10.1007/s40820-025-02035-1](https://doi.org/10.1007/s40820-025-02035-1)]**

Terminology collision to flag: a "self-rectifying" device is asymmetric, but its asymmetry is a **fixed** diode direction used to *select* the cell. It is not a device whose **rectification direction is itself the stored symbol**. The latter is the principal's actual proposal, and it is a different, much rarer beast (Section 3).

### 1.3 The seed patent is a selector, not a trit

[US20120039111 "Polarity dependent switch for resistive sense memory"](https://patents.google.com/patent/US20120039111A1/en) (Seagate, priority 2008, MRAM-era). The abstract describes: a resistive sense memory cell (high/low resistance) **in series with a semiconductor transistor**, where the transistor's source is "more heavily implanted with dopant material than the bit contact." The "polarity-dependent switch" is the **asymmetric-doping access transistor** (a polarity-dependent MOS pass gate), inherited from "Polarity Dependent MOS Switch for Spin-Torque RAM." **[DIRECT — patent abstract/background]**

**Calibration: the seed patent is about the array access device, not about direction-encoded storage.** Its "polarity dependence" is the selector's asymmetric on/off behavior. It does not encode a trit by current direction. The title flatters the principal's hypothesis; the claims do not support it.

---

## 2. The "trinary memristor cell" that actually exists — it is magnitude, not direction

### 2.1 Seed paper: an *adaptive read/write circuit* for a 3-level cell (no storage numbers)

[An Adaptive Trinary Read/Write Circuit Based on Digital Memristors](https://ieeexplore.ieee.org/abstract/document/10928321) (IC2ECS 2024, DOI [10.1109/ic2ecs64405.2024.10928321](https://doi.org/10.1109/ic2ecs64405.2024.10928321)). Full abstract recovered via OpenAlex **[DIRECT]**:

> "…an adaptive trinary read/write circuit for the digital memristors based on 180nm standard CMOS process. The selection of digital memristors can effectively avoid the issue of state offset… the read circuit employs **three amplifiers** to incrementally amplify the voltage, with the **three output ports serving to independently represent the three resistive states**, thereby providing support for the envisaged trinary system."

What this actually is:

- The **three resistive states are magnitude levels** read by three amplifiers (three-way threshold discrimination). **[DIRECT]**
- "Digital memristor" = they deliberately keep well-separated two/three digital levels to avoid analog *state offset* (variability) — i.e. the paper's own premise is that multi-level state drift is the enemy. **[DIRECT]**
- It is a **read/write circuit-design paper in a 180 nm CMOS process library.** It reports **no storage energy, no density, no endurance, no retention, no variability** numbers for the cell. It is not a storage-axis energy/density claim. **[DIRECT — absence of such numbers in the abstract]**

So the "trinary memristor cell that already exists" does **not** use direction encoding, and it does **not** report a storage energy/density win. It re-implements, in CMOS, the exact magnitude-discrimination read the principal wants to escape.

### 2.2 The native multi-state device (TaOₓ): magnitude stop-voltage grading

[Multistate Memristive Tantalum Oxide Devices for Ternary Arithmetic](https://www.nature.com/articles/srep36652) (Sci. Rep. 2016, [PubMed 27834352](https://pubmed.ncbi.nlm.nih.gov/27834352/)) — a **seven-state** (LRS + six levels) Pt/W/TaOₓ/Pt device for radix-3 modular arithmetic. **[DIRECT]**

- States are set by **RESET stop-voltage magnitude** (V_stop −1.50→−2.25 V in 0.15 V steps → six resistance levels). This is **magnitude discrimination**, not direction. **[DIRECT]**
- The paper itself: "three resistive states would be sufficient" for ternary — they used six only as a demo. **[DIRECT]**
- **No measured per-operation energy.** The discussion says only: "The energy per operation depends on the device properties… Since the pulse width (t) that will be used in real application is much shorter than 200 ns (used in study), the final power consumption will be reduced further." That is a *hand-wave toward lower energy*, not a number. **[DIRECT — flag as variability-free / not measured]**
- **Sample size is tiny:** "Each state is based on 5 devices with 10 cycles." No C2C/D2D variability stats, no endurance, no retention for the multilevel states. **[DIRECT — flag]**
- The paper reproduces our "compute tax" in its own words: "the actual gain will be somehow **smaller due to need for better sense amplifiers and more control circuitry**," and "this requires **ultra-low variance ReRAM devices**" (a future requirement, not demonstrated). **[DIRECT — this is our settled AAT verdict restated by a device group]**

The generic marketing-grade numbers in the *introduction* ("scaled to 5 nm, endurance up to 10¹² cycles, 10 years retention, <200 ps") are **borrowed industry claims, not measured in this paper** — flag as marketing/variability-free. **[DIRECT + OURS flag]**

### 2.3 The honest numbers (TReMo+): density win = the 0.63× factor, paid in write-verification

[TReMo+: Modeling Ternary and Binary ReRAM-Based Memories With Flexible Write-Verification Mechanisms](https://www.frontiersin.org/journals/nanotechnology/articles/10.3389/fnano.2021.765947/full) (Front. Nanotechnol. 2021, FAU Erlangen). A **circuit-level model**, not measured silicon. **[DIRECT]**

Key results (extracted from the paper's tables) **[DIRECT]**:

| Metric | SLC (1 bit/cell) | Ternary (3 levels) | Readout |
|---|---|---|---|
| Cells for 8.4M-bit-class memory | 8,388,608 | 4,194,304 | half the cells (that's the whole "win") |
| Area cost per trit / per bit | 0.7738 µm²/bit | 0.7846 µm²/trit | per-cell: ternary is **1.4% larger** |
| Write-verification iterations | 5 | **12** | middle-state landing costs 2.4× |
| Read | single compare | serial (2 compares) or parallel (2 sense amps) | the 2-threshold tax, verbatim |

Read this honestly:

- The per-**cell** footprint is essentially identical (0.78 µm²/trit vs 0.77 µm²/bit). The entire ~1.58× per-bit density "win" is **1/log₂3 = 0.63× area per bit**, i.e. purely the information-theoretic factor, *conditional on the 3-level cell being as cheap as a 1-bit cell*. TReMo+ **assumes** that. It does not charge the native cell for its extra cost. **[DIRECT numbers + OURS interpretation]**
- The **read is the 2-threshold discrimination** the principal wants to avoid: serial = two sequential comparisons, parallel = two sense amplifiers. The parallel read recovers latency but at the cost of a second sense amp (area/energy). **[DIRECT]**
- The **write is the real tax**: landing the middle level needs write-verification with **12 vs 5 iterations**; their own Table 3 shows that finer voltage stepping for the middle state (V_step 0.05 V) pushes write latency to ~280 µs and write energy to ~2335 nJ vs ~1244 nJ at coarse 0.4 V steps — i.e. ~1.9× energy to buy middle-state precision. **[DIRECT]**
- TReMo+ is a **variability-light model**: it prices variability only through the write-verification iteration count; the headline area/energy tables assume the verification *succeeds*. No endurance degradation, no retention, no C2C/D2D spread in the "cost per trit." **[OURS flag — this is exactly the "variability-free figure" the audit is supposed to catch]**

TReMo+ also confirms the 2-bit premise: "realizing ternary states with binary storage elements requires two binary storage elements… making such designs immensely expensive," and it cites Junsangsri et al. (2014), which "uses **two memristors to obtain three different states**… but loses the advantage of saving one storage cell." So the *native 3-level* route is the only one that could beat 2-bit on density, and it pays for it in write/read discrimination. **[DIRECT]**

---

## 3. The direction-encoded devices (closest to the principal's idea)

These are real, but they are **materials demonstrations, not storage cells with reported energy/density/endurance.**

### 3.1 Ferroelectric diode with tri-state via rectification *direction* (the genuine "direction-encoded trit")

[Ferroelectric diode characteristic and tri-state memory in self-assembled BiFeO₃ nanoislands with cross-shaped domain structure](https://doi.org/10.1063/5.0096858) (Appl. Phys. Lett. 2022). **[DIRECT]**

> "the cross- and quad-domains show diode-like transport behaviors but with **different rectification directions** owing to their different polarization orientations. Specifically, an intriguing two-step ferroelectric polarization switching can be realized, which locally results in a **tri-state nonvolatile memory**."

This is the closest physical realization of the principal's intuition: the **stored symbol is the rectification direction** (polarization orientation), and a third domain configuration gives a third state. **But:** it is an epitaxial-nanoisland microscopy/demonstration result. **No endurance, no retention, no energy, no array integration, no variability statistics are reported.** **[DIRECT — absence]**

The honest read: this device confirms the *existence* of direction-encoded 3-state storage, and simultaneously confirms that the field has **not** produced energy/density/endurance numbers for it — the principal's question is answerable as "no evidence it beats 2-bit, and no numbers at all."

### 3.2 Memdiode: history-dependent rectification, but "ternary" = synaptic plasticity, not a storage trit

[Ternary Synaptic Plasticity Arising from Memdiode Behavior of TiOₓ Single Nanowires](https://advanced.onlinelibrary.wiley.com/doi/abs/10.1002/aelm.201500359) (Adv. Electron. Mater. 2016, DOI [10.1002/aelm.201500359](https://doi.org/10.1002/aelm.201500359)) — defines the **memdiode**: a device with "strongly history-dependent rectifying behavior." The "ternary" is **ternary synaptic plasticity** (three Hebbian plasticity regimes, via resistance + photocurrent), **not** a 3-symbol storage cell. **[DIRECT]**

[Scalable Memdiodes Exhibiting Rectification and Hysteresis for Neuromorphic Computing](https://pmc.ncbi.nlm.nih.gov/articles/PMC6113211/) (Sci. Rep. 2018, DOI [10.1038/s41598-018-30727-9](https://doi.org/10.1038/s41598-018-30727-9)) — Nb₂O₅₋ₓ memdiodes, forming-free. **Neuromorphic application, no storage-trit energy/density claim.** **[DIRECT]**

**Calibration:** "memdiode" is a *rectifying + hysteretic* device class. Its direction-dependence is real, but the literature uses it for **synapses and selectors**, not for encoding a balanced-ternary trit, and no paper reports a storage-axis energy/density win from it. **[DIRECT + OURS]**

### 3.3 Reconfigurable rectification (switchable diode direction)

[A reconfigurable memristor diode based on a CuInP₂S₆/graphene lateral heterojunction](https://pubs.rsc.org/en/content/articlelanding/2025/nr/d4nr03400g) (Nanoscale 2025, [PubMed 39641375](https://pubmed.ncbi.nlm.nih.gov/39641375/)) — "reconfigurable characteristics of the diode under the control of only lateral voltage," via Cu⁺ migration changing barrier height. Again a **device demonstration**, no storage energy/density/endurance. **[DIRECT]**

These are the class of "switchable-rectification" devices. Collectively: **they show a direction-encoded symbol is physically possible, and none of them reports a number that competes with a 2-bit cell.** **[OURS synthesis]**

### 3.4 Terminological collision to flag

"3D self-rectifying memristive **ternary** content addressable memory" ([Sci. China Inf. Sci.](https://cdn.sciengine.com/doi/10.1007/s11432-024-4253-9)) uses "ternary" in the **TCAM sense** — a match line with 0 / 1 / X (don't-care), stored as a **2-bit encoding**, not a 3-state storage cell. Do not count TCAM "ternary" as a trit cell. **[DIRECT + OURS flag]**

---

## 4. Honest verdict on the principal's question

### 4.1 Does direction-encoding sidestep the 2-threshold tax? **No.** [SPECULATION + ANALOGY]

The 2-threshold tax is the cost of discriminating a 3-valued *magnitude* into three bins. Direction-encoding replaces it with a **2-polarity probe**: to read a direction-encoded trit you must apply a small bias in *both* polarities and compare the two resulting currents (or their ratio). That is still **two discrimination operations** — a sign/direction comparison *and* a null-vs-non-null magnitude comparison — plus the extra energy of driving current in both directions on every read. **[SPECULATION — physical argument, not sourced; flagged as reasoning]**

Worse: in the magnitude-multilevel cell the read is *one* voltage ramp and one or two comparisons; in the direction cell the read is *two* probes plus a comparison, with the rectifying device's on-state current flowing in at least one direction. There is **no free lunch** — direction-encoding does not delete the discrimination step, it relabels it. **[SPECULATION]**

### 4.2 The "free null" does not transfer from transport to storage. [OURS + ANALOGY]

The project's null (00 = no current) is free **on the wire**, because *not sending* costs nothing — that is the **transport axis** win (the ~2.7–6.3×). A **storage cell** must *hold* the null as a persistent physical state and *read* it back; "no current" is not a stable stored state in a memristor (a zero-current, symmetric or double-high-resistance state still has to be programmed and probed). So the principal's intuition borrows a transport property and applies it to the storage axis, where it does not hold. **[OURS framing + SPECULATION; consistent with the project's settled "addressing/transport are the wins, storage is not"]**

### 4.3 0.63× is a *density ceiling*, not an energy win — and every device confirms it. [OURS]

1/log₂3 = 0.6309 is the maximum per-bit area shrink a trit *could* deliver if a trit cell cost exactly as much as a bit cell. It is information-theoretic, **silent on energy, endurance, and variability**. TReMo+'s tables demonstrate this precisely: its entire ~1.58× density comes from packing 1.585 bits into a cell it *assumes* is free, while its own write-verification data (12 vs 5 iterations; ~1.9× energy for middle-state precision) is the tax the 0.63× headline hides. **[OURS + DIRECT numbers]**

### 4.4 The answer

**Same answer as every native device, and then some.** On the honest (per-bit, endurance-included, variability-included) storage axis:

- **No direction-encoded memristor reports any energy/density/endurance/variability number at all.** The genuine direction-encoded trit (BiFeO₃ ferroelectric diode) is a proof-of-concept with zero storage metrics. **[DIRECT]**
- **The trinary cells that *do* report numbers are magnitude-multilevel devices read by 2-threshold discrimination** — the exact mechanism the principal wanted to escape — and they either report no energy (TaOₓ) or get their win only by assuming a free native cell and hiding the tax in write-verification (TReMo+). **[DIRECT]**
- **Direction-encoding does not remove the discrimination tax; it converts it into a two-polarity read and re-prices the null.** The "free null" is a transport property, not a storage property. **[SPECULATION + OURS]**

Net: **a direction-encoded memristor does not beat the 2-bit/trit cell on storage energy/density; it is another "0.63× native floor" flattery, and a *worse*-evidenced one than the AAT, because it currently has no measured numbers at all.** The project's actual wins remain addressing (3ⁿ) and transport (the wire), not storage. **[OURS verdict, consistent with the settled AAT audit]**

---

## 5. Sources

- [An Adaptive Trinary Read/Write Circuit Based on Digital Memristors — IEEE Xplore 10928321](https://ieeexplore.ieee.org/abstract/document/10928321) (DOI [10.1109/ic2ecs64405.2024.10928321](https://doi.org/10.1109/ic2ecs64405.2024.10928321)) — abstract via OpenAlex.
- [Multistate Memristive Tantalum Oxide Devices for Ternary Arithmetic — Sci. Rep. 6:36652](https://www.nature.com/articles/srep36652) / [PubMed](https://pubmed.ncbi.nlm.nih.gov/27834352/).
- [TReMo+: Modeling Ternary and Binary ReRAM-Based Memories… — Front. Nanotechnol. 2021](https://www.frontiersin.org/journals/nanotechnology/articles/10.3389/fnano.2021.765947/full) (DOI [10.3389/fnano.2021.765947](https://doi.org/10.3389/fnano.2021.765947)).
- [US20120039111 — Polarity dependent switch for resistive sense memory (Seagate)](https://patents.google.com/patent/US20120039111A1/en).
- [Ferroelectric diode characteristic and tri-state memory in BiFeO₃ nanoislands — Appl. Phys. Lett. 2022](https://doi.org/10.1063/5.0096858) (DOI [10.1063/5.0096858](https://doi.org/10.1063/5.0096858)).
- [Ternary Synaptic Plasticity from Memdiode Behavior of TiOₓ Nanowires — Adv. Electron. Mater. 2016](https://advanced.onlinelibrary.wiley.com/doi/abs/10.1002/aelm.201500359) (DOI [10.1002/aelm.201500359](https://doi.org/10.1002/aelm.201500359)).
- [Scalable Memdiodes Exhibiting Rectification and Hysteresis — Sci. Rep. 2018](https://pmc.ncbi.nlm.nih.gov/articles/PMC6113211/) (DOI [10.1038/s41598-018-30727-9](https://doi.org/10.1038/s41598-018-30727-9)).
- [A reconfigurable memristor diode (CuInP₂S₆/graphene) — Nanoscale 2025](https://pubs.rsc.org/en/content/articlelanding/2025/nr/d4nr03400g) ([PubMed](https://pubmed.ncbi.nlm.nih.gov/39641375/)).
- [Self-Rectifying Memristors for Beyond-CMOS Computing — Nano-Micro Lett. review](https://nmlett.org/index.php/nml/article/view/2328) (DOI [10.1007/s40820-025-02035-1](https://doi.org/10.1007/s40820-025-02035-1)).
- [3D self-rectifying memristive ternary CAM — Sci. China Inf. Sci.](https://cdn.sciengine.com/doi/10.1007/s11432-024-4253-9) (terminological collision: TCAM "ternary" = 2-bit X state).
- Marketing figure flagged as such: [TetraMem 22 nm multi-level RRAM analog SoC announcement](https://www.businesswire.com/news/home/20260516556464/en/) — not used for any number here.

---

*Audit notes: figures flagged "marketing/variability-free" above are (a) the generic ReRAM endurance/retention/speed claims in the srep36652 *introduction*, (b) TReMo+'s area/energy tables (a model that assumes verification succeeds and prices no endurance/retention/variability), and (c) the TetraMem press release. The direction-encoded devices contribute no numbers because they report none.*
