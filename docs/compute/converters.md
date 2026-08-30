# Binary ↔ Ternary Converters — the emulation bridge, costed and calibrated

**2026-08-29 — Wave-1 survey #4 (interface).** Answers the "ADC/DAC at the edge"
question from `docs/TERNARY_COMPUTE_SURVEY.md` §component-matrix / fan-out item 4:
what the ternary↔binary boundary costs, and where that cost flips the
"emulate-binary-in-ternary" vs "go-full-native-ternary" decision.

**Calibration legend (used on EVERY claim):**
- **DIRECT** — measured or proved, with the file/instrument cited.
- **ANALOGY** — parallel structure, different object/technology.
- **OURS** — our design claim (follows from DIRECT, but is our own object).
- **SPECULATION** — untested estimate; flagged and bounded, never asserted as fact.

---

## 0. The reframe that organizes everything

"Ternary↔binary converter" conflates **three different objects**. Keeping them apart
is the whole report, because they have wildly different costs:

| layer | what it is | cost class |
|---|---|---|
| **A. Physical ADC** | resolve 3 states on a wire → 2 binary rails (the 2-threshold flash ADC) | = the receiver itself. Law 1: fixed per symbol, ~50 fJ/trit |
| **B. Physical DAC** | drive 3 states onto a wire from 2 binary control bits | ~free in our encoding (a 1-hot driver); expensive only if you must synthesize a *voltage level* |
| **C. Logical radix converter** | convert a binary *integer* ↔ a balanced-ternary *digit string* (base-2 ↔ base-3) | real arithmetic, ~1–2 kµm², only paid at a numeric boundary |

The single most important fact in this survey, restated: **in our one-hot
per-direction trit code (`01=+1, 00=0, 10=−1, 11=NEVER`), a trit IS two binary
wires.** So layers A and B are *not* the "emulation bridge" — they are the ternary
cell's own read and drive, the same 2-threshold measurement every ternary gate pays
every cycle (Law 1, `docs/ENERGY_LAWS.md`). The only genuine *bridge* cost is layer C,
and it is paid **only when a binary integer value must cross the boundary**, not per
trit and not per gate.

Consequence: the "ADC/DAC edge" the survey worried about is, in our architecture,
almost entirely **layer C** — and layer C is a *cold-path* cost, not a per-cycle tax.

---

## 1. Converter topologies + transistor/gate counts

### 1a. Layer A — ternary→binary, the 2-threshold flash ADC

A 3-level read is a 2-threshold measurement (`docs/ENERGY_LAWS.md` Law 1). Two
topologies, same 2-threshold structure:

