# Energy · Address Benchmark — the Tau ISA, native ternary vs binary emulation

**2026-08-30 (adversarial-referee corrections applied).** The flagship reference. One master
table: for every Tau operation, the native ternary cost vs the binary-emulation cost, the trit
vs bit address size, and the crossover where ternary outpaces binary. Then the crossover curve,
the "what ternary does natively" scoreboard, and the honest bottom line.

**Corrections applied over the first draft** (from `address_space/bench_adversarial.md`):

1. **Rotation is priced against the *fair* binary baseline (axial coordinates), not a Cartesian
   trig strawman.** A 60° rotation `ωᵏ` is a `{0, ±1}` coordinate permutation in *both* the
   Eisenstein basis and axial-coordinate binary — one add plus a sign flip. The real
   ternary-only delta is the **free negation** (0 cells vs invert+increment), *not* a 4× win.
   The √3/exactness gap remains true but only against **Cartesian `(x,y)`** binary, which is no
   longer the headline baseline.
2. **The 2-threshold READ tax is now charged on *writes* too** (register-file write and cell
   store each land a 3-level value → 2.0, vs 1.0 binary), not just operand reads. This flips the
   "compute ties ~1.0×" headline to the honest **binary beats ternary ~1.3–1.6× on compute**.
3. **The 2.67× namespace number is gone.** The correct namespace comparisons are **21 trits vs
   32 bits = 1.52×** (address) or **12 trits vs ~19.02 bits = 1.585×** (value info). The 2.67×
   that remains below is the **transport-energy** ratio (`champion_vs_lowswing = 8/3`), which is
   a different axis and correctly labeled as such.

**Sibling inputs.** `instruction_footprint.md` (the 19-op read/address/free split),
`minimal_namespace.md` (trit/bit per structure), `eisenstein_free_ops.md` (the free/cheap
geometry ops), `operation_cost.md` (the sense-work cost model), `address_space_verdict.md`,
`average_load.md`, `emulation_geometry.md` (the axial-coordinate fair baseline for rotation).

**Calibration legend** (copied from the repo convention):

- **DIRECT** — read verbatim from a file: an RTL cell count, a measured yosys/sky130 area, a
  checked Lean theorem statement.
- **DERIVED** — arithmetic on DIRECT numbers (a `⌈log₃N⌉`, a sum, a ratio).
- **SPECULATION** — a classification judgment about what the numbers *mean* (the
  read-bound/address-bound/free split, "which ops does ternary win").

---

## 0. The measuring stick

Two axes, kept separate because they are *not commensurate* (see `address_space_verdict.md`):

- **Cost** (sense-work): `cost = 2.0·(reads + writes) + 0.5·cheap`, `free = 0`. One *read* of a
  ternary value = **2 thresholds** vs **1** for a binary read — the per-sense form of the
  2-threshold tax (`ThresholdLowerBound.lean` `ternary_binary_ratio = 2·ln2/ln3 ≈ 1.26×` **per
  bit**, DIRECT). **One *write* of a ternary value (register-file write or cell store) also pays
  2.0**, because it must land/resolve a 3-level value exactly as a read does — this is the
  adversarial correction #2; binary writes pay 1.0. One *cheap* op (norm/conj/dot/wedge/add cone
  over already-sensed trits) = 0.5. *Free* = rotation `ωᵏ`, negation (wire swap), neighbor
  `+unit` — cost 0 *to compute*, but their output is a ternary value that pays the 2.0 write tax
  when it is landed. Units below are **sense-units `u`**, 1 u = one binary read.
- **Address size** (namespace): `trits = ⌈log₃N⌉` vs `bits = ⌈log₂N⌉` for a structure of `N`
  cells. This is the axis where ternary wins: `log₃2 = 0.6309` → **36.9 % fewer symbols**,
  compounding as `(3/2)ⁿ`.

