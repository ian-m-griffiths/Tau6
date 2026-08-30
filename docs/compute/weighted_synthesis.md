# Weighted Synthesis — minimal-energy ternary netlists as weighted-logic search

**2026-08-29 — spec (not a measurement, not a proof).** This file frames the Tau
Architecture's synthesis problem — *"find the cheapest gate-level netlist for a ternary
operation"* — as a **weighted-logic search**: weight every candidate unit (wire / gate output)
by its channel-activation energy, and let that weighting drive the pruning. It states the
problem, writes the 0-1 ILP, argues the branch-and-bound / A\* pruning, and then states the
**honest boundary**: what the weighting buys and what it cannot buy.

**Calibration legend (house standard, `docs/MAP_BRIEF.md`):**

- **DIRECT** — measured or proved (our ngspice/yosys/Lean numbers, or a citable textbook fact).
- **ANALOGY** — parallel structure to something real, but the mapping is not an identity.
- **OURS** — our design claim, carried from / derived from project files.
- **SPECULATION** — untested hypothesis, flagged as such, never stated as fact.

**One-line answer up front:** the minimal-energy netlist problem is a **0-1 integer linear
program (ILP)** whose variables are gate instances + wire values, whose constraints are
**one-hot-per-trit** (the physical `11=NEVER` constraint, exactly) + **gate function tables**,
and whose objective is **Σ energy · activity** = a linear sum of `p(α)·E(v)` coefficients on the
wire-value indicators. The one-hot constraint is what makes the matrix **sparse** (≤3 nonzeros
per row); the **24:1 null/±1 energy gap** (0.05 vs 1.20 pJ) is what makes the objective
**sharp enough to prune** — it concentrates the optimum in a null-heavy region so a monotone
lower bound cuts ±1-heavy branches early. But this is a **heuristic** win, not a polynomial one:
the problem is **NP-hard** (it subsumes minimum two-level logic minimization), and the weighting
cannot erase the **2-threshold sensing tax**, which is a *per-gate physical cost* (measured
2.54×, `gate_energy.md`; proved 1.26×/bit floor, `ThresholdLowerBound.lean`), not a search cost.

---

## 1. The problem, stated precisely

**Substrate.** Balanced ternary on the Eisenstein lattice ℤ[ω]; trit ∈ {−1, 0, +1}; each trit is
**2 wires, one-hot per direction** (`rtl/trit_functions.vh`, Lean-proved in `TernaryCell.lean`):

```
value  bits   energized wires
 +1    2'b01  push only
  0    2'b00  neither (null — nothing energized)
 -1    2'b10  pull only
 11    2'b11  BOTH — NEVER produced (free don't-care input)
```

**[DIRECT — `docs/compute/gates.md` §1, `TernaryCell.lean` `encode_never_both`, `null_is_free`]**

**Cell library.** `L = {tneg, tand (min), tor (max), tmul, tadd1 (balanced full adder)}`, plus
**free constants** {−1, 0, +1} (rail ties) and the fact that `tneg` is a **0-transistor wire
swap** (free). `{tadd1.sum, tmul}` is the minimal complete set (F₃ field pair); min/max/neg are
the cheaper-but-incomplete lattice fragment. **[DIRECT — `docs/compute/ground_up/minimal_gates.md`]**

**Energy per channel activation** (`scripts/transport.py`, the fair-fight operating point):

```
E_null = 0.05 pJ        (a trit whose value is 0 — ~free on the wire)
E_±1   = 1.20 pJ        (a trit whose value is ±1 — a driven wire)
gap    = 1.15 pJ        ratio = 24×
```

**[DIRECT — `scripts/transport.py` lines 32-34, `circuit/ENERGY_RESULTS.md` CORRECTION 1.]**
Note up front: these are **wire/transport** energies. The **gate** energies are separate and
larger (min = 85.19 fJ/toggle, dominated by a 61.87 fJ receiver — `gate_energy.md`); §5 makes this
boundary explicit.

**The two forms.**

