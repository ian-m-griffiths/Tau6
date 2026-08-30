# Ternary Processor — Design Doc

**Status:** DESIGN DOC / DRAFT (research-grounded spec collection — not a proof, not silicon)
**Date:** 2026 (session)
**Author:** research + design-doc agent, per Ian's brainstorm
**Companion:** [`HEXAGON_LATTICE_PLAN.md`](HEXAGON_LATTICE_PLAN.md) (the build plan — Lean first, Rust emulator second, hardware never-yet). This doc is the *spec/research* layer for the same ideas; the plan is the *execution* layer. Where they disagree, the plan's guardrails (§2 of the plan) win.

**Claim labels used throughout** (house calibration system):
- **[DIRECT]** — established fact, checked (math, history, or documented hardware).
- **[ANALOGY]** — structurally similar to something real, but the mapping is not an identity.
- **[SPECULATION]** — the author's idea or a design sketch, unverified as stated.
- **[OURS]** — already established inside this project (plan / thread / Lean ledger) and carried here verbatim.

**Honesty clause:** this document collects ideas the author brainstormed, fleshed out with what is known, what has precedent, and what is still open. Several claims below are *mathematically checkable and checked*; several are *engineering bets*; none of the hardware claims are built.

---

## TL;DR

1. **Balanced ternary** ({−1,0,+1}, Setun's number system, Knuth's "prettiest number system") is [DIRECT] real math with a real (tiny) computing history. The author's physical encoding — **one wire, push/pull/null, polarity of an AC-like behavior rather than voltage level** — is a novel combination whose *components* all have [DIRECT] mainstream precedent (differential pairs, Manchester/phase encoding, 3-level line codes MLT-3/PAM-3), but no found precedent as a *balanced-ternary computing* scheme. The open question (direction-setting via excess/dearth of electrons, 2-diode receiver) has a concrete sketch (§1.4) that needs engineering, not magic.
2. **The ternary ISA** (§2) is CANDIDATE/SPECULATION by construction, grounded in Setun (18-trit word, single-address) and two modern proposals (REBEL-6 32-trit ISA with a C compiler pipeline; 5500FP 24-trit RISC) — 12 proposed opcodes, including the author's own prior sketches (CVT, HEX-load/store, gauge-rotate).
3. **Fractal hex RAM** (§3) is *literally* a hexagonal DGGS (Discrete Global Grid System): Uber's H3 is an aperture-7 hex hierarchy with per-layer orientation rotation — the "7 cells, north becomes north-east one layer up, 7ⁿ addressing" idea already exists in geospatial indexing. As RAM it's a *logical addressing* scheme over binary memory; the plan's guardrail 2 (hex↔u32 bijection still unproved) applies.
4. **Gauge-as-area** (§4): the author's insight restated precisely. The checked numbers split cleanly: `{20,1} ≡ {10,2}` **only** under the triangle-area reading (½·a·b: 20·1 = 10·2 = 20); under the Eisenstein norm N(a,b)=a²+ab+b² they do *not* match (421 ≠ 124). The mathematically load-bearing object is the norm = **determinant of the regular representation** (an area) = Z₆-invariant, multiplicative — that is where "isotropy" and "cheap gauge change" are real. The Lean ledger has T0–T3 proved (`lake build` green); the Gauge theorems are a stated contract.
5. Open questions for the author in §5.

---

## 1. Balanced ternary & the polarity encoding

### 1.1 What balanced ternary is (known, [DIRECT])

Balanced ternary is radix 3 with digits {−1, 0, +1} (written {T, 0, 1} in some literature). Standard facts, all [DIRECT]:

