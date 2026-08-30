# Bipolar Transistor Basics (Electronics Tutorials — unattributed)

## 1. Node inventory

| id | type | name | one-line | location |
|----|------|------|----------|----------|
| n1 | DEVICE | BJT (Bipolar Junction Transistor) | Three-layer, two-junction, three-terminal *current-controlled* device | L6–7, 34–40 |
| n2 | DEVICE | NPN | Negative–Positive–Negative structure; **sources** current | L29–31, 217–218 |
| n3 | DEVICE | PNP | Positive–Negative–Positive structure; **sinks** current | L29–31, 378–383 |
| n4 | CLAIM | Two-state toggle | Transistor switches between **insulator or conductor** (two states) | L10–12 |
| n5 | DEFINITION | Three operating regions | Active / Saturation / Cut-off | L13–20 |
| n6 | CLAIM | Active region | Amplifier; Ic = β·Ib (linear, continuous) | L16 |
| n7 | CLAIM | Saturation region | Fully-ON switch; Ic = I(saturation) | L18 |
| n8 | CLAIM | Cut-off region | Fully-OFF switch; Ic = 0 | L20 |
| n9 | MEASUREMENT | β (beta / hfe) | DC current gain Ic/Ib, typically 20–200 | L114, 122, 238 |
| n10 | MEASUREMENT | α (alpha) | Ic/Ie, always < 1 (0.950–0.999) | L115–116, 243–246 |
| n11 | METHOD | Common-Base (CB) | Voltage gain, no current gain (attenuates) | L61, 67–88 |
| n12 | METHOD | Common-Emitter (CE) | Both current and voltage gain, inverting, most common | L62, 96–103 |
| n13 | METHOD | Common-Collector (CC) | Current gain, no voltage gain (emitter follower) | L65, 142–147 |
| n14 | DEVICE | Complementary / matched pair | Matched NPN+PNP for Class B / H-bridge | L423–429 |
| n15 | DEVICE | Darlington transistor | Two BJTs cascaded; β = β1·β2 | L546–557 |
| n16 | DEVICE | FET | Voltage-controlled **unipolar** device | L600–606 |
| n17 | DEVICE | JFET | Junction-gate FET | L629–651 |
| n18 | DEVICE | MOSFET | Insulated-gate FET (IGFET) | L703–716 |
| n19 | DEVICE | Enhancement-mode MOSFET | Normally **OFF** ("normally open" switch) | L744–754 |
| n20 | DEVICE | Depletion-mode MOSFET | Normally **ON** ("normally closed" switch) | L728–734 |
| n21 | RESULT | MOSFET switching table | Vgs = +ve / 0 / −ve mapped onto ON/OFF | L781–785 |
| n22 | CLAIM | Leakage & offsets | Real OFF has leakage current and Vce(sat) | L504–506 |
| n23 | CLAIM | NPN-sources / PNP-sinks | Polarity fixes the *direction* of current flow | L381–383 |
| n24 | CLAIM | Bipolar vs unipolar carriers | Holes+electrons (BJT) vs one carrier (FET) | L394–396, 619–621 |
| n25 | METHOD | Flywheel diode | Protects inductive load when switch turns OFF | L489–491 |

## 2. Edge inventory

| src→tgt | type | calibration | evidence |
|---------|------|-------------|----------|
| n1 → n2 | has-type (NPN) | DIRECT | L29–31 |
| n1 → n3 | has-type (PNP) | DIRECT | L29–31 |
| n2 ↔ n3 | complements (polarity) | DIRECT | L369–371, 391–393 |
| n4 → n5 | defines-as | ANALOGY | L10–20 (paper names "two states", then lists "three regions") |
| n5 → n6 | contains | DIRECT | L13–20 |
| n5 → n7 | contains | DIRECT | L13–20 |
| n5 → n8 | contains | DIRECT | L13–20 |
| n6 → n9 | transconductance (Ic = β·Ib) | DIRECT | L16 |
| n7 + n8 → switch | ON/OFF logic states | DIRECT | L18–20, 462–479 |
| n6 → {push/pull/null} | counter-to (active region ≠ trit) | OURS | L16 |
| n23 → polarity-encodes-direction | maps-to | ANALOGY | L381–383 |
| n2 + n3 → n14 | H-bridge push/pull assembly | ANALOGY | L423–429 |
| n18 → n21 | ternary-input → binary-output | ANALOGY | L781–785 |
| n18 → null (gate draws 0 current) | free-null-at-input | ANALOGY | L713–716 |
| n19 → null-default | normally-OFF ≈ null | ANALOGY | L744–754 |
| n22 → non-ideal-null | leakage costs the null | DIRECT | L504–506 |
| n16 → current-vs-voltage control | controls | DIRECT | L600–606, 946–958 |
| n15 → β-product | gain cascade | DIRECT | L551–557 |
| n24 → binary-fundamental | carrier duality | OURS | L619–621 |

