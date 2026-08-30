# Address-Space Verdict — what the Tau engine actually costs, per operation

**2026-08-30.** The synthesis that answers the principal's real question: not
"how many joules per bit" but **"what does an operation cost in address space?"**
The engine computes on *addresses*, not bits — so the cost of an operation is the
cost of *naming and walking cells*, and the win is the size of the *namespace*
those names live in, not the energy of the wire that carries them.

Every number is **DIRECT** (proved in Lean — `lake build Hexagon.JunctionMemory`
green, zero `sorry` — or measured and cited) unless tagged **OURS** (our framing
of a proved fact) or **BENCHMARK** (an illustrative size, not a proved structure).
Sibling inputs: `instruction_footprint.md`, `minimal_namespace.md`,
`average_load.md`, `eisenstein_free_ops.md`, `operation_cost.md` (written in
parallel; this file stands alone on the raw artifacts if they are absent).

---

## The three questions, answered in one table each

### (a) Minimal address space per operation to be viable

"Viable" = the smallest number of trits that *name* the cells an operation
touches, so the operation has a dense-enough namespace to exist. Three structures
matter:

| structure | cells | binary symbols | ternary symbols | utilization (ternary) | proof |
|---|---|---:|---:|---:|---|
| **pod** (radius-1 hex ball) | 7 | ⌈log₂7⌉ = **3 bits** | ⌈log₃7⌉ = **2 trits** | 7/9 = **78%** (2 spare carry states) | `Pod.lean` `pod_card = 7`; `HexDisk.lean` `hexDiskCard_one = 7` |
| **field store** (8×8 patch) | 64 | 2⁶ = **6 bits** | 3⁴ = 81 ≥ 64 → **4 trits** | 64/81 = **79%** | arithmetic + `TritPacking.lean` `four_trits_fit_seven_bits` pattern; region size is BENCHMARK |
| **word** (operand / instruction) | 3¹² = 531,441 | ⌈log₂(3¹²)⌉ = **20 bits** | **12 trits** | see (b) — *mostly unused* | `control.md`, `trit_tricks.md` (12 trits = 24 bits, 19.02 info bits) |
| **u32 address box** (the full namespace) | 2³² = 4.29×10⁹ | **32 bits** | ⌈32·log₃2⌉ = **21 trits** | see (b) — *≈unused* | `Bijection.lean` `toNat_lt_two_pow_32`; `NAMESPACE_TABLE.md` |

**Two calibrations the principal should see, stated flat:**

