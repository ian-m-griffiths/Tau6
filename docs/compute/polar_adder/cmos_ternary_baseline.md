# CMOS Digital Ternary Full Adder — the baseline the polar current-mode adder must beat

**2026-08-30 — re-stated baseline. No new netlist; every number is re-read from the
measured files `circuit/trelax.cir` + `circuit/trelax.log`, `rtl/word_fairfight.txt`,
`rtl/ternary_gates.v`, and `docs/compute/field_calculus/trelax_measured.md`.**

Calibration legend (repo standard): **DIRECT** = measured (`ngspice -b` / yosys) or counted
from a netlist; **DERIVED** = arithmetic on DIRECT numbers; **ANALOGY** = structural parallel;
**OURS** = design interpretation; **SPECULATION** = untested.

---

## 0. TL;DR

| quantity | value | calibration |
|---|---|---|
| balanced-ternary full adder `tadd1` | **192 transistors** | DIRECT — `circuit/trelax.cir` |
| `tadd1` energy / toggle (switching) | **0.355 fJ** | DIRECT — `trelax.log` `e1_pt = 3.547e-13` |
| `tadd1` area (yosys/sky130) | **25 cells / 146.39 µm²** | DIRECT — `gate_area.md` |
| ternary vs **binary** full adder | **1.92× energy, 3.31× transistors, 4.33× area** | DIRECT — `trelax_measured.md` §0 |
| word-level (6 trits vs 10 bits) | **969.68 µm² vs 258.998 µm² (3.74×)** | DIRECT — `rtl/word_fairfight.txt` |

**One-line verdict:** the CMOS digital ternary full adder is **192 T** (the naive boolean
2-wire one-hot encoding) and costs **0.355 fJ/toggle** of switching energy — **1.92× a binary
full adder's energy, 3.31× its transistors, 4.33× its area** — and *that* is the number the
polar current-mode adder is trying to undercut.

---

## 1. The cell: `tadd1` = 192 transistors

`tadd1` implements the balanced carry rule `a + b + cin = sum + 3·carry` (digit sum
`s ∈ {−3..+3}`): **carry +1 iff `s ≥ +2`; carry −1 iff `s ≤ −2`; sum = the residue mod 3.**
The trit encoding is **one-hot per direction, 2 wires per trit** (`rtl/ternary_gates.v`):

```
+1 = 2'b01 (push only)    0 = 2'b00 (null — nothing energized)    −1 = 2'b10 (pull only)
     2'b11 is never produced.
```

Because a trit is carried on *two* 0/1 V wires, every 3-state decision is built from ordinary
static-CMOS boolean gates — this 2-wire overhead is exactly the tax the polar approach hopes
to avoid (§4).

