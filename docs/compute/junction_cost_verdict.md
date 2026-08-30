# Junction Cost Verdict — is single-channel-activation ternary actually ≤ binary?

**2026-08-29.** The adversarial review of the principal's claim. This file does one job:
take the claim verbatim, split it into its three load-bearing sub-claims, and settle each
against the *measured and proved* ground truth (`FINAL_VERDICT.md`, `ENERGY_LAWS.md`,
`fair_binary.md`, `lowswing_diode.md`, `gate_energy.md`, `radix_lower_bound.md`,
`meta_math.md`, `transport.py`, `fairfight.py`, and the Lean proofs). No flattery; every
number is calibrated.

**The claim (verbatim-ish):** *"if we wire the P and the N in the middle it will only ever
go in one channel because they require opposite polarity… we get 2 bits but only ever have
to activate one… most of the things we do to get ternary is just not activate most
channels, and that should be a cost saving… this should not be more expensive than binary."*

---

## 0. The verdict in one line

**The claim is half-true.** The half that is true is a *transport/static-power* fact: a
one-hot (single-rail-active) encoding makes the null free and the wire cheap. The half that
is false is the leap from "one channel active" to "not more expensive than binary": logic
still has to **read** the trit as one of three levels/directions, and that two-threshold
sensing cost is *not* removed by activating only one rail — it is a per-symbol discrimination
tax, measured and proved, that pushes ternary compute **above** binary.

---

## 1. The claim restated as three sub-claims

| # | sub-claim | verdict |
|---|---|---|
| (a) | one-channel activation means a trit never energizes both rails | **TRUE (with a measured caveat)** |
| (b) | therefore null-heavy data is cheaper than binary | **CONDITIONAL** |
| (c) | therefore ternary logic/circuits are "not more expensive than binary" | **FALSE** (as a claim about circuits; true only if restricted to the wire) |

---

## 2. Sub-claim (a) — "a trit never energizes both rails"

**Verdict: TRUE in the sense that matters, with one measured exception.**

The push–pull driver the claim describes is real and does what it says at *steady state*.
The three trit states map to exactly one active output rail each: `+1` drives the P path,
`−1` drives the N path, `null` drives **neither**. P and N require opposite gate polarity,
so a properly non-overlapped driver holds at most one rail charged at any instant. The
measured consequence is the single cleanest fact in the whole corpus:

| symbol | measured energy (fair-fight, per trit) | calibration |
|---|---|---|
| `±1` (one rail active) | **1.20 pJ** | DIRECT — `circuit/ENERGY_RESULTS.md` CORRECTION 1; `transport.py` `TRIT_PLUS` |
| `null` (no rail active) | **0.05 pJ** (24× cheaper) | DIRECT — same; `transport.py` `TRIT_NULL` |
| null-idle quiet window | **< 0.2 aJ** (gate G4) / **6.4×10⁻²⁰ J** (G10) | DIRECT — `lowswing_diode.log` §2 |

So "don't activate most channels" genuinely saves *static* power: an idle trit burns
~nothing, and an asserted trit burns 1.20 pJ only on the one rail it drives.

**The caveat that stops (a) from being a clean TRUE — "never" is too strong.** The same
measurement that confirms the cheap case also catches the exception. The cheapest toggle
(`null↔+1`) activates one channel and costs 54.2 fJ. But the *full-swing* toggle
(`+1↔−1`) costs **368.7 fJ = 6.8×** the cheap toggle, and the measured mechanism is a
**dead-zone crowbar**: during the sign reversal the output stage sweeps through a window
where `P_HI` *and* `N_HI` conduct together. **[DIRECT — `fair_binary.md` §4 mechanism 2;
`radix_lower_bound.md` §2.1.]** So "only ever one channel" is true of *duty* and of the
null↔outer toggles, but false of the full-swing sign flip, which momentarily energizes
both. The claim's absolute ("only ever") overstates by exactly this 6.8× transition.

---

## 3. Sub-claim (b) — "null-heavy data is cheaper than binary"

**Verdict: CONDITIONAL.** True only on the *transport/static* axis, only against the right
binary baseline, and only above a computable null fraction.

The free null is real (0.05 vs 1.20 pJ/trit), but it is a **wire/driver** saving, not a
logic saving, and its value depends on (i) how null-heavy the traffic is and (ii) which
binary baseline is the honest comparison. `transport.py` already encodes the correct model:

```
E_trit(p) = (1 − p)·1.20 + p·0.05        (p = null fraction, fair-fight full-swing point)
E_bit(p)  = E_trit(p) / log₂3             (log₂3 = 1.585 bits/trit)
```

