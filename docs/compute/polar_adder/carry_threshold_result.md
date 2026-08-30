# Carry Threshold — the "detect magnitude ≥ 2 → carry" device

**Netlist:** `circuit/carry_threshold.cir` · **Log:** `circuit/carry_threshold.log` · ngspice 44.2

## The honest question

The polar ternary adder sums two input **currents** at a node (Kirchhoff's
current law). That sum is a free **magnitude**: `|S| = |Ia + Ib| ∈ {0, 1, 2}`
units. Getting `0, ±1, ±2` costs nothing — it is two wires tied together.

But the sum digit must be a ternary digit `±1`, and `±2` must fold back to
`∓1` **with a carry**. To know *when* to fold, you must answer one question:

> **is |S| ≥ 2 ?**

That question is a **threshold** — a device that conducts only above ~2 units —
and it is *not* free. The magnitude is free; the ≥2 **detection** is a real
device.

## The device (stated): a **zener diode**, in reverse breakdown

A zener conducts only when the reverse voltage across it exceeds its
breakdown voltage `Vz`. Set `Vz` strictly **between 1 unit and 2 units**
(here ~1.5 units), and it is a magnitude-2 threshold:

| |S| | Vsum | zener | carry |
|---|---|---|---|---|
| 2 units | ~2.0 V | **conducts** | **CARRY** |
| 1 unit  | ~1.0 V | ~0 current | no carry |
| 0       | 0 V    | 0 current  | no carry |

A single zener is **unidirectional** (it forward-clamps at ~0.7 V on the
opposite polarity), so one zener detects **one sign** of the carry. The
**signed ±carry needs two of them**, wired back-to-back (anti-series) so
each blocks the other's forward clamp. That pair *is* the "2-threshold tax"
in device form.

## Representation

- 1 ternary unit = 1 mA (same convention as `ternary_transistor.cir`).
- The summed current flows through a sense resistor `Rs = 1 kΩ`, so
  1 unit = 1.0 V and 2 units = 2.0 V. `Rs` is the magnitude **readout** — it
  dissipates on *every* addition and is counted separately from the threshold.
- Zener: `D (IS=1e-12 N=1 RS=1 BV=1.0 IBV=1e-3)`. The anti-series pair
  conducts above `BV + Vf ≈ 1.55 V ≈ 1.5 units`.

## Verification (truth table, measured)

Carry current `I_carry` = (Ia + Ib) − Vsum/Rs (KCL, the excess over the
sense resistor), at 5 ns into each 10 ns detection window:

| case | Ia | Ib | Vsum | I_carry | verdict |
|---|---|---|---|---|---|
| +2 | +1 | +1 | +1.501 V | **+499 µA** | ✅ carry |
| +1 | +1 | 0  | +0.999 V | +0.65 µA | ✗ no carry |
| 0  | 0  | 0  | 0 V      | 0 | ✗ no carry |
| 0 (cancel) | +1 | −1 | 0 V | 0 | ✗ no carry |
| −1 | −1 | 0  | −1.000 V | −0.22 µA | ✗ no carry |
| −2 | −1 | −1 | −1.501 V | **−499 µA** | ✅ carry |

On/off discrimination is ~**770×** (499 µA vs ≤ 0.65 µA). The magnitude-2
case fires; ±1 and 0 do not. The `+1,−1` cancellation case confirms the sum
itself resolves sign *before* the threshold (it reads 0, free).

## Energy (measured, per 10 ns detection window)

| case | threshold (zener) | sense resistor (readout) |
|---|---|---|
| +2 (carry) | **7.36 pJ** | 22.3 pJ |
| +1 | 6.4 fJ (~0) | 9.85 pJ |
| 0  | 0 | 0 |
| 0 (cancel) | 0 | 0 |
| −1 | 2.2 fJ (~0) | 9.86 pJ |
| −2 (carry) | **7.36 pJ** | 22.3 pJ |

- **Threshold (zener) energy = ~7.4 pJ per carry event**, and ~0 (≤6 fJ) on
  every non-carry. Detecting a carry costs energy; *not* detecting one is
  free. Power during a carry ≈ 0.75 mW (1.5 V × 0.5 mA); energy is linear in
  the hold time.
- The **sense resistor** (`Rs`) is a separate, honest cost: ~9.9 pJ on *every*
  ±1 addition and ~22 pJ on ±2, carry or not. This is the I²R price of reading
  the magnitude at all, and it is *not* specific to the carry — it belongs to
  the sum readout, not to the threshold.

## Device count

| component | count | notes |
|---|---|---|
| zener diode (threshold) | **2** | back-to-back pair = signed ±carry (1 per polarity) |
| sense resistor Rs | 1 (passive) | magnitude readout, not counted as a device |
| keeper Rk | 1 (passive) | floats the carry node at 0, not counted |

**Device count: 2 diodes** for the signed ±carry. One zener per carry polarity.

## The honest statement

> The magnitude `(0, ±1, ±2)` is free — it is Kirchhoff's law, just wire.
> The **≥2 detection is not free**. It is a threshold, and a threshold is a
> real device: **2 zener diodes** (one per sign) and **~7.4 pJ per carry
> event**. The signed ±carry needs **two** of these, so the "2-threshold tax"
> is exactly that pair — this is where "free" ends, in device form.

Two further honest footnotes:

1. **The readout costs more than the threshold.** Turning the summed current
   into a voltage (the sense resistor) dissipates ~9.9 pJ on *every* ±1 add,
   more than the 7.4 pJ the zener spends only when a carry actually fires.
   In a real adder this load is the next stage's input, so it is already
   "inside" the sum gate — but it means the marginal *carry* hardware (2
   zeners) is small next to the *sum* hardware it piggybacks on.

2. **The sign is already free.** The direction of `S` is given by the existing
   passive diode-direction receiver (`diode_gates.cir`), so the zener pair only
   pays for *magnitude ≥ 2*, not for sign. The two zeners are the marginal
   cost of folding `±2 → ∓1` with a carry.
