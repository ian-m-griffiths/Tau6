# Balanced-Ternary Logic — Synthesis (truth_table × minimal_gates × PolarGate)

**2026-08-29 — the "logic" synthesis of ground-up batch 1.** This file reads the three logic
documents — the truth-table reference (`truth_table.md`), the minimal-complete-set argument
(`minimal_gates.md`), and the Lean gate semantics (`../proofs/lean-src/hexagon/Hexagon/PolarGate.lean`)
— and does four things the individual files cannot: (1) states the overlap they all agree on,
(2) names the disagreements, (3) merges their TODO/caveat tails into one ranked list of untested
questions, and (4) isolates the single logic-level fact that would most move the verdict.

**Scope.** Only the three named files. Sibling ground-up files (`device_circuit.md`,
`meta_critique.md`, `polar_gates.md`, `gate_energy.md`, …) exist and are referenced where a
claim *should* now be closed, but they are **not** folded in here; that is listed in the tail as
out of scope, not as a gap in the three files.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — definition or first-principles derivation; a truth table, a count, a Lean theorem
  (`lake build`-green), or a citable literature number. Carried verbatim from the files'
  own DIRECT tags where the files verified it.
- **ANALOGY** — the *name/role* parallels something (Boolean NAND/XOR, Łukasiewicz L₃, CNTFET
  counts), but the mapping is a translation, not an identity.
- **OURS** — a project design claim carried from project files (RTL, the negation-reduction
  framing, the "two cells" library).
- **SPECULATION** — editorial/selection judgment, ranking, or an unmeasured hypothesis. The
  ranking in §3 is SPECULATION by construction; the facts it ranks are not.

---

## 1. Overlap — what all three agree on

These are the facts the three documents state *jointly and consistently*. A fact goes here only
if no file contradicts it; each is tagged with its strongest source.

### 1.1 The carrier is the field F₃, and the value set is balanced

All three use the balanced trit **T = {−1, 0, +1}**, symmetric about 0, and all three identify it
with the **field of order 3**: `(T, ⊕, ⊗) ≅ F₃ ≅ ℤ/3`. The digit relabel is the **residue**
mapping `−1 ≡ 2 (mod 3)`, `+1 ≡ 1 (mod 3)`, `0 = 0`.

- `truth_table.md` §1: "(T, ⊕, ⊗) ≅ F₃". [DIRECT]
- `minimal_gates.md` §1: "{−1, 0, +1} ≅ {2, 0, 1} (mod 3)". [DIRECT]
- `PolarGate.lean`: `Trit := Fin 3` (Z/3), `tritInt` records the balanced reading `2 ↦ −1`. [DIRECT]

### 1.2 The irreducible new operation is the mod-3 sum ⊕ (tsum)

All three agree that the one operation the Kleene/lattice system cannot express — the genuinely
*new* operation — is the **mod-3 sum** `⊕ = (x + y) mod 3`, the balanced Latin square (Cayley table
of (F₃,+)), the operation that carries the cyclic structure.

- `truth_table.md` §3.2, §7: "⊕ … is not regular … This is the one irreducible gap"; "The
  irreducible new operation is ⊕". [DIRECT — counterexample verified]
- `minimal_gates.md` §2: "min/max/neg … cannot produce the cyclic / field structure that
  interpolation needs". [DIRECT]
- `PolarGate.lean`: `tsum` is the additive group; `tsum 1 1 = 2` is "+1 + +1 = −1" (balanced
  carry), `tsum_neg` proves additive inverses, `neg_tsum` proves negation is a group
  homomorphism. [DIRECT]

### 1.3 The minimal complete set is {⊕, ⊗} + constants; negation is derived, not primitive

All three agree completeness comes from the **field pair** `{⊕, ⊗}`, that **negation is not a
third primitive** (`−x = x ⊕ x` since `2 = −1` in characteristic 3), and that **one nonzero
constant** must be seeded (the "vanishes at the all-zero input" argument).

