# Gauge-Unification Seed — 2-pass survey of `chat-session-gauge-unification.md`

**Surveyed by:** research agent (Tau Architecture rebuild), 2026.
**Source read end-to-end:** `/home/ian/opencode/parser/english/docs/surveys/chat-session-gauge-unification.md`
(136 lines, 10,273 bytes) — a survey of the **raw** 31-turn solo derivation
`/home/ian/opencode/parser/english/docs/chat session/chat session blah.txt` (11,869 lines).
Both were read for this pass: the survey end-to-end, and the raw chat's load-bearing turns
(L8043, L9651, L9954, L10830, L11070, and the AI's completion L11120–11441) read in full so
the "derivation" is reproduced from the primary text, not from the survey's condensation.

**Method:** PASS 1 = Map (description only, extract every derivation step). PASS 2 = Lens
(calibrate every step DIRECT / ANALOGY / OURS / SPECULATION against the rebuild). Calibration
is done *at mapping time* (learning-method rule 1), not deferred to the lens pass.

**Cross-checked against (all read in full):**
- `HEXAGON_LATTICE_PLAN.md` (172 lines) — the plan.
- `GAUGE_VARIANTS.md` (324 lines) — the calibration cheat-sheet / knowledge graph.
- `proofs/lean-src/hexagon/Hexagon/ConventionBridge.lean` (69), `Haar.lean` (133),
  `ChiSquareGauge.lean` (73) — the three gauge files named in the brief.
- Provenance chain via `ox alpha.md` (L3109 = TODO #16), `survey/oxalpha_lens.md` (L151),
  `survey/oxalpha_graph.md` (L396), `docs/REBUILD_SURVEY.md` (L33, L93, L97, L113, L295),
  and `patches/gauge_int.rs` (the Signature POC).

---

## PASS 1 — MAP (what the source actually says)

### 1.0 What the document is

It is **not** the raw chat. It is a *survey of* `chat session blah.txt`, itself the product of a
prior two-subagent pass ("one graphed the contents, one mapped every concept against our lattice
system"). So we are surveying a survey-of-a-chat. The raw chat is a solo derivation with an LLM
interlocutor whose visible output interleaves (a) an "Analyze/Deconstruct/Structure the Response"
scratch pad and (b) the polished reply. The **user's** lines are the actual insights; the **AI's**
lines name them (often correctly) and supply the standard-math labels (Eisenstein integers, root
lattices Aₙ/Bₙ, geometric algebra, Lipschitz/Hurwitz quaternions).

### 1.1 The 31-turn arc (compressed)

| Turn | Insight | What it actually establishes |
|---|---|---|
| 1–7 | gauge symmetry of `(a−a²)/2` (`a→1−a` = attract/repel); `(a−aᵇ)/2`; "parabolas hide Euler's e"; e is on the *base* not the exponent | The e-vs-χ duality: e = derivative-invariant (repeating change), χ = topological invariant (V−E+F). No lattice yet. |
| 8–9 | e/χ = the symmetric/antisymmetric halves of the geometric product; τχ = total rotation | Connects Euler's number to Clifford sym/antisym decomposition. |
| 10–12 | fractal dimension = continuous grade; scale↔dimension duality (Mellin/Γ); constant density / gauge covariance | "gauge = dimensionality" theme. |
| 13 | operators = rotations/weighted edges; `÷2 = rotate`; `a·b + a²+b²` = stats+trig+gauge | First "operator as edge/rotation" move. |
| 14 | **edge is the primitive, not the node** (L8043) | Ontology move: difference = vector; swap = −1 (180°). |
| 15–16 | zero-summing pair `−1+1` builds "2"/3D? swap = anticommutation = spinor; `a²+b²=c²`; complex = time | Spinor + metric of two edges. |
| 17 | **gauge = the unit** ("gauge of the gauge"); **square binary** = two orthogonal integers, no floats (L9651) | The Signature idea first surfaces: replace floats with Gaussian-integer pair. |
| 18 | scalar = c-edge of a Gaussian integer; trivector = 3-axis Gaussian integer; **gauge indistinguishable from the unit, a property of it** (L9954) | "gauge variants = category operators + geometric primitives." |
| 19 | patch set 3; cubic math becomes linear; RISC-V vectors ~100× | Hardware framing. |
| 25 | **Eisenstein**: the unit = the equilateral-triangle distortion (L10830) | The triangular lattice replaces square. |
| 26 | **climax**: least action requires such a unit; triangle = artifact of two integer edges; "L2 norm by addition"; "Einstein edge"; n-dimensional triangle; a **unified set** computing both (L11070) | The thesis sentence the brief quotes. |

### 1.2 The load-bearing derivations, verbatim-ish, in order

**D1 — edge-as-primitive (L8043, user):**
> "the basic unit needs to be the edge not the node … we accumulate difference which we can get
> the rotation and addition and subtraction as the differences between them, no operator needed …
> unless the only number that exists is a 1 and a 0 … then all the math emerges."

*Map:* the AI names this "relational/edge ontology", "the vector is B−A", "swap = −1 (180°)". No
theorem; an ontological claim + the observation that an oriented edge carries magnitude+direction.

**D2 — gauge = the unit / square binary (L9651, user):**
> "we use gauge as a change, but then gauge may be the unit then … to transform them we use the
> gauge of the gauge … the curve of a floating point number may be better served by two orthogonal
> integers as the basic unit … then we would not need floats."

*Map:* AI glosses "gauge of the gauge" = curvature `F = dA + A∧A`; "square binary" = Gaussian
integers ℤ[i]; "two orthogonal integers" = the pair (a,b). The *unit's own multiplication table* is
posited as the gauge.

**D3 — scalar = c-edge; trivector = quaternion; gauge indistinguishable from unit (L9954, user):**
> "the scaler is the c edge of the gaussian integer … a trivector would be a gaussian integer with
> three axis … the gauge would be indistinguishable from the unit and a property of it … the gauge
> variants are category theory operators … and geometric primitives."

*Map:* AI maps trivector → Lipschitz/Hurwitz quaternion (the even subalgebra of Cℓ₀,₃), and
"gauge as property of the unit" → lattice gauge theory / spin networks (edge = holonomy).

**D4 — the Eisenstein step (L10830, user):**
> "the unit would be the equilateral triangle distortion … one triangle added to another makes
> custom curves … it is not just a speed up … it is categorically different."

*Map:* AI names Eisenstein integers, gives ω²+ω+1=0 **and** ω=e^{iπ/3} (see the error in §2.1),
norm a²−ab+b², 6-fold vs 4-fold isotropy.

**D5 — the climax, "least action → triangular" (L11070, user):**
> "least action has to make up the universe, in order to have that we would have to use a unit that
> can actually use that … the triangle is the artifact of the edges of two integers … the l2 norm by
> addition … love the einstine edge … more an n dimensional triangle … which could compute both sets
> on its own … so a unified set is good."

*Map (the AI's explicit rendering, L11168–11441):*
1. least action ⇒ a particle takes the path of least resistance ⇒ shortest path = sum of edge lengths.
2. Square grid: shortest path (0,0)→(1,1) is √2 (diagonal) ⇒ "action changes depending on angle" (anisotropic).
3. Triangular grid: 6 directions all length 1 ⇒ "action is perfectly isotropic".
4. **Conclusion (asserted, not derived):** "the triangle is the minimal edge configuration required
   for the principle of least action to work without angular biases."
5. "L2 norm by addition": hex distance = `max(|a|,|b|,|a+b|)` (cube coords), integer add/compare only.
6. "n-dimensional triangle" = simplex; square↔triangle duality = root lattices Bₙ (cubic) vs Aₙ (simplex).
7. "unified set" = a Clifford algebra with a *freely chosen quadratic form* — "switch gauges by
   redefining the dot product"; concretely a `Signature`/`GAUGE_TYPE` compile-time switch.

### 1.3 The concept graph (the survey's own §3)

The survey condenses the nodes and load-bearing edges. Key edges (all asserted by the chat, none
proved there):
```
power-curve differences ──motivates──▶ factorials → e
e ──is-dual-to──▶ χ (derivative-invariant vs topological-invariant)
e/χ ──is-special-case-of──▶ geometric product (symmetric/antisymmetric)
edge-as-primitive ──contradicts──▶ point/particle ontology
a²+b²=c² ──derives-from──▶ two perpendicular edges
gauge-of-the-gauge ──generalizes──▶ gauge-as-change (F=dA+A∧A)
Gaussian integer ──derives-from──▶ gauge = the unit
Eisenstein/triangular ──is-dual-to──▶ Gaussian/square (6-fold vs 4-fold)
n-simplex (Aₙ) ──generalizes──▶ triangle (2D → nD)
unified set ──generalizes──▶ both square and triangular via one gauge switch
```

---

## PASS 2 — LENS (calibrate every step against the rebuild)

### 2.1 The convention error the chat makes, and that WE already fixed

The raw chat (L10935–10949) and the survey's mapping table ("Eisenstein triangles
`ω²+ω+1=0`, 60°") state **both** `ω²+ω+1=0` **and** `ω=e^{iπ/3}` for the same object. These are
**incompatible**: `ω=e^{iπ/3}=(1+i√3)/2` satisfies `ω²−ω+1=0` (the **60°** convention, norm
`a²+ab+b²`); `ω²+ω+1=0` is `ω=e^{2πi/3}` (the **120°** convention, norm `a²−ab+b²`).

Our rebuild **caught and corrected this** — `HEXAGON_LATTICE_PLAN.md` §3 pins `ω=e^{iπ/3}`,
`ω²=ω−1`, `N=a²+ab+b²`, and explicitly names the *other* convention as the alternative; and
`ConventionBridge.lean` **proves** the two are the same ring via `φ(a,b)=(a,−b)` (`phi_mul`,
`norm_preserved`, `phi_phi`). This is a genuine lens-pass win: the seed document's climax carries a
notation collision, and our ledger's C1 theorem is precisely the fix. **Calibration: our
convention choice is DIRECT and PROVED; the chat's is a genuine (uncorrected) error.**

### 2.2 The four tasks, answered

#### Task 1 — Does it REALLY derive the Eisenstein lattice from least-action?

**No. It does not derive it.** The "derivation" is a 2-line assertion plus an isotropy gloss. The
full logical content is D5 above. Reproduced key steps and their status:

| Step | Status |
|---|---|
| "least action ⇒ shortest path = sum of edge lengths" | restatement, not derivation (this is the *definition* of a geodesic on a graph, not a theorem) |
| "square grid diagonal is √2 ⇒ anisotropic" | **DIRECT**, classical, true |
| "triangular grid: 6 equal-length directions ⇒ isotropic" | **DIRECT**, classical, true |
| "isotropy ⇒ least action requires the triangle" | **non-sequitur** — least action is a variational principle (stationarity of an action functional); it does NOT imply a grid, let alone an isotropic one. The step is an evocative *framing*, not a derivation. |
| "L2 norm by addition" (hex dist = max(\|a\|,\|b\|,\|a+b\|)) | **DIRECT**, classical (cube-coordinate hex metric) — but the chat *conflates* it with the Eisenstein norm `a²+ab+b²` (a squared length, multiplicative), which is a *different* quantity |
| "n-dimensional triangle = simplex; Aₙ vs Bₙ root lattices" | **DIRECT** (classical naming), supplied by the AI, not derived by the user |
| "unified set = Clifford algebra with a free quadratic form" | **DIRECT** (classical: Cℓ(p,q) is parametrized by a quadratic form) — but "one gauge switch computes both square and triangular" is the *Signature-enum* idea, which is a data-structure claim, not a theorem |

There is **no** Euler–Lagrange equation, **no** action functional, **no** variation, **no** geodesic
computation anywhere in the raw chat. The phrase "least action requires a triangular/Eisenstein
integer lattice" is the user's *felt* synthesis, elevated by the AI into a publishable-sounding
thesis. **Calibration of the headline claim: SPECULATION (as a derivation) resting on a DIRECT
(isotropy) and a DIRECT (hex metric) classical fact.** The *correct* sentence is: "a hexagonal grid
is more isotropic than a square grid, and its metric is an integer max-norm" — which is true and
known, but is **not** implied by least action.

#### Task 2 — Is it the actual seed of our plan? Borrowed or independently re-derived?

**Partially, and the borrowing is documented — not independent re-derivation.**

Provenance chain (verified in this pass):
```
chat session blah.txt (2026-08-25, 11,869 lines)
   └─ surveyed as chat-session-gauge-unification.md
        └─ ox alpha.md L3109 = TODO #16 "Gauge-int / Eisenstein lattice"
             (explicitly marked "NEW (from docs/chat session/chat session blah.txt,
              survey in docs/surveys/chat-session-gauge-unification.md)")
             ├─ HEXAGON_LATTICE_PLAN.md §1 (folds in TODO #16)
             └─ GAUGE_VARIANTS.md §6 Q3 ("the conversation's one genuinely new idea")
```

So the "gauge-int / Signature `i²∈{−1,+1,0,ω}` / gauge = property of the unit" idea **is borrowed**
from the blah chat, and the borrowing is *explicitly cited* in the repo (`ox alpha.md` L3109).
We did **not** re-derive it.

**But** the hex-lattice *plan* has a second, sibling source: `HEXAGON_LATTICE_PLAN.md` §0–§1 names
`hexigon_conversation.md` ("the Tau Architecture thread") as its primary source — and that is a
**different** conversation (15,635 lines). I checked the two against each other: the blah chat's
climax phrases (`"least action has to make up"`, `"gauge of the gauge"`, `"square binary"`,
`"unified set"`) have **zero** occurrences in `hexigon_conversation.md`, while `hexigon_conversation.md`
carries the balanced-ternary ↔ 7-hex bijection, the Z₆ mod-6 rotation, and the "Tau Architecture"
name — which the blah chat does not. So the project reached the Eisenstein lattice **twice, via two
independent routes**:
1. **hexigon thread** → balanced-ternary triples ↔ hex cells → Z₆ rotation (the *plan's* spine).
2. **blah chat** → least-action → isotropy → Eisenstein + "gauge = unit" → Signature enum (the
   *gauge-int* spine, TODO #16).

The claim in `docs/REBUILD_SURVEY.md` L295 that the gauge-unification survey "**is the seed of the
hex-lattice plan**" is therefore **overstated by half**: it is the seed of the *gauge-int/Signature*
sub-plan, not of the *balanced-ternary/hex-cell* sub-plan. And critically, the **least-action
framing was dropped**: `HEXAGON_LATTICE_PLAN.md` never invokes least action; it justifies the
Eisenstein lattice by (a) the ternary bijection, (b) the Z₆ integer rotor, and (c) exact integer
arithmetic. **We imported the gauge-int Signature idea and discarded the least-action derivation.**
Correct to call it "a seed", wrong to call it "the seed" or to say the plan re-derives it.

#### Task 3 — The "gauge-switchable set": our Z₆ ≅ Z₂×Z₃, or something more?

**Something more — Z₆ is only the Eisenstein case's unit group, one corner of it.**

- **Our Z₆** = the unit group {±1,±ω,±ω²} of ℤ[ω] (the six 60° rotations). **DIRECT, PROVED**
  (`Rotation.lean` `units_card`/`units_closed_under_mul`; `Gauge.lean` `units_eq_omega_powers`,
  `omegaPow_six`). `Z₆ ≅ Z₂×Z₃` (cyclic order 6 ≅ product of coprime orders) is a classical group
  fact; the ledger proves the group *structure* (closure, inverses, 6 elements) but I did not find
  a separate `Z₆ ≅ Z₂×Z₃` theorem — it is implied, not stated as a named lemma.
- **The chat's "gauge-switchable set"** = the *four-signature* `Signature {Gaussian i²=−1,
  Eisenstein ω²=ω−1, Minkowski j²=+1, Null ε²=0}` — the claim that **one** integer-pair data
  structure `(a,b)` computes **four different rings** by swapping the unit's multiplication table.
  This is exactly `patches/gauge_int.rs`'s `enum Signature` + `gauge_mul = (ac−s·bd, ad+bc)`.
  **Calibration:** POC-coded, but **SPECULATION beyond the Eisenstein case** — `GAUGE_VARIANTS.md`
  §6 Q1 states plainly the four signatures are *genuinely different rings* (Z₄ vs Z₆ vs (Z₂)²-esh
  vs trivial unit groups; domains vs zero-divisors vs nilpotents) and "what exactly distinguishes
  them … is not yet stated as a theorem."

So the answer: the "unified set" is a **superset** of Z₆. Z₆ is what we have *proved* (the Eisenstein
unit group); the four-signature switchable set is what we have *POC-coded but not proved*, and its
central sub-claim — that square and triangular are "truly one object" via an algebraic map rather
than a compile-time flag — is **still open** (see §3.2, open #2).

#### Task 4 — Lean-provable identities vs open derivations

See §3.1/§3.2. Summary: the *arithmetic* the chat gestured at (Eisenstein ring, norm, Z₆, 60°↔120°
bridge, δ-vs-χ² gauge, Z₆ Haar invariance) is **now proved in our ledger**; the *derivations* the
chat *claimed* (least-action→triangle, square≡triangle-as-one-object, n-dimensional Aₙ root lattice,
integer-lattice↔residual bridge) are **open**, and several are **not even well-posed**.

---

## 2.3 The detailed map (calibrated at mapping time)

Legend: **DIRECT** = same math, proved in ledger or classical; **ANALOGY** = parallel structure,
different object; **OURS** = our object/framing on one side only; **SPECULATION** = unproved both
sides. *(This table extends the source survey's §4 table, re-calibrated against the current ledger.)*

| Conversation concept | Calibration | Our counterpart (verified) |
|---|---|---|
| gauge symmetry of `(a−a²)/2`, `a→1−a` flip | DIRECT→ANALOGY | `Registers.lean` `δ = O/E−1`; the "−1 flips sign" is δ's gauge normalization |
| e = derivative-invariant | OURS | rebuild's rotor `exp(r_bwd−r_fwd)`; "Euler = correction between gauges" (AGENTS.md) |
| χ = V−E+F (Euler characteristic) | **OPEN / not computed** | no Euler-characteristic file in the ledger; only the residual's loop-polarity analogue |
| geometric product = symmetric + antisymmetric | DIRECT (now proved) | `DotWedge.lean`/`SymDot.lean` + `Registers.lean` `sym_plus_skew`, `wedge_antisymm` |
| spinor / swap = anticommutation | DIRECT | `Rotation.lean`; rotor θ/2; the Z₆ rotor realizes ψ=(α+βI)U in mod-6 |
| edge-as-primitive | OURS (canonical truth) | "stored primitive is the signed residual r=O−E" (AGENTS.md) |
| **gauge = the unit / Signature i²∈{−1,+1,0,ω}** | **SPECULATION (POC-coded)** | `patches/gauge_int.rs` enum `Signature`; `GAUGE_VARIANTS.md` §6 Q3 — not proved beyond Eisenstein |
| Gaussian integer (integer pair, 90°) | DIRECT (classical, external) | `GAUGE_VARIANTS.md` §2 row 1 — standard ℤ[i], cited not ported |
| square binary (no floats, full integer geometric product) | OURS→POC | `gauge_int.rs`; `simd.rs`/`cosine.rs` integer cos² generalized to (ac−s·bd, ad+bc) |
| Eisenstein triangle (60°, ω²=ω−1) | **DIRECT — PROVED** | `Conventions.lean` (T0/T1), `EuclideanDomain.lean` (T5), `Gauge.lean` (G1) |
| norm a²+ab+b² | **DIRECT — PROVED** | `Conventions.lean` `norm_mul`; `Gauge.lean` `norm_eq_det`, `norm_mul_unit` |
| Z₆ units | **DIRECT — PROVED** | `Rotation.lean` `units_card`, `units_closed_under_mul`; `Gauge.lean` `units_eq_omega_powers` |
| 60°↔120° = same ring | **DIRECT — PROVED** | `ConventionBridge.lean` `phi_mul`, `norm_preserved`, `phi_phi` (φ(a,b)=(a,−b)) |
| counting measure = Haar for Z₆ | **DIRECT — PROVED** | `Haar.lean` `unit_inv`, `mul_unit_bijective`, `sum_invariant`, `units_counting_normalized` |
| δ invariant, χ² scales (count↔prob gauge) | **DIRECT — PROVED** | `ChiSquareGauge.lean` `fold_gauge_invariant`, `surprise_scales`, `fold_eq_surprise_div` |
| hex distance = integer max-norm | **DIRECT — PROVED** | `GraphDistance.lean` `honeycomb_dist_eq_hexDist`; `HexDisk.lean` |
| 7-hex ↔ balanced ternary | **DIRECT — PROVED** | `SevenHex.lean` `hexCells_card`, `balanced_iff_mem` |
| hex cell ↔ u32 (Szudzik pairing) | **DIRECT — PROVED (bijection only)** | `Bijection.lean` `hexPairEquiv`, `toNat_bijective` |
| τ = 2π packing density number | **DIRECT — PROVED (number identity)** | `Packing.lean`; Thue optimality *cited*, not proved |
| **least action ⇒ triangular lattice** | **SPECULATION (not a derivation)** | *no Lean target; dropped from the plan* |
| **square ≡ triangle as one algebraic object** | **SPECULATION / OPEN** | `ConventionBridge` proves E₆₀⇄E₁₂₀ only; ℤ[i]⇄ℤ[ω] unproved (different rings) |
| **n-dimensional triangle (Aₙ simplex vs Bₙ cubic)** | **SPECULATION / OPEN** | ledger is 2D Eisenstein only; no Aₙ root-lattice file |
| trivector = quaternion (even subalgebra Cℓ₀,₃) | OURS→POC | `gauge_int.rs` header cites even_part()+rotor() as TODO #13's semantic |
| complex = time | OURS | `eigen_bench.rs` H=S+iW (imaginary = time) |
| integer lattice ↔ co-occurrence residual | **FORBIDDEN to conflate** | hex norm ≠ ring guardrail (plan §2.1); the bridge is unproven |

---

## 3.1 Lean-provable / proved identities (the parts the chat pointed at that are now checked)

| # | Identity | File / theorem | Status |
|---|---|---|---|
| 1 | ℤ[ω] is a ring, `(a+bω)(c+dω)=(ac−bd)+(ad+bc+bd)ω` | `Conventions.lean`, `Haar.lean` `mul_assoc`/`one_mul` | PROVED |
| 2 | N(a+bω)=a²+ab+b² multiplicative, N=0 iff x=0 | `Conventions.lean` `norm_mul` | PROVED |
| 3 | N = det of the regular representation (area scalar) | `Gauge.lean` `norm_eq_det` | PROVED |
| 4 | units are exactly ±1,±ω,±ω²; six of them; closed under mul | `Rotation.lean`, `Gauge.lean` `units_eq_omega_powers`, `omegaPow_six` | PROVED |
| 5 | norm invariant under units (isotropy) | `Gauge.lean` `norm_of_unit`, `norm_mul_unit`, `norm_unit_mul` | PROVED |
| 6 | 60° ⇄ 120° = same ring, φ(a,b)=(a,−b) | `ConventionBridge.lean` `phi_add`/`phi_mul`/`phi_phi`/`norm_preserved` | PROVED |
| 7 | Z₆ is a group (every unit has a unit inverse) | `Haar.lean` `unit_inv` | PROVED |
| 8 | counting measure is Z₆-invariant (finite-group Haar) | `Haar.lean` `sum_invariant`, `measure_invariant_card`, `units_counting_normalized` | PROVED |
| 9 | δ=O/E−1 invariant under count↔prob gauge; χ² scales by c | `ChiSquareGauge.lean` `fold_gauge_invariant`, `surprise_scales`, `fold_eq_surprise_div` | PROVED |
| 10 | residual register ladder r/δ/z/s; wedge antisymmetry | `Residual.lean`, `Registers.lean` | PROVED |
| 11 | 7-hex ↔ balanced-ternary bijection | `SevenHex.lean` | PROVED |
| 12 | hex metric = max-norm | `GraphDistance.lean` | PROVED |
| 13 | hex cell ↔ u32 (Szudzik pairing) | `Bijection.lean` | PROVED (bijection; *replacement* of XOR kernel blocked) |
| 14 | τ/π packing-density number identity | `Packing.lean` | PROVED (number); Thue optimality cited |

## 3.2 Open derivations (what is NOT formalized — the honest gap)

| # | Open item | Where it lives | Why open |
|---|---|---|---|
| 1 | **least-action ⇒ triangular lattice** | chat D5 | Not a derivation (isotropy ≠ variational principle). No well-posed Lean statement. Dropped from the plan. |
| 2 | **square ⇄ triangular as ONE algebraic object** (algebraic map a²+b² ↔ a²+ab+b², not a compile-time flag) | chat §5 open thread #2; `GAUGE_VARIANTS.md` §6 Q1 | ℤ[i] and ℤ[ω] are genuinely different rings (Z₄ vs Z₆). Only E₆₀⇄E₁₂₀ is proved. |
| 3 | **four-signature algebra as a single "gauge variant" theorem** | `GAUGE_VARIANTS.md` §6 Q1 | Only i_ω proved; i₋₁ classical/external; i₊₁/i₀ ANALOGY. |
| 4 | **normalization of dimensional translation** (÷factorial vs ÷metric-determinant vs τ) | chat §5 open thread #1 | Unresolved; no Lean target. |
| 5 | **"÷2 = rotate 46°" vs rapidity ln2≈39.7°** | chat §5 open thread #3 | Unresolved (the chat itself flags it as wrong). |
| 6 | **integer lattice ↔ co-occurrence residual mapping** | chat §5 open thread #4 | Explicitly **FORBIDDEN** to conflate (hex norm ≠ ring, plan §2.1). The deep bridge is unproven and must stay separate. |
| 7 | **n-dimensional triangle / Aₙ root lattice** | chat D5 | Ledger is 2D Eisenstein; no Aₙ/Bₙ file. "n bytes per dimension" is hardware, not math. |
| 8 | **χ = V−E+F (Euler characteristic) as the "χ" in e/χ duality** | survey §4 row | Not computed anywhere in the rebuild; no ledger file. |
| 9 | **polarization axis** (third axis, f(a)/f(b)−f(b)/f(a)) | rebuild `statistics.rs` | Asserted in code, port candidate #9, no Lean. (This is the rebuild's, not the chat's.) |
| 10 | **hex addressing *replaces* the u32 XOR kernel** | `Bijection.lean` header | Bijection proved; the replacement claim is SPECULATION/blocked (plan §2.2, `GAUGE_VARIANTS.md` §6 Q5). |

---

## 3.3 What the seed gave us that we DID formalize (and what we did NOT take)

**Taken and formalized (now DIRECT):** the Eisenstein ring ℤ[ω]; the norm a²+ab+b²; the Z₆ unit
group; the 60°↔120° convention bridge (fixing the chat's own ω²+ω+1=0 vs ω=e^{iπ/3} error); the
gauge-as-unit *idea* as the `Signature` enum in `gauge_int.rs`; the integer-pair data structure
(replacing the float rotor); the "c-edge" reading of the scalar as the norm.

**Taken but NOT formalized (SPECULATION/POC):** the four-signature "unified set" as *one* object;
the square≡triangle algebraic identity; the n-dimensional Aₙ generalization.

**NOT taken (dropped or retired):** the least-action derivation itself (replaced by the ternary
bijection + Z₆ rotor justification); "quantum speedup" and "exponential speedup" language
(author-confirmed suspicion, retired per plan §2.4); the silicon/energy claims (out of scope).

---

## TODO / not covered / caveats

- **The source is a survey-of-a-chat, and I read the raw chat's load-bearing turns (L8043–L11070)
  but not all 11,869 lines verbatim.** The derivation steps are reproduced from the primary text's
  climax and the survey's condensation; the 20–24 "meta/humility" turns and turns 1–7 (e/χ) were
  taken from the survey's turn-table, not re-read word-for-word. If a word-level audit of turns 1–12
  is needed, read `chat session blah.txt` L1–L8030 directly.
- **I did not attempt `lake build`** to re-confirm the PROVED statuses; they are taken from the file
  headers + `GAUGE_VARIANTS.md` + `proofs/INDEX.md`, which I did not re-run. The three files named in
  the brief (`ConventionBridge`, `Haar`, `ChiSquareGauge`) I read in full and their headers claim
  `lake build` green with zero `sorry` — accepted as recorded, not independently rebuilt.
- **`Z₆ ≅ Z₂×Z₃`** is implied by the ledger (Z₆ proved cyclic of order 6) but I found **no** named
  `Z₆ ≅ Z₂×Z₃` theorem; if the brief wants that isomorphism *named*, it is a two-line add to
  `Rotation.lean`/`Gauge.lean`.
- **The "χ = V−E+F" Euler characteristic** is the one node in the chat's e/χ duality that has **no**
  rebuild home (survey §4 marks it NEW; I confirmed no ledger file). Worth a decision: is the
  graph's Euler characteristic a real gauge-invariant for the residual graph, or is it a
  terminology collision with the χ² divergence? (learning-method rule 4: resolve the collision
  first — "χ" in the chat is V−E+F, "χ²" in our canonical truth is the L2 norm; these are unrelated.)
- **Terminology collision flagged but not resolved here:** "least action" in the blah chat (physics
  geodesics/isotropy) ≠ "least action / constant action" in the rebuild's canonical truth (speech
  Lagrangian ∫L held constant, `T=ring/2`). The brief's "least action" is the chat's physics sense;
  do not conflate the two in the plan.
- **The "SEED" claim is itself a project artifact** (`docs/REBUILD_SURVEY.md` L113/L295). This
  survey re-verifies it is the seed of the *gauge-int/Signature* sub-plan only; the hexagon plan's
  other seed is `hexigon_conversation.md`. A fuller seed-audit would diff the two chats'
  contributions line-by-line — not done here (that is a separate survey).
