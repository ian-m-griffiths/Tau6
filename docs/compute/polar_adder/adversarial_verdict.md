# Adversarial Verdict — does the polar current-mode ternary adder beat binary on size or power?

**2026-08-30 — hostile referee pass.** This file polices the polar **current-mode** ternary
adder claim on its own terms. The claim under review, stated as three load-bearing theses:

- **(a)** the Kirchhoff-current-law (KCL) sum is *free* — `σ = I_a + I_b` on one node;
- **(b)** therefore the *only* real devices are the **carry threshold** and the **direction
  sense** (the "trit is the diode");
- **(c)** therefore the polar adder beats CMOS ternary (**192 T**) and *maybe* binary
  (**28 T / 6.94 fJ**).

**Source note.** There is no `polar_adder/` tree on disk; the claim's documentation is spread
across the sibling files and the audit already done against it. Every number below is read
from those on-disk docs, chiefly: `ground_up/analog_polar.md` (the current-mode survey),
`polar_gates.md` (measured native gates), `junction_cost_verdict.md` (the one-channel-claim
review), `ground_up/fair_binary.md` (the honest binary baseline), `ground_up/radix_lower_bound.md`
(the Π-factor decomposition), `ground_up/meta_mishandled.md` + `ground_up/meta_math.md`
(direction ≠ free), `gate_energy.md` (the 2.54× receiver tax), and
`circuit_diagrams/full_adder_comparison.md` (192 T vs 28 T). Nothing here is invented.

**Calibration legend (house standard):** **DIRECT** = measured/proved in-repo or textbook
identity; **DERIVED** = arithmetic on DIRECT; **OURS** = this review's synthesis; **SPECULATION**
= untested, carries no weight.

---

## 0. One-line answer

**The free KCL sum is real, but it is the only free thing in the adder; the direction sense
(2 devices per input, not 1), the 2-threshold carry, the 9 crossbar intersections, and the
always-on current-source tail are all real, counted costs — so the polar current-mode adder is
smaller than the naive 192 T ternary cell but does *not* beat binary on size (28 T) or power
(6.94 fJ). It is a cheaper ternary adder, not a binary-beater.**

---

## 1. The five traps, each adjudicated

### Trap 1 — "The sum is free, but the SENSE is not."

**The claim being probed.** `σ = I_a + I_b` is free by KCL, so the *summation* costs nothing
and the only cost left is the wrap/carry.

**Does the design honestly account for it?** **Partially — and the "direction sense" half is
where it hides a cost.** KCL summation is genuinely free (**DIRECT** — Kirchhoff's current law,
`analog_polar.md` §1). But the sum node can only add *already-sensed* currents: before `I_a`
and `I_b` reach the junction, each input trit must be **read** as one of three states
(push/pull/null) and steered onto the node. That read is the *sense*, and it is paid **per
input, every cycle**, before any "free" addition happens.

The "direction sense is free (it's just a diode)" escape has already been measured-and-falsified
in this corpus:

