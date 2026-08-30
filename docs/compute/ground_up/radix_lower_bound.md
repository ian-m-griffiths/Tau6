# Radix-based lower bound for ternary power — two models, and where the measured cost exceeds it

**2026-08-29 — Tau Architecture.** This file derives the *radix-based* lower bound for
ternary energy-per-bit under **two distinct device models**, then decomposes the measured
gate gap (3.4–33× worse than binary) into its multiplicative ("capital-Π") factors and
ranks which of them a **native 3-state device** would remove.

It is the *companion* to `meta_math.md` (which stresses the theorem) and
`meta_transistor.md` (which corrects the device survey). This file does the one job neither
does: **states the bound under each model side-by-side, and locates the measured cost on
that scale.**

**Calibration legend** (house standard):

- **DIRECT** — measured/proved in-repo, or a textbook arithmetic identity.
- **ANALOGY** — structural resemblance, not identity.
- **OURS** — our inference/arithmetic from DIRECT, not independently measured.
- **SPECULATION** — untested hypothesis, or an order-of-magnitude estimate with no cited source.

---

## 0. The blunt verdict, first

**The two models differ by exactly a factor of 2, and the measured gates are ~5–53× above
the native-device floor — but almost none of that excess is the "2-threshold tax" the
native-device bet targets.** Four facts, all arithmetic on measured numbers:

1. **Binary-substrate bound = 1.26×.** `2 thresholds / log₂3 bits = 2·ln2/ln3 = 1.262×`
   binary per bit. **[DIRECT — `ThresholdLowerBound.lean`, proved.]**
2. **Native-device bound = 0.63×.** `1 measurement / log₂3 bits = 0.631×` binary per bit —
   i.e. ternary is **37% cheaper per bit** *iff* the one measurement costs like a binary
   transistor's. **[DIRECT — arithmetic; the "one measurement" premise is the model.]**
3. **The two bounds are exactly 2× apart** (`1.262 / 0.631 = 2.000`): the entire
   disagreement is **2 measurements per symbol vs 1**, nothing else. The `1/log₂b` native
   floor is also **monotone decreasing in `b`** — so the native-device argument, taken
   literally, says "highest radix you can fabricate," not "radix 3." **[DIRECT.]**
4. **The measured gap is dominated by implementation, not the floor.** The diode-direction
   gate (the source of "3.4–33×") factorizes almost exactly as
   `33.5× ≈ 7.8× (swing², bipolar 2 V vs single-ended 1 V) × 6.8× (dead-zone crowbar) ÷ 1.585 (radix economy)`.
   The 2-threshold tax (2.54×) is a *third-order* term: the floor itself is only
   **1.26/33.5 ≈ 3.8% of the full-swing gap**. **[DIRECT — arithmetic on `fair_binary.log`,
   `gate_energy.log`.]**

---

## 1. The theoretical lower bound under each model

The general radix-based cost-per-bit is one function:

```
C(b) = m(b) / log₂b            (relative to binary, where C(2) = 1)
```

`log₂b` = information per symbol (bits); `m(b)` = number of *native measurements* needed to
resolve one symbol. The two models differ **only** in `m(b)`.

### Model 1 — binary substrate (2-level MOSFET reading 3 ordered levels)

A 2-level device can answer at most one yes/no question per measurement. To name one of `b`
states you need `⌈log₂b⌉` binary discriminations (a flash/thermometer decoder pays `b−1`;
for `b=3` these coincide: `⌈log₂3⌉ = b−1 = 2`). So:

```
m(3) = 2      →      C(3) = 2 / log₂3 = 2·ln2/ln3 = 1.262×  per bit
```

This is exactly what `ThresholdLowerBound.lean` prices (`(b−1)/ln b`, monotone, min at
`b=2`). **[DIRECT — proved; `meta_math.md` §1.2–1.3 shows the `b−1` flash model coincides
with the honest `⌈log₂b⌉` bound at b=2 vs b=3, and overcounts for b≥4.]**

