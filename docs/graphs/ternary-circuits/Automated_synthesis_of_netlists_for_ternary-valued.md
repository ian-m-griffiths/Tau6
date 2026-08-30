# Automated synthesis of netlists for ternary-valued n-ary logic functions in CNTFET circuits
Risto, Bos & Gundersen (Ternary Research Group, University of South-Eastern Norway), SIMS 2020 (DOI 10.3384/ecp20176483). An open-source C++ synthesizer that takes an n-dimensional ternary truth table and emits a ready-to-simulate SPICE subcircuit netlist for CNTFET circuits, built on the static ternary gate design methodology (Kim et al. 2018) with pull-up/pull-down networks + external PTI/NTI inverters. Proposes a canonical **function indexing** system (base-3 truth-table index, heptavintimal base-27 notation) because most of the 19,683 2-input ternary functions have no names. Compares compound vs non-compound vs hybrid 1-trit balanced full-adders in HSPICE: the 3-operand hybrid wins on power–delay product. This is the ternary-world analogue of our Yosys step.

## 1. Node inventory (id | type | name | one-line | location)

| id | type | name | one-line | location |
|----|------|------|---------|----------|
| N1 | METHOD | static ternary gate design | build pull-up/pull-down transistor networks straight from a truth table; external 2-transistor PTI/NTI (positive/negative ternary) inverters provide the four transistor operations (Kim et al. 2018) | §1, §3 |
| N2 | METHOD | automated netlist synthesizer | open-source C++: input = arity + truth-table values {low 0, middle 1, high 2, don't care x} + CNTFET model/transistor params; output = ready-to-simulate SPICE subcircuit, filename = function index | §3.1 |
| N3 | DEFINITION | function indexing | any ternary function = its truth table read as a base-3 number; `Frange = R^(R^A)` functions (radix 3: arity 1 → 27, arity 2 → 19,683, arity 3 → 7.6e12); heptavintimal base-27 packs 3 trits/symbol (Jones 2012) | §2, Table 1–2 |
| N4 | METHOD | logic minimization | Karnaugh-like: find fewest n-dim rectangular groupings of 1s per pull-up/pull-down network; each grouping = a transistor path to the output | §3.2 |
| N5 | RESULT | balanced full-adder comparison | 1-trit balanced FA: compound (2-operand, 118 tr) vs non-compound (3-operand, 188 tr) vs hybrid (118 tr); **hybrid wins on PDP** (1.10e-15 J @500MHz vs compound 1.44e-15 J); 3-operand functions can beat 2-operand composition in some cases | §4, Table 3 |
| N6 | RESULT | simulation setup | HSPICE, Stanford 32nm CNFET compact model (Deng & Wong 2007), 0.9 V supply, 2 fF load; thresholds <200 mV low, 250–650 mV middle, >700 mV high | §5 |
| N7 | CLAIM | coverage | any 1-output ternary function up to 7 operands can be synthesized; runtime grows with arity | §6, §7 |
| N8 | METHOD | holistic (non-compound) design | treat the 3-operand function (e.g. 3-input carry) as one relation input→output instead of composing 2-operand gates | §4, Fig 1–2 |
| N9 | CLAIM | why indexing | binary has few enough functions to name (AND, OR, XOR); ternary's function count grows exponentially — most ternary functions have no semantic name | §1, §2 |

## 2. Edge inventory (src→tgt | type | calibration | evidence)

| src→tgt | type | calibration | evidence |
|---------|------|-------------|----------|
| N1→N2 | derives-from | — | the synthesizer implements the static (Kim) methodology |
| N2→N4 | requires | — | the grouping algorithm is the minimizer inside the tool |
| N3→N2 | supports | — | the index names the generated files and references any function unambiguously |
| N9→N3 | derives-from | — | indexing exists because semantic naming fails at 19,683 functions |
| N1→N5 | requires | — | the FA circuits are built from the static methodology |
| N8→N5 | derives-from | — | the non-compound/hybrid designs ARE the holistic 3-operand approach |
| N6→N5 | supports | — | all comparisons are measured in HSPICE/CNFET |
| N5→N7 | supports | — | the general synthesizer is what the FA case demonstrates |

## 3. Counter-to / reversal edges

- **C1 — "Compound (2-operand) composition is the standard, best way to build ternary functions" is FALSE for the balanced full-adder.** The non-compound/hybrid (3-operand) designs beat the compound design on power–delay product (hybrid 1.10e-15 J vs compound 1.44e-15 J @500MHz; hybrid 0.56 ns vs 0.55 ns delay — comparable delay at 44% less energy). Treating the 3-input function as one relation beats composing 2-input gates.
- **C2 — "Ternary gates have semantic names like AND/OR" is FALSE in general.** 19,683 binary-arity-2 ternary functions (7.6e12 at arity 3) — only a handful are named; naming is infeasible, indexing is mandatory (N3/N9).
- **C3 — "More operands = more transistors, so worse" is the wrong metric.** The 3-sum cell (150 tr) and 3-carry (50 tr) have more transistors than their 2-operand counterparts (40 / 10), yet the *system* (full adder) wins on PDP via the hybrid design — transistor count is not the figure of merit; power×delay is.

## 4. Map-to-current-system (lens) — TERNARY CIRCUITS

| paper concept | our system | calibration | evidence |
|---------------|-----------|-------------|----------|
| **Truth-table → automated netlist synthesis** (C++ → SPICE netlist → HSPICE simulation) | our Yosys step: `rtl/*.v` (ternary_gates.v, trit_functions.vh, cpu.v) → yosys synth (~6–7K cells, 213 FFs) → iverilog/vvp verification (STATE_NOTE; plan §7) | **DIRECT** | same pipeline shape — design intent → automated netlist → simulation/verification. Their backend is CNTFET/SPICE at the transistor level; ours is yosys/standard cells at the gate level. This is the paper Ian flagged as "maps to our Yosys step" |
| **Function indexing: truth table as base-3 number** (heptavintimal base-27 for 3 trits) | our trit encoding `01/00/10/11` and hand-written cells `tneg/tmul/tand/tor/tadd1` (rtl/trit_functions.vh) | **DIRECT (tooling reuse)** | the indexing scheme is directly adoptable: it would name/uniquely reference any of the 19,683 2-input ternary functions in our RTL without ambiguity — a naming standard we currently lack (we only use 6 named cells) |
| **Don't-care `x` in the truth table** (minimization freedom) | `2'b11 = never` — never produced, don't-care input (trit_functions.vh header; TernaryCell.lean `never-both`/`not-surjective`) | **DIRECT** | identical concept: the unused/unreachable state is free minimization material on both sides; our 11 slot is exactly their x |
| **3-operand balanced full-adder beats 2-operand composition (hybrid wins PDP)** | our `tadd1` is already a **3-operand** full-adder cell: `s = a+b+cin`, balanced carry rule +1+1 → sum −1 cout +1, −1−1 → sum +1 cout −1 (rtl/trit_functions.vh lines 32–49) | **DIRECT (validates our cell choice)** | their measured result is independent confirmation that the non-compound 3-input design (what tadd1 implements) is the right strategy — we got the architecture right without this paper |
| **Balanced carry rule** (digit sums stay in {−2,…,+2}, carry ±1) | same bounded-carry rule in tadd1 and TERNARY_PROCESSOR §1.1 ("addition has a small carry") | **DIRECT** | identical balanced-ternary addition logic, independently re-derived |
| **PTI/NTI external inverters (Kim)** as gate primitives | our `tneg` (wire swap +1↔−1) + `tand`/`tor` (min/max) cells | **ANALOGY** | both decompose ternary logic into inverter + network primitives; different primitives (level-inverting PTI/NTI vs our one-hot direction cells) |
| **Heptavintimal base-27 packing** (3 trits per symbol) | our 12-trit-in-24-bit packing (4×3 = 12, LCM of 8 and 12; TERNARY_PROCESSOR §2.2) | **ANALOGY** | both compactly pack 3 trits per encoded symbol; different radix choices (27 vs 24-bit words) |
| **HSPICE energy numbers** (CNTFET 0.9 V, PDP per gate) | our per-transition energy model: ≤1 energized line, null = 0, avg 2/3 vs binary 1 (TernaryCell, PROVED; STATE_NOTE) | **ANALOGY** | both report ternary energy — theirs SPICE-simulated device-level PDP, ours an abstract line-energy bound; unbridgeable without a power-analysis pass (Yosys power pass is a future direction per STATE_NOTE) |
| **Synthesis to CNTFET transistors** (ternary stays physical) | our yosys maps ternary RTL semantics onto **binary standard cells** (213 FFs) | **OURS / contrast** | they keep ternary at the transistor level; we compile ternary→binary gates — both are "automated synthesis of ternary logic" at different abstraction layers; ours is the only one relevant to `rtl/` |
| **Function count explosion** (R^(R^A): 19,683 / 7.6e12) | our 4-symbol cell encoding (2 bits) with 27 reachable (a,b,cin) triples in tadd1 | **ANALOGY** | both quantify the combinatorial size of the ternary function space; motivates why we hand-pick 6 cells rather than enumerate |

## 5. One-liner

**The Yosys-analog for ternary: an open-source truth-table→netlist synthesizer (CNTFET/SPICE) plus a canonical base-3 function-indexing scheme whose don't-care `x` is exactly our `11 = never` slot, and HSPICE evidence that a 3-operand balanced full-adder — precisely our `tadd1` cell — beats 2-operand composition on power–delay product; the indexing scheme, the don't-care slot, and the 3-operand design strategy are DIRECTLY reusable in our RTL, the CNTFET backend and its energy numbers are not.**
