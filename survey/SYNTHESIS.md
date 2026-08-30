# Synthesis — "Einstein triangle" & "hexagonal causal lattice" vs the rebuild

Survey of two files, two rounds (map → lens), per the graph-survey method in
`/home/ian/opencode/parser/english/AGENTS.md`. Inputs:

- `/home/ian/dsh/projects/lattice/hexigon_conversation.md` (15,635 lines) — a multi-day
  human↔AI chat that opens on gauge symmetry of `(a−a²)/2` and ends as the "Tau Architecture"
  spec (balanced ternary + Eisenstein 60° lattice + fractal memory).
- `/home/ian/opencode/parser/english/AGENTS.md` (3,094 lines) — the project's canonical
  lattice-math framework ("the rebuild": `build_causal`, signed residual `r = O−E`).

Round-1 artifacts: `survey/hexigon_graph.md` (80 nodes, ~90 edges, 24 counter-to edges),
`survey/agents_graph.md` (~150 nodes, ~130 edges, 48 reversals).
Round-2 artifacts: `survey/hexigon_lens.md`, `survey/agents_lens.md`.

---

## 0. The naming reality check (read first)

Neither "Einstein triangle" nor "hexagonal causal lattice" is a literal term in either file.

- **"Einstein triangle" = the Eisenstein integer lattice** `ℤ[ω]`, `ω = e^{iπ/3}` — the 60°
  triangular/hexagonal lattice (integer norm `a²+ab+b²`, hex max-norm). "Einstein" is a
  name-collision/pun: AGENTS.md itself files an "Eisenstein/Einstein frame" note as
  SPECULATION (L1506–1518). The conversation builds this into a full hardware spec it calls
  the **Tau Architecture** (balanced ternary + Eisenstein lattice + 7ⁿ fractal memory +
  Riemann-sphere closure).
- **"hexagonal causal lattice" = one sentence.** The word "causal" appears exactly once
  (conversation L12393): the **60° light cone** inside a Regge-calculus passage claiming
  "edge weights = the metric tensor" and "pentagon = +60° deficit (black hole),
  heptagon = −60° (dark energy)" (L12376–12551). AGENTS.md has no light cone and no 60°.

## 1. The one discovery that reframes everything

**The two files are a single thread.** AGENTS.md's "Chat-session survey #2 — 'gauge = the
unit'" (L2821–2844) is the project's *own record of this exact hexigon conversation* (31 turns,
"a solo derivation"). The arc matches: gauge of `(a−a²)/2` → e vs χ → geometric product →
edge-as-primitive → spinor → Gaussian integers → Eisenstein triangles → simplex Aₙ.

Consequence: the "Eisenstein triangles" hunt target in AGENTS.md is **not an external fact** —
it is the project's landing note on this conversation, already carrying a plan
(`gauge-int` experiment + a `Signature` axis + store the spinor as integer `(E,w)`). The
framework has *already* filed the conversation's "gauge = the unit" claim as a SPECULATION.

## 2. The four calibration verdicts

Verdicts are DIRECT (same math) / ANALOGY (parallel structure, different object) / OURS
(one side only) / SPECULATION (unproven on both).

### Q1 — Einstein triangle (Eisenstein lattice) vs the rebuild's u32 hypercube + ring bands + integer register → **ANALOGY**

- Conversation: a **planar** 6-fold A₂ tiling, mod-6 rotation arithmetic, balanced-ternary
  neighbor encoding, 7ⁿ page-table hierarchy.
- Rebuild: the **32-dim Boolean hypercube `(Z₂)³²`** with XOR kernel `g[i⊕j]`; "ring" is a
  **statistical** χ² divergence / L2 norm, not a geometric ring; the "register" is a
  fixed-point value representation.
- Not DIRECT: different root structures (hex tiling ≠ Hamming cube); "ring bands" are
  frequency strata of co-occurrence stats, not geometric rings; the isomorphism the
  conversation needs (hex address ↔ u32 index) is asserted, never established.
- Not pure SPECULATION: the Eisenstein math is real and provable — it is just math about a
  *different* structure. The *upgrade claim* (hex addressing replacing the u32 kernel) is
  SPECULATION; the *structures* are ANALOGOUS.

### Q2 — gauge symmetry ("gauge is the page table", O→UOU⁻¹) vs gauge = register = ring shift → **ANALOGY**, with two sharp sub-points

- "Gauge" does **five different jobs** in the conversation (change-of-variable, exponential
  map, U-conjugation, page table/MMU layout, unit signature); the framework's gauge is a
  **statistical normalization** (Abelian R⁺/2^ℤ, invariant `δ = O/E − 1`).
- **DIRECT (algebra):** the conversation's `O→UOU⁻¹` conjugation *is* the framework's inner
  automorphism `x→RxR⁻¹` (L2261–2264) — same operation, but ACTIVE on the conversation side,
  INERT on the framework's grade-0 side.
