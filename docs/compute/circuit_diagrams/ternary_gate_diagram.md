# Ternary Gate — Transistor-Level Schematic (the Tau balanced-ternary gate)

**Purpose.** Show, at transistor/diode level, how the **three states of a trit** —
**push (+1 / forward)**, **null (0)**, **pull (−1 / backward)** — are *physically
generated* by the diode-direction ternary gate (`dd_not`, the ternary inverter), and
why that gate costs **2 diodes + 2 transistors = 4 devices** where a binary inverter
costs **2 transistors**.

Ground truth is the netlist `circuit/diode_gates.cir` (the *gate* netlist, measured:
`circuit/diode_gates.log`), cross-checked against the comm-cell netlists
`circuit/ternary_cell.cir` and `circuit/ternary_transistor.cir` and the prose in
`docs/compute/ground_up/diode_gates.md`, `fair_binary.md`, and `radix_lower_bound.md`.

**Calibration legend (two levels, per the task):**

- **DIRECT** — counted from the netlist, or measured in a `.log` / cited `.md`.
- **DERIVED** — one arithmetic/logical step from a DIRECT fact (e.g. `Vgs` from the
  rail and supply voltages, a device-count ratio). No invented numbers.

---

## 0. The device models (verbatim from the `.cir` files)

These are the exact `LEVEL=1` SPICE models the schematic below uses. **DIRECT** —
`circuit/diode_gates.cir` lines 88, 99–112.

```
VDD   = 1.0 V            →  the two supplies are +VDD = +1.0 V and −VDD = −1.0 V

.model NMOS1  NMOS(LEVEL=1 VTO=+0.4  KP=200u LAMBDA=0.05 TOX=2n)   ← binary control
.model PMOS1  PMOS(LEVEL=1 VTO=-0.4  KP=100u LAMBDA=0.05 TOX=2n)   ← binary control
.model N_HI   NMOS(LEVEL=1 VTO=+1.4  KP=200u LAMBDA=0.05 TOX=2n)   ← ELEVATED |Vt| (dead zone)
.model P_HI   PMOS(LEVEL=1 VTO=-1.4  KP=100u LAMBDA=0.05 TOX=2n)   ← ELEVATED |Vt| (dead zone)
.model DD     D (IS=1e-9 RS=200 CJO=2f TT=1p N=1.05)               ← Schottky rectifier
```

Two things carry the whole mechanism:

1. **The elevated-|Vt| = 1.4 V is *between* VDD (1.0 V) and VDD+Vrail (~1.73 V).**
   A device whose source is at −VDD sees `Vgs = +1.0 V` when its gate (a rail) is at
   **0 V (null)** → **OFF** (dead zone); it sees `Vgs ≈ 1.73 V` when the rail fires →
   **ON**. The null is therefore a *dead zone*, not a driven level. **DIRECT** (model)
   / **DERIVED** (the `Vgs` arithmetic, §4).
2. **The diode `DD` is Schottky-ish** (`TT=1p`, `CJO=2f`): it blocks reverse and its
   ~0.43 V forward drop at 1 mA lets the rail assert well above the 0.4 V dead-zone
   floor. **DIRECT** — `diode_gates.md` §2/§6.

---

## 1. The gate (`dd_not`) — full schematic

`dd_not` is the **ternary NOT / inverter**: the minimal self-restoring ternary gate.
Input push → output pull, input pull → output push, input null → output null. Netlist
`circuit/diode_gates.cir` `.subckt dd_not` (lines 130–134) + `.subckt dd_recv`
(lines 116–123). The receiver is **passive** (no supply, no clock); the driver is a
**push-pull pair of elevated-|Vt| devices**.

