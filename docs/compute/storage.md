# Ternary Storage — memory cells survey (Wave 1, component 2)

**2026-08-29 — the storage arm of the ternary-compute survey.** Scope: 3-level
memory cells (SRAM / DRAM / the `11=NEVER` don't-care), margins/refresh, energy/area
vs binary, and the headline question — *is the MEMORY CELL, not the logic gate, the
real wall for full-ternary-internal?*

Calibration legend (same as `TERNARY_COMPUTE_SURVEY.md`):
- **DIRECT** — textbook/first-principles physics, or a cited source number.
- **ANALOGY** — structural resemblance, not identity.
- **OURS** — our design claim, derived from our encoding / Lean proofs.
- **SPECULATION** — untested hypothesis, flagged.

---

## 0. The reframe: "ternary memory cell" means two different things

Before any numbers, the single most important distinction in this whole survey
(the one that dissolves the naive question):

| | **(A) Analog 3-level cell** | **(B) 2-bit-encoded cell (OURS)** |
|---|---|---|
| What is stored | one of 3 *voltage levels* on **one** storage node (`0, Vdd/2, Vdd`) | one trit = **2 binary bits** (`01=+1, 00=0, 10=−1, 11=NEVER`) |
| Physical cell | a *new* cell with a mid-level | a **standard binary cell**, nothing new |
| Density vs binary | 1.585 bits/cell → a real density win | 2 bits/trit = 1.585 bits of information → **26% overhead**, no win |
| Margin | Vdd/4 (halved) | Vdd/2 (unchanged) |
| Cost | new physics, mid-rail, 2-threshold sensing | zero — it *is* binary |

**Every published "ternary SRAM" paper builds (A).** Our RTL (`ternary_ff.v`,
`tword_ff`, the 213 binary FFs in `cpu.v`) already does (B) and has done so from the
start. The entire "is the memory cell the wall?" question is really two questions:
(a) *can (A) ever pay off?* and (b) *is (B) good enough?* They have opposite answers.

**Calibration: OURS** (the reframe is our own synthesis; the two encodings are DIRECT
— (A) is every MVL memory paper in the corpus, (B) is `rtl/ternary_ff.v` + `TernaryCell.lean`).

---

## 1. The one formula that governs all multi-level storage

A memory cell stores one of **m** levels spread evenly across a swing `Vdd`.
Adjacent levels are `Vdd/(m−1)` apart; the sense amplifier splits the difference, so
the **sense margin** (half the spacing) is

```
margin = Vdd / (2(m−1))
```

| m | bits/cell | margin | margin vs binary |
|---|---|---|---|
| 2 (binary) | 1.000 | Vdd/2 | 1.00× |
| 3 (ternary) | 1.585 | Vdd/4 | 0.50× |
| 4 | 2.000 | Vdd/6 | 0.33× |
| 8 | 3.000 | Vdd/14 | 0.14× |

**Calibration: DIRECT** (textbook sense-amplifier margin; the `log₂m` column is the
radix-economy identity already proved in `RadixEconomy.lean`).

**The two facts that matter:**

1. **Ternary is the *good* point on this curve.** Going 2→3 levels buys +0.585 bits
   for a 2× margin hit; going 3→4 buys +0.415 bits for a *further* 1.5× hit. The
   marginal bit is cheapest *at 3*. [DIRECT arithmetic on the table — this is the
   storage-flavoured echo of `ternary_saves_third` and Law 3.]

2. **But the margin hit is *not* shrinkable in a memory cell.** Law 1 says the
   receiver (the measurement) is the energy floor; a memory cell's *whole job* is to
   keep a state that can be re-measured, against leakage and noise, for the whole
   retention window. You cannot drive the signal down toward the receiver floor the
   way the comm stack does (`ENERGY_LAWS.md`: 0.081 pJ/bit by shrinking the wire),
   because the stored level *must survive* between reads. [ANALOGY to Law 1 — memory
   = retention + repeated measurement, not one-shot resolution.]

---

## 2. Ternary SRAM — what has actually been built

Published cells, transistor counts, and what they cost:

| Cell | Transistors | What it stores | Margin / stability | Source | Calibration |
|---|---|---|---|---|---|
| Binary 6T SRAM (baseline) | 6 | 1 bit | Vdd/2, RSNM ~ hundreds of mV | textbook | DIRECT |
| **Ternary SRAM 6T** (mid-rail reuse) | 6 | 1 trit (3 levels) | Vdd/4; needs a Vdd/2 mid-rail on the storage node | IEEE 10673161 (6T/8T/10T survey) | DIRECT (exists) / margin is the formula above |
| **Ternary SRAM 8T** | 8 | 1 trit | improved over 6T; still < binary | J. Sensor Sci. Tech. 2024 ("Novel Design of 8T Ternary SRAM") | DIRECT (named count) |
| **Ternary SRAM 10T** | 10 | 1 trit | better RSNM, more area | IEEE 10673161 | DIRECT (named count) |
| **Ternary SRAM 14T** (buffer-assisted) | 14 | 1 trit | "low-power" (targets standby), high area | Sci. Reports 2026 (`s41598-026-56270-6`) | DIRECT (named count) |
| **CNTFET ternary cell** | ~8T-class | 3 stable states | 3 stable points via CNT chirality | Lin/Kim/Lombardi, IEEE TNANO 2012 | DIRECT (exists); exact count — see source |
| **Our `tff_edge` (B)** | 2 bits ⇒ 12T-equivalent per trit | 1 trit in 2 binary bits | Vdd/2 (binary margins) | `rtl/ternary_ff.v` | OURS / DIRECT (it is literally 2 binary latches) |

**Calibration note:** the transistor counts 6/8/10/14 come from the *titles* of the
cited papers (each names its cell). The per-cell static-noise-margin *numbers* I have
**not** read out of the paywalled bodies — I state the *formula* margin (Vdd/4) and
flag the rest as "worse than binary, see source." Do not treat the table as measured
RSNM values. [honesty flag]

**What every (A)-cell pays, in three places [DIRECT across the corpus]:**

1. **A mid-rail.** The `Vdd/2` level must be generated and distributed, or it becomes
   a static `Vdd→GND` path (the exact failure the 2211.04542 thesis documents: naive
   3-level design is an energy *liability* until you move the mid-rail off-chip).
2. **A 2-threshold sense amp.** Reading 3 levels = 2 comparisons (`>Vref_lo`, `>Vref_hi`).
   This is literally the "3-level READ is a 2-threshold measurement" of the task
   brief — Law 1's receiver cost paid **per read, forever**.
3. **A 2-threshold write driver.** Writing the middle level needs more precision than
   rail-to-rail write; over/undershoot corrupts the neighbour level.

So the honest area/economics of a true ternary SRAM:

| metric | binary 6T | (A) 8T ternary | (A) 10T ternary | (B) ours (12T/trit) |
|---|---|---|---|---|
| transistors / cell | 6 | 8 | 10 | 12 |
| bits / cell | 1 | 1.585 | 1.585 | 1.585 (as 2 bits) |
| **transistors / bit** | **6.00** | **5.05** | **6.31** | **7.57** |
| vs binary 6T | 1.00× | **0.84× (16% better)** | 1.05× (worse) | 1.26× (worse) |
| sense margin | Vdd/2 | Vdd/4 | Vdd/4 | Vdd/2 |

**Break-even: a ternary cell beats binary 6T on raw bits/transistor only if it is
≤ 9 transistors** (`6 × log₂3 ≈ 9.5`). The 8T cell *nominally* wins (5.05 vs 6.00),
but that ignores the two killers: (i) the Vdd/4 margin forces **larger devices** per
transistor for equal noise immunity, and (ii) the **mid-rail generator + 2-threshold
sense amp** are array-level overheads that the per-cell count does not include.
Published 8T/10T/14T designs trade exactly these three levers; none reports a net
area+energy win over 6T binary once margins are equalized.

**Calibration:** the bits/transistor column is **OURS** (simple division on cited
counts); the "no net win once margins equalize" verdict is **ANALOGY** (consistent
with the corpus's own AND/OR-lose and divider-liability reversals, not a measured
result).

---

## 3. Ternary DRAM — charge storage, the genuinely hard case

DRAM stores a bit as **charge on a capacitor** (1 transistor + 1 capacitor, `1T1C`).
The signal is already tiny: the cell capacitor (~20–30 fF) charge-shares onto a bitline
(~100–200 fF), so a binary DRAM sense amp sees only ~100–300 mV. A multi-level DRAM
slices that already-small signal into `m−1` levels.

- **3-level DRAM (1T1C, three charge levels):** per-level signal ≈ Vdd/2, sense margin
  Vdd/4 of the *shared* swing — i.e. tens of mV. **SPECULATION-free statement: the
  margin per level is half the (already marginal) binary margin, and the charge per
  level is ~2/3 of binary.** [DIRECT formula + textbook DRAM numbers]
- **The refresh penalty:** retention is leakage-limited. Halving the stored charge per
  level (for equal cell cap) means the cell reaches the noise floor ~2× sooner, so
  refresh must run ~2× more often → ~2× the refresh energy per bit, which is the
  *dominant* DRAM energy term. [ANALOGY — the direction is certain, the exact factor
  is node-dependent and unmeasured here]
- **The empirical record:** multi-level DRAM was built and *abandoned*. Aoki et al.
  demonstrated a **16-level/cell** (4-bit) DRAM (ISSCC 1997) and follow-on
  "multilevel DRAM with adjustable cell capacity" (IEEE 933699); none became a
  product. Samsung/Intel 2-bit/cell DRAM research (~2009–2011) likewise never shipped.
  **Multi-level *won* only in flash** (MLC/TLC/QLC) and **signaling** (PAM-4) — places
  with no refresh (flash) or per-hop regeneration (signaling). It *lost* everywhere the
  state must be **retained and re-measured in place** — i.e. DRAM and SRAM. [DIRECT —
  the commercial outcome is documented; the "why" is the retention point above]

**Verdict on ternary DRAM: this is the single hardest cell in the whole survey.**
3-level charge storage on a 1T1C cell pays ~half the already-tiny DRAM margin, a
2-threshold sense amp, and a ~2× refresh-rate tax, to gain 1.585 bits/cell — and even
the *4-level* (2-bit) version of this idea, with better economics, never shipped. If
anything in full-ternary-internal is a *wall*, it is this. [ANALOGY → strong, but keep
it calibrated: no ternary DRAM cell has been fabricated and measured for us to cite.]

---

## 4. Energy / area vs binary — the summary table

| memory | transistors/cell | bits/cell | margin | refresh | energy/bit | area/bit |
|---|---|---|---|---|---|---|
| binary SRAM 6T | 6 | 1 | Vdd/2 | none | baseline | 1.00× |
| binary DRAM 1T1C | 1 + cap | 1 | ~100–300 mV | ~64 ms | lowest, refresh-bound | 1.00× (dense) |
| ternary SRAM (A) 8T | 8 | 1.585 | Vdd/4 | none | ~2× read (2-threshold) + mid-rail leak | 0.84× nominal, ≤1.0× after margin equalization |
| ternary SRAM (A) 10T/14T | 10/14 | 1.585 | Vdd/4 | none | same + larger | ≥1.05× / 1.47× |
| ternary DRAM (A) | 1 + cap | 1.585 | ~half binary | **~2× more frequent** | +2× refresh, 2-threshold sense | ~1.6× denser nominal, undermined by refresh |
| **ours (B)** — 2-bit trit | 12 / trit | 1.585 | Vdd/2 | none | = binary per bit | 1.26× (26% overhead) |

**Calibration:** the binary rows are DIRECT (textbook). The ternary rows mix DIRECT
cell counts with **ANALOGY** energy estimates — the project has a fair-fight ngspice
harness (`circuit/`) but it has **measured the comm stack (0.081 pJ/bit), NOT a memory
cell**. Every ternary energy number above is unmeasured; the *direction* (2-threshold
read, mid-rail leak, 2× refresh) is forced by physics, the *magnitude* is not. This is
the first thing to close with the harness.

**The one number that anchors the area question [OURS, derived]:** a true ternary cell
must be **≤ 9 transistors** to beat 6T binary on bits/transistor, *and* must hold
Vdd/4 margins with devices small enough that the array-level mid-rail + sense-amp
overhead doesn't eat the 16% nominal win. That is a narrow target and the published
cells (8T/10T/14T) sit right around the break-even, not decisively below it.

---

## 5. Is the memory cell or the logic the wall?

**Answer: the memory cell is the harder wall — but for a different reason than the
logic gate, and only if the goal is *native ternary density*.**

- **The logic wall** (surveyed in the sibling report) is the 2-threshold receiver tax
  per toggle. But a gate **regenerates a full-swing output** every cycle — the tax is a
  one-shot per-operation cost, and radix economy can amortize it. That is why the
  logic literature is *mixed* (some ternary gates win PDP, some lose) rather than
  uniformly negative.

- **The memory wall** is worse because a cell must **retain** a marginal state
  *between* measurements and then **re-measure** it on every access. Law 1's receiver
  cost, which comm can dodge by shrinking the wire and logic can dodge by regenerating,
  is paid here **continuously**: every refresh is a re-measurement, and the stored
  signal *cannot* be shrunk toward the receiver floor because it must survive the
  retention window against leakage and noise. Multi-level storage therefore has a
  *second* tax (retention/refresh) on top of the receiver tax that comm and logic do
  not pay.

- **The empirical proof is already on the record [DIRECT]:** multi-value *won*
  commercially in exactly the two places that escape this second tax — **flash**
  (charge isolated in a floating gate, no refresh) and **signaling** (regenerated at
  every hop) — and *lost* in exactly the two places that pay it — **DRAM** (MLC DRAM
  demonstrated, abandoned) and **SRAM** (ternary cells remain research-only). The
  storage cell is where multi-level's promise has historically died.

- **The honest counterpoint [OURS]:** for *our* architecture the wall is not the cell
  physics at all. Our trit is **2 bits**, so our "ternary storage" is binary storage
  with a hole at `11` — no margin penalty, no refresh penalty, no new cell. The price
  is not a *cell* wall but a *density* ceiling: we pay 2 bits for 1.585 bits of
  information (26% overhead), so full-ternary-internal over binary *cells* buys
  semantics (balanced arithmetic, `11` don't-care, fault canary) and **nothing** on
  storage density. Native ternary density is the one promise we *cannot* redeem with
  encoding (B) alone.

**One sentence [OURS synthesis]:** the logic gate can amortize its 2-threshold tax
because it regenerates; the memory cell cannot, because it must retain — so *native*
ternary storage (a true 3-level cell) is the harder wall, while *our* 2-bit-encoded
storage sidesteps the wall entirely and pays for it with a 26% density ceiling instead.

---

## 6. How `11 = NEVER` helps storage

Four distinct mechanisms, calibrated separately:

**1. A 1/3-free soft-error canary [OURS, exact].** In a 2-bit code with 3 valid +
1 forbidden word, a single-bit upset (SEU) lands in the forbidden word with
probability exactly **1/3** — and *1/3 is the maximum* any 3-valid-1-invalid 2-bit
code can achieve (the forbidden corner has degree 2, so at most 2 of the 6 single-bit
transitions from valid words can terminate on it). Concretely: `01→11` and `10→11`
are detectable, `01→00`/`00→01`/`00→10`/`10→00` are silent value corruption. Binary
gives **0%** detection without a parity bit. So `NEVER` is a weak, asymmetric, but
*genuinely free* canary — not ECC, but a nonzero SEU-detection rate we'd otherwise pay
a parity bit for. (The asymmetry: the null `00` has *zero* detection — both its flips
are valid codes.)

**2. Don't-care in the write/read decode [DIRECT, echoes the synthesis survey].** The
unused `11` is free minimization material in the address decode, sense, and ECC logic —
the same "don't-care `x` in truth tables = our `11` slot" already established for the
*logic* side (PDR 2105.09169, Automated_synthesis). For storage it means the 4th code
never needs a defined read/write behaviour, so fault injection can use it as an
"impossible value" sentinel.

**3. Trit-packing — reclaim the 0.415 bits/trit [DIRECT combinatorics, OURS framing].**
`11` is the headroom that lets trits pack tighter than 2 bits/trit:
`3⁴=81 ≤ 2⁷=128` ⇒ 4 trits in 7 bits (12.5% saving over 8); `3⁵=243 ≤ 2⁸=256` ⇒
5 trits in 8 bits (20% saving over 10). As the block grows the packing approaches
`log₂3 ≈ 1.585` bits/trit — recovering most of the 26% overhead of encoding (B)
**in bulk**, at the cost of variable-width unpack logic. This is how we get the
density win *without* a true 3-level cell.

**4. A ready-made 4th level if the cell *can* hold it [ANALOGY/SPECULATION].** A cell
that physically tolerates 4 levels is 2-bit storage, not ternary — but `NEVER` is
exactly the level that would occupy that 4th slot, so the 3-trit code extends to a
4-level cell with no redesign of the encoding. Unused unless we choose 2-bit/cell
storage.

**Net [OURS]:** `NEVER` does **not** give free density (that needs trit-packing, #3)
and does **not** give ECC (that's the 1/3 canary, #1). What it *does* give is a
free fault-detection canary and a clean route to bulk trit-packing — the two ways our
binary-cell storage can claw back what the true-3-level-cell path would have cost in
margins.

---

## 7. Bottom line and next steps

1. **The memory cell is the wall for *native* ternary, and it is harder than the logic
   gate**, because memory adds a retention/refresh tax to Law 1's receiver tax that
   neither comm (shrinks the wire) nor logic (regenerates) pays. The commercial record
   (MLC flash/signaling won; MLC DRAM/SRAM lost) is the empirical proof. [ANALOGY +
   DIRECT record]

2. **We already dodge the wall** with 2-bit-encoded trits (`ternary_ff.v`, 213 binary
   FFs) — and pay a **26% storage-density ceiling** for it. The honest trade is
   *semantics + canary + packable density* vs *native 1.585 bits/cell at Vdd/4 margin*.

3. **The cheapest next win is trit-packing (#6.3), not a new cell.** Bulk 4-trit→7-bit
   / 5-trit→8-bit packing recovers most of the 26% overhead using the binary cells we
   already have; it is a pure encoding-layer change with no margin or refresh risk.
   [OURS — design decision, testable in RTL]

4. **Do not green-light a true 3-level SRAM/DRAM cell.** The ≤9-transistor break-even
   plus the Vdd/4 margin plus the array-level mid-rail/sense-amp overhead is a narrow,
   historically-losing target. If we *do* explore it, measure with the existing
   fair-fight harness first — every ternary-cell energy number in this survey is
   currently ANALOGY, not measured. [OURS verdict]

---

## 8. Sources

- IEEE 10673161 — "Ternary SRAM Cell Designs for Next-Generation: 6T, 8T, 10T"
  [ieeexplore.ieee.org/document/10673161](https://ieeexplore.ieee.org/document/10673161)
- J. Sensor Science & Technology (2024) — "Novel Design of 8T Ternary SRAM"
  [koreascience.kr](http://koreascience.kr/article/JAKO202417172014349.pub)
- Scientific Reports (2026) — "A low-power buffer-assisted 14T ternary SRAM"
  [nature.com/s41598-026-56270-6](https://www.nature.com/articles/s41598-026-56270-6)
- Lin, Kim, Lombardi — "Design of a Ternary Memory Cell Using CNTFETs," IEEE TNANO
  (2012) [dl.acm.org/doi/10.1109/TNANO.2012.2211614](https://dl.acm.org/doi/abs/10.1109/TNANO.2012.2211614)
- US 10755769 — "Carbon nanotube ternary SRAM cell with improved stability and low
  standby power" [patents.justia.com/patent/10755769](https://patents.justia.com/patent/10755769)
- Aoki et al. — multilevel DRAM / 16-level cell (ISSCC 1997); "Design of a multilevel
  DRAM with adjustable cell capacity," IEEE 933699
  [ieeexplore.ieee.org/document/933699](https://ieeexplore.ieee.org/document/933699)
- Local corpus cross-refs: `docs/synthesis/ternary-circuits.md` (§3 "middle state is
  never free"; 2211.04542 divider liability, 2211.12176 D-latch App. A.3),
  `docs/ENERGY_LAWS.md` (Law 1 receiver floor, 0.081 pJ/bit), `rtl/ternary_ff.v`,
  `proofs/INDEX.md` (`TernaryCell.lean`, `FractalRam.lean`, `RadixEconomy.lean`).
