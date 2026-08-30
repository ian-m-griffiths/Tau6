# The Cut Line — where each Tau op runs native-ternary vs binary-emulated

**2026-08-30.** The hybrid binary/ternary processor's *routing table*: for each of the 19 Tau
operations, the decision — run it on the native-ternary datapath or on the binary-emulated
side — read directly off the measured charts and the master table. This file is the answer to
"draw the optimal cut line." It takes the verdict already in hand and states the *boundary*
precisely, so the fuzzy ops (rotation, conjugate, norm) get a rule, not a shrug.

**Sibling inputs (all read on disk).** `compute/energy-address-bench.md` (the master table +
crossover curve + honest bottom line), `compute/address_space/` (the six docs:
`operation_cost.md`, `eisenstein_free_ops.md`, `emulation_{arithmetic,geometry,field}.md`,
`minimal_namespace.md`, `address_space_verdict.md`, `average_load.md`, `instruction_footprint.md`,
`crossover_curve.md`, `bench_adversarial.md`), and `scripts/plot_combined.py` — the generator of
`address_space/combined_advantage.png`, whose per-op cost model and annotations are the chart's
source of truth. The deeper skeptical pass (`hybrid_verdict.md`) asks whether the hybrid beats a
*pure-binary* machine; this file is the narrower, prior question — *given* the hybrid, where does
each op belong.

**Calibration legend** (repo convention): **DIRECT** = proved in Lean / measured in
yosys·ngspice / read verbatim from a file; **DERIVED** = arithmetic on DIRECT numbers;
**SPECULATION** = the classification judgment (which side an op belongs on), which is this
document's explicit job.

---

## 0. The verdict already in hand (one line)

The `combined_advantage.png` flat band (DIRECT from `plot_combined.py`, y = `1 − ternary/binary`,
POSITIVE = ternary wins):

- **Ternary WINS flat** — `ternary_link` **+23 % = 0.77×** (transport, 50 % null),
  `hex_neighbor` **+33 % = 0.67×**, `hex_pod_addr` **+23 %→+12 % = 0.77→0.88×** (decaying).
- **Ternary TIES** — `hex_encode`, `hex_decode` (Szudzik pairing and the `isqrt` are
  binary-native; both engines pay the same integer arithmetic).
- **Ternary LOSES flat** — **13 ops at −50 %…−100 % = 1.48–2.0×** (the whole value-sensing
  compute band: add, mul, GA, field-calculus).

The chart's loss band runs **1.48× (TCONJ, DERIVED: `5.92n / 4.00n` from the TCONJ row —
`reads=1, writes=1, comp=(1.92n, 2.00n)`) to 2.0× (the read+write-tax asymptote that TADD/TSUB/
TROT/LDI/TRECON/TGRAD approach: `2.0·(reads+writes)·n / 1.0·(reads+writes)·n → 2.0`)**. This is
the chart's exact statement; the independent sense-unit model (`energy-address-bench.md` §4,
`operation_cost.md` §3) lands the same conclusion as a **~1.3–1.6× summed ternary loss** on
compute (binary reads/writes at 1.0 vs ternary 2.0, cheap 0.5), and the measured per-bit gate
penalties — adder **3.94×/bit**, multiplier **1.72×/bit**, mod-3 sum **1.42×/bit** (DIRECT,
`word_fairfight.txt`, `rtl/README.md`) — are the mechanism behind the chart's 1.48–2.0×.

---

## 1. The datapath zones, in order, with the measured verdict per zone

The cut is drawn *along the datapath*, not per-instruction in isolation. Six zones, in the order
a value travels, each with its measured ternary-vs-binary verdict from the charts.

### 1. RAM storage → **TERNARY** (the `3ⁿ` namespace)

The win here is **address symbols, not value density**. A cell name costs `⌈log₃N⌉` trits vs
`⌈log₂N⌉` bits: pod (7 cells) **2 vs 3 = 33.3 % fewer**, field store (64) **4 vs 6 = 33.3 %**,
u32 box (`2³²`) **21 vs 32 = 1.52× / 34.4 % fewer**, widening to **1.585× / 36.9 %** in the limit
(DIRECT, `minimal_namespace.md` §3, `crossover_curve.md` §3; `log₂3 = 1.58496…`). Every structure
sits past the `n = 2` trit crossover (`2³ = 8 < 9 = 3²`, DIRECT `JunctionMemory.lean`
`three_pow_gt_two_pow_succ`).

