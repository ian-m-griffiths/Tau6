# The Ternary Power Story — why a ternary gate costs 1.92× a binary gate's energy

**Purpose.** This is the energy side of the ternary-gate diagrams. It answers one question with
the measured ngspice numbers: *where do the joules actually go in a ternary gate, and why is the
cheapest possible ternary gate still more expensive than a binary gate?* The headline number —
**1.92×** — is the fairest possible ternary case (a *zero-transistor* ternary NOT against a binary
NOT, same rails, same receiver). The honest full-gate numbers are worse: **7.8×** on the cheapest
toggle and **53×** on the full-swing toggle. This file shows which of those joules are SENSING,
which are SWING, and which are LEAKAGE — each tied to a visible circuit element, each measured.

**Sources (all measured, none invented):**
`circuit/gate_energy.cir` + `.log` (the 2-threshold sensing tax and the 1.92×),
`circuit/diode_gates.cir` + `.log` (the diode-direction gate, dd_not),
`circuit/fair_binary.cir` + `.log` (the corrected single-ended binary baseline),
`circuit/break_before_make.cir` + `.log` (the crowbar→leakage correction and the decomposition),
`circuit/prebias_probe.cir` + `.log` (pre-bias = leakage, the crowbar wall),
and the write-ups `docs/compute/gate_energy.md`, `docs/compute/ground_up/fair_binary.md`,
`docs/compute/ground_up/break_before_make.md`, `docs/compute/ground_up/prebias_probe.md`,
`docs/compute/gates.md`.

**Calibration legend (two levels, per the task):**

- **DIRECT** — measured (a number read from an ngspice `.log` or counted from a netlist).
- **DERIVED** — follows from DIRECT facts by one arithmetic/logical step (a ratio, a ½CV² scaling,
  a floor). No invented numbers.

---

## 0. The one-line answer

A binary NOT flips **one wire through 1 V** for **6.94 fJ**. A ternary NOT does not have a free
lunch: even the **zero-transistor** ternary NOT (a wire swap) pays **1.92×** a binary NOT once you
put a receiver on it, because reading 3 states costs **2 threshold detectors, not 1** (measured
**2.54×** the receiver energy). When you then build the *real* ternary gate — the diode-direction
`dd_not` — its cheapest toggle is **54.2 fJ (7.8×)** and its full-swing toggle is **368.7 fJ
(53×)**. That gap decomposes into exactly three homes, all visible in the circuit: **(1) SENSING**
— two thresholds, a 1.26× per-bit floor no transistor removes; **(2) SWING** — a trit is two
directions/wires, so a full toggle moves 2× the charge and ½CV² squares it to 4.3×; **(3)
LEAKAGE** — the passive null-return termination draws ~17 µW while the output holds a rail, and it
is 89–93% of the measured gate energy. The thing it is **not** is "more logic": the 0-transistor
NOT still loses, and the loss is sensing + leakage, not gate depth.

---

## 1. Where the "1.92×" comes from (the sensing number, measured)

`gate_energy.cir` measures the *fairest* ternary gate there is — `tneg`, the negation that is a
pure wire swap, **0 transistors** — against a binary NOT, on identical single-ended 0→1 V rails,
both driving the same clocked PMOS-input sense-amp receiver. Per output transition:

| gate | logic | E_gate (driver) | E_rec (receiver) | **E_total** |
|---|---:|---:|---:|---:|
| binary NOT | 1 inverter (2 T) | 7.93 fJ | 24.35 fJ | **32.28 fJ** |
| ternary NOT (`tneg`) | **0 T (wire swap)** | 0.00 fJ | 61.87 fJ | **61.87 fJ** |
| **ratio** | | | **2.54×** | **1.92×** |

**[DIRECT — `gate_energy.log`: `egate_not=1.586e-14 J`, `erec_not=4.870e-14 J`, `egate_tneg=0`,
`erec_tneg=1.237e-13 J`, halved for per-toggle.]**

Two things to notice, because they are the whole story:

1. **The ternary NOT spends nothing on logic and still loses 1.92×.** The entire 61.87 fJ is the
   receiver. Binary pays 24.35 fJ for **1** sense amp; ternary pays 61.87 fJ for **2** sense amps
   (one per direction wire: `push vs 0`, `pull vs 0`). That is the **2-threshold sensing tax**.
