# Binary Full-Adder Baseline — the yardstick the polar ternary adder must beat

**2026-08-30 — re-stated baseline. No new design, no new netlist; every number is
re-read from the existing measurements in `circuit/`.**

Calibration legend (repo standard): **DIRECT** = measured (`ngspice -b`) or counted
from a netlist; **DERIVED** = arithmetic/logical step on DIRECT numbers; **ANALOGY** =
structural parallel; **OURS** = design interpretation; **SPECULATION** = untested.

---

## 0. One-line answer

The binary CMOS full adder is the **canonical 28-transistor cell** — **16T sum
(2 × XOR) + 12T carry (3 × NAND majority)** — and it costs **~6–12 fJ per add**
(gate/compute energy, the same band as the measured single-ended binary gates:
NOT 6.94 / NAND 11.36 / NOR 8.65 fJ per toggle) and **0.512 pJ/bit** to move the
result on the wire (`fair_binary.cir` BT1). Its carry is a **single, unsigned,
single-threshold majority** — and *that* is the exact thing the polar ternary
adder's **signed, two-threshold carry** is compared against.

---

## 1. The cell: 28T = 16T sum + 12T carry

Standard static-CMOS full adder (the count every ternary-vs-binary paper quotes):

```
    Sum   S  = A ⊕ B ⊕ Cin
    Carry C  = A·B + Cin·(A ⊕ B)  =  majority(A, B, Cin)
```

| block | gates | transistors | produces |
|---|---|---:|---|
| XOR #1 | 1 × 2-input XOR (8T) | **8** | `X = A ⊕ B` |
| XOR #2 | 1 × 2-input XOR (8T) | **8** | `S = X ⊕ Cin` |
| carry | 3 × 2-input NAND (4T each) | **12** | `C = ¬( ¬(A·B) · ¬(Cin·X) )` |
| **total** | | **28** | `{C, S}` |

**[DIRECT — the conventional static-CMOS full adder.]** Two facts pin the count:

1. **The sum path is 16T** because a 3-input XOR is two 2-input XORs (8T each, in the
   standard transmission-gate form: 2 inverters + 2 transmission gates). **[DIRECT]**
2. **The carry path is 12T** because the carry *reuses* the intermediate `X = A ⊕ B`
   already produced on the sum path: `C = NAND(NAND(A,B), NAND(Cin,X))`. That reuse is
   what keeps the cell at 28T instead of ~34T. The three NANDs are De Morgan's identity
   for `AB + Cin·X` — i.e. **majority-of-3** ("is the majority of {A, B, Cin} a 1?").
   **[DIRECT]**

(The netlist `circuit/trelax.cir` also carries a *hand-built* `bin_fa` at 58T — a
deliberately generous-to-binary harness — measured at 0.185 fJ/toggle under a different
load; see §4. The canonical number for a fair comparison is **28T**, not 58T.)

---

## 2. The key point for the comparison: ONE threshold vs TWO

This is the sentence the whole comparison reduces to:

> **Binary's carry is one threshold, single-direction; the polar ternary carry is two
> thresholds, signed — and that second threshold is the entire cost being compared.**

- **Binary carry (one threshold, single-direction).** The carry is **unsigned**:
  `cout ∈ {0, 1}`. One wire, one `majority(A,B,Cin)` decision, one state boundary
  (is ≥2 of the 3 bits a 1?). There is no direction to distinguish — a carry is always
  "add 1 to the next column", never "borrow". One decision, one threshold. **[DIRECT]**

- **Ternary carry (two thresholds, signed).** The balanced carry is **signed**:
  `cout ∈ {+1, 0, −1}`. The cell must decide *both* "is the digit sum `s ≥ +2`" (carry
  **+1**) *and* "is `s ≤ −2`" (carry **−1**) — two separate majority gates, two state
  boundaries, two thresholds — plus the null bookkeeping between them. In `tadd1` that
  duplication alone is one extra `maj3` (26T), pushing the carry block to **92T = 48%
  of the cell**. **[DIRECT — counted in `circuit/trelax.cir`, `docs/compute/circuit_diagrams/full_adder_comparison.md` §2.1/§4(c).]**

The binary baseline is the *minimum* carry: **one** unsigned majority. The polar adder
must justify why paying for the **second** threshold (the signed ±carry) buys back more
than it costs. That is the yardstick, and it is already the known failure mode:
`polar_gates.md` measures the native single-wire polar gates at **8–23× the binary gate
energy per toggle**, and the full-swing signed toggle (`fair_binary.md` §4) at ~24–33×
per bit — precisely because a 3-level wire + signed carry forces the 2-threshold demux
that binary never pays. **[DIRECT — `circuit/polar_gates.cir`, `circuit/fair_binary.cir` §3.]**

---

## 3. The honest baseline (the numbers)

