# Audit: are the Lean theorems load-bearing, or do they prove a priced model while we claim the conclusion?

**2026-08-29 — Tau Architecture, the cross-verification audit of the *proof method* itself.**
This is the `TEST_METHODS.md` method #5 ("cross-verification audit") applied to the Lean
ledger. It asks, for every load-bearing theorem: (1) what the formal statement actually is,
(2) what the docs claim it proves, (3) whether the gap is sound or an unproved leap. It does
**not** re-prove anything and invents no numbers; it reads the `.lean` sources against the
docs that cite them.

**Build state verified:** `proofs/lean-src/hexagon/Hexagon/` contains **zero** `sorry`, `admit`,
or `axiom` as *terms* (a grep matches only the header comments that say "zero `sorry`"). So the
theorems are all genuinely checked — the question below is never "is the proof broken," it is
"does the proof prove what the docs say it proves."

**Calibration legend** (house standard): **DIRECT** = measured/proved/textbook identity;
**ANALOGY** = structural resemblance, not identity; **OURS** = our design claim, follows from
DIRECT but not independently established; **SPECULATION** = untested.

---

## 0. The blunt verdict, first

**The proofs are load-bearing as *mathematics* and not load-bearing as *conclusions*.** Every
theorem in the ledger is true, and `lake build` is green. The problem is precisely the failure
mode `TEST_METHODS.md` names for the method — *"a theorem can be true math over a priced model
while the model itself is the thing in question"* — and it is happening in exactly the two places
the brief flagged:

1. **`ThresholdLowerBound.lean` proves monotonicity of a hand-picked cost function `(b−1)/ln b`
   that *prices* a flash/thermometer decoder (ordered levels + uniform threshold cost).** The
   informal conclusion "ternary compute cannot beat binary per bit" is **not** the theorem; it is
   two unproved premises (energy ∝ threshold count; resolution = b−1 ordered thresholds) wearing a
   proof's clothes. The specific 1.26× *number* survives (it is `2/log₂3 = 2·ln2/ln3`, the
   "`3 ≠ 2^k` waste"), but that identity is **not what the file proves** and the file's *mechanism*
   (b−1 flash thresholds) is the wrong one — it overcounts every b ≥ 4.
2. **`RadixMin.lean` / `RadixEconomy.lean` prove a *density* fact** (`b/ln b` minimized at e, 3 is
   the densest of {2,3,4}). The informal conclusion "ternary wins transport" is a **measured** fact
   about the wire (0.081 pJ/bit), *not* a consequence of the theorem, and "3 wins *because* nearest
   e" conflates that density fact with the free-null circuit fact. e is not a machine integer and
   nothing in the file is about joules.

Two further findings the brief asked about:

3. **`Gauge.lean` / `ChiSquareGauge.lean` / `Haar.lean` are a *separate axis* from the energy
   argument.** They prove real algebraic/statistical facts (Eisenstein-norm Z₆ isotropy; the δ-fold
   is count→prob gauge-invariant while χ² scales). **Neither has any premise or conclusion about
   energy, voltage, the receiver, or the threshold tax.** Law 1 ("receiver is gauge-agnostic")
   *borrows* `ChiSquareGauge.lean` as "the same structure" — that is an **ANALOGY** (two different
   "gauges" over two different objects), and it is never labelled as such.
4. **"Proved in Lean" is being used to launder a *measured heuristic* into a *law* in at least one
   place (Law 1), and to launder a *priced model* into a *law* in the verdict table.** Law 1 is a
   measured heuristic (13%→61%→67% receiver share), not a theorem; its only Lean touchpoint is an
   analogy to a different gauge. The verdict's "thresholds" row lists `ThresholdLowerBound.lean` as
   "PROVED" while the *energy* sentence it carries is not proved.

Net: **the theorems are sound and correctly scoped inside their own files; the claims that cite
them are the over-claimed part.** The fix is a re-stated theorem (`⌈log₂b⌉/log₂b`) plus a
relabelling pass, not a re-proof pass. Details below.

---

## 1. The theorem-vs-claim gap table (the core deliverable)

For each load-bearing theorem: **formal statement → claimed conclusion → gap (sound / leap).**

