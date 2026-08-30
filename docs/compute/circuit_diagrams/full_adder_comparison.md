# Full-Adder Comparison — the ternary balanced `tadd1` vs the binary full adder

**Why this file exists.** The repo's per-gate and word-level benchmarks
(`gate_area.md`, `word_fairfight.md`) both land on a "~4×" area penalty for the
balanced-ternary full adder. This file draws the two cells side by side so the
~4× is *visible in the schematic* — not just quoted — and pins down the one
physical mechanism behind it.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured (yosys/ngspice runs cited below) or counted from a netlist.
- **DERIVED** — arithmetic on DIRECT numbers (a ratio, a ×N product).
- **ANALOGY** — structural parallel, not identity (e.g. a literature transistor
  count ported to our flow).
- **OURS** — design interpretation supported by DIRECT but not itself measured.
- **SPECULATION** — untested hypothesis.

---

## 0. One-line answer

**A balanced ternary full adder is 3.31× the transistors (192 T vs 58 T, or ~6.9×
against a canonical 28-T binary FA), 4.33× the area, and 1.92× the toggle energy of
a binary full adder — and the ~4× is the *cost of a signed, 3-valued digit carried on
2 wires*.** The schematic shows the same thing the numbers say: the ternary cell must
run **two** majority thresholds (one per carry sign), emit **two** signed output rails
for the sum and **two** for the carry, and resolve **27** input triples instead of
**8**. The 2-wire/trit encoding + the 2-threshold sensing it forces is the root; the
balanced ±carry and the 27-vs-8 combos are its downstream consequences.

---

## 1. The two cells, side by side (ASCII)

Trit encoding (from `rtl/trit_functions.vh`, Lean-proved in `TernaryCell.lean`):
one trit = **2 wires**, one-hot-per-direction — `2'b01 = +1` (push), `2'b00 = 0`
(null, neither), `2'b10 = −1` (pull), `2'b11 = never`.

```
 BINARY FULL ADDER (bin_fa)                    TERNARY BALANCED FULL ADDER (tadd1)
 ===========================                    =======================================
 3 inputs, 1 wire each:  {0,1}                 3 inputs, 2 wires each:  {+1,0,-1}
 1 threshold per input                         2 thresholds per trit (push AND pull)
 2^3 = 8 input triples                         3^3 = 27 input triples
 1 carry direction (0/1)                       2 carry directions (+1 / -1)
 2 output wires (sum, cout)                    4 output wires (sp, sn, cop, con)

       a ──────────┐                                ap an    bp bn    cp cn
       b ──────────┼──► MAJ3 ───────► cout          │  │     │  │     │  │
     cin ──────────┘    majority       (1 rail)     ▼  ▼     ▼  ▼     ▼  ▼
                        26 T                     +-----------------+ +-----------------+
                                                 | MAJ3(+)  p2     | | MAJ3(-)  n2     |
       a ──────────┐                             | = 3·AND2 + OR3   | | = 3·AND2 + OR3   |
       b ──────────┼──► XOR3 ───────► sum        | (ap,bp,cp ≥2 +)  | | (an,bn,cn ≥2 -)  |
     cin ──────────┘    xor3         (1 rail)     | 26 T             | | 26 T             |
                        32 T                     +--------+---------+ +--------+---------+
                                                          |                    |
                                                       cop (s ≥ +2)      con (s ≤ -2)
                                                       carry +1           carry -1
                                                          (2 signed rails, 2 thresholds)

  carry logic:  1 x maj3  =  26 T              carry logic:  2 x maj3 + null/±2 bookkeeping
  sum logic:    1 x xor3  =  32 T              carry total:  92 T  (48% of the cell)
                                               sum logic:    sp + sn, 2 signed rails = 52 T

  sum = a XOR b XOR cin                        sp = (p1&nz) | (p2x&n1) | (pz&n2x)   [sum +1]
  cout = MAJ3(a,b,cin)                         sn = (n1&pz) | (n2x&p1) | (nz&p2x)   [sum -1]
                                               cop = nz & p2        con = pz & n2
```