```
            THE TAU TERNARY GATE  —  "dd_not"  (the diode-direction NOT / inverter)
            one trit IN (1 wire)  →  diode demux  →  2 rails  →  dead-zone push-pull OUT
            ========================================================================

   INPUT WIRE (polar)          RECEIVER (2 Schottky diodes)             DRIVER (2 dead-zone MOS)
   win :  +1 = PUSH (current OUT of wire)                                                     
           0 = NULL (no current)                                                                
          -1 = PULL (current INTO wire)                                                        

                                        D1  anode=win ──► cathode=rA  (current win → rA)          
    win o──────────────────────────────>|──────────────────── o rA ─────────► gate of Mn       
         │                               │  (push: win → rA)     PUSH RAIL                     
         │                               │                        (0 → +0.73 V)                
         │                               ├────/\/\──── 0          RkA 100 kΩ (keeper)          
         │                                                                                     
         │                     D2  anode=rB ◄── cathode=win  (current rB → win, i.e. ←)        
         └──────────────────────────────|<──────────────────── o rB ─────────► gate of Mp       
                                         │  (pull: rB → win)     PULL RAIL                     
                                         │                        (0 → −0.74 V)                
                                         ├────/\/\──── 0          RkB 100 kΩ (keeper)          

                                     (next stage of the same figure: the two rails rA, rB
                                      are the GATES of the two output devices below)

                                                   +VDD = +1.0 V                               
                                                       │                                      
                                                   ┌───┴───┐                                  
                                    rB ───────────○│   Mp  │   P_HI  PMOS, Vt = −1.4 V        
                                    (pull rail)     └───┬───┘   source=+VDD, drain=wout       
                                                       │                                      
                                                       ├────────────────── o wout  (OUTPUT)    
                                                       │                                     │ 
                                                   ┌───┴───┐                                 Rterm
                                    rA ───────────○│   Mn  │   N_HI  NMOS, Vt = +1.4 V   100 kΩ → 0
                                    (push rail)     └───┬───┘   source=−VDD, drain=wout  (null return)
                                                       │                                      
                                                   −VDD = −1.0 V                              
```

**Diode-direction rule (DIRECT — netlist `dd_recv`):**

- `D1 win rA DD` — anode = `win`, cathode = `rA`. Conducts **win → rA** (forward) when
  `V(win) > V(rA)`, i.e. on a **push**; it is what charges the push rail `rA` positive.
- `D2 rB win DD` — anode = `rB`, cathode = `win`. Conducts **rB → win** when
  `V(rB) > V(win)`, i.e. on a **pull** (the wire is dragged negative, so current is
  pulled *out of* the pull rail `rB`, driving it negative).

A diode is a **direction detector**: two opposite diodes fire on push and on pull
respectively, and **neither fires on null** (no current → free). This is the whole
receiver. **DIRECT** — `diode_gates.cir` header lines 1–13; `diode_gates.md` §1.

---

## 2. The three states — exactly which device conducts

| state | input `win` | D1 | D2 | rA (push rail) | rB (pull rail) | Mp (P_HI) | Mn (N_HI) | output `wout` |
|---|---|---|---|---|---|---|---|---|
| **PUSH (+1)** | current OUT | **ON** | off | **+0.73 V** | 0 | off | **ON** | **−1.0 V** (pull) |
| **NULL (0)** | no current | off | off | 0 | 0 | off | off | **0 V** (no line energized) |
| **PULL (−1)** | current IN | off | **ON** | 0 | **−0.74 V** | **ON** | off | **+1.0 V** (push) |

Tracing the three current paths (DIRECT rail values from `circuit/diode_gates.log`
`vra_*`/`vrb_*`/`vw_*`; DERIVED `Vgs` arithmetic):

**PUSH path (input +1 → output −1, a *negation*):**
```
win ↑  →  D1 conducts win→rA  →  rA = +0.733 V
      →  Mn gate = +0.733 V, source = −1.0 V  ⇒  Vgs = +1.73 V  >  Vt(+1.4)  ⇒  Mn ON
      →  wout pulled DOWN to −VDD = −1.0 V   (pull out)
```

**PULL path (input −1 → output +1, a *negation*):**
```
win ↓  →  D2 conducts rB→win  →  rB = −0.744 V
      →  Mp gate = −0.744 V, source = +1.0 V  ⇒  |Vgs| = 1.74 V  >  |Vt|(1.4)  ⇒  Mp ON
      →  wout pushed UP to +VDD = +1.0 V   (push out)
```

