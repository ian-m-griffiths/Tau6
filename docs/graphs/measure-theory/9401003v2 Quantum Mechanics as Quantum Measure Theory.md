# Quantum Mechanics as Quantum Measure Theory (Rafael D. Sorkin, 1994, arXiv:gr-qc/9401003v2)

Survey graph, MEASURE-THEORY lens. Calibration: DIRECT / ANALOGY / OURS / SPECULATION, at mapping time.

## 1. Node inventory (id | type | name | one-line | location)

| id | type | name | one-line | location |
|---|---|---|---|---|
| N1 | DEFINITION | quantum measure `\|A\|` | non-negative real set-function over sets of histories — the primitive of the paper | §"Quantum materialism and the quantum measure" (L116–119) |
| N2 | DEFINITION | interference term `I(A,B) = \|A⊔B\| − \|A\| − \|B\|` | deviation from classical additivity for a disjoint union | §"Quantum materialism…" (L127–134) |
| N3 | DEFINITION | sum-rule hierarchy `I_n` | inclusion–exclusion deviations; lemma: the nth sum-rule entails the (n+1)st — ever weaker rules | §"Quantum measure theory and its generalizations" (L167–199) |
| N4 | CLAIM | `I_2 = 0` ⇔ Kolmogorov measure theory | classical additivity = classical probabilities as set-measures | L189–195 |
| N5 | CLAIM | `I_3 = 0` ⇔ quantum measure theory | preserves most, not all, of classical additivity; QM a special case | L195–199, L214 |
| N6 | RESULT | `I_2` bi-additive ⇒ `\|X\| = I(X,X)/2` | the quantum measure is the DIAGONAL of a bi-additive bilinear set function (the decoherence functional) | L204–244 |
| N7 | RESULT | `I(x,y) = δ(x(T),y(T))·e^{−iS(x)}e^{iS(y)} + c.c.` | "probabilities = squares of amplitudes" is DERIVED from the sum-rule, not assumed | L266–294 |
| N8 | CLAIM | quantum probabilities ≠ ensemble frequencies | frequency interpretation unavailable for the quantum measure | L151–154, L304 |
| N9 | CONCEPT | preclusion / correlation-based objectivity | "realistic" interpretation: small-measure events are precluded; objectivity via correlation | L304–334 |
| N10 | OPEN-QUESTION | extra axioms (measure-zero sets); Markovian character; is truncation time T needed? | what distinguishes QM among solutions of (2) | L340–366 |
| N11 | MAPPING | three-slit null test | any failure of `I_3 = 0` is experimental evidence of beyond-QM dynamics | L379–389 |

## 2. Edge inventory (src→tgt | type | calibration | evidence)

| src→tgt | type | calibration | evidence |
|---|---|---|---|
| N3→N5 | derives-from | DIRECT (their lemma, proof cited elsewhere) | L185–199 |
| N3→N4 | derives-from | DIRECT | L189–195 |
| N5→N6 | derives-from | DIRECT (lemma ⇒ bi-additivity of I₂) | L217–228 |
| N6→N7 | derives-from | DIRECT (concrete I via action S) | L266–294 |
| N5→N8 | supports | CLAIMED (interpretive, not proved) | L151–154 |
| N8→N7 | contradicts (counter-to) | — | frequency reading of the derived probabilities rejected |
| N7→N2 | instance-of | DIRECT (two-slit as the basic case) | L120–134 |
| N5→N11 | requires | CLAIMED | L379–389 |
| N1→N2 | requires | DIRECT (I defined from \|·\|) | L129, L169 |

## 3. Counter-to / reversal edges

- **The quantum measure is neither a count nor a probability** — it is a third kind of object: real-valued, non-negative, defined by the *n=3* sum-rule and built from a bi-additive bilinear form. A naive "measure ⇒ generalizes probability" reading is reversed: Sorkin's hierarchy relaxes additivity, so classical probability is the *special* case, and frequency interpretation is *lost* at the quantum level (L151–154, N8).
- **`\|X\| = I(X,X)/2` — the measure is the DIAGONAL**: the bilinear object `I` is more fundamental than the measure, which is derived. (Parallel, not reversal, to our register ladder: our linear primitive `r` is stored and the quadratic `s = (O−E)²/E` is derived — same "linear primitive → quadratic readout" direction, different axioms.)
- **Sorkin explicitly disavows lattice theory**: his formalism is "more akin to measure theory than to (say) lattice theory or the theory of W\*-algebras" (L50–53). Term collision: his "lattice" = lattice of subsets of histories; our lattice = co-occurrence graph + Eisenstein-integer core. Do not map the two on the word "lattice."
- **`T` collision**: Sorkin's truncation time `T` (L277–285) ≠ our corpus total `T` in `E = f(a)f(b)/T` (LATTICE_MATH.md). Different objects, same letter.