Two honest asterisks, stated flat (they do not move the cut but must not be laundered):

- **Value-storage density is *not* the win.** The 2-bits-per-trit code carries 19.02 info bits in
  24 physical bits → **1.26× worse per info-bit** (`address_space_verdict.md` §c, `2/log₂3`); a
  physical native 3-level cell is the project's explicitly-absent "big open one" (`storage.md`).
  The namespace win is on the *cell-name* axis, which is why storage stays ternary.
- **The headroom is ~99.99999997 % unused today** — real workloads touch **3 of 21 trits**
  (DIRECT, `average_load.md` §4). The win is a *reserve*, not a spent advantage.

### 2. Transport wire → **TERNARY** (free null)

`ternary_link` = **0.77× at 50 % null** (0.394 vs 0.512 pJ/bit, DIRECT `plot_combined.py`), and
the null-saturated limits are **2.67×** (`champion_vs_lowswing = 8/3`, matched low-swing 0.216 vs
0.081 pJ/bit) and **6.32×** (`champion_vs_natural = 512/81`, vs natural single-ended). The
mechanism: a **null trit costs ≈ 0.05 pJ on the wire vs ≈ 1.20 pJ for a ±1 toggle** (DIRECT,
`instruction_footprint.md` §0). The win is **conditional on null-heavy data** (`hybrid_verdict.md`
§1a: at uniform trits it is 0.99× — a tie); it is the one ternary part that earns its keep, and
it earns it *on the wire, by data statistics*.

### 3. Address arithmetic → **TERNARY** (isotropic `+unit`, free negation)

- `hex_neighbor` = **0.67×** — 2 uniform axial adds vs binary's 2 adds **+ odd-r/odd-q row-parity
  correction** (DIRECT `plot_combined.py`: `2.0n / 3.0n`; `eisenstein_free_ops.md` §1c).
- `hex_pod_addr` = **0.77→0.88× decaying** — `(n²+12n)/(n²+18n)`: the 6×2 axial adds beat the
  7-point stencil's per-neighbor parity fix, and that linear advantage is diluted as the shared
  `n²` (Szudzik re-encode) dominates (DIRECT `plot_combined.py`).
- **free negation** — `gate_tneg` = **0 cells / 0.000 µm²** vs two's-complement invert+increment
  (DIRECT `gate_area.txt`): the one true *radix* win, and it lives entirely inside address
  arithmetic.
- `hex_encode`/`hex_decode` = **tie** on compute (Szudzik pair + `isqrt` are radix-neutral; the
  decode `isqrt` is "the ONE non-trivial op in the whole datapath," ~16 serial stages, identical
  in both engines — DIRECT `emulation_geometry.md` §1, `instruction_footprint.md` §3). They stay
  on the ternary side *only* for the 21-vs-32-trit namespace, not for any compute saving.

### 4. Geometry / GA → **the subtle middle** (see §3, drawn precisely)

`TROT`, `TCONJ`, `TNORM`, `TDOT`, `TWEDGE`, `TSYMDOT` are **free-to-tie to compute in both bases**
(axial-coordinate binary gets the same `{0,±1}` rotation matrix and the same 4-product dot/wedge/
symdot sharing, radix-independently — DIRECT `emulation_arithmetic.md` §2/§5), **but every landed
op pays the 2.0 read+write tax**. Verdict: **binary once a value is sensed; ternary only as pure
combinational address logic.** The full rule is §3.

### 5. Field calculus → **BINARY** (the reduction is identical in both bases)

`TGRAD` and `TRELAX` are each **6 signed adds in binary exactly as in ternary** (DIRECT,
`emulation_field.md` §1; the ternary full adder is measured **1.92× the energy** of a binary FA).
The 7-cell gather then pays the 2× tax on **7 reads + 1 write**: `TGRAD` = **19.0 u vs binary
~14–17 u**, `TRELAX` = **16.5 u** (chart ~1.67–1.97×). The single ternary radix micro-win nested
here is `TRELAX`'s **÷3/÷9 = free trit right-shifts** (`3 = 10₃`; binary pays ~4–6 real division
ops — DIRECT `trelax.v` L10–11/61–62, `emulation_field.md` §3). The cut: do the 6-add reduction
in binary; **keep the ÷3/÷9 as a ternary shift only if the value already lives in ternary**.