**NULL path (input 0 → output 0):**
```
win = 0  →  neither diode conducts  →  rA = 0, rB = 0  (held by RkA/RkB keepers)
        →  Mn gate = 0 ⇒ Vgs = +1.0 V  <  Vt(+1.4)  ⇒  OFF
        →  Mp gate = 0 ⇒ |Vgs| = 1.0 V <  |Vt|(1.4)  ⇒  OFF
        →  both output devices off  ⇒  wout returns to 0 V via Rterm  ("no line energized")
```

The cross-coupling (push rail gates the *NMOS to −VDD*; pull rail gates the *PMOS to
+VDD*) **is** ternary negation — the diode receiver + elevated-|Vt| driver is a
self-restoring inverter with a dead-zone null: **no sense amp, no clock, no level
shifter.** **DIRECT** — `diode_gates.cir` lines 125–134; `diode_gates.md` §1.

---

## 3. Device count — one ternary gate vs one binary inverter

**DIRECT** counts from `circuit/diode_gates.cir` (`.subckt inv` lines 184–187;
`.subckt dd_not` lines 130–134; `.subckt dd_recv` lines 116–123).

```
   BINARY inverter (inv)                         TERNARY gate (dd_not)
   ----------------------                        -------------------------
        VDD                                          D1  (push rectifier)     ← 1 diode
         │                                           D2  (pull rectifier)     ← 1 diode
     ┌───┴───┐   Mp  PMOS  ──○ A                     Mp  P_HI  (Vt=−1.4)     ← 1 transistor
     │  Mp   │                                         Mn  N_HI  (Vt=+1.4)     ← 1 transistor
     └───┬───┘                                     -------------------------
         ├──── Y   (2 transistors, total)           2 D  +  2 T  =  4 devices
         │                                          (keeper Rs/Cs are passive,
     ┌───┴───┐   Mn  NMOS  ──○ A                     not counted as devices)
     │  Mn   │
     └───┬───┘
        GND

   transistor count:  2 T                            transistor count:  2 T  (+2 rectifier diodes)
```

| part | binary `inv` | ternary `dd_not` | what it does |
|---|---|---|---|
| rectifier diode (per input wire) | — | **D1, D2 = 2 D** | split the 1 polar wire into push rail / pull rail |
| pull-up transistor | Mp (PMOS, `Vt=−0.4`) | Mp (P_HI, `Vt=−1.4`) | fires on pull → drives +1 |
| pull-down transistor | Mn (NMOS, `Vt=+0.4`) | Mn (N_HI, `Vt=+1.4`) | fires on push → drives −1 |
| **total active devices** | **2 T** | **2 D + 2 T = 4** | **2.0× the binary inverter** (DERIVED) |

The **full ternary family** (DIRECT — `diode_gates.md` §3 table):

| gate | devices | vs binary analog |
|---|---|---|
| binary NOT | 2 T | — |
| binary NAND / NOR | 4 T | — |
| `dd_not` (negation) | 2 D + 2 T = **4** | 2.0× NOT |
| `dd_nand` / `dd_nor` | 4 D + 4 T = **8** | 2.0× NAND/NOR |
| `dd_min` / `dd_max` (= NOT∘NAND / NOT∘NOR) | 6 D + 6 T = **12** | 3.0× NAND/NOR |

The keeper/termination elements (`RkA`, `RkB` = 100 kΩ, `CkA`, `CkB` = 2 f, `Rterm`
= 100 kΩ) are **passive** and are not counted as devices (`diode_gates.cir` header,
"DEVICE COUNTING"). The elevated-|Vt| devices and the Schottky rectifier are two
**extra fabrication flavors** binary never needs — the device-count story is the
active-area story, not the process story. **DIRECT** — `diode_gates.md` §4/§6.

---

## 4. The elevated-|Vt| dead zone — why null is "no line energized"

The elevated threshold `|Vt| = 1.4 V` sits **between VDD (1.0 V) and VDD+Vrail
(~1.73 V)**, so a rail at **0 V never turns a device on** — the null is a genuine
dead zone, a full `Vt − VDD = 0.4 V` clear of either trip point. **DERIVED** from the
DIRECT model values.