- `truth_table.md` §3.1: "negation is not primitive in F: −x = x ⊕ x"; without a constant a
  polynomial has zero constant term, so `f(0,…,0) = 0`. [DIRECT]
- `minimal_gates.md` headline + §1: "two gates — {mod-3 sum, mod-3 product} … negation is NOT a
  third primitive"; `−x = x ⊕ x`, `0 = x ⊕ x ⊕ x`, no nonzero constant derivable. [OURS for the
  reduction framing; DIRECT for the F₃ algebra it rests on]
- `PolarGate.lean`: `neg` is the unary additive-inverse gate (not built from `tsum` in the file,
  but `tsum_neg` proves `neg t + t = 0`), `tsum`/`tprod` are the binary field ops, and the file's
  self-described "field-pair completeness anchor" is distributivity (`tprod_distrib`). [DIRECT]

### 1.4 The completeness mechanism is Lagrange interpolation over F₃

All three route completeness through the same theorem: **every function F₃ⁿ → F₃ is a polynomial
in ⊕ and ⊗**, using Fermat `x³ = x`.

- `truth_table.md` §3.1: "Every function … is a polynomial in ⊕ and ⊗ … using x³ = x (Fermat)".
  [DIRECT]
- `minimal_gates.md` §2: the full construction with Lagrange basis `δ₀, δ₊, δ₋`. [DIRECT]
- `PolarGate.lean`: proves only the *anchor* (`tprod_distrib`), not the full interpolation
  theorem — see §3.2. [DIRECT for the anchor; the full theorem is absent]

### 1.5 The Kleene/lattice basis {¬, min, max} is NOT universal

All three agree `{¬, min, max}` (Kleene strong logic K₃) generates only a proper fragment — the
monotone/regular functions — and can never make the cyclic structure.

- `truth_table.md` §3.2: "K = regular fragment (never universal)". [DIRECT]
- `minimal_gates.md` table + §2: "{min, max, neg} ❌ lattice fragment". [DIRECT]
- `PolarGate.lean`: presents `tmin`/`tmax` as the *lattice* part, separate from the *field* part
  `tsum`/`tprod`, with no completeness claim for the lattice part alone. [DIRECT]

### 1.6 The digit convention (where the field identity lives)

All three use the **residue** convention `0=0, 1=+1, 2=−1`, and this is the only convention under
which the field identities hold. This is one of the two things the three files agree on *against*
an external brief (see §2.1). [DIRECT]

### 1.7 The balanced/Latin-square status of ⊕

`truth_table.md` flags ⊕, ⊖ (= x⊕¬y), and ¬⊕ as the **only balanced binary gates among the useful
ones** (each output −,0,+ appears exactly 3 times; ⊕ is a Latin square). The other two files do not
enumerate balance, but they agree ⊕ is the additive group / Latin square. Coverage asymmetry, not
a conflict. [DIRECT — truth_table.md §5.5–5.8, §7]

---

## 2. Disagreements — where they conflict

### 2.1 Digit convention: residue-order vs display-order (the one real conflict — external)

The sharpest conflict in the set is **not between the three files, but between the files and the
task brief** that they were written against.

- The brief's mapping — **"0 = −1, 1 = 0, 2 = +1"** (what we call **display-order**: digits in
  the value order −1 < 0 < +1) — is **inconsistent with the required identities**.
- `PolarGate.lean` makes the argument explicit in its convention note: `tsum t 0 = t` forces
  digit `0` to be the additive identity (balanced 0), and `tsum (neg t) t = 0` forces `neg` to
  be the additive inverse (so `neg 1 = 2`, i.e. `+1 ↦ −1`). The only consistent mapping is
  **residue-order**: `0=0, 1=+1, 2=−1`.
