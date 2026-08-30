# Hybrid Verdict — is the hybrid better than a pure-binary machine?

**2026-08-30 — adversarial referee pass over the hybrid thesis.** The hybrid thesis:
*ternary RAM + ternary transport + ternary address arithmetic (hex, free null, isotropic pod)
+ a BINARY ALU (because ternary compute is 1.48–2.0× worse).* This file is the fair-fight
referee: it does **not** ask whether the hybrid beats a full-ternary machine (it trivially
does, since it keeps compute binary and full-ternary loses compute). It asks the **killer
question**: does the hybrid beat a **pure-binary** machine that does *everything* in binary —
binary RAM, binary transport, binary hex-via-**axial-coordinates** — with the **same
low-swing lever** the ternary side is allowed? Every ternary part of the hybrid must beat its
*binary equivalent*, not a strawman.

**Calibration legend** (repo convention): **DIRECT** = proved in Lean / measured in
ngspice·yosys (re-checked here); **DERIVED** = arithmetic on DIRECT numbers; **SPECULATION** =
this referee's judgment about what the numbers *mean*.

Sibling inputs (read on disk): `FINAL_VERDICT.md`, `compute/energy-address-bench.md`,
`compute/address_space/bench_adversarial.md` (the previous referee's findings — read-tax
waiver, rotation strawman, 2.67× category error), `compute/address_space/emulation_geometry.md`,
`compute/address_space/{minimal_namespace,average_load,operation_cost,eisenstein_free_ops}.md`,
`compute/ground_up/fair_binary.md`, `compute/ground_up/meta_assumptions.md`, `compute/storage.md`,
`compute/control.md`. *(The six `hybrid/*.md` siblings named in the brief — `cut_line.md`,
`base6_interface.md`, `emulation_cost.md`, `hybrid_rtl.md`, `conversion_cost.md`,
`research_potential.md` — are **not on disk**; this is the first file in the directory and
stands on the ground-truth corpus above.)*

---

## 0. The killer question, made precise

> **Is the hybrid better than a pure-binary machine that does EVERYTHING in binary —
> binary RAM, binary transport, binary hex-via-axial-coordinates — and is granted the same
> low-swing lever?**

Three ternary parts are claimed to survive, and each must beat its **binary equivalent**, not
a flattering strawman:

| ternary part | claimed win | the honest binary equivalent it must beat |
|---|---|---|
| **transport** | free-null 2.67–6.32× | same wire, **matched 0.65 V low-swing** binary (0.216 pJ/bit) — the lever is radix-agnostic |
| **hex RAM** | isotropic lookup | **axial-coordinate** binary — which gets the `{0,±1}` pod for free (`emulation_geometry.md` §3) |
| **3ⁿ namespace** | 21 trits vs 32 bits | 32 physical bits vs **21 trits × 2 bits/trit = 42 physical bits** — the encoding, not the radix |

The previous referee already established the ground rules (`bench_adversarial.md`): the
rotation "win" is a coordinate choice, the read tax must be charged on writes too, and the
"2.67× namespace" was a value-width ÷ address-width category error. This file applies the same
three rules to the hybrid's *own* three wins.

---

## 1. Adjudicating each ternary win against the fair binary baseline

### 1a. Transport — CONDITIONAL WIN (null-heavy only; 2.67× matched, not 6.32×)

The champion is **0.081 pJ/bit** (low-swing × LC-resonant, `fair_binary.md` §3). Against the
honest baselines:

| baseline | binary cost | ternary ratio | what the ratio actually contains |
|---|---|---|---|
| natural single-ended (0→1 V) | **0.512 pJ/bit** | **6.32×** | mostly the low-swing + resonant lever — **radix-agnostic** |
| **matched low-swing (0→0.65 V)** | **0.216 pJ/bit** | **2.67×** | the residual once binary gets the same lever |
| uniform-trit ternary null-carrying link | 0.512 | **0.99× — a tie** | the free null *is* the ternary claim, and it vanishes at uniform trits |

