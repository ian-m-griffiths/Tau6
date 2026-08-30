# Minimal Address Space per Operation

*The smallest 3ⁿ ternary namespace each Tau operation needs to be viable — and where
ternary beats binary. 2026-08-30.*

**Calibration.** Every number below is **DIRECT**: an integer power inequality or a
finite-cell count backed by a checked Lean theorem in `proofs/lean-src/hexagon/Hexagon/`,
or by the synthesizable RTL in `rtl/`. Where a claim in the request is *not* supported by
those sources, it is flagged in §4 rather than laundered.

---

## 0. The measuring stick

An address is a hex cell. The ternary namespace is **3ⁿ** (n trits); the minimal namespace
for a data structure of `C` cells is the smallest power of three that holds them:

```
trits(C) = ⌈log₃ C⌉   — the smallest n with 3ⁿ ≥ C
 bits(C) = ⌈log₂ C⌉   — the smallest k with 2ᵏ ≥ C
```

The saving is `(bits − trits) / bits`. The cell count `C` comes from the structure itself:

| structure | C | source |
|---|---|---|
| pod = center + 6 ring neighbors | 7 | `Pod.lean` `pod_card : pod.card = 7` |
| hex disk radius r | `3r²+3r+1` | `HexDisk.lean` `hexDiskCard_eq` |
| field store | 64 | `rtl/hex_field_accel.v` `cells [0:63]` |
| u32 box `[−2¹⁵, 2¹⁵−1]²` | 2³² | `Bijection.lean` `toNat_lt_two_pow_32`, `toNat_fin` |

---

## 1. The minimal-namespace table

| operation / structure | cells `C` | trits ⌈log₃C⌉ | 3ⁿ (namespace) | bits ⌈log₂C⌉ | 2ᵏ | symbol saving |
|---|---:|---:|---:|---:|---:|---:|
| **pod lookup** (center + 6) | 7 | **2** | 9 | 3 | 8 | 3→2 = 33.3% |
| **TGRAD** (pod footprint) | 7 | **2** | 9 | 3 | 8 | 33.3% |
| **TRELAX** (pod footprint) | 7 | **2** | 9 | 3 | 8 | 33.3% |
| **hex neighbor** (Z₆ direction) | 6 | **2** | 9 | 3 | 8 | 33.3% |
| **hex disk r=1** (= pod) | 7 | **2** | 9 | 3 | 8 | 33.3% |
| **hex disk r=2** | 19 | 3 | 27 | 5 | 32 | 5→3 = 40.0% |
| **hex disk r=3** | 37 | 4 | 81 | 6 | 64 | 6→4 = 33.3% |
| **hex disk r=4** | 61 | 4 | 81 | 6 | 64 | 33.3% |
| **field store** (64-cell RAM) | 64 | **4** | 81 | 6 | 64 | 6→4 = 33.3% |
| **full u32 addressing** | 2³² = 4,294,967,296 | **21** | 3²¹ = 10,460,353,203 | 32 | 2³² | 32→21 = 34.4% |

Read the last row against `docs/NAMESPACE_TABLE.md`: the "32 bits → 21 trits, 0.656,
34.4% saving" entry is exactly `⌈32·log₃2⌉ = 21`. The table above is the same radix
economy, applied per-operation rather than to the full 2ᵏ range.

**Two things the table makes explicit:**

1. **The saving is structural, not asymptotic.** Every row sits at 33–40% (the finite
   rounding of the `log₃2 = 0.6309` limit → 36.9%). The pod is 33.3%, the store is 33.3%,
   the u32 box is 34.4% — all essentially the same *one-third fewer symbols*, because
   `⌈·⌉` rounding has already died out by these widths (`NAMESPACE_TABLE.md` §1).
