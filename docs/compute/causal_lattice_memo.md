# Causal-Lattice Memoization for Ternary Circuit Synthesis — "each path exists once"

**Status:** DESIGN DOC + measured prototype. Not a proof, not silicon.
**Date:** 2026-08-30 (session).
**Companion files:**
- Prototype: `scripts/circuit_memo.py` (stdlib-only; runs, prints numbers, stores into a `.latx`).
- Grounding: `proofs/lean-src/hexagon/Hexagon/CausalLattice.lean` (flow / curl / diamond_balance),
  `proofs/lean-src/hexagon/Hexagon/Residual.lean` (stored primitive `r = O − E`),
  `docs/compute/ground_up/minimal_gates.md` (the `{⊕, ⊗}` cell set), `docs/compute/ground_up/truth_table.md`.
- House calibration legend (unchanged): **DIRECT** = measured/proved/citable; **ANALOGY** =
  parallel structure, different object; **OURS** = our design claim that *follows from* a DIRECT
  fact but is unmeasured; **SPECULATION** = untested hypothesis.

---

## 0. Verdict up front

Memoizing ternary circuit fragments by a **canonical truth-table signature** *does* remove
redundancy — the measured dedupe is **187.8× functional** and **8.0× further under
permutation + free negation** (55,415 syntactic fragments → 295 functions → 37 canonical
classes). But the honest finding is that **this is ordinary functional hashing** (the technique
ABC/`fraig`, CEGAR, and every modern synthesizer already use), and **the causal lattice
contributes the content-addressable *store*, not the compression**. The lattice's own
mathematics — the signed residual `r = O−E`, the wedge, flow/curl, `diamond_balance` — is
about **temporal precedence between co-occurring tokens**, which is a *different object* from
"which netlists compute the same function". The pitch "put fragments on the causal lattice and
each path exists once" is therefore **real as a store, metaphor as a compiler**.

---

## 1. The problem being solved

Minimal-energy ternary synthesis enumerates netlists (compositions of cells over `{−1,0,+1}`)
and scores each by energy. Two sources of blow-up:

1. **Functional duplication** — many *different* trees realize the *same* function
   (`x⊕x⊕x = −x`, `neg(neg(x)) = x`, `x⊕0 = x`, commutativity/associativity of `⊕`/`⊗`). [DIRECT]
2. **Permutation / renaming duplication** — the *same fragment* re-appears with its input wires
   permuted, or an input/output negated. Negation is a wire swap in balanced ternary (0 cells,
   0.00 µm² measured in `gate_area.md`), and input re-wiring is free, so these variants have
   **identical energy** and only one representative needs to be kept. [DIRECT for "negation is
   free"; the *dedupe-worthiness* is OURS — it depends on the cell library being
   negation-equivariant, §5.]

The claim to test: storing each *distinct* fragment once and reusing it removes this blow-up.

---

## 2. The representation: fragment → signature → lattice node

A fragment is an **expression tree** over a tiny cell set. The prototype uses 9 cells —
`{const−1, const0, const+1}` (arity 0), `{neg, id}` (arity 1), `{sum ⊕, mul ⊗, min, max}`
(arity 2) — matching the minimal complete set `{⊕, ⊗}` plus the K₃ lattice fragment. [DIRECT,
the cell set is from `minimal_gates.md`.]

Three signatures, three keys, three levels of collapse:

| level | key | what it collapses | calibrated |
|---|---|---|---|
| **raw truth table** | the 9-tuple of outputs over `(x,y) ∈ {−1,0,+1}²` | nothing (identity) | DIRECT — a function *is* its table |
| **permutation signature** | lex-min of the table and its transpose | input swap `x↔y` | DIRECT — rewiring is free |
| **canonical signature** | lex-min over the free-renaming group `G = C₂(swap) × C₂(neg-x) × C₂(neg-y) × C₂(neg-out)` (`|G|=16`) | input swap + input/output negation | **CONDITIONAL** — see §5 |

