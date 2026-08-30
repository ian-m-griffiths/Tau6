# MAP BRIEF — the docs synthesis method (2026-08-28)

You are a survey agent processing academic papers (already extracted to `.txt`). For EACH
paper assigned to you, produce ONE markdown file that (A) maps the paper to a labeled
relation graph, then (B) maps it against the CURRENT SYSTEM (lens). This is the project's
own graph-survey method (map → lens, the "convergence diamond").

## The current system you're mapping against (read these FIRST)
- `STATE_NOTE.md` — project state: Eisenstein integers ℤ[ω] (ω=e^(iπ/3), N=a²+ab+b², Z₆),
  the gauge variants, the ternary cell (01=push/00=null/10=pull/11=never), the Lean proofs,
  Rust, Verilog.
- `GAUGE_VARIANTS.md` — the naming convention + "what the sums mean".
- For MEASURE THEORY papers also skim `LATTICE_MATH.md`; for TERNARY CIRCUITS papers also
  skim `TERNARY_PROCESSOR.md`.
- The Lean proof paths live under `proofs/lean-src/hexagon/Hexagon/` (see `proofs/INDEX.md`).

## Method A — map to graph (per paper, first)
Model the paper as a LABELED RELATION GRAPH, not a flat summary:
- Node types: CONCEPT | CLAIM | DEFINITION | METHOD | RESULT | ANALOGY | OPEN-QUESTION | MAPPING
- Edge types (directed): supports | contradicts (counter-to) | derives-from | analog-of |
  instance-of | maps-to | requires
- Calibration on every cross-domain ANALOGY/MAPPING edge: DIRECT | ANALOGY | OURS | SPECULATION
- Surface REVERSALS / counter-to edges in their own section.
- Distinguish CLAIMED vs PROVED vs SPECULATED.

## Method B — map to current system (lens, per paper, second)
For each key concept in the paper, calibrate it against OUR system:
- **DIRECT** = same math/object (e.g. a paper's Eisenstein norm = our `N=a²+ab+b²`).
- **ANALOGY** = parallel structure, different object.
- **OURS** = only in our system (no counterpart in the paper).
- **SPECULATION** = unproven on either side.
Give evidence + the paper's section and the Lean file where ours lives.

## Folder-specific lens
- **MEASURE THEORY** — the core question is **counts vs probabilities**: the counting
  measure (raw integer counts — our "absolute math") vs the probability measure
  (normalize to sum 1). Hunt for: counting measure, Dirac/point measure, Haar measure,
  translation invariance (= ISOTROPY, our Z₆), lattice valuations, Riesz representation,
  sum-to-1 normalization. Ian's thesis: *measure theory is how we got to Eisenstein
  integers — "gauge becomes a natural and cheap INTEGER thing."* Flag any paper that
  directly supports that.
- **TERNARY CIRCUITS** — the core question is how the paper connects to OUR ternary cell
  (one-hot-per-direction: 01=push, 00=null, 10=pull, 11=never; energy ≤1 line, null free,
  avg 2/3 vs binary 1). Hunt for: balanced ternary, symmetric ternary, ternary gate
  families, polarity reconfigurability, energy advantages, codes over Eisenstein integers,
  MVL verification, ternary logic synthesis. Flag what's DIRECTLY reusable in our RTL
  (`rtl/`) vs ANALOGY/SPECULATION.

## Output
Write each paper's graph to `docs/graphs/<measure-theory | ternary-circuits>/<clean>.md`
(use the paper's `clean` name from `docs/manifest.json`, spaces intact).
Structure each md:
```
# <paper title>
## 1. Node inventory (table: id | type | name | one-line | location)
## 2. Edge inventory (table: src→tgt | type | calibration | evidence)
## 3. Counter-to / reversal edges
## 4. Map-to-current-system (lens): table (paper concept | our system | DIRECT/ANALOGY/OURS/SPECULATION | evidence)
## 5. One-liner: "what this paper gives us"
```
Aim ~80–150 lines each; completeness over polish. Never invent a Lean theorem that isn't
in `proofs/INDEX.md` — if you're unsure, mark it ANALOGY/SPECULATION.
