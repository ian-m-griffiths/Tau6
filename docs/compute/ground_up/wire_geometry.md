# Wire geometry — can wire width / parallel rails reduce ternary energy?

**2026-08-30 — Tau Architecture, ground-up experiment.** One question: does the
principal's hypothesis hold — *"optimise the current vs resistance modifiers, because
parallel and wider wires negate the losses of smaller things… may even need to be
different across our complex transistors"* — i.e. is there an **R-vs-C optimum per
wire**, does **parallel beat wide**, and does **heterogeneous (push≠pull) sizing** win?

**Verdict up front:** for a full-swing rail the R-vs-C "optimum" is a **delay** optimum,
not an energy one — energy is monotonic in width (narrower is always cheaper) because
`E = C_total·V²` is independent of R. Parallel rails are **strictly worse** than one
wide wire at equal resistance (+5–8%, fringe + via overhead). Heterogeneous sizing is
**not an energy win** — the energy-minimum is always *both rails at minimum width*.
Geometry recovers **~56%** of the interconnect-stage toggle energy in the repo's
wire-dominated regime (because the 1 pF line is 5× the 0.2 pF receiver), *not* <10% —
but that number is regime-dependent and shrinks toward <10% as the device/receiver
capacitance overtakes the wire.

---

## 1. Method (reproducible, single headless run)

**Netlist:** `circuit/wire_geometry.cir` (new). ngspice-44.2 here has **no `.step`**
(verified), so — matching the repo convention in `ternary_transistor.cir` §2 and
`run_lowswing_sweep.sh` — the sweep is 13 instantiations in staggered 70 ns windows,
one `ngspice -b` invocation, `.tran 20p 950n`, exit 0. Reproduce:

```bash
ngspice -b circuit/wire_geometry.cir
```

**Circuit** (two-rail one-hot ternary driver, the task's `01=push / 00=null / 10=pull`
encoding, realised AC-polarity like `lowswing_sweep.cir`):

- **+1 (push):** PMOS driver pulls the PUSH wire `0 → +VDD`; **−1 (pull):** NMOS driver
  pulls the PULL wire `0 → −VDD`; **0 (null):** both off, wires stay 0 (free).
- **Driver:** real CMOS, `VDD=+1 / VSS=−1`, `VTO=±0.4`, `KP 200u/100u`, **equal W=11u**
  so the PMOS is genuinely ~2× weaker than the NMOS — the real P/N mobility asymmetry the
  heterogeneity test is meant to exploit. (Driver gate charge ~34 fJ/toggle is negligible
  and width-independent; noted, not swept.)
