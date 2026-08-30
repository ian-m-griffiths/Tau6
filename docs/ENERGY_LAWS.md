# Three Laws of the Hex Ternary Cell

> **⚠️ CORRECTION BANNER (2026-08-29):** this file's headline multipliers were
> computed against a **flattered binary baseline (0.748 pJ/bit)**. The fair-fight
> correction (`docs/FINAL_VERDICT.md` §correction 2, `circuit/ENERGY_RESULTS.md`)
> moves the honest reference to **0.512** (natural single-ended) / **0.216** (matched
> low-swing), so "9.2×" becomes **6.3× / 2.67×**, and the adiabatic "0.165 pJ" was
> ideal-source flattery (CORRECTION 2). Treat `docs/FINAL_VERDICT.md` as authoritative.

**2026-08-28 — synthesis of the night's energy/circuit/Lean work.** Every number below
is *measured* (ngspice 44.2, fair-fight harness: real CMOS driver + real sense-amp
receiver, no ideal sources) or *proved* (Lean, `lake build` green). Calibration legend:
**DIRECT** = measured or proved; **OURS** = our design claim, follows from DIRECT;
**SPECULATION** = untested, flagged as such.

---

## The three laws

### Law 1 — The receiver is gauge-agnostic.

Energy splits into two *different kinds*:

- **Transmission energy** (the wire): driver channel loss `(Vrail−Vline)·I·t` + line
  charge `½CV²`. Scales with swing ∝ V². Shrinkable.
- **Detection energy** (the receiver): the cost of *resolving which state you're in*.
  Fixed per symbol — it does not care how hard you drove the wire, only how much
  information you're extracting. Not shrinkable by any transmission gauge change.

**Calibration: DIRECT (measured three times).** The receiver's share of symbol energy
went **13% → 61% → 67%** as the swing dropped (high-swing PWM-5 → low-swing →
low-swing×resonant). Low-swing cuts the wire cost ∝V² but leaves the receiver standing;
the receiver is the *invariant* part — the same structure as `ChiSquareGauge.lean`
(δ gauge-invariant, χ² not).

**Consequence:** the ultimate energy floor is the cost of *extracting information*, not
of *moving charge*. Once the wire is cheap enough, the measurement is the wall.

### Law 2 — The diagonal is cheap because of physics (I²R), not a V² toy model.

In the (voltage, time) plane, "long-low" beats "short-high" at equal detectability by
~14%. The mechanism is **I²R**: `E_drv ≈ VDD·Q`, so equal detectability ≈ equal charge ≈
equal energy — but the short pulse crams the same charge into a shorter time → higher
peak current → more wire/diode loss. The cheap direction is the **anti-diagonal**
(down-in-voltage ↔ up-in-time).

**Calibration: DIRECT (measured).** The 2D amplitude×duration 5-symbol cell lands at
0.397 pJ/bit (ties PAM-4), and the win is the long-low symbol replacing the expensive
long (0.76/0.99 vs 1.72/1.91 pJ). The V²-vs-t story I originally told was *wrong on the
mechanism* — the measurement corrected it to I²R.

### Law 3 — Three wins because it's nearest e.

Radix economy `b/ln(b)` is minimized at `b = e ≈ 2.71828`; the nearest integer is 3
(`3/ln3 = 2.73` vs `2/ln2 = 2.89` vs `e = 2.72`). *And* 3 is the smallest odd radix, so
it has a free middle digit — the null, which is data-bearing and costs ~0.05 pJ.

**Calibration: DIRECT (proved + measured).** `RadixEconomy.lean` proves
`3/ln3 < 2/ln2`; the fair-fight measures null ≈ free. Two independent reasons point at
the same digit.

**Consequence:** the "explosion of states" (5-state, PAM-4) buys *namespace*, not
*energy* — every extra state pays a receiver tax (Law 1) that never shrinks. 5-state
= 2.32 bits/symbol vs ternary 1.585, but 5³² = 1.26×10⁷ × 3³² is an *address-space*
win, not a joules win.

---

## Final energy leaderboard (pJ/bit, fair-fight, measured)

| scheme | pJ/bit | vs binary (0.748) |
|---|---|---|
| binary | 0.748 | 1.00× |
| ternary (null-carrying, uniform) | 0.515 | 1.45× better |
| PWM-5 (length-only) | 0.550 | 1.36× |
| PAM-4 | 0.401 | 1.86× |
| PWM-5 2D (long-low) | 0.397 | 1.88× |
| LC-resonant (full swing) | 0.13–0.17 | 4.5–5.6× |
| low-swing (fast) | 0.092 | 8.1× |
| **low-swing × resonant** | **0.081** | **9.2×** |

## The thesis: the receiver is the floor

**0.081 pJ/bit** is where the two *shrinkable* levers bottom out against the one
*invariant* cost:

- **low-swing** (partial powering — Ian's idea) cuts wire energy ∝V²,
- **resonant recovery** (LC tank) returns the stored charge instead of burning it,
- …and what's left standing is the **receiver** (~0.08–0.09 pJ/trit, 2/3 of the total).

The two levers **compose** (the cuboid corner beats both prior winners), and the
receiver — the measurement, the "cost between dimensions" — is the floor. To go below
0.081 pJ/bit, cheapen the *receiver*, not the wire.

**Calibration: OURS** (follows from Law 1 + the measured decomposition), with the caveats
that made it honest: recovery needs the L-wall (L=40 µH solid, 9.4 µH dead — same as
full swing); the reduced-swing push needs negative gate drive (|Vt|=0.4 wall); speed is
L-bound at 48–100 Mtrit/s (5–10× the adiabatic tax); di/dt stays tame (0.17–0.30 A/µs).

---

## Area (RTL, SkyWater 130nm, yosys 0.52, formally verified)

- **−9.0% chip / −20.1% tnorm** — from the norm identity `N(a+bω) = (a+b)² − ab`
  (3 products → 2), **not** Karatsuba (which loses +28% at the 6-trit word size).
- Eisenstein multiply (identity #1, 3 products) pays −14.6% at N=6 but awaits a
  TROT-style instruction. Correctness: SAT equivalence (UNSAT) + 13,282-vector sweep +
  CPU end-to-end, all green.

## Lean (15 theorem contracts closed — 19 theorems total in 4 files; `lake build` green, 8734 jobs, zero `sorry`)

| file | what it proves |
|---|---|
| `Pod.lean` | pod = norm ≤ 1 = **7 of 9** axial states; 2 spare norm-3 carry states |
| `HexIsotropy.lean` | exactly **6 distinct unit neighbors** (free Z₆ action); pod rotation-invariant |
| `HexDisk.lean` | centered hexagonal number **3r²+3r+1** (grab by area) |
| `OffsetGrid.lean` | hex lattice **≃ the offset square grid** (checkerboard, (a,b)↦(2a+b,b)) |

These are the *node-invariant geometry* — the layer we own. The speed optimizer
`a·b·c·d` (technology-dependent coefficients) is deliberately left to industry PnR.

---

## Open levers (not yet tested)

- **Parallelized receiver** (Ian, 2026-08-28): cut receiver activation cost via
  parallelism. **SPECULATION** — note the distinction: the N=4 *parallelled-diode* win
  (0.562 pJ) was *wider devices* (Ron÷N, less drop); *more* sense amps would *duplicate*
  energy, not divide it. The receiver-side version of the width lever is untested.
- Ternary ECC ("6 directions data + center parity") — SPECULATION, structure is elegant
  (the center is the Z₆ fixed point) but unverified.
- Low-swing × resonant at L=40 µH with a *cheaper receiver* (the actual floor).