> **Decision form (MIN-ENERGY-NETLIST).** Given a target function
> `f : {−1,0,+1}ⁿ → {−1,0,+1}` (truth table), the cell library `L`, an activity distribution
> `p` over the `3ⁿ` input vectors, a netlist-size bound `N` (number of gate instances), and an
> energy budget `E`, decide: **does there exist a combinational netlist of ≤ N gate instances
> from L (plus free constants and free negation) realizing f, with expected channel-activation
> energy ≤ E?**

> **Optimization form.** Minimize, over all realizing netlists,
>
> ```
> cost(netlist) = Σ_wires w  E_w · a_w
>               = Σ_wires w  [ E_null + (E_±1 − E_null) · P(w ≠ 0) ]
>               = 0.05·W  +  1.15 · Σ_w P(w ≠ 0)          (W = #wires)
> ```
>
> where `E_w` is the wire's per-evaluation energy and `a_w` its activity (evaluation
> frequency). Because `1.15 ≫ 0.05`, to first order **minimizing energy = minimizing total
> non-null wire activity**, weighted by the 1.15 pJ gap. A null wire costs 24× less than a ±1
> wire, so the search is told to *leave wires null wherever the data allows*.

**[DIRECT — the arithmetic is on the two constants; the "minimize non-null activity" restatement
is OURS, a one-line corollary.]**

This is the "weighted-logic search" framing in one sentence: **the search objective is a weighted
sum of 0-1 indicators, where the weight of "wire w is non-null" is 1.15 pJ × its activity, and the
weight of "wire w is null" is 0.05 pJ × its activity.**

---

## 2. The 0-1 ILP

Variables are **gate instances** and **wire values**. Because a gate's output depends on the input
vector, and the activity distribution `p` is over input vectors, the honest truth-table encoding
indexes the value indicators by input vector. For small `n` (an *operation* is 1–3 trits, not a
32-trit word — see §7) this is the standard exact-synthesis encoding.

**Variables.**

- **Wire-value indicators** `y_{w,v,α} ∈ {0,1}`: wire `w` carries value `v ∈ {−1,0,+1}` under input
  vector `α ∈ {−1,0,+1}ⁿ`. (Equivalently two channel bits `push_{w,α}, pull_{w,α} ∈ {0,1}` with
  value = `push − pull`.)
- **Gate-instance variables** `z_{i,t} ∈ {0,1}`: candidate node `i` realizes library type `t`
  (`z_{i,∅} = 1` = unused), and **connectivity variables** `e_{i,j,port} ∈ {0,1}`: node `i`'s
  input port `port` is fed by source `j` (primary input, constant, or earlier node).

**Constraints.**

1. **One-hot per trit** (the `11=NEVER` / "at most one channel" constraint), for every wire and
   every input vector:

   ```
   Σ_{v∈{−1,0,+1}} y_{w,v,α} = 1        ∀w, ∀α          (exactly-one-value form)
   push_{w,α} + pull_{w,α} ≤ 1           ∀w, ∀α          (at-most-one-channel form)
   ```

   Each row has **3 nonzeros** (one-hot) or **2** (channel) — this is the sparse constraint.

2. **Gate function tables**, for every gate of type `t` with fan-in wires `(a,b)` and output `c`,
   every input vector `α`, and every *forbidden* combination `(x,y,z) ∉ T_t`:

   ```
   y_{a,x,α} + y_{b,y,α} + y_{c,z,α} ≤ 2        (18 per 2-input gate: 27 − 9 allowed)
   ```

   Each row has **3 nonzeros**. (With one-hot, forbidding a triple is enough; the allowed triples
   are then forced. `tadd1` is 3-input → 81 − 27 = 54 forbidden triples, still 4 nonzeros each.)

3. **Primary-input anchoring:** `y_{x_j, α_j, α} = 1` for primary input wire `x_j` (its value is
   the j-th digit of `α`).

4. **Primary-output realization:** `y_{out, f(α), α} = 1` — the output wire must equal the target
   under every input.

5. **Topology consistency** (connectivity): each used node's inputs are MUX-selected from earlier
   sources, and the type/connectivity variables are linked to the value indicators. (Standard; the
   MUX rows are the only rows with more than a constant number of nonzeros.)