```
   N_HI device:  source = −VDD = −1.0 V,  gate = push rail rA,  turns on when Vgs > Vt = +1.4 V

      rA (V)      Vgs = rA − (−1.0)        device state
   -----------   ----------------------    --------------------------------
     +0.733 V          +1.73 V              ON   (overdrive ≈ +0.33 V)   ← push fires it
      0 V (null)       +1.00 V              OFF  (dead zone: 1.00 < 1.4)  ← null does NOT
   -----------   ----------------------    --------------------------------
   dead-zone width = Vt − VDD = 1.4 − 1.0 = 0.4 V

   The level ladder (output stage, both devices):

        pull rail fired          NULL (dead zone)          push rail fired
            rB = −0.74 V                                     rA = +0.73 V
                │                                                │
    −1.0 V ─────┼────────── 0 V (null) ──────────┼────────── +1.0 V
                │              │  ▲               │
                │              │  │  0.4 V gap    │
      Mp ON  ───┘              └──┴───────────────┴── Mn ON
     (P_HI: |Vgs|=1.74)      both OFF: |Vgs|=1.0 < 1.4
                             "no line energized" (wout → 0 via Rterm)
```

**Rail voltages, measured (DIRECT — `circuit/diode_gates.log`):**

| quantity | value | source |
|---|---|---|
| push rail `rA` on push | **+0.7328 V** | `vra_6` (dd_nor) / `vra_4` (fair_binary) |
| pull rail `rB` on pull | **−0.7436 V** | `vrb_4` (dd_not) / `vrb_6` (fair_binary) |
| output wire on assert | **+0.976 / −0.987 V** (≈ ±VDD) | `vw_6_r`, `vw_4_r` |
| null return (release) | **−0.025 … +0.055 V** (≪ 0.4 V trip) | `diode_gates.md` §3 |
| rails range cited in `fair_binary.md` §4 / `radix_lower_bound.md` §2.2 | **±0.57 / ±0.73 V** | prose (the low end is the heavier full-swing-toggle operating point) |

The null is therefore **not a third driven voltage level** — it is the *absence* of
conduction: `rA = rB = 0`, both dead-zone devices off, the output wire released to 0 V
through `Rterm`. Measured null-idle supply energy is **1.5–3.8 × 10⁻¹⁹ J over 75 ns** —
statistically the noise floor; the null draws ~0 current. **DIRECT** — `diode_gates.md`
§3.