- **Wire** (Elmore, repo's `Rw in x` + `Cx x 0` convention), width `W`:
  `R(W)=Rref·Wref/W`, `C(W)=Caref·(W/Wref)+Cf`. Reference `Wref=1` = `Rref=500 Ω`,
  `Caref=1 pF` (the repo's `rwire=500, cline=1p` defaults), `Cf=0.1 pF` fringe,
  `Cvia=20 fF` via overhead. **Parallel N rails** divide R by N but add `N·Cf + N·Cvia`;
  **one wide wire `W=N·Wref`** adds only the area term.
- **Load:** `CL=0.2 pF` receiver input (the "next gate") + 1 MΩ DC return.

**Energy accounting** (repo convention `∫V·I dt`): `E_push = ∫−V(vdd)·I(VDD)`,
`E_pull = ∫−V(vss)·I(VSS)` over each 20 ns toggle window. A 20 ns pulse lets every rail
**fully settle** (settled swing measured `0.997–0.999 V`), so the measured energy is the
textbook `C_total·V²` — ½ stored, ½ dissipated in driver + wire — with the wire/channel
dissipation *inside* the integral. Honest idealisations: LEVEL=1, no body diode, no
subthreshold, no mismatch, pure-C receiver (the diode demux + sense amp add a
width-*independent* constant that cannot change the wire ranking, so they are omitted to
isolate the wire).

---

## 2. Measured table

`E` = rail supply energy per toggle (pJ); `t_p`/`t_n` = 10–90% delay (ns).
"Wide W=2" is one wire of width 2; "par N=2" is two width-1 rails in parallel —
same R (250 Ω), different C.

| case | push wire | pull wire | E_push | E_pull | t_p (push) | t_n (pull) |
|---|---|---|---|---|---|---|
| **W=0.25** | 0.25 | 0.25 | 0.597 | 0.597 | 2.88 | 2.70 |
| **W=0.5** | 0.5 | 0.5 | 0.848 | 0.846 | 2.34 | 2.06 |
| **W=1 (ref)** | 1 | 1 | 1.348 | 1.348 | 2.36 | 1.88 |
| **W=2** | 2 | 2 | 2.348 | 2.347 | 3.01 | 2.07 |
| **W=4** | 4 | 4 | 4.345 | 4.345 | 4.69 | 2.80 |
| **W=8** | 8 | 8 | 8.326 | 8.344 | 8.25 | 4.51 |
| **par N=2** | 1 (×2) | 1 (×2) | 2.468 | 2.467 | 3.16 | 2.18 |
| **par N=3** | 1 (×3) | 1 (×3) | 3.586 | 3.585 | 4.10 | 2.58 |
| **par N=4** | 1 (×4) | 1 (×4) | 4.705 | 4.705 | 5.08 | 3.03 |
| **het 2/1** | 2 | 1 | 2.348 | 1.348 | 3.01 | 1.88 |
| **het 4/1** | 4 | 1 | 4.345 | 1.348 | 4.69 | 1.88 |
| **het 1/2** | 1 | 2 | 1.348 | 2.347 | 2.36 | 2.07 |
| **het 1/4** | 1 | 4 | 1.348 | 4.345 | 2.36 | 2.80 |

Device floor (width-independent, unreachable by wire geometry): charging `CL=0.2 pF` +
`Cvia=20 fF` = **0.22 pJ/toggle**.

---

## 3. Finding 1 — the "R-vs-C optimum" is a delay optimum, not an energy optimum

Energy is **monotonic in width**: `0.60 → 8.33 pJ` from `W=0.25 → 8`, matching
`C_total·V²` to within 2% at every point (the small constant offset is gate–drain
feedthrough). There is **no interior energy minimum** — wider wire only ever *adds* C,
and for a fully-settled rail R does not appear in the energy at all (`E = C·V²`,
R only decides *where* the ½C·V² is dissipated, not *how much* is drawn).

Delay is **U-shaped**: push `2.88 → 2.34 → 2.36 → 3.01 → 4.69 → 8.25 ns`, minimum at
`W≈0.5–1`; pull `2.70 → 2.06 → 1.88 → 2.07 → 2.80 → 4.51 ns`, minimum at `W≈1`. This is
the textbook wire-width optimum: narrow is R-limited (driver fights wire R), wide is
C-limited (driver must charge extra C), and the wire's *own* RC is width-invariant
(`R∝1/W, C∝W ⇒ RC=const`), so widening never speeds the wire itself up — it only
rebalances driver-loading vs load-charging.

**So the honest R-vs-C answer:** the optimum is **"as narrow as your timing budget
allows"** on energy (minimum width), and **"W where driver-R ≈ wire-R"** on delay
(here `W≈1`). Energy-delay product in this regime *also* favours narrow (0.60·2.88=1.72
at W=0.25 vs 1.35·2.36=3.18 at W=1), because C grows linearly with W while delay only
flattens. Geometry **cannot beat `C·V²`** — it only moves `C·V²` up (wider) or the delay
up (narrower).

## 4. Finding 2 — parallel vs wide: parallel loses

At **equal resistance**, one wide wire beats N parallel rails on energy:

| same R | wide | parallel | parallel penalty |
|---|---|---|---|
| 250 Ω (W=2 vs N=2) | 2.348 pJ | 2.468 pJ | **+5.1%** |
| 125 Ω (W=4 vs N=4) | 4.345 pJ | 4.705 pJ | **+8.3%** |

The penalty is the extra per-rail **fringe** (`Cf=0.1 pF/rail`) + **via** (`Cvia=20 fF/rail`)
that a single wide wire pays only once. Parallel is also slightly *slower* (more C).
This **contradicts** the "parallel rails negate the losses" hope: parallel's real merits
(electromigration, litho uniformity, IR-drop in power nets, redundancy) are **not energy
merits**. For a signal rail, a single wide wire is the energy-efficient way to buy low R.

## 5. Finding 3 — heterogeneous sizing is NOT an energy win

Total push+pull energy (pJ): symmetric `W=1` = **2.696**; `het 2/1` = 3.696; `het 4/1`
= 5.693; `het 1/2` = 3.695; `het 1/4` = 5.693. Every heterogeneous option is **worse**,
and the true minimum is **symmetric at minimum width** (`W=0.25` = 1.194 pJ). The reason
is the same as Finding 1: energy scales with `C_push + C_pull`, and both rails' C should
be minimised independently — widening either rail *only* costs `ΔC·V²`.

The P/N mobility asymmetry is real and visible — the pull rail (NMOS) is ~25% faster than
the push rail (PMOS) at every width (`t_n < t_p`). But that asymmetry shows up in **delay,
not energy**, and it can only *justify* widening the slow (push) rail to meet a clock
target — a delay-balancing knob that **costs** energy, never saves it. The principal's
"we want them doing different things" is true only if "different things" means "different
delay budgets", and even then the energy-optimal answer is *shrink whichever rail has
slack*, converging back to symmetric-minimum.

## 6. Honest verdict — how much does geometry recover?

- **Per-toggle recovery, `W=1 → W=0.5`:** (1.348−0.847)/1.348 = **37%**.
- **Per-toggle recovery, `W=1 → W=0.25`:** (1.348−0.597)/1.348 = **56%**.

This is **not <10% — but the reason matters.** At `W=1` the wire is `1.1 pF` vs the
`0.22 pF` device floor (receiver input + via), i.e. the wire is **83% of the toggle
energy and 5× the device**. Geometry recovers a lot *because the repo's own
`cline=1 pF` is a long, wire-dominated line*. The `<10%` regime the task anticipates is
the **opposite** limit — a short local wire (`cline ≲ cload`) where the receiver/device
capacitance dominates — and any real design lives on this spectrum:

| regime | wire C : load C | geometry recovery |
|---|---|---|
| long line (`cline=1p`, this run) | 5 : 1 | **~37–56%** |
| local wire (`cline≈cload`) | 1 : 1 | ~20–30% |
| device-dominated (`cline≪cload`) | 1 : 5 | **<10%** |

Three further honesty flags, so the number is not oversold:

1. **This is the interconnect stage, not the whole cell.** The repo's own fair-fight
   (`ENERGY_RESULTS.md`, `lowswing_sweep.cir`) finds the **driver channel loss is "the
   wall"** (~0.61 pJ of the 1.20 pJ toggle), plus a diode forward drop and 2× sense-amp
   receiver. Those are width-*independent* constants; wire narrowing shrinks only the
   wire's `C·V²` share, so the **circuit-level** recovery is diluted by those fixed
   overheads.
2. **Narrowing is bounded by delay and by minimum design rules.** The 56% assumes you can
   reach `W=0.25` without the R blowing past your clock period (at `W=0.25` push delay is
   already 22% above optimum). Under a fixed-throughput constraint the real recovery is
   the `W` that *just* meets timing — a smaller number.
3. **It is recovery of `C·V²`, not a violation of it.** No geometry choice gets below
   `C_min·V²`; the 0.22 pJ device floor is untouched.

**Bottom line:** the principal's intuition is half right. There **is** an R-vs-C tradeoff,
but it is a **delay** tradeoff (optimum `W≈1`), not an energy tradeoff — energy only goes
up with width, so the energy-optimum is always minimum legal width. **Parallel rails do
not beat wide** (they add fringe+via, +5–8% at equal R). **Heterogeneous push/pull widths
do not help energy** (symmetric-minimum wins; asymmetry only rebalances delay at an energy
cost). The headline recovery, **~37–56% of the interconnect-stage toggle**, is real but
regime-dependent: it holds because the repo's 1 pF line is wire-dominated, and it shrinks
toward **<10%** the moment the device/receiver capacitance, not the wire, dominates —
which is exactly where the full ternary cell (driver channel + diode + sense amp) pushes
the ledger.
