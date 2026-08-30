# Synthesis — the native 3-state DEVICE (literature × physics × circuit)

**2026-08-29 — Tau Architecture, ground-up synthesis. Three files, one question: is there a
native 3-state device that makes the polar-ternary demux+driver tax disappear, and what does
it cost?**

Sources synthesized (all same directory):

- `device_literature.md` — *which* devices give 3 states (RTD, CNTFET, SET, IG-FinFET, FeFET, …) and the ranked shortlist.
- `device_physics.md` — *why* 3 stable states, and what they cost (free-energy / NDR / Landauer).
- `device_circuit.md` — *how* to build the cells (NOT / MIN / MAX / mod-3 sum) from a multi-threshold FET.

**Calibration legend** (house standard, applied per claim, at mapping time):

- **DIRECT** — measured/proved in-repo or a citable textbook/literature identity; here, *also* "stated and agreed by all three source files."
- **ANALOGY** — parallel structure, not identity.
- **OURS** — a claim of this synthesis (an overlap *detected*, a disagreement *identified*, a ranking *chosen*); derived from the three files but not independently established.
- **SPECULATION** — untested hypothesis, flagged as such.

---

## 1. Overlap — what all three AGREE on

### 1.1 The physics (the same answer, in three voices)

All three converge on a single definition of "natively 3-state," stated most crisply in
`device_physics.md` and *implicitly used* by the other two:

> A natively 3-state device is one whose **free-energy landscape `F(q)` has three local
> minima separated by barriers `≫ k_B T`** — equivalently, in the electrical picture, a device
> characteristic with **two NDR segments** (or two stacked bistable elements), so the load
> line has **three stable** crossings. **[DIRECT — `device_physics.md` §0–§4]**

The counting rule is the shared load-bearing fact:

- a **monotonic** I–V → **1** stable state (the ordinary FET under one bias);
- **one** NDR region (N-shape) → **2** stable states (bistable, the tunnel-diode flip-flop);
- **two** NDR regions (double-peak) → **3** stable states (tristable). **[DIRECT]**

The second shared premise: **a 2-level MOSFET is a binary threshold** — it distinguishes 2
levels, not 3, so a polar-ternary gate built on plain MOSFETs pays a 2-sense-amp demux +
push-pull re-encode tax for *every* gate (`polar_gates.md`: 18/44/44/100 T). This is the
failure the native device is meant to fix, and all three files take it as established.
**[DIRECT — `device_literature.md` §0, `device_physics.md` §0, `device_circuit.md` §0]**

The three known **mechanisms** for building the three-minimum landscape are the same across
files:

1. **NDR (RTD)** — resonant-tunneling folds the I–V; two NDRs → three stable branches.
2. **Multi-threshold (two turn-on points)** — two thresholds → three *driven* levels.
3. **Quantized charge (SET / Coulomb blockade)** — the integer-`n` Coulomb ladder is native M-valued.
   **[DIRECT — `device_physics.md` §1–§3; `device_literature.md` §2.1–§2.3]**

### 1.2 The candidates (the shortlist converges)

All three files, working at different levels of abstraction, land on the **same three-device
core** plus the same two satellites:

| role | device | shared verdict |
|---|---|---|
| fabricable front-runner(s) | **multi-Vt CNTFET**, **independent-gate FinFET** | the "native ternary gate" mechanism is real and cited; IG-FinFET is the only one *in production* |
| physics reference | **RTD (2-peak / two series)** | the *only* device whose single structure gives 3 *stable* states; III-V, off-CMOS |
| cleanest-native, non-fab | **SET** | charge quantization = the thermodynamic existence proof; cryogenic/slow |
| dark horse | **FeFET** | "multiple thresholds in one transistor" literally true, HfO₂ CMOS-compatible, but ternary *logic* immature |
| memory adjuncts (not logic) | **memristor / MTJ** | genuine 3-state *storage* (DIRECT), but passive 2-terminal → no gain/restore |

**[DIRECT — `device_literature.md` §1–§3, `device_circuit.md` §1, `device_physics.md` §1–§3]**

