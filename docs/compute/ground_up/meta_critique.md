# Meta-Critique of the Ground-Up Plan — what `TERNARY_GROUND_UP.md` missed

**2026-08-29.** This is the batch-1 meta-critique agent. It reads the plan
(`docs/TERNARY_GROUND_UP.md`) against the *entire* prior corpus — the three laws
(`docs/ENERGY_LAWS.md`), the measured gate verdicts (`docs/compute/polar_gates.md`,
`gate_energy.md`, `gate_area.md`, `word_fairfight.md`, `gates.md`), the component
surveys (`converters.md`, `storage.md`), the 19-paper graph survey
(`docs/synthesis/ternary-circuits.md`, `docs/graphs/ternary-circuits/`), the feasibility
notes (`TERNARY_PROCESSOR.md` §1.5), and the Lean ledger (`proofs/INDEX.md`).

Calibration legend (house standard, `docs/MAP_BRIEF.md`): **DIRECT** = measured/proved
(our ngspice/yosys/Lean numbers, or a citable literature number); **ANALOGY** = parallel
structure, not identity; **OURS** = our own design claim; **SPECULATION** = untested
hypothesis. Where I assert external history (RTD, SET, NULL-convention logic) from
established engineering knowledge rather than a file we already hold, I flag it
`DIRECT (domain history — verify citation in batch 2)`.

---

## 0. The blunt verdict, first

**The plan is not greenfield, and it is built on one wrong premise.** The premise
"the native 3-state device was never built, so measure it" is true but irrelevant to
the actual wall. The wall is already identified — in our own measurements — and it is
**not the transistor, it is the measurement** (Law 1: the receiver is gauge-agnostic;
the 2-threshold tax). A native device only rescues ternary *if it collapses 2
thresholds into fewer measurements or makes the null free **inside the gate**, not on
the wire*. No device on the plan's list is known to do that, and the plan never asks
the question in those terms. **A large fraction of batch 1 as specced will re-derive
results the corpus already holds** (truth tables, minimal set, completeness, the CNTFET
and memristor verdicts). The highest-value single correction: **re-frame the search as
"does any fabricable device resolve 3 states cheaper than 2 CMOS thresholds," and spend
the first agent on the fabrication-path audit that kills the dead ends early.**

If that audit comes back empty (my strong prior: it will), the honest output of this
whole program is: *"ternary compute is a dead end unless a device exists that does X;
no such device is fabricable at VLSI scale; therefore keep the hybrid `cpu.v` (ternary
datapath for the free negation/Z₆ symmetry, binary standard cells underneath) and stop
spending agents on native devices."* That is a **valuable** outcome — it converts a
faith-based search into a measured, closed question. Do not let the search continue
past batch 2 without a yes/no on the fabrication question.

---

## 1. The one framing error that dominates everything else

The plan inherits the thesis "with a native device, ternary compute is competitive or
better," but it never separates **three different bets** that are orthogonal and must
be fought separately:

| bet | what it claims | status in corpus |
|---|---|---|
| **B1 — the wire wins** | ternary transport beats binary | **already won, no native device needed** — 0.081 pJ/bit measured on plain CMOS (low-swing × resonant), `ENERGY_LAWS.md` |
| **B2 — the gate wins** | ternary compute beats binary | **already lost** — 2.00–4.33× area, 1.2–14.3× energy, survives word-level normalization (`gate_area.md`, `gate_energy.md`, `polar_gates.md`, `word_fairfight.md`) |
| **B3 — a native device flips B2** | a 3-state transistor beats 2-level CMOS at the gate | **unmeasured, and the plan's entire subject** |