| # | file | what it ACTUALLY proves (formal) | what we CLAIM it proves | gap |
|---|---|---|---|---|
| TLB | `ThresholdLowerBound.lean` | `b ↦ (b−1)/ln b` has positive derivative and is strictly increasing on `(1,∞)`; hence over `b ≥ 2` the minimum is `b=2`, and `2/ln3 > 1/ln2` (ratio `2·ln2/ln3 ≈ 1.26`). | "ternary compute cannot beat binary per bit" — the "2-threshold tax" (header L16–17); verdict "thresholds" row lists it as PROVED. | **LEAP.** The calculus is airtight but the *function* prices two unproved premises: (P1) b states = b ordered levels on one wire, decoded by a flash/thermometer with b−1 thresholds; (P2) uniform per-threshold cost. Polar sign×magnitude is not ordered levels, and its sign-vs-ground/diode read is not a uniform comparator. `(b−1)` is the flash count, not the minimal `⌈log₂b⌉`; it overcounts every b ≥ 4 (b=4: 3 vs 2). The coincidence b−1 = ⌈log₂b⌉ at b=2,3 is what saves the *specific* 1.26× but not the *general* claim. |
| RM | `RadixMin.lean` | derivative of `b/ln b` is `(ln b − 1)/(ln b)²`; `e ≤ b/ln b` for all `b>1` (so e is the global min *value*); `e < 3/ln3`. | "3 wins because nearest e" (Law 3). Header also *claims* "decreasing on (1,e), increasing on (e,∞)" is proved. | **LEAP as energy, SOUND as density.** It proves a digit-count/density fact, not joules. e is not a machine integer; the *integer-minimizer* claim ("3 is best of ALL integers") needs monotonicity on (e,∞), which the header asserts but the body does **not** prove (body proves the value-min and e<3/ln3 only). The b=2 vs 3 vs 4 comparisons that the transport claim actually uses *are* proved in `RadixEconomy.lean`, so the specific claim is fine; the generalization is a hair over-claimed. |
| RE | `RadixEconomy.lean` | `3/ln3 < 2/ln2`; `4/ln4 = 2/ln2`; `1 < ln3/ln2` (trit > 1 bit). | "ternary is the most efficient integer radix" / transport density win. | **SOUND** for the formal statements. The *energy* reading ("ternary wins transport") is NOT here — the transport win is measured on the wire, and its energy cause is the free null (a balanced return-to-zero circuit fact), not nearest-e. |
| G | `Gauge.lean` | `N(u)=1` for the six units; `N(x·u)=N(x)`, `N(u·x)=N(x)` (Z₆ isotropy of the Eisenstein norm); `N = det` of the regular rep (area scalar); units = ω⁰…ω⁵. | "gauge change = cheap 60° rotation"; cited as the "gauge as area scalar" layer. | **SOUND** for the hex-lattice geometry. **Does NOT bear on energy.** Any doc that reads this as supporting Law 1 / the receiver is making an unlabelled analogy. |
| CSG | `ChiSquareGauge.lean` | `δ = O/E − 1` is invariant under `(O,E)↦(c·O,c·E)`; χ² `(O−E)²/E` scales by c (not invariant); `surprise = δ²·E`. | "store δ, not r" (register/statistics design). **Also** borrowed by Law 1 as "the same structure" (δ gauge-invariant, χ² not). | **SOUND for the statistics layer** (count→prob gauge). **LEAP to energy:** Law 1's "gauge" (voltage swing) ≠ this "gauge" (count rescale). The theorem says nothing about the receiver. |
| H | `Haar.lean` | counting measure is invariant under the Z₆ unit action; normalized counting measure on units is a probability measure. | "isotropy at the measure level." | **SOUND**, same axis as Gauge.lean — algebraic, not energetic. |
| TC | `TernaryCell.lean` | one-hot encoding; `energy t ≤ 1` where `energy = # energized wires`; null free; uniform avg 2/3 vs binary avg 1; `encode` never produces (true,true). | "the ternary cell saves 1/3 of energy" / "null is free." | **LEAP when read as joules.** "energy" is *defined* as "number of energized wires" (a combinatorial count), NOT physical energy. The measured cell (`EnergyModel.lean` real numbers) actually *lost* (5.36 pJ/push vs 0.75 pJ/bit). The 2/3 is a wire-count fact; calling it an energy saving is model-dependent. |
| VE | `ValuationEnergy.lean` | energy (wire-count) is modular (`energy(min)+energy(max)=energy(t)+energy(u)`); min+max=sum on trit values; energy monotone **w.r.t. a cost order the file itself defines** (`trit_cost_le`). | "energy is a lattice valuation; the tadd1 identity." | **SOUND, and honestly self-correcting** (records that the *balanced*-order monotonicity is FALSE and proves only the cost-order version). The caveat: "energy" is still wire-count, and `trit_cost_le` is *defined* into existence — a modelling choice, not a discovered fact. |
| ZE | `ZipfEnergy.lean` | expected wire-energy = `1 − P(null)`; `p₀ > 1/3 ⟹ E < 2/3`; concrete `p₀=1/2 ⟹ E=1/2`. | "null-heavy data ⇒ saving > 1/3." | **SOUND as conditional algebra; the premise is unmeasured.** "Null dominates in real data (Zipf)" is a SPECULATION workload assumption; `meta_assumptions.md` A3 flags it. The theorem proves *IF p₀ > 1/3 THEN*, nothing about whether real data is. |
| EM | `EnergyModel.lean` | `E_cap ≤ E_transfer`; naive cell dissipates `> E_cap`; break-even `p₀ > 1 − Eb/Et`; with the measured `Et=5.361, Eb=1.19` ⇒ needs `p₀ > 77.8%`. | "why we must lower Et." | **SOUND and exemplary** — it *states* its inputs as measured numbers and reaches the honest "no realistic workload is that null-heavy" conclusion. The inputs are later revised, but the file's structure is the model the others should copy. |
| EV | `EnergyVerdict.lean` | `2·trit_uniform(1.2, 0.05) < 3·binary_bit(0.748)` — i.e. 2 trits (uniform, measured numbers) cost less than 3 bits. | "ternary wins uniformly on energy." | **LEAP.** The arithmetic is true, but the premises encode the hidden assumptions: `binary_bit = 0.748` is the **±1 V bipolar** baseline (`meta_assumptions.md` A2), and `null=0.05` is a specific receiver. Against single-ended 0–1 V binary the win shrinks to ~2–4× or a loss. This is the cleanest case of "proved over a priced model" — the theorem is load-bearing arithmetic whose *premises* are the thing in question. |
| PG/CrtH/PE/TP | `PolarGate.lean`, `CrtHex.lean`, `PolarEncoding.lean`, `TritPacking.lean` | F₃ gate identities; Z₆ ≅ Z₂×Z₃; trit↔2-bit injective-not-surjective (11=NEVER); 3ⁿ ≤ 2²ⁿ, 2ⁿ<3ⁿ. | "polar gate semantics / encoding / packing." | **SOUND.** Pure finite combinatorics; correctly scoped to encoding/semantics, not energy. No leap found. |