The single most important agreement, stated as a headline in the literature file and
re-affirmed by the circuit file:

> **No device in the literature is a drop-in "one transistor → three rail voltages" part.**
> The closest *production* answer (IG-FinFET) still needs a current→voltage load; the closest
> *single-device* answers (RTD, SET, QCA, FeFET) are non-CMOS or immature. **[DIRECT]**

### 1.3 The cost (the verdict is shared and negative)

All three files independently reach the **same energy verdict**, from different directions:

1. **The overhead tax can be removed.** Folding the two thresholds into the transistor (multi-Vt)
   deletes the clocked sense amps and the re-encode driver — the pull networks *are* the driver.
   `device_circuit.md` quantifies it: NOT 18 T → 4, MIN/MAX 44 T → 10, mod-3 sum 100 T → ~45
   (TLG) or ~8 (RTD). **[DIRECT — `device_circuit.md` §2–§6]**

2. **The information tax cannot be removed.** Push/null/pull on one wire is a one-dimensional
   ordered code: 3 ordered levels **must** be resolved by **two** decision boundaries, whether
   those boundaries are sense amps or transistor thresholds. The 2.54× receiver tax (measured)
   exceeds the `log₂3 = 1.585×` density gain, *before* any gate logic is counted.
   **[DIRECT — `device_physics.md` §2.3, `device_circuit.md` §0, `gate_energy.md`]**

3. **The noise-margin tax cannot be removed.** Three levels in one swing sit `V_swing/2` apart,
   so holding a fixed BER costs a larger swing or larger C — more energy, not less.
   **[DIRECT — `device_physics.md` §2.3, §5.3]**

4. **At the Landauer floor, per-bit it is exactly tied.** One trit costs `k_B T ln 3 = 4.55 zJ
   = 1.585 bits`; the digit-count saving and the per-digit erasure cost cancel
   (`k_B T ln N` is radix-independent). There is **no thermodynamic free lunch in base 3**.
   **[DIRECT — `device_physics.md` §5.1–§5.2]**

5. **Above the floor, 3-state loses per bit.** Net result converges on "**no per-bit energy
   win**": `device_circuit.md` says even the best native cell lands **~1.5–2× worse per bit**
   (the 4.9–14.3× collapses but no win appears); `device_physics.md` says it "currently loses"
   at any practical operating point.

6. **What 3-state is genuinely good for** (the one honest positive all three allow): **a
   representation / interconnect economy** — fewer digits per value = fewer wires, pins, and
   clock cycles — plus **mechanism-specific** physics wins (RTD ~ps speed, SET near-Landauer
   energy). The wins belong to the *mechanism*, not to the *number 3*.
   **[DIRECT — `device_physics.md` §5.4, consistent with `device_circuit.md` §7.3 and `device_literature.md` §3]**

---

## 2. Disagreements / qualifications (where the three files qualify each other)

These are cross-file tensions, identified here. **[OURS — the identification of each tension;
the underlying claims are DIRECT to the cited file sections.]**

### D1. "Native" means two incompatible things, and the three files weight them differently

`device_physics.md` §2.2 makes a **sharp** distinction the other two files blur:

- **Multi-threshold → *driven* levels**, NOT stable attractors. No barriers, no minima; the
  "state" collapses the moment the input leaves. This is exactly what a *combinational* gate
  needs — but it is **not** a 3-minimum memory device.
- **NDR / SET → *stable* attractors** (self-held states).