The plan's error is treating B3 as a continuation of B1. **It is not.** B1's win is
the *free null on the wire* (nothing to transmit). B2's loss is the *gate must resolve
−1/0/+1 every cycle* (Law 1's receiver tax), which `polar_gates.md` measured and
attributed to the **demux + re-encode at every boundary**, not to the absence of a
native device. The relevant test for B3 is therefore a single, sharp inequality:

> **Does any device resolve 3 states with fewer than 2 thresholding measurements,**
> **or make the null genuinely free *inside a gate*?**

A device that stores/transports 3 states but still needs 2 thresholds to *read* them
(e.g. multi-threshold CNTFET, level-coded memristor) buys **nothing** against Law 1 —
it just relocates the same 2-threshold receiver into a new material. The plan's device
list never distinguishes "3-state storage" from "3-state *measurement*." That
distinction **is** the search. This correction, stated up front, will redirect at least
half the batch-1 agents.

---

## 2. Not greenfield — what the corpus already holds (batch 1 must NOT re-derive)

The plan lists as batch-1 work several things that are already done. An agent spent on
these is a wasted agent. Table:

| plan item | already answered in | answer (calibrated) |
|---|---|---|
| "enumerate the ternary truth tables" (item 3) | `gates.md` §2–4; `docs/graphs/ternary-circuits/Automated_synthesis…md` | 27 unary, 19,683 binary; canonical base-3 function indexing exists; min/max/neg tables bit-identical across 4 sources. **DIRECT.** Nothing to enumerate. |
| "find the minimal gate set" (item 5) | `gates.md` §4/§8 | `{mod-3 sum, mod-3 product}` + constants = F₃ field pair = `{tadd1.sum, tmul}`; completeness is Lagrange interpolation over F₃. Also: no single ternary Sheffer function (Martin 1954); `{min,max,neg}` is incomplete (lattice fragment). **DIRECT.** |
| "RTD/CNTFET/SET device" literature (item 1) | `synthesis/ternary-circuits.md` + 5 graph papers | CNTFET: fabricated but stuck ~15K transistors, no VLSI (`2211.12176` §2.2); memristor-CMOS: fabricated balanced-ternary silicon but level-coded + 10⁴-cycle endurance (`2309.01615`); multi-Vt CMOS: scalable but level-coded (`2211.12176`); reconfigurable-polarity ternary transistor fabricated in black phosphorus, 2D material, single-device (`Yeom 2025`). **DIRECT.** RTD/SET/spintronic/quantum-dot are *genuinely* unmapped — see §4. |
| "null-as-default power" (item 6) | `TernaryCell.lean` (wire semantics only) + `polar_gates.md` (gate null is meta-stable) | Wire-level `null_is_free`, `energy_le_one` proved. Gate-level null-as-default is **not** done, and `polar_gates.md` shows why it's hard (null sits on the SA threshold → shoot-through). **OURS/SPECULATION.** |
| "prove gate semantics in Lean" (item 8) | `proofs/INDEX.md` | Encoding proved (`TernaryCell.lean`, `PolarEncoding.lean`). The F₃ **completeness corollary** and a *semantic* definition of "what a polar ternary gate is" are **NOT in the ledger** — `gates.md` flags it as "not separately proved." This is the one Lean gap worth closing. |

**Action for the coordinator:** cut "truth table" and "minimal set" as standalone
agents; fold them into one "Lean the F₃ completeness corollary + define the gate
semantics" agent (§6). The device agents must start from the corpus's existing CNTFET/
memristor/CMOS verdicts and go *deeper* (fabrication path, measurement count), not
re-survey the devices.

---

## 3. What is NOT in the search space (the gaps)

These are the axes the plan omits entirely. Ranked by how likely they are to kill the
program.

### 3a. The clocking problem (omitted; this is the null meta-stability finding wearing a clock)

`polar_gates.md` already measured that a 3-level wire **cannot drive static CMOS** and
that the null is **meta-stable** (sits on the SA threshold, draws continuous
shoot-through). The plan's item 6 ("null = default = off") is a *power* claim, but it
silently presumes a clocked, dynamic, pipelined gate. The plan never asks:

- Is the native device **static or dynamic**? RTDs/NDR devices are latching —
  monostable-bistable (MOBILE) logic needs a **reset clock** and has **static power**
  because an NDR latch sits at a bias point. CNTFET/memristor are different again.
- Who tells the gate to evaluate? The measured CMOS gates were dynamic/pipelined
  (sense-amp latch + eval phase). A native device that is inherently clocked may not
  compose with the null-as-default power idea at all.
- **The clock tree energy is never counted.** Every prior fair-fight measures a
  *combinational* toggle; a real design pays clock distribution + clock gating. For a
  dynamic ternary gate (which *needs* the clock to demux the 3-level wire), the clock
  cost is a first-order term the plan ignores.

**Missing axis: clocking/clock-gating energy and static-vs-dynamic device physics.**
This should be its own batch-1 agent.

### 3b. Asynchronous / self-timed ternary — NULL Convention Logic is the missing prior art

The plan's "null is the default, power only when needed" is **not a novel idea** — it
is, structurally, **NULL Convention Logic** (Fant/Theseus Logic, late 1990s): a
delay-insensitive, dual-rail family where every wire alternates NULL ↔ DATA and the
**null is the synchronization token** (`DIRECT, domain history`). NCL is the only
clockless logic family where the null is a first-class, power-gating value. The plan
never mentions it, and it is the single most important prior art to read before
pitching "null-as-default," because:

- NCL's null is exactly our null: a data-bearing *absence* that gates power and
  synchronizes. Our "null = default = off" is NCL's NULL phase.
- NCL is ternary-shaped but uses **binary dual-rail** per bit — so its null is a
  *coding* null, not a *third voltage level*. Our one-wire 3-level null is the
  *analog* version. The comparison (does a 3-level wire beat NCL's 2-wire null?) is
  an open, measurable question the plan doesn't know to ask.
- NCL's honest history: it never displaced clocked CMOS (area + completion-detection
  overhead), which is *directly predictive* of whether our null-as-default idea pays.
  If NCL lost, the ternary-null version has the same completion-detection tax **plus**
  the 2-threshold receiver tax.

**Missing axis: self-timed/async ternary vs clocked; NCL as calibration control.**
High-value agent.

### 3c. Interconnect vs gate — the device search is aimed at the wrong half

The plan's device search is gate-centric, but the corpus already established the win is
at the **wire** (0.081 pJ/bit, no native device). A native device does **nothing** for
interconnect — the wire is already 3-level and winning. It only matters for the gate.
So the device search must be *framed* as "does the device cheapen the **gate**
(receiver + re-encode)," not "does ternary win" in the abstract. The plan's framing
("ternary compute is competitive or better") re-opens a battle (the wire) that is
already won and leaves the actual battle (the gate) implicit. This is why the B1/B2/B3
split in §1 matters.

### 3d. Binary↔ternary interface energy for a *native* device (omitted)

`converters.md` costed the interface — but **only for the 2-wire one-hot encoding on
binary cells**, where it's cheap (~9.5% area, sub-pJ/crossing, cold path). That result
**does not transfer** to a native 3-state device: a native ternary core still must talk
to binary DRAM/flash/I/O/host, and converting a *true 3-level analog wire* to binary is
the 218-device divider problem the thesis paid (`2211.04542`), i.e. **level synthesis**,
which our no-drive-null encoding specifically avoids. The plan omits the interface
entirely, so it will **undercount** the true system energy of a native-ternary core.
The device search must carry the converter forward or its headline "win" is a
schematic-level artifact.

### 3e. Fabrication reality / process path (the omission most likely to kill the program)

The plan lists devices as if "search for a native 3-state device" were a *literature*
problem. It is a **fabrication** problem, and the honest prior is bad:

| device | has 3 stable states? | VLSI fab path? | the catch (calibration) |
|---|---|---|---|
| RTD / NDR | yes (NDR gives multiple stable points) | **no** — III-V (InP/InGaAs/AlAs) heterostructures, no CMOS foundry | latching MOBILE logic needs reset clock + static bias power; 30-year DARPA-era history, never VLSI (`DIRECT, domain history — verify`) |
| CNTFET | yes (chirality thresholds) | **no commercial foundry** | ~15K-transistor scale ceiling (`2211.12176` §2.2, DIRECT) |
| SET | yes (Coulomb blockade) | **no** — needs cryogenic T (E_c ≈ e²/2C ≫ kT → sub-nm island) | extreme variability; no VLSI (`DIRECT, domain history — verify`) |
| memristor | yes | **no logic path** | 10⁴-cycle endurance → storage, not logic (`2309.01615`, DIRECT); level-coded → mid-rail liability |
| multi-Vt CMOS | 3 *voltage* states via 2 thresholds | **yes (only fab-real option)** | this is the **2-threshold receiver tax in device form** — it is what already lost |
| reconfigurable-polarity FET | yes | **no** — few-layer black phosphorus, 2D, single device (`Yeom 2025`, DIRECT) | closest to our "polarity is value," but no fab path, device scale |

The unstated premise of the whole plan — **"a native 3-state device with a VLSI path
exists"** — is, on current evidence, **false for every candidate except multi-Vt CMOS,
and multi-Vt CMOS is just the 2-threshold tax wearing a device.** This is not a reason
to skip the search; it is the reason the search must be a **fabrication-path audit
first** (one agent, yes/no/maybe table per device), so the dead ends are killed in
batch 1 instead of batch 3.

### 3f. EDA / synthesis / verification gap for a native device (omitted)

The prior work's entire flow (yosys → `sky130_fd_sc_hd.lib` → OpenSTA → PDR/iverilog)
assumes **binary standard cells**. A native 3-state device has **no liberty file, no
yosys mapping, no PnR, no STA corner models**. The plan's "per-gate test suite" (item 8:
ngspice) is fine for one gate, but there is a yawning gap between "I simulated one RTD
gate" and "I built a 27K-cell ternary CPU." The plan never asks: **what is the
synthesis/mapping story for the native device?** Even if a device wins at the
single-gate level, there is no path to a processor — which is the same wall CNTFET hit
at 15K transistors. This is a first-order dead-end risk and must be a batch-1 question:
"if device X wins per-gate, how do I synthesize a 25K-cell design with it?"