### 6. Generic ALU → **BINARY** (measured loss)

`TADD`/`TSUB`/`TMUL` carry the whole 1.48–2.0× band: adder **3.94×/bit** (50.98 vs 12.95 µm²/bit),
multiplier **1.72×/bit** (287.74 vs 167.22), mod-3 sum **1.42×/bit** (DIRECT `word_fairfight.txt`,
`rtl/README.md`), on top of the 2.0 read + 2.0 write tax. Nothing Eisenstein about an add or a
multiply removes the tax — it is charged on the *read path*, not the *address path*
(`address_space_verdict.md` §c).

---

## 2. THE CUT

> **Ternary for [storage, transport, address arithmetic]; binary for [generic ALU, GA compute,
> field-calculus reduction].**

The justification is the two flat bands side by side, and they are not commensurate in *sign*:

| side | what lives there | the number |
|---|---|---|
| **TERNARY** | transport `ternary_link`, address `hex_neighbor`, `hex_pod_addr`, `hex_encode`/`hex_decode`, the scatter `TRECON`, the `3ⁿ` RAM namespace | **0.67×, 0.77×, 0.77→0.88× wins** (and 21 vs 32 = 1.52× on namespace) |
| **BINARY** | generic ALU (`TADD/TSUB/TMUL`), GA compute (`TNORM/TCONJ/TDOT/TWEDGE/TSYMDOT`), field reductions (`TGRAD/TRELAX`) | **1.48–2.0× loss** (the flat −50 %…−100 % band) |

Ternary's wins are *flat* and *positive* — they survive to any word width, because they are
address/transport savings, not per-bit arithmetic. Ternary's losses are *flat* and *negative* —
the 2.0 read+write tax is a fixed constant (`2·ln2/ln3 ≈ 1.26×` per bit, DIRECT
`ThresholdLowerBound.lean`), and the measured 1.42–3.94×/bit gate penalties compound with it,
never cancel it. A cut that draws *any* value-sensing op onto the ternary side buys a
guaranteed 1.48–2.0× loss for, at best, one free increment (the negation) — a losing trade. A cut
that draws the address/transport/namespace ops onto the binary side throws away a flat 0.67–0.77×
win for nothing. The cut is therefore forced: **the sign of the band, not its size, decides the
side.**

---

## 3. The subtle middle — geometry ops drawn precisely

The three ops that *look* like they could go either way — **rotation (`TROT`), norm (`TNORM`),
conjugate (`TCONJ`)** — are the boundary. The rule that resolves all three:

> **A geometry op is ternary if and only if it is a *pure combinational address transform* —
> zero operand senses, zero result landings. The instant it reads a 3-state operand or lands a
> 3-state result, it crosses to binary, because its compute advantage over binary is at most one
> increment, while its read+write tax is a fixed 2.0 vs 1.0.**

Apply it op by op:

| op | free-to-compute in BOTH bases? (compute verdict) | landed value cost (read+write tax) | the line |
|---|---|---|---|
| **TROT** (rotate ωᵏ) | **Yes — ≈tie.** 1 add + free negate (ternary) vs 1 add + 2's-complement negate (axial binary). The only ternary delta is the free negate = **one increment** (DIRECT `bench_adversarial.md` §1.1, `emulation_geometry.md` §3). | 1r·1w → **4.0 u** vs binary ~3.0 u (**~1.33× dearer**) | **Ternary only as re-indexing** (the mod-6 angle add + `{0,±1}` permute inside `hex_neighbor`/`hex_pod_addr`, where nothing is sensed); **binary as the `rd=ωᵏ·ra` register op**, which senses `ra` and lands `rd`. |
| **TNORM** (norm) | **Yes — tie.** `(a+b)²−ab` is ring-agnostic (DIRECT `emulation_arithmetic.md` §3); binary `x²+y²` is even **1 add cheaper**, and the extra cross-term from `ω²=ω−1` costs ternary +1 add. | 1r·1w → **4.5 u** vs binary ~3.5 u | **Binary** once it reads operands. Ternary only as the exact ring-counting `N=a²+ab+b²` *inside* address/geometry combinational logic (it counts the hex rings, `N = 1,3,4,7,9,12,…`). |
| **TCONJ** (conjugate) | **No — binary is strictly *cheaper*.** Ternary `(a+b,−b)` = 1 add + free negate; binary complex-conjugate = **1 negate** — the Eisenstein `ω̄=1−ω` coupling costs ternary +1 add (DIRECT `eisenstein_free_ops.md` §2a). | 1r·1w → **4.5 u** vs binary ~2.5 u (1 negate = 1 cheap op) — the sense-unit model's ~1.8×; the *chart* model prices the binary side as the Eisenstein conjugate (1 add + 1 negate) and lands **1.48×**, the band's floor | **Binary, unconditionally** as a value op. Ternary conjugate exists only as the projection that *splits* a geometric product inside fused address logic. |