2. **The 1.92× is *less* than the 2.54× receiver gap** only because the free logic (0 fJ vs binary's
   7.93 fJ) masks part of it. Per *bit* — a trit carries log₂3 ≈ 1.585 bits, not 1 — the ternary
   NOT still loses **1.21×** (39.0 fJ/bit vs 32.3 fJ/bit). **[DIRECT — `gate_energy.md` §"toggle-energy
   ratio": "negation +21%".]**

This is the *ceiling* for the sensing term in isolation. The honest full-gate numbers (§3) are worse,
because the real gate trades the clocked sense amp for a diode receiver — which removes the *sense-amp*
portion of the tax but pays two new costs: the full swing and the null-return leakage.

---

## 2. The three energy terms, each tied to a visible circuit cause

### 2a. SENSING — two thresholds (2.54× receiver, 1.26× floor)

Reading a 3-state value requires **two discriminations**, where reading a bit requires one. In the
2-wire encoding a trit is two wires, each of which must be resolved against the null; in the
1-wire polar gate it is one wire resolved against **two** boundaries (−V vs 0 vs +V). Either way:
**2 thresholds, forever** (DIRECT — `gates.md` §1; this is information structure, not a transistor
choice).

```
BINARY  (1 wire = 1 bit):                TERNARY  (2 wires = 1 trit = 1.585 bit):

   in ──►[NOT, 2T]──► out                   push ──►[sense amp P: push vs 0]──► push
                │                           pull ──►[sense amp N: pull vs 0]──► pull
                ▼                                 (null = neither wire crosses 0)
         [sense amp: out vs 0]                    
                                                  1 trit  =  2 detection paths
   receiver = 1 threshold               receiver = 2 thresholds
            24.35 fJ/eval                            61.87 fJ/eval  =  2.54×
```

**[DIRECT — `gate_energy.cir`: binary `Xsa1` is one `sensamp`; ternary `XsaP4`/`XsaN4` are two.]**
The ratio is **2.54×, not 2×**, because the ternary's *idle*-wire amp (reading `0 vs 0`) never
latches cleanly and draws more than a latching amp over the whole evaluation — measured, not
assumed (DIRECT — `gate_energy.md` §"the two numbers").

**The 1.26× floor (DERIVED).** Two thresholds cost 2× a one-threshold read, but a trit carries
1.585 bits. Per bit the unavoidable sensing penalty is

```
   2 thresholds / 1.585 bits  =  1.26×
```

That 1.26× is the *floor* — it is the information-theoretic price of 3 ordered states needing 2
boundaries, and **no transistor removes it**: a better transistor makes each threshold cheaper but
cannot make "two boundaries" into "one". **[DERIVED — arithmetic on the DIRECT 2.54× receiver and
the 1.585 bits/trit.]**

### 2b. SWING — two wires/directions per trit (½CV², 4.3× full swing)

The dynamic charge on the wire(s) is ½C·V² per edge. A bit is one wire through 1 V. A trit is two
directions (two wires in the one-hot encoding; two opposite rails on the polar wire), so its
*cheap* toggle matches binary, but its *full* toggle moves 2× the charge — and ½CV² squares the
swing:

```
trit value         wires (one-hot)        toggle       charge moved       intrinsic (measured)
───────────        ───────────────        ─────────    ─────────────────  ──────────────────
  null (0)          push=0  pull=0
  +1                push=1  pull=0        null↔+1      push 0→1:  1 wire×1 V   =  5.9 fJ
  −1                push=0  pull=1        null↔−1      pull 0→1:  1 wire×1 V   =  5.9 fJ
  (11 = NEVER)                             +1↔−1       push 1→0 AND pull 0→1
                                                        2 directions × full swing = 25.4 fJ
```

On the polar `dd_not` wire the same 4× appears as **one wire swinging 2 V** (from +1 V to −1 V)
instead of 1 V: the intrinsic full-swing cost is **25.4 fJ = 4.3× the 5.9 fJ** — exactly the
½CV²·(2V/V)² = 4× scaling (the 4.3 vs 4 is channel/ramp detail). **[DIRECT — `break_before_make.cir`
`Cl`-only control: 50.9 fJ/2 = 25.4 fJ for +1↔−1, 11.9 fJ/2 = 5.9 fJ for null↔+1.]**

The swing term is the one place ternary is *not* clearly behind: the cheap toggle's 5.9 fJ is
**matched** to binary's 6.94 fJ (both one wire, 1 V). The swing only hurts when a trit *must* cross
the full ±1 span — and then it is the honest ½CV², 4×, not a mystery.

### 2c. LEAKAGE — the elevated-|Vt| output stage + the static null-return (~17 µW)

The third term is the one that was **mislabeled "crowbar" and corrected to "leakage"**
(`fair_binary.md` §4 → `break_before_make.md`). The diode-direction gate's output stage uses
**elevated-|Vt| = 1.4 V** devices whose dead zone *is* the null — that dead zone already works
(shoot-through is measured at only ~1.7 fJ/toggle). The real cost is that the null is returned
**passively**: the output wire is terminated to ground through `Rterm = 100 kΩ`, and the next
gate's diode-receiver keepers `RkA/RkB = 100 kΩ` each hang off the wire too. Whenever the output
**holds a rail**, those resistors conduct a **static** current:

```
dd_not output stage (diode_gates.cir):            null-return termination (the LEAK path):
                                    +VDD
                                     │
   (pull rail rB, from diodes) ──○ ┌─┴───┐
                                    │ Mp  │  P_HI, |Vt|=1.4 V (drives +1 on pull)
                                    └─┬───┘
                                      ├───────────────── out  (polar wire)
                                    ┌─┴───┐
   (push rail rA, from diodes) ────○│ Mn  │  N_HI,  Vt =1.4 V (drives −1 on push)
                                    └─┬───┘
                                      │
                                    −VDD

      out ──┬── Rterm 100 kΩ ──► 0              ≈ 10 µA   ┐
            └── next gate keepers RkA/RkB         ≈ 7.4 µA │ ≈ 17 µA ≈ 17 µW
               100 kΩ each ──► 0                  (diode-fed)┘   while out holds a rail
```

**[DIRECT — `diode_gates.cir`: `Rterm` on every polar wire plus `RkA/RkB` inside `dd_recv`;
`break_before_make.cir` measured the steady-state power at 17.3 µW and decomposed the toggle:
null↔+1 = 5.9 fJ intrinsic + 48.2 fJ leakage; +1↔−1 = 25.4 fJ intrinsic + 343.3 fJ leakage.]**

Three facts that make this term decisive (all DIRECT — `break_before_make.md`):

- **It is static, not transient.** The current flows the whole time the wire sits at ±V — it is a
  DC path, not a switching glitch. That is why `prebias_probe.cir` ("pre-bias = leakage") finds the
  same µA-class wall at a threshold.
- **It scales with *hold time*, not swing.** The +1↔−1 pulse holds a rail ~40 ns of its cycle vs
  ~5 ns for null↔+1, so its leakage is ~7× larger (343 vs 48 fJ) — which is *exactly* the measured
  6.8× "crowbar" gap. The 6.8× was never shoot-through; it was the DC null-return integrating over
  a longer hold.
- **It is a design choice, not a device limit.** A non-leaky null return — higher `Rterm`, or a
  clocked/latching receiver that draws no DC on a held rail — removes it. Break-before-make gating
  does *not* (measured flat 340–350 fJ, plus 2.97–8.79 pJ of gating overhead).

---

## 3. The honest numbers (measured, decomposed)

Binary baseline is the *corrected* one (`fair_binary.md`): single-ended **0→1 V**, no clocked
receiver (the next gate's input capacitance *is* the load). Ternary is the real diode-direction
gate `dd_not` at both toggles.

| gate | toggle | measured (fJ) | = intrinsic swing | + null-return leakage | vs binary NOT |
|---|---|---:|---:|---:|---:|
| binary NOT | 0↔1 | **6.94** | 6.94 | 0 | 1.00× |
| **dd_not** | null↔+1 (cheapest) | **54.2** | 5.9 | ~48 | **7.8×** |
| **dd_not** | +1↔−1 (full swing) | **368.7** | 25.4 | 343.3 | **53×** |

**[DIRECT — `fair_binary.cir` §2/§3 for 6.94/368.7 and the 54.2 null↔+1; `break_before_make.cir`
for the 25.4 + 343.3 and 5.9 + 48.2 decompositions (its `Rterm`-removal control).]**

Read the two columns against the three terms:

- **Intrinsic swing** is the honest ½CV²: 5.9 fJ (1 V) matches binary's 6.94 fJ; 25.4 fJ (2 V) is
  4.3× that. Swing is the *only* term that is matched-to-binary on the cheap toggle and exactly
  predictable on the full toggle. **[DIRECT]**
- **Leakage** is the dominator: **89% of the 54.2 fJ** and **93% of the 368.7 fJ**. Take it away
  (the `Rterm`-removal control) and the ternary gate collapses to 5.9–25.4 fJ — the swing alone,
  i.e. competitive with binary. **[DIRECT]**
- **Sensing** is not inside the 54.2/368.7 numbers at all — the diode receiver removed the clocked
  sense amp (`E_rec = 0`). Its cost shows up instead in `gate_energy.cir` (§1): 2.54× the receiver,
  1.92× total for even the free NOT, and a 1.26× per-bit floor that the diode receiver *relocates*
  (two boundary decisions move into the two elevated-|Vt| devices) but cannot delete. **[DIRECT for
  the measurement; DERIVED for "relocated, not deleted".]**

---

## 4. Where each joule goes — the ternary gate, annotated

One ternary NOT (`dd_not`, the gate whose 54.2/368.7 fJ are the honest numbers), with all three
energy terms marked at their physical location. (The clocked-receiver "2.54×" from §1 is the
SENSE term in its sense-amp form; the diode receiver below is the same term folded into two
passive boundary devices.)

```
                       TERNARY NOT  (dd_not) — the three energy homes
   ══════════════════════════════════════════════════════════════════════════════════════

   SENSE ─ 2 thresholds (reading 3 states = 2 boundaries; 1.26× per-bit floor)
   ──────   the receiver splits ONE wire into TWO direction rails:
                                              ┌── D1 ──► rA  (push rail: 0 → +V on push)
            win (polar: +1 / 0 / −1) ────────┤
                                              └── D2 ──► rB  (pull rail: 0 → −V on pull)
            null = neither diode fires (free)      │            │
                                                   │            │  2 boundary devices:
                                                   │            │  (the clocked version
                                                   │            │   is 2 sense amps = 2.54×)

   SWING ─ 2 directions/trit (½C·V²; matched on the cheap toggle, 4.3× on the full toggle)
   ──────
            null↔+1 : 1 direction × 1 V  =  5.9 fJ   (≈ binary NOT's 6.94 fJ — matched)
            +1↔−1   : 2 directions × 2 V = 25.4 fJ   (4.3× = ½CV²·(2V)²)

   OUTPUT STAGE ─ elevated |Vt| = 1.4 V (the dead zone IS the null)
   ────────────
                                   +VDD                             −VDD
                                    │                                │
                 rB (pull) ──○ ┌────┴────┐            ┌────┴────┐ ○── rA (push)
                                │  Mp P_HI │            │ Mn N_HI │
                                └────┬────┘            └────┬────┘
                                     └──────────┬───────────┘
                                               out  (polar wire: +1 / 0 / −1)

   LEAKAGE ─ the static null-return (the corrected "crowbar"); ~17 µW while a rail is held
   ───────
            out ──┬── Rterm 100 kΩ ──► 0          ≈ 10 µA
                  └── next gate keepers RkA/RkB   ≈ 7.4 µA      (diode-fed)
                       100 kΩ each ──► 0
                  ─────────────────────────────────────────
                   ≈ 17 µA ≈ 17 µW  ·  hold time  =  48 fJ (null↔+1) / 343 fJ (+1↔−1)

   ──────────────────────────────────────────────────────────────────────────────────────
   BUDGET (measured, per toggle):
        null↔+1  54.2 fJ  =  5.9 swing (11%)  +  ~48 leakage (89%)
        +1↔−1   368.7 fJ  = 25.4 swing ( 7%)  + 343   leakage (93%)
        (the 1.92× headline is the SENSE term alone: 2 sense amps = 2.54× a binary receiver)
```

---

## 5. The honest bottom line

**The energy is dominated by SENSING + LEAKAGE, not by "more logic" — and neither is removable
by a cleverer transistor.**

1. **It is not "more logic".** The ternary NOT is *zero transistors* and it still loses 1.92× to a
   2-transistor binary NOT. The 12–68-transistor gate bodies (MIN, the mod-3 sum) only make a loss
   that already exists *deeper* — they are not its cause. **[DIRECT — `gate_energy.md`: tneg, 0 T,
   still 1.92×/1.21× per bit.]**

2. **SENSING is the 1.26× floor.** 3 states need 2 boundaries; 2 boundaries ÷ 1.585 bits/trit =
   1.26× per bit, *before* any logic. A better transistor shrinks each threshold's joules but cannot
   turn two boundaries into one — the floor is information structure, not device quality.
   **[DERIVED — from the DIRECT 2.54× receiver and 1.585 bits/trit.]**

3. **LEAKAGE is a null-return design choice.** The ~17 µW through `Rterm` + keepers is the price of
   returning the null *passively* through resistors. It is 89–93% of the measured gate energy, and it
   is removable by a *different circuit* (a non-leaky null return: higher `Rterm`, or a
   clocked/latching receiver that draws no DC on a held rail) — not by a better transistor. The thing
   that looked like a fixable "crowbar" was a static DC path the design chose to leave in.
   **[DIRECT — `break_before_make.md`; the "not a transistor fix" is DERIVED from the measured
   flat BBM sweep + the DC path location.]**

Put together: the 1.92× is the sensing tax on even the free gate; the honest 7.8×–53× is that same
sensing (relocated into two boundary devices) plus a full ½CV² swing plus a leaking null return —
and the two terms that dominate, sensing and leakage, are a *floor* and a *design choice*, not a
transistor deficiency.

---

## Calibration ledger

| claim | calibration |
|---|---|
| binary NOT 0↔1 = 6.94 fJ (single-ended, no clocked receiver) | **DIRECT** — `fair_binary.cir` §2, `fair_binary.log` |
| dd_not null↔+1 = 54.2 fJ (7.8×); +1↔−1 = 368.7 fJ (53×) | **DIRECT** — `fair_binary.cir` §3 + `diode_gates.cir` (54.2 reproduced) |
| decomposition 25.4 intrinsic + 343.3 leakage; 5.9 + 48.2 | **DIRECT** — `break_before_make.cir` Rterm-removal control |
| leakage ≈ 17 µA ≈ 17 µW (Rterm 10 µA + keepers 7.4 µA) | **DIRECT** — `break_before_make.md` §3 steady-state |
| "crowbar" is actually static null-return leakage, scales with hold time | **DIRECT** — `break_before_make.md` (corrects `fair_binary.md` §4) |
| shoot-through ≈ 1.7 fJ (dead zone already works) | **DIRECT** — `break_before_make.md` (25.4 − 4×5.9) |
| receiver 24.35 fJ (1 SA) vs 61.87 fJ (2 SA) = 2.54× | **DIRECT** — `gate_energy.log` |
| tneg vs NOT = 1.92× per toggle, 1.21× per bit | **DIRECT** — `gate_energy.md` (arithmetic on the log) |
| "2.54× not 2×: idle-wire amp draws more" | **DIRECT** — `gate_energy.md` |
| sensing floor = 2 thresholds / 1.585 bits = 1.26× | **DERIVED** — arithmetic on DIRECT 2.54× and log₂3 |
| intrinsic 25.4 fJ = 4.3× 5.9 fJ = ½CV² swing scaling | **DIRECT** (measured 4.3×); the ½CV² identity is **DERIVED** |
| trit = 2 wires = 0.79 bits/wire | **DIRECT** — `gate_area.md` (encoding arithmetic) |
| leakage is a "design choice", removable by a non-leaky null return | **DERIVED** — from the DC path location + measured BBM no-op |
| sensing is "not removable by a cleverer transistor" | **DERIVED** — 3 ordered states ⇒ 2 boundaries (information structure) |

*No number in this file is invented: every energy is read from an ngspice `.log` (`gate_energy`,
`fair_binary`, `diode_gates`, `break_before_make`, `prebias_probe`), every ratio is one arithmetic
step on those numbers, and the two "floor" / "design choice" conclusions are flagged DERIVED where
they step beyond the measurement.*
