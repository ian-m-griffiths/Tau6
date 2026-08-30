# Measurement Audit — is the ternary "fair fight" systematically biased?

**2026-08-29. A verification pass over the *measurement methodology itself* — not the results, not
the proofs.** This file audits `docs/TEST_METHODS.md`, `circuit/ENERGY_RESULTS.md`, and
`docs/compute/ground_up/meta_assumptions.md` against the actual netlists and `.log` files in
`circuit/`. It runs no new sims; it reads the ones already on disk. Every number cited below is
either a measured `.meas` value from a `.log`, a device count from a netlist, or flagged arithmetic
(OURS) on those numbers.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — read from a netlist / `.log` / measured value / a proved identity.
- **ANALOGY** — parallel structure, not identity.
- **OURS** — my inference/arithmetic from DIRECT, not independently measured.
- **SPECULATION** — untested, flagged.

---

## 0. The blunt one-line answer

**The fair fight was never fully fair — and the two headline "corrections" the corpus already
made are themselves mis-calibrated.** The meta-critic's flagship smoking gun (A2/§7.1: "the binary
baseline is ±1 V bipolar, so halve every N×") is **factually wrong for the transport direction**:
`binary_baseline.cir` is single-ended 0→1 V, and the 0.748 pJ/bit is already ½·1.5 pF·(1 V)². But
the fair fight **is** systematically biased — by four things the critic *did not* catch — and the
one experiment that would settle most of it, **`circuit/fair_binary.cir`, was already run and its
`.log` was never folded into the leaderboard or the verdict.** The honest numbers, already on disk:

| what the leaderboard says | what `fair_binary.log` already measured |
|---|---|
| champion **0.081 pJ/bit = 9.2× better than binary (0.748)** | single-ended binary, same wire: **0.512 pJ/bit** (full swing) → 6.3×; **0.216 pJ/bit** (matched low swing) → **2.7×** |
| low-swing **0.092 pJ/bit = 8.1× better than binary (0.748)** | matched low-swing binary **0.216 pJ/bit** → **2.3×** |
| diode gates **0.48–0.97×/bit (a win)** vs ±1 V binary (54 fJ NOT) | single-ended binary NOT = **6.9 fJ** → ternary **~5× worse** (cheapest toggle) to **~34× worse** (full-swing toggle) |

The win is real but roughly **3–4× smaller** than the headline, and the *compute* "win" is
**actually a loss** once you use the single-ended binary control that is already measured. This is
the valuable, honest answer the brief asked for.

---

## 1. Receiver choice — the diode/sense-amp split, and the *other* leaking default

**What the smoking gun was.** `meta_assumptions.md` §5–6 correctly identified that the *compute*
gate loss was measured with a **sense-amp level receiver** (2 clocked SAs comparing rail vs 0), and
that a **diode-direction receiver** (2 passive rectifiers, null = "neither rail charged" = a dead
zone) removes both the null meta-stability and the clocked receiver supply. That is DIRECT and right:
`diode_gates.cir`/`.log` measured null-idle ≈ 0 (1.5–3.8×10⁻¹⁹ J/75 ns) and E_rec = 0.

**What the critic missed — the sense-amp default is *still leaking* through the transport wins.**
Every transport "fair fight" after the naive cell uses the *sense-amp* level comparator as the
receiver, not the diode direction receiver:

- `ternary_fairfight.cir` — 2× PMOS-input SAs (`SA_A: rA vs 0`, `SA_B: rB vs 0`). **DIRECT (netlist).**
- `pam4.cir`, `pwm5.cir`, `pwm5_2d.cir` — 3+ comparators, all level compares vs 0 / ±THR. **DIRECT.**
- `lowswing_sweep.cir`, `lowswing_resonant.cir` — "SA-only receiver (2× sense amp reading the rails
  vs 0)" / "PMOS-input sense-amp receiver powered locally". **DIRECT (ENERGY_RESULTS.md).**

In all of these the diode rectifier is still present but only as the **energy-capture element** that
*charges* the rails; the **decision** (push/pull/null) is made by sense amps. So the champion's
"receiver is the invariant floor" (Law 1, 0.081 pJ/bit with receiver = ⅔ of the total) is a
**sense-amp** floor, not a receiver floor. The diode-direction receiver — which `diode_gates.log`
proved idles at ~0 with no clocked supply — was **never substituted into the transport champion.**
The one experiment that would test "is the receiver floor real or a sense-amp artifact" is the
one that was never run. **Calibration: DIRECT (netlists) for the leak; OURS for "it would change the
0.081 champion".**

