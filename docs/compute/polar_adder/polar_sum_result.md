# Polar current-mode sum — measured: the free part, and where it ends

**2026-08-30 — the measured "free addition by Kirchhoff" claim, in ngspice 44.2.**

Companion to `polar_full_adder_design.md` / `binary_baseline.md` (the adder's
logic + yardstick) and to `docs/compute/ground_up/analog_polar.md` §3 (whose
"Idea A — KCL makes the sum free" sketch this file finally *runs*). This file
measures **only the sum**: the wire junction where two polar currents meet.
The wrap/carry is deliberately out of scope and handed to the next agent.

Calibration legend (repo standard): **DIRECT** = measured here (`ngspice -b
polar_sum.cir`) or read from another repo measurement; **DERIVED** =
arithmetic on DIRECT numbers; **OURS** = design interpretation; **SPECULATION**
= untested.

---

## 0. One-line answer

**The Kirchhoff sum is free — measured exactly.** Two polar currents meeting at
one node add to the correct signed current (`+1+1=+2`, `+1−1=0`, `−1−1=−2`,
`+1+0=+1`) with zero error, at zero node voltage, and the only energy is ohmic
`I²R_wire` loss in the wires (~100 pW per conducting wire at 1 µA through 100 Ω,
≈0.1 fJ over a full 1 µs hold — ~1000× below one measured gate toggle). **The
free ride ends at the output: the sum is a *magnitude* in `{0, ±1, ±2}`, and the
`±2` states lie OUT of the ternary range `±1`, so a real adder must still
threshold `|σ| > 3·Iunit/2` and wrap `±2 → ∓1` with a signed carry — that
measurement is *not* free.**

---

## 1. The netlist and what it measures

`circuit/polar_sum.cir` instantiates four independent summing junctions. Each
case is two **ideal** current sources (push/pull/null) that meet at one node,
each through its own `Rwire = 100 Ω` wire resistance, with the node feeding a
`0 V` ammeter to ground.

| element | what it is | why |
|---|---|---|
| `I<a|b>N 0 nX {±Iunit}` | ideal current source per input | push = `+Iunit` (current into the node), pull = `−Iunit`, null = `0`; abstracts the previous stage's driver (its energy is already counted there — the same ideal-input convention as `diode_gates.cir` / `gate_energy.cir`) |
| `Rw… nX sN {Rwire}` | 100 Ω parasitic wire | measures the *honest* wire loss instead of assuming an ideal node |
| `VsN sN 0 0` | 0 V ammeter to ground | reads the exact short-circuit output current `I(VsN)` = the KCL sum, while holding the node at 0 V so the meter itself dissipates nothing |
| `BpwN` | power B-source | wire dissipation `Σ V²/Rwire`, computed from node voltages |

`Iunit = 1 µA` is arbitrary — the sum is *linear* in it, so the magnitude
choice only rescales the (already negligible) wire loss. **[DIRECT — the
netlist; the linearity is the definition of a current source.]**

---

## 2. The measurement (all four cases)

```
case        I_out (measured)    expected    node V    wire energy (1 µs)    wire power
+1 + +1     +2.000000 µA       +2 µA       0 V       0.2 fJ                 200 pW
+1 + -1      0.000000 µA        0 µA       0 V       0.2 fJ                 200 pW
-1 + -1     -2.000000 µA       -2 µA       0 V       0.2 fJ                 200 pW
+1 + 0      +1.000000 µA       +1 µA       0 V       0.1 fJ                 100 pW
```

- **Current magnitudes — exact.** `I_out = I_a + I_b` to the simulator's full
  precision (`2.000000e-06`, `0.000000e+00`, `-2.000000e-06`, `1.000000e-06`).
  The summing node is a conservation-of-charge identity, not a device: there is
  nothing in the model to introduce error. **[DIRECT.]**
- **Node voltage — exactly 0 V.** The ammeter holds the junction at ground, so
  the junction itself stores/dissipates no energy. **[DIRECT.]**
- **Wire energy — I²R only.** Each *conducting* wire carries exactly one unit
  (measured `vwire_a1 = vwire_b1 = 0.1 mV` = `1 µA × 100 Ω`), so it dissipates
  `I²R = 100 pW`; two wires → 200 pW, one wire → 100 pW. **The `±2` never
  exists on any single wire** — it exists only *at the node* as a current
  magnitude. **[DIRECT.]**

---

## 3. The free part, confirmed — and the one honest caveat about "free"

