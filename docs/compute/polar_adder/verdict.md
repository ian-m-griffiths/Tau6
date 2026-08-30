# Verdict — the polar current-mode ternary adder

**Question on the table:** is it worth building and testing Ian's polar current-mode ternary
adder (the Kirchhoff-sum adder: signed trit currents summed on one node) against binary for
power and size?

**Calibration legend** (house standard): **DIRECT** = measured (ngspice/yosys `.log`) or a
physical/citable identity. **DERIVED** = one arithmetic step on DIRECT numbers. **OURS** = a
design claim following from DIRECT but not yet simulated. **SPECULATION** = untested hypothesis.

---

## 0. The bottom line, up front

**The Kirchhoff sum is free, the carry threshold is not, and the carry threshold is where the
information lives — so the polar current-mode adder lands at the 1.26× floor, not below it.**
It is a *much cheaper ternary adder than the 192 T emulation it would replace* — plausibly
~20–60 T, in the ballpark of the literature's optimized 118-T current-mode ternary FA — but it
does **not** beat the 28 T binary full adder, because the direction sense alone (2 devices per
input, ~42 T for three inputs) exceeds the whole binary cell before the carry is touched. It does
**not** cross the `2·ln2/ln3 ≈ 1.26×` per-bit line, because the free sum only removes the
*formation* of the digit sum, while the *read* of that sum (three output states) is still a
two-threshold measurement. Recommendation: **build the minimal carry-threshold + direction-sense
cell and measure the threshold cost** — it is cheap to run, and it is the only measurement that
can still move the verdict. Do **not** commit to a full adder first.

---

## 1. The measured numbers (what we actually have)

The polar current-mode adder itself has **no measured device count and no measured energy** — no
netlist has been run. What we *do* have is measured, and it frames the whole decision.

### 1.1 The baselines (DIRECT)

| cell | transistors | energy / toggle | calibration |
|---|---:|---:|---|
| **binary full adder** (canonical) | **~28 T** | — | DIRECT/ANALOGY — textbook count; the harness's own sky130 note says `badd1 ≈ 24–28 T` |
| binary full adder (our harness `bin_fa`) | 58 T | **0.185 fJ** | DIRECT — `circuit/trelax.cir`, LEVEL=1 switching-only |
| binary NOT (single-ended, real load) | 2 T | **6.94 fJ** | DIRECT — `circuit/fair_binary.cir` |
| **binary energy per add** | — | **~6–12 fJ** | DERIVED — band of the measured single-ended gate toggles (NOT 6.94 / NAND 11.36 fJ), `binary_baseline.md` §3 |
| **binary transport** | — | **0.512 pJ/bit** | DIRECT — `fair_binary.cir` BT1 |
| **CMOS ternary full adder** (`tadd1`, 2-wire static emulation) | **192 T** (naive boolean) / 118 T (literature-optimized) | **0.355 fJ** | DIRECT — `circuit/trelax.cir`; 118 T is ANALOGY (`Automated_synthesis`) |
| ternary/binary full-adder ratio | | | **1.92× energy, 3.31× transistors, 4.33× area** — DIRECT |
| native polar gate (`dd_not`, the closest measured "native polar" gate) | ~18 T-class | **54.2 fJ** (null↔+1) / **368.7 fJ** (+1↔−1) | DIRECT — `circuit/diode_gates.cir` + `fair_binary.cir` |

Three calibrations that matter and are easy to miss:

1. **The 192 T / 0.355 fJ ternary number is the *2-wire static-CMOS emulation*.** It is not a
   current-mode adder, and it is the thing the polar design is trying to beat. Its 4.33× area
   penalty is the 2-threshold tax of a signed 3-valued digit carried on two rails
   (`full_adder_comparison.md` §4). **DIRECT.**