**Objective.**

```
minimize  Σ_w  Σ_α  p(α) · Σ_v E(v) · y_{w,v,α}
        = Σ_w  Σ_α  p(α) · [ 0.05 · y_{w,0,α} + 1.20 · (y_{w,+1,α} + y_{w,−1,α}) ]
```

This is **exactly "Σ energy · activity"**: the coefficient of `y_{w,v,α}` is `p(α)·E(v)` — the
activity (how often input `α` occurs) times the energy (what value `v` costs). With uniform
`p(α) = 3⁻ⁿ` this is the average channel energy; with a **null-heavy (Zipf) workload** the weight
shifts toward the `α` with many null digits, making null-heavy implementations cheaper — the
search-level echo of the `ZipfEnergy.lean` bound (expected energy = 1 − P(null) < 2/3). **[OURS —
the objective is the definition; the Zipf link is DIRECT from `ZipfEnergy.lean`.]**

**Why one-hot is *itself* what makes this sparse and prune-able.**

- **Sparse — DIRECT (a counting fact).** Every one-hot row has ≤3 nonzeros; every forbidden-pattern
  row has exactly 3 (or 4 for `tadd1`). The constraint matrix is `O(N · 3ⁿ)` rows with `O(1)`
  nonzeros each — linear in the netlist size, with a tiny per-row constant, *because* the value of
  a wire is a single one-hot bit and the gate function is a conjunction of short conflict clauses.
  A dense encoding (`t_w ∈ {−1,0,+1}` as an integer with big-M links) would instead couple every
  gate's inputs and output through big-M inequalities with large constants and a weak LP relaxation.
- **The `11=NEVER` constraint and the ILP's one-hot constraint are the *same* constraint.** The
  "at most one energized channel" that the physical 2-wire encoding enforces is literally the
  `push + pull ≤ 1` row. So the ILP's sparsity is inherited from the *encoding*, not imposed on it.
  **[DIRECT — `TernaryCell.lean` `encode_never_both`, `energy_le_one`.]**
- **Prune-able — ANALOGY (standard MILP behaviour, not yet measured on our library).** One-hot /
  at-most-one constraints are SOS1 / clique structure: solvers branch by *fixing one value and
  excluding the rest*, and they get tight cutting planes (clique cuts, partition cuts) and a tight
  LP relaxation. Because the objective coefficients differ by **24×**, the LP relaxation pushes
  every wire to null wherever the function tables allow — surfacing cheap (null-heavy) completions
  as the relaxation's natural preference, which the branch step then exploits. **[ANALOGY —
  standard; SPECULATION until run on `L`.]**

---

## 3. Branch-and-bound / A\* — why the weighting prunes

**The mechanism is monotonicity of the cost.** Channel-activation energy is **additive** (sum over
wires) and **non-negative** (`E(v) ≥ 0.05 > 0` for every value). Therefore, in a construction search
that builds the netlist gate by gate:

- the **committed energy** `g` of a partial netlist is a **lower bound** on the energy of *any*
  completion (every remaining wire adds ≥ 0.05 pJ);
- A\* with `f = g + h`, where `h ≥ 0` is any optimistic estimate of the remaining cost (the LP
  relaxation of §2, or simply `h = 0.05 · (remaining wires)`), is **admissible and monotone**
  (consistent), so it never re-expands and finds the optimum first; and
- **branch-and-bound prunes a partial netlist the moment `g ≥ incumbent`** — because `h ≥ 0`, no
  completion of that node can beat the best solution already found.

**[DIRECT — this is the textbook B&B/A\* admissibility argument; it holds for *any* non-negative
additive cost, so the *validity* of the pruning is not specific to energy.]**

**What the energy weighting adds is the *ordering*, not the validity.** An unweighted "minimize
gate count" search has a flat objective (every gate costs 1); the energy weighting replaces it with
a sharply **skewed** objective where a ±1 wire costs **24×** a null wire. Two consequences:

