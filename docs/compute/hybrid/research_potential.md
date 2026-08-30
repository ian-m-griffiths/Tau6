# Research Potential — is ternary's compute loss fundamental, or a dearth of research?

**2026-08-30.** The counterfactual: if ternary transistors had received 70 years × trillions of
devices of optimization the way binary has — instead of ~50 tube-era Setuns plus a small
CNTFET/FeFET/memristor literature — would ternary *compute* catch up to binary?

**One-line answer.** The loss splits into two parts of different kind: a **fundamental 1.26×
sensing floor** that no research budget moves (a coding fact, `3 ≠ 2^k`), and a **closable gap
above it** — the measured 1.72×/1.92× (and 3.94× adder-area) device penalty plus the 2-bit/trit
encoding overhead. Research can narrow compute from ~1.5–2.0× toward ~1.26×, **never below**.
The "dearth of research" is real but bounded. And the one place research money would actually pay
is **transport/storage, not compute**, because those axes are not bounded by the read floor.

**Calibration legend** (repo convention, unchanged from the sibling `hybrid/*.md` files):
**DIRECT** = proved in Lean (`lake build` green, zero `sorry`) or measured (ngspice/yosys);
**DERIVED** = arithmetic on DIRECT numbers; **OURS** = design claim following from DIRECT but not
independently established; **SPECULATION** = untested, carries no adjudicatory weight.

---

## 0. The two numbers that bound everything

| quantity | value | what it is | source |
|---|---|---|---|
| **sensing floor** (immovable) | **1.26× = 2·ln2/ln3** per bit | the cost of reading 3 states: `3` values need `⌈log₂3⌉ = 2` decisions, `2` need `1`; a trit is `log₂3 ≈ 1.585` bits, so per-bit sensing is `2/1.585` | `ThresholdLowerBound.lean` `ternary_binary_ratio` (PROVED); `meta_math.md` §2 |
| **measured device penalty** (closable) | **1.72×** mult / **1.92×** FA-energy / **3.94×** adder-area, per bit or per gate | what the current 2-wire-encoded-on-binary-CMOS gates actually cost above the floor | `word_fairfight.txt`; `trelax_measured.md`; `gate_area.md` |

The rest of this file is the argument that the first number is a law and the second is a budget.

---

## 1. The split: fundamental 1.26× vs the closable gap

### (a) FUNDAMENTAL — the 1.26× sensing floor (immovable)

`ThresholdLowerBound.lean` proves `b ↦ (b−1)/ln b` is strictly increasing for `b > 1`, so binary
minimizes threshold-cost-per-bit and ternary is `(2/ln3)/(1/ln2) = 2·ln2/ln3 ≈ 1.26×` worse.
**DIRECT** (Lean, zero `sorry`).

The deeper, cleaner statement is in `meta_math.md` §2: the 1.26× is **representation-independent**.
It is the cost of `3 ≠ 2^k` — a trit carries `log₂3 ≈ 1.585` bits but must occupy `⌈log₂3⌉ = 2`
binary units, wasting the 4th corner (`2 − log₂3 = 0.415` bits/symbol). The same number falls out
of **three independent countings**:

| counting | cost per symbol | bits/symbol | per-bit |
|---|---|---|---|
| ordered thresholds (`b−1` flash) | 2 thresholds | 1.585 | **1.262** |
| binary decisions (`⌈log₂b⌉`) | 2 decisions | 1.585 | **1.262** |
| 2-cell sign+magnitude erasure (`k_B T ln 4`) | `ln 4` | 1.585 | **1.262** |

**DIRECT** (arithmetic identity `2/log₂3 = 2·ln2/ln3 = ln4/log₂3 ÷ ln2`; `meta_math.md` §2).

Why this is *compute*-specific and *immovable*: every ternary gate that consumes a trit must first
**sense** which of 3 states it is. Sensing is a decision, and one binary decision can name at most 2
alternatives, so 3 states cost 2 decisions — every read, forever, regardless of device or encoding.
Re-encoding (sign+magnitude, ordered levels, any 2-of-3 code) relabels the two decisions; it cannot
delete one (`meta_math.md` §4: even the "direction-via-diode" receiver still needed 2 sense amps,
measured 2.54×). The only escape is a *single native 3-way measurement* (`meta_math.md` T-new-2),
and the survey says that route is unwinnable (`_SYNTHESIS.md`; the AAT's one-measurement read costs
≫1.585×, `FINAL_VERDICT.md` correction 5).