`TDOT`/`TWEDGE`/`TSYMDOT` fall the same way, without even the "free-to-compute" ambiguity: the
4-product `ga_split_trits` sharing is **radix-independent** (a binary ALU computes `dot`, `wedge`,
`symdot` from the same `ac, ad, bc, bd` — DIRECT `emulation_arithmetic.md` §5), the wedge is an
**exact integer skew in both bases** (no float `sinθ` once the coordinates are in hand — the
"float sinθ" in `eisenstein_free_ops.md` §2c is a cosmetic strawman the referee already flagged),
and the landed ops pay **6.5 u vs ~3.5–5.5 u**. They are binary.

**The precise line, in one sentence:** rotation, norm, and conjugate (and dot/wedge/symdot) are
free-to-tie to *compute* in both bases, so they are worth ternary **only as the combinational
address logic** that never senses a stored value; as soon as any of them becomes a value
operation — an operand read or a result write — it pays the fixed 2.0 read+write tax for an
advantage of at most one increment, and it belongs on the **binary** side.

---

## 4. The cut line — one rule + all 19 ops

**One-line rule:**

> **Ternary until a 3-state value must be sensed; binary from the first sense (or landing) onward.**

The 19 distinct ISA operations, sorted into the two sides (TROT is listed once, flagged as the
one op that sits astride the line):

### Ternary side — never senses a stored value

| op | zone | verdict | the number |
|---|---|---|---|
| **ternary_link** | transport | **WIN** | **0.77×** (50 % null); 2.67–6.32× null-saturated |
| **hex_neighbor** | address | **WIN** | **0.67×** (2 uniform adds vs 2 adds + parity) |
| **hex_pod_addr** | address | **WIN** | **0.77→0.88×** decaying |
| **hex_encode** | address/namespace | **TIE** (Szudzik binary-native) | + 21 vs 32 trits (1.52×) |
| **hex_decode** | address/namespace | **TIE** (`isqrt` binary-native) | + 21 vs 32 trits (1.52×) |
| **TRECON** | field (scatter) | **address-bound** | 0 adds both bases; the win is the free `+unit` 7-address scatter |
| **TROT** *(as address relabel only)* | address/geometry | **free** | 0 cells negate; 1 add, no operand sense |

### Binary side — senses or lands a 3-state value

| op | zone | verdict | the number |
|---|---|---|---|
| **TADD** | generic ALU | **LOSS** | chart ~1.98×; adder 3.94×/bit |
| **TSUB** | generic ALU | **LOSS** | chart ~1.58× (free negation ≠ free read+write) |
| **TMUL** | generic ALU | **LOSS** | chart ~1.7–1.9×; multiplier 1.72×/bit |
| **TNORM** | GA | **LOSS** (tie compute) | landed 4.5 u vs ~3.5 u; binary `x²+y²` is 1 add cheaper |
| **TCONJ** | GA | **LOSS** (binary cheaper) | **1.48×** — the band's floor |
| **TDOT** | GA | **LOSS** (tie compute) | 6.5 u vs ~3.5–5.5 u |
| **TWEDGE** | GA | **LOSS** (tie compute) | 6.5 u vs ~3.5–5.5 u |
| **TSYMDOT** | GA | **LOSS** (sharing radix-independent) | 6.5 u; "free with dot+wedge" is true in *both* bases |
| **TGRAD** | field calculus | **LOSS** | **19.0 u** vs 14–17 u; 6 signed adds both bases |
| **TRELAX** | field calculus | **LOSS** *except ÷3/÷9* | **16.5 u**; keep the free ÷3/÷9 shift ternary if the value already is |
| **TROT** *(as landed register op)* | GA | **~tie→LOSS** | 4.0 u vs ~3.0 u (the flip side of the ternary row) |
| **LDI** | storage (landing) | **neutral→binary** | 2.0 u vs 1.0 u; no compute to win back |