**What to look at in the picture.** The binary cell is two gates: one **maj3** (the
carry, a single 0/1 decision) and one **xor3** (the sum, a single 0/1 wire). The
ternary cell is that structure *duplicated and signed*: a **maj3 on the push rail**
(`p2`, the `s ≥ +2` decision) **and a maj3 on the pull rail** (`n2`, the `s ≤ −2`
decision), a signed sum that must produce `+1`, `0`, *or* `−1` on two rails, and a
signed carry on two rails. Every one of the ternary cell's 4 output wires is a
"which-of-3-states" question, where binary asks "which-of-2".

---

## 2. Transistor counts, with the per-part breakdown

### 2.1 DIRECT — counted from the netlist `circuit/trelax.cir`

The device counts are printed *in the netlist header* (lines 169–172 for `tadd1`,
229–232 for `bin_fa`) and cross-checked against the `ngspice` instance list.

**Binary full adder `bin_fa` = 58 T** (a deliberately *generous-to-binary* hand build;
see §2.2 for the canonical number):

| block | gates | T |
|---|---:|---:|
| `cout = maj3(a,b,cin)` | 3×and2 + or3 | **26** |
| `x = a XOR b` | nand2 + or2 + and2 | **16** |
| `sum = x XOR cin` | nand2 + or2 + and2 | **16** |
| **total** | | **58** |

**Ternary balanced full adder `tadd1` = 192 T**:

| block | gates | T | what it decides |
|---|---|---:|---|
| `p2 = maj3(ap,bp,cp)` | 3×and2 + or3 | **26** | ≥2 *positive* inputs (carry +1) |
| `n2 = maj3(an,bn,cn)` | 3×and2 + or3 | **26** | ≥2 *negative* inputs (carry −1) |
| `all3p` / `all3n` | 2×and3 | **8 + 8** | all three + / all three − |
| `nz = ~(an\|bn\|cn)` / `pz = ~(ap\|bp\|cp)` | 2×nor3 | **6 + 6** | "no −" / "no +" (the null context) |
| `p2x` / `n2x` (exactly two) | 2×(inv+and2) | **8 + 8** | exactly two of a sign |
| `p1` / `n1` (exactly one) | 2×(or3+inv+and2) | **16 + 16** | exactly one of a sign |
| `cop` / `con` (carry out) | 2×and2 | **6 + 6** | the two signed carry rails |
| `sp` / `sn` (sum out) | 2×(3×and2 + or3) | **26 + 26** | the two signed sum rails |
| **total** | | **192** | |

**Ratio = 192 / 58 = 3.31×** (DIRECT, measured — `trelax_measured.md` §0, §3).

The breakdown makes the mechanism legible: the carry block alone is **92 T = 48% of
the cell**, and inside it the two `maj3` gates (`p2` + `n2` = **52 T**) are exactly the
"carry +1" and "carry −1" decisions that a binary FA makes **once** (26 T). The sum is
the other big ticket — **52 T for two signed rails** vs binary's single 32-T xor3.

### 2.2 The calibration fix: ~28–40 T binary vs ~100–130 T ternary

The task's "binary FA ~28–40 T, tadd1 = 3.31× that (~100–130 T)" needs one honesty
clamp, because the DIRECT-measured pair is **58 T vs 192 T**, not 28–40 vs 100–130:

| binary full adder | transistors | source / calibration |
|---|---:|---|
| canonical CMOS FA | **28 T** | standard textbook count; the netlist's own note says sky130 `badd1` (maj3+xor3) ≈ **24–28 T** |
| NAND-only / larger variant | **40 T** | common alternative topology |
| our `bin_fa` (harness) | **58 T** | DIRECT — `trelax.cir` §2, *deliberately generous to binary* |