### (b) CLOSABLE — the gap above the floor

Everything in the measured loss *above* 1.26× is, in principle, a device-engineering artifact, not
a law. It has two components:

**1. The device penalty — 1.72×/1.92× (and 3.94× adder-area).** The ternary gates are laid on a
*binary* standard-cell library using the 2-wire encoding, so a trit gate is 2 rails × 2 thresholds.
Measured per gate (`gate_area.md`, `trelax_measured.md` §2):

| cell | energy / toggle | transistors | sky130 area |
|---|---|---|---|
| ternary balanced FA `tadd1` | **0.355 fJ** | **192 T** | **146.4 µm²** |
| binary FA `bin_fa` | **0.185 fJ** | **58 T** | **33.8 µm²** |
| **ratio** | **1.92×** | **3.31×** | **4.33×** |

Normalized per bit at the word level (`word_fairfight.txt`/`.md`): the multiplier penalty melts to
**1.72×/bit** (shift-add) / 2.08× (Karatsuba) because the 1.585-bit/trit density partially offsets
the gate cost; the adder stays **3.94×/bit** (the balanced carry entangles the digits and gives
synthesis nothing to collapse). **DIRECT** (all measured, same yosys 0.52 + sky130 flow).

**2. The 2-bit/trit encoding overhead — 26% wire waste.** One trit is 2 binary wires
(`2'b01=+1, 2'b00=0, 2'b10=−1, 2'b11=NEVER`), so `1.585 bits / 2 wires = 0.792 bits/wire` vs
binary's `1.0` — a **1.26× wire penalty**, the same `3 ≠ 2^k` waste viewed as a *representation*
cost (`gate_area.md` §3; `storage.md` §4–5: 12T/trit vs 6T/bit). **DIRECT.**

These two are the "device gap" a ternary-transistor research program would target. The honest
point of §2 is *how much* of them it can actually close.

---

## 2. What ternary-transistor research COULD close — and what it cannot

Three candidate research directions, each with its ceiling stated up front.

