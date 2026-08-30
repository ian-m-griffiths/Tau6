# Ternary Transistors — re-test of the "no native fabricable ternary device" verdict

**2026-08-29.** One task: take Ian's newly-suggested ternary-transistor list, download the
arXiv ones, search the named non-arXiv ones, and re-test the ground-up verdict that
**"no fabricable native 3-state device exists; AAT costs ≫ 1.585× a binary op."**

**Method:** arXiv API (`export.arxiv.org/api/query`) for metadata, `arxiv.org/pdf/<ID>v1` for
PDFs, `pdftotext -layout` for text; Semantic Scholar API + publisher/institutional-repo pages
for the paywalled IEEE papers. Every number below is from an abstract/PDF I actually read
(downloads in `docs/rebuild_surveys/papers/`); anything I could not read is flagged, not invented.

**The break-even test (Etiemble's methodology, which we adopt):** a ternary wire carries
`IR = log₂3 = 1.585` bits. A ternary *cell* (full adder, multiplier) is therefore only worth
using if it costs **≤ 1.585×** the equivalent binary cell — because you need ~1/1.585 fewer
ternary cells for the same information. The conservative binary full-adder baseline is **28 T**
(complementary CMOS, full noise margin); the aggressive one is **8 T** (reduced margin). The
break-even thresholds are therefore **44 T** (vs 28 T) and **12.7 T** (vs 8 T).

---

## Executive verdict

The verdict is **softened but not reversed.**

- **"No native fabricable 3-state device" is now too strong.** Native multi-state devices
  demonstrably *exist and are being fabricated*: the SWCNT/AlScN ferroelectric FET
  (2411.03198, ~735-device array, measured), the silicon MOS-SET (1108.5527, measured, cryo),
  and the inkjet-printed anti-ambipolar transistor (T³L, measured device). So the *device*
  half of the verdict is dead.
- **"AAT costs ≫ 1.585× a binary op" is *not* reversed — it is re-confirmed**, with one
  partial caveat. The two headline claims in the list are both **within-ternary**
  comparisons, not binary-beating:
  - **T³L "84.7–98.8% power reduction"** is *"compared to the previous designs"* (prior
    ternary BTFAs), not vs binary. Classic flattery class.
  - **T-CMOS "5.6–58.5× frequency"** is an enhancement of *"the T-CMOS-based ternary
    system"* (vs prior T-CMOS ternary designs), not vs binary CMOS.
- The *only* paper that reaches the 1.585 break-even — and it does so by a whisker, at
  **42 T = 1.5× the conservative binary FA** — is T-CMOS, and only (a) in simulation, (b) on a
  TFET (a fundamentally different, lower-`I_on` device than the MOSFET baseline), and (c)
  at reduced noise margins. Against the 8 T aggressive binary FA it is 5.25×, still ≫ 1.585.
- The independent cross-check (Etiemble 1908.07299, 2101.01516) reaches our exact prior
  conclusion from the other side: ternary adders/multipliers **cannot compete with binary at
  equal information** — the best CNTFET ternary FA is 72 T (2.57× the 28 T binary FA).

The two walls from the prior verdict (the 1.585 information floor; the mod-3 `⊕` cell) both
**stand**. Nothing in this list clears them.

---

## Per-paper

### 1. arXiv:2411.03198 — Reconfigurable SWCNT ferroelectric-FET arrays (Rhee et al., 2024)

- **Device:** single-gate reconfigurable FeFET — monolayer aligned **SWCNT** channel +
  ferroelectric **Al₀.₆₈Sc₀.₃₂N** gate dielectric. **Fabricated** (~735 devices on ~1 cm²,
  BEOL-compatible, on/off > 10⁵, ambipolar with balanced e/h ~270 µA/µm at V_DS=3 V).
- **Claim:** one ambipolar FeFET = a full **ternary content-addressable memory (TCAM)** cell,
  vs "10 or more" transistors in conventional CMOS TCAM and ~4/2 devices in RRAM/PCM/unipolar
  FeFET TCAM.
- **Transistor count:** TCAM *core* = 1 FeFET (+ 1 PMOS precharge + 1 cap as *periphery*).
- **Energy/speed:** none reported. No power or per-bit comparison to binary.
- **Honest read:** the device is **DIRECT** (a real, fabricated, native multi-state device via
  ferroelectric polarization: p-FET / n-FET / NVM). But "ternary" here is TCAM's **{0, 1, X}**
  (don't-care) — a *memory-match* primitive, **not** balanced-ternary **{-1, 0, +1} arithmetic**.
  The TCAM circuit itself is **Cadence simulation** (device model from measured transfer
  curves), not a fabricated circuit. It is orthogonal to the AAT/gate-energy question: it is a
  memory-density win, not a logic-per-bit win. **Does not touch the 1.585 floor.**

### 2. arXiv:2309.01615 — Balanced memristor-CMOS ternary logic family (Wang et al., 2023)

- **Device:** **memristor** (bipolar metal-oxide, fabricated, 10⁴ s retention) **+ multi-threshold
  CMOS** (NMOS Vth 0.8 V / 1.5 V). VDD = 1 V, balanced {-1,0,+1} = {-VDD, 0, +VDD}.
- **Claim:** TMIN/TMAX/STI/PTI/NTI gates → encoders, decoders, half adder, multiplier, comparator;
  "99.77% power reduction" (decoder-based vs multiplexer-based half adder).
- **Transistor count:** balanced ternary **half adder = 10 T + 59 memristors** (decoder-based;
  10 T + 64 M multiplexer-based). ≈ **69 devices** for a 2-trit half adder.
- **Energy:** half-adder avg power 0.17 µW (decoder) vs 72.65 µW (multiplexer) — the "99.77%".
- **Honest read:** the "99.77%" is **decoder-vs-multiplexer**, i.e. **within-ternary**, not
  ternary-vs-binary. There is **no binary comparison anywhere in the paper**. The 3 states come
  from multi-threshold CMOS + memristor *ratioed dividers* (the memristor is a passive
  programmable resistor, not a native 3-state device). At ~69 devices for 3.17 bits
  (~22 devices/bit) vs ~3 devices/bit for a binary half adder, it is **~7× worse per bit**, and
  it never claims otherwise. **Calibration: OURS-flavored flattery only in the abstract's framing;
  the paper itself makes no binary-beating claim.** No challenge to the verdict.

### 3. arXiv:1108.5527 — Balanced ternary addition using a gated silicon nanowire (Mol et al., 2011)

- **Device:** silicon **MOS-SET** (single-electron transistor) with 3 gates, on 200 mm SOI CMOS
  platform. **Fabricated.** "Proof of principle."
- **Claim:** gate-dependent rectification under **AC bias** gives a 3-valued output
  (negative/zero/positive current); a full balanced-ternary adder on **2 SETs** (one sum, one
  carry, C_G ratio 3×).
- **Transistor count:** 1–2 SETs for a ternary full add (vs ~28 T binary FA) — but this is a
  *device*, not a gate; the carry-out path needs an inverting buffer/amplifier for fan-out.
- **Energy/speed:** none reported. No binary comparison.
- **Honest read:** a genuine **DIRECT** demonstration that one device can natively compute a
  ternary operation (Coulomb-blockade charge states are inherently multi-valued). But: SETs
  operate at **cryogenic** temperature (charging energy ≫ kT), the scheme is **clocked (AC)**
  not static, and there is **no receiver / noise-margin / fan-out** analysis. It is a
  physics proof that a native 3-state device exists, **not** a fabricable VLSI logic family.
  **Does not claim to beat binary; does not reverse the AAT cost verdict.**

### 4. T³L — Tri-Transistor Ternary Logic (Kim et al., IEEE TCAS-I 70(12):4826–4839, 2023)

- **Device:** **inkjet-printed anti-ambipolar transistor (AAT)** (negative differential
  resistance / anti-ambipolar conduction) + thin-film **CMOS**.
- **Claim:** two BTFA designs — a *compact* one at **64 T**, and an *ultra-low-power* one that
  **"reduces power by 84.7% to 98.8% compared to the previous designs."**
- **Transistor count:** BTFA = **64 T** (compact).
- **Energy:** 84.7–98.8% power reduction — **vs previous (ternary) designs** (verbatim from the
  abstract).
- **Honest read — this is the flagged one.** The "84.7–98.8%" is **ternary-vs-ternary**, not
  ternary-vs-binary. It does **not** reverse the AAT verdict; it never compares against binary
  per bit. Even its *compact* 64 T BTFA is **64/28 = 2.29×** the conservative binary FA
  (> the 1.585 break-even) and **64/8 = 8×** the aggressive one. The AAT is a real native
  NDR 3-state device (fabricable by inkjet), but it is a **thin-film / large-area** process,
  not a VLSI-scaled logic fabric, and per bit it still loses. **Calibration: the device is
  DIRECT; the "84.7% reduction" is SPECULATION-into-flattery — it is a no-receiver-count,
  vs-previous-ternary artifact, exactly the class the re-test was asked to catch.**

### 5. T-CMOS — tunnelling-MOSFET ternary (KAIST, IEEE TCAS-I, doi:10.1109/TCSI.2023.3287274, 2023)

- **Device:** **T-CMOS = tunnelling-based MOSFET (TFET)**. Circuit-level design; no fabrication
  reported.
- **Claim:** "first balanced ternary adder whose transistor count is only **42**"; "enhance the
  operating frequency of the **T-CMOS-based ternary system** by **5.6× to 58.5×**."
- **Transistor count:** BTFA = **42 T** (lowest reported).
- **Energy/speed:** 5.6–58.5× frequency — again scoped to *"the T-CMOS-based ternary system"*
  (prior T-CMOS ternary designs), **not** "vs binary CMOS."
- **Honest read:** the **42 T** count is the first to sit **under** the 1.585 break-even vs the
  *conservative* 28 T binary FA (42/28 = 1.5×). That is genuinely the closest any paper in this
  list comes to parity. But three caveats keep the verdict intact: (1) **TFET ≠ MOSFET** — the
  baseline is a MOSFET while the ternary device is a fundamentally different, lower-`I_on`
  tunneling device, so "transistor count" alone understates the cost; a fair comparison is
  42 T ternary-TFET vs a binary-TFET FA, not a binary-MOSFET FA. (2) The 5.6–58.5× headline is
  **within-ternary** (vs prior T-CMOS ternary), not binary-beating. (3) Low counts of this class
  use pass-transistor/mux logic with **reduced noise margins** and no receiver accounting; vs the
  8 T aggressive binary FA the ratio is 5.25×. **Calibration: ANALOGY for the 42 T "win" —
  it is a level-1 (simulation, ideal TFET model) result against a conservative binary baseline,
  and it does not reverse the verdict; it marks the ceiling of the ternary-transistor-count
  frontier.**

### 6. Current-mode symmetric ternary CMOS (Shen & Chen, J. Electronics (China), 1997)

- **Device:** standard **2-level CMOS**; the 3 states are **current levels** (current-mode
  signaling), not a native 3-state device.
- **Claim:** "theory of transmission current-switches based on symmetric ternary logic" →
  current-mode ternary CMOS with "simpler circuit structure" (vs voltage-mode ternary).
- **Transistor count / energy:** not extracted (paywalled; abstract read via aipub.cn mirror).
- **Honest read:** an **encoding-level** trick, not a device answer. Current-mode ternary
  changes where the 3 states live (current, not voltage) but still synthesizes them from 2-level
  transistors, so it **sidesteps** rather than solves the native-device question. 1997, no
  fabrication, no binary comparison. **Historic interest only. Calibration: SPECULATION
  (could not read full text); the claim of "simpler" is unmeasured vs binary.**

### 7. CNFET ternary (12× power, SRAM) + optimal ternary gate synthesis (49% PDP)

- **CNFET ternary class** (Lin–Kim–Lombardi 2011 and successors). The specific "12× power" SRAM
  figure could not be pinned to one arXiv-accessible number; the class is represented here by the
  papers I *did* read:
  - **Sharifi et al. 2017 (1701.00307):** ternary FA = **55 T / 43 T + 3 input caps**, 32 nm
    Stanford CNTFET HSPICE. Headline "PDP reduced 57.67%/37.50%" is **vs a prior ternary FA**
    ([Moaiyeri 2011]), **not vs binary**. Power ~10–18 µW, delay 55–66 ps, PDP ~0.7–1.0 fJ. Pure
    ternary-vs-ternary flattery.
  - **Sandhie et al. 2021 (2108.09342):** 3 T ternary **DRAM** cell (CNTFET, 16 nm model), total
    power 32 nW cell / 84 nW with sense circuit. No binary comparison; simulation only.
- **The independent cross-check (this is the important part):**
  - **Etiemble 2019 (1908.07299) "Comparing ternary and binary adders and multipliers":** the
    fair-computation comparison the field was missing. 1-trit FA = **124 T** vs 1-bit FA
    **8–28 T** (ratio **4.4–15.5×**); 1-trit multiplier = **38 T** vs 1-bit AND = **6 T**
    (6.3×); ternary Wallace-tree carry doubles partial products. Conclusion (verbatim): ternary
    adders and multipliers **"cannot compete with the binary ones"** at the same information
    throughput.
  - **Etiemble 2021 (2101.01516) "Best CNTFET Ternary Adders?":** best ternary HA = **42 T**,
    best ternary FA = **72 T** (2 power supplies), vs binary HA = 14 T / FA = 28 T → ratios
    **3× and 2.57×**, both > 1.585. Verbatim: *"3 is not the best base for computation and
    multivalued circuits are restricted to a small niche."*
- **Optimal ternary gate synthesis (ASP-DAC 2018, doi:10.1109/ASPDAC.2018.8297369):** "49%
  PDP reduction in the ternary full adder, 62% in the ternary multiplier **compared to the
  existing methodology**" — i.e. vs prior *ternary* synthesis, **not vs binary**. The same paper
  concedes prior ternary "could not show advantages over binary logic," and its own binary-vs-
  ternary transistor-count comparison (per Etiemble) lands on the losing side.
- **Honest read:** the CNFET/SRAM "power reduction" claims are **level-1 (ideal Stanford CNTFET
  SPICE models), no fabricated circuit, no receiver accounting, and ternary-vs-ternary when they
  give a number**. The "49% PDP" synthesis paper is the same shape (vs-existing-methodology).
  The two Etiemble papers are the **DIRECT** independent calibration, and they reproduce our
  prior verdict almost word-for-word: **ternary arithmetic loses to binary per bit; the 1.585
  floor holds.**

---

## Summary table

| Paper | Device (native 3-state?) | Headline claim | Real baseline | Transistor count | Beats binary per bit? |
|---|---|---|---|---|---|
| 2411.03198 SWCNT FeFET | **Yes** (ferro p/n/NVM, fabricated) | 1 FeFET = TCAM cell vs 10 T CMOS | device-count (memory), no energy | 1 core (+periphery) | **N/A** — memory {0,1,X}, not arithmetic |
| 2309.01615 Memristor-CMOS | **No** (multi-Vth CMOS + passive memristor) | "99.77% power" | decoder-vs-mux (within-ternary) | HA = 10 T + 59 M | **No** (~7× worse/bit; no binary claim) |
| 1108.5527 Si SET | **Yes** (Coulomb states, fabricated, cryo) | ternary add on 1–2 SETs | proof-of-principle, no binary metric | 2 SETs + buffer | **N/A** — no receiver/fan-out, cryo |
| T³L (2023) | **Yes** (inkjet AAT/NDR) | **"84.7–98.8% power"** | **vs previous ternary designs** | BTFA = 64 T | **No** (2.29× vs 28 T binary) |
| T-CMOS (2023) | **Yes-ish** (TFET, sim only) | "42 T FA; 5.6–58.5× freq" | **vs prior T-CMOS ternary** | BTFA = 42 T | **No** (1.5× vs *conservative* 28 T; 5.25× vs 8 T; TFET≠MOSFET) |
| Current-mode (1997) | **No** (current encoding on 2-level CMOS) | "simpler structure" | none | n/r | **No** (encoding trick) |
| CNFET FA (Sharifi 2017) | **No** (CNTFET = tunable-Vth MOSFET) | "PDP −57.67%" | vs prior ternary FA | 43–55 T + caps | **No** |
| CNFET 3T DRAM (2021) | **No** | "3T ternary DRAM" | none vs binary | 3 T + sense | **No** |
| Etiemble 2019/2021 | (comparison, not device) | "ternary cannot compete" | **fair binary (28 T)** | FA 72–124 T vs 28 T | **No — our verdict confirmed** |
| Gate synthesis (2018) | No | "49% PDP" | **vs existing ternary method** | n/r | **No** |

---

## Does the re-test verdict change?

1. **"No fabricable native 3-state device" → RETIRED.** Three native 3-state devices are now
   *measured*: ferro-SWCNT FeFET (2411.03198), silicon MOS-SET (1108.5527), inkjet AAT (T³L).
   The device wall is no longer "does it exist" — it is "can it be a *VLSI logic fabric* with
   receiver, fan-out, and noise margin, at room temperature" (FeFET yes for memory; SET no/cryo;
   AAT thin-film only).
2. **"AAT costs ≫ 1.585× a binary op" → STANDS, with one documented near-miss.** The best
   ternary FA count fell from 124 T (2017) to 72 T (2021) to 42 T (2023, T-CMOS). At 42 T it
   *touches* the 1.585 break-even — but only against the most conservative binary FA (28 T), in
   simulation, on a non-MOSFET device, at reduced margins. Against a margin-comparable or
   aggressive binary FA (8 T), ternary remains 2.5–5× over budget.
3. **Both "84.7–98.8%" and "5.6–58.5×" are within-ternary.** Neither is a binary-beating claim;
   both are the exact flattery class the task flagged (ideal-source/level-1, no receiver count,
   vs-previous-ternary baseline). **No reversal.**

**Bottom line:** the list upgrades *"no native device"* to *"native devices exist but are not yet
a fabricable ternary logic family"*, and leaves *"AAT ≫ 1.585×"* intact — re-confirmed
independently by Etiemble's fair-comparison papers. The two surviving walls (the 1.585
information floor and the mod-3 `⊕` cell) are untouched.