| balanced ternary FA | transistors | source / calibration |
|---|---:|---|
| **our `tadd1` (naive boolean)** | **192 T** | **DIRECT** — `trelax.cir`, `trelax_measured.md` |
| literature, compound/hybrid | **118 T** | **ANALOGY** — `Automated_synthesis` (CNFET), quoted in `gates.md` §5b |
| literature, non-compound | **188 T** | **ANALOGY** — `Automated_synthesis` |

So **"3.31 × (28–40 T) = 93–132 T"** is a **DERIVED** figure, and it lands almost
exactly on the literature's **optimized 118-T** balanced FA — *not* on our measured
192-T naive cell. Read it either way:

- **Against the canonical 28-T binary FA**, our measured 192-T `tadd1` is **6.9×**, not 3.31×.
- **The 3.31× ratio** is what the repo *measured* against its 58-T harness FA (which is
  generous to binary), so 3.31× is a **lower bound** on the true ternary penalty.
- **The ~100–130 T ternary figure** is the literature's *optimized* cell (118 T), i.e.
  the number a ternary designer quotes when comparing against a 28–40 T binary FA.

Every "×4" number in this file is computed on the **DIRECT** pair (192 T vs 58 T,
146.39 vs 33.78 µm²) so the mechanism argument below stands regardless of which
baseline you prefer.

---

## 3. Measured area and energy (all cited)

### 3.1 Per-adder (DIRECT)

| quantity | ternary `tadd1` | binary FA | ratio | source |
|---|---:|---:|---:|---|
| area | **146.39 µm²** (25 cells) | **33.78 µm²** (2 cells: maj3+xor3) | **4.33×** | `gate_area.md` + `rtl/gate_area.txt` |
| transistors | **192 T** | **58 T** (harness) | **3.31×** | `trelax_measured.md` §0/§3 |
| energy / toggle | **0.355 fJ** | **0.185 fJ** | **1.92×** | `trelax_measured.md` §2 (identical toggle shape) |

- The energy pair uses the **same toggle shape** (sum swings full, carry toggles) on the
  same LEVEL=1 rails, so 1.92× is the clean per-gate ratio. `trelax_measured.md` §2.
- The 4.33× area would be **7.31×** against sky130's dedicated multi-output `fa_1` cell
  (20.02 µm²) if abc used it — it doesn't, so 4.33× is the *ternary-favorable* bound.
  `gate_area.md`.

### 3.2 Word-level, equal-information datapaths (DIRECT)

`word_fairfight.md` + `rtl/word_fairfight.txt`: 6 trits (3⁶ = 729 states) vs 10 bits
(2¹⁰ = 1024 states) — the nearest equal-information widths.

| datapath | cells | area (µm²) | ratio |
|---|---:|---:|---:|
| `wf_tadd6` — 6-trit ripple adder (6×`tadd1`) | 167 | **969.680** | |
| `wf_badd10` — 10-bit ripple adder (10×binary FA) | 48 | **258.998** | |
| **raw area ratio** | | | **3.744×** |
| **area / bit** | | | **3.937×** |

A ripple adder *is* N full-adders, so the word ratio ≈ the full-adder ratio ×
(digit-count ratio) — the word fight confirms, does not dilute, the per-gate 4.33×.

**One measured ripple detail worth keeping** (`word_fairfight.md` §3): the binary
ripple came out *cheaper per bit than its isolated FA* (25.90 vs 33.78 µm²) because abc
collapses each carry to a single `maj3` and each sum to cheap `nand3`/`nor3` cells. The
ternary ripple came out *dearer per trit* (161.6 vs 146.39 µm²) because the balanced
carry's **four output rails entangle the digits and give abc nothing to collapse** —
the 4× penalty is structural, not a synthesis artifact.

### 3.3 Energy context (DIRECT)

