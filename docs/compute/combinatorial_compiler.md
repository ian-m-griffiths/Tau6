# The Combinatorial Compiler — top-level spec

*The end-to-end toolchain for minimal-energy ternary circuit synthesis. The
document you hand to anyone who asks "so what does the compiler do?"*

**Calibration legend (house standard, `docs/MAP_BRIEF.md`):**

- **DIRECT** — measured (ngspice/yosys) or proved (Lean, `lake build` green, zero
  `sorry`), or a citable literature fact.
- **ANALOGY** — parallel structure to something real, but the mapping is not an
  identity.
- **OURS** — our own design claim, carried from project files (RTL, Lean ledger,
  this toolchain's own definition).
- **SPECULATION** — untested hypothesis, flagged as such.

---

## What the compiler does, in one sentence

It turns junction physics into **symbolic logic**, prices every gate by its
**channel-activation energy**, **searches** for the cheapest netlist realizing a
given ternary operation (pruning the search by energy), and **memoizes** distinct
fragments on a **causal lattice** so each subcircuit is paid for once — then hands
back a minimal-energy netlist *plus an honest energy estimate that separates the
searchable logic cost from the non-searchable sensing cost*.

The encoding it operates on (fixed by the architecture, not by this toolchain):

```
trit value   bits     energized channel
  push +1    2'b01    push line only
  null  0    2'b00    neither line (nothing energized)
  pull −1    2'b10    pull line only
  NEVER 11     --     BOTH — forbidden (don't-care input)
```

**[OURS — design; the 2-bit one-hot encoding in `rtl/trit_functions.vh`,
Lean-proved in `TernaryCell.lean`].** Three consequences govern the whole tool:

- **Negation is free** — `tneg` is a wire swap, zero logic **[DIRECT — measured
  0.00 µm² / 0 cells, `docs/compute/gate_area.md`]**.
- **Null is free on the wire, not in the gate** — sending null costs ~0.05 pJ
  (~24× cheaper than a ±1) **[DIRECT — measured, `docs/ENERGY_LAWS.md`]**, but a
  gate must still *resolve* "push / null / pull" every evaluation.
- **Every non-negation gate is two binary thresholds** — a trit lives on two
  wires, so a MIN gate is literally an AND2 + an OR2 **[DIRECT — `docs/compute/gates.md`]**.

---

## 1. The pipeline, end to end

```
                         THE COMBINATORIAL COMPILER
                         ───────────────────────────

 input: ternary op spec ──▶  (1) JUNCTION ALGEBRA ──▶ (2) GATE LIBRARY
 (truth table over              symbolic logic         + energy weights
 {push,null,pull})              (trit = two            (E_gate per channel)
                                anti-polar channels)
                                        │                        │
                                        ▼                        ▼
 output: minimal-energy ──◀  (4) FRAGMENT MEMOIZATION ◀─ (3) WEIGHTED SEARCH
 netlist + energy                 causal lattice             branch-and-bound / ILP
 estimate (logic vs               ("each path exists         prune by energy
 sensing, separately)              once")                    (weighted logic ↓ search)

   ══ fixed taxes, reported but NOT optimized by the search ══
   (a) 2-threshold SENSING tax   — physical, per evaluation, invariant under netlist
   (b) NP-hardness                — the search + lattice are a cache, not a polynomial
                                     algorithm
```

Stages, one line each:

1. **Junction algebra** — the trit (two anti-polar channels sharing a middle node)
   becomes a symbolic term language: `push`/`null`/`pull`, `negation = swap the two
   lines`, `null = nothing energized`. Rewrite rules that preserve the operation.
2. **Gate library with energy weights** — each gate carries a numeric weight = its
   **channel-activation energy** (the cost to energize its output channels), taken
   from the measured table, not invented.
3. **Weighted search** — branch-and-bound / ILP over netlists realizing the spec,
   pruned by an energy lower bound ("weighted logic decreases the search space").
4. **Fragment memoization** — distinct subcircuits are canonicalized onto a **causal
   lattice** (a node's output depends only on its inputs), so each fragment is
   synthesized and priced **once**, not once per permutation.
5. **Output** — the minimal-energy netlist (Verilog) plus an energy estimate split
   into **logic** (searchable) and **sensing** (fixed, reported separately).

---

## 2. Stage by stage — artifact, proven vs speculative, open problem

### Stage 1 — Junction algebra (symbolic logic)

- **Artifact:** `docs/compute/combinatorial_compiler/junction_algebra.md`
  (the term language + rewrite rules); the polarity facts are Lean-proved in
  `proofs/lean-src/Tau/JunctionPolarity.lean`; the physical grounding is
  `rtl/junction_cell.v` (the trit cell itself).
- **Proven:** negation = free polarity swap **[DIRECT — measured 0.00 µm²]**; the
  one-hot encoding with `11=NEVER` as a free don't-care **[OURS, Lean `TernaryCell.lean`]**;
  the rewrite rules are mechanically checkable **[OURS]**.
- **Speculative:** that the *algebra* is the right abstraction layer — i.e. that a
  rewrite is a valid implementation step whose cost can be attached *afterward*.
  The algebra is symbolic; it does not know energy.
- **Open problem:** the algebra must be **complete but not too free** — if its
  rewrite rules admit every netlist, the search space is uninhabited by structure
  (Stage 3 drowns); if too restrictive, it prunes the optimum. Finding the
  rewrite system whose normal forms are *exactly* the energy-relevant fragments is
  open.

### Stage 2 — Gate library with energy weights

- **Artifact:** `docs/compute/combinatorial_compiler/junction_cost_verdict.md`
  (the honest cost check that decides what a weight *means*);
  `proofs/lean-src/Tau/JunctionEnergy.lean` (the activation-energy model);
  numbers sourced from `docs/compute/gate_energy.md` and `docs/compute/polar_gates.md`.
- **Proven (the numbers exist, measured):** binary NOT 32.28 fJ, NAND 36.96 fJ;
  ternary `tneg` 61.87 fJ (0-transistor logic), `tmin` 85.19 fJ, `tmax` 82.73 fJ,
  `tsum` 183.61 fJ per toggle **[DIRECT — ngspice 44.2, `gate_energy.md`]**. The
  **2-threshold receiver tax is 2.54×** (1 sense amp = 24.35 fJ vs 2 = 61.87 fJ)
  **[DIRECT]**.
- **Speculative:** that the per-gate weight is a **monotone, additive** cost over
  composition — the property the search (Stage 3) needs to prune soundly. A real
  gate's energy depends on fan-out, wire load, and neighbor activity; the static
  weight is an approximation, not a theorem.
- **Open problem:** **activity-dependent weights.** The one lever the compiler
  actually has is *null-heavy data* (fewer channels energized ⇒ less energy), but
  the static weight is data-blind. A weight that depends on the *input distribution*
  is the difference between "prices the hardware" and "prices the workload" — and it
  is not yet modeled.

### Stage 3 — Weighted search (branch-and-bound / ILP)

- **Artifact:** `scripts/tau_energy_search.py` (the search engine);
  `docs/compute/combinatorial_compiler/weighted_synthesis.md` (the ILP/SAT framing).
- **Proven:** branch-and-bound with an *admissible* (lower-bound) energy heuristic
  returns the true minimum **[DIRECT — standard algorithmics]**. Circuit synthesis
  as SAT/ILP is a well-trodden reduction **[DIRECT — literature]**.
- **Speculative:** that energy-weighting *actually shrinks the search* in practice.
  The pruning power is data-dependent and unmeasured; it is the headline promise and
  it is, today, an assertion.
- **Open problem:** **the blow-up.** ILP variable counts grow super-linearly with
  spec size; branch-and-bound optimality is exponential worst-case. Weighting helps
  only insofar as the admissible bound is tight — and making it tight without
  admitting the sensing tax (which would make it *un*sound) is open.

### Stage 4 — Fragment memoization (causal lattice)

- **Artifact:** `scripts/circuit_memo.py` (the memoization runtime);
  `proofs/lean-src/Tau/JunctionMemory.lean` (the lattice identities: "two
  permutations of the same fragment are one canonical node").
- **Proven:** the lattice identity itself — a fragment keyed by its causal structure
  (inputs → outputs) is invariant under input permutation — is Lean-provable
  **[OURS]**.
- **Speculative:** that fragment **reuse dominates real circuits** — i.e. that the
  typical synthesized netlist is mostly repeated subcircuits, so paying each once is
  a real win, not a bookkeeping flourish.
- **Open problem:** **canonicalization is itself hard.** Deciding whether two
  fragments are "the same" is (sub)graph-isomorphism-flavored — expensive. The
  lattice removes *duplicate/permutation* cost, but the cost of *deciding* identity
  is nonzero and unbounded. (See boundary (b).)

### Stage 5 — Output

- **Artifact:** the emitted netlist (Verilog, `rtl/junction_cell.v` as the leaf cell)
  plus a cost report: `Σ gate-weight(path)` for logic, and the **sensing tax as a
  separate, invariant line**, never folded into the number the search minimized.
- **Proven:** the split is honest — the two costs are measured separately
  **[DIRECT — `gate_energy.md` E_gate vs E_rec]**.
- **Speculative:** that the estimate transfers to a real place-and-routed netlist.
  The gate-weight model is pre-layout; routing and load change the true number.
- **Open problem:** closing the loop — back-annotating post-layout energy into the
  weights so the search's estimate converges on the silicon's, not the spreadsheet's.

---

## 3. The two hard boundaries

### (a) The search finds the cheapest LOGIC netlist; it does not erase the 2-threshold SENSING tax

The compiler weights **channel-activation energy** — the combinational logic cost
(`E_gate` in `gate_energy.md`). The **sensing** cost — resolving "push / null /
pull" with **two thresholds** instead of binary's one — is a fixed per-evaluation
tax. It is measured at **2.54×** (24.35 fJ → 61.87 fJ), and it is **physical, not
searchable**: even the single best gate balanced ternary has — negation, a
0-transistor wire swap — still **loses 21% per bit** (61.87 fJ ÷ 1.585 = 39.0 fJ/bit
vs binary NOT's 32.3 fJ/bit) *because it must drive a 2-threshold receiver*
**[DIRECT — `gate_energy.md` §"The honest verdict"]**.

Consequence, stated plainly: **no netlist rearrangement the search can perform moves
this number.** The compiler optimizes the small term (logic) and must report the big
term (sensing) as an invariant — otherwise its "minimal-energy netlist" claim is
laundering. The search's output is correctly titled *"minimal-energy LOGIC netlist,"
with the sensing tax added on top, not under, the search.*

### (b) The causal lattice removes DUPLICATE/permutation cost; circuit synthesis is still NP-hard

Memoization pays each distinct fragment once instead of once per permutation — it
removes a *polynomial/constant-factor* cost of re-deriving and re-pricing the same
subcircuit. It does **not** remove the exponential: the number of *distinct*
fragments realizing a spec grows exponentially with the spec, and finding the
minimum-energy realization of a truth table **generalizes Boolean circuit
minimization, which is NP-hard (Σ₂^p-hard for optimality)** **[DIRECT — literature]**.

Consequence: the causal lattice is a **good cache, not a polynomial algorithm**. It
makes the search *cheaper by the amount of duplication*, which is real but bounded;
it does not change the asymptotic class. Claiming otherwise would be the exact
"laundering" this repo's audits exist to catch.

---

## 4. Minimum viable milestone — v0.1

**Goal (end-to-end, one toy):** synthesize the **balanced-ternary half-adder**
(2 trits in → mod-3 sum + carry) from the measured gate library `{tneg, tmin, tmax,
tsum}`, and report the cheapest netlist with the logic/sensing energy split.

The pipeline runs all five stages on a spec small enough to inspect by hand but
large enough to exercise search + memoization:

1. Spec: the half-adder truth table (3×3 → sum, carry).
2. Junction algebra: canonicalize; the sum's `−` sub-terms should rewrite to free
   negations.
3. Weighted search: branch-and-bound over netlists up to a fixed depth, pruned by
   the measured gate weights.
4. Memoization: the carry-detection threshold appears in both outputs — synthesize
   it once.
5. Output: Verilog + `logic energy / sensing tax` report.

**Success criterion (honest):** the search **reproduces the known hand-built cell**
(`tmin`/`tmax` = 12 T, `tsum` = 68 T — `gate_energy.md`) or finds an equally-good
one, and **correctly reports that the sensing tax dominates the logic energy**.
v0.1 is a success when the pipeline *prices* correctly — **not** when it beats
binary. It must also smoke-test the free negation (the search should find it for
free, not "pay" for an inverter).

**The next step after v0.1 (the honest one):** not "make the search faster." Two
things, in order:

1. **Activity-dependent weights.** Feed a null-heavy input distribution into the
   weight model so the search optimizes the *workload* (the only thing it can truly
   move), and measure whether the resulting netlists are cheaper than the static
   ones on real toggling patterns.
2. **Measure the cache, don't assert it.** Run a benchmark of ternary ops and plot
   **distinct-fragments vs search-nodes** — the curve that either confirms or kills
   the SPECULATION that memoization shrinks the search in practice.

---

## 5. Honest assessment — does it reduce the cost, and by what mechanism?

Yes, but bounded, and for concrete reasons rather than magic. The compiler reduces
the **combinational logic (channel-activation) energy** of a ternary netlist by two
real mechanisms: **null-heavy data** — it routes work through nulls and free wire
swaps (negation), so on typical input fewer channels are energized and the search
prefers those implementations; and **fragment reuse** — it pays each distinct
subcircuit once instead of once per permutation, so the synthesis cost of a repeated
fragment is amortized. Both are genuine, mechanizable levers **[OURS]**. But the
measurements draw a hard line around what they buy: the energy these levers move is
the **small term** — the combinational logic — while the dominant per-evaluation cost
is the **2-threshold sensing tax (2.54×)**, which is fixed and outside the search
**[DIRECT — `gate_energy.md`]**; and the search remains NP-hard with a cache, not a
polynomial algorithm **[DIRECT — literature]**. So the toolchain, if built, makes a
ternary netlist cheaper than a *naive* ternary netlist — better than hand-waving,
worse than magic — but it does not overturn the already-measured verdict that ternary
compute loses to binary compute on CMOS. It optimizes the part of the energy that
was never the wall, and the honest product is a *correctly priced* netlist, not a
winning one.

---

## 6. File map — the nine sibling pieces

This spec is the top-level contract; the pieces are written by the sibling agents.
Paths are the canonical targets (update the map if an agent lands one elsewhere).

| stage | artifact | role |
|---|---|---|
| 1 | `docs/compute/combinatorial_compiler/junction_algebra.md` | symbolic term language + rewrite rules |
| 1–2 | `proofs/lean-src/Tau/JunctionPolarity.lean` | negation = free polarity swap; one-hot encoding |
| 0–2 | `rtl/junction_cell.v` | the physical trit cell (push/pull channels, middle node) |
| 2 | `docs/compute/combinatorial_compiler/junction_cost_verdict.md` | honest cost check: what a weight means |
| 2 | `proofs/lean-src/Tau/JunctionEnergy.lean` | channel-activation energy model |
| 3 | `scripts/tau_energy_search.py` | weighted search (branch-and-bound / ILP) |
| 3 | `docs/compute/combinatorial_compiler/weighted_synthesis.md` | ILP/SAT framing of the search |
| 4 | `scripts/circuit_memo.py` | fragment memoization runtime |
| 4 | `proofs/lean-src/Tau/JunctionMemory.lean` | causal-lattice identities (permutation-invariant fragments) |

Supporting measured facts (not written by the siblings, cited above):
`docs/compute/gate_energy.md`, `docs/compute/polar_gates.md`, `docs/compute/gates.md`,
`docs/TAU_ARCHITECTURE.md`, `docs/FINAL_VERDICT.md`.

---

*Every number in this spec is carried from a measured or proved source and cited;
the claims that are still ours are tagged OURS or SPECULATION. Nothing here is
invented — the compiler's honesty is the whole point of the tool.*
