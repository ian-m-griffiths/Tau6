# Bench Adversarial — is the energy-address benchmark fair, or flattering?

**2026-08-30 — adversarial referee pass over the "per-operation native-ternary cost vs
binary-emulation cost" benchmark.** Verdict first, evidence after: the benchmark's
*infrastructure* is honest — every number it tags DIRECT checks out against a Lean theorem
(`lake build Hexagon.JunctionMemory` green, zero `sorry`) or a yosys/iverilog RTL log — but
its *headline* numbers flatter ternary in four specific, falsifiable ways, and none of the
four is a matter of taste: each is either a strawman binary, a waived read tax, a "tie"
label over a measured loss, or a namespace figure inflated by a category error.

**A necessary first finding: the file named in the brief does not exist.** There is no
`energy-address-bench.md` on disk. The benchmark the brief describes — *"per Tau operation,
a native ternary cost vs a binary emulation cost, plus the trit/bit address size and
crossover"* — is realized as the six sibling files written the same day:
`operation_cost.md` (the per-op cost table and the only place ternary and binary costs are
priced head-to-head), `eisenstein_free_ops.md` (the binary-equivalent inventory),
`minimal_namespace.md` + `address_space_verdict.md` (trit/bit size and crossover),
`average_load.md`, `instruction_footprint.md`. This audit prices the benchmark *as it
actually exists in those files*, with `operation_cost.md` as the load-bearing table.

**Calibration legend.** `DIRECT` = proved in Lean or measured in an RTL/yosys/ngspice log
(and re-checked here); `DERIVED` = arithmetic on DIRECT numbers; `SPECULATION` = this
referee's judgment about what the numbers mean.

---

## 1. The binary emulation: fair, or a strawman?

### 1.1 ROTATION — STRAWMAN (the biggest one in the benchmark)

`eisenstein_free_ops.md` §1b prices the binary equivalent of a 60° rotation as *"rotation
matrix: 4 mul + 2 add + √3 (irrational → not exact in ℤ)"* — i.e. **Cartesian
`(x cosθ − y sinθ, x sinθ + y cosθ)` with trig**. The headline table then advertises
*"4 mul + 2 add + trig → 1 add — the biggest win"* and the §4 summary repeats *"deletes a
full trig rotation matrix (and its √3 exactness problem)."*