- **Near-DIRECT:** "÷2 = rotation, rapidity ln2 ≈ 39.7°" (conversation) = the framework's
  log-space exponent correspondence / bit-shift = fixed-angle rotation.
- **Genuinely new:** the conversation's "gauge is indistinguishable from the unit — its
  signature `i² ∈ {−1,+1,0,ω}`" is a *third gauge position* the framework's Abelian gauge
  lacks. Already filed by the framework as SPECULATION (`gauge-int` + `Signature` axis).

### Q3 — hexagonal causal lattice vs build_causal's r=O−E + wedge skew → **NOT DIRECT (name collision, pointing opposite ways)**

- `r = O−E` and `build_causal` are **OURS** — the conversation has zero "residual", zero
  "O−E", zero "integer register", zero "causal.rs".
- The conversation's "wedge" is the GA **bivector** `a∧b` — which is exactly the object the
  framework **RETIRED as V3** ("wedge = |a∧b|", retired L990, L2678–2682). Porting it verbatim
  re-imports a dead over-claim.
- The conversation's "causal" (60° light cone) and the framework's "causal" (Rung-1
  association; "the sign/wedge is an orientation signal, never a causal arrow") are
  **contrary objects**. Bridging them resurrects the over-claim AGENTS.md exists to retire.
- The GR-from-edge-weights claim also **conflicts with N18**: the framework's edge residual
  is signed, asymmetric, `d(a,a)≠0` — explicitly **NOT a metric** — while the conversation
  needs symmetric metric edge weights `g_μν`.

### Q4 — what the conversation genuinely adds → two DIRECT confirmations, three SPECULATION candidates, one CONFLICT

**DIRECT (confirmations, not upgrades):**
1. "The basic unit is the **edge, not the node**" (conversation L8043) ≡ the framework's
   stored edge primitive `r = O−E`.
2. "Semantic search @ 0.023 ms, SQL-free" (conversation L15281) is the framework's **own**
   `lattice-lookup` measurement (AGENTS L196/L449/L507).

**SPECULATION candidates (each tagged):**
1. **Signature-valued gauge** ("gauge = the unit") — the framework's own filed `gauge-int`
   experiment + `Signature` axis; the one idea that adds a *new math dimension* to the
   rebuild's gauge theory.
2. **Balanced-ternary ↔ 7-hex bijection** (`q+r+s=0` ↔ 7 states) — PROVED by enumeration,
   Lean-provable as a one-page theorem; DERIVABLE as math, SPECULATION as a rebuild axis.
3. **Regge deficit-angle curvature** (pentagon +60° / heptagon −60°) — a ready-made template
   for the rebuild's *unbuilt* "holonomy / triangle-curvature statistic" (L3086); needs a
   metric edge object the framework explicitly rejects (N18).

**CONFLICT (not an extension):** hex norm `max(|a|,|b|,|a+b|)` ≠ ring = L2 = χ² divergence.
Adopting it would break `ring² = Σ(O−E)²/E`, the identity the canonical truth depends on.

## 3. How this relates to "the rebuild"

- The rebuild is `rust/lattice/src/build/causal.rs`: signed directional residual `r = O−E`,
  three axes (correlation / wedge-skew / polarization), ring = χ², integer fixed-point
  register, gauge = register = ring-shift (bit-shift RG, PROVEN 2-adic).
- The hexigon conversation **never touches that core**. Its hex/Eisenstein/gauge/causal
  content is the project's *own speculative elaboration* of three SPECULATION nodes already
  in AGENTS.md: the "Hexagon conjecture" (L626), "gauge = the unit" (L2821–2844), and the
  "Eisenstein/Einstein frame" (L1506–1518).
- The conversation **does** offer the rebuild two concrete, bounded experiments the framework
  already scoped: (1) a **signature-valued gauge** (`i² ∈ {−1,+1,0,ω}`), and (2) a **mod-6
  integer realization** of the even-grade spinor fix `ψ = (α+βI)U` — `Z₆ ⊂ SO(2)` is a
  discrete, exact, integer rotation group, which matches the rebuild's integer-only stack.
- Everything else is analogy, name-collision, or ours-on-one-side.

## 4. The standing caution — six terminological collisions

Before any downstream survey reuses either file, disambiguate: **wedge** (GA bivector vs skew
residual), **causal** (light cone vs Rung-1 orientation), **polarization** (ferroelectric state
vs radial-scale axis), **fixed point** (math theorem vs band-gap retirement), **ternary**
(balanced radix vs balanced Lagrangian), **rebuild** (FTS5 index vs lib rebuild).

## Bottom line

The two documents share a vocabulary and an ambition but **not a single theorem**. The only
hard bridges are (a) the `O→UOU⁻¹` conjugation (DIRECT as algebra, active-vs-inert) and (b) the
0.023 ms search cross-citation (DIRECT, same engine). "Einstein triangle" = the Eisenstein
integer lattice — ANALOGOUS to (not identical with) the rebuild's u32 hypercube — and
"hexagonal causal lattice" = a Regge-calculus light-cone speculation that *contradicts* the
rebuild's "edge is not a metric / causality is Rung-1" doctrine. The conversation's real value
to the rebuild is narrow and specific: a signature-valued gauge and a mod-6 integer spinor —
both already filed as untested experiments in AGENTS.md.