---

## 2. The five specific checks

### 2.1 `ThresholdLowerBound.lean` — do we overclaim "ternary can't win compute"?

**Yes, and it is the single worst over-claim in the ledger.** The formal statement is a
monotonicity theorem about a *chosen* function `(b−1)/ln b`. "Ternary can't win compute" requires
three things the theorem does not contain: (i) energy is proportional to threshold count; (ii) each
threshold costs uniformly (a flash/thermometer decoder on one wire); (iii) a 3-way read *must*
decompose into b−1 binary thresholds (no native single-measurement device). All three are the
"priced model" — the header even says so ("on a substrate where each threshold costs uniformly"),
but the *verdict* drops that hedge and lists the row as PROVED.

The honest content is narrower and, per `meta_math.md` §2, is actually a **coding-efficiency**
statement: `⌈log₂3⌉ = 2` decisions for `log₂3` bits ⇒ `2/log₂3 = 2·ln2/ln3 ≈ 1.262` per bit,
*representation-independent*. That is the true, robust fact — and it is **not** what the file
proves. The file proves the flash-decoder `(b−1)` version, which happens to equal `⌈log₂b⌉` only
at b=2 and b=3 (the only comparison used), and which is wrong as a general lower bound (b=4:
b−1=3 vs ⌈log₂4⌉=2).

**Verdict: calculus SOUND; "ternary can't win compute" OVERCLAIMED (the mechanism is wrong, the
conclusion survives only by the b=2,3 coincidence, and the representation-independence is argued
in a doc, not proved).** Needs the re-stated theorem T-new-1 (§4).

### 2.2 `RadixMin.lean` — do we overclaim "ternary wins transport"?