`device_literature.md` §4 admits "native" is used in *both* senses ("native states" vs "native
thresholding") and that they "do not imply each other." `device_circuit.md` then builds its
entire design on the *thresholding* sense while calling the result "native ternary gates" and
claiming a "genuinely driven zero-static-current **rest state**."

The qualification: **the multi-Vt cell is not a 3-state *memory*, and its "rest state" is not a
*stable* state.** If the input rail droops or is removed, the driven null collapses — it is held
open, not self-held. No file reconciles this cleanly, and `device_circuit.md`'s word "rest state"
risks being read as "stable state." **[OURS — come-to-terms failure per the AGENTS.md rule "come
to terms first."]**

### D2. The single-NDR crossing count: the literature file is wrong, the physics file corrects it

`device_literature.md` §2.1 says an NDR I–V "can cross [the load line] at **more than two
points, each intersection a stable bias point**." `device_physics.md` §0.1 corrects this: an
N-shaped (one-NDR) I–V crosses a load line **three** times, but the middle (NDR) intersection has
`g_d + 1/R_L < 0` → **unstable**, leaving **2** stable points. One NDR → bistability, never
tristability; **two** NDRs are required for three *stable* states.

This is a genuine correction, not a quibble: it is the difference between "the RTD is a
3-state device" (wrong for a single NDR) and "the RTD is *the* bistable primitive; you need a
2-peak device or two in series for 3." The literature file's own later sections (via the 2-peak
patents) agree with the physics, so it is an internal wording slip, not a settled conflict —
but the slip is exactly the kind that produces over-claimed ternary. **[OURS — flags a DIRECT
inconsistency in `device_literature.md` §2.1 vs `device_physics.md` §0.1.]**

### D3. The front-runner ranking is not fully agreed, and it is partly self-undermining

`device_literature.md` ranks **IG-FinFET #1** ("the closest thing to a native polar ternary
transistor that can be taped out *today*") and CNTFET #2. But:

- the same file's §2.5 caveat — the IG-FinFET's 3 states are **current** states, and converting
  to push/null/pull **voltage** rails "still needs a load/resistor network" — undercuts the
  "#1 native polar *transistor*" title;
- `device_circuit.md` does not actually pick IG-FinFET; it writes its cells against a generic
  "multi-threshold FET (realized as CNTFET, IG-FinFET, or multi-Vt/multi-gate CMOS)," and its
  **4-flavor threshold inventory (two of them depletion)** is not obviously realizable by
  IG-FinFET back-gate bias alone;
- `device_physics.md` ranks nothing — it is mechanism-level, and its mechanism B is
  "multi-threshold" in general.

Net: the three files agree on the *shortlist* but not on the *order*, and the specific
fabrication constraint the circuit file raises (depletion) is a claim about *which* candidate
can actually carry the design, which neither of the other two files has evaluated. **[OURS]**

### D4. RTD energetics: the literature file is optimistic where the physics file is explicitly not

`device_literature.md` §2.1 calls RTD "~fJ-range at ps switching, fastest solid-state device
(THz oscillation)." `device_physics.md` §1.3 flags the switch energy as **SPECULATION** ("no
single cited energy number") and adds a cost the literature file under-weights: an NDR region is
an **active** element (`dI·dV < 0` means it *supplies* power), so the device must be **DC-biased
continuously** to hold *any* state, including idle — static dissipation is the price of a
negative resistor and is "not recovered." `device_circuit.md` §5.3 carries this as disqualifying
for the null-as-default target ("holds state *with* current unless clocked").

The qualification: the RTD's headline speed is DIRECT; its energy and its idle power are
**unquantified and possibly disqualifying**, not a settled "fJ, low-power" fact. **[OURS — the
DIRECT-vs-SPECULATION disagreement between `device_literature.md` §2.1 and `device_physics.md` §1.3.]**

### D5. Depletion-mode fabrication risk appears in only one of the three files — and it is the killer

`device_circuit.md` §1.1/§TODO-2 states that a mid-level (0 V) output from a mid-level (0 V)
gate voltage **requires depletion-mode (normally-on) devices**, a level-shifted source, or an
external mid-rail — and names this "the single most likely thing to kill the whole design."
`device_literature.md` presents IG-FinFET/CNTFET as clean (no depletion flag); `device_physics.md`
§2.1 lists "dual-gate / CNTFET bandgap / work-function multi-Vt" as ways to get two thresholds
but never asks whether any of them gives a **depletion** threshold.

This is a one-sided flag: the fabrication blocker that would most likely kill the entire
multi-threshold cell family is raised by only the file that is actually trying to draw the nets,
and neither of the survey files has tested for it. **[OURS]**

### D6. FeFET sits in no file's physics taxonomy

`device_literature.md` §2.8 gives FeFET the *strongest* single-device claim — "the only device
where 'multiple thresholds in a single transistor' is literally true" — and marks it DIRECT in
principle / SPECULATION on maturity. But `device_physics.md`'s clean dichotomy (mechanism B =
multi-threshold = **driven** levels, no barriers; only NDR/SET give **stable** states) does not
accommodate FeFET: a ferroelectric multi-Vt device is *non-volatile* — its thresholds ARE stored
states with barriers. `device_circuit.md` omits FeFET entirely.

