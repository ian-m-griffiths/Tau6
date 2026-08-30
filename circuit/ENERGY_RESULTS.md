# Ternary AC-polarity cell — energy results (2026-08-28, ngspice 44.2, measured)

The question: does a single-wire AC-polarity ternary cell beat binary CMOS on energy?

> **⚠️ CORRECTION 2 (adiabatic fair-fight, same day): the adiabatic "win" was also flattered.**
> `ternary_adiabatic_fairfight.cir` replaced the ideal ramp/LC sources with REAL drivers
> (CMOS current-source ramp, half-bridge LC switches) and the free comparator with the
> fair-fight sense amps. Verdict:
> - **The slow-ramp scheme is DEAD.** Real-driver ramp (Tr=10n/30n): **2.5-2.6 pJ per
>   transition — 3.5× WORSE than binary, ~2× worse than even the non-adiabatic fair
>   fight (1.20 pJ)**. The 0.165-0.30 pJ claim was ~90-95% ideal-source flattery: a real
>   FET generating the ramp burns (Vrail−Vline)·I for the whole ramp (channel loss
>   1.3-3 pJ/phase), and a fixed DC rail can never accept the "returned" charge — the
>   original's 72% recovery existed only because the ideal source absorbed at the line
>   voltage. The ramp made the driver-channel loss WORSE, not better.
> - **The LC-resonant scheme SURVIVES.** Real half-bridge switches + real receiver:
>   **0.210 pJ/trit (L=40µH, ~40 Mtrit/s) and 0.266 pJ/trit (L=9.4µH, ~81 Mtrit/s) —
>   4.5-5.6× better than binary (0.748 pJ/bit), 0.13-0.17 pJ/bit** (÷log₂3). The pull
>   phase is free (measured ~0) and the reset phase RECOVERS −0.225 pJ (measured) —
>   the ring energy genuinely oscillates in the LC tank and only the R/Z0 loss escapes.
> - Caveats: (a) recovery needs a power-clock that accepts the return (plain DC supply
>   → 0.36 pJ/trit, still 2× better than binary); (b) the null needs rail equalization
>   (~0.05 pJ; the 1 MΩ rails hold their assert for τ≈200 ns — the original never
>   measured the null); (c) the pull switch needs body isolation + negative gate drive
>   (real-process fix) — without it the off-switch conducts on the negative swing and
>   dumps ~2.5 pJ (same class of bug as the fair-fight's body-diode caveat).
>
> **⚠️ CORRECTION 1 (fair-fight check, same day): the "win" below is CELL-ONLY and was
> flattered by ideal sources.** With a REAL driver (±1.0 V rails, channel loss counted) and a
> REAL receiver (2× sense amps), the honest per-transfer energy is **1.20 pJ — 1.61× WORSE
> than binary** (0.748 pJ/bit), a dead heat per bit-of-info at absolute best. The ideal
> current source had hidden ~0.61 pJ/transfer of driver channel loss (+114%). **Null remains
> nearly free (0.05 pJ).** So: null-free ✓, recycling ✓, but the *driver* is the wall, and the
> ternary cell does NOT beat binary in this circuit family. See `ternary_fairfight.cir` and
> `ternary_fairfight.log`. The table below is the cell-only story, kept for the mechanism
> decomposition but NOT the final energy verdict.
>
> **✅ RESOLUTION (null carries information — Ian's correction):** the "1.61× worse" above
> treats every trit as a ±1. But a trit is {−1,0,+1}, and **null costs 0.05 pJ (24× cheaper
> than a ±1)**. With null as a DATA-BEARING symbol (which balanced ternary gives — 0 is a real
> value), the correct average is: **uniform: (1.20+1.20+0.05)/3 = 0.817 pJ/trit = 0.515 pJ/bit
> → 31% BETTER than binary** (0.748 pJ/bit); Zipf/null-dominated data → ~0.32 pJ/bit → 57%
> better. **So ternary WINS on average, because the null is free and carries information.**
> The ±1 driver cost (0.61 pJ channel loss) is still the thing to attack (adiabatic), but the
> verdict is a win, not a loss.

## The full measured table (energy per trit TRANSITION, vs binary 0.75 pJ/bit-transition)

| Receiver / driver | per-transition | vs binary | speed |
|---|---|---|---|
| ideal diode, sharp 3 ns pulse, 500 Ω sink | 5.36 pJ | 7.2× worse | ~130 MHz |
| single MOSFET-diode, charge-transfer (1 ns, 100 Ω) | 0.66 pJ | 1.13× better | ~130 MHz |
| Schottky diode, swept (1 ns, 100 Ω, 1 mA) | 0.59 pJ | 1.27× better | ~130 MHz |
| **N=4 paralleled MOSFET-diodes** (1 ns, 100 Ω) | **0.562 pJ** | **1.33× better** | ~130 MHz |
| adiabatic ramp (Tr=10 ns) + 1 MΩ cap receiver | 0.30 pJ | 2.5× better | ~23 MHz |
| **adiabatic ramp (Tr=30 ns) + 1 MΩ cap receiver** | **0.165 pJ** | **4.5× better** | ~8 MHz |
| resonant LC (L=40 µH) + 1 MΩ cap receiver | 0.176 pJ | 4.2× better | ~15 MHz |
| — FAIR-FIGHT rows (real drivers + sense-amp receiver) — | | | |
| ~~adiabatic ramp (Tr=10 ns)~~ real CMOS ramp driver | 1.90–3.80 pJ | 2.5–5.1× worse | ~25 MHz |
| ~~adiabatic ramp (Tr=30 ns)~~ real CMOS ramp driver | 1.85–3.70 pJ | 2.5–4.9× worse | ~12 MHz |
| **resonant LC (L=40 µH) + real half-bridge switches** | **0.210 pJ** | **3.6× better** | ~40 MHz |
| **resonant LC (L=9.4 µH) + real half-bridge switches** | **0.266 pJ** | **2.8× better** | ~81 MHz |

Per bit of information (÷ log₂3 ≈ 1.585): the cell-only winner is **~0.10 pJ/bit ≈ 7× below binary**;
the FAIR-FIGHT winner is the **LC-resonant at 0.13–0.17 pJ/bit ≈ 4.5–5.6× below binary** (ramp rows
are 1.58–1.63 pJ/bit — 2.1–2.2× worse than binary and ~2× worse than the fast fair-fight 1.20 pJ).

## The two regimes (both real, both beat binary)

1. **Fast charge-transfer** (~130 MHz): the winner is **N=4 paralleled diode-connected
   MOSFETs at 0.562 pJ** (1.33× better). Mechanism: short 1 ns pulse kills the static
   V·I·t term; low-swing 0.36 V drop; paralleling divides R_on by N (overdrive ∝ 1/√N).
   This is Ian's "paralleling MOSFETs" insight, now measured.
2. **Slow adiabatic** (~8–23 MHz): ramp/resonant drive + a capacitive (1 MΩ) receiver lands
   0.165–0.30 pJ (4.5× better), trading speed for energy (textbook adiabatic). The pull
   phase costs ~0 and the down-ramp returns ~72% of the charge.

## The honest strings

- The 7× → win flip required **two fixes**: (a) charge-transfer pulse (not static current),
  (b) a low-swing transistor receiver or a capacitive rail — NOT the naive 500 Ω resistive
  diode sink (whose ~1 mA static assert current is the wall; adiabatic can't rescue it alone).
- The winning swing is **±0.27 V** (vs binary 1 V) — low-swing, noise-margin-limited, SLVS
  territory. Relax the comparator to 0.1 V and the charge-transfer winner drops further.
- Adiabatic speed cost is 5–20×; the LC scheme is timing-critical (switch at π√(LC)).
- Recovery is credited to ideal sources; real drivers + a real sense/latch add cost
  (excluded here, same as the baseline's free-comparator caveat).
- **Adiabatic fair-fight (measured, `ternary_adiabatic_fairfight.cir`): the ramp's
  "recovery" was ~100% ideal-source fiction — a fixed DC rail never accepts the returned
  charge, and the current-source FET burns (Vrail−Vline)·I for the whole ramp (ramp ends
  up ~2× WORSE than the fast fair-fight driver). The LC-resonant recovery IS real (the
  ring energy oscillates in the tank; measured −0.225 pJ on the reset) — it beats binary
  4.5-5.6×, but needs a power-clock that accepts the return and the null needs rail
  equalization (~0.05 pJ; the 1 MΩ rails hold their assert for τ≈200 ns).

## The break-even (Lean-proved, `Hexagon/EnergyModel.lean`)

`ternary beats binary ⇔ p_null > 1 − E_binary/E_ternary`. At the naive 5.36 pJ this needs
**77.8% nulls** (a loss in practice); at the 0.562 pJ winner, `E_ternary < E_binary`, so
**the win is unconditional** — nulls are pure upside on top.

## Key files
- `ternary_cell.cir` — naive baseline (5.36 pJ, null free, 50% recycling).
- `ternary_sweep.cir` — 96-combo sweep → Schottky winner 0.59 pJ.
- `ternary_transistor.cir` — MOSFET-diode (3.86 pJ) + paralleled N=4 (0.562 pJ).
- `ternary_adiabatic.cir` — ramp/LC drive + high-Z receiver (0.165–0.30 pJ; cell-only, ideal sources).
- `ternary_adiabatic_fairfight.cir` — the ADIABATIC fair fight (real ramp driver / real half-bridge
  LC switches + sense-amp receiver): ramp 2.5-2.6 pJ/trit (dead), LC 0.21-0.27 pJ/trit (alive).
- `ENERGY_IDEAS.md` — the ranked technique survey; `PHYSICAL_NOTES.md` — MOSFET-vs-diode rule.
- `proofs/.../EnergyModel.lean` — the decomposition + break-even theorem.

## PAM-4 fair fight (2026-08-28, ngspice 44.2, measured — `pam4.cir`)

**The question:** does "more levels per symbol" (PAM-4, 2 bits/symbol, no free null) beat
"free null" (ternary, 1.585 bits/symbol, null = 0.05 pJ)? Same honesty rules as the ternary
fair fight: real binary-weighted CMOS driver on ±1.0 V rails producing 4 levels
(+0.659/+0.236/−0.233/−0.657 V), real receiver (3 comparators → 2 bits), wire + load matching
the ternary cell (rwire=100, cline=1p, rterm=1Meg, 0.2p receiver cap).

**Measured (uniform 4-level, one activation from rest per symbol):**

| Symbol | level | E_drv | E_gate | E_rec | E_symbol |
|---|---|---|---|---|---|
| +3 (strong PMOS) | +0.659 V | 0.795 pJ | 0.016 pJ | 0.231 pJ | 1.042 pJ |
| +1 (weak PMOS) | +0.236 V | 0.282 pJ | 0.005 pJ | 0.244 pJ | 0.531 pJ |
| −1 (weak NMOS) | −0.233 V | 0.282 pJ | 0.002 pJ | 0.273 pJ | 0.557 pJ |
| −3 (strong NMOS) | −0.657 V | 0.794 pJ | 0.008 pJ | 0.279 pJ | 1.081 pJ |

**Average: 0.803 pJ/symbol → 0.401 pJ/bit** (2 bits/symbol).

| scheme | pJ/bit | vs binary | vs ternary |
|---|---|---|---|
| binary | 0.748 | 1.00× | — |
| ternary (null-carrying, uniform) | 0.515 | 1.45× better | 1.00× |
| **PAM-4** | **0.401** | **1.86× better** | **1.28× better (+22%)** |

**Verdict: "more levels" BEATS "free null" in this circuit family — but by 22%, not the
naive ~2×.** Decomposition:

- **The driver amortization is real and is where the win lives:** PAM-4 driver+gate =
  0.273 pJ/bit vs ternary's 0.504 pJ/bit — 1.85× cheaper per bit, exactly the 2-bits-per-
  activation effect. Inner levels (0.28 pJ each) are the bargain; ternary's ±1 trits
  always pay full swing (1.20 pJ).
- **The "receiver is cheap" assumption FAILS — this is the big finding.** The ternary's own
  sense amp cannot resolve PAM-4's ±0.447 V midpoint comparisons at all: the references put
  the PMOS input pair in triode, the latch loop gain drops below 1, and the comparator sticks
  at a stable 13–46 mV differential forever (verified with 4× cross-coupling and 8 ns eval;
  only the 0-referenced comparator latches directly). The 4-level receiver therefore needs a
  preamp front end (clocked PMOS diff pair, resistive loads) to re-center the comparisons to
  ~0.25 V common mode — 3 preamp+SA comparators at **0.257 pJ/symbol = 0.128 pJ/bit**, 4× the
  ternary's 0.032 pJ/bit. The receiver is no longer a rounding error.
- **Speed:** PAM-4 symbol = 1 ns pulse + 2 ns eval = 3 ns (0.67 bit/ns); ternary ≈ 2–2.5 ns
  per trit (0.63–0.79 bit/ns). Roughly a wash; PAM-4 wins energy, not speed.
- **Noise margin (not in the toy model):** PAM-4's worst margin is ~0.21 V (inner levels vs
  midpoints) vs binary's 0.5 V and ternary's 0.25 V rails — ~7.5 dB worse SNR than binary.
  Real links would need equalization/offset calibration; the model's energy win assumes the
  link can close at these margins.
- **Stream correction:** iid-uniform transitions average |ΔV| = 0.55 V → ~0.47 pJ/bit (still
  beats ternary, thinner). From-rest is the harness convention for all three schemes.

**8 levels would give ~0.33 pJ/bit (extrapolated):** avg |V| = 0.36 V → driver 0.44 pJ +
7 comparators ≈ 0.54 pJ/symbol → 0.99 pJ/symbol ÷ 3 bits ≈ 0.33 pJ/bit. That's only 17%
better than PAM-4 while halving the noise margin (0.18 V spacing) and making the receiver
(7 comparators) the dominant cost — 16 levels would be WORSE. **PAM-4 is near the sweet
spot; the comparator count and noise margin are the walls, not the driver amortization.**

**Files:** `pam4.cir` (netlist, fully commented), `pam4.log` (measurements).

## PWM-5 fair fight (2026-08-29, ngspice 44.2, measured — `pwm5.cir`)

**The question:** Ian's "polarity × pulse-width" idea — 5 symbols {long−, short−, null,
short+, long+} = log₂5 ≈ 2.32 bits/symbol, with the claim that the SHORT pulse only needs
to be detectable (not a full clock), so energy ∝ pulse duration, not clock. Same honesty
rules as the ternary/PAM-4 fair fights: real CMOS driver on ±1.0 V rails (WP=11u, the ternary
winner's operating point), verbatim `tcell4` (rwire=100, cline=1p, RLA=500, rterm=1Meg),
real receiver = 3 comparators (2 polarity sense amps + 1 length comparator on the rail, the
cell's charge-integral readout of pulse width; the PULL length comparator needs an NMOS-input
mirror SA with a ±1 V clock because the PMOS sense amp dies below ~−0.15 V common mode).

**Measured (φ: short=1.0 ns, long=1.618 ns, eval at 1.7 ns after symbol start, THRLEN=0.22 V;**
one activation from rest per symbol; E_gate = |Q_gate|×VDD, ternary convention):

| Symbol | E_drv | E_gate | E_rec | E_symbol |
|---|---|---|---|---|
| +long | 1.603 pJ | 0.024 pJ | 0.096 pJ | 1.724 pJ |
| +short | 1.131 pJ | 0.023 pJ | 0.097 pJ | 1.251 pJ |
| −long | 1.602 pJ | 0.012 pJ | 0.296 pJ | 1.910 pJ |
| −short | 1.130 pJ | 0.012 pJ | 0.253 pJ | 1.395 pJ |
| null | ~0 | 0 | 0.100 pJ | 0.100 pJ |

**Average 1.276 pJ/symbol → 0.550 pJ/bit** (÷2.322). All 5 demuxes resolve with margin
(dA push / dB pull / dL long: +long +0.68/+0.11/+0.67; +short +0.57/+0.14/−0.78;
−long +0.35/+0.43/+1.68; −short +0.31/+0.38/−1.78; null +0.01/−0.01/−0.78).

| scheme | pJ/bit | vs binary | vs ternary | vs PAM-4 |
|---|---|---|---|---|
| binary | 0.748 | 1.00× | — | — |
| ternary (null-carrying, uniform) | 0.515 | 1.45× better | 1.00× | — |
| **PWM-5 (polarity×width, φ)** | **0.550** | **1.36× better** | **0.94× (6% WORSE)** | — |
| **PAM-4** | **0.401** | **1.86× better** | 1.28× better | 1.00× |

**Verdict: the polarity×width idea does NOT beat ternary or PAM-4 in this cell family —
0.550 pJ/bit is 6% worse than ternary and 37% worse than PAM-4, only 27% better than
binary.** The density win (2.32 bits/symbol) is real but doesn't pay for two costs the
idea ignores:

1. **The LONG symbol is not free.** E_drv grows ~0.85 pJ per ns of pulse (measured
   `pwm5_pwscale.cir`: E_drv 1.131 pJ at 1.0 ns → 1.871 pJ at 2.0 ns, linear). The 1.62 ns
   long pulse costs 1.60 pJ vs the ternary's 1.13 pJ trit — the extra pulse time is pure
   channel loss (VDD−Vline)·I. "Energy ∝ pulse, not clock" is VERIFIED (the 60 ns clock
   contributes zero), but that's the problem, not the win: the pulse is the energy.
2. **The length detector receiver is not free.** 3 comparators instead of 2, and the PULL
   length comparison sits at −0.25 V common mode where the stock PMOS sense amp cannot
   latch (measured: dies below ~−0.15 V CM) — it needs an NMOS-input mirror comparator with
   a ±1 V clock (E_rec 0.25–0.30 pJ vs ternary's 0.05 pJ). A fixed 5-symbol receiver pays
   the pull-side cost on every symbol: ~0.60 pJ/bit.

**The φ vs 1.5× sweep (`pwm5_ratiosweep.cir`):** with a fixed receiver schedule (eval at
1.7 ns, THRLEN=0.22 V), RATIO = 1.3/1.4/1.5 FAIL to decode the +long symbol (dL reads
short: the long rail at the eval edge is already decaying — the driver must still be ON at
the threshold time, so LONGPW+0.2 ns > 1.7 ns → RATIO > 1.5). RATIO ≥ 1.618 decodes
cleanly. **φ "beats" 1.5× on decodability, not energy** — the long-symbol driver energy
rises monotonically with ratio (1.518 pJ at 1.5×, 1.603 at φ, 1.871 at 2.0×), so the
energy-optimal ratio is the smallest decodable one, and φ ≈ that knee (the RC floor
pushes it there, not golden-ratio mysticism).

**Speed:** symbol = 1.7 ns (threshold-time eval) + 1.5 ns eval + guard ≈ 3.5–4 ns
(2.32 bits/3.75 ns ≈ 0.62 bit/ns) — about PAM-4's 0.67 and ternary's 0.63–0.79. The
short-pulse energy saving does NOT buy a faster clock; the LONG pulse and the eval-after-
long set the rate (same as any PWM).

**RC floor (`pwm5_pwscale.cir`):** the rail assertion collapses below ~0.6–0.8 ns pulses
(the line never reaches the diode-leg turn-on before the driver releases: rail 0.10 V at
0.3 ns, 0.19 V at 0.75 ns, 0.25 V at 1.0 ns). SHORTPW = 1.0 ns is already at the floor —
the "short only needs to be detectable" refinement cannot shorten below ~1 ns in this
cell, so it does not escape the driver's ~1.13 pJ/pulse cost.

**Caveats (same class as prior fair fights):** LEVEL=1 models, no body diodes (a real
bipolar driver needs body isolation); references are gate loads (shared across lanes);
per-case receiver instances (a fixed 5-symbol receiver costs more, see above); timing
skew between the transmitter's pulse edge and the receiver's threshold-time sample is a
real-world margin concern (the window is ~0.3–0.6 ns at φ).

**Files:** `pwm5.cir` (netlist, fully commented), `pwm5_ratiosweep.cir` (ratio sweep),
`pwm5_pwscale.cir` (pulse-width energy scaling + RC floor), `pwm5.log`,
`pwm5_ratiosweep.log`, `pwm5_pwscale.log`.

## Low-swing (partial-powering) sweep (2026-08-29, ngspice 44.2, measured — `lowswing_sweep.cir`)

**The question (Ian's insight):** "partially powered interface — reduce what goes through
the bus (low swing), power the receiver locally." Wire energy falls with swing while the
receiver must resolve a smaller differential — is there a sweet-spot swing, and where is
the crossover where wire-energy-savings == receiver-energy-cost?

**The harness (fair-fight honesty rules):** lower the driver rail VDDR on the SAME
fair-fight ternary link (real CMOS push-pull driver, verbatim `tcell4` with rwire=100,
cline=1p, rterm=1Meg, 0.2p rail caps) while the receiver is powered LOCALLY at vddsa=1.0 V
(the "power the receiver locally" part). Two receiver front-ends are measured at every
swing: the ternary's own **SA-only** receiver (2× sense amp reading the rails vs 0) and
the **preamp+SA** receiver (the pam4.cir fix: clocked PMOS diff-pair preamp + the same SA).
E_wire = driver supply energy (line charge + channel loss) + gate charge; E_iface =
receiver supply energy per evaluation; totals averaged over push/pull/null trits (null ≈
free, receiver only); pJ/bit = ÷log₂3 = ÷1.585. Resolution = latch differentials at the
1 ns (SA) / 2 ns (preamp) eval vs a ±4 mV null baseline: OK ≥ 10 mV, FAIL < 5 mV or wrong
sign. This ngspice build has no `.step`, so `run_lowswing_sweep.sh` runs the 29 points
externally; **every point converged (exit 0) — no swing failed to converge.**

**Two driver families** (receiver identical in both):
- **FAIR** — the fair-fight driver (VTO=±0.4, KP 200u/100u, WP=11u fixed): partial
  powering = same driver, lower rail. The honest "just lower the bus rail" curve.
- **VTENG** — VT-engineered driver (VTO=±0.1, WP resized ∝ 1/Vov² to keep ~1 mA drive):
  real low-swing links need low-VT devices (SLVS transmitters use 0.15–0.25 V Vt); with
  VTO=0.4 the driver is dead below VDDR≈0.5 V (Vov ≤ 0.1), so this pass is the only way to
  reach the low-swing steps. LEVEL=1 has no subthreshold leakage — below ~0.1 V overdrive
  the wide low-VT drivers are flattered.

**Measured table** (swing = driver rail; line = delivered wire swing at the plateau;
rail = ternary demux rail assert; energies in pJ/trit; pJ/bit = ÷1.585; ipk/di/dt = push):

| mode | VDDR | line | rail | wire-E | iface-E | **total** | **pJ/bit** | SA res | ipk | di/dt |
|---|---|---|---|---|---|---|---|---|---|---|
| FAIR | 1.00 V | 0.672 V | 0.220 V | 0.765 | 0.050 (SA) | 0.816 | **0.515** | OK (0.63) | 1.26 mA | 56 A/µs |
| FAIR | 0.90 | 0.527 | 0.112 | 0.507 | 0.051 | 0.558 | 0.352 | OK (0.57) | 0.90 | 51 |
| FAIR | 0.80 | 0.348 | 0.059 | 0.293 | 0.052 | 0.344 | 0.217 | OK (0.09) | 0.60 | 45 |
| FAIR | 0.75 | 0.267 | 0.044 | 0.211 | 0.052 | 0.262 | 0.165 | OK (0.05) | 0.47 | 42 |
| FAIR | 0.70 | 0.196 | 0.032 | 0.145 | 0.052 | 0.196 | 0.124 | OK (0.04) | 0.37 | 40 |
| **FAIR** | **0.65** | **0.136** | **0.022** | **0.094** | **0.052** | **0.145** | **0.092** | OK (0.03) | 0.27 | **37** |
| FAIR | 0.60 | 0.087 | 0.014 | 0.056 | 0.051 | 0.108* | 0.068* | MAR (0.02/0.01) | 0.20 | 34 |
| FAIR | 0.50 | 0.021 | 0.003 | 0.013 | 0.051 | — | — | **FAIL** | 0.09 | 28 |
| FAIR | ≤0.45 | ~0 | ~0 | ~0 | 0.051 | — | — | **FAIL** (driver dead: Vov≤0) | <0.06 | <26 |
| VTENG | 0.60 | 0.487 | 0.101 | 0.332 | 0.051 | 0.383 | 0.242 | OK | 1.21 | 45 |
| VTENG | 0.40 | 0.367 | 0.076 | 0.170 | 0.051 | 0.222 | 0.140 | OK | 1.27 | 84 |
| VTENG | 0.30 | 0.287 | 0.064 | 0.110 | 0.052 | 0.162 | 0.102 | OK | 1.38 | 141 |
| VTENG | 0.25 | 0.243 | 0.057 | 0.087 | 0.051 | 0.138 | 0.087 | OK | 1.53 | 209 |
| **VTENG** | **0.20** | **0.197** | **0.048** | **0.072** | **0.051** | **0.123** | **0.078** | OK (0.11) | 1.90 | **376** |
| VTENG | 0.15 | 0.149 | 0.037 | 0.079 | 0.051 | 0.130 | 0.082 | OK (0.20) | 3.55 | **1128** |
| VTENG | ≤0.10 | ~0 | ~0 | ~0 | 0.051 | — | — | **FAIL** (driver dead: Vov≤0) | — | — |

\* = SA-only total at 0.60 V with the pull latch at only 8.4 mV (2× the 4 mV null baseline) —
marginal; the preamp+SA receiver resolves there but costs 0.195 pJ → total 0.251 pJ/trit
(0.158 pJ/bit), i.e. **worse** than the 0.65 V point. SA res = push/pull latch differential
(V) at the eval time.

**The crossover and the minimum:**

- **FAIR crossover (wire-savings == receiver-cost):** VDDR ≈ **0.60–0.65 V** (line ≈
  0.09–0.14 V, rail assert ≈ 14–22 mV). Above it the total is wire-dominated and falling;
  at 0.65 V wire-E (0.094 pJ) ≈ 2× iface-E (0.052 pJ); at 0.60 V wire-E (0.056 pJ) has
  crossed below iface-E (0.051 pJ) — **the receiver is now the floor and the total has
  bottomed out**. The **minimum-total swing is VDDR = 0.65 V: 0.145 pJ/trit = 0.092 pJ/bit**
  (SA receiver, 1 ns eval — no speed change).
- **The preamp is never a win for the ternary.** The SA resolves down to rail ≈ 20 mV
  (measured OK at 22 mV, marginal at 14 mV, ±4 mV null baseline). The preamp+SA extends
  resolution below that (to ~2–5 mV) but at +0.14 pJ/trit — and one more swing step below
  the SA floor (0.65→0.60 V) saves only 0.038 pJ of wire: **net loss of 0.10 pJ/trit.**
  The receiver does NOT become the wall before the driver does.
- **Why the pam4 preamp lesson doesn't transfer:** the ternary compares *rail vs 0* — low
  common mode, PMOS input pair deep in saturation, the latch regenerates at rail ≥ ~15 mV.
  PAM-4 needed the preamp because its ±0.447 V *references* put the same input pair in
  triode (high common mode) — a common-mode problem, not a small-swing problem.
- **VTENG minimum:** VDDR = 0.20 V → 0.123 pJ/trit = **0.078 pJ/bit** (SA, rail 48 mV,
  dA = 0.11 V); 0.15 V gives 0.082 pJ/bit (rail 37 mV, dA = 0.20 V — the SA resolves hard
  even there). The SA floor lies *below* the driver's VT floor, so in both passes **the
  driver — not the receiver — is the binding wall.**

**Verdict: low-swing wins, big, and the wall is the driver VT, not the receiver.**

1. **How much:** partial powering the fair-fight driver at VDDR = 0.65 V (line 0.14 V,
   rail 22 mV) gives **0.092 pJ/bit — 5.6× better than the ternary fair-fight baseline
   (0.515), 8.1× better than binary (0.748), and better than the LC-resonant adiabatic
   fair fight (0.13–0.17 pJ/bit) with none of its power-clock/timing constraints.** The
   0.65 V point is the old "±0.27 V winning swing" in spirit (rail 22–32 mV vs the 0.25 V
   rail of the ±1.0 V driver) — the fair fight's 1.20 pJ/transfer was dominated by driver
   channel loss, and partial powering kills exactly that term.
2. **The price (noise margin):** the latch differential at the minimum is 17–25 mV vs the
   ±4 mV null baseline (~4–6×) and vs 630 mV at full swing — a ~25× noise-margin
   reduction. These LEVEL=1 models have no device mismatch; a real chip's offset (σ ≈
   5–20 mV at these sizes) would push the practical floor up to VDDR ≈ 0.8–0.9 V (rail
   60–110 mV, latch 90–570 mV) → ~0.22–0.35 pJ/bit. The old "rail ≥ 0.25 V" README rule
   of thumb is ~10× more conservative than what the SA actually needs.
3. **The price (di/dt):** with the SAME driver (FAIR), peak current and di/dt both FALL
   with the swing (1.26 mA / 56 A/µs → 0.27 mA / 37 A/µs) — partial powering is
   di/dt-friendly. The VT-engineered pass is the opposite: keeping ~1 mA of drive at 0.1 V
   overdrive needs W = 400–1600 µm, and di/dt explodes to **376–1128 A/µs (7–20× the
   full-swing driver) with 1.9–3.5 mA peaks** — the "faster slew on a smaller swing can
   still make di/dt worse" caveat is CONFIRMED for the low-VT route. Those huge-W drivers
   also show LEVEL=1 Meyer-cap turn-off charge injection (line bumps up to 0.11 V, ~44% of
   the swing at VDDR=0.15 V) — an extra noise/energy cost a real process would pay.
4. **The floor on how low you can go:** with VTO=0.4 driver devices the push is physically
   dead below VDDR ≈ 0.5 V (Vov ≤ 0.1, LEVEL=1 hard cutoff) — the ±0.27/0.2/0.15/0.1/0.05 V
   swing steps are **unreachable with the fair-fight driver**; that's a device-wall result,
   not a simulator failure. Reaching them needs VT-engineered drivers (VTENG pass), which
   reach VDDR = 0.15 V but die at 0.10 V (Vov = 0) and buy only 0.078 vs 0.092 pJ/bit for
   the di/dt/injection pain. The cell's diode drop also pins the demux rail at ~15% of the
   line swing (rail ≈ 0.15·line at low line), so the bus cannot usefully swing below ~0.1 V
   in this topology.

**Files:** `lowswing_sweep.cir` (master netlist, fully commented; `ngspice -b` at the
default VDDR=1.0 point exits 0 and reproduces the fair fight), `run_lowswing_sweep.sh`
(external 29-point driver), `lowswing_sweep.log` (all 29 per-point measurement logs),
`analyze_lowswing.py` (table + crossover extraction).

## PWM-5 2D (amplitude×duration) fair fight (2026-08-29, ngspice 44.2, measured — `pwm5_2d.cir`)

**The question (Ian's proposal):** pwm5.cir's length-only 5-symbol scheme lost (0.550 pJ/bit)
because the LONG pulse pays ~0.85 pJ/ns of extra channel loss and the length-detector receiver
is expensive. Ian's fix: separate the two nonzero magnitudes in the **(V,t) PLANE**, not the
t line alone — (a) amplitude-distinguished (both pulses ~1 ns, different rail voltages), and
(b) "long-LOW vs short-HIGH" (opposite corners: weak driver pulsed long, strong driver pulsed
short). Physics under test: detectability ~ area (V·t), but time costs LINEARLY (~0.85 pJ/ns,
verified `pwm5_pwscale.cir`) while voltage costs QUADRATICALLY (½CV² + channel loss) — so the
long-low corner should deliver equal detectability for less energy.

**Harness (identical honesty rules to pwm5.cir):** real CMOS push-pull on ±1.0 V rails with
per-symbol driver width (NMOS = PMOS/2), verbatim `tcell4` (rwire=100, cline=1p, RLA=500,
rterm=1Meg, 0.2p rail caps), real receiver = 2 polarity sense amps + 1 magnitude comparator
(rail vs ±THR; the PULL magnitude comparator is the NMOS-input mirror SA with a ±1 V clock).
E_drv = driver supply energy, E_gate = |Q_gate|×VDD, E_rec = receiver supply; pJ/bit = avg
÷ log₂5 = ÷2.322. No preamp used (all comparisons sit at ≤0.23 V common mode).

**Measured (per-symbol, pJ; one activation from rest):**

**Variant (a) — amplitude-distinguished, both at 1.0 ns:**

| config | +H | +L | −L | −H | null | avg | pJ/bit | resolves? |
|---|---|---|---|---|---|---|---|---|
| A: low=11u (0.142 V) / high=21u (0.218 V), THR 0.18 | 1.750 | 1.254 | 1.420 | 1.906 | 0.103 | 1.286 | 0.554 | **NO** — L-comp latches LOW for both magnitudes (dL = −0.736/−0.738/−1.74/−1.74): ±0.038 V input diff is below the SA's resolution cliff |
| A2: high=25u (0.232 V), THR 0.19 | 1.859 | 1.253 | 1.414 | 2.005 | 0.102 | 1.326 | 0.571 | **NO** — same (diff ±0.042 V) |
| A3: low=8u (0.092 V) / high=25u (0.232 V), THR 0.157 | 1.865 | 0.995 | 1.178 | 2.061 | 0.104 | 1.241 | 0.534 | **YES, barely** — widest gap 1.0 ns can give (diff 0.065–0.075 V): dL +0.61/−0.71/+1.63/−1.72; but low-symbol rail is 92 mV and margins are thin |

**Variant (b) — long-LOW vs short-HIGH (opposite corners):**

| Symbol | (W, PW) | rail@eval | E_drv | E_gate | E_rec | E_symbol |
|---|---|---|---|---|---|---|
| +H (short-high) | 11u @ 1.0 ns | +0.142 V | 1.131 | 0.023 | 0.107 | **1.261** |
| +L (long-low) | 3.67u @ 1.618 ns | +0.048 V | 0.646 | 0.007 | 0.106 | **0.760** |
| −L (long-low) | 3.67u @ 1.618 ns | −0.048 V | 0.646 | 0.004 | 0.335 | **0.985** |
| −H (short-high) | 11u @ 1.0 ns | −0.142 V | 1.130 | 0.012 | 0.358 | **1.500** |
| null | — | ~0 | ~0 | 0 | 0.108 | **0.108** |

**Average 0.923 pJ/symbol → 0.397 pJ/bit** (÷2.322). ALL 5 symbols resolve with the stock
sense amps, no preamp (demux dA/dB/dL: +H +0.571/+0.135/+0.559; +L +0.517/−0.072/−0.638;
−L −0.073/+0.245/−1.65; −H +0.310/+0.375/+1.59; null +0.013/−0.006/−0.639).

| scheme | pJ/bit | vs binary | vs ternary | vs PAM-4 |
|---|---|---|---|---|
| binary | 0.748 | 1.00× | — | — |
| ternary (null-carrying) | 0.515 | 1.45× | 1.00× | — |
| **PWM-5 (length-only)** | **0.550** | 1.36× | 0.94× | — |
| PWM-5-2D (a) amplitude | 0.534 (A3, thin margins) | 1.40× | 0.96× | — |
| **PWM-5-2D (b) long-low×short-high** | **0.397** | **1.88×** | **1.30×** | **1.01× (tie)** |

**Verdict: Ian's variant (b) WORKS — 0.397 pJ/bit, statistically a tie with PAM-4 (0.401),
23% better than ternary (0.515), 28% better than the length-only PWM-5 (0.550).** The win is
entirely the LONG-LOW symbol: replacing pwm5's strong-11u long pulse (E_drv 1.60 pJ, rail
0.31 V) with a weak-3.67u long pulse (E_drv 0.646 pJ, rail 0.048 V) for the same 1.618 ns of
time cuts the two long symbols from 1.724/1.910 pJ to 0.760/0.985 pJ (−0.96/−0.93 pJ each).
The short-high symbols are unchanged from pwm5's shorts. Net: the 5-symbol average drops
1.276 → 0.923 pJ/symbol.

**The specific findings Ian asked about:**

1. **Is long-low cheaper than short-high for equal detectability? YES — 14%, measured, on
   the receiver's metric; a WASH on the toy V·t metric.** At equal rail@eval (the cell's
   actual detectability, since the receiver samples the rail at the eval edge): (5.6u,
   1.618 ns) gives rail 0.148 V for E_drv **0.967 pJ** vs (11u, 1.0 ns) rail 0.142 V for
   **1.130 pJ** (`_2d_probe3.cir`) — the long-low corner is ~14% cheaper. But at equal rail
   AREA (the abstract "detectability ∝ V·t"): matching 336 pV·s needs ~7u @ 1.618 ns ≈
   1.15–1.20 pJ — a **wash (2–6% worse)**. The mechanism is NOT the toy V²-vs-t trade; it
   is **I²R**: the short pulse concentrates the same delivered charge into 1 ns → higher
   peak current → more loss in the 100 Ω wire and diode legs; the long pulse trickles the
   charge at lower current. The V²-physics prediction holds *directionally* (time IS the
   cheaper axis) but only by 14%, not the 2–3× a V² model would suggest — because the
   driver energy is ≈ VDD·Q (charge-dominated), and equal detectability means equal Q.
2. **Does amplitude-distinguishing beat length-distinguishing? NO.** At fixed 1.0 ns the
   amplitude axis is squeezed between two floors: below ~0.08–0.09 V rail the diode-leg
   rectifier stops charging the rail (line must clear ~0.35 V; a 3.67u driver's line is
   0.26 V → rail collapses to 6 mV, polarity dead), and above ~0.23 V rail the charging-time
   cap binds (a 1.0 ns pulse can't pump more charge — even 25u reaches only 0.232 V @ eval).
   The usable range is ~1.6–2.9×, and the stock sense amp needs ≥ ~0.06 V input differential
   at CM ~0.16–0.20 V (measured: ±0.038–0.045 V latches the WRONG side — dL −0.74 for a rail
   ABOVE threshold; ±0.065–0.075 V just resolves). The widest resolvable split (A3, 8u/25u)
   lands at 0.534 pJ/bit — worse than ternary (0.515) and 34% worse than variant (b). **The
   length axis beats the amplitude axis in this cell at the short-width corner.**
3. **Where the cheap corner (V_min, t_min) sits:** at **(V = 0.048 V rail, t = 1.618 ns)**
   — the long-low corner, 0.646 pJ — NOT at both-min. The both-min corner (V_min at t_min =
   1.0 ns) is unresolvable: the weak driver never clears the diode turn-on in 1 ns (rail
   0.006 V, dA 0.025 = dead). The V_min floor is ~0.02–0.05 V rail (the lowswing sweep
   measured the SA OK at 22 mV, and my 48 mV low corner resolves at dA +0.52, 2.4× above
   that floor); the t_min floor is ~1.0 ns (pwm5_pwscale RC floor). The two floors interact:
   below t ≈ 1.0 ns you cannot go low in V at all. So the cheap corner lives at the LONG end
   of the time axis, not the short end.

**Caveats (same class as prior fair fights):** LEVEL=1 models, no body diodes, no device
mismatch. Variant (b)'s margins are the thinnest yet measured in this family: the magnitude
discriminator input diff is 0.047 V and the low symbol's polarity input is 48 mV. The
lowswing sweep's real-process estimate (offset σ ≈ 5–20 mV → practical floor rail 60–110 mV)
would eat part of that margin — moving the low corner to W≈4.5–5u @ 1.618 ns (rail 90–118 mV,
E_drv 0.79–0.97 pJ) keeps the scheme resolvable on a real chip and the win shrinks to
~0.41–0.44 pJ/bit (still beats ternary and pwm5, still ties PAM-4). Timing skew between the
transmitter's pulse edge and the fixed eval edge is a real-world margin concern (the window
is ~0.1–0.5 ns). A fixed 5-symbol receiver would pay the pull-side comparator cost on every
symbol (same caveat as pwm5).

**Files:** `pwm5_2d.cir` (netlist, fully commented; runs all four configurations via the
control block), `pwm5_2d.log` (measurements), `analyze_2d.py` (table extraction),
`_2d_probe.cir` / `_2d_probe2.cir` / `_2d_probe3.cir` (the (V,t) map and equal-detectability
probes).

## Low-swing 5-state: PWM-5 @ 0.65 V vs ternary @ 0.65 V (2026-08-29, ngspice 44.2, measured — `lowswing_pwm5.cir`)

**The question (Ian's "low-power high-density" mode):** does 5-state (polarity × pulse
width, log₂5 = 2.322 bits/symbol, 5ⁿ namespace) at the low-swing sweet spot earn its
density against ternary at the SAME 0.65 V rail (0.092 pJ/bit, 1.585 bits/symbol)?
Prediction under test: ternary still wins the energy race because the 5-state length-
detector receiver (~0.25–0.30 pJ/symbol) is a FIXED cost that low swing does not shrink
(powered locally at vddsa=±1.0 V), while ternary's receiver (~0.05 pJ) is nearly free.

**The harness:** `pwm5.cir` verbatim (real CMOS driver VTO=±0.4/WP=11u, `tcell4`
rwire=100/cline=1p/RLA=500/rterm=1Meg, 3-comparator receiver: 2 polarity SAs + 1 length
comparator, PULL length = NMOS-input mirror SA on a ±1 V clock, SHORTPW=1.0n, RATIO=φ,
TEVAL=1.7n — the protocol's mandatory late eval, set by the long pulse) with ONLY the
bus rails dropped to VDDR=0.65 V and the receiver kept local at +1.0/−1.0 V. THRLEN
swept 0.005–0.100 V via a control block (rails are threshold-independent); every point
converged, exit 0.

**Measured per-symbol energies at 0.65 V (would-be energies — see resolution below):**

| Symbol | E_drv | E_gate | E_rec | E_symbol | wire vs iface split |
|---|---|---|---|---|---|
| +long | 0.213 pJ | 0.009 pJ | 0.112 pJ | 0.334 pJ | wire 66% / iface 34% |
| +short | 0.134 pJ | 0.009 pJ | 0.112 pJ | 0.256 pJ | wire 56% / iface 44% |
| −long | 0.213 pJ | 0.005 pJ | 0.400 pJ | 0.617 pJ | wire 35% / iface 65% |
| −short | 0.134 pJ | 0.004 pJ | 0.398 pJ | 0.536 pJ | wire 26% / iface 74% |
| null | ~0 | 0 | 0.112 pJ | 0.112 pJ | 100% iface |

**Average 0.371 pJ/symbol → 0.160 pJ/bit** (÷2.322) — **IF it decoded. It does not.**

**RESOLUTION: FAILS at 0.65 V** (THRLEN sweep 0.005–0.100 V; null baseline for the
3-comparator receiver is dA ≈ +11 mV / dB ≈ −6 mV — already 2.5× the ternary's ±4 mV):

| Symbol | rail @ eval | dA (push) | dB (pull) | dL (length) | Verdict |
|---|---|---|---|---|---|
| +long | +22.9 mV | +0.110 | −0.064 | +0.069→+0.018 (THRLEN 0.005→0.010), **flips wrong at ≥0.012** | MARGINAL/FAIL: length decodes only in a 5 mV threshold window at the SA regeneration floor (peak +37 mV vs +670 mV at full swing) |
| +short | **+2.7 mV** | **+0.017** | −0.007 | −0.03…−0.10 (short ✓) | **FAIL: push polarity +17 mV vs null +11 mV — 5.8 mV separation, threshold-INDEPENDENT** |
| −long | −22.9 mV | −0.050 | +0.092 | **+1.53** (long ✓) | OK (NMOS-input SA on the negative rail latches full-scale) |
| −short | −2.7 mV | +0.004 | +0.017 | **−1.54** (short ✓) | MARGINAL polarity (17 mV) but length robust |
| null | ~0 | **+0.011** | −0.006 | −0.04…−0.65 | **COLLIDES with +short** (same push code, 5.8 mV apart) |

Why it collapses — protocol-structural, not tuning: the length protocol forces the eval
AFTER the long pulse ends (TEVAL=1.7n > LONGPW=1.618n). By that late edge the SHORT
symbol's rail has decayed to **2.7 mV** (peak 22 mV, τ≈0.9 ns bleed via RLA) — ~7× below
the ternary's 22 mV rail at its earlier eval, and below the SA's ~11 mV offset floor.
The push length comparator's input diff is ≤ 18 mV (rail 22.9 mV − THRLEN), at the
regeneration threshold: THRLEN ≥ 0.012 misdecodes +long as short. The pull half is fine
(±1.5 V latch) — the wall is specifically the PMOS-input push side, plus the short-push
polarity.

**Decomposition — the fixed receiver tax now DOMINATES (Ian's mechanism, confirmed):**

| | high swing (pwm5.cir) | **0.65 V (this run)** | ternary @ 0.65 V |
|---|---|---|---|
| wire avg / symbol | 1.108 pJ (87%) | **0.144 pJ (39%)** — fell 7.9× (∝V²) | 0.094 pJ/trit (65%) |
| iface avg / symbol | 0.169 pJ (13%) | **0.227 pJ (61%)** — did NOT shrink (rose 1.35×) | 0.052 pJ/trit (35%) |
| total | 1.276 pJ → 0.550 pJ/bit | 0.371 pJ → **0.160 pJ/bit (would-be)** | 0.145 pJ → **0.092 pJ/bit** |

The 5-state's wire energy fell ~8× with the swing exactly as low-swing theory says, but
the receiver — powered locally at ±1.0 V — stayed fixed (0.11 pJ base for 3 SAs, +0.29 pJ
extra on pull symbols for the NMOS length comparator + ±1 V clock; even the null pays
0.112 pJ vs ternary's 0.052). Receiver share of symbol energy: 13% → 61%.

**The two-mode table Ian asked for (head-to-head @ 0.65 V):**

| | **ternary @ 0.65 V** | **5-state @ 0.65 V** |
|---|---|---|
| pJ/bit | **0.092** (resolves) | 0.160 would-be — **does NOT resolve** |
| bits/symbol | 1.585 (log₂3) | 2.322 (log₂5) |
| namespace @ 32 lanes | 3³² ≈ 1.85×10¹⁵ (50.7 bits) | 5³² ≈ 2.33×10²² (74.3 bits) — 1.26×10⁷ × larger |
| receiver cost | 0.052 pJ/trit (2 SAs) | 0.112–0.400 pJ/symbol (3 SAs + NMOS length comp) |
| resolution margin | dA 25 mV / dB 17 mV vs ±4 mV null (OK) | +short vs null 5.8 mV; +long length 18–69 mV at SA floor (FAIL) |

**Verdict: the prediction is CONFIRMED and the gap WIDENS past the point of usability.**
At full swing the 5-state was 6% worse than ternary (0.550 vs 0.515 pJ/bit); at 0.65 V
the would-be 5-state is 1.74× worse (0.160 vs 0.092 pJ/bit) AND it cannot decode — the
length detector collapses (short rails at the mandatory late eval = 2.7 mV, below the SA
floor; push length works only in a razor-thin THRLEN window at the regeneration
threshold) and the +short symbol is indistinguishable from null (5.8 mV). The fixed
length-detector receiver tax (0.11–0.40 pJ, powered at ±1.0 V) does not shrink with the
bus swing and now dominates 39–100% of every symbol, exactly as predicted. A "low-power
5-state" mode is NOT energy-competitive at any swing in this cell family — it earns only
the namespace axis (5³² = 1.26×10⁷ × the ternary namespace) at ≥1.74× the per-bit energy,
and only after a receiver redesign (e.g. NMOS-input length comparators on the push side
too, or larger rails) restores the length margin. Caveats (same class as every fair
fight here): LEVEL=1 models, no device mismatch (real SA offsets σ≈5–20 mV would erase
the 5.8–18 mV margins entirely — this FAIL is if anything optimistic), no body diodes.

**Files:** `lowswing_pwm5.cir` (netlist, fully commented; `ngspice -b` runs the full
THRLEN sweep, exit 0), `lowswing_pwm5.log` (all 12 threshold runs).

## The cuboid corner: low-swing × LC-resonant (2026-08-29, ngspice 44.2, measured — `lowswing_resonant.cir`)

**The question (the two levers stacked):** the low-swing sweep won wire energy ∝V²
(VDDR=0.65 V → 0.092 pJ/bit) with NO charge recovery; the LC fair fight recovered charge
at FULL swing (reset −0.225 pJ → 0.133–0.168 pJ/bit). Does running the SAME LC-resonant
half-bridge cell at a reduced bus rail (VLC=±0.36 V → line ≈0.66 V, and ±0.28 V → line
≈0.51 V) compose the V² saving AND the charge recovery — or does one lever's overhead
dominate?

**Harness (fair-fight honesty rules):** the `ternary_adiabatic_fairfight.cir` cell verbatim
(rwire=500, cline=1p, DIDEAL diode receiver, 1MΩ rails, 0.2p caps), real half-bridge LC
switches (MPP/MN0/MNN, body at −VLC, closed T/2=π√(LC) at the current zero-crossing), real
PMOS-input sense-amp receiver powered LOCALLY at vddsa=1.0 V, LC power-clock rails that
accept the return. **VT wall:** with the STOCK push drive (gate VLC↔0) the push PMOS
(|Vt|=0.4) is below threshold below VLC≈0.4 V — case C0 demonstrates this death (line never
swings, dA_push only +0.03). The reduced cases therefore use **negative gate drive on the
push switch** (gate VLCP↔VLCN, Vgs=−2·VLC) — the same class of real-process fix the
fairfight already applies to the pull switch (its off level is −0.6 V).

**Measured (E in pJ; per-trit = cycle/3; pJ/bit = ÷1.585; per-trit-full adds the
receiver, both SAs, 2 ns evals):**

| case | VLC | L | line +/− | railA/railB | push | pull | reset | cycle | per-trit drv (pJ/bit) | +rec (pJ/bit) | dA_push |
|---|---|---|---|---|---|---|---|---|---|---|---|
| REF | 0.60 | 40µ | +1.09/−0.78 | 0.60/−0.43 | 0.862 | ~0 | **−0.082** | 0.700 | 0.233 (0.147) | (0.193) | +0.99 |
| C0 | 0.36 | 40µ | ~0/~0 | ~0/~0 | 0.000 | 0 | +0.294 | 0.294 | — **DEAD** | — | +0.03 FAIL |
| **A1** | 0.36 | 40µ | +0.66/−0.53 | 0.34/−0.29 | 0.318 | ~0 | **−0.093** | **0.221** | **0.074 (0.046)** | **(0.099)** | +0.86 |
| A2 | 0.36 | 20µ | +0.65/−0.48 | 0.33/−0.26 | 0.306 | ~0 | −0.011 | 0.286 | 0.095 (0.060) | (0.113) | +0.84 |
| A3 | 0.36 | 9.4µ | +0.62/−0.36 | 0.32/−0.19 | 0.276 | ~0 | +0.041 | 0.316 | 0.105 (0.066) | (0.120) | +0.83 |
| **B1** | 0.28 | 40µ | +0.51/−0.42 | 0.26/−0.23 | 0.192 | ~0 | **−0.069** | **0.124** | **0.041 (0.026)** | **(0.081)** | +0.80 |
| B2 | 0.28 | 20µ | +0.49/−0.38 | 0.25/−0.20 | 0.187 | ~0 | −0.004 | 0.184 | 0.061 (0.039) | (0.093) | +0.80 |
| B3 | 0.28 | 9.4µ | +0.47/−0.32 | 0.24/−0.17 | 0.178 | ~0 | +0.010 | 0.191 | 0.064 (0.040) | (0.095) | +0.80 |

**Verdict: the two levers COMPOSE — and the cuboid corner beats BOTH prior winners.**

1. **They stack, and better than the V² law alone.** Cycle energy falls from 0.700 pJ
   (full swing) to 0.221 pJ at VLC=0.36 and **0.124 pJ at VLC=0.28** — a 3.2× / 5.6× cut.
   Pure ½CV² scaling would predict 0.259/0.152 pJ from the measured line peaks
   ((0.66/1.09)²=0.37×, (0.51/1.09)²=0.22×); the measured cycle is even lower, because the
   R/Z0 ring loss and switch channel loss also shrink with swing (∝I²∝V²) while the
   recovery fraction of the tank energy is preserved. **Driver-only per-trit: 0.074 pJ at
   0.65 V swing and 0.041 pJ at 0.5 V → 0.046 / 0.026 pJ/bit** — vs 0.147 pJ/bit at full
   swing, 3.2–5.6× below.
2. **The reset still RECOVERS charge at low swing — this was the open question.** Reset
   energy is NEGATIVE at L=40µH for both reduced swings: **−0.093 pJ (A1) and −0.069 pJ
   (B1)** — the LC tank still returns net energy to the power clock even though the stored
   charge is only ½CV². Recovery does NOT vanish with the smaller charge at the big-L
   operating point; it dies only at L=9.4µH (reset +0.041/+0.010 pJ) — the SAME L-wall the
   fairfight found at full swing (their 9.4µH reset was +0.038). The recovery fraction of
   the push actually IMPROVES at low swing: A1 returns 29% of its push energy on reset vs
   REF's 9.5% — the fixed diode-drop overhead shrinks relative to the tank energy.
3. **The receiver still resolves at the reduced swing.** Rail asserts fall 0.60→0.34→0.26 V
   but the sense-amp latch differential at the demux time stays **+0.86 (A1), +0.80 (B1)**,
   vs the ±4 mV null baseline and vs the lowswing sweep's OK ≥ 10 mV criterion — clean at
   both reduced swings. C0 (stock drive) is the only FAIL (+0.03) and it is the
   driver-death demo, not a receiver problem.
4. **Low swing tames the resonant current; di/dt does not blow up.** Peak push supply
   current: 95.5 µA (full) → 57.8 (A1) → 44.4 µA (B1), ∝ swing. di/dt stays 0.17–0.30 A/µs
   at every swing — 100–200× below the fast lowswing driver (37–56 A/µs) and far below the
   VTENG pass (376–1128 A/µs). The low-swing×resonant cell is the di/dt-friendliest point
   in the whole survey.
5. **The receiver is the new floor — one lever's overhead now dominates, but only because
   the wire is so cheap.** With the locally-powered receiver included (both SAs, ~0.08–0.09
   pJ/trit, unchanged by swing), A1 totals 0.157 pJ/trit (0.099 pJ/bit) and B1 totals 0.128
   pJ/trit (**0.081 pJ/bit**). Head-to-head: **B1 (0.081) beats the lowswing-only winner
   (0.092) by 12% and the LC-only fair fight (0.133–0.168) by 39–52%**; A1 (0.099) beats the
   LC-only numbers but sits 8% above the fast lowswing cell — because the fixed receiver
   tax is now 2/3 of the total. The honest bottom line: **the composition is real and
   measurable at the driver/wire level (0.026–0.046 pJ/bit, recovery included); with the
   current receiver it lands at 0.081 pJ/bit total — the best measured point in the survey —
   and the receiver, not the tank, is what keeps it from going lower.** (The lowswing
   sweep's own iface was 0.052 pJ/trit at a 1 ns eval; the fairfight's 2 ns eval + 1MΩ
   rail-hold draws ~0.08–0.09 — receiver redesign is the remaining lever.)
6. **Speed: unchanged by the swing — the adiabatic tax is L-bound, not V-bound.**
   Mtrit/s = 1/T2 (phase-limited): 48 (40µH), 68 (20µH), 100 (9.4µH). The fast lowswing
   cell does ~400–500 Mtrit/s; the cuboid corner is ~5–10× slower, the same trade as the
   full-swing LC fair fight.

**Caveats (same class as every fair fight here):** LEVEL=1 models, no body diodes, no
device mismatch (real SA offsets σ≈5–20 mV would still be ~5–10× below the +0.80 latch
differentials here — comfortable); the null/reset eval still reads the previous pull state
unless rail equalization is added (1MΩ rails hold their assert for τ≈200 ns — fairfight
caveat (b), ~0.05 pJ, swing-independent, flagged in the netlist); the C0 stock-drive death
at VLC=0.36 (|Vgs|=0.36<|Vt|=0.4) is the same device wall the lowswing sweep measured
(FAIR dead below VDDR≈0.5 V) — the negative gate drive is the real-process fix and is
documented as such, not hidden.

**Files:** `lowswing_resonant.cir` (netlist, fully commented; `ngspice -b` exit 0),
`lowswing_resonant.log` (all 8 cases, one transient).