**Transistor breakdown** (functional grouping; each block maps to the named gates in
`trelax.cir`'s `.subckt tadd1`, which sums to 192 T):

| functional block | what it computes | gates (`trelax.cir`) | T |
|---|---|---|---|
| **signed carry** | the two signed majority votes | `p2 = maj3(ap,bp,cp)`, `n2 = maj3(an,bn,cn)` | **52** |
| **mod-3 sum** | exactly-one / exactly-two classification | `p2x`,`n2x` (inv+and2); `p1`,`n1` (or3+inv+and2) | **48** |
| **output rails** | the two sum rail drivers (+1 / −1) | `sp = (p1&nz)|(p2x&n1)|(pz&n2x)`; `sn = (n1&pz)|(n2x&p1)|(nz&p2x)` | **52** |
| **null & saturation + carry gate** | null detect, s=±3 saturation, carry output | `nz`,`pz` (nor3); `all3p`,`all3n` (and3); `cop`,`con` (and2) | **40** |
| **total** | | | **192** |

Raw per-gate count (verbatim from the `.subckt` header): `maj3 p2 26 + n2 26 + all3p 8 +
all3n 8 + nz 6 + pz 6 + p2x 8 + n2x 8 + p1 16 + n1 16 + cop 6 + con 6 + sp 26 + sn 26 = 192 T`.
The four-bucket grouping above is the same 192 T re-sliced by function.

Two honest caveats, carried from `trelax_measured.md`:

1. **192 T is the *naive* boolean cell.** yosys maps the same equations to **25 sky130
   cells / 146.39 µm²** (packed AOI cells) — the transistor count and the cell count agree
   within "simple gates vs packed cells." The literature's optimized current-mode ternary
   FA is ~118 T (CNTFET), which is the more demanding comparison for a *native* cell — but
   the CMOS digital baseline is 192 T. **[DIRECT for 192/25-cell; ANALOGY for 118 T.]**
2. **`tadd1` is verified correct** against an independent behavioral reference over 8 input
   triples (all diffs ≈ 7.6×10⁻¹⁰ V). **[DIRECT — `trelax.cir` §truth-table.]**

---

## 2. Measured energy — keep two numbers straight

There are **two distinct measured energies** in play, and conflating them is the single most
common error in this comparison.

### 2.1 The CMOS digital cell's energy: 0.355 fJ/toggle

`circuit/trelax.cir` measures `tadd1` (rich toggle: `a` 0→+1→0, `b=+1`, `cin=0` ⇒ sum
swings +1↔−1, carry 0↔+1) with isolated supply `V·I` integrated over one full cycle, halved:

```
e1_pt = 3.547e-13 J = 0.355 fJ / toggle        (tadd1, balanced ternary FA)
e4_pt = 1.845e-13 J = 0.185 fJ / toggle        (bin_fa, binary FA, same toggle shape)
ratio_ener = 1.923×
```

**[DIRECT — `circuit/trelax.log`.]** This is **LEVEL=1, switching-only, no leakage** — the
fair-fight convention (inputs from ideal sources, 10 fF next-gate load). `trelax_measured.md`
calls the LEVEL=1 "no leakage" omission explicitly (its §TODO #2). The 0.355 fJ is therefore
a *switching* floor; silicon adds leakage on top.

### 2.2 The polar current-mode gate's energy: 54.2 / 368.7 fJ

The numbers **54.2 fJ (null↔+1) and 368.7 fJ (+1↔−1)** are **not** the CMOS cell's energy —
they are the measured energy of the repo's **native polar diode-direction gate `dd_not`**
(the closest measured "polar" primitive, `2 D + 2 T = 4` devices, `circuit/diode_gates.cir`).
They are quoted here because they are the *current* polar primitive's cost — the number the
polar adder must *get below*, not the CMOS baseline it must beat:

```
dd_not  null↔+1  =  54.2 fJ   =   5.9 fJ intrinsic  +  48.2 fJ leakage
dd_not  +1↔−1    = 368.7 fJ   =  25.4 fJ intrinsic  + 343.3 fJ leakage
```

The `+1↔−1` decomposition (**25.4 fJ intrinsic + 343.3 fJ leakage**) is measured in
`break_before_make.md` §3 by removing the passive null-return termination (Rterm 100 kΩ +
receiver keepers ≈ 17 µA standing current): the 6.8× gap is **hold-time leakage**, not
shoot-through. **[DIRECT — `fair_binary.md` §4, `break_before_make.md` §3,
`junction_synthesis.md` §2.]** Against single-ended binary NOT (6.94 fJ) the polar gate is
**7.8× worse** at its cheapest toggle and **53× worse** at full swing (`fair_binary.md` §4).

**The asymmetry to hold onto:** the CMOS digital ternary FA costs **0.355 fJ/toggle** (a
full adder), while the polar current-mode primitive already costs **54–368 fJ/toggle** (a
*NOT gate* — a wire swap with zero logic). The polar adder's promise is that its
Kirchhoff-sum structure avoids the 192 T encoding *without* paying that 54–368 fJ — but as of
this baseline, no polar-adder netlist has been run, so that is unmeasured (see the sibling
`verdict.md` / `adversarial_verdict.md`).

---

## 3. Area — 4.33× binary (per adder), 3.74× at word level

- **Per adder (the headline).** `tadd1` = 146.39 µm² vs binary `badd1` = 33.78 µm² ⇒
  **4.33×**. **[DIRECT — `gate_area.md`, `trelax_measured.md` §3.]**
- **Word level (the honest word-width comparison).** 6 trits (729 states) vs 10 bits
  (1024 states) — equal state count — from `rtl/word_fairfight.txt`:

  ```
  wf_tadd6  (6-trit ripple, 6 × tadd1)  = 969.680 µm²   (167 cells)
  wf_badd10 (10-bit ripple, 10 × FA)    = 258.998 µm²   ( 48 cells)
  ratio ≈ 3.74×
  ```

  **[DIRECT — yosys 0.52, sky130_fd_sc_hd.]** The word ratio is *better* than the per-adder
  4.33× because 6 trits replace 10 bits (the radix economy partially pays back the per-cell
  tax), but it is still a ~3.7× area penalty.

The full baseline, in one table:

| quantity | value | source |
|---|---|---|
| transistors / adder | **192 T** | `trelax.cir` |
| energy / toggle (switching) | **0.355 fJ** (0.185 fJ binary) | `trelax.log` |
| area / adder | **146.39 µm²** (33.78 binary) = **4.33×** | `gate_area.md` |
| word area (6T vs 10b) | **969.68 vs 258.998 µm² = 3.74×** | `word_fairfight.txt` |
| vs binary, all-in | **1.92× energy, 3.31× T, 4.33× area** | `trelax_measured.md` |

---

## 4. The honest point — what the polar adder is trying to beat

**The 192 T is the price of the CMOS *digital encoding*, not of ternary arithmetic itself.**
A balanced trit needs three states, but CMOS is binary, so the trit is carried one-hot on
**two wires** (`push`/`pull`), and every 3-state decision (signed carry, mod-3 residue, null
detection) must be rebuilt from 0/1 gates — two majority gates, two output rails, a null
detector, a ±3 saturation detector, and two carry gates. That 2-wire + 2-threshold tax is
what piles up to 192 T and 4.33× area.

**The polar current-mode approach is precisely the attempt to *not* pay that encoding.** If a
trit is the *direction of a current* (push = +I, pull = −I, null = 0 A), then:

- the **sum** `σ = I_a + I_b + I_cin` is a free Kirchhoff junction (0 transistors), and
- the **null** is `0 A` — a native dead zone, not the 0-V saddle the 2-wire encoding forces.

So the polar adder's bet is: *replace 192 T of boolean 2-wire emulation with a current
junction plus a signed carry detector.* The number it must beat to be interesting is
**192 T / 0.355 fJ / 4.33× area** — and the honest state of play (sibling `verdict.md`,
`adversarial_verdict.md`) is that the free sum is real but the signed carry is still a
2-threshold measurement, so the polar cell lands near the `2·ln2/ln3 ≈ 1.26×` per-bit floor,
*a better ternary adder, not a binary-beating one*.

---

## 5. The baseline, stated for the record

> **192 T · 0.355 fJ/toggle · 4.33× binary area.** This is the CMOS digital ternary
> full-adder baseline the polar current-mode adder must beat to be interesting — and the
> current polar primitive (`dd_not`, 54.2–368.7 fJ) is still ~150–1000× *above* that 0.355 fJ
> switching floor, so the 192 T is the encoding to undercut, not the energy to match.

---

## Calibration ledger

| claim | calibration |
|---|---|
| `tadd1` = 192 T (naive boolean, 2-wire one-hot) | DIRECT — `circuit/trelax.cir` |
| `tadd1` = 0.355 fJ/toggle; `bin_fa` = 0.185 fJ; ratio 1.92× | DIRECT — `circuit/trelax.log` (`e1_pt`/`e4_pt`/`ratio_ener`) |
| `tadd1` 25 cells / 146.39 µm²; binary 2 / 33.78 ⇒ 4.33× | DIRECT — `gate_area.md`, `trelax_measured.md` |
| word-level 969.68 vs 258.998 µm² = 3.74× | DIRECT — `rtl/word_fairfight.txt` |
| `dd_not` 54.2 / 368.7 fJ (= 25.4 intrinsic + 343.3 leakage) | DIRECT — `fair_binary.md` §4, `break_before_make.md` §3 |
| polar gate vs binary NOT = 7.8× / 53× worse | DIRECT — `fair_binary.md` §4 |
| polar adder ≈ free KCL sum + 2-threshold carry, lands ≥ 1.26×/bit | OUR/SPECULATION — `analog_polar.md`, `verdict.md` (no polar-adder netlist run) |

## Sources

- `circuit/trelax.cir` + `circuit/trelax.log` — 192 T breakdown; `e1_pt = 3.547e-13`
  (0.355 fJ), `e4_pt = 1.845e-13` (0.185 fJ), `ratio_ener = 1.923`.
- `rtl/ternary_gates.v` — the trit encoding and the `tadd1` balanced-carry truth table.
- `rtl/word_fairfight.txt` — `wf_tadd6` 969.680 µm² vs `wf_badd10` 258.998 µm².
- `docs/compute/field_calculus/trelax_measured.md` — 1.92× energy, 3.31× T, 4.33× area;
  the LEVEL=1 no-leakage caveat.
- `docs/compute/gate_area.md` — `tadd1` 25 cells / 146.39 µm², `badd1` 2 / 33.78 µm².
- `docs/compute/ground_up/fair_binary.md` §4, `break_before_make.md` §3,
  `diode_gates.md` — the polar `dd_not` 54.2 / 368.7 fJ and the 25.4 + 343.3 fJ decomposition.

*No number in this file is invented: every DIRECT value is re-read from the cited
ngspice/yosys `.log`/`.txt` files, and the only unmeasured quantity (the polar adder's own
cell) is explicitly flagged OURS/SPECULATION.*