- `truth_table.md` §1 and `minimal_gates.md` §1 resolve it only *implicitly*, by writing
  `−1 ≡ 2 (mod 3)`. `PolarGate.lean` is the file that *argues* it.

**Reading:** the three files are in agreement (residue-order); the disagreement is with the
brief. The hazard is real: a reader who trusts the brief's display-order will misread every
`tsum`/`tprod` table by transposing `±1`. The bridge is not a settled theorem — see §3.3.
[DIRECT — `PolarGate.lean` convention note]

### 2.2 Is ⊗ "new to the field" or "already in the lattice"? (emphasis, not contradiction)

`truth_table.md` §5.7 makes a non-obvious claim: **⊗ is inside the Kleene fragment** —
`x⊗y = (x∧y) ∨ (¬x∧¬y)`, verified entry-by-entry. Hence the field basis's *only* real addition
over K is ⊕, not ⊗.

`minimal_gates.md` presents `{⊕, ⊗}` **symmetrically** as the two field primitives (§2, §3), and
its phrasing "min/max … cannot produce the cyclic / field structure" can be misread as claiming ⊗
is as irreducible as ⊕. It is not: ⊗ is K-derivable; ⊕ is not.

Both are literally true (⊗ ∈ K *and* ⊗ is a field primitive), so this is an **emphasis/coverage**
tension, not a falsity. But it matters: a reader of `minimal_gates.md` alone could conclude the
field basis contributes *two* new operations, when it contributes **one** (⊕). [DIRECT — both
claims verified in `truth_table.md` §5.7 and §3.2]

### 2.3 Median/majority: "complete" (minimal_gates) vs "inside the incomplete Kleene fragment" (truth_table) — the sharpest internal conflict

This is the one place the corpus **contradicts itself**:

- `minimal_gates.md` §3 fact 4 and TODO #9 claim that "higher-arity single gates (3-input
  majority/median) are complete" — i.e. a Sheffer function *reappears* at arity 3.
- `truth_table.md` §6 proves **maj3 = median(x,y,z) = (x∧y)∨(y∧z)∨(z∧x)** is **K-derivable with
  no constant** — i.e. it sits *inside* the regular fragment, which §3.2 proves is **not**
  universal.

These cannot both hold. The median is monotone in the order −1 < 0 < +1; constants are monotone;
monotonicity is preserved under composition; the successor (cycle) is not monotone. Therefore the
clone generated by the median alone is a subclone of the regular fragment ⊊ full clone — **the
plain 3-input median is NOT a Sheffer function**. Resolution: a higher-arity Sheffer function, if
one exists for radix 3, must be *non-regular* (it must escape the monotone fragment); the MVL
"consensus-plus" may be such a function, but the median is not. `minimal_gates.md` conflates the
two. [DIRECT — the median ∈ K fact is proved in `truth_table.md` §6; the monotonicity argument is
first-principles]

### 2.4 "Negation primitive or not" — bookkeeping, not a disagreement

`truth_table.md` still *names* the F-basis "{negation, mod-3 sum ⊕, mod-3 product ⊗}" (with a
§3.1 note that negation is derivable), while `minimal_gates.md` drops negation and makes the
reduction its headline. Same fact, different labeling. [DIRECT]

### 2.5 "Minimal" means two different things

`minimal_gates.md` TODO #6 concedes `{⊕, ⊗}` is minimal in **gate count**, not in **cost**: ⊕ is
the 4.33× expensive cell, so a cost-minimal library might prefer `{min, max, neg}` for the logic
slice and pay for ⊕ only where the field structure is needed. `truth_table.md` §7's "one-line
reading" treats minimality purely at the derivability level. Not a cross-file conflict, but a
place where "minimal" is overloaded and worth keeping straight. [DIRECT for both uses; the
cost-vs-count trade is SPECULATION until energy numbers exist]

### 2.6 Coverage asymmetries (not conflicts, but worth listing)