Binary op-counts (the "emulation" column) come from `eisenstein_free_ops.md` §1–§4 and
`emulation_geometry.md`, priced against the **fair axial-coordinate binary**: rotation = **1 add
+ negate** (the same `{0,±1}` matrix, *not* 4 mul + trig), norm = **2 mul + 1 add**, dot =
**2 mul + 1 add**, cross = **2 mul + 1 sub**, complex conjugate = **1 negate**, add = **1 add**.
The 4-mul + 2-add + √3 figure appears *only* for the Cartesian comparison and is labeled as such.

---

## 1. THE MASTER TABLE (all 19 operations)

One row per Tau operation. `cost` is native ternary sense-work `2(r+w) + 0.5c` (free = 0 to
compute, write tax charged) and, where the sibling model priced it, the binary side. `trits |
bits` is the *address* size (`⌈log₃N⌉ | ⌈log₂N⌉`) of the operation's namespace `N`. `crossover
N` is the global first strict win (see §2). Device counts are DIRECT from the RTL.

| operation | native ternary cost | binary emulation cost | trits | bits | crossover N |
|---|---|---|---|---|---|
| **TADD** `rd=ra+rb` | 2r·1w·1c = **6.5 u** (2×6 `tadd1`) | 2 binary adds; **cheaper/bit** (adder 3.94×/bit, `word_fairfight.txt`) | 2 | 3 | 3 |
| **TSUB** `rd=ra−rb` | 2r·1w·1c+free-neg = **6.5 u** (negate = wire swap, 0 gates) | 2 adds + 2 two's-complement negates (invert+incr) | 2 | 3 | 3 |
| **TROT** `rd=ωᵏ·ra` | 1r·1w·1free = **4.0 u** (1 add + free negate, **no mul**, but pays 2.0 write) | **axial: 1 add + 1 negate (invert+incr) — ≈ tie**; Cartesian: 4 mul + 2 add + √3 (NOT EXACT) | 2 | 3 | 3 |
| **TNORM** `N=a²+ab+b²` | 1r·1w·1c = **4.5 u** (2–3 mul + 2 add) | 2 mul + 1 add (`x²+y²`) — cheaper, but *not* multiplicative / +√ for length | 2 | 3 | 3 |
| **LDI** `rd=(imm,0)` | 0r·1w = **2.0 u** (s2t6 relabel, but lands a value) | load-immediate (1 write = 1.0 u — binary *cheaper*) | 2 | 3 | 3 |
| **TMUL** `rd=ra·rb` | 2r·1w·3c = **7.5 u** (3 scalar products, Karatsuba) | 4 mul + 2 add (Cartesian complex) — **cheaper/bit** (mult 1.72×/bit) | 2 | 3 | 3 |
| **TCONJ** `rd=(a+b,−b)` | 1r·1w·1c+free-neg = **4.5 u** (1 add + free negate) | **1 negate** — binary is *cheaper* | 2 | 3 | 3 |
| **TDOT** `Re(z·conj w)` | 2r·1w·1c = **6.5 u** (3 mul + 2 add) | 2 mul + 1 add (2D dot) — ~tie / binary cheaper | 2 | 3 | 3 |
| **TWEDGE** `Im(z·conj w)` | 2r·1w·1c = **6.5 u** (2 mul + 1 sub) | 2 mul + 1 sub (2D cross) — ~tie | 2 | 3 | 3 |
| **TSYMDOT** `N(z+w)−N(z)−N(w)` | 2r·1w·1c = **6.5 u** (free w/ dot+wedge, same 4 products) | **no integer analog** (symmetric polarization) | 2 | 3 | 3 |
| **HLT** | **0.0 u** (no-op) | no-op (tie) | — | — | — |
| **TGRAD** `∇F=(div,curl)` | 7r·1w·6c = **19.0 u** (48 `tadd1` = 2×(3 adders @8 trits)) | 7 reads @1.0 + 6 adds + 1 write = **~14–17 u** (binary *cheaper*: read+write tax dominates) | 2 | 3 | 3 |
| **TRECON** `∇⁻¹J` | 1r·7w(store) = **16.0 u** (wires + 4-trit fit check, *no arithmetic*; stores already write-charged) | 7-address scatter (tie; address-bound both) | 2 | 3 | 3 |
| **TRELAX** `u'=u/3+Σnb/9` | 7r·1w·1c = **16.5 u** (46 `tadd1`; **÷3,÷9 = free shifts**) | 7 reads + 5 adds + **explicit ÷3,÷9** (NOT shifts → division, NOT EXACT) | 2 | 3 | 3 |
| **hex_encode** `(a,b)→u32` | **0 reads** (1 square + compare + add; combinational, no register landing) | same (Szudzik pair is binary-native) — tie | **21** | **32** | 3 |
| **hex_decode** `u32→(a,b)` | **0 reads** (1 `isqrt`, ~16 serial stages) | same (binary-native `isqrt`) — tie | **21** | **32** | 3 |
| **hex_neighbor** `(a,b)+ωᵏ` | **0 reads** (2 uniform adds + re-encode) | 2 adds + **odd-r/odd-q row correction** (hex-on-array) | 2 | 3 | 3 |
| **hex_pod_addr** (pod lookup) | **0 reads** (1 `isqrt` + 6×2 adds + re-encode) | 7-pt stencil on square array (index correction) | 2 | 3 | 3 |
| **ternary_link** (transport) | 1 latch read + **12 nulls free** = **~2 u** | same width, **no null savings** (0.216–0.512 pJ/bit) | 12 | 20 | 3 |

