# Ternary ideas from other AI agents — evaluation (borrow-don't-trust)

Two transcripts were pasted: **z.ai** (a "ternary-native blueprint" + cool-facts) and
**kimi** (a long Q&A about ternary, GA/Einstein math, and emulation). Each claim is triaged
against what the Tau project has **already built and proved**, then sorted into four bins:

1. **ALREADY HAVE** (rename/duplicate — the agent is describing our existing design)
2. **GENUINELY NEW** (a real axis we have NOT built — worth testing)
3. **FLATTERY** (native-device/marketing claims we've repeatedly debunked)
4. **WRONG / CONFUSED** (a category error)

## Bin 1 — ALREADY HAVE (the bulk; this is our design, restated)

| agent claim | our artifact |
|---|---|
| balanced ternary, not unbalanced | `Conventions.lean`, whole project |
| negation = flip 1↔T, no two's-complement | `tneg` = wire swap `{t[0],t[1]}` in `trit_functions.vh` |
| add carry: 1+1=1T, T+T=T1, 1+T=00 | `tadd1` truth table (identical) in `trit_functions.vh` |
| shift left = ×3 | `trelax.v` uses `>>1 trit` (=/3), `>>2 trits` (=/9) |
| MIN/MAX = ternary AND/OR | `tand` / `tor` |
| 6-trit tryte = 729 values, ±364 | our 12-trit word (24 bits) = Eisenstein a+bω, range exceeds this |
| tryte-addressable memory; 12 trits = 531,441 | `hex_encode`/`hex_decode` + `Bijection.lean` (the 3ⁿ namespace, fills u32 exactly) |
| radix economy: 3 closest integer to e | `RadixEconomy.lean`, `RadixMin.lean` (proved) |
| Setun history, "fewer components" | project history docs |
| "why binary won": noise margins, infrastructure, power | `FINAL_VERDICT.md` (our own settled verdict — it AGREES with us) |
| GA instructions (geometric product) | `TDOT`/`TWEDGE`/`TSYMDOT` — the dot⊕wedge split, over Eisenstein ℤ[ω] (2D; richer than 3D multivectors for a hex lattice) |
| weekend emulator spec (9 trits, 8 regs, ~12 ops) | we EXCEEDED it: 11-opcode ternary CPU in RTL + full PicoRV32 SoC |

**Verdict on Bin 1:** the z.ai "blueprint" is a near-exact restatement of what we already
built — encouraging (independent convergence) but not new.

## Bin 2 — GENUINELY NEW (real axes we have NOT built)

### 2a. The LOGIC axis — Kleene three-valued logic (true / false / unknown)
We built the **numeric** ternary (Eisenstein ℤ[ω], signed digits). We have **not** built the
**logic** ternary: Kleene/Łukasiewicz where the third state is *unknown*, not *zero*.

- `AND(unknown, false)=false`, `OR(unknown, true)=true`, `NOT(unknown)=unknown` (Kleene).
- Applications the agent lists that are real and unbuilt here: **speculative-execution
  safety** (mark speculative results `unknown` until confirmed; branch only on known),
  **SQL-NULL-native** semantics, **partial computation** ("not yet computed" as a genuine state).
- Honest hook: we already reserve the `11=NEVER` encoding as a canary. A first-class
  `unknown` **value** (distinct from numeric `null` and from the `NEVER` *error*) would be a
  new semantic layer — cheap in software, and it composes with the existing 2-bit/trit code.
- Calibration: the LOGIC idea is **DIRECT** (Kleene is standard), the speculative-execution
  application is **SPECULATION** (no one has shipped a ternary-unknown CPU; it's a design idea).

### 2b. The SPARSITY axis — ternary matmul with zero-skip (TNN)
Ternary Neural Networks (−1/0/+1 weights, XNOR-Net / Ternary Weight Networks) are real and
literature-backed: ~20× compression, near-zero accuracy loss, and "zero weights skip
connections."

- **Why this is the strongest new idea:** the TNN win is **not** ternary arithmetic being
  cheaper per op — it is the **zero-skip** (a null weight does no multiply-accumulate). That
  is *exactly our free-null insight*, applied to compute. The agent's "zero weights mean you
  skip connections, giving built-in sparsity" is our `null_is_free` transport theorem wearing
  an AI costume.
- So a `MATMUL_TRIT` / sparse-MAC primitive is genuinely aligned with the Tau thesis — but it
  must be priced honestly: the win is **null-skip** (sparsity/transport), *not* a compute
  density win. It does NOT overturn "compute loses 1.26–3.5×/bit"; it confirms "ternary wins
  where the null is free."
- Calibration: TNN results are **DIRECT** (peer-reviewed, and Samsung/Intel have prototyped);
  the mapping "TNN sparsity = our free null" is **OURS** (a mapping, and I'd argue it's an
  identity, not just an analogy).

### 2c. The FLOAT axis — bias-free truncation (balanced-ternary floating point)
"Chop off the low trits = symmetric round-to-nearest, no rounding bias, no banker's-rounding."
This is a **real, proved property** of balanced ternary, and it is the single untapped lead
that sits in `docs/balenced ternery/` (the **Tekum** paper, arXiv:2511.10964 — balanced-ternary
tapered-precision real arithmetic, plus Knuth).

- We use fixed-point trits (3 int + 3 frac in `trelax.v`). A balanced-ternary **float**
  (symmetric truncation = bias-free rounding by default) would be a new core primitive with a
  genuine advantage for iterative/financial/physics numerics where rounding bias accumulates.
- Calibration: the truncation property is **DIRECT** (standard balanced-ternary math, and in
  `FewerTrits.lean`'s neighbourhood); the "bias-free FPU" application is **SPECULATION**
  (nobody ships one), but it is the most *mathematically clean* of the new axes.

### 2d. TCAM wildcard (0 / 1 / X) — a DIFFERENT ternary
Ternary Content-Addressable Memory is real, mass-produced hardware (every router matches IP
prefixes with `X = don't-care` in one cycle). A TCAM coprocessor (regex / pattern / rule
matching) is a genuine, distinct application.

- **Honest caveat:** TCAM's ternary is **{0, 1, X}** — the third value is a *wildcard*, not a
  signed `−1`, and not our numeric `null`. It is "ternary" in the 3-state sense, a different
  encoding and semantics from balanced ternary. So it is a real but *separate* ternary that
  would not reuse our balanced adder/gate cells.

### 2e. Minor / speculative (note, don't chase yet)
- **Ternary Gray codes** (single-trit ±1 transitions → minimal EMI/power): real, small, useful
  for a counter/encoder; low priority.
- **Cantor-set addressing**: base-3 fractal — we already have the *hex* analogue
  (`FractalRam.lean`, 7ⁿ). A different fractal, same idea; no new core feature.
- **3-state cellular automata** as a demo workload: fun, not architecture.

## Bin 3 — FLATTERY (the "ternary resurgence" claims — verify or reject)

The kimi "recent projects" list repeats the exact native-device flattery we've debunked:

| claim | verdict |
|---|---|
| Huawei 7 nm ternary gate patent (2025) | a **patent is not a chip**; also Huawei's "three threshold voltages" is level-encoded ternary (driven mid-level), not free-null — the 2-threshold tax in the open |
| CNTFET ternary: "45% less area, 30% less energy" | simulation numbers on a non-manufacturable process; the ~1.58×/bit is the `1/log₂3` factor, and area claims exclude the sense/verification overhead |
| memristor ternary: "100× energy reduction" | the native-floor flattery; see `polar_memristor.md` and `_SYNTHESIS.md` |
| qutrits: "37% more compact than qubits" | quantum information (different resource theory); 37% ≈ log₂3 advantage, not an implementation win |
| Setun "literally cheaper" | historical, single data point, pre-transistor era; not evidence for today |

**Verdict on Bin 3:** none of these overturn `FINAL_VERDICT.md`. The honest position stands:
compute loses, addressing + transport win, native devices are flattery.

## Bin 4 — WRONG / CONFUSED

- **TCAM "X" is not balanced ternary** (Bin 2d) — a category error if you expect it to reuse
  our signed cells.
- **"3 is cooler than 2" / "that's just science"** — rhetorical, not a claim.
- **The 2–4 year timeline** is for a beginner starting from zero; we have already cleared the
  two long poles it names (Lean ISA proofs and the RTL datapath). Mostly irrelevant to us.
- **"Curved-spacetime arithmetic"** (Einstein math as instructions) — kimi itself correctly
  flags this as "research fiction": a metric-tensor cache and parallel transport are a physics
  engine, not an instruction. We have the *field-calculus* echo (`CausalLattice.lean` flow/curl,
  `TGRAD`/`TRECON`/`TRELAX`), which is the right scoped-down version of that instinct.

## Bottom line

The two agents' best ideas do **not** overturn the thesis — they *confirm it*. The genuinely
new and exciting axes (**2b** sparsity, **2a** logic, **2c** float) all win **because of the
null**, not because ternary arithmetic beats binary:

- **2b** (TNN) = the free-null *transport* insight applied to compute (zero-skip).
- **2a** (Kleene) = a *third semantic value* (unknown), not a faster digit.
- **2c** (float) = the null-as-symmetric-zero property, not a cheaper ALU.

So if we add anything, the honest framing is: **these are new *null semantics*, not new
*compute wins*.** The one most worth a real build is **2b** — a `MATMUL_TRIT`/sparse-MAC
primitive — because it is the only one with peer-reviewed silicon behind it, and it is the
freest reuse of our existing ternary cells + the hex MMU as a sparse-weight store.

**Suggested next action:** survey `docs/balenced ternery/` (Tekum + Knuth) for axis **2c**,
and — separately — decide whether to spec axis **2b** as a co-processor (a TNN sparse-MAC on
the same PCPI/CFU port the Xlattice ops already use).