- **Direction is 2 decisions, not 1.** "Direction" distinguishes push from pull (a sign test);
  the null still needs a separate presence/magnitude test. Two decisions, relabeled, not
  removed — `meta_math.md` §4 ("2 directions… = 2 decisions, exactly the theorem's count, just
  relabeled"). **[DIRECT — `meta_math.md` §4; `radix_lower_bound.md` §2.2 factor 7 = ×1.00.]**
- **The realized diode receiver still uses 2 sense amps, measured 2.54×.** The repo's own
  "direction-via-diode" cell reads its two rails with two sense amps: **61.87 fJ vs 24.35 fJ**
  for one binary sense amp (`gate_energy.md` §1). **[DIRECT.]**
- **Even a pure diode leg is a device with a conduction cost.** Two antiparallel diodes per
  input (not one, not zero), each dissipating `V_d·I` — `meta_math.md` §4 point 3. **[DIRECT —
  physics; the 2-diode receiver is `ternary_cell.cir` verbatim.]**

**What it costs.** 2 devices (diode legs) or **14 T** (2 × 7-T sense amp) per input wire. A
3-input adder pays **6 devices / 42 T of receiver before any logic** — more than the entire
28-T binary full adder, before the carry is even touched. **[DERIVED from `polar_gates.md`'s
14-T receiver.]**

**Verdict: FAILS as "free"; HONEST only in `analog_polar.md` §3.2, which counts the wrap
measurement but still leans on "direction ≈ free" from `meta_mishandled.md` §2.3. The sense is
part of the adder, it is 2 devices/input, and claim (b) under-counts it by exactly that
factor.**

---

### Trap 2 — "The carry threshold is a real device" (the 2-threshold tax).

**The claim being probed.** The carry is one threshold; everything else is the free sum.

**Does the design honestly account for it?** **The carry is counted, but as "a device" when it
is really *two*.** The balanced carry is signed: `σ = +2 → s = −1` (wrap down) and
`σ = −2 → s = +1` (wrap up). Detecting both requires **two current comparators at ±3I₀/2**,
one per sign — `analog_polar.md` §3.2 states this explicitly and admits it is exactly
`device_physics.md` Law 1 (two thresholds → three levels) relocated, not removed. **[DIRECT —
`analog_polar.md` §3.2, the wrap table is arithmetic.]**

So the carry is a **2-threshold tax**, and it is where the information lives: distinguishing
`σ = +2` from `σ = +1` (and `−2` from `−1`) is the only nontrivial part of the mod-3 sum, and
it cannot be dodged by "the trit is the diode" — a diode reads direction, not magnitude, and the
wrap is a *magnitude* decision. Plus the correction itself needs a **3:1 current mirror** to
steer `∓3I₀` back through the sum node, and that mirror is mismatch-limited.

**What it costs.** 2 elevated-Vt devices **or** 2 comparators + a ratioed 3:1 mirror. The
representation-independent floor for naming one-of-3 states is `2/log₂3 = 2·ln2/ln3 = 1.262×`
per bit — proved, `ThresholdLowerBound.lean`, and it does not care whether the states are drawn
as levels or as directions. **[DIRECT — proved; `meta_math.md` §2.]**

**Verdict: HONEST in `analog_polar.md`; the trap is the *count* — "the carry threshold"
(singular) is really two thresholds (a signed carry is a ± decision), and it is a real
elevated-Vt/comparator device, not a diode. Claim (b) is wrong by a factor of 2 on the carry.**

---

### Trap 3 — Current-mode static power.

**The claim being probed.** Current-mode "adds for free," so it must be cheap on power.

**Does the design honestly account for it?** **Yes — this is the one trap the docs flag loudest,
and it is fatal to claim (c).** Static current-mode logic (CMMVL/SCL) holds a current level with
a **bias/tail current that flows in every state, including null and idle**. This is the
literature's *own* admitted cost — Current, *IEEE JSSC* 29(2):95–107, 1994, quoted verbatim in
`analog_polar.md` §2 caveat 3: current-mode buys speed and easy summation **at the cost of
static power and noise margin**. **[DIRECT.]**

The collision with polar ternary's own premise is direct: the whole transport win
(`null = 0.05 pJ` vs `±1 = 1.20 pJ`, `junction_cost_verdict.md` §2) rests on **"null = no
power."** A static current-mode gate draws its tail current *on a null input*, so the null that
was free on the wire becomes a standing drain in the gate. The two escapes each have a price
(`analog_polar.md` §3.2 Item 4):

- **Charge-packet / dynamic current mode** recovers null-free, but the gate becomes
  self-timed/clocked (MOBILE-style) and inherits the completion-detection tax.
- **Current mirrors** (for the 3:1 wrap and any ⊗ scaling) are **mismatch-limited**, i.e. the
  same ~2×-worse-than-binary offset story as 3 voltage levels.

**What it costs.** A µA-class standing current at ~1 V is µW-class static power: over a 10 ns
gate cycle that is **~10–100 fJ of idle energy per gate** — against binary's **6.94 fJ total
dynamic toggle** (`fair_binary.md` §2). The free sum saves a one-shot switching term and is
swamped by the always-on tail. **[DERIVED — order-of-magnitude from `analog_polar.md` §3.2;
the 6.94 fJ is DIRECT.]**

**Verdict: HONEST in the docs, ignored by claim (c). Current-mode is a *speed/low-swing* idiom,
not an *energy* idiom — so on power the polar adder loses, and the "free sum" does not even
begin to pay for the standing current.**

---

### Trap 4 — Noise margins (levels 2× closer; tight matching costs area/precision).

**The claim being probed.** Three current states are just as clean as two voltage rails.

**Does the design honestly account for it?** **Yes, and it concedes the point against claim (c).**
Three levels in a fixed swing sit **`V_swing/2` apart**, not `V_swing` — so to hold a fixed BER
against `kT/C` noise you must raise swing or capacitance, both energy (`device_physics.md`
§5.3). Current mode is *worse* per level, not better: the sense-node noise is channel thermal
noise `4kTγg_m Δf` (and shot `2qI Δf` if shot-limited), and you pay `I²R` to get `I`
(`analog_polar.md` §4.3). The threshold device that decides the carry at `±3I₀/2` therefore
needs **tight matching** — the 3:1 wrap mirror and any current mirror for `⊗` must hold ratio
accuracy to a *fraction* of a level. `analog_polar.md` TODO #4 admits the mismatch number is
**unquantified**; `meta_critique.md` §3g puts the offset story at ~2× worse than binary.

**What it costs.** Wider input pairs / larger mirror devices for matching → area + energy,
on top of the halved per-level margin. Real sense-amp offsets (σ ≈ 5–20 mV) already move the
ternary low-swing floor to **0.22–0.35 pJ/bit — a loss, not a win, against binary's 0.512**
(`fair_binary.md` TODO #4). **[DIRECT for the numbers.]**

**Verdict: HONEST in the docs (§4.3, TODO #4); claim (c) omits it. The "levels are closer" tax
falls hardest on the very threshold device claim (b) calls a "real device" — it is a *precision*
device, and precision costs area.**

---

### Trap 5 — The crossbar intersections are devices, not free wires.

**The claim being probed.** "The carry threshold + direction sense are the *only* real
devices" — i.e. the routing fabric is priced at zero.

**Does the design honestly account for it?** **No — this is the single cleanest over-claim.**
The sum node is drawn (`analog_polar.md` §5 Idea A) as a bare junction — `Ia sum 0`, `Ib sum 0`,
"one wire junction, I(sum) = I_a + I_b by KCL." That junction only works if each input's three
states have *already been steered* onto the correct sum rail (push → +Σ, pull → −Σ, null →
nowhere). Routing a 3-state input into the crossbar **is** a 3×3 switching problem: 9
intersections, each a steering transistor / diode / current switch, none of them a free wire.
Claim (b) prices the crossbar at zero by counting only "carry + direction sense" and treating
the 9 intersections as wires.

**What it costs.** **9 intersection devices minimum** (one per crosspoint), plus the output-side
re-encode and driver. Even at the most optimistic 1-device-per-crosspoint this is 9 T that claim
(b) silently drops; realistically the intersections are pass-transistor or diode stacks and cost
more. **[DERIVED — 3 inputs × 3 states; the "free wire" reading is what claim (b) asserts and
the sum-node sketch does not itemize.]**

**Verdict: FAILS. The design does not count all 9 intersections, and "carry + direction sense =
the only real devices" is false by exactly the 9 devices of the crossbar.**

---

## 2. Adjudication — size and power, with numbers

### SIZE: does it beat CMOS ternary (192 T)? Does it beat binary (28 T)?

**vs 192 T CMOS ternary — YES, plausibly.** The 192 T is the repo's *naive boolean* `tadd1`
(`full_adder_comparison.md` §2.1), whose 100 T mod-3-sum construction (`polar_gates.md`) is
exactly the thing KCL removes. The current-mode cell replaces ~92 T of boolean carry + ~52 T of
sum with: direction sense (6 devices, or 42 T if sense-amped) + 2 carry thresholds + 9 crossbar
+ 3:1 wrap mirror + driver ≈ **~20–60 T**. That is genuinely smaller than 192 T — but it is
**not** a fair claim, because the honest comparison is the *literature's optimized current-mode
ternary FA (~118 T CNFET, `full_adder_comparison.md` §2.2), not the repo's deliberately naive
boolean cell. Against 118 T the margin is thin and unmeasured. **[DERIVED estimate; the 192/118 T
baselines are DIRECT.]**

**vs binary 28 T — NO.** The honest floor is the sense: 2 devices/input × 3 inputs = 6, plus 2
carry thresholds, plus ≥9 crossbar intersections, plus the wrap mirror and drivers. Even the
*most generous* count lands at **~20–30 devices**, and the realistic count (2 sense amps/input =
**42 T of receiver alone**, `polar_gates.md` §transistor breakdown) blows past 28 T before any
logic. The radix economy (÷1.585) cannot recover a 2-device-per-input + 2-threshold-carry +
9-crosspoint tax against a 28-T binary cell. **[DERIVED from DIRECT per-part counts.]**

### POWER: does it beat binary (6.94 fJ)?

**NO — decisively.** The free sum saves a one-shot switching term; the **always-on current
source** (static CMMVL) or the **mismatch-limited mirror** (dynamic) both cost more than that
saving. Static current-mode draws its tail current in *every* state including null, directly
violating the "null = no power" premise the polar win depends on, at ~10–100 fJ/cycle of idle
drain vs binary's 6.94 fJ dynamic toggle. The measured reality is unambiguous: the cheapest
measured polar/diode gate is **54.2 fJ/toggle = 4.9×/bit worse than binary NOT**, and that is
*before* adding a standing current source. **[DIRECT — `fair_binary.md` §4; `gate_energy.md`.]**
Current-mode moves the wall from "demux + driver" to "quantizer + tail" — it does not remove
the wall (`analog_polar.md` §0's own words).

### Where it genuinely wins (fairness)

- **The KCL sum is real and free** — it removes the single most expensive voltage-mode cell (the
  100 T mod-3 sum). That is not nothing.
- **Null = 0 A is a native dead zone**, not a 0-V saddle — it removes the measured 1.9 pJ/toggle
  null shoot-through of `polar_gates.md` — but **only in dynamic/charge-packet mode**, not static
  current-mode.
- Both wins make it **a better polar gate**; neither makes it **a winning one**
  (`analog_polar.md` §3.3's own verdict, which this review confirms rather than overturns).

---

## 3. The honest one-sentence verdict

**The polar current-mode ternary adder is a real, smaller ternary adder — its KCL sum and its
0-A null dead-zone are genuine — but it does not beat binary on size (28 T) or power (6.94 fJ),
because the direction sense (2 devices per input), the 2-threshold signed carry, the 9 crossbar
intersections, and the always-on current-source tail are all real costs that the "free sum"
does not pay for: it beats the naive 192-T ternary cell, not the 28-T binary one.**

---

## Calibration ledger (this file's own claims)

| claim | calibration |
|---|---|
| KCL signed-current summation is free on one node | **DIRECT** — Kirchhoff's current law; `analog_polar.md` §1 |
| direction = 2 decisions (sign + presence), relabeled not removed | **DIRECT** — `meta_math.md` §4; `radix_lower_bound.md` §2.2 factor 7 |
| realized diode receiver = 2 sense amps, 61.87 vs 24.35 fJ = 2.54× | **DIRECT** — `gate_energy.md` §1 |
| 2-diode receiver per input (14 T = 2×7-T sense amp per wire) | **DIRECT** — `ternary_cell.cir`; `polar_gates.md` transistor breakdown |
| wrap/carry = 2 current thresholds at ±3I₀/2 + 3:1 mirror | **DIRECT** — `analog_polar.md` §3.2 |
| 1.262× = 2/log₂3 = 2·ln2/ln3, representation-independent | **DIRECT** — proved, `ThresholdLowerBound.lean` |
| static CMMVL draws idle bias in every state (incl. null) | **DIRECT** — Current 1994, quoted `analog_polar.md` §2 |
| 3 levels sit V_swing/2 apart; current SNR ∝ I/√Δf, pay I²R for I | **DIRECT** — `device_physics.md` §5.3; `analog_polar.md` §4.3 |
| mirror mismatch unquantified; ~2× worse than binary | **DIRECT/OURS** — `analog_polar.md` TODO #4; `meta_critique.md` §3g |
| 9 crossbar intersections priced at zero by claim (b) | **OURS** — 3 inputs × 3 states; the sum-node sketch itemizes none |
| binary FA = 28 T canonical; 6.94 fJ/toggle NOT | **DIRECT** — `binary_baseline_diagram.md`; `fair_binary.md` §2 |
| ternary FA = 192 T naive (118 T literature-optimized) | **DIRECT/ANALOGY** — `full_adder_comparison.md` §2 |
| cheapest measured polar/diode gate 54.2 fJ = 4.9×/bit vs binary | **DIRECT** — `fair_binary.md` §4 |
| current-mode adder ≈ 20–60 T (vs 192 T), unmeasured | **DERIVED/SPECULATION** — no current-mode netlist was run |

*Every quantitative anchor above is measured/proved in the cited on-disk files or arithmetic on
those numbers; the only unmeasured quantity — the current-mode adder's own transistor count and
energy — is flagged SPECULATION and carries no adjudicatory weight.*
