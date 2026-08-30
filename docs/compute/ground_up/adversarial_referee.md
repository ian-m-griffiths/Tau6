# Adversarial Referee — Falsifying Every "Ternary Win" in the Current Batch

**2026-08-29 (referee pass).** This file is the hostile peer-review of the current
experiment batch (`break_before_make.md`, `prebias_probe.md`, `wire_geometry.md`,
`encoding_permutations.md`, `device_permutations.md`). It adjudicates each claim the batch
could produce against the **fair-binary baseline** (`fair_binary.md`), the **settled
scoreboard** (`FINAL_VERDICT.md`, `ENERGY_LAWS.md`), and the **known self-deception modes**
(`meta_mishandled.md`).

**Status note:** at referee time, the five batch docs did **not** yet exist on disk
(verified `ls docs/compute/ground_up/`). This file therefore adjudicates the claims *as
named in the batch brief* against the existing measured corpus. If the batch docs land with
different numbers, the referee must re-run the below ledger against those numbers — but the
fair-binary baselines below are already measured and will not move.

**Calibration legend** (enforced on every number here):
- **DIRECT** — measured in-repo (ngspice 44.2 log) or proved (Lean, zero `sorry`).
- **DERIVED** — arithmetic on DIRECT numbers; no new measurement.
- **SPECULATION** — untested, flagged; carries no adjudicatory weight.

---

## 0. The one-line verdict

**None of the four batch claims beats a fair binary baseline, and the principal's "1.29×"
is a 5-ary transport-modulation number mislabeled as ternary compute that collapses to a
1.84× *loss* against matched low-swing binary. The settled verdict — ternary compute loses,
ternary transport wins only via radix-agnostic levers, ternary names win — is unchanged.**

---

## 1. The claims, each adjudicated

The fair-fight baselines every claim must beat (all DIRECT, `fair_binary.md` §2–§4):

| baseline | number | calibration |
|---|---|---|
| binary transport, natural single-ended 0→1 V | **0.512 pJ/bit** | DIRECT (BT1) |
| binary transport, matched low-swing 0.65 V | **0.216 pJ/bit** | DIRECT (BT2) |
| binary NOT gate, 0→1 V | **6.94 fJ/toggle** | DIRECT (fair_binary §2) |
| binary NOT gate, 0.65 V | **3.57 fJ/toggle** | DIRECT (lowswing_diode §2) |

A claim "beats binary" only if its **per-bit** energy is *below* the fair binary number at
**matched swing**, with **all its own overheads counted** (receiver, pre-charge, pre-bias,
termination, recovery). Anything else is a category error or a radix-agnostic lever wearing
a radix's clothes.

---

### Claim 1 — "break-before-make recovers the crowbar"

**The claim.** The +1↔−1 full-swing toggle pays a 6.8× crowbar penalty (368.7 fJ vs
54.2 fJ, `fair_binary.md` §4: P_HI and N_HI conduct together through the thin elevated-|Vt|
dead band). Break-before-make (non-overlapping drive, never both devices on) is claimed to
recover that penalty.

**Baseline it must beat.** binary NOT at 6.94 fJ/toggle (per-bit ÷1.585 ⇒ compare per bit:
dd_not per-bit vs binary per-bit).

**Does it actually beat it?** **No.** Even a *perfect* break-before-make that removes the
entire 6.8× crowbar multiplier lands exactly back on the **cheapest toggle** — `null↔+1` at
**54.2 fJ** — which is **already 7.8× worse per toggle / 4.93× worse per bit** than binary
NOT (`fair_binary.md` §4). Recovering the crowbar removes a *self-inflicted* penalty; it
returns the gate to a floor that was already losing. Break-before-make cannot get below the
cheapest-toggle energy, and that energy is ~5× per bit above binary.

**The measurement that decides it.** A `+1↔−1` toggle through a break-before-make driver,
full-cycle `V·I` integrated (including the dead-time/idle supply), divided by 1.585, compared
against 6.94 fJ binary NOT. Pass condition: **< 6.94 fJ per bit**. The 54.2 fJ cheapest
toggle already fails this by 4.9×; break-before-make cannot do better than 54.2 fJ, so it
fails *a fortiori*. Note also that break-before-make buys energy with **dead time** — an
energy-delay trade that "per bit" (energy-only) hides, exactly `meta_assumptions.md` A1.

**Verdict: FALSIFIED as a ternary win.** At best it converts a 33.5× loss into a 4.93× loss.
That is an honest improvement to *report*, not a win to *claim*.

---

### Claim 2 — "pre-bias saves energy"

**The claim.** Pre-biasing the receiver/wire (pre-charging a rail, biasing a dead-zone node)
reduces toggle energy.

