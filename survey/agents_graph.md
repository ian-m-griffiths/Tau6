# AGENTS.md — Knowledge Graph (Map pass)

Source: `/home/ian/opencode/parser/english/AGENTS.md` (3,094 lines, ~192 KB, append-only project memory for the "lattice" semantic-language system).
Map-stage pass: DESCRIBE only (no critique). This graph models the file's own claims as typed nodes + typed directed edges; the file's own internal survey verdicts (CURRENT / RETIRED / REFUTED / SPECULATION) are mapped as content, not as my judgments.
Note on source fidelity: the workspace-instruction snapshot of AGENTS.md shown to me was an OLDER revision (mentions V2, 23 libs, JSON fallback, "Phase 4 rebuild … N17"). The actual file on disk is the v3-era revision (2026-08-22+). All line ranges below are against the ACTUAL 3,094-line file. Two hunt phrases from the task list — "Phase 4" and "integer register" — do NOT appear verbatim in the actual file; nearest matches are indexed in §4.5.

---

## 1. Node inventory (id | type | name | one-line definition | line range)

### A. Canonical truth / core math
| id | type | name | one-line definition | lines |
|---|---|---|---|---|
| N01 | DEFINITION | signed residual `r = O−E` | The stored primitive, per direction; NOT flux `(O−E)²/E`, NOT `O_ab`; `O = r + E`. | 13–15, 431 |
| N02 | DEFINITION | expected co-occurrence `E = f(a)f(b)/T` | Chance expectation in count gauge; `p(a)p(b) = E/T` is the same object in probability gauge. | 13–15, 824, 2877–2878 |
| N03 | CONCEPT | three-axis taxonomy | Exactly three axes: correlation/surprise (scalar), wedge (bivector), polarization (radial). | 16–18, 1609–1635 |
| N04 | CLAIM | `surprise ≡ correlation²` | Surprise and correlation are ONE axis; the split is sign vs magnitude, not correlation vs surprise. | 1630–1635, 1758–1762 |
| N05 | DEFINITION | wedge `O_ab − O_ba` | The SKEW part / curl / temporal precedence; NOT bivector area, NOT a causal arrow. | 17–18, 990, 2678–2680 |
| N06 | DEFINITION | polarization `f(a)/f(b) − f(b)/f(a)` | Radial-scale axis; also `f(a)/f(b)` ratio form = `\|a\|/\|b\|`. | 18, 1623, 1755 |
| N07 | DEFINITION | ring = χ² divergence value = L2 norm | `ring² = Σ(O−E)²/E`; a scalar χ² value, NOT Fisher information (a matrix ∝ 1/frequency). | 19–20, 800, 2305–2309 |
| N08 | CLAIM | action is a constant level set | Coherent speech keeps `∫L` constant; it does NOT minimize it; constrained Hamiltonian/costate = untapped upgrade. | 21–23, 656, 2655–2659 |
| N09 | CLAIM | `T = ring/2` (not `ring²/2`) | Replacing the quadratic kinetic term with the linear one balances T vs V. | 23, 658–666 |
| N10 | CLAIM | "surprise" = anti-correlation | Surprise means repulsion (`O < E`); the χ² magnitude is ORDER, not surprise. Keep the sign, `abs()` later. | 24–25, 1878–1894 |
| N11 | CLAIM | wedge ≠ rotor | Wedge = clean irreversibility; rotor `exp(r_bwd−r_fwd)` is grade-0 scalar (inert) and a confounded Granger statistic. | 26–29, 2236–2243 |
| N12 | DEFINITION | spinor / even-grade fix | Combined object `\|a\|\|b\|(cos θ + I sin θ)`; upgrade to genuine even-grade spinor `ψ = (α + βI)U`. | 27–29, 2146–2147, 2863–2867 |
| N13 | CLAIM | fiber bundle = fibered SET | Base (ring bands = integers) discrete ⇒ every bundle trivial; correct object is a bare surjection. | 30, 2684–2691 |
| N14 | CLAIM | causality is Rung-1 association | Sign/wedge is an orientation signal, never a causal arrow; "causation vs gravity" collapses to polarization. | 31–32, 2179–2191 |
| N15 | CLAIM | "attractor" = two opposite zeros | Feedback equilibrium `O→E` (noise) vs topic center `div=0` (max structure); keep them distinct. | 33–34, 2661–2663 |
| N16 | CLAIM | band gap = ridge/noise-floor cutoff | Not a fixed point, not the spectral gap λ₂; band-gap pruning = ridge sparsification. | 35, 2380–2383 |
| N17 | CLAIM | multifractality = local mono + heterogeneous field | Locally monofractal with heterogeneous exponent field h(x); not a single universal monofractal. | 36–37, 2561–2566 |
| N18 | CLAIM | edge residual is NOT a metric | Signed, asymmetric, `d(a,a)≠0`, triangle inequality fails; `ring = ‖v‖` IS a norm. | 38, 2665–2669 |
| N19 | CLAIM | "natural gradient = L1" is wrong | `G⁻¹∇L` is contravariant vector; L1 is a scalar; mirror-descent-shaped at best. | 39–40, 2311–2314 |
| N20 | CLAIM | "least squares = least action" as rate function | Quadratic large-deviation rate function; NOT free-energy minimization, NOT Euler–Lagrange. | 41–42, 2082–2088, 2442–2445 |
| N21 | DEFINITION | fold `δ = (O−E)/E = O/E − 1` | The invariant core; four registers = δ scaled by powers of E (raw `E·δ`, fold `δ`, z `√E·δ`, surprise `E·δ²`). | 1842–1860, 2855–2861, 3034–3050 |
| N22 | CONCEPT | two bridges (relational + symmetry) | Bridge 1: which E (global vs rest-frame clock); Bridge 2: whether the sign survives (correlation vs surprise). | 1801–1838 |
| N23 | CLAIM | exponent correspondence | In log space `×≡+`, `÷≡−`; a gauge is an addition; bit-shift `d>>1` = fixed-angle rotation. | 1903–1913, 2848 |
| N24 | CONCEPT | one-branch collapse | Everything is area-normalised trigonometry: `a·b = \|a\|\|b\|(cos θ + I sin θ)`; statistics/trig/complex/physics/log/algebra are one product. | 1920–1961 |
| N25 | CLAIM | correlation × surprise = geometric product | `a·b = cos θ` (attract), `a∧b = sin θ` (repel), surprise = total energy cos²+sin². | 1588–1607, 1922–1936 |
| N26 | CLAIM | statistics taxonomy: 3 orthogonal axes | surprise/corr (scalar), wedge (curl, fully independent), polarization (scale); surprise ≡ correlation² exactly. | 1609–1635 |
| N27 | CLAIM | O−E sign = primitive density signal | Two signs: sign of O−E (density: attract/repel) and sign of wedge (temporal); sign survives all normalization. | 1637–1653 |
| N28 | RESULT | raw signed O−E = best reproducibility statistic | Held-out 1.000/1.000/0.992, matches multifractal residue; beats Pearson 0.52 and diff_sq 0.60. | 1655–1678 |
| N29 | CLAIM | O and E are the normalization | Pearson √E / density ρ are a SECOND normalization only for cross-band comparability (topic discovery, not prediction). | 1680–1696 |
| N30 | CLAIM | node/edge bridge = quantum/relativistic unification | Raw O−E (edge, discrete) ≡ multifractal residue (node, continuous); one object, two projections. | 1698–1713 |

### B. Storage / stack / architecture
| id | type | name | one-line definition | lines |
|---|---|---|---|---|
| N31 | CLAIM | `.latx` v3 binary = source of truth | JSON `.lattice`/`.alattice` support REMOVED (2026-08-22); plugin is `.latx`-only; manifest reports live state. | 10–12, 429, 787, 982 |
| N32 | CLAIM | `build_causal` canonical; `build_flat` deprecated | `lattice-cli build` = causal DAG (bytes→subwords→words→compounds, signed directional O−E); flat builder exiled to `rust/lattice-legacy/`. | 43–48, 181–187, 1781–1799 |
| N33 | METHOD | surprise register `r²/E` + mean-threshold | Recall/consult ranking: square + mean-threshold + rank; NO stop list; display-side of the signed-primitive rule. | 46, 2064–2080 |
| N34 | CONCEPT | Rust CLI `lattice-cli` | Engine for build/down/consolidate/lookup/sense/join/consult/stats/topic-map/manifest/edge-stats/curl-field. | 56–71, 189–213, 448–458 |
| N35 | CONCEPT | Semantic ISA opcodes | LKP/SNS/JON/FMT/XOR/DEC/PSH/MGE/PRN/QRY/BLD/KRN; the lattice IS a processor. | 1188–1230 |
| N36 | CONCEPT | register map (A/B/X/R/F) | Accumulator/Base/Index/Ring/Flags; "the prompt IS the register state". | 1209–1214 |
| N37 | CONCEPT | XOR kernel `g[i⊕j]` on hypercube (Z₂)³² | XOR = index arithmetic; kernel = stored value; translation-invariant = index depends only on i^j. | 900–906, 1102–1113 |
| N38 | CONCEPT | barrel shifter `d >> 1` = ring shift | Bit-shift changes ring band (scale); RG-zoom in/out; replaces transcendental functions. | 555–558, 905–906, 1911–1912 |
| N39 | CONCEPT | inverse-mult integer arithmetic | No division/sqrt/float: `inv = ⌊2^(2P)/x⌋`, shift-only query ops; integer chi-squared. | 940–948, 1137–1161 |
| N40 | CLAIM | lattice = normalized lookup table | LUT at every granularity (word adjacency / PCA (deprecated) / XOR convolution); every tier pre-computed. | 1094–1113 |
| N41 | METHOD | breadth-first → depth-first divide & conquer | BFS cluster then DFS within cluster; join opcode stitches; apply above ~500 items. | 1232–1255 |
| N42 | CONCEPT | memory plugin + compaction pipeline | `lattice-memory.ts`; conversation.log → down → temp .latx → consolidate → main .latx → prune. | 1257–1295 |
| N43 | RESULT | dsh bundle integration | DeepSeek Harness bundle registers 9 native tools wrapping lattice-cli (pure Node, no MCP). | 1297–1330 |
| N44 | RESULT | 11 active build_causal libs | compression, cybernetics, dictionaries, geometric_algebra, german_english, mathematics_extra, philachive, physics_extra, physics_texts, shannon, systems_thinking; flat/political/JSON quarantined. | 433, 470–478 |