2. **The 54–368 fJ "ternary" energies are a *NOT gate* (a wire swap, 0 transistors of logic), not
   an adder.** Even the free gate costs 54 fJ (cheapest toggle) because it must resolve 3 levels
   and return the null through a leaking termination. 89–93% of that is null-return leakage, not
   logic (`ternary_power_story.md` §3). **DIRECT.** An adder can only be worse than its cheapest
   gate.

3. **The three "binary energy" figures are three different conventions and must not be mixed.**
   `6.94 fJ` is the single-ended NOT *toggle*; `0.185 fJ` is the LEVEL=1 *switching-only* full-adder
   number (no leakage, toy load); `~6–12 fJ` is the honest per-add *band* derived from the measured
   gate toggles. The `0.185 vs 0.355 fJ → 1.92×` ratio is the only *like-for-like* ternary-vs-binary
   comparison; for an absolute yardstick the adder must be held against **~6–12 fJ per add and
   0.512 pJ/bit transport**, not against 0.185 fJ. **DIRECT (each number) / DERIVED (the band).**

### 1.2 What is known about the polar current-mode adder (DIRECT physics, no measurement)

Exactly two load-bearing facts are DIRECT — one in Ian's favor, one against:

- **The sum is free.** `σ = a + b + cin` is a wire junction: Kirchhoff's current law adds signed
  currents for nothing. This is the single most concrete thing current-mode buys, and it removes
  the *digit-sum construction* that made the voltage-mode mod-3 sum the expensive cell (100 T
  measured). **DIRECT — KCL is a conservation identity, not an analogy.** (`analog_polar.md` §1,
  §3.1.)
- **The null is a dead zone, not a saddle.** A current null is `0 A` — a full `I_th` *below* every
  trip point — where a voltage null sits *exactly on* the comparator threshold and draws ~1.9 pJ of
  shoot-through (`polar_gates.md`, measured). Current-mode makes the null natively free inside the
  gate. **OURS** (mechanism argued, not yet measured) — `analog_polar.md` §3.1 Item 2.

Everything else about the polar adder — its device count, its energy, whether the null really is
free in silicon — is **OURS/SPECULATION** until a netlist is drawn and run.

### 1.3 The projected polar current-mode full adder (DERIVED, not measured)

Working from the DIRECT structure (`analog_polar.md` §3.2, §5 Idea A; `adversarial_verdict.md` §1–2):

```
direction sense (per input) →  2 devices / 14 T (2×7-T sense amp)  × 3 inputs = 6 dev / 42 T
σ = Ia + Ib + Icin          →  a wire junction                                 = 0 T   (KCL, DIRECT)
carry:  detect |σ| ≥ 2      →  2 current comparators                           = ~14–20 T (trip at ±3I₀/2)
sum:    σ mod 3, sign       →  1–2 comparators + a 3:1 steering mirror         = ~7–14 T + mirror
crossbar routing (3×3)      →  9 intersection devices                          = ≥9 T
```