**Baseline it must beat.** binary NOT 6.94 fJ — and binary pays **no pre-bias** (its next
gate *is* the receiver; `fair_binary.md` §2 makes this explicit). Pre-bias is an *extra*
charge the ternary cell pays that the binary reference does not.

**Does it actually beat it?** **No.** Two independent walls, both measured:

1. **Pre-bias is a tax binary doesn't pay.** Any pre-bias energy is counted in the same
   full-cycle supply integral. The cheapest measured ternary toggle (54.2 fJ) is already
   7.8× binary *without* pre-bias. Adding pre-bias can only raise it, unless pre-bias is
   itself recovered — and if it is recovered, that is the **LC-resonant lever**, which is
   radix-agnostic and already in the leaderboard, not a new ternary win.
2. **The gate's cost is DC termination, not swing** (`lowswing_diode.md` §4). The 54.2 fJ
   is 17.31 µA of *sustained* DC through the 100 kΩ null-return termination during the
   whole assert window — exactly reproduced by `V/R` arithmetic on measured nodes. Pre-bias
   does not touch a resistive DC path; it cannot remove the dominant term.

**The measurement that decides it.** Full-cycle `V·I` with the pre-bias source **in the
circuit and its energy summed in**, divided by 1.585, vs 6.94 fJ. Pass condition: **< 6.94
fJ/bit with pre-bias included**. No published number meets this; the closest candidate
mechanism (recovery) is the already-counted resonant lever, not pre-bias.

**Verdict: FALSIFIED.** Pre-bias is either (a) an added cost that widens the loss, or (b) a
relabeling of a radix-agnostic recovery lever. Neither makes ternary compute beat binary.

---

### Claim 3 — "geometry saves energy"

**The claim.** Wire/constellation geometry — the 2D amplitude×duration "anti-diagonal"
(long-low × short-high) of `ENERGY_LAWS.md` Law 2, or a hex/geometric encoding — saves energy.

**Baseline it must beat.** 0.512 pJ/bit (natural) **and** 0.216 pJ/bit (matched low-swing),
because the geometry lever is, by construction, a *modulation* change available to any radix.

**Does it actually beat it?** **No, once the baseline is fair.** This is already measured:
the 2D 5-symbol cell is **PWM-5-2D = 0.397 pJ/bit** (`fair_binary.md` §3). It beats *natural*
binary 0.512 by 1.29×, but **loses to matched low-swing binary 0.216 by 1.84×**
(0.397/0.216). And it is **not ternary** — it is a 5-state (quinary) modulation scheme
(2.32 bits/symbol, `ENERGY_LAWS.md` Law 3), and its "win" is the Law-2 I²R diagonal, a
mechanism with no dependence on the radix being 3. PAM-4 (a 4-state scheme) gets 0.401
pJ/bit from the same lever — the geometry helps *any* multi-level constellation equally.

**The measurement that decides it.** The geometry cell's pJ/bit vs 0.216 pJ/bit (the matched
low-swing binary that is allowed the *same* low-swing lever). Pass condition: **< 0.216
pJ/bit**. Measured 0.397 → **fails by 1.84×**.

**Verdict: FALSIFIED as a ternary win.** Geometry is real but radix-agnostic; vs a fair
binary it is a loss. Quoting it as "1.29×" without the 0.216 comparison is the inflated-
baseline deception (§3.1).

---

### Claim 4 — "an encoding/device permutation beats binary"

**The claim.** Some permutation — a sign+magnitude (vs level-coded) encoding, or a
reconfigurable/native device — beats binary per bit.

**Baseline it must beat.** 6.94 fJ/toggle (binary NOT) / 0.512–0.216 pJ/bit; for a device
claim, the per-bit cost must be **< 1.585 × the binary toggle**, i.e. the toggle must be
**< 11.0 fJ** just to tie at per-bit.

**Does it actually beat it?** **No.** The settled corpus already forecloses each branch:

- **Encoding.** No encoding removes the **1.26× representation-independent floor**
  (`2/log₂3 = 2·ln2/ln3`, `FINAL_VERDICT.md` correction 5): sign+magnitude still needs
  `⌈log₂3⌉ = 2` decisions. The *cheapest measured* encoding/gate is dd_not `null↔+1` at
  54.2 fJ = **4.93×/bit worse** (matched low-swing: 3.54×/bit, `lowswing_diode.md` §6). The
  honest native-device floor is **~1.5–2×/bit**, not 0.63× (`radix_lower_bound.md`,
  `lowswing_diode.md` §6).
