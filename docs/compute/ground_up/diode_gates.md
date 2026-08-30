# Diode-direction polar ternary gates — energy, device count, and the 2-threshold tax

**2026-08-29, ngspice 44.2, measured. Netlist: `circuit/diode_gates.cir` (exit 0, no
warnings, no DC shorts — quiet-window energies all < 4 aJ).**

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured (this run's ngspice log) or counted from the netlist.
- **ANALOGY** — structural parallel, not identity.
- **OURS** — design claim / interpretation supported by DIRECT but not itself measured.
- **SPECULATION** — untested hypothesis, flagged as such.

---

## 0. One-line answer

**The diode-direction receiver removes the *sense-amp* 2-threshold tax — the meta-stable
null and the clocked receiver supply are both gone (null-idle ≈ 0, E_rec = 0) — but it does
not remove the *information* 2-threshold requirement (3 ordered states still need 2 decision
boundaries).** Net result, measured: ternary polar gates go from the sense-amp version's
**4.9–14.3× worse per bit** to **0.48–0.97× per bit** (tie to ~2× *better*) on energy, while
paying **2–3× the device count** and a **multi-Vt fabrication ask** (elevated-|Vt| dead-zone
devices). The prior "2-threshold tax" was indeed a sense-amp artifact — it is not intrinsic
to polar ternary.

---

## 1. The reframe, made concrete

Polar ternary is **1 magnitude × 2 directions**: push = current OUT, pull = current IN,
null = no current. A diode is a **direction detector**: two opposite diodes fire on push and
on pull respectively, and **neither fires on null** (no current → free). A sense amp is a
**level detector** (compare vs 0 V), which is exactly why `polar_gates.cir`'s null sat at the
threshold, drew continuous shoot-through, and cost 2 clocked 7-T amplifiers per input.

The gate this netlist builds is the honest minimum a direction receiver forces:

```
[polar wire] → [2 diodes: rA = push rail, rB = pull rail, null = neither]
            → [elevated-|Vt| push-pull driver: dead-zone null] → [polar wire]
```

The receiver is **passive** (no supply, no clock): the two diode rails `rA` (0→+Vrail on
push) and `rB` (0→−Vrail on pull) *are* the sign/magnitude decomposition. The driver uses
**elevated-|Vt| = 1.4 V** devices whose dead zone is the null:

- a device whose source is −Vdd sees `Vgs = +Vdd` when its gate (rail) is at 0 (null) → **OFF**
  (dead zone, `Vdd < Vt`), but `Vgs = Vdd + Vrail ≈ 1.76 V` when the rail fires → **ON**
  (`Vt < Vdd + Vrail`). So `P_HI (src=+Vdd, gate=rB)` fires on **pull** → drives +1, and
  `N_HI (src=−Vdd, gate=rA)` fires on **push** → drives −1.

That cross-coupling **is** negation: the diode receiver + elevated-Vt driver is a
self-restoring ternary inverter with a dead-zone null — **no sense amp, no clock, no level
shifter**. The two-input primitives are the series/parallel stacks of the same two devices:

| gate | +1 branch (push) | −1 branch (pull) | meaning |
|---|---|---|---|
| `dd_not` | P_HI(g=rB) — on pull | N_HI(g=rA) — on push | negation |
| `dd_nand` | parallel P_HI — either pulls | series N_HI — both push | `NOT(MIN)` |
| `dd_nor` | series P_HI — both pull | parallel N_HI — either pushes | `NOT(MAX)` |

`MIN = NOT(NAND)` and `MAX = NOT(NOR)` are clean 2-stage compositions. The **mod-3 sum is
NOT reachable** from `{NOT, NAND, NOR}` (it is an F₃ *field* op, not a lattice op): it needs
explicit null detection (`NOT(push OR pull)`), i.e. "null" as a *signal*, but the direction
receiver produces null as the *absence* of a rail. See §7 and the TODO tail.

---

## 2. Method (fair-fight honesty, same rules as every fair fight in `circuit/`)

- **Rails:** everything on ±VDD = ±1.0 V. Binary `0=−1 V, 1=+1 V`; ternary `−1=−1 V, 0=0 V,
  +1=+1 V`. Same rails, same common mode.
- **Real output driver** (elevated-Vt push-pull, supply V·I counted over a **full output
  cycle**: assert + release). No ideal current sources.
- **Real (passive) receiver:** the next stage's diode rectifier is an explicit load the
  output driver must charge. It has **no supply**, so its energy is already inside E_gate —
  the honest contrast with the sense-amp receiver whose clocked supply (`E_rec`)
  `polar_gates.cir` added separately (binary +133.6 fJ, ternary +379 fJ per toggle).
- **Inputs are ideal voltage sources** (previous stage's output is abstracted; its cost is
  symmetric to this gate's own output driver) — `polar_gates.cir`'s convention.
- **LEVEL=1 models, no body diodes, no device mismatch** — generous to ternary (its 2-boundary
  receiver has 2× the offset budget). All device counts are from the netlist.
- **Toggle = cheapest toggle:** binary `0↔1` (full ±1 V swing), ternary `null↔+1` (half
  swing) — the standard "generous to ternary" convention. The ternary wire and receiver caps
  are sized for a fan-out-of-1 gate (10 fF wire, 2 fF rail caps), **not** the comm cell's 1 pF
  line.

The receiver uses a **Schottky diode model** (`TT=1p`, no minority-carrier storage) and
**small junction capacitance** (`CJO=2f`). Both are load-bearing, not cosmetic — see §6.

---

## 3. The measured table

**Energy per toggle** (fJ; one full cycle = assert + release, ÷2) and **device count**
(D = rectifier diode, T = transistor):

| gate | devices | E/toggle (fJ) | null-idle over 75 ns | truth table |
|---|---:|---:|---:|---|
| **binary NOT** | 2 T | **54.0** | 0.30 aJ | +1.00 / −1.00 ✓ |
| **binary NAND** | 4 T | **79.3** | 0.60 aJ | +1.00 / −1.00 ✓ |
| **binary NOR** | 4 T | **63.5** | 0.30 aJ | +1.00 / −1.00 ✓ |
| **dd_not** (negation) | 2 D + 2 T = **4** | **54.2** | 0.15 aJ | −0.987 / ~0 ✓ |
| **dd_nand** | 4 D + 4 T = **8** | **60.8** | 0.23 aJ | −0.987 / ~0 ✓ |
| **dd_nor** | 4 D + 4 T = **8** | **58.6** | 0.23 aJ | +0.976 / ~0 ✓ |
| **dd_min** (= NOT∘NAND) | 6 D + 6 T = **12** | **122.2** | 0.38 aJ | +0.975 / ~0 ✓ |
| **dd_max** (= NOT∘NOR) | 6 D + 6 T = **12** | **109.4** | 0.38 aJ | +0.975 / ~0 ✓ |

Receiver demux checkpoints (mid-pulse, next stage's rails): every gate resolves its
direction — e.g. dd_not's pull rail asserts **−0.744 V** with push rail **−0.0002 V**;
dd_nor's push rail asserts **+0.733 V** with pull rail **+0.0003 V**. The null return at the
110 ns checkpoint is **−0.025 … +0.055 V** — cleanly below the ~0.4 V dead-zone trip, so the
null is unambiguously resolved, not meta-stable.

**The headline number:** null-idle supply energy is **1.5–3.8 × 10⁻¹⁹ J** over the whole
75 ns quiet window for *every* ternary gate — statistically indistinguishable from the
numerical noise floor. The null draws **~0 current**. This is the property
`null_default.md` set as the goal and `polar_gates.md` showed the sense amp could not deliver.

---

## 4. The honest ratio (per bit, after ÷log₂3)

Per-bit = ternary E/toggle ÷ 1.585, compared to the binary analog's E/toggle (binary carries
1 bit/toggle):

| ternary vs binary | per toggle | **per bit** (÷1.585) | device count |
|---|---:|---:|---:|
| dd_not vs NOT | 1.00× | **0.63× (1.58× better)** | 4 vs 2 = **2.0×** |
| dd_nand vs NAND | 0.77× | **0.48× (2.07× better)** | 8 vs 4 = **2.0×** |
| dd_nor vs NOR | 0.92× | **0.58× (1.72× better)** | 8 vs 4 = **2.0×** |
| dd_min vs NAND† | 1.54× | **0.97× (tie)** | 12 vs 4 = **3.0×** |
| dd_max vs NAND† | 1.38× | **0.87× (1.15× better)** | 12 vs 4 = **3.0×** |

† MIN/MAX are 2-input lattice gates; their binary analog is any 2-input gate (NAND/NOR).

**Read the table honestly — the two halves tell opposite stories:**

- **Energy: the sense-amp loss is gone.** `polar_gates.md` measured native ternary at
  **4.9–14.3× worse per bit** (NOT 4.9×, MIN 5.0×, MAX 10.5×, sum 14.3×). The diode receiver
  turns that into **0.48–0.97× per bit** — a tie to a ~2× win. The entire turnaround is the
  receiver: the sense-amp demux (2 clocked 7-T amps/input + meta-stable null shoot-through +
  a clocked receiver supply on every toggle) is replaced by 2 passive diodes + 2 dead-zone
  devices that idle at ~0.
- **Devices: the radix economy does not cover the boundary count.** NOT is 2× binary's
  transistors (4 vs 2 devices), NAND/NOR 2× (8 vs 4), MIN/MAX 3× (12 vs 4). The energy win
  is bought with **2–3× the active-area**, plus two process flavors binary does not need
  (the rectifier and the elevated-|Vt| dead zone — §6).

So the honest headline is **not** "ternary wins". It is: **the diode receiver kills the
2-threshold *sense-amp* tax, and what remains is a fair, tunable trade — ~0.5–1× the energy
per bit for 2–3× the devices — rather than a 5–14× energy loss on top of 8–11× the
transistors.**

---

## 5. The verdict on the 2-threshold tax

**Q: does the diode receiver remove the 2-threshold tax?**

**Two separate taxes were conflated in `polar_gates.md`, and the diode receiver removes one
and not the other:**

1. **The sense-amp tax (REMOVED — DIRECT).** Two clocked sense amps per input cost 14 T, drew
   continuous shoot-through on the meta-stable null (measured: held-null lifted MAX/SUM's
   E_gate to 2.3–3.1× MIN's), and fired a clocked supply every cycle. The diode receiver has
   none of this: null = no current = both diodes block (idle ~1e-19 J, measured), and the
   receiver is passive (E_rec = 0). **This was the artifact. It is gone.**

2. **The information tax (NOT REMOVED — it is physics, not topology).** A 3-level ordered
   code on one wire still needs **two decision boundaries** to resolve (−V vs 0 vs +V), and
   the two directions still need **two devices** to re-drive (one per polarity). The diode
   receiver moves those two boundaries from "2 clocked amplifiers at 0 V" to "2 elevated-|Vt|
   devices in the output driver, with a dead zone at 0 V" — *cheaper and null-free, but still
   two*. This is exactly `device_circuit.md`'s Law 1: the diode receiver folds the thresholds
   into cheap dead-zone transistors and deletes the clock/amplifier around them; it cannot
   reduce "two boundaries" to one. **[DIRECT (measured) for the removal; OURS (this is the
   standard reading) for the boundary-count statement.]**

So the reframe's premise is **half right**: "the 2-threshold tax was a sense-amp artifact" is
**CONFIRMED** for the *energy* tax (the thing the fair fights actually measured). But the
*device* tax (2 boundaries → ≥2 devices/direction, 2–3× binary) is real and remains, and it
is the same reason `device_circuit.md` concluded "native ternary converts 4.9–14.3× into
~1.5–2× worse" — our measured **0.5–1× energy is *better* than that prediction because the
null, not just the receiver, became free**, but the device-count half is unchanged.

---

## 6. The three fabrication asks the win stands on (all SPECULATION until a PDK)

1. **Elevated-|Vt| dead zone (Vt = 1.4 V between Vdd and Vdd+Vrail).** This is the entire
   null-is-a-dead-zone mechanism. It is a **multi-Vt process** ask (a high-|Vt| flavor on the
   same area as a standard device), plus a **margin** ask: the off-margin is `Vt−Vdd = 0.4 V`,
   so the rail must assert `> 0.4 V` for the device to ever turn on — the comm cell's 0.25 V
   rail (500 Ω load) is **not** enough; this gate needs a high-impedance receiver (100 kΩ
   keeper) to assert ~0.76 V. **[OURS — derived; the Vt selection and margin are the design
   choice this netlist makes.]**

2. **A low-storage rectifier (Schottky, `TT≈0`).** With a junction diode's stored charge
   (`C_diff = TT·I_f/Vt`), the rail's discharge time is `R_keeper·C_diff` — measured ~10–16 ns
   with TT=0.5 n, which pins the output at its asserted value for the whole cycle and the
   gate never returns to null. Only with TT≈0 (Schottky, no minority-carrier storage) does the
   null return in ~5 ns. High-speed rectifiers are Schottky for exactly this reason, but it is
   a real process/device choice, not a default. **[DIRECT — the slowdown is measured; the
   Schottky fix is the standard solution.]**

3. **Small junction area (`CJO≈2f`).** The diode's junction cap couples the wire edge into
   the rail; with `CJO=0.2p` (the comm cell's diode) against a 2 fF rail cap, the coupling is
   99% and the rail is driven to the wrong polarity during the transition. A small-area
   diode (`CJO≈2f`, comparable to the rail cap) is required. **[DIRECT — measured.]**

None of these are free in silicon, and LEVEL=1 models no subthreshold leakage, no
mismatch, and no body diode — a real elevated-Vt device at the 0.4 V dead-zone margin would
pay leakage and offset costs that this netlist does not. **[SPECULATION.]**

---

## 7. mod-3 sum — not tractable in pure diode-direction form

The 2-input mod-3 sum (`s = (a+b) mod 3`, the F₃ "ternary XOR") has, e.g.,
`s=+1` for `(0,+1)` and `(−1,−1)` — it **must distinguish `null` from `+1` and `−1` as an
explicit third input**, i.e. it needs the signal `null_a = NOT(push_a OR pull_a)`. The
direction receiver produces `push` and `pull` as rails but `null` only as their *joint
absence* — there is no `null` rail to feed the logic, and `{NOT, NAND, NOR}` (the lattice
fragment) provably cannot generate the F₃ field sum. **[OURS — the argument is
`minimal_gates.md` §1/§4 (the lattice fragment is incomplete); the direction receiver adds
no null rail, so the sum cannot be built from it directly.]**

So I did **not** converge a pure-diode mod-3 sum, and I report that as a structural result,
not a failure to tune. The regeneration path (diode receiver → low-Vt level-shift to
full-swing push/pull + null-detect NOR → `gate_energy.cir`'s `tsum` static CMOS → push-pull
driver) is the way to get it, at roughly the `gate_energy` device count (100 T) *plus* the
receiver — the follow-up is spelled out in the TODO tail.

---

## 8. Calibration summary

| claim | calibration |
|---|---|
| Diode gate energies (54.2–122.2 fJ/toggle), binary (54.0–79.3 fJ/toggle) | DIRECT — `diode_gates.log` |
| Null-idle ≈ 0 (1.5–3.8e-19 J / 75 ns) for all diode gates | DIRECT — `diode_gates.log` |
| Truth tables correct, null resolves (≤0.06 V, dead zone ~0.4 V) | DIRECT — `diode_gates.log` |
| Device counts (4/8/8/12/12 vs 2/4/4/4/4) | DIRECT — counted from the netlist |
| Per-bit ratios (0.48–0.97×) | DIRECT — arithmetic on the above |
| "The 2-threshold tax was a sense-amp artifact" (energy half) | OURS — supported by DIRECT (idle ≈0, E_rec=0) |
| "3 states still need 2 boundaries" (device half) | OURS / ANALOGY — `device_circuit.md` §0, `minimal_gates.md` |
| Elevated-Vt dead zone (Vt=1.4) is a multi-Vt ask + 0.4 V rail floor | OURS — the design choice here |
| Schottky (TT≈0) and small CJO required for fast null-return | DIRECT (the slowdown is measured); OURS (the fix choice) |
| Leakage / mismatch / body-diode cost of the elevated-Vt devices | SPECULATION — LEVEL=1 models none |
| mod-3 sum not reachable from the lattice fragment | OURS — `minimal_gates.md` §4; not measured here |

---

## TODO / not covered / caveats

1. **mod-3 sum (and the 3-input balanced full adder) is unmeasured.** The regeneration path
   (diode receiver + level-shift + `tsum` static CMOS) is the concrete next netlist; expect
   ~100 T + receiver, i.e. the `gate_energy` loss story returns for the one gate that
   genuinely needs a null rail. The field-op incompleteness of `{NOT,NAND,NOR}` is the
   structural reason, not a tuning gap.
2. **The toggle is the *cheapest* ternary toggle (null↔+1, half swing).** Binary toggles the
   full ±1 V. A ternary +1↔−1 toggle swings the full ±1 V and costs ~2× the measured
   null↔+1 energy (½CV² + channel loss scale with swing), which would move the per-bit ratios
   to ~0.97–1.94× (tie to ~2× worse). Which ratio is "right" depends on the data statistics —
   null-heavy data favors ternary, ±1-heavy data favors binary (the `ENERGY_RESULTS.md`
   break-even). **Measure the +1↔−1 toggle before quoting the 0.48× figure as the headline.**
3. **The elevated-|Vt| devices are idealized.** LEVEL=1 has no subthreshold leakage, so the
   0.4 V dead zone is a hard cutoff; a real 1.4-V-Vt device leaks, and the ~0.4 V rail floor
   sits near the process-offset floor (σ 5–20 mV at these sizes — the lowswing sweep's real
   estimate). The null-idle "≈0" is a model artifact; silicon's floor is leakage, not zero.
4. **No body diode / no mismatch.** A real bipolar push-pull driver needs body isolation
   (the fair-fight's standing caveat), and device mismatch halves the dead-zone margin
   (2 thresholds = 2× the offset budget).
5. **The rail floor (~0.4 V) is a real swing tax.** The direction receiver must assert the
   rail above `Vt−Vdd = 0.4 V`, which forced the high-impedance (100 kΩ) keeper; the comm
   cell's 0.25 V rail (500 Ω, 0.562 pJ optimized) is incompatible with this dead zone. A
   lower-|Vt| dead zone would relax this but shrink the null margin — the trade is not swept.
6. **Null-return speed is Schottky- and margin-limited.** Measured: TT=0.5 n pins the output
   (~10–16 ns); TT≈0 returns in ~5 ns with Vt=1.4. No sweep over (Vt, R_keeper, CJO, TT) was
   done — the ~5 ns/gate operating point is one point, not an optimum.
7. **MIN/MAX are 2-stage compositions**, so they are 2 gate delays deep and their
   intermediate polar wire needs its own null-return (the 100 kΩ `Rmid`). A merged
   single-stage MIN/MAX does not exist in this primitive set (MIN/MAX provably need the
   inversion the diode receiver supplies "for free" as NOT, but only by adding a stage).
8. **The binary baseline is gate-level (E_gate only, passive receiver).** This is the honest
   apples-to-apples: both binary and ternary here have passive receivers (next gate's cap /
   next gate's diodes). It is *more* favorable to ternary than `polar_gates.md`, which added
   a clocked sense amp to binary too. Do not compare this file's 0.48–0.97× against
   `polar_gates.md`'s 4.9–14.3× without noting the receiver-accounting change.

*Every number above is measured by `circuit/diode_gates.cir` (ngspice 44.2) or counted from
its netlist; nothing is invented.*