- **Balanced-output counts** (6 of 27 unary, 1680 of 19 683 binary) appear only in
  `truth_table.md`. Neither other file addresses output balance. [DIRECT]
- **Realization numbers** (µm², CNFETs) appear only in `minimal_gates.md`; `truth_table.md`
  explicitly defers them. [DIRECT]
- **Lean theorems** exist only in `PolarGate.lean`; the two prose files cite the ledger but the
  ledger proves strictly less than the prose asserts (see §3.2). [DIRECT]

---

## 3. New research — merged TODO, ranked

One ranked list of the three files' open items, merged and de-duplicated. Rank = (how much it
moves the verdict) × (how unproven it currently is). The ranking itself is SPECULATION; each
item's content is tagged by its own calibration.

### Rank 1 — The maximal-clone confirmation (settles "minimal set" at the logic level)

Prove that the clone generated by `{min, max, neg, ⊕}` is the **full clone** and that the regular
fragment is exactly K, by the **Rosenberg/Jablonskij maximal-clone test** — verify the generated
clone is contained in no maximal (pre-complete) clone — instead of the per-gate invariant
arguments both prose files use.

This subsumes `truth_table.md` TODO #1 ("a clone-theory pass would make §3.2 a cited theorem
rather than a per-gate invariant argument"). It is *finite and doable* **because** the full clone
lattice is not: the clone lattice of radix 3 is not enumerable (Yanov–Muchnik 1958: for k ≥ 3
there exist closed classes with no finite basis), so "enumerate the full Post-lattice" is a
non-starter — but the **maximal clones are finite and classified** (Rosenberg 1970; 18 for k=3,
Jablonskij 1954). This is also the single decisive fact (§4). [DIRECT-literature — the maximal-clone
classification and the 18 count must be re-cited from the primary sources, not re-derived; see tail]

### Rank 2 — Close the Lean ledger's F₃ ring/field axioms and the lattice half

`PolarGate.lean` proves **commutativity, identity, inverses, and distributivity** — but **not**:

- associativity of `tsum` and of `tprod` (the task's own example; trivially true, unproved);
- `tprod` absorbing 0 (`tprod a 0 = 0`) and `tprod`'s identity 1 (`tprod a 1 = a`);
- Fermat `x³ = x` and the full Lagrange-interpolation completeness theorem (only the
  distributivity *anchor* is proved);
- the lattice half: `tmax_comm` (only `tmin_comm` is there), `tmin_idem` (only `tmax_idem`),
  dual absorption, lattice distributivity, and De Morgan (`neg` over `tmin`/`tmax`).

Each is a one-line `fin_cases <;> decide` proof, but their absence means "F₃ is a field" is
*asserted* in prose and only *partially* proved in Lean. Close them; promote the "field-pair
completeness" from anchor to theorem. [DIRECT — the gaps are read off `PolarGate.lean`; the
proofs are finite arithmetic]

### Rank 3 — The digit-convention bridge (make §2.1 a theorem, not a warning)

Prove a **relabeling bijection** φ : Fin 3 ≃ Fin 3 between the residue convention (`0=0, 1=+1,
2=−1`) and the brief's display convention (`0=−1, 1=0, 2=+1`), and that `tsum`/`tprod`/`neg`/
`rot1`/`rot2` translate correctly under it. Currently this is a prose *warning* in
`PolarGate.lean` and an implicit choice in the two prose files; the bridge that lets a reader
move between conventions without error is exactly the failure mode the convention note is
guarding against. [DIRECT for the need; the theorem is unproved]

### Rank 4 — The binary-subalgebra theorem (does ternary strictly generalize binary?)