- **Device.** The AAT "complex transistor" exists and resolves 3 states in one measurement,
  but its middle state is a static-current divider costing **≫1.585×** a binary op
  (`FINAL_VERDICT.md` correction 5; `native_device_aat.md` §0, §3). No native-device gate has
  *ever* measured below binary. The whole "native device" program is *unmeasured* (no compact
  model — `meta_mishandled.md` §5.3), so a device "win" is an absence-of-evidence claim.

**The measurement that decides it.** The specific permutation's full-cycle per-bit energy
(with receiver, termination, pre-charge, and mismatch on) vs 6.94 fJ binary NOT (per toggle)
or 0.216 pJ/bit (per bit). Pass condition: **a ternary toggle < 11.0 fJ (per-bit tie) and
ideally < 6.94 fJ**. No permutation in the corpus is within 5× of this. **SPECULATION** until
a real compact model produces a measured number; a claimed win without one is not evidence.

**Verdict: FALSIFIED** (unmeasured for the device branch; measured-and-losing for the
encoding branch). This is the one axis where the corpus's own TODO says "run the measurement
before claiming anything" — and it has not been run.

---

## 2. The principal's statement, specifically adjudicated

> *"we found a 1.29× which makes ternary circuits better than binary"*

**Three things are wrong with this sentence, and each is a category error, not a nuance.**

1. **1.29× is PWM-5-2D — a 5-level scheme, not ternary.** `fair_binary.md` §3, row
   "PWM-5-2D (long-low×short-high)": **0.397 pJ/bit vs 0.512 pJ/bit = 1.29×** (DERIVED:
   0.512/0.397 = 1.2897). PWM-5 is **five** states (2.32 bits/symbol, `ENERGY_LAWS.md` Law 3),
   not three. A 5-ary transport scheme beating binary says *nothing* about ternary; if
   anything it is evidence *against* radix-3 uniqueness (PAM-4, a 4-state scheme, gets 0.401
   pJ/bit from the same lever — `fair_binary.md` §3).

2. **It is transport/modulation, not a circuit and not compute.** PWM-5-2D is a wire-line
   modulation cell (`circuit/pwm5_2d.cir`), measured in the transport fair-fight. The compute
   verdict — the "circuits" the principal names — is the *opposite* sign: **3.4–4.9×/bit
   worse** at the cheapest toggle, **~24–33× worse** at full swing (`fair_binary.md` §4). The
   number 1.29× does not touch that ledger at all.

3. **It collapses against matched low-swing binary.** The 1.29× is against **natural
   single-ended 0→1 V binary (0.512)**. Against the **matched** 0.65 V low-swing binary
   (0.216) — the honest comparison once binary is allowed the same low-swing lever —
   PWM-5-2D is **1.84× WORSE** (0.397/0.216 = 1.8379, DERIVED). It does not "make ternary
   better than binary"; it is a thin 1.29× edge that flips to a 1.84× loss the moment the
   baseline is fair. `fair_binary.md` §3 says this in its own words: "only PAM-4 / PWM-5-2D
   hold a thin ~1.3× edge" — and §5: "every headline that bundled 'free null + low swing' and
   credited it to the radix… collapses."

**Does this change the settled verdict? No.** The settled scoreboard
(`FINAL_VERDICT.md`) is: **compute loses** (bounded ~1.5–3.5×/bit, measured), **transport
wins only by radix-agnostic levers** (low-swing + resonant, 6.3×/2.67×), **names win
exponentially** (`3ⁿ`, proved). The "1.29×" is a sub-case of the transport column, it is
5-ary not 3-ary, and vs a fair baseline it is a loss. Nothing in the batch revises the
scoreboard.

---

## 3. Self-deception modes to watch (from `meta_mishandled.md`) — and which appear here

The corpus has already fooled itself in these ways; each is present or at risk in this batch.

