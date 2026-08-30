# Ternary vs Binary energy measurement — ngspice test harness

**Status: DRAFT / UNVERIFIED.** The netlists in this directory were written
by-construction (standard Berkeley SPICE 3 syntax) but **never executed** —
`ngspice` was not installed in the authoring environment. Every number these
files would print is a prediction until you run them. Do not quote any `.meas`
value from this README as a measurement; run the sims first.

**Claim under test** (TERNARY_PROCESSOR.md §1.2, Lean-proofed as *combinatorics*
in `proofs/lean-src/hexagon/Hexagon/TernaryCell.lean`):

> A balanced ternary trit = the **direction of current** on one wire
> (push = +1, pull = −1, null = 0 = no current), read by two antiparallel
> diodes. **"Null is free"** and **"polarity switching saves power"** (the
> Lean proof: at most one line energized, null = 0, average 2/3 of a wire vs
> binary's 1).

The Lean proof counts **energized lines**. SPICE cannot measure a count — it
measures the *physical transfer energy* of one wire driven one way or the
other. This harness is the bridge: it converts the 2/3 claim into Joules per
trit under an explicit, tunable driver model, and compares it with the
classic binary `C·V²` figure on the *same* wire capacitance.

---

## Files

| File | What it does |
|---|---|
| `ternary_cell.cir` | 4 test cases in one run: **(a) push (+1)**, **(b) pull (−1)**, **(c) null (0)**, **(d) push→pull back-to-back** (charge-recycling test). Measures `∫ V·I dt` per transfer window at the driver, receiver rail levels, demux rail levels, and idle leakage. |
| `binary_baseline.cir` | CMOS inverter driving `CL = 1.5 pF` (≈ the ternary cell's total capacitance) through the same 500 Ω wire, switching 0↔Vdd; measures `∫ V(vdd)·I(VSUP) dt` per full cycle = the textbook `C·V²`. |
| `run_all.sh` | Runs both netlists in batch mode and prints the `.meas` summaries. |

## Install

```bash
sudo apt install ngspice      # Debian/Ubuntu (the plan's assumption)
# macOS:  brew install ngspice
# verify:
ngspice --version             # want >= 37; any recent build is fine
```

(If your distro's package is old or missing, build from
https://ngspice.sourceforge.io/ — the netlists here use only long-stable
Berkeley-SPICE-3 features: `D`/`M` devices, `PULSE`, `.subckt`, behavioral
`B` sources, `.tran`, `.meas` with `INTEG`/`AVG`/`FIND`/`WHEN`/`TRIG`/`TARG`.)

## Run

```bash
cd circuit
ngspice -b ternary_cell.cir        # batch mode; .meas summary printed at the end
ngspice -b binary_baseline.cir
# or both with the measurements extracted:
./run_all.sh
```

Interactive (if you want to poke at it): `ngspice ternary_cell.cir`, then
`run`, `print all`, `plot tran v(rAp) v(rBp)`, etc. Batch output also writes
ASCII `.plot` waveforms to stdout.

## What each netlist models

### Ternary cell (`ternary_cell.cir`)

```
 DRIVER (current-mode, LVDS-like)   WIRE         2-DIODE RECEIVER
                                        R_wire=500
 push(+1): Ip=+1 mA -> dA --VsA(0V)-- drvA --/\/\/-- x --|>| D1 -- rA --RLA(500)--> gnd   (push -> rail A HIGH)
 pull(-1): Ip=-1 mA <- dB --VsB(0V)-- drvB --/\/\/-- x --|<| D2 -- rB --RLB(500)--> gnd   (pull -> rail B HIGH)
 null (0): Ip = 0                    (no current: both rails stay at 0, E ~ 0 + leakage)
                                             x --C_line(1p)--> gnd ; x --Rterm(1Meg)--> gnd (high-Z keeper)
```

- **Driver** = a current pulse (`PULSE`) — deliberately *current-mode*,
  because the claim is about the *direction of current*. This is the LVDS/CML
  idiom: the trit is the sign of the driven current. `VsA/B/N/C` are 0 V
  sense sources; a behavioral source computes `V(drv)·I(Vs)` (watts) and
  `.meas ... INTEG` integrates it over the transfer window (joules).
- **Wire** = lumped `R_wire` + `C_line` (a commented lossy transmission-line
  alternative is included). **Receiver** = the two antiparallel diodes of the
  spec: `D1` conducts on positive excursions (push→A), `D2` (the reverse
  diode) conducts on negative excursions and charges rail B *up* through
  `RLB` from ground (pull→B high). Ideal-ish diode model with small leakage
  `IS = 1e-14 A`. **Load** = `RLA`/`RLB` plus small rail caps.
- **Demux** = ideal comparators `da = 5·(V(rAp)>0.25)`, `db = 5·(V(rBq)>0.25)`
  show the *binary* rails the receiver produces: push→`da`=5, pull→`db`=5,
  null→both 0. (Real comparators cost energy; see caveats.)

Test-case timing (all in one `.tran 0..200 ns`):

| case | window | what's measured |
|---|---|---|
| (a) push | 10–16 ns | `epush` = ∫ V·I dt, +1 mA pulse |
| (b) pull | 40–46 ns | `epull` = ∫ V·I dt, −1 mA pulse |
| (c) null | 70–90 ns | `enull` ≈ 0 + `ileak_d1n/d2n/rtermn` (leakage) |
| (d) cycle | 100–111 ns | `ecyc1` (push), `ecyc2` (pull right after), `ecycT` (both) |

### Binary baseline (`binary_baseline.cir`)

```
Vdd --(PMOS)-- out --(NMOS)-- gnd ;  in drives both gates
out --R_wire(500)-- load --CL(1.5p)-- gnd
E_cycle = INTEGRAL V(vdd)·I(VSUP) dt over one full 0->1->0 cycle  =  CL·Vdd²
```

`CL` is sized to the ternary cell's total capacitance (1 pF wire + 2×0.2 pF
rail caps + diode CJO) so `C·V²` is computed on the *same physical wire*;
the same 500 Ω wire resistance is in series; same 1 V rail.

## What each `.meas` should report

> ⚠️ **UNVERIFIED estimates.** These are the textbook/ballpark numbers the
> sims should land near; the actual printed values are the measurement.

**binary_baseline.cir** (solid theory, independent of my device tweaks):
| meas | expected | meaning |
|---|---|---|
| `ecycle` | **≈ 1.5 fJ** = `CL·Vdd²` = 1.5 pF · 1 V² | the classic C·V² per cycle |
| `erise` | ≈ 1.5 fJ | supply acts only while the output rises |
| `efall` | ≈ 0 fJ | falling edge draws no supply current |
| `vout_hi`/`vout_lo` | ≈ 1.0 / ≈ 0 V | full rail swing |
| `tr_rise`/`tf_fall` | ≈ 3–5 ns | RC-limited by 500 Ω·1.5 pF |

**ternary_cell.cir** (depends on the driver model — the experiment's job):
| meas | expected (ballpark) | meaning |
|---|---|---|
| `epush` | ~1–10 fJ (sim decides) | energy of one +1 transfer |
| `epull` | ~1–10 fJ (sim decides) | energy of one −1 transfer |
| `enull` | **≈ 0** (leakage only) | null-is-free test |
| `ileak_d1n/d2n` | ~1e-14 A (= IS) | diode reverse leakage |
| `ileak_rtermn` | ~0 A | keeper draws nothing at 0 V |
| `ecyc2` vs `epull` | `ecyc2` < `epull` → **charge recycling present** | the pull right after a push recovers the line's stored charge |
| `ecycT` | ~`epush`+`ecyc2` | the full push+pull pair |
| `vrA_push` | ≈ +0.5 V | rail A asserts on push |
| `vrB_pull` | ≈ +0.5 V | rail B asserts on pull |
| `vrA_null`/`vrB_null` | ≈ 0 V | neither rail on null |
| `vda_push`/`vdb_pull`/`vdan_null`/`vdbn_null` | 5 / 5 / 0 / 0 | the binary demux truth table ✓ |

## What confirms vs. falsifies the claim — the honest statement

**"Null is free" is confirmed iff**
`enull ≪ epush` (ideally ≈ 0, i.e. no more than leakage-level energy),
and both demux rails stay at 0 through the idle window. It is **falsified**
if `enull` is comparable to `epush` — which would mean the idle driver,
keeper/termination, or diode leakage burns real energy (this is exactly the
"floating vs. driven null" question TERNARY_PROCESSOR.md §1.4/§5.1 poses).

**"Polarity switching saves power" is confirmed iff** either of these holds
at the *measured* values:

1. **Charge recycling (micro):** `ecyc2 < epull` — the pull executed
   immediately after a push needs less supply energy than an isolated pull,
   because it recovers the charge stored in the line capacitance. The
   strongest form: `ecyc2 ≤ 0` (the pull returns energy). The strongest
   form is unlikely with a real driver (headroom loss); any strictly
   smaller number is still recycling.
2. **Per-symbol average (macro):**
   `(epush + epull + enull) / 3  <  ecycle / 2`
   — the ternary cell's average per-trit transfer is cheaper than the
   binary cell's average per-bit (`ecycle/2` = C·V²/2 because one binary
   cycle carries two symbols). An even more favorable frame (if the Lean
   line-count is the claim): compare *per bit of information carried*,
   `ecycle/2 / 1` vs `(epush+epull+enull)/3 / log₂3`.

**It is falsified** if `enull ≈ epush` (null not free) **or** if
`(epush+epull+enull)/3 ≥ ecycle/2` (polarity switching doesn't beat binary on
the same wire) **or** if `ecyc2 ≥ epull` (no recycling — the model's pull is
fully dissipative, as plain RC would be).

**Do not pre-decide the outcome.** The numbers are what they are. Two honest
possibilities to expect from this exact model: (i) `enull` will indeed be ≈ 0
(null is structurally free in a zero-current idle), and (ii) the *magnitude*
of `epush`/`epull` will be dominated by the current-mode driver's static
dissipation (diode drops + wire drop + load current during the pulse width),
which may or may not clear the `C·V²/2` bar — **the sim decides.** The design
levers below are where a "win" would have to come from, and the experiment
is the test, not this README.

## Honest caveats (read before quoting any number)

1. **UNVERIFIED.** No sim has been run in the authoring environment. Treat
   every printed value as a first data point of an experiment, not a result.
2. **Ideal current source is optimistic about recycling.** The driver is an
   ideal current source: on the pull, recovered charge flows back into it
   and is credited as negative energy. A real transistor driver has a
   saturation/headroom loss, so `ecyc2` will be *less negative (or more
   positive)* in silicon. The sign and size of the effect is what the model
   is for — but the ideal-source number is an upper bound on recycling.
3. **The receiver is only costed as a load.** The diodes, rail caps and
   `RLA/RLB` appear as loads (their dissipation is real in the sim), but the
   *ideal comparator* that produces the binary `da/db` rails is free. A real
   receiver stage (comparator + level shifter) adds its own supply energy,
   which this harness deliberately excludes so the *cell* claim is isolated.
   Add it later if you want the full link budget.
4. **Pulse width is a design lever, not a constant.** In this current-mode
   model, energy scales with pulse width (static current through the diode +
   load while the pulse is on). A short, charge-transfer-style pulse
   (`PW=1n`, or better a *voltage*-mode push-pull driver) is the regime where
   the ternary cell could plausibly beat `C·V²`; a long, LVDS-style pulse is
   where it can't. To probe the charge-transfer regime: set `PW=1n` and
   swap the diode model to the commented `DSCHOTTKY` (IS=1e-9, Vf≈0.35 V).
5. **AC vs. DC coupling is not modeled.** The line here is DC-coupled with a
   1 MΩ keeper. TERNARY_PROCESSOR.md §1.4 warns that true AC coupling makes a
   held +1 decay (needing Manchester-style DC balance or refresh — a real
   energy cost not in this harness). The 1 MΩ keeper represents the "null =
   held, not floating" answer to the doc's open question §5.1; if you prefer
   floating null, delete `Rterm` and expect `enull` to still be ≈ 0 but the
   *line* to drift (and the next transfer to pay for whatever drift happened).
6. **What the Lean proof does and doesn't say.** `TernaryCell.lean` proves
   the *combinatorial* facts: `energy ≤ 1`, `null_is_free`, `average 2/3` —
   counting energized lines per symbol. SPICE measures *Joules per transfer*,
   which folds in driver model, wire R/C, diode drops, and pulse width. The
   Lean 2/3 is a lower-bound-style structural fact; whether it survives as an
   energy win is precisely the experiment this harness runs. Don't claim the
   proof implies the energy win without the sim.
7. **Apples-to-apples basis.** Binary `ecycle = CL·Vdd²` with `CL` matched to
   the ternary cell's total capacitance, same wire R, same rail voltage. The
   one asymmetry: binary swings the wire full rail (1 V); the ternary cell
   swings it only to the diode-clamped level (~1.2 V at the driver, ~0.5 V on
   the asserted rail) — that asymmetry is the interesting physics, and the
   sim measures it rather than assuming it.

## Numbers to paste into the report when you run it

```text
ternary:  epush=____ J   epull=____ J   enull=____ J   ecyc2=____ J
          (epush+epull+enull)/3 = ____ J
binary:   ecycle=____ J   (ecycle/2 = ____ J)
Verdict:  null-is-free: PASS/FAIL      recycling: PASS/FAIL
          polarity-saves-power: PASS/FAIL   (criteria in the table above)
```