### Model 2 — native 3-state device (AAT / RTD / SET: one device, one measurement)

A device whose *intrinsic* degree of freedom resolves 3 states in a **single** measurement
(anti-ambipolar transfer hump, NDR branch, Coulomb-ladder charge) pays:

```
m(3) = 1      →      C(3) = 1 / log₂3 = 0.631×  per bit    (37% cheaper)
```

*iff* that one measurement costs like one binary transistor's threshold. **[DIRECT as
arithmetic; the `m(3)=1` premise is the device claim — `meta_transistor.md` §4.1 lists the
device families, all non-fabricable at VLSI.]**

### The relationship, and the "why stop at 3?" caveat

| model | `m(3)` | C(3) | verdict |
|---|---|---|---|
| binary substrate (2 thresholds) | 2 | **1.262×** | ternary 26% *worse* per bit |
| native 3-state (1 measurement) | 1 | **0.631×** | ternary 37% *cheaper* per bit |
| ratio | 2× | 2× | the whole disagreement |

**`C(b) = 1/log₂b` has no interior minimum** — it falls monotonically with `b`. So the
native-device model does **not** single out `b=3`; it says "maximize the radix." The `b=3`
stop is a **device-physics constraint** (only 3-state mechanisms exist — AAT/AFE/RFET/SET/RTD),
not a consequence of the math. The measured transport family already shows this: PAM-4
(`b=4`, 0.401 pJ/bit) beat ternary (`b=3`, 0.515 pJ/bit) by 22% in `pam4.cir`.
**[DIRECT — the monotonicity is arithmetic; the PAM-4 number is measured.]**

---

## 2. The gap analysis — Π-factor decomposition of 3.4–33×

The "3.4–33×" is `fair_binary.md` §4: the diode-direction gate vs **single-ended 0→1 V
binary**, per bit (÷1.585). Cheapest toggle (null↔+1): **3.4× (dd_nand) – 4.9× (dd_not)**.
Full-swing toggle (+1↔−1): **24× (dd_nand) – 33.5× (dd_not)**.

### 2.1 The closed form (dd_not, the extremes)

Per bit = per-toggle ÷ 1.585, so the radix-economy dividend `1/1.585 = 0.63×` is *already
inside* the measured number. The remaining per-toggle multiplier factorizes cleanly:

```
dd_not cheapest  (54.2 fJ/toggle):   4.93×  =  7.8×  ÷ 1.585          (swing² only; no crowbar)
dd_not full-swing (368.7 fJ/toggle): 33.5×  =  7.8×  × 6.8× ÷ 1.585   (swing² × dead-zone crowbar)
```

The two factors, both measured:

