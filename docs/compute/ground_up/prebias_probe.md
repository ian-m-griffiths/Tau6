# Pre-bias probe — does "pre partial activation" win, or leak?

**Verdict up front: it leaks. Pre-biasing a push-pull junction near its switching
threshold is a net energy LOSS, and it is also *slower*, not faster. The principal's
suspicion ("this may take more energy not less") is confirmed with numbers.**

Netlist: `circuit/prebias_probe.cir` · log: `circuit/prebias_probe.log` · ngspice 44.2,
headless (`ngspice -b`), run 2026-08-30.

---

## 1. What was measured

The junction under test is a **CMOS push-pull stage** (PMOS pull-up + NMOS pull-down,
`W/L` = 4µ/0.18µ and 2µ/0.18µ, `|VTO| = 0.4 V`, `VDD = 1.0 V`), the canonical element
whose "threshold" is the trip point `V_M = 0.5 V` where the output flips. Holding its
input near `V_M` is precisely "both devices partially conduct" — the crowbar region.

- **Static leakage** — `.dc` sweep of the input voltage; `P_leak = VDD · I_q(V_in)`.
  Measured twice: the project-standard **LEVEL=1** model (hard cutoff below `VTO`, no
  subthreshold) and a **LEVEL=3 + NFS** model (~60 mV/dec subthreshold slope, the *ideal*
  slope — real devices are leakier). The two agree wherever the device is actually on;
  they differ only below `VTO`, where LEVEL=1 silently reads zero.
- **Dynamic switch** — `.tran`: input held at the pre-bias point, then stepped a small
  `ΔV` to 0.55 V (just past `V_M`), flipping the output full rail. Measured: input-drive
  energy `ein` (the `C·ΔV²` term), supply energy `es`, and switch delay/fall time.
- **Crossover idle time** — `T_x = (dynamic saving) / P_leak`: how long the junction can
  sit idle before the standing leakage burns the per-switch saving.

Pre-bias points are `X%` of the way from 0 V toward threshold `V_M = 0.5 V`.

## 2. Static leakage vs pre-bias depth (the headline)

| pre-bias | V_pb | I_q (LEVEL=1) | I_q (LEVEL=3) | P_leak = VDD·I_q |
|---|---|---|---|---|
| 0%  | 0.000 V | 1.01 pA  | 1.07 pA  | ~1 pW      |
| 25% | 0.125 V | 1.01 pA  | 8.42 pA  | ~8 pW      |
| 50% | 0.250 V | 1.01 pA  | 0.891 nA | ~0.9 nW    |
| 75% | 0.375 V | 1.01 pA  | **107 nA** | ~0.1 µW |
| 90% | 0.450 V | **2.92 µA** | 2.78 µA | **~2.8 µW** |
| 95% | 0.475 V | **6.55 µA** | 6.25 µA | **~6.3 µW** |
| 98% | 0.490 V | **9.43 µA** | 9.00 µA | **~9.0 µW** |
| 100% | 0.500 V | 11.4 µA | 11.1 µA | ~11 µW |

Two things to read off this table:

1. **The leakage that matters is crowbar, and it switches on like a wall between 75%
   and 90%.** The instant the input crosses `VTO` (0.4 V, i.e. ~80% of the way to `V_M`),
   the NMOS turns on while the PMOS is still on, and a standing µA-class current flows
   from rail to rail. "Just below threshold" (90–98%, 0.45–0.49 V) sits squarely in that
   wall: **~2.8–9 µA, i.e. ~3–9 µW, paid 100% of the time the junction sits there.**
2. **LEVEL=1 hides the subthreshold tail but does not change the verdict.** Below `VTO`
   (0–75%) LEVEL=1 reads the ~1 pA `gmin` floor; the LEVEL=3 correction shows real
   subthreshold rising to 107 nA at 75%. That is still **3–5 orders below the crowbar**
   at 90%+. The conclusion is model-robust: the energy penalty is the crowbar, not
   subthreshold.

## 3. Dynamic switch energy and speed

All cases assert to the same 0.55 V, so the switch `ΔV` shrinks with pre-bias depth.
`ein` = input-driver energy (the only term pre-bias can save — the output still swings
full rail every switch, and its `½·C_L·VDD²` is paid identically in every scheme).

| pre-bias | ΔV (V) | ein (fJ) | es (fJ) | et (fJ) | tpd (ns) | tf (ns) |
|---|---|---|---|---|---|---|
| ref 0→1 V | 1.00  | 8.54 | −6.76 | 1.78  | **0.128** | **0.134** |
| 0%  | 0.550 | 2.97 | 2.63  | 5.60  | 1.154 | 1.764 |
| 25% | 0.425 | 2.76 | 4.00  | 6.76  | 1.145 | 1.764 |
| 50% | 0.300 | 2.32 | 5.34  | 7.66  | 1.134 | 1.764 |
| 75% | 0.175 | 1.63 | 6.70  | 8.33  | 1.122 | 1.764 |
| 90% | 0.100 | 1.07 | 10.80 | 11.87 | 1.108 | 1.764 |
| 95% | 0.075 | 0.82 | 15.07 | 15.90 | 1.089 | 1.764 |
| 98% | 0.060 | 0.64 | 18.32 | 18.96 | 1.058 | 1.764 |