`trelax_measured.md` §5: a 6-input balanced reduction + blend (= 6 adder evaluations)
costs **~13–16 fJ/cell/step** vs **~11 fJ** for a binary adder-tree computing the same
6-input sum. The ternary adder's 1.92× energy penalty is only *partly* offset by binary
needing 10 bits where ternary needs 6 trits — net **1.2–1.5× worse**, not a win. (The
wire is still the wall: ~1 pJ/transfer dwarfs both.)

---

## 4. The physical mechanism of the ~4× — read from the diagram

Four mechanisms multiply together. All four are visible in §1's schematic; each is
anchored to a transistor count in §2.1.

### (a) 2 wires per trit — the 2-bit/trit encoding

A trit is `{pull, push}`: **two wires carry one digit**, and the 4th wire state
(`2'b11`) is a wasted don't-care. So a 3-input adder carries **6 input wires** (3 trits
× 2) where binary carries **3**, and the 2 wires deliver only log₂3 = 1.585 bits —
**0.792 bits/wire vs binary's 1.0**, a 26% waste *before any gate cost*.
**[DIRECT — `gate_area.md` §3; the encoding is Lean-proved in `TernaryCell.lean`.]**

This is the *root*: because each trit is 2 rails, every "single" ternary operation is
really a 2-rail signed operation, and the whole cell below is the consequence.

### (b) 2 thresholds to sense 3 states

Binary resolves one boundary (0/1) → **one threshold**. Ternary must resolve
`+1`/`0`/`−1` → **two decision boundaries** (push-rail above threshold *and* pull-rail
above threshold *and* neither). This is the "2-threshold tax" of `ENERGY_LAWS.md` Law 1,
measured cleanly on the cheap gates: `tmin`/`tmax` = **2.00×** a binary AND/OR, because a
ternary MIN is literally one AND2 (the `+` line) *plus* one OR2 (the `−` line).
**[DIRECT — `gate_area.md` §2.]**

In `tadd1` the two thresholds are the two `maj3` gates: `p2` thresholds the push rails,
`n2` thresholds the pull rails — 52 T doing what binary does with one 26-T `maj3`.

### (c) The balanced carry must distinguish ±carry — 2 cases, not 1

Binary carry is **unsigned**: `cout ∈ {0,1}`, one wire, one `maj3` (26 T). Balanced
carry is **signed**: `cout ∈ {+1,0,−1}`, two wires (`cop`,`con`), and the cell must
detect *both* `s ≥ +2` **and** `s ≤ −2` — **two separate majority gates, 26 T each**.
That single duplication (one extra `maj3`) is 26 T by itself, and the null-context
bookkeeping it drags in (`all3p/all3n`, `nz/pz`, `p2x/n2x`) pushes the carry block to
**92 T = 48% of the cell**. **[DIRECT — counted in §2.1.]**

### (d) 27 vs 8 input combos

A 3-input binary adder resolves 2³ = **8** input triples; a 3-input ternary adder
resolves 3³ = **27**. The `tadd1` truth table (`rtl/trit_functions.vh`) groups those 27
into digit-sum classes `s = a+b+cin ∈ {−3…+3}`, and the carry must partition them into
**3** classes (`+1`/`0`/`−1`) and the sum into **3** — so every output is a
"which-of-3" decision over 3.375× the input space. The hardware cost of the extra
combos is the "exactly one / exactly two" bookkeeping (`p1/n1/p2x/n2x` = 48 T, 25% of
the cell) that the naive one-hot count drops — `trelax_measured.md` §1.3 calls out these
cross terms explicitly.

### 4.1 Which one dominates? The verdict

**The dominant mechanism is the 2-wire/trit encoding and the 2-threshold sensing it
forces (a)+(b).** It is the *root*: 3 signed states carried on 2 rails means the adder
is a 2-rail signed adder, and everything else follows from it —

- the **signed ±carry** (c) is the *most expensive single line item* (the second `maj3`,
  52 T of carry thresholds vs 26 T) — but it exists **because** the digit is signed on 2
  rails;