### 3g. Variability / margin / ECC (omitted)

A 3-level device sits at **Vdd/4 margin** (half of binary's Vdd/2 — `storage.md` §1,
DIRECT), so it is ~2× more sensitive to process variation, RTN, aging, and SEU. The
plan has no variability/robustness axis. `ENERGY_LAWS.md` already floated "ternary ECC:
6 directions data + center parity" as **SPECULATION**; it is not in the ground-up
search space and should be — a native 3-level device that can't meet margin is dead on
arrival regardless of its energy.

### 3h. Speed / latency target (omitted — and the "competitor" is a moving target)

"Competitive" is never quantified. The prior fair-fights let binary use its cheapest
cells (NAND/NOR/INV, dedicated `fa_1`), its natural 1 V swing, and its 3–5 GHz
operating point; our own ternary CPU runs 50 MHz. The adiabatic/reversible lever that
produced 0.081 pJ/bit is **L-bound at 48–100 Mtrit/s** (`ENERGY_LAWS.md`), and RTD/SET
latching is not obviously faster. A native device that wins pJ/bit at 1/50th the speed
has **not** "beaten binary." The plan needs a stated speed+energy product target
(energy-delay product, not energy alone).

### 3i. Setun as the empirical control (omitted)

Setun built ternary **with 2-level physical devices** (ferrite cores + diode logic
emulating 3 levels), ~50 machines, and it did **not** beat binary. The plan never uses
Setun as the calibration anchor for the two facts it teaches: (1) ternary *works*
without a native device — so "native device" is not a prerequisite for a ternary
computer, only for a ternary *win*; (2) working ≠ winning, so the plan must prove a
*win*, not a *feasibility*. Setun is the control group the plan is missing.

