# Differential noise rejection and the polar ternary cell — does it rescue the halved margin?

**2026-08-29 — Tau Architecture, ground-up survey. ONE question: does the polar ternary
cell's push/pull (differential) structure reject common-mode noise, and does that change the
"halved noise margin kills ternary" verdict?**

**The claim under test (Ian):** "Noise is not a problem when the signal goes backwards and
forwards" — i.e. the polar ternary cell (push = +V, pull = −V, null = 0) is a *differential*
signal, and common-mode noise cancels in the difference.

**Calibration legend** (repo standard — mark at mapping time, verify later):

- **DIRECT** — measured, proved, or a textbook identity. Cite the number or the source.
- **ANALOGY** — structural resemblance, not identity. The shapes match; the objects differ.
- **OURS** — our design claim; follows from DIRECT but is not independently established.
- **SPECULATION** — untested hypothesis, or an order-of-magnitude estimate with no cited source.

---

## 0. The one-sentence verdict

**Half right, in a way that leaves the wall standing.**

Differential/balanced signaling *does* reject common-mode noise — that is real, well-understood,
and large (it is why LVDS runs a ~350 mV swing over meters). But the polar ternary cell **as
built** (`circuit/ternary_fairfight.cir`) is *not* a differential pair: it is a **single wire
carrying three levels {+V, 0, −V}**, and its "±" symmetry lives in the *codebook* (the symbol
set), not in the *channel* (there is no second complementary wire to subtract). So the cell gets
**none** of the common-mode rejection it is claiming, and the 3-level noise margin is still
`V_swing/4`, exactly as `device_physics.md` already says. Worse, the **null — the middle symbol —
is precisely the one that no differential structure protects**, because the null *is* the zero of
the difference: it has no sign, so "read the direction" cannot decode it. The halved-margin
argument survives, with one honest amendment recorded in §4.

---

## 1. The principle, named and verified

### 1.1 What "differential" actually rejects

In a **differential (balanced) link**, information is carried by the *difference* between two
conductors:

```
V_p = V_cm + V_sig/2        V_n = V_cm − V_sig/2
receiver reads:  V_diff = V_p − V_n = V_sig
```

Any disturbance that couples *equally* to both conductors — ground bounce, supply ripple, EMI
picked up by an adjacent aggressor, the driver's DC offset — appears only in the common mode
`V_cm = (V_p + V_n)/2`, and is rejected by the subtraction. The receiver's **common-mode
rejection ratio (CMRR)** quantifies how much of that equal-mode disturbance leaks through;
a real differential receiver rejects 20–60 dB (10×–1000×), instrumentation front-ends 80–120 dB.

**[DIRECT — textbook.** This is the standard definition of differential/balanced signaling; the
CMRR dB figures are the standard op-amp/instrumentation-amplifier ranges (Horowitz & Hill, *The
Art of Electronics*).]**