## 3. Counter-to / reversal edges

- **VERDICT: the BJT is a 2-state transconductance device, not a native 3-state transistor.** Its three *named* operating regions are **2 digital states + 1 continuous linear region**, not a ternary alphabet: Cut-off = OFF (Ic=0), Saturation = ON (Ic=I(sat)), and Active is a *continuum* (Ic = β·Ib) — an analog amplification range, not a discrete third trit. Mapping cutoff/active/saturation → null/push/pull **fails**: the "active region" is neither a sign nor a free null; it is the linear transconductance zone.
- **Counter-to the paper's own "three regions"**: the text itself states the transistor "changes between these *two* states" (insulator/conductor, L10–12) before listing three regions. Two of the three are the ON/OFF pair; the third is linear. This is exactly the "native 3-state device ≈ 0.63× native floor" flattery the lens warns about — three labels, two logic states.
- **Counter-to "NPN/PNP = trit polarity"**: NPN vs PNP is the *binary* complement (source vs sink), structurally identical to NMOS/PMOS in CMOS. It encodes **one bit of direction**, not a trit sign; it gives 2 polarities, not 3.
- **The nearest push/pull is an assembly, not device physics**: bidirectional drive exists only as the complementary pair / H-bridge (L423–429) — a circuit topology. Its "null" is a bolt-on (both switches OFF + flywheel diode L489–491), not an intrinsic third state.
- **Counter-to "free null"**: the BJT's OFF is not free — leakage currents and saturation voltage (L504–506) make the null cost power and non-ideal. Only the MOSFET's *insulated gate* gives a ~free input null (zero gate current, L713–716), and only at the input; the channel still leaks. The null is free at the *control terminal*, never at the *output*.
- **Reversal (inverted ternary)**: the MOSFET switching table (L781–785) is a genuine *ternary input* (Vgs = +ve / 0 / −ve) collapsed to a *binary output* (ON/OFF). Tau wants 3 output states from one device; this delivers 2 output states from 3 input levels — the 2-threshold tax running in reverse.

## 4. Map-to-current-system (lens)

| paper concept | our system | calibration | evidence |
|---------------|------------|-------------|----------|
| Three operating regions (cutoff/active/saturation) | trit {−1, 0, +1} = push/pull/null | SPECULATION (rejected) | L13–20 — active region is linear/continuous, not a trit |
| NPN/PNP polarity | 2-bit one-hot direction (01=push, 10=pull) | ANALOGY | L381–383 — source vs sink is direction, but only 1 bit |
| Complementary pair / H-bridge | push/pull bidirectional drive | ANALOGY | L423–429 |
| Enhancement-mode MOSFET "normally OFF" | null default (00=null) | ANALOGY | L744–754 |
| MOSFET insulated gate (no gate current) | null trit ~0 transport cost | ANALOGY | L713–716 |
| MOSFET switching table (Vgs +/0/−) | ternary drive voltage | ANALOGY (inverted) | L781–785 — ternary in, binary out |
| BJT "current controlled" (β transconductance) | 2-threshold compute tax | ANALOGY | L234–240, 600–606 — analog gain, no threshold logic |
| Leakage currents / Vce(sat) | non-ideal null (null not free) | DIRECT | L504–506 |
| Bipolar (holes+electrons) vs unipolar | (no trit analog — device is binary) | OURS | L619–621 |
| Darlington (β = β1·β2) | gain cascade | OURS | L551–557 — irrelevant to ternary |

## 5. One-liner

The BJT is a two-state current-controlled transconductance device whose three named regions collapse to ON/OFF plus a linear analog continuum and whose NPN/PNP "polarity" is just the binary source/sink complement — so it offers Tau no native push/pull/null trit, only a circuit-level (H-bridge) analogy to bidirectional drive.