So the device that most cleanly matches the "one transistor, multiple native thresholds" ideal
is the one whose physics-status is **unresolved in the shared taxonomy**, and the cell design
file does not consider it at all. **[OURS]**

### D7. The same verdict, three different degrees of pessimism

All three say "no per-bit win," but they scope the win differently:

- `device_literature.md` — most optimistic: frames the whole thing as a "transistor-technology
  bet" worth making for the *overhead* win, and ranks candidates for it.
- `device_physics.md` — neutral: per-bit tie at the floor, loss above, positive only as
  interconnect/representation economy.
- `device_circuit.md` — most pessimistic: even the *best* native cell lands **~1.5–2× worse per
  bit**, and §7.3 states the only way to flip it ("resolve 3 states in fewer than 2 thresholding
  measurements") is **impossible by construction** on one ordered wire.

This is not a contradiction in the physics — it is a difference in where the "yes, but" is
placed, and it matters: the literature file could be read as "the native device is the answer,"
while the circuit file's own bottom line is "the native device removes the overhead but still
loses the information battle." **[OURS]**

---

## 3. Merged TODO, ranked (highest-value untested questions first)

All `## TODO / not covered / caveats` items from the three files, de-duplicated and ranked by
**how much answering the question would move the verdict** (the verdict being: *native 3-state
removes the overhead but loses per bit*). The rank is **[OURS]**; each item's source is cited.

| rank | untested question | source | why it matters |
|---|---|---|---|
| **1** | **Does the multi-threshold native cell, simulated against a real compact model, actually deliver (a) the zero-static-current null and (b) the ~1.5–2× energy — or does it fall back to the 4.9–14.3× polar-gate loss?** | `device_circuit.md` TODO-1, -4; `device_literature.md` §4-L3 | **The decisive experiment (see §4).** It is the only item that converts the design's every OURS/SPECULATION claim into measured; it is currently blocked only by a missing device model. |
| **2** | **Does a depletion-mode multi-Vt device exist in a foundry flow (CNTFET doping / IG-FinFET back-gate bias)?** | `device_circuit.md` TODO-2 | The mid rail *requires* depletion or falls back to a static divider (re-introduces the null failure) or a third supply. The single most likely thing to kill the whole multi-threshold cell family. |
| **3** | **Does a single IG-FinFET close the loop as a complete 3-rail (−V/0/+V) ternary inverter** (not just 3 current states in SRAM/TCAM)? | `device_literature.md` §4-L3, TODO-2 | If yes, the "#1" pragmatic candidate is genuinely "tape-out-able today"; if no, it needs a companion load and the ranking changes. |
| **4** | **Normalized energy/area measurement tables** (RTD/MOBILE, CNTFET, SET, MTL) from primary papers. | `device_literature.md` TODO-1, -2; `device_physics.md` TODO-1, -2 | Replaces every qualitative "fJ/sub-fJ/aJ" cell with cited numbers — the prerequisite for any honest cross-device comparison. |
| **5** | **The RTD static DC-bias / idle-current term, quantified.** | `device_physics.md` TODO-7; `device_circuit.md` TODO-6 | The largest unmeasured term in the "true 3-stable-state" column; determines whether the RTD quantizer is even a *memory* option, not just a speed reference. |
| **6** | **FeFET ternary *logic* (not multi-level memory) — dedicated search.** | `device_literature.md` TODO-4, §4 | The "one transistor, multiple native thresholds" dark horse; could re-rank above FinFET/CNTFET, and resolves D6's taxonomy gap. |
| **7** | **Is the single-RTD 3rd branch (intrinsic tristability) usable/logic-grade?** | `device_physics.md` TODO-3 | Distinguishes "3 branches exist" from "3 branches are a usable logic family" — the over-claim boundary for RTD. |
| **8** | **Quantify the 3-level vs 2-level SNR penalty** (PAM-4-vs-NRZ energy-to-hold-BER curve). | `device_physics.md` TODO-5 | Turns the "~2× noise-margin cost" from assertion into a number before any downstream doc quotes it. |
| **9** | **Does reversible/adiabatic ternary interact differently from binary?** | `device_physics.md` TODO-6 | The *only* regime where the "no per-bit win" verdict could flip (energy recovery below `k_B T ln 2`). |
| **10** | **Decide the architectural bet: restoring-logic transistor vs non-volatile 3-state memory + CMOS logic hybrid.** | `device_literature.md` §4 (deeper digging) | Re-scopes the whole device shortlist: memristor/MTJ only make sense under the hybrid. |
| **11** | **Variability / mismatch / RTN / aging / SEU / ECC for 3 levels** (~2× worse than binary). | `device_circuit.md` TODO-9 | A cell that cannot meet margin is dead regardless of its device count. |
| **12** | **A synthesis/mapping path** (yosys/PnR/STA liberty for a multi-Vt ternary cell). | `device_circuit.md` TODO-10 | The same wall CNTFET hit at ~15 K transistors; a per-gate win without PnR is unactionable. |
| **13** | **Draw the mod-3 sum net (pull `2211.12176`) and add `tmul`** (mod-3 product). | `device_circuit.md` TODO-3, -12 | Completes the F₃ pair and removes the "deferred" caveat from the hard cell. |
| **14** | **Topology survey: pass-transistor / current-mode / DCVS ternary.** | `device_circuit.md` TODO-11 | Some topologies may dodge the depletion requirement at a different cost. |
| **15** | **Is SET-native-3 better than 2 or 4 (M-valued vs ternary)?** | `device_physics.md` TODO-4 | Whether the Coulomb ladder's "free" extra states give any logic-family advantage. |
| **16** | **Dual-rail wire-cost accounting** (the 26% 2-wire waste). | `device_circuit.md` TODO-5 | The "10 T" MIN/MAX is marginal cell cost, not loaded per-signal cost. |
| **17** | **Spintronic / QCA energy numbers cross-checked**; **single authoritative PVCR cite.** | `device_literature.md` TODO-5; `device_physics.md` TODO-2 | Low-value housekeeping (memory-adjunct side). |
| **18** | **Quantum-coherent / superconducting native-3-state (flux/phase-slip).** | `device_physics.md` TODO-8 | Out of scope for a room-temp processor; only relevant if Tau goes cryogenic. |
| **19** | **Cross-check reconciliation of `gate_energy.md` / `trit_tricks.md` in one place.** | `device_physics.md` TODO-9 | They already agree; pure consolidation. |

---

## 4. The single open question — the one device-level experiment

> **THE experiment:** obtain (or fit) a **real compact model for the multi-threshold FET** —
> the elevated-|Vt| push/pull pair, the depletion-mode mid driver, and, for contrast, the
> 2-peak RTD — and run `test_suite_spec.md`'s fair-fight on the four cells (NOT / MIN / MAX /
> mod-3 sum). Measure, per cell, exactly three things:
>
> 1. **Does the null-as-default claim hold?** Is the 0 V output actively driven with
>    **zero static current** (no shoot-through, no divider), or does it draw the ~1.9 pJ/toggle
>    held-null current that killed the binary-MOSFET polar gate?
> 2. **What is the measured energy/toggle?** Does it land at the claimed **~1.5–2× binary**
>    (the demux overhead removed), or does it collapse back toward the measured **4.9–14.3×**?
> 3. **Is the depletion-mode device real?** Does the mid-level driver need a depletion-mode
>    multi-Vt FET that **exists in a fabricable flow**, or must it fall back to the divider /
>    third-supply (which re-introduces the exact failure the design claims to remove)?

