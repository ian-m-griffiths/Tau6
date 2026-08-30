# Ternary Arithmetic Beyond Add & Multiply

**Division · comparison · barrel-shift/rotation (Z₆) · ALU composition**

**Date:** 2026-08-29. **Scope:** the arithmetic units the Tau Architecture does *not* yet
have. The adder and multiplier are out of scope (already built and verified — see "already
have" below); this survey costs the four missing units and recommends the ALU composition.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured or proved (our ngspice/yosys numbers, our Lean proofs, or a citable
  literature number).
- **ANALOGY** — parallel structure to something real, but the mapping is not an identity
  (e.g. CNTFET transistor counts ported to our CMOS flow; textbook binary baselines).
- **OURS** — our own design claim, carried from project files (RTL, Lean ledger, rust-mirror).
- **SPECULATION** — untested hypothesis, flagged as such.

**One-line answer up front:** balanced ternary makes **negation, Z₆ rotation, and round-to-
nearest** *structurally* cheaper (fewer gate stages, integer-exact, no sign bookkeeping), makes
**shift** cheaper by *density* (×3 per trit vs ×2 per bit, and that is the same free wiring
binary already enjoys), and makes **division** *no cheaper* — division is hard in every radix,
and ternary pays its 2-threshold receiver tax per quotient-digit step for no structural return.
Comparison is a mild structural win (it *is* lattice min/max, `min+max=sum`).

---

## 0. What we already have (do NOT re-derive)

- **Adder** — `rtl/verify_tadd1.sv`: PDR-verified balanced-ternary full adder `tadd1`
  (`rtl/trit_functions.vh` L32–49), 27 reachable `(a,b,cin)` rows, balanced carry
  (`s≤−2 → cout −1`, `s≥2 → cout +1`). The cell is a **3-operand** relation, not a 2-input
  gate chain — the literature independently shows this is the right architecture (see §1,
  the hybrid FA PDP number).
- **Multiplier** — `rtl/tmul_opt.v`: shift-add + Karatsuba + the norm identity
  `N = (a+b)² − ab` (3 products → 2), SAT-proved; **−9.0% chip / −20.1% tnorm** area
  (`docs/ENERGY_LAWS.md`). Karatsuba itself loses (+28%) at the 6-trit word size; the win is
  the norm identity. Eisenstein multiply `tmul_eisen_trits` (3 products) pays −14.6% at N=6
  but has no instruction yet.
- **Cells** — `rtl/trit_functions.vh`: `tneg` (wire swap), `tmul` (sign product), `tand`
  (min), `tor` (max), `tadd1`. Trit encoding `01=+1 / 00=0 / 10=−1 / 11=NEVER`.
- **ALU today** — `rtl/cpu.v`: `TADD TSUB TROT TNORM LDI HLT`. `TSUB` = free digit-swap
  negate + add; `TROT` = Z₆ gauge change (6-way case + one `a+b` adder + `fneg6`).
- **Lean** (`proofs/INDEX.md`, `lake build` green, zero `sorry`): T3 Z₆ units
  (`Rotation.lean`), G1 `norm_eq_det` / `units_eq_omega_pow` (`Gauge.lean`), T5 ℤ[ω] is a
  Euclidean domain (`EuclideanDomain.lean`), A3 `min+max=sum` (`ValuationEnergy.lean`), TC1
  the ternary cell (`TernaryCell.lean`).
- **Rust mirror** — `rust-mirror/src/ternary.rs`: 12-opcode emulator; `TDIV`/`TMOD`/`TBR` are
  **STUBs** (truncating `i64` division, round-to-nearest TODO); `TROT`/`TNORM` implemented.
- **Measured silicon** (`docs/REAL_SKY130_SYNTHESIS.md`): full CPU 26,713 → **24,314 µm²**,
  3,970 cells, 50.3 MHz, 1.60 mW (SkyWater 130 nm). Energy floor (`docs/ENERGY_LAWS.md`):
  comm **0.081 pJ/bit** vs binary 0.748 (9.2×) — *communication*, not compute.

---

## 1. Per-operation survey

