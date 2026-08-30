# Binary CMOS Baseline — Schematic & Transistor Counts

**Purpose.** This is the *reference baseline* the ternary gate diagrams are measured
against. Three standard static-CMOS binary gates — the inverter, the 2-input NAND, and the
full adder — drawn as ASCII schematics with exact transistor counts. Everything here is
**standard textbook CMOS** (Weste & Harris / Weste & Eshraghian class), so the side-by-side
with the ternary cells (`docs/compute/gates.md`, `gate_area.md`, `gate_energy.md`) reduces to
one question: *how many transistors — and how many thresholds — does a binary gate need,
versus its ternary counterpart?*

**Calibration legend (two levels, per the task):**

- **DIRECT** — standard CMOS fact: a citable textbook topology and transistor count, or a
  measured number already in `circuit/` (`fair_binary.cir`, `fair_binary.log`).
- **DERIVED** — follows from the DIRECT facts by one arithmetic/logical step (e.g. "one
  threshold because one state boundary"). No invented numbers.

---

## 0. Transistor glyph legend

The same convention on every drawing below.

```
  pMOS (pull-up)                    nMOS (pull-down)

      VDD                               node
       │                                 │
   ┌───┴───┐                         ┌───┴───┐
   │  pMOS │────○ gate   (bubble:    │  nMOS │──── gate  (no bubble:
   └───┬───┘     conducts when       └───┬───┘     conducts when
       │         gate = 0)               │         gate = 1)
      node                              GND

   VDD = top rail (logic "1")      GND = bottom rail (logic "0")
   ● = wire junction               ○ = PMOS inversion bubble on the gate
```

- A pMOS sits **between VDD and the output** and pulls the output *up* (to 1) when its gate
  is 0.
- An nMOS sits **between the output and GND** and pulls the output *down* (to 0) when its
  gate is 1.
- **Pull-up network (PUN)** = all pMOS above the output. **Pull-down network (PDN)** = all
  nMOS below the output. For a static gate to work, the PUN and PDN are *complements*: for
  every input pattern exactly one of them conducts, so there is never a VDD→GND short and the
  output is never floating.

---

## 1. Inverter (NOT) — 2 transistors

```
          VDD
           │
       ┌───┴───┐
       │  Mp   │────○──── A        Mp = pMOS pull-up   (gate driven by A)
       └───┬───┘
           ├────────────── Y        Y = ¬A   (drain of Mp joined to drain of Mn)
           │
       ┌───┴───┐
       │  Mn   │────────── A        Mn = nMOS pull-down (gate driven by A)
       └───┬───┘
           │
          GND
```

| transistor | type | role | gate |
|---|---|---|---|
| **Mp** | pMOS | pull-up (Y → 1 when A = 0) | A |
| **Mn** | nMOS | pull-down (Y → 0 when A = 1) | A |

**Count: 2 transistors (1 pMOS + 1 nMOS).** **[DIRECT — standard static CMOS]**

- A = 1 → Mn conducts, Mp off → Y pulled to GND = 0.
- A = 0 → Mp conducts, Mn off → Y pulled to VDD = 1.

The inverter is the *definition* of "one threshold": a single device pair straddling a single
Vth, one state boundary (0/1), one voltage comparison.

---

## 2. 2-input NAND — 4 transistors

```
          VDD
           │
       ┌───┴───┐        ┌───┴───┐
       │  Mp1  │──○ A   │  Mp2  │──○ B       pMOS in PARALLEL  (PUN)
       └───┬───┘        └───┬───┘
           ├────────┬───────┘
                    ├──────────── Y          Y = ¬(A·B)
                    │
                ┌───┴───┐
                │  Mn1  │──── A             nMOS in SERIES   (PDN)
                └───┬───┘
                    │
                ┌───┴───┐
                │  Mn2  │──── B
                └───┬───┘
                    │
                   GND
```

| transistor | type | network | role | gate |
|---|---|---|---|---|
| **Mp1** | pMOS | PUN (parallel) | Y → 1 when A = 0 | A |
| **Mp2** | pMOS | PUN (parallel) | Y → 1 when B = 0 | B |
| **Mn1** | nMOS | PDN (series) | Y → 0 only when A = B = 1 | A |
| **Mn2** | nMOS | PDN (series) | Y → 0 only when A = B = 1 | B |

**Count: 4 transistors (2 pMOS parallel + 2 nMOS series).** **[DIRECT — standard static CMOS]**

- **PUN (parallel):** either Mp1 *or* Mp2 pulling up is enough to drive Y = 1 — so Y = 1
  whenever *any* input is 0.
- **PDN (series):** *both* Mn1 *and* Mn2 must conduct to pull Y = 0 — so Y = 0 only when
  *all* inputs are 1.

That parallel/series duality is the whole static-CMOS recipe: an OR of conditions in the
pull-up becomes an AND of the same conditions in the pull-down (De Morgan), and vice versa.
The **NOR** (also 4T, measured in `fair_binary.cir`) is the mirror image — pMOS in series,
nMOS in parallel — and costs the same 4 transistors. **[DIRECT]**

---

## 3. CMOS full adder — 28 transistors

Standard static-CMOS full adder. Boolean form (the one textbooks give):

```
    Sum  S  = A ⊕ B ⊕ Cin
    Carry C  = A·B + Cin·(A ⊕ B)      =  majority(A, B, Cin)
```

The carry reuses the intermediate `X = A ⊕ B` already produced on the sum path, which is
exactly what keeps the whole cell at **28T** instead of ~34T.

```
                            ┌────────────────┐
 A ──────────────┬──────────┤  XOR  (8T)     │
                 │          │                │
 B ──────────────┤          │   X = A ⊕ B    ├──────┬─────────────────────────────
                 │          └────────────────┘      │
                 │                                  │
 Cin ────────────┼──────────────────────────────────┤
                 │                                  │
                 │   ┌────────────────┐             │
                 └───┤  XOR  (8T)     │             │
                     │  S = X ⊕ Cin   ├─────────────┼─── S   (sum)
                     └────────────────┘             │
                                                    │
        ┌────────────────┐                          │
 A ─────┤  NAND  (4T)    │                          │
 B ─────┤  n1 = ¬(A·B)   ├────────────┐             │
        └────────────────┘            │             │
                                      │             │
        ┌────────────────┐            │             │
 Cin ───┤  NAND  (4T)    │            │             │
 X ─────┤  n2 = ¬(Cin·X) ├─────────┐  │             │
        └────────────────┘         │  │             │
                                   │  │             │
                           ┌───────┴──┴─────────────┴──┐
                           │  NAND  (4T)               │
                           │  C = ¬(n1·n2)             ├─── C   (carry out)
                           └───────────────────────────┘
```

### Transistor budget (28T)

| block | gates | transistors | produces |
|---|---|---|---|
| XOR #1 | 1 × 2-input XOR | **8** | `X = A ⊕ B` |
| XOR #2 | 1 × 2-input XOR | **8** | `S = X ⊕ Cin` |
| carry | 3 × 2-input NAND | **12** | `C = ¬( ¬(A·B) · ¬(Cin·X) )` |
| **total** | | **28** | `{C, S}` |

**Count: 28 transistors (16T sum path + 12T carry path).** **[DIRECT — the conventional
static-CMOS full adder]**

Notes on the sub-blocks (all DIRECT, standard CMOS):

- **2-input XOR = 8T** — two inverters (2T each) plus two transmission gates (2T each):
  fully static, full-swing output, no floating node. (A fully *complementary* static XOR is
  sometimes cited at 12T; the 8T transmission-gate form is the standard count in the 28T
  adder.) If your reference uses 12T XORs, the adder reads 32T; the *conventional* number
  every ternary-vs-binary paper compares against is **28T**.
- **Carry = 12T** — three NAND2s. `C = NAND(NAND(A,B), NAND(Cin, X))`, which is De Morgan's
  identity `AB + Cin·X = ¬( ¬(AB) · ¬(CinX) )`. This is the majority-of-3 (if any two of
  {A, B, Cin} are 1, C = 1).

This 28T adder is the exact reference cell that `gate_area.md` and `gates.md` measure the
ternary `tadd1` (mod-3 sum, 25 standard cells ≈ 146 µm², ~4.33× the binary `badd1`) against.
**[DIRECT — `docs/compute/gate_area.md`]**

---

## 4. Summary — transistor counts, labeled

| gate | transistors | PUN (pMOS) | PDN (nMOS) | function | calibration |
|---|---:|---|---|---|---|
| **Inverter** | **2** | 1 (single) | 1 (single) | `Y = ¬A` | DIRECT |
| **NAND2** | **4** | 2 (parallel) | 2 (series) | `Y = ¬(A·B)` | DIRECT |
| **NOR2** | **4** | 2 (series) | 2 (parallel) | `Y = ¬(A+B)` | DIRECT |
| **Full adder** | **28** | — | — | `{C, S}` = `{majority(A,B,Cin), A⊕B⊕Cin}` | DIRECT |

Measured toggle energies on these exact topologies (`circuit/fair_binary.cir` §2, single-ended
0→1 V, the *fair* binary baseline): NOT **6.94 fJ**, NAND **11.36 fJ**, NOR **8.65 fJ** per
toggle. **[DIRECT — `fair_binary.log`]** These are the numbers the ternary diode/polar gates
are compared against in `fair_binary.md` §4.

---

## 5. WHY binary is cheap — 1 wire, 1 threshold, 2 states

Three facts, each DIRECT from the schematics above, plus one DERIVED consequence. This is the
one-page "what the ternary diagrams must beat."

### 5.1 One wire per bit — no encoding overhead **[DERIVED, from §1–§3]**

A binary gate's state *is* its voltage: one wire, two rails, and the bit is the level
(0 = GND, 1 = VDD). There is nothing to encode. Contrast the project's trit
(`rtl/trit_functions.vh`, `docs/compute/gates.md` §1): a balanced trit is **2 wires**,
one-hot-per-direction — `2'b01 = +1`, `2'b00 = 0`, `2'b10 = −1`, `2'b11 = NEVER` — so a trit
costs 2 wires to carry log₂3 ≈ 1.585 bits = **0.792 bits/wire**, *below* binary's 1 bit/wire.
**[DERIVED — the 0.792 figure is the measured/DIRECT consequence in `gate_area.md` §"honest
verdict"]** Binary is the only radix where the wire and the digit coincide; every higher radix
pays an encoding to put >1 bit on the wire, and (in this project's 2-wire encoding) that
overhead *loses* density instead of gaining it.

### 5.2 One threshold — a single Vth **[DIRECT]**

Binary resolves exactly **one state boundary** (0 vs 1), so it needs exactly **one
threshold** (one Vth, one comparator, one sense amp). The inverter's Mn and Mp are one device
pair straddling one threshold. **[DIRECT — this is the definition of the inverter]**

A level-coded ternary gate resolves **3 levels → 2 thresholds** (two comparators); the
project's polarity receiver demuxes push/pull onto 2 rails, each with its own sense amp —
still **2 detection paths per trit**. **[DIRECT — measured: the 2-threshold receiver tax is
2.54× a 1-threshold receiver, `docs/compute/gate_energy.md`; MIN/MAX = 2.00× a binary AND/OR,
`gate_area.md`]** More states = more thresholds = more fixed receiver/gate energy per
evaluation, *before* the logic is counted. Binary pays the minimum possible: one.

### 5.3 Two states — on/off **[DIRECT]**

Binary has exactly 2 states (on/off, 1/0), so its swing is **rail-to-rail** and the noise
margin is the *full* VDD/2. **[DIRECT]** There is no middle level to hold, no dead-zone
between elevated |Vt| devices, no null-return termination, and no keeper to leak through the
middle state. (The ternary diode-direction gates pay all of those: a full-swing +1↔−1 toggle
costs **369 fJ** — 53× the binary NOT's 6.94 fJ — because the dead-zone output stage passes
through a both-devices-conducting middle window; `fair_binary.md` §4. **[DIRECT — measured]**)

### 5.4 The one-line minimality claim

> **Binary is minimal because a bit is its own encoding: 1 wire carries 1 bit, 1 threshold
> (one Vth) resolves 1 boundary, and 2 states (on/off) fill the full rail-to-rail noise
> margin — zero encoding overhead, zero middle state.** **[DERIVED — conjunction of §5.1–5.3]**

Every radix >2 trades some of that minimality for per-*symbol* density (log₂3 ≈ 1.585 bits),
and the whole ternary survey (`gates.md`, `gate_area.md`, `gate_energy.md`, `fair_binary.md`)
is the measurement of whether that density ever buys back more than the extra threshold +
extra wire + middle-state costs. On a binary standard-cell library, it does not — but that is
the *next* diagram's argument. This file is only the baseline being measured against.

---

## 6. Calibration ledger

| claim | calibration |
|---|---|
| inverter = 2T (1 pMOS + 1 nMOS) | **DIRECT** — standard static CMOS |
| NAND2 = 4T (2 pMOS ∥ + 2 nMOS series); NOR2 = 4T mirror | **DIRECT** — standard static CMOS |
| full adder = 28T (2× XOR-8T = 16T sum + 3× NAND-4T = 12T carry) | **DIRECT** — conventional static-CMOS full adder |
| 2-input XOR = 8T (2 inverters + 2 transmission gates) | **DIRECT** — standard transmission-gate XOR |
| carry = 3× NAND2 = `¬(¬(AB)·¬(Cin·X))` = majority(A,B,Cin) | **DIRECT** — De Morgan identity, standard |
| NOT/NAND/NOR toggle energy 6.94 / 11.36 / 8.65 fJ | **DIRECT** — `circuit/fair_binary.cir` §2, measured |
| "one wire per bit, zero encoding overhead" | **DERIVED** — from §1–§3 (a bit *is* a level) |
| "one threshold (single Vth) resolves one boundary" | **DIRECT** — definition of the inverter |
| "2 states → full rail-to-rail noise margin" | **DIRECT** — standard CMOS |
| "binary is the minimum: 1 wire / 1 threshold / 2 states" | **DERIVED** — conjunction of §5.1–5.3 |
| ternary trit = 2 wires/trit = 0.792 bits/wire | **DIRECT** — `gate_area.md` (measured consequence of `rtl/trit_functions.vh`) |

*No number in this file is invented: every transistor count is the standard CMOS figure, and
the two energy numbers are re-read from `circuit/fair_binary.log`. The "why binary is cheap"
argument is the minimality claim (`DERIVED`) the ternary side must defeat.*