---

## 4. The unstated assumptions (numbered, so batch 2 can test each)

- **A1. A native 3-state device exists AND has a VLSI fab path.** Unstated; §3e says
  likely false. **The single assumption that, if false, ends the program.**
- **A2. "Beat binary per bit" is the right metric.** Unstated and wrong. The corpus's
  own honest number is **per-bit** (J/bit) but the decision-relevant number is
  **energy-delay product per logical operation at system level** (incl. clock, memory,
  converter, EDA). Ternary can win density and lose everything else (`storage.md`: 26%
  overhead). Fix the metric before spending agents.
- **A3. The transport win transfers to compute.** Unstated; already refuted by
  `polar_gates.md`/`gate_energy.md` (null free on wire ≠ free in gate). This is the
  exact error the plan's thesis repeats.
- **A4. A device can eliminate the 2-threshold receiver tax.** Unstated and unproven.
  Law 1 says the tax is the *measurement* cost (how much information you extract),
  which a device does **not** change unless it changes the *information*, not the
  voltage. The plan never states the tax-elimination mechanism it's betting on.
- **A5. The minimal gate set is open.** False — known (`gates.md` §8). See §2.
- **A6. The truth tables are un-enumerated.** False — enumerated. See §2.
- **A7. "Null-as-default" is novel.** False — NULL Convention Logic. See §3b.
- **A8. The existing ngspice harness can measure a native device.** Unstated and
  likely false — the harness is LEVEL=1 **MOSFET** models. RTD/SET/CNTFET need
  different compact models (NDR is not a MOSFET IV); ngspice may not ship them, and
  any number it produces on a LEVEL=1 model is meaningless for a III-V/SET device. The
  test-suite agent must first answer "do we have a valid compact model?"
