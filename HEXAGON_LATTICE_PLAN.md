# Hexagon Lattice Plan — Eisenstein ℤ[ω] + balanced ternary + Lean proofs

**Requested by:** Ian (direct reply to the ox-alpha lens pass, 2026).
**Sources folded in:** `hexigon_conversation.md` (the Tau Architecture thread), `survey/SYNTHESIS.md` (prior two-file survey verdicts), `survey/oxalpha_lens.md` (this file's own lens), `LATTICE_MATH.md` (the rebuild), ox alpha.md TODO #16.
**Status:** PLAN — calibrated, phased, first-three-tasks executable. Nothing here is claimed as built.

---

## 0. What we're building

The **hexagon lattice** = the **Eisenstein integer lattice ℤ[ω]**, ω = e^{iπ/3} — "the einstein triangles of 60 degrees": the triangular/honeycomb tiling whose unit cell is an equilateral triangle (60°) and whose packing of circles is optimal (hexagonal packing, density τ/(4√3) = π/(2√3) ≈ 0.9069, where τ = 2π — a full turn). Three promises, in increasing order of verifiability:

1. **Exact integer geometry** — ℤ[ω] arithmetic is pure integer pairs (a, b); no floats, no trig (angles are mod 6). This is *native* to the rebuild's integer-only register.
2. **Ternary emulation** — the hex cell (center + 6 neighbors = 7 states) is bijective with balanced-ternary triples (q, r, s) ∈ {−1, 0, +1}, q+r+s = 0. (Already PROVED by enumeration in the hexigon thread — this is the one-page theorem.)
3. **A mod-6 integer spinor** — the units ±1, ±ω, ±ω² form the rotation group Z₆ ⊂ SO(2): a discrete, exact, integer realization of the rebuild's even-grade spinor fix ψ = (α+βI)U. This is the **one DIRECT bridge** to the rebuild.

**"The old diamond lattice" — RESOLVED (author-directed search):** it is the project's own **causal-graph diamond motif** — `a→b, a→c, b&c→f` — the "universal motif" documented in the info-geometry notes (`~/opencode/parser/english/docs/info_geometry/lasttheory/how-to-simplify-the-causal-graph.md`, "Diamonds All the Way Down", 2026-08-05; the same event-collapse rule as the compression graph). It is "not old — just the current working versions": the parser used to be stack-based until the math replaced it. The hexagon lattice "overlaps" the diamond because **a diamond (rhombus) in the honeycomb is exactly two adjacent 60° triangles sharing an edge** — the diamond is the elementary two-triangle cell of the Eisenstein lattice, and the `a→b, a→c, b&c→f` motif is the causal reading of that cell (two inputs merging into one output through the shared 60° vertex). The plan therefore treats the hexagon as the lattice that *embeds* the project's diamond motif in integer geometry — and the Lean ledger should carry the diamond-doc provenance (see §4.3).

---

## 1. Where this already lives in the project (reuse, don't reinvent)

| Idea | Source | Line refs |
|---|---|---|
| Balanced-ternary ↔ 7-hex bijection (q+r+s=0; 27 → 7 states) | hexigon_conversation.md | L10005–10017; the one-page theorem statement L10105 |
| Mod-6 rotation = Z₆; "trig becomes modulo arithmetic" | hexigon_conversation.md | L10179–10197, 11248, 11397–11399, 11515, 11912–11949 |
| "Tau Architecture" name + full spec | hexigon_conversation.md | L14342–14461 |
| Three-project split: lattice-core / hex-mmu / lean-lang | hexigon_conversation.md | L15122, 15188, 15267 |
| Lean agent setup (proofs/ AGENTS.md, prover tooling) | hexigon_conversation.md | L9432–9563 (DeepSeek-Prover-V2, LeanTool); L9805–9806 |
| Hex norm (Lean target) | hexigon_conversation.md | L15537, 15622 |
| Synthesis verdicts: hex vs u32 = ANALOGY; bijection = PROVED; gauge-int = SPECULATION candidate | survey/SYNTHESIS.md | L50–62 (Q1), L92–111 (Q4), L113–126 (§3) |
| **TODO #16 gauge-int / Eisenstein lattice**: integer pair (a,b) + Signature i²∈{−1,+1,0,ω}, "gauge = a property of the unit" | ox alpha.md (REPO quote) | L3109 |
| The rebuild core to hook into | LATTICE_MATH.md | L6–28 (primitive, integer register, gauge = ring shift) |

---

## 2. Calibration guardrails (what this is NOT — the six lines to never cross)

1. **Hex norm ≠ ring.** The hexagon's max-norm / cube-distance (max(|q|,|r|,|s|)) is a *geometric* norm; the framework's ring is a *statistical* L2 = χ² divergence (`ring² = Σ(O−E)²/E`). Adopting the hex norm for the ring would break the identity the canonical truth depends on. **Keep ring for statistics, hex for geometry/addressing.** (SYNTHESIS Q4 CONFLICT.)
2. **Hex addressing ≠ the u32 XOR kernel.** The hex tiling is not the Boolean hypercube (Z₂)³²; the isomorphism hex-address ↔ u32-index is *asserted, never established*. The upgrade claim stays SPECULATION **until** we write the explicit bijection and prove the address translation in Lean. (SYNTHESIS Q1.)
3. **"Hexagonal causal lattice" ≠ rebuild causality.** The 60° light cone of the hexigon thread is a Regge-calculus speculation; the rebuild's causality is Rung-1 orientation (sign/wedge), and the edge residual is explicitly NOT a metric. Do not resurrect the light cone inside build_causal. (SYNTHESIS Q3.)
4. **Quantum speedup stays SPECULATION.** Ian's own words (2026): "the quantum speedup is something i wonder about, but it is just a suspicion, not a proof." The plan therefore has no quantum claims; "superposition" language is retired (classical late binding).
5. **Silicon claims are out of scope.** Ternary energy savings, "3 orders of magnitude", tau scaling, EUV bypass — engineering speculation from the thread; not Lean-provable as stated and not needed for the math/emulator. The emulator is the right scope.
6. **The only DIRECT bridge to the rebuild is narrow:** (a) the mod-6 integer spinor (Z₆ ⊂ SO(2)) realizing ψ = (α+βI)U, and (b) the gauge-int Signature arithmetic (TODO #16). Everything else is analogy, ours-on-one-side, or speculation.

---

## 3. The math (exact conventions — get these right once, put them in the Lean file header)

- ω = e^{iπ/3} = (1+i√3)/2; satisfies **ω² = ω − 1** (equivalently ω² − ω + 1 = 0). (Note: the *other* common convention ω = e^{2πi/3} has ω² + ω + 1 = 0 and norm a² − ab + b² — pick e^{iπ/3}/a²+ab+b² and state it.)
- Ring: ℤ[ω] = {a + bω : a, b ∈ ℤ} ≅ ℤ[x]/(x² − x + 1).
- Multiplication: **(a+bω)(c+dω) = (ac − bd) + (ad + bc + bd)ω.**
- Norm: **N(a+bω) = a² + ab + b²**, multiplicative (N(xy) = N(x)N(y)); N(x) = 0 iff x = 0.
- Units: ±1, ±ω, ±ω² — the six 60° rotations, the group **Z₆** (multiply = add angles mod 6).
- Axial/cube coordinates: hex cell at (q, r, s) with **q + r + s = 0**; each of q, r, s ∈ {−1, 0, +1} → exactly **7 cells** (center (0,0,0) + six neighbors, the permutations of (1,−1,0)). 3³ = 27 triples, constraint kills 20.
- Hex distance: max(|Δq|, |Δr|, |Δs|) in cube coords.
- Packing: hexagonal lattice is the densest circle packing, density τ/(4√3) = π/(2√3) ≈ 0.9069 (τ = 2π — the base unit of rotation is a circle, not a semicircle; Thue's theorem; optimality is deep — formalize the *density number* first, cite optimality).
- Ternary emulation: balanced ternary {−1, 0, +1} ↔ the three hex axes (q, r, s); center = (0,0,0) = 0; the six directions = the six non-zero triples. Addition is component-wise vector addition in {−1,0,+1}³ (no sign bit needed); the q+r+s=0 constraint is the carry rule's geometry.
- **One-wire ternary (author's physical encoding):** the ternary is the *communication signal on a single wire* — push (+1) / null (0) / pull (−1), AC-style polarity on one conductor — NOT multiple voltage rails. The receiver needs only **two diodes** to re-derive regular binary at the processor where binary emulation is wanted. Purpose: reduce the *cost of transporting information* (fewer wires, no power wasted as heat in rails) — a hex-mmu phase-3 concern, but it pins the encoding: trit = wire polarity, not voltage level.
- **Triangle representation ("base and rise"):** an Eisenstein value is drawn as a triangle with a base and a rise; the *area* (½·base·rise) does not care which leg is which — that symmetry IS commutativity of the product, and it is why the build's "area of the a×b rectangle in the T×T possibility square" reading (ox alpha.md L5414) carries over to the hexagon. At 60° the triangle is one τ/6 wedge; six wedges close the hexagon into a τ-cycle "sphere" — the six neighbors as the discrete circle. Gauge (mod-6 rotation) and cheap multiplication (integer pairs, exponent-like angle addition) both fall out of the 60° basis — "trig becomes modulo arithmetic" (hexigon L11248).

---

## 4. Lean 4 setup + background prover (state VALIDATED 2026-08-28 — scaffold delivered)

### 4.1 Packages — the exact list Ian asked for

**Verified on this machine:** Rust/cargo 1.95.0 ✓, Python 3.13 ✓, git ✓, 330 GB free disk ✓, network ✓ (GitHub + DeepSeek API reachable), **DeepSeek API key VALIDATED** (balance $235.40; models `deepseek-v4-flash`, `deepseek-v4-pro`, `deepseek-v4-flash-vision-exp`), **Ollama reachable from the sandbox** (local models `qwen3.6` 23 GB, `qwen3:14b`, `qwen3.5:9b`, `deepseek-ocr`; generation confirmed working).

**Caveats found while verifying:**
- **elan binaries exist but NO Lean toolchain is installed** (`elan toolchain list` → empty; `lean --version` → empty). And from the survey sandbox `~/.elan` is READ-ONLY ("Read-only file system" when elan tries to create its toolchains dir) — so the toolchain install must run on Ian's real machine (`proofs/SETUP.md` step 1). The scaffold is drop-in.
- **`deepseek-prover-v2` is NOT on this DeepSeek API** (no prover model in the list). Use **`deepseek-v4-pro`** as the background prover — it is the model that wrote the ox-alpha proofs — with `deepseek-v4-flash` for cheap sketches.
- **AMD GPU: not visible from the sandbox** (no `/dev/dri`, no `/dev/kfd` — the execution environment doesn't expose it) though the real machine has one and Ollama uses it there. In-sandbox Ollama falls back to CPU (works, slow: ~29 s for a 20-token qwen3 generation including model load).
- **No deepseek models in the local Ollama list** and the registry 404s `deepseek-prover-v2`/`deepseek-r1` from here → local prover fallback = **`qwen3.6`** via the OpenAI-compatible endpoint (`http://localhost:11434/v1`, `think:false`).

| # | Package | Why | Status (2026-08-28) |
|---|---|---|---|
| 1 | **elan** (Lean 4 toolchain manager) | binaries present at `~/.elan/bin`; **no toolchain installed yet** | install the toolchain on the real machine: `elan toolchain install "$(cat /tmp/lt)"` with mathlib's pinned `lean-toolchain` (SETUP.md) |
| 2 | **Lean 4** (via elan) | the prover itself | comes with the toolchain install above |
| 3 | **mathlib** (via `lake new hexagon math`) | rings, norms, NumberTheory | **NEEDED** — first `lake exe cache get` downloads ~1 GB precompiled artifacts (disk fine). NOTE: mathlib likely already has Eisenstein integers (`Mathlib/NumberTheory/EisensteinInts`, probably ω = e^{2πi/3} / norm a²−ab+b²) — **check and reuse**, prove the convention bridge to our e^{iπ/3} convention once, in the file header (INDEX.md T-ISO). |
| 4 | **DeepSeek API (primary prover)** | model **`deepseek-v4-pro`** (not deepseek-prover-v2 — not on this API); `deepseek-v4-flash` for sketches | key **VALIDATED** (balance $235.40) — stored in `proofs/.env` (gitignored). Runner: DeepSeek Harness background agent per goal file (project carries a `deepseek-harness/` copy). |
| 5 | **Ollama (local fallback prover, free)** | model **`qwen3.6`** via `http://localhost:11434/v1`, `think:false` | works from the sandbox right now; uses the AMD GPU on the real machine |
| — | cargo / rustc / python3 / git | already present | ✓ no action |
| — | cuda / vllm / torch (local model weights) | not needed — API + Ollama cover the prover routes | SKIP |

```
# On Ian's real machine (writable ~/.elan + AMD GPU) — full steps in proofs/SETUP.md:
curl -fsSL https://raw.githubusercontent.com/leanprover-community/mathlib4/master/lean-toolchain -o /tmp/lt
elan toolchain install "$(cat /tmp/lt)" && elan override set "$(cat /tmp/lt)"
cd proofs/lean-src && lake new hexagon math && cd hexagon   # then drop in the lean-src/ contract files
lake update && lake exe cache get && lake build
# prover: DEEPSEEK_API_KEY lives in proofs/.env (validated); fallback OLLAMA_BASE_URL=http://localhost:11434/v1
```

**Delivered (2026-08-28):** `proofs/` scaffold written — README, SETUP, AGENTS (prover rules), INDEX (claim ledger), `.env` (validated key), `.gitignore`, and the Lean contract files `lean-src/{lakefile.lean, Hexagon.lean, Hexagon/Conventions.lean, Hexagon/SevenHex.lean, Hexagon/Rotation.lean}` with provenance headers + calibration labels. First goal for the prover: **T2** (`SevenHex.lean`, the one-page bijection).

### 4.2 Bootstrapping
Install elan (`curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh`), then `lake new hexagon math`; first build pulls mathlib. Half a session.

### 4.3 The proving agent + idea histories
- **proofs/AGENTS.md** (per hexigon L9523–9535): Lean 4, generate proof *sketches*, prefer `have`/`calc` over `sorry`, run as a background job (`lean-agent --project proofs/ --timeout 3600 --output proofs/results/`), human verifies invariants (the repo's rule: agents implement, human verifies).
- **DeepSeek-Prover-V2 as the background** (author-confirmed): the harness spawns an agent per goal file; it returns a Lean proof or a sketch with a `sorry` marked; the human (or a second pass) closes the gaps. T2 (the bijection) is the first goal to throw at it — it is small, enumeration-proved, and ideal for automated search.
- **Idea histories:** every theorem file carries a provenance header — *origin* (hexigon L…, ox alpha L…, the diamond-doc path, TODO #16, SYNTHESIS Q…), *status* (proved / ported / stated-unproved), *calibration* (DIRECT / ANALOGY / SPECULATION). `proofs/INDEX.md` maps claim → Lean file → status, updated on every commit. The Lean mirror of the repo's append-only ledgers: the proof ledger outlives every agent.

---

## 5. Lean theorem order (one-page wins first; each is a self-contained deliverable)

| # | Theorem | Why first | Difficulty |
|---|---|---|---|
| **T0** | ℤ[x]/(x²−x+1) is a commutative ring (the Eisenstein integers) | Foundation; trivial in mathlib | Easy |
| **T1** | N(a+bω) = a²+ab+b² is multiplicative | Norm = the ring's "size"; needed everywhere | Easy |
| **T2** | Balanced-ternary triples (q,r,s), q+r+s=0, are **bijective** to the 7 hex cells | The flagship one-page theorem; already enumeration-proved in the thread (L10005–10105) — port it | Easy-Med |
| **T3** | The six units form Z₆; rotation = mod-6 addition of angles | The exact-integer rotor (the rebuild bridge) | Easy-Med |
| **T4** | Cube-coordinate distance = max(|Δq|,|Δr|,|Δs|) | The addressing metric (guardrail 2's prerequisite) | Medium |
| **T5** | ℤ[ω] is a Euclidean domain / UFD | Classical; likely in mathlib already — check before writing | Medium |
| **T6** | Hexagonal lattice packing density = τ/(4√3) (= π/(2√3)) | The "packs circles optimally" claim, reduced to a computable number | Medium (defer the full Thue optimality proof) |

T2 is the critical path: it converts "ternary ↔ hexagon" from a beautiful coincidence into a checked theorem, and it is the one claim the whole plan's credibility rests on.

---

## 6. Rust mirror — the emulator core (phase 2, integer-only, no .latx change)

- **`eisenstein.rs`**: integer pair (a, b); add; mul via ω² = ω − 1; norm (a²+ab+b², via inverse-mult or direct — it's one add of two squares plus a product); mod-6 rotate (angle index add mod 6); neighbor table (6 offsets + center); balanced-ternary ↔ hex-cell encode/decode. **Property tests mirroring T0–T4** (ring axioms on random integer pairs; norm multiplicativity; bijection round-trip over all 7 cells; Z₆ table).
- **gauge-int wiring (TODO #16, ox alpha.md L3109):** promote `clifford.rs::Rotor{f32,f32}` to an integer pair + `Signature` (i² ∈ {−1, +1, 0, ω}); the ω case IS the Eisenstein step; "store the spinor integer (E, w), invariant δ" — no `.latx` change (~100 lines, as the TODO says).
- **Mod-6 spinor experiment (the one DIRECT rebuild bridge):** in the generator, replace the float rotor angle with exact mod-6 integer rotation; compare held-out P@K before/after (rule 5: held-out, not feel). If it holds, the rebuild gains an exact-integer rotation layer; if not, the experiment is recorded as a null — either way it's a result.

---

## 7. Three-project container (per hexigon L15122, 15267 — Ian's own split)

1. **lattice-core** — the math library + Lean proofs (this plan's phases 1–2: §4–§6).
2. **hex-mmu** — the emulator layer. **Scope now author-defined:** "emulate means we will emulate **hexagonal RAM, ternary instruction, and Einsteinian math of the 60-degree triangles**" — i.e. (a) a hex-addressable memory emulator (hex RAM), (b) a ternary instruction set (trits from the one-wire push/pull/null encoding, two-diode receiver → binary at the processor boundary), (c) an Eisenstein ALU (60° triangle arithmetic: base/rise, mod-6 gauge, cheap multiplication). Phase 3+ — the silicon/energy claims stay SPECULATION (§2.5), the emulator is the right scope.
3. **lean-lang** — the formal-verification harness (the proofs/ folder, agent-driven; §4.3).

Each gets its own repo when the "alien" project starts. This plan is the lattice-core seed: **Lean proofs first, integer Rust second, hardware never-yet.**

---

## 8. First three tasks (pick ONE per session — AGENTS.md: one small task per session)

1. **The socket:** install elan + Lean 4 + mathlib; `proofs/` skeleton with AGENTS.md + INDEX.md (half a session; unblocks everything; per hexigon L9805–9806 "just set up the socket").
2. **T2 in Lean:** the 7-hex ↔ balanced-ternary bijection — smallest, highest-value, already enumeration-proved; port it with provenance header.
3. **T0+T1 in Lean + eisenstein.rs property tests:** ring + multiplicative norm, mirrored in Rust so the two ledgers (Lean proofs, Rust tests) cross-check — the "bit-for-bit" discipline applied to math.

---

## 9. Open questions for Ian (one-liners that pin the plan)

**Resolved in the 2026 replies:**
1. "The old diamond lattice" → the project's causal-graph **diamond motif** (`a→b, a→c, b&c→f`, "Diamonds All the Way Down", info-geometry docs) — "not old, just the current working versions"; the hexagon embeds the diamond as two adjacent 60° triangles (§0).
2. "Trinary" = **balanced ternary {−1, 0, +1}** — confirmed; physical encoding = **one-wire push/pull/null** (AC polarity, not multi-voltage), 2-diode receiver re-derives binary at the processor (§3).
3. Scope of "emulate" = **hexagonal RAM + ternary instruction set + Eisenstein math** — confirmed (§7).
4. Background prover = **DeepSeek-Prover-V2** — confirmed; route = API (no GPU), runner = the DeepSeek Harness background agent (§4.1).

**Still open (small):**
5. **DEEPSEEK_API_KEY** — needed for the background prover; not present in env. Ian supplies one (or we start plain-Lean and add the prover later).
6. **mathlib convention check** — whether to adopt mathlib's existing Eisenstein integers (likely ω = e^{2πi/3}, norm a²−ab+b²) or define our e^{iπ/3} convention and prove the isomorphism. Implementation detail, decided at task 1, no input needed.

---

## 10. Calibration ledger entry (append to the survey record)

- "Hexagon lattice emulates ternary": **DIRECT as arithmetic** (bijection enumeration-proved; T2 formalizes it); **SPECULATION as hardware** (§2.5). The one-wire push/pull/null encoding and 2-diode receiver are the *communication* layer (hex-mmu phase 3) — recorded, not yet Lean-relevant.
- "The diamond lattice" = the project's causal-graph diamond motif (`a→b, a→c, b&c→f`, "Diamonds All the Way Down", 2026-08-05): the hexagon embeds it as the rhombus of two adjacent 60° triangles — the "overlap" Ian described is now author-documented; provenance belongs in the Lean file headers (§4.3).
- "Einstein triangles of 60 degrees" = Eisenstein ℤ[ω]: **DIRECT** — Ian's own words (2026 reply) + hexigon thread + SYNTHESIS §0. Note: Ian's "Einstein triangle" is polyvalent — it ALSO means his geometric-mean triangle (ox alpha.md L4996). Two senses, both his; the plan targets the 60° Eisenstein sense.
- "Base and rise" triangle representation / τ/6 wedge / "the area does not care which is which": the commutativity symmetry of the product, matching the rebuild's rectangle-area reading (ox alpha.md L5414) — a DIRECT geometric translation of a claim already in the framework.
- "Hex lattice replaces the u32 kernel / is the semantic manifold's shape": **SPECULATION** — blocked on the provable hex↔u32 address bijection (guardrail 2; T4 + a T-address-translation theorem are the unlock).
- "Quantum speedup via superposition": **SPECULATION (author-confirmed suspicion)** — excluded from the plan.
- Million× speedup: baseline now **named by the author** (vs the original/unoptimised implementation, tested earlier) — no longer unbounded, but still not written in the repo docs; add one README line when convenient.
- **Toolchain state (2026):** Rust 1.95 / Python 3.13 / git present; elan + Lean 4 + mathlib to install (package list §4.1); no local GPU → DeepSeek-Prover-V2 via API; DEEPSEEK_API_KEY not yet set.