**The second leaking default — the diode receiver's own measurement is the *cheapest* toggle.** See §4.

---

## 2. Normalization — is ÷log₂3 = 1.585 the right number?

**DIRECT facts.** `÷1.585` is the house normalization for "per bit of information" (`RadixEconomy.lean`:
one trit = log₂3 bits *for a uniform iid source*). It is applied to energy, area, and idle power;
delay is a constraint.

**Bias 2a — the conflation of four different "per X".** The brief names it: per-wire, per-state,
per-gate, per-joule-of-work are *not* the same axis, and ÷1.585 only addresses "per bit of
information carried by a uniform symbol". It does **not** address:

- **per wire** (1.585 bits/wire — a radix *namespace* fact, DIRECT, but *not* an energy fact);
- **per joule of work** (needs the energy-delay product; the champion is adiabatic and L-bound at
  48–100 Mtrit/s, 5–10× slower — `meta_assumptions.md` A1 is DIRECT on this and it is *not* in the headline);
- **per state / per threshold** (÷1.585 does not amortize the 2-threshold receiver tax).

**Bias 2b — the entropy double-count (the worst one, and un-caught).** The transport "win" is
`(E_push + E_pull + E_null)/3 ÷ 1.585` = 0.515 pJ/bit, and the *stronger* claim "Zipf/null-dominated
→ 0.32 pJ/bit → 57% better" divides a **null-heavy** energy average by **1.585**, which is the
entropy of a **uniform** source. You cannot have both: if the data is null-dominated its entropy per
symbol is **< log₂3**, so the correct divisor is the *actual* source entropy `H(source) < 1.585`, and
the per-bit energy is **higher** than 0.32. `ENERGY_RESULTS.md` CORRECTION 1's "31% better (uniform)"
and "57% better (Zipf)" both keep ÷1.585 while swapping the energy average between uniform and
null-heavy — a genuine conflation. **Calibration: OURS (the arithmetic), but the two numbers coexist
verbatim in ENERGY_RESULTS.md.**

**Bias 2c — binary is not held to the same entropy standard.** Binary's "per bit" is ÷1 (1 bit/symbol)
regardless of the data. A biased binary source also carries < 1 bit/symbol, but the corpus never
divides binary by its actual entropy. The normalization is applied asymmetrically. **OURS.**

**Verdict on 1.585:** ÷1.585 is the right number **only** for a uniform iid source and **only** for the
"per bit of information" axis. It systematically favors ternary whenever it is combined with a
null-heavy energy average (Bias 2b) or when binary's own non-uniformity is ignored (2c).

---

## 3. The binary baseline — the critic got the *reason* wrong, and there are bigger handicaps

### 3.1 Factual correction: the transport binary was already single-ended

`circuit/binary_baseline.cir` (DIRECT, read the netlist):

```
.param VDD = 1.0
Vin in 0 PULSE(0 {VDD} ...)      ; 0 -> 1 V, single-ended
M1 out in vdd vdd PMOS1 W=4u     ; inverter on a SINGLE 1 V rail
M2 out in 0 0 NMOS1 W=2u
Rw out load 500 ; CL load 0 1.5p
```

`ternary_fairfight.cir`'s own header states the binary reference explicitly: *"0.748 pJ/bit (measured
binary_baseline.cir: ecycle 1.496 pJ / 2 transitions, full 0↔1V swing on 1.5 pF at VDD=1V)."*

Therefore **`meta_assumptions.md` A2/§7.1 and `TERNARY_COMPUTE_VERDICT.md` #2 are wrong for
transport**: they claim "every N× vs binary was against ±1 V bipolar" and correct "9.2× → 4.6×".
The 9.2× is against **single-ended** 0.748 pJ/bit, so that specific "halve it" correction does not
exist. **Calibration: DIRECT (the netlist contradicts the critic).**