**Yes, by category error, though the direction of the error is subtler.** The theorem proves
`b/ln b` is minimized (in *value*) at e and that 3 beats 2 and ties nothing (4=2). It is a
*digit-count / representation-density* fact — how many digits×states it takes to write a number.
It says **nothing** about energy, and e is not a machine integer (so "nearest e" is a heuristic
pointer, not a proof that 3 is the minimizing integer over *all* b; the monotonicity-on-(e,∞)
half that would make it airtight is claimed in the header but absent from the body).

The actual transport win (0.081 pJ/bit) is **measured**, and its energy cause is the **free null**
— a property of balanced return-to-zero coding that holds for *any* odd radix (PWM-5 has a null
too and ties PAM-4). Law 3's "two independent reasons point at 3" bundles the density fact with the
free-null circuit fact and calls it one "win"; `meta_assumptions.md` §7.2/A14 already names this as
the conflation. **The density win (nearest e) and the energy win (free null) are two different wins
sharing the digit 3.**

**Verdict: SOUND as density; OVERCLAIMED as "ternary wins transport (energy)."** Re-word the claim,
don't re-prove the theorem.

### 2.3 `Gauge.lean` / `ChiSquareGauge.lean` — do they bear on the energy argument?

**No. They are a separate axis.** `Gauge.lean`/`Haar.lean` live in the *hex-lattice algebra* (Z₆
isotropy of the Eisenstein norm and the counting measure). `ChiSquareGauge.lean` lives in the
*statistics* layer (the count→prob renormalization of the χ² register). The energy argument (Law 1,
the threshold tax) lives in the *circuit/physics* layer (receiver energy vs voltage swing). The
three layers share the word "gauge" and nothing else: the algebraic gauge is a rotation by a unit,
the statistical gauge is a common rescale, the energy gauge is a voltage-swing change. No theorem
crosses the boundary.

The only "bearing" is the **analogy** in `ENERGY_LAWS.md` L26 ("the same structure as
`ChiSquareGauge.lean` (δ gauge-invariant, χ² not)"). That is a legitimate *structural* parallel —
"the invariant part survives the gauge change" — but it is an ANALOGY and must be labelled one. As
written, the calibration line says "DIRECT (measured three times)" (true of the measurement) and
leaves the ChiSquareGauge link uncalibrated, which reads as if Lean proved Law 1.

**Verdict: the gauge theorems are sound and correctly scoped; they are NOT load-bearing for the
energy argument, and every place that implies they are needs an ANALOGY label.**

### 2.4 Is "proved in Lean" laundering a priced model into a "law"? (Law 1 "receiver is gauge-agnostic")

**Yes, in two distinguishable ways, and Law 1 is the test case the brief names.**

- **Law 1 is a measured heuristic, not a theorem.** No `.lean` file states or proves anything about
  the receiver. The 13%→61%→67% numbers are *measured* (DIRECT as measurement), but the conclusion
  "the ultimate energy floor is the cost of extracting information" smuggles in "the receiver cannot
  be shrunk" — which the same corpus contradicts (0.052 pJ @1 ns vs 0.087 pJ @2 ns eval;
  `receiver_cheap.md` is the open lever). `meta_assumptions.md` A13/§7.4: it is gauge-agnostic in V,
  **not** an absolute floor. The measurement is DIRECT; the "law" generalization is OURS.
- **The laundering step is the `ChiSquareGauge.lean` reference.** Citing a *proved* theorem about a
  *different* gauge next to a *measured* heuristic about voltage makes the heuristic look proved.
  This is the exact "priced model in a proof's clothes" pattern, applied to a heuristic rather than
  a model.

The same laundering happens to a *model* in the verdict table: the "thresholds" direction is listed
as PROVED via `ThresholdLowerBound.lean`, when only the calculus is proved and the energy mapping is
an analogy. Law 2 (diagonal cheap, I²R) is DIRECT-by-measurement with **no** Lean backing and is
honest about it; Law 3's "nearest e" half has Lean backing but is a density fact, while its "free
null" half is measured. **None of the three "laws" is a Lean theorem.** Two of the three are
measured heuristics; the third is a measured heuristic + a density theorem.