Three facts kill the headline "6.32×":

1. **The low-swing lever is radix-agnostic** (DIRECT, `fair_binary.md` §5a): binary at 0.65 V
   drops to 0.216 pJ/bit *for free*. A pure-binary machine takes this lever, so the honest
   ternary-specific number is **2.67×, not 6.32×**.
2. **The free null is a workload claim, not a circuit claim** (DIRECT, `meta_assumptions.md`
   A3): at **uniform** trits the ternary null-carrying link is **0.515 pJ/bit = 0.99× — a
   tie** with binary. The null is free (~0.05 pJ receiver energy) **only when the data is
   null-heavy**; the *same* argument gives an idle binary link ~0 too (`fair_binary.md` §7.5).
3. **Even 2.67× is optimistic** (`fair_binary.md` §7.1/§7.4, DIRECT caveats): the strictly
   matched 0→0.5 V binary reference for the resonant B1 champion would shrink 2.67× **toward
   ~1.6×**; real sense-amp offsets (σ ≈ 5–20 mV) push the ternary low-swing floor to
   **0.22–0.35 pJ/bit — a *loss* vs 0.512**, while binary's receiver (a plain gate) pays no
   such offset. The energy-delay product is not yet folded in.

**Verdict:** transport is a **conditional win** — real, but only on **null-heavy** links, and
only **~2.67×** once the (radix-agnostic) low-swing lever is granted to both sides. It is the
one place the hybrid earns its keep, and it earns it *on the wire, by data statistics, not by
radix*.

### 1b. Hex RAM (isotropic lookup) — REAL BUT SMALL (~0.67–0.88×), and a geometry win, not a radix win

The claim is that a ternary hex RAM looks up the 7-cell pod isotropically — no row-parity
correction — while binary must fake the hex grid. The honest numbers (`emulation_geometry.md`
§1, `eisenstein_free_ops.md` §1c):

| op | ternary native | best binary | honest ternary delta |
|---|---|---|---|
| **hex_neighbor** | **2 adds**, uniform across all 6 | **2 adds + 1 parity check** (odd-r/odd-q offset correction) | **~0.67–0.88×** (2A vs 2A+1C) — one conditional, not a multiply |
| **rotation** (ωᵏ) | 1 add + free negate | axial binary: **1 add + 2's-complement negate — ≈ tie** | the free negate (one increment) |
| **negation** | 0 gates (wire swap, `gate_tneg` = 0 cells) | invert + increment (1 N-bit adder) | one increment |
| **hex_encode/hex_decode** (Szudzik) | 1 isqrt + M/A | **same Szudzik, binary-native — ~tie** | none (binary slightly *cheaper*: the multiply pays 1.72×/bit) |

Two things collapse here:

1. **The pod is free to *axial-coordinate* binary.** The 60° rotation is the *same* `{0,±1}`
   matrix on both sides (`emulation_geometry.md` §3) — "binary hex-via-axial-coordinates" gets
   the isotropic pod for free. The √3/closure gap only bites **Cartesian** `(x,y)` binary,
   which a fair baseline is not forced into (`bench_adversarial.md` §1.1). This is the rotation
   strawman, re-dispatched at the hybrid level.
2. **What actually survives is the offset correction + the free negate.** The offset-correction
   saving is **~0.67–0.88×** — one parity check per neighbor — and the free negate is **one
   increment**. Real, but they are *convenience* deltas (fewer conditionals, no sign bit), not
   a physical density or energy win.

**Verdict:** hex isotropic lookup is a **real but small** win — it buys *uniformity and a free
sign flip*, worth roughly 0.67–0.88× on the neighbor and one increment on negation, and
nothing on encode/decode. It is a **geometry/convenience** win, and the geometry itself is
recoverable by any binary machine that adopts axial coordinates.

### 1c. The 3ⁿ namespace (21 trits vs 32 bits) — CANCELLED by the 2-bit/trit encoding (42 > 32)

This is the advertised "exponential" win, and it is the one the hybrid most leans on. The
numbers:

| quantity | value | source |
|---|---|---|
| address namespace, symbols | **21 trits vs 32 bits** = 0.656 = 34.4 % fewer | DIRECT (`minimal_namespace.md` §3, `NAMESPACE_TABLE.md`) |
| … but the trit code is **2 bits/trit** | 21 trits = **42 physical bits** | DIRECT (`control.md` §1c: "12 trits = 24 physical bits"; `storage.md` §0 option B) |
| **physical bits, address** | **42 vs 32 → 1.31× WORSE** | DERIVED (42/32) |
| storage density, 2-bit trit | **26 % overhead, 1.26× worse** (12T/trit vs 6T/bit) | DIRECT (`storage.md` §4–§5) |
| native 3-level cell | **does not exist in the project** ("the big open one") | DIRECT (`storage.md` §5, `control.md` §2c) |
| 3ⁿ headroom actually exercised | **~99.99999997 % unused** (3 trits of a 21-trit box) | DIRECT (`average_load.md` §4) |

The "21 trits vs 32 bits" is a **logical information** count (1.585 bits/trit). It becomes a
*physical* win **only** with a native 3-level cell — and the project has none. On the hybrid's
own substrate (binary cells, 2 bits/trit), a ternary address of the u32 box costs **42 physical
bits vs 32**: a **1.31× physical *penalty***. The "26 % density overhead" of encoding (B) is the
same fact from the storage side (`storage.md` §0: "2 bits/trit = 1.585 bits of information →
26 % overhead, no win").

The escape hatch — native ternary SRAM/DRAM — is the one the corpus already closed: 3-level
cells pay Vdd/4 margins, a 2-threshold sense amp, and a ~2× refresh tax, and multi-level
storage **won commercially only in flash/signaling and was abandoned in DRAM/SRAM**
(`storage.md` §3). And even if it existed, `average_load.md` shows the actual workloads touch
**3 of 21 trits** — the "1.86×10¹¹ at n=64" is a *capacity* statement about the format, not a
*spent* advantage.

**Verdict:** the 3ⁿ namespace is **NOT a physical win** for the hybrid. It is cancelled by the
2-bit/trit encoding: **21 trits = 42 physical bits > 32 bits**, a 1.31× penalty. The namespace
"win" is a logical bookkeeping fact that the hybrid's binary substrate cannot redeem, and the
one path that could redeem it (native 3-level cells) is the project's explicitly-absent,
historically-losing "big open one."

---

## 2. The killer question, answered line by line

| hybrid part | beats the fair binary equivalent? | honest margin |
|---|---|---|
| **transport** (free null) | **Conditionally** — null-heavy only | 2.67× matched-swing (→ ~1.6× strictly matched; ≤1× with real SA offsets); 6.32× is the radix-agnostic lever |
| **hex RAM** (isotropic lookup) | **Marginally** — a convenience | ~0.67–0.88× offset-correction + 1 increment free negate; pod is free to axial binary |
| **3ⁿ namespace** (21 vs 32) | **No** — physically worse | 42 physical bits vs 32 = 1.31× penalty; 26 % storage overhead; ~0 % of the headroom is used |
| *(compute — already conceded)* | — | binary ALU, by the thesis's own admission (1.42–3.94×/bit ternary penalty, `FINAL_VERDICT.md`) |

Two of the three ternary parts fail the fair baseline outright; the third (transport) survives
only under a workload condition that a pure-binary machine with an idle link also enjoys.

---

## 3. The honest verdict

**The hybrid is a pure-binary machine wearing a ternary coat of paint — except for the wire.**

Concretely, of the hybrid's four components:

- **Binary ALU** — the hybrid already admits compute is binary; this is not a ternary "win," it
  is a *concession* that survives by definition. Nothing to falsify.
- **Ternary transport** — the one genuine, non-cancelling win: **~2.67×** at matched swing,
  **conditional on null-heavy data** (`A3`), and it is the *free null on an idle link*, not the
  radix, that produces it. This is a *signaling/energy* win, and it is real but narrow.
- **Ternary RAM** — the isotropic lookup saves **one parity check** (~0.67–0.88×) and a free
  negation; the pod and rotation are **free to axial-coordinate binary** (`emulation_geometry.md`),
  so the RAM's "ternariness" is a convenience, not a capacity. Its storage is 2-bit-encoded
  binary cells at a **26 % density penalty**.
- **Ternary address arithmetic (3ⁿ)** — **cancelled by the encoding.** 21 trits = 42 physical
  bits > 32, a **1.31× physical penalty**, and the headroom is ~unused (`average_load.md`).

So the hybrid does **not** buy any compute win (it cedes that to binary), does **not** buy any
storage-density win (it pays 26 % for the privilege of calling a bit-pair a trit), and its
address-arithmetic "exponential" is a logical quantity its own substrate cannot realize. What
it *does* buy is real but smaller than the thesis's headline: a **null-heavy transport edge**
and a **slightly more uniform hex address walk**.

---

## 4. The one honest sentence

> **What the hybrid actually buys is a real-but-conditional transport win — ~2.67× on
> null-heavy links at matched low-swing (not 6.32×, which is the radix-agnostic lever), plus a
> small hex-geometry convenience (one parity-check saving and a free negation that axial-coordinate
> binary gets almost entirely for free) — and what it does *not* buy is any compute win (the ALU
> is binary by concession) or any storage-density win (the 2-bit/trit encoding makes 21 trits
> cost 42 physical bits against 32, a 1.31× penalty).**

---

## Calibration summary

| claim | calibration | source |
|---|---|---|
| champion 0.081 pJ/bit; 6.32× vs 0.512; 2.67× vs 0.216 | **DIRECT** (ngspice) | `fair_binary.md` §3/§5 |
| low-swing lever radix-agnostic; binary 0.216 for free | **DIRECT** | `fair_binary.md` §5a |
| uniform trits → 0.515 pJ/bit = 0.99× tie; free null ~0.05 pJ conditional | **DIRECT** | `fair_binary.md` §3/§7.5; `meta_assumptions.md` A3 |
| strictly-matched 0.5 V binary → ~1.6×; SA offsets → 0.22–0.35 pJ/bit loss | **DIRECT** (caveats) | `fair_binary.md` §7.1/§7.4 |
| hex_neighbor 2A vs 2A+1C → ~0.67–0.88× | **DERIVED** (on DIRECT op counts) | `emulation_geometry.md` §1; `eisenstein_free_ops.md` §1c |
| axial binary rotation = 1 add + negate (≈ tie); free negate = 1 increment | **DIRECT** | `emulation_geometry.md` §3; `bench_adversarial.md` §1.1 |
| Szudzik encode/decode ~tie | **DIRECT** | `emulation_geometry.md` §1 |
| 21 trits vs 32 bits = 1.52× symbols (34.4 %) | **DIRECT** (Lean + arithmetic) | `minimal_namespace.md` §3; `NAMESPACE_TABLE.md` |
| 2 bits/trit → 21 trits = 42 physical bits vs 32 = 1.31× worse | **DERIVED** (42/32) | `control.md` §1c; `storage.md` §0 |
| 2-bit trit = 26 % overhead, 12T/trit = 1.26× worse | **DIRECT** | `storage.md` §4–§5 |
| native 3-level cell absent ("big open one"); MLC DRAM/SRAM abandoned | **DIRECT** | `storage.md` §3/§5; `control.md` §2c |
| 3ⁿ headroom ~99.99999997 % unused (3 of 21 trits) | **DIRECT** | `average_load.md` §4 |
| compute 1.42–3.94×/bit ternary penalty (hybrid already cedes to binary ALU) | **DIRECT** | `FINAL_VERDICT.md`; `word_fairfight.txt` |
| "hybrid = coat of paint except the wire" | **SPECULATION** (this referee's synthesis of the DIRECT/DERIVED above) | this file |