| Operation | Balanced-ternary form | Native-ternary advantage | Transistor count | Energy/area vs binary | Calibration |
|---|---|---|---|---|---|
| **Division — scalar** (`TDIV`/`TMOD`) | Positional division, quotient digit ∈ {−1,0,+1}, round-to-nearest; symmetric remainder \|r\| ≤ \|b\|/2 | Symmetric rounding is *natural* (digit set is symmetric about 0); sign of quotient embedded | No ternary number published; iterative: ~N steps × (3-way compare + trit-multiply-subtract) | **No win.** Each quotient-digit step is a 3-way compare = the 2-threshold tax; offset only by ~1.585× fewer steps (12 trits ≈ 19 bits) | ANALOGY (hardware); OURS/SPECULATION (round-to-nearest — the emulator stub is still truncating) |
| **Division — Eisenstein** (ℤ[ω]) | `x/y = round((x·conj(y))/N(y))` in the `(1,ω)` basis; `N(x%y) < N(y)` | **Structural.** The ring *is* a Euclidean domain with the norm as Euclidean function — exact division-with-remainder exists | Needs a norm (2 squares + product) + conjugate multiply + 2 rounds; the Lean `Div` instance uses ℝ `round` — **not synthesizable** | Math proof, not a hardware unit | DIRECT (proved, T5 `EuclideanDomain.lean`); OURS (60° convention) |
| **Comparison** (`TCMP`/`TBR`) | Lexicographic MSB-first trit compare; 3-way below/equal/above; min/max = `tand`/`tor`; sign embedded | **Structural (mild).** Comparison *is* lattice min/max (meet/join) over a *total* order; `min+max=sum`; no sign-magnitude or two's-complement overflow case | `tand`/`tor` = 2 binary gates per trit (2 bits); ≈ 4 gates/trit ≈ 2.5 gates per info-bit | Wash-to-mild-win per bit; the win is *structure* (no sign handling), not gate count | DIRECT (`tand`/`tor` in `trit_functions.vh`; A3 `ValuationEnergy.lean`) / ANALOGY (vs binary comparator) |
| **Shift ×3ᵏ** (trit barrel shift) | Shift left k trits = ×3ᵏ = pure wiring; shift right = ÷3ᵏ (round) | **Density, not structure.** Same free wiring as binary shift-left, but ×3 per position (1.585× more) and log₃N mux stages vs log₂N | Fixed shift = **0 tr** (rewiring); variable shift = 3:1-mux tree, ~2·N·log₃N | Smaller than binary barrel shifter for equal range (fewer positions × fewer stages) | DIRECT (shift = rewire); ANALOGY (mux-tree counts, textbook) |
| **Rotation Z₆** (`TROT`) | Multiply by ωᵏ, k mod 6; ω¹=(−b, a+b), all six = permutation + negate + (k=1,2,4,5) one add; angle-add mod 6 | **Structural flagship.** Binary has *no* native 60° rotation (needs CORDIC or a complex multiply, both with error); ours is integer-exact, zero trig | 1 shared `a+b` adder (6 `tadd1`) + 6:1 mux on the 24-bit word + free negates ≈ **~1 K-transistor-class** | Beats a CORDIC rotator (dozens of iterations, ~2–4 K tr) or complex multiplier on area *and* is exact | DIRECT (proved `units_eq_omega_pow`, implemented `cpu.v` op 2 + rust-mirror) |

### 1.1 Division — the honest "no free lunch" entry