**[OURS / SPECULATION — this experiment is the merge of `device_circuit.md` TODO-1 (nothing is
simulated, no compact model) + TODO-2 (depletion is the killer) + `device_literature.md` §4-L3
(single-device 3-rail inverter) + `device_physics.md` TODO-7 (NDR static current); it is proposed
here, not performed.]**

**Why this is the one.** Every other open question changes a *number*; this one changes the
*verdict*. The three files have already agreed that no per-bit energy win exists and that the
only claim worth defending is "the native cell removes the demux+driver overhead." But that
claim is, in all three files, **entirely unmeasured** — `device_circuit.md` says so explicitly
("Nothing here is simulated… every energy and 'no static current' claim is unverified"). The
entire native-device thesis reduces to three assertions that only one experiment can settle at
once: (a) the null is genuinely free, (b) the energy lands at ~1.5–2×, (c) the depletion device
exists.

- **If the experiment passes (null free + ~1.5–2× + depletion available):** the verdict shifts
  from "native 3-state loses per bit, wins only interconnect" to "native 3-state **removes the
  overhead tax** — a confirmed, if not winning, transistor-technology bet worth the Fab work."
  The overhead win is real; the information cost remains the only loss.
- **If it fails on the null (still hot):** the multi-threshold cell re-introduces the exact
  meta-stable-null failure of `polar_gates.md`, and the native-cell thesis collapses to the
  measured 4.9–14.3× — Tau should commit to the **non-native hybrid** (CMOS logic + 3-state
  memory) or the **transport-layer null**.