The ±1 V "share-the-rails" convention is real **only in the compute/gate direction** (`polar_gates.cir`,
`gate_energy.cir`, `diode_gates.cir` §2, `test_suite_spec.md` §3.1): there binary runs 0=−1 V / 1=+1 V
(a 2 V swing), which *is* generous to ternary. And even there the critic understates it: E ∝ V², so a
2 V swing is **4×** the 1 V swing's energy per toggle, not "~2×" — `fair_binary.log` confirms it
(single-ended NOT = 6.9 fJ vs ±1 V NOT = 54.0 fJ = **7.8×**, the extra from the bipolar driver's
channel loss on both edges).

### 3.2 The real, bigger, un-reported handicap: the *load* and the *swing*, already measured

`circuit/fair_binary.cir` + `fair_binary.log` (DIRECT — it exists, it ran, exit 0) re-baselines binary
single-ended **on the same wire as the ternary champion** (`rwire=100`, `cline=1p`, ternary's `WP=11u`
driver):

| binary control | measured (fair_binary.log) | the leaderboard's denominator |
|---|---|---|
| full swing 0→1 V, same wire | **0.512 pJ/bit** (`ebit_bt1 = 5.116e-13`) | 0.748 pJ/bit |
| low swing 0→0.65 V, same wire | **0.216 pJ/bit** (`ebit_bt2 = 2.162e-13`) | 0.748 pJ/bit |
| gate NOT / NAND / NOR, single-ended 0→1 V | **6.9 / 11.4 / 8.7 fJ** (`ept_1/2/3`) | 54.0 / 79.3 / 63.5 fJ (the ±1 V bipolar numbers) |

Two separate handicaps are hiding in the leaderboard's 0.748:

1. **Load mismatch.** `binary_baseline.cir` drives `CL = 1.5 pF` (it was sized to "the ternary cell's
   total capacitance"), but the ternary fair-fight line is `cline = 1 pF`. The same-wire single-ended
   binary costs 0.512, not 0.748 → every transport N× shrinks by **1.46×**.
2. **Swing mismatch — the big one.** The champions (0.092 low-swing, 0.081 low-swing×resonant) are
   low-swing schemes compared against **full-swing** binary. The low-swing lever is radix-agnostic —
   binary gets it too, and `fair_binary.log` BT2 shows a low-swing binary at 0.216 pJ/bit. So the
   "8.1× better" (0.092 vs 0.748) is really **2.3×** (0.092 vs 0.216), and the champion "9.2×" is
   really **2.7×** — and that is *before* giving binary the LC-recovery lever the champion also
   uses (giving binary the same two levers would shrink 2.7× further; unmeasured, SPECULATION).

**Calibration: the handicaps are DIRECT (measured, fair_binary.log); the "which binary is fair" choice
is OURS** (the corpus itself states both 1.5 pF and 1 pF as "the same wire" in different files —
`circuit/README.md` vs `fair_binary.cir`). The point for this audit is narrower and stronger: **the
honest single-ended control was measured and its result was never propagated into the verdict or the
leaderboard.**

### 3.3 The other binary asymmetries (real, but smaller / opposite)

- **Binary's receiver is not costed.** Binary's "receiver" is the next gate's input capacitance (already
  in the load); ternary pays 2 clocked SAs (0.05 pJ/trit). This is a *genuine* difference, not a bias —
  but it means the binary 0.512/0.216 already includes its (free) receiver while the ternary 0.081
  includes a ⅔-of-total receiver cost. Fair. **No bias.**
- **Activity/toggle mismatch (real bias, flatters ternary).** See §4: binary is quoted per-toggle
  (every bit toggles), ternary is quoted null-averaged (⅓ of symbols free).
- **Wire R (500 Ω vs 100 Ω).** For a full-swing CMOS charge the supply energy is C·V² independent of R
  (the ½C·V² is dissipated in R but the total from the supply is unchanged), so this biases *speed*,
  not the energy number. **No energy bias; a speed/EDP asymmetry (A1).**

---

## 4. The toggle convention — cheapest vs full-swing vs full-cycle/2

**The correct convention is already written down** (`test_suite_spec.md` §3.3/§5.1): a full cycle
A→B→A, per-toggle = full-cycle/2, cover the **full-swing +1↔−1** (most expensive) and the
null↔±1 (cheapest, flagged "generous"), headline = uniform average. **The actual measurements predate
and violate it:**