> The ±0.57 V figure is the *low* end of the rail-assertion range quoted in
> `fair_binary.md` §4 and `radix_lower_bound.md` §2.2 (their words: "the elevated-|Vt|
> output stage has a thin dead band (rails only reach ±0.57/±0.73 V)"). The
> directly-measured gate rail checkpoints are **+0.733 V / −0.744 V** (the ±0.73 V
> end). Both are far enough above the 0.4 V dead-zone floor to fire, and far enough
> below to leave the null a true dead zone.

---

## 5. 2-bit/trit encoding — why one trit is TWO wires

One trit is `log₂3 = 1.585` bits, but the gate only has **2-level** (boolean) wires
and **2-level** MOSFET gates to work with. So a trit is *physically* carried as
**two wires** — the **push line** and the **pull line**:

```
   BINARY:   1 wire  = 2 levels (0/1)  = 1 bit          → 1 wire carries 1 bit

   TERNARY:  1 trit  = 3 states = log2(3) = 1.585 bits  → needs ⌈log2 3⌉ = 2 boolean wires

   the 2-wire one-hot code (push line + pull line):
        push   pull   │  trit
       ────── ──────  │ ────────
          1      0    │   +1   (forward / push)
          0      0    │    0   (null)
          0      1    │   −1   (backward / pull)
          1      1    │   NEVER  ← the wasted 4th state
```

- 2 wires → 4 codes, of which **3 are used and 1 (`11`) is wasted** → each wire carries
  `log₂3 / 2 = 0.79` bits/wire vs binary's **1.0** bit/wire = a **+26% wire overhead**
  (`1 / 0.79 = 1.26×`). **DIRECT** — `gate_area.md`; `diode_gates.md` §2, factor 6 of
  `radix_lower_bound.md` §2.2.
- **In the diode-direction gate this "two wires" is literal.** The single polar input
  wire `win` is rectified by D1/D2 into **two physical rails** — `rA` (push line) and
  `rB` (pull line) — each a boolean "charged / not charged" node. The trit is held at
  the gate boundary as `(rA, rB)`: `(+, 0)` = push, `(0, 0)` = null, `(0, −)` = pull.
  The two rails then gate the two output devices. **DIRECT** — `dd_recv` + `dd_not`
  netlist; the one-hot reading is DERIVED from it.
- The *transport* wire is still **one physical wire, three levels** (`ternary_cell.cir`:
  1.585 bits/wire, no wasted state). The **gate** is where the trit is split into two
  wires — this is exactly the "null is free *on the wire*, expensive *in the gate*"
  boundary that `polar_gates.md` and `diode_gates.md` document.

---

## 6. Receiver diode variants — where the rail voltages come from

The three `.cir` files use three different "diode" models, which is why the rail
assertion appears as different numbers in different docs. All three are the **same
two-opposite-diodes topology**; only the forward drop differs. **DIRECT** from each
netlist's header.

| netlist | rectifier | forward drop | line swing | rail asserts |
|---|---|---|---|---|
| `ternary_cell.cir` | ideal diode `DIDEAL` (`IS=1e-14 RS=50`) | ~0.7 V | ±1.67 V | ±0.48 V |
| `ternary_transistor.cir` | diode-connected NMOS (`VTO=0.30`, W/L=6400) | VTO+Vov ≈ 0.36 V | ±1.22 V | ~0.386 V |
| `diode_gates.cir` (the **gate**) | Schottky `DD` (`IS=1e-9 RS=200 TT=1p CJO=2f`) | ~0.43 V @ 1 mA | ±1.0 V (VDD) | **+0.733 / −0.744 V** |

The gate's Schottky receiver is chosen so the rail asserts **above the 0.4 V dead-zone
floor** (a 500 Ω comm-cell load only reaches ~0.25 V — *not* enough to fire a 1.4 V-Vt
device), which is why the gate uses a 100 kΩ keeper. **DIRECT** — `diode_gates.md` §6
item 1.

---

## 7. Calibration ledger

| claim | calibration |
|---|---|
| device models (`Vt=1.4` N_HI/P_HI, `Vt=0.4` binary, `DD` Schottky, `VDD=1.0`) | **DIRECT** — `diode_gates.cir` lines 88, 99–112 |
| diode directions (`D1 win→rA`, `D2 rB→win`) | **DIRECT** — `dd_recv` lines 116–123 |
| `dd_not` = 2 D + 2 T = 4 devices; binary `inv` = 2 T | **DIRECT** — netlist counts |
| 2.0× / 2.0× / 3.0× device ratios | **DERIVED** — arithmetic on the counts |
| rail asserts `+0.733 V / −0.744 V`, output `±0.976/−0.987 V` | **DIRECT** — `diode_gates.log` `vra_6`, `vrb_4`, `vw_*` |
| null return `−0.025…+0.055 V`; null-idle `1.5–3.8e-19 J / 75 ns` | **DIRECT** — `diode_gates.md` §3 |
| rails range `±0.57/±0.73 V` | **DIRECT** (as quoted) — `fair_binary.md` §4, `radix_lower_bound.md` §2.2 |
| dead-zone width `Vt−VDD = 0.4 V`; `Vgs` null=1.0 V, push=1.73 V | **DERIVED** — arithmetic on DIRECT model + rail values |
| trit = `log₂3 = 1.585` bits; 2 wires → 0.79 bits/wire, +26% | **DIRECT** — `gate_area.md`, `diode_gates.md` §2 |
| receiver diode variants (0.48 / 0.386 / 0.73 V rails) | **DIRECT** — the three `.cir` headers |

---

## Files

- `circuit/diode_gates.cir` / `circuit/diode_gates.log` — the gate netlist and its measurements (rails, energies, truth-table checkpoints).
- `circuit/ternary_cell.cir` — the ideal-diode comm cell (the transport baseline, rail ±0.48 V).
- `circuit/ternary_transistor.cir` — the diode-connected-MOSFET comm cell (rail ~0.386 V).
- `circuit/polar_gates.cir` — the sense-amp (2-threshold) native gates, for contrast with the diode-direction receiver.
- `docs/compute/ground_up/diode_gates.md`, `device_physics.md`, `analog_polar.md` — the measured gate story and the 2-threshold physics.