The **direction sense is not free**: before `I_a`, `I_b`, `I_cin` can be summed, each input must be
*read* as one of three states and *steered* onto the node — and that read is 2 devices per input
(the null needs a presence test on top of the push/pull sign test). **A 3-input adder pays ~42 T of
receiver before any logic — more than the entire 28-T binary full adder, before the carry is even
touched.** (`adversarial_verdict.md` §Trap 1; `meta_math.md` §4 — "direction = 2 decisions,
relabeled not removed.")

Net: a **~20–60 transistor-class cell** before output drivers and the standing current source. That
is genuinely smaller than the 192 T naive ternary cell (the KCL sum removes the 100 T mod-3-sum
construction), and it is in the ballpark of the literature's 118-T optimized current-mode ternary
FA — but it is **not** smaller than 28 T, because the receiver alone already exceeds it.
**DERIVED/OURS/SPECULATION** — this is the honest *estimate*, not a measurement, and it is the
number the minimal build in §4 would turn into one. The two caveats that stop it being a "win" are
in §3.

---

## 2. The honest answer: is it worth testing against binary for power and size?

**Yes, test it — but for the *right* reason, and expect the wrong answer on the headline metric.**

What a fair measurement would most likely find, in order of confidence:

1. **The sum really is free.** The current-sum node will add three signed currents with no
   transistors and no error beyond mirror mismatch. **DIRECT physics; near-certain.** This part of
   the idea is correct and worth having on the record.

2. **The null really is cheaper than the voltage null.** The 1.9 pJ/toggle shoot-through that
   killed `polar_gates.cir` should collapse toward the leakage floor, because `0 A` sits a full
   threshold below every trip point. **OURS; likely** — this is the single most credible claim in
   the design.

3. **The carry + direction sense still cost two thresholds, and that keeps it ≥ 1.26× binary per
   bit.** Reading `σ` as "one of three output states" is a two-boundary decision, whether you do
   it with voltage rails or current comparators. The free sum does not make the *read* free.
   **DERIVED from Law 1 / `ThresholdLowerBound.lean`; near-certain** — see §3.

4. **Static current-mode draws idle tail current in every state, including null.** If the adder is
   built as *static* current-mode (the CMMVL mainstream), it burns bias power on null — the exact
   opposite of the null-as-default rule the whole polar transport win depends on — at **~10–100 fJ
   of idle drain per cycle against binary's 6.94 fJ total dynamic toggle** (`adversarial_verdict.md`
   §Trap 3). To keep the null free it must go *charge-packet/dynamic*, which pays a
   self-timing/completion-detection tax. **DIRECT (Current 1994's own cost statement) for static
   mode; OURS for the charge-packet fork.**

5. **This is a 40-year-old field, and its own fair comparisons already said "no."** Signed
   current-mode ternary adders with KCL-sum + comparator-carry have been published since the 1980s
   (`current_mode_literature.md` §2). The modern equal-technology comparisons (2020–2022 CNTFET)
   are unanimous: *"the transistor count ratio between ternary and binary implementations is always
   greater than the information ratio log₂3 ≈ 1.585"*, and binary wins on power, delay, area, and
   PDP (`current_mode_literature.md` §3.2; arXiv:2101.01516, 2005.02678, 2206.03252). **DIRECT
   citations.** The free sum is real and known; the carry threshold + static power eating it is
   equally known. Nothing here predicts a different outcome on CMOS.

So the test would find: **the free sum and the free null are real, and the adder is the best
ternary adder we have — but it does not beat binary on power or size.** On size it improves
sharply *against the ternary baseline* (from the 192 T emulation's 3.3–6.9× down to roughly
~1.5–2× binary) but it does **not** cross below 1× — the receiver alone (42 T) is already larger
than the 28 T binary cell. On power it is a wash-to-loss: the 2-threshold read is fixed, and either
tail current (static mode) or self-timing (charge-packet mode) is added on top of it. The one thing
it would *not* find is a win over binary at the gate.

---

## 3. The ONE thing that matters

The whole verdict reduces to a single question: **does the free Kirchhoff sum change the floor, or
only the ceiling?**

The answer is unambiguous, and it is the honest heart of this document:

**The free sum lowers the *ceiling* (how bad ternary can be), not the *floor* (how good it can
be).** The floor is the `1.26×` from `2·ln2/ln3` — the information-theoretic price of naming one
of three states with two binary discriminations, per the 1.585 bits a trit carries. That number is
proved representation-independent (`ThresholdLowerBound.lean`, `meta_math.md` §2): ordered
thresholds, binary-decision counts, and sign+magnitude erasure all land on the *same* 1.26×.
**DIRECT (proved).**

Current-mode does not touch it. Concretely, the current-mode `⊕` is:

```
free KCL sum  +  a carry detector (2 current thresholds at ±3I₀/2)
              +  a current-steering correction (subtract 3I₀ when the carry fires)
```

The sum is free, **but the carry detector is the same two-boundary measurement that the voltage
mode paid** — current-mode "did not reduce two boundaries to one, any more than multi-Vt did"
(`analog_polar.md` §3.2). The wrap (`σ = ±2 → ∓1`) *is* the carry, and the carry is where the
information lives. So:

- **The free Kirchhoff sum + cheap polar transport do NOT change the verdict.** They move the wall
  from "demux + driver" to "quantizer + tail" — a *better* polar gate, not a *winning* one.
- **The carry threshold + direction sense keep it at the 1.26× floor.** The direction sense is the
  two-threshold read of the sum; the carry threshold is two more thresholds on top. This is why
  the honest sentence is exactly: *"the sum is free but the carry threshold eats it, so it lands
  near the 1.26× floor, not a win."*

The one escape that would reopen this — and it must be said plainly so Ian knows what he'd have to
find — is a **device that resolves 3 states in fewer than 2 measurements** (a genuine native
3-state device: multi-Vt / CNTFET / memristor), or a **null that is free *and* draws zero static
current** inside the gate. Current-mode delivers the second (the 0 A dead zone) but explicitly not
the first. Until one of those exists, ternary compute loses at the gate and wins only on the wire
(0.081 pJ/bit transport, already measured and already the transport cell's, not the adder's).

---

## 4. Recommendation

**Build the minimal version to measure the threshold cost. Do not build the full adder.**

The single measurement that settles the verdict is cheap, already spec'd, and runs in the existing
LEVEL=1 harness (current sources, mirrors, the 7-T sense amp all model fine — no exotic device
needed). It is `analog_polar.md` §5, **Idea A + Idea B**:

1. **The carry-threshold + direction-sense cell** (Idea A): the KCL sum node + two current
   comparators at `±3I₀/2` + the 3:1 steering mirror. Measure (a) the truth table, (b) the
   carry-detector energy `e_carry` against the 100 T voltage baseline, and (c) the null-null idle
   current `i_idle`.
2. **The null-vs-push idle test** (Idea B): reproduce the held-null and measure `e_null / e_push`.
   If it drops toward ~0 (vs the measured ~0.5× for the voltage gate), the null-as-zero-current
   claim is real.

**Pass/fail, stated up front so the result cannot be talked around:**

- **If** `e_carry` comes in ≪ the 100 T baseline's gate energy **and** `i_idle ≈ 0` (leakage
  floor) **and** `e_null/e_push → 0` — then the current-mode adder is genuinely cheap, it earns a
  full adder build, and it *might* land near the 1.26× floor rather than above it.