1. **"12 trits" is the *word*, not the address box.** The 12-trit word
   (`control.md`, `CPU_INTEGRATION.md`: "Word = 12 trits = 24 bits = an Eisenstein
   integer `a + b·ω`") is the *operand width*, packed 2 bits/trit into a u32
   (24 of 32 bits used). The **u32 address box** — the `2³²`-cell namespace the
   `Bijection.lean` bijection actually covers — needs **21 trits**, not 12.
   Conflating the two is the single most likely misquote in this whole area; keep
   them as separate rows.
2. **The pod is exactly the crossover.** `JunctionMemory.lean`
   `three_pow_gt_two_pow_succ`: `2^(n+1) < 3ⁿ` for `n ≥ 2`, and
   `three_pow_lt_two_pow_succ_one`: `3¹ < 2²`. So **1 trit loses** (3 cells < 4 =
   2 bits), and **2 trits overtake** (9 cells > 8 = 3 bits) — the pod's 2 trits
   sit *precisely* where the ternary namespace first beats binary even with
   binary's extra digit of head start. The engine's natural operand granularity
   (2–4 trits) is not arbitrary; it is the crossover region.

### (b) Average load — how much of the namespace a real workload touches

The honest answer is a *utilization* curve, and it falls off a cliff:

| granularity | full namespace | what a real workload touches | utilization | verdict |
|---|---:|---:|---:|---|
| pod (2 trits) | 3² = 9 | 7 cells | **78%** | near-full — the win is *real* here |
| field store (4 trits) | 3⁴ = 81 | 64 cells | **79%** | near-full |
| opcode field (3 trits) | 27 | 12 opcodes | **44%** | beats binary (6/16 = 37.5%) |
| register field (3 trits) | 27 | 8 registers | **30%** | *worse* than binary (8/8 = 100%) — 19 wasted slots |
| word (12 trits) | 531,441 | operands are 6-trit (729) / 8-trit (6561) fields | **0.14–1.2%** | the word is 4–5× wider than the values it carries |
| u32 box (21 trits) | 4.29×10⁹ | a field sweep of hex radius r=100 → 30,301 cells; r=1000 → 3.0×10⁶ | **7×10⁻⁶ to 7×10⁻⁴** | the box is *≈entirely unused headroom* |

**The honest reading.** The ternary namespace win is a *headroom* win, and that
headroom is **almost entirely unused**. The engine only exercises a meaningful
fraction of the namespace at the **2–4 trit granularity** (pod 78%, field 79%).
At the word level the utilization drops to ~1%; at the u32-box level it is
millionths. So the `(3/2)ⁿ` exponential is real but the engine *rides it for its
first two or three doublings and never touches the rest*. This is not a defect —
the point of headroom is that it is there when the address set grows — but anyone
quoting "1.86×10¹¹ at n=64" as *usable capacity* is flattering the engine.

(Utilization arithmetic: `hexDiskCard(r) = 3r² + 3r + 1` from `HexDisk.lean`;
r=100 → 30,301 cells; the u32 box is a hex disk of radius ≈ 37,836.)

### (c) Average cost per instruction, in address-space terms

Per instruction, the cost splits by *what the instruction does*:

| instruction class | address-space cost | the honest number | source |
|---|---|---|---|
| **fetch/decode** (the instruction stream itself) | 12 trits = **24 physical bits** @2 bits/trit, carrying 19.02 info bits vs binary's 16 bits | **1.26× worse per info-bit** (`24/19.02 = 2/log₂3` — the 2-bits-per-trit encoding tax) | `control.md` §1c; `ThresholdLowerBound.lean` |
| **read** (per trit, per cycle) | 2 thresholds vs binary's 1, per 1.585 bits of info | **1.26× per bit, constant** (`2·ln2/ln3`) | `ThresholdLowerBound.lean` `ternary_binary_ratio` |
| **generic arithmetic** (TADD / TMUL / TDIV) | the 1.26× read tax *plus* gate area | adder **3.94×/bit**, multiplier **1.72×/bit** (shift-add), floor 1.26×, native floor 1.5–2× | `word_fairfight.md`; `FINAL_VERDICT.md` |
| **geometry/address** (TROT/TNEG/neighbor/TCONJ/TDOT/TWEDGE/TNORM) | **~1 op each**, already in RTL; no separate circuit | rotation = mod-6 index add; negation = free digit swap; neighbor = 2 integer adds; conjugate = 1 add + 1 neg; dot+wedge = **one** TMUL | `CPU_INTEGRATION.md` opcode table; `Rotation.lean`, `Conjugate.lean`, `DotWedge.lean` |

**The line, drawn where it actually is:** for the *address/geometry* half of the
ISA the per-instruction cost is one integer op — the read tax (1.26×) is the only
ternary surcharge, and it is a **fixed per-read overhead**. For the *generic
compute* half, the read tax *compounds with* a 1.7–3.9× gate penalty, and ternary
loses per bit. The two halves do not have the same cost model, and treating them
as one "average instruction" is the error that makes the numbers look like they
"don't mean much."

---

## The decisive reframe — exponential namespace, constant read tax

**The address-space win is `(3/2)ⁿ` — exponential in the number of symbols. The
read cost is `1.26×` — a constant. They are not commensurate: one compounds, the
other does not.**

Made precise with the proved theorems:

- `JunctionMemory.lean` **`three_pow_div_two_pow`** (DIRECT): `3ⁿ/2ⁿ = (3/2)ⁿ` —
  the namespace ratio grows *geometrically*, factor `3/2` per rail.
- `ThresholdLowerBound.lean` **`ternary_binary_ratio`** (DIRECT):
  `(2/ln3)/(1/ln2) = 2·ln2/ln3 = 2/log₂3 = 1.26186…` — the read tax has **no `n`
  in it**; it is
  a fixed real constant, and `FINAL_VERDICT.md` correction #5 shows it is
  representation-independent (sign+magnitude still needs `⌈log₂3⌉ = 2` decisions).
- `JunctionMemory.lean` **`namespace_outruns_linear_cost`** (DIRECT):
  `∀C, ∃n, C·n < 3ⁿ`. The *read* overhead is **linear** in word length (`C·n`
  thresholds); the *namespace* is **exponential** (`3ⁿ`); the exponential outruns
  any linear overhead beyond a finite word size (the proof crosses at `n = C`,
  i.e. at ~2–3 trits when `C` is the 2-threshold read cost — again the pod).

So "per operation, in address-space terms": an operation that addresses `n` trits
pays a read cost `C·n` (linear) and acquires a namespace `3ⁿ` (exponential). The
1.26× read tax multiplies the *linear* cost — it is a **fixed per-read overhead,
not a per-address cost**. The per-address win compounds as `(3/2)ⁿ`:

| trits addressed (`n`) | namespace win `(3/2)ⁿ` | net vs the 1.26× read tax | structure |
|---:|---:|---:|---|
| 1 | 1.5 | 1.19× | (still wins: 1.5 > 1.26) |
| 2 | 2.25 | 1.78× | the pod |
| 4 | 5.06 | 4.01× | the field store |
| 12 | 129.7 | 1.03×10² | the word |
| 21 | 4.99×10³ | 3.95×10³ | the u32 box |
| 64 | 1.86×10¹¹ | 1.48×10¹¹ | the `NAMESPACE_TABLE` headline |

The engine wins *by namespace headroom*: the read tax is a constant toll on every
read, but the address space it buys grows exponentially, so the tax is drowned as
the addressed structure grows from pod → field → word → box. This is the theorem
`namespace_outruns_linear_cost` made concrete, and it is why "compute on
addresses, not bits" is the correct cost model for this engine — and why per-bit
energy alone is the wrong measure.

---

## The "easier operations" point, honestly

Rotation / negation / neighbor / norm / conjugate / dot / wedge **are**
structurally easier in Eisenstein — this is real, and it is proved:

| operation | the Eisenstein structure | Lean theorem | cost |
|---|---|---|---|
| rotation | Z₆ units; rotation = index permutation, no trig | `Rotation.lean` `units_card = 6`, `units_closed_under_mul` (the Z₆ group) | mod-6 add, free |
| negation | balanced ternary sign flip | `CPU_INTEGRATION.md` TSUB = "free digit-swap" | 0 gates |
| neighbor | `(a,b) + (Δa,Δb)` | `CausalLattice.lean` `causal_isotropy` (exactly 6 unit neighbors); `hex_mmu.md` §2 | 2 integer adds |
| norm | `N(a,b) = a²+ab+b²`, multiplicative | `Conventions.lean` `norm_mul` | 1 multiply (TNORM, in RTL) |
| conjugate | `conj(a,b) = (a+b, −b)`, a ring automorphism | `Conjugate.lean` `conj_involutive`, `conj_mul`, `mul_conj_eq_norm` | 1 add + 1 neg |
| dot **and** wedge | `z·conj w = ⟨dot, wedge⟩` — **one** geometric product yields **both** | `DotWedge.lean` `gp_decomp`, `wedge_antisymm`, `dot_sq_add_wedge_sq` | 1 multiply (TMUL) + coordinate split |

**But draw the line where the "simple numbers" stop being meaningless:**

- **For geometry/address work** (naming cells, walking the lattice, `∇F = div⊕curl`,
  the pod ops) the principal is **RIGHT**: the operations collapse to integer
  coordinate arithmetic with no transcendental functions and no separate
  circuits, so per-bit energy is the wrong measure — the *structural* win is the
  thing that matters, and it is the addressing win, not an energy win.
- **For generic per-bit arithmetic** (TADD/TMUL/TDIV, bit-level logic) the
  principal is **WRONG**: the 2-threshold tax is `1.26×` and it is
  representation-independent (`ThresholdLowerBound.lean`
  `ternary_worse_than_binary`; `FINAL_VERDICT.md` correction #5), and on silicon
  it shows up as a measured **1.7–3.9×/bit** area penalty (`word_fairfight.md`).
  No Eisenstein trick removes it, because it is charged on the *read path*, not
  the *address path*. Here the simple numbers mean *exactly* what they say:
  ternary generic compute loses by a bounded, real, per-bit factor.

So "the simple numbers don't mean much" is **true for the geometry/address
workload and false for generic compute**, and the boundary between the two is
precisely whether the operation is *naming a cell* (address-bound → ternary wins)
or *reading a bit* (read-bound → ternary pays the constant tax).

---

## The bottom line

"Viable" for the Tau engine means **address-bound**: a workload whose primitive
operation is naming and stepping through Eisenstein cells — pods, fields,
neighbors, gradients — and whose cost is therefore the *namespace* it addresses,
not the bits it reads. For that workload the address-space cost genuinely favors
ternary: the `3ⁿ` namespace gives exponentially more names per symbol (`(3/2)ⁿ`),
the geometry ops are structurally free, and the 1.26× read tax is a fixed
per-read toll that `namespace_outruns_linear_cost` proves the exponential
outruns. For the *opposite* workload — read-bound generic compute, where every
operation is a bit-level read — the same 1.26× tax plus a measured 1.7–3.9× gate
penalty means the address-space cost does **not** favor ternary, and no amount of
namespace headroom pays it back. And the honest asterisk on the whole thesis:
the win is **mostly unused headroom** — the engine actually *exercises* only ~79%
of a pod, ~79% of a 4-trit field, ~1% of its 12-trit word, and ~10⁻⁶ of its u32
box. The address-space win is real, it is exponential, and it is correct — but
today it is a *reserve*, not a *spent* advantage, and it only converts into a
working win for the address-bound half of the ISA, never for read-bound generic
compute.