- **7.8× = swing².** The diode gate runs ±1 V (2 V domain); the fair binary runs 0→1 V
  (1 V domain). `fair_binary.log` Finding 3 measured this on the *binary* control: binary
  NOT drops 54.0 → 6.94 fJ (7.8×) when re-based from ±1 V to 0→1 V. `fair_binary.md`
  decomposes it as **~4× pure V²** × **~1.95× swing-crowbar** (the ±1 V inverter sweeps a
  ~1.2 V-wide both-devices-on window vs ~0.2 V at 1 V). **[DIRECT — 54.0/6.94 = 7.78; the
  4×/1.95× split is OURS (the numbers are DIRECT, the attribution is `fair_binary.md`'s).]**
- **6.8× = dead-zone crowbar.** The elevated-|Vt| output stage has a thin dead band (rails
  reach only ±0.57/±0.73 V), so the +1↔−1 toggle sweeps through a window where `P_HI` and
  `N_HI` conduct together. Measured: 368.7 vs 54.2 fJ = 6.80× — the cheapest-toggle
  convention had been hiding it. **[DIRECT — `fair_binary.log` `ept_4` vs the null↔+1
  toggle; `fair_binary.md` §4 mechanism 2.]**

Check: `7.8 × 6.8 = 53.04`; `53.04 / 1.585 = 33.5` ✓. `7.8 / 1.585 = 4.93` ✓.

### 2.2 The full factor ledger (all seven named factors, across all three gate families)

The two big factors above are the *diode-gate* story. The complete list of multiplicative
terms the task names, each with its measured number, where it bites, and calibration:

| # | Π factor | measured size | where it is measured | calibration |
|---|---|---|---|---|
| 0 | **radix economy** `1/log₂3` | **0.63×** (a *reduction*) | every per-bit ÷1.585 | DIRECT — `RadixEconomy.lean` |
| 1 | **swing² / split-supply** | **4× (pure V²); 7.8× incl. swing-crowbar** | `fair_binary.log` Finding 3 (54.0→6.94 fJ); `meta_transistor.md` §2.3 (balanced polar = 2× voltage domain) | DIRECT (the 7.8×); OURS (the 4×/1.95× split) |
| 2 | **dead-zone crowbar** | **6.8×** | `fair_binary.log` `ept_4` 368.7 vs 54.2 fJ | DIRECT |
| 3 | **receiver / measurement** | **2.54×** (2 SAs vs 1) | `gate_energy.md` 61.87 vs 24.35 fJ | DIRECT |
| 4 | **driver channel loss** | **×2.14** (+114%) | `ENERGY_RESULTS.md` CORRECTION 1 (0.61 pJ hidden on the ideal-source cell) | DIRECT (transport cell; folded into gate E_gate, not separately measured for gates) |
| 5 | **diode drop** | `V_d ≈ 0.3–0.7 V ≥ 1 V swing`; pins demux rail at **~15% of line swing** | `meta_transistor.md` §2.2; `lowswing_sweep` (rail ≈ 0.15·line) | DIRECT (physics + the 15% pinning); not isolated as a standalone energy multiplier |
| 6 | **2-wire encoding overhead** | **+26% wires** (0.79 bits/wire) | `gate_area.md` (1/0.792 = 1.26); `gate_energy.md` §3 ("pays binary's wire cost twice") | DIRECT |
| 7 | **level-vs-direction code** | **×1.00** (no saving) | `meta_math.md` §4 — direction relabels the 2 decisions, doesn't remove one | DIRECT (the *count* is unchanged) |

**Note on factor 7.** The "direction via diode" re-encoding is the *escape that isn't*: it
converts 2 level-thresholds into 1 sign test + 1 null/amplitude test — still 2 decisions —
and *adds* a diode drop. It changes *where* the margin penalty lives (balanced polar moves
it from halved per-level margin to the split supply, `meta_transistor.md` §2.3) but not
*whether* there are 2 decisions. So it contributes **×1.00** to the product. **[DIRECT —
`meta_math.md` §4; the realized 2-sense-amp diode receiver measured 2.54×.]**

### 2.3 Which factor is biggest, and artifact vs irreducible

**Biggest single factor: the swing² (×4 pure, ×7.8 measured).** Second: the **dead-zone
crowbar (×6.8)** — the biggest *ternary-specific* factor. Together they are ~53× of the
53× per-toggle loss. The receiver/measurement tax (2.54×) and driver channel loss (2.14×)
are secondary; the diode drop and the 2-wire overhead are material in the *other* gate
families (polar native, emulation) rather than in the diode gate's two big terms.

**The "genuinely irreducible vs binary-substrate-artifact" split is model-dependent:**

| against… | irreducible floor | measured gap above the floor |
|---|---|---|
| **Model 1** (binary substrate) | **1.26×** (the `⌈log₂3⌉=2` decision floor) | 3.4–33.5 ÷ 1.26 = **2.7–26.6×** of implementation artifact |
| **Model 2** (native device) | **0.63× — a win, not a cost** (no irreducible penalty) | 3.4–33.5 ÷ 0.63 = **5.4–53×** of artifact |

Under **Model 1** the only "genuinely irreducible" content is the 1.26× (`3 ≠ 2^k` wastes
`2 − log₂3 = 0.415` bits/symbol). Under **Model 2** there is **no irreducible penalty at
all** — the "irreducible" content is the 0.63× *win* (radix density), and every bit of the
3.4–33× above it is binary-substrate artifact. **In both models the floor is a small
fraction of the measured gap** (1.26× is 3.8% of 33.5×), which is the decisive point: **the
gap is not about the radix bound; it is about swing, crowbar, and receiver implementation,
which the bound says nothing about.**

---

## 3. Why doesn't 3.4–33× match the 0.63× native-device floor?

The 0.63× floor assumes a device that (a) resolves 3 states in **one** measurement, (b) does
so at **one binary-threshold's cost**, (c) on a **single supply**, with (d) **no dead-zone
traversal** and (e) **no separate receiver/driver** to re-encode the symbol. Every factor
below is a gap between that ideal and the measured gate. Ranked by size, with the
"would a native device remove it?" mark:

| rank | factor between 0.63× and 3.4–33× | size | native device removes it? |
|---|---|---|---|
| 1 | **swing² / split supply** — balanced polar `{−V,0,+V}` needs a 2 V domain vs binary's 1 V | 4–7.8× | **Only if unipolar** — an AAT runs `{0,Vdd/2,Vdd}` (single supply) and removes the 4×, but *re-introduces* mid-level shoot-through (`meta_transistor.md` §3.2). Net: **partial / traded, not removed.** SPECULATION. |
| 2 | **dead-zone crowbar** — full-swing +1↔−1 sweeps the both-devices-on window | 6.8× | **Claimed, unproven** — the AAT's mid level is a transfer-curve *peak* in a dead zone (zero shoot-through), but `meta_transistor.md` §6 item 1 flags "dead zone / no shoot-through" as OURS/SPECULATION until the primary paper is read. |
| 3 | **2-threshold receiver** — 2 sense amps vs binary's 0 (or 1) | 2.54× | **Yes** — this is the one factor the native-device bet directly targets: 1 intrinsic measurement replaces 2 comparators. But it is only ~2.5× of the ~53×. |
| 4 | **driver channel loss** — `(Vrail−Vline)·I` during assert | 2.14× | **No / transformed** — any restoring driver pays an I²R or `(Vrail−Vline)·I` term; a native device changes the driver topology, not the existence of the loss. SPECULATION. |
| 5 | **diode drop** — fixed `V_d` conduction, ≥ the 1 V swing; pins rail at 15% of swing | (1.2–2×, not isolated) | **Yes** — it is a receiver-topology artifact (diode rectification), not a radix property. A native device that doesn't rectify through a diode drops it. |
| 6 | **2-wire encoding** — 3 states on 2 boolean wires = 0.79 bits/wire, +26% wires | 1.26× (area) | **Yes** — a native device stores/transmits the trit on one device/wire, restoring 1.585 bits/symbol without the second wire. |
| 7 | **meta-stable null** — null sits at the SA threshold, draws continuous current (MAX/SUM 2.3–3.1× MIN) | 2.3–3.1× (receiver) | **Yes** — a native device's mid state is a real third state (transfer peak / polarization minimum), not a saddle point on a threshold. |
| 8 | **LEVEL=1 flattery** — mismatch/leakage/body-diode *would* make ternary worse (floor 0.092→0.22–0.35 pJ/bit) | a *flattery*, not a factor | **No — swapped, not removed** — native devices trade CMOS offset for their *own* variability (AFE endurance, 2D-material uniformity, cryo). SPECULATION. |

**Net reading of the table.** The 0.63× floor is out of reach not because the "2-threshold
tax" is large — it is ~2.5× — but because **the two dominant factors (swing² and crowbar,
together ~53×) are *not* the 2-threshold tax**, and a native device removes them only
conditionally (unipolar → re-imports shoot-through; dead-zone-free → unproven). **The
native-device bet addresses the wrong term**: it would shave the 2.5× receiver tax and the
1.26× 2-wire overhead, leaving the ~50× of swing + crowbar standing — and even *those* two
are only partially in a device's power to remove. **[OURS — synthesis of the DIRECT
factors above; the per-factor "removes it?" marks are DIRECT where the device physics is
cited, SPECULATION where flagged.]**