**Verdict: yes — "proved in Lean" is used to launder both a measured heuristic (Law 1) and a priced
model (the threshold tax) into law-like statements.** The remedy is relabelling, not re-proving:
Law 1 is DIRECT(measured)+OURS(generalization)+ANALOGY(ChiSquareGauge); the verdict's thresholds row
is DIRECT(calculus)+ANALOGY(energy∝thresholds).

### 2.5 The proof-to-claim map — which "DIRECT" calibrations are "proved theorem" vs "true-but-model-dependent"?

Three buckets, not two. "DIRECT" in `INDEX.md`/`ENERGY_LAWS.md` covers **four** different kinds of
strength, and the docs mostly don't say which.

**Bucket A — proved theorem, no model dependency (pure finite math / calculus).** These are safe to
call DIRECT and PROVED, full stop: T0–T5, T2a/T2b, T3a/T3b, T4, T5 (`EuclideanDomain`), G1, R1, R2,
B1 (bijection), C1, FR1, A1 (Haar), B4 (Signature), `CrtHex`, `OffsetGrid`, `HexDisk`,
`HexIsotropy`, `Pod`, `PolarGate`, `PolarEncoding`, `OmegaEmbedding`, `Conventions`, `Rotation`,
`SevenHex`, `GraphDistance`, `ConventionBridge`, `FractalRam`, `Residual`, `Registers`. The formal
statements are about well-defined math objects (rings, norms, finsets, finite groups) with no
physical premise. The *informal glosses* ("gauge change = cheap multiplication") are fair, as long
as they aren't pushed into energy.

**Bucket B — proved theorem, but the physical reading is model-dependent (the "priced model" class).**
This is where the audit lives:

| theorem | proved (DIRECT) | the model it prices | the reading that is NOT proved |
|---|---|---|---|
| `ThresholdLowerBound` | monotonicity of `(b−1)/ln b` | ordered levels + uniform threshold cost (flash) | "ternary can't win compute" |
| `TernaryCell` | wire-count ≤1, null free, avg 2/3 | "energy = # energized wires" | "ternary saves 1/3 *energy*" |
| `ValuationEnergy` | modularity of wire-count energy | "energy" = wire-count; `trit_cost_le` defined | "the tadd1 energy identity" |
| `ZipfEnergy` | `E = 1 − p₀`; `p₀>1/3 ⇒ E<2/3` | `p₀` distribution is real-data Zipf | "real saving > 1/3" |
| `EnergyModel` | break-even iff `p₀ > 1−Eb/Et` | Et=5.361, Eb=1.19 measured inputs | (none — file states inputs honestly) |
| `EnergyVerdict` | `2 trits < 3 bits` for given inputs | 0.748 pJ/bit = ±1 V bipolar binary | "ternary wins uniformly" |
| `RadixEconomy`/`RadixMin` | 3 densest of {2,3,4}; min at e | density = energy | "ternary wins transport (energy)" |
| `ChiSquareGauge` | δ gauge-invariant, χ² scales | count→prob gauge = voltage gauge | "receiver is gauge-agnostic" |

Every row's *left* column is genuinely proved and safe to cite. Every row's *right* column is what
the docs actually say and is an unproved leap of exactly the kind `TEST_METHODS.md` warns about.

**Bucket C — not proved at all, but presented near "proved".**

- **T6 (hex packing density / Thue optimality):** `Packing.lean` is PARTIAL — the τ identity is
  proved, the geometric derivation + Thue optimality are *cited, not proved*. `INDEX.md` is honest
  about this. No over-claim found.
- **Law 1 / Law 2 / Law 3 as laws:** measured heuristics (L1, L2) and a density theorem + measured
  null (L3). No Lean "law" exists.
- **T-new-1 (`⌈log₂b⌉/log₂b`):** stated in `meta_math.md` §6, **not** in the ledger. This is the one
  theorem worth adding (§4).
- **"Hex replaces the u32 XOR kernel":** SPECULATION, correctly blocked in `INDEX.md`.

---

## 3. Which conclusions survive vs collapse (post-audit)

**Survive as stated (sound):**

- All of Bucket A (the pure-math layer: rings, norms, units, bijections, encodings, gate semantics).
- Radix *density*: `3/ln3 < 2/ln2`, `b/ln b` min at e, ternary per-wire/per-symbol density. (DIRECT.)
- The conditional algebra: `ZipfEnergy`'s `E = 1−p₀`, `EnergyModel`'s break-even, `ChiSquareGauge`'s
  δ-invariance. Each is correct *as a conditional*.