- **If** (the honest prediction, following Law 1 and the CMMVL literature) the carry detector
  costs ~2 thresholds and/or static mode draws tail current on null — then the verdict is closed:
  the sum is free, the read is not, and it lands at the floor. Record it and move on.

The reason this is the right scope is not optimism — it is that **the cost of running this minimal
cell is a day or two of ngspice, and it is the only measurement left that can still move the
verdict.** Building the full adder first spends the same effort for a result that is already
predictable from `analog_polar.md` §3.2 and `ThresholdLowerBound.lean`: a better ternary adder,
not a winning one.

**One-line recommendation:** build the minimal carry-threshold + direction-sense cell and measure
the threshold cost — because the free sum is real and worth confirming, but the carry threshold is
where the 1.26× lives, and until it is measured the polar adder is a *promising ternary cell*, not
a competitor to binary.

---

## Calibration ledger

| claim | calibration |
|---|---|
| binary FA ~28 T canonical; harness 58 T / 0.185 fJ | DIRECT/ANALOGY — textbook + `trelax.cir` |
| binary NOT 6.94 fJ; per add ~6–12 fJ; transport 0.512 pJ/bit | DIRECT (6.94, 0.512) / DERIVED (band) — `fair_binary.cir`, `binary_baseline.md` |
| ternary `tadd1` 192 T / 0.355 fJ; 118 T optimized | DIRECT (192/0.355) / ANALOGY (118) — `trelax.cir`, `Automated_synthesis` |
| ternary/binary FA = 1.92× energy, 3.31× T, 4.33× area | DIRECT — `trelax_measured.md`, `gate_area.md` |
| native polar `dd_not` 54.2 / 368.7 fJ | DIRECT — `diode_gates.cir`, `fair_binary.cir` |
| KCL adds signed currents for free | DIRECT — Kirchhoff's current law |
| direction sense = 2 devices/input; 42 T receiver before any logic (3 inputs) | DIRECT — `gate_energy.md` (2.54×), `polar_gates.md` (14 T/input); count DERIVED |
| 9 crossbar intersections are devices, not free wires | OURS — `adversarial_verdict.md` §Trap 5 |
| null = 0 A is a dead zone (removes ~1.9 pJ shoot-through) | OURS — mechanism, unmeasured |
| the wrap/carry is still a 2-threshold measurement | DERIVED — `device_physics.md` §2.3, `ThresholdLowerBound.lean` |
| 1.26× floor = 2·ln2/ln3 | DIRECT (proved) — `ThresholdLowerBound.lean` |
| literature: ternary/binary transistor ratio always > 1.585 | DIRECT citations — arXiv:2101.01516, 2005.02678, 2206.03252 |
| polar FA ≈ 20–60 T: smaller than 192 T, not 28 T | OURS/SPECULATION — estimate, not measured |
| static current-mode draws idle tail current (~10–100 fJ/cycle) | DIRECT (Current 1994) / DERIVED (magnitude) |
| minimal build settles it (Idea A + B) | OURS — design targets, not run |