### Neither side

| op | verdict | note |
|---|---|---|
| **HLT** | **tie** | no-op; zero reads, zero writes |

**Count check:** 7 ternary + 12 binary + 1 neutral = 19 distinct ops; TROT appears in both lists
because it is the *one* op whose placement is a function of "address relabel vs landed value,"
which is exactly the line this document exists to draw.

---

## Calibration summary

| claim | calibration | source |
|---|---|---|
| ternary_link +23 % (0.77×), hex_neighbor +33 % (0.67×), hex_pod_addr +23 %→+12 % (0.77→0.88×), 13 ops −50 %…−100 % (1.48–2.0×) | **DIRECT** (chart annotations) | `plot_combined.py`; `combined_advantage.png` |
| loss-band floor 1.48× = TCONJ (`5.92n/4.00n`); asymptote 2.0× = read+write tax | **DERIVED** (on the DIRECT TCONJ/TADD rows) | `plot_combined.py` |
| summed compute loss ~1.3–1.6× (binary 1.0/1.0/0.5 vs ternary 2.0/2.0/0.5) | **DERIVED** | `energy-address-bench.md` §4; `operation_cost.md` §3 |
| read/write tax 2.0 per read *and* per write; 1.26×/bit = `2·ln2/ln3` | **DIRECT** (Lean) | `ThresholdLowerBound.lean`; `bench_adversarial.md` §2.2 |
| adder 3.94×/bit, multiplier 1.72×/bit, mod-3 sum 1.42×/bit | **DIRECT** (yosys/sky130) | `word_fairfight.txt`; `rtl/README.md` |
| `gate_tneg` = 0 cells; `tadd1` 146.39 µm² vs binary FA 33.78 µm² | **DIRECT** | `gate_area.txt` |
| namespace 21 vs 32 = 1.52×; pod 2 vs 3 = 33.3 %; limit 1.585× / 36.9 %; crossover `n = 2` trits | **DIRECT/DERIVED** | `minimal_namespace.md` §3; `crossover_curve.md` §3; `JunctionMemory.lean` |
| transport 2.67× (`champion_vs_lowswing = 8/3`), 6.32× (`champion_vs_natural = 512/81`), null ≈ 0.05 pJ vs 1.20 pJ | **DIRECT** (Lean/ngspice) | `JunctionMemory.lean`; `instruction_footprint.md` §0 |
| rotation ≈ tie vs axial binary (1 add + negate both sides); free negate = 1 increment | **DIRECT** | `emulation_geometry.md` §3; `bench_adversarial.md` §1.1 |
| Eisenstein multiply = complex multiply **+1 add** (`+bd` cross-term) | **DIRECT** | `emulation_arithmetic.md` §4; `Conventions.lean` L50–51 |
| TGRAD/TRELAX = 6 signed adds both bases; ternary FA = 1.92× energy | **DIRECT** | `emulation_field.md` §1; `trelax_measured.md` §5.2 |
| ÷3/÷9 = free trit shifts (`trelax.v` L10–11, 61–62); binary ÷3 ≈ 2–3 ops, ÷9 ≈ 4–6 | **DIRECT** | `emulation_field.md` §3 |
| TGRAD 19.0 u / TRELAX 16.5 u / TRECON 16.0 u / TMUL 7.5 u / TADD·TSUB·TDOT·TWEDGE·TSYMDOT 6.5 u / TNORM·TCONJ 4.5 u / TROT 4.0 u / LDI·ternary_link 2.0 u / HLT·hex 0.0 u | **DIRECT** | `energy-address-bench.md` §1 master table |
| the cut (storage/transport/address = ternary; ALU/GA/field-reduction = binary) and the one-line rule | **SPECULATION** (this file's classification, forced by the DIRECT/DERIVED bands) | this file |
