# ENERGY_IDEAS — low-power techniques mapped to the AC-polarity ternary cell

**Status:** RESEARCH SURVEY + MEASURED BASELINE (ngspice 44.2, run in this directory on 2026).
**Companions:** [`ternary_cell.cir`](ternary_cell.cir) + [`binary_baseline.cir`](binary_baseline.cir) (the
harness that measured the loss), [`README.md`](README.md) (harness docs), [`TERNARY_PROCESSOR.md`](../TERNARY_PROCESSOR.md)
(the encoding spec: one wire, polarity = value, null = no current, 2-diode receiver).

**Calibration legend** (house system): **[DIRECT]** established fact/measured here or in cited
literature · **[ANALOGY]** structurally similar to something real, mapping not an identity ·
**[SPECULATION]** design sketch, unverified as stated.

---

## 0. The measured baseline — why it loses (run today, not predicted)

All numbers below are real `.meas` outputs from this directory's netlists (ngspice 44.2).

| config | energy per transfer | notes |
|---|---|---|
| **ternary, as shipped** (3 ns × 1 mA pulse, 500 Ω load to gnd, PN diode) | **5.36 pJ** (`epush` = `epull`) | driver voltage `vline = 1.67 V` |
| ternary, null | **≈ 0** (`enull = −6e-66 J`) | null-is-free **confirmed** ✓ |
| ternary, push→pull back-to-back | `ecyc2 = 2.68 pJ` vs `epull = 5.36 pJ` | charge recycling **present** (halves it) ✓ |
| **binary, same wire** (1.5 pF, 1 V rail) | **1.50 pJ/cycle = 0.75 pJ/bit** | textbook ½·C·V²·… = 1.5 pF·1 V² ✓ |