**Yes, the sum is free.** There is no supply, no clock, no active device on the
sum path; KCL is a charge-conservation identity. In the ideal limit
(`Rwire → 0`) the junction costs **exactly 0 J** — nothing exists that could
dissipate "addition energy". **[DIRECT for KCL-identity; OURS for "this removes
the sum-construction cost" — see §4.]**

**The tiny parasitic cost is *not* a sum cost.** The measured `I²R_wire` is
ohmic loss present on *any* wire carrying current, summed or not: a lone `+1`
current on one wire already burns the same 100 pW. The addition adds **nothing**
on top of what the two inputs would dissipate separately. At 100 pW/wire, even a
full 1 µs hold costs ~0.1 fJ/wire — **~500–1200× below a single measured gate
toggle (54–122 fJ, `diode_gates.cir`)**. In a realistic ~30 ns gate-window the
wire loss is ~3 aJ/wire, i.e. ~10⁴× below a gate toggle. **[DERIVED — the
comparison re-reads `diode_gates.cir`'s measured per-toggle energies; the wire
figure is this file's measurement.]**

---

## 4. Where the free ride ends (the honest physical limit)

The output of the junction is the **signed digit sum** `σ = a + b`:

```
σ ∈ { −2, −1, 0, +1, +2 }        ← 5 values, NOT the 3 the wire carries
```

The four measured cases already cover every *magnitude* (`|σ| = 0, 1, 2`), and
the full 9-input table spans all five values. The `±2` states are **out of the
ternary range `±1`**, so a balanced-ternary adder cannot pass `σ` onward as-is:

```
σ = +2  →  s = −1,  carry = +1     (wrap down:  +1 ⊕ +1 = −1)
σ = −2  →  s = +1,  carry = −1     (wrap up:   −1 ⊕ −1 = +1)
σ ∈ {−1,0,+1}  →  s = σ,  carry = 0
```

To do that the cell must **measure `|σ| > 3·Iunit/2`** (two thresholds, one per
sign) and then **steer `∓3·Iunit` back** through the node to correct `±2` to
`∓1`. That threshold-and-wrap is the *carry*, it is a **2-threshold measurement
(Law 1, `device_physics.md` §2.3)**, and it is **not free** — the summation was
never the expensive part, the *measurement* is. **[DIRECT — the wrap map is
computed arithmetic; "the wrap decision is a 2-threshold measurement" is OURS,
following `analog_polar.md` §3.2.]**

**One-line "where the free ride ends":** *KCL hands you the raw magnitude
`σ ∈ {0,±1,±2}` for free, but the instant you must tell `±2` from `±1` to wrap
it back into ternary, you pay the 2-threshold measurement — that is the carry,
and that is the next agent's job.*

---

## 5. Calibration ledger

| claim | calibration |
|---|---|
| `I_out = I_a + I_b` exactly (4 cases) | **DIRECT** — `polar_sum.cir`, measured to full precision |
| summing node at 0 V, meter dissipates 0 | **DIRECT** — measured `vsum = 0` |
| wire loss = `I²R_wire` only (100 pW/wire) | **DIRECT** — measured `pwire`, `vwire = 0.1 mV` |
| `±2` exists only at the node, never on one wire | **DIRECT** — measured each wire carries exactly 1 unit |
| ideal node (`Rwire→0`) costs exactly 0 J | **DIRECT** — no dissipating element remains |
| wire loss ≈ 500–1200× below a gate toggle | **DERIVED** — vs `diode_gates.cir` 54–122 fJ/toggle |
| sum free = removes the sum-construction cost | **OURS** — follows `analog_polar.md` §3.1 Item 1 |
| `σ ∈ {−2,…,+2}`; wrap `+2→−1`, `−2→+1` | **DIRECT** — arithmetic table, `analog_polar.md` §3.2 |
| wrap/carry = 2-threshold measurement (not free) | **OURS** — Law 1, `device_physics.md` §2.3 |

---

## 6. Sources

- `circuit/polar_sum.cir` + `circuit/polar_sum.log` — this measurement.
- `circuit/diode_gates.cir` + `diode_gates.log` — the fJ-class gate toggles used
  for the "~1000× below" comparison, and the ideal-input-source convention reused.
- `circuit/gate_energy.cir` — the same conventions (ideal inputs, `Rwire = 100`,
  supply-energy measurement style).
- `docs/compute/ground_up/analog_polar.md` §3 — the "KCL free sum + priced wrap"
  argument this file measures (Idea A).
- `docs/compute/ground_up/device_physics.md` §2.3 — Law 1 (the 2-threshold tax).
- `docs/compute/polar_adder/polar_full_adder_design.md` — the wrap/carry target
  (next agent).

*No number here is invented: the currents and energies are read from
`polar_sum.log`, and the only derived figure (the ~1000× comparison to gate
energy) re-reads `diode_gates.cir`'s own measured toggles.*