---

## Sources

Sibling docs in this tree (the direct inputs to this verdict):
- `docs/compute/polar_adder/binary_baseline.md` — 28 T (16 T sum + 12 T carry), ~6–12 fJ per add,
  0.512 pJ/bit transport, the "one threshold vs two" yardstick.
- `docs/compute/polar_adder/polar_full_adder_design.md` — the crossbar realization (18 junctions +
  9 ORs per full adder), unbalanced 0/1/2 convention, binary carry.
- `docs/compute/polar_adder/adversarial_verdict.md` — the hostile pass: the 5 traps, the 42-T
  receiver-before-logic count, the ~20–60 T estimate, "beats 192 T, not 28 T".
- `docs/compute/polar_adder/current_mode_literature.md` — the 40-year prior-art survey; the
  "transistor ratio always > 1.585" equal-technology verdict (arXiv:2101.01516, 2005.02678,
  2206.03252).

Underlying measurements and proofs:
- `docs/compute/ground_up/analog_polar.md` — the current-mode survey + Ideas A/B/C; the "free sum,
  priced wrap" argument; the CMMVL literature.
- `docs/compute/circuit_diagrams/full_adder_comparison.md` — 192 T vs 58 T, the 4.33× mechanism.
- `docs/compute/circuit_diagrams/ternary_power_story.md` — 6.94 / 54.2 / 368.7 fJ, the 1.26× floor,
  the sensing+leakage decomposition.
- `docs/compute/field_calculus/trelax_measured.md` — 0.355 vs 0.185 fJ (1.92×), current-mode
  neighbor-sum explicitly unmeasured (SPECULATION).
- `docs/compute/polar_gates.md` — the native polar gate wall (demux+driver, metastable null).
- `docs/compute/junction_cost_verdict.md` — the transport-vs-gate split, the 1.26× floor.
- `docs/compute/ground_up/meta_math.md` — representation-independence of the 1.26× floor.
- `proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean` — the proved 1.26×.

*Every DIRECT number above is read from a cited ngspice/yosys `.log` or a proved Lean theorem; the
polar adder's own numbers are explicitly OURS/SPECULATION because no polar-adder netlist has been
run. Nothing is invented.*
