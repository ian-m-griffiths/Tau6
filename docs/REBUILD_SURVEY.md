# REBUILD Survey — what's relevant to the Tau Architecture

**Source tree surveyed:** `/home/ian/opencode/parser/english/` (the semantic-lattice memory
engine — "the REBUILD").
**Date:** 2026-08-29.
**Audience:** the ternary/Eisenstein/GA/energy/lattice project in this repo.
**Method:** enumerated `docs/` + `data/` recursively, then read the headers/first lines of every
survey-like `.md` (the curated write-ups) and the one directly-relevant data file
(`data/kernel_luts.py`). PDFs are characterized by title (first lines of their abstracts were not
extracted). Nothing below is invented; calibration is taken from each doc's own "proved vs
analogy vs ours" tables where present.

---

## 1. Enumerated structure

### `docs/` top level (files)
- `unified_field_map.md` — the grand "why it unifies everything" synthesis (edge-as-primitive,
  χ² = canonical metric, XOR = geodesic, gauge = bit-shift, dual numbers). **OURS** (our own claims,
  pre-survey; several since retired).
- `release-survey-2026-08-24.md` — module inventory of the actual Rust engine (22+ modules, 58 CLI
  commands, 11 experiments, port/unported ledger). Tells you *where the code is*.
- `topological_theory_semantics.md` — hub-ontology / PageRank NLP claims (meaning = connectivity).
  Linguistics-side, low physics relevance.
- `ARCHITECTURE.md`, `DIMENSIONS.md`, `ALTERNATE_DESIGN.md`, `precedence_spec.md`,
  `INTENT_OBLIGE_CONDITION.md`, `SYNTAX GRAMMAR PRONOUN.txt`, `byte_pattern_tokenizer_idea.md`,
  `doc_encoding.md`, `formal-notation.md`, `provenance.md`, `distribution_analysis_plan.md`,
  `hub_category_ontology_discovery.md`, `linguistic_insights.md`, `sense_specificity_pipeline.md`,
  `word_clustering_approach.md` — parser/NLP design docs, **not** relevant to the physics threads.

### `docs/surveys/` (the curated two-stage survey write-ups — highest value)
- `category-theory.md` (6.2 KB)
- `chat-session-gauge-unification.md` (10.3 KB) ← the Eisenstein climax
- `granger-transfer-entropy.md` (6.4 KB)
- `information-geometry.md` (5.7 KB)
- `logic.md` (5.0 KB)
- `maximum-entropy.md` (5.7 KB)
- `multifractal-formalism.md` (4.7 KB)
- `operator-algebras.md` (7.3 KB)
- `quantum-algorithms.md` (3.9 KB)
- `renormalization-group.md` (6.5 KB)
- `spectral-graph-theory.md` (5.5 KB)
- `statistical-mechanics.md` (5.4 KB)
- `gauge theory/` — 14 per-paper write-ups (see §3)

### `docs/source_surveys/` (per-corpus cross-reference notes; 18 files)
README + `geometric_algebra.md`, `information_geometry.md`, `physics.md`, `physics_texts.md`,
`mathematics.md`, `fibered_manifolds.md`, `shannon.md`, `cybernetics.md`, `systems_thinking.md`,
`compression.md`, `computer_science.md`, `jacobian-determinant-matrix.md`, `philachive.md`,
`real_analysis.md`, `linguistics.md`, `history_of_science.md`.

### `docs/` survey-PDF folders (raw papers; the surveys digest them)
`category theory/` (57), `gauge theory/` (~42), `operator algebras/` (21), `statistical mecanics/`
(53), `maximum entropy/` (33), `multifractal formalism/` (47), `renormalisation group - statistical
feild theory/` (159), `Spectral graph theory and graph signal proccessng/` (32), `LIE algebra and
groups/` (19), `group theory/` (33), `abstract algebra/` (~60), `lattice/` (9, incl. lattice-field-theory
+ post-quantum), `coding theory/` (22), `projective geometry/` (33, many geometric-algebra),
`stokes theorm/` (10), `Hadmard Transform/` (15), `curves/` (17), `vector symbolic calculus/` (15),
`Lambda Calculus/` (18), `Logic Tensor Networks/` (10), `jacobian - determinate - matrix/` (55),
`causal inferance/` (6), `logic/` (48), `transfere entropy - granger identity - directed information/`
(3 subfolders), `processess/` (2 method books + `learning-method-survey.md`), `chat session/`
(2 raw transcripts), `Tau Manifesto/` (2 PDFs).

