# Break-before-make gating — does it recover the ternary push-pull "crowbar"?

**2026-08-30, ngspice 44.2, measured (`circuit/break_before_make.cir`, `break_before_make.log`).**

This experiment tests the hypothesis in `fair_binary.md` §4: that the diode-direction
driver's full-swing +1↔−1 toggle costs 368.7 fJ (6.8× the null↔+1 toggle's 54.2 fJ)
because the elevated-|Vt| output stage "passes through a window where P_HI and N_HI
conduct together (shoot-through)". If that were the cause, break-before-make
(non-overlapping rail enables, a dead time so push turns fully off before pull turns
on) should collapse the +1↔−1 energy toward ~2×54.2 fJ. **It does not.** The measured
result is decisive and the mechanism is *not* shoot-through.

---

## 0. The one-line answer

Break-before-make **does not recover the crowbar**, and the net is **strongly
negative**. The +1↔−1 "crowbar" is ~93% the *static null-return termination leakage*
(Rterm=100 kΩ on the polar wire + the next stage's diode-receiver keepers RkA/RkB),
which flows whenever the output holds a rail and scales with hold time — **not**
shoot-through. Actual shoot-through is ~1.7 fJ/toggle (the elevated-|Vt| dead zone
already works). Non-overlapping gating therefore has nothing meaningful to recover
(~28 fJ at most) while its own logic costs **2.97–8.79 pJ/toggle** — ~100–300× what it
saves.

---

## 1. What was measured

All numbers are `ngspice -b`, LEVEL=1, verbatim corpus models (`NMOS1/PMOS1`,
`N_HI/P_HI`, `DD`), per-toggle = full cycle (95–135 ns) / 2. References reproduced
first: `dd_not` null↔+1 = **54.1 fJ**, +1↔−1 = **368.7 fJ** (matches `fair_binary.md`).

| case | what it is | per-toggle (fJ) |
|---|---|---|
| REF null↔+1 | dd_not, cheapest toggle (reproduce) | 54.1 |
| REF +1↔−1 | dd_not, full swing (reproduce) | **368.7** |
| STACK_ON | same output stage + series *enable switches held ON* | 448.7 |
| HELD_NULL | dd_not, input +1→null→−1 with a 5 ns null dwell | 271.9 |
| BBM output (TD 0.33–0.89 ns) | non-overlap-gated driver, output-stage supply | 340–350 |
| BBM gating (TD 0.33–0.89 ns) | the non-overlap logic + request detectors | **2972–8788** |

---

## 2. The dead-time sweep — no minimum, no collapse

`dd_not_bbm` inserts a **series enable switch** in each output branch
(`Mp`→`Mep` for pull-up, `Mn`→`Men` for pull-down) gated by a standard CMOS
non-overlap generator (`ENn = P & ~delay(N)`, `ENp = N & ~delay(P)`) whose dead time is
set by an inverter-chain delay (2→64 stages). Output-stage and gating-logic supplies
are separate, so the two energies are measured independently.

| dead time (measured) | output-stage energy (fJ/toggle) | gating-logic energy (fJ/toggle) |
|---|---|---|
| 0.33 ns | 350.4 | 2972 |
| 0.32 ns | 351.7 | 3158 |
| 0.32 ns | 350.8 | 3504 |
| 0.35 ns | 349.6 | 4217 |
| 0.46 ns | 347.8 | 5737 |
| 0.89 ns | 340.1 | 8788 |

**There is no minimum and no collapse.** The output-stage energy is flat at ~340–350 fJ
across the whole dead-time range (vs 368.7 fJ un-gated), and never approaches
2×54.2 = 108 fJ. The gating energy *rises* with dead time (more inverter stages).

Two independent facts already told us the floor is not 108 fJ:

1. **HELD_NULL = 271.9 fJ.** The cleanest possible break-before-make — sequence the
   *input* +1→null→−1 with a 5 ns null dwell, zero extra logic — only drops 368.7 →
   271.9 fJ (26%), not to 108 fJ.
2. **STACK_ON = 448.7 fJ.** Adding the series enable switches (even held permanently
   ON, no gating) already *costs* 80 fJ/toggle above the reference.

---

## 3. What the "crowbar" actually is — a leakage measurement

The decisive control: re-measure the +1↔−1 and null↔+1 toggles **with the null-return
termination removed** (Rterm=10 GΩ and no next-stage receiver; only Cl=10 fF on the
wire). Full-cycle energies over 95–135 ns:

| load | +1↔−1 | null↔+1 |
|---|---|---|
| full corpus (Rterm 100 kΩ + next receiver) | 737.5 fJ | 108.2 fJ |
| Cl only (no termination) | **50.9 fJ** | **11.9 fJ** |
| ⇒ leakage (difference) | **686.6 fJ** | 96.3 fJ |

Per toggle this is:

- **+1↔−1 = 368.7 fJ = 25.4 fJ intrinsic + 343.3 fJ leakage.**
- **null↔+1 = 54.1 fJ = 5.9 fJ intrinsic + 48.2 fJ leakage.**

The **intrinsic** cost of a full 2 V swing (25.4 fJ) is 4.3× the 1 V swing (5.9 fJ) —
exactly the ½CV² swing scaling (4×). **The shoot-through excess is ~1.7 fJ/toggle, i.e.
negligible.** The elevated-|Vt| dead zone already prevents shoot-through.

The 6.8× gap is **leakage**, and it scales with *hold time*, not swing: the +1↔−1
pulse holds a rail for 40 ns of the cycle vs 5 ns for the null↔+1 pulse, so its leakage
is ~7× larger (343 vs 48 fJ) — matching the measured 6.8×. Where does the leakage come
from? Whenever the output wire sits at ±V, the null-return termination pulls current:
Rterm (100 kΩ → 0 V) ≈ 10 µA, plus the next diode-receiver's keepers RkA/RkB
(100 kΩ each, fed through the receiver diode) ≈ 7.4 µA, total ≈ 17 µA ≈ 17 µW at 1 V.
This is the *price of the passive null return* the diode-direction design chose — it is
a static current, not a transient.

`fair_binary.md` §4's mechanism ("P_HI and N_HI conduct together") is **wrong**: the
crowbar is a hold-time leakage, not a shoot-through window.

---

## 4. Gating overhead — the honest net

- **Crowbar-saved** (best case, BBM vs un-gated reference): 368.7 − 340 = **~28 fJ**.
- **Gating-cost** (non-overlap logic + request detectors, ±1 V rails): **2972–8788 fJ**.
- **Net** = saved − cost = **−2.9 to −8.8 pJ per toggle. Strongly negative.**

Even the most generous accounting (compare BBM against STACK_ON, i.e. credit the
non-overlap with the 448.7−340 = 108 fJ it "recovers") gives net = 108 − 2972 =
**−2.9 pJ**. The gating cost is dominated by the request level-detectors (real N_HI/P_HI
devices + 100 kΩ pull resistors, which crowbar their follower inverter through the slow
rail edge) and the inverter-chain delay, all on the ternary scheme's natural ±1 V rails
(which `fair_binary.md` showed are ~7× more expensive than single-ended 0→1 V binary
logic). Running the logic on 0→1 V rails would cut the number ~7× to ~0.4–1.3 pJ but
then requires level shifters to drive the ±1 V enable switches — and 0.4 pJ is still
**14×** the ~28 fJ it saves.

---

## 5. Verdict

| question | answer |
|---|---|
| Does break-before-make recover the crowbar? | **No.** The +1↔−1 energy stays ~340–350 fJ (vs 368.7 fJ) across all dead times; even a perfect 5 ns input null-dwell only reaches 271.9 fJ. |
| Is there a dead-time minimum? | **No.** Flat, no collapse toward 108 fJ. |
| Is the dead-zone overlap the cause? | **No.** Shoot-through is ~1.7 fJ/toggle; the "crowbar" is the null-return termination leakage (Rterm + receiver keepers), which scales with rail-hold time. |
| Is the net positive? | **No.** −2.9 to −8.8 pJ/toggle. The gating costs 100–300× what it can save. |

**Bottom line.** The 6.8× +1↔−1 penalty is not a shoot-through that break-before-make
can gate away; it is the *static* null-return termination leakage the diode-direction
scheme pays whenever a polar wire holds a rail. The fix is not gating — it is to make
the null return not leak: raise Rterm/RkA/RkB (slower null return), or replace the
passive null return with a clocked/latching receiver that doesn't draw DC when the wire
is held at a rail. That is a different experiment.

### Calibration ledger

| claim | calibration |
|---|---|
| 54.1 / 368.7 fJ references | DIRECT — reproduced in this netlist |
| +1↔−1 intrinsic 25.4 fJ, leakage 343.3 fJ | DIRECT — Rterm/receiver removal control |
| shoot-through ≈ 1.7 fJ | DIRECT — 25.4 − 4×5.9 fJ (½CV² swing scaling) |
| leakage ≈ 17 µA while holding a rail | DIRECT — steady-state power 17.3 µW measured |
| gating cost 2.97–8.79 pJ | DIRECT — separate NOC supply, integrated |
| "the crowbar is hold-time leakage, not shoot-through" | DIRECT — the numbers above; this *corrects* fair_binary.md §4's mechanism (which was an inference, marked OURS/ANALOGY there) |
| gating on 0→1 V rails would be ~7× cheaper | ANALOGY — from fair_binary.md's ±1 V vs 0→1 V binary gate gap; not re-measured |

### Caveats

1. LEVEL=1, no body diodes (except default), no device mismatch — same caveat class as
   the whole corpus.
2. The +1↔−1 and null↔+1 pulses differ in *width* (20 ns vs 5 ns) as well as swing.
   This width difference is exactly what exposes the leakage: the "6.8×" is a
   hold-time artifact, not a swing artifact. A null↔+1 with a 20 ns hold would cost
   ~4×54 = 216 fJ/toggle for the same reason.
3. The request level-detectors are real elevated-|Vt| devices (matching the output
   stage's threshold); a faster digitizer would lower the gating cost somewhat but
   cannot make it competitive with a ~28 fJ saving.
4. The dead-time sweep only reached 0.33–0.89 ns (the inverter-chain delay compresses
   against the detector's own ~0.3 ns edge). This does not affect the verdict: the
   output energy is flat and the mechanism is already shown to be leakage, which no
   dead time addresses.

*Measured with ngspice 44.2, `circuit/break_before_make.cir` (`ngspice -b` exit 0, no
convergence warnings).*
