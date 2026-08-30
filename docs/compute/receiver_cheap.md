# Can the ternary cell's RECEIVER be cheapened? (2026-08-29, ngspice 44.2, measured)

**The question.** The champion cell `lowswing_resonant.cir` (case B1: VLC=±0.28 V, L=40 µH)
lands at **0.081 pJ/bit**, and the receiver is now 2/3 of that: the driver/wire/tank costs
only 0.041 pJ/trit (0.026 pJ/bit), while the locally-powered sense-amp receiver costs
~0.0865 pJ/trit. Can the receiver — the energy floor — be cheapened? Three levers tested,
fair-fight, against the verbatim B1 cell.

## Method (fair-fight honesty rules)

`receiver_cheap.cir` reproduces the champion B1 resonant front end **verbatim** (real
half-bridge LC switches, `ternary_cell` with rwire=500/cline=1p/1 MΩ rails/0.2 p caps,
negative-gate-drive push switch), and attaches each receiver variant to its **own identical
cell + its own 1.0 V receiver supply**, so the energies are separable and there is zero
cross-loading of the rails. One shared sense-amp clock, the verbatim B1 eval schedule
(2 ns evals at 888.71 / 921.41 / 954.12 n). Receiver energy = ∫ −(vddsa · I(VDDSA)) over each
5 ns eval window (the champion's own windows); the three evals averaged = receiver pJ/trit.
Resolution = latch differential at the demux time (dA push at 889.71 n, dB pull at 922.41 n),
null baseline ~±4 mV, OK ≥ 10 mV.

**Baseline reproduces the champion exactly** (measured here → champion's own log):

| quantity | this run | champion |
|---|---|---|
| driver cycle (push+pull+reset) | 0.1238 pJ (reset −0.0693 recovered) | 0.124 pJ (−0.069) |
| rail asserts | +0.255 / −0.226 V | +0.26 / −0.23 V |
| receiver: push / pull / reset eval | 0.0594 / 0.1001 / 0.1000 pJ | 0.059 / 0.100 / 0.100 pJ |

So the harness is faithful, and the receiver floor to beat is **0.0865 pJ/trit** (avg of the
three evals), i.e. total **0.081 pJ/bit**.

## Results — per-variant receiver energy (measured, pJ)

| variant | input pair | # SAs | push | pull | reset | **rec/trit** | **total pJ/bit** | Δ vs floor |
|---|---|---|---|---|---|---|---|---|
| **V0 baseline** | W=1u, Vt=−0.4 | 2 | 0.059 | 0.100 | 0.100 | **0.0865** | **0.081** | — (the floor) |
| V1 wider | W=2u | 2 | 0.073 | 0.108 | 0.107 | 0.0961 | 0.087 | **+7.5%** |
| V2 wider | W=4u | 2 | 0.084 | 0.112 | 0.112 | 0.1027 | 0.091 | +12.7% |
| V3 wider | W=8u | 2 | 0.094 | 0.116 | 0.115 | 0.1085 | 0.094 | +17.2% |
| V4 low-Vt | W=1u, Vt=−0.2 | 2 | 0.094 | 0.108 | 0.107 | 0.1030 | 0.091 | +12.9% |
| V5 low-Vt | W=1u, Vt=−0.1 | 2 | 0.104 | 0.109 | 0.108 | 0.1071 | 0.094 | +16.2% |
| V6 amp-par | W=1u | 4 | 0.118 | 0.200 | 0.200 | 0.1727 | 0.135 | +67.5% |
| V7 amp-par | W=1u | 6 | 0.176 | 0.300 | 0.300 | 0.2588 | 0.189 | +134.9% |

Driver per-trit is unchanged at 0.0413 pJ (0.026 pJ/bit); the receiver redesigns do not touch
the tank.

## Resolution — every variant must still resolve to count

| variant | dA_push | dB_pull | dB_peak | verdict |
|---|---|---|---|---|
| V0 | +0.803 | +0.409 | 0.462 | resolves (champion's own numbers) |
| V1 (W=2u) | +0.737 | **+0.039** | 0.445 | pull detector collapses |
| V2 (W=4u) | +0.675 | **+0.015** | 0.437 | pull detector FAIL (≤ ~4 mV null) |
| V3 (W=8u) | +0.621 | **+0.007** | 0.428 | pull detector FAIL |
| V4 (Vt=−0.2) | +0.561 | +0.029 | 0.276 | pull marginal |
| V5 (Vt=−0.1) | **+0.102** | +0.018 | 0.193 | both detectors collapse |
| V6 (4 SA) | +0.804 | +0.409 | 0.461 | resolves (identical to baseline) |
| V7 (6 SA) | +0.806 | +0.409 | 0.459 | resolves (identical to baseline) |

dB_peak = peak pull-latch differential over the eval window: every widened/low-Vt pair still
peaks at ~0.43–0.46 V at the eval edge, but then **decays** — by the demux time the wider pair
has bled to 7 mV. This is a *failed regeneration*, not merely a slower one.

## Verdict

**None of the three levers cheapens the receiver. The stock sense amp (W=1u input pair,
Vt=−0.4, 2 SAs) is already the energy floor for this receiver topology, and the floor stays
0.081 pJ/bit.**

1. **Wider input pairs LOSE — the hypothesis is rejected on energy, and on resolution too.**
   Energy rises monotonically with input-pair width: 0.0865 → 0.096 → 0.103 → 0.108 pJ/trit
   (+7.5% to +17.2%). The input pair was never a resistive bottleneck for energy — it is a
   transconductor, and widening it with the fixed W=0.3u tail just passes **more** tail
   current (measured peak supply current 51.0 → 57.3 → 63.0 µA as W goes 1u → 2u → 8u), so
   the SA burns more, not less. Simultaneously the pull detector's demux differential
   collapses 0.409 → 0.007 V — the wider pair loads the latch nodes with extra drain
   capacitance and runs at lower overdrive (closer to triode), which *damps* the cross-coupled
   NMOS latch so it stops regenerating. The champion's cell-level "N=4 paralleling" win does
   **not** transfer to the sense amp: that win was about a diode-connected rectifier's Ron,
   whereas the SA input pair is a differential transconductor whose current is what you pay
   for.
2. **More sense amps in parallel LOSE, exactly as predicted — they DUPLICATE energy.**
   4 SAs → 0.1727 pJ/trit, 6 SAs → 0.2588 pJ/trit: precisely 2× and 3× the baseline (each
   extra SA draws its own tail current and charges its own latch). Resolution is bit-identical
   to baseline (parallel amps neither help nor hurt it), so there is no offsetting gain — it
   is pure duplication, +67.5% and +134.9% on the total.
3. **Lower-Vt front end LOSE too** (the models allow it; LEVEL=1 has no subthreshold
   leakage, so this is if anything *optimistic* for the low-Vt path). Vt=−0.2 → 0.1030 pJ/trit,
   Vt=−0.1 → 0.1071 pJ/trit (+12.9%, +16.2%). Lower |Vt| = higher overdrive = more current at
   the same W — the same wrong direction as widening — and the resolution collapses with it
   (dA_push 0.803 → 0.561 → 0.102; dB_pull 0.409 → 0.029 → 0.018). At Vt=−0.1 even the push
   detector stops resolving cleanly.

## The new floor

There is **no new floor**. The champion's 0.081 pJ/bit stands; the receiver's 0.0865 pJ/trit
is a genuine floor of this SA topology, and every tested redesign makes it worse (energy up)
while several also break resolution.

The honest decomposition of why the receiver costs 0.0865 pJ/trit: it is
*(#SAs) × (tail current ≈ 30 µA) × (eval time 2 ns) × (1.0 V)*, averaged over the three evals
— push pays one strong latch + one weak latch (0.059 pJ), pull and reset pay two strong
latches each (0.100 pJ). The only levers that *would* move this floor are the ones not tested
here and each has a resolution price: **shorten the eval window** (the lowswing sweep's own
SA-only receiver is 0.052 pJ/trit at a 1 ns eval vs 0.0865 here at 2 ns — nearly half), or
**shrink the tail current** (but the tail sets gm, so resolution falls with it). Neither is
free; the 2 ns eval is what the fair-fight receiver schedule uses, and the tail is sized for
the −0.23 V pull rail.

**Caveats (same class as every fair fight in this survey):** LEVEL=1 models, no body diodes,
no device mismatch (real SA offsets σ≈5–20 mV would make the widened/low-Vt failures *worse*,
not better, and would also erode the baseline's own pull-detector 0.409 V margin); the null
caveat is reproduced faithfully (1 MΩ rails hold their asserts, so the reset eval reads the
pull state — push=1-strong, pull/reset=2-strong is the mechanism, not an artifact).

## Files

- `circuit/receiver_cheap.cir` — the benchmark netlist, fully commented; `ngspice -b`
  exits 0, reproduces the champion baseline, then measures 8 receiver variants (wider input
  pair ×3, low-Vt ×2, amp-parallel ×2) each on its own identical B1 cell and supply.
- `circuit/receiver_cheap.log` — all measurements (driver anchor, per-variant per-eval
  receiver energy, resolution at demux/end/peak).
