# Ian's polar-ternary HALF-adder — transistor/diode-level schematic and exact device count

**2026-08-30 — the transistor/diode-level formalization of Ian's crossbar half-adder.**
Sibling to `polar_full_adder_design.md` (which builds the full adder from *this* half-adder,
counted in crossbar primitives: "9 junctions + 4 ORs"). This file expands those primitives
to **real devices** (transistors + diodes), using the house's *measured* polar primitives in
`circuit/diode_gates.cir` and `circuit/tsum_cell.cir`.

Calibration legend (repo standard): **DIRECT** = measured (`ngspice -b`) or counted from a
netlist; **DERIVED** = arithmetic/logical step on DIRECT numbers; **ANALOGY** = structural
parallel; **OURS** = design interpretation; **SPECULATION** = untested.

> **No new netlist was run for this file.** Every device count below is **DERIVED** by
> summing the **DIRECT** device counts of the primitives (counted from the existing netlists).
> The document is a design + count, not a measurement.

---

## 0. One-line answer

**Ian's half-adder, realized at transistor/diode level, needs ~110–135 devices — the honest
number for the corrected, composable half-adder is 122 devices = 4 diodes + 118 transistors —
and they go to three places: the 2-input "3-state sense" (2 × [2 diodes + 10 transistors] =
24 devices), the 9-intersection crossbar (9 × 6-transistor AND = 54 transistors, the single
biggest block), and the OR grouping + carry + output drivers (44 transistors). It is "dozens,"
not "a few" — roughly 6× a canonical 28-transistor binary full adder, and the crossbar is
only *not* free because each intersection is a real 2-input AND, not a 1-diode ROM cell.**

---

## 1. What Ian's graph literally says (transcribed faithfully, bugs flagged)

```
trit1[out] -> (zero[], one[source], two[source])          # a's 3 rows
trit2[out] -> (one_two[p], one_one[n], two_one[n], two_two[p],
               zero_one[n], zero_two[p], zero_zero[])     # b's 3 columns
one[out]  -> (one_one[in], one_two[in], one_zero[in])
two[out]  -> (two_two[source], two_one[source], two_zero[in])

carry_1 <- two_two
3 <- or(ONE_TWO, two_one, two_two)
2 <- or(one_one, two_zero, zero_two)
1 <- or(zero_one, one_zero)
0 <- and(zero_zero)
```

Reading it as a 3×3 crossbar (cell name `X_Y` = trit1 value X, trit2 value Y), Ian groups
the 9 cells into **five outputs**:

| output | Ian's expression | cells it lights | actual sum covered |
|---|---|---|---|
| `0` | `and(zero_zero)` | (0,0) | sum = 0 |
| `1` | `or(zero_one, one_zero)` | (0,1), (1,0) | sum = 1 |
| `2` | `or(one_one, two_zero, zero_two)` | (1,1), (2,0), (0,2) | sum = 2 |
| `3` | `or(ONE_TWO, two_one, two_two)` | (1,2), (2,1), **(2,2)** | sum = 3 **and 4** |
| `carry_1` | `two_two` | **(2,2)** only | sum = 4 only |

**Two honest observations about the graph as drawn (not the design I would ship):**

1. **`carry_1 <- two_two` is wrong for "carry when sum ≥ 3".** `a + b ≥ 3` happens on
   *(three)* cells — `(1,2)`, `(2,1)`, `(2,2)` — but Ian's carry only fires on `(2,2)`.
   `1+2 = 3` and `2+1 = 3` would light the "3" bucket *without* setting the carry. The
   correct carry is `or(one_two, two_one, two_two)`.
2. **The "3" bucket conflates sum 3 and sum 4.** It is `or(1,2),(2,1),(2,2)`, so the same
   cell `(2,2)` drives *both* the "3" bucket *and* the carry simultaneously. There is no
   distinct "sum = 4" signal and no mod-3 reduction — the graph emits a **raw sum in the
   range 0…4**, split as {0, 1, 2, "3-or-4", "4"}.