1. **Early incumbent.** Best-first search (A\* by energy) descends first into null-heavy partial
   netlists (they are cheap), so it finds a near-optimal incumbent *early* — and an early incumbent
   is what makes the `g ≥ incumbent` test fire. **[ANALOGY — the 24:1 skew is DIRECT arithmetic;
   that it yields early incumbents is the standard effect of a skewed admissible heuristic.]**
2. **Tight pruning threshold.** If the optimum is null-heavy (`cost* ≈ 0.05·W + ε`), then *any*
   partial netlist with even a handful of ±1 wires on the common data paths already exceeds
   `cost*`, and is pruned. The pruning threshold is ~24× tighter than a wire-count model's. **[OURS
   — follows from the arithmetic; the *magnitude* is untested.]**

**The asymptotic reduction vs exhaustive — be quantitative and don't oversell.** Exhaustive
enumeration of netlists with `N` internal gates over `m` primary inputs, fan-in 2, library of `g`
gates, counts ordered input choices and gate types:

```
C(N) ≈ ∏_{i=1..N} g · (m + i − 1)²  =  g^N · [ (m+N−1)! / (m−1)! ]²
```

**[DIRECT — a standard labelled-DAG count; for `m=2` this is `g^N · ((N+1)!)²`.]** Concretely,
`g = 5` (`tneg, tand, tor, tmul, tadd1`), `m = 2`:

| N gates | exhaustive candidate netlists |
|---:|---:|
| 3 | 7.2 × 10⁴ |
| 4 | 9.0 × 10⁶ |
| 5 | 1.6 × 10⁹ |
| 6 | 4.0 × 10¹¹ |
| 7 | 1.3 × 10¹⁴ |
| 8 | 5.1 × 10¹⁶ |

This is **super-exponential in N** (≈ `g^N (N!)²`), and it is the search space the energy weighting
is meant to shrink. The honest statement of the shrink:

> **The energy weighting does not change the `g^N (N!)²` class.** The worst case — *proving* the
> optimum, which requires ruling out every cheaper candidate — still visits a super-exponential
> number of nodes, because the problem is NP-hard (§4). What the weighting buys is a
> **prefactor/typical-case** win: a monotone, admissible, 24×-skewed lower bound that prunes the
> ±1-heavy majority of the tree once a null-heavy incumbent is in hand. A defensible order of
> magnitude is **10²–10⁴× fewer nodes** for null-heavy target functions — but this is
> **[SPECULATION]**: it is an estimate from the 24:1 cost ratio and the early-incumbent mechanism,
> not a measured or proved reduction factor, and it has **no worst-case guarantee**.