**Why the 5.36 pJ happens (decomposition from the model's own numbers):**
`V(drv) = 1.67 V = 1 mA × (R_wire 500 Ω + diode RS 50 Ω + load 500 Ω) + Vf(PN) ≈ 1.05 V resistive + 0.62 V diode`.
Energy = ∫V·I dt ≈ **1.67 V × 1 mA × 3 ns ≈ 5.0 pJ**. So of the 5.36 pJ:

- **~60 % is resistor drops** — the wire, the diode's series R, and *especially the 500 Ω load to ground*,
  which burns `I²·R` continuously for the whole pulse (a deliberate LVDS-style termination — wrong for a
  short RC-dominated on-chip wire, see §1.6).
- **~26 % is the diode forward drop** (0.62 V PN).
- **~14 % is actual capacitance charging** (1.5 pF worth) — the *only* part the encoding "should" pay.

The cell does not lose because ternary is a bad encoding. **It loses because the driver is a static-current
source into a resistive sink.** Binary's 0.75 pJ/bit is the *ideal* ½·C·V²; ternary's 5.36 pJ is the *ideal*
plus a 4–5 pJ static-current tax.

**Quick experiments that prove the levers** (all run on copies of the shipped netlist):

| experiment | `epush` | vs baseline |
|---|---|---|
| remove 500 Ω load (`rload=1meg`), keep 3 ns pulse | 8.32 pJ | **worse** — current source rams the rail-cap voltage to 3.3 V; a fixed-width current pulse *needs* a resistive sink |
| **charge-transfer: 0.5 ns pulse + `rload=1meg`** | **1.52 pJ** | **−72 %**, rail still asserts 0.72 V (> 0.25 V demux threshold) |
| Schottky-like diode (IS=1e-9, N=1.05), everything else as shipped | 4.67 pJ | −13 % (diode drop is a minority of the budget) |
| **combined: 0.5 ns + `rload=1meg` + low-Vf diode** | **1.50 pJ** | **−72 %**, rail 0.93 V, `ecyc2 = −0.26 pJ` (energy *returned*) |

Bottom line: **a ~3.5–4× reduction is already sitting in the driver/receiver choice, not in any exotic
physics** — and the charge-transfer regime turns recycling negative (energy flows back).

---

## 1. Ranked techniques, mapped to this cell

Each entry: **what** / **expected saving mechanism** / **what it costs** / **one-line ngspice test** /
calibration + sources. Ranked by (energy impact × feasibility) for *this* cell.

---

### 1.1 Charge-transfer pulse + high-impedance (capacitive) receiver — kill the static current  — **[DIRECT]**

**What.** Replace the 3 ns × 1 mA constant-current pulse (static power for the whole pulse) with a short
pulse that transfers only the charge the wire needs: `Q = C_line·V_swing` (≈ 1.4 pF × 0.3 V ≈ 0.4 pC ⇒
`PW ≈ 0.4 ns` at 1 mA), then release. Simultaneously remove the 500 Ω loads (`RLA/RLB → 1 MΩ`): the
receiver becomes a diode clamp + small rail cap + high-impedance sense, instead of a resistor that converts
every nanoamp of signal current into heat. This is standard **low-swing charge-transfer signaling**: the
state of the art on-chip is [40.4 fJ/bit/mm low-swing signaling with self-resetting repeaters in 45 nm SOI](https://ieeexplore.ieee.org/abstract/document/6513778)
(also [ACM version](https://dl.acm.org/doi/epdf/10.5555/2485288.2485677)) — voltage-pulse driven, no
termination, energy ∝ transitions only.

**Saving mechanism.** Removes the ~4 pJ static `V·I·t` term, leaving ~CV² plus a short resistive transient.
Measured: 5.36 → 1.52 pJ (**−72 %**), and `ecyc2` goes negative (recycling returns energy).

**What it costs.** The trit is no longer "a packet of current for a fixed time"; it becomes "a polarity
excursion of the line voltage", which is what the encoding claims anyway (TERNARY_PROCESSOR §1.2). Needs a
keeper/level-hold (§1.3) and a real sense amplifier at the receiver (§1.10). Requires giving up the
LVDS-style 100 Ω termination idiom — fine for short RC wires, wrong for long transmission lines
([TI on LVDS termination](https://www.ti.com/video/5775278303001)).

**Test (one line).** In `ternary_cell.cir`: change `.param PW = 3n` → `.param PW = 0.5n` and append
`rload=1meg` to the three `Xpush/Xpull/Xcyc` subckt calls; re-run and compare `epush` and `ecyc2`.
(Measured answer above: 1.52 pJ / −0.26 pJ.)

---

### 1.2 Operate at the Schottky knee (~0.3–0.4 V swing) — the SLVS precedent with a diode detector — **[DIRECT]/[ANALOGY]**

**What.** The 2-diode receiver pins the minimum signal to the diode forward drop. PN Vf ≈ 0.6 V sets the
1.67 V driver headroom; a Schottky (Vf ≈ 0.3–0.35 V at 1 mA) or low-Vt pass-transistor rectifier sets it
to ≈ 0.9–1.0 V. Note the delightful coincidence: **0.3–0.4 V is exactly the swing real low-power links use** —
SLVS-400 (JEDEC [jesd8-13](https://web.archive.org/web/20150219011544if_/http://www.jedec.org:80/sites/default/files/docs/jesd8-13.pdf),
[CERN SLVS transmitter/receiver](https://indico.cern.ch/event/489996/contributions/2212777/attachments/1343890/2028065/poster_twepp2016_SLVS.pdf))
and the MIPI D-PHY/SLVS-12 family ([D-PHY chip design](https://www.sciencedirect.com/science/article/abs/pii/S0026269212001735)).
So "Schottky-diode polarity receiver at 0.35 V" ≈ **a single-ended SLVS link with a diode rectifier instead
of a differential comparator**. Lowering swing also shrinks the CV² term quadratically (§1.4 does the math).

**Saving mechanism.** Two terms: (a) diode-drop share of the budget (measured −13 % standalone: 4.67 pJ);
(b) at equal *driver* swing, every capacitive term scales as V². With the §1.1 fix already at 1.5 pJ, the
0.35 V receiver plus ~0.9 V driver headroom shaves the remaining resistive/diode overhead roughly in half.

**What it costs.** Schottky leakage is ~5 orders higher (IS=1e-9 vs 1e-14) — null-state leakage grows
(marginal: measured `enull` still ≈ 0 because the keeper is 1 MΩ). **Hard constraint:** below Vf the diode
stops conducting, so swing ≤ Vf kills the receiver — this is the real floor on how low you can go with
passive rectification (the *active* alternative is §1.10).

**Test (one line).** Uncomment `.model DSCHOTTKY` (or set `IS=1e-9 N=1.05`) in the shipped netlist, re-run,
read `epush` + `vline_push`; then sweep pulse amplitude 0.2/0.35/0.5/0.7/1.0 V and plot `epush` vs V²
(expect a quadratic knee at V ≈ Vf).

---

### 1.3 Hold-on-null + charge recycling — make energy *transition-count*-based (the third state's structural win) — **[ANALOGY] → cell math [SPECULATION]**

**What.** Decide the open question TERNARY_PROCESSOR §5.1 in the energy-winning direction: **null = hold
the line's last polarity (keeper, zero current), not "line returns to 0"**. Then a null costs nothing *and*
a same-polarity repeat costs nothing — only a **polarity flip** (push→pull or pull→push) charges the line.
This is the exact energy model of **charge-recycling buses** ([Sotiriadis, ISLPED'01, "Analysis and
implementation of charge recycling for deep sub-micron buses"](https://dl.acm.org/doi/epdf/10.1145/383082.383184)
/ [Semantic Scholar record](https://www.semanticscholar.org/paper/Analysis-and-implementation-of-charge-recycling-for-Sotiriadis-Konstantakopoulos/0d901add336671ef5d283e4c18b1098268466fa2)),
where the wire's stored charge is passed to the next symbol instead of dumped ([1-of-n NDL charge-recycling
gate patent](https://patents.google.com/patent/US20130141073)). The harness already shows recycling:
`ecyc2 = 2.68 pJ < epull = 5.36 pJ` at baseline, and **negative** (−0.26 pJ) in charge-transfer mode.

**Saving mechanism.** The cost model becomes `E_avg = P(flip)·E_flip + leakage` instead of
`E_avg = (1−p)·E_sig`. For a memoryless source with null probability p (and ± equally likely),
`P(flip) = (1−p)²/2`. The third state now wins *structurally*: per bit of information carried,
ternary flips less often than binary flips, and the null is a free symbol on top (see §1.9 for numbers).

**What it costs.** The receiver must *remember* the last polarity (a latch/keeper per rail instead of
resistors that drain it — §1.1's high-Z receiver does this). History dependence: the demux reads the last
excursion, so a burst of nulls must not let the line drift (keeper sizing). This is the "null = held, not
floating" answer — the exact policy the harness's 1 MΩ `Rterm` already implements.

**Test (one line).** With §1.1 applied (`PW=0.5n`, `rload=1meg`), add a burst of alternating
push/pull pulses (`Icy3…Icy10` at 2 ns spacing), and add `.meas` windows on events 5–10; expect
steady-state per-event energy ≈ `P(flip)·E_flip ≪ epush`.

---

### 1.4 Adiabatic (ramped) charging of the line — how close to zero reversible charging gets — **[DIRECT]**

**What.** Charge the wire through its resistance with a *slowly ramped* driver instead of a step. For a
linear ramp of duration T into an RC load: `E_diss ≈ (RC/T)·½·C·V²` — the CV² term multiplied by
`RC/T`, so **E → 0 as T → ∞** ([TUM, "Enhanced prediction of energy losses during adiabatic
charging"](https://mediatum.ub.tum.de/download/680196/680196.pdf); [Zyvex reversible-computing intro](https://www.zyvex.com/nanotech/reversible.html)).
Real adiabatic logic families (2N-2N2P, PAL, clock-powered CMOS) report ~10–100× energy cuts at speed
penalties ([Athas, "Clock-Powered CMOS: a hybrid adiabatic logic style"](http://www.ai.mit.edu/projects/im/ftp/poc/athas/arvlsi.pdf);
[recent adiabatic NOT/AND/FA measurements](https://ieeexplore.ieee.org/abstract/document/10986360);
[partially vs fully adiabatic family survey](http://shodhbhagirathi.iitr.ac.in:8081/xmlui/bitstream/handle/123456789/12147/PHDG20181.pdf)).

**Saving mechanism.** On this cell, the *current-source driver already is a ramp* — the CV² part is already
quasi-adiabatic. The trick is to apply the ramp *only to the capacitive part* and not feed the static
current through the load resistors (i.e., combine with §1.1). RC = 500 Ω·1 pF = 0.5 ns; a 5 ns ramp gives
a 10× reduction of the remaining CV² term. **This is the theoretical floor section's headline: there is no
energy floor at CV² for *charging* — the floor is set by how slow you're willing to be, and by the
receiver (§1.10).**

**What it costs.** Speed (E ∝ 1/T) and a trapezoidal/ramped supply or a controlled-current driver. On a
*shared* bus with a keeper (hold-on-null), the ramp must be per-event.

**Test (one line).** Add `.step param TR 0.5n 5n 0.5n` and change the driver to
`PULSE(0 {IP} 10n {TR} {TR} {PW} 200n)`; print `epush` per step and check `epush ∝ 1/TR`.

---

### 1.5 Near-threshold / subthreshold operation — lower V and I — **[DIRECT]**

**What.** Operate the driver at the lowest supply that meets the timing budget. Near-threshold (Vdd ≈
0.3–0.5 V) is where energy/op is minimized: dynamic energy falls ∝ V² while leakage grows only
exponentially ([Alioto, HotChips-26 ULV tutorial](http://old.hotchips.org/wp-content/uploads/hc_archives/hc26/HC26-10-tutorial-epub/HC26.10-tutorial2-IoT-epub/HC26.10.225-Ultra-Low-Alioto-Singapore-HotChips2014_alioto.pdf);
[NTV variability survey](https://www.sciencedirect.com/science/article/abs/pii/S0026269215002372)).

**Saving mechanism.** If the whole link ran at 0.4 V instead of 1 V, every V² term drops 6×. For the
current-mode driver, lower I with the same Q means longer τ but `E = I·R·Q` scales down linearly with I.

**What it costs.** **Direct conflict with the 2-diode receiver**: subthreshold swings (0.05–0.15 V) are
below any diode's Vf — the receiver must become active (§1.10) or the swing must stay ≥ Vf (which defeats
subthreshold). Also speed and noise-margin penalties. Conclusion: near-threshold *supply* with a
Schottky/Vf-matched swing is compatible; *subthreshold* signaling is only viable with an active receiver.

**Test (one line).** Set `.param IP=100u .param PW=30n` (same transferred charge Q), keep `rload=1meg`,
re-run, and compare `epush` (expect ~10× lower) while checking `vrA_push` still clears the demux threshold.

---

### 1.6 Current-mode verdict — keep it for the *direction sense*, drop it for the *energy model* — **[DIRECT]**

**What.** The model's driver is the LVDS/CML idiom: a constant current whose *sign* is the symbol. That
idiom exists for **speed and low swing**, not energy: CML draws static current on every symbol regardless
of data (see the current-mode interconnect literature — [high-throughput current-mode global interconnect](https://ieeexplore.ieee.org/document/5640513),
[multi-bit quaternary current-mode on-chip signaling](https://ieeexplore.ieee.org/document/4405738)). Real
low-power links are the opposite: **voltage-mode, low-swing, zero static current**, energy ∝ actual
transitions — the 40.4 fJ/bit/mm repeater link above, SLVS (§1.2), and bus-encoding work (§1.8).

**Saving mechanism.** Switching the *model* from current-mode to voltage-pulse mode removes the static
`I·V·τ` term (measured −72 % in §1.1). The *encoding claim* (polarity = value) survives intact: a voltage
excursion still has a sign. Nothing about "push/pull/null" requires a current source.

**What it costs.** Nothing conceptually — it's a driver swap. The reason to *keep* a current sense is
diagnostic: `∫V·I` at the driver is the natural `.meas`. Keep current sources for measuring, drive with
voltage pulses for the energy story.

**Test (one line).** `VpA dA 0 PULSE(0 0.35 10n 0.5n 0.5n 2n 200n)` in series with a 50 Ω source R
(delete `IpA`), `rload=1meg`, measure `epush` — expect ≲ 0.5 pJ.

---

### 1.7 DC-couple + keeper; refuse the AC-coupling/8B10B/Manchester tax — **[DIRECT]**

**What.** The harness already DC-couples with a 1 MΩ keeper. That is the right answer and should be made
explicit as a *policy*: TERNARY_PROCESSOR §1.4/§5.2 flags "if truly AC-coupled, a held +1 decays, so you
need DC balance or refresh". **Do not go AC.** DC-balance coding is expensive: 8B/10B adds 25 % symbols
([original 8B/10B patent](https://patents.google.com/patent/US4486739A)); Manchester *doubles* the
transition rate by guaranteeing an edge every symbol ([Manchester, DigiKey](https://www.digikey.com/en/blog/old-but-still-useful-the-manchester-code)) —
both are catastrophic under the transition-count energy model of §1.3 (energy ∝ transitions).

**Saving mechanism.** Avoids a 25–100 % energy tax on every symbol. Bonus: with a keeper, the null and
same-polarity events are *free* (§1.3), which is exactly the property a DC-balanced code would destroy
(nulls contribute nothing to running balance, so a DC-balanced ternary line code would have to emit
balancing ± pairs regardless of data — the null would stop being free *for balancing purposes*).

**What it costs.** No DC isolation (a shared mid-rail or level mismatch problem if the "wire" is
galvanically separated — not the on-chip case). A keeper that must win over diode leakage (trivial at
1 MΩ vs 1e-14–1e-9 A).

**Test (one line).** Control experiment: insert a series coupling cap `Cc drvA x 1n` (AC-couple) and
measure `vrA` drift between pulses (`FIND V(rAp) AT=90n` with a held +1); quantify the refresh cost the
doc's AC option would impose.

---

### 1.8 Symbol-to-state mapping (bus-invert-style): put the common symbol on null — **[ANALOGY]**

**What.** Bus-invert/DBI encoding picks, per transfer, whether to invert the bus so the *majority* of bits
don't toggle, saving `α·C·V²` ([Stan & Burleson, "Low-power encodings for global communication"](https://www.virascience.com/document/cefff969812a382e0f4797472424c6a31752b33d/);
[DBI for SERDES buses](https://www.semanticscholar.org/paper/Data-Bus-Inversion-Encoding-for-Improving-the-Power-Kang-Park/9b246bc3aa2dd03d12e238409ed68ffb7b768812);
[broad bus-encoding survey](https://shodhganga.inflibnet.ac.in/bitstream/10603/400157/9/09_chapter%202.pdf)).
The single-wire ternary analogue: **map the most frequent symbol of your traffic to the zero-cost state**.
Under Zipf-ish traffic one symbol dominates; if that symbol is the null (sparse/event traffic, sparse
activations, idle lanes), it is *free* (§1.3). If the dominant symbol is a ±1, no mapping helps — the
*frequency order of your traffic* decides.

**Saving mechanism.** Converts traffic statistics into energy savings for free (no extra wire, no
overhead symbol). The information-theoretic bound on how low transition *activity* can go is set by the
source entropy — [Ramprasad/Shanbhag/Hajj, "Information-theoretic bounds on average signal transition
activity", IEEE TVLSI'97 (DOI 10.1109/92.784097)](https://oula.finna.fi/PrimoRecord/pci.cdi_crossref_primary_10_1109_92_784097):
you cannot beat the entropy bound, but a 3-state line with a free state sits *below* a 2-state line with
the same per-transition cost, because ternary's per-bit transition rate is lower: 0.42 vs 0.5 per bit in
the symbol-change model (any non-null event costs), and only 0.32 flips per bit in the hold model of
§1.9 (only polarity changes cost).

**What it costs.** Only if you add an explicit invert-tag symbol on a *wide* bus (the classic DBI cost).
On a single wire, the "mapping" is just *choosing* which symbol is the zero state — free, but it hard-wires
the energy win to your traffic mix, so it must be measured on real traffic (§1.9 test).

**Test (one line).** Generate a PWL stimulus with a `pnull` parameter (`.param PNULL=0.5`), run 100
symbols, `.meas` average `∫V·I` per symbol, and sweep `PNULL` ∈ {0, 0.3, 0.5, 0.8, 0.95}.

---

### 1.9 Average-energy (Zipf) model — the quantified break-even — **[DIRECT math], framing [SPECULATION]**

**What.** The honest cost function, from §1.3: per-trit average energy
`E_avg = (1−p)·E_sig` in the "null = zero" regime, or `E_avg = P(flip)·E_flip` in the "null = hold"
regime. Compare per **bit of information**: one trit = log₂3 = 1.585 bit, so ternary wins iff
`E_trit / 1.585 < E_binary_bit = 0.75 pJ`, i.e. **`E_trit < 1.19 pJ`**.

**Break-even null probability** (null-free cost model, `E_avg = (1−p)·E_sig`):

| `E_sig` | p* = 1 − 1.19/E_sig | meaning |
|---|---|---|
| 5.36 pJ (as shipped) | **0.778** | need > 78 % nulls just to tie — brutal, *this* is why it loses |
| 1.5 pJ (measured §1.1 fix) | 0.21 | wins with only 21 % nulls |
| 1.19 pJ | 0 | ties even with zero nulls |
| 0.6 pJ | < 0 | wins 2× with zero nulls; 4× at 50 % nulls |

**Transition-count model** (hold-on-null, memoryless, `P(flip) = (1−p)²/2`; one flip swings the line by
2V, so a *non-recycled* flip costs ≈ `2·C·V²`). The honest equal-swing comparison at V = 0.35 V,
C = 1.5 pF, uniform traffic (p = 0):

| quantity | value |
|---|---|
| binary `E/bit = P(0→1)·C·V²` | 0.25·1.5p·0.1225 = **46 fJ/bit** |
| ternary `E/symbol = P(flip)·2·C·V² = 0.5·0.367 pJ` | 184 fJ/symbol ÷ 1.585 = **116 fJ/bit** |
| ternary with **50 % charge recycling** (measured: `ecyc2 ≈ 0.5·epull` at baseline; **negative** in charge-transfer mode) | ≈ **58 fJ/bit** — beats binary |
| ternary with **recycling + nulls** (p = 0.5, `P(flip) = 0.125`) | ≈ **15 fJ/bit** — ~3× under binary |

Ternary's structural edge at equal swing: 1.585 bits/symbol, fewer flips per bit (0.32 vs 0.5),
and a free null state — **but only if the flip's stored charge is recovered**. A bipolar hold-line flip
swings 2× binary's swing; *recycling is not optional, it is the mechanism that turns "3 states" into a
win at uniform traffic.* With nulls, the win grows quadratically (`P(flip) = (1−p)²/2`).

**The honest answer to "does a higher per-transfer cost win on average?":** *only if your null probability
clears p\*, and at the shipped 5.36 pJ that means > 78 % nulls — a very demanding traffic assumption
(that's exactly the "sparse traffic" regime: event buses, sparse memory, idle lanes). The fix is not to
pray for Zipf; it's to drop E_sig below 1.19 pJ (§1.1–§1.2 do that *measured*), after which the null is
pure bonus and the break-even is automatic.*

**What it costs.** Nothing in silicon — it reframes the metric. What it *demands*: a traffic histogram of
the real workload (the input to §1.8's mapping and to the `PNULL` sweep).

**Test (one line).** No circuit change — run §1.8's `PNULL` sweep and plot `E_avg(PNULL)` against the
1.19 pJ line.

---

### 1.10 Cost the real receiver/demux — the practical floor lives here — **[DIRECT]**

**What.** The harness's demux (`da/db` in the README's sketch; ideal comparator in the docs) is free. A
real receiver — sense amplifier / strongARM latch / comparator — adds energy per sample. State-of-the-art
low-swing receivers exist ([ultra-low-power on-chip differential interconnect with high-resolution
comparator](https://www.infona.pl/resource/bwmeta1.element.ieee-art-000006457833)); the 40.4 fJ/bit/mm
link's [self-resetting repeaters](https://dl.acm.org/doi/epdf/10.5555/2485288.2485677) are the
energy-efficient local-regeneration precedent.

**Saving mechanism.** None directly — it's a *cost* item, but it sets the floor: below
~10–100 fJ/sample receiver energy (45 nm-era comparator), the wire is no longer the dominant term and the
whole exercise is moot. It also fixes the polarity-convention wart found while measuring: with a high-Z
load the *pull* rail asserts **negative** (`vrb_pull = −0.72 V` vs the ideal-comparator assumption of
+0.5 V) — a real receiver must handle bipolar rails or level-shift, and this must be in the energy ledger.

**Test (one line).** Add a minimal CMOS latch/strongARM subckt on `rA`/`rB`, `.meas` its supply integral
per sample, and add it to the per-trit budget.

---

## 2. The honest theoretical floor

1. **Absolute (information):** Landauer's kT·ln2 ≈ **2.9 aJ/bit at 300 K** for erasing one bit
   ([experimental verification, Science Advances](https://www.science.org/doi/full/10.1126/sciadv.1501492));
   the receiver's decision also costs ≥ ~kT·ln2 (Shannon noise floor). This is unreachable for *transport*;
   it is the hard limit only for the logical *erasure* part of driving a wire.
2. **Absolute (charging):** adiabatic charging has **no CV² floor** — `E ≈ (RC/T)·½CV² → 0` as the ramp
   time T → ∞ ([TUM model](https://mediatum.ub.tum.de/download/680196/680196.pdf), [Zyvex](https://www.zyvex.com/nanotech/reversible.html)).
   The floor is set by how much *time* you can spend, and by the receiver.
3. **Practical floor for this cell topology:** with the §1.1+§1.2+§1.3 package at 0.35 V swing and a
   real comparator (~10–100 fJ/sample), the link lands at roughly **10–100 fJ per trit** (transition-count
   model, §1.9), i.e. **~5–60 fJ/bit** — 10–100× under binary's 0.75 pJ/bit on the *same wire*. The
   current model at 5.36 pJ is **~50–500× above that floor, and 100 % of the gap is driver/receiver
   choice, not the ternary encoding.**

---

## 3. The fair fight (do this before claiming victory)

The 0.75 pJ/bit binary number uses a 1 V rail. At equal swing V, binary costs `½·C·V²` per bit; ternary
at the same V costs `P(flip)/1.585·2·C·V²`. The correct experiment:

- run `binary_baseline.cir` at `VDD=0.35…0.6` (careful: VTO=0.4 stops switching below ~0.6 V — the
  binary *driver* needs VT-engineered transistors at low swing, which is itself a "technique" worth
  noting, or compare against the analytic `½CV²`),
- compare against the §1.1–§1.3 ternary at the same swing and same receiver energy class.

Only then does the ternary-vs-binary verdict come from the encoding (1.585 bits/symbol, fewer flips/bit,
free null) instead of from a 1 V vs 0.35 V driver difference.

---

## 4. Source list

**Adiabatic / reversible / charge recovery**
- [Reversible computing intro — Zyvex](https://www.zyvex.com/nanotech/reversible.html)
- [Experimental test of Landauer's principle — Science Advances](https://www.science.org/doi/full/10.1126/sciadv.1501492)
- [Enhanced prediction of energy losses during adiabatic charging — TUM](https://mediatum.ub.tum.de/download/680196/680196.pdf)
- [Clock-Powered CMOS: a hybrid adiabatic logic style — Athas et al.](http://www.ai.mit.edu/projects/im/ftp/poc/athas/arvlsi.pdf)
- [Power reduction in NOT/AND/FA using adiabatic methods — IEEE](https://ieeexplore.ieee.org/abstract/document/10986360)
- [Partially vs fully adiabatic families — IIT-Roorkee thesis](http://shodhbhagirathi.iitr.ac.in:8081/xmlui/bitstream/handle/123456789/12147/PHDG20181.pdf)

**Near-threshold / subthreshold**
- [Ultra-low-voltage design tutorial — Alioto, HotChips-26](http://old.hotchips.org/wp-content/uploads/hc_archives/hc26/HC26-10-tutorial-epub/HC26.10-tutorial2-IoT-epub/HC26.10.225-Ultra-Low-Alioto-Singapore-HotChips2014_alioto.pdf)
- [Variability modeling in near-threshold CMOS — ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0026269215002372)

**Current-mode vs voltage-mode / low-swing links**
- [Low-power high-throughput current-mode global interconnect — IEEE](https://ieeexplore.ieee.org/document/5640513)
- [Multi-bit quaternary current-mode on-chip signaling — IEEE](https://ieeexplore.ieee.org/document/4405738)
- [40.4 fJ/bit/mm low-swing on-chip signaling, self-resetting repeaters, 45 nm SOI — IEEE](https://ieeexplore.ieee.org/abstract/document/6513778) · [ACM](https://dl.acm.org/doi/epdf/10.5555/2485288.2485677)
- [Ultra-low-power on-chip differential interconnect with high-resolution comparator — IEEE](https://www.infona.pl/resource/bwmeta1.element.ieee-art-000006457833)

**Low-swing standards (the "single wire but efficient" precedent)**
- [JEDEC SLVS jesd8-13 (archived)](https://web.archive.org/web/20150219011544if_/http://www.jedec.org:80/sites/default/files/docs/jesd8-13.pdf)
- [SLVS transmitter and receiver for readout ASIC — CERN](https://indico.cern.ch/event/489996/contributions/2212777/attachments/1343890/2028065/poster_twepp2016_SLVS.pdf)
- [D-PHY chip design (MIPI SLVS-12 family) — ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0026269212001735)
- [Advantages of LVDS — TI](https://www.ti.com/video/5775278303001)

**Multi-level / line codes / DC balance**
- [PAM3 vs PAM4 — Rambus glossary](https://www.rambus.com/chip-interface-ip-glossary/pam3-and-pam4/)
- [MLT-3 — Wikipedia (eo)](https://eo.wikipedia.org/wiki/MLT-3)
- [Manchester code — DigiKey](https://www.digikey.com/en/blog/old-but-still-useful-the-manchester-code)
- [Original 8B/10B patent — Google Patents](https://patents.google.com/patent/US4486739A)

**Charge recycling / bus encoding / transition activity**
- [Analysis and implementation of charge recycling for deep sub-micron buses — ISLPED'01 (ACM)](https://dl.acm.org/doi/epdf/10.1145/383082.383184) · [Semantic Scholar](https://www.semanticscholar.org/paper/Analysis-and-implementation-of-charge-recycling-for-Sotiriadis-Konstantakopoulos/0d901add336671ef5d283e4c18b1098268466fa2)
- [Charge-recycling 1-of-n NDL gate (patent)](https://patents.google.com/patent/US20130141073)
- [Low-power drivers / bus-invert — Stan & Burleson](https://www.virascience.com/document/cefff969812a382e0f4797472424c6a31752b33d/)
- [DBI for SERDES buses — Semantic Scholar](https://www.semanticscholar.org/paper/Data-Bus-Inversion-Encoding-for-Improving-the-Power-Kang-Park/9b246bc3aa2dd03d12e238409ed68ffb7b768812)
- [Bus encoding for low power (survey chapter)](https://shodhganga.inflibnet.ac.in/bitstream/10603/400157/9/09_chapter%202.pdf)
- [Information-theoretic bounds on average signal transition activity — Ramprasad/Shanbhag/Hajj, TVLSI'97](https://oula.finna.fi/PrimoRecord/pci.cdi_crossref_primary_10_1109_92_784097)

**Project-internal**
- [`ternary_cell.cir`](ternary_cell.cir) · [`binary_baseline.cir`](binary_baseline.cir) · [`README.md`](README.md) · [`TERNARY_PROCESSOR.md`](../TERNARY_PROCESSOR.md)

---

## 5. Summary — top 3 to try next (~10 lines)

1. **Charge-transfer pulse + high-Z receiver (§1.1)** — the measured 5.36 pJ is ~60 % resistor drops +
   ~26 % diode drop from a 3 ns static 1 mA pulse into a 500 Ω load. Shorten the pulse to
   `PW=0.5n`, kill the loads (`rload=1meg`): **measured 1.52 pJ (−72 %)** with the demux still asserting
   and recycling going negative. This alone drops E_sig below the 1.19 pJ per-bit break-even *almost*
   (still needs a bit of swing reduction or nulls).
2. **Operate at the Schottky knee / 0.3–0.4 V swing (§1.2)** — Vf is the swing floor, and 0.35 V is
   exactly SLVS-400 territory; combined with #1 the link is "a single-ended SLVS link with a diode
   rectifier", and every V² term falls ~8×. Measured: Schottky alone −13 %; the win compounds.
3. **Decide "null = hold" and adopt the transition-count model (§1.3 + §1.9)** — with a keeper, nulls
   and same-polarity repeats are free; only flips cost (`E ∝ (1−p)²/2`). That is the *structural* reason
   ternary can beat binary (fewer flips/bit + 1.585 bit/trit + free null), **provided the flip's stored
   charge is recycled** — a bipolar flip swings 2× binary's swing, and the cell already returns energy
   (`ecyc2` = 0.5·`epull` at baseline, negative in charge-transfer mode). The quantified break-even: at
   the shipped 5.36 pJ you'd need > 78 % nulls, but after #1+#2 the win is automatic at p≈0 and grows
   quadratically with null probability. Then run the fair fight (§3): same swing, same receiver class,
   binary vs ternary.