2. **The headroom.** The 3ⁿ namespace is always *larger* than the structure it holds:
   pod `9/7 = 1.29×`, store `81/64 = 1.27×`, u32 box `3²¹/2³² = 2.44×`. The u32 box is
   the loose one — you over-provision 2.44× of cells to win the 34.4% symbol saving.

---

## 2. The viability crossover (proved, exact)

Three Lean theorems pin the crossover to a single trit count:

| theorem | statement | meaning |
|---|---|---|
| `three_pow_gt_two_pow_succ n (hn : 2 ≤ n)` | `2^(n+1) < 3^n` | for **n ≥ 2**, n trits address *strictly more* cells than n+1 bits |
| `three_pow_lt_two_pow_succ_one` | `3^1 < 2^2` | at **n = 1**, 1 trit (3 cells) does *not* beat 2 bits (4 cells) |
| `two_pow_le_three_pow_pred k (hk : 3 ≤ k)` | `2^k ≤ 3^(k−1)` | for **k ≥ 3**, k bits fit in k−1 trits |

(all in `JunctionMemory.lean` for the first two, `FewerTrits.lean` for the third.)

**The crossover is exactly n = 2 trits.** At n = 2: `2³ = 8 < 9 = 3²` — two trits
out-address three bits. At n = 1: `3 < 4` — they do not. Equivalently (the `FewerTrits`
form), 3 bits = 8 cells already fit in 2 trits = 9 cells, but 2 bits = 4 cells do not fit
in 1 trit = 3 cells. So **n = 2 is the first symbol width where ternary is cheaper than
binary for the same cell count.**

In cell-count terms: a data structure with **5, 6, 7, 8, or 9 cells** costs 2 trits
(ternary) but 3 bits (binary). The pod — 7 cells — sits in exactly this window. There is
*no* sub-crossover operation in Tau's repertoire, because the smallest non-trivial
structure already lives on the winning side:

```
1 cell → 1 trit (3 states) vs 1 bit (2 states)      — ternary already denser (3 > 2)
7 cells → 2 trits (9 states) vs 3 bits (8 states)   — ternary cheaper (2 < 3)  ← crossover
```

The `n = 1` comparison is between *equal* symbol counts (1 vs 1), where `2 < 3` always
(`three_pow_gt_two_pow`, `TritPacking.lean`); the *crossing* is the "n trits vs n+1 bits"
question, and that crossing is n = 2.

---

## 3. The specific answer — minimal 3ⁿ per operation

**Pod = 2 trits.** `Pod.lean` proves `pod.card = 7` (and `norm_le_one_iff_mem`: the pod
is exactly the norm-≤-1 set, the 7 of the 9 axial `{−1,0,1}²` states, with the two
norm-3 states `(1,1)`, `(−1,−1)` as the "left the pod" carries). Since `3¹ = 3 < 7 ≤ 9 =
3²` and `2² = 4 < 7 ≤ 8 = 2³`, the pod needs **2 trits** (minimal 3ⁿ = 9) versus **3
bits** (minimal 2ᵏ = 8). Two trits, not one and not three.

**Field store = 4 trits.** `rtl/hex_field_accel.v` instantiates `reg [23:0] cells
[0:63]` — 64 cells (each 24 bits = 12 trits of *field value*, the 2-bit/trit code). Since
`3³ = 27 < 64 ≤ 81 = 3⁴` and `2⁵ = 32 < 64 ≤ 64 = 2⁶`, the store needs **4 trits**
(minimal 3ⁿ = 81) versus **6 bits**. (The RTL today addresses those 64 cells with a plain
6-bit binary index — `hex_field_accel.v` is explicit that "the cell ADDRESS … is a plain
binary cell index, NOT ternary." The 4-trit figure is the *minimal ternary namespace that
could* name the 64 cells, not what the current datapath does.)