**Collapse / need re-wording (over-claimed):**

- "Ternary can't win compute" (from `ThresholdLowerBound`) → "binary minimizes *ordered, uniform-cost
  flash thresholds* per bit; the robust fact is the representation-independent `2/log₂3 ≈ 1.262`."
- "Ternary wins transport because nearest e" (Law 3) → "ternary wins *density* because nearest e, and
  wins *wire energy* because of the free null of balanced return-to-zero — two wins sharing a digit."
- "Receiver is gauge-agnostic = the energy floor" (Law 1) → "receiver is *measured* gauge-agnostic in
  V (13%→61%→67%); its *generality* and *irreducibility* are OURS, not proved."
- "Ternary wins uniformly on energy" (`EnergyVerdict`) → "2 trits < 3 bits *given* a ±1 V bipolar
  binary baseline; against single-ended binary it is ~2–4× or a loss."
- The verdict's "four independent directions" → **two independent directions** (fabrication,
  circuit) **plus two facets of one coding fact** (thresholds and Landauer both reduce to
  `2/log₂3 = 2·ln2/ln3`, the `3 ≠ 2^k` waste). Of those four, only ONE has a Lean theorem, and it is
  the priced flash-decoder model; the Landauer direction has no Lean at all (it's an arithmetic
  identity in `device_physics.md` §5).

---

## 4. Re-stated theorems needed (the concrete fixes)

1. **T-new-1 (replaces `ThresholdLowerBound` as the load-bearing statement).** For integer `b ≥ 2`,
   the minimal binary-decision cost per bit is `g(b) = ⌈log₂b⌉ / log₂b`, with `g(b) ≥ 1`, equality
   iff `b` is a power of 2, and `g(3) = 2·ln2/ln3 ≈ 1.262`. This is representation-independent
   (ordered levels *and* sign+magnitude both need `⌈log₂b⌉` yes/no answers), so it cannot be escaped
   by re-encoding, and it fixes the b≥4 overcount. It *subsumes* `ThresholdLowerBound.lean` at the
   only point that file is used (b=2 vs 3). Calibration: DIRECT (provable; the hard part is only
   formalizing `⌈·⌉`/`log₂`). **This is the single Lean follow-up worth doing** — until it is in the
   ledger, the honest cost function is unproved and `ThresholdLowerBound`'s `b−1` premise stays
   uncorrected.
2. **T-new-2 (the escape condition, reframes the impossibility as a device question).** Ternary
   beats binary per bit on the measurement axis iff a *single native 3-way discrimination* costs less
   than `2/log₂3` times one binary discrimination. Makes explicit what `ThresholdLowerBound` buries
   in P4, and turns the verdict into a go/no-go device question. Calibration: OURS (the inequality is
   DIRECT; "this is *the* criterion" is our reframe).
3. **Re-label, don't re-prove:** Law 1 → DIRECT(measured) + OURS(generalization) +
   ANALOGY(ChiSquareGauge). Verdict thresholds row → DIRECT(calculus) + ANALOGY(energy∝thresholds).
   Law 3 → split "nearest e (density, DIRECT)" from "free null (circuit, DIRECT)" and stop bundling.
