# Synth — the DESIGN/measurement group (null-as-default × V/I/R n-gram × test-suite spec)

**2026-08-29 — Batch-1 synthesis, group "the DESIGN / measurement" angles.** This file
merges three batch-1 reports — `null_default.md` (item 6, null-as-default),
`optimization_ngram.md` (item 7, V/I/R), `test_suite_spec.md` (item 8, fair-fight
measurement contract) — into their **overlap**, their **disagreements**, a **merged ranked
TODO**, and the **one decisive experiment**. It is a *synthesis*, so its own claims are
tagged `OURS` unless they restate a number the sources already measured (`DIRECT`) or a
parallel structure (`ANALOGY`); anything about the unbuilt native device is `SPECULATION`.

**Calibration legend (house standard, `docs/MAP_BRIEF.md`):**

- **DIRECT** — measured/proved (ngspice/Lean) or a textbook identity; cite the file.
- **ANALOGY** — structural resemblance, not identity.
- **OURS** — our synthesis/design claim; follows from DIRECT but not independently established.
- **SPECULATION** — untested hypothesis; flagged, never stated as fact.

---

## 1. Overlap — what all three agree on

These are the load-bearing agreements; every one of them is restated across all three
files in near-identical language.

1. **Null is free on the wire, expensive in the gate.** This is the single most-quoted
   sentence in the group. All three trace the same DIRECT finding to
   `polar_gates.md`: a held-null input sits exactly on the sense amp's threshold → continuous
   shoot-through (~1.9 pJ/toggle, E_gate 2.3–3.1× MIN's), ~0.18 V kickback, false "push"
   latches. `null_default.md` §2, `optimization_ngram.md` §2.4, `test_suite_spec.md` §5.2.
   **[DIRECT — polar_gates.md]**
2. **The receiver (measurement) is the binding floor, not Landauer.** All three name the
   receiver as the wall: 0.052 pJ/trit (1 ns eval) / 0.087 pJ/trit (2 ns eval), and the
   2-threshold tax (2.54× vs 1 threshold, `gate_energy.md` 61.87 vs 24.35 fJ).
   `optimization_ngram.md` is explicit that the champion (0.081 pJ/bit) is ~28,000× above
   Landauer (2.9 zJ/bit), so the thermodynamic floor is irrelevant here.
   **[DIRECT — receiver_cheap.md, lowswing_sweep.md, gate_energy.md, ENERGY_RESULTS.md]**
3. **The driver already satisfies Ian's rule; the receiver does not.** `null_default.md` §2.3
   (driver null = `(gp=+VDD, gn=−VDD)` both off, wire returns via Rterm), and both others
   restate that the demux+re-encode receiver is where the tax lives.
   **[DIRECT — polar_gates.cir; OURS for the "driver was never the wall" framing]**
4. **The native 3-state device is unbuilt and unmeasured; every number we hold is for a
   2-level MOSFET cell.** All three open with this. The premise under test — that a device
   thresholding 3 states natively removes the demux+driver tax — is `[SPECULATION]` in all
   three. **[DIRECT for "2-level measured"; SPECULATION for "native wins"]**
5. **The fair-fight discipline is identical and non-negotiable.** Real driver, real
   receiver, no ideal sources, energy = ∫V·I dt, no fictional recovery (the ~90–95%
   ideal-source flattery exposure is cited by all three), full rise/fall cycle with
   per-toggle = full-cycle/2. `test_suite_spec.md` §3/§7 codifies it; the other two cite
   the same honesty rules as their anchor. **[OURS — compiled from ENERGY_RESULTS.md's
   CORRECTION 1]**
6. **The null is data-bearing AND (nearly) free — and that is the *only* reason ternary
   wins on average.** `optimization_ngram.md` §1.1: ternary 0.817 pJ/trit = 0.515 pJ/bit vs
   binary 0.748, but the ±1 trits are each 1.20 pJ (vs 0.75 pJ binary bit) — "ternary wins
   on average only because the null is free and data-bearing." `null_default.md` states the
   same as "power ∝ data activity." **[DIRECT — ENERGY_RESULTS.md fair-fight table]**
7. **"Exactly zero" is a model artifact, not silicon.** `null_default.md` §5 ("exactly zero
   is a model artifact"), `optimization_ngram.md` §3/§2.4 (LEVEL=1 has no subthreshold
   leakage), `test_suite_spec.md` §5.2 ("the null's static cost must be measured, not
   assumed free"). The honest idle floor is *leakage*, not 0 J. **[DIRECT for the LEVEL=1
   limitation; SPECULATION for the silicon leakage floor]**
8. **Per-bit normalization is ÷log₂3 = 1.585.** All three use the radix-economy gauge
   (`RadixEconomy.lean`) for the headline. **[DIRECT — RadixEconomy.lean]**

---

## 2. Disagreements — where they conflict

These are real, not stylistic. The first one is the headline conflict the group has so far
left unstated, and it is load-bearing for the whole null-as-default claim.

### D1 (headline) — Is null free in a *synchronous* cell, or only self-timed?

- `null_default.md` §3.3 is explicit and sharp: **"null is only free if the cell is
  self-timed (or data-gated)."** A synchronous pipeline fires every sense amp every clock
  edge, so a null symbol still pays one receiver eval (0.052–0.087 pJ) and
  null-as-default fails *structurally, not electrically*. The dead-zone alone fixes the
  shoot-through but not the "measure every cycle" cost. **[OURS]**
- `optimization_ngram.md` §2.4 defines the free idle in *static* terms — "idle at 0 current
  → no static I²R, no DC shorts," resting V=0 lets the driver be fully off — with **no
  timing qualifier** and no per-clock eval term. It reads the null win as a DC/leakage
  property. **[OURS reading]**
- `test_suite_spec.md` §6 *measures* null-as-default as a **steady-state DC contract**
  (P_null vs P_hold vs P_binary_idle) and never asks for the per-clock eval energy of a null
  in a free-running pipeline. Its harness (dynamic, clocked, "report minimum cycle time")
  would **pass a gate whose null still pays full eval-per-clock**, because §4.4 only reads
  static current. **[OURS — a gap in the spec, not a wrong statement]**

**Why it matters:** only `null_default.md` conditions the null win on timing discipline;
the other two implicitly treat it as a static property. If `null_default.md` is right, the
test suite as specified cannot actually falsify the null-as-default claim — it measures the
wrong quantity.

### D2 — Where the null win is allowed to count (null-heavy vs uniform headline)

- `null_default.md` §4: the payoff is **null-heavy data**; it is explicit that the scheme
  reduces the *average* (null-heavy) cost and does **not** reduce the per-non-null cost.
- `optimization_ngram.md` §1.1: the headline is the **uniform** average (1.20+1.20+0.05)/3
  = 0.515 pJ/bit — which already leans on the free null.
- `test_suite_spec.md` §3.3/§8: headline = uniform over *toggles*; it **explicitly demotes**
  the null-dominated average ("must not be the headline") and flags the cheap null↔±1 toggle
  "generous to ternary."

**Conflict:** the design doc wants to win on null-heavy workloads; the measurement doc
refuses to headline them. They agree the *number* is null-heavy, disagree whether that is
the *verdict*.

### D3 — What the 0.05 pJ comm-cell null actually measures

- `null_default.md` §3.1 reads it as a physical zero: "null = no pulse = no charge =
  nothing burns," and targets the gate's null at that class (≈ 0.05 pJ, receiver gated off).
- `optimization_ngram.md` §1.1/§2.4 reads the same 0.05 pJ as **"rail-equalization/keeper
  cost, not a drive cost"** — small but *not* zero, and not "nothing to transmit."

**Conflict:** one doc's null floor is a physical zero; the other's is a nonzero keeper cost.
This decides whether the gate's null target is "≈ 0" or "≈ 0.05 pJ-class" — a 2-orders
difference from the 1.9 pJ it costs today either way, but the two stories attribute the
comm-cell win to different mechanisms. **[OURS]**

### D4 — The diode rectifier: the fix, or a cost to be removed?

- `null_default.md` §3.2 adopts the passive rectifier (verbatim `tcell4`) + dead-zone as
  **the fix** for the null.
- `optimization_ngram.md` §1.3 documents the same rectifier as **a cost**: Vf·Q (~26% of the
  baseline), diode drop, low-swing swing-tax (~0.15× the line swing), to be minimized via
  MOSFET/synchronous rectifier — not embraced.

**Conflict:** the component one doc adopts as the solution is the component the other flags
as lossy. Partly resolvable (both end up at "MOSFET rectifier, low drop"), but
`null_default.md`'s dead-zone additionally trades signal window for metastability immunity —
a noise-margin price `optimization_ngram.md` explicitly leaves untested. **[OURS]**

### D5 — What "the verdict" is: energy-only vs five-metric conjunction

- `null_default.md` and `optimization_ngram.md` frame the win as **energy/power** (with area
  only as a caveat).
- `test_suite_spec.md` §8 makes PASS a **conjunction**: energy-per-bit AND area-per-bit AND
  idle-per-bit AND delay (or energy·delay at matched throughput) AND clean traps.

**Conflict:** a native device that wins energy but loses area or delay is a "win" under two
docs' framing and a "FAIL" under the third. The synthesis must hold the stricter (test-suite)
verdict to avoid re-running the exact over-claim the earlier benchmarks made. **[OURS]**

### D6 — Does null-as-default remove the 2-threshold tax, or only gate it?

- `null_default.md` §3.2.3 keeps the **unchanged 7-T SA ×2** (one per polarity), only
  data-gated by `arm_push OR arm_pull`; §4 admits it "does not touch the 2-threshold tax."
- `optimization_ngram.md` §3.3 and `test_suite_spec.md` §3.1 make **threshold-count collapse
  (2 SAs → 1 native device)** the *point* of the native device.

**Conflict:** the design doc's null-as-default does **not** deliver the threshold-count win
the other two say is the reason native ternary might beat binary. The three are not
disagreeing about a fact — they are disagreeing about *what null-as-default achieves*.
`null_default.md` is honest that its scheme, alone, "does not by itself reverse the
polar_gates verdict on plain CMOS"; the other two implicitly rely on the native device
(not the null scheme) to do that. **[OURS]**

---

## 3. Merged TODO — ranked untested questions

Union of the three `## TODO / not covered / caveats` sections, ranked by how much the
answer would move the verdict. Provenance in brackets: [N]=`null_default.md`,
[O]=`optimization_ngram.md`, [T]=`test_suite_spec.md`.

1. **The native device, measured.** Pick ONE candidate (RTD is the literature-mature
   choice), model its 3-state I–V with a *named, latchable null*, and run its per-state
   switching energy against the **0.0865 pJ/trit receiver bar**. This is the whole thesis;
   every other row is downstream. [O#1, T§1 "no device model", N§3.3] **[SPECULATION — the
   thing `TERNARY_GROUND_UP.md` exists to test]**
2. **Stable-null vs relocated-saddle on the native device.** Is the native device's null a
   *stable fixed point* (two wells + origin), or merely the saddle relocated to the rails
   (the diode-rectifier outcome)? This decides whether "free null in the gate" is even
   physically available. [O#3, N§3.1/3.2] **[SPECULATION]**
3. **`null_default.cir` — the runnable-now A/B on the existing 2-level cell.** Rectifier +
   ±V_th dead-zone + data-gated SA: (a) is the held-null shoot-through actually removed?,
   (b) does the null land at the receiver floor (~0.05 pJ class)?, (c) what do the diode
   drop and integrate/reset overhead add? — **and crucially (d) run it free-running-clocked
   vs data-gated to settle D1 directly.** This is the only top-ranked item unblocked by the
   missing device model. [N#1] **[OURS — see §4]**
4. **Same-gate null-vs-+1 sweep to nail the 1.9 pJ shoot-through.** The MAX-vs-MIN delta is
   an inference from *different* gates, not a controlled A/B; a dedicated same-gate sweep
   de-risks the group's most-cited load-bearing number. [N#3] **[DIRECT for "it is an
   inference"; the fixed number is OURS]**
5. **Self-timed vs clock-gated overhead.** Measure the completion-detection/handshake energy
   and latency, and whether clock-gating the receiver behind the passive charge detector
   recovers *most but not all* of the null win in a clocked pipeline. This is the
   architectural crux D1 exposes and the test suite currently omits. [N#6, N#1(c)]
   **[OURS/SPECULATION]**
6. **Leakage/off-current model.** LEVEL=1 has no subthreshold leakage, so "idle = 0" is
   overstated; the null-as-default win must be re-priced against a real off-current floor for
   both the 2-level cell and the native device. [N#2, O#6, T§5.2] **[DIRECT for the LEVEL=1
   limitation; SPECULATION for the silicon/native floor]**
7. **Binary single-ended 0–1 V reference.** The current binary control shares ±1 V rails
   (generous to ternary); a 0–1 V single-ended binary cell (~2× cheaper) would move every
   verdict further against ternary and is the missing control. [T§TODO, O§1.1 swing
   accounting] **[DIRECT — polar_gates.md caveat]**
8. **Mismatch/offset re-run.** Real SA offset σ ≈ 5–20 mV makes null metastability *worse*;
   the dead-zone's V_th ≈ 50–100 mV vs this σ trade is untested, and any measured win is an
   upper bound until mismatch is modeled. [T§TODO, N#4] **[DIRECT for σ; SPECULATION for the
   re-run]**
9. **Per-gate Landauer reversibility audit.** Which of neg/cycle/min/max/mod-3-sum/consensus
   are permutations (Landauer-exempt) vs erasing? (neg and cycle are permutations; min/max/
   consensus are not.) [O#4] **[DIRECT for the partition; the audit is OURS]**
10. **Can the RTD's NDR snap be driven to return charge?** The "dissipative snap, not a
    shuttle" claim is literature inference; an external resonator coupling a native device to
    the LC tank (or the device *as* the tank's nonlinear element) is untested and would change
    the adiabatic picture. [O#5, O#8] **[SPECULATION]**
11. **Area-per-device (count vs footprint).** "Fewer devices but bigger devices" is
    un-quantified; area is the headline, count is a diagnostic, and it stays count-only until
    a per-device µm² exists. [T§TODO, O#8] **[ANALOGY for the CNTFET/RTD footprint claim]**
12. **Load-bearing cells out of scope: 3-input balanced full adder (carry) + mod-3 product
    (`tmul`).** The carry needs two more thresholds and is the hardest cell; `tmul` completes
    the F₃ pair. Both are the real arithmetic, not the 2-input toy set. [T§TODO]
    **[OURS — flagged in polar_gates.md]**
13. **Storage null-as-default (retention) + the `11=NEVER` spare state.** The ternary FF's
    "both rails discharged" null is a *different* (retention vs idle) mechanism, and the spare
    state could encode an arm/valid handshake in the event scheme. Both untouched. [N#7, N#8]
    **[OURS/SPECULATION]**
14. **Housekeeping.** Correct `ENERGY_IDEAS.md` §2.1's "2.9 aJ" → "2.9 zJ" [O#7]; fix the
    ngspice `DERIV` vs ΔI/Δt di/dt convention [T§TODO]. **[DIRECT — unit error]**

---

## 4. The one decisive experiment

**The blocking experiment (highest ceiling, not runnable):** a native RTD device measured at
per-state switching energy with a natively-stable null vs the 0.0865 pJ/trit bar. This is
the thesis itself and would settle the verdict *in principle* — but it is blocked on a
device model that does not exist, so it is not the answer to "one design experiment we can
run next." **[SPECULATION]**

**The decisive *design* experiment (runnable now, most moves the verdict):**

> **`circuit/null_default.cir` — the `tcell4` rectifier + ±V_th dead-zone + data-gated SA,
> built on the existing 2-level cell, measured in BOTH configurations: (A) free-running
> clocked, and (B) data-gated (SA clock = `arm_push OR arm_pull`).** [N#1, extended]

Three measurements decide it, against a three-way pass bar:

1. **Held-null shoot-through** — does the dead-zone move the null off the trip point so the
   null-input current drops from the ~1.9 pJ/toggle shoot-through to the leakage floor?
   (D1/D4; the meta-point repair.)
2. **Null symbol energy** — in (B), does a null land at the receiver floor (~0.05 pJ class),
   and does (A) vs (B) differ by roughly one receiver eval (0.052–0.087 pJ)? **This is the
   measurement that settles D1** — the difference between the two configs *is* the
   self-timed-vs-synchronous crux, measured as a number.
3. **The overhead** — diode drop + integrate/reset + dead-zone signal-window loss, reported
   as a separate line item so the "fix" is not credited with the "cost" (D4).

**Why this one, and not the native device:**

- It is the **only top-ranked question that is unblocked** — it runs on the 2-level harness
  we already have, today, with no device model.
- It is the **one experiment all three docs converge on** as the immediate next step
  (`null_default.md` names it verbatim as its #1 TODO), and it is the experiment that the
  *test suite as specified would miss* (it measures static P_null, not the per-clock eval).
- Its outcome **branches the entire search in both directions.** If (B) beats (A) by a full
  eval and null reaches the receiver floor, then null-as-default is recoverable on the
  *existing* cell — which *re-prices the native-device bet* (the win was never exclusively
  the native device's). If (A) and (B) are equal, or the diode/overhead eats the win, then
  null-as-default is confirmed as a **self-timing-only** property, and the native device's
  stable-null (TODO #2) becomes the *only* path — sharpening the verdict either way.
  **[OURS]**

**Calibration of this recommendation:** the components are DIRECT (tcell4 rectifier, 7-T SA
at 0.052–0.087 pJ, dead-zone anchored to the measured 22 mV resolution / 5–20 mV offset);
the prediction that (A) and (B) will differ by ~one eval is OURS (arithmetic on the measured
floor); the claim that this re-prices the native-device bet is SPECULATION.

---

## 5. Calibration summary

| synthesis claim | calibration |
|---|---|
| null free on wire / expensive in gate (agreed) | DIRECT — polar_gates.md |
| receiver is the binding floor, not Landauer | DIRECT — receiver_cheap.md, ENERGY_RESULTS.md |
| native device unbuilt/unmeasured; its win is the thesis | DIRECT (2-level measured) + SPECULATION (native) |
| D1: free-null is self-timed-only in one doc, static in two | OURS (reading of the three) |
| D3: 0.05 pJ = physical zero vs keeper cost | OURS (both readings are DIRECT; the conflict is attribution) |
| D4: rectifier is fix (N) vs cost (O) | OURS |
| merged-TODO ranking (1–14) | OURS (ranking) on DIRECT/SPECULATION items |
| null_default.cir is the decisive experiment | OURS (recommendation); SPECULATION (that it re-prices the bet) |
| native RTD vs 0.0865 pJ/trit is the *blocking* experiment | SPECULATION |

---

## TODO / not covered / caveats

- **This synthesis did not re-read the source logs** (`ENERGY_RESULTS.md`, `polar_gates.md`,
  `receiver_cheap.md`, `gate_energy.md`, `ENERGY_LAWS.md`); every number above is carried
  from the three batch-1 reports, which themselves cite those files. A cross-check pass
  against the raw logs is unfiled.
- **The group is one corner of a 10-angle batch.** `device_physics.md`, `device_literature.md`,
  `device_circuit.md`, `truth_table.md`, `minimal_gates.md`, `meta_critique.md`,
  `analog_polar.md`, `differential_noise.md` were not synthesized here. The TODO ranking is
  therefore incomplete until merged with the device/literature angles' TODOs (e.g. which
  candidate device, and its own model requirements, are decided there).
- **The D1 conflict is asserted, not resolved.** The right fix — extend `test_suite_spec.md`
  §4.4 to add a *dynamic* null-eval measurement (energy of a null symbol per free-running
  clock edge) — is a concrete spec change this synthesis recommends but does not itself write.
- **"Most moves the verdict" is a judgment call.** The native device (TODO #1) has a strictly
  higher ceiling than `null_default.cir`; it is demoted here only because it is blocked. If a
  device model lands first, the ranking flips.
- **The two-binary-control discipline (§7.4/§2) is not yet reflected in any run.** Both the
  same-device 2-state control and the 0–1 V single-ended control are spec'd but unmeasured;
  until they run, every "ternary beats binary" number is optimistic.
- **No workload model.** The uniform toggle distribution is the headline everywhere; the
  null-dominated (Zipf) average — where the transport win lives — is reported nowhere as a
  measured number, only asserted. D2 remains open until a real trit-activity trace exists.
- **Temperature, mismatch, and process are unmodeled** across the whole group; the LC-tank ×
  native-device interaction (can the device *be* the tank's nonlinear element?) is untouched.
- **Out of scope here (carried, not resolved):** 3-level storage/DRAM retention, the
  `11=NEVER` arm/valid spare-state handshake, and the per-gate Landauer audit.