- **A9. A per-gate win scales to a system.** Unstated; §3f (no synthesis path) says no.
- **A10. Binary is the only adversary.** Unstated. Binary gets the **same** adiabatic/
  resonant/low-swing levers that produced our 0.081 pJ/bit (they're radix-agnostic:
  PAM-4 hits 0.401, low-swing 0.092 — none is ternary-specific). So the native device
  must beat *binary-with-adiabatic*, not binary-static. The plan never sets this
  adversary.

---

## 5. Dead-end vs high-value ranking

`⚠ dead end` = high probability of "no," one agent max, terminate with the "why it
died" summary. `★ high value` = de-risks or kills the program.

| rank | thread | verdict | why |
|---|---|---|---|
| ⚠ | **RTD search** | dead end | III-V, no VLSI, latching needs reset clock + static power, 30-yr history. One agent → "why RTD logic died" summary. |
| ⚠ | **SET search** | dead end | cryogenic Coulomb blockade, variability. One agent → summary. |
| ⚠ | **spintronic / quantum-dot** | dead end | no logic path at scale; exotic. Fold into one "exotic devices" agent, or skip. |
| ⚠ | **enumerate 19,683 truth tables** | already done | `Automated_synthesis` canonical index; `gates.md`. Waste. |
| ⚠ | **"find minimal set" as standalone** | already done | F₃ field pair, `gates.md` §8. Fold into the Lean agent. |
| — | **CNTFET / memristor / multi-Vt CMOS re-survey** | mostly done | corpus already has verdicts. Only *new* angle: measurement-count + fab-path audit, not device re-survey. |
| ★ | **Fabrication-path audit** (one agent, yes/no/maybe table per device, §3e) | high value | the cheapest way to kill A1 and prune 3–4 dead-end agents before they run. |
| ★ | **Receiver-tax reframe** (does any device resolve 3 states in <2 measurements, or free the null in-gate) | high value | this IS the search, restated. Frames every device agent. |
| ★ | **NULL Convention Logic / self-timed ternary** (one agent) | high value | prior art for null-as-default; directly addresses the null meta-stability finding; predicts the completion-detection tax. |
| ★ | **Clocking + static/dynamic device physics** (one agent) | high value | the null meta-stability + clock-tree energy are unmeasured first-order terms. |
| ★ | **Native-device interface energy** (one agent) | high value | the 218-device level-synthesis cost re-enters when you leave the 2-wire encoding; plan omits it. |
| ★ | **Lean: define "polar ternary gate" + prove F₃ completeness corollary** (one agent) | high value | cheap, de-risks everything, and closes the one real ledger gap (`gates.md` admits it's unproved). |
| ★ | **Variability/margin/ECC at Vdd/4** (one agent) | high value | a 3-level device that can't meet margin is dead regardless of energy. |
| ★ | **Adiabatic × native-device interaction** (one agent) | high value | separates the two orthogonal bets; asks whether the device *composes with* resonant/reversible clocking (it may not — RTD latching fights adiabatic). |
| — | **Synthesis/mapping path for the native device** (one agent) | high value | §3f; the CNTFET-15K-transistor wall in general form. |

**Net direction:** of the plan's 10 batch-1 agents, ~4 (truth table, minimal set, and
two device re-surveys) are redundant with the corpus. Re-allocate to: fab-path audit,
receiver-tax reframe, NCL/self-timed, clocking+device-physics, native-interface, Lean
F₃ completeness, variability/ECC, adiabatic-interaction. That is a **strictly more
informative** batch and it is front-loaded with the kill-or-proceed questions.