---

## 4. Calibration ledger

| claim | calibration |
|---|---|
| `C(b) = m(b)/log₂b`; binary-substrate `m=⌈log₂b⌉`, native `m=1` | DIRECT — arithmetic; the `m` choices are the two models |
| 1.26× = 2/log₂3 = 2·ln2/ln3 | DIRECT — `ThresholdLowerBound.lean` |
| 0.63× = 1/log₂3 | DIRECT — arithmetic; "one measurement costs like a binary threshold" is the MODEL premise |
| the two bounds are 2× apart | DIRECT — 1.262/0.631 = 2.000 |
| native floor `1/log₂b` is monotone in `b` (no interior optimum) | DIRECT — arithmetic; PAM-4 (b=4) beating ternary (b=3) measured in `pam4.log` |
| diode gate 3.4–4.9× (cheapest) / 24–33.5× (full-swing) per bit | DIRECT — `fair_binary.md` §4 |
| 7.8× swing factor (binary 54.0→6.94 fJ on re-baseline) | DIRECT — `fair_binary.log` Finding 3 |
| 6.8× dead-zone crowbar (368.7 vs 54.2 fJ) | DIRECT — `fair_binary.log` `ept_4` |
| `33.5 = 7.8×6.8÷1.585`, `4.93 = 7.8÷1.585` | DIRECT — arithmetic (verified to 3 s.f.) |
| 2.54× receiver tax | DIRECT — `gate_energy.md` 61.87/24.35 fJ |
| +114% channel loss | DIRECT — `ENERGY_RESULTS.md` CORRECTION 1 |
| +26% wire waste (0.79 bits/wire) | DIRECT — `gate_area.md` |
| level/direction re-encoding does not reduce the decision count below 2 | DIRECT — `meta_math.md` §4; 2-sense-amp diode receiver measured 2.54× |
| floor is 3.8% of the full-swing gap (1.26/33.5) | DIRECT — arithmetic |
| "swing² and crowbar, not the 2-threshold tax, dominate the gap" | OURS — arithmetic on DIRECT factors; the single most important conclusion |
| "native device removes only the 2.5× receiver + 1.26× 2-wire, not the ~50× swing+crowbar" | OURS — synthesis; the per-factor removal marks are SPECULATION where flagged |

