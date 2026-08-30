# Low-swing diode-direction polar ternary gates — does partial powering close the 3.4–33× gap?

**2026-08-29, ngspice 44.2, measured. Netlist: `circuit/lowswing_diode.cir` (exit 0,
no warnings, no DC shorts — null-idle energies all < 0.2 aJ). Baselines reproduced
from `circuit/diode_gates.cir` (54.2 fJ) and `circuit/fair_binary.cir` (6.94 fJ).**

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured (this run's ngspice log) or arithmetic on measured node
  voltages / counted from the netlist.
- **ANALOGY** — structural parallel, not identity.
- **OURS** — design claim / interpretation supported by DIRECT but not itself measured.
- **SPECULATION** — untested hypothesis, flagged as such.

---

## 0. One-line answer

**No.** Applying the low-swing lever to the diode-direction gate does **not** push the
54.2 fJ NOT toward binary's 6.94 fJ. The gate **dies at VDD ≈ 0.82 V** (fixed `|Vt| = 1.4 V`)
and at **≈ 0.40 V** even with a *perfectly scaled* multi-threshold device — because the
elevated-`|Vt|` dead zone and the diode forward drop are **both** fixed-voltage features
that eat the swing headroom low swing is trying to save. At the lowest *working* swing the
diode NOT is still **~5.6× binary per toggle (3.5× per bit)** — barely better than full
swing's 7.8× (4.9× per bit). The three levers do **not** compose toward the 0.63× floor:
low swing is radix-agnostic (binary gets it for free), polar's dead zone actively *resists*
low swing, and even the multi-threshold native device (which removes the diodes and the
termination) only reaches ~1.5–2× per bit — the 0.63× floor is the radix economy with the
3-level noise-margin tax omitted.

---

## 1. What was measured (three sections, one netlist)

`lowswing_diode.cir` instantiates 13 gates and measures each under the identical
fair-fight rules as `diode_gates.cir` / `fair_binary.cir` (real output driver, supply
`V·I` over a full assert+release cycle, per-toggle = cycle/2; passive diode receiver as
the explicit load; ideal input sources; LEVEL=1, no body diodes, no mismatch; cheapest
toggle `null↔+1` for ternary, `0↔1` for binary; matched swing = `VDD` in both radices):

1. **§1 — binary NOT controls** (single-ended `0→VDD`, verbatim `fair_binary.cir`) at
   `VDD = 1.00 / 0.65 / 0.40 V`. `0.65 V` is binary's *own* low-swing lever (radix-agnostic).
2. **§2 — `dd_not` with FIXED `|Vt| = 1.4 V`** (the diode-gate dead-zone device held
   fixed) at `VDD = 1.00 / 0.90 / 0.85 / 0.82 / 0.80 / 0.70 V` — the honest "just lower
   the supply, keep the fabrication ask fixed."
3. **§3 — `dd_not` with SCALED `|Vt| = 1.4·VDD`** (the "tunable multi-threshold" native
   device model: the dead zone *tracks* the swing) at `VDD = 0.65 / 0.50 / 0.40 / 0.35 V` —
   isolates "what if the multi-threshold device scales with the swing."

The `dd_not` subckt exposes its input receiver rails (`ra`, `rb`) so the dead-zone **ON
overdrive** `Vrail + VDD − |Vt|` is measured directly, not inferred.

---

## 2. The measured table

**Energy per toggle** (fJ) and **output resolution** (assert checkpoint @103 ns, null
@110 ns; rail = input push-rail assert @103 ns):

| gate | VDD (V) | Vt | E/toggle (fJ) | output @103n (V) | rail (V) | verdict |
|---|---|---:|---:|---:|---:|---:|---|
| binary NOT | 1.00 | 0.4 | **6.94** | 0 → 1.000 | — | OK |
| binary NOT | 0.65 | 0.4 | **3.57** | 0 → 0.650 | — | OK |
| binary NOT | 0.40 | 0.4 | ~0 | 0.200 (stuck) | — | **DEAD** (VDD=Vt) |
| dd_not fixed Vt | 1.00 | 1.4 | **54.09** | −0.987 | 0.756 | OK |
| dd_not fixed Vt | 0.90 | 1.4 | **39.14** | −0.876 | 0.660 | OK (weaker) |
| dd_not fixed Vt | 0.85 | 1.4 | 18.35 | −0.532 | 0.612 | **MARGINAL** (63% swing) |
| dd_not fixed Vt | 0.82 | 1.4 | 0.06 | −0.002 | 0.583 | **DEAD** |
| dd_not fixed Vt | 0.80 | 1.4 | 0.002 | ~0 | 0.564 | **DEAD** |
| dd_not fixed Vt | 0.70 | 1.4 | 0.01 | ~0 | 0.469 | **DEAD** |
| dd_not scaled Vt | 0.65 | 0.91 | **20.02** | −0.634 | 0.422 | OK |
| dd_not scaled Vt | 0.50 | 0.70 | **10.37** | −0.476 | 0.284 | OK |
| dd_not scaled Vt | 0.40 | 0.56 | 2.49 | −0.200 | 0.194 | **MARGINAL** (50% swing) |
| dd_not scaled Vt | 0.35 | 0.49 | 0.21 | −0.022 | 0.151 | **DEAD** |

Null-idle (quiet window 10–85 ns) is **1.5×10⁻¹⁹ J** (G4) and **6.4×10⁻²⁰ J** (G10) —
the null stays ~free at low swing (the DC current only flows on an *asserted* trit).

**[DIRECT — `lowswing_diode.log`; the binary 1.00/0.65 V rows reproduce `fair_binary.cir`
(6.94 / 3.57 fJ), the dd_not 1.00 V row reproduces `diode_gates.cir` (54.2 fJ).]**

---

## 3. Q1 — does low swing push 54.2 fJ toward 6.94 fJ? No. The dead zone is the wall.

Three facts, all measured:

1. **The fixed-`|Vt|` gate gets ~1.4× cheaper, then dies.** 54.1 fJ → 39.1 fJ (0.90 V),
   then the output stops reaching the rail (−0.53 V at 0.85 V, 63% of target) and the
   gate is **dead at 0.82 V** (output −2 mV, energy 0.06 fJ). It never gets within 5× of
   binary's 6.94 fJ. **[DIRECT.]**

2. **The death point is set by the dead zone, not the simulator.** The elevated-`|Vt|`
   driver turns on only when `Vrail + VDD > |Vt|`. With the measured rail `Vrail = VDD − Vf`
   (`Vf ≈ 0.244 V` at full swing — measured rail 0.756 V at `VDD = 1.0`), this is
   `2·VDD − Vf > 1.4`, i.e. **`VDD > 0.82 V`**. The measured death (0.82 V dead, 0.85 V
   marginal) matches. **[DIRECT — measured death; the `2·VDD − Vf > Vt` expression is
   arithmetic on measured voltages.]**

3. **Even a *perfectly scaled* multi-threshold device dies at ~0.40 V — the diode drop is
   a second, independent floor.** With `|Vt| = 1.4·VDD` the dead-zone ratio is preserved,
   but the ON condition becomes `VDD − Vf > 0.4·VDD`, i.e. **`VDD > Vf/0.6 ≈ 0.40 V`**.
   Measured: works at 0.50 V (10.4 fJ), marginal at 0.40 V (output only −0.20 V), dead at
   0.35 V. The Schottky rectifier's forward drop `Vf` is a *fixed* voltage that does not
   scale with swing, so **no** amount of `Vt` tuning gets the diode receiver below
   `VDD ≈ Vf`. **[DIRECT — measured death at the scaled point; the `VDD − Vf > 0.4·VDD`
   expression is arithmetic on measured voltages.]**

So the answer to Q1 is crisp: **low swing cannot move the diode gate toward binary,
because the two things that define the diode gate — the elevated-`|Vt|` dead zone and the
diode forward drop — are both fixed-voltage features that consume the swing headroom low
swing is trying to reclaim.**

---

## 4. The real reason dd_not is 7.8× binary (the DC-termination finding)

The decomposition measures (`lowswing_diode.log`, gate G4 at full swing) show the 54 fJ
is **not** `½CV²`:

| quantity | value | |
|---|---|---|
| full-cycle energy, VDD rail | +4.3×10⁻¹⁸ J | ≈ **0** (P_HI never conducts on `null↔+1`) |
| full-cycle energy, VSS rail | **108.2 fJ** | the entire toggle |
| … of which in the assert window (99–110 ns) | 108.3 fJ | all of it |
| … in the release window (110–135 ns) | −0.08 fJ | ≈ 0 (null return is passive) |
| steady-state `I(VSSg4)` @ 103.5 ns | **17.31 µA** | sustained DC |
| steady-state `I(VDDg4)` @ 103.5 ns | −0.06 µA | ≈ 0 |

The asserted output node `l4 = −0.99 V` sits between **two 100 kΩ resistors to ground** —
the null-return termination `Rterm` (100 kΩ) and the next stage's receiver keeper `RkB`
(100 kΩ, with its rail `rb4 = −0.744 V`). The DC current they draw is
`0.987 V/100 kΩ + 0.744 V/100 kΩ = 9.87 µA + 7.44 µA = 17.31 µA` — **exactly the measured
17.31 µA**. **[DIRECT — arithmetic on measured `l4 = −0.987 V`, `rb4 = −0.744 V` and the
netlist's resistor values, reproducing the measured current to <1%.]**

So the diode-direction receiver's "free null" is bought with a **resistive** load on every
*asserted* trit: the elevated-`|Vt|` driver must sink ~17 µA for the whole 5 ns assertion
(~85 fJ), against binary's pure `½CV²` (~7 fJ of capacitive charge on the same 10 fF).
That DC current — not the 2 diodes, not the elevated `Vt` per se, not the swing — is the
7.8×. It is a *circuit* cost (the null-return termination the direction receiver forces),
and it scales `∝ VDD²` (energy `= VDD·(VDD/R)·t`), so **low swing scales it down exactly
as fast as it scales binary's `½CV²` — the ratio is left standing.** (Measured `I(VSSg10)`
at 0.65 V = 10.4 µA ≈ 17.3 × 0.65, confirming the `∝V` current law. **[DIRECT.]**)

---

## 5. Q2 — which fabrication ask is binding, and does low swing reduce it?

The three asks from `diode_gates.md` §6, re-ranked by what the low-swing sweep shows:

1. **Elevated-`|Vt|` multi-threshold — BINDING, and low swing makes it *worse*, not better.**
   It is the entire null-is-a-dead-zone mechanism *and* the reason the gate cannot be
   partially powered: lowering `VDD` with `|Vt|` fixed kills the ON overdrive
   (`Vrail + VDD − |Vt|`) and the gate dies at 0.82 V (§3). The only "fix" is a **tunable**
   multi-`Vt` process (`|Vt| ∝ VDD`, §3), which is the ask itself — not a reduction of it —
   and even that hits the diode-`Vf` floor at ~0.40 V. **[DIRECT — measured death points;
   OURS — the "keep `Vt` fixed vs scale it" reading of what low swing demands.]**

2. **Schottky rectifier (`TT ≈ 0`) — a *speed* ask, partially *helped* by low swing.** The
   stored charge that pins the rail scales with forward current `∝` swing, so low swing
   *reduces* it — but the null return is also `Rterm`-limited (a 100 kΩ×10 fF = 1 µs RC,
   shorted in practice by the diode path). Low swing relaxes the Schottky ask without
   removing the termination RC. It was never the energy-binding ask. **[DIRECT for the
   `TT≈0` requirement — `diode_gates.md` §6; OURS — that low swing reduces the stored
   charge.]**

3. **Small junction (`CJO ≈ 2 fF`) — a *coupling* ask, *helped* by low swing.** The edge
   coupling into the rail is `∝ dv/dt ∝` swing, so low swing reduces it. It was never
   energy-binding either. **[DIRECT for the requirement; OURS for the low-swing effect.]**

**The binding *energy* cost is not one of the three fab asks at all** — it is the
resistive null-return termination (§4), a circuit choice the direction receiver forces,
and low swing does not remove it (it scales `∝V²` exactly like binary's load). The honest
re-ranking: the elevated-`|Vt|` ask is what *blocks* low swing; the resistive termination
is what *sets* the energy; the Schottky/small-junction asks are speed/coupling concerns
that low swing actually relaxes.

---

## 6. Q3 — can low-swing + polar + multi-threshold close the 3.4–33× gap toward 0.63×?

**No. The three levers do not compose; two of them actively conflict, and the third lands
above the floor the question names.**

The measured ratios (per toggle, and per bit after `÷log₂3 = 1.585`, vs fair single-ended
binary NOT at matched swing):

| comparison | per toggle | **per bit** |
|---|---:|---:|
| dd_not vs binary NOT, full swing (1.00 V) | 54.09 / 6.94 = **7.80×** | **4.92× worse** |
| dd_not (scaled Vt) vs binary NOT, matched 0.65 V | 20.02 / 3.57 = **5.61×** | **3.54× worse** |

**[DIRECT — arithmetic on the §2 table.]** Low swing moves the per-bit ratio from 4.9× to
3.5× — a 28% nudge, not a closure. The 0.63× floor is `1/log₂3`: the per-bit ratio you
would get **if the ternary toggle cost the same as the binary toggle**. The measured gate
is 5.6× *above* that floor at its best working swing, for three reasons that are each
physics, not tuning:

1. **Low swing is radix-agnostic.** It scales *both* sides `∝V²` (binary 6.94 → 3.57 fJ,
   dd_not 54.1 → 20.0 fJ at the same 0.65 V). A lever both radices can pull cannot close a
   per-bit gap between them. **[DIRECT — both curves measured; the "radix-agnostic"
   framing is OURS, same as `fair_binary.md` §5.]**

2. **Polar's dead zone resists low swing.** The diode-direction gate cannot even *reach*
   deep low swing: it dies at 0.82 V (fixed `Vt`) or 0.40 V (scaled `Vt`), while binary
   keeps working to 0.65 V and below on standard devices (§3). Low swing is the *wrong*
   lever for this particular gate. **[DIRECT — measured death points.]**

3. **The 0.63× floor itself is unphysical for a 3-level ordered code.** `0.63×` assumes a
   ternary toggle costs the same as a binary toggle — but three levels on one wire sit
   `V_swing/2` apart, so holding the same BER costs ~2× the energy per toggle (the
   3-level noise-margin penalty), *before* the 2-threshold information cost. That is why
   `device_circuit.md` — which *removes* the diodes and the termination and reaches
   `½CV²`-class per toggle — still lands at **~1.5–2× per bit**, not 0.63×. The honest
   native-device floor is **~1.5–2× per bit**; 0.63× is the radix economy with the
   noise-margin tax silently dropped. **[OURS/ANALOGY — `device_circuit.md` §7.2, §0; the
   0.63× = `1/log₂3` identity is DIRECT.]**

**Verdict:** low-swing + polar + multi-threshold does **not** compose toward 0.63×. Low
swing and polar conflict at the diode gate (death at 0.82/0.40 V), low swing cannot move a
per-bit ratio anyway (it is shared with binary), and the multi-threshold device, even
idealized, floors at ~1.5–2× per bit — not 0.63×. The measured 3.4–33× gap shrinks, at
best, to ~3.5× per bit (the cheapest toggle, matched low swing), and the remaining gap is
the noise-margin + 2-boundary cost that no lever in this list touches.

---

## 7. Calibration ledger

| claim | calibration |
|---|---|
| §2 table (all 13 energies, outputs, rails, null-idle) | **DIRECT** — `lowswing_diode.log` |
| binary 6.94 / 3.57 fJ reproduce `fair_binary.cir`; dd_not 54.09 fJ reproduces `diode_gates.cir` | **DIRECT** — reproduction |
| fixed-`Vt` death at 0.82 V; scaled-`Vt` death at 0.40 V | **DIRECT** — measured output collapse |
| death-condition expressions `2·VDD − Vf > Vt`, `VDD − Vf > 0.4·VDD` | **DIRECT** — arithmetic on measured rail (0.756 V) and `Vf = 1.0 − 0.756` |
| decomposition: 108.2 fJ all-VSS, 17.31 µA = 9.9 µA (Rterm) + 7.4 µA (RkB) | **DIRECT** — arithmetic on measured `l4=−0.987`, `rb4=−0.744`, resistors 100 kΩ |
| "the DC termination current is why dd_not is 7.8× binary" | **OURS** — mechanism reading of DIRECT numbers |
| "low swing scales both sides ∝V², ratio invariant" | **OURS** — the two curves are DIRECT; the invariance framing is our inference (the measured ratio moves 7.8→5.6, so it is "invariant" only approximately) |
| "elevated-`Vt` is the binding ask; low swing worsens it" | **OURS** — from DIRECT death points |
| "Schottky / small-junction asks are relaxed by low swing" | **OURS** — scaling argument; not swept |
| "0.63× = `1/log₂3`; native-device floor is ~1.5–2× per bit" | **DIRECT** identity for 0.63×; **OURS/ANALOGY** for the floor (`device_circuit.md` §7.2) |
| leakage/mismatch/body-diode cost of the elevated-`Vt` device | **SPECULATION** — LEVEL=1 models none (carried from `diode_gates.md` §6) |

---

## TODO / not covered / caveats

1. **Only `dd_not` was measured.** The 3.4–33× gap's low end is `dd_nand` (3.38× per bit,
   `fair_binary.md` §4) and its high end is the `+1↔−1` full-swing toggle (33.5×). The
   low-swing story for NAND/NOR/MIN/MAX and for the full-swing toggle is *not* re-measured
   here; `fair_binary.md` §4 shows the full-swing toggle is a dead-zone crowbar that low
   swing can only make worse (it is the same fixed-`Vt` dead zone, exercised at double the
   swing). Expect the same "dies at ~0.82 V / ratio ~invariant" shape, not a reversal.
2. **The toggle is the cheapest (`null↔+1`, half swing).** A `+1↔−1` toggle swings the
   full `2·VDD` and, per `diode_gates.md` TODO #2 and `fair_binary.md` §4, costs ~6.8× the
   null↔+1 energy at full swing. Low swing would cut it `∝V²` but cannot remove the
   crowbar; it is unmeasured.
3. **The DC-termination cost is a tunable trade, not a constant.** `Rterm = 100 kΩ` sets
   both the null-return speed (τ = Rterm·CL) and the asserted-trit DC current (`VDD/Rterm`).
   A larger `Rterm` (the lowswing_sweep's 1 MΩ) cuts the DC current 10× at 10× slower null
   return. The 54.2 fJ operating point is one point on that speed/energy trade, not an
   optimum — a slow, high-`Rterm` diode gate could approach `½CV²`, but only by trading away
   the gate's speed, which the fair fights do not count (energy only, not energy-delay).
4. **LEVEL=1 has no subthreshold leakage and no body diode.** The elevated-`Vt` device at
   the 0.4 V dead-zone margin, and the bipolar output driver, would pay leakage/offset/body
   costs in silicon that this netlist does not. Same caveat class as every prior fair fight.
5. **No device mismatch.** The 0.14 V ON-overdrive margins at the scaled low-swing points
   (e.g. rail 0.28 V at 0.50 V swing) sit near the σ≈5–20 mV process-offset floor; a real
   chip would die earlier than the ideal death points measured here.
6. **Binary at 0.40 V is dead only because `VDD = Vt`.** A real low-swing binary link uses
   low-`Vt` devices (SLVS transmitters, `lowswing_sweep.cir` VTENG pass); the point of the
   dead G3 row is the *symmetry* — low swing below the device `Vt` is equally lethal to both
   radices, so it confers no relative advantage on ternary.
7. **The decomposition is for the full-swing gate only.** The 17.3 µA → 9.9+7.4 µA split
   is computed at `VDD = 1.0`; the scaled gate's 10.4 µA at 0.65 V is consistent with
   `∝V` but its per-resistor split is not re-derived. A full (VDD, Rterm, Rk) sweep of the
   DC term is a separate task.

*Every number above is measured by `circuit/lowswing_diode.cir` (ngspice 44.2, `ngspice -b`
exit 0), reproduced from `circuit/diode_gates.cir` / `circuit/fair_binary.cir`, or counted
from the netlist; nothing is invented.*