## 4. Map-to-current-system (lens): paper concept | our system | calibration | evidence

| paper concept | our system | calibration | evidence |
|---|---|---|---|
| Kolmogorov additivity `I_2 = 0` (classical level) | our counting measure: counts `O` are additive, integer-valued; `Σ_b E(a,b) = f(a)` marginal identity | **DIRECT** (standard math; our side PROVED) | Sorkin L189–195; `Residual.lean` `sum_E_row` (INDEX R1) |
| "Measure is the primitive; probability is a special (normalized) case" (Abstract) | "counts not probabilities": count gauge `E = f(a)f(b)/T` vs probability gauge `p(a)p(b) = E/T` — a register shift by `T` | **ANALOGY** (same measure-first direction; his primitive is real-valued, ours is integer counts — the paper's *framing* supports us, its *objects* don't) | Sorkin Abstract L17–30; GAUGE_VARIANTS §B `[count]/[prob]` (recorded, no Lean file); LATTICE_MATH.md L9–10 |
| quantum measure `\|A\|` (bi-additive, real-valued, frequency-uninterpretable) | our signed residual `r = O−E` and the register ladder `r_raw/δ/z/s` | **ANALOGY** — parallel structure (a "measure-like" quadratic readout built from a linear primitive), different axioms; NOT our counts | Sorkin L116–119, L257–265; `Registers.lean` (INDEX R2) |
| `\|X\| = I(X,X)/2` — measure as diagonal of a bilinear form | `surprise s = (O−E)²/E = E·δ²` — χ² summand, sign-collapsed square | **ANALOGY** (same "diagonal of a bilinear object" shape; our side PROVED, his is a theorem of bi-additivity) | Sorkin L237–244; `Registers.lean` `surprise_eq_delta_sq_mul_E` (INDEX R2) |
| "probabilities = \|amplitudes\|²" *derived* from the n=3 sum-rule via `e^{−iS(x)}e^{iS(y)}` | `δ = O/E − 1`, `s = E·δ²` — square of the fold residual | **ANALOGY** — both "square the linear deviation," but his runs through complex action phases; ours through the classical χ² divergence | Sorkin L274–294; `Registers.lean` `δ_eq_residual_div` (INDEX R2) |
| frequency interpretation rejected for the quantum measure (N8) | our counts ARE frequencies over a corpus (ensemble/classical all the way) | **counter-to / OURS** — we stay at Sorkin's level-2; nothing in our system is frequency-uninterpretable | Sorkin L151–154; STATE_NOTE "counts not probabilities" |
| sum-rule hierarchy (n=2 ⇒ n=3 ⇒ …) | our register ladder (raw→δ→z→s) is a *scale* ladder, not a sum-rule hierarchy | **OURS** (don't force the parallel) | Sorkin L185–199; GAUGE_VARIANTS §C |
| three-slit null test (`I_3 ≠ 0` as new physics) | our band-gap / pruning noise-floor cutoff | **SPECULATION** (no mapping; do not claim) | Sorkin L379–389 |

**Honest calibration of the paper's core question.** Is Sorkin's "quantum measure" our "counts not probabilities"? **ANALOGY, not DIRECT.** Our claim lives entirely at Sorkin's classical level (n=2): the counting measure is the integer-valued additive primitive and the probability measure is its normalized register shift (an arithmetic identity on our side). Sorkin's quantum measure is a *third* object — real-valued, bi-additive, frequency-uninterpretable, with the squaring derived from a sum-rule on complex amplitudes. Claiming our lattice is "quantum measure theory" would be an over-claim (consistent with the project's canonical truth retiring the quantum-superposition claim). What the paper genuinely gives us is its *framing*: measure is primitive, probability is the special case — the same measure-first move as "counts not probabilities," and a named location (level n=2) for where our counting measure sits.

## 5. One-liner

Sorkin's sum-rule hierarchy pins our counting measure exactly at the classical (Kolmogorov, n=2) level and gives us a measure-first *framing* that supports "counts not probabilities" — but its quantum measure is an ANALOGY, not our counts: real-valued, bi-additive, frequency-uninterpretable, with "probabilities = squares of amplitudes" derived from a sum-rule, not from integer counts.