---

## 6. What batch 1 should actually be (redirect, for the coordinator)

1. **Fab-path audit** — for RTD/CNTFET/SET/memristor/reconfigurable-polarity FET, output a
   yes/no/maybe VLSI-foundry table **and** the measurement-count (does reading 3 states
   cost 1 or 2 thresholds). Start here; feed it to every other device agent.
2. **Receiver-tax reframe** — one page: "what would a device have to do to beat the
   2-threshold tax, and is any candidate on the list claimed to do it?" This is the
   program's go/no-go criterion.
3. **NCL / self-timed ternary** — prior-art pass; cost the completion-detection tax.
4. **Clocking + static/dynamic device physics** — does the native device need a clock?
   clock-tree energy; does it fight or help the adiabatic lever.
5. **Native-device interface** — the 3-level↔binary bridge cost when the null is a true
   voltage level, not a no-drive encoding.
6. **Lean F₃ completeness + gate semantics** — close the ledger gap; define "polar
   ternary gate" as a relation, prove `{mod-3 sum, mod-3 product}` + constants is
   functionally complete for F₃ⁿ (Lagrange interpolation formalized).
7. **Variability/margin/ECC** — Vdd/4 margin, SEU (the `11=NEVER` canary at 3 levels),
   ternary ECC spec.
8. **Adiabatic × native-device** — does the device compose with resonant/reversible
   clocking, or are these two separate and only one is achievable.
9. **Metric fix** — define the system-level energy-delay product target before anyone
   declares a "win." (Fold into the coordinator, not a separate agent.)

The two already-answered items (truth tables, minimal set) are cut; their content is
`gates.md` and the `Automated_synthesis` graph.

---

## 7. The honest bottom line

**The plan is a reasonable instinct (measure the device we never measured) wrapped
around a premise the corpus has already undercut.** The wall is the receiver/measurement
(Law 1), not the transistor; the native-device bet only pays if a device resolves 3
states in *fewer measurements* than 2 CMOS thresholds, and **no candidate on the list
is known to do that, while the only fab-real option (multi-Vt CMOS) is the 2-threshold
tax in device form.** The plan's biggest omissions are the clocking problem, NULL
Convention Logic (the prior art for its own null-as-default idea), the native-device
interface energy, the fabrication-path question, the EDA/synthesis gap, and any
variability/margin/speed metric. The batch-1 roster, as specced, wastes ~40% of its
agents re-deriving known results.