---

# Addendum — `ox alpha.md` (checked against this synthesis)

A third file, `/home/ian/dsh/projects/lattice/ox alpha.md` (5,805 lines, 8/23–8/27), was
surveyed after this synthesis was written. It is a chat between **Ian** and **ox-alpha** (later
DeepSeek V4 Pro) reviewing the repo's own `THEORY.md`/`docs`. Artifacts:
`survey/oxalpha_graph.md` (map, 120 nodes across IAN/OX/REPO voices) and
`survey/oxalpha_lens.md` (lens, 83-row calibration + 6 special targets).

## The Einstein/Eisenstein disambiguation (corrects §0 of this synthesis)

"Einstein triangle" is **not one term — it is three**, and this synthesis's §0 mapping only
holds for the *hexigon* thread:

1. **hexigon thread → the Eisenstein integer lattice ℤ[ω]** (60° hex lattice) — correct as
   mapped; framework anchor re-confirmed at ox alpha.md L3109 (TODO #16 "Gauge-int / Eisenstein
   lattice", `Signature i²∈{−1,+1,0,ω}`).
2. **ox alpha.md → Ian's own "einstine triagle" (L4996, the only occurrence)** = a private
   geometric-mean / proportionality triangle for computing the polar ratio `(O−E)/E` in
   integers, where `E = f(a)f(b)/T = G²/T` (G = the geometric mean = "the square of the
   polar"). Never defined; ox-alpha offers three candidate readings (L5052, none Eisenstein)
   and supersedes it: *"it needs no Einstein triangle — just one global division"* (L5093),
   via the marginal identity `Σ_b E_ab = f(a)` + scaled integer residual `N = O·T − f(a)f(b)`.
3. **Elsewhere, "Einsteinian"** = the test-only density-dilation frame `E·ρ(a)ρ(b)`
   ("do NOT productionize", L955, 3288–3292).

**Do not bridge the rebuild to the Tau Architecture through "Einstein triangle"** — the only
legitimate bridge is the already-filed `gauge-int`/`Signature` experiment (L3109).

## What this file adds — the "more speculation", triaged

**Genuinely new speculation (2):** (1) the **braided-monoidal-category reading of the wedge**
— the categorical distinction is real math, the application to the lattice is unverified
SPECULATION (braid/Yang–Baxter axioms asserted, never tested on data); (2) an **exposition-format
prediction** (list-form should measure higher ‖skew‖/‖sym‖ than prose) — cheap to test.

**Confirmed math (framework-consistent, now named):** Pearson-residual naming
(`z=(O−E)/√E`, `Var(O)=E ⇒ E[z²]=1` — explains the framework's own cross-fitting +1 bias and
surprise-register degeneracy); sparse-χ² `Σ(O−E)²/E = ΣO²/E − T` (O(edges) — Ian conjectured,
ox-alpha proved); the geometric square `ψ²=(α²−β²)+2αβI` (what `clifford.rs` already computes);
`E = f(a)f(b)/T` as the unique doubly-marginal table (Sinkhorn/IPF closed form).

**Bug-fix / the highest-value item:** Ian's "forgot column balancing" (L5099) is the *half-null
diagnosis* — it ties to the framework's own logged fwd/bwd port bug (L2931–2937). The sharpest
new test is two one-line assertions on every rebuilt lib: `Σ_b E_ab == f(a)`, `Σ_a E_ab == f(b)`.
Plus the **Birkhoff trap**: never doubly-stochastic-normalize (would destroy wedge + Zipf).

**Over-claims, all caught in-file:** "unify all of maths" → downgraded to *normal form* (Ian
himself first, then ox-alpha's LLVM/IR reframe); "quantum emulator / superposition speedup" →
retired (no BQP, classical late binding); repo-internal contradictions (THEORY #7 "physics =
information" vs README "possible unification"; N17 gate vs "N17 MOOT"); the million× speedup
still has no baseline.

## Four concrete, integer-native upgrades for the rebuild

1. **Marginal-invariant assertions** (`Σ_b E_ab == f(a)`, `Σ_a E_ab == f(b)`) as release-gate
   checks — de-risks the fwd/bwd Python port bug.
2. **Sparse-χ² global computation** `ΣO²/E − T`, O(edges), per-register.
3. **Register conformance audit** (E−O sign-flip hunt, pz/nz naming) before v5.
4. **"Compute in counts, display in probabilities" / "Lossiness is the real enemy"** as
   README thesis lines.

**One-sentence:** ox alpha.md is the framework talking to itself — every math claim is either
the framework's own (DIRECT, confirmed) or a standard-math name for it (DIRECT, extended); its
real gift is four small, integer-native, test-first items, the marginal invariants chief among
them.