The canonical signature is encoded as a **lattice word string**, e.g. the class of `x⊕y` is
`f2:-+0+0-0-+` (`-` = −1, `0` = 0, `+` = +1, row-major `x`-slow). This string is what is
stored as a lattice **node id**. [OURS — the key format is our choice; nothing here depends on
the lattice's algebra.]

> **Why the truth table is the right key (and the honesty check).** A function of `k` trits is
> *fully determined* by its `3^k`-entry table; two fragments are the same fragment-as-function
> iff their tables are equal. So "did I already see this fragment?" is *exactly* an equality test
> on a canonical form of the table. This is not a lattice fact — it is the standard
> **functional-hashing / e-graph** reduction. [DIRECT — standard technique.]

---

## 3. The three "moves", and what they actually are

| proposed move | what it is *here* | calibration |
|---|---|---|
| **"fragment as lattice node"** (truth-table signature as key) | a string key into a key→record store; the lattice's `down`/`lattice-lookup` give exactly this (key-value with an on-disk `.latx` binary) | **DIRECT** — the store exists and works (verified headless, §4) |
| **"find overlap = `lattice-lookup`/`sense`"** | `lattice-lookup --word <w>` returns the node's **neighbors ranked by co-occurrence residual `r = O−E`**, *not* "is there a fragment with this signature" and *not* "which fragments share a sub-function" | **STRETCH** — a residual-neighbor walk is the wrong query for functional overlap |
| **"dedupe = each path exists once"** | dedupe is **canonical hashing**: distinct signatures stored once because the *key* is canonical; the same netlist under permutation/negation produces the same key | **DIRECT as a technique, but OURS-as-attributed** — the win comes from the canonical signature, not from any property of the causal lattice |

Two clarifications that carry the honesty load:

1. **"Have I seen this signature?" is an exact-key existence check**, which the lattice *can*
   do (lookup a missing word → "not found") but which is the boring O(1)/O(degree) part of the
   engine — not the `sense` 2-hop abstract search, and not the flow/curl field.
2. **The causal lattice's native semantic is different.** `CausalLattice.lean` formalizes
   `flow(w) = Σ wedge(w, nb)` over the six ℤ[ω] unit directions, `curl` = the skew part, and
   `diamond_balance` = the pod's outflow cancelled by the ring's backflow (`Σ(O−E) = 0`).
   That is **temporal precedence / circulation between co-occurring tokens** — a Rung-1
   association structure. A circuit fragment's truth table has **no co-occurrence, no wedge, no
   diamond**. Putting signatures on it uses the lattice's *key-value store* and *ignores* its
   causal algebra. [DIRECT reading of the Lean files; the "ignores" is OUR editorial claim.]

So: the **store is a real, working substrate**; the **"compiler" is the canonical signature**, and
it does not live in the causal lattice.

---

## 4. Measured numbers (from `scripts/circuit_memo.py`)

k = 2 inputs, 9 cells, all trees of size ≤ 6 (`size` = total node count):

```
syntactic trees enumerated            55,415
distinct truth tables (functions)        295     compression   187.8x   [FUNCTIONAL hashing]
distinct modulo input permutation        170     compression   326.0x   [permutation only]
distinct canonical signatures             37     compression  1497.7x   [permutation + free negation]
distinct (parent,subfragment) edges      150     (the stored overlap graph)
```

- The **permutation-only** collapse is `295 → 170` = **1.7×** — small, because k = 2 has only
  `S₂` (2 elements) to permute.
- The **permutation + free-negation** collapse is `295 → 37` = **8.0×** (mean 7.97 distinct
  functions per canonical class, max 16 — consistent with `|G| = 16` minus stabilizers).
- A concrete orbit: `x⊕y`, `y⊕x`, `(−x)⊕y`, `x⊕(−y)`, `−(x⊕y)`, `−((−x)⊕(−y))` — all six map to
  the single node `f2:-+0+0-0-+`.
- The **k = 3** orbit check: the `S₃` orbit of `min(max(x,y), z)` has 3 distinct tables (the
  `x↔y` swap is a stabilizer because `max` is symmetric) and collapses to **1** canonical node.
  This is where the pitch's "k!" payoff lives: **k=2 → 2×, k=3 → 6×, k=4 → 24×, k=5 → 120×**.

The prototype *actually stores and queries* the lattice headlessly: `lattice-cli down` wrote the
37 canonical nodes + 150 sub-fragment containment edges to a `.latx`, and
`lattice-lookup f2:---------` returned its sub-fragments (`f2:000000000`, `f2:---000+++`) ranked
by residual correlation. **Caveat the prototype prints itself:** the dedupe measurement is done
with an in-process `dict`; the lattice is used only as the persistent store, and the numbers are
identical without it. [DIRECT — verified on this machine.]

**Two honesty flags on the 187.8× figure.**

1. The tree enumeration is *deliberately dumb*: it does not syntactically prune `id(x)`,
   `neg(neg(x))`, `x⊕0`, `x⊗1`, double-negation, etc. A real synthesis enumerator prunes those
   at generation time, so its tree→function ratio is **lower** than 187.8×. That number is an
   *upper bound* on the functional-hashing win for this cell set, not a claimed synthesis gain.
2. The 8.0× rename win is **conditional**: it is only sound because the cell set `{⊕, ⊗, min,
   max, neg}` is **negation-equivariant** (§5). A general gate library is not.

---

## 5. Calibration of the mapping (the table the task asks for)

| claim | calibration | why |
|---|---|---|
| Fragment = expression tree over a tiny cell set | DIRECT | definition |
| Signature = canonical truth table; equality = same function | DIRECT | a function *is* its `3^k` table |
| Dedupe by signature removes the permutation/renaming blow-up | **OURS (conditional)** | only if the renamings quotient are *free* in the library |
| Negation is free (wire swap) in balanced ternary | DIRECT | measured 0.00 µm² (`gate_area.md`) |
| Input permutation is free (rewire) | DIRECT | definitional |
| "Put the distinct signatures in the causal lattice" | **DIRECT as a store** | `down`/`lattice-lookup` verified headless |
| "Find overlap = `lattice-lookup`/`sense`" | **STRETCH** | lookup returns residual-neighbors, not functional overlap; sub-fragment containment has to be *stored as edges by us*, re-purposing the edge table |
| "Dedupe = each path exists once" (lattice property) | **SPECULATION** | the lattice's "one path" is about its residual edge DAG, not about canonical-function orbits; the dedupe is the *signature*, not the lattice |
| "A combinatorial compiler" | **ANALOGY** | a real combinatorial compiler = an e-graph / functional hash-cons; the lattice is a plausible *persistence* layer for one, not the compiler itself |
| Negation-equivariance of `{⊕, ⊗, min, max}` | DIRECT | `−(a⊕b) = (−a)⊕(−b)`, `−(a⊗b) = (−a)⊗b`, `min(−a,−b) = −max(a,b)`, etc. — all checkable in 3 lines |
| The Z₆ hex symmetry ≅ the renaming group | **ANALOGY** | the Eisenstein rotation (ω) and negation (−1↔+1) are both renamings of ℤ[ω], but the truth-table group is discrete `S₂ ⋉ C₂³`, not the hex rotation; related, not identical |

---

## 6. Honest verdict: real speedup or metaphor?

**Real speedup, wrong attribution.** Functional + permutation memoization *does* shrink the
search space — 55,415 → 37 on the toy example — and for k ≥ 3 the k! permutation term becomes
large. But:

1. The win is **functional hashing**, a 40-year-old synthesis technique, *independent of the
   causal lattice*. A Python `dict` keyed by the canonical signature does exactly this, in
   process, faster than `lattice-cli`'s subprocess round-trip.
2. The **causal-lattice-specific machinery (residual, wedge, flow/curl, diamond)** does *none*
   of the work. It is the wrong algebra for the problem: it measures *co-occurrence
   precedence*, not *functional equivalence*.
3. The **permutation/renaming** term is small at k = 2 (2×) and only large at higher arity;
   and the **negation** term (the bigger piece of the 8×) is ternary-specific and library-
   dependent.

So "**put fragments on the causal lattice**" is a **real, working store and a metaphor as a
compiler**. The combinatorial win ("each path exists once") is real, but it is delivered by the
**canonical signature**, not by the lattice; the lattice is, at best, the on-disk key-value
layer that *persists* the signature→cost table across synthesis runs.

---

## 7. What would make the lattice the *right* substrate (design sketch, OURS)

The one place the lattice genuinely helps a synthesizer is **cross-run, persistent memoization**
— caching `signature → (min cost, representative netlist)` so a later synthesis of a larger
target reuses earlier sub-circuit results without re-deriving them. Concretely:

1. **Store** each canonical signature as a node; attach its minimal cost as a record.
2. **Store** the containment DAG (parent fragment → child fragments) as edges — the prototype
   already does this — so `lattice-lookup <sig>` returns sub-circuits = the "overlap" query,
   *but only because we wrote those edges ourselves*.
3. The **"have I seen it"** query is an exact-key lookup (node present?), *not* `sense`.
4. The **combinatorial compiler** is then a standard e-graph / hash-cons over the signature
   space, with the lattice as its *durable backing store*.

This is a legitimate architecture. It is **not** a new computation class, and it does **not**
route the compression through the causal algebra — it uses the lattice's key-value store and
file format. [OURS — a design claim that follows from the DIRECT facts above; unbuilt.]

---

## 8. Over-claims to avoid (the guardrail list)

- ❌ "The causal lattice's flow/curl/diamond removes circuit duplication." It doesn't; the
  canonical signature does.
- ❌ "`lattice-lookup` finds equivalent fragments." It finds co-occurrence neighbors; the
  equivalence test is exact key equality.
- ❌ "187.8× is a synthesis speedup." It's an upper bound from a deliberately dumb enumerator.
- ❌ "Negation dedupe is free in general." It's free in *this* ternary library only.
- ✅ What survives: a content-addressable store keyed by canonical truth-table signatures
  removes *functional and renaming* duplication, measured at **187.8× → 8.0× → (k! at higher
  arity)**, and the causal lattice is a working, persistent place to keep that store.

---

## 9. Next steps

1. Generalize `circuit_memo.py` to k = 3 (permutation = `S₃`) and measure the orbit collapse on
   a *fully asymmetric* fragment (orbit size 6, not 3).
2. Add the cost map: store `signature → min energy` and demonstrate cross-run reuse (store at
   size ≤ 4, query during a size ≤ 6 run).
3. Port the canonical-signature function to the Lean ledger (`Signature.lean` already has the
   four i²-signatures; a truth-table-orbit `canonical` definition + `lake build` would turn the
   "conditional" dedupe into a proved fact).
4. Decide, explicitly, whether the lattice is the store of record or an in-process dict is —
   the numbers are identical either way, which is itself the finding.