**[The `g^N (N!)²` count is DIRECT; "the weighting gives 10²–10⁴×" is SPECULATION; "no asymptotic
change" is DIRECT from NP-hardness (§4).]**

---

## 4. The honest landscape — solvers and complexity

**Complexity class, stated plainly: NP-hard.** The decision problem MIN-ENERGY-NETLIST is NP-hard,
because it contains minimum two-level logic minimization as a special case (the "cheapest DNF/CNF"
problem is NP-hard by reduction from Set Cover — classical, Garey–Johnson). Ternary synthesis
contains binary synthesis as a sub-problem (binary embeds in ternary via two of the three digits),
so the hardness carries over. **[DIRECT — classical logic-minimization hardness; the embedding is
DIRECT.]**

**The honest nuance (do not launder it):** the minimum-size problem for *arbitrary* fan-in-2 DAGs
(the Minimum Circuit Size Problem, MCSP) is **not known** to be NP-hard — it is a famous open
problem. That does **not** rescue us: (a) our problem already contains the *two-level* restriction,
which *is* NP-hard; and (b) in practice we solve it by ILP/SAT, whose solvers are exponential in
the worst case regardless. So "NP-hard in general" is the correct, safe statement, with the MCSP
rider kept for honesty. **[DIRECT — the MCSP open status and the two-level hardness are both
standard facts.]**

**Is it reducible to a known solver? Yes, and trivially so:**

| encoding | target | calibration |
|---|---|---|
| **0-1 ILP / Pseudo-Boolean** (§2) | Gurobi / SCIP / CP-SAT | **DIRECT** — it *is* an ILP by construction; the objective is linear and every constraint is linear |
| **Weighted MaxSAT / MaxSAT** | "wire w is null under α" as a soft clause weighted `p(α)·1.15` | **DIRECT** — the min-cost SAT form is the standard exact-synthesis encoding |
| **SAT-based exact synthesis** | CDCL solver + cardinality optimization (Knuth–Burch DAG synthesis; EPFL `mockturtle`/`percy`) | **DIRECT** — an established technique for *minimum* circuits |
| **A\* / B&B over the construction tree** (§3) | LP relaxation as the admissible heuristic | **DIRECT** — textbook |

So the machinery is **off-the-shelf**: "weighted-logic search" is *not* a new algorithm, it is a
**weighted pseudo-boolean / ILP / MaxSAT formulation** whose weights are the channel energies.
**[OURS — the framing; DIRECT — the solvers and reductions.]**

**The energy weighting is a good heuristic, not a polynomial magic bullet.** It improves the
objective's tightness (24:1 skew), supplies an admissible monotone lower bound, and guides
best-first search to cheap incumbents early — all of which reduce *typical* node counts. It does
**not** move the problem out of NP-hard, and it does not turn branch-and-bound into a
polynomial-time procedure. Anyone claiming "energy weighting solves synthesis in polynomial time"
is claiming `P = NP`. **[DIRECT.]**

---

## 5. The honest boundary — CAN vs CANNOT

### What the weighted search CAN do

1. **Find better constants and cheaper realizations within the fixed physical model.** The search
   can choose among equivalent multi-gate realizations, move the free negation (`tneg` = wire swap,
   0 cost) around to sit on the low-activity side, reorder/permute inputs so the *common* cases
   produce null, and tie unused operands to the free constants. These are all decisions the energy
   weights rank correctly. **[OURS — a design claim; the free-cell facts are DIRECT.]**
2. **Reuse null-heavy fragments.** Sub-circuits whose output is **0 on common inputs** are nearly
   free under the objective, so common-subexpression elimination (CSE) biased by the energy weights
   will *share* them — the weighted search discovers the null-as-default discipline automatically.
   This is the search-level form of "power only on push/pull". **[OURS — follows from the objective;
   unmeasured.]**
3. **Optimize the *transport-side* energy against a workload.** The objective coefficients are
   `p(α)·E(v)`, so a null-heavy (Zipf) workload weighting directly re-prices the search toward
   implementations that hold null on the hot paths. This is where the weighted search has real,
   quantifiable bite — and it is the same lever as `scripts/transport.py`'s `p_null` sweep.
   **[DIRECT — the objective is linear in `p`.]**

### What the weighted search CANNOT do

1. **Erase the 2-threshold sensing tax.** Every ternary gate must still *resolve* −1/0/+1 every
   evaluation — 2 thresholds vs binary's 1 — and this is a **physical** cost paid per gate, per
   evaluation, independent of how the netlist is searched. It is measured: the ternary receiver
   costs **2.54×** the binary one (61.87 vs 24.35 fJ, `gate_energy.md`), and proved: thresholds per
   bit `(b−1)/ln b` is minimized at binary, ternary is **1.26×** worse per bit
   (`ThresholdLowerBound.lean`, `ternary_worse_than_binary`). Weighting the *search* by energy
   changes the *coefficients* (0.05 vs 1.20 pJ on a wire); it does not change this per-gate floor.
   **[DIRECT — both numbers; the "search can't touch it" is OURS and follows.]**
2. **Make a `tand` cost less than its measured 85.19 fJ, or remove the 61.87 fJ receiver.** The
   search optimizes *which* gates and *how many* and *what values flow through them* — it does not
   re-engineer the cells. The tax is in the cell, not in the search. **[DIRECT — `gate_energy.md`.]**
3. **Close the wire/gate gap, because the objective only costs *wires*.** The 0.05/1.20 pJ weights
   are **transport** energies. A gate's own energy (min 85.19 fJ/toggle ≈ 0.085 pJ, dominated by a
   fixed 61.87 fJ receiver) is a **separate, larger, per-evaluation** term that the §2 objective
   does not even see. So "minimal-energy netlist" under this objective is minimizing
   **wire/activity** energy, *not* the full gate energy — and it is the gate energy where the
   2-threshold tax lives. This is the single most important honesty clause in the file. **[DIRECT —
   the two energy tables are from two different files and two different physical layers; the
   conflation risk is the exact one `meta_mishandled.md` §6 flags.]**