### C. Empirical notes (2026-08-08/09)
| id | type | name | one-line definition | lines |
|---|---|---|---|---|
| N45 | RESULT | six coordinate-system tests | Ring bands, concentration×ring, curl, antipode, wedge coherence, energy metrics, eigenvector-ring fibration. | 513–523 |
| N46 | CONCEPT | field-theory correspondence table | kinetic=ring², potential=log f, force=O−E, angular momentum=wedge, spin=rotor, curl, antipode, fiber bundle, Hodge dual=anti-lattice. | 525–537 |
| N47 | CLAIM | wedge IS the anti-symmetric derivative | No extra normalization; div=0 = topic center (sovereignty ring=37.8); second-order pairs = semantic channels. | 539–547 |
| N48 | CLAIM | multifractal GA + rotor descent | Ring = Hölder exponent (later corrected); `d = i^j` = bivector generator; `G[d] = cos θ`; fractal descent = argmin(G[d]). | 549–564 |
| N49 | CLAIM | Zipf's law as the band gap | `f ∝ 1/r^α`; squaring doubles log slope; f² noise-floor cutoff = integer limit of u32 space. | 566–568 |
| N50 | CLAIM | never use stop-word filters | `O−E` downweights high-freq words; band gap + ring stratification auto-separate; hardcoded lists wrong. | 570 |
| N51 | CLAIM | multi-level topic modeling via ring shifts | Binary exponent IS the ring band; shifting bits changes scale/resolution; children learn by counting. | 572–579 |
| N52 | CLAIM | eigenbasis as domain separator / opinion field | Eigenbasis partitions knowledge domains without labels; each source occupies orthogonal dimensions. | 583, 668–675 |
| N53 | CLAIM | harmonic ontology | Word meaning = ring_band × eigenvector_angle × cross_band_energy; auto-discovered ontology. | 585–587 |
| N54 | CONCEPT | anti-lattice | Stores what a source's discourse OMITS; analytical filter for what a source leaves unsaid. | 589, 1606–1607 |
| N55 | METHOD | Lagrangian speech generation | L = T − V; ∇L = force; argmin/argmax walk; curl≈0 termination; edge density = gravity. | 591–603 |
| N56 | CONCEPT | causation vs gravity | P(B|A)=O/f_a (production) vs P(A|B)=O/f_b (attraction); gravity selects semantic bridges. | 612–616 |
| N57 | RESULT | constant action confirmed | Coherent + hybrid sentences L2 ≈ 3200–3500/word; random walks ≈ 71; speech MAINTAINS energy level. | 656 |
| N58 | RESULT | ring/2 simplification | `L1 = ring/2 + log(f/T)`; function words (30–80) and content words (−10..+10) same range. | 658–666 |
| N59 | RESULT | Lagrangian as nonsense filter | L1 partitions vocab: noise < −10, working vocab [0,30), scaffolding [30,100); no thresholds needed. | 684–692 |
| N60 | RESULT | Hessian × eigenbasis duality | Cosine kernel (discourse, corr +0.06–0.27) vs Hessian kernel 1/(1+Δring²) (ring strata, −0.87..+0.69); Hessian eigenvectors = ring shells. | 696–711 |
| N61 | RESULT | frame distribution as comparative register | Ring-band distribution = cognitive frame; Zipf exponent characterizes register; three-axis unified coordinate system. | 719–731 |
| N62 | CLAIM | multifractal fibration | Nested fiber bundle: base ring, fiber eigenaxis, voice = consistent fibration; sub-donuts on different planes. | 733–739 |
| N63 | CLAIM | 3D sphere / donut geometry | Ring = Z-coordinate on high-dim sphere; antipodes = opposed words; donuts = sphere∩eigenbasis plane. | 741 |
| N64 | METHOD | ring harmonic ranking (p-sweep) | RG flow on flux threshold E_p = p·fa·fb/T at p=1,2,4,8; persistence across p = relevance. | 743–748 |
| N65 | RESULT | generator comparison (5 tests) | Only `lattice_gen.py --measured` produces grammatical English; Lagrangian-only generators make word salad. | 750–758 |
| N66 | METHOD | hybrid generator | Measured bigrams (grammar) × ring_gravity O/(ring_a·ring_b) (topic) × .latx anchors; no two-mode switching. | 760–785 |
| N67 | OPEN-QUESTION | "coherent nonsense" limitation | Bigram chain real but not semantically coherent ("get rid of the country" = delete Australia); mutual-prediction gating needed. | 777 |
| N68 | METHOD | wedge fix (anti-symmetry direction) | Replace symmetric mutual prediction with `wedge = r(anchor→cand) − r(cand→anchor)`; fixes "immigration high"→"immigration policy" (+14). | 779 |
| N69 | RESULT | .latx lookup = content-only neighbors | Function words already filtered by band gap; JSON .lattice returned function words first (removed). | 787 |

### D. Relativity / quantum / frame physics
| id | type | name | one-line definition | lines |
|---|---|---|---|---|
| N70 | RESULT | relativistic invariant `c = L1/λ` | Register-local: spoken 14.3–16.0, academic 25.6, encyclopedia 11.2; CV 0.28 vs 0.60/0.49 for parts. | 811–843 |
| N71 | RESULT | frame dilation | speaker_a proper 14.34 → stem frame 75.92 (5.3×) → wikipedia 3.27 (0.23×); frame mismatch IS dilation. | 845–859 |
| N72 | CONCEPT | Lagrangian vs Einsteinian frames | Lagrangian normalizes frame (absolute L1); Einsteinian is local per-word frame; lattice-lookup = Doppler shift. | 861–876 |
| N73 | CLAIM | lattice IS quantum (structural isomorphism) | Full quantum-property table on Boolean hypercube (Z₂)³²; XOR kernel = WHT domain. | 880–906 |
| N74 | CLAIM | measurement as search | Query vector = measurement operator; flux O−E = interference pattern; can't observe without interfering. | 908–914 |
| N75 | RESULT | temporal fix (2026-08-10) | Alphabetical edge-key sort destroyed non-commutativity (wedge=0); restoring temporal order returns curl + bivector. | 923–928 |
| N76 | RESULT | multifractality = monofractal + time dilation | Local Hölder ramp 0.04→1.68 collapses to α≈0.5 plateau under density-dilated RG axis; subordination. | 1339–1356 |
| N77 | RESULT | proper-frame residue validated | Split-half: raw 0.520/0.510/0.450 vs proper 1.000/1.000/0.798; frame correction is predictive on held-out. | 1360–1384 |
| N78 | CLAIM | Zipf–rotor–multifractal chain | Zipf line f∝r^(−α); rotor = exp(r_bwd−r_fwd) = motion along line; barrel shift = constant-angle rotation; relativistic fix recovers line. | 1386–1403 |
| N79 | METHOD | proper residue as importance score | Per-edge reproducibility score; comparable only WITHIN a ring band; filter to content/bridge bands for topics. | 1405–1415 |
| N80 | MAPPING | gauge = register = ring shift | One operation three names; t-1..t2 gauge plateau (invariance), t3 singularity (noise band empties). | 1417–1425 |
| N81 | RESULT | edge vs node normalization | Edge-flux-cohort normalization circular (P@50 0.56); node-band wins (1.0); frame must come from outside the measurement. | 1427–1435 |
| N82 | RESULT | mechanics stack as normalization choice | Raw flux 0.52 / Lagrangian 0.56 / Einsteinian 1.00 P@50; the three differ ONLY in the frame. | 1437–1451 |
| N83 | RESULT | gauge symmetry only in local frame | Lagrangian sweep degrades 0.58→0.00 monotonically; Einsteinian register sweep has invariant plateau t-1..t2. | 1453–1463 |
| N84 | RESULT | Lagrangian gauge limit: saturation at 0.60 | Extended sweep to p=0.001 never reaches 1.000; relativity is new information, not a limit of the Lagrangian. | 1465–1473 |
| N85 | RESULT | edge-level Einsteinian fails | Edge-level proper normalizations collapse (0.0–0.24); rest frames are CATEGORICAL (band), not continuous ring. | 1475–1487 |
| N86 | RESULT | rest frames = topical structure | Node-band frames = topic categories from band gap; topology/topicality/time-dilation are one object. | 1489–1504 |
| N87 | SPECULATION | multi-project memories → frame dilation as distance | Per-project .latx = own rest frame; cross-project distance = frame dilation (Eisenstein/Einstein frame pun). Untested. | 1506–1518 |
| N88 | RESULT | relativistic multifractal residue | Continuous tail-CDF ρ: P@50 1.000, P@500 0.992 (vs categorical 0.798); frame is continuous, not quantized. | 1520–1537 |
| N89 | CLAIM | precision as physical certainty | P@500 = 0.992 held-out ⇒ "structure is geometric, not statistical; language has a metric". | 1539–1550 |
| N90 | RESULT | lossless reconstruction via residual surprise | Store rank of true next word, not the word; 4.76 bits/word vs 13.12 uniform = 2.75×; layers compound. | 1552–1568 |
| N91 | CONCEPT | co-occurrence scale = frame | sentence(w≈6)/paragraph(w≈100)/section(w≈1000)/document(∞); only sentence scale built; surprise vs correlation swaps. | 1570–1586 |
| N92 | ANALOGY | Mandelbrot/Julia duality = frame/structure duality | c = frame/register/gauge; z = word; z²+c = flux walk; Julia = topic in fixed frame; Mandelbrot = space of frames. | 1715–1739 |
| N93 | RESULT | directional renormalisation (format) | .latx now stores {O_ab, O_ba, f(w), T}; wedge was zero by construction in old format; `cat↔chases` wedge +55.7. | 1741–1779 |
| N94 | CONCEPT | polar spinor | angle = O_ab/O_ba (ratio/direction), magnitude = O_ab−O_ba (difference/strength); one vector off stored primitives. | 458, 2909–2929 |