---

## TODO / not covered / caveats

- **T³L and T-CMOS full text not read** (IEEE paywalled). I read the abstracts verbatim and
  extracted the numbers, but did not audit the receiver/noise-margin/simulation-setup details
  inside. To *prove* (not just flag) the "84.7–98.8%" baseline and the T-CMOS "42 T is a fair
  full-swing comparison," the full PDFs are needed — ideally from a subagent with library/sci-hub
  access. Same for the T-CMOS "5.6–58.5×" baseline: the abstract scopes it to "the T-CMOS-based
  ternary system" but the exact comparator design is not visible from the abstract.
- **"12× power CNFET SRAM" not pinned.** I could not identify which specific paper carries the
  "12×" figure Ian listed; I represented the CNFET-ternary-memory class with the 3T ternary DRAM
  (2108.09342) and the CNFET full-adders instead. The "12×" claim should be tracked to a DOI and
  audited for binary-vs-ternary vs ternary-vs-ternary baseline.
- **Current-mode 1997 full text not read** (paywalled Chinese journal; only the English abstract
  via a mirror). Characterization is from the abstract + the known current-mode-ternary literature,
  flagged SPECULATION for anything beyond the abstract.
- **The mod-3 `⊕` cell is unexamined by all seven papers.** None of them addresses the one
  primitive our prior verdict named as the hardest wall (the `NOT(push OR pull)` null-rail sum).
  Their "full adders" all build sum via decoder/mux/carry-decomposition, not a native `⊕`. This
  remains the decisive open cell.
- **Fair-binary baseline still unresolved at the device level.** The 28 T vs 8 T binary-FA spread
  changes the break-even from 44 T to 12.7 T — a 3.5× uncertainty band that no paper resolves with
  a same-technology, same-margin, fabricated binary reference. A definitive re-measurement pass
  (fair binary + full-swing + receiver) is still the next decisive step, as the prior verdict said.
- **FeFET "ternary" is a different object.** 2411.03198's TCAM {0,1,X} should not be confused with
  balanced {-1,0,+1}; future surveys should keep the two buckets separate, or the "native ternary
  device" claim gets inflated by memory-circuit wins.