The canonical deployed instance is **LVDS** (TIA/EIA-644-A): a ~**350 mV** nominal differential
swing, a ~**1.2 V** driver common-mode offset, and — the headline common-mode spec — the receiver
must tolerate a **±1 V ground-potential difference between transmitter and receiver**. The whole
point is that the *difference* survives while the *common mode* wanders. This is the real,
quantitative phenomenon behind "noise cancels in the difference." **[DIRECT — TIA/EIA-644-A;
Texas Instruments, *LVDS Owner's Manual* (SLLA054).]**

### 1.2 The direct citation that matters most: MLT-3

Polar ternary *over a differential pair* is not hypothetical — it is deployed. **MLT-3**, the
100BASE-TX line code, is a **three-level {−1, 0, +1} signal sent over a differential twisted
pair** (cat-5). It is, literally, "polar ternary + balanced transmission." **[DIRECT — IEEE
802.3u, 100BASE-TX PHY.]**

MLT-3 is worth citing *twice*, because it demonstrates **both halves** of the honest split at
once:

1. It gets LVDS-class **common-mode rejection** *because it is a true two-wire differential
   pair* — the {−1, 0, +1} levels ride on a differential pair, so ground bounce / coupled EMI is
   subtracted out.
2. Its **noise margin is still set by the 3-level spacing**, not by the balancing. The three
   levels are `V_diff` apart on a differential swing of `2·V_diff` (peak-to-peak), so adjacent
   levels sit `V_diff/2` from their thresholds — the differential pair does **not** widen the
   per-level spacing. Balancing removes the common-mode floor; it does not touch the
   differential-mode floor.

And a second reason MLT-3 is instructive: it uses three levels **for spectral shaping, not for
3-level information.** MLT-3 still carries **one bit per transition** (1.585 bits/symbol would
require a 3-level *decoder*; MLT-3's 3 levels just cut the fundamental frequency to ~f/4 of NRZ).
So the one deployed "polar ternary + differential" system does not even attempt the thing the
Tau comm cell attempts (extract 1.585 bits/trit); it uses the third level as a bandwidth trick.
**[DIRECT — standard MLT-3 description.]**

---

## 2. The honest split: common-mode rejection ≠ signal margin

This is the crux, and it is the part Ian's claim collapses. Two *different* noise channels:

| channel | what it is | does differential reject it? |
|---|---|---|
| **common-mode** | noise added *equally* to both conductors of a pair (ground bounce, supply ripple, coupled EMI, driver DC offset) | **YES** — the difference subtracts it. Real, big (LVDS ±1 V ground offset; CMRR 20–60 dB). |
| **differential-mode** | noise added *independently* to each conductor (thermal/`kT/C` noise on each node, device offset/mismatch, crosstalk that hits one wire harder) | **NO** — it appears directly in the difference; it *is* the signal's noise. |

The **signal margin** is set by the **differential-mode** noise: the distance from a symbol to
its decision threshold, divided by the independent noise. Differential signaling does **not**
move the symbols apart — three levels still occupy the same swing, still sit `V_swing/(M−1)`
apart, still have margin `V_swing/4` for M=3.

**[DIRECT — the M-level PAM penalty is textbook:** M levels in a fixed peak swing are spaced
`V_pp/(M−1)`, so the noise margin falls by `(M−1)`; in dB that is `20·log10(M−1)`. Ternary
(M=3): **`20·log10(2) = 6.02 dB`** — exactly a *halved* margin. PAM-4 (M=4): `20·log10(3) =
9.54 dB`. This is the same SNR argument `device_physics.md` §2.3 already invokes, restated in
dB.]**

So the correct statement of Ian's intuition is: **"noise isn't a problem" is true for *shared*
noise, false for *independent* noise — and the *signal margin* is governed by the independent
kind.** Differential signaling moves the link down the *common-mode* wall; the
*differential-mode* wall (V_swing/4 spacing for ternary) is untouched.

---

## 3. Applied to the polar ternary cell — what it actually is

### 3.1 The cell is single-ended, not a pair

Read the netlist. `circuit/ternary_fairfight.cir` transmits on **one wire** (`x`), driven to
three levels in time:

```
push:  line → +V     pull:  line → −V     null:  line ≈ 0
```

There is **no second wire carrying the complement.** The "signal and its inverse" the claim needs
are **not present simultaneously** — `+V` and `−V` are two *different symbols at different times*
on the same conductor, not a pair `{+V, −V}` present at the same instant for a receiver to
subtract. **[DIRECT — the netlist: one node `x`, one driver MP1/MN1 per case, one wire model
`Rw/Cx/Rterm`.]**

Consequence: **a balanced *constellation* (symmetric ± symbols) is not balanced
*transmission*.** The ± symmetry is a property of the codebook; the common-mode rejection the
claim cites is a property of the channel. The cell has the former, not the latter.

What about the two receiver rails `rA`, `rB`? They are **not a differential pair** either. They
are two *rectified* single-ended signals:

```
rA charges when line > 0   (NMOS diode leg M1…M1D)
rB charges when line < 0   (NMOS diode leg M2…M2D)
```

On a push, `rA ≈ +0.25 V`, `rB ≈ 0`; a common-mode line shift of `+δ` lifts `rA → rA + δ` and
leaves `rB ≈ 0` (it is reverse-biased and not charging). The difference `rA − rB` therefore moves
**by the full δ**, not by zero — the noise does **not** cancel, because the two rails are not
symmetric images under the noise; they are two halves of a rectifier, and the noise enters only
the conducting half. **[OURS — reading of the measured netlist; the rectifier asymmetry is
DIRECT from the diode topology.]**

### 3.2 Is the null protected by the differential structure? **No.**

The null is decoded as **"neither rail charged"** (both sense amps read ≈ 0). This is the one
symbol that no differential structure can help, for a reason that is close to tautological:

> **The null is the zero of the difference.** A differential receiver decides *direction*; the
> null is exactly the symbol with *no direction*. You cannot read the null by reading the sign —
> "no sign" is what you must distinguish from "positive" and "negative" *by amplitude*.

The null's margin is therefore a **3-level amplitude distinction**, not a 2-level sign
distinction: how far can the line rise before the null starts to look like a push (or fall before
it looks like a pull)? The differential/sign machinery is simply not in the loop for that
decision.

**[DIRECT — the null is the center of the constellation by definition; the "halved margin"
arithmetic in §2 puts the null at `V_swing/4` from each of its two thresholds, the *same* margin
as the outer symbols and *worse* in the sense that it is flanked on both sides.]**

There is a genuine circuit detail worth recording (flagged OURS, not differential): the fairfight
null is *not* a naive 3-level voltage comparison. It is a **rectifier with a dead-band** — the
line must rise past the diode-connected NMOS's `VTO ≈ 0.30 V` before `rA` begins to charge, so
the null has an effective dead-zone of roughly the diode forward drop (~0.3 V) before a false
push fires, which is *comparable to, or marginally better than*, the naive `V_swing/4 = 0.25 V`
at the measured 1.0 V line swing. But:

- this is a **device threshold** (the diode drop), not an *algebraic* common-mode cancellation,
  so it varies with process and temperature exactly like any `VTO` does — it is not the robust
  20–60 dB CMRR of a true differential receiver;
- the **same** diode drop that buys the dead-band is what forces the ±1 symbols to over-swing
  (line ≈ 0.70 V to assert a 0.25 V rail), so the "free" null margin is paid for in outer-symbol
  swing, not in differential rejection. **[OURS — measured numbers 0.25 V rail / 0.70 V line /
  VTO=0.30 from the fairfight header and `lowswing_sweep.cir`; the "threshold ≠ cancellation"
  contrast is DIRECT.]**

### 3.3 Does push-vs-pull give a cleaner *direction* read? **Yes — but that is not the wall.**

Here the claim is, narrowly, right. The two-rail rectifier makes **direction** a *rail-selection*
decision, not a 3-level voltage comparison:

- a push charges `rA` and **cannot** charge `rB` (the pull diode is reverse-biased on a positive
  line) — so "+1" and "−1" are maximally separated: they live on *different rails*, not at two
  voltages on one scale. The direction read "which rail charged?" has a binary-like robustness;
  the two outer symbols are separated by the full 2·V of the swing in the *direction* axis.
- In a naive single-ended 3-level receiver you would compare one wire against two thresholds
  (±V_swing/4), and a large noise could in principle carry a symbol all the way from +1 to −1 by
  crossing the whole middle. The rectifier topology removes that failure mode for the *sign*.

**[OURS — follows from the diode-rail topology in the netlist; the "rail-selection is more robust
than two-threshold voltage comparison" contrast is DIRECT from how the two receivers are wired:
`XsaA1 0 rA1` vs `XsaB1 rB1 0`, two independent sign tests against ground.]**

But this robustness **was never the thing being threatened.** The halved margin comes from the
**null-vs-outer** decision (is there a signal at all?), not from the **push-vs-pull** decision
(which sign?). Making the sign read cleaner does not touch the null read, and the trit **cannot
be decoded without the null read**. So the cleaner direction read is real and correctly
identified, but it rescues nothing.

---

## 4. Verdict: does differential signaling rescue ternary's noise margin?

**No — the margin is still the wall. The "halved noise margin kills ternary" argument survives,
with one amendment.**

1. **The cell as built gets zero common-mode rejection** (single wire, no complementary pair),
   so it does not even collect the one real benefit of differential signaling. **[DIRECT from
   §3.1.]**

2. **Even a true differential rebuild would not widen the margin.** If the polar ternary cell
   were rebuilt as a *genuine* two-wire pair (push = `+V`/`−V` on the pair, pull = `−V`/`+V`,
   null = both wires at common mode), it would reject common-mode noise — real, and genuinely
   useful against ground bounce and coupled EMI, exactly as LVDS/MLT-3 do. But the null would
   then be "both wires at common mode", and distinguishing that from "±V across the pair" is a
   **differential-mode amplitude** decision with margin `V_diff/2` — i.e. still `V_swing/4` for a
   three-level swing. Common-mode rejection lowers the noise *floor*; it does not widen the
   symbol *spacing*. **[OURS — design analysis, not measured; the "differential-mode noise is
   unrejected" premise is DIRECT (standard).]**

3. **And a true pair costs the one thing the cell is selling.** The whole point of the comm cell
   is **three symbols on one wire** (radix economy as *interconnect* economy, `ENERGY_LAWS.md`
   Law 3 / §5.4). A differential rebuild is **two wires per trit** — it gives back the wire count
   the cell is using to win. You cannot have "one wire" and "balanced pair" at the same time;
   the claim is trying to. **[OURS — arithmetic: differential doubles the conductor count per
   symbol.]**

The amendment the analysis does force: **the direction (sign) sub-decision is more robust than
the naive "3 levels on one comparator" picture implies** (§3.3), and the specific rectifier
topology gives the null a diode-drop dead-band of the same order as the naive margin (§3.2). So
"the middle level has exactly half the margin" is slightly pessimistic about the *direction* and
about *this particular null detector* — but the **null-vs-outer** decision, which is the binding
one, still sits at ~`V_swing/4`, still needs the swing or the capacitance raised to hold a fixed
BER (`device_physics.md` §2.3), and still loses per bit to binary on noise margin. The wall is
still the wall.

---

## 5. The one place the "balanced" intuition is *right* (and it is not noise margin)

Balanced ternary's symmetry is genuinely worth something — but it buys **DC balance**, not
common-mode rejection:

- A balanced {−V, 0, +V} constellation has **zero DC / zero mean** (when symbols are equiprobable
  and symmetric), which means no DC wander, so the link can be **AC-coupled** and the receiver can
  be **DC-offset-cancelled** with a simple high-pass. This is the same reason MLT-3, Manchester,
  and 8b/10b exist. **[DIRECT — standard line-coding rationale; MLT-3 is the polar-ternary
  instance.]**
- "Balanced" in *that* sense is a **spectral / biasing** benefit. It is easy to *confuse* it with
  "balanced signaling" (the two-wire common-mode-rejecting kind), because they share the word —
  but they are different objects. DC balance ≠ differential noise rejection. **[OURS — the
  terminological disambiguation; the two senses of "balanced" are each DIRECT from their
  respective literatures.]**

This is the charitable reading of Ian's claim: the ± symmetry is real and buys something. It just
buys *spectral balance*, and the *noise-margin* rescue the claim needs is a different mechanism
(common-mode rejection) that the cell does not have.

---

## TODO / not covered / caveats

- **Not simulated.** This document is analysis of the *existing* measured netlists
  (`ternary_fairfight.cir`, `lowswing_sweep.cir`, `pam4.cir`), not a new ngspice run. The claims
  "the two rails do not cancel common-mode line noise" and "the null dead-band ≈ diode drop" are
  structural readings that should be *verified* by injecting a common-mode offset on the line
  node and re-measuring the demux. A ~10-line perturbation of `ternary_fairfight.cir` (add a DC
  or transient source in series with `x`) would turn §3 into measurements.
- **The "cleaner direction read" (§3.3) is untested as a *margin* claim.** It is argued from
  topology, not measured. A noise-margin *sweep* (perturb the line and count demux errors per
  symbol) would quantify how much more robust the sign read is than a naive 3-level comparator.
- **CMRR/SNR numbers are cited, not derived.** The 20–60 dB CMRR range, the ±1 V LVDS ground
  tolerance, and the 6.02 dB ternary penalty are from the cited standards/textbooks; I did not
  re-derive the `kT/C` → BER curve for the specific sense-amp. The exact energy-to-hold-BER
  curve for 3-level vs 2-level (the same open item flagged in `device_physics.md` §8) is still
  not computed.
- **Differential-mode noise sources are not enumerated for this cell.** Real independent-noise
  terms here are: `kT/C` on the rails (0.2 pF → ~1.4 mV rms at 300 K), the sense-amp input offset
  (σ ≈ 5–20 mV per the lowswing note), driver/reference mismatch, and rail-to-rail coupling.
  Which one actually sets the floor at a given swing is not measured; `lowswing_sweep.cir` already
  flags offset as the practical wall at low swing, and this doc takes that as given rather than
  re-establishing it.
- **A true differential rebuild is analyzed, not built.** §4.2's "even a two-wire pair leaves the
  null at V_diff/2" is a design argument. Whether the *common-mode* rejection of a real 2-wire
  polar-ternary pair would more than offset the wire-count doubling (net win or net loss per bit)
  is an open energy question that would need a fairfight of its own — and it sits on the
  interconnect-economy ledger, not the noise ledger.
- **MLT-3 is cited as analogy, not as evidence for the Tau cell.** MLT-3 carries 1 bit per
  transition over a differential pair; the Tau comm cell claims 1.585 bits/trit on one wire.
  They share "three levels, balanced" and *differ* on everything that matters here (wire count,
  bits per symbol, decoder). The MLT-3 citation bounds the *principle*, not the *cell's* claim.

---

## Sources

- **TIA/EIA-644-A** (a.k.a. ANSI/TIA/EIA-644), "Electrical Characteristics of Low Voltage
  Differential Signaling (LVDS) Interface Circuits" — 350 mV nominal differential swing, 1.2 V
  driver common mode, receiver common-mode range, ±1 V ground-offset tolerance.
  Texas Instruments, *LVDS Owner's Manual*, SLLA054 — the common-mode-rejection rationale and
  single-ended-vs-differential comparison. https://www.ti.com/lit/pdf/slll004
- **Horowitz & Hill, *The Art of Electronics*** — CMRR definition and the 20–120 dB instrument
  ranges; the textbook statement that differential receivers reject common-mode but pass
  differential-mode noise.
- **IEEE 802.3u, 100BASE-TX PHY** — MLT-3: three-level {−1, 0, +1} line code over a differential
  twisted pair, 1 bit/transition, fundamental-frequency reduction to ~f/4. (The deployed instance
  of "polar ternary + balanced transmission", used here as the bounding analogy.)
- **Standard M-PAM SNR result** — M levels in a fixed swing have spacing `V_pp/(M−1)` and a
  `20·log10(M−1)` dB margin penalty vs NRZ; ternary = 6.02 dB, PAM-4 = 9.54 dB. (The same SNR
  argument cited in `docs/compute/ground_up/device_physics.md` §2.3 and used in
  `circuit/ENERGY_RESULTS.md`'s PAM-4 margin note.)
- **In-tree (project):** `circuit/ternary_fairfight.cir` (the single-wire, two-rail, two-sense-amp
  cell: push/pull/null, diode VTO=0.30, rail assert 0.25 V, line peak 0.70 V),
  `circuit/ENERGY_RESULTS.md` (lowswing noise-margin note, ±4 mV null baseline, SA offset
  σ≈5–20 mV, PAM-4 ~7.5 dB), `docs/ENERGY_LAWS.md` (radix economy as interconnect economy),
  `docs/compute/ground_up/device_physics.md` §2.3 (the halved-margin claim this file tests).