### E. Surveys (2026-08-15 → 08-18)
| id | type | name | one-line definition | lines |
|---|---|---|---|---|
| N95 | RESULT | GA&GC survey (Macdonald) | Proved equation-for-equation table; still-ours list; THREE analogies to stop over-claiming (ring shift≠translator, rotor grade-0, sinθ assignment); gifts: even-grade spinor, directed-integral local frame, conformal model, Thomas rotation. | 2090–2153 |
| N96 | RESULT | causal-inference survey | Proved: sym/skew/diag matrix split; over-claims to STOP: wedge≠causal arrow, causation-vs-gravity within Rung 1, causality-as-suggestion honest; upgrades: invariance test, stratification, mediation, rotor null, identify-before-estimate. | 2155–2223 |
| N97 | RESULT | Granger/TE/DI survey | Wedge = circulation with reversal null; rotor ≠ wedge (confounded Granger); least squares = least action proven (Dirichlet energy); BUG: cross-fitting bias in surprise injection. | 2225–2255 |
| N98 | RESULT | operator-algebra survey | Rotor = inner *-automorphism but grade-0 inert; "one branch" = ringed space (semisimple + nilpotent); quantum-on-classical = real algebraic claim; anti-lattice → commutant; Takesaki; Bogoliubov = physics=information. | 2257–2293 |
| N99 | RESULT | info-geometry survey | flux = χ² = 2nd-order Taylor of KL (proven); ring ≠ Fisher (inverted); natural gradient ≠ L1; dually-flat θ/η; Legendre transform of ρ = missing piece. | 2295–2324 |
| N100 | RESULT | RG / SFT survey | bit-shift = 2-adic RG (PROVEN); p-sweep is persistence diagnostic not flow; ρ = density not running coupling; band gap ≠ fixed point; monotone RG unproven; DFT phase-transition gift. | 2326–2359 |
| N101 | RESULT | spectral-graph survey | XOR = GFT of hypercube (proven); wedge = non-Hermitian content; band gap = ridge (not Cheeger); upgrade: directed complex spectrum. | 2361–2393 |
| N102 | RESULT | max-ent / Tsallis / Bregman survey | flux = α-divergence α=3 = Tsallis q=2 = Bregman; edge weight is the α-layer BELOW KL; Zipf is max-ent; ρ is NOT a Bregman projection (reference-measure reweighting); escort analogy with sign note; Legendre of ρ specified. | 2395–2431 |
| N103 | RESULT | statistical-mechanics survey | Wedge = antisymmetric part + fluctuation theorems; least squares = least action as rate function; physics=information = four-component accounting (memorization ≠ value); repulsion refuted as noise (P=0.000); exp-ratio FT experiment. | 2433–2459 |
| N104 | RESULT | category-theory survey | Wedge = direction functor (proven); geometric product = mixor; residual edge = internal hom of Lawvere metric space; RETIRE geometric-product=composition / lattice IS a category / Rosetta Stone; Yoneda insight; promote wedge to functor-valued. | 2461–2494 |
| N105 | RESULT | logic survey | sign = Booleanisation (proven); observation ≠ intervention (no do-operator); description-vs-value = signed residual vs collapsed surprise; do-operator = biggest gap. | 2496–2524 |
| N106 | RESULT | quantum-algorithms survey | XOR = WHT (proven); quantum-on-classical = data-layout coincidence (no Shor/Grover, FWT classical); ℂ^{2³²} = Cartan subalgebra of Cℓ₀,₃₂; quantum structure present but inert; no BQP advantage. | 2526–2547 |
| N107 | RESULT | multifractal-formalism survey | Zipf exponent = Hölder/local dimension (not ring); proper frame = monofractal is a gauge (proven); SINGLE monofractal REFUTED → locally monofractal heterogeneous field; ρ = survival function not D(h); Legendre steps. | 2549–2578 |
| N108 | RESULT | source-surveys disposition (15 folders) | build/reference/foil per folder; philachive = FOIL; fibered_manifolds forces fiber-bundle downgrade; geometric_algebra = grade-0 fix shelf. | 2580–2604 |
| N109 | RESULT | new direct identities | E = Shannon independence null; Shannon-1953 lattice = name-ancestor only; Shannon=correlation vs thermo=wedge; Newton = full geometric product; Jacobi metric = least action; Chern = wedge conserved; controllability = do-operator; Rule 90 = XOR; Boyd conjugate = mirror map; α=0 resolved. | 2606–2651 |
| N110 | RESULT | source-survey corrections (retire over-claims) | 10 corrections: E–L/level-set; attractor two zeros; edge residual not metric; Banach shape-only; wedge = skew part (retire V3); fiber bundle vacuous; field = analogy; string "flux" homonym; L = D−W ≠ O−E; bitmask = flattened HPSG sign. | 2653–2711 |
| N111 | RESULT | upgrade paths | Crouzeix ∇²φ·∇²φ*=I test; controllability Gramian = do-operator; loop polarity ∏ sign(O−E); MDL framing (4.76 bits); philachive caution (self-citation inflates flux; EmDrive numerology). | 2713–2727 |
| N112 | RESULT | Jacobian/determinant/matrix synthesis | scalar/wedge split = det/curl split; contraction constant λ = ‖J⁻¹‖·mod(J); det J = ∏λᵢ; Helmholtz = scalar+bivector; sign of det = orientation = sign of O−E; test on flux-walk Jacobian. | 2729–2751 |
| N113 | RESULT | Jacobian paper-corpus corrections | det≠0 ⟹ invertible is FALSE (local only, escape-to-infinity); det J = tangential × normal (ρ = normal part); det≠0 ⟹ convergent FALSE (Markus-Yamabe dim≥14); criticality = band-gap boundary; RG non-uniqueness (wedge forces it); determinant = binary oracle. | 2753–2781 |
| N114 | RESULT | chat-session survey 1 (8 tips vetted) | Curvature routing = the ONE new adoptable idea; "1D hole" = missing conjecture (analogy); MNN pruning = TRAP (would zero the wedge); systematic-vs-random re-derives gauge invariance but "spectral gap = right math" clause WRONG; analogy vs duality = signed residual. | 2783–2819 |
| N115 | RESULT | chat-session survey 2 — "gauge = the unit" | Gaussian integers ("square binary") → Eisenstein triangles → n-dim triangle (simplex Aₙ); gauge indistinguishable from the unit (third gauge position); lands as gauge-int experiment + Signature axis. | 2821–2844 |
| N116 | CLAIM | gauge-variant system + spinor (v5 notes) | This is a gauge-variant system; invariant core = fold δ; count↔probability gauge global; ρ = non-uniform part; spinor = combined object of the three operators. | 2846–2867 |
| N117 | CLAIM | geometric mutual probability = the spinor | ψ_ab = E + I·w = |ψ|(cos θ + I sin θ); area (E, symmetric) + divide (w/E = tan θ, antisymmetric); counting→curve→dimension chain; polar form = (ratio, difference). | 2869–2929 |
| N118 | CLAIM | gauge ladder | pow1 +/−, pow2 ×/÷, pow3 a^b; gauge-shifting down the ladder shrinks big-O; "little-o" = gauge rung; gauge GA preserves symmetric/antisymmetric split, δ invariant. | 2931–2957 |
| N119 | CLAIM | gauge = dimensionality; Euler between gauges | Gauge rung = dimension of the sum; big-O exponent = Hölder/Zipf slope α; e and γ are the corrections between gauges; trig gauge e^(iθ) breaks at θ=π/2 (pure-wedge singularity). | 2959–2983 |
| N120 | CLAIM | e^(1/e) normalization + SIMD gauges | e^(1/e)≈1.4447 = max of x^(1/x), power-tower convergence boundary; SIMD/byte-sliced fixed-point per-lane gauges; VGAUGE_ADD future instruction. | 2985–3012 |
| N121 | CLAIM | O(t·n) per pass + provenance | Per-pass time = Σ rung-cost × count; gauge/geometric/big-O = reinterpretation of Weyl, Clifford, Amari, Barral–Seuret, von Neumann, Kadanoff–Wilson; "shoulders of giants". | 3014–3030 |
| N122 | RESULT | gauge IDs + transform table (C6) | `gauge.rs` (+5 tests, 53 green): register id 0..3 (raw/fold/z/surprise), δ^k·E^p, cost, keeps-sign; GaugeSum carries gauge ID; Register::cheapest(need_sign). | 3032–3060 |
| N123 | RESULT | gauge-theory survey (14 papers) | Labels were BACKWARDS (ρ is the genuine gauge, rigid register is trivial); gauge-invariant = δ not r; gauge group R⁺ Abelian ("register shift = rotor" wrong); wedge = gauge field (curvature); only the CLASSICAL part solved. | 3062–3086 |
| N124 | RESULT | data-quality fixes surfaced | Mislabeled/scanned/OCR-broken PDFs across mathematics, computer_science, fibered_manifolds, physics_texts — defer to cleanup pass. | 3088–3094 |

### F. This file's own methods (self-referential)
| id | type | name | one-line definition | lines |
|---|---|---|---|---|
| N125 | METHOD | Deep-Dive Method | Two-stage subagent survey: pass 1 map+describe whole source; pass 2 lens recheck + new searches; "proved vs still-ours" tables. | 79–97 |
| N126 | METHOD | Learning & Reading Method | 6 rules: calibrate at mapping time; understand before judge; classify disagreements (uninformed/misinformed/illogical/incomplete); come to terms; test before trusting; syntopical not single-source. | 99–122 |
| N127 | METHOD | Graph-survey additions | Model ideas as labeled relation graph; counter-to edges carry the content; effort hub; fluency trap; reconsolidation = spine; two-stage = convergence diamond. | 124–148 |
| N128 | RESULT | graph-survey scale finding | Per-book (deepest, reversals surface) vs per-cluster (~11 papers, synthesis) vs depth-2 (untested); relations live in edges. | 150–162 |
| N129 | CONCEPT | project structure | rust/lattice (v3 engine: main.rs, latx.rs, build/causal.rs, gauge.rs, curl_field.rs, consult.rs), lattice-legacy (deprecated flat), archive (alt_parser, v3, v4). | 282–317 |

### G. Hunt-target nodes
| id | type | name | one-line definition | lines |
|---|---|---|---|---|
| N130 | SPECULATION | Hexagon conjecture | Do hexagons pack the semantic manifold? E=mc² analogy: energy = mass×c² via geometric product; "documented for later refactor investigation". | 626 |
| N131 | CLAIM | `(1/α)·α=1` tautology | philachive EmDrive "30μN forced convergence" = reverse-engineered free params + this tautology + mixed units; classified misinformed numerology. | 114, 2726–2727 |
| N132 | SPECULATION | Eisenstein triangles / simplex Aₙ | Chat arc ends at n-dimensional triangle (simplex Aₙ) / unified set; "square binary" (Gaussian) vs triangular (Eisenstein) integer lattices. | 2821–2844 |
| N133 | OPEN-QUESTION | square vs triangular one object? | Open thread: whether a²+b² and a²+ab+b² are one object via a real map, not a flag. | 2843–2844 |

### H. Dead / retired claim nodes (anchors for counter-to edges)
| id | type | name | one-line definition | lines |
|---|---|---|---|---|
| N134 | CLAIM | ring = Fisher information | RETIRED: ring is a χ² divergence; Fisher ∝ 1/frequency is inverted vs ring. | 800, 2305–2309 |
| N135 | CLAIM | natural gradient = multiplicative L1 | RETIRED: L1 is mirror-descent-shaped; natural gradient is contravariant. | 801, 2311–2314 |
| N136 | CLAIM | wedge = \|a∧b\| bivector area (V3) | RETIRED: wedge is the skew part/curl; Hestenes–Sobczyk canonical form. | 53–54, 990, 2678–2682 |
| N137 | CLAIM | raw flux is wrong | REVERSED (2026-08-12): raw signed O−E is the best REPRODUCIBILITY statistic; "wrong" held only for topic discovery. | 950–956, 1655–1678 |
| N138 | CLAIM | fiber bundle total space = ring × S^(n−1) | RETIRED: the × literally asserts triviality over a discrete base. | 536, 2684–2686 |
| N139 | CLAIM | band gap = spectral gap λ₂ (Cheeger) | RETIRED: band gap is ridge sparsification / noise-floor cutoff. | 2380–2383 |
| N140 | CLAIM | band gap = fixed point | RETIRED: frequency-space cutoff (DFT Λ_cutoff), not β=0 fixed point. | 2346–2347 |
| N141 | CLAIM | single universal monofractal α≈0.5 | REFUTED: locally monofractal with heterogeneous exponent field h(x). | 1353–1356, 2561–2566 |
| N142 | CLAIM | anti-lattice = Hodge dual | RETIRED: re-target to the commutant M′ (what a source erases). | 537, 2282–2283, 2688–2689 |
| N143 | CLAIM | rotor = α=0 Levi-Civita / zero curvature | RETIRED: α=0 is the curved Hellinger point; α=±1 are the flat dual geometries. | 2323–2324, 2648–2651 |
| N144 | CLAIM | geometric product = categorical composition; lattice IS a category | RETIRED: monoidal/tensor op; the lattice is a Lawvere metric space (weighted digraph). | 2480–2484 |
| N145 | CLAIM | "RG flow" over p-threshold sweep (M5) | RETIRED as flow: persistence diagnostic only; block-spin renormalization is the fix. | 2336–2339 |
| N146 | CLAIM | "proper frame = single monofractal" is a discovery | RETIRED as discovery: subordination/gauge; density dilation is exactly Barral–Seuret's dilation. | 2346–2349, 2557–2559 |
| N147 | CLAIM | repulsion reproduces (anti-lattice negatives meaningful) | REFUTED: P=0.000 held-out; negative edges are sampling noise, not suppressed reverse events. | 1671–1675, 2452–2454 |
| N148 | CLAIM | ring = Hölder exponent | CORRECTED: Zipf exponent is the Hölder/local dimension; ring is a χ² divergence on the Lq-spectrum side. | 551, 2553–2555 |
| N149 | CLAIM | quantum-on-classical gives speedup / real isomorphism | RETIRED: data-layout coincidence; structure present but inert; no BQP advantage. | 882–883, 1986–1994, 2533–2543 |
| N150 | CLAIM | ρ = Bregman projection / running coupling / singularity spectrum D(h) | ALL MIS-CATEGORIZED: ρ is a survival function (tail CDF) / reference-measure reweighting / spectral density μ(λ). | 2341–2344, 2414–2416, 2568–2571 |

---

## 2. Edge inventory (source→target | type | calibration | evidence/quote | line range)