So Ian's literal graph is a **raw-sum decoder with a conflated top bucket and an under-wired
carry** — not yet a half-adder. I count it faithfully in §5, then give the corrected
half-adder (sum mod 3 + carry = `or(1,2),(2,1),(2,2)`) in §6, which is what
`polar_full_adder_design.md` consumes.

---

## 2. Encoding decisions (flagged choices, not defaults)

**The polar wire has exactly 3 states by current direction:** push (current *out*), pull
(current *in*), null (no current). Unbalanced ternary has 3 values `{0,1,2}`. They must be
mapped one-to-one onto `{push, null, pull}`. I choose the **order-preserving** mapping:

| trit value | polar state | receiver rail that fires |
|---|---|---|
| `2` | push | `rA` (0 → +Vrail) |
| `1` | **null** | *neither* (the expensive one) |
| `0` | pull | `rB` (0 → −Vrail) |

**Flags:**

- This is a **choice**: `0→pull, 1→null, 2→push` is order-preserving and matches "bigger trit
  = stronger/pushier". The alternative `0→null, 1→pull, 2→push` would move *which* value is
  the free-ish null, but the total cost is identical: **exactly one of the three values is
  the null, and that one line needs an explicit `NOT(push OR pull)` rail.** Three ordered
  states on one wire need two direction thresholds (the 2 diodes) *plus* the null rail —
  the "2-threshold tax" from `docs/compute/ground_up/diode_gates.md` §5, which is a device
  tax even when the *energy* tax is gone.
- **The null rail is the whole reason the crossbar is not "9 diodes".** In *balanced*
  ternary (`docs/compute/ground_up/tsum_cell.md`) the null is the *free* output state (sum=0
  = no current). In *unbalanced* ternary, `sum=0` is a **real value** (pull) and the null is
  the *middle* input value, so every one of the 9 cells — including the sum-0 cell — has to
  be materialized as an explicit AND. The unbalanced encoding buys "0 is a normal number" at
  the cost of "0 is no longer free."

---

## 3. The building blocks (DIRECT counts from the existing netlists)