| null fraction p | ternary E_bit | vs binary natural 0.512 | vs binary low-swing 0.216 |
|---|---|---|---|
| 0.00 (all ±1) | 0.757 pJ/bit | **1.48× worse** | 3.5× worse |
| 0.333 (uniform) | 0.515 pJ/bit | **tie (1.00×)** | 2.4× worse |
| 0.50 | 0.394 pJ/bit | 1.30× better | 1.8× worse |
| 0.80 | 0.177 pJ/bit | 2.9× better | 1.2× worse |
| 1.00 (all null) | 0.0315 pJ/bit | 16× better | 6.9× better |

**[ESTIMATE — deterministic arithmetic on the DIRECT per-trit constants 1.20 / 0.05, the
identical calculation `transport.py::ternary_energy_per_bit` prints.]**

The two crossover points are the key numbers of this whole review:

- **p ≈ 33.8%** — ternary crosses *below natural single-ended binary (0.512 pJ/bit)*.
  Uniform traffic (p = 1/3) sits essentially *on* this line: it **ties**, it does not win.
- **p ≈ 74.6%** — ternary crosses *below matched low-swing binary (0.216 pJ/bit)*.

So the claim's "null-heavy data is cheaper" is true **only** when (a) you're talking about
transport, and (b) the null fraction is high enough: > ~34% to beat the natural binary link,
> ~75% to beat a binary link allowed the *same* low-swing lever. At uniform traffic it is a
tie, not a saving.

Three further honest caveats that shrink the saving:

1. **The low-swing lever is radix-agnostic.** The headline 0.081 pJ/bit champion is
   *low-swing × resonant*, and binary gets low-swing for free (0.216 pJ/bit). The
   ternary-specific saving is the 2.67× against matched low-swing, not the 6.3× against
   natural binary. **[DIRECT — `fair_binary.md` §3, §5; `FINAL_VERDICT.md` §transport.]**
2. **Idle is free for binary too.** A binary link that mostly idles also pays ~0, so
   "null-heavy ⇒ cheaper" is a *workload* claim, not a radix claim. The circuit fact is
   only that the ternary link's *data-bearing* null is ~free; whether the workload is
   null-heavy is a property of the data, not the radix. **[OURS — `fair_binary.md` TODO #5;
   `FINAL_VERDICT.md` `meta_assumptions.md` A3.]**