### 2.1 Core-formalism derivation edges
| edge | type | calib | evidence | lines |
|---|---|---|---|---|
| N01 → N02 | derives-from | — | "`O` is recovered as `r + E`; `E = f(a)f(b)/T`" | 13–15 |
| N01 → N31 | requires | — | "stored primitive is the signed residual r = O−E" in `.latx` | 13, 431 |
| N03 → N01 | derives-from | — | "Three axes (exactly)… all derivable from the five raw numbers O, E, f(a), f(b), T" | 16–18, 1611–1612 |
| N04 → N03 | derives-from | — | "surprise ≡ correlation² (corr 1.000000)… ONE axis; split is sign vs magnitude" | 1630–1635, 1758–1762 |
| N05 → N03 | instance-of | — | "wedge `O_ab − O_ba` (bivector = the SKEW part / curl = temporal precedence)" | 17–18 |
| N06 → N03 | instance-of | — | "polarization `f(a)/f(b) − f(b)/f(a)` (radial scale)" | 18 |
| N07 → N01 | derives-from | — | "ring² = Σ(O−E)²/E" — an L2 norm of the residual | 19–20 |
| N07 → N134 | contradicts | counter-to | "NOT Fisher information (which is a matrix ∝ 1/frequency — inverted)" | 19–20, 2305–2309 |
| N08 → N20 | supports | — | constant-action level set = large-deviation rate function, not minimizer | 21–23, 2442–2445, 2655–2659 |
| N09 → N08 | derives-from | — | "`T = ring/2` (not `ring²/2`)" — balances the Lagrangian | 23, 658–666 |
| N10 → (naive surprise) | contradicts | counter-to | "`surprise` means anti-correlation (repulsion, `O < E`); the χ² magnitude is ORDER" | 24–25, 1878–1894 |
| N11 → N136(earlier rotor-is-rotation) | contradicts | counter-to | "The wedge is not the rotor… rotor is grade-0 scalar (inert) and a confounded Granger statistic" | 26–29, 2236–2243 |
| N12 → N11 | derives-from | — | spinor = combined object; even-grade fix ψ=(α+βI)U | 27–29, 2863–2867 |
| N13 → N62 / N138 | contradicts | counter-to | "The 'fiber bundle / fibration' is a fibered SET (base discrete ⇒ trivial)" | 30, 2684–2691 |
| N14 → N56 | contradicts | counter-to | "Causality is Rung-1 association… 'Causation vs gravity' collapses to the polarization axis" | 31–32, 2186–2191 |
| N15 → (single attractor) | contradicts | counter-to | "'attractor' is two opposite zeros: feedback O→E (noise) vs topic center div=0 (max structure)" | 33–34, 2661–2663 |
| N16 → N140, N139 | contradicts | counter-to | "band gap is a ridge/noise-floor cutoff, not a fixed point, not the spectral gap λ₂" | 35, 2346–2347, 2380–2383 |
| N17 → N141 | contradicts | counter-to | "locally monofractal with a heterogeneous exponent field, not a single universal monofractal" | 36–37, 2561–2566 |
| N18 → (metric claim) | contradicts | counter-to | "edge residual is NOT a metric (signed, asymmetric, d(a,a)≠0); ring = ‖v‖ IS a norm" | 38, 2665–2669 |
| N19 → N135 | contradicts | counter-to | "natural gradient G⁻¹∇L is a contravariant vector, L1 a scalar (mirror-descent-shaped at best)" | 39–40, 2311–2314 |
| N20 → (E–L / free-energy reading) | contradicts | counter-to | "NOT free-energy minimization and NOT Euler–Lagrange" | 41–42, 2655–2659 |
| N21 → N01 | derives-from | — | "δ = (O−E)/E = O/E − 1 the first-order (tangent) deviation" | 1845–1846 |
| N21 → N122 | instance-of | — | gauge.rs register table: raw/fold/z/surprise = δ^k·E^p | 3034–3050 |
| N22 → N21 | derives-from | — | two bridges, both of the same primitive O−E | 1801–1838 |
| N23 → N38 | supports | — | "A gauge (×ρ(a)ρ(b)) is an ADDITION in log space… bit-shift d>>1 is a fixed-angle rotation" | 1903–1913 |
| N24 → N25 | derives-from | — | one-branch: everything is area-normalised trigonometry | 1920–1961 |
| N26 → N01 | derives-from | — | taxonomy from five raw numbers; wedge fully independent (corr 0.07/0.22) | 1609–1635 |
| N27 → N01 | derives-from | — | sign of O−E = primitive; two signs (density + temporal) | 1637–1653 |
| N28 → N27 | supports | — | raw signed O−E best reproducibility 1.0/1.0/0.992 | 1655–1678 |
| N28 → N137 | contradicts | counter-to | "reconciles the old 'raw flux is wrong' note… two goals, two statistics" | 950–956, 1667–1669 |
| N29 → N28 | supports | — | "O and E are already the normalization; the rest is cross-band comparability" | 1680–1696 |
| N30 → N73/N82 | maps-to | OURS | "raw O−E ≡ multifractal residue — identical held-out score (one object, two projections)" | 1698–1713 |

### 2.2 Stack/architecture edges
| edge | type | calib | evidence | lines |
|---|---|---|---|---|
| N31 → N32 | supports | — | ".latx-only; the canonical builder is build_causal while build_flat/build-source are DEPRECATED" | 43–48 |
| N32 → (flat-built libs reality) | contradicts | counter-to | "It is the builder that ACTUALLY produced the libs (24 of 49 carry build_flat; 0 carry build_causal)" | 1788–1789 |
| N33 → N105 | derives-from | — | surprise register r²/E + mean-threshold = the square+mean display rule | 46, 2064–2080 |
| N33 → N50 | supports | — | square+mean "NO stop list"; ring IS the function/content classifier | 46, 781 |
| N34 → N31 | requires | — | CLI reads .latx v3 (mmap, targeted lookup kernel) | 189–213, 293 |
| N35 → N34 | instance-of | — | opcode table maps each command | 1188–1230 |
| N36 → N35 | instance-of | — | register map A/B/X/R/F | 1209–1214 |
| N37 → N73 | supports | — | "(Z₂)³² is a 32-qubit space; XOR kernel = WHT domain" | 900–906 |
| N38 → N37 | supports | — | barrel shifter changes ring band = gauge transformation through RG | 555–558, 905–906 |
| N39 → N24 | supports | — | pre-normalize → GA collapses to arithmetic; integer-only ops | 1137–1161, 1954–1961 |
| N40 → N39 | derives-from | — | every tier a pre-computed LUT; no division/sqrt/float | 1094–1113 |
| N41 → N34 | maps-to | OURS | BFS-cluster + DFS-conquer + JON stitch | 1232–1255 |
| N42 → N34 | requires | — | plugin pipes into down/consolidate | 1274–1295 |
| N43 → N34 | requires | — | dsh bundle wraps lattice-cli in pure Node | 1297–1330 |
| N44 → N32 | instance-of | — | 11 active libs built by build_causal; flat libs quarantined | 433, 470–478 |