Scalar balanced-ternary division gets one real gift: the digit set {−1,0,+1} is symmetric, so
**round-to-nearest and a symmetric remainder `|r| ≤ |b|/2` are the default**, not a special
case (Setun's "round-to-nearest" heritage, `TERNARY_PROCESSOR.md` §2.2 `TDIV`/`TMOD`). But the
quotient digit is chosen by a **3-way compare per iteration**, and — per Law 1
(`docs/ENERGY_LAWS.md`) — every ternary gate pays a **2-threshold measurement tax** vs binary's
1. So the inner loop is *not* cheaper per step; it is only ~1.585× *shorter* (fewer trits than
bits for the same range). Net: a wash at best, and the corpus flags naive 3-level division as
an energy *liability* (`2211.04542` divider transistors). **Verdict: do not build a dedicated
ternary divider first; emulate division from compare + shift + multiply** (§3).

The one place ternary *does* get division structurally right is the **Eisenstein** reading:
`EuclideanDomain.lean` proves ℤ[ω] is a Euclidean domain, with `norm` as the Euclidean function
and `N(x % y) < N(y)` (`norm_mod_lt`). This is the same theorem the Eisenstein-codes paper
(`2412.18328`) uses for its division algorithm (Voronoi-cell reduction). Two honest cautions:
(i) this is *lattice-point* division (ℤ[ω] ÷ ℤ[ω]), **not** the positional radix division the
ALU's `TDIV` does; and (ii) the Lean instance is a *mathematical existence proof* using ℝ
`round` — it is **not** a synthesizable RTL divider, and no one has built one. The number that
anchors the scalar side: binary division is "the most complex basic arithmetic operation"
([TalTech thesis](https://digikogu.taltech.ee/en/Download/fb0e0c17-4233-41de-a682-c3c4534cd4c1)),
typically ~3–5× a multiplier's area — ANALOGY, no ternary counterpart measured.

### 1.2 Comparison — it is min/max, and min+max=sum

Balanced ternary needs no sign bit: the sign of a number is the sign of its leading non-zero
trit, and the balanced order −1 < 0 < +1 is **total**. Comparison is therefore exactly the
lattice meet/join, which `trit_functions.vh` already ships as `tand` (min) and `tor` (max):

```
tand = {a[1]|b[1], a[0]&b[0]}   // min: 2 gates
tor  = {a[1]&b[1], a[0]|b[0]}   // max: 2 gates
```

and `ValuationEnergy.lean` proves `min + max = sum` (`tritVal_min_add_max`) — the identity the
adder's sum/carry decomposition already relies on. A 3-way compare (below/equal/above) is a
lexicographic min/max + an equality test (`a==b` per trit = XNOR both rails, AND-reduced).
The structural win is that **there is no sign-magnitude vs two's-complement bookkeeping and no
overflow special case** — compare `a` vs `b` and `−a` vs `−b` are the *same* hardware, because
negation is a free wire swap. Transistor density is a wash (≈2.5 gates per info-bit vs binary
~3–5), so this is a *simplicity/exactness* win, not an area win. CALIBRATION: DIRECT for the
cell (our RTL + Lean), ANALOGY for the binary baseline (textbook: ~1 XNOR ≈ 4 tr/bit for
equality; ~12–20 tr/bit for a full 3-way magnitude comparator).

### 1.3 Shift ×3ᵏ — free wiring, one of the two "trit tricks"

Multiplying a balanced-ternary word by 3ᵏ is **repositioning trits by k places — zero gates**,
exactly like binary shift-left-by-k is free wiring. The ternary version just packs more per
shift: one trit-place = ×3 (1.585× a bit's ×2), and the balanced digit set makes a right-shift
(÷3ᵏ) round-to-nearest symmetric for free. A *variable*-amount barrel shifter costs only the
mux tree: binary needs log₂N stages of 2:1 muxes (~2·N·log₂N tr), ternary needs log₃N stages
of 3:1 muxes — fewer positions *and* fewer stages for the same numeric range. CALIBRATION:
DIRECT (shift = rewire is trivially true in the positional encoding), ANALOGY (mux-tree counts
are textbook, not measured here). This is the *density* leg of the trit-tricks hypothesis
(`docs/TERNARY_COMPUTE_SURVEY.md`), not a structural leg — binary already has the free shift.

### 1.4 Rotation Z₆ — the flagship structural win

This is the one operation binary cannot express cheaply at all. In ℤ[ω], the six 60° rotations
are the units ±1, ±ω, ±ω² (`Rotation.lean` `units_card` = 6, `units_closed_under_mul`), and
`Gauge.lean` proves `units_eq_omega_pow` — the six units are exactly ωᵏ, k = 0..5. Multiplying
a lattice point by ω is (`cpu.v` opcode 2, `Gauge.lean` `rep`):

```
k=0: ( a,      b  )     k=3: (−a,   −b  )   [negation]
k=1: (−b,   a+b  )     k=4: ( b, −(a+b))
k=2: (−(a+b), a  )     k=5: (a+b,  −a  )
```

i.e. **a permutation + a free negate + (for four of the six) one single `a+b` add — no
multiplies, no trig, integer-exact.** Composing rotations is **angle-add mod 6** (`angleAdd :
Fin 6 → Fin 6`, `Rotation.lean`), a mod-6 counter — this is the "trig becomes modulo
arithmetic" claim made literal. The binary baseline for the same operation is a CORDIC rotator
(dozens of iterations, accumulating error) or a complex multiplier; ours is one ripple-add wide
(~6 `tadd1` cells) plus a 6:1 word mux plus free wiring. CALIBRATION: DIRECT — proved in Lean,
implemented in `cpu.v` and `rust-mirror/src/eisenstein.rs` (`rotate`). This is the operation to
lean on in the ALU, and the honest place where "ternary is not just denser, it can do a thing
binary can't."

---

## 2. What ternary makes *structurally* cheaper (not just denser)

Ranked, with the honest "not cheaper" entries first so they don't get oversold:

**Not cheaper — say it once:**

- **Division** (scalar): the 3-value quotient digit charges a 2-threshold compare per step; no
  structural return. Same hardness class as binary.
- **Adder density**: the balanced full adder is ~4× a binary FA's transistors (118 tr vs ~28 tr,
  see §1 / ledger) for ~1.585× the digit information — the 2-threshold tax, in area. The adder's
  win is *symmetry* (free negate ⇒ free subtract; balanced carry ±1), not density.

**Structurally cheaper — the list:**

1. **Z₆ rotation** (flagship). Integer-exact 60° rotation as a permutation + negate + one add,
   with composition = mod-6 addition. Binary's nearest equivalent is iterative and lossy. The
   win is *eliminated gate stages and eliminated error*, not smaller gates.
2. **Negation** (the foundation). A per-digit wire swap — no ripple, no two's-complement, no
   borrow. Every other structural win (subtract = negate+add, compare sign-symmetry, rotation)
   inherits from this.
3. **Round-to-nearest / symmetric remainder**. The digit set is symmetric about zero, so
   round-to-nearest and `|r| ≤ |b|/2` are the *default* behavior of truncation-with-symmetric-
   digits — no separate rounding mode. Mild, but it removes a whole class of corner cases.
4. **Comparison = lattice min/max**. Total balanced order + `min+max=sum` (proved) + embedded
   sign means a 3-way compare is a meet/join over two rails, with no sign-magnitude overflow
   handling. Mild win on structure, wash on gates.
5. **Shift ×3ᵏ**. Cheaper, but by *density* (×3 per place, log₃ stages), and only because
   binary already has the identical free-wiring trick for ×2. Listed for completeness; it is
   **not** a structural distinction.

The cleanest formulation: ternary's arithmetic edge is **symmetry-derived structure** (free
negation, exact rotation, symmetric rounding), while its *per-gate* energy/area is at best
neutral and usually the 2-threshold tax. The "structural, not just denser" filter sorts the
four units into **rotate ≫ negate > round > compare ≫ shift (density only) ≈ division (none)**.

---

## 3. Recommended ALU composition

Current `cpu.v` has 5 arithmetic ops (`TADD TSUB TROT TNORM` + `LDI`); the rust-mirror ISA
already names the full 12. Recommendation, split by *what the hardware gives free*:

**Single-cycle (add to `cpu.v` first — all are mux/wiring + at most one ripple-add):**

| Op | Action | Why it belongs in the 1-cycle set | Status |
|---|---|---|---|
| `TADD` / `TSUB` | add / negate+add | already there; `TSUB` rides free negate | present |
| `TROT` | ×ωᵏ, k mod 6 | the flagship: 6:1 mux + one add + wiring | present |
| `TCMP`/`TBR` | 3-way compare & branch | = `tand`/`tor` + equality AND-reduce; no sign handling; the branch predicate is the null test for free | **add** (stub in rust-mirror) |
| `TSHL`/`TSHR` | ×3ᵏ / ÷3ᵏ | fixed shift = pure rewiring; variable shift = a 3:1-mux tree (log₃N stages) | **add** |
| `TCVT` | binary↔ternary | the interface edge; cheap, already specified | **add** (implemented in rust-mirror) |
| `TNORM` | N = a²+ab+b² | already present; Z₆-invariant scalar | present |

**Multi-cycle (share one iterative datapath):**

| Op | Action | Why multi-cycle | Status |
|---|---|---|---|
| `TMUL` | scalar / Eisenstein multiply | `tmul_trits_opt` + `tmul_eisen_trits` are **already verified and sitting unused** (−14.6% Eisenstein, −9% norm); they just need an opcode wired in, then they can stay single-cycle at 6 trits | **wire in** |
| `TDIV` / `TMOD` | divide / symmetric remainder | **do not build a dedicated divider.** Emulate by a long-division microcode loop over `TCMP` + `TSHL` + `TSUB` (restoring/SRT inner loop is mostly the compare + free shift + negate-add that are already 1-cycle). Round-to-nearest falls out of symmetric digits | **defer / microcode** |

**The composition principle.** Split the ALU into two layers by *latency cost*: (a) the
**rewire layer** — negate, shift, rotate, compare, convert — whose cost is wiring + a mux tree +
at most one ripple add, all single-cycle; and (b) the **iterate layer** — multiply, divide —
which reuses (a) as its inner loop. Ternary earns this split because the rewire layer is where
its structural wins live (negate free, rotate exact, compare = min/max), while the iterate
layer is where it has *no* advantage and should spend as little dedicated silicon as possible.
Concretely: a balanced restoring-divide needs a per-step 3-way compare (already in the rewire
layer), a shift (free), and a subtract (negate+add, free) — so the *only* new hardware a
ternary divider would add is the iteration control, and that is better spent once in microcode.

---

## 4. Known-numbers ledger (cite, don't invent)

| Number | Value | Where it comes from | Calibration |
|---|---|---|---|
| Ternary 1-trit balanced FA transistors | **118 tr** (compound/hybrid), 188 tr (non-compound) | Automated synthesis of ternary netlists (SIMS 2020, CNTFET, [DOI 10.3384/ecp20176483](https://doi.org/10.3384/ecp20176483)); graph `docs/graphs/ternary-circuits/Automated_synthesis_of_netlists_for_ternary-valued.md` | DIRECT (their flow) / ANALOGY (CNTFET → our CMOS) |
| Ternary FA power-delay product | hybrid **1.10e-15 J** @500 MHz vs compound 1.44e-15 J | same paper, Table 3 | DIRECT (their flow) |
| Binary 1-bit full adder transistors | **~28 tr** static CMOS; ~14–20 tr optimized/TG | textbook (not measured here) | ANALOGY |
| Binary 3-way magnitude comparator | ~1 XNOR (≈4 tr)/bit (equality); ~12–20 tr/bit (full 3-way) | textbook | ANALOGY |
| Binary barrel shifter | ~2·N·log₂N tr (transmission-gate mux tree) | textbook | ANALOGY |
| Binary division area | "most complex basic arithmetic operation", ~3–5× a multiplier | [TalTech division thesis](https://digikogu.taltech.ee/en/Download/fb0e0c17-4233-41de-a682-c3c4534cd4c1) + textbook | ANALOGY |
| Our full CPU | 26,713 → **24,314 µm²**, 3,970 cells, 50.3 MHz, 1.60 mW (SkyWater 130 nm) | `docs/REAL_SKY130_SYNTHESIS.md` | DIRECT |
| Norm-identity multiplier saving | **−9.0% chip / −20.1% tnorm**; Eisenstein −14.6%; Karatsuba +28% (loses at N=6) | `docs/ENERGY_LAWS.md`, `rtl/tmul_opt.v` | DIRECT (measured) |
| Ternary cell energy | avg **2/3 wire/trit** vs binary 1 (saves 1/3) | `TernaryCell.lean` `average_energy`, `ternary_saves_third` | DIRECT (proved) |
| Z₆ units / rotation | exactly **6** units, closed under mul, = ωᵏ, angle-add mod 6 | `Rotation.lean`, `Gauge.lean` | DIRECT (proved) |
| ℤ[ω] Euclidean domain | `N(x % y) < N(y)`, `x/y = round(x·conj(y)/N(y))` | `EuclideanDomain.lean` `norm_mod_lt`, `div_def` | DIRECT (proved, math — not RTL) |
| min+max=sum (adder identity) | `min a b + max a b = a + b` on balanced trits | `ValuationEnergy.lean` `tritVal_min_add_max` | DIRECT (proved) |
| Comm energy floor | **0.081 pJ/bit** vs binary 0.748 (9.2×) | `docs/ENERGY_LAWS.md` | DIRECT (measured — *communication*, not compute) |

**Explicitly NOT claimed** (so it is not mistaken for a measured number): no per-cell
transistor count from our own Sky130 flow (only the whole-CPU 3,970 cells); no ternary-vs-binary
*gate-level* energy number (the corpus's "ternary saves energy" is conditional and corrected —
`docs/synthesis/ternary-circuits.md` §1); no ternary divider transistor count anywhere in the
corpus. Where a number is needed and absent, this report says so and falls back to an
order-of-magnitude ANALOGY from the binary baseline, which is the honest bound.