---

## TODO / not covered / caveats

1. **No new measurement; no new Lean work.** Every number is read from `fair_binary.log`,
   `gate_energy.md`, `polar_gates.md`, `gate_area.md`, `ENERGY_RESULTS.md`, and the Lean
   ledger. The two "closed forms" (§2.1) are arithmetic on measured edge energies, not new
   simulations.
2. **The 7.8× swing factor bundles three things I did not separate.** Pure V² (4×), the
   swing-induced crowbar (~1.95×), and both-edge channel loss are folded together in the
   measured 54.0→6.94 fJ. A clean per-factor split needs a dedicated sweep (e.g. a NOT
   gate stepped over swing with crowbar-window width recorded). Until then, "swing² = 4×"
   is the physics and "7.8×" is the *measured bundle* — do not quote one as the other.
3. **The "native device removes X" column is the least-calibrated part of this file.** It
   leans on `meta_transistor.md` §1.1 (AAT dead-zone claim) and §3.2 (unipolar STI
   shoot-through), both of which that file already flags as SPECULATION-until-the-primary-
   paper-is-read. The one claim that can move the whole §3 ranking — "does the AAT's mid
   level sit in a zero-shoot-through dead zone?" — is still unverified.
4. **The dead-zone crowbar (6.8×) is measured on the *diode* gate only.** Whether the
   polar/native single-wire gates (`polar_gates.md`) have the same full-swing factor is
   unmeasured — `polar_gates.md` deliberately measured only the cheapest null↔+1 toggle.
   Their 4.9–14.3× per-bit losses are therefore **understated** by the same convention
   `fair_binary.md` §4 exposes; the honest full-swing polar gate is plausibly ~2–7× deeper.
   **[SPECULATION — inferred from the diode-gate 6.8×, not measured for polar.]**