### 2.3 Empirical edges
| edge | type | calib | evidence | lines |
|---|---|---|---|---|
| N45 → N34 | derives-from | — | six coordinate-system tests on .latx data | 513–523 |
| N46 → N73 | maps-to | ANALOGY | field-theory table: "isomorphic to physical field theory" (rotor row later counter-to'd) | 525–537 |
| N47 → N05 | supports | — | "The wedge IS the anti-symmetric derivative — no extra normalization needed" | 539–547 |
| N48 → N38 | derives-from | — | rotor descent on XOR kernel; fractal descent = argmin(G[d]) | 549–564 |
| N49 → N48 | derives-from | — | Zipf power law + squaring = band gap at u32 integer limit | 566–568 |
| N50 → N33 | supports | — | "Hardcoded stop lists are the wrong answer — the math already handles this" | 570 |
| N51 → N38 | derives-from | — | "The binary exponent IS the ring band" | 572–579 |
| N52 → N40 | supports | — | eigenbasis partitions domains without labels/training | 583, 668–675 |
| N53 → N52 | derives-from | — | harmonic ontology = ring_band × angle × cross_band_energy | 585–587 |
| N54 → N142 | maps-to | OURS | anti-lattice = Hodge dual (later re-targeted → N98) | 589, 537 |
| N55 → N46 | derives-from | — | Lagrangian speech generation L = T − V | 591–603 |
| N56 → N14 | maps-to | OURS | causation P(B|A) vs gravity P(A|B); "surprise flux O−E IS the gravity term" | 612–616 |
| N57 → N08 | supports | — | "not minimizing action but MAINTAINING it at a specific energy level" | 656 |
| N58 → N09 | derives-from | — | ring/2 balanced Lagrangian | 658–666 |
| N59 → N58 | derives-from | — | L1 partitions vocabulary; gap is structural | 684–692 |
| N60 → N52 | derives-from | — | cosine vs Hessian eigenbases = two coordinate systems | 696–711 |
| N61 → N60 | derives-from | — | ring-band distribution = cognitive frame; Zipf exponent = register | 719–731 |
| N62 → N13 | contradicts | counter-to | multifractal "nested fiber bundle" later downgraded to fibered set | 733–739 vs 2684–2691 |
| N63 → N62 | derives-from | — | 3D sphere/donut geometry | 741 |
| N64 → N38 | maps-to | ANALOGY | "renormalization group flow on the flux threshold E_p" (later: not a flow) | 743–748 |
| N65 → N66 | supports | — | only measured bigrams produce grammar | 750–758 |
| N66 → N55 | derives-from | — | hybrid: measured bigrams × ring_gravity × anchors | 760–785 |
| N67 → N66 | derives-from | — | "coherent nonsense" limitation | 777 |
| N68 → N05 | derives-from | — | wedge-fixed candidate selection | 779 |
| N69 → N31 | requires | — | .latx lookup returns content-only neighbors | 787 |

### 2.4 Relativity/quantum/frame edges
| edge | type | calib | evidence | lines |
|---|---|---|---|---|
| N70 → N58 | derives-from | — | c = L1/λ measured across 6 corpora | 811–843 |
| N71 → N70 | derives-from | — | frame dilation: 5.3× / 0.23× | 845–859 |
| N72 → N70 | derives-from | — | Lagrangian vs Einsteinian frames | 861–876 |
| N73 → N37 | derives-from | — | quantum table on (Z₂)³² | 880–906 |
| N73 → N149 | claims | OURS→ANALOGY | "The lattice IS a quantum computational system — not an analogy, a structural isomorphism" (later retired by N106) | 882–883, 2533–2543 |
| N74 → N73 | derives-from | — | measurement as search; query = measurement operator | 908–914 |
| N75 → N93 | supports | — | temporal fix restores wedge/curl | 923–928, 1741–1779 |
| N76 → N17 | supports | — | monofractal + time dilation (α→0.5 collapse) — later refined by N107 | 1339–1356 |
| N76 → N141 | contradicts | counter-to | "single monofractal" reading of the collapse is refuted | 1353–1356, 2561–2566 |
| N77 → N80 | derives-from | — | proper-frame residue P@50=1.0 on held-out | 1360–1384 |
| N78 → N48 | derives-from | — | Zipf–rotor–multifractal chain | 1386–1403 |
| N79 → N77 | derives-from | — | proper residue = importance score (within-band only) | 1405–1415 |
| N80 → N38 | maps-to | DIRECT | "gauge transformation (physics) = register change (hardware) = ring shift d>>n (lattice)" | 1417–1425 |
| N81 → N82 | supports | — | node-band normalization wins (P@50 1.0 vs 0.56) | 1427–1451 |
| N82 → N77 | supports | — | raw 0.52 / Lagrangian 0.56 / Einsteinian 1.00 | 1437–1451 |
| N83 → N80 | supports | — | gauge invariance only in local frame; t3 singularity | 1453–1463 |
| N84 → N82 | contradicts | counter-to | Lagrangian saturates at 0.60 — "relativity is not a limit of the Lagrangian" | 1465–1473 |
| N85 → N81 | supports | — | edge-level Einsteinian fails (frames categorical) | 1475–1487 |
| N86 → N81 | derives-from | — | rest frames = topical structure | 1489–1504 |
| N87 → N71 | maps-to | SPECULATION | multi-project frame dilation as distance; "SPECULATION, not a result" | 1506–1518 |
| N88 → N77 | supports | — | continuous tail-CDF ρ: P@500 0.992 | 1520–1537 |
| N89 → N88 | derives-from | — | P@500=0.992 ⇒ "the structure is geometric, not statistical" | 1539–1550 |
| N90 → N28 | derives-from | — | residual-rank coding: 4.76 bits/word | 1552–1568 |
| N91 → N85 | derives-from | — | scale = frame; sentence=surprise, document=correlation | 1570–1586 |
| N92 → N80 | maps-to | ANALOGY | Mandelbrot/Julia duality = frame/structure duality | 1715–1739 |
| N93 → N75 | derives-from | — | directional format stores {O_ab, O_ba, f(w), T} | 1741–1779 |
| N94 → N12 | derives-from | — | polar spinor = (ratio, difference) | 2909–2929 |

### 2.5 Survey edges
| edge | type | calib | evidence | lines |
|---|---|---|---|---|
| N95 → N24 | maps-to | DIRECT (proved rows) / ANALOGY (rotor, ring shift) / SPECULATION (physics=information) | proved table vs "still ours — NOT proven" vs "three analogies to stop over-claiming" | 2090–2153 |
| N96 → N56 | contradicts | counter-to | "causation vs gravity" collapses to polarization; wedge never a causal arrow | 2155–2223 |
| N97 → N11 | supports | — | "The rotor is NOT the wedge — split them"; wedge = circulation with reversal null | 2225–2255 |
| N98 → N12 | supports | — | even-grade spinor is the fix for grade-0 rotor; quantum-on-classical "real provided the Clifford product is actually used" | 2257–2293 |
| N99 → N134/N135 | contradicts | counter-to | "ring = Fisher information is INVERTED"; natural gradient ≠ L1 | 2295–2324 |
| N100 → N38 | supports (partial) | DIRECT | "bit-shift d>>1 IS the 2-adic hierarchical RG blocking step — a genuine theorem" | 2330–2334 |
| N100 → N145 | contradicts | counter-to | "a threshold sweep is a persistence diagnostic, not a flow — Retire 'RG flow'" | 2336–2339 |
| N101 → N37 | supports | DIRECT | "XOR kernel g[i⊕j] IS the graph Fourier transform of the hypercube" | 2365–2369 |
| N101 → N139 | contradicts | counter-to | "band gap = ridge sparsification, not Cheeger" | 2380–2383 |
| N102 → N07 | supports | DIRECT | "flux (O−E)²/E = χ² = α-divergence (α=3) = Tsallis q=2 = Bregman divergence" | 2399–2403 |
| N102 → N150 | contradicts | counter-to | ρ NOT a Bregman projection; NOT running coupling | 2414–2416, 2341–2344 |
| N103 → N05 | supports | DIRECT | "wedge IS the antisymmetric part; Q=0 ⟺ reversible" | 2437–2440 |
| N103 → N147 | contradicts | counter-to | "repulsion is sampling noise, not suppressed reverse events (P=0.000)" | 2452–2454 |
| N104 → N05 | supports | DIRECT | "wedge = the value of a 'direction functor'… verbatim our wedge O_ab − O_ba" | 2465–2469 |
| N104 → N144 | contradicts | counter-to | "RETIRE 'geometric product = composition'; the lattice is a Lawvere metric space" | 2480–2484 |
| N105 → N27 | supports | DIRECT | "sign(O−E) IS Booleanisation" | 2500–2504 |
| N106 → N73 | contradicts | counter-to | "quantum-on-classical is a data-layout coincidence, not a speedup"; no BQP advantage | 2533–2543 |
| N107 → N141 | contradicts | counter-to | "'a single universal monofractal α≈0.5' REFUTED — heterogeneous exponent field" | 2561–2566 |
| N107 → N148 | contradicts | counter-to | Zipf exponent = Hölder, not the ring | 2553–2555 |
| N108 → N34 | maps-to | OURS | 15-folder disposition (build/reference/foil) | 2580–2604 |
| N109 → N21 | supports | DIRECT | E = Shannon independence null; Boyd conjugate = mirror map; controllability = do-operator | 2606–2651 |
| N110 → N136/N138/N139/N140/N141/N142/N144 | contradicts | counter-to | the 10 retired over-claims (details in §3) | 2653–2711 |
| N111 → N109 | derives-from | — | Crouzeix test, Gramian, loop polarity, MDL, philachive foil | 2713–2727 |
| N112 → N26 | supports | DIRECT | scalar/wedge split = det/curl split of the local Jacobian | 2734–2738 |
| N113 → N112 | contradicts | counter-to | det≠0 ⟹ invertible/convergent FALSE; coarea factorization | 2758–2768 |
| N114 → N102/N104 | derives-from | — | curvature routing (new); MNN pruning trap | 2789–2806 |
| N115 → N80 | maps-to | SPECULATION | gauge = the unit; Gaussian/Eisenstein integers; simplex Aₙ | 2821–2844 |
| N116 → N21 | supports | — | v5: gauge-variant system; invariant core = δ | 2846–2867 |
| N117 → N12 | supports | — | geometric mutual probability = the spinor ψ = E + I·w | 2869–2929 |
| N118 → N21 | derives-from | — | gauge ladder pow1/2/3; little-o | 2931–2957 |
| N119 → N23 | derives-from | — | gauge = dimensionality; Euler between gauges | 2959–2983 |
| N120 → N39 | supports | — | SIMD gauges; byte-sliced fixed-point | 2985–3012 |
| N121 → N39 | supports | — | O(t·n) per pass; gauge-rung cost model | 3014–3030 |
| N122 → N21 | instance-of | — | gauge.rs C6: register IDs, δ^k·E^p, GaugeSum | 3032–3060 |
| N123 → N80 | contradicts | counter-to | "labels backwards: ρ is the genuine gauge, rigid register is trivial"; "register shift = rotor" wrong | 3067–3075 |
| N123 → N21 | supports | — | "the gauge-invariant is the RATIO δ, not the stored residual r" | 3071–3072 |

### 2.6 Method self-reference + hunt edges
| edge | type | calib | evidence | lines |
|---|---|---|---|---|
| N127 → N126 | derives-from | — | graph-survey additions = operational rules on top of the learning method | 124–148 |
| N125 → N127 | instance-of | — | deep-dive two stages = the convergence diamond | 79–97, 146–148 |
| N128 → N127 | derives-from | — | scale-determinant finding | 150–162 |
| N126 → N95/N110 | maps-to | OURS | "Calibrate at mapping time" is exactly what the surveys apply (DIRECT/ANALOGY/OURS/SPECULATION) | 105–108 |
| N130 → N24 | maps-to | SPECULATION | "Hexagons most densely pack circle-like shapes… This may be a normalization identity" | 626 |
| N131 → (philachive claims) | contradicts | counter-to | "misinformed numerology + the (1/α)·α=1 tautology"; "EmDrive '30μN forced convergence' is numerology" | 114, 2726–2727 |
| N132 → N80 | maps-to | SPECULATION | gauge = unit signature; Eisenstein triangles; "n-dimensional triangle (simplex Aₙ) / unified set" | 2821–2844 |
| N133 → N132 | derives-from | — | "whether square/triangular are one object (a real map between a²+b² and a²+ab+b², not a flag)" | 2843–2844 |

---

## 3. Counter-to / reversal / retired-claim edges (dedicated section, exhaustive)

The file is append-only; older notes are repeatedly corrected by later surveys. These are the reversals and retirements the file itself documents. "Counter-to" marks edges where a later note explicitly overrides an earlier one; every entry gives both sides with line ranges.

### 3.1 Reversals of verdicts (same object, verdict flipped)
1. **"raw flux is wrong" → "raw signed O−E is the best reproducibility statistic"** — [counter-to] L950–956 (old verdict: "Function words win every edge… so raw flux is wrong") vs L1655–1678 + L50–53 (2026-08-12 reversal: "this 'wrong' verdict was about TOPIC discovery — for reproducibility, raw O−E is correct. Two goals, two statistics"). Edge N28→N137.
2. **"surprise = χ² magnitude (order)" → "surprise means anti-correlation"** — [counter-to] L24–25 + L1878–1894 ("Co-occurrence (O > E) is ORDER… Genuine surprise is directional: − (O < E) = surprise (the anti-lattice). Keep the sign, abs() later"). Edge N10→naive.
3. **"least squares = least action = free-energy minimization / Euler–Lagrange" → rate-function reading** — [counter-to] L41–42, L2442–2445 ("quadratic large-deviation rate function, NOT free-energy minimization and NOT Euler–Lagrange"), L2655–2659 ("E–L gives stationary action; our empirical result is a constant-action level set, not a minimizer. The costate/adjoint p in Pontryagin IS our δ=(O−E)/E"). Edge N20→E–L-reading, N08→N20.
4. **"T = ring²/2" → "T = ring/2"** — [counter-to] L658–666 ("The ring²/2 kinetic term dominates log(f/T) by 100–3,000×… the ring² term was disproportionately large") + L23 (canonical truth: "T = ring/2 (not ring²/2)"). Edge N09→old-kinetic.
5. **"ring = Fisher information" → "ring = χ² divergence value"** — [counter-to/retired] L800 (strikethrough in the info-geometry table), L2305–2309 ("Fisher info is a matrix ∝ 1/frequency… The ring is large for common words — backwards"), canonical truth L19–20. Edge N07→N134.
6. **"natural gradient = multiplicative L1" → mirror-descent-shaped** — [counter-to/retired] L801 (strikethrough), L2311–2314 ("G⁻¹∇L is a contravariant vector; L1 is a scalar. They cannot be equal"). Edge N19→N135.
7. **V3 "wedge = |a∧b| (bivector area)" → "wedge = skew part / curl"** — [counter-to/retired] L53–54, L990 (V3 row struck), L2678–2680 ("the wedge O_ab−O_ba is the SKEW PART of a linear transformation (the curl), NOT a bivector area… RETIRE our V3 mapping"). Edge N05→N136.
8. **"wedge = rotor / rotation = rotor" (field table row) → "wedge ≠ rotor; rotor inert"** — [counter-to] L533 ("Rotation / spin | Rotor | exp(r_bwd − r_fwd)") and L1052–1058 ("rotor = exp(r_bwd − r_fwd) simplification") vs L26–29 ("The wedge is not the rotor… rotor is a grade-0 scalar (inert — it doesn't act) and a confounded Granger statistic") and L2236–2243 ("The rotor is NOT the wedge — split them… wedge (difference) is clean irreversibility; rotor (ratio) is a Granger statistic missing the persistence correction"). Edge N11→N136/rotor-table.
9. **"causation vs gravity = two directional forces" → "a distinction within Rung 1, collapses to polarization"** — [counter-to] L612–616 (causation P(B|A) vs gravity P(A|B)) vs L31–32 + L2186–2191 ("Both are OBSERVATIONAL conditionals; their ratio is exactly f(b)/f(a) = polarization… 'causation' is doing rhetorical work the do-calculus would not license"). Edge N14→N56.
10. **"wedge = causal arrow / temporal precedence implies causality" → "wedge = candidate orientation signal, never a causal arrow"** — [counter-to] L2179–2185 ("Temporal priority is necessary, not sufficient… the direction is fundamentally unidentifiable from a single joint distribution"). Edge N14→wedge-as-arrow.
11. **"attractor (one concept)" → "two OPPOSITE zeros"** — [counter-to] L33–34 + L2661–2663 ("Feedback equilibrium e=r−y→0 means O→E (noise); topic center div=0 means large |O−E| (max structure). A servo minimizes the residual; we rank BY it"). Edge N15→single-attractor.
12. **"fiber bundle / fibration (total space = ring × S^(n−1))" → "fibered SET; bundle trivial"** — [counter-to/retired] L536, L733–739 (nested fiber bundle) vs L30 + L2684–2691 ("the base (ring bands = integers) is DISCRETE, so every bundle over it is trivially trivial… 'total space = ring × S^(n-1)' literally asserts triviality (the × IS the trivial bundle). Correct object: the fibered set. 'register = gauge' mislabels external as internal — swap the labels"). Edges N13→N62, N13→N138.
13. **"quantum-on-classical = structural isomorphism (the lattice IS quantum)" → "data-layout coincidence; present but inert; no speedup"** — [counter-to] L882–883 ("not an analogy, a structural isomorphism") + L1986–1994 ("TO TEST… UNPROVEN") vs L2533–2543 ("Shor does NOT use the WHT; Grover does NOT; the FWT is a classical O(N log N) algorithm… no BQP-type advantage follows. The 'UNPROVEN' flag stands, now confirmed"; "quantum structure is present but inert — the noncommutative product is never used"). Edges N106→N73, N149.
14. **"anti-lattice = Hodge dual" → "re-target to the commutant"** — [counter-to/retired] L537, L589 vs L2282–2283 ("'What a source erases' = the operators outside its algebra (M′), not the internal Hodge star A* = AI⁻¹") and L2688–2689 ("Hodge dual ≠ anti-lattice (the commutant is right)"). Edge N54→N142.
15. **"rotor = α=0 Levi-Civita / zero curvature" → "α=0 is the curved Hellinger point"** — [counter-to/retired] L2323–2324 (α=0 contradiction) vs L2648–2651 ("dual flatness + Legendre + Crouzeix live at α=±1; α=0 is the self-dual curved Hellinger point (R^α=(1−α²)/σ⁴). Retire 'rotor = α=0 Levi-Civita'"). Edge N143.
16. **"band gap = fixed point" → "band gap = cutoff / ridge"** — [counter-to/retired] L2346–2347 ("RETIRE 'band gap = fixed point'… a frequency-space cutoff (DFT's Λ_cutoff), not a fixed point (β=0 in coupling space)") + canonical L35. Edge N16→N140.
17. **"band gap = spectral gap λ₂ (Cheeger)" → "band gap = ridge sparsification"** — [counter-to/retired] L2380–2383 ("RETIRE 'band gap = spectral gap λ₂ (Cheeger)'… The correct home is ridge sparsification (2604.20078)") + L35. Edge N101→N139.
18. **"single universal monofractal α≈0.5" → "locally monofractal with heterogeneous exponent field"** — [counter-to/refuted] L1353–1356 ("the multifractal spectrum is a single monofractal (D≈0.5)") vs L2561–2566 ("REFUTED… the correct statement is locally monofractal with a heterogeneous exponent field h(x) — a monofractal sea with multifractal islands. The heterogeneity IS the physics") and canonical L36–37. Edge N107→N141.
19. **"proper frame = monofractal is a discovery" → "a subordination/gauge, not a discovery"** — [counter-to] L2557–2559 ("Barral–Seuret proves a dilation operation changes the spectrum and breaks the Legendre duality. Our density dilation is exactly this dilation") + L2346–2349. Edge N146.
20. **"ring = Hölder exponent" → "Zipf exponent = Hölder; ring = χ² divergence on the Lq-spectrum side"** — [counter-to/corrected] L551 ("The ring value IS the Hölder exponent") vs L2553–2555 ("the Zipf exponent = the Hölder/local dimension, not the ring band"). Edge N107→N148.
21. **"RG flow over p-threshold sweep (M5)" → "persistence diagnostic, not a flow"** — [counter-to/retired] L743–748 vs L2336–2339 ("a threshold sweep is a persistence diagnostic, not a flow — a real RG flow must integrate-out + rescale + renormalize the couplings. Retire 'RG flow'; the fix is to implement the block-spin renormalization"). Edge N100→N145.
22. **"geometric product = categorical composition; 'the lattice IS a category'" → "Lawvere metric space / monoidal operation"** — [counter-to/retired] L2480–2484 ("RETIRE 'geometric product = composition' — it is a monoidal/tensor operation… RETIRE 'the lattice IS a category' — it is a Lawvere metric space (a weighted digraph), a category only after freely generating paths") + L2667–2668. Edge N104→N144.
23. **"one-branch = the Rosetta Stone" → retired** — [counter-to/retired] L2481–2483 ("the downloaded paper is the Other Minds stone, not Baez–Stay"). Edge N144-family.
24. **"repulsion reproduces / anti-lattice negative edges = meaningful suppressed events" → "sampling noise (P=0.000)"** — [counter-to/refuted] L1671–1675 ("Repulsion does not reproduce: negative edges (O < E) score P=0.000… sampling noise") vs L2452–2454 ("a genuine FT reverse event is rare but real; our repulsion scores P=0.000 — it does not reproduce at all. So the anti-lattice's negative edges are sampling noise, not suppressed reverse events"). Edge N103→N147.
25. **"ρ(w) = running coupling" → "ρ is a density/measure μ(λ)"** — [counter-to/corrected] L2341–2344 ("In Data Field Theory the canonical dimension is set by the spectral density μ(λ); ρ(w) is our μ(λ). The 'running coupling' role is the flux residual O−E itself"). Edge N102→N150.
26. **"ρ = Bregman projection" → "reference-measure reweighting (KL-layer axiom)"** — [counter-to/mis-categorized] L2414–2416 ("FALSE (mis-categorized): the density dilation ρ is NOT a Bregman projection. It is a reference-measure reweighting E→E·ρ(a)·ρ(b) — the base-measure/prior, i.e. the KL-layer axiom"). Edge N102→N150.
27. **"ρ = singularity spectrum D(h); proper frame = Legendre transform" → "ρ is a survival function (tail CDF)"** — [counter-to/mis-categorized] L2568–2571 ("FALSE (mis-categorized): ρ(w) = singularity spectrum D(h)… ρ is a survival function (tail CDF); D(h) is a level-set dimension. The correct identity is D(a) = −I(a)/χ+"). Edge N102→N150.
28. **"det J ≠ 0 ⟹ invertible" → "local invertibility only (IFT); global needs properness (Hadamard)"** — [counter-to] L2758–2761 ("'det J ≠ 0 ⟺ invertible' is FALSE… det ≠ 0 gives only local invertibility (IFT); global needs properness. Every counterexample fails via escape-to-infinity. So our 'sign of O−E = orientation' is a LOCAL statement"). Edge N113→N112.
29. **"det J ≠ 0 ⟹ convergent" → false (Markus-Yamabe fails dim ≥ 14)** — [counter-to] L2766–2768 ("Convergence is three-tier: det ≠ 0 (local necessary), spectral radius (the rate), spectral gap + sharp threshold (persistence, NHIM (1−λ)²). Our Part-1 contraction constant is the local (IFT) case only"). Edge N113→N112.
30. **"edge residual is a metric / 'lattice converges to a topic center' (Banach)" → "not a metric; Banach in shape only"** — [counter-to] L38, L2665–2669 (fails positivity/identity/symmetry/triangle; Lawvere metric space) and L2671–2676 ("Missing hypotheses: metric space + completeness + deterministic self-map + contraction λ<1. Also split the two conflated fixed points: Banach F(x)=x vs harmonic ∇·F=0. 'RG flow converges' is metaphor — d>>1 is a map, not a flow"). Edge N18→metric-claim, N16-family.
31. **"register shift = rotor (gauge group)" → "gauge group R⁺ is ABELIAN; 'register shift = rotor' is wrong"** — [counter-to] L3073–3075 ("The gauge group is R⁺ (or 2^ℤ ≅ ℤ for the barrel shift) — ABELIAN. Not a rotor gauge… 'register shift = rotor' is wrong; the non-commutativity lives in the transition matrix (wedge/time-order)") + L2140–2144 (ring shift is a rotor, not a translator — the "three analogies to stop over-claiming"). Edge N123→N80.
32. **"gauge vs frame labels" → "backwards: ρ is the genuine gauge, the rigid register is the trivial symmetry"** — [counter-to] L3067–3070 ("We had the labels backwards: we call the rigid register 'gauge' and the local ρ 'frame'; the papers say the rigid part is the trivial symmetry and ρ is the genuine gauge (Weyl 1918 scale gauge)") + L3081–3082 ("ρ is the frame, not the gauge — its P@50 0.52→1.00 efficacy proves it isn't a redundancy"). Edge N123→N80.
33. **"store r = O−E (gauge-variant)" → "the invariant is δ = O/E − 1; store δ not r"** — [counter-to/upgrade] L3071–3072 ("The gauge-invariant is the RATIO δ… We store r (the gauge-variant form); the invariant δ is derived at query time") + L3085 ("store δ not r"). Edge N123→N21.
34. **"e^(iθ) is the invariant" → "the trig gauge breaks at θ=π/2; δ is the invariant, θ is gauge-variant"** — [counter-to] L2976–2983 ("Euler's e^(iθ) is gauge-variant — maybe not optimal… the trig gauge breaks exactly where the symmetric part vanishes… e^(iθ) is a gauge correction term between gauges, not the invariant. The invariant is the fold δ = O/E − 1"). Edge N119→N21.
35. **"Shannon-1953 'lattice' = our lattice" → "name-ancestor only"** — [counter-to/terminology] L2614–2617 ("Shannon 1953 'The Lattice Theory of Information' is a name-ancestor, NOT our structure — it's a partial-order join-semilattice… Stop calling the co-occurrence graph 'Shannon's lattice'"). Also string-theory "flux" homonym L2697–2698 ("'Flux' in string theory is a HOMONYM — gauge-field background H=dB, zero contact with (O−E)²/E"). Edge N109→name-ancestor.
36. **"MNN pruning on the directional layer" → "TRAP — would zero the wedge by construction"** — [counter-to] L2803–2806 ("MNN pruning is a TRAP… Its justification ('true dualities are always symmetric') contradicts the wedge O_ab ≠ O_ba… MNN would zero the wedge by construction — the exact 2026-08-14 bug"). Edge N114→MNN.
37. **"spectral gap widening = math became right" → wrong (band gap is ridge, not Cheeger)** — [counter-to] L2808–2811. Edge N114→wrong-clause.
38. **"causality = minimum energy" → "= least squares = least action (proven via Dirichlet energy); harmonic component = topic center"** — [counter-to/upgrade] L2245–2249 ("The Dirichlet energy ½‖div‖² + ½‖curl‖² is a least-squares objective; gradient descent is least action; the harmonic component X_H ∈ ker B₁ ∩ ker B₂ᵀ (div=0 ∧ curl=0) is our div=0 topic center"). Edge N97→least-action.
39. **"flux = derivative (naive)" → "flux = derivative = the incidence commutator [L_x, A]"** — [recast] L2377–2378 ("PROVEN (recast): 'flux = derivative' = the incidence commutator [L_x, A] with [L_x,A]_{ij} = (x_i−x_j)A_{ij} and Δ = K†K (div∘grad)"). Edge N101→flux-derivative.
40. **"one branch (single algebra)" → "ringed space: semisimple C*/Clifford base + nilpotent tangent layer"** — [counter-to/correction] L2266–2272 ("The dual numbers ℂ[ε]/(ε²) are a nilpotent *-algebra with NO C*-norm. So the framework has two layers… The 'one-branch collapse' needs this correction"). Edge N98→N24.
41. **"rotor is a rotor (GA sense)" → "ANALOGY — ours is grade-0 scalar, the paper's is even-grade"** — [calibration downgrade] L2136–2137 ("rotor exp(r_bwd − r_fwd) = a rotor | analogy — ours is grade-0 scalar, the paper's is even-grade; ring shift = versor/translation | analogy — a grade-0 rotor stand-in, not a PGA versor") + L2140–2144. Edge N95→N11/N12.
42. **"wedge = bivector area sin² = 1−cos² (GA &GC)" → "kept for the AREA identity, but the wedge object itself is the skew part"** — [refinement] L2119 (proved: wedge area sin² = 1−cos² = Eq. 1.4 + Pythagoras) vs L2678–2682 (wedge = skew part; don't conflate with the Amari–Chentsov tensor C_ijk = Γ−Γ*, a symmetric 3rd-order skewness). Edge N95→N05.
43. **"fibration as 'ring = fiber base space' (eigenvector-ring fibration test)" → "fibered set; 'register = gauge' mislabels external as internal"** — [counter-to] L523 vs L2684–2691. Edge N13→N62.
44. **"polarization second-order register (f(a)²−f(b)²)/T²" → "UNTESTED — decide by held-out score after full build_causal lib rebuild"** — [open] L1776–1779 ("the normalization register — E = f(a)f(b)/T (first-order) vs (f(a)²−f(b)²)/T² (second-order polarization) — untested"). Edge N06→open.
45. **"edge weight = Shannon-level max-ent" → "the α-layer, one rung BELOW KL"** — [counter-to/downgrade] L2405–2408 ("our edge weight is the α-layer, one rung BELOW KL… χ² ≈ 2·KL is second-order only. Our 'max-ent' claims hold only at the generalized (power/Bregman) level, not the Shannon level"). Edge N102→N109.
46. **"wedge as 2-categorical / 'one RG orbit'" → "wedge is 1-level gauge; non-zero wedge forces RG non-uniqueness"** — [correction] L3076–3077 ("the wedge is 1-level, NOT 2-categorical gauge") and L2773–2775 ("RG non-uniqueness: the wedge forces it… nonzero wedge = rotational content = complex flow-Jacobian eigenvalues = the signature of non-uniqueness. Falsifiable: imaginary eigenvalues ⟹ 'one RG orbit' is false"). Edge N100→N05.
47. **"causality-as-suggestion (honest self-diagnosis)" → formal placement: weighted-association-graph side, not causal-graph side** — [re-framing] L2192–2194 ("'Causality as suggestion' is an honest self-diagnosis. It correctly places us on the weighted-association-graph side (not the causal-graph side)"). Edge N96→N14.
48. **"correlation = symmetric (note drops wedge clause)" → "Newton's action=reaction = FULL geometric product"** — [correction] L2623–2627 ("'equal' = symmetric scalar, 'directed to contrary parts' = anti-symmetric bivector (wedge). Our 'correlation = symmetric' note drops the wedge clause"). Edge N109→N03.

### 3.2 Retired-but-still-verbatim claims (the file's own dead-claims ledger, L50–54)
- "ring = Fisher information" (L800, L2305–2309) — RETIRED (see §3.1 item 5).
- "raw flux is wrong" (L888-era note, reversed at L950–956, L1655–1678) — REVERSED for reproducibility; valid only as a topic-discovery verdict (see item 1).
- V3 "wedge = |a∧b|" (L925-era, struck at L990, retired at L2678–2680) — RETIRED (see item 7).

---

## 4. Hunt-target index

### 4.1 "Einstein triangle" / "Einsteinian" / "triangle"
- **No literal phrase "Einstein triangle" in the file.** Closest matches, exhaustively:
  - **"Eisenstein triangles"** — L2821–2844 (chat-session survey #2): arc "gauge symmetry of (a−a²)/2 → e vs χ → geometric product = symmetric+antisymmetric → edge-as-primitive → spinor → Gaussian integers ('square binary') → **Eisenstein triangles** → n-dimensional triangle (simplex Aₙ) / unified set" (L2826–2828). Lands as gauge-int experiment + Signature axis (L2840–2842).
  - **"Eisenstein/Einstein frame"** — L1516 (multi-project memory speculation: "the Eisenstein/Einstein frame as a project-distance metric. SPECULATION, not a result").
  - **"n-dimensional triangle (simplex Aₙ)"** — L2828. Open question "whether square/triangular are one object (a real map between a²+b² and a²+ab+b², not a flag)" — L2843–2844.
  - **"triangle inequality"** — L2478 (Lawvere metric space: "composition = the triangle inequality, and the converse (reversed edge) ≠ original = the wedge") and L2666 ("triangle inequality almost certainly false (χ² is a Bregman divergence)").
  - **"triangle-curvature statistic"** — L3086 (gauge-theory upgrade to test).
  - **Einsteinian (physics-frame usage)** — L439 (density-dilation frame stays test-only), L861–876 (Lagrangian vs Einsteinian frames; "Einsteinian mechanics IS Lagrangian mechanics from the local perspective: proper time dτ = ds/c is the invariant action element"), L1445–1451 (Einsteinian = node-band dilation, P@50 1.00), L1456, L1468 (Einsteinian 1.000 vs Lagrangian 0.600), L1475–1487 (edge-level Einsteinian fails), L1705, L1766, L1901, L2149 (directed-integral local frame Iₘ(x) proves why Einsteinian beats Lagrangian), L2317–2321 (Lagrangian global vs Einsteinian local = θ/η coordinates; "The Legendre transform of ρ is the missing piece that would unify the two bridges"), L2430, L2635 (Kalman duality = node/edge (Lagrangian/Einsteinian) bridge).
  - **The "(1/α)·α=1 tautology"** (task hint) — L114 (learning-method rule 3 example: "philachive: misinformed numerology + the (1/α)·α=1 tautology") and L2726–2727 (philachive EmDrive "30μN forced convergence" is numerology: "reverse-engineered free params + the tautology (1/α)·α=1 + mixed μN vs μN/kW units"). Node N131.

### 4.2 "hexagon" / "hexagonal" / "causal lattice" / "hexagon conjecture"
- **EXACTLY ONE occurrence in the whole file: "Hexagon conjecture" — L626** (node N130): "Hexagons most densely pack circle-like shapes, minimizing area. Is the lattice the right shape for the semantic manifold? E=mc² analogy: if information processes at c², creating a plane, then what travels through the plane has energy equal to the mass of information. This may be a normalization identity — the geometric product a·b = |a||b|cos(θ) relates energy (ring magnitude) to mass (frequency) through the angle of intersection. Documented for later refactor investigation."
  - Status: SPECULATION/UNTESTED — "documented for later refactor investigation", never revisited or confirmed anywhere later in the file.
- **"hexagonal"** — 0 occurrences. **"causal lattice"** — 0 occurrences (the phrase does not exist; the lattice's causal claim is handled via "causality" terms, §4.4).

### 4.3 "gauge", "register", "ring shift", "RG flow", "renormalization"
- **gauge** (121 matches; thematic ranges):
  - Canonical truth: probability/count = "same object in a different gauge (register)" L15; 2026-08-22 stack L43–48.
  - Relativity: "Ring = dimension; changing ring = changing reference frame = gauge transformation" L577; barrel shifter = "gauge transformation through the renormalization group" L905–906.
  - **"Gauge = register = ring shift (terminology)" L1417–1425** — one operation three names; t-1..t2 plateau, t3 singularity; Landau/Coulomb/axial analog L1424.
  - Gauge symmetry only in local frame L1453–1463; Lagrangian gauge limit L1465–1473.
  - Exponent correspondence L1903–1913; δ gauge connection L1849–1851.
  - PGA: "ring shift = gauge transform" analogy L2100; "three analogies to stop over-claiming" L2140–2144.
  - RG survey: ρ = density not running coupling L2341–2344.
  - Escort sign note L2421–2426; register/gauge shift L2492, L2853.
  - Gauge-theory survey L3062–3086 (labels backwards; δ invariant; Abelian group; wedge = gauge field; classical-only).
  - Gauge-variant system v5 L2846–2867; gauge ladder L2931–2957; gauge = dimensionality L2959–2983; e^(1/e) L2985–2994; SIMD gauges L2996–3012; gauge IDs C6 L3032–3060; gauge.rs L295, L3034.
- **register** (47 matches; thematic ranges):
  - Gauge/register equivalence L15; surprise register r²/E L46.
  - Register (speaker style) L505, L673, L719–731 (frame distribution as comparative register).
  - Register map (ISA) L1191, L1209–1214.
  - Gauge = register = ring shift L1417–1425; register shift plateau L1457.
  - Mandelbrot c = frame/register/gauge L1722.
  - Normalization register open question L1776–1779.
  - δ registers table L1842–1860 (raw/fold/z/surprise); statistics vs physics register L1900.
  - Register/gauge shifts for invariance test L2208–2210; register/gauge shift = lossy adjunction L2492.
  - v5: normalization register L2850–2853.
  - gauge.rs register IDs + transform table + GaugeSum L3032–3060; register group closure untested L3084–3086.
- **ring shift** (15 matches): L568 (Zipf/band-gap), L572 (multi-level topic modeling), L921 (LUT descent), L1227 (ISA example "SHR R 2"), **L1417–1425 (gauge = register = ring shift)**, L1457 (register shift sweep), L2100 (PGA: "our ring shift = gauge transform is this idea"), L2104 (ring shift = multiply by s), L2137 (ring shift = versor/translation — analogy), L2140 (ring shift is a rotor, not a translator), L2492, L2853, L3074 ("register shift = rotor" is wrong).
- **RG flow / renormalization** (18 matches): L555 (bit-shift = RG flow, right-shift zoom out), L743 (RG flow on flux threshold p-sweep — later retired as flow, L2336–2339), L906 (gauge via RG), L1400 (bit-shift = fixed angle), L1734 (mini-Mandelbrot RG zoom), L1911–1912 (bit-shift d>>1 fixed-angle rotation), **L2326–2359 (RG/SFT survey: bit-shift = 2-adic RG PROVEN L2330–2334; M5 p-sweep retired as flow L2336–2339; ρ not running coupling L2341–2344; band gap ≠ fixed point L2346–2347; band-gap pruning = monotone RG UNPROVEN L2351–2353; DFT dimensional phase transition gift L2355–2359)**, L2450 (renormalized flux topics), L2674–2676 ("RG flow converges" is metaphor — d>>1 is a map not a flow), L2773–2775 (RG non-uniqueness: wedge forces it), L2947 (gauge-shift down the ladder), L3025 (renormalization provenance: Kadanoff–Wilson).

### 4.4 "causal", "residual", "O − E", "wedge", "spinor", "polarization", "rotor"
- **causal / causality / causation** (48 matches): canonical truth L31–32 (Rung-1 association, never a causal arrow); "Causation vs Gravity" L612–616 (two directional components; gravity selects bridges); wedge fix "forward causation (wedge>0)" L779; relativity "causality propagation identical in all frames" L873; quantum "word order is causal" L896; **"The sign is where causality lives" L1825–1829**; "Causality as suggestion" L1973–1976; **Causal-inference survey L2155–2223** (wedge is temporal precedence NOT causal arrow L2179–2185; causation vs gravity within Rung 1 L2186–2191; causality-as-suggestion honest L2192–2194; invariance test = causal-robust candidate L2206–2211; identify-before-estimate L2221–2223); "Causality = minimum energy = least squares = least action" L2245–2249; logic survey: observation ≠ intervention L2506–2509; do-operator gap L2521–2524; controllability = do-operator L2634–2637; MNN trap "causality = the bivector" L2804.
- **residual** (≈50 matches, thematic): signed residual r = O−E (passim); Pearson residual L942; residual vectors (eigen/coordinate systems) L984–1034; proper-frame residue L1360–1415, L1520–1537; residual surprise (lossless) L1552–1568; edge residual not a metric L38, L2665–2669; residual = internal hom of Lawvere metric L2476–2478; residual edge = description vs collapsed surprise L2511–2515; "raw O−E vs renormalized flux topics" L2450.
- **O−E / O-E** (≈60 matches; core formula): definitions L13–14, L940 (F0 flux), L950–956 (discovery path + reversal), L1621–1623 (three statistics), L1637–1653 (sign primitive), L1655–1678 (reproducibility), L1680–1696 (O and E are the normalization), L1741–1779 (directional format), L1801–1838 (two bridges), L1840–1918 (δ registers), L1920–1961 (one-branch), L2042–2054 (Pythagoras), L2330–2334 (2-adic RG), L2655–2659 (costate p = δ).
- **wedge** (100 matches — the single most-edited concept): canonical L16–18, L26–29 (wedge ≠ rotor), L53–54 (retired |a∧b|); coordinate tests L521; field table L532–533; anti-symmetric derivative L539–547; rotor descent L557; oscillation L640; wedge fix L779; wave model polarization = wedge L823; temporal fix L923–928; V3 retired L990; wedge deflation L1083–1085; taxonomy L1615–1628; two signs L1647–1652; directional format L1746–1754; cat↔chases +55.7 L1774; sign/causality L1825–1829; one-branch L1929; GA&GC L2116–2119, L2152; causal survey L2172–2185; Granger survey L2225–2255 (circulation, rotor ≠ wedge, reversal null); operator algebra L2263; info-geometry L2302–2303; spectral graph L2371–2375; max-ent L2411; stat-mech L2437–2459 (FT, exp-ratio experiment); category theory L2465–2494 (direction functor; functor-valued upgrade); logic L2518; Jacobian L2734–2738; RG non-uniqueness L2773–2775; MNN trap L2804–2806; spinor L2863–2899; gauge field L3076–3077.
- **spinor** (26 matches): canonical L27–29 (even-grade fix ψ = (α+βI)U); curl-field --seed polar spinor L458; GA&GC gifts L2146–2147; escort note L2425; Hestenes–Sobczyk shelf L2601; chat #2 L2827, L2842; **v5 spinor notes L2846–2867** (combined object of the three operators); **geometric mutual probability = the spinor L2869–2929** (ψ_ab = E + Iw, |ψ|e^(iθ), polar form (ratio, difference)); gauge ladder L2954; trig-gauge singularity L2976–2983.
- **polarization** (27 matches): canonical L18 (radial scale); L32 (causation-vs-gravity collapses to it); L439 (polarization fix untested flag); L823 (wave rotation = wedge component); L926 (zeroed by alphabetical sort); ISA flags L1214; taxonomy L1615–1628 (fully independent); directional format L1755; open register L1776–1779; two bridges L1835–1838; polarization identity (GA) L2042, L2115; radial part extension L2135; matrix split proven L2173; L2188–2189 (collapse); Jacobian diagonal L2737; curvature routing proxy L2793; spinor L2864, L2899.
- **rotor** (52 matches): canonical L26–29 (grade-0 inert, confounded Granger); field table L533; rotor descent L549–558; pre-normalization L1052–1058; Zipf–rotor chain L1386–1403; edge = rotor with scale L1626, L1837, L1922; GA&GC L2096–2144 (versor/rotor, three analogies); causal survey rotor null L2218–2220; Granger survey L2236–2243 (rotor ≠ wedge, condition on target's past); operator algebra L2261–2264 (inner *-automorphism, grade-0 doesn't act); α=0 contradiction L2323–2324; category theory L2491–2492 (functor-valued direction fixes inert rotor); α=0 retired L2648–2651; even_part()/rotor() L2835; spinor L2865–2867; gauge group "not a rotor gauge" L3073–3074.

### 4.5 "rebuild", "causal.rs", "build_causal", "fixed point", "integer register", "Phase 4", "N17"
- **rebuild** (3 matches): L439 ("The directional rebuild (N17) is MOOT — the stack is already directional (wedge ≠ 0 verified)"); L507 (Wikipedia full rebuild: 10K articles → 27.5M flux edges → 256 MB .latx); L1778 ("decide by held-out score after a full build_causal lib rebuild (the 11 active libs are directional; the 25 v1-era libs are still the pre-renormalisation symmetric builds, quarantined)").
- **causal.rs** — L294 (project structure: "build/ # causal.rs (build_causal) + common.rs — the builders"). Related: smush_causal port L1792–1793.
- **build_causal** (12 matches): L44–45 (canonical builder), L181–187 (canonical; build_flat deprecated; NOT feature-equivalent — flat has optimisations), L294, L433, L444, L474 (11 active libs), L1177 (dependency chain layer 0), L1206 (BLD opcode), L1778, L1788–1799 (flat ACTUALLY produced the libs, 24 of 49; build_causal 0; build_causal carries N11 cleaning + R10 docs sidecar).
- **fixed point** (6 matches): L35 (band gap NOT a fixed point); L2346–2347 (RETIRE "band gap = fixed point"); L2353 ("least squares = least action" is variational (fixed point), NOT an irreversibility theorem); L2673 (split the two conflated fixed points: Banach F(x)=x vs harmonic ∇·F=0); L2991 (e = fixed point of the x↔1/x gauge); L2998/L3005 (fixed-point arithmetic — different meaning).
- **integer register** — **phrase NOT present in the file.** Nearest matches: ISA register map L1209–1214 and "the prompt loads the register file" L1191; gauge.rs register IDs + transform table L3032–3060; "integer (a,b) pair" (gauge-int experiment) L2840. (The phrase appears only in the older AGENTS.md snapshot shown to me, not in the current file.)
- **Phase 4** — **NOT present in the file.** Only "Phase 2" appears: L439 ("NORMALISATION PASS (Phase 2, 2026-08-16)"). The older snapshot's "Phase 4 rebuild of english.latx + 23 libs as directional signed .latx (N17)" has been superseded: the current file states the directional rebuild (N17) is MOOT (L439).
- **N17** — exactly 1 match: L439 ("The directional rebuild (N17) is MOOT — the stack is already directional (wedge ≠ 0 verified)"). Related build-issue codes: N9 (directional sign fix, L1790), N11 (corpus-cleaning ports, L1796), D2/D3/D5/D7 (latent bugs, L439), R10 (docs sidecar, L1797).

---

## 5. Claim-calibration ledger: CURRENT / RETIRED / UNTESTED (top ~45 claims)

| # | Claim | Status | Where decided |
|---|---|---|---|
| 1 | Stored primitive = signed residual `r = O−E` (per direction), not flux, not O_ab | CURRENT | 13–15, 431 |
| 2 | Three axes exactly: correlation/surprise (scalar), wedge (bivector), polarization (radial) | CURRENT | 16–18, 1609–1635 |
| 3 | `surprise ≡ correlation²` — one axis, split is sign vs magnitude | CURRENT | 1630–1635, 1758–1762 |
| 4 | Ring = χ² divergence value = L2 norm (`ring² = Σr²`) | CURRENT | 19–20, 800, 2305–2309 |
| 5 | Ring = Fisher information | RETIRED | 800, 2305–2309 |
| 6 | Wedge = skew part `O_ab − O_ba` / curl / temporal precedence | CURRENT | 17–18, 990, 2678–2680 |
| 7 | Wedge = \|a∧b\| bivector area (V3) | RETIRED | 53–54, 990, 2678–2682 |
| 8 | Wedge ≠ rotor; rotor `exp(r_bwd−r_fwd)` grade-0 inert, confounded Granger | CURRENT | 26–29, 2236–2243 |
| 9 | Spinor `\|a\|\|b\|(cosθ + I sinθ)` = combined object; even-grade fix `ψ=(α+βI)U` | CURRENT (fix = upgrade path, not yet shipped) | 27–29, 2146–2147, 2863–2867 |
| 10 | Action: coherent speech keeps ∫L CONSTANT (level set), not minimized | CURRENT | 21–23, 656, 2655–2659 |
| 11 | "Least squares = least action" = quadratic large-deviation rate function, NOT E–L / free-energy | CURRENT | 41–42, 2442–2445, 2655–2659 |
| 12 | `T = ring/2`, not `ring²/2` | CURRENT | 23, 658–666 |
| 13 | "Surprise" = anti-correlation (O<E); χ² magnitude = order | CURRENT | 24–25, 1878–1894 |
| 14 | Causality = Rung-1 association; "causation vs gravity" collapses to polarization | CURRENT | 31–32, 2186–2191 |
| 15 | "Attractor" = two opposite zeros (O→E noise vs div=0 structure) | CURRENT | 33–34, 2661–2663 |
| 16 | Band gap = ridge/noise-floor cutoff | CURRENT | 35, 2380–2383 |
| 17 | Band gap = fixed point | RETIRED | 2346–2347 |
| 18 | Band gap = spectral gap λ₂ (Cheeger) | RETIRED | 2380–2383 |
| 19 | Multifractality = locally monofractal heterogeneous exponent field | CURRENT | 36–37, 2561–2566 |
| 20 | Single universal monofractal α≈0.5 | RETIRED/REFUTED | 1353–1356, 2561–2566 |
| 21 | Edge residual is NOT a metric; `ring = ‖v‖` IS a norm | CURRENT | 38, 2665–2669 |
| 22 | "Natural gradient = L1" | RETIRED (mirror-descent-shaped at best) | 39–40, 801, 2311–2314 |
| 23 | Raw signed O−E = best REPRODUCIBILITY statistic (1.0/1.0/0.992) | CURRENT (reverses "raw flux is wrong") | 950–956, 1655–1678 |
| 24 | O and E are the normalization; density ρ = cross-band comparability only | CURRENT | 1680–1696 |
| 25 | Node-band normalization beats edge normalization (P@50 1.0 vs 0.56) | CURRENT | 1427–1435, 1475–1487 |
| 26 | Lagrangian gauge saturates at 0.60; relativity is NEW information, not a limit of Lagrangian | CURRENT | 1465–1473 |
| 27 | .latx v3 = source of truth; JSON .lattice/.alattice removed | CURRENT | 10–12, 429, 787 |
| 28 | build_causal canonical; build_flat/build-source deprecated → lattice-legacy | CURRENT | 43–48, 1781–1799 |
| 29 | Surprise register `r²/E` + mean-threshold (square+mean, no stop list) | CURRENT | 46, 2064–2080 |
| 30 | Bit-shift `d>>1` = 2-adic hierarchical RG blocking step | CURRENT (PROVEN) | 2330–2334 |
| 31 | p-threshold sweep (M5) = RG flow | RETIRED (persistence diagnostic) | 2336–2339 |
| 32 | XOR kernel = WHT = GFT of the hypercube | CURRENT (PROVEN) | 2365–2369, 2530–2531 |
| 33 | flux `(O−E)²/E` = χ² = α-divergence (α=3) = Tsallis q=2 = Bregman | CURRENT (PROVEN) | 2399–2403 |
| 34 | Edge weight sits at the α-layer, one rung BELOW KL (`χ² ≈ 2·KL` 2nd-order only) | CURRENT | 2405–2408 |
| 35 | Wedge = circulation / time-irreversibility with reversal null | CURRENT (PROVEN) | 2229–2234, 2437–2440 |
| 36 | Rotor needs a null (Granger/lead-lag, no null distribution) | UNTESTED (actionable) | 2218–2220 |
| 37 | Wedge = direction functor (category theory) | CURRENT (PROVEN) | 2465–2469 |
| 38 | Edge = internal hom of a Lawvere metric space | CURRENT (PROVEN) | 2476–2478 |
| 39 | Sign of O−E = Booleanisation | CURRENT (PROVEN) | 2500–2504 |
| 40 | Quantum-on-classical = structural isomorphism + speedup | RETIRED (data-layout coincidence, inert, no BQP advantage) | 882–883, 1986–1994, 2533–2543 |
| 41 | ℂ^{2³²} = Cartan subalgebra of Cℓ₀,₃₂; structure real iff Clifford product used | CURRENT (PROVEN, conditional) | 2274–2280, 2541–2543 |
| 42 | δ = (O−E)/E is the invariant core; four registers δ^k·E^p | CURRENT | 1842–1860, 3034–3050 |
| 43 | Gauge group R⁺/2^ℤ Abelian; "register shift = rotor" wrong | CURRENT | 3073–3075 |
| 44 | ρ = the genuine gauge (labels were backwards); ρ is frame not redundancy | CURRENT | 3067–3070, 3081–3082 |
| 45 | Store δ not r (r is gauge-variant) | UNTESTED (upgrade flagged) | 3071–3072, 3085 |
| 46 | ρ = Bregman projection / running coupling / singularity spectrum | RETIRED (all mis-categorized; ρ = survival CDF / reweighting / μ(λ)) | 2341–2344, 2414–2416, 2568–2571 |
| 47 | Legendre transform of ρ = missing mirror-map piece; Crouzeix `∇²φ·∇²φ*=I` test | UNTESTED (highest-value next step) | 2317–2321, 2428–2431, 2645–2651, 2715–2717 |
| 48 | c = L1/λ register-local invariant (spoken 14–16 / academic 25.6 / wiki 11.2) | CURRENT (measured) | 827–843 |
| 49 | Proper-frame residue P@50 = 1.000, P@500 = 0.992 (tail-CDF ρ) | CURRENT (measured, held-out) | 1360–1384, 1520–1537 |
| 50 | "Language has a metric; structure is geometric, not statistical" | CLAIM (from P@500 0.992) | 1539–1550 |
| 51 | Anti-lattice = Hodge dual | RETIRED (→ commutant M′) | 537, 2282–2283, 2688–2689 |
| 52 | Rotor = α=0 Levi-Civita / zero curvature | RETIRED (α=0 = curved Hellinger point) | 2323–2324, 2648–2651 |
| 53 | Geometric product = categorical composition / lattice IS a category | RETIRED (monoidal op; Lawvere metric space) | 2480–2484 |
| 54 | Repulsion (O<E) reproduces / anti-lattice negatives meaningful | REFUTED (sampling noise, P=0.000) | 1671–1675, 2452–2454 |
| 55 | Ring = Hölder exponent | CORRECTED (Zipf exponent = Hölder; ring on Lq side) | 551, 2553–2555 |
| 56 | Polarization second-order register `(f(a)²−f(b)²)/T²` | UNTESTED (open, decide by held-out) | 439, 1776–1779 |
| 57 | Hexagon conjecture (lattice = hexagonal packing of semantic manifold; E=mc²) | SPECULATION/UNTESTED ("documented for later refactor investigation") | 626 |
| 58 | Superfluid-spacetime / quantum-on-classical "squish space" conjecture | SPECULATION/UNTESTED (flagged) | 1996–2028 |
| 59 | Multi-project memories → frame dilation as project distance | SPECULATION (deferred) | 1506–1518 |
| 60 | Gauge = the unit (Gaussian/Eisenstein integer lattices; simplex Aₙ) | SPECULATION (gauge-int experiment planned) | 2821–2844 |
| 61 | e^(1/e) = dimensionality normalisation; SIMD gauges | CLAIM/UNTESTED (TODO A8/F10) | 2985–3012 |
| 62 | Curvature routing (spend deep compute on negative-curvature edges) | NEW/UNTESTED (adoptable idea from chat survey) | 2789–2795 |

---

*Map-pass complete. This graph is the map; the lens pass (stage 2) would recheck it against the lattice-math framework and the "proved vs still-ours" verdicts of the file's own surveys.*