**The correct posture:** treat this as a *go/no-go audit*, not an open-ended search.
Front-load the fabrication-path and receiver-tax questions; if they come back "no," say
so in batch 2 and **stop** — keep the hybrid `cpu.v`, which the corpus already shows is
the right architecture, and spend the remaining budget on the two things that are
actually winnable on plain CMOS: the receiver-cheapening lever (the 2/3 of the 0.081
pJ/bit floor, already in `receiver_cheap.cir`) and the Eisenstein-multiply opcode
(−14.6% area, already measured). Both are cheaper and higher-EV than any native device
on the list.

---

## TODO / not covered / caveats

**For batch 2 — the specific questions the feedback loop should ask (merged into the
next prompts):**

1. **Fab-path go/no-go.** For each of RTD / CNTFET / SET / memristor /
   reconfigurable-polarity FET: is there a foundry/PDK today (2026) that can tape out a
   billion-transistor version? Answer in a yes/no/maybe table with a citation, not a
   sentence. *(Tests A1.)*
2. **Measurement-count.** For each device: reading 3 states costs how many thresholding
   measurements — 1 or 2? If 2, state explicitly that the device does not touch Law 1's
   tax. *(Tests A4.)*
3. **Does the device free the null *inside the gate*, or only on the wire?** The corpus
   proved the wire null is free (`TernaryCell.lean`); the gate null is meta-stable
   (`polar_gates.md`). Which does the device change? *(Tests A3.)*
4. **Compact model.** Do we have a valid ngspice/SPICE compact model for the device, or
   are we about to run LEVEL=1 MOSFET models against a III-V/SET IV and call it a
   measurement? If no model, the "per-gate test suite" is blocked until one exists.
   *(Tests A8.)*
5. **NCL prior art.** How does our null-as-default differ from NULL Convention Logic's
   NULL phase, and what is NCL's measured completion-detection + area tax? (Predicts
   whether null-as-default pays.)
6. **Clock + clock-gating energy** for a dynamic ternary gate; static vs dynamic device
   physics; does the device fight or help resonant/reversible clocking (0.081 pJ/bit was
   adiabatic — does a native device keep it)? *(Tests A10.)*
7. **Native-interface cost.** What does a *true 3-level* ternary core pay at its binary
   boundary (level synthesis vs our no-drive null)? Carry the converter forward; don't
   reuse `converters.md`'s 2-wire numbers unchanged.
8. **System metric.** State the energy-delay product target (not pJ/bit alone) and the
   speed floor, so "competitive" stops being a floating term. *(Tests A2.)*
9. **Synthesis path.** If device X wins per-gate, how do we synthesize a 25K-cell
   ternary CPU with it (liberty/yosys/PnR/STA)? If the answer is "there is no path,"
   the per-gate win is unactionable. *(Tests A9.)*
10. **Variability/ECC.** Vdd/4 margin at the device level: process/RTN/aging/SEU budget,
    and does the `11=NEVER` canary (1/3 SEU detection, `storage.md`) survive a native
    3-level cell, or does the encoding change?

**Caveats on this critique itself:**

- **External history is from domain knowledge, not our corpus.** The RTD/SET/NCL
  claims are `DIRECT (domain history)` — well-established but not yet backed by a
  paper *in this repo*. Batch 2's fab-path and NCL agents must attach citations; treat
  my "no VLSI path" as a strong prior to be confirmed, not a settled result.
- **I did not measure anything.** This is a meta-critique; every number cited is from
  the existing `docs/compute/`, `circuit/`, and `proofs/` corpus. No new ngspice/yosys/
  Lean work.
- **I assume the corpus is internally consistent** (e.g. that `polar_gates.md`'s
  "native is 20–44× worse than emulation" and `gate_area.md`'s "2.00–4.33×" are both
  correct). If those two conflict, the entire "B2 already lost" premise needs a
  re-check before this critique's ranking is trusted.
- **The one thing this critique cannot rule out:** a *currently-unpublished* device
  (or a 2025–2026 material) that resolves 3 states in one measurement. The fab-path
  audit should include a forward-looking scan (recent arXiv/nature), not just the
  device families the plan names. That is the only place the "dead end" verdict can be
  overturned.
