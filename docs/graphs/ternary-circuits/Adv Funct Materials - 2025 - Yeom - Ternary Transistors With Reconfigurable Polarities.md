# Ternary Transistors With Reconfigurable Polarities
Yeom, Ko, Ko, Im, Song, Seok, Jang, Hwang, Jin, Watanabe, Taniguchi & Lee, Advanced Functional Materials 35, 2502112 (2025). Fabricated polarity-reconfigurable **ternary transistors** in few-layer black phosphorus (BP) homojunctions with asymmetric Au/In contacts and split gates: an ambipolar transistor is converted to a p-type *ternary* transistor (≈50× on–off improvement, well-defined intermediate state), and — via the antisymmetric device architecture — electrically switched to an n-type ternary operation with a *matched* intermediate state. This is the closest fabricated silicon-adjacent realization of Ian's "polarity is the value" idea: the carrier polarity (hole vs electron direction) is the controllable, information-bearing degree of freedom.

## 1. Node inventory (id | type | name | one-line | location)

| id | type | name | one-line | location |
|----|------|------|---------|----------|
| N1 | CLAIM | MVL reduces circuit resources | ternary logic reduces circuit complexity to 63.1% of binary, quaternary to 50% (citing Hurst 1984) — fewer transistors, less interconnect power | §1 |
| N2 | CLAIM | the CMOS gap | both p- and n-type multi-valued transistors with stable intermediate states are rare, especially without CMOS-incompatible heterostructures; this is why MVL is uncommercialized | §1 |
| N3 | METHOD | device architecture | BP homojunction, asymmetric contacts Au (near valence band) / In (near conduction band) with antisymmetric Schottky barrier heights ΦSBH, split gates (main gate VG + control gate VCG) | §2, Figs 1–3 |
| N4 | RESULT | ambipolar → p-type ternary | VCG suppresses electron injection from Au ⇒ unipolar p-type with a well-defined intermediate state; ≈50× Ion/Ioff improvement | §2, Fig 3b,c |
| N5 | RESULT | mechanism of the intermediate state | current-constant middle state = weakly gate-dependent **minority-carrier injection** (holes from In, ≈0.1 μA/μm); Landauer/JFNT analysis matches | §2, Fig 2d,f |
| N6 | RESULT | reconfigurable polarity | antisymmetric ΦSBH (p-type ΦSBH of In ≈ n-type ΦSBH of Au) lets the same device switch electrically between p-type and n-type ternary operation with matched intermediate-state currents | §2, Fig 4 |
| N7 | RESULT | tunability + the ternary→binary edge | Jmiddle controlled by VD, VCG, VBG, tBP; for tBP < 8 nm the intermediate state *disappears* (higher ΦSBH) — the device reverts to binary | §2, Fig 3d–g |
| N8 | DEFINITION | the three states | on (VG<0), intermediate (VG≈0, gate-independent minority current), off (VG>0, reverse-biased p–n junction leakage) | §2, Fig 3a,b |
| N9 | CLAIM | first demonstration | "the first to demonstrate the reconﬁgurable polarity of a ternary transistor" (per the authors); performance metrics still need improvement | §2, §3 |
| N10 | RESULT | ΦSBH antisymmetry + Eg | n-type ΦSBH of Au ≈ p-type ΦSBH of In; Eg recovered as their sum — the symmetry that makes n/p intermediate states match | §2, Fig 1g,h |

## 2. Edge inventory (src→tgt | type | calibration | evidence)

| src→tgt | type | calibration | evidence |
|---------|------|-------------|----------|
| N1→N2 | supports | — | the complexity/power promise is why the missing p/n ternary devices matter |
| N3→N4 | derives-from | — | split gate + asymmetric contacts produce the ternary operation |
| N4→N5 | derives-from | — | the middle state's physics is the weak VG-dependence of minority injection |
| N3→N6 | derives-from | — | antisymmetric contacts are what make polarity reconfiguration possible |
| N10→N6 | requires | — | matched intermediate states rest on the antisymmetric ΦSBH pair |
| N5→N7 | supports | — | weak VG-dependence of Jmiddle is exactly what makes it tunable by VD/tBP/VCG |
| N7→N8 | supports | — | the thin-BP data pin down when the ternary→binary transition happens |
| N6→N9 | derives-from | — | reconfigurable polarity is the claimed novelty |
| N6→N1 | supports | — | complementary (n+p) ternary logic advances the MVL efficiency story |
| N5→N8 | derives-from | — | the intermediate state IS the weakly-injected minority current |

## 3. Counter-to / reversal edges