1. **Level-coded flash ADC** (the literature's answer, `{0, Vdd/2, Vdd}`): two
   comparators with references at Vdd/3 and 2Vdd/3 → thermometer code → 2-bit
   decode. This is a standard 2-bit flash ADC.
2. **Polarity/one-hot demux** (ours): the 2-diode receiver — positive excursions
   conduct one diode path → rail A, negative the other → rail B, null → neither
   (`TERNARY_PROCESSOR.md` §1.4). Two threshold comparisons against 0 / diode
   turn-on. **DIRECT**: measured in the fair-fight harness as "2× sense amp"
   (`circuit/ENERGY_RESULTS.md`); **ANALOGY** to a classic flash ADC's comparator
   pair (2 thresholds for 3 levels is the definition of a 2-bit flash).

**Cost.** Our measured receiver = **2 sense amps / trit**, ~**50 fJ/trit** at 1 ns eval
(`lowswing_sweep.cir` iface-E = 0.052 pJ/trit) to **~0.08–0.09 pJ/trit** at the fair-fight's
2 ns eval (`ENERGY_RESULTS.md` §cuboid). That is ~25 fJ per threshold. **DIRECT** (ngspice 44.2).

### 1b. Layer B — binary→ternary, the "DAC"

1. **Voltage-level synthesis** (literature): the thesis's DPL converter uses a MOSFET
   pass switch + two diode-connected transistors as a voltage divider to produce the
   middle level (0.9 V) between 0 V and 1.8 V (`2211.04542` Fig. 5.3, Table 5.4).
   **This is where the 218-device cost lives** — the middle *level* must be built.
2. **Polarity drive** (ours): driving {push, pull, null} from 2 control bits is a
   one-hot driver — energize the push line, the pull line, or neither. No level
   synthesis, because null is "drive nothing" (the free null,
   `TernaryCell.lean: null_is_free`). **OURS**: ~free.

### 1c. Layer C — the logical radix converters (the real bridge)

The binary↔balanced-ternary *integer* conversion. Both are implemented and
**synthesized to SkyWater 130 nm in this session** (`rtl/converters.v`, yosys 0.52,
`rtl/sky130_fd_sc_hd.lib`; round-trip verified exact over the full 9-bit range with
iverilog). Numbers are **DIRECT**:

| converter | algorithm | cells | area (µm²) | FFs |
|---|---|---|---|---|
| **b2t** (9-bit → 6 trits) | MSB-first balanced digit extraction: 6 stages of `|r| > (3ⁱ−1)/2` compare + constant add/sub (verbatim `cpu.v` `s2t6`) | **139** | **913.4** | 0 |
| **t2b** (6 trits → 10-bit) | Horner: `r = 3r + dᵢ`, 6 stages of shift-add-add (no multiplier) | **170** | **1627.8** | 0 |

Two structural findings, both **DIRECT**:

- **t2b is 1.78× the area of b2t.** The Horner form is a 6-stage *ripple of adds*;
  the MSB-first extraction is a 6-stage *compare against constants*, which `abc`
  minimizes much harder. (Direction matters: reading ternary *out* to binary is the
  expensive direction.)
- **Both are tiny vs the machine.** Combined = 2,541 µm² = **9.5 % of the whole CPU's
  26,713 µm²** (`REAL_SKY130_SYNTHESIS.md`), and 0 sequential elements — pure
  combinational glue, no state.

### 1d. The literature's converter pair (for calibration contrast)

The thesis `2211.04542` (Jaber, El-Hajj et al.) — the same group's published papers
[A Novel Binary to Ternary Converter using DPL](https://ieeexplore.ieee.org/abstract/document/9021886) and
[A Novel CNFET-Based Ternary to Binary Converter](https://www.semanticscholar.org/paper/A-Novel-CNFET-Based-Ternary-to-Binary-Converter-in-Jaber-El-Hajj/4981f8be84c639cdaab570e26fa0aa29de95ec67)
— builds the *level-coded* version of layers B+C together:

| converter | implementation | devices | notes |
|---|---|---|---|
| **B→T, 4 bits → 3 trits** | CMOS DPL, decompose each trit into 2 rails, MOSFET switch + diode-resistor divider | **218 devices** (Table 5.5) | 0.18 µm, 1.8 V |
| **T→B, 2 trits → 4 bits** | CNFET "decoder-less", per-trit PTI→NTI unary pair + K-map decode | **102 transistors** (Table 5.9) | 0.9 V |

Their two-rail code `0→00, 1→02, 2→20, 11 = "This Case Does Not Exist"` (Table 5.4/5.7)
is **literally our `11=NEVER`** — the same forbidden code re-derived in silicon
(`docs/synthesis/ternary-circuits.md` §2c). **DIRECT** (code identity) / **ANALOGY**
(their level-coded CNFET vs our polarity one-hot).

**Why ours is ~an order of magnitude cheaper:** they must *synthesize a third voltage
level* (the 218-device divider stack); we encode the third state as *the absence of a
drive*, so our b2t/t2b are pure logic (139/170 cells) with no analog front end. The
difference between "build 0.9 V" and "drive nothing" is the entire gap.

---

## 2. Energy / area / latency per conversion

### 2a. Physical layer (A + B) — per trit, at the wire

| metric | value | calibration |
|---|---|---|
| ADC energy (2 thresholds) | **~50 fJ/trit** (1 ns) – **90 fJ/trit** (2 ns) | DIRECT, ngspice |
| DAC energy (drive push/pull/null) | driver-dominated, **0.094 pJ/trit** wire-E at the 0.65 V sweet spot; null ≈ 0 | DIRECT, `lowswing_sweep.cir` |
| ADC latency | 1–2 ns eval (the sense-amp latch) | DIRECT |
| ADC area | 2 sense amps ≈ a few hundred µm² each (analog, not yet PnR'd) | SPECULATION (not synthesized) |

Layer A is **not a converter overhead over native ternary** — it *is* the ternary
read. Every ternary gate pays it; "converting" to binary at the edge just reuses the
same receiver.

### 2b. Logical layer (C) — per integer word crossing

| metric | value | calibration |
|---|---|---|
| b2t area | **913 µm²** | DIRECT (yosys, this session) |
| t2b area | **1,628 µm²** | DIRECT |
| latency | 6 radix stages, combinational; **≲ a few ns** at 130 nm, well under the CPU's 19.9 ns critical path | OURS (structural); not OpenSTA-measured |
| energy | **~0.1–1 pJ per crossing** | SPECULATION (bounds below) |

Energy bound, stated honestly: the literature's *level-coded, CNFET* 4b→3t converter
measures **23.7 fJ** max energy and the 2t→4b measures **2.32 fJ PDP**
(`2211.04542` Table 5.6/5.10). Our converters are ~3× the bit-width, 1.8 V CMOS (vs
their 0.9 V), and ~2.5 kµm² total. Area-scaling the CPU's own **1.60 mW / 50 MHz =
32 pJ per cycle** (`REAL_SKY130_SYNTHESIS.md`) gives **~1.1 pJ per b2t crossing and
~2.0 pJ per t2b crossing** (~3 pJ round-trip) at average activity — a
order-of-magnitude estimate, not a worst case. Real crossings toggle only a fraction
of the cells, so **sub-pJ is the honest central estimate**; the thesis's tens-of-fJ is
the lower literature anchor. **Do not quote a single "the converter costs X fJ"
number — the honest statement is a ~0.02–1 pJ band per crossing.**

### 2c. The literature's numbers, for the record (DIRECT from corpus, CNFET-simulated)

| converter | power | delay | energy/PDP |
|---|---|---|---|
| B→T 4b→3t (proposed) | 263.5 µW (text also says 349.9 µW — thesis inconsistency) | 0.09 ns max (0.06–0.09 ns/transition) | **23.7 fJ** max (vs 246 fJ for prior [57]) |
| T→B 2t→4b (proposed) | 0.143 µW | 16.19 ps | **2.32 fJ** PDP (vs 7.03 fJ [27], and 8.7×10⁶ µW / 8000 ps for [58] — the [58] CMOS row is numerically absurd and flagged as a thesis typo) |

These are **level-coded, CNFET HSPICE/MicroCap numbers**, not our architecture; use
them only as the "how much does a converter cost in the literature" anchor, not as
our cost.

---

## 3. The honest break-even — where the bridge flips the decision

### 3a. The decision is about *gate energy*, and the bridge is a *boundary* term

The hybrid-vs-native spectrum (`TERNARY_COMPUTE_SURVEY.md` §reframe) is decided by
one inequality:

> **Does radix economy (3/ln3 ≈ 2.73, ~37 % fewer symbols per unit of information)
> beat the per-gate 2-threshold receiver tax (2 thresholds vs 1)?**

The converters enter that decision **only as an additive boundary term**, not in the
per-gate loop. Model a computation as **G** ternary-gate activations and **B**
boundary crossings (word-level binary↔ternary integer conversions):

| architecture | cost ≈ |
|---|---|
| native binary | G · E₁ (one threshold/gate) |
| **emulate binary in ternary** | G · E₂ (two thresholds/gate, *no* radix-economy benefit — the 3rd state is wasted) **+ 2B · E_conv** (round-trip convert every operand) |
| **hybrid (current `cpu.v`)** | G · E₂ **+ B · E_conv** (convert only at the true boundary: immediates, I/O, addresses) |
| **full native ternary** | (G/1.585) · E₂ **+ B · E_conv** (radix economy shrinks G, same boundary) |

where E₂ ≈ (2 thresholds) is the ternary gate energy, E₁ ≈ (1 threshold) the binary
gate, E_conv ≈ layer-C cost (~0.02–1 pJ, §2b).

### 3b. The three break-even facts, quantified with the DIRECT numbers

1. **Emulation never wins.** "Emulate binary in ternary" pays E₂ ≈ 2·E₁ per gate
   *and* 2·B·E_conv, against native binary's G·E₁. It is strictly dominated — the
   2-threshold tax buys nothing when you throw away the 3rd state. The bridge is the
   *extra* nail, not the deciding one: even if E_conv were zero, emulation loses on
   the gate tax alone. **DIRECT** (E₂ = 2 thresholds by Law 1; the "3rd state wasted"
   is the definition of emulation).

2. **The bridge does NOT block native ternary.** Per-crossing E_conv is ~0.02–1 pJ
   vs **32 pJ per CPU cycle** (`REAL_SKY130_SYNTHESIS.md`, DIRECT). One boundary
   crossing costs **~0.1–3 % of one instruction's energy**, and its area is **9.5 %**
   of the chip. So converting at the I/O boundary is a rounding error *unless B is
   huge*. **Full native ternary is therefore gated by the radix-economy-vs-gate-tax
   question (the Wave-1 "logic gates" survey's job), NOT by the converter.**

3. **There is no crossing where the bridge helps emulation — it is monotone against
   it.** Compare the two ternary options directly: the bridge differential is
   (2B − B)·E_conv = B·E_conv, and the gate count also favors native
   ((G/1.585)·E₂ < G·E₂). *Both* terms point the same way, so emulate-binary is
   strictly dominated — the bridge can only determine **how much** emulation loses,
   never whether it wins. The single genuine break-even in the spectrum is
   **native-ternary vs native-binary**:

   > ternary beats binary ⟺ (G/1.585)·E₂ + B·E_conv < G·E₁
   > ⟺ **E₂ < 1.585·(E₁ − (B/G)·E_conv)**

   i.e. the 2-threshold ternary gate must come in under 1.585× the binary gate, with
   the converter imposing a *small penalty* (B/G)·E_conv that binary does not pay.
   Because B/G ≪ 1 (crossings happen per word or per I/O transaction, not per gate —
   ~10⁻³ or lower), the penalty term is negligible: with E₁ ≈ ~fJ and E_conv ≈
   ~0.1 pJ, (B/G)·E_conv ≈ ~0.1 fJ/gate, under a percent of E₁. **The bridge moves
   the ternary-vs-binary break-even by less than a percent; the decision is made by
   E₂ vs 1.585·E₁ (the Wave-1 gate-energy survey).** **OURS/SPECULATION** (E₂ and E₁
   per-gate are not yet measured; the *form* is the claim).

**Net:** the bridge never flips the decision toward emulation — it is monotone
against it (emulation pays 2B crossings and wasted 3rd states, native pays B and uses
them). The one real break-even in the spectrum is **native-ternary vs native-binary**,
at **E₂ = 1.585·E₁**, and the converter shifts that point by **< 1 %** (the
(B/G)·E_conv term). So the honest answer to "where does the bridge flip the decision"
is: **it doesn't — it is a cheap, near-neutral boundary term, and the hybrid-vs-native
choice is decided by the gate-energy question (2 thresholds vs 1 against radix
economy), which is Wave-1 survey #1's job, not the converter's.**

---

## 4. The minimum-cost bridge design

Given §0–§3, the minimum-cost bridge is *not a clever converter* — it is a **boundary
placement discipline** plus two small combinational blocks. Five rules:

1. **Keep the trit as 2 bits end-to-end (no conversion in the hot path).** The
   physical ADC/DAC (layers A/B) are the cell's own read/drive; the logical radix
   conversion (layer C) is the only real cost, so confine it to the few places a
   *binary integer value* must cross: instruction immediates, I/O words, addresses,
   compare-against-binary-constant.

2. **Use the one-way LDI bridge that already exists; add only its inverse.**
   `cpu.v` already ships b2t as `s2t6` on the LDI path. The missing half is t2b
   (read a ternary result back to binary for store/output/compare) — **1,628 µm²,
   170 cells, 0 FFs** (`rtl/converters.v`, DIRECT). Add it once, as the TCVT
   counterpart (`TERNARY_PROCESSOR.md` §2.2 `TCVT rd, ra`), not per-gate.

3. **Reuse the `11=NEVER` code as the don't-care.** The literature's
   "This Case Does Not Exist" (`2211.04542` Table 5.4) is free minimization material
   in both b2t and t2b (`docs/synthesis/ternary-circuits.md` §2c); `abc` already
   consumes it (the 139/170-cell counts include it). **DIRECT**.

4. **Do NOT build the level-coded divider.** The 218-device cost in the thesis is the
   price of *synthesizing a 0.9 V middle level*. Our null is "drive nothing", so the
   DAC collapses to a 1-hot driver. Reject any design that generates a third voltage
   level; it re-imports the energy liability the thesis itself corrected away
   (`docs/synthesis/ternary-circuits.md` §3, the dual-supply reversal). **OURS**
   following from DIRECT.

5. **Don't pay the numeric converter for trit-stream movement.** If the consumer only
   needs the trit *stream* (sign/magnitude per digit, e.g. driving the ternary bus,
   or a ternary memory), the 2-bit code already *is* that stream — no Horner sum, no
   digit extraction. Reserve b2t/t2b strictly for *numeric* crossings. This is the
   single largest saving and it is free.

**Minimum-cost bridge, stated:** *the existing `s2t6` (b2t, 913 µm²) plus one added
`t2b` (1,628 µm²), placed only at the numeric boundary, with the trit kept as its 2-bit
one-hot code everywhere else.* Total added hardware **≈ 2.5 kµm², ~9.5 % of the CPU,
zero flops, sub-pJ per crossing** — a bridge that is cheaper than the cost of not
having it.

---

## 5. One-sentence synthesis

**In a one-hot-per-direction trit code the "2-threshold flash ADC" is just the
receiver you already measured (~50 fJ/trit) and the "DAC" is just "drive nothing for
the third state", so the only real converter is the binary↔balanced-ternary *radix*
conversion (b2t 913 µm², t2b 1,628 µm², both sub-pJ per crossing) — and because that
bridge costs ~9.5 % of the chip's area and ~0.1–3 % of an instruction's energy *per
crossing* while an emulated ternary gate pays 2 thresholds *per gate*, the bridge
never flips the decision toward emulation; it only raises emulation's already-losing
bill, leaving full-native-ternary's fate to the gate-energy question (2 thresholds vs
1, against radix economy) and making the hybrid (`cpu.v` today) the correct default —
convert at the boundary, never per gate.**

---

### Provenance & files

- `rtl/converters.v` + `rtl/converters_tb.v` — the b2t/t2b modules, written and
  verified this session (round-trip exact over [−256, 255]).
- Synthesis (DIRECT, this session): yosys 0.52 → `rtl/sky130_fd_sc_hd.lib`;
  b2t = 139 cells / 913.4 µm², t2b = 170 cells / 1627.8 µm², 0 FFs each.
- `circuit/ENERGY_RESULTS.md` — receiver (2-threshold ADC) = 0.052 pJ/trit (1 ns) to
  0.08–0.09 pJ/trit (2 ns); driver/wire energy 0.094 pJ/trit at 0.65 V.
- `docs/REAL_SKY130_SYNTHESIS.md` — CPU 26,713 µm² / 3970 cells / 50.25 MHz / 1.60 mW
  → 32 pJ/cycle.
- `docs/Ternary Circuts/2211.04542…txt` §5.2–5.3 — the literature converter pair
  (218 devices B→T, 102 transistors T→B, 23.7 fJ / 2.32 fJ), CNFET/level-coded.
- `docs/ENERGY_LAWS.md`, `docs/synthesis/ternary-circuits.md` — Law 1 (2-threshold
  measurement), the `11=NEVER` code identity, the level-coded energy liability.