Formalize that the subset **{−1, +1}** (digits {2, 1}) is closed under `neg`, `min`, `max`, `⊗`,
and that under the identification `−1 ↦ 0, +1 ↦ 1` this subalgebra **is Boolean logic**:
`min = AND`, `max = OR`, `neg = NOT`, `⊗ = XOR`, with the balanced `0` as the excluded middle.
This is the precise sense in which "binary is the {±1} subalgebra of balanced ternary" and
"ternary strictly generalizes binary with no loss." It is *implied* by `truth_table.md` §3.2's
observation that "{−,+} is closed" under all three K ops, but never stated or proved. This is
the theorem that pins down the "superset / no-loss" argument the architecture leans on.
[SPECULATION-to-DIRECT — the closure facts are DIRECT; the "is Boolean logic" identification is
the unproved theorem]

### Rank 5 — Prove ⊕-irreducibility and the ⊗∈K identity in Lean

Two theorems that make §1.2 and §2.2 formal:

- `tprod a b = tmax (tmin a b) (tmin (neg a) (neg b))` — the `truth_table.md` §5.7 identity that
  ⊗ is inside the Kleene fragment. A single equality theorem. [DIRECT — verified entry-by-entry in
  `truth_table.md`; unproved in Lean]
- ⊕ ∉ K — needs a **monotonicity predicate** (the information order `0 ⊑ ±1`) plus a
  preservation lemma ("regular functions are closed under composition, and `⊕` is not regular").
  The ledger has neither the predicate nor the preservation lemma. [DIRECT — the counterexample is
  in `truth_table.md` §3.2; the formalization is absent]

### Rank 6 — The negation-reduction theorems (minimal_gates' headline, unproved)

Prove `tsum x x = neg x` (`−x = x ⊕ x`), `tsum x x x = 0` (`3x = 0`), and `tprod x (−1) = neg x`
in Lean. `minimal_gates.md` TODO #4 flags this explicitly; TODO #5 adds the subtlety that
`x ⊕ x = −x` uses only `tadd1.sum` with the **carry dropped** — the positional adder `tadd1` keeps
`{cout, sum}`, and the field ⊕ is the sum projection. [OURS/DIRECT — the derivation is 3 lines;
the Lean theorem is missing]

### Rank 7 — Adjudicate the median/Sheffer contradiction (§2.3)

Settle whether any **3-ary Sheffer function** exists for radix 3 and whether the median is one
(it is not — see §2.3). This closes the live contradiction between `minimal_gates.md` TODO #9 and
`truth_table.md` §6. The clean answer: a Sheffer function at any arity must be non-monotone, so
the median cannot be one; the "consensus-plus" of the MVL literature is a different, non-regular
function and needs its own table + derivability note. [DIRECT for the median fact; the
"consensus-plus" table is unverified/uncited]

### Rank 8 — Minimality facts formalized (Martin 1954 + affine/monomial)