| quantity | value | source / calibration |
|---|---:|---|
| full adder, transistors | **28T** (16T sum + 12T carry) | DIRECT — conventional static CMOS |
| NOT toggle (single-ended 0→1 V) | **6.94 fJ** | DIRECT — `circuit/fair_binary.cir` §2, `fair_binary.log` |
| NAND toggle (single-ended 0→1 V) | **11.36 fJ** | DIRECT — same |
| NOR toggle (single-ended 0→1 V) | **8.65 fJ** | DIRECT — same |
| **energy per add** | **~6–12 fJ** | DERIVED — see below |
| **energy per bit (transport)** | **0.512 pJ/bit** | DIRECT — `fair_binary.cir` §1 (BT1), `fair_binary.log` |
| matched low-swing ref (0.65 V) | 0.216 pJ/bit | DIRECT — same (BT2) |

**Energy per add, stated honestly.** There is no dedicated 28T-adder energy netlist in
`circuit/`; the per-add figure is **DERIVED** from the measured gate primitives the
adder is built from. A full add evaluates `{sum, carry}` by toggling a handful of
internal nets through the two XORs and three NANDs above — each net is one 10 fF
next-gate input, each toggle is a `½CV²`-class event — so one add sits in the **same
band as one-to-two measured single-ended binary gate toggles**: **~6–12 fJ** (bounded
below by NOT 6.94 fJ, above by ~one NAND 11.36 fJ). This is the honest compute number
to hold the polar adder against; it is *not* a precision claim, it is an order-of-band
clamp. **[DERIVED — from the DIRECT gate energies above.]**

**Two distinct numbers, two distinct axes — do not conflate them:**

- **~6–12 fJ per add** is the **gate/compute** cost (what the transistors spend to
  evaluate the logic).
- **0.512 pJ/bit** is the **wire/transport** cost (what it takes to move one bit across
  the line at natural single-ended 0→1 V, `fair_binary.cir` BT1: 1.0232 pJ full cycle ÷ 2).

The polar adder must beat *both* on its own terms: its per-add gate energy against
~6–12 fJ, and its per-trit (÷1.585 bits) transport energy against 0.512 pJ/bit. The
transport number is the one that already looks soft for ternary — the measured polar
gates lose there too, not win (`polar_gates.md`, `fair_binary.md`). **[DIRECT — cited.]**

---

## 4. Calibration ledger

| claim | calibration |
|---|---|
| full adder = 28T (2× XOR-8T + 3× NAND-4T) | **DIRECT** — conventional static CMOS; `binary_baseline_diagram.md` §3 |
| sum (XOR) = 16T, carry (majority) = 12T | **DIRECT** — same |
| carry reuses `X = A⊕B` (keeps cell at 28T) | **DIRECT** — standard textbook form |
| NOT/NAND/NOR toggle = 6.94 / 11.36 / 8.65 fJ | **DIRECT** — `circuit/fair_binary.cir` §2, `fair_binary.log` (ept_1/ept_2/ept_3) |
| transport per bit = 0.512 pJ/bit (0.216 at 0.65 V) | **DIRECT** — `circuit/fair_binary.cir` §1, `fair_binary.log` (ebit_bt1/ebit_bt2) |
| energy per add ≈ 6–12 fJ | **DERIVED** — band of the measured single-ended gate toggles; no dedicated 28T-adder netlist run |
| binary carry = 1 threshold, unsigned, single-direction | **DIRECT** — one `majority(A,B,Cin)` |
| ternary/polar carry = 2 thresholds, signed ± | **DIRECT** — `tadd1` in `trelax.cir` (two `maj3`: `p2`/`n2`), `full_adder_comparison.md` §4(c) |
| polar gates lose on energy (8–23×/toggle, ~24–33×/bit at full swing) | **DIRECT** — `circuit/polar_gates.cir`, `circuit/fair_binary.cir` §3 |

---

## Sources

- `circuit/fair_binary.cir` + `circuit/fair_binary.log` — single-ended 0→1 V binary
  gates (NOT/NAND/NOR) and transport (BT1 0.512 pJ/bit, BT2 0.216 pJ/bit).
- `circuit/binary_baseline.cir` — the original CMOS inverter baseline.
- `docs/compute/ground_up/fair_binary.md` — the corrected "N× vs binary" re-baseline.
- `docs/compute/circuit_diagrams/binary_baseline_diagram.md` — the 28T schematic + counts.
- `docs/compute/circuit_diagrams/full_adder_comparison.md` — the 28T-vs-192T side-by-side
  and the "signed carry = second majority threshold" mechanism.
- `docs/compute/polar_gates.md` + `circuit/polar_gates.cir` — the native single-wire
  polar ternary gates the adder is being compared against.
- `docs/compute/field_calculus/trelax_measured.md` + `circuit/trelax.cir` — the `tadd1`
  (192T) vs `bin_fa` (58T harness) measured pair, for cross-reference only.

*No number in this file is invented: the transistor count is the standard CMOS figure,
the gate and transport energies are re-read from `circuit/fair_binary.log`, and the only
derived figure (the ~6–12 fJ per-add band) is flagged as such.*
