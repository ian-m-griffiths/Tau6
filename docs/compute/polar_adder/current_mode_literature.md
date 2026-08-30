# Current-Mode Multivalued (Ternary) Logic — Prior-Art Survey for the Polar-Ternary Adder

**Purpose.** Ian's idea — *polar ternary on one line* (current direction: push / pull / null,
i.e. `{+I, 0, −I}`), where the **SUM is free** (Kirchhoff current summing) and **only the carry
needs a threshold** — is a specific instantiation of a well-known, four-decade-old circuit
family called **current-mode multiple-valued logic (CM-MVL)**. This survey answers three
questions honestly:

1. Has anyone already built a current-mode ternary adder?
2. What do they report for transistor count, power, and speed vs. binary?
3. Does the literature support "fewer transistors for the sum" and "beats binary on power"?

**Bottom line up front (read this if nothing else):** the core mechanism is **not novel** — it is
the textbook CM-MVL adder, published continuously since the early 1980s. The "sum is free" claim
is **true and trivial** (it is a wire junction, literally zero transistors). But the papers that
actually do the fair, equal-technology **MVL-vs-binary** comparison (the 2020–2022 CNTFET work)
conclude that ternary/quaternary does **not** beat binary on transistors, power, delay, or area
once the carry threshold detectors, current-to-voltage conversion, I/O encoders/decoders, and
always-on current sources are counted. The free sum is real; the **carry threshold + static
power** cost eats it. Verdict: **known-to-work in principle, known-to-lose on power/area in
practice; not a novel idea, not a known failure either — a known niche with a known ceiling.**

---

## 1. What current-mode MVL is, and why "the sum is free"

In voltage-mode logic (binary CMOS), a logic value is a **voltage** and addition requires
explicit gate logic. In **current-mode MVL**, a logic value is a **current level** (e.g.
`0, I, 2I, 3I` for radix-4, or `0, I, 2I` for radix-3), and two of its properties do the work
that voltage logic has to build transistors to do:

- **Summing is free.** Kirchhoff's current law (KCL) says currents *add at a node*. To add two
  operands you literally **wire their current outputs together** — the junction current is the
  sum. No transistors, no gate delay, no switching energy for the sum itself. This is the
  "SUM is free" claim, and it is exactly correct.
- **The carry needs a threshold.** The summed current must be compared against the radix to
  extract the carry: if `I_sum ≥ 3I` (radix-3), generate a carry and subtract `3I`. This is
  done with a **threshold detector / current comparator** — a device whose switching point
  must sit between `2I` and `3I`. That comparator is the *whole* cost of the carry path, and
  it is the thing that needs tight matching (see §5).

Ian's polar variant is just a **signed** current encoding: the sign is carried by the current
*direction* (`+I` push, `−I` pull, `0` null). This is the current-mode analogue of **balanced
ternary / signed-digit** arithmetic (`{−1, 0, +1}`), which has its own long literature
(redundant signed-digit and carry-free addition, e.g. Avizienis-style redundant number
systems). The mechanism is identical: KCL gives the sum, a comparator gives the carry.

So the *architecture* Ian is proposing is not a new circuit; it is the standard CM-MVL adder
with a signed-digit radix-3 encoding.

---

## 2. Has anyone built a current-mode ternary adder? **Yes — for 40 years.**

This is a mature, well-trodden field. Representative lineage (all real, citable):