- **Transport** (`ENERGY_RESULTS.md`): "one activation **from rest** per symbol" — push = null→+1,
  pull = null→−1, null = stay. This **never measures the +1↔−1 full-swing toggle**, which in a real
  iid stream occurs 2/9 of the time and costs ~2× a half-swing. The PAM-4 section *did* compute the
  stream correction and it made PAM-4 worse (0.40→0.47) — but that correction was **not** applied to
  the ternary champion or to binary. **Flatters ternary.**
- **`diode_gates.cir` (compute)** is explicit: *"Toggle = cheapest ternary toggle (null↔+1) — generous
  to ternary."* The headline "0.48–0.97×/bit win" is built on it. The doc's own TODO #2 admits a
  +1↔−1 toggle moves the ratios to "~0.97–1.94× (tie to ~2× worse)" — but that admission is **not**
  in the verdict's headline. `fair_binary.log` measured the actual full-swing ternary diode toggle:
  **dd_not 368.7 fJ** (`ept_4 = 3.687e-13`), **6.8×** the 54.2 fJ cheapest toggle — not the "~2×" the
  `fair_binary.cir` header itself claims. **Flatters ternary.**

**Which is right:** full-cycle/2 over the transition matrix, at the *same* activity for both sides. The
two conventions actually in use — "from rest" and "cheapest toggle" — both flatter ternary by up to
~2× on the toggle axis, and the full-swing number that would correct them is measured but unused.

**The symmetric activity bias (the one that flips the transport verdict).** Binary's 0.748 pJ/bit is
the energy of *one* 0→1 edge (per-toggle, 100% activity — every bit toggles). Ternary's 0.515 pJ/bit
is a *null-averaged* figure (⅓ of symbols are free). The honest matched-activity comparison:

- binary, random data (its "null" is the non-toggling bit): **~0.375 pJ/bit** (½·0.748) — the corpus
  never quotes this;
- ternary, iid stream (including +1↔−1 flips): **~0.63 pJ/bit** — the corpus never computes this.

At matched activity the "31% better" (0.515 vs 0.748) becomes a **loss or near-tie** (~0.63 vs ~0.375).
**Calibration: OURS — my arithmetic on the measured edge energies; the exact stream-average should be
re-measured, but the *direction* (the two sides use different activity conventions) is DIRECT from the
netlists.**

---

## 5. LEVEL=1 models — what it flatters, and in which direction

`LEVEL=1` in this corpus means **no subthreshold leakage, no device mismatch/offset, no body diodes.**
All three flatter **ternary**, not binary, because ternary's extra cost is exactly where these live:

1. **No subthreshold leakage → flatters the null and the dead zone.** The null-idle "≈0" (diode_gates,
   lowswing) is a hard-cutoff artifact: `N_HI`/`P_HI` with VTO=1.4 are *exactly* off below threshold.
   Real elevated-Vt devices leak, and the 0.4 V dead-zone margin sits near the process floor. The
   "null is free" is `0.05 pJ relative-to-±1`, not a thermodynamic fact — `meta_assumptions.md` §3.3 is
   DIRECT and correct here. **Flatters ternary.**
2. **No subthreshold leakage → flatters the low-swing VTENG pass.** The wide low-Vt drivers
   (W=400–1600 µm at Vov≈0.1 V) would leak heavily in silicon; LEVEL=1 makes them free. The
   lowswing sweep itself flags this ("below ~0.1 V overdrive the wide low-VT drivers are flattered").
   **Flatters ternary's low-swing champions.**