- the **27-vs-8 combos** (d) are the *combinatorial background* that logic must resolve —
  but it is realized in silicon **through** the 2-threshold/2-rail structure of (a)+(b).

So the task's hypothesis is confirmed, with one sharpening: the "~4×" (not ~2×) is
(a)+(b) *as it manifests in* (c). A 2-wire encoding alone would predict ~2×; the extra
factor to reach 4.33× is the **signed carry's second majority threshold** and the signed
sum's second rail — i.e. (c) is what turns "2 wires per trit" into "4 wires out per adder
vs 2", and 4 rails out / 2 rails out is the schematic-level face of the 4.33× area.

---

## 5. Calibration ledger

| claim | calibration |
|---|---|
| `tadd1` = 192 T, `bin_fa` = 58 T, ratio 3.31× | **DIRECT** — counted from `circuit/trelax.cir` (header lines 169–172, 229–232); `trelax_measured.md` §0/§3 |
| per-part breakdown (maj3 26 T, carry block 92 T, sum 52 T, …) | **DIRECT** — counted from the same netlist header |
| `tadd1` 146.39 µm² / 25 cells, `badd1` 33.78 µm² / 2 cells = 4.33× | **DIRECT** — `rtl/gate_area.txt`, `gate_area.md` |
| `wf_tadd6` 969.68 vs `wf_badd10` 259.00 µm² = 3.744× (3.937×/bit) | **DIRECT** — `rtl/word_fairfight.txt`, `word_fairfight.md` |
| energy 0.355 vs 0.185 fJ = 1.92× (same toggle shape) | **DIRECT** — `trelax_measured.md` §2, `circuit/trelax.log` |
| "2 thresholds to sense 3 states" (tmin/tmax = 2.00× AND/OR) | **DIRECT** — `gate_area.md` §2; Law 1 of `ENERGY_LAWS.md` |
| "0.792 bits/wire" (2-wire trit, 26% wire waste) | **DIRECT** — `gate_area.md` §3; log₂3 = 1.585 [Lean `RadixEconomy.lean`] |
| binary FA ~28–40 T canonical | **DIRECT/ANALOGY** — textbook + the netlist's own note (sky130 badd1 ≈ 24–28 T) |
| ternary FA ~100–130 T (= 3.31 × 28–40) | **DERIVED/ANALOGY** — matches the literature's 118-T compound/hybrid cell (`gates.md` §5b), **not** our measured 192-T naive cell |
| "the ~4× is the 2-wire/trit + 2-threshold sensing, manifested as the signed carry" | **OURS** — interpretation anchored on the DIRECT counts of §2.1 |

---

## 6. Sources

- `docs/compute/gate_area.md` + `rtl/gate_area.txt` — per-gate area (yosys 0.52, sky130), 4.33×.
- `docs/compute/word_fairfight.md` + `rtl/word_fairfight.txt` — word-level area, 3.744×/3.937×.
- `docs/compute/field_calculus/trelax_measured.md` + `circuit/trelax.cir` + `circuit/trelax.log` —
  per-adder energy (1.92×) and transistor counts (3.31×), and the `tadd1`/`bin_fa` netlists.
- `rtl/trit_functions.vh` + `rtl/ternary_gates.v` — the `tadd1` truth table, boolean form, encoding.
- `docs/compute/gates.md` — the 2-threshold tax framing and the literature's 118–188 T balanced FA.
- `docs/compute/ground_up/tsum_cell.md` — the mod-3 sum's null-rail story (why `⊕` is irreducible).
- `docs/ENERGY_LAWS.md` (Law 1) + `circuit/ENERGY_RESULTS.md` — the 2-threshold receiver tax.
- `proofs/lean-src/hexagon/Hexagon/TernaryCell.lean` + `RadixEconomy.lean` — encoding proofs, log₂3.

*Every count and ratio in this file is measured (yosys/ngspice) or counted from a netlist;
the only derived/analogy items are flagged as such in §5.*