**u32 box = 21 trits.** `Bijection.lean` proves the box `[−2¹⁵, 2¹⁵−1]²` addresses below
`2³²` (`toNat_lt_two_pow_32`) and into `Fin (2³²)` (`toNat_fin`): two u16 sign-folds
fill u32 *exactly* (`pair_lt_two_pow_32`, `u32::MAX = (2¹⁶−1)² + (2¹⁶−1) + (2¹⁶−1)`).
So `C = 2³² = 4,294,967,296`, and since

```
3²⁰ = 3,486,784,401  <  2³²  ≤  3²¹ = 10,460,353,203
```

the box needs **21 trits** (minimal 3ⁿ = 3²¹) versus 32 bits — a `32/21 = 1.52×` win, or
34.4% fewer symbols. *(Not 12 trits — see §4.)*

**The one-line answer.** *Minimal address space per operation = the smallest 3ⁿ that
holds the structure's cell count:* pod = 2 trits (3² = 9 ⊇ 7), field store = 4 trits
(3⁴ = 81 ⊇ 64), full u32 box = 21 trits (3²¹ ⊇ 2³²) — and every one of these is already
at or past the n = 2 crossover, so ternary is cheaper than binary at every rung of the
hierarchy.

---

## 4. Calibration — two conflations in the request, corrected

The request carries two numbers that the sources do not support; both are flagged rather
than repeated.

**"a word is a+bω (12 trits = 24 bits)" conflates the *value* width with the *address*
width.** "12 trits = 24 bits" is verbatim the **field-value** encoding in
`rtl/hex_field_accel.v` ("Field values are 12 trits = 24 bits … 2 bits/trit … 11=NEVER").
It is the width of a *stored number*, not of a cell name. The *address* of a cell is
`a + bω` with `a, b` each a signed 16-bit coordinate (`rtl/hex_encode.v`:
`input wire signed [15:0] a, b`), i.e. a **32-bit** address over the 2³²-cell box —
exactly the `Bijection.lean` object. The value is 12 trits; the address is 32 bits /
21 trits. Those are different quantities.

**"full u32 = 12 trits, wins by 2.67×" is wrong on both counts.**

- *12 trits is not the u32 namespace.* 3¹² = 531,441 cells ≈ 19.02 bits of information —
  four orders of magnitude short of 2³². The correct figure is ⌈log₃ 2³²⌉ = **21 trits**
  (matches `NAMESPACE_TABLE.md`'s "32 bits → 21 trits" row). 12 trits *would* be the
  answer for a 2¹⁶-cell structure (one u16 coordinate: `⌈log₃ 2¹⁶⌉ = 11`), or the
  per-coordinate width if each of `a, b` were a 6-trit word (3⁶ = 729); it is not the
  width of the 2³² box.
- *2.67× is not a namespace ratio.* `8/3 = 2.67×` is the **transport energy** win from
  `JunctionMemory.lean` `champion_vs_lowswing : binaryLowSwing / ternaryChampion = 8/3`
  (0.216 pJ/bit ÷ 0.081 pJ/bit) — a *pJ/bit* throughput figure, radix-agnostic, unrelated
  to addressing. The namespace win for the u32 box is `32/21 = 1.52×` fewer symbols
  (34.4%). The "2.67×" appears in the request only because `32/12 = 8/3` — an artifact of
  the wrong 12-trit denominator. The *genuine* 2.67× lives on the transport axis, and the
  *genuine* namespace win on this axis is the ~1.5× symbol saving (which, compounded over
  symbols, is the `(3/2)ⁿ` explosion — `(3/2)²¹ ≈ 4988×` at the u32 width).

**The clean version of the "largest wins most" claim.** The largest operation (full u32)
wins by the *same one-third* as the smallest, in symbols — but it wins by `(3/2)ⁿ` in
*addressable cells*, which is where the exponential lives. At 21 trits vs 32 bits, ternary
names `(3/2)²¹ ≈ 4988×` more cells than 21 bits would, while using 34.4% fewer symbols
than 32 bits. The "wins by 2.67×" framing belongs to transport, not to namespace.