5. **The "3.4–33×" is one family (diode gates).** The other two gate families bracket it:
   the 2-wire static emulation (`gate_energy.md`) is only **1.2–3.1× worse**, and the
   native single-wire (`polar_gates.md`) is **4.9–14.3× worse** (cheapest toggle). The
   Π-decomposition in §2.1 is exact *for the diode gate*; the factor *ledger* (§2.2) is
   what generalizes. A unified "one number" per gate family is out of scope here.
6. **`÷1.585` is the uniform-source entropy, not the actual source entropy.**
   `audit_measurement.md` Bias 2b: dividing a null-heavy energy average by `log₂3` double-
   counts. Every per-bit number here inherits that convention (it is the corpus standard),
   so the *ratios* are right but the *absolute* per-bit energies assume uniform trits.
7. **The native-device floor has no error bar.** "1 measurement costs like 1 binary
   threshold" is the entire model. A native device that costs *more* than one binary
   threshold per read (e.g. a cryogenic SET read, an AFE write/read cycle) sits somewhere
   between 0.63× and 1.26× — and no number for that exists in the corpus, because none of
   the native devices is simulatable (`meta_transistor.md` TODO 8). The 0.63× is therefore
   a *model bound*, not a *measured bound*.
8. **Transport is not decomposed here.** This file is about the *compute* gap (the 3.4–33×).
   The transport champion (0.081 pJ/bit, corrected to 2.67–6.3× vs fair binary by
   `fair_binary.md` §3) has its own Π (low-swing lever, LC recovery, receiver floor) and is
   deliberately out of scope; `audit_measurement.md` §1/§5 covers its biases.
9. **Adiabatic/reversible is untouched.** Like `meta_math.md`, this file's "power" bound is
   about irreversible per-toggle energy; the Landauer/reversible regime (where the radix
   bound is a *different* statement) is not analyzed here.

---

## Sources

- `proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean` — `(b−1)/ln b` monotone; the 1.26×.
- `proofs/lean-src/hexagon/Hexagon/RadixEconomy.lean` — `b/ln b` min at `e`; `3/ln3 < 2/ln2`.
- `docs/compute/ground_up/meta_math.md` — §1.2–1.3 (the `⌈log₂b⌉` correction), §2 (1.26×
  representation-independent), §4 (direction ≠ free).
- `docs/compute/ground_up/meta_transistor.md` — §1.1 (AAT), §2.2–2.3 (diode receiver, split
  supply), §3.2 (unipolar STI shoot-through), §4.1 (2-threshold tax is code, not radix).
- `docs/compute/ground_up/audit_measurement.md` — §2 (entropy), §3–4 (toggle/activity), §5
  (LEVEL=1 flattery).
- `docs/compute/ground_up/fair_binary.md` — §3 (transport re-baseline), §4 (diode gate
  3.4–4.9× / 24–33×), Finding 3 (7.8× swing).
- `circuit/ENERGY_RESULTS.md` — CORRECTION 1 (+114% channel loss), CORRECTION 2 (adiabatic),
  PAM-4 (0.401 pJ/bit), low-swing (0.092), low-swing×resonant (0.081).
- `docs/compute/gate_energy.md` — the 2.54× receiver tax, 2-wire emulation losses.
- `docs/compute/polar_gates.md` — native single-wire losses (4.9–14.3×), meta-stable null.
- `docs/compute/gate_area.md` — the 2.0–4.3× area ratio, +26% wire waste.