4. **Provide a polynomial algorithm.** §4. The "we can decrease the search space" claim is
   **heuristic and typical-case** (10²–10⁴×, SPECULATION), never an asymptotic change. **[DIRECT.]**

**The one-sentence boundary:** the weighted search re-prices the **search** (which cells, which
wiring, which values flow) by the true **wire** energies — it can find cheaper constants and reuse
null-heavy fragments — but it cannot re-price the **sensing**, which is a per-gate physical cost
(the 2-threshold tax) that the search, however well weighted, still has to pay in silicon.

---

## 6. Calibration summary

| claim | calibration |
|---|---|
| encoding 2 wires/trit, 11=NEVER, one-hot-per-direction | DIRECT — `TernaryCell.lean`, `rtl/trit_functions.vh` |
| E_null=0.05, E_±1=1.20 pJ (wire/transport) | DIRECT — `scripts/transport.py`, `ENERGY_RESULTS.md` |
| objective ≈ minimize non-null wire activity (24:1 gap) | OURS — one-line arithmetic on DIRECT constants |
| one-hot rows have ≤3 nonzeros → sparse matrix | DIRECT — counting |
| one-hot = the physical 11=NEVER constraint | DIRECT — `encode_never_both`, `energy_le_one` |
| one-hot ⇒ tighter LP relaxation ⇒ more pruning | ANALOGY (standard MILP) / SPECULATION (unrun on L) |
| additive non-negative cost ⇒ monotone admissible lower bound ⇒ valid B&B/A\* pruning | DIRECT — textbook |
| 24:1 skew ⇒ early incumbent ⇒ tight pruning threshold | OURS — arithmetic; magnitude SPECULATION |
| exhaustive space ≈ `g^N·((m+N−1)!/(m−1)!)²` | DIRECT — labelled-DAG count |
| energy weighting gives 10²–10⁴× fewer nodes (typical case) | SPECULATION |
| MIN-ENERGY-NETLIST is NP-hard | DIRECT — subsumes min two-level logic minimization (Set Cover) |
| MCSP not known NP-hard (rider) | DIRECT — open problem |
| reducible to 0-1 ILP / PBO / Weighted MaxSAT / SAT-exact-synthesis | DIRECT — by construction + established tools |
| cannot erase the 2-threshold tax (2.54× measured, 1.26×/bit proved) | DIRECT — `gate_energy.md`, `ThresholdLowerBound.lean` |
| objective costs wires, not the gate receiver energy | DIRECT — the two energy tables differ |

---

## 7. TODO / not covered / caveats

1. **The truth-table encoding is exponential in `n`.** §2 indexes variables by the `3ⁿ` input
   vectors, so the ILP is practical only for small *operations* (n = 1–4, i.e. 3–81 rows), which
   is exactly the cell-library target, but **not** for 32-trit word-level synthesis. A word-level
   version needs BDD / structural / don't-care encodings (or incremental/don't-care exact
   synthesis) — out of scope, unfiled.