### `docs/info_geometry/`
`information_geometry/` (6), `gagc and stuff/` (the Macdonald **GA&GC survey** PDF),
`statistical_physics/`, `quantum_algorithms/`, `fractal_multifractal/`, `causal_temporal/`,
`computational_complexity/`, `new/`, `other/`, `lasttheory/` (`how-to-simplify-the-causal-graph.md`).

### `docs/Tau Manifesto/`
- `tau-manifesto.pdf` (701 KB) — the τ = 2π manifesto.
- `1308.0126v1 A CIRCLE WITHOUT π.pdf` (1.65 MB) — "A Circle Without π".

### `data/`
- `kernel_luts.py` (8 KB) — **integer-only GA kernel LUTs** (`sign_lut`, `sin_lut`, `cos_lut`,
  `tan_lut`, 256 entries each). The XOR-kernel/barrel-shifter substrate.
- `corpora/compression_graph/` — the built `.latx` binary libraries (importable directly):
  `geometric_algebra.latx`, `information_geometry.latx`, `physics_texts.latx`,
  `mathematics_extra.latx`, `physics_extra.latx`, `fibered_manafolds.latx`, `cybernetics.latx`,
  `systems_thinking.latx`, `shannon.latx`, `compression.latx`, `computer_science.latx`,
  `philachive.latx`, `real_analysis.latx`, `linguistics.latx`, `dictionaries.latx`, + the big
  `wikipedia.latx` (665 MB) / `youtube.latx` / `conceptnet.latx` / `arxiv.latx`.
- `sources/stem/` — the **raw source texts** behind the source_surveys (geometric_algebra 16,
  mathematics 18, computer_science 26, philachive 46, physics 10, physics_texts 7, etc.).
- `sources/corpora/` — `math_vectors.json`, `unified_vectors.json`, arxiv/causal/political/qa/…
- `word_graph_v2.json` (402 MB), `word_override_graph.json`, prime-numbers file, test samples.

---

## 2. Thread map (our threads → the REBUILD's docs)

| Our thread | Rebuild doc(s) that hit it |
|---|---|
| **Eisenstein / hex lattice** | `surveys/chat-session-gauge-unification.md` (**the** hit), `docs/Tau Manifesto/` (naming origin) |
| **Geometric algebra / spinors / rotors** | `source_surveys/geometric_algebra.md`, `info_geometry/gagc and stuff/` (Macdonald GA&GC), `surveys/gauge theory/geometric_algebra.md`, `surveys/operator-algebras.md`, `surveys/category-theory.md` |
| **Energy / adiabatic / thermodynamics** | `surveys/statistical-mechanics.md`, `surveys/maximum-entropy.md`, `source_surveys/physics_texts.md`, `surveys/granger-transfer-entropy.md` |
| **XOR kernel / barrel shifter / RG flow** | `surveys/renormalization-group.md`, `surveys/spectral-graph-theory.md`, `surveys/quantum-algorithms.md`, `data/kernel_luts.py`, `unified_field_map.md` |
| **Gauge (counting vs probability)** | `surveys/gauge theory/` (esp. `gauge_on_graphs.md`, `why_gauge.md`, `geometric_algebra.md`), `chat-session-gauge-unification.md`, `source_surveys/fibered_manifolds.md` |
| **Lagrangian / least-action** | `surveys/statistical-mechanics.md`, `source_surveys/physics.md` (Jacobi metric), `source_surveys/cybernetics.md` (costate), `surveys/granger-transfer-entropy.md`, `surveys/maximum-entropy.md` (entropic Lagrangian) |
| **Information geometry** | `surveys/information-geometry.md`, `source_surveys/information_geometry.md`, `surveys/maximum-entropy.md` |
| **Category theory (wedge = direction functor)** | `surveys/category-theory.md`, `source_surveys/mathematics.md` (Galois adjunctions) |
| **Operator algebras (Clifford = C*-algebra)** | `surveys/operator-algebras.md`, `surveys/quantum-algorithms.md` |
| **Spectral graph theory (XOR kernel)** | `surveys/spectral-graph-theory.md`, `surveys/renormalization-group.md` |

