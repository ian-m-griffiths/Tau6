# Native Polar-Ternary Cells — transistor/device-level designs (NOT / MIN / MAX / mod-3 sum)

**2026-08-29 — `docs/TERNARY_GROUND_UP.md` batch 1, item 4 ("gate topology") / the
"circuit" angle of the device×3 search.** Companion files, same wave:

- `device_physics.md` — *why* 3 stable states, and what they cost (the free-energy/NDR/Landauer physics).
- `device_literature.md` — *which* devices give 3 states (RTD, CNTFET, SET, IG-FinFET, FeFET, …).
- `minimal_gates.md` — the *minimal set* (`{mod-3 sum, mod-3 product}` + constants) this file must realize.
- `test_suite_spec.md` — the **measurement contract** that would settle these cells once a device model exists.

**This file is a DESIGN TARGET, not a measurement.** It proposes concrete cells, counts
their devices, and reasons about energy/area from the counts and the corpus's measured
anchors — it does **not** run a netlist, because no compact model for the native device
exists yet (`test_suite_spec.md` §1, `meta_critique.md` A8). Nothing here invents a
measured number; every quantitative anchor is tagged.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured/proved in-repo, or a citable literature/textbook identity.
- **ANALOGY** — parallel structure, not identity (e.g. binary dual-rail/DCVS generalized to ternary).
- **OURS** — our design claim; a specific net/count derived here, not yet simulated.
- **SPECULATION** — untested hypothesis, flagged as such.

---

## 0. One-line answer, and the honest constraint it sits on

**A native multi-threshold cell removes the demux + push-pull driver overhead that killed
`polar_gates.md` — NOT collapses 18 T → 4 T, MIN/MAX 44 T → 10 T, mod-3 sum 100 T →
~45 T (or ~8 devices on an RTD) — and it makes the null a genuinely driven, zero-static-
current rest state instead of a meta-stable threshold.** But it does **not** produce a
per-bit *win*: it converts the measured "4.9–14.3× worse per bit" into roughly "1.5–2×
worse per bit," because the two remaining costs are physics, not topology.

The constraint, stated once so it frames everything below **[DIRECT — `device_physics.md`
§2.3, §5; `meta_critique.md` §1; `gates.md` §6]**:

> push/null/pull on **one wire** is a **one-dimensional ordered code** (−V < 0 < +V).
> Any 3 ordered levels need **two decision boundaries** to resolve, whether those
> boundaries are two clocked sense amps (`polar_gates.md`'s demux) or two transistor
> thresholds (this file's multi-Vt). A device can (a) fold the two thresholds into
> transistors cheaply and delete the clock/amplifier/driver around them — **this file does
> that** — but it cannot reduce "two boundaries" to one, and it cannot undo the fact that
> three levels in one swing sit `V_swing/2` apart, which is a noise-margin cost, not an
> encoding cost.

So the three *separate* bets are kept separate, and this file only claims the first:

| bet | what it claims | this file |
|---|---|---|
| remove the **demux+driver overhead** (clock, 2 sense amps, re-encode) | multi-Vt thresholds replace the sense amps; the pull networks *are* the driver | **yes — §2–§5** |
| remove the **meta-stable null** (shoot-through at the SA threshold) | the null is actively driven to 0 V by a mid-level branch, not sampled at a threshold | **yes — §2–§5** |
| remove the **2-threshold information cost** / **3-level noise-margin cost** | (nothing removes these; they are Law 1 + SNR) | **no — honest, §7** |

---

## 1. The device primitive: a multi-threshold "polar FET" (and the RTD alternative)

There is **no single 3-terminal "polar ternary transistor" in any PDK** — that is the
honest headline of `device_literature.md` and it is re-affirmed here. The closest
single-device primitives are:

- **Independent-gate FinFET** — a *production* single transistor with 3 drive-current
  states (both gates off / one on / both on). **[DIRECT — `device_literature.md` §2.5]**
- **Multi-threshold CNTFET** — a FET whose threshold is set by nanotube chirality; the
  standard ternary inverter is 4–6 such FETs of 2–3 chiralities. **[DIRECT — `device_literature.md` §2.2]**
- **2-peak RTD / two series RTDs** — a single structure whose I–V has 3 stable branches
  (two NDR regions → 3 stable load-line crossings). **[DIRECT — `device_physics.md` §0–§1]**

The cells below are written against a **multi-threshold FET** (realized as CNTFET,
IG-FinFET, or multi-Vt/multi-gate CMOS) because that is the fabricable path and the one
whose *mechanism* is the literature's "native ternary gate." The RTD version of the mod-3
sum is given in §5.3 as the "true 3-stable-state" contrast.

### 1.1 The threshold inventory (the whole fabrication cost, up front)

Normalize `Vdd = 1`. Levels are `+1 = +Vdd`, `0 = 0 V`, `−1 = −Vdd`. The cells need
**four threshold flavors** — two elevated-enhancement, two depletion. Each flavor is a
fabrication step (a chirality/diameter in CNTFET, a back-gate bias in IG-FinFET), so the
**count of *flavors*, not just *devices*, is the honest cost**:

| device | threshold | conducts when | what it detects (with source at …) |
|---|---|---|---|
| **N_hi** | `Vtn = +1.5` | `Vgs > +1.5` | "input = +1" (source at −Vdd) |
| **P_hi** | `Vtp = −1.5` | `Vgs < −1.5` | "input = −1" (source at +Vdd) |
| **depN** | `Vtn = −0.5` (depletion) | `Vgs > −0.5` | "input ≥ 0" (source at 0 V) |
| **depP** | `Vtp = +0.5` (depletion, on when `Vgs < Vtp`) | `Vgs < +0.5` | "input ≤ 0" (source at 0 V) |
| **window switch** | depN in series with depP | `−0.5 < Vgs < +0.5` | "input = 0" (2 devices, source at 0 V) |

**[OURS — this specific 4-flavor set; ANALOGY to the literature's 2-chirality STI; the
"two thresholds → three driven levels" mechanism is DIRECT — `device_physics.md` §2.]**

The two loads that matter:

1. **The dead zone.** N_hi's source is at −Vdd, so `Vgs = x + Vdd`; for `x = 0`, `Vgs =
   Vdd < 1.5·Vdd` → **off**. Likewise P_hi at `x = 0` has `Vgs = −Vdd > −1.5·Vdd` → off.
   So a mid-level input turns **both** push and pull devices fully off. That single fact is
   what `polar_gates.md` lacked: its mid input sat a *binary* MOSFET at its threshold and
   drew shoot-through. Here the mid input is a clean dead zone. **[OURS — derived; the
   elevated-|Vt|-for-dead-zone principle is the multi-Vt ternary inverter's mechanism,
   DIRECT — `device_literature.md` §2.2]**
2. **Depletion is required for the mid level.** A FET whose gate is at 0 V cannot conduct
   to a 0 V source unless its threshold is ≤ 0 (depletion N) or its turn-off point is
   ≥ 0 (depletion P). The mid (0 V) output *must* therefore be driven by depletion
   devices, or by a level-shifted source, or by an external mid-rail. **[OURS — derived; the
   tradeoff is DIRECT-flagged in `device_literature.md`: the naive *divider* mid-rail is a
   static Vdd→GND path, and the *external* mid-rail is a third supply.]** This is the
   single biggest fabrication ask of the whole design and is repeated in the TODO tail.

### 1.2 Rest-state rule (null-as-default), applied uniformly

Every cell below is a **3-branch complementary network**: a `+1` branch (P devices to
+Vdd), a `−1` branch (N devices to −Vdd), and a `0` branch (depletion devices to 0 V).
For every input combination **exactly one branch conducts**, so:

- the output is a hard rail (+Vdd / 0 / −Vdd), never a floating or threshold-sitting node;
- there is **no static current in any of the 3 states** (each branch is at equilibrium with
  its own rail when on, and off when not);
- the all-null idle (`(0,0)` inputs, or `0` for NOT) propagates null → null through every
  gate with zero current. **[OURS — this is the property `null_default.md` sets as the goal
  and `test_suite_spec.md` §6 turns into a measurement; it is *asserted here, not measured*.]**

---

## 2. NOT (negation / STI) — **4 devices** vs 18 T

Truth table **[DIRECT — `gates.md` §2, `test_suite_spec.md` §2]**: `−1→+1, 0→0, +1→−1`.

```
             +Vdd
              │
              │▸ P_hi   (gate = IN)   on iff IN = −1
              │
    IN ───────┼──────────────────────────── OUT
              │
              │▸ N_hi   (gate = IN)   on iff IN = +1
              │
             −Vdd

   0-branch (window switch, conducts iff IN = 0):
       OUT ── depN(g=IN) ── n1 ── depP(g=IN) ── 0 V
```

**Count: 4 devices** (N_hi, P_hi, depN, depP) — the *same* four threshold flavors, used
once each. **[OURS — this net; ANALOGY/DIRECT to the literature's 4–6 CNTFET STI,
`device_literature.md` §2.2, `minimal_gates.md` §4b.]**

**3-state mechanism:** N_hi and P_hi form a push-pull pair whose elevated `|Vt| = 1.5·Vdd`
puts the mid input (0 V) in a dead zone (both off). The window switch (depN + depP in
series) is the third, mid-level driver: it conducts *only* when IN = 0, pulling OUT to 0 V.
So the three levels are produced by three distinct device paths, with no sense amp and no
separate driver — the two rail FETs *are* the driver.

**Rest state:** `IN=0 → P_hi off, N_hi off, window on → OUT = 0 V, zero current`.
`IN=+1 → N_hi on → OUT=−Vdd, window open (depP off)`. `IN=−1 → P_hi on → OUT=+Vdd, window
open (depN off)`. No state draws static current; null is the default. **[OURS — asserted,
to be confirmed by the `test_suite_spec.md` null-at-threshold probe.]**

**vs baseline:** the measured polar NOT was 18 T = 2 sense amps (14 T) + inverter (2 T) +
push-pull driver (2 T), with *zero* transistors of logic — the demux + re-encode was the
entire cost **[DIRECT — `polar_gates.md`]**. The native cell is **4 devices → 4.5× fewer**,
and it deletes the clocked sense amps and the re-encode driver entirely.

---

## 3. MIN (meet / ternary AND) — **10 devices** vs 44 T

Truth table **[DIRECT]**: `min(x,y)` over the order `−1 < 0 < +1`.

Branches (dual-rail: complements `x̄ = NOT(x)`, `ȳ = NOT(y)` are available on the bus):

```
  +1 branch (P devices from +Vdd, low-active gates):
      +Vdd ── P_hi(g=x̄) ── P_hi(g=ȳ) ── OUT      on iff x=+1 AND y=+1      (2 devices)

  −1 branch (N devices from −Vdd, high-active gates):
      −Vdd ── N_hi(g=x̄) ── OUT                    on iff x=−1 OR y=−1       (2 devices)
      −Vdd ── N_hi(g=ȳ) ── OUT

   0 branch (depletion devices from 0 V):
      0V ──[depN(g=x)+depP(g=x)]──[depN(g=y)]── OUT     x=0 AND y≥0           (3 devices)
      0V ──[depN(g=y)+depP(g=y)]──[depN(g=x)]── OUT     y=0 AND x≥0           (3 devices)
```

**Count: 10 devices** (2 + 2 + 6). **[OURS — this net.]** If complements are *not* already
on the bus, add two STIs (§2) → **18 devices single-rail, still 2.4× fewer than 44 T**.

**3-state mechanism:** the same dead-zone discipline, generalized to two inputs. The +1
branch needs "both inputs high"; a P-FET turns on for a *low* gate, so the branch is gated
by the complements `x̄, ȳ` (which are low exactly when `x, y` are +1) — this is the binary
dual-rail/DCVS trick carried to three levels **[ANALOGY]**. The −1 branch needs "either
input low"; N-FETs turn on for a high gate, so again the complements make it work. The 0
branch is the only place mid-level detection happens, and it lives entirely in the 0 V rail
where the depletion window switches belong: `x=0` (window) AND `y≥0` (single depN), OR the
mirror.

**Rest state:** the three branch conditions partition all 9 input pairs exactly (verify:
+1 branch = {(1,1)}; −1 branch = any pair with a −1; 0 branch = {(0,0),(0,1),(1,0)}), so
exactly one branch conducts per pair, no contention, no static current. The all-null idle
`(0,0)` → 0 branch → OUT = 0 V. **[OURS — asserted.]**

**vs baseline:** the measured polar MIN was 44 T = 4 sense amps (28 T) + and2 + or2 + inv +
driver **[DIRECT — `polar_gates.md`]**. Native = **10 devices → 4.4× fewer** (dual-rail) or
18 → 2.4× (single-rail).

---

## 4. MAX (join / ternary OR) — **10 devices** vs 44 T

Truth table **[DIRECT]**: `max(x,y)`. Exact mirror of MIN:

```
  +1 branch (P, low-active):  +Vdd ── P_hi(g=x̄) ── OUT     on iff x=+1 OR y=+1   (2 devices)
                              +Vdd ── P_hi(g=ȳ) ── OUT

  −1 branch (N, high-active): −Vdd ── N_hi(g=x̄) ── N_hi(g=ȳ) ── OUT   on iff x=−1 AND y=−1  (2 devices)

   0 branch (depletion, 0 V): 0V ──[depN(g=x)+depP(g=x)]──[depP(g=y)]── OUT    x=0 AND y≤0   (3 devices)
                              0V ──[depN(g=y)+depP(g=y)]──[depP(g=x)]── OUT    y=0 AND x≤0   (3 devices)
```

**Count: 10 devices. vs baseline 44 T → 4.4× fewer (dual-rail) / 2.4× (single-rail).**
Mechanism and rest-state analysis are the mirror of §3; the only change is that the 0
branch's "≥0" detectors become "≤0" detectors (single depP instead of single depN). **[OURS.]**

---

## 5. mod-3 sum (F₃ addition, "ternary XOR") — the hard cell, **~45 T (TLG) / ~8 devices (RTD)** vs 100 T

Truth table **[DIRECT — `test_suite_spec.md` §2, `gates.md`]**: `s = (a+b) mod 3`,
carry dropped — `+1+1→−1, +1+0→+1, +1−1→0, 0+0→0, 0−1→−1, −1−1→+1`.

### 5.1 Why it is *not* a clean static 3-branch network (the honest structural fact)

`s = +1` holds for `(x=−1,y=−1)` **and** `(x=0,y=+1)` **and** `(x=+1,y=0)`. The first
term is pure low-detection (P_hi works); the last two **AND a mid-detection (`x=0`) with an
extreme-detection (`y=+1`) inside the same branch**. Mid-detection lives only in the 0 V
rail (depletion window switch), extreme-detection lives only in the ±Vdd rails — a single
static branch cannot hold both at once without a level translation. **[OURS — derived; this
is the *reason* the literature builds the ternary adder as a holistic threshold cell rather
than a pass/parallel FET network — `minimal_gates.md` §4b, `Automated_synthesis`.]**

So the honest answer for the sum is: **do not build it as a static complementary network.**
Two physically-grounded alternatives follow.

### 5.2 Ternary threshold-logic gate (TLG) — the fabricable native cell

A **multi-Vt threshold gate** computes, in one cell, a weighted digit-sum against
thresholds. The mod-3 sum and its carry are exactly threshold functions of the digit sum
`σ = x + y ∈ {−2,−1,0,+1,+2}`:

- carry `c`: `+1 iff σ ≥ +2` (i.e. `σ=+2`), `−1 iff σ ≤ −2` (`σ=−2`), else 0;
- sum `s`: the wrap of `σ` around the balanced digit grid.

This is precisely the gate the multi-Vt threshold literature reports as the *native winner*:
the ternary threshold gate beats CMOS on **STI, comparator, XOR (= mod-3 sum), and half-adder
while AND/OR lose** (the clocked threshold gate carries a flip-flop the min/max gates don't
amortize) **[DIRECT — `2211.12176`, cited in `gates.md` §6b and `minimal_gates.md` §4b]**.

**Count:** the corpus's best cited ternary half-adder (sum+carry) is **45 CNTFETs**
(`2211.04542`, "85/90/**45**"); the 3-sum cell is 150 and the 3-operand balanced full adder
118–188 **[DIRECT — `minimal_gates.md` §4b, `gates.md` §5b]**. Against the 100 T baseline,
the TLG mod-3 sum is **~45 devices → ≈2.2× fewer**, and the corpus's headline is a
power–delay *win* (the 3-operand hybrid full adder's 1.10e-15 J vs 1.44e-15 J for 2-operand
composition @ 500 MHz) — i.e. build the sum as **one holistic 3-input threshold cell**, not
a chain of 2-input gates **[DIRECT — `Automated_synthesis`]**. A clean single-cell *schematic*
is **not drawn here** because the threshold-gate internals are a weighted-current-sum +
thresholding topology whose exact device net is in `2211.12176`, not re-derivable from our
corpus without risking fabrication — this is an explicit TODO, not a silent gap. **[OURS —
the decision to defer the net; the mechanism/count are DIRECT.]**

### 5.3 RTD tristable quantizer — the true 3-stable-state alternative

A **2-peak RTD** (or two series RTDs) has three stable load-line branches; the output
*is* one of three states by physics, with a restoring force (a real local minimum at each
level), not a held rail **[DIRECT — `device_physics.md` §0–§1]**. A small steering network
(few-FET) computes the digit sum polarity and pushes the midpoint to the nearest stable
branch → the sum appears. **Order ~6–10 devices** (2 RTDs + 4–6 FETs), the only cell here
where "3 stable states" is literally true.

**The two honest catches, carried from `device_physics.md` §1.3:** (i) an NDR latch is an
*active* element — DC-biased it draws **static current in every state including idle**, so it
violates "0 V, no current at rest" unless it is clocked (MOBILE-style bias ramp); (ii) it is
III-V, not CMOS, so the ~12× device-count win is against a part with no VLSI path. **[DIRECT
physics / SPECULATION as a fab cell — the same calibration as `device_literature.md` §2.1.]**

**vs baseline:** the measured polar mod-3 sum was 100 T = 4 sense amps (28 T) + 2 nor2 + 6
and2 + 2 or3 + inv + driver **[DIRECT — `polar_gates.md`]**. Native = **~45 T (TLG) → 2.2×
fewer**, or **~8 devices (RTD) → 12× fewer but unfabricable + DC-hungry**.

---

## 6. Summary table

Counts are **devices per cell**; "baseline" is the measured 2-level-MOSFET polar gate
**[DIRECT — `polar_gates.md`]**. "×" = baseline ÷ native.

| gate | native cell | devices | baseline | ratio | null-as-default? | main new cost |
|---|---|---|---|---|---|---|
| **NOT** | dead-zone push-pull + window switch (§2) | **4** | 18 T | **4.5×** | yes (0 V driven, 0 A) | 4 Vt flavors incl. 2 depletion |
| **MIN** | dual-rail 3-branch (§3) | **10** (18 single-rail) | 44 T | **4.4×** (2.4×) | yes | complements on bus (dual-rail) |
| **MAX** | mirror of MIN (§4) | **10** (18) | 44 T | **4.4×** (2.4×) | yes | same |
| **mod-3 sum** | ternary TLG (§5.2) | **~45** | 100 T | **~2.2×** | yes (mid threshold driven) | holistic 3-input cell; net deferred |
| **mod-3 sum** | RTD tristable quantizer (§5.3) | **~8** | 100 T | **~12×** | **no** (DC bias unless clocked) | III-V; NDR static current |

All five native cells have the property the whole search is about: **no clocked sense-amp
demux and no separate push-pull re-encode driver** — the thresholds and the drive are both
inside the device network. **[OURS — the design's claim; the counts are not measured.]**

---

## 7. Energy & area — what can and cannot be said

### 7.1 Area

**Transistor/device count is the only honest proxy until a per-device area exists**
(`test_suite_spec.md` §4.5). On that proxy the native cells are **2.2–4.5× smaller** than the
2-level polar gate (table above). Two corrections, both flagged, both unquantified:

- **count ≠ area.** A CNTFET/RTD may be physically larger per device than a MOSFET, so
  "4.5× fewer devices" is an upper bound on the area win, not the area win itself.
  **[ANALOGY — `device_literature.md` §1]**
- **flavors ≠ area but they are real cost.** The 4 threshold flavors (incl. 2 depletion) are
  fabrication steps (chirality classes / back-gate biases) that don't show in a device
  count. **[OURS]**

The one *structural* area win that does transfer: the polar gate's 14 T of matched-pair
sense amps per input (and their common-centroid layout) and the re-encode driver are
**gone**, not just shrunk. **[DIRECT — `polar_gates.md` breakdown; OURS — that removing them
shrinks area.]**

### 7.2 Energy

The measured polar-gate energy loss (4.9–14.3×/bit) was dominated by three things the
native cell removes **[DIRECT — `polar_gates.md`, `gate_energy.md`]**:

1. the **2 clocked sense amps per input** (2.54× receiver tax, measured) — replaced by transistor thresholds;
2. the **push-pull re-encode driver** — absorbed into the pull networks;
3. the **meta-stable null** (~1.9 pJ/toggle shoot-through on held-null inputs, measured) — removed, because 0 V is now actively driven from a dead zone, not sampled at a threshold.

So a static multi-Vt cell should land in the **ordinary static-CMOS `½CV²`-per-toggle
class**, not the `1465–4885 fJ/toggle` of the clocked-demux gates. **[OURS — this is the
design's energy claim; it is *derived*, not measured.]**

What the native cell does **not** remove, and why it still loses per bit **[DIRECT —
`device_physics.md` §2.3, §5; `gate_energy.md`]**:

- **3-level noise margin.** Adjacent levels sit `V_swing/2` apart; holding a fixed BER
  forces a larger swing or larger C — roughly a ~2× energy-per-bit penalty vs binary.
- **The 2-threshold information cost** (Law 1) persists: you still extract `log₂3 = 1.585`
  bits through two boundaries. Folding them into transistor thresholds removes the *overhead*
  of the boundaries, not the boundaries themselves.

**Net energy estimate:** ~1.5–2× binary **per bit**, i.e. the demux overhead (4.9–14.3×)
collapses but no win appears. This matches the corpus's standing verdict
(`meta_critique.md`: "multi-Vt CMOS is the 2-threshold tax in device form"). **[OURS/SPECULATION
— scaling argument from DIRECT anchors; not a measurement.]**

### 7.3 What would flip the verdict (the go/no-go criterion)

The only way a native device *wins* is to resolve 3 states in **fewer than 2 thresholding
measurements** or make the null genuinely free **inside the gate** — and push/null/pull on
one ordered axis cannot do the former by construction. **[DIRECT — `meta_critique.md` §1, §4
(A4).]** The cells here win the *overhead* battle and lose the *information* battle; that is
the honest state of the art, and `test_suite_spec.md` is the contract that turns "derived"
into "measured."

---

## 8. Calibration ledger

| claim | calibration |
|---|---|
| 18/44/44/100 T baseline; 4.9–14.3×/bit loss; meta-stable null; 2-sense-amp demux | **DIRECT** — `polar_gates.md` (measured) |
| 2.54× receiver tax; 2.00–4.33× area tax; ½CV² static-CMOS framing | **DIRECT** — `gate_energy.md`, `gate_area.md` |
| 3 stable states = 3 free-energy minima; 2 NDRs → 3 states; Landauer `kT ln 3` = 4.55 zJ = 1.585 bits; 3-level SNR penalty | **DIRECT** — `device_physics.md` |
| multi-Vt CNTFET/IG-FinFET/RTD devices exist with the mechanisms used | **DIRECT** — `device_literature.md` |
| literature STI = 4–6 CNTFETs; THA = 45; balanced FA = 118–188; TLG beats CMOS on XOR/THA | **DIRECT** — `2211.04542`, `2211.12176`, `Automated_synthesis` (via `gates.md`, `minimal_gates.md`) |
| the 4-flavor threshold inventory (N_hi/P_hi/depN/depP) | **OURS** |
| NOT = 4 devices (§2); MIN = MAX = 10 devices (§3–§4) | **OURS** — nets derived here, not simulated |
| dual-rail needed for clean MIN/MAX (complements on bus) | **OURS** — derived; **ANALOGY** to binary dual-rail/DCVS |
| static 3-branch cannot express mod-3 sum (mid⊗extreme cross-rail) | **OURS** — derived structural fact |
| mod-3 sum as TLG ≈45 devices, RTD quantizer ≈8 devices | **DIRECT** count for TLG / **SPECULATION** for the RTD cell |
| "no static current in any state; null is the default rest state" | **OURS** — asserted; the measurement is `test_suite_spec.md` §4.4/§5.2 |
| energy ≈1.5–2× binary per bit after overhead removal | **OURS/SPECULATION** — scaling, not measurement |

---

## TODO / not covered / caveats

1. **Nothing here is simulated.** All four nets are design targets. The blocker is
   `test_suite_spec.md` §1: **no compact model** for a multi-Vt CNTFET / IG-FinFET / RTD
   exists in our ngspice harness (LEVEL=1 MOSFET models cannot express NDR or multiple Vt),
   so every energy and "no static current" claim is unverified. **Next step is a device
   model, then the `test_suite_spec.md` fair-fight — not more counting.**
2. **The 4 threshold flavors are the real fabrication risk, and 2 of them are depletion.**
   A mid-level output from a mid-level gate voltage *requires* depletion-mode (normally-on)
   devices, or a level-shifted source, or an external mid-rail. Depletion CNTFETs are
   plausible (doping/workfunction) and IG-FinFET back-gate bias can shift Vt, but **I have
   not confirmed a depletion multi-Vt device in a foundry flow**. If it does not exist, the
   mid level falls back to the *divider* (static Vdd→GND current — re-introduces the exact
   "no current at rest" failure) or the *external mid-rail* (a third supply). This is the
   single most likely thing to kill the whole design.
3. **The mod-3 sum net is deferred, not solved.** §5.2 gives the mechanism and the
   literature's count (~45 CNTFET THA) but **not** a drawn, counted single-cell schematic —
   re-deriving the `2211.12176` threshold-gate internals from our corpus would risk
   fabricating a net. Pull the primary source and draw it before quoting the sum as "native".
4. **The `~1.5–2× per bit` energy figure is a scaling argument, not a number.** It rests on
   "static multi-Vt ≈ static CMOS ½CV², minus the measured demux/SA/null overhead, plus the
   measured 2.54×/noise-margin penalties." It could be off by a factor of ~2 either way.
   Do not use it as a spec until `test_suite_spec.md` §8 fills the table.
5. **Dual-rail costs are not counted.** MIN/MAX assume complements `x̄, ȳ` are free on a bus;
   single-rail adds 8 devices (2 STIs). Dual-rail also doubles the wire count per trit — a
   routing cost `gate_area.md` flags as the 2-wire encoding's 26% waste. The "10 T" number
   is the *marginal* cell cost, not the loaded per-signal cost.
6. **RTD "no current at rest" is not met.** The tristable quantizer's stable points sit on a
   DC-biased I–V; it holds state *with* current unless clocked (MOBILE). It is included as
   the physics reference for "true 3-stable-state," not as a null-as-default cell.
7. **Area is count-only.** No per-device µm² exists for CNTFET/IG-FinFET/RTD in our corpus;
   "4.5× smaller" is a device-count ratio, and a physically-larger native device would
   shrink it (`test_suite_spec.md` §4.5). **PENDING.**
8. **The 2-threshold information cost and the 3-level noise-margin cost are not addressed**
   — by design (§0). A reader wanting a *win* must look elsewhere (reversible/adiabatic
   ternary, or the transport layer where the null is already free), not here.
9. **No variability/mismatch/ECC analysis.** Vdd/4-level margins, device Vt spread, RTN,
   aging, and SEU are unexamined and are ~2× worse for 3 levels than 2
   (`meta_critique.md` §3g, `storage.md` §1). A cell that can't meet margin is dead
   regardless of its count.
10. **No synthesis/mapping path.** Even if a cell wins per-gate, there is no liberty/yosys/
    PnR/STA story for a multi-Vt ternary cell — the same wall CNTFET hit at ~15K transistors
    (`meta_critique.md` §3f). A per-gate win without a synthesis path is unactionable.
11. **Single-ended static CMOS is only one topology.** Ternary pass-transistor logic, the
    current-mode threshold gate, and cross-coupled (DCVS-style) ternary are alternatives not
    drawn here; some may dodge the depletion requirement at a different cost (level
    restoration, swing loss). Worth a topology survey before committing to §2–§4.
12. **mod-3 *product* (`tmul`) is not in the requested set** but is the other half of the
    complete F₃ pair (`minimal_gates.md`); without it the completeness claim is untestable
    in silicon, however clean the four cells here are.

---

## In-tree anchors (what these counts compare against)

- `docs/compute/polar_gates.md` — the measured 18/44/100 T baseline and the demux+null failure this file removes.
- `docs/compute/gate_energy.md` / `gate_area.md` — the measured 2.54× receiver tax and 2.00–4.33× area tax.
- `docs/compute/ground_up/device_physics.md` — 3 stable states, NDR counting, Landauer `kT ln 3`, noise-margin cost.
- `docs/compute/ground_up/device_literature.md` — the device shortlist (IG-FinFET, CNTFET, RTD) this file's primitives draw on.
- `docs/compute/ground_up/minimal_gates.md` — the minimal set `{⊕, ⊗}` this file's cells must realize; the CNTFET THA/FA counts.
- `docs/compute/ground_up/null_default.md` — the null-as-default target these cells are meant to satisfy.
- `docs/compute/ground_up/test_suite_spec.md` — the measurement contract (device model, fair-fight, pass/fail) that would settle this file.
- `docs/compute/ground_up/meta_critique.md` — the go/no-go criterion (multi-Vt = 2-threshold tax in device form) this file's §0/§7 accept.

*Every count in this file is a device count of the schematic drawn (or a literature count
explicitly cited); every energy/area number is a scaling argument from the corpus's measured
anchors. No measurement of a native 3-state device was performed or invented.*