3. **Real receiver offsets eat the low-swing margin.** The 0.081 number is LEVEL=1 (no
   mismatch); real sense-amp offsets (σ ≈ 5–20 mV) move the ternary low-swing floor to
   **0.22–0.35 pJ/bit**, which is a *loss*, not a win, against 0.512 binary. **[DIRECT —
   `fair_binary.md` TODO #4.]**

---

## 4. Sub-claim (c) — "ternary logic/circuits are not more expensive than binary"

**Verdict: FALSE.** This is the elephant, and it is not subtle.

The channel-activation saving is a **transport / static-power** saving. It governs how much
energy you spend *holding and moving* the symbol. It does **not** govern how much you spend
*reading* it. But every gate must read its inputs — "is this −1, 0, or +1?" — and that read
costs **two thresholds against binary's one**. The one-hot encoding ("only one rail active")
does not remove the read; it only changes *where* the read's margin lives. The value still
has to be resolved as one of three levels/directions, and one yes/no answer cannot name one
of three states.

**The floor (proved, representation-independent).** To name one of 3 states you need
`⌈log₂3⌉ = 2` binary discriminations — regardless of whether you draw the states as ordered
levels `{0,1,2}` or as sign×magnitude `{push, null, pull}`. Per bit that is

```
2 / log₂3 = 2·ln2/ln3 ≈ 1.262×
```

This is `ThresholdLowerBound.lean` (the `(b−1)/ln b` monotonicity, green, zero `sorry`) and
`meta_math.md` §2 shows it is the *same* number in all three costings — ordered thresholds,
binary decision count, and two-cell sign+magnitude erasure (`k_B T ln 4` for `log₂3` bits).
It is the cost of `3` not being a power of `2` (the wasted 4th "−0"/both-rails corner,
`2 − log₂3 = 0.415` bits/symbol). **Re-encoding as direction does not remove it** — "direction"
is still *sign decision + null-vs-active magnitude decision* = 2 decisions. **[DIRECT —
`ThresholdLowerBound.lean`; `meta_math.md` §2, §4.]**

**The measured cost (the floor is a *lower* bound, not the real cost).** The realized
direction receiver confirms the count empirically, and the gates confirm the loss:

| quantity | measured | vs binary | calibration |
|---|---|---|---|
| receiver tax: 2 sense amps vs 1 | 61.87 vs 24.35 fJ/eval | **2.54×** | DIRECT — `gate_energy.md` |
| receiver tax already exceeds the radix-economy density gain | 2.54× > 1.585× | loss before logic is counted | DIRECT — `gate_energy.md` |
| diode-direction gate, cheapest toggle | — | **3.4–4.9× /bit** | DIRECT — `fair_binary.md` §4 |
| diode-direction gate, matched low swing | — | **~3.5× /bit** | DIRECT — `lowswing_diode.md` §6 |
| diode-direction gate, full-swing toggle | 368.7 vs 6.94 fJ | **33.5× /bit** | DIRECT — `fair_binary.md` §4 |
| 2-wire static-CMOS gates (neg/min/max/sum) | — | **+21% / +45% / +53% / +214% per bit** | DIRECT — `gate_energy.md` |

The honest native-device floor — the *best possible* ternary gate, idealized — is
**~1.5–2× /bit**, not the 0.63× that `1/log₂3` would promise if a ternary toggle cost the
same as a binary one. Three levels on one wire sit `V_swing/2` apart, so holding equal BER
already costs ~2× *before* the two-threshold read. **[OURS/ANALOGY — `lowswing_diode.md`
§6 item 3; `radix_lower_bound.md` §3.]**

**Why the claim's own framing fails here.** "Only activate one channel" saves *rail* energy
(static power, shoot-through), but the **sensing/discrimination** cost is per *symbol read*,
not per *channel activated* — it is paid whether one channel or zero channels fired, because
the next gate still must decide which of three states arrived. The one-hot encoding does not
turn a 3-way read into a 1-way read; it relabels the two decisions (sign + magnitude) and
the measured direction receiver still uses **two sense amps** (2.54×). The channel-activation
intuition is *exactly right about the wire and exactly silent about the gate*.

---

## 5. Quantification — where a ternary datapath's energy actually goes

There is no single measured "typical ternary datapath" split, because the two axes were
measured separately. But the decomposition is unambiguous at both measured endpoints:

**On the link (transport), the sense cost is the invariant wall, not the wire.** As the
swing is lowered, the receiver's share of symbol energy climbs **13% → 61% → 67%**
(high-swing → low-swing → low-swing×resonant). At the 0.081 pJ/bit champion the split is
roughly **wire/driver ≈ 1/3, receiver(sense) ≈ 2/3** (≈ 0.08–0.09 pJ/trit). **[DIRECT —
`ENERGY_LAWS.md` Law 1.]** So even *on the axis where ternary wins*, two-thirds of the
residual cost is already the sensing/discrimination floor — the very cost the claim's
one-hot encoding cannot touch.

**In the gate (compute), sense dominates and switching is the minority.** `gate_energy.md`
measured the per-toggle decomposition (E_gate = switching, E_rec = sensing):

| gate | switching E_gate | sensing E_rec | sense share |
|---|---|---|---|
| binary NOT | 7.93 fJ | 24.35 fJ | 75% |
| ternary NOT (0-transistor wire swap) | 0.00 fJ | 61.87 fJ | 100% |
| ternary min | 23.32 fJ | 61.87 fJ | 73% |

**[DIRECT — `gate_energy.md` table.]** The punchline: the *free* ternary gate (negation =
wire swap, the single best thing balanced ternary has) still loses **+21% per bit** to
binary NOT, because it must drive a 2-threshold receiver. The 2.54× receiver tax alone is
larger than the entire 1.585× radix-density gain, *before any switching energy is counted*.

So the honest answer to "what fraction is transport vs sense vs switching": in the gate it
is roughly **sense ≈ 73–100%, switching ≈ 0–27%** of per-toggle energy (2-wire family),
with the sense part at **2.54× binary**; on the link it is **sense ≈ 2/3, wire ≈ 1/3** at
the champion. **The sensing/discrimination cost — the thing the claim's "activate one
channel" saving does not reduce — is the dominant term on both axes.** Transport vs compute
split across a full datapath is workload-dependent and is *not* a measured single number;
any claim that "most of the energy is the free-null transport saving" is **SPECULATION**
until a null-fraction-and-workload sweep is actually run.

---

## 6. The honest bottom line (one sentence)

**Single-channel-activation ternary is cheaper than binary on the wire (2.7–6.3× transport,
conditional on null-heavy data and a low-swing lever binary also gets) and unambiguously
more expensive in logic (1.26× proved floor → 2.54× measured receiver → 3.4–4.9× measured
gate), because activating one channel saves static rail power but does not remove the
two-threshold read — so "not more expensive than binary" is true of the link, false of the
gate, and the net is a workload question, not a law.**

---

## 7. The one experiment that settles what remains

**Build the diode-direction receiver with *no* sense amp** — two diode rails driving a
cross-coupled latch directly, plus a *single* null-detector comparator (one magnitude test) —
and fair-fight it against **one** binary sense amp at **fixed BER**, counting total energy
including the diode `V_d·I` and the latch. **[`meta_math.md` §6 E-new-1.]**

- **If** it reads 3 states at ≤ 1.0× binary per bit: the "direction is free" hypothesis is
  real, the 1.26× / 2-threshold application collapses, and sub-claim (c) would have to be
  reopened.
- **If** (as the 2.54× measured prior predicts) it lands ≥ ~1.3× binary: the compute half of
  the claim is dead for good, and only the transport half survives.

This is the single measurement that discriminates the claim's intuition from the theorem.
Until it is run, the verdict above stands: **the wire yes, the gate no.** (A companion
null-fraction-vs-idle sweep — ternary null-heavy vs binary idle-heavy on the *same* wire at
the same workload — is the second measurement, and it is what would settle the size of the
"free null" saving in (b).)

---

## 8. Calibration ledger

| claim | calibration |
|---|---|
| ±1 = 1.20 pJ, null = 0.05 pJ per trit (24×) | DIRECT — `ENERGY_RESULTS.md` CORRECTION 1; `transport.py` |
| null-idle < 0.2 aJ / 6.4×10⁻²⁰ J | DIRECT — `lowswing_diode.log` |
| full-swing +1↔−1 crowbar = 6.8× (368.7 vs 54.2 fJ) | DIRECT — `fair_binary.md` §4 / `radix_lower_bound.md` §2.1 |
| crossover null fractions ≈ 33.8% / 74.6% | ESTIMATE — arithmetic on DIRECT 1.20 / 0.05 constants |
| transport 0.081 vs 0.512 / 0.216 = 6.3× / 2.67× | DIRECT — `fair_binary.md` §3 |
| real-offset ternary floor 0.22–0.35 pJ/bit | DIRECT — `fair_binary.md` TODO #4 |
| 2-threshold floor 1.26× = 2·ln2/ln3, representation-independent | DIRECT (proved) — `ThresholdLowerBound.lean`; `meta_math.md` §2 |
| receiver tax 2.54× (61.87 vs 24.35 fJ) | DIRECT — `gate_energy.md` |
| diode gate 3.4–4.9× / 33.5× / ~3.5× per bit | DIRECT — `fair_binary.md` §4; `lowswing_diode.md` §6 |
| 2-wire gates +21%…+214% per bit | DIRECT — `gate_energy.md` |
| native-device floor ~1.5–2× per bit | OURS/ANALOGY — `lowswing_diode.md` §6; `radix_lower_bound.md` §3 |
| receiver share 13%→61%→67%; ≈2/3 at champion | DIRECT — `ENERGY_LAWS.md` Law 1 |
| "sense ≈ 73–100% of gate energy" | DIRECT — arithmetic on `gate_energy.md` table |
| "idle is free for binary too" | OURS — `fair_binary.md` TODO #5 |
| diode-only receiver settles (c); prediction ≥ ~1.3× binary | SPECULATION (prediction), prior 2.54× DIRECT — `meta_math.md` §6 E-new-1 |

---

## Sources

- `docs/FINAL_VERDICT.md` — the settled scoreboard (transport ~2.7–6.3× win; compute ~1.26–3.5× loss).
- `docs/ENERGY_LAWS.md` — Law 1 (receiver gauge-agnostic, 13%→61%→67%), Law 3, the 0.081 champion.
- `docs/TERNARY_COMPUTE_VERDICT.md` — Path A/B, the 1.26× floor and the `⊕` wall.
- `scripts/transport.py` — the null-fraction energy model (`ternary_energy_per_bit`).
- `scripts/fairfight.py` — the grounded three-axis summary.
- `proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean` — the proved 1.26× tax.
- `proofs/lean-src/hexagon/Hexagon/EnergyVerdict.lean` — the *uniform* tie (0.515 vs 0.748, superseded by the 0.512 baseline).
- `docs/compute/ground_up/fair_binary.md` — honest binary baselines + diode-gate reversal.
- `docs/compute/ground_up/lowswing_diode.md` — low swing cannot close the gate gap (~3.5× per bit).
- `docs/compute/ground_up/radix_lower_bound.md` — Π-factor decomposition; floor is 3.8% of the gap.
- `docs/compute/ground_up/meta_math.md` — representation-independence; "direction ≠ free"; E-new-1.
- `docs/compute/gate_energy.md` — the 2.54× receiver tax and the E_gate/E_rec split.