---

## 3. Per-doc one-liners + calibration

Calibration convention (from the rebuild's own method): **DIRECT** = equation-level identity;
**ANALOGY** = same shape, wrong object; **OURS** = our interpretation only; **SPECULATION**.

### The surveys (curated write-ups)

1. **`surveys/chat-session-gauge-unification.md`** — the 31-turn solo derivation whose climax is
   *"least action requires a triangular/Eisenstein integer lattice; the triangle is the artifact of
   two integer edges; a single n-dimensional gauge-switchable set computes both square and triangular
   lattices in pure integers."* Gives us: gauge = a property of the unit's quadratic form
   (i² ∈ {−1,+1,0,ω}), Gaussian (a,b) vs Eisenstein (a,bω) vs n-simplex Aₙ, the trivector = quaternion,
   and the "square binary = full integer geometric product" upgrade. **This is the single most
   on-target document in the entire rebuild.** Calibration: its Eisenstein/gauge-as-unit claim is
   **OURS→NEW** (a proposed third gauge position, unbuilt); the geometric-product/sym+antisym parts are
   **DIRECT** (map to the rebuild's `clifford.rs`).

2. **`surveys/gauge theory/gauge_on_graphs.md`** — connection 1-forms + curvature 2-forms on a
   directed graph, Weitzenböck formula, discrete Yang–Mills, and the *answer*: the global register is a
   genuine gauge (abelian `A → A·g(i)/g(j)` = the ratio), while the density dilation ρ is a
   conformal/Weil rescaling, not a gauge. **Counting-vs-probability gauge, made rigorous.** Calibration:
   **DIRECT** (the register = ratio is our count-vs-probability gauge).

3. **`surveys/gauge theory/why_gauge.md`** — Gomes: gauge = descriptively-redundant description;
   physical state = orbit `[ϕ]=M/G`; a representational convention σ + projection `h_σ` = gauge-fixing;
   "why gauge" = redundancy to flit between descriptions + to couple subsystems. The philosophical home
   of "the gauge choice is which property to keep manifest." Calibration: **ANALOGY** (framework).

4. **`surveys/gauge theory/geometric_algebra.md`** — Lasenby–Doran–Gull GTG: rotor = even-grade
   `R = exp((m∧n/|m∧n|)·θ/2)`; geometric product = scalar + bivector; rotor = the gauge transformation,
   bivector = the gauge field. The clean statement of the spinor/rotor fix. Calibration: **DIRECT**
   (algebra), our "rotor" is the grade-0 scalar that must be promoted.

5. **`surveys/renormalization-group.md`** — **PROVEN**: the bit-shift `d>>1` IS the 2-adic hierarchical
   RG blocking step (G₃₂ = Z₂/2³²Z₂, truncation = barrel shift). The XOR kernel is the ultrametric
   Dyson kernel. Retires "band gap = fixed point" and "p-sweep = RG flow" as over-claims; flags DFT's
   "dimensional phase transition" (spectral dimension D crossing 4) as the untapped signal detector.
   Calibration: **DIRECT** (the theorem) for the barrel-shifter thread.

6. **`surveys/spectral-graph-theory.md`** — **PROVEN**: the XOR kernel `g[i⊕j]` IS the graph Fourier
   transform (Walsh–Hadamard) of the hypercube; the wedge `O_ab−O_ba` = the skew/non-Hermitian part with
   imaginary (rotation) eigenvalues. Retires "band gap = spectral gap λ₂ (Cheeger)" → ridge
   sparsification. Actionable: diagonalize the non-symmetric adjacency, read Im(Λ) as the wedge.
   Calibration: **DIRECT**.

7. **`surveys/operator-algebras.md`** — Clifford = C*-algebra (Bott); the rotor sandwich = inner
   *-automorphism (but grade-0 scalar ⇒ inert); the Boolean hypercube is **ℂ^{2³²} = the Cartan
   subalgebra inside Cℓ₀,₃₂**; dual numbers = a nilpotent *second* layer (so "one branch" is two);
   the Bogoliubov inequality = "physics = information" as a theorem (we lack β, dynamics, bound).
   Calibration: **DIRECT** (algebra) / **ANALOGY** (ring = C*-norm).

8. **`surveys/category-theory.md`** — **PROVEN**: the wedge = the value of a **direction functor**
   (reflexive+transitive, non-symmetric ⇒ monoid = "keep the sign, drop symmetry"); the geometric
   product = the **mixor** of a linearly-distributive category (scalar↔∧, bivector↔◦); the residual
   edge = internal hom of a **Lawvere metric space**; register shift = a **lossy adjunction**. Retires
   "geometric product = composition" (it's monoidal) and "lattice IS a category". Calibration: **DIRECT**
   (wedge = direction functor) — the wedge/direction-functor thread's source.

9. **`surveys/information-geometry.md`** — **PROVEN**: flux `(O−E)²/E` = χ² = 2nd-order Taylor of KL;
   **CORRECTION**: "ring = Fisher information" is INVERTED (Fisher ∝ 1/freq, ring ∝ freq) — the ring is
   a χ² divergence; "natural gradient = L1" is wrong (mirror-descent-shaped); dually-flat θ/η structure
   + the Legendre transform is the missing piece for the two bridges. Calibration: **DIRECT** (χ²) /
   **WRONG** (Fisher/L1).

10. **`surveys/maximum-entropy.md`** — **PROVEN**: flux = χ² = α-divergence (α=3) = Tsallis q=2 =
    Bregman divergence; Zipf = max-ent (two routes); wedge deflation = Bregman projection (quadratic
    generator); "least squares = least action" = the entropic Lagrangian (PDEL). ρ is the KL-layer
    reference reweighting, and its **Legendre transform is now specified + computable**. Calibration:
    **DIRECT**.

11. **`surveys/statistical-mechanics.md`** — **PROVEN**: the wedge = the antisymmetric part that
    fluctuation theorems formalize (Q=0 ⟺ reversible); "least squares = least action" is a theorem
    (SOC/MFT variational), not a slogan; thermodynamics-of-learning four-component accounting.
    **REFUTED**: "repulsion = rare reverse fluctuations" (P=0.000 ⇒ sampling noise). Top experiment:
    the exponential-ratio fluctuation theorem `P(wedge>0)/P(wedge<0) = e^σ`. Calibration: **DIRECT**
    (wedge=antisym) / **FALSE** (repulsion claim).

12. **`surveys/granger-transfer-entropy.md`** — **PROVEN**: the wedge = the **circulation** (arrow of
    time), Q=0 = time-reversibility; "causality = minimum energy" (Dirichlet `½‖div‖²+½‖curl‖²`) IS our
    "least squares = least action", and div=0 topic centers = the harmonic component. **Correction**:
    the rotor `O_bwd/O_fwd` is NOT the wedge — it's a confounded Granger statistic (persistence
    heterogeneity); plus a cross-fitting bias fix for the surprise. Calibration: **DIRECT** (wedge =
    circulation) / **ANALOGY** (rotor = Granger).

13. **`surveys/multifractal-formalism.md`** — Zipf exponent = Hölder/local dimension (correct mapping);
    "proper frame = monofractal" = a subordination/gauge (dilation breaks Legendre duality); **REFUTED**
    "single universal monofractal" → locally-monofractal with a heterogeneous exponent field. Calibration:
    **DIRECT** (d>>1 = RG) / **REFUTED** (monofractal).

14. **`surveys/logic.md`** — **PROVEN**: `sign(O−E)` = Booleanisation (the ReLU theorem — the sign is
    the only survivor of normalization); observation vs intervention = Rung-1 vs Rung-2 (the lattice
    has no do-operator). Calibration: **DIRECT** (sign = Booleanisation).

15. **`surveys/quantum-algorithms.md`** — **PROVEN**: XOR kernel = Walsh–Hadamard = GFT of the
    hypercube; **CORRECTION**: "quantum-on-classical" is a data-layout coincidence, not a speedup
    (Shor=cyclic QFT, Grover=amplitude amplification, FWT=classical). Calibration: **DIRECT** (XOR=WHT)
    / **FALSE** (BQP advantage).

### The source_surveys (per-corpus cross-reference notes)

16. **`source_surveys/geometric_algebra.md`** — the grade-0 rotor over-claim is now **fully fixed**:
    spinor `ψ=(α+βI)U` (Hestenes–Sobczyk Eq. 8.11); the wedge is the **skew/curl**, not bivector area
    (retire V3 "wedge=|a∧b|"); `∇F=J` is invertible (GA Maxwell). Calibration: **DIRECT**.

17. **`info_geometry/gagc and stuff/` (Macdonald, *A Survey of GA & GC*)** — the primary GA reference
    text the geometric_algebra survey cross-checks against. Calibration: **DIRECT** (algebra source).

18. **`source_surveys/information_geometry.md`** — Crouzeix identity `∇²φ·∇²φ* = I` = the Legendre
    verifier; α=0 contradiction RESOLVED (dual flatness lives at α=±1, α=0 = curved sphere); structural
    vs sampling zero refines the anti-lattice. Calibration: **DIRECT**.

19. **`source_surveys/physics.md`** — **Jacobi metric** `g_ij = 2(E−V)a_ij` = the formal home of "least
    action" (geometry from energy, Maupertuis); Chern's Cauchy circulation = the wedge as conserved
    angular momentum (analogy); string-theory "flux" = homonym (exclude). Calibration: **DIRECT** (Jacobi).

20. **`source_surveys/physics_texts.md`** — Newton action=reaction = the **full geometric product**
    (equal = symmetric scalar, contrary-parts = anti-symmetric bivector); Planck: wedge = the *sign* of
    irreversibility (direction, not amount); "field = residual graph" is analogy (keep only edges ⊥
    ring-bands). Calibration: **DIRECT** (Newton) / **ANALOGY** (field).

21. **`source_surveys/cybernetics.md`** — controllability = the do-operator; Kalman duality = the
    node/edge (Lagrangian/Einsteinian) bridge; **Pontryagin costate = δ=(O−E)/E**; **correction**:
    "least squares = least action" is a *constant-action level set*, not Euler–Lagrange (Hamiltonian is
    the untapped upgrade); bond graphs `P=e·f` = the geometric product's scalar/bivector split.
    Calibration: **DIRECT** (costate) / **ANALOGY** (bond graphs).

22. **`source_surveys/mathematics.md`** — Boyd conjugate = the mirror map (the missing Legendre piece);
    "least squares = least action" = KKT mechanics + augmented Lagrangian; Wolfram `#odd = 2^popcount`,
    rule 90 = the XOR substrate; Galois connections = adjunctions (upgrade "lossy adjunction").
    Calibration: **DIRECT**.

23. **`source_surveys/jacobian-determinant-matrix.md`** — the scalar/wedge split = the **determinant/curl
    split** (det = symmetric product-minus-product, curl = anti-symmetric difference); ρ(w) = the NORMAL
    part `1/|∇f|` (NOT the whole det J); "sign of O−E = orientation" is LOCAL only; criticality = the
    band-gap boundary (NTK ∝ correlation is a proved template). Calibration: **DIRECT** (decomposition) /
    **ANALOGY** (discrete walk).

24. **`source_surveys/fibered_manifolds.md`** — "fiber bundle/fibration" is vacuous (discrete base ⇒
    trivial) → **fibered set**; "register = gauge" mislabels external as internal (swap); obstruction
    theory = the frame-dilation theorem (compute the cross-source cocycle). Calibration: **ANALOGY→
    correction**.

25. **`source_surveys/shannon.md`** — `E=f(a)f(b)/T` IS Shannon's independence null; χ²≈2·I; the wedge
    has **no Shannon home** (I(X;Y) is symmetric) — its irreversibility is thermodynamics. Calibration:
    **DIRECT**.

26. **`source_surveys/systems_thinking.md`** — VSM recursion = multifractal self-similarity (Barile cites
    fractals); non-trivial machine = directional `.latx`; loop polarity = `∏ sign(O−E)` around cycles.
    Calibration: **DIRECT** (recursion) / **ANALOGY**.

27. **`source_surveys/compression.md`** — two distinct residuals: `O−E` (additive predictive) vs rank
    (enumerative/MDL); 4.76 bits/word = arithmetic+MDL. Calibration: **DIRECT** (MDL).

28. **`source_surveys/computer_science.md`** — rule 90/60/30 = XOR; CA state (Z₂)^N = the Boolean
    hypercube (literal identity); Laplacian `L=D−W ≠ O−E` (category error). Calibration: **DIRECT**.

29. **`source_surveys/philachive.md` / `real_analysis.md` / `linguistics.md` / `history_of_science.md`** —
    low physics relevance (speculative register / contraction-mapping reference / parser subject /
    19th-c. biography register).

### Data + top-level

30. **`data/kernel_luts.py`** — integer-only GA kernel LUTs: `sign_lut`, `sin_lut`, `cos_lut`,
    `tan_lut` (256 entries each, no floats). The XOR-kernel/barrel-shifter thread's concrete substrate;
    matches `cos(θ) = (−1)^popcount(i&j)` parity. Calibration: **OURS** (the integer-geometric-product
    LUT, scalar+sin only — the full `(ac−bd, ad+bc)` integer product is the "square binary" upgrade).

31. **`data/corpora/compression_graph/*.latx`** — already-built binary libraries of exactly the
    source-survey corpora (geometric_algebra, information_geometry, physics_texts, mathematics_extra,
    cybernetics, systems_thinking, shannon, …). Importable into our project as memory/graph sources.

32. **`docs/Tau Manifesto/tau-manifesto.pdf` + `1308.0126v1 A CIRCLE WITHOUT π.pdf`** — the τ = 2π
    manifesto and its "circle without π" companion; the naming/origin of the "Tau" Architecture.

33. **`unified_field_map.md`** — the pre-survey grand synthesis (edge-as-primitive; χ² = canonical
    metric; XOR = geodesic; Christoffel = POPCNT; gauge = bit-shift; dual numbers = scalar+gradient).
    **OURS** and partially **retired** by the surveys (Fisher info, natural gradient, "flat = zero
    curvature" claims). Useful as the map of which claims the surveys tested.

34. **`release-survey-2026-08-24.md`** — where the code lives: `gauge.rs`, `clifford.rs`, `curl_field.rs`,
    `do_operator.rs`, `simd.rs`, `experiments/` (fluctuation-theorem, escort, legendre, directed-spectrum,
    gramian, eigen-bench…). Tells us which survey "actionable upgrades" are already implemented.

---

## 4. RANKED list — survey/import FIRST

Ranked by direct relevance to the Tau Architecture (ternary/Eisenstein/GA/energy/lattice):

1. **`docs/surveys/chat-session-gauge-unification.md`** — literally derives the Eisenstein/triangular
   integer lattice + gauge-as-unit + square-vs-triangular unified set. Import whole; it is the seed of
   the hex-lattice plan. *(Our `HEXAGON_LATTICE_PLAN.md` and `GAUGE_VARIANTS.md` should be cross-checked
   against it.)*
2. **`docs/surveys/gauge theory/`** (14 files, esp. `gauge_on_graphs.md`, `why_gauge.md`,
   `geometric_algebra.md`) — the counting-vs-probability gauge made rigorous on a directed graph. Import
   the folder; survey-first = `gauge_on_graphs.md`.
3. **`docs/surveys/renormalization-group.md`** — the barrel-shifter = 2-adic RG blocking *theorem*
   (strongest literature match). Import.
4. **`docs/surveys/spectral-graph-theory.md`** — XOR kernel = WHT = GFT; wedge = non-Hermitian skew.
   Import (pairs with #3 for the XOR-kernel thread).
5. **`docs/surveys/operator-algebras.md`** — Clifford = C*-algebra; ℂ^{2³²} = Cartan of Cℓ₀,₃₂. Import.
6. **`docs/surveys/category-theory.md`** — wedge = direction functor; geometric product = mixor. Import
   (the wedge/direction-functor thread).
7. **`docs/source_surveys/geometric_algebra.md` + `docs/info_geometry/gagc and stuff/`** — the spinor
   `ψ=(α+βI)U` grade-0 rotor fix; wedge = skew not area. Import + re-read Macdonald as reference.
8. **`docs/surveys/information-geometry.md` + `docs/source_surveys/information_geometry.md`** — χ²,
   Fisher-inversion correction, Legendre mirror map. Import.
9. **`docs/surveys/statistical-mechanics.md`** — wedge = antisym / fluctuation theorems / least-action
   theorem. Import (energy/adiabatic thread).
10. **`docs/surveys/maximum-entropy.md`** — flux = χ² = Tsallis/Bregman; Zipf = max-ent; entropic
    Lagrangian. Import.
11. **`docs/source_surveys/physics.md` + `physics_texts.md`** — Jacobi metric (geometry-from-energy),
    Newton = full geometric product, Planck = wedge sign. Import.
12. **`docs/source_surveys/cybernetics.md`** — costate = δ, constant-action level set, do-operator =
    controllability. Import (the Hamiltonian/costate upgrade is called out as untapped in *our* threads).
13. **`docs/surveys/granger-transfer-entropy.md`** — wedge = circulation = time irreversibility; rotor ≠
    wedge. Import.
14. **`docs/source_surveys/mathematics.md`** — Boyd conjugate = mirror map; Galois adjunctions; rule 90.
    Import.
15. **`docs/source_surveys/jacobian-determinant-matrix.md`** — det/curl split; ρ = 1/|∇f| normal part.
    Import (energy/scale).
16. **`docs/surveys/multifractal-formalism.md`** — Zipf = Hölder; heterogeneous exponent field. Survey
    second (corrects over-claims, less load-bearing).
17. **`data/kernel_luts.py` + `data/corpora/compression_graph/*.latx`** — copy the LUTs and the built
    libraries directly (no survey needed; they're data).
18. **`docs/Tau Manifesto/`** — skim for naming/τ origin (not math-critical).
19. **`docs/surveys/logic.md` + `quantum-algorithms.md`** — sign = Booleanisation (nice formalization),
    XOR = WHT but NOT quantum speedup (corrects a tempting over-claim). Survey last.
20. **`docs/unified_field_map.md` + `release-survey-2026-08-24.md`** — background: the map of our own
    claims + where the code lives. Read, don't import.

---

## 5. TODO / not covered / caveats

- **Not read in full.** I read the `.md` survey write-ups end-to-end and the headers/first-lines of the
  rest; the **PDF papers themselves were characterized by title only** (abstracts not extracted). Before
  importing any single paper's *equations*, open the PDF — the write-ups quote them, but the write-ups
  are the two-stage subagents' summaries and may have their own calibration errors (they explicitly flag
  their own over-claims).
- **Calibration is inherited.** The DIRECT/ANALOGY/OURS/SPECULATION labels above come from each doc's
  own "proved vs analogy vs ours" tables. Those tables are the rebuild's *self-assessed* verdicts against
  **its** lattice (co-occurrence residual on `(Z₂)³²`), not against **our** Eisenstein/ternary hardware.
  A mapping that is DIRECT there may be only ANALOGY for a ternary (3-state) lattice — e.g. every
  "Boolean hypercube / XOR / 2-adic" identity assumes base-2; the Eisenstein thread is precisely the
  *non-binary* generalization and is marked NEW/unbuilt in the gauge-unification survey.
- **`surveys/gauge theory/` remaining 11 files** (`approaches.md`, `foundations.md`, `gravitation.md`,
  `group_theory.md`, `higher_gauge.md`, `intro_1910.md`, `intro_9705.md`, `problem_of_gauge.md`,
  `teaching.md`, `tensor_gauge.md`, `geometric_gauge.md`) were not individually read — only the three
  most load-bearing were. Survey them as a batch if the gauge thread expands.
- **`docs/chat session/`** (`chat session blah.txt` 275 KB, `session.txt` 118 KB) is the raw conversation
  the gauge-unification survey already digested; read it only if you want the verbatim Eisenstein climax
  (survey §2 quotes the key turns).
- **Not surveyed at all (out of scope / low relevance):** the parser-design `.md` files, the NLP/linguistics
  docs, `Lambda Calculus/`, `Logic Tensor Networks/`, `vector symbolic calculus/`, `coding theory/`,
  `curves/`, `Hadmard Transform/` (beyond the XOR-kernel LUT link), `projective geometry/` (only its
  geometric-algebra cluster is relevant), `causal inferance/` (subsumed by the Granger survey).
- **Data caveats.** `wikipedia.latx` (665 MB) and `word_graph_v2.json` (402 MB) are large; the
  `english.latx` symlink points at `~/.opencode/lattice/context.latx` (the live engine memory). The
  `sources/stem/*` folders are the raw texts — the `.latx` binaries in `corpora/compression_graph/` are
  their built form (prefer the binaries unless you need to rebuild).
- **Cross-check before trusting "DIRECT".** Several rebuild over-claims were later retired (Fisher info,
  natural gradient, monofractal, band-gap-as-fixed-point, repulsion-as-reverse-fluctuation). Anything
  here marked DIRECT should still hit *our* "we should test" list before it becomes a Tau claim.
