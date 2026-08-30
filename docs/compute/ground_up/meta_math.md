# Meta-Math: does the impossibility argument survive the sign+magnitude re-encoding?

**2026-08-29 — Tau Architecture, ground-up meta-critique of the *theorems*.** This file
stress-tests the two mathematical legs of "ternary compute cannot beat binary per bit":
(1) `(b−1)/ln b` is minimized at `b = 2` (`proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean`),
and (2) Landauer `k_B T ln N` is radix-independent (`docs/compute/ground_up/device_physics.md` §5).

It is the *math* sibling of `meta_critique.md` (which attacks the plan, and already names
the right question — "does any device resolve 3 states in fewer than 2 measurements") and
`differential_noise.md` (which already tests the "direction-via-rectifier" idea at the
circuit level). This file does the theorem-level job those two don't: **what exactly the
Lean theorems prove, which premises are level-model assumptions, and whether re-encoding
three states as sign+magnitude changes the bound.**

**Calibration legend** (repo standard — mark at mapping time, verify later):

- **DIRECT** — measured, proved, or a textbook identity. Cite the number or the source.
- **ANALOGY** — structural resemblance, not identity. The shapes match; the objects differ.
- **OURS** — our design claim; follows from DIRECT but is not independently established.
- **SPECULATION** — untested hypothesis, or an order-of-magnitude estimate with no cited source.

---

## 0. The blunt verdict, first

**The impossibility argument is *right*, but for a reason it never states, and the
sign+magnitude escape it fears does not exist.** Three independent facts, all DIRECT:

1. `b/ln b` minimized at `e` and `(b−1)/ln b` minimized at `b=2` are **airtight calculus**.
   `RadixEconomy.lean`, `RadixMin.lean`, `ThresholdLowerBound.lean` are correct as proved.
2. **The 1.26× penalty (`2·ln 2/ln 3`) is representation-independent.** It is the *same*
   number whether you count ordered-level thresholds (`2 thresholds`), binary decisions
   (`⌈log₂3⌉ = 2`), or erasure cost of a 2-cell sign+magnitude register (`k_B T ln 4`).
   It is the cost of **`3` not being a power of `2`** — the wasted 4th corner of the
   2-bit space (`2 − log₂3 = 0.415` bits/symbol). Re-encoding as sign+magnitude *cannot*
   remove it, because three states need two yes/no answers no matter how you draw them.
3. **The sign+magnitude representation is, if anything, *worse* than the theorem claims**,
   not better: on the Landauer side it erases `ln 4` worth of state while carrying only
   `log₂3` bits → **1.26× worse per bit** (not tied, not better). The project's own
   realized "direction-via-diode" receiver still uses **2 sense amps (2.54× measured)** —
   it is the empirical confirmation that "direction" is not free.

The *only* genuine escape is a device that resolves 3 states in **one** measurement — a
native 3-way decision that is *not* a composition of two binary thresholds. That is the
SET / tristable-RTD bet, already surveyed as unwinnable (cryogenic/slow; DC-hungry;
no VLSI path) in `device_physics.md` and `meta_critique.md` §3e. The sign+magnitude
"direction" framing is a **red herring** relative to that real escape: it does not reduce
the decision count from 2, it only relabels one of the two decisions.

---

## 1. What each theorem actually proves (and what it silently prices)

### 1.1 `RadixEconomy.lean` / `RadixMin.lean` — Airtight, and *not* about energy

`b/ln b` is minimized at `b = e`; among integers `b = 3` wins (`3/ln3 = 2.73 < 2/ln2 = 2.89`).
**[DIRECT — pure calculus; `RadixMin.lean` proves `e ≤ b/ln b` and `e < 3/ln3`,
`RadixEconomy.lean` proves `3/ln3 < 2/ln2` and `4/ln4 = 2/ln2`.]**

This is a statement about **digit count per value** (representation/interconnect economy),
not about joules. The repo already applies it correctly (`ENERGY_LAWS.md` Law 3, `VERDICT`
transport column). No critique needed — it is not part of the impossibility claim; it is
the *opposite* leg (the transport win).