2. **No instance has been run.** Everything in §3 about the pruning magnitude is arithmetic +
   standard-solver lore, not a measured node count. The immediate experiment: encode one 2-input
   target (say `tadd1.sum(x,y,0)` or `tmul`) as the §2 ILP, and measure B&B node counts with vs
   without the energy weights (flat weights = "minimize non-null count", energy weights = "minimize
   pJ"). That A/B *is* the test of "weighting reduces the search space."
3. **The objective under-prices the gate.** §5.3: a faithful cost should be
   `cost = Σ_wires p(α)·E_wire(v) + Σ_gates p_eval·E_receiver` — the per-evaluation receiver term is
   fixed and must be added before the search's answer is a *true* gate-energy minimizer, not a
   wire-energy minimizer.
4. **Activity model is asserted, not measured.** `p(α)` is uniform here; the null-heavy (Zipf)
   workload weighting is stated, not fed by a real trit-activity trace (`meta_mishandled.md` §6.3's
   "no workload model").
5. **Connectivity variables were sketched, not detailed.** The MUX rows in §2.5 are the standard
   but verbose part; a real spec must fix the port ordering, the constant injection, and the
   fan-out/fan-in bounds per cell (tadd1 is 3-input, tneg 1-input — the `g^N (N!)²` count in §3 is
   fan-in-2 only).
6. **The "one-hot ⇒ prune-able" claim is ANALOGY, not a theorem.** It rests on SOS1/clique-cut
   behaviour that is well understood for *generic* MILP but not demonstrated on *this* gate library
   and encoding. Do not promote it past ANALOGY until experiment #2 runs.
7. **`tadd1` vs `tsum` naming.** `gate_energy.md` measures the mod-3 sum cell as `tsum` (68 T);
   `gates.md` names the 3-operand balanced full adder `tadd1` (146.39 µm² / 25 cells). The §2
   function-table constraint for `tadd1` must use the *3-input* table (a, b, cin → {sum, carry});
   `tadd1.sum(x, y, 0)` is the 2-input mod-3 sum with cin tied to the free constant 0.
8. **Hardness is inherited, not re-derived.** "NP-hard" here is cited from classical logic
   minimization (Set Cover), not a fresh reduction from a ternary instance. A self-contained
   reduction (e.g. binary NAND-synthesis ⊆ ternary) is a small unfiled piece if a future reader
   wants the proof in-house.

---

## Sources

**Ours (DIRECT, measured/proved):**
- `scripts/transport.py` — E_null = 0.05 pJ, E_±1 = 1.20 pJ (fair-fight operating point).
- `docs/compute/gate_energy.md` — measured gate energies; 2-threshold receiver tax 2.54× (61.87 vs
  24.35 fJ); min/tor/tsum 85.19/82.73/183.61 fJ.
- `docs/compute/gates.md` — encoding, cell library, completeness (`{tadd1, tmul}` F₃ pair), the
  free negation.
- `docs/compute/ground_up/minimal_gates.md` — minimal complete set `{mod-3 sum, mod-3 product}` +
  free constants; negation derived (`x ⊕ x`).
- `proofs/lean-src/hexagon/Hexagon/ThresholdLowerBound.lean` — `(b−1)/ln b` minimized at binary;
  `ternary_worse_than_binary` (1.26×/bit); the 2-threshold lower bound.
- `proofs/lean-src/hexagon/Hexagon/TernaryCell.lean` — `encode_never_both`, `null_is_free`,
  `energy_le_one`, `average_energy` (the one-hot encoding).
- `docs/compute/ground_up/meta_mishandled.md` §6 — the wire/gate/metric conflation this file's §5
  is written to avoid.
- `docs/TERNARY_GROUND_UP.md` — the search-space list (device/encoding/logic/topology/set).

**External (DIRECT, classical — cited at the level of known results, not re-derived here):**
- Minimum two-level logic minimization is NP-hard (Set Cover reduction; Garey & Johnson,
  *Computers and Intractability*).
- The Minimum Circuit Size Problem is not known to be NP-hard (open).
- SAT/ILP-based exact synthesis — the Knuth–Burch DAG-synthesis technique and the EPFL
  `mockturtle`/`percy` exact-synthesis toolchain (standard references in the logic-synthesis
  literature).
- Branch-and-bound / A\* admissibility and the SOS1 / at-most-one formulation — standard
  combinatorial-optimization text.

*No number in this file is invented: the energies are from `scripts/transport.py` /
`gate_energy.md`, the cell facts from `gates.md` / `minimal_gates.md`, the tax from
`ThresholdLowerBound.lean`, and the search-space counts are arithmetic on a standard labelled-DAG
formula. The only new quantitative claim — the 10²–10⁴× pruning estimate — is explicitly
SPECULATION.*