Every count below is taken verbatim from `circuit/tsum_cell.cir` / `circuit/diode_gates.cir`
(the house's measured diode-direction polar gates). "Diode" = rectifier diode (D);
"transistor" = MOSFET (T). Keepers (R, C) are passive and not counted.

| primitive | devices | source |
|---|---:|---|
| `dd_recv` — 2 opposite diodes, push rail `rA` + pull rail `rB`, null = neither | **2 D** | `diode_gates.cir` L116 |
| `t_recv` — full 3-state sense: `dd_recv` + push/pull restore + null rail | **2 D + 10 T** | `tsum_cell.cir` L149 |
| `and2` — static CMOS AND = `nand2` (4 T) + `inv` (2 T) | **6 T** | `tsum_cell.cir` L111 |
| `or2` — static CMOS OR = `nor2` (4 T) + `inv` (2 T) | **6 T** | `tsum_cell.cir` L116 |
| `or3` — `or2` + `or2` | **12 T** | `tsum_cell.cir` L121 |
| `driver` — dead-zone push-pull output (PMOS + NMOS) | **2 T** | `tsum_cell.cir` L130 |
| `inv` | **2 T** | `tsum_cell.cir` L90 |

The multi-Vt fabrication ask is inherited, not extra devices: the restore stages use the
elevated-|Vt| dead-zone devices (`N_HI`/`P_HI`, |Vt| = 1.4 V) — they are ordinary MOSFETs in
the count, but they are a *process* ask (`diode_gates.md` §6).

---

## 4. The schematic, stage by stage

### 4.1 Input sense — how each trit's 3 states activate its row/column

Per input wire `w`, the house `t_recv` (2 D + 10 T) turns the polar wire into three
**full-swing, one-hot** logic lines `{p, n, z}`:

```
                 dd_recv (2 D)        push restore            pull restore         null rail
  w (polar) ──► D1 w→rA (push)   Mpu midp rA vdd (PMOS1)   Mnu n rB vdd (P_HI)    z = NOR(p,n)
               D2 rB→w (pull)    Mpd midp rA vss (N_HI )   Mnd n rB vss (NMOS1)        [4 T]
                                        │  inv: p=NOT(midp)
                                        └──────────────────────► p = +VDD iff push
        rA = push rail, rB = pull rail                        ► n = +VDD iff pull
                                                              ► z = +VDD iff null
```

Then the row/column lines for an input are just a relabeling:

```
    trit value 2  →  row_2 / col_2  =  p   (push rail, restored)
    trit value 1  →  row_1 / col_1  =  z   (null rail = NOR(p,n))   ← the new piece
    trit value 0  →  row_0 / col_0  =  n   (pull rail, restored)
```

For the two operands `a`, `b`:

```
    a: row_0 = n_a,  row_1 = z_a,  row_2 = p_a
    b: col_0 = n_b,  col_1 = z_b,  col_2 = p_b
```

**Device cost per input = 2 D + 10 T. Two inputs = 4 D + 20 T = 24 devices.** This is the
"2-threshold sense" of the task: the 2 diodes are the two direction thresholds, and the null
rail is the third, explicit decision (`NOT(push OR pull)`) they cannot produce directly.

### 4.2 The 9 crossbar intersections — one full AND per cell, NOT a diode

Each cell `(i,j)` lights iff `row_i AND col_j`. **Both operands are active logic signals**,
so the cell is a genuine 2-input AND (`and2` = `nand2` + `inv` = 6 T):

```
        n_b (col_0)      z_b (col_1)      p_b (col_2)
  n_a  ─── . ─────────── . ─────────────── . ────   row_0   (0,0) (0,1) (0,2)
  z_a  ─── . ─────────── . ─────────────── . ────   row_1   (1,0) (1,1) (1,2)
  p_a  ─── . ─────────── . ─────────────── . ────   row_2   (2,0) (2,1) (2,2)

  each "." = and2(row, col) = nand2(4 T) + inv(2 T) = 6 T
```

One cell `(2,2)` expanded to transistors (this is the pattern repeated 9×):

```
  and2(p_a, p_b) → t22
     nand2:  Mp1 t22 p_a vdd        inv:   Mp  t22_mid → t22  vdd
             Mp2 t22 p_b vdd               Mn  t22_mid → t22  vss
             Mn1 t22 p_a mid
             Mn2 mid p_b vss
```

**Device cost for the crossbar = 9 × 6 T = 54 T.** The name "crossbar" invites the ROM
reading ("one diode per intersection"), but a ROM cell has one *active* input (the word line)
driving one *passive* output (the bit line); here **both row and column are inputs**, so a
single diode/pass device cannot compute the AND. This is the crux — see the ledger in §7.

### 4.3 OR/AND grouping — Ian's literal buckets

```
  sum_0   = (0,0)                                  → wire (degenerate "and")        0 T
  sum_1   = (0,1) OR (1,0)                         → or2                           6 T
  sum_2   = (1,1) OR (2,0) OR (0,2)                → or3                          12 T
  sum_3   = (1,2) OR (2,1) OR (2,2)                → or3                          12 T   ← contains sum 4
  carry_1 = (2,2)                                  → wire (tap of cell (2,2))      0 T   ← UNDER-WIRED
```

**Device cost for grouping = 0 + 6 + 12 + 12 + 0 = 30 T.**

### 4.4 Carry

- **Ian's literal:** `carry_1 = (2,2)` is a bare tap off the cell-`(2,2)` AND output — **0
  extra devices**, but it fires only on `2+2`, so it misses `1+2` and `2+1` (§1).
- **Corrected:** `carry = or((1,2),(2,1),(2,2))` = one `or3` = **12 T** (§6).

### 4.5 Output drivers

The internal bucket/carry wires are already full-swing static-CMOS nodes, so at the house's
fan-out-of-1 convention they need **no** extra driver if consumed by the next CMOS stage.
But a *polar* output (to compose into a ripple, as `polar_full_adder_design.md` needs) must
be re-encoded onto a push/pull/null wire, at **4 T each** (`inv` to make the active-low push
enable + 2-T `driver`). I separate "logic" from "driver" in the counts below because it is a
real design fork:

- **one-hot bucket output** (Ian's literal style): each of the 5 wires needs only a 2-T
  buffer to isolate load → +10 T if buffered, or +0 T at fan-out 1.
- **polar trit output** (true polar half-adder): sum and carry ride 2 polar wires → 2 × 4 T.

---

## 5. Exact device count — Ian's literal design (faithful, buggy)

| stage | sub-part | devices |
|---|---:|---:|
| input sense | 2 × `t_recv` (2 D + 10 T each) | 4 D + 20 T |
| crossbar | 9 × `and2` (6 T each) | 54 T |
| grouping | `sum_0` wire | 0 |
| | `sum_1` `or2` | 6 T |
| | `sum_2` `or3` | 12 T |
| | `sum_3` `or3` | 12 T |
| | `carry_1` wire (tap of `(2,2)`) | 0 |
| **subtotal (logic)** | | **4 D + 104 T = 108** |
| output | 5 one-hot bucket wires, buffered (2 T each) | +10 T |
| **Ian's literal total** | | **4 D + 114 T = 118** |

**This is what Ian drew, and it is not a half-adder:** 108 devices of logic emit a 5-wire
raw-sum signal (0, 1, 2, "3-or-4", "4") whose carry is under-wired. The count is honest to
the graph; the *function* is not (§1).

---

## 6. Exact device count — the corrected half-adder (sum mod 3 + carry)

This is the design `polar_full_adder_design.md` assumes: `sum = (a+b) mod 3` on one polar
wire, `carry = 1 iff a+b ≥ 3` on one polar wire.

```
  sum mod 3 (polar, 0=pull, 1=null, 2=push):
      push_en (sum=2) = (0,2) OR (1,1) OR (2,0)      → or3   12 T
      pull_en (sum=0) = (0,0) OR (1,2) OR (2,1)      → or3   12 T
      null   (sum=1) = implicit (neither)            → free
  carry = 1 iff (a+b)≥3:
      carry_en       = (1,2) OR (2,1) OR (2,2)       → or3   12 T
```

| stage | sub-part | devices |
|---|---:|---:|
| input sense | 2 × `t_recv` | 4 D + 20 T |
| crossbar | 9 × `and2` | 54 T |
| sum mod 3 | `push_en` `or3` | 12 T |
| | `pull_en` `or3` | 12 T |
| carry | `carry_en` `or3` | 12 T |
| output drivers | sum: `inv` + `driver` | 4 T |
| | carry: `inv` + `driver` | 4 T |
| **corrected half-adder total** | | **4 D + 118 T = 122** |

**Optimization note (honest, not counted in the headline):** the null residue `sum=1` pairs
`(0,1)` and `(1,0)` never need materializing (null is free), and `carry` reuses `(1,2)`,
`(2,1)` which are already in `pull_en`. A residue-aware version drops those 2 ANDs:

```
  7 × and2 = 42 T  (not 54 T)   →   corrected-optimized = 4 D + 106 T = 110 devices
```

The crossbar approach (materialize all 9) is what Ian specified and what the full-adder doc
counts; the 7-AND version is the honest "you don't have to pay for the two null-residue
cells" saving.

---

## 7. The honest design-decision ledger (the crux)

| decision | choice | cost | why |
|---|---|---|---|
| crossbar cell = 2-input AND | **6 T** (`and2`) | 54 T | both row AND column are *active* inputs; a 1-diode ROM cell needs one side passive. |
| … vs "ROM diode" | rejected | — | a diode has one active control; it cannot AND two active logic signals. |
| … vs pass-transistor cell | flagged, not counted | 3–4 T/cell | 1 NMOS (gate=row, src=col) *does* AND, but the high level degrades to `VDD−Vt`, the off-state floats, and it needs a keeper + restore buffer before it can drive the ORs — unmeasured. |
| input 3-state sense | **2 D + 10 T** per input | 24 devices | 2 diodes give the 2 direction thresholds; the null rail `NOR(p,n)` + restore is the explicit third decision. |
| unbalanced `0→pull, 1→null, 2→push` | chosen | — | order-preserving; any mapping still pays one null rail. |
| OR grouping | **6 T / 12 T** (`or2`/`or3`) | 30–36 T | static CMOS, house-standard. |
| degenerate `and(zero_zero)` | wire | 0 T | a 1-input AND is the identity. |
| Ian's `carry = (2,2)` | **0 T** | — | a bare tap, but functionally wrong (misses `1+2`, `2+1`). |
| corrected `carry = or((1,2),(2,1),(2,2))` | **12 T** | 12 T | one `or3`. |
| sum-3 conflates 3+4 | flagged | — | `(2,2)` drives both `sum_3` and `carry`; not a bug in *count*, a bug in *encoding*. |
| polar output driver | **4 T** per wire | 8 T | `inv` + dead-zone push-pull; free only at fan-out-1 internal CMOS. |

**The single most important line:** the crossbar is 54 transistors because **each of the 9
intersections is a real 6-transistor AND**. There is no "9-diode crossbar" version — the
diode-crossbar mental model is a ROM (one active word line, one passive bit line), and Ian's
design has *two* active operands, so the per-cell "row AND column" test is a 2-input gate,
which in the house's static-CMOS accounting is `nand2 + inv` = 6 T.

---

## 8. "A few devices or dozens?" — the honest answer

| object | devices |
|---|---:|
| **Ian's literal graph** (raw-sum, buggy carry) | 4 D + 104 T = **108** (logic) / **118** (buffered) |
| **Corrected half-adder** (sum mod 3 + carry, polar out) | 4 D + 118 T = **122** |
| **Corrected, 7-AND optimized** | 4 D + 106 T = **110** |
| binary **half-adder** (XOR 14 T + AND 6 T, harness) | **20 T** |
| binary **full adder** (canonical static CMOS) | **28 T** (`binary_baseline.md`) |

**It is dozens, not a few — and the crossbar is the biggest single block, not the input
sense.** The input sense (24 devices) is the *hidden* tax (it is what forces the crossbar to
6 T/cell instead of 1 diode/cell), but the crossbar itself (54 T) is the largest line item,
~2.25× the sense. Against binary, Ian's half-adder is ~5–6× a binary full adder's 28 T for a
*half* the job; the unbalanced encoding is the reason — `0` is an active signal (pull), not
a free null, so all 9 cells must be materialized and the null is paid for *in the middle* of
each input.

---

## 9. Calibration ledger

| claim | calibration |
|---|---|
| `t_recv` = 2 D + 10 T; `and2` = 6 T; `or2` = 6 T; `or3` = 12 T; `driver` = 2 T | **DIRECT** — counted from `circuit/tsum_cell.cir` |
| `dd_recv` = 2 D | **DIRECT** — `circuit/diode_gates.cir` L116 |
| half-adder totals 108/118/122/110 | **DERIVED** — sums of the DIRECT primitive counts; no netlist run |
| crossbar cell is a 6-T AND, not a diode | **OURS** — both inputs active; `tsum_cell.cir` uses the same `and2` |
| null rail is the explicit third decision (2-threshold + null) | **OURS/ANALOGY** — `diode_gates.md` §5, `tsum_cell.md` §1 |
| pass-transistor cell = 3–4 T | **SPECULATION** — level degradation/keeper unmeasured |
| Ian's `carry=(2,2)` misses `1+2`,`2+1` | **DIRECT** — reading of the graph |
| unbalanced `sum=0` = active signal, not free null | **OURS** — consequence of the 0→pull mapping |
| multi-Vt (elevated-|Vt|) is a fabrication ask, not extra devices | **OURS/ANALOGY** — `diode_gates.md` §6 |

---

## Sources

- `circuit/diode_gates.cir` — the measured diode-direction receiver + lattice gates.
- `circuit/tsum_cell.cir` — the measured `t_recv` (2 D + 10 T), `and2`, `or2`, `or3`, `driver`.
- `docs/compute/ground_up/diode_gates.md` — the 2-threshold tax, multi-Vt ask.
- `docs/compute/ground_up/tsum_cell.md` — why the null rail is the gap for field ops.
- `docs/compute/polar_adder/polar_full_adder_design.md` — consumes this half-adder (9 junctions + 4 ORs).
- `docs/compute/polar_adder/binary_baseline.md` — the 28-T binary full-adder yardstick.

*Nothing is invented: the primitive device counts are read from the existing netlists, and the
half-adder totals are arithmetic on those counts.*