### 1.2 `ThresholdLowerBound.lean` — Airtight *as calculus*, but it proves a priced model

The file proves: `b ↦ (b−1)/ln b` is strictly increasing on `(1,∞)`, hence over integer
`b ≥ 2` the minimum is `b = 2`, and ternary is `2·ln2/ln3 ≈ 1.26×` worse.
**[DIRECT — the derivative `(ln b − 1 + b⁻¹)/(ln b)² > 0` for `b > 1` is a correct
inequality; `deriv_threshold_per_bit_pos`, `threshold_per_bit_mono`,
`binary_min_threshold_per_bit`, `ternary_worse_than_binary` are all green.]**

But the *theorem's content* is conditional. The header states the premise explicitly:
"on a substrate where each threshold costs uniformly." Unpacked, the function `(b−1)/ln b`
prices the cost model:

| hidden premise | what it assumes | true for polar ternary? |
|---|---|---|
| **P1 — ordered levels on one axis** | `b` states are `b` voltages on a single wire, decoded by a flash/thermometer decoder with `b−1` thresholds | **NO** — polar is sign×magnitude, not a 3-level line |
| **P2 — uniform threshold cost** | every threshold is a comparator against a nonzero reference, all costing the same | **NO** — a *sign* threshold is against **ground** (the one reference needing no bandgap/divider), and a *diode* does it without a comparator at all |
| **P3 — information = `ln b`** | states equiprobable, one symbol = one decision | partially — true for the wire, wrong for the 2-cell store |
| **P4 — no native M-ary decision** | a `b`-way read *must* decompose into `b−1` binary thresholds | **the real question** — see §4 |

So the theorem is **not** "ternary is 1.26× worse, period." It is "**IF** the cost of a
radix-`b` readout is `b−1` uniform comparators, **THEN** binary minimizes cost-per-bit."
The physics lives entirely in the IF. The Lean proof is correct; its *application* to
polar ternary is an extra step that the file header asserts but does not prove.

### 1.3 The counting is actually *better* than `b−1` for large `b` — and this is a theorem bug, not a physics bug

`b−1` is the number of thresholds in a **flash** (parallel, thermometer) decoder. The
*minimal* number of binary decisions to identify one of `b` states is **`⌈log₂b⌉`**, not
`b−1`. For `b = 4`: `b−1 = 3` thresholds, but a binary decision tree needs only `2`
comparators. So `(b−1)/ln b` **overcounts** the true lower bound for every `b ≥ 4`.

The coincidence that saves the theorem's specific claim: **`b−1 = ⌈log₂b⌉` exactly at
`b = 2` (1) and `b = 3` (2)**. Since the verdict only ever compares `b=2` vs `b=3`, the
flash-model number happens to equal the true bound, and the conclusion survives. But the
file's *general* claim ("thresholds-per-bit `(b−1)/ln b` is the cost function") is only
correct as a *flash-decoder* cost, not as a lower bound. The honest lower bound is
`⌈log₂b⌉/log₂b` (see §6, T-new-1).

---

## 2. The core finding: the 1.26× is representation-independent

Attack the key question directly: *does sign+magnitude get a different (better) lower
bound than "b−1 thresholds"?*

**No. The minimum number of binary discriminations to identify a state among 3 is
`⌈log₂3⌉ = 2`.** One yes/no answer distinguishes at most 2 alternatives; you cannot name
one of 3 states with a single binary test. This is a pure information-theoretic floor and
it does not care whether the 3 states are drawn as `{0,1,2}` on a line or as
`{push, null, pull}` on a sign×magnitude star.

Consequently the per-bit decision cost is `2 / log₂3 = 2·ln2/ln3 ≈ 1.262` **regardless of
encoding** — ordered levels *and* sign+magnitude both hit the same number, because both
pay 2 binary decisions for 1.585 bits. The theorem's "b−1 thresholds" is one *realization*
of that floor (a flash decoder); sign+magnitude is another (sign decision + magnitude
decision); they coincide because `3` is small enough that `b−1 = ⌈log₂b⌉`.