4. **Optional:** prove `b/ln b` is increasing on `(e,∞)` (the header of `RadixMin.lean` claims it;
   the body doesn't). Needed only to close "3 is the minimizer over *all* integers," not for the
   transport claim.

---

## 5. Calibration summary (the DIRECT/ANALOGY/OURS/SPECULATION re-map)

| claim | current | corrected |
|---|---|---|
| `b/ln b` min at e; 3 densest of {2,3,4} | DIRECT | **DIRECT** (proved; density only) |
| `(b−1)/ln b` monotone, min at b=2 | DIRECT | **DIRECT as calculus** |
| "ternary can't win compute" (from that) | PROVED/DIRECT (verdict) | **ANALOGY→OURS** (energy∝uniform thresholds is the unpriced leap) |
| `(b−1)` = true lower bound ∀b | (implied) | **WRONG for b≥4** — honest bound is `⌈log₂b⌉` |
| 1.26× = `2·ln2/ln3` is representation-independent | DIRECT (meta_math) | **DIRECT arithmetic, but unproved in Lean** (needs T-new-1) |
| Law 1 "receiver gauge-agnostic" | DIRECT (measured) | **DIRECT(measured) + OURS(floor/generalization) + ANALOGY(ChiSquareGauge)** |
| Law 3 "3 wins nearest e ⇒ energy" | DIRECT (proved+measured) | **conflation: density(DIRECT) + free-null(DIRECT) ≠ one axis** |
| "four independent directions" | (verdict) | **OURS/overstated** — two independent + two facets of `3 ≠ 2^k` |
| `TernaryCell` "saves 1/3 energy" | DIRECT | **DIRECT as wire-count; ANALOGY as joules** |
| `EnergyVerdict` "ternary wins uniformly" | DIRECT | **DIRECT arithmetic over a ±1 V-bipolar priced premise** |

---

## TODO / not covered / caveats

- **T-new-1 is stated, not proved.** `⌈log₂b⌉/log₂b` is the honest re-statement of the threshold
  tax and it is not in the ledger. Until it is, `ThresholdLowerBound.lean`'s `(b−1)` premise remains
  the only checked artifact and its overcount-at-b≥4 goes uncorrected. **Highest-value Lean task.**
- **I did not re-run `lake build`.** I verified "zero `sorry`/`admit`/`axiom` as terms" by grep, and
  relied on the ledger's claimed green build (8734 jobs). A clean `lake build` in this checkout is
  the cheap confirmation of that claim; the audit's conclusions don't change if it's green.
- **I did not re-derive the SNR/BER or energy numbers.** Every measured number cited (0.748 pJ/bit
  binary, 0.05 pJ null, 13%→61%→67%, 2.54×, 0.081 pJ/bit) is taken from the corpus, not re-measured.
  If `gate_energy.md`'s 2.54× and `polar_gates.md`'s "native 4.9–14.3× worse" ever conflict, the
  empirical half of the "over-claim" verdict needs a re-check (`meta_math.md` flags this same
  dependency).
- **The audit covers the *energy/compute* load-bearing theorems.** It does not re-audit the pure
  geometry batch (`Pod`, `HexDisk`, `OffsetGrid`, `HexIsotropy`, `WeightHex`) in depth — those are
  Bucket A and I found no model dependency, but they were read for scope, not line-by-line for
  header-vs-body drift the way `RadixMin` was.
- **The one genuinely open scientific question is not a proof gap.** Whether a *direction (diode)
  receiver* or a *multi-threshold device* resolves 3 states in fewer than 2 measurements is an
  *experiment*, not a theorem. The single experiment that could overturn the *application* of
  `ThresholdLowerBound` (not its math) is the diode-only gate fair-fight (`meta_math.md` E-new-1);
  it is unmeasured, and no Lean theorem can settle it.
- **"Proved" statuses in `INDEX.md` are per-file correct** (the theorems are real), but the
  calibration column *should* distinguish "proved theorem" from "proved theorem whose physical
  reading is model-dependent." That distinction is what this audit adds and what `INDEX.md` currently
  collapses into a single DIRECT.
- **Landauer / thermodynamics has no Lean file** and never did; the "thermodynamics direction" of
  the impossibility is an arithmetic identity (`k_B T ln N`) in `device_physics.md` §5, not a theorem
  in the ledger. Anyone citing "the four directions are proved" is citing at most one Lean theorem,
  one arithmetic identity, and two empirical surveys.

---

## Sources (read for this audit)

- `proofs/lean-src/hexagon/Hexagon/{ThresholdLowerBound, RadixMin, RadixEconomy, Gauge,
  ChiSquareGauge, Haar, TernaryCell, ValuationEnergy, ZipfEnergy, EnergyModel, EnergyVerdict,
  PolarGate, CrtHex, PolarEncoding, TritPacking, Registers}.lean`
- `proofs/INDEX.md` — the claim→file→status ledger.
- `docs/TEST_METHODS.md` — the methods ledger (the failure modes this audit tests).
- `docs/ENERGY_LAWS.md` — the three laws and their calibrations.
- `docs/TERNARY_COMPUTE_VERDICT.md`, `docs/TERNARY_GROUND_UP.md`, `docs/TERNARY_COMPUTE_SURVEY.md`.
- `docs/compute/ground_up/{meta_math, meta_assumptions, meta_critique}.md` — the prior meta passes
  this audit consolidates and pins to specific theorems.