`minimal_gates.md` §3's four minimality facts are prose: (1) ⊗ not derivable from ⊕ (affine vs
quadratic), (2) ⊕ not derivable from ⊗ (monomials can't sum), (3) one nonzero constant required,
(4) **no 2-ary Sheffer function** (Martin 1954). Only (4) has a citation; none has a proof in the
ledger. Formalizing "no single binary operation is complete" requires a term/clone semantics the
ledger lacks. Lower priority than Ranks 1–6 because the set is already pinned by the field-pair
completeness + ⊕-irreducibility. [DIRECT for the facts (cited); the formalization is absent]

### Rank 9 — Cost-minimal vs gate-minimal library (needs energy, not just area)

Whether `{min, max, neg}` + pay-for-⊕-only-where-needed beats the field pair in *cost*, given ⊕
is the 4.33× cell. Blocked on: no ngspice joule/transition for ⊕/⊗ (`minimal_gates.md` TODO #2)
and `tmul` area is an *estimate* (`minimal_gates.md` TODO #3, `truth_table.md` TODO #9). This is
hardware-adjacent; it ranks below the pure-logic items but above the device floor on verdict
impact for the *logic slice*. [SPECULATION until measured]

### Rank 10 — The single-wire native-device floor

`minimal_gates.md` §4c / TODO #1 / TODO #8: the whole field-basis bet rests on ⊕ being *cheap* on
a single-wire native 3-state device (one 3-state threshold network), and that floor was unmeasured
at the time of writing. **Note:** `device_circuit.md` now exists in this directory — the "missing
sibling" caveat in `minimal_gates.md` is stale, and this item should be re-checked against it
rather than treated as open. [SPECULATION/ANALOGY — device story; out of this synthesis's scope]

### Rank 11 — Catalog the un-named balanced gates + name the swaps

Of the 1680 balanced binary functions, only ⊕, ⊖, ¬⊕ are named/used (`truth_table.md` TODO #4):
are any others cheap-and-useful (e.g. a balanced `eq`, a balanced "sign product minus zero")? And
the `swap` transpositions have no canonical literature name ("cyclic negation" / "half-negation"
both appear — `truth_table.md` TODO #8). Low verdict impact, but a completeness-of-catalog item.
[DIRECT for the counts; the "any others useful" is SPECULATION]

### Rank 12 — Łukasiewicz usefulness + NAND/NOR non-uniqueness

- `truth_table.md` TODO #6: the L₃ operators (`→ₗ`, `⊙`, `⊕ₗ`) are *translations*; whether the
  processor wants them at all (vs Kleene's) is untested against the opcode set. [SPECULATION]
- `truth_table.md` TODO #2: "NAND/NOR analogue" is not unique in radix 3 — the "field NAND" `¬⊗`
  vs the Kleene NAND `¬∧` are different functions; only the Kleene form is tabulated. [ANALOGY —
  naming; DIRECT — the tables]

---

## 4. The single open question — the fact that most moves the verdict

**The one logic-level fact:** *prove (by citation to the Rosenberg/Jablonskij maximal-clone
classification, not by per-gate invariants) that the clone generated by {min, max, neg, ⊕} is the
full clone of radix 3 — equivalently, that ⊕ is the unique single non-regular generator needed,
and that every 2-element complete binary basis must contain a cyclic (non-monotone) operation, of
which ⊕ is the canonical representative up to the S₃ relabeling.*

Formally, the theorem to prove/cite:

> (i) The regular fragment R = ⟨¬, min, max⟩ is exactly the Kleene clone, a *maximal* clone of the
> monotone family; and (ii) the only maximal clones that contain R are escaped by adjoining a
> single cyclic operation, so ⟨¬, min, max, ⊕⟩ = full clone, and **any** complete binary basis must
> include a non-monotone operation — ⊕ (mod-3 sum) being the unique such operation that is also
> balanced/Latin-square. [DIRECT-literature for the classification; the "up to S₃ relabeling"
> uniqueness is the thing to nail down]

**Why this one fact moves the verdict.** Every other logic claim in the three files — "minimal set
= {⊕, ⊗}", "negation is derived", "⊕ is irreducible", "K is incomplete", "⊕, ⊖, ¬⊕ are the
balanced ones" — is currently a *per-gate invariant argument* (truth_table) or an *assertion*
(minimal_gates). This single classification converts all of them into one cited theorem, and —
decisively — it **rules out a cheaper/nontrivial alternative basis hiding in an intermediate
clone**: if the maximal-clone check passes, there is no second operation *other than a cyclic one*
that could complete the regular fragment, so `{⊕, ⊗}` is not merely *a* minimal basis but *the*
minimal basis (up to the value relabel S₃). If the check were to *fail* (a non-cyclic second
operation completing R), the minimal-set claim would be wrong and the architecture's basis choice
would need redoing. That is what makes it verdict-moving.

**Honest calibration.** This is **open for this project, not open in mathematics.** The maximal
clones of a finite universe are a classical, classified object (Rosenberg 1970; Jablonskij's
18 pre-complete classes for k=3). What is missing is (a) a citation in our docs, (b) a Lean
statement of the maximal-clone test, and (c) the ⊕-uniqueness claim stated as a theorem rather
than an editorial reading. The **runner-up** most-verdict-moving fact is *hardware*, not logic:
the single-wire native-device cost of ⊕ (does the 4.33× penalty collapse?). It is deferred to
`device_circuit.md` and is out of this synthesis's logic scope, but it is the fact that decides
"balanced ternary is worth it" even after the logic basis is settled. [DIRECT for the existence of
the classification; SPECULATION for "this is the one that moves the verdict" — editorial]

---

## TODO / not covered / caveats

1. **This synthesis reads only three files.** The sibling ground-up files (`device_circuit.md`,
   `meta_critique.md`, `meta_assumptions.md`, `polar_gates.md`, `gate_energy.md`, `gates.md`,
   `gate_area.md`, and the six other `synth_*` / `test_suite_spec.md` files in this directory)
   are **not** folded in. In particular `device_circuit.md` now exists, so `minimal_gates.md`'s
   "missing sibling" caveats (TODO #1, §4c) are **stale** and Rank 10 should be re-checked
   against it, not treated as open. A next pass should diff `synth_logic.md` against the other
   five `synth_*` files for duplicate/contradictory overlap claims.
2. **The maximal-clone count "18" and the Yanov–Muchnik non-finite-basis result are literature
   facts I introduce here, not re-derived from the three files.** They are standard (Jablonskij
   1954; Rosenberg 1970; Yanov–Muchnik 1958) but must be **re-cited from the primary sources**
   before §3.1/§4 are quoted downstream. The exact cardinality of the radix-3 clone lattice is
   deliberately left vague ("not enumerable") rather than asserted as continuum.
3. **No truth table is re-invented here.** Every gate table, count (27 / 19 683 / 6 / 1680), and
   derivability cell is carried from the three files' own DIRECT-tagged content. If a cell is
   wrong upstream, it is wrong here; the synthesis does not re-verify entry-by-entry.
4. **§2.3's median-vs-Sheffer adjudication is first-principles reasoning, not a Lean proof.** It
   follows from the two files' own DIRECT facts (median ∈ K; K incomplete), but "the median is not
   a Sheffer function" is stated here as an inference, and should be promoted to a formal
   non-derivability/monotonicity-preservation proof (Rank 7) before it is cited as settled.
5. **"Balanced" is doing two jobs in this corpus** and the synthesis does not reconcile them: (a)
   the balanced *value set* {−1,0,+1} vs {0,1,2}, and (b) the balanced *output* property
   (uniform output counts). Only `truth_table.md` tracks (b); `minimal_gates.md` and `PolarGate.lean`
   use (a) only. A reader must not read "balanced gate" as "gate over the balanced value set" when
   a specific file means "balanced output."
6. **The S₃ relabeling in §4 ("up to S₃") is not yet checked exhaustively.** The six balanced
   unary permutations (identity, negation, cycle ±1, the two swaps) give six ways to relabel the
   trit; the claim that ⊕ is the *unique* balanced non-monotone binary primitive should be checked
   against all six relabelings (and the `rot1`/`rot2` naming in `PolarGate.lean` vs `cycle ±1` in
   `truth_table.md` should be confirmed to match, as the synthesis's §-level read assumed).
7. **The ranking in §3 is editorial.** The order is by the synthesis's own (verdict-impact ×
   unprovenness) criterion and is SPECULATION; the items themselves are tagged by their own
   calibration. Another synthesis could defensibly put Rank 10 (device floor) first if the
   criterion were "moves the architecture verdict" rather than "logic-level."
8. **No Lean build was run for this synthesis.** The claim "`PolarGate.lean` is `sorry`-free and
   `lake build`-green" is carried from the file's own header (`Status: PROVED … zero sorry`), not
   re-verified here. The gap list in §3.2 is a *read* of the theorem inventory, not a compile
   check.