Even more pointedly, the same 1.262 appears in **erasure** (see §3), where it cannot
possibly be a "threshold" artifact. Three physical observations all reduce to one number:

| counting | cost per symbol | bits/symbol | per-bit | |
|---|---|---|---|---|
| ordered thresholds (`b−1`) | 2 thresholds | `log₂3 = 1.585` | `2/1.585` | 1.262 |
| binary decisions (`⌈log₂b⌉`) | 2 decisions | 1.585 | `2/1.585` | 1.262 |
| 2-cell sign+magnitude erasure | `k_B T ln 4` | 1.585 | `(ln4/1.585)/ln2` | 1.262 |

**[DIRECT — all three are arithmetic; the identity `2/log₂3 = 2·ln2/ln3 = ln4/log₂3 ÷ ln2`
is what makes them equal.]**

The physical content: **`3 ≠ 2^k` means representing a trit in binary cells wastes
`2 − log₂3 = 0.415` bits per symbol** (the unused 4th corner of the 2-bit space: the
"−0"/"both-rails" state). That waste is *not* removable by changing how you draw the
constellation. It shows up identically in threshold count, decision count, and erasure
energy. This is the deep, honest reason the impossibility argument is robust: **it is a
coding-efficiency statement, not a voltage-level statement.** Any future theorem should
say *that* instead of "b−1 thresholds."

---

## 3. Does the sign+magnitude representation escape the *Landauer* leg? **No — it is worse there.**

The claimed radix-independence is the identity

```
(log_b N)·(k_B T ln b) = k_B T ln N     —  independent of b
```

**[DIRECT — the two `ln b` factors cancel; pure arithmetic.]** This is airtight **as an
identity about a single `b`-valued degree of freedom with equiprobable states**. But it
silently assumes a specific *erasure model*, and the sign+magnitude encoding breaks it:

- **Single 3-state degree of freedom** (one capacitor at `{+Q, 0, −Q}`, one SET island at
  `n ∈ {−1, 0, +1}`, one 3-minimum free-energy well): erasing costs `k_B T ln 3`, carrying
  `log₂3` bits → **`k_B T ln 2` per bit, exactly tied with binary.** Radix-independence
  holds. **[DIRECT — Landauer generalization to radix `r`; `Entropy` 21(12):1150 (2019).]**

- **Two binary cells** (a sign rail + a magnitude rail, or push-rail + pull-rail — which is
  *what "sign+magnitude" physically is at the logic level*): the register has **4** physical
  states, of which 3 are used. Erasing it costs `k_B T ln 4`, carrying `log₂3` bits →
  **`(ln 4)/log₂3 = 1.262 k_B T` per bit, i.e. 1.26× *worse* than binary.** The "−0"/"both"
  state is paid-for erasure energy that carries no information.

**[DIRECT — arithmetic: `k_B T ln 4 / log₂3 = 2·k_B T ln 2 / (ln 3 / ln 2) = 2·ln2/ln3 · k_B T ln 2`.]**

So the honest answer to "is Landauer radix-independence airtight?" is: **the algebra is
airtight; the *model* is not.** `k_B T ln N` is radix-independent only for a single
`b`-valued DOF. The sign+magnitude representation the brief proposes is the *two-cell*
case, and there the radix-independence fails **in the direction that hurts ternary**: you
erase `ln 4` and keep `log₂3`. The escape the brief is looking for does not exist on the
thermodynamic leg — sign+magnitude makes that leg *worse*, not better.

This also restates the repo's transport/compute split in erasure language: the **wire** is
one 3-level node (one DOF → tied, `ln 3`), the **gate** is two rails (two DOF → `ln 4`,
1.26× worse). The transport win and the compute loss are the *same* fact viewed through
the erasure model. **[OURS — follows from the DIRECT arithmetic above + the measured
single-wire transport / two-rail receiver topology.]**