**Namespace `N` per row** (the address size the `trits|bits` columns encode):
register ops → 8 regs (`2 | 3`), pod ops + `hex_neighbor`/`hex_pod_addr` → 7 cells / Z₆ (`2 | 3`),
`hex_encode`/`hex_decode` → u32 box `2³²` (`21 | 32`), `ternary_link` → 1 word `3¹² = 531 441`
value states (`12 | ⌈log₂3¹²⌉ = 20`). **Every operation's namespace is ≥ 7 cells, hence already
past the global crossover (N = 3).** The 12-trit *value* width (24 bits = 19.02 info bits) is
deliberately listed *only* for the link, where it is the payload; it is **not** the address width
of the other rows (`minimal_namespace.md` §4).

Three rows that carry the whole argument, read side-by-side:

- **TROT** — demoted from the old draft's "biggest win". Against the **fair axial binary** the
  rotation is **≈ a tie** (1 add + negate both sides); ternary's only radix-specific edge is the
  **free negation** (0 cells vs invert+increment). The "1 add vs 4 mul + 2 add + √3" gap exists
  *only* against Cartesian `(x,y)` binary, which a fair baseline is not forced into.
- **TRELAX** — the one op whose emulation is *not even exact*: ternary `÷3`, `÷9` are free
  right-shifts (`3 = 10₃`); binary must divide by 3 (or multiply by a non-terminating reciprocal).
  This is a genuine radix win and is *not* demoted.
- **hex_encode / hex_decode** — the only ops where the ternary content is *pure namespace*: the
  address logic (`isqrt`, Szudzik) is binary-native and identical in both engines; the ternary win
  is `21 trits vs 32 bits`, nothing else.

---

## 2. THE CROSSOVER CURVE — `⌈log₃N⌉` vs `⌈log₂N⌉`

The crossover is where `⌈log₃N⌉ < ⌈log₂N⌉`. Computed exactly (DERIVED):