- **Dynamic saving is tiny and bounded.** The input-drive energy falls from 8.54 fJ
  (full rail) to 0.64 fJ (98%): a saving of at most **~7.9 fJ per switch** vs full rail.
  Against the *sensible* no-pre-bias baseline — a minimal-swing driver (0%, `0→0.55 V`)
  that flips the same output with **zero** leakage — the incremental saving of pre-biasing
  to 90–98% is only **~1.9–2.3 fJ per switch**. The output flip is unchanged, and the
  supply energy `es` actually *grows* with pre-bias depth (2.6 → 18.3 fJ) because the
  input lingers in the crowbar region during the transition. (`es_ref = −6.76 fJ` is the
  full-rail control: with the output collapsing at full speed, Miller/Cgd coupling pushes
  charge back into the supply, so `et_ref` reads small — `es` is therefore *not* the clean
  dynamic-cost number; `ein` is, and it is what the saving table uses.)
- **It is slower, not faster.** Operating near threshold means minimum overdrive =
  minimum drive current. The output fall time is **1.76 ns at every pre-bias point vs
  0.13 ns for a full-rail drive — an 8–13× slowdown**. The propagation delay only edges
  down 1.15 → 1.06 ns as pre-bias deepens; every pre-biased case is ~8× slower than the
  full-rail reference. The "fast" half of the hypothesis fails for a digital push-pull
  stage (the intuition holds only for a class-A *small-signal* amplifier, not a rail
  slewing a logic node).

## 4. Crossover idle time

`T_x = (per-switch dynamic saving) / P_leak` — the idle time after which leakage has
burned the entire saving.

| pre-bias | saving vs full rail | `T_x` | saving vs minimal-swing (0%) | `T_x` |
|---|---|---|---|---|
| 75% | 6.91 fJ | **64.6 ns** | 1.34 fJ | 12.5 ns |
| 90% | 7.47 fJ | **2.7 ns**  | 1.90 fJ | **0.69 ns** |
| 95% | 7.72 fJ | **1.24 ns** | 2.15 fJ | **0.34 ns** |
| 98% | 7.90 fJ | **0.88 ns** | 2.33 fJ | **0.26 ns** |

The crossover is **sub-nanosecond to a few nanoseconds** at the "just below threshold"
points. A junction pre-biased to 98% can idle for ~0.9 ns (generously, ~0.3 ns against
the honest minimal-swing baseline) before its standing crowbar current has wasted more
energy than the small-`ΔV` switch saved. That is the entire saving gone after roughly
**one clock period at ~1 GHz** — and there is no "idle fraction" that rescues it, because
the leakage is paid *continuously*, in both logic states (the junction never rests at 0
or `VDD`; both its states sit near `V_M`).

## 5. Honest verdict

**Pre-biasing near threshold is not a net win at any realistic duty cycle.** The
tradeoff is one-sided:

- The **dynamic saving is ~7.9 fJ/sw** (vs a full-rail swing) and only **~2 fJ/sw** vs
  the no-pre-bias minimal-swing driver that already flips the same output leakage-free.
  It buys nothing on the output node (which still swings full rail) and it costs speed.
- The **static leakage is ~3–9 µW** at 90–98% pre-bias — a permanent crowbar current, not
  a subthreshold tail. It exceeds the saving after **~0.3–3 ns of idle**, i.e. the scheme
  only breaks even if the junction switches continuously at ~GHz with effectively zero
  idle fraction — and even then it is ~8× slower per switch.

So: the small-swing physics (`E ∝ C·ΔV²`) is real but applies only to the input node's
~19 fF of gate charge (~a few fJ), while the high-gain region that makes the small swing
possible is exactly the crowbar region that leaks µW continuously. **The leakage
dominates by ~3 orders of magnitude.** If the goal is a cheap switch, the right lever is
the one this project already found elsewhere: a minimal-swing voltage drive (0% here)
with a dead-zone null — i.e. keep the input *away* from threshold, not parked on it.

### Caveats (honesty notes)

- LEVEL=1 has no subthreshold conduction, which flatters the 0–75% points; the LEVEL=3
  + NFS sweep is the correction (and its ~60 mV/dec slope is the *ideal* — real
  nanoscale devices with n ≈ 1.2–1.5 leak more, making the case against pre-bias only
  stronger).
- No body diodes, no device mismatch, ideal voltage drivers behind a 500 Ω source
  impedance. Absolute energies scale with `C_L` and device width; the **ratio**
  leakage/dynamic — which is what decides the verdict — does not.
- The crowbar magnitudes assume `|VTO| = 0.4 V` on a 1 V rail. Lowering `VTO` (the
  "VT-engineered" option) *widens* the crowbar window and raises leakage; the elevated-|Vt|
  dead-zone devices in `diode_gates.cir` are the opposite design — they deliberately push
  the null away from the crowbar, which is the same conclusion reached here by
  measurement.