### 3.1 Two further holes in the "thermodynamics" direction

1. **It is the *erasure* floor, not a compute floor.** `k_B T ln N` bounds *logically
   irreversible* reset. Reversible/adiabatic logic evades it entirely (energy recovery),
   and `device_physics.md` §8 already admits this is not covered. The verdict's "four
   independent directions" therefore overstates: **the "thermodynamics" direction is
   silently about irreversible erasure only, and it is not independent of the "thresholds"
   direction — both reduce to the same 1.26× `3 ≠ 2^k` waste** (one in comparators, one in
   reset energy). That is two facets of one fact, not two independent proofs.
   **[DIRECT — Landauer 1961 is an erasure bound; the `2·ln2/ln3` coincidence is §2.]**
2. **Equiprobability.** `k_B T ln b` per digit assumes uniform state occupancy. A biased
   or correlated symbol stream erases for less. Minor for a uniform codebook, but it is
   another place the "radix-independent" claim is a model, not a theorem.

---

## 4. The specific attack: is "direction via diode" free? (No — and we already measured it)

The brief's sharpest question: *is "b−1 thresholds" the right cost for a signal measured
by direction (diode rectification) rather than level (comparator)?* The charitable reading
is real: a **passive** rectifier (crystal radio, back-to-back LEDs, a full-wave bridge)
genuinely resolves sign with **zero comparators** — which diode conducts *is* the answer,
and no reference voltage or gain stage is involved. **[DIRECT — a rectifier's polarity
selection is the junction's physics, not a thresholding measurement.]**

But the escape fails on all four counts, and the last one is already measured:

1. **It needs regeneration.** A diode's decision must be amplified back to full logic
   swing and fanned out to the next gate. A cross-coupled latch / sense amp doing that
   *is* a comparator in all but name (positive feedback = gain = a decision), and it is
   exactly the "sense amp" the receiver already counts. **[DIRECT — a signal-restoring
   amplifier is a thresholding measurement; Law 1's receiver is precisely this.]**
2. **The null still needs an amplitude decision.** "Direction" only distinguishes push
   from pull. The trit cannot be decoded without answering "is there a signal at all,"
   and that is the **null-vs-outer** decision — the one with the *halved* margin
   (`V_swing/4`), the one no differential/sign machinery touches. `differential_noise.md`
   §3.2 already proves this point: the null is the zero of the difference, and "no sign"
   must be distinguished from the two signs *by amplitude*. **[DIRECT — differential_noise.md §2–3.]**
3. **The diode is a conduction cost, not free.** `V_d·I` dissipated per detection, and a
   fixed `V_d ≈ 0.3–0.7 V` is **incompatible with the low-swing lever** that produced the
   0.081 pJ/bit transport win — a diode eats a low-swing signal. **[DIRECT — diode forward
   drop is a fixed offset; low-swing needs the whole swing, so `V_d` dominates. `ENERGY_LAWS.md`
   Law 2 already counts diode loss as the thing to shrink.]**
4. **The realized circuit already proves the count is 2.** `circuit/ternary_fairfight.cir`
   implements "direction via diode" — two diode rails (`rA` charges on `line > 0`, `rB` on
   `line < 0`) — and it still needs **2 sense amps** (one per rail, each a sign test vs
   ground). Measured receiver cost **2.54×** binary (`gate_energy.md`). So in practice
   "direction via diode" did **not** collapse to fewer measurements; it relocated the two
   thresholds to two sign-tests-against-ground and *added* a diode drop. **[DIRECT — measured.]**

Net: the sign decision via rectifier is **not** free; it converts a *level* threshold
(against a nonzero reference) into a *sign* threshold (against ground) plus a *conduction*
loss. The one real, narrow win is that ground is the one reference needing no bandgap or
divider — `differential_noise.md` §3.3 already credits this ("the direction read is more
robust than a naive 3-level comparison"). But it does **not** reduce the decision *count*
from 2, so it does not move the 1.26×. **[OURS — synthesis of the DIRECT circuit facts.]**

The correct cost model for sign+magnitude is therefore: **1 magnitude decision + 1 sign
decision = 2 decisions, exactly the theorem's count, just relabeled.** The brief's hope
("1 voltage × 2 directions → fewer than 2 thresholds") is wrong because the "2 directions"
still require a sign decision, and the "1 voltage" still requires the null-vs-active
amplitude decision.

---

## 5. What the argument gets *right* (the parts that survive the attack)

To be blunt in both directions:

- **`RadixEconomy`/`RadixMin`:** correct, correctly scoped (transport). No attack lands.
- **`ThresholdLowerBound`:** correct conclusion (1.26×), correct for the b=2-vs-b=3
  comparison it is used for, **wrong mechanism** (flash "b−1" instead of "⌈log₂b⌉ binary
  decisions"), and **over-generalized** for `b ≥ 4`. Fixable by restating the cost as
  `⌈log₂b⌉/log₂b` (§6).
- **Landauer radix-independence:** correct algebra, **model-dependent** application.
  Single-DOF ternary ties binary (correct as stated); the sign+magnitude *2-cell* form is
  1.26× worse. The "no thermodynamic free lunch" conclusion is right, but the *reason*
  (the `3 ≠ 2^k` waste) is more general than the file states, and the claim is only about
  irreversible erasure, not compute.
- **The four-direction framing:** "proved from four independent directions" overstates.
  Thermodynamics and thresholds are **the same 1.26× waste** in two costumes; only
  fabrication and circuit are genuinely independent. The verdict should read "three
  independent directions, two of which are facets of one coding fact."

---

## 6. The specific NEW theorem and counterexample to test

### T-new-1 — the representation-independent binary-decision bound (replaces the flash model)

**Statement.** For integer radix `b ≥ 2`, the minimum number of *binary* discriminations
per bit of symbol information is

```
g(b) = ⌈log₂b⌉ / log₂b ,
```

with `g(b) ≥ 1`, equality **iff** `b` is a power of 2, and `g(3) = 2/log₂3 = 2·ln2/ln3 ≈ 1.262`.

**Why it is the right theorem.** It is invariant under re-encoding (ordered vs
sign+magnitude both need `⌈log₂b⌉` yes/no answers), so it *cannot* be escaped by the
brief's re-encoding move, and it exposes the true mechanism (`3 ≠ 2^k` wastes
`⌈log₂b⌉ − log₂b` bits). It subsumes `ThresholdLowerBound.lean` at the only point that
file is used (b=2 vs b=3, where `b−1 = ⌈log₂b⌉`) and fixes the overcounting at `b ≥ 4`.
**Calibration: DIRECT (provable — see below).**

**Provable in Lean.** `⌈log₂b⌉ ≥ log₂b` with equality iff `b = 2^k` (integer log), plus
`2/log₂3 = 2·ln2/ln3` from `RadixEconomy.lean`'s existing lemmas. This is a *companion* to
`ThresholdLowerBound.lean`, not a rewrite of it. The hard part is only formalizing
`⌈·⌉`/`log₂`; the arithmetic is the same `log 8 < log 9` move `RadixEconomy.lean` already
uses.

### T-new-2 — the escape condition (reframes the impossibility as a *device* question)

**Statement.** Ternary beats binary per bit on the measurement axis **iff** a *single
native 3-way discrimination* costs less than `g(3) = 2/log₂3 ≈ 1.262` times a single
binary discrimination.

**Why it is the right theorem.** It makes explicit what `ThresholdLowerBound.lean` buries
in P4: the only way under the `2`-decision floor is a decision that is **not** a
composition of two binary thresholds — one measurement that directly yields one of 3
values. SET's Coulomb-ladder read (one charge measurement → `n` directly) and a tristable
RTD's load-line read are the canonical candidates; both are single-measurement, and both
are already surveyed as unwinnable (cryogenic/slow; DC-hungry; no VLSI path —
`device_physics.md` §3, `meta_critique.md` §3e). This theorem is what turns the verdict
into a *go/no-go* device question instead of a counting claim.
**Calibration: OURS (the inequality is DIRECT; "this is *the* criterion" is our reframe).**

### E-new-1 — the counterexample that kills (or saves) the diode hypothesis

**What to build/measure.** A receiver that resolves sign *only* by rectification — two
diode rails driving a cross-coupled latch directly, **no sense amp** — and a null detector
as a single magnitude test. Fair-fight it against one binary sense amp at **fixed BER**,
counting total energy (including the diode `V_d·I` and the latch). This is the one
experiment that discriminates the brief's hypothesis from the theorem.

**Prediction (from §4).** No win: the sign decision still needs the latch (a regenerating
amplifier = a measurement), the null decision still needs a comparator with `V_swing/4`
margin, and the diode adds `V_d·I` while forfeiting low-swing. Best case ≈ 1 comparator +
1 cheap sign latch ≈ **≥ 1.3× binary**, consistent with the 2.54× already measured for the
2-sense-amp version. If this prediction *fails* — if the diode-only receiver genuinely
reads 3 states at ≤ 1.0× binary per bit — then `ThresholdLowerBound.lean`'s *application*
is overturned and the impossibility argument falls back to Landauer + fabrication alone.
**Calibration: SPECULATION (untested; the 2.54× measured for the sense-amp version is the
prior).**

### E-new-2 — the erasure counterexample that distinguishes the two models

**What to measure.** Erasure energy of (a) a **one-node** 3-level register (`+Q/0/−Q` on a
single capacitor) vs (b) a **two-rail** sign+magnitude register (sign cell + magnitude cell),
both storing `log₂3` bits.

**Prediction (from §3).** (a) → `k_B T ln 3` per symbol = tied with binary (radix-independence
holds); (b) → `k_B T ln 4` per symbol = 1.26× worse. This isolates exactly where the
"radix-independence" claim is model-dependent, and it is cheap to simulate (two RC
resets + Landauer bookkeeping). **Calibration: SPECULATION (the identity is DIRECT; the
"one-node vs two-rail" split is the untested circuit realization).**

---

## 7. Calibration summary

| claim | calibration |
|---|---|
| `b/ln b` min at `e`, `3` best integer | **DIRECT** (Lean-proved) |
| `(b−1)/ln b` increasing, min at `b=2` | **DIRECT as calculus**; **OURS** as a cost model (P1–P4 are the load-bearing, unproved premises) |
| `(b−1)` = true lower bound for all `b` | **WRONG for `b≥4`** — the honest bound is `⌈log₂b⌉` |
| 1.26× = `2·ln2/ln3` is representation-independent | **DIRECT** (arithmetic identity; the core result of this file) |
| sign+magnitude needs < 2 decisions | **FALSE** — `⌈log₂3⌉ = 2`; refuted empirically by the 2-sense-amp receiver (2.54×) |
| diode rectification makes direction free | **FALSE in active logic** — needs regeneration + null comparator + `V_d·I`; **OURS** synthesis of DIRECT circuit facts |
| Landauer `k_B T ln N` radix-independent | **DIRECT for a single b-valued DOF**; **fails for 2-cell sign+magnitude (1.26× worse)** |
| "four independent directions" | **OURS/overstated** — thermodynamics and thresholds are one fact (`3 ≠ 2^k`) in two costumes |
| only escape = single native 3-way decision < 1.262× binary | **OURS** (reframe of the DIRECT counting); the device survey already says no candidate wins |

---

## TODO / not covered / caveats

- **No new Lean work.** `T-new-1` (`⌈log₂b⌉/log₂b`) is stated but not proved; it is the
  one Lean follow-up worth doing (formalize `⌈·⌉`/`log₂`, then `g(b) ≥ 1` iff-`2^k`). Until
  it is in the ledger, `ThresholdLowerBound.lean` remains the only checked artifact and its
  `b−1` premise stays uncorrected.
- **No new measurement.** `E-new-1` (diode-only receiver) and `E-new-2` (one-node vs
  two-rail erasure) are *predictions*, not runs. `E-new-1` is the single highest-value
  experiment in this file: it is the only thing that could actually overturn the theorem's
  *application* (not its math).
- **I did not re-derive the SNR/BER curve.** The `V_swing/4` halved-margin claim is taken
  from `differential_noise.md` §2 and `device_physics.md` §2.3, not recomputed. The exact
  energy-to-hold-BER curve for 3-level vs 2-level is still the open item both those files
  flag.
- **The "diode is a conduction cost, not a measurement cost" split is asserted, not
  quantified.** Law 1/Law 2 (`ENERGY_LAWS.md`) says conduction is shrinkable and measurement
  is not, which *suggests* moving the sign decision into conduction could rebalance energy —
  but whether `V_d·I` can actually be pushed below a sense amp's fixed cost at fixed BER is
  exactly what `E-new-1` must decide. This is the one place the brief's intuition has a
  live (if narrow) kernel; it is not settled.
- **`2 − log₂3 = 0.415` bits/symbol is the "wasted state" — but only for uniform codes.**
  A non-uniform (shaped) ternary code, or a code that *uses* the 4th state for something
  (e.g. the `11 = NEVER` canary in `storage.md`, or a 2-trit-pairs-to-3-state packing), would
  change the arithmetic. 3-valued *block* codes (e.g. packing 3 trits = 27 states vs 5 bits
  = 32) amortize the waste differently; that is out of scope here and could shift the
  per-bit constant, though not the `≥ 1` direction for single symbols.
- **Reversible/adiabatic compute is not analyzed.** Landauer is an *erasure* bound; the
  "no thermodynamic win" claim is only about irreversible reset. Whether ternary composes
  with adiabatic/reversible logic differently than binary (the `device_physics.md` §8 open
  item, and `meta_critique.md`'s "adiabatic × native-device" thread) is genuinely open and
  could change the verdict in the reversible regime — for *both* radices.
- **Assumes the corpus is internally consistent.** If `gate_energy.md`'s 2.54× and
  `polar_gates.md`'s "native is 4.9–14.3× worse" ever conflict, the empirical half of §4
  (which leans on them) needs a re-check before `E-new-1`'s prior is trusted.
- **This file attacks the *math*, not the fabrication leg.** The "no native 3-state device"
  direction of the impossibility is untouched here; it is `device_physics.md` §7 and
  `meta_critique.md` §3e. `T-new-2` connects the two: if a single-measurement 3-way device
  ever *is* fabricated, this file's floor is exactly what it must beat.

---

## Sources

- `proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean` — `(b−1)/ln b` monotone; the
  theorem under critique.
- `proofs/lean-src/hexagon/Hexagon/RadixMin.lean`, `RadixEconomy.lean` — `b/ln b` min at `e`;
  `3/ln3 < 2/ln2`; `log 8 < log 9`.
- `docs/compute/ground_up/device_physics.md` §5 — Landauer `k_B T ln N` radix-independence,
  and the "Generalization of the Landauer Principle" citation (`Entropy` 21(12):1150, 2019).
- `docs/ENERGY_LAWS.md` — Law 1 (receiver gauge-agnostic), Law 2 (I²R/diode loss), the
  transport/compute split.
- `docs/compute/ground_up/differential_noise.md` — the direction-read robustness and the
  null-vs-outer wall; the single-ended vs differential distinction.
- `docs/compute/ground_up/meta_critique.md` — the "resolve 3 states in <2 measurements"
  reframe and the device fabrication audit.
- `docs/compute/gate_energy.md` — the measured 2.54× receiver tax (1 vs 2 sense amps).
- `docs/compute/polar_gates.md` — the realized polar receiver (2 sense amps + push-pull
  driver), native-vs-binary energy.