- **Negation is free**: swap digits (−1 ↔ +1). No separate sign bit; the sign lives in the digits.
- **Symmetric range**: n trits cover [−(3ⁿ−1)/2, +(3ⁿ−1)/2], exactly centered on zero — no off-by-one asymmetry.
- **Addition has a small carry**: digit sums stay in {−2,…,+2}, so each position emits a carry of at most ±1 with a simple rule. (Positional radix-3 addition *does* carry — e.g. 1+1 = 2 = 3 − 1, i.e. `1T` — but the rule is bounded and simple. Negation is the carry-free one.)
- **Knuth**: *The Art of Computer Programming, Vol. 2, §4.1* calls balanced ternary "perhaps the prettiest number system of all" — a widely quoted line; the exact quote appears in [The Power of Three and the Wooden Computer (red-gate)](https://www.red-gate.com/simple-talk/opinion/opinion-pieces/power-three-wooden-computer/). [DIRECT]
- **History — Setun**: the Soviet computer [Setun (Wikipedia)](https://en.wikipedia.org/wiki/Setun), designed by N. P. Brusentsov at Moscow State University, 1958, ~50 machines built — the only serial-production ternary computer; 18-trit word (≈ 28.5 bits, since log₂3¹⁸ ≈ 28.5), 5-trit addresses (243 words/page). Also see [The Setun Computer (Earl T. Campbell)](https://earltcampbell.com/2014/12/29/the-setun-computer/) and the [Setun-70](https://handwiki.org/wiki/Setun-70) successor (3-stack "value-oriented" design). Specifics (exact opcode count) vary across sources — treat fine detail as loosely sourced; the architectural shape (small single-address opcode set, 18-trit word) is reliable. [DIRECT for shape / VARIANCE for counts]
- **Three-valued logic** as a logic (not hardware): Kleene's strong K3 and Łukasiewicz's L3 both give three-valued truth tables {false, unknown, true} — [Stony Brook CSE371 slides, "Some Three Valued Logics Semantics"](https://www3.cs.stonybrook.edu/~cse371/5slide.pdf), [Łukasiewicz's Three-Valued Logic (Wolfram)](https://www.wolframcloud.com/objects/demonstrations/LukasiewiczsThreeValuedLogicSource.nb). This is the *logic* side of "ternary"; the author's project is the *arithmetic/encoding* side. [DIRECT]
- **Radix economy**: for a fixed number range, the "cost" b/ln b is minimized at b = e; the best *integer* base is 3. This is the standard argument that ternary is information-dense per symbol (log₂3 ≈ 1.585 bits/trit) — [HN: Base 3 Computing Beats Binary](https://hn.svelte.dev/item/41201922), [python-ideas radix discussion](https://mail.python.org/archives/list/python-ideas@python.org/message/HKBXLBEYRYJ6YTCD7JGSRRJQOTHPQSMH/). [DIRECT as math] — the *engineering* conclusion ("therefore build ternary") is contested; see §1.5. [ANALOGY]

### 1.2 The author's encoding claim — restated precisely

> "Balance is useful for circuitry because we measure **polarity of the AC-like behavior** as the encoding, and not the voltage."
> Encoding: **balanced ternary {−1,0,+1} on ONE wire via push/pull/null** — not multiple voltage rails.

Restatement (from the author's own words in the thread, e.g. hexigon L8847, L9926, and the plan §3 line 59):
- **push** = drive the line one way (+1), **pull** = drive it the other (−1), **null** = don't drive (0 / "no electrons").
- The receiver reads the *direction* (polarity of the excursion), not the absolute level — hence "AC-like": an AC-coupled / transition-based reading where DC level carries no meaning.
- Purpose: cheaper information transport — one conductor per trit instead of multi-rail or multi-wire, and null costs (in principle) no energy. [OURS — the project's own recorded framing, plan §3; the energy claims are model-derived, unmeasured]

### 1.3 Precedent: does "polarity as the encoding, not voltage" exist? ([DIRECT] — yes, in communication; [SPECULATION] as a computing scheme)

The *principle* is mainstream and old. Polarity/phase-as-information, not level:

- **Differential signaling**: RS-485, LVDS, USB, Ethernet PHYs encode the bit as the *polarity of the voltage difference* between the two wires of a pair — the receiver compares, it never measures absolute level. [DIRECT] — [RS-485 polarity conventions (TI app note)](https://e2e.ti.com/cfs-file/__key/telligent-evolution-components-attachments/13-143-00-00-00-26-49-60/RS485-_2D00_-Polarity-Conventions.pdf), [Polarities for differential pair signals (white paper)](https://adv-www-jp.azurewebsites.net/en-eu/resources/white-papers/2fde048f-f42c-439b-b0a9-485cd548f172). A differential pair is literally "the sign of the pair difference is the bit."
- **Transition/edge encoding**: Manchester encodes the bit as the *direction of the mid-symbol transition*, not the level; it's DC-balanced precisely because levels are meaningless — [Old, but Still Useful: The Manchester Code (DigiKey)](https://www.digikey.com/en/blog/old-but-still-useful-the-manchester-code). Phase-modulation (BPSK/QPSK) is the same idea at RF. [DIRECT]
- **Three-level line codes**: MLT-3 (Fast Ethernet 100BASE-TX) cycles through three levels {−1, 0, +1} on one pair — [Pico-100BASE-TX (MLT-3 signaling)](https://github.com/steve-m/Pico-100BASE-TX/blob/master/README.md); PAM-3 (Automotive Ethernet 100BASE-T1) uses 3 levels with 4B3B — [Fundamentals of 100Base-T1 (Teledyne LeCroy)](https://blog.teledynelecroy.com/2020/07/fundamentals-of-100base-t1-ethernet.html). PAM-4 (400G Ethernet) uses 4 levels; MLC/TLC/QLC NAND flash store 2/3/4 bits per cell (4/8/16 levels). So **multi-level signaling is everywhere** — the industry's answer to "more than 2 states per wire/cell" is *more voltage levels*, not polarity. [DIRECT]

So the honest finding: **"encode in polarity/phase rather than level" is real and old (differential pairs, Manchester, BPSK); "3 states on one wire" is real and current (MLT-3, PAM-3); "balanced-ternary *logic* over one AC-coupled wire, with null as an information-carrying zero-energy state" as a computing scheme has no found precedent** — it's the author's synthesis. [DIRECT precedent per component; SPECULATION as a whole]

The author's own thread already contains the two sharpest counter-notes ([OURS], hexigon L8531–8558 "physical ternary cannot be done on standard silicon without exotic materials" — C11; L8722: "differential ternary = 2 wires for 3 states is *worse* density per wire than binary": 3 states/2 wires = 1.5 states/wire < 2). The plan's guardrail 5 (silicon claims out of scope) applies to everything below.

### 1.4 The open question — direction setting & the 2-diode receiver (design sketch, [SPECULATION] with [DIRECT] components)

**The question (author's words, compressed):** setting direction in chips must be feasible — likely by "changing an excess or dearth of electrons on one end" — how is that generated? What does a 2-diode receiver do to recover binary at the processor?

**Sketch that answers both halves (engineering reasoning, not yet built):**

1. **Generating push/pull/null** — this is a *three-state driver*, a standard circuit: [DIRECT components]
   - push = connect the line to the high rail through a driver (pushes charge in);
   - pull = connect to the low rail (pulls charge out);
   - null = disconnect (high-impedance / tristate), the line then floats or is held at mid by a termination/keeper.
   - Precedents: tristate (three-state) buses and push-pull vs open-drain drivers are [DIRECT], decades-old CMOS staples. "Excess or dearth of electrons on one end" is the wire-level intuition for *current direction*: a push at one end injects a surplus there; the far end sees the polarity of the resulting excursion. The *novel* part is not the driver — it's using the null as a third data symbol plus the AC-coupled reading. [SPECULATION]
2. **The 2-diode receiver → binary** — two antiparallel (opposite-polarity) diode paths split the line's two polarities into two rails: positive excursions conduct through one diode path → rail A; negative excursions through the other → rail B; null → neither. The trit {+1, 0, −1} demultiplexes to (railA, railB) ∈ {(1,0), (0,0), (0,1)} — two binary streams, recoverable by ordinary binary logic ("it locally swaps the ternary to be a trivial swap between the steps", author's words, hexigon L9926). Diode rectification/clamping is [DIRECT] (clamp diodes, full-wave detection); the *specific* 2-diode ternary→dual-binary demux is a [SPECULATION] sketch needing threshold sizing, hysteresis, and noise-margin analysis.
3. **Where the "AC-like" part bites (the real engineering risk):** if the line is truly AC-coupled, a steady +1 will decay — you need DC-balance (Manchester-style, guaranteeing transitions) or periodic refresh. That trades away some of the "null costs nothing" advantage. If it's not AC-coupled, then it's just 3-level DC signaling (MLT-3/PAM-3 territory), and "polarity not voltage" is a framing, not a mechanism. **The doc's recommendation: pin this choice first** — it changes everything downstream. [SPECULATION/design decision]

### 1.5 Feasibility notes — why ternary logic didn't displace binary ([DIRECT] history, [ANALOGY] lessons)

- Ternary *gates* have been built in research for decades: CMOS ternary arithmetic (TSMC 40 nm) — [Design and simulation of CMOS-based ternary logic arithmetic circuits (NTU)](https://dr.ntu.edu.sg/entities/publication/285af415-5c9c-4da3-bdf9-cd60456defe7); the multiple-valued-logic literature survey — [THE MULTIPLE-VALUED (PDX)](http://web.cecs.pdx.edu/~mperkows/temp/May13/006C.Intro-MV-new.pdf); balanced ternary in CNFET — [Toward efficient implementation of basic balanced ternary arithmetic operations in CNFET technology (ScienceDirect)](https://www.sciencedirect.com/science/article/abs/pii/S0026269218304634); memristor-CMOS ternary logic — [A balanced Memristor-CMOS ternary logic family (arXiv via X-MOL)](https://www.x-mol.com/paper/1699545935766114304). [DIRECT — the circuits exist]
- Why it never displaced binary: (a) for a fixed voltage swing and noise budget, 3 levels per wire has ~half the noise margin of 2; (b) CMOS transistors are naturally 2-state switches; (c) the entire ecosystem (EDA, memory, software) is binary; (d) binary already extracts the one mathematical benefit balanced ternary is famous for — *signed-digit sparsity* — via **Booth encoding** (the {−1,0,1} recoding trick that cuts partial products), so there is no multiplication-density win left for ternary. See the [StackOverflow thread on converting microprocessors to trinary](https://stackoverflow.com/posts/72831742/timeline) for the practical catalog of walls. [DIRECT/ANALOGY]
- Commercial multi-value wins exist only in **storage** (MLC/TLC/QLC flash) and **signaling** (PAM-4/MLT-3/PAM-3), never in **logic**. The author's architecture is consistent with that split: ternary in *communication* (one-wire push/pull/null), binary inside the core (2-diode receiver), hex *addressing* on top. [ANALOGY — the split is real; the author's specific scheme is untested]

---

## 2. Ternary ISA — candidate instruction set

**Status: CANDIDATE / SPECULATION by construction.** Grounded in (a) Setun's actual ISA, (b) two modern balanced-ternary ISA proposals, (c) the author's own prior ISA sketches in the thread. Nothing here is fixed; it's the seed for the hex-mmu emulator (plan §7).

### 2.1 Grounding — what exists

| Source | What it is | Relevance |
|---|---|---|
| [Setun (Wikipedia)](https://en.wikipedia.org/wiki/Setun) | 1958 Soviet ternary computer; 18-trit word (~28.5 bits), 5-trit addresses (243 words/page), small single-address opcode set (count varies by source, ~2 dozen) | The historical baseline: ternary word, ternary addresses, tiny ISA |
| [REBEL-6: A 32-trit balanced ternary ISA with R2R compiler pipeline for C (IEEE 2025)](https://ieeexplore.ieee.org/document/11038296) | Modern 32-trit balanced-ternary ISA **with a working C compiler pipeline** | Proof that a balanced-ternary ISA + toolchain is buildable today; the closest thing to "download data on a ternary ISA" |
| [5500FP: A 24-Trit Balanced Ternary RISC Processor (Zenodo)](https://zenodo.org/records/18881738) | 24-trit RISC-style ternary processor | A modern, small, RISC-flavored template |
| [Setun-70](https://handwiki.org/wiki/Setun-70) | 1970s 3-stack "value-oriented" successor | Stack-machine alternative to register ISA |
| [Standard Ternary Logic (D. W. Jones, U. Iowa — archived)](https://web.archive.org/web/20220523030224/http://homepage.cs.uiowa.edu/~jones/ternary/logic.shtml) + [The Ternary Manifesto](http://www.nedopc.org/forum/viewtopic.php?style=14&p=170057) | The classic English-language balanced-ternary design corpus | Opcode/encoding conventions; the "balanced" design philosophy |
| [Ternary Computing Testbed (Cal Poly)](http://honors.calpoly.edu/program/documents/winter08research/pdf/54.pdf) | Undergraduate ternary testbed | Small-scale feasibility reference |
| hexigon_conversation.md L12633–12916, L8284, L8345 | Author's own sketches: `CVT_TERNARY_TO_BINARY`/`CVT_BINARY_TO_TERNARY` (1 cycle), 4×3=12 ternary symbols packed in 24 bits, `TERNARY_MODE` flag, `LOAD_HEX`/`STORE_HEX`, `VGAUGE_ADD` | [OURS] — folded into the candidate below |

### 2.2 The candidate opcode set (12 opcodes)

Design rules (from the grounding): balanced digits {−1,0,+1}; no sign bit; word = 12 trits packed in 24 bits (LCM of 8 and 12 — the author's 4×3=12 packing, so 12 ternary symbols sit exactly in 3 bytes); opcode 3 trits (27 slots), two 4-trit operand fields, 1 trit flag/immediate — 3+4+4+1 = 12. All of §2.2 is **[SPECULATION]** unless tagged otherwise.

| # | Opcode | Meaning | Notes / heritage |
|---|---|---|---|
| 1 | `TADD rd, ra, rb` | Balanced-ternary add | Digit-sum with the bounded ±1 carry rule; symmetric digits, no sign bit [DIRECT math] |
| 2 | `TSUB rd, ra, rb` | Subtract | Negate rb by digit-swap (free) then add — negation is carry-free [DIRECT math] |
| 3 | `TMUL rd, ra, rb` | Balanced-ternary multiply | Integer-pair product; sign embedded in digits; sparsity benefit already extracted by binary via Booth, so no density win — the win here is *symmetry*, not partial-product count |
| 4 | `TDIV rd, ra, rb` | Divide, round-to-nearest | Setun heritage; exact symmetric rounding to the balanced digit grid |
| 5 | `TMOD rd, ra, rb` | Remainder, |r| ≤ |b|/2 | Symmetric modulus — the balanced analogue of Euclidean mod |
| 6 | `TROT rd, ra, #k` | Gauge change: multiply by ω^k, k ∈ 0..5 | The Z₆ rotation op — mod-6 rotation of the lattice point, angle-add mod 6. For k=1: (a,b) → (−b, a+b), i.e. a negate + an add, no multiplies. This is the project's "cheap gauge change" made an instruction [DIRECT math / OURS framing] |
| 7 | `TNORM rd, ra` | N(a,b) = a²+ab+b² → scalar | The "value as its area" (§4); Z₆-invariant, so gauge-free by construction [DIRECT math] |
| 8 | `HEXLD rd, [q,r,s]` | Load via cube/hex address | The hex-mmu addressing op; cube coords q+r+s=0 [OURS — thread L8284 `LOAD_HEX`] |
| 9 | `HEXST [q,r,s], rd` | Store via cube/hex address | [OURS — thread L8284 `STORE_HEX`] |
| 10 | `NEIGH rd, ra, #dir` | 6-neighbor gather: rd = mem[ra + dir] | The isotropy op — one lattice hop in any of 6 directions, same distance; the address-space analogue of "perfect prefetch" |
| 11 | `TCVT rd, ra` | Convert packed-binary ↔ balanced-ternary | The author's 1-cycle CVT pair, generalized; 24-bit ↔ 12-trit pack/unpack [OURS — thread L12843–12844] |
| 12 | `TBR #k, rd` | 3-way compare & branch (below / equal / above) | Kleene-style three-valued predicate; a `null` test falls out as the "equal-zero" case |

Candidate 13th (keep in the back pocket): `TNUL rd, ra` — extract/test the null symbol explicitly (the "1 state requires no electrons, we get information by doing nothing" op, hexigon L9926). **Why only 12:** a 3-trit opcode field gives 27 slots; a small, Setun-like set keeps the emulator honest and leaves room. The one *hard* addition over a plain RISC is the pair `TROT` + `TNORM` — those are the only opcodes that encode something binary can't express cheaply (exact 60° gauge change; the Z₆-invariant area scalar).

**ISA-level notes:**
- 18-trit words (Setun scale) are unnecessary for the emulator; 12 trits ≈ 19 bits is a comfortable word for a first `hex-mmu` target. [SPECULATION]
- Binary compatibility is *not* assumed native: the thread's own analysis (N73) proposed 99% program compat via `TCVT` + a `TERNARY_MODE` flag; treat that as a goal, not a given. [OURS/SPECULATION]
- The `q+r+s=0` constraint doing "carry work" (plan §3 line 58, thread L10071): **careful.** Cell-level vector addition in cube coordinates is carry-free and exact [DIRECT], but *positional* radix-3 addition still carries (1+1 = `1T`). "The constraint is the carry rule's geometry" is a true statement about the lattice reading of balanced-ternary triples, not a license to delete carry logic from `TADD`. [DIRECT vs SPECULATION — flagged]

---

## 3. Fractal hex RAM — the 7ⁿ addressing scheme

### 3.1 The idea, restated

> 7 cells (center + 6 neighbors); "north becomes north-east one layer up"; a 7-cell cluster of 7, **rotating each layer**; 7ⁿ addressing; the memory is not just isotropic, it is fractal.

Restatement (thread L11971–12095, L11565): memory cells arranged on a hex lattice; 7 cells form a cluster; 7 clusters form the next-level cluster; at each level the orientation **rotates** (so the "north" neighbor at level k is a "north-east" neighbor at level k+1); addresses count 7 per level → 7ⁿ address space at depth n; routing between hierarchy levels is "a mod-6 rotation and a carry" (L12095). [OURS — the thread's own formulation]

### 3.2 The DGGS connection — this already exists as geospatial indexing [DIRECT]

The thread itself recognized it (hexigon L8078, L8109: "Hexagonal Discrete Global Grid Systems (DGGS)… applied to memory architecture"). The match is exact, not approximate:

- **Uber H3** is a hierarchical hexagonal grid: an icosahedral base tessellation whose cells refine by **aperture 7** — each hexagon subdivides into 7 child hexagons per resolution — giving exactly the 7-cluster-of-7 structure and a hierarchical index that behaves like 7ⁿ addressing. [DIRECT] — [H3 overview (h3geo.org)](https://h3geo.org/docs/3.x/core-library/overview/), [H3 core-library overview docs (GitHub)](https://github.com/uber/h3/blob/9df3940473e2f0446cf38e22443c77c6b3935382/docs/doxyfiles/overview.md)
- **Per-layer rotation**: H3's aperture-7 refinement rotates the child grid's orientation relative to the parent at each resolution — the geospatial form of "north becomes north-east one layer up." The commonly cited angle is ~19.1° per resolution; verify the exact constant in the H3 docs before quoting it in code. [DIRECT that rotation happens; the exact angle — verify]
- Aperture-3 hexagonal DGGS literature (a cleaner sibling): [Geospatial Data Organization Methods with Emphasis on Aperture 3 Hexagonal Discrete Global Grid Systems (Cartographica)](https://www.giv.cpsc.ucalgary.ca/pdf/Cartographica.pdf). [DIRECT]
- **Why this matters for the project**: "7ⁿ addressing with rotating layers" is not a physics discovery — it's a well-studied index family with known algorithms (parent/child navigation, local-to-global index conversion, neighbor lookup — H3 ships all of these as library functions). The project should *steal* the DGGS algorithms rather than re-derive them. [DIRECT/ANALOGY]

### 3.3 Space-filling-curve precedent for "hierarchical addressing for locality"

Hilbert curves and Morton/Z-order maps are the classic answer to "how does a flat 1-D address encode 2-D locality": [the array-layout-functions literature (survey, citeseerx)](https://citeseerx.ist.psu.edu/document?doi=eff97853a72bba06114c8992ad9da0232c268913&repid=rep1&type=pdf). The hex-DGGS hierarchy is the *hexagonal* member of the same family (locality-preserving hierarchical addressing). [DIRECT] — but note the honest caveat: H3/Hilbert serve *indexing*; whether the same structure buys anything inside a *DRAM address decoder* is a separate question (§3.4).

### 3.4 The "algorithm + operations" question (author's item 4 — needs clarification)

The author asks for "an algorithm (like the **last theory** / causal graph) and a way to have the operations."

- **"The last theory"** — the nearest resolved reference in the project is the causal-graph *diamond motif* (`a→b, a→c, b&c→f`, "Diamonds All the Way Down", info-geometry `lasttheory/` docs), which the plan (§0) already identified as "the old diamond lattice": a rhombus of two adjacent 60° triangles — *the elementary two-triangle cell of the Eisenstein lattice*, with the causal reading "two inputs merge into one output." [DIRECT per plan §0] So a plausible reading of the request: **the hex lattice's operations should include the diamond/collapse rewrite rule** (event-collapse compression, in hex geometry) — a hex-graph algorithm, not just addressing. Marking the *intent* [SPECULATION] (the author should confirm this is what he means).
- **The operations** the hex lattice provably needs, with [DIRECT] references: cube/axial coordinate arithmetic (q+r+s=0, distance = max(|Δq|,|Δr|,|Δs|), 6-neighbor offsets — the plan §3 conventions, and the H3 neighbor/child APIs as the ready-made version); 7-cluster expand/collapse (aperture-7 parent/child — H3); mod-6 rotation at hierarchy boundaries (plan §3; the Z₆ group, T3 proved in Lean). [DIRECT math; the *native-instruction* packaging is [SPECULATION]]

### 3.5 Honesty about "fractal RAM"

- Physical DRAM arrays are rectangular; a hex-fractal memory is, at minimum, a **logical address remap layer** over binary memory (the plan's hex-mmu emulator scope — [OURS, plan §7]). Nothing about the 7ⁿ scheme requires new silicon.
- Plan guardrail 2 stands: "hex addressing ≠ the u32 XOR kernel" — the hex↔u32 address bijection is asserted, not proved; T4 (hex distance = graph distance) is PARTIAL in the Lean ledger, and the address-translation theorem is the unlock. [OURS, proofs/INDEX.md]
- The "routing at fractal boundaries is a mod-6 rotation and a carry — the cheapest possible operation in silicon" (L12095) is [SPECULATION] as silicon economics; as an addressing rule it's just the DGGS rotation, which is real and cheap. [DIRECT/SPECULATION split]

---

## 4. Gauge-as-area scalar encoding

### 4.1 The author's insight, quoted exactly

From `proofs/lean-src/hexagon/Hexagon/Gauge.lean` (the project's own contract file, header note):

> "the math that gives us the isotropy, and lets us encode the gauge and the value as its area as one number… {20,1} is {10,2} by area… the gauge is just another number, giving cheap multiplication and gauge change."

And the supporting thread material: "calculating things as triangles lets us add gauge and number natively… the gauge is the direction (which roots) and the value is the integer multiple… Gauge = orientation, Number = magnitude" (hexigon L10109–10166); "a relative coordinate system… because all places can be the basis point… that is what isotropic really provides" (L10397–10442); the triangle representation with base and rise whose **area (½·base·rise) does not care which leg is which — that symmetry IS commutativity of the product** (plan §3 line 60). [OURS — all quoted from project files]

### 4.2 Restatement + the numbers, checked

**Claim A — "{20,1} is {10,2} by area."** Checked under the *triangle-area* reading (½·a·b, the base/rise triangle from the plan): ½·20·1 = 10 and ½·10·2 = 10 — **equal**. The equality holds because 20·1 = 10·2 = 20. So "the value as its area as one number" with the author's example means the scalar **S(a,b) = ½·a·b** (the ½ cancels in any comparison): infinitely many (gauge, value) pairs collapse to one area scalar — that is the "gauge is just another number" claim, made literal. **[DIRECT arithmetic — the example checks out exactly under this reading]**

**Claim B — "0,0 ≡ 20,20 (isotropy → free offset)."** As raw coordinates this is **false**: N(0,0) = 0 ≠ N(20,20) = 400+400+400 = 1200. It becomes true under three coherent readings: (i) **translation invariance / relative coordinates** — only differences matter, so any point may be the origin ("all places can be the basis point"); (ii) **periodic wrap** — the thread explicitly compactifies the hex lattice to a torus (hexigon L14379, L14735–14737), and on a torus of side 20, (0,0) ≡ (20,20) mod 20 *exactly*; (iii) **Z₆ direction-classes** — (20,20) = 20·(1,1), and (1,1) = 1+ω = e^{iπ/3} is one of the six equivalent 60° rays. [DIRECT arithmetic / the intended meaning is [SPECULATION] — the author should pick the reading]

### 4.3 Where it maps: the Eisenstein norm and Z₆ isotropy [DIRECT math, T0–T3 proved in Lean]

The project's conventions (plan §3; Conventions.lean): ω = e^{iπ/3}, ω² = ω − 1, ℤ[ω] = {a + bω}, multiplication (a+bω)(c+dω) = (ac−bd) + (ad+bc+bd)ω, **norm N(a+bω) = a² + ab + b²**, units ±1, ±ω, ±ω² = the six 60° rotations = the group **Z₆**. (Note: the *other* common convention ω = e^{2πi/3} has norm a² − ab + b² — the project picked the 60° convention and documented it; mathlib's `EisensteinInt` likely uses the other one, bridge theorem T-ISO pending.)

The load-bearing identities, all [DIRECT] and all **checked**:

1. **The norm IS an area.** N(a+bω) = det [[a, −b], [b, a+b]] — the determinant of the regular representation (multiplication by a+bω as a 2×2 integer matrix): a(a+b) + b² = a²+ab+b². The norm is the *area-scaling factor* of the lattice map — "the value as its area as one number" has a precise realization: **N is a single integer (an area) computed from the pair.** (This is exactly what Gauge.lean's header asserts, and it's verified by hand here.)
2. **Z₆ isotropy.** N(u·x) = N(x) for every unit u: rotating by any multiple of 60° leaves the norm unchanged. Gauge = *which* of the six rotated copies you're in; the norm doesn't care — that's the isotropy. (T3: the six units form Z₆ with mod-6 angle addition — PROVED in the Lean ledger.)
3. **Areas multiply.** N(xy) = N(x)·N(y) — the norm is multiplicative (T1, PROVED in Lean: `norm_mul`, `ring_nf`). "Cheap multiplication" in the area-scalar sense: *the area of the product is the product of the areas* — a real, exact identity.
4. **Cheap gauge change.** Multiplication by a unit is rotation: (a,b) → (−b, a+b) for ω, and the other five are permutations/negations of that — a negate and an add, no multiplies. Gauge change is genuinely cheap in ℤ[ω]. (This is the `TROT` opcode of §2.2.)

**And the honest corrections:**
- {20,1} ≡ {10,2} **fails** under the norm reading: N(20,1) = 421 ≠ N(10,2) = 124. The author's example instantiates the *triangle-area* scalar S = ½·a·b, *not* the Eisenstein norm. The two "area" scalars are different objects: S(a,b) = ½·a·b (commutativity-symmetric, gauge-destroying — the product collapses everything) vs N(a,b) = a²+ab+b² (Z₆-invariant, multiplicative — the length²/area-of-representation). **The doc's recommendation: keep both, name them distinctly** — S for the collapse-to-scalar encoding (lossy), N for the isotropy/multiplicativity (lossless, Z₆-invariant). Gauge.lean currently points at N; the author's example points at S.
- "Multiplication becomes addition of exponents" (thread L10073): true for the **unit group** (Z₆: angles add mod 6 — [DIRECT, T3]) but **not** for general multiplication, which is the 4-multiply formula above. [DIRECT correction]
- "No sign bit, addition just adds the ternary vectors component-wise" (L10071): true for lattice vectors / cell algebra [DIRECT]; positional radix-3 still carries (§2.2 note). [DIRECT correction]

### 4.4 The Lean work — current state [OURS]

- **Proved** (2026-08-28, `lake build` green, zero `sorry`, per `proofs/INDEX.md`): T0 `mul_comm`, T1 `norm_mul` (Conventions.lean); T2a/T2b the 7-hex ↔ balanced-ternary bijection (SevenHex.lean); T3a/T3b the Z₆ units (Rotation.lean). T4 (hex distance) and T5/T6 partial.
- **Stated, not yet proved**: Gauge.lean is a *contract* — the header (quoted in §4.1) with the theorem list in comments ("N(u·x) = N(x) for a unit u; N(u) = 1; N = determinant of the regular representation (the 'area'); {a,b} re-encoding") and an empty namespace body. These are the exact theorems §4.3 needs — they are the natural next goals for the prover agent (per `proofs/AGENTS.md` order, after T4/T5).
- The convention bridge to mathlib's `EisensteinInt` (T-ISO) is still open (INDEX.md).

---

## 5. Open questions for the author

Numbered, each with what is known so far and what to test:

1. **The physical null — floating or driven?** Is "null" high-impedance (line floats; needs a termination/keeper, and a truly floating node on a shared bus is a classic reliability hazard) or actively driven to a mid-level (costs power, negating the "null = no electrons" claim)? This pins the whole one-wire story. Test: SPICE-level simulation of push/pull/null with a realistic line + 2-diode receiver. *(Known: tristate drivers [DIRECT]; the specific null handling [SPECULATION].)*
2. **AC-coupled or DC?** If "polarity of the AC-like behavior" means true AC coupling, a held +1 decays — DC-balance or refresh is mandatory (Manchester's reason to exist). If DC, then the scheme is 3-level signaling (MLT-3/PAM-3 territory) and "not the voltage" is framing. Which is intended?
3. **The 2-diode receiver mapping.** Confirm the demux: push → rail A, pull → rail B, null → neither; the binary core consumes (railA, railB). And is "recover binary" about *compatibility* (existing binary logic) or *density* (3 states → 1.58 bits)? The thread's own note (L8722) says differential-2-wire ternary loses per-wire density vs binary — the one-wire version's density math should be written down explicitly (3 states/wire vs 2 states/wire, minus the DC-balance overhead).
4. **ISA scope.** For the hex-mmu emulator: 12 trits/24-bit word (author's 4×3=12 packing), 3-trit opcode, 27 slots, 12 used? And is the binary-compat layer (`TCVT`, `TERNARY_MODE`) in scope for v0 or later? (REBEL-6's C pipeline is the proof it's doable; it's also the biggest scope item.)
5. **Fractal RAM depth.** How many levels of 7ⁿ? (H3 goes 16 resolutions ≈ 5×10¹⁴ cells globally; an emulator needs maybe 3–5 levels.) And confirm the "north → north-east" rotation is meant to match DGGS-style per-layer orientation rotation — if yes, import H3's rotation constant rather than inventing one.
6. **"The last theory / causal graph" algorithm — clarify.** Is the intended algorithm the diamond-collapse rewrite (`a→b, a→c, b&c→f`, the plan §0 motif) re-expressed on hex cells — i.e., a *hex graph compression* rule — or something else ("last theory" was resolved to the diamond doc once already)? This determines what "operations" the hex lattice needs beyond addressing.
7. **Which area scalar?** Confirm §4.3's split: S = ½·a·b (your {20,1}≡{10,2} example — collapse-to-scalar, lossy) vs N = a²+ab+b² (norm — Z₆-invariant, multiplicative, Lean target). The doc recommends N for isotropy/multiplication, S only for the "one number" encoding, and naming them separately. Also: is "0,0 ≡ 20,20" mod-20 (torus wrap), translation-freedom, or something else?
8. **Scope guardrails.** Confirm this doc's hardware claims stay "emulator + math only" (plan §7, guardrail 5: silicon/energy claims out of scope). The thread's energy numbers (per-transition, null = 0; 16% dense / 60% sparse) are model-derived, never measured — is measurement on the roadmap, or are they decoration?
9. **The gauge theorems.** OK to queue Gauge.lean (N(u·x) = N(x), N(u) = 1, N = det of the regular representation) as the next Lean goals after T4/T5? They're small, they're the only fully-checked way to pin §4, and the prover agent is set up for them.

---

## Appendix — source URLs

**Balanced ternary & history**
- [Setun — Wikipedia](https://en.wikipedia.org/wiki/Setun)
- [The Setun Computer — Earl T. Campbell](https://earltcampbell.com/2014/12/29/the-setun-computer/)
- [The Power of Three and the Wooden Computer (Knuth quote) — red-gate](https://www.red-gate.com/simple-talk/opinion/opinion-pieces/power-three-wooden-computer/)
- [Setun-70 — HandWiki](https://handwiki.org/wiki/Setun-70)
- [Three Valued Logics — Stony Brook CSE371](https://www3.cs.stonybrook.edu/~cse371/5slide.pdf)
- [Łukasiewicz's Three-Valued Logic — Wolfram](https://www.wolframcloud.com/objects/demonstrations/LukasiewiczsThreeValuedLogicSource.nb)
- [Base 3 Computing Beats Binary — HN](https://hn.svelte.dev/item/41201922)
- [python-ideas: radix generalization](https://mail.python.org/archives/list/python-ideas@python.org/message/HKBXLBEYRYJ6YTCD7JGSRRJQOTHPQSMH/)

**Ternary ISA**
- [REBEL-6: 32-trit balanced ternary ISA with R2R compiler pipeline for C — IEEE](https://ieeexplore.ieee.org/document/11038296)
- [5500FP: 24-Trit Balanced Ternary RISC Processor — Zenodo](https://zenodo.org/records/18881738)
- [Standard Ternary Logic — D. W. Jones (archived)](https://web.archive.org/web/20220523030224/http://homepage.cs.uiowa.edu/~jones/ternary/logic.shtml)
- [The Ternary Manifesto](http://www.nedopc.org/forum/viewtopic.php?style=14&p=170057)
- [Ternary Computing Testbed — Cal Poly](http://honors.calpoly.edu/program/documents/winter08research/pdf/54.pdf)

**Polarity / differential / multi-level signaling**
- [RS-485 polarity conventions — TI](https://e2e.ti.com/cfs-file/__key/telligent-evolution-components-attachments/13-143-00-00-00-26-49-60/RS485-_2D00_-Polarity-Conventions.pdf)
- [Polarities for differential pair signals](https://adv-www-jp.azurewebsites.net/en-eu/resources/white-papers/2fde048f-f42c-439b-b0a9-485cd548f172)
- [Manchester code — DigiKey](https://www.digikey.com/en/blog/old-but-still-useful-the-manchester-code)
- [Fundamentals of 100Base-T1 (PAM-3) — Teledyne LeCroy](https://blog.teledynelecroy.com/2020/07/fundamentals-of-100base-t1-ethernet.html)
- [Pico-100BASE-TX (MLT-3)](https://github.com/steve-m/Pico-100BASE-TX/blob/master/README.md)

**Ternary circuits / MVL**
- [CMOS ternary logic arithmetic, TSMC 40nm — NTU](https://dr.ntu.edu.sg/entities/publication/285af415-5c9c-4da3-bdf9-cd60456defe7)
- [The Multiple-Valued (MVL intro) — PDX](http://web.cecs.pdx.edu/~mperkows/temp/May13/006C.Intro-MV-new.pdf)
- [Balanced ternary arithmetic in CNFET — ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0026269218304634)
- [Balanced Memristor-CMOS ternary logic family](https://www.x-mol.com/paper/1699545935766114304)
- [Converting microprocessors to trinary — StackOverflow](https://stackoverflow.com/posts/72831742/timeline)

**DGGS / hierarchical addressing**
- [H3 overview — h3geo.org](https://h3geo.org/docs/3.x/core-library/overview/)
- [H3 core-library overview — GitHub (uber/h3)](https://github.com/uber/h3/blob/9df3940473e2f0446cf38e22443c77c6b3935382/docs/doxyfiles/overview.md)
- [Aperture 3 Hexagonal DGGS — Cartographica](https://www.giv.cpsc.ucalgary.ca/pdf/Cartographica.pdf)
- [Array layout functions / locality-preserving mappings — citeseerx](https://citeseerx.ist.psu.edu/document?doi=eff97853a72bba06114c8992ad9da0232c268913&repid=rep1&type=pdf)

**Eisenstein integers**
- [eisenstein crate (ℤ[ω] with norm) — docs.rs](https://docs.rs/crate/eisenstein/0.1.1)
- [Lattices with moduli i or ω — CUNY](https://fsw01.bcc.cuny.edu/anthony.weaver/Research_files/ExPoints-JPAA.pdf)

**Project-internal (OURS)**
- [`HEXAGON_LATTICE_PLAN.md`](HEXAGON_LATTICE_PLAN.md) — the plan (conventions §3, guardrails §2, scope §7)
- `hexigon_conversation.md` — the raw brainstorm (L8078/8109 DGGS; L8531–8558 physical-ternary caution; L8722 differential-density note; L9926 2-diode receiver; L10005–10105 bijection; L10109–10166 gauge-and-number; L11565/L11971–12095 fractal memory; L12633–12916 packing/CVT; L14735–14737 torus wrap)
- `proofs/INDEX.md` — Lean ledger (T0–T3 proved; T4–T6 partial; Gauge pending)
- `proofs/lean-src/hexagon/Hexagon/Conventions.lean` — T0/T1 (ω-mult, norm)
- `proofs/lean-src/hexagon/Hexagon/SevenHex.lean` — T2 (7-hex ↔ balanced-ternary bijection, proved)
- `proofs/lean-src/hexagon/Hexagon/Gauge.lean` — the gauge-as-area contract (§4)