- **If it fails only on depletion (no device exists):** the mid rail falls back to the divider
  (static current) or a third supply (new rail) — a *fabrication* kill, which reorders the
  candidate list (toward the RTD/FeFET stable-state paths) and reframes the whole bet as "wait
  for a depletion multi-Vt device."

This is the experiment `test_suite_spec.md` is already written to run; it is blocked only by a
missing compact model (`device_circuit.md` TODO-1). **The highest-value next action is therefore
not more counting and not more surveys — it is obtaining/fitting the device model so the
fair-fight can run.** **[OURS]**

---

## TODO / not covered / caveats

- **This synthesis did not re-verify any primary source.** Every DIRECT claim above is
  DIRECT *to the three source files*, which themselves cite the literature; where a source file
  was internally inconsistent (D2), I flagged it but did not resolve it against the original
  paper.
- **The ranking (§3) and the "single experiment" (§4) are OURS**, not measured and not voted by
  the three files. They are a judgment about *what would move the verdict*, and a different
  weighting (e.g. "interconnect is the real product, so §3-10 is #1") would reorder the list.
- **The D1/D8 "driven vs stable" terminology collision is noted, not resolved.** A proper
  come-to-terms pass over the words *native / stable / driven / rest state* across the three
  files (and `null_default.md`, `test_suite_spec.md`) is still owed, per the learning-method rule.
- **FeFET's place in the physics taxonomy (D6) is unresolved** — it may force a third category
  ("stored thresholds = non-volatile multi-Vt") between "driven levels" and "stable attractors,"
  which neither `device_physics.md` nor this file has done.
- **The lattice-math mapping is deliberately absent.** None of the AGENTS.md lattice concepts
  (residual / ring / wedge / 3 axes) are mapped onto "3 native states" anywhere in the three
  files; whether the ternary digit, the polar −/0/+ code, or the trit's 1.585 bits has a lattice
  analogue is a *separate* analogy and is **not** attempted here (consistent with
  `device_literature.md` §4's explicit non-mapping).
- **"1.5–2× worse per bit" remains a scaling argument** in every file that states it; until §4's
  experiment runs, the number should be treated as an estimate with a ~2× uncertainty either way.
