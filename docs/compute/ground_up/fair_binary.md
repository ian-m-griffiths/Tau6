# Fair Binary — the honest "N× vs binary" re-baseline

**2026-08-29, ngspice 44.2, measured (`circuit/fair_binary.cir`, `fair_binary.log`).**

This file executes `meta_assumptions.md` TODO item 1: re-run every "N× vs binary"
number against a **fair** binary baseline — **single-ended 0→1 V (1 V swing)**, not
the ±1 V bipolar (2 V swing) convention the gate fair-fights used. Every number below
is a fresh `ngspice -b` measurement; no number is invented or extrapolated from the
old corpus.

---

## 0. The one-line answer

The transport win shrinks **9.2× → 6.3×** against natural single-ended binary, and to
**2.7×** against a *matched-swing* (0.65 V) binary. The diode-gate "win" **reverses
into a 3.4–4.9× per-bit LOSS** (and a ~33× loss at the full-swing toggle) — it was
entirely an artifact of the 2 V bipolar binary baseline. The meta-critic's headline
("binary was 2 V bipolar, so halve every win") is **half right**: it is exactly right
for the *gates*, but **wrong for transport** — the transport binary reference
(`binary_baseline.cir` → 0.748 pJ/bit) was *already* single-ended 0→1 V. The transport
correction comes from a **load mismatch** (1.5 pF vs the ternary's ~1 pF line), not a
swing mismatch, so it is ~1.46× not ~2×.

---

## 1. What the old binary baselines actually were

Measured by re-running the two baseline netlists as they exist:

| baseline | netlist | swing | load | measured | used by |
|---|---|---|---|---|---|
| transport binary | `binary_baseline.cir` | **0→1 V single-ended** | 1.5 pF | **0.748 pJ/bit** (1.496 pJ / 2) | ternary/PAM-4/PWM-5/low-swing/resonant "vs binary" |
| gate binary | `diode_gates.cir` §binary | **±1 V bipolar (2 V)** | Rw=100 + CL=10 fF | NOT 54.0 / NAND 79.3 / NOR 63.5 fJ/toggle | diode_gates / polar_gates ratios |

**Finding 1 (DIRECT): the meta-critic's A2 is wrong for transport.** The 0.748 pJ/bit
transport reference is *already* single-ended 0→1 V (`binary_baseline.cir`:
`VSUP vdd 0 DC 1.0`, `Vin PULSE(0 1.0)`). The "2 V bipolar" claim is true **only** of
the *gate* baselines (`diode_gates.cir`/`polar_gates.cir` run binary on ±VDD = ±1.0 V).

**Finding 2 (DIRECT): but the transport reference has a different handicap — its load.**
`binary_baseline.cir` drives a **1.5 pF** load; the ternary transport cell (`tcell4`)
drives **~1 pF** (`cline=1p` + rail caps). So 0.748 pJ/bit overstates the honest
same-wire binary by ~1.46×.

**Finding 3 (DIRECT): the bipolar→single-ended correction on the *gates* is ~7×, not ~2×.**
Binary NOT drops 54.0 → 6.94 fJ (7.8×), NAND 79.3 → 11.4 fJ (7.0×), NOR 63.5 → 8.65 fJ
(7.3×). The meta-critic's "~2× cheaper" was too small by ~3.5×: halving the swing
quarters the ½CV² term (4×) **and** collapses the short-circuit (crowbar) current —
the ±1 V inverter sweeps its input through a ~1.2 V-wide both-devices-on window, the
0→1 V inverter through a ~0.2 V window at ~6× lower overdrive.

---

## 2. The fair single-ended binary transport link (measured)

`fair_binary.cir` §1: CMOS inverter (WP=11u/WN=5.5u — the ternary fair-fight driver)
→ `rwire=100` → `cline=1p` + 10 fF next-gate input, rails 0..VDD. **No clocked
receiver**: binary's next gate *is* the receiver, contributing only its gate
capacitance (already in the load) — the honest contrast with ternary's two locally-
powered sense amps (E_rec ≈ 0.05 pJ/trit).

| case | rail | swing | full-cycle supply | **per bit** |
|---|---|---|---|---|
| BT1 (natural binary) | 0→1.00 V | 1.00 V | 1.0232 pJ | **0.5116 pJ/bit** |
| BT2 (low-swing ref) | 0→0.65 V | 0.65 V | 0.4323 pJ | **0.2162 pJ/bit** |

Sanity check (DIRECT): ½·(1.01 pF)·(1 V)² = 0.505 pJ vs measured 0.512 pJ (1.4% channel
loss); ½·(1.01 pF)·(0.65 V)² = 0.213 pJ vs 0.216 pJ. The driver is strong enough that
the binary bit is essentially its line capacitance.

---

## 3. The corrected "N× vs binary" table — transport champions

Numerators unchanged from `ENERGY_RESULTS.md` (all measured there). Only the binary
denominator is corrected.

| champion | pJ/bit | published N× (vs 0.748) | **corrected N× (vs 0.512, natural)** | corrected N× (vs 0.216, matched 0.65 V) |
|---|---|---|---|---|
| ternary null-carrying, uniform | 0.515 | 1.45× | **0.99× (tie)** | — (full-swing scheme) |
| PAM-4 | 0.401 | 1.86× | **1.28×** | — |
| PWM-5 (length-only) | 0.550 | 1.36× | **0.93× (loss)** | — |
| PWM-5-2D (long-low×short-high) | 0.397 | 1.88× | **1.29×** | — |
| LC-resonant (full swing) | 0.133–0.168 | 4.5–5.6× | **3.05–3.85×** | — |
| low-swing (VDDR=0.65 V) | 0.092 | 8.1× | **5.57×** | **2.35×** |
| **low-swing×resonant (B1)** | **0.081** | **9.2×** | **6.32×** | **2.67×** |

**Verdict (transport).** The honest "vs binary" for the champion is **6.3×** (against
natural single-ended binary), down from 9.2× — a **1.46× shrink**, from the load
mismatch, *not* the 2× swing correction the meta-critic assumed. Against a
**matched-swing** 0.65 V binary it is **2.67×** — and that number is the more honest
one, because it isolates what *ternary* contributes once binary is allowed the same
low-swing lever. The entire full-swing leaderboard (ternary/PAM-4/PWM-5) collapses:
**ternary null-carrying ties binary (0.99×), PWM-5 loses (0.93×), and only PAM-4 /
PWM-5-2D hold a thin ~1.3× edge.**

---

## 4. The diode gate vs fair binary (measured, both toggles)

`fair_binary.cir` §2 (binary, single-ended) and §3 (ternary diode-direction gates at
the **full-swing +1↔−1** toggle — the expensive one `diode_gates.cir` never measured).
`diode_gates.cir` supplies the null↔+1 toggle (reproduced: 54.2/60.8/58.6 fJ).

| gate | toggle | energy/toggle | per-bit (÷1.585) | vs fair binary (per-toggle) | vs fair binary (per-bit) |
|---|---|---|---|---|---|
| binary NOT | 0↔1 | 6.94 fJ | 6.94 fJ | 1.00× | 1.00× |
| **dd_not** | null↔+1 | 54.2 fJ | 34.2 fJ | **7.8× worse** | **4.93× worse** |
| **dd_not** | +1↔−1 | 368.7 fJ | 232.6 fJ | **53× worse** | **33.5× worse** |
| binary NAND | 0↔1 | 11.36 fJ | 11.36 fJ | 1.00× | 1.00× |
| **dd_nand** | null↔+1 | 60.8 fJ | 38.4 fJ | **5.35× worse** | **3.38× worse** |
| dd_nand | +1↔−1 | 433.8 fJ | 273.7 fJ | 38× worse | 24× worse |
| binary NOR | 0↔1 | 8.65 fJ | 8.65 fJ | 1.00× | 1.00× |
| **dd_nor** | null↔+1 | 58.6 fJ | 37.0 fJ | **6.77× worse** | **4.28× worse** |
| dd_nor | +1↔−1 | 410.8 fJ | 259.2 fJ | 47× worse | 30× worse |

Published (bipolar binary): dd_not 0.63×, dd_nand 0.48×, dd_nor 0.58×, dd_min 0.97×,
dd_max 0.87× — i.e. "up to 2.1× *better*". **Corrected: the diode-direction gate is
3.4–4.9× *worse* per bit at its cheapest toggle, and ~24–33× worse at the full-swing
toggle.** The "0.48×" headline was 100% the 2 V bipolar binary, not the gate.

Two mechanisms, both measured, both previously hidden:

1. **The binary side was inflated ~7×** (Finding 3): single-ended 0→1 V binary is
   6.9–11.4 fJ, not 54–79 fJ.
2. **The ternary full-swing toggle was never measured.** null↔+1 is genuinely the
   cheapest (54 fJ), but +1↔−1 is **6.8× that** (369 fJ) — the elevated-|Vt| dead-zone
   output stage has a thin dead band (rails only reach ±0.57/±0.73 V), so a full-swing
   toggle passes through a window where P_HI and N_HI conduct together (crowbar). This
   is exactly the `test_suite_spec.md` §3.3 "cheapest toggle is generous to ternary"
   warning, now quantified.

> **CORRECTION (2026-08-30, `break_before_make.md`):** the "6.8× crowbar" is NOT
> shoot-through. Re-measuring with the null-return termination removed (Rterm = 10 GΩ)
> decomposes 368.7 fJ into **25.4 fJ intrinsic + 343.3 fJ leakage**. The intrinsic
> 2 V swing is 4.3× the 1 V swing's 5.9 fJ (exactly ½CV² scaling), so shoot-through is
> only ~1.7 fJ/toggle (negligible — the elevated-|Vt| dead zone already works). The
> 6.8× is *static* null-return leakage (Rterm 100 kΩ + next-receiver keepers ≈ 17 µW)
> flowing whenever the output holds a rail, scaling with **hold time** (40 ns vs 5 ns),
> not swing. The fix is a non-leaky null return (higher Rterm, or a clocked receiver),
> **not** break-before-make gating (measured flat 340–350 fJ + 2.97–8.79 pJ overhead).

MIN/MAX (2-stage NAND/NOR+NOT, published 0.97×/0.87×) were **not** re-measured here;
they are the same two effects stacked (their binary analog — 2-stage AND/OR on 0→1 V —
would be ~2× the single-stage, so expect the same ~4×-class reversal).

---

## 5. Verdict — how much the win shrinks

| claim (old) | honest re-baseline | shrink |
|---|---|---|
| transport champion 9.2× (0.081 pJ/bit) | **6.3× vs natural binary; 2.67× vs matched-swing binary** | 1.46× / 3.4× |
| low-swing champion 8.1× (0.092 pJ/bit) | **5.6× / 2.35×** | 1.46× / 3.4× |
| ternary null-carrying 1.45× (0.515) | **0.99× — a tie** | win gone |
| PAM-4 1.86× (0.401) | **1.28×** | 1.46× |
| PWM-5-2D 1.88× (0.397) | **1.29×** | 1.46× |
| PWM-5 1.36× (0.550) | **0.93× — a loss** | reversed |
| diode gates 0.48–0.97× (2× "better") | **3.4–4.9× worse (cheapest); ~24–33× worse (full swing)** | reversed, ~7× deeper than predicted |

The honest core that *survives*: (a) the low-swing lever is real and large — but it is
**radix-agnostic** (binary at 0.65 V drops to 0.216 pJ/bit for free); (b) the
LC-resonant charge recovery is real (it survives as 3–6× at full swing, and the
resonant low-swing corner holds ~2.7× at matched swing); (c) radix economy remains a
namespace/density fact, not an energy fact. What *collapses*: every headline that
bundled "free null + low swing" and credited it to the radix, and the diode-gate
transport→compute bridge, which reverses outright.

---

## 6. Calibration ledger

| claim | calibration |
|---|---|
| transport binary reference (0.748) is single-ended 0→1 V, 1.5 pF | **DIRECT** — re-ran `binary_baseline.cir`, `VSUP=1.0` single rail |
| gate binary reference is ±1 V bipolar (2 V swing) | **DIRECT** — `diode_gates.cir` lines 56–58; re-ran, 54.0/79.3/63.5 fJ reproduced |
| fair binary transport 0.512 / 0.216 pJ/bit | **DIRECT** — `fair_binary.cir` §1, ngspice exit 0, no warnings |
| fair binary gates 6.94/11.36/8.65 fJ | **DIRECT** — §2 |
| dd_not/dd_nand/dd_nor full-swing 369/434/411 fJ | **DIRECT** — §3 |
| all ratios in §3/§4 | **DIRECT** — arithmetic on the above |
| "binary needs no clocked receiver" (the next gate is the receiver) | **OURS** — standard CMOS; it is the *framing* that makes §2 receiver-free. A perverse "add a clocked SA to binary" control would only *raise* the binary number, widening the transport win; it is not the honest binary. |
| choosing matched 0.65 V binary as the secondary reference | **OURS** — methodology; the 0→1 V number is the canonical "natural binary". |
| "single-ended binary crowbar is the reason for the ~7× gate gap" | **OURS/ANALOGY** — mechanism reading of the measured 54→6.9 fJ gap; the *numbers* are DIRECT, the crowbar *explanation* is our inference. |
| MIN/MAX corrected ratios | **SPECULATION** — not re-measured; inferred from the single-stage reversal. |

---

## TODO / not covered / caveats

1. **Matched-swing binary for the low-swing×resonant corner.** BT2 (0→0.65 V) matches
   the *lowswing_sweep* champion (VDDR=0.65 V), but the resonant B1 champion runs
   VLC=±0.28 V (line ≈ 0.5 V). A 0→0.5 V binary reference (≈0.5·1.01p·0.5² ≈ 0.13 pJ/bit)
   is the strictly-matched control for B1 and would shrink its 2.67× further toward ~1.6×.
2. **MIN/MAX diode gates not re-measured** (2-stage, and their binary AND/OR analog on
   0→1 V was not built). Their corrected ratios in §4 are inference, not measurement.
3. **Energy-delay product still not folded in** (`meta_assumptions.md` A1). The 0.081 and
   0.092 champions are adiabatic/low-swing at 48–100 Mtrit/s and ~400 Mtrit/s; the fair
   binary here is a fast (GHz-class) CMOS link. Per joule-of-work the resonant win shrinks
   further; per *wire* (1.585 bits/wire) and per *symbol* (namespace) it is untouched.
4. **LEVEL=1, no body diodes, no device mismatch** — the same caveat class as every
   prior fair fight. Real SA offsets (σ≈5–20 mV) move the ternary low-swing floor to
   0.22–0.35 pJ/bit (`ENERGY_RESULTS.md`), which against 0.512 pJ/bit binary is a
   *loss*, not a win. The fair binary side has no such offset penalty (its receiver is a
   gate). So this re-baseline is *optimistic for ternary*.
5. **Null frequency.** The 0.515 pJ/bit ternary number assumes uniform trits; null-heavy
   data would lower it, but the *same* workload argument applies to binary (a binary link
   that mostly idles pays ~0 too). The tie (0.99×) is the uniform average; the null-
   dominated headline is a workload claim, not a circuit claim.
6. **The "receiver-free binary" is the one genuine asymmetry in our favor.** If a
   reader insists binary must also pay a clocked sampler (to make the receiver
   topology identical), the binary number rises and the transport win widens back up —
   but that is not binary's natural implementation. Flagged rather than hidden.
7. **This file corrects the *baseline*; it does not re-derive the champion numerators.**
   The 0.081/0.092/0.401/0.515/0.550 numbers are carried from `ENERGY_RESULTS.md`
   un-audited. A full re-audit of those netlists is a separate task.

*Measured with ngspice 44.2, `circuit/fair_binary.cir` (`ngspice -b` exit 0, no
convergence warnings) and `circuit/diode_gates.cir` (baseline reproduction).*