| # | deception mode | source | present in this batch? |
|---|---|---|---|
| 1 | **Comparing against an inflated binary baseline** (the ±1 V bipolar 2 V gate baseline inflated binary ~7×; the 0.748→0.512 load mismatch) | `fair_binary.md` §1/§4; `meta_assumptions.md` A2/§7.1 | **YES — active.** The "1.29×" and "geometry saves energy" quotes use 0.512 (natural, full-swing) and silently omit the 0.216 matched baseline against which both are losses. |
| 2 | **Measuring only the cheapest ternary toggle** (`null↔+1`, hiding the +1↔−1 crowbar 6.8×) | `fair_binary.md` §4; `test_suite_spec.md` §3.3 | **YES — the entire premise of Claim 1.** Break-before-make only matters because the crowbar exists; and it recovers *to* the cheapest toggle, which is itself 4.93× worse. |
| 3 | **Crediting a radix-agnostic lever (low-swing, resonant, 2D diagonal) to the radix** | `fair_binary.md` §5; `meta_assumptions.md` A14/§7.2 | **YES — active.** Claims 2 and 3 are exactly this: pre-bias/recovery and geometry are modulation/charge levers available to binary, and binary at 0.65 V gets them for free (0.216). |
| 4 | **Folding the sensing/receiver tax under the search** (Law 1's receiver is 2/3 of the 0.081 champion; the "2.54× receiver tax" was a sense-amp artifact) | `meta_mishandled.md` §3/§7.1; `ENERGY_LAWS.md` Law 1 | **RISK — watch Claim 4 and any device permutation.** A device "win" that counts the state-resolution in one bias point but omits the receiver/load/sensing cost is this mode. The AAT already shows the failure shape (static divider ≫1.585×). |
| 5 | **Collapsing per-wire / per-state / per-gate into one "per bit"** | `meta_mishandled.md` §6 | **RISK — active in the principal's sentence.** "1.29× (transport, per-bit) ⇒ circuits better (compute, per-gate)" is the metric conflation verbatim. |
| 6 | **Absence of evidence ⇒ evidence of absence (device branch)** | `meta_mishandled.md` §5.3 | **RISK — Claim 4.** "A device permutation beats binary" cannot be asserted from no measurement; it is SPECULATION until a compact model produces a number. |

The single most dangerous sentence in the batch is the principal's, and it instantiates
modes **1, 3, and 5 simultaneously**: an inflated baseline (0.512 not 0.216), a radix-agnostic
lever (2D modulation) credited to the radix, and a transport number mis-stated as a
circuit/compute win.

---

## 4. The honest bottom line

After this batch, **there is no axis on which ternary now beats binary that it did not before.**
Break-before-make and pre-bias cannot push the cheapest ternary gate below its already-losing
54.2 fJ (4.93×/bit worse than binary); geometry (PWM-5-2D) is a 5-ary radix-agnostic lever
that loses 1.84× to matched low-swing binary; and no encoding/device permutation has produced
a measured ternary toggle below binary's 6.94 fJ — the encoding floor is representation-
independent 1.26× and the measured floor is ~1.5–2×/bit, not a win. The settled verdict is
unchanged: **compute loses, transport wins only through levers binary shares, and the one real
ternary win remains the exponential `3ⁿ` namespace — a fact about names, not joules.**

---

## Calibration ledger (this file's own claims)

| claim | calibration |
|---|---|
| fair binary baselines 0.512 / 0.216 pJ/bit, 6.94 / 3.57 fJ | DIRECT — `fair_binary.md` §2, `lowswing_diode.md` §2 |
| dd_not null↔+1 = 54.2 fJ; +1↔−1 = 368.7 fJ (6.8× crowbar) | DIRECT — `fair_binary.md` §4 |
| dd_not per-bit ratios 4.93× / 33.5×; matched-swing 3.54× | DERIVED — ÷log₂3 = 1.585 on DIRECT |
| PWM-5-2D = 0.397 pJ/bit; 1.29× vs 0.512 | DIRECT (0.397) / DERIVED (ratio) — `fair_binary.md` §3 |
| PWM-5-2D vs matched 0.216 = 1.84× worse | DERIVED — 0.397/0.216 = 1.8379 |
| PWM-5 is 5-state (2.32 bits/symbol), not ternary | DIRECT — `ENERGY_LAWS.md` Law 3 |
| 1.26× representation-independent floor | DIRECT — `FINAL_VERDICT.md` correction 5, `meta_math.md` §2 |
| native-device floor ~1.5–2×/bit (not 0.63×) | OUR/SPECULATION per source — `radix_lower_bound.md` §3, `lowswing_diode.md` §6 |
| break-before-make recovers only to the cheapest toggle | DERIVED — the cheapest toggle (54.2 fJ) is the *lower* bound on any non-recovery switching scheme; SPECULATION only in that the break-before-make netlist is unrun |
| "pre-bias saves energy" is unmeasured | SPECULATION — no netlist/log exists; adjudicated by the measured cheapest-toggle + DC-termination walls |
| the batch docs were absent at referee time | DIRECT — `ls docs/compute/ground_up/` (2026-08-29) |

*No number in this file is invented. Every quantitative claim is DIRECT (measured/proved in
`fair_binary.md`, `lowswing_diode.md`, `FINAL_VERDICT.md`, `ENERGY_LAWS.md`) or DERIVED by
arithmetic on those; the only SPECULATION entries are the batch's own unmeasured claims,
which carry no weight and are labeled as such.*