| N (cells) | `⌈log₃N⌉` trits | `⌈log₂N⌉` bits | verdict |
|---:|---:|---:|---|
| 1 | 0 | 0 | tie (`3⁰ = 2⁰ = 1`) |
| 2 | 1 | 1 | tie |
| **3** | **1** | **2** | **ternary wins (first strict win)** |
| 4 | 2 | 2 | tie (`2² = 4`) |
| 5 | 2 | 3 | win |
| 6 | 2 | 3 | win |
| 7 (pod) | 2 | 3 | win |
| 8 (regfile) | 2 | 3 | win |
| 9 | 2 | 4 | win |
| 64 (field store) | 4 | 6 | win |
| `2³²` (u32 box) | 21 | 32 | win |

**Asymptotic.** `⌈log₂N⌉ / ⌈log₃N⌉ → log₂3 = 1.58496… ≈ 1.585×` — binary needs **1.585× as many
symbols (bits) as ternary (trits)** in the large-`N` limit; equivalently ternary needs
`log₃2 = 0.6309 = 1/1.585` of the symbols, i.e. **36.9 % fewer** (DERIVED from `log₂3`; the
1.585 bits/trit constant is `TritPacking.lean`'s header, DIRECT).

**Lean theorems that pin it** (all DIRECT, checked, zero `sorry`):

| theorem | statement | what it proves |
|---|---|---|
| `three_pow_gt_two_pow_succ` (`JunctionMemory.lean` L452) | `2^(n+1) < 3^n` for `n ≥ 2` | for **n ≥ 2 trits**, ternary addresses *strictly more* than **n+1 bits** |
| `three_pow_lt_two_pow_succ_one` (`JunctionMemory.lean` L466) | `3^1 < 2^2` | at **n = 1**, 1 trit (3 cells) does **not** beat 2 bits (4 cells) |
| `two_pow_le_three_pow_pred` (`FewerTrits.lean` L31) | `2^k ≤ 3^(k−1)` for `k ≥ 3` | **k bits fit in k−1 trits** — from 3 bits up, ternary needs one fewer symbol |
| `three_pow_gt_two_pow` (`TritPacking.lean` L67) | `2^n < 3^n` for `n > 0` | strict per-rail density |
| `three_pow_div_two_pow` (`JunctionMemory.lean` L371) | `3^n/2^n = (3/2)^n` | the namespace ratio compounds **geometrically**, ×3/2 per rail |
| `namespace_outruns_linear_cost` (`JunctionMemory.lean` L439) | `∀C, ∃n, C·n < 3^n` | the exponential namespace outruns any linear read overhead |

**Two crossover facts, stated precisely so they are not conflated:**

1. **First strict win = N = 3.** At `N = 3`: `⌈log₃3⌉ = 1` (3¹ = 3 ≥ 3) but `⌈log₂3⌉ = 2`
   (2¹ = 2 < 3 ≤ 4 = 2²). One trit names three cells; one bit does not. This is exactly the
   boundary the Lean theorem `three_pow_lt_two_pow_succ_one` (`3 < 4`) sits on, and it is the
   mechanical answer to "min address size where `⌈log₃N⌉ < ⌈log₂N⌉`".
2. **The prompt's "first-strict-win at N = 5" is the first N in the 2-trit-vs-3-bit window, not
   the first strict win.** `three_pow_gt_two_pow_succ` at `n = 2` gives `3² = 9 > 2³ = 8`: a
   structure of **5, 6, 7, 8, or 9 cells** needs 2 trits but 3 bits. `N = 5` is the *first* of
   that window (and the pod at 7, the register file at 8, both sit inside it). But under the
   column's own definition (`min N` with `⌈log₃N⌉ < ⌈log₂N⌉`), `N = 3` wins first — `N = 3` is
   *not* a tie, so "ties at N = 1,2,4" already implies the first strict win is `N = 3`.
   Calibrated as DERIVED; the correction is flagged, not hidden.

**Ties are exactly N = 1, 2, 4** (the only cells counts where `⌈log₃N⌉ = ⌈log₂N⌉`); every other
`N ≥ 3` is a strict ternary win, and the win width is **one symbol** in each rounding window,
widening to 1.585× in the limit.

---

## 3. WHAT TERNARY DOES NATIVELY — the honest scoreboard

The operations where binary emulation is qualitatively *different* — more ops, not exact, or not
closed — versus the operations where ternary ≈ binary (arithmetic).

### (a) MORE ops — binary pays extra explicit logic

| op | ternary (native) | binary (emulation) | source |
|---|---|---|---|
| **TROT** (60° rotation) | **1 add + free negate, no multiplier** | **axial coords: 1 add + 2's-complement negate (≈ tie)**; Cartesian: 4 mul + 2 add + trig | `Gauge.lean` `units_eq_omega_pow`; `eisenstein_free_ops.md` §1b; `emulation_geometry.md` §3 |
| **TSUB / TCONJ negation** | free wire swap (`gate_tneg` = **0 cells**, `gate_area.txt`) | two's-complement invert + increment (1 N-bit adder) | `cpu.v` `fneg6`; `gate_area.txt` |
| **hex_neighbor** | **2 uniform adds**, isotropic | 2 adds + **odd-r/odd-q row correction** (hex-on-rectangular array) | `HexIsotropy.lean` `neighbors`; `eisenstein_free_ops.md` §1c |
| **TSYMDOT** (symmetric correlation) | **free** with dot+wedge (same 4 products) | **no integer analog** (raw `Re(z·conj w)` is half-integral, `dot_swap`) | `SymDot.lean` `symdot_eq_two_dot_add_wedge` |

### (b) NOT EXACT — binary emulation cannot be an integer operation

| op | the exactness gap |
|---|---|
| **TROT** (√3) | `cos60° = ½`, `sin60° = √3/2` — **irrational** in **Cartesian** coordinates: an exact integer 60° rotation is not an integer operation there (needs float or ℚ(√3), which *is* the Eisenstein structure). **This gap does not apply to axial-coordinate binary**, which applies the same `{0,±1}` matrix exactly. |
| **TRELAX** (÷3, ÷9) | ternary `u/3`, `Σnb/9` are **right-shifts** (`3 = 10₃`, free wire re-wiring, `trelax.v` L10–11). Binary ÷3/÷9 is *not* a shift — it is a real division (or multiply-by-non-terminating-reciprocal), i.e. rounding error. |
| **TNORM** (exact length) | `N = a²+ab+b²` is an **exact integer** squared-distance; the exact Cartesian length needs a √. |
| **TWEDGE** (exact skew) | ternary wedge is an **exact integer** curl; a binary angle-form cross needs `sinθ` (float). |

### (c) NOT CLOSED — binary emulation leaves the integer lattice

| op | the closure gap |
|---|---|
| **TROT** | *In Cartesian `(x,y)`:* a 60° rotation maps `ℤ²` **off** `ℤ²` (√3/2 coefficients). *In axial `(a,b)`:* the rotation is a bijection of `ℤ²` onto itself for **both** engines — the closure win is a **coordinate choice**, not a radix win. Ternary/Eisenstein rotation is a bijection of `ℤ[ω]` onto itself (`units_closed_under_mul`, `Rotation.lean`). |
| **TNORM** | `x²+y²` does **not** count hex rings and is **not** multiplicative; `N` counts the lattice's squared-radius levels (`N = 1,3,4,7,9,12,…`) and satisfies `norm_mul` (`Conventions.lean`). |
| **TGRAD/TRELAX** | `div ⊕ curl` is the discrete echo of `Σ(O−E) = 0`; the **center drops out of ∇** (`Σωᵏ = 0` gauge) — no Cartesian square-stencil analog exists without the Z₆ structure. |

### The other side — where ternary loses on compute (arithmetic), honestly

These ops are **not** cheaper in ternary; with the write tax charged, the per-bit measured
reality is a **loss** (`rtl/README.md` caveat 1, `word_fairfight.txt`,
`ThresholdLowerBound.lean`):

| op | honest verdict |
|---|---|
| **TADD / TSUB** | mod-3 sum is **1.42×/bit**; adder **3.94×/bit** area (50.98 vs 12.95 µm²/bit). Binary add wins. |
| **TMUL** | multiplier **1.72×/bit** (287.74 vs 167.22 µm²/bit). Binary multiply wins. |
| **TNORM / TDOT / TWEDGE** | op count ~tie (norm even costs +1 cross-term for the non-orthogonal `{1,ω}` basis); the gain is *exactness/algebra*, not cheaper arithmetic — and the read+write tax still makes the landed op ~1.3× dearer. |
| **TCONJ** | binary complex-conjugate is **1 negate** — *cheaper* than the Eisenstein 1 add + 1 negate. |
| **TROT** | against **axial binary** the rotation is a tie; the ternary-only residue is the free negate (one increment), and the read+write tax still makes the landed op ~1.3× dearer. |
| **TGRAD / TRELAX** | 7 ternary reads × 2 thresholds + a 2.0 write ≈ 16 u of tax vs 7 binary reads + 1.0 write ≈ 8 u — the read+write tax *dominates*; binary wins. |
| **hex_encode / hex_decode / hex_pod_addr** | the `isqrt` + Szudzik pairing are **binary integer ops** already; both engines pay the same. The only ternary content is the geometry and the 21-vs-32-bit namespace. |

**Scoreboard tally** (SPECULATION, the classification): ternary **strictly wins** on ~4–5
geometry/transport items (TRELAX's free ÷3/÷9 shift, hex_neighbor's isotropy, hex_pod_addr,
ternary_link, and the free negation on TSUB/TCONJ/TROT) and on the **namespace** — **ties** ~8
(LDI, HLT, TSYMDOT, TRECON, hex_encode, hex_decode, and the exact-but-equal GA
norm/dot/wedge/TROT-vs-axial-binary) — and **loses per bit** on ~6 (TADD, TSUB, TMUL, TNORM,
TCONJ, TGRAD/TRELAX's reads+writes). This is exactly the `instruction_footprint.md` split:
**47.4 % address/free vs 52.6 % read-bound**, and the read-bound majority is where ternary pays
the 1.26× per-bit tax, the measured 1.42–3.94× gate penalty, *and* the newly-charged write tax.

---

## 4. THE HONEST BOTTOM LINE

**The summed ratio (native vs emulated).** Summing the 19 per-op native sense-work costs with
the write tax now charged (DERIVED from `operation_cost.md` §2.1 + the six address/transport
rows):

```
native ternary total ≈ 108.5 sense-units  (over 19 ops: 106.5 for the 13 register/pod ops
                      + ~2.0 transport; write tax now charged)
binary emulation    ≈ 1/1.3× … 1/1.6× of that — i.e. ternary LOSES ~1.3–1.6× on compute
                      (binary reads 1.0 / writes 1.0 / cheap 0.5 vs ternary 2.0 / 2.0 / 0.5)
namespace           = 21 trits vs 32 bits = 0.656 = 34.4 % fewer symbols (1.52×)
transport           = 2.67× (vs low-swing) … 6.32× (vs natural single-ended)
```

The ratio is **~1.3–1.6× ternary LOSS on the compute axis** — the free negation/÷3/isotropy and
the free address ops are *not enough* to cancel the 2-threshold read tax once it is charged on
**both** reads and writes. The real, non-cancelling advantages live on the **other two axes**:
the **namespace** (`21 trits vs 32 bits`, compounding to `(3/2)ⁿ`) and the **transport**
(`champion_vs_lowswing = 8/3`, `champion_vs_natural = 512/81`, `JunctionMemory.lean`). The
measured per-bit compute penalty (1.42× sum, 3.94× adder, 1.72× multiplier) plus the write tax
is real and is **not** hidden — it is the reason the summed compute ratio is a ~1.3–1.6× loss,
not a win and not a tie.

**The one-sentence answer** to "for each operation, at what address size does ternary cost less
than binary, and by how much":

> **Ternary costs less than binary in address symbols at every size `N ≥ 3` — first strict win at
> `N = 3` (1 trit vs 2 bits), ties only at `N = 1, 2, 4`, widening to `log₂3 ≈ 1.585×` fewer
> symbols in the limit — and it wins on transport (2.67–6.32×) and on free negation (0 gates vs
> invert+increment); but on per-operation *compute* the two engines do **not** tie — binary beats
> ternary **~1.3–1.6×**, because the 2-threshold read tax, charged on reads *and* writes, is only
> partly offset by the free address ops (rotation/negation/neighbor) and the measured 1.42–3.94×/bit
> arithmetic penalty, so ternary "outpaces" binary only for the ~4–5 geometry/address/transport
> items (led by TRELAX's free ÷3/÷9), never for generic add/multiply — and the rotation "win" is
> a coordinate choice (axial binary gets the same {0,±1} matrix), not a radix win.**

---

## Calibration summary

| claim | calibration | source |
|---|---|---|
| 19 ops, read-bound 52.6 % / address 26.3 % / free 21.1 % | DIRECT+SPECULATION | `instruction_footprint.md` §5 |
| sense-work model `2(r+w) + 0.5c`, free = 0 to compute, write tax charged; per-op costs 0–19 u | DIRECT/DERIVED | `operation_cost.md` §1–§2 (write-tax corrected) |
| native total ≈ 108.5 u over 19 ops (106.5 register/pod + ~2.0 transport; write tax charged) | DERIVED (sum of per-op rows) | this file §4 |
| binary beats ternary ~1.3–1.6× on compute (read+write tax) | DERIVED | `bench_adversarial.md` §2.2/§4; `operation_cost.md` §3 (corrected) |
| read tax 1.26×/bit = `2·ln2/ln3`; 2.0 per read *and* per write | DIRECT (Lean) | `ThresholdLowerBound.lean` `ternary_binary_ratio` |
| adder 3.94×/bit, multiplier 1.72×/bit, mod-3 sum 1.42×/bit | DIRECT (measured) | `word_fairfight.txt`, `rtl/README.md` |
| `gate_tneg` = 0 cells; `tadd1` = 146.39 µm² vs binary FA 33.78 µm² | DIRECT (measured) | `gate_area.txt` |
| TROT = 1 add; **axial binary rotation = 1 add + negate (≈ tie)**; Cartesian = 4 mul + 2 add + √3 | DIRECT | `eisenstein_free_ops.md` §1b; `emulation_geometry.md` §3; `Gauge.lean` |
| TRELAX ÷3,÷9 = free shifts | DIRECT | `trelax.v` L10–11 |
| TGRAD = 48 `tadd1`, TRELAX = 46 `tadd1`, TRECON = wires only | DIRECT | `grad_recon.v` L61–64, `trelax.v` L23–24 |
| pod = 7 cells, field store = 64, u32 box = 2³² | DIRECT (Lean/RTL) | `Pod.lean` `pod_card`, `hex_field_accel.v`, `Bijection.lean` `toNat_lt_two_pow_32` |
| namespace 21 trits vs 32 bits (0.656, 34.4 %, 1.52×); value 12 trits vs 19.02 bits (1.585×) | DERIVED | `minimal_namespace.md`, `NAMESPACE_TABLE.md` |
| crossover first strict win N = 3; ties N = 1,2,4; asymptotic 1.585× | DERIVED + DIRECT (Lean) | this file §2; `JunctionMemory.lean` `three_pow_gt_two_pow_succ` / `three_pow_lt_two_pow_succ_one`, `FewerTrits.lean` |
| transport 2.67× (low-swing) / 6.32× (natural) — a *transport* ratio, not namespace | DIRECT (Lean) | `JunctionMemory.lean` `champion_vs_lowswing` / `champion_vs_natural` |
