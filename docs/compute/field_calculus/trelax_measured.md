# TRELAX — measured (heat-relaxation step on the hex lattice)

**2026-08-29 — ngspice 44.2 + yosys 0.52, measured.** This closes the SPECULATION in
`heat.md` §TODO ("no measured ∇²/TRELAX datapath") and `synthesis.md` §3 ("TRELAX has no RTL,
no area, no energy"). It builds the datapath, measures its energy and device count, and runs the
relaxation to show it drives a non-uniform field toward uniform (the `O→E` attractor).

Calibration legend (repo-wide, unchanged): **DIRECT** = measured/proved/classical; **ANALOGY** =
structural resemblance; **OURS** = our design claim following from DIRECT but unmeasured; **SPECULATION**
= untested hypothesis.

Files: `circuit/trelax.cir` (netlist, `ngspice -b` exit 0), `circuit/trelax.log`, `rtl/trelax.v`
(the RTL for the yosys area cross-check), `rtl/trelax_tb.v` (iverilog lockstep, 7/7 PASS).

---

## 0. TL;DR (the numbers up front)

| quantity | value | calibration |
|---|---|---|
| balanced-ternary full adder `tadd1` | **0.355 fJ / toggle, 192 T** (25 sky130 cells / 146.39 µm²) | DIRECT (measured) |
| binary full adder (same toggle) | **0.185 fJ / toggle, 58 T** (2 cells / 33.78 µm²) | DIRECT (measured) |
| ternary/binary full-adder ratio | **1.92× energy, 3.31× transistors, 4.33× area** | DIRECT (measured) |
| 6-trit ripple adder `tadd6` | 0.198 fJ (1 trit) – 3.33 fJ (full + carry ripple) / toggle | DIRECT (measured) |
| **TRELAX per-cell-per-step** | **~13–16 fJ, 36–46 `tadd1` = 6 912–8 832 T** | DIRECT (measured + counted) |
| trelax_cell (yosys/sky130) | **891 cells / 5 594.12 µm²** | DIRECT (measured) |
| per-pod (7 cells) | ~89–114 fJ / step, 48 384 T | DIRECT (derived) |
| relaxation works? | variance 0.1224 → 0.000194 in 4 steps (monotonic) | DIRECT (exact arithmetic) |

**One-sentence verdict:** TRELAX works — the balanced-ternary hex-stencil step does drive a spike
to uniform, monotonically — but it is **not cheap per gate** (the balanced full adder is 1.92× a
binary full adder's energy, 3.3× its transistors), so a per-cell relaxation step (~13–16 fJ, ~36–46
adders) costs **~1.2–1.5× an equivalent binary adder-tree reduction**, not less. The "relaxation is
free" intuition (heat.md's analog solver) survives only if the neighbor-sum is done in **analog
(current-mode)** — which I did **not** measure and remains SPECULATION.

---

## 1. What was built

### 1.1 The instruction, made concrete

`TRELAX` = one heat iteration `u ← u + α·∇²u`, `∇²f(x) = Σ_{k=0..5} f(x+ωᵏ) − 6f(x)` (6-point
hex-disk Laplacian). I chose **α = 2/3** (a damped, under-relaxed Jacobi step, 0 < α < 1 ⇒
guaranteed convergence for the hex Laplacian) for one reason: it makes the update's two coefficients
powers of three, so both divisions become **free ternary right-shifts**:

```
u' = (1−α)u + (α/6)Σnb  =  u/3 + Σnb/9        (α = 2/3)
   = (u >> 1 trit) + (Σnb >> 2 trits)
```

The "−6·center" is not dropped — it is folded into the `u/3` coefficient, exactly:
`u + (1/9)(Σnb − 6u) = u/3 + Σnb/9`. **DIRECT** (algebra). The explicit `Σnb − 6·center` would cost
an extra subtractor; the folded form needs only **6 balanced adders** (5 for the 6-input reduction
tree + 1 for the blend) plus two free shifts. **OURS** (the α=2/3 choice + the fold), resting on a
DIRECT identity.

### 1.2 The trit encoding (unchanged from the repo)

One trit = 2 wires, one-hot-per-direction: `+1 = 2'b01`, `0 = 2'b00`, `−1 = 2'b10`, `11` never.
In the netlist each wire is a 0/1 V signal on the shared `VDD = 1.0 V` rail (the repo's binary
reference rail), so the balanced ternary is carried by *which* wire is high — exactly
`rtl/trit_functions.vh`.

### 1.3 The balanced full adder `tadd1` (the atomic cell)

Implemented in static CMOS from the balanced-adder truth table (digit sum `s = a+b+cin ∈ {−3..+3}`;
`carry = sign(s)·[|s|≥2]`, `sum = sign(s)·[s ∈ {±1, ∓2}]`), as the boolean form:

```
p2 = maj3(ap,bp,cp);  n2 = maj3(an,bn,cn);  nz = ~(an|bn|cn);  pz = ~(ap|bp|cp)
p2x = p2 & ~(ap&bp&cp);  n2x = n2 & ~(an&bn&cn)          (exactly two)
p1  = (ap|bp|cp) & ~p2;  n1 = (an|bn|cn) & ~n2            (exactly one)
cop = nz & p2;  con = pz & n2
sp  = (p1&nz) | (p2x&n1) | (pz&n2x)      sn = (n1&pz) | (n2x&p1) | (nz&p2x)
```

This is the *naive* boolean cell (same as `trit_functions.vh`'s `tadd1`; the two cross terms
`p2x&n1` / `n2x&p1` — the `s=±1` cases with `(2,1)`/`(1,2)` sign splits — are the ones the naive
"one-hot count" derivation drops). It counts **192 transistors**; `gate_area.md`'s yosys pass maps
the same equations to 25 sky130 cells / 146.39 µm² (the two counts agree within "simple gates vs
packed AOI cells"). **DIRECT** (measured; the cell is verified against an independent behavioral
reference below).

### 1.4 The per-cell datapath `trelax_cell`

`rtl/trelax.v` = the combinational per-cell step: 6 neighbor values + center → relaxed center, using
`tadd_trits` (the repo's ripple adder). The reduction tree runs at **SW = 8 trits** (a 6-input sum of
6-trit values spans ±2184, which needs 8 trits), the update add runs at 6 trits. Total **46 `tadd1`**
= 5×8 + 6. For a normalized field (|u| ≲ 1.5, the relaxation regime) the sum fits 6 trits and the
reduction could run at 6 trits → **36 `tadd1`**; both counts are reported below.

---

## 2. Measured energy (ngspice 44.2, LEVEL=1, VDD=1.0 V, isolated supplies)

Method = the repo's fair-fight convention: real static-CMOS gates, inputs from ideal sources
(previous stage abstracted), output loads = one next-gate input cap (10 fF), energy = ∫V·I of the
gate's own supply over one full toggle cycle, halved for "per toggle". The ternary and binary full
adders use the **identical toggle shape** (sum swings full, carry toggles) so `e1/e4` is the clean
per-gate ratio.

| instance | what toggles | energy / toggle |
|---|---|---|
| `tadd1` (balanced FA) | a: 0→+1→0, b=+1, cin=0 ⇒ sum +1↔−1, carry 0↔+1 | **0.355 fJ** |
| `bin_fa` (binary FA) | a: 0→1→0, b=1, cin=0 ⇒ sum 1↔0, carry 0↔1 | **0.185 fJ** |
| `tadd6` cheapest | a=0, b trit0 0↔+1 (no carry) | **0.198 fJ** |
| `tadd6` worst | a=+364, b 0↔+364 (full 6-trit swing + carry ripple) | **3.33 fJ** |

Per-cell-per-step (6 adders = 5 reduction + 1 update):

| width framing | adder count | energy / cell / step |
|---|---|---|
| normalized field (6-trit reduction) | 36 `tadd1` | **12.8 fJ** |
| full-range safe (8-trit reduction, the RTL) | 46 `tadd1` | **16.3 fJ** |
| `tadd6` activity bounds (6 × measured adder) | — | [1.19, 20.0] fJ |

Per-pod (7 cells): **89–114 fJ / step**. The `tadd6` bounds and the `tadd1`-atomic figure are
mutually consistent (16.3 fJ sits inside [1.2, 20] fJ).

---

## 3. Device count

| unit | transistors (this netlist) | sky130 cells / µm² (yosys) |
|---|---|---|
| `tadd1` balanced FA | 192 T | 25 / 146.39 (gate_area.md) |
| `bin_fa` binary FA | 58 T | 2 / 33.78 (gate_area.md) |
| `tadd6` 6-trit ripple | 1 152 T | — |
| **`trelax_cell` (per-cell step)** | **8 832 T** (46 `tadd1`) | **891 / 5 594.12** (measured) |
| normalized-field variant | 6 912 T (36 `tadd1`) | — |
| per-pod (7 cells) | 61 824 T (safe) | ~39 159 µm² (= 7 × 5 594) |

The yosys figure was measured this session with the same flow as `eisen_opcode.md`
(`read_verilog rtl/ternary_gates.v rtl/trelax.v; hierarchy -top trelax_cell; proc; opt; flatten;
techmap; abc -liberty rtl/sky130_fd_sc_hd.lib; stat`). For scale: the whole optimized CPU is
24 314 µm² and TMUL added 15 766 µm², so one TRELAX cell (5 594 µm²) is ~23% of the CPU and ~35%
of the TMUL instruction's area.

---

## 4. Relaxation works — the `O→E` attractor, demonstrated

Behavioral (exact, α=2/3) 7-cell hex pod, center spike +1 in a zero field, fixed-zero boundary (the
pod is a *local stencil* — a ring cell's 6 hex neighbors are the center + 5 cells outside the pod,
held at 0). The netlist's `.control` block runs 4 steps and prints the field and its population
variance:

| step | u_center | u_ring (×6) | variance_u |
|---|---|---|---|
| 0 | 1 | 0 | **0.122449** (= 6/49) |
| 1 | 1/3 | 1/9 | 0.00604686 |
| 2 | 5/27 | 2/27 | 0.00151172 |
| 3 | 1/9 | 11/243 | 0.000530863 |
| 4 | 49/729 | 20/729 | **0.000193774** |

The variance falls monotonically by **~633×** in 4 steps; the spike diffuses into the ring and the
field flows toward uniform (here uniform = 0 because the boundary is fixed at 0). This is exactly the
heat-flow's `dE/dt ≤ 0`: the non-uniformity (a quadratic, Dirichlet-like functional) is strictly
dissipated. **DIRECT** (exact arithmetic, cross-checked against the `Fraction` computation).

Mass-conserving reading (the other, non-trivial "uniform"): if the 7 cells form a *closed* 6-regular
system (each cell's 6 neighbors = the other 6 — a K7 reading, an illustration, **not** the hex star),
the same update conserves total mass and drives to uniform **1/7 ≈ 0.1429** (variance
0.1224 → 0.00605 → 0.000299 → 1.47×10⁻⁵ → 7.28×10⁻⁷). The hex pod itself is a star (ring cells are
not mutual neighbors), so a strictly closed 7-cell hex torus does not exist; the fixed-boundary spike
is the physically honest local demonstration.

Two independent correctness checks back the circuit itself: (a) the ngspice `tadd1` is compared to an
independent behavioral reference over 8 input triples covering every output class and the `s=±1`
cross cases — all 8 diffs ≈ 7.6×10⁻¹⁰ V = verified; (b) `rtl/trelax_tb.v` checks `trelax_cell`
against hand-computed balanced-ternary values — **7/7 PASS** (iverilog).

---

## 5. Honest verdict — "is this cheap?"

**No per gate; ~parity per cell; cheap only vs the wire.** Three distinct comparisons, all measured:

1. **Per gate (the primitive):** the balanced-ternary full adder is **1.92× the energy and 3.31× the
   transistors of a binary full adder** (4.33× area in the yosys flow). This is the 2-threshold tax of
   `control.md`/`gate_area.md`, measured cleanly on the identical toggle shape. **DIRECT.** Nothing
   about the hex stencil changes it.

2. **Per cell (the honest "neighborhood reduction ≠ gate" comparison):** a TRELAX step is a 6-input
   reduction + blend = 6 adder-evaluations. A **binary** adder tree computing the same fixed-point
   6-input sum (10-bit words, since 6 trits = 729 states needs 10 bits) is ~60 binary full adders ≈
   **11 fJ/cell/step**. TRELAX is **~13–16 fJ/cell/step ⇒ 1.2–1.5× the binary equivalent**. The
   ternary adder's 1.92× energy penalty is *partly* offset by binary needing 10 bits where ternary
   needs 6 trits, so the net is a small multiple, not a win. **DIRECT** (measured tadd1/bin_fa +
   counted structure).

3. **Per cell vs the wire (the only place it looks cheap):** the repo's measured link energies are
   0.748 pJ/bit (binary) and 0.515 pJ/trit (ternary, null-carrying) — i.e. **~1 pJ to move one symbol
   across a wire**. One TRELAX step per cell is ~13–16 fJ, **~40–70× cheaper than one wire transfer**.
   So *compute (relaxation) ≪ communication* in this system — the relaxation is cheap only because the
   wire is the wall, not because the arithmetic is free. **DIRECT** (both sides measured in this repo).

**Bottom line:** TRELAX is a *correct, convergent* primitive and its per-cell cost (~13–16 fJ, ~9 kT
of transistors, 891 sky130 cells) is a real, measured number — but it is **not cheaper than a binary
adder tree for the same reduction**, and the "the physics relaxes it for free" intuition of `heat.md`
is realized only by an **analog (current-mode) neighbor-sum**, which is the untested alternative and
stays SPECULATION. `ENERGY_LAWS.md`'s warning ("parallelism duplicates energy") is confirmed in
shape: the 6-neighbor gather duplicates the adder 5×.

---

## 6. Calibrated verdict

| claim | calibration |
|---|---|
| hex-disk Laplacian = 6-neighbor sum − 6·center | DIRECT (classical, heat.md) |
| α=2/3 damped Jacobi converges for the hex Laplacian | DIRECT (0 < α < 1, connected non-bipartite stencil) |
| folded update `u/3 + Σnb/9` = spec with α=2/3 | DIRECT (algebra identity) |
| ternary right-shift = ÷3 (free wire re-wiring) | DIRECT (balanced-ternary digit shift) |
| `tadd1` = 192 T, 0.355 fJ/toggle, correct over 8/8 triples | DIRECT (measured) |
| ternary FA = 1.92× energy / 3.31× T / 4.33× area of binary FA | DIRECT (measured; gate_area.md) |
| TRELAX per-cell = ~13–16 fJ, 891 cells / 5 594 µm² | DIRECT (measured + counted) |
| relaxation drives spike → uniform, variance ↓ 633× | DIRECT (exact arithmetic) |
| TRELAX beats a binary adder-tree reduction | **SPECULATION → false as stated** (it is 1.2–1.5× worse) |
| TRELAX is "cheap because compute ≪ wire" | DIRECT (13–16 fJ vs ~1 pJ/transfer), but that is a communication comparison, not a compute win |
| an analog/current-mode neighbor-sum would be cheap | SPECULATION (unmeasured; not in this netlist) |

---

## TODO / not covered / caveats

1. **Analog current-mode sum not measured.** The one implementation that could make the relaxation
   genuinely cheap — 6 current sources summed on a node (the natural "neighbor average") — is not in
   this netlist. Until it is measured the same way, "relaxation is free" stays SPECULATION. This is
   the single highest-value follow-up.
2. **LEVEL=1, no body diodes, no mismatch.** Same class as every fair fight in `circuit/`: the energy
   numbers are the toy-model truth, and real device mismatch (sense-amp offsets, σ≈5–20 mV per
   `lowswing_sweep`) is irrelevant here (no clocked receiver) but leakage/subthreshold is *omitted* —
   LEVEL=1 draws zero static current, so these are switching-only energies.
3. **The `tadd1` is the naive boolean cell (192 T).** `gate_area.md`'s 25-cell/146 µm² yosys number is
   the honest area, but a *native* multi-valued device (one that thresholds 3 states on one wire, per
   the `polar_gates.cir` reframe) is not modeled; the 2-wire one-hot encoding is what pays the 2× tax.
4. **Fixed-point truncation semantics.** "Drop lowest trits" is round-toward-the-removed-trits, not
   round-half-even; for the demonstration's small positive values it is exact, but a full-range
   relaxation would accumulate a per-step truncation error (O(1) LSB = O(1/27) in u). Not bounded here.
5. **No time axis in the processor.** The "steps" are software iterations; nothing here supplies the
   `∂/∂t` that `heat.md` §TODO flags as the missing ingredient. TRELAX is one *explicit-Euler* step;
   its stability bound (α ≤ 1) and CFL-style step-size discipline are not explored.
6. **Full-range overflow of the reduction** is avoided by the 8-trit SW (measured area already
   includes it); the 36-tadd1 "normalized" figure is only valid for |u| ≲ 1.5 and is stated, not
   separately synthesized.
7. **Not covered:** multi-step throughput/energy (only the per-step cost is measured), the harmonic
   (`div=0`) attractor as a *computation* (only the `O→E`/uniform one is demonstrated), the
   reversibility audit (is a damped neighbor-average information-erasing? per `synth_design.md`), and
   any boundary-condition hardware (the fixed-zero boundary is assumed, not implemented).

## Sources

**Measured this session:** `circuit/trelax.cir` + `circuit/trelax.log` (energy, truth table,
relaxation demo), `rtl/trelax.v` (yosys area = 891 cells / 5 594.12 µm²), `rtl/trelax_tb.v`
(iverilog 7/7). **Repo:** `rtl/trit_functions.vh`, `rtl/ternary_gates.v` (encoding, `tadd1` truth
table), `docs/compute/gate_area.md` (tadd1 25 cells / 146.39 µm², badd1 2 / 33.78),
`circuit/ENERGY_RESULTS.md` (0.748 pJ/bit binary, 0.515 pJ/trit ternary, fair-fight method),
`docs/compute/eisen_opcode.md` (CPU 24 314 µm², TMUL +15 766 µm²), `docs/compute/field_calculus/heat.md`
+ `synthesis.md` (the TRELAX spec and the two attractors).