3. **No mismatch/offset → flatters the 2-threshold receiver and the low-swing resolution.** The SA
   resolves at rail 22 mV / ±4 mV baseline; real σ≈5–20 mV pushes the practical floor from 0.092 to
   0.22–0.35 pJ/bit (the corpus's own estimate). Ternary is flattered **more** than binary because a
   2-threshold receiver has 2× the offset budget (`test_suite_spec.md` §7 rule 8). **Flatters ternary.**
4. **No body diode → flatters the bipolar ±1 V push-pull driver.** The fair-fight itself measured that
   adding a real PMOS body diode clamps the pull phase and dumps ~2.9 pJ ("real-process fix" needed).
   Binary's single-ended driver has no such bipolar-body issue. **Flatters ternary's ±1 V driver.**

**Net:** LEVEL=1 flatters **ternary** across the board (its null, its bipolar driver, its 2-threshold
receiver, its low-swing low-Vt drivers are precisely the objects LEVEL=1 idealizes). Binary, being
single-ended and single-threshold, is barely affected. Every "N× better" is therefore an **upper
bound** for ternary, and the champion (0.081) is the most-flattered point in the survey (low-swing +
resonant + sense-amp receiver + LEVEL=1 all stack). **Calibration: each sub-point is DIRECT (the
corpus's own caveats); the "flatters ternary *more*" ranking is OURS.**

---

## 6. Measurement-integrity failures the audits did not catch

These are not biases in a technique; they are two self-contradictions in the corpus itself, and they
matter because load-bearing conclusions sit on each:

1. **Two different values for the same diode-gate measurement.** `diode_gates.md`/`.log` say
   `dd_not = 54.2 fJ/toggle` (tie with binary NOT). `meta_mishandled.md` §3.3 says
   "`dd_not ≈ 1.03 pJ/toggle` … still ≈20× worse per toggle", citing the same `diode_gates.log`.
   The log reads `ept_4 = 5.417e-14` = 54.2 fJ. **meta_mishandled.md's 1.03 pJ is wrong (19× off).**
   The "compute is still 20× worse" line and the "compute is 0.48–0.97× (a win)" line **cannot both
   stand**, and only one is in the log. **DIRECT (log vs the two docs).**
2. **`fair_binary.cir`'s own header contradicts its own log.** The header claims Section 3 (full-swing
   ternary diode gates) is "~108 fJ … about 2× the null↔+1 toggle"; its log measures
   `ept_4/5/6 = 368.7 / 433.8 / 410.8 fJ` — **6.8×**, not 2× (the header assumed swing scales linearly;
   it scales as V²). The honest full-swing toggle is ~7× the cheapest, not ~2×. **DIRECT.**

---

## 7. Corrected measurement protocol

Do these before another "N× vs binary" is written anywhere:

1. **Retire the 0.748 pJ/bit denominator; use the measured same-wire single-ended binary.**
   Transport: 0.512 pJ/bit (full swing) and **0.216 pJ/bit (low swing)** from `fair_binary.log`.
   Low-swing champions must compare against the low-swing binary (0.216), not full-swing 0.748 —
   **the low-swing lever is radix-agnostic and must be granted to binary symmetrically.**
2. **Fix the toggle convention to full-cycle/2 over the transition matrix, both sides.**
   Kill "from rest" (transport) and "cheapest toggle" (diode_gates) as headline conventions; report
   the +1↔−1 full-swing toggle (368.7 fJ for dd_not, already measured) and the iid stream average.
3. **Match activity on both sides.** Either both per-toggle (ternary 0.758 vs binary 0.748 — dead heat)
   or both activity-averaged (ternary ~0.63 vs binary ~0.375 — ternary loses). Never ternary-averaged
   vs binary-per-toggle.
4. **Fix ÷log₂3 to ÷H(source).** Uniform source → ÷1.585 with the uniform energy average; null-heavy
   source → ÷(actual entropy < 1.585). Do not divide a Zipf energy average by 1.585. Give binary the
   same entropy correction.
5. **Substitute the diode-direction receiver into the transport champion.** The "receiver is the
   floor" (0.081) thesis is sense-amp-specific; `diode_gates.log` proves a passive receiver idles at ~0.
   Re-run `lowswing_resonant.cir` with `dd_recv` in place of the 2× SA before asserting a receiver floor.
6. **Re-measure the champion with mismatch + leakage + body diodes on.** The corpus's own estimate
   moves the floor 0.092 → 0.22–0.35 pJ/bit. The headline must carry the range, not the LEVEL=1 point.
7. **Reconcile the two contradictions in §6** (dd_not 54.2 fJ vs 1.03 pJ; the "~2×" vs "6.8×"
   full-swing factor) before the compute verdict is quoted again.
8. **State an energy-delay-product target before any "win".** The champion is 5–10× slower; "9.2×" is
   energy-only. (This is A1, already DIRECT, still not in the headline.)

---

## 8. Calibration ledger (this file's own claims)

| claim | calibration |
|---|---|
| `binary_baseline.cir` is single-ended 0→1 V (transport binary = 0.748 pJ/bit) | **DIRECT** — netlist + fairfight header |
| `meta_assumptions.md` A2/§7.1 "binary is ±1 V bipolar" is wrong for transport | **DIRECT** — contradiction between the netlist and the claim |
| ±1 V "share-the-rails" binary is real but *only* in the compute/gate direction | **DIRECT** — `polar_gates.cir`, `diode_gates.cir` §2, `test_suite_spec.md` §3.1 |
| ±1 V bipolar gate binary is ~4× (measured 7.8×) the single-ended gate energy | **DIRECT** — 54.0 vs 6.9 fJ (`diode_gates.log` vs `fair_binary.log`) |
| same-wire single-ended binary = 0.512 (full) / 0.216 (low) pJ/bit | **DIRECT** — `fair_binary.log` `ebit_bt1/bt2` |
| low-swing champions compared against full-swing binary (a swing mismatch) | **DIRECT** — `ENERGY_RESULTS.md` "8.1× vs 0.748" vs `fair_binary.log` BT2 0.216 |
| transport uses "from rest", diode_gates uses "cheapest toggle" | **DIRECT** — `ENERGY_RESULTS.md`, `diode_gates.cir` header |
| full-swing ternary diode toggle = 368.7 fJ (6.8× the cheapest, not ~2×) | **DIRECT** — `fair_binary.log` `ept_4` vs its own header |
| ÷log₂3 double-counts uniform entropy with null-heavy energy | **OURS** — arithmetic on two coexisting claims in `ENERGY_RESULTS.md` |
| matched-activity binary ≈0.375 / ternary ≈0.63 → the 31% flips | **OURS** — my arithmetic; re-measure to confirm |
| LEVEL=1 flatters ternary more than binary | **OURS** — the sub-facts are the corpus's own DIRECT caveats |
| `meta_mishandled.md` dd_not "1.03 pJ" is wrong (log = 54.2 fJ) | **DIRECT** — `diode_gates.log` `ept_4` |
| the transport 9.2× is *not* flattered by a bipolar binary baseline | **DIRECT** — it is flattered by load/swing/LEVEL=1/toggle instead |

---

## TODO / not covered / caveats

1. **I ran no sims.** Every number is read from the existing `.cir`/`.log`/`.md`. My "matched-activity"
   and "stream-average" numbers (§4) are arithmetic on the measured edge energies, not new measurements
   — they need a re-run to be quoted as DIRECT.
2. **"Which binary load is fair" is not settled by this file.** `binary_baseline.cir` (1.5 pF) and
   `fair_binary.cir` (1 pF) are *both* in the corpus, each claiming "the same wire". The leaderboard
   uses one, the control the other. A single stated convention (line cap = 1 pF, or total cell cap
   = 1.5 pF) must be picked and held. I flag the discrepancy but do not adjudicate it.
3. **`fair_binary.log` is not yet integrated into any `.md`.** It appears to be the response to
   `meta_assumptions.md` A2 that was measured but never propagated. If it postdates the verdicts, the
   verdicts are stale; if it predates them, they ignored it. Either way it is the single highest-value
   file to fold in. (I did not check git history for the ordering.)
4. **The champion's "matched binary with both levers" is unmeasured.** Giving binary the LC-recovery
   lever the 0.081 champion uses would shrink the 2.7× further; I did not compute it (SPECULATION).
5. **The mod-3 sum and the 3-input balanced adder remain the unmeasured compute cells** (`diode_gates.md`
   §7, `test_suite_spec.md` TODO). The "compute is a tunable trade" conclusion rests on NOT/NAND/NOR/
   MIN/MAX only, and on a toggle convention this file shows was flattering.
6. **I did not audit the yosys/area direction** (the "2–3× device count" claims) beyond the diode-gate
   counts already in the netlist — the "area vs count" risk (`test_suite_spec.md` §4.5) is out of scope
   here but is a live bias of the same family.
7. **This file's own blind spot:** like `meta_assumptions.md`, it is a reading pass. The one claim that
   could still be wrong is my reading of which netlist each `.log` corresponds to (the `.log`s have no
   embedded netlist checksum). I matched `diode_gates.log`/`fair_binary.log`/`binary_ref.log` by their
   `.meas` names and values; a re-run with `--netlist` provenance would close that.

*This file invents no numbers and runs no netlists; it is a calibration pass over the on-disk netlists
and logs. Its core deliverable: the fair fight was never fully fair, the "9.2×" is really ~2.7–6.3×,
the compute "win" is really a loss against the already-measured single-ended binary, and the honest
control that proves all of it (`circuit/fair_binary.log`) is sitting unused.*