That binary is a strawman. The **best reasonable binary** stores the same lattice point in
**axial coordinates `(a,b)`**, where the 60° rotation is the *same* `{0, ±1}` matrix the
ternary side uses: `ωᵏ·(a,b)` is `(−b, a+b)`, `(−(a+b), a)`, … — one add plus a negation.
The doc *itself* says so, twice, in plain prose (§0 fact 1: *"a binary CPU using the same
axial coordinates gets the same saving"*; §1b calibration: *"A binary ALU that stores
(a,b) axial coordinates and applies the {0,±1} matrix gets the same 1-add rotation"*).

So the honest saving for rotation is **not** "4 mul + 2 add + trig → 1 add". It is
**1 add + free-negate (ternary) vs 1 add + 2's-complement-negate (binary)** — a *tie* to
within one increment. The only genuinely radix-specific residue is that balanced-ternary
negation is a wire swap (`tneg = {t[0],t[1]}`, DIRECT `trit_functions.vh` L55–58, 0 cells
DIRECT `rtl/gate_area.txt` `gate_tneg = 0.000 µm² / 0 cells`) while binary negation is
invert+increment. That is real but it is *one increment*, not a trig matrix. The benchmark
flags this in prose and keeps the strawman in the headline table — the exact pattern a
fair-fight referee must call.

`operation_cost.md` §3(b) repeats the leak: *"in Cartesian form it is irrational, √3/2."*
The axial-coordinate binary is never the baseline in the priced table.

### 1.2 NEIGHBOR — FAIR (correctly a tie)

`eisenstein_free_ops.md` §1c prices the binary hex-neighbor honestly: *"a square-grid
neighbor is also two adds … a hexagonal grid indexed on a rectangular array needs the
odd-r/odd-q offset-row correction."* The saving is correctly reduced to **isotropy / the
missing row-parity conditional**, not an op-count win. This is the fair-binary treatment;
no strawman.

### 1.3 DOT / WEDGE — mostly fair, one cosmetic strawman

§2c prices binary wedge as *"2 mul + 1 sub (float sinθ)"*. The best binary has the
coordinates already (it just multiplied them), so wedge = `x₁y₂ − x₂y₁` needs no float and
no `sinθ`. The doc *concludes* "~tie" anyway, so the number is fair; the "float sinθ" is a
cosmetic strawman left in the "binary equivalent" column.

### 1.4 ÷3 — NOT a strawman; a genuine, correctly-claimed radix win (and under-priced on the binary side)

The ÷3/÷9 in TRELAX is priced "free" (`operation_cost.md` §1.1, `instruction_footprint.md`
§2). This one is **real**: `rtl/trelax.v` L60–62 shows `u1 = {2'b00, u[2W-1:2]}` and
`s2 = sum[2W+4-1:4]` — division by 3 and 9 are literal wire re-routes (drop one/two trits,
pad null), zero gates. In binary, ÷3 is **not** a shift (base is 2); it needs a real
division (reciprocal multiply or restoring divider). So ternary genuinely owns this
operation. Note the asymmetry runs the *other* way here: the benchmark **never prices the
binary ÷3**, so the "tie" comparison in §3 under-credits ternary on this one op — this is
the one place the benchmark is conservative rather than flattering.

**Strawman verdict (§1):** one hard strawman (rotation-as-Cartesian-trig, in the headline
table and net summary), one cosmetic one (wedge-as-float-sinθ), two fair treatments
(neighbor, and ÷3 which is actually *under*-priced on the binary side). The rotation
strawman is the single largest falsification: the benchmark's self-described "biggest win"
is mostly a coordinate-system choice that a binary axial ALU gets for free.

---

## 2. The native ternary costs: is the 2-threshold READ tax hidden?

### 2.1 The tax on *reads* is honestly counted (credit due)

`operation_cost.md` prices `READ_COST = 2.0` per trit-sense (2 thresholds vs 1) and its
§0 headline is *"89–93% of the cost is the 2-threshold READ tax."* The constant is correct:
`ThresholdLowerBound.lean` `ternary_binary_ratio = 2·ln2/ln3 ≈ 1.26×` per bit, PROVED and
representation-independent (DIRECT; also `FINAL_VERDICT.md` correction #5). The per-trit
2.0 and the per-bit 1.26× are the same quantity in different units. Every operand read in
the per-op table is charged at 2.0. That part is honest.

### 2.2 The tax on *writes* is WAIVED — and the waiver is inconsistent (the read-tax omission)

The cost model's own definition (§1.2) says: *"a cell store … resolve/land a 3-level value
→ each = READ_COST."* The benchmark **does** charge stores: TRECON is priced `1 + 7 store
= 8 reads → 16.0` (§2.1 table). But the **register-file writes are not charged**:

| op | priced reads | priced sense-work | writes `rd` it also performs |
|---|---:|---:|---|
| TROT | 1 | **2.0** | 1 (a full 12-trit result landed) |
| TADD | 2 | 4.5 | 1 |
| TMUL | 2 | 5.5 | 1 |
| TRECON | 1 + 7 store | 16.0 | (stores already counted) |

Under the benchmark's *own* rule, a register write lands a 3-level value exactly as a cell
store does, and should pay READ_COST. Charging it uniformly — `+2.0` ternary vs `+1.0`
binary per written result (the same 2-threshold factor, applied on the output side) —
changes the picture decisively:

- **TROT** goes 2.0 → **4.0**; the "FREE" rotation is 2× its stated price, because it still
  must land a 12-trit result.
- **TADD** 4.5 → **6.5**; **TDOT** 4.5 → **6.5**; **TGRAD** 17.0 → **19.0**.
- Against the binary equivalents (reads 1.0, writes 1.0, cheap 0.5), the "tie" in §3
  becomes a consistent **~1.3–1.6× ternary loss** on every op that writes a result.

This is the answer to the brief's item 2: **the rotation is free to *compute* but its
output is a ternary value, and the table prices that output at 0** — while pricing the
*identical* landing at 2.0 when it happens to be a memory store (TRECON). The read tax is
charged on inputs and waived on outputs, and the waiver is the thing that lets §3 print
"tie."

*(One honest caveat in the benchmark's favor: it is not double-counting. The output is
correctly re-charged as the *next* instruction's operand read; the issue is the missing
write/landing cost, not a missing downstream read. And the benchmark does flag, in §1.3,
that "free neighbor" is free only in the Eisenstein-native frame — the current u32-backed
RTL pays a decode+isqrt+re-encode. That same honesty is not applied to the register-write
side.)*

### 2.3 The "free" bucket hides that its outputs are still ternary values

The cost model prices rotation/negation/neighbor at **0** because they cost "no multiplier,
no new address sense." True for the *compute* step (DIRECT: `tneg` is a wire swap,
`TROT` in `rtl/cpu.v` L183–190 is one shared `ab_sum` add + `fneg6` + a 6-way mux). But
every "free" op *produces* a ternary value that will be read downstream at 2.0. So "free"
describes only the combinational cone, never the value's life-cycle cost — which is exactly
where the constant 1.26× tax lives and never disappears.

---

## 3. The crossover math: win, or tie dressed as a win?

The two proved crossover facts (DIRECT, `JunctionMemory.lean`, `FewerTrits.lean`):

- `three_pow_gt_two_pow_succ` (n ≥ 2): `2^(n+1) < 3^n` — **n trits out-address n+1 bits.**
- `three_pow_lt_two_pow_succ_one`: `3¹ < 2²` — **1 trit loses to 2 bits.**

So the crossover is genuinely **n = 2 trits**, and the benchmark states this correctly and
honestly (`minimal_namespace.md` §2, `address_space_verdict.md` §a note 2: *"1 trit loses
(3 cells < 4 = 2 bits), and 2 trits overtake (9 cells > 8 = 3 bits)"*). The brief's
reformulation — `⌈log₃N⌉ < ⌈log₂N⌉` for N ≥ 5, with ties at N = 1, 2, 4 — is also true, and
every *actual* structure in the benchmark sits in genuine-win territory: pod (N=7) is 2 vs 3,
field store (N=64) is 4 vs 6, u32 box (N=2³²) is 21 vs 32. **No row of the namespace table
claims a win where there is a tie.**

**One cosmetic tie-as-win.** `minimal_namespace.md` §2 draws the crossover as:

```
1 cell → 1 trit (3 states) vs 1 bit (2 states)  — ternary already denser (3 > 2)
```

For N = 1 the symbol counts **tie** (`⌈log₃1⌉ = ⌈log₂1⌉ = 0`; or 1 vs 1 in the "1 symbol
holds b cells" reading). "Already denser (3 > 2)" is a *capacity* claim (1 trit holds 3
states vs 1 bit's 2), presented inside a symbol-count crossover diagram, so it reads as a
symbol-count win where the honest statement is "equal symbols, more states." The doc
immediately clarifies (*"the n=1 comparison is between equal symbol counts (1 vs 1), where
2 < 3 always"*), so this is hedged — but it is precisely the N=1 "win where there is a tie"
the brief asked about. Cosmetic, not substantive: no operational structure lives at N=1.

**The one real crossover/namespace over-claim is a magnitude error, not a tie error.**
`operation_cost.md` prints, in its headline (§0) and in the §3/§4 tables, *"12 trits vs
32 bits = 2.67× fewer symbols."* That number conflates a **value width** (12 trits = 3¹² =
531,441 values ≈ 19.02 bits of information) with an **address width** (32 bits = the u32
box). The correct namespace comparisons are **21 trits vs 32 bits = 1.52×** (addresses) or
**12 trits vs ~19 bits = 1.585×** (values). The benchmark *caught this itself* — a
`CORRECTION` block in `operation_cost.md` §0 and `minimal_namespace.md` §4 both flag the
2.67× as a category error — **but the tables still carry 2.67×**, and the §4 answer table
still reads *"12 trits vs 32 bits (2.67×)."* A correction note above a table that wasn't
fixed is a residual over-claim, and it is the single most-quotable inflated number in the
benchmark.

---

## 4. Adjudication: outpacing, or tying?

The single most important question, answered directly against the priced table
(`operation_cost.md` §3):

| workload | ternary | binary | honest reading |
|---|---:|---:|---|
| TDOT (2-operand) | 4.5 | 4.5–5.5 | tie-to-thin-win |
| TGRAD (7-cell ∇) | **17.0** | **13–16** | **ternary 1.06–1.3× WORSE** |
| namespace (word) | 12 trits | 32 bits | 1.52× (or 1.585×) — **not 2.67×** |

The benchmark's own §3 labels the TGRAD row a "tie" while the numbers in the same table
show ternary losing by up to 1.3×. The honest sentence the data supports is: **ternary does
not outpace binary anywhere in per-operation compute.** It **ties (or slightly loses)** on
every arithmetic/GA op — the 2-threshold read tax (2.0 per sense) is *almost* cancelled by
the free address ops but never quite is — and it **wins only on** (i) the *namespace*
(fewer symbols: 21 vs 32, 4 vs 6, 2 vs 3), and (ii) a short list of genuinely radix-native
micro-ops: free negation (no increment), free ÷3/÷9 (trit shift, `trelax.v`), and the
isotropic pod's row-parity-free neighbor. The read tax is the constant `1.26×` that
`ThresholdLowerBound.lean` proves representation-independent, and it never disappears —
which is exactly what the benchmark's *prose* already says (`eisenstein_free_ops.md` §3/§5,
`address_space_verdict.md` bottom line, `rtl/README.md` caveat #1: *"Compute is a measured
loss, not a win"*), but its *headline table* softens into "tie."

So the division the brief suspected is correct and is **mostly** honestly reported by the
corpus: **geometry/address ops are structurally cheaper (coordinate-system + free
negation + ÷3), generic arithmetic is a measured 1.26–3.94× loss, and the namespace is the
one clean exponential win — which `average_load.md` then shows is ~99.99999997% *unused*
headroom.** The benchmark's flaw is not that it hides this; it is that its headline numbers
(spreadsheet rows, §4 answer table) print the flattering version of it: "tie" for a loss,
"2.67×" for 1.52×, "free" for an op that still lands a taxed output, and a Cartesian-trig
binary for rotation.

---

## 5. Calibration ledger (every number re-checked)

| claim | calibration |
|---|---|
| read tax 1.26×/bit (`2·ln2/ln3`), representation-independent | **DIRECT** — `ThresholdLowerBound.lean` `ternary_binary_ratio`, PROVED, zero `sorry` |
| crossover `2^(n+1) < 3^n` for n≥2; `3¹ < 2²` | **DIRECT** — `JunctionMemory.lean` `three_pow_gt_two_pow_succ` / `three_pow_lt_two_pow_succ_one` |
| namespace growth `(3/2)ⁿ`; outruns linear cost | **DIRECT** — `JunctionMemory.lean` `three_pow_div_two_pow`, `namespace_outruns_linear_cost` |
| pod = 7 cells; norm≤1 ⇔ in-pod | **DIRECT** — `Pod.lean` `pod_card`, `norm_le_one_iff_mem` |
| hexDiskCard(r) = 3r²+3r+1; r=1 ⇒ 7 | **DIRECT** — `HexDisk.lean` `hexDiskCard_eq`, `hexDiskCard_one` |
| u32 box ⊂ 2³² (21 trits) | **DIRECT** — `Bijection.lean` `toNat_lt_two_pow_32`; `FewerTrits.lean` |
| ternary adder 3.94×/bit, multiplier 1.72×/bit area | **DIRECT** — `rtl/word_fairfight.txt` (50.98/12.95; 287.74/167.22, both shift-add) |
| `tneg` = 0 cells; `tadd1` = 146.39 µm²; binary FA = 33.78 µm² | **DIRECT** — `rtl/gate_area.txt` |
| mod-3 sum floor 1.42×/bit | **DIRECT** — `rtl/README.md` caveat #1 (cited, not re-derived here) |
| ÷3, ÷9 free trit shifts | **DIRECT** — `rtl/trelax.v` L60–62 (wire re-route, zero gates) |
| TROT = 1 add + free negate, no multiplies | **DIRECT** — `rtl/cpu.v` L183–190 (`ab_sum` + `fneg6` + mux) |
| rotation's binary equivalent is 1 add in axial coords (not trig) | **DIRECT** — the benchmark's own §0/§1b prose in `eisenstein_free_ops.md` |
| 2.67× = value-width ÷ address-width category error; correct 1.52×/1.585× | **DIRECT** — `minimal_namespace.md` §4, `operation_cost.md` §0 CORRECTION |
| register writes not charged while cell stores are | **DIRECT** — `operation_cost.md` §1.2 def vs §2.1 TRECON/TROT/TADD rows |
| "tie" label over TGRAD 17.0 vs 13–16 | **DIRECT** — `operation_cost.md` §3 table vs its own "tie" sentence |
| TGRAD = ternary 1.06–1.3× worse; write-tax flips tie → ~1.3–1.6× loss | **DERIVED** — arithmetic on the DIRECT table + the write-cost rule |
| "1 cell → already denser" is a capacity claim in a symbol-count crossover | **SPECULATION** — reading of `minimal_namespace.md` §2 (cosmetic) |

---

## 6. Verdict

**One sentence:** `energy-address-bench.md` (as realized across its six sibling files) is a
*flattering-but-self-flagging* benchmark, not a clean measurement — its every DIRECT number
is genuinely Lean-proved or RTL-measured and its prose is honest about ternary's compute
loss, but its headline table sells ternary as "tying" binary on compute with a "2.67×"
namespace win when the correct reading of its own numbers is a small ternary *loss* on
every arithmetic op (once the waived register-write read tax is charged), a 1.52× namespace
win, and a rotation "biggest win" that a fair axial-coordinate binary gets for free.