**2.1 A native 3-state device that reads at near-1.0× energy.** The hope: a device whose intrinsic
physics gives push/null/pull on one wire (a "free null"), collapsing the 2-rail × 2-threshold
structure so a trit gate costs ~a binary gate. **Ceiling: the 1.26× floor still applies.** A native
device reads 3 states in *one* physical unit, but the read is still **≥ 2 decisions** (3 values,
2 yes/no answers), so per-bit sensing bottoms out at `2/1.585 = 1.26×`, not 1.0×. The only way under
the floor is a *single* native 3-way discrimination costing <1.262× a binary decision
(`meta_math.md` T-new-2) — and the survey found **none**: all 11 papers in
`docs/graphs/ternary-transistors/_SYNTHESIS.md` are negative; every "polar/reconfigurable" degree of
freedom is binary-or-analog; and the closest thing to a native trit (graphene's e/Dirac/hole) has a
null that is a finite-conductance minimum, not a free open state. **DIRECT** (survey) — the native
device is the "0.63× native floor" flattery: `0.63× = 1/log₂3` assumes a ternary toggle costs the
same as a binary one, which the 3-level SNR margin forbids (`FINAL_VERDICT.md` correction 4).

**2.2 A better 2-of-3 encoding.** The hope: don't waste the 4th corner — pack trits into bit-words
(3 trits = 27 states in 5 bits = 1.051×; 5 trits = 243 states in 8 bits = 1.009×) so the wire
overhead amortizes toward `log₂3`. **This is real, and it is the one genuinely open lever** — but
note what it closes and what it does not. It closes the **representation/wire** axis toward the
radix-economy limit (1.585 bits/symbol). It does **not** close the **sensing** axis: reading a
packed trit still takes `⌈log₂3⌉ = 2` decisions, so compute stays at 1.26×. The block-code win lives
on the *transport/storage* side (fewer symbols to move/store), not the *compute* side
(`meta_math.md` §7 TODO notes this exactly). **OURS/DERIVED** (the packing arithmetic is DIRECT; the
"compute stays at 1.26×" is the §1 floor restated).

**2.3 A ternary full adder at <1.26×/bit.** The hope: a native balanced adder that beats binary per
bit. **Unlikely — it hits the floor.** The balanced FA must threshold for both carry directions and
both sum directions (2 rails × 2 thresholds = the 2.00×–4.33× per-gate tax, `gate_area.md` §2), and
even a perfect native version cannot read its 3-valued inputs in fewer than 2 decisions each. Best
case is the 1.26× sensing floor; the measured cell is already 1.92× energy / 3.31× T / 4.33× area,
and the word-level adder 3.94×/bit. **DIRECT** (measured) + **DERIVED** (the "hits the floor" bound
is §1).

Net of §2: research can *shrink* the device penalty (2.1) and *amortize* the encoding overhead (2.2),
but both are bounded below by the same 1.26× `3 ≠ 2^k` fact, and the one direction that could go
under it (a single native 3-way measurement, 2.1's escape) is empirically empty.

---

## 3. The honest bounded conclusion

> **Research can narrow ternary compute from ~1.5–2.0× toward ~1.26× per bit, and never below it.**

Three pieces of evidence pin this down:

1. **The floor is a coding fact, not a device gap.** `2·ln2/ln3 ≈ 1.26×` is representation-
   independent (`meta_math.md` §2) and Lean-proved (`ternary_binary_ratio`). It is the price of `3`
   not being `2^k`. No transistor — native or otherwise — rewrites `⌈log₂3⌉ = 2`.
2. **The honest native-device floor is ~1.5–2.0×, already above the 1.26×.** The 0.63× "win" was
   unphysical: a 3-level signal has half the margin per level, so matching binary's BER forces ~2×
   energy on top of the 2-decision cost (`FINAL_VERDICT.md` correction 4; `radix_lower_bound.md` §3;
   `lowswing_diode.md` §6). A perfect native device lands at ~1.5–2×, not 0.63×.
3. **The "dearth of research" is real but bounded.** Binary got 70 years × trillions of transistors;
   ternary got ~50 tube-era Setuns plus a small CNTFET/FeFET/memristor literature, none of which
   reports a native 3-state compute device (`docs/riscv_survey/ternary_ideas_eval.md` Setun rows;
   `_SYNTHESIS.md`: 11/11 negative). So the *measured* 1.72–3.94× is partly an immaturity artifact —
   but the maturity payoff is bounded: even a perfectly mature ternary compute stack stops at the
   1.26× sensing floor, and realistically at ~1.5–2× once noise margin is paid. More research buys
   the gap from ~1.5–2.0× down to ~1.26×; it buys **nothing below** it.

So: **fundamental** is the 1.26×; **dearth-of-research** is the *difference between ~1.5–2.0× and
1.26×*. Both are true at once, and neither one dissolves the other.

---

## 4. Where research money would actually pay: transport/storage, not compute

The 1.26× floor is a **sensing** floor — it is paid every time a trit is *read* (discriminated).
Transport and storage, done right, are not sensing:

- **Transport** moves a symbol without reading it. The null is "nothing on the wire" (~0.05 pJ, no
  current to drive), and radix economy sends 36.9% *fewer* symbols (`log₃2 = 0.6309`). Measured
  champion **0.081 pJ/bit = 6.32× vs natural binary (0.512), 2.67× vs matched low-swing binary
  (0.216)** — a win **not bounded by the read floor**, because no 2-decision read happens on the
  wire. **DIRECT** (`transport_model.md` §0; `FINAL_VERDICT.md` transport row; `JunctionMemory.lean`
  `champion_vs_lowswing` / `champion_vs_natural`). Caveat, for honesty: the low-swing lever is
  radix-agnostic (2.67× is the matched number), and the free null is conditional on null-heavy data
  (`hybrid_verdict.md` §1a).

- **Storage** — a native 3-level cell (memristor/FeFET) *holds* 3 states in one device: `log₂3 ≈
  1.585` bits/cell, i.e. a **0.63× density ceiling** (`1/log₂3`). The 2-decision floor applies only
  at read-back; a dense memory that writes once and reads rarely lets the density win dominate the
  read tax. **DIRECT** (the ceiling is arithmetic) — and the honest caveat is the same one as every
  native device: no surveyed memristor/FeFET currently *reports* beating the 2-bit cell on the honest
  (per-bit, endurance, variability) axis, and the "free null" is a **transport** property that does
  not transfer to storage — a storage cell must *hold and program* the null, not merely not-send it
  (`polar_memristor.md` §4.2/§4.4). So storage is where the ceiling is *unbounded by the read floor*,
  not where a win already exists.

The deep reason both escape the compute floor is in `meta_math.md` §3: the **wire is one 3-level
node** (one degree of freedom — tied with binary on erasure), while the **gate is two rails** (two
degrees of freedom — `ln 4` erasure for `log₂3` bits = 1.26× worse). Transport/storage live on the
one-node side; compute lives on the two-rail side. The floor is a *compute* floor.

> **One sentence:** ternary-transistor research is worth funding **only on the transport/storage
> axis — a native 3-state device (memristor/FeFET) with a free null, where the win is the unbounded
> 2.67–6.32× (transport) and the 0.63× density ceiling (storage) — and is a bounded-money pit on the
> compute axis, where the best possible outcome is still ≥1.26× worse than binary and nothing a
> device does can go under it.**

---

## Calibration summary

| claim | calibration | source |
|---|---|---|
| 1.26× = `2·ln2/ln3` sensing floor; `ternary_binary_ratio` proved | **DIRECT** (Lean) | `ThresholdLowerBound.lean` |
| 1.26× representation-independent (thresholds / decisions / erasure) | **DIRECT** (arithmetic) | `meta_math.md` §2–§3 |
| `3 ≠ 2^k` wastes `2 − log₂3 = 0.415` bits/symbol | **DIRECT** | `meta_math.md` §2 |
| `tadd1` = 1.92× energy / 3.31× T / 4.33× area of `bin_fa` | **DIRECT** (measured) | `trelax_measured.md` §2; `gate_area.md` |
| multiplier 1.72×/bit (shift-add) / 2.08× (Karatsuba); adder 3.94×/bit | **DIRECT** (measured) | `word_fairfight.txt` / `.md` |
| 2-bit/trit = 0.792 bits/wire = 1.26× wire overhead; 12T vs 6T | **DIRECT** | `gate_area.md` §3; `storage.md` §4–5 |
| honest native floor ~1.5–2×; 0.63× "win" unphysical | **DIRECT** (correction) | `FINAL_VERDICT.md` correction 4; `radix_lower_bound.md` §3 |
| no native 3-state device; 11/11 papers negative; free null transport-specific | **DIRECT** (survey) | `_SYNTHESIS.md` §2–§3 |
| transport 2.67–6.32× (0.081 vs 0.216/0.512 pJ/bit); not bounded by read floor | **DIRECT** (measured) | `transport_model.md` §0; `FINAL_VERDICT.md` transport row |
| storage density ceiling 0.63× = `1/log₂3`; no device beats 2-bit; null doesn't transfer | **DIRECT + OURS** | `polar_memristor.md` §4.3/§4.2 |
| Setun history (~50 tube-era) vs 70 years of binary | **DIRECT** (historical) | `ternary_ideas_eval.md` §Setun |
| "research narrows ~1.5–2.0× → 1.26×, never below" | **DERIVED** (floor + measured gap) | this file, on the DIRECT above |

## Sources

- `proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean` — the proved 1.26× floor.
- `docs/compute/ground_up/meta_math.md` — representation-independence; wire-vs-gate DOF split.
- `docs/compute/ground_up/adversarial_referee.md`, `docs/FINAL_VERDICT.md` — the ~1.5–2× native
  floor, the 0.63× correction, the settled compute/transport/namespace scoreboard.
- `docs/compute/word_fairfight.md` / `rtl/word_fairfight.txt`, `docs/compute/field_calculus/trelax_measured.md`,
  `docs/compute/gate_area.md` — the measured device penalty (1.72×/1.92×/3.94×).
- `docs/compute/storage.md` — the 2-bit/trit density overhead.
- `docs/graphs/ternary-transistors/_SYNTHESIS.md` — the 11-paper negative survey.
- `docs/riscv_survey/polar_memristor.md` — storage-device honesty (0.63× ceiling, free-null
  transfer failure).
- `docs/riscv_survey/transport_model.md` — the measured 2.67–6.32× transport win.
- `docs/riscv_survey/ternary_ideas_eval.md` — the Setun history control.
- Sibling refs: `docs/compute/hybrid/{hybrid_verdict,conversion_cost,emulation_cost}.md` — the
  consistent "compute loses 1.48–2.0×, transport conditional-win, 3ⁿ cancelled by 2-bit encoding"
  frame this file answers.