- **K. W. Current, "Current-mode CMOS multiple-valued logic circuits," IEEE J. Solid-State
  Circuits, vol. 29, no. 2, 1994.** The canonical current-mode CMOS MVL paper — threshold
  detectors, min/max operators, current mirrors, and arithmetic blocks in a standard CMOS
  process. ([IEEE](https://ieeexplore.ieee.org/abstract/document/272112))
- **"Current mode techniques for multiple valued arithmetic and logic," ISCAS 1994.**
  Current-mode arithmetic (add/multiply) explicitly. ([IEEE](https://ieeexplore.ieee.org/abstract/document/272112), [Bath](https://researchportal.bath.ac.uk/en/publications/current-mode-techniques-for-multiple-valued-arithmetic-and-logic/))
- **S. L. Hurst, "Multiple-Valued Logic — Its Status and Its Future," IEEE Trans. Computers,
  vol. C-33, no. 12, 1984.** The foundational survey of the whole MVL promise and its
  difficulties. ([IEEE](https://dl.acm.org/doi/10.1109/TC.1984.1676392))
- **A. K. Jain, "Multiple-Valued Logic Design in Current-Mode CMOS," M.Sc. thesis, Univ. of
  Saskatchewan, 1994.** Documents a full current-mode CMOS MVL design methodology; its abstract
  explicitly discusses the CMCL-vs-VMCL tradeoff (current-mode's disadvantages). ([USask](https://harvest.usask.ca/items/15de457a-adae-4e0c-8807-89aeba435746/full))
- **Wu Xunwei et al., "Design of ternary current-mode CMOS circuits based on switch-signal
  theory."** Ternary current-mode CMOS gates. ([Semantic Scholar](https://www.semanticscholar.org/paper/Design-of-ternary-current-mode-CMOS-circuits-based-Xunwei-Xiaowei/e57743ae0b4e743c0948a36ab6ec141d61ba3280))
- **T. Temel & A. Morgül**, "Multi-valued logic function implementation with novel current-mode
  logic gates," and "Multiple valued current mode logic circuits," IEEE, 2018. ([SS](https://www.semanticscholar.org/paper/Multi-valued-logic-function-implementation-with-Temel-Morg%C3%BCl/8cbb5490503126ad330f32d1039542a99e310a90), [IEEE](https://ieeexplore.ieee.org/abstract/document/8363975))
- **"The structure design of MOS current mode logic adder," ICMMT 2012.** A MOS current-mode
  adder specifically. ([IEEE](https://scite.ai/reports/the-structure-design-of-mos-ML6kEl#1))
- **M. Moradi & R. F. Mirzaee**, "Two state-of-the-arts current-mode ternary full adders based
  on CNTFET Technology," Int. J. Reconfigurable & Embedded Systems, vol. 9, no. 1, 2020.
  Explicitly a **current-mode ternary full adder** with the exact Ian structure: (1)
  current-to-voltage conversion, (2) threshold detectors, (3) parallel output-current paths.
  ([IJRES](https://ijres.iaescore.com/index.php/IJRES/article/view/19485))
- **M. Moradi & R. F. Mirzaee, "Ternary Versus Binary Multiplication with Current-Mode
  CNTFET-Based K-Valued Converters," ISMVL 2016.** One of the few papers that puts ternary and
  binary head-to-head. ([IEEE](https://ieeexplore.ieee.org/document/7515516))
- **Moaiyeri et al.** — a whole CNTFET ternary full-adder line ("A low-power dynamic ternary
  full adder using CNTFETs", etc.). ([UI](https://ris.ui.ac.ir/en/profile/article/A-low-power-dynamic-ternary-full-adder-using-carbon-nanotube-field-effect-transistors))
- **"An area and power efficient ternary serial adder using phase composite ZnO stack channel
  FETs," 2025** — still active in 2025. ([ScienceDirect](https://www.sciencedirect.com/org/science/article/pii/S2516023025001832))

**Conclusion on novelty:** the answer to "has anyone tried Ian's idea" is **yes, extensively, and
under exactly the name he'd use.** A signed current-mode ternary adder where KCL gives the sum
and a threshold detector gives the carry is the standard building block, not an open problem. If
Ian's specific novelty is *"polar on a single wire with only one threshold for carry,"* it is a
minor encoding choice within a saturated field, not a new concept.

---

## 3. Reported numbers: transistor count, power, speed vs. binary

The honest headline is that **most of the CM-MVL literature benchmarks its new adder against
*previous MVL* adders, not against binary.** That is a systematic, well-known gap. The few papers
that *do* the fair comparison are recent, use equal CNTFET/CMOS technology, and are consistent:

### 3.1 The information-ratio floor

A ternary wire carries `log₂ 3 ≈ 1.585` bits, vs. `1` bit for a binary wire. So ternary *should*
need ~`1/1.585 ≈ 0.63×` the wires/operands for the same information. Any ternary claim has to
beat **1.585** on the cost ratio to win on a per-bit basis. This is the bar.

### 3.2 The equal-technology verdict (2020–2022, CNTFET)

- **"Best CNTFET Ternary Adders?" (arXiv:2101.01516, 2021)** — a survey of ternary half/full
  adders using MUX/predecessor/successor styles, compared against binary MUX and complementary
  CMOS. Verbatim finding: *"The transistor count ratio between ternary and binary
  implementations is **always greater than** the information ratio (log₂3/log₂2 = 1.585)
  between ternary and binary wires."* I.e. **ternary adders lose on transistor count even after
  you grant ternary its greater information density.** ([arXiv](https://arxiv.org/abs/2101.01516))
- **"Comparing quaternary and binary multipliers" (arXiv:2005.02678, 2020)** — 8×8-bit binary vs
  4×4-quaternary-digit multiplier. Verbatim: *"the best quaternary multiplier includes the
  corresponding binary one … there is **no opportunity** to get less interconnects, less chip
  area, less power dissipation with the quaternary multiplier."* ([arXiv](https://arxiv.org/abs/2005.02678))
- **"CNTFET quaternary multipliers are less efficient than the corresponding binary ones"
  (arXiv:2206.03252, 2022)** — N×N quaternary vs 2N×2N binary, Wallace trees, 32 nm CNTFET,
  HSPICE. Verbatim: *"the binary implementations are **always more efficient** … The quaternary
  multipliers have **larger worst case delays, more power dissipation and far more chip areas**
  than the binary ones computing the same amount of information."* ([arXiv](https://arxiv.org/abs/2206.03252))

These are the modern, apples-to-apples numbers, and they are unanimous: **on transistors, power,
delay, and area, binary wins.** The `1.585` information edge never pays for itself because the
per-digit MVL operators (threshold detectors, converters, comparators) are *more* than 1.585×
dearer than the per-bit binary operators they replace.

### 3.3 What the pro-MVL papers actually show

Pro-MVL papers (e.g. Moradi's IJRES current-mode ternary FA, the 2012 ICMMT MOS current-mode
adder, Moaiyeri's CNTFET line) typically report, *relative to other MVL designs*: "fewer
transistors, lower static power, better PDP." These numbers are real but **scoped to MVL-vs-MVL.**
The "sum is free" claim they celebrate is the *sum alone*, not the full datapath: a current-mode
ternary FA still carries (i) a current-to-voltage front end, (ii) threshold detectors for carry,
and (iii) I/O converters — none of which exist in a binary FA, and none of which the free sum
removes.

---

## 4. The three known tradeoffs (reported honestly)

These are documented across the Hurst survey, the current-mode literature, and the USask thesis;
they are the *structural* reasons CM-MVL never displaced binary CMOS.

**(a) Threshold-device precision.** Logical values are `0, I, 2I, …`; discriminating them needs
current comparators with thresholds at `I/2, 3I/2, 5I/2, …`. Those thresholds are set by
**current-mirror matching** between the reference source and the input mirror. Mismatch (from
process variation, and from **single-device threshold variation in FETs** — which is *worse* in
the very CNTFET/finFET nodes where people hoped MVL would win) directly eats the margin between
levels. Practical current-mode CMOS tops out around **4–8 levels** before matching makes the
levels unreliable; radix-3 (or balanced radix-3) is chosen precisely because it is the smallest
radix where matching is survivable. Ian's carry threshold — the comparator that must sit between
`2I` and `3I` — is the single most matching-sensitive device in his whole adder.

**(b) Noise margins.** Current levels are separated by **one unit current `I`**, not by a
full rail. Binary CMOS swings `≈ Vdd` with the inverter's gain providing **restoration**
(regeneration toward the rail). Current-mode MVL has weaker/narrower margins and **weaker
restoration** — noise, supply bounce, and capacitive coupling inject directly into a signal that
has only `I/2` of headroom per level. More radix = closer levels = smaller margins; this is the
fundamental tension between "more information per wire" and "less noise immunity."

**(c) Static power.** Current-mode logic needs **always-on bias/reference current sources**, and
every gate draws quiescent current even when idle. This is the direct opposite of static CMOS,
whose idle power is ~zero (only leakage). The "sum is free" in *transistors* is paid in *static
current*: a free Kirchhoff junction is only free of transistors, not free of the standing
currents feeding it. This is the canonical reason current-mode MVL is quoted as power-*hungry*,
and it is what the 2022 quaternary-multiplier paper means when it says binary is "more
efficient" on power.

---

## 5. Verdict against Ian's three claims

| Ian's claim | Literature verdict |
|---|---|
| **"The sum is free (Kirchhoff)."** | **TRUE, and trivial.** KCL summing is a wire, zero transistors, zero gate delay for the sum. This is textbook CM-MVL. |
| **"Fewer transistors overall."** | **FALSE at datapath level.** The sum is free, but the carry threshold detector, current-to-voltage front end, and I/O converters cost *more* than the binary carry logic they replace. Transistor ratio vs binary is **always > 1.585** (the information ratio) in the fair comparisons. |
| **"Beats binary on power."** | **FALSE in the equal-technology comparisons.** Always-on current sources (static power) + threshold-detector switching overwhelm the free sum. The 2020–2022 CNTFET papers find binary wins on power, delay, area, and PDP. |
| **"The idea is novel."** | **FALSE.** Signed/balanced current-mode ternary adders with KCL sum + comparator carry have been published since the 1980s (Current, Hurst, Wu, Temel/Morgül) and into 2025 (CNTFET/ZnO FET). |

**Net assessment — "borrow, don't trust":**

- The *mechanism* is **known-to-work**: current-mode ternary adders have been simulated and
  fabricated, and the KCL-sum + threshold-carry structure is sound. Ian is not chasing a broken
  idea.
- The *advantage* is **known-to-fail as an absolute claim**: current-mode MVL does not beat
  binary on power, area, delay, or transistor count when compared fairly. It wins only in
  **wire-limited** scenarios (reducing *interconnect*, not logic), and even that win evaporates
  in the modern multiplier comparisons.
- The **one place Ian could still be right** is a narrow, honest one: if his *specific* metric is
  "transistors **in the sum path only**" or "number of **wires/pins** for a signed ternary
  datapath," then yes — the sum is genuinely cheaper. But the carry threshold is the thing that
  must be designed to tight matching, and the static power is the thing that must be budgeted;
  the literature says those two eat the free sum.

**Recommendation:** do not spend engineering effort expecting ternary to *beat binary on power or
transistor count* — the field's own fair comparisons say it won't. If the goal is a *wire-count
or pin-count* argument, or a *signed-digit carry-free* argument, that is defensible and has real
precedent (Avizienis signed-digit / redundant number systems). Cite the 2020–2022 CNTFET papers
up front; they are the strongest, most recent evidence and they go *against* the naive
"fewer transistors" story.

---

## 6. Key references

1. K. W. Current, "Current-mode CMOS multiple-valued logic circuits," *IEEE J. Solid-State
   Circuits*, 29(2), 1994. https://ieeexplore.ieee.org/abstract/document/272112
2. "Current mode techniques for multiple valued arithmetic and logic," *ISCAS*, 1994.
   https://researchportal.bath.ac.uk/en/publications/current-mode-techniques-for-multiple-valued-arithmetic-and-logic/
3. S. L. Hurst, "Multiple-Valued Logic — Its Status and Its Future," *IEEE Trans. Computers*,
   C-33(12), 1984. https://dl.acm.org/doi/10.1109/TC.1984.1676392
4. A. K. Jain, "Multiple-Valued Logic Design in Current-Mode CMOS," M.Sc. thesis, Univ. of
   Saskatchewan, 1994. https://harvest.usask.ca/items/15de457a-adae-4e0c-8807-89aeba435746/full
5. "Best CNTFET Ternary Adders?", arXiv:2101.01516, 2021. https://arxiv.org/abs/2101.01516
6. "Comparing quaternary and binary multipliers," arXiv:2005.02678, 2020.
   https://arxiv.org/abs/2005.02678
7. "CNTFET quaternary multipliers are less efficient than the corresponding binary ones,"
   arXiv:2206.03252, 2022. https://arxiv.org/abs/2206.03252
8. M. Moradi & R. F. Mirzaee, "Ternary Versus Binary Multiplication with Current-Mode
   CNTFET-Based K-Valued Converters," *ISMVL*, 2016. https://ieeexplore.ieee.org/document/7515516
9. M. Moradi & R. F. Mirzaee, "Two state-of-the-arts current-mode ternary full adders based on
   CNTFET Technology," *IJRES*, 9(1), 2020.
   https://ijres.iaescore.com/index.php/IJRES/article/view/19485
10. T. Temel & A. Morgül, "Multiple valued current mode logic circuits," IEEE, 2018.
    https://ieeexplore.ieee.org/abstract/document/8363975
11. Wu Xunwei et al., "Design of ternary current-mode CMOS circuits based on switch-signal
    theory." https://www.semanticscholar.org/paper/Design-of-ternary-current-mode-CMOS-circuits-based-Xunwei-Xiaowei/e57743ae0b4e743c0948a36ab6ec141d61ba3280
12. "The structure design of MOS current mode logic adder," *ICMMT*, 2012.
    https://scite.ai/reports/the-structure-design-of-mos-ML6kEl
13. "An area and power efficient ternary serial adder using phase composite ZnO stack channel
    FETs," 2025. https://www.sciencedirect.com/org/science/article/pii/S2516023025001832