- **C1 — "Better (thinner/more ideal) devices give cleaner ternary" is INVERTED.** As tBP shrinks below 8 nm, the intermediate state *vanishes* (increased ΦSBH suppresses minority-carrier injection) and the device reverts to binary operation. The third state is a *parasitic, imperfect-device feature* — improved electrostatics destroy it. This is the sharpest honest counter to any naive "ternary is just better engineering" reading.
- **C2 — "The intermediate/null state is free" is FALSE here.** Jmiddle ≈ 0.1 μA/μm is a real minority-carrier current — gate-independent, but energetically present. It is not our null (no electrons). (counter-to: our "null costs nothing"; flagged for calibration, not for dismissal — the *level* of the middle state is tunable via VD, which is a design handle our null lacks.)
- **C3 — "Ternary needs more transistors than binary" is the wrong objection here.** Prior threshold-based ternary circuits ([7–9]) do use *more* unit devices; a single device with an intrinsic third state avoids the transistor-count penalty entirely. (reversal of the standard MVL-cost critique; consistent with N1.)
- **C4 — "Polarity-reconfigurable" ≠ "the ternary state is polarity."** The device's *mode* (p-type vs n-type operation) is what's electrically reconfigurable; the three ternary states themselves are current **levels** (on/intermediate/off). Polarity is the *carrier type*, not the per-trit information encoding. (Honest boundary on the "polarity is the value" mapping — see lens.)

## 4. Map-to-current-system (lens) — TERNARY CIRCUITS

| paper concept | our system | calibration | evidence |
|---------------|-----------|-------------|----------|
| **Single device, three states** (on/intermediate/off) — ternary *per device*, no multi-transistor threshold stacks | our ternary cell: 2 bits one-hot-per-direction `01=push/00=null/10=pull/11=never`, energy ≤1 line (TernaryCell.lean, PROVED; rtl/trit_functions.vh header) | **ANALOGY** | both are 3-state-per-cell architectures; but their states are current LEVELS set by VG thresholds, ours are DIRECTION-encoded (push/pull/null) — the architecture parallels, the encoding differs |
| **Reconfigurable polarity = carrier direction (hole vs electron) as a controllable, information-bearing degree of freedom** | **"polarity is the value"** — one-wire push/pull/null read by the *direction* of the excursion, not the level (TERNARY_PROCESSOR §1.2; plan §3; 2-diode receiver sketch) | **ANALOGY (closest silicon precedent)** | the same principle in silicon: the direction of charge flow (carrier polarity) is what's set and switched; it validates the *plausibility* of direction-as-information — but per C4 their ternary data is level-based and their polarity is a device *mode*, so it is not the identical mechanism. This is the paper Ian flagged as "polarity is the value in silicon" — the honest calibration is ANALOGY with strong plausibility support (SPECULATION-support for the one-wire story), not DIRECT |
| **Matched p/n intermediate states "crucial for complementary circuits"** | balanced/symmetric ternary: negation = free digit swap −1↔+1, symmetric range ±(3ⁿ−1)/2 (TERNARY_PROCESSOR §1.1) | **ANALOGY** | both need the two "halves" of the ternary system to be symmetric (their n/p matched middles, our balanced digit set) — different layers (device complementarity vs number-system symmetry) |
| **MVL complexity 63.1% of binary (ternary), 50% (quaternary)** | radix economy log₂3 ≈ 1.585 bits/trit; energy avg 2/3 vs binary 1 (STATE_NOTE; TernaryCell) | **DIRECT** | the standard MVL efficiency argument family — their system-level transistor/interconnect accounting vs our per-trit line-energy accounting; ours is additionally Lean-proved at the cell level |
| **VCG blocks one carrier polarity (electron injection suppressed)** | `11 = never` (both lines energized never produced); null as the inactive state | **SPECULATION** | VCG "switches off" one polarity channel — structurally like an excluded combination; no math connects a control gate to our one-hot encoding |
| **Device physics (ΦSBH, Landauer/JFNT, BP band gap 0.3–2.0 eV)** | `rtl/` gates + yosys flow (~6–7K cells, 213 FFs, iverilog verified); plan guardrail 5: silicon claims out of scope | **NONE / OURS** | a fabricated-device paper — no Verilog-level transfer; it informs *whether* a physical third state is realizable (it is), not *how* to build our gates |
| **Intermediate state vanishes in ideal devices (C1)** | our "null = free" energy claim (TernaryCell) | **counter-to** | their evidence that the middle state is parasitic would, if taken literally, undercut the "null is a designed free state" story — our null is a *chosen* encoding state, theirs an *unwanted* leakage; the counter applies to any assumption that "3 states per device is free" |
| ternary→binary **transition** (thin BP) | our TCVT / TERNARY_MODE binary↔ternary conversion (TERNARY_PROCESSOR §2.2, opcode 11) | **ANALOGY** | both recognize the ternary/binary boundary as a real operational seam — theirs physical (device thickness), ours architectural (an instruction) |

## 5. One-liner

**The silicon existence proof for "polarity is the value": a single BP transistor with a well-defined intermediate state whose carrier polarity (p ↔ n) is electrically reconfigurable with matched middles for complementary logic — validating the plausibility of direction-as-information and the 3-states-per-cell architecture, with the honest calibration that its ternary states are current levels and its middle state is a parasitic minority current that vanishes in ideal devices (counter to our energy-free null); DIRECT on the MVL-efficiency numbers, ANALOGY everywhere else, zero RTL transfer.**
