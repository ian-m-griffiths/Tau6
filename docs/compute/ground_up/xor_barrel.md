# XOR Kernel & Barrel Shift — the hypercube's "discrete trig," mapped to the Eisenstein lattice

**2026-08-29.** Survey of the two GA Tier-2 instructions `TXOR` (`cos θ ≡ (−1)^popcount(i&j)`)
and `TBARREL` (`d >> 1`) from `docs/GA_INSTRUCTIONS.md`, against the rebuild's GA corpus and the
project's own Eisenstein-lattice Lean proofs. Scope: (1) what the XOR kernel *is* precisely,
(2) the Eisenstein map via `CrtHex`, (3) the barrel shift as RG/scale-change, (4) Lean-provable
theorems vs cited facts.

Calibration legend (repo standard — mark at mapping time, verify later):

- **DIRECT** — measured, proved, or a textbook identity. Cite the number/file.
- **ANALOGY** — structural resemblance, not identity. The shapes match; the objects differ.
- **OURS** — our design claim; follows from DIRECT but is not independently established.
- **SPECULATION** — untested hypothesis; never stated as fact.

---

## 1. What the XOR kernel is, precisely

The phrase `cos θ ≡ (−1)^popcount(i & j)` bundles **two distinct objects** that must be kept apart:

### 1.1 The Walsh–Hadamard matrix entry — this is DIRECT

Let `i, j ∈ {0,…,2ⁿ−1}` be n-bit labels (vertices of the Boolean hypercube `(Z₂)ⁿ`; for the
rebuild, `n = 32`). Write `⟨i, j⟩ = Σₖ iₖ·jₖ (mod 2)` for the bitwise dot product, i.e. the
**parity of the bitwise AND**:

```
⟨i, j⟩ = popcount(i & j) mod 2
```

The Walsh–Hadamard transform (WHT) is the `2ⁿ × 2ⁿ` matrix

```
H[i, j] = (−1)^{⟨i,j⟩} = (−1)^popcount(i & j)
```

The right-hand side is exactly the rebuild's kernel. `(−1)^k` only depends on `k mod 2`, so
`(−1)^popcount(i&j)` **is** `(−1)^{⟨i,j⟩}` — the popcount is a means of computing the parity of
the AND, and nothing more. **[DIRECT — definition of the WHT; the rebuild cites it as such in
`docs/surveys/quantum-algorithms.md` ("`H^⊗n` has matrix `(−1)^{x·y}`") and
`docs/surveys/spectral-graph-theory.md`.]**

### 1.2 Why "cos" — the two-valued discrete cosine is the *interpretation*, not the identity

The Walsh characters `χ_i(j) = (−1)^{⟨i,j⟩}` take **only the two values `+1, −1`**. The rebuild
reads this as a "cosine" because:

- In the continuous world, `cos θ = Re(e^{iθ})` is the real part of a character; the finite
  group `(Z₂)ⁿ` has **real** characters, and each is a homomorphism into `{±1}`. So the "angle"
  is collapsed to `θ ∈ {0, π}` — aligned (`+1`) vs anti-aligned (`−1`).
- `cos θ = +1`/`−1` are the *two extreme values* of the cosine: the kernel distinguishes
  "same direction" from "opposite direction" and **cannot** represent any intermediate angle
  (60°, 120°, …). It is a *sign-only* cosine.

So `cos θ ≡ (−1)^popcount(i&j)` is **OURS as a naming**: the *identity* `(−1)^popcount(i&j)
= (−1)^{⟨i,j⟩} = WHT entry` is DIRECT, but calling that entry "cos θ" is the rebuild's
interpretation. It is the "discrete cos" **of the hypercube**, a 2-valued object. The phrase
"parity as the bivector sign" in `GA_INSTRUCTIONS.md` is loose — see §5.1 (the parity is the
*scalar* sign ±1; the *bivector* is the sin/orientation half).

### 1.3 Why it is "the graph Fourier transform of the hypercube" — DIRECT

The hypercube is a **Cayley graph** of the group `(Z₂)ⁿ`. Pontryagin duality for finite abelian
groups says: the group's characters (= the Walsh functions) are the eigenvectors of *every*
operator that is translation-invariant under `⊕` (every convolution / XOR-kernel `g[i ⊕ j]`).
The WHT is therefore the **group Fourier transform**: it diagonalizes any kernel that depends
only on `i ⊕ j`. This is stated as PROVEN in `docs/surveys/spectral-graph-theory.md`
("`(Z₂)³²` is a Cayley group; its characters are the Walsh functions; the WHT is the group
Fourier transform") and in `ox alpha.md` proven-identity #3 ("XOR kernel = WHT = graph Fourier
transform of the hypercube … and literally rule-90 CA").

**The undirected/directed split** (also from `spectral-graph-theory.md`): the *real* WHT is the
Fourier transform of the **undirected** hypercube (characters are real ⇒ no imaginary part).
The **directed** (wedge / `O_ab − O_ba`) content generalizes to *complex* characters — phase
winding — via the gauge paper (cited there as `2605.15863`: similarity transform to a circulant
makes eigenvectors the Fourier characters; a diagonal-unitary gauge is a **Fourier shift**).
This is the precise sense in which "cos = the real/undirected part, sin = the directed/wedge
part."

---

## 2. The Eisenstein map — does Z₆ connect parity (mod 2) to 60° (mod 6)?

### 2.1 What `CrtHex` proves — DIRECT

`proofs/lean-src/hexagon/Hexagon/CrtHex.lean` proves two things (both `lake build` green):

1. **The six units factor as sign × 3-cycle:** `signCycleMul : sign × cycle → units` is a
   bijection, where `sign = {±1}` (the mod-2 part) and `cycle = {1, ω, ω²}` (the mod-3 part).
   Every one of the six 60° rotations `±1, ±ω, ±ω²` is `±1 · ωᵏ`.
2. **The CRT bijection on the angle index:** `mod6_iff_mod2_mod3 : Fin 6 ≃ Fin 2 × Fin 3`,
   `n ↦ (n mod 2, n mod 3)`, with inverse `(a,b) ↦ 3a + 4b (mod 6)`.

So the Z₆ angle (60° rotation) is *exactly* a `Z₂ × Z₃` pair: the **sign** (mod 2) times the
**cycle position** (mod 3).

### 2.2 The balanced-ternary instantiation of the CRT — DIRECT (identity), mostly not yet in Lean

For a balanced-ternary number `n = Σ tᵢ 3ⁱ` with digits `tᵢ ∈ {−1, 0, +1}`:

```
n mod 3 = t₀                       (since 3ⁱ ≡ 0 (mod 3) for i ≥ 1)
n mod 2 = (Σ tᵢ) mod 2             (since 3ⁱ ≡ 1 (mod 2))
n mod 6 = ( (Σ tᵢ) mod 2 ,  t₀ )   (by CRT; 2 and 3 coprime)
```

This is the *hex-lattice analog of popcount parity*: binary computes `popcount(i & j) mod 2`
as a second XOR-fold; balanced ternary reads the **sign of the balanced digit-sum** `S = Σ tᵢ`
(already signed) and the least-significant trit `t₀`, and `n mod 6` falls out. **[DIRECT as
arithmetic — stated in `docs/compute/trit_tricks.md` rows 1–2; the *Lean* statement
`n mod 6 = (S mod 2, t₀)` is a target, not yet in-tree — see §4.]**

### 2.3 Answer: parity is the *sign half* of the Z₆ angle, not the whole angle

- **Does the CRT connect popcount parity (mod 2) to the 60° rotation (mod 6)?** **Yes, but only
  as half the bridge.** The parity is the `Z₂` factor — the `±1` sign of the unit — and the CRT
  lifts it to a full mod-6 angle *only when the mod-3 (3-cycle) component is also supplied*.
  Parity alone is a `Z₂` object with no `Z₃` content; it cannot by itself distinguish `ω` (60°)
  from `ω²` (120°). **[DIRECT: the CRT bridge is proved. ANALOGY: "parity ⇒ 60° rotation" — the
  parity is one coordinate of the pair, not the pair.]**

- **Is the XOR kernel the "discrete cos" of the hex lattice?** **No — it is the discrete cos of
  the hypercube, a 2-valued sign.** The hex lattice's own discrete cosine is 6-valued: the real
  parts of the six units `Re(ωᵏ) ∈ {1, 1/2, −1/2, −1}` (in the ℂ embedding of
  `OmegaEmbedding.lean`). The XOR kernel's `±1` captures exactly the **sign** of that hex
  cosine — the `mod 2` / `±1` factor of `CrtHex` — and collapses the four intermediate angles to
  nothing. So the honest statement is:

  > **The XOR kernel's parity is the *sign* (mod-2 factor) of the hex cosine, i.e. it is the
  > `Z₂` component of the `Z₆ ≅ Z₂ × Z₃` angle. The full "discrete trig" of the hex lattice is
  > `Z₆ = Z₂ (XOR parity) × Z₃ (the ω-cycle)`.** **[OURS as the mapping; the two ingredients
  > — the parity identity and the CRT — are each DIRECT.]**

### 2.4 The integer-valued dot, and a convention warning

The project's own dot/wedge (`DotWedge.lean`) defines `dot z w = (z · conj w).a` and
`wedge z w = (z · conj w).b` — the two **integer coordinates** of the product, **not** the
Euclidean `Re`/`Im`. With `ω = e^{iπ/3} = 1/2 + i√3/2`, the Euclidean real part is `a + b/2`,
so the a-coordinate `dot` is offset from `Re` by `wedge/2` (`dot_swap : dot z w = dot w z +
wedge w z` — the file explicitly records that the naive "dot commutes" claim is FALSE). Do not
conflate "dot = a-coordinate" (integer, what `DotWedge` proves) with "cos θ = Re" (rational, the
6-valued discrete cosine). **[DIRECT — the convention; flagged to prevent exactly the
half-integral mistake `DotWedge` documents.]**

---

## 3. The barrel shift `d >> 1` — RG/scale-change, and its lattice map

### 3.1 What `d >> 1` is — DIRECT (the algebra), and PROVEN (the RG reading)

`d >> 1` is the right-shift by one bit: drop the least-significant bit, i.e. integer division by
2 (`⌊d/2⌋`). In the rebuild, `d` is an index on the u32 address space `G₃₂ = Z₂/2³²Z₂` (often
`d = i ⊕ j`), and the shift moves between **ring bands** (the coarse-graining levels). The RG
survey (`AGENTS.md`, `docs/surveys/renormalization-group.md`) records it as **PROVEN**:

> "the bit-shift `d >> 1` **IS** the 2-adic hierarchical RG blocking step … `G_32 = Z₂/2³²Z₂`,
> `d >> 1 = Λ_{l,l−1}` (the truncation map, drop the least-significant digit), and the XOR
> kernel is the ultrametric kernel. Coarse-graining on a tree is *exact* (block = common
> prefix)."

The algebraic statement (right-shift = drop LSB = the projection `Z₂/2³²Z₂ → Z₂/2³¹Z₂`) is
trivial and Lean-provable; the *label* "this is the RG blocking step" is the literature match
(cited, not re-derived here).

### 3.2 Does it correspond to ×ω or ÷ω? — **Neither: it is a scale change, and ω is a rotation**

The key structural fact: **`ω` is a unit** (`N(ω) = 1`), so `×ω` and `÷ω = ×ω⁻¹` are **rotations
by ±60°** — they do **not** change the norm, hence are **not** scale changes. `×ω` is exactly the
`TROT` instruction (`(a,b) ↦ (−b, a+b)`, a negate + an add, no multiplies — `Rotation.lean` +
`trit_tricks.md` row 4). So:

| object | lattice primitive | norm change | nature |
|---|---|---|---|
| `d >> 1` (binary ÷2) | **trit right-shift ÷3** (`d = i ⊞ j`, drop least-significant trit) | ÷3 (ring band) | scale change |
| `d >> 1` (binary ÷2) | **aperture-7** (`× (2+ω)`, `N(2+ω)=7`; base-7 digit drop) | ÷7 | hex self-similar scale |
| `×ω` / `÷ω` | `TROT` (Z₆, 60°) | ×1 (unit) | rotation, **not** scale |

- The **ternary analog** of the binary barrel shift is **trit-shift ÷3** (one trit-shift zooms
  3× in scale vs binary's 2×, so `log₃` vs `log₂` = a `1/1.585 ≈ 0.63×` reduction in shift
  count). **[`trit_tricks.md` row 6 — the rebuild's `d>>1`=ring×2 is OURS, the ternary ÷3 is
  ANALOGY, "fewer shifts" is DIRECT (`log₃ < log₂`).]**
- The **hex self-similar scale change** is **aperture 7** (`2+ω`, norm 7) — the `7ⁿ` fractal
  addressing already proved in `FractalRam.lean` (`parent`/`child` = append/drop a base-7 digit;
  `parent_fiber_card`; `level_succ_card`). Dropping a base-7 digit is *the* hex analog of
  `d >> 1`, and it is already Lean-proved. **[DIRECT — `FractalRam.lean`.]**
- The intermediate aperture **3** (`1+ω`, `N(1+ω)=3`, rotate 30° + dilate √3) is the geometric
  form of the trit-shift ÷3. **[DIRECT arithmetic; not needed for the two target instructions
  but pins down the norm-3 lattice dilation.]**

### 3.3 Two come-to-terms traps (both already flagged in-tree, re-stated here)

1. **"barrel shifter" is a homonym.** In the *hex* conversation (`hexigon_conversation.md`,
   `hexigon_lens.md`) "barrel shifter" means the **60°-rotation hardware** (TROT). In the
   *rebuild* it means the **RG `d >> n` scale shifter**. These are different objects; `TBARREL`
   is the rebuild's (RG) sense. Do not map `TBARREL` onto `TROT` — they sit on different axes
   (scale vs rotation).
2. **The gauge group is abelian, so "register shift = rotor" is retired.** The scale gauge is
   `R⁺` (or `2^ℤ ≅ ℤ` for the barrel shift) — **abelian**, zero structure constants; the
   non-commutativity lives in the transition matrix (wedge/time-order), not in the scale gauge.
   So `d >> 1` is a **gauge change of scale**, not a rotor. **[`AGENTS.md` / `survey/agents_graph.md`
   edge N123→N80.]**

---

## 4. Lean-provable theorems vs cited facts

### 4.1 Already proved in-tree (DIRECT, `lake build` green)

| theorem | file | content |
|---|---|---|
| `mod6_iff_mod2_mod3`, `modPair_bijective` | `CrtHex.lean` | the CRT bijection `Fin 6 ≃ Fin 2 × Fin 3` (the mod-6 ↔ mod-2×mod-3 bridge) |
| `signCycleMul_{surjective,injective}` | `CrtHex.lean` | `Z₆ ≅ Z₂ × Z₃`: every unit is `±1 · ωᵏ` |
| `units_card`, `units_closed_under_mul` | `Rotation.lean` | the six 60° units form Z₆ |
| `omega_sq_rel`, `phi_mul`, `phi_omega`, `phi_injective` | `OmegaEmbedding.lean` | `ω = e^{iπ/3}` embeds ℤ[ω] as the 60° lattice |
| `conj_involutive`, `mul_conj_eq_norm` | `Conjugate.lean` | `conj(a,b)=(a+b,−b)`; `z·conj z = N(z)` |
| `gp_decomp`, `wedge_antisymm`, `dot_sq_add_wedge_sq`, `dot_swap` | `DotWedge.lean` | the dot/wedge split + Pythagorean identity (and the *corrected* non-commuting dot) |
| `signFold_*`, `toNat_bijective`, `eisensteinEquiv`, `toNat_lt_two_pow_32` | `Bijection.lean` | hex↔u32 (Szudzik) address bijection |
| `parent`, `parent_fiber_card`, `level_succ_card`, `levelOneEquiv` | `FractalRam.lean` | the 7ⁿ aperture-7 fractal addressing (= hex analog of `d >> 1`) |
| `sum_invariant`, `units_counting_normalized` | `Haar.lean` | counting measure = Haar for the Z₆ action |

### 4.2 Lean-provable but **not yet in-tree** (targets, all small and integer-native)

| target theorem | statement | difficulty |
|---|---|---|
| **popcount-parity identity** | `(−1)^popcount(i & j) = (−1)^{⟨i,j⟩}`, i.e. the WHT entry is the parity of the AND | easy — induction over bits; `Nat`/`Fin (2ⁿ)` + `Nat.testBit` |
| **WHT = n-fold Hadamard product** | `H = H₂^⊗n`, so `H` is involutive/orthogonal up to scale (`H·Hᵀ = 2ⁿ I`) | moderate — Kronecker product over `Fin (2ⁿ)` |
| **balanced-ternary CRT instance** | `n mod 6 = ((Σ tᵢ) mod 2, t₀)` for `n = Σ tᵢ 3ⁱ` | easy — `3ⁱ ≡ 1 (mod 2)`, `3ⁱ ≡ 0 (mod 3)`, CRT |
| **`n mod 3 = t₀` / `parity(n) = parity(S)`** | the two free trit tricks of `trit_tricks.md` row 10/2 | easy — positional arithmetic |
| **shift = truncation map** | `d >> 1` as the projection `Z₂/2³²Z₂ → Z₂/2³¹Z₂` (drop LSB) | easy — `Nat.shiftRight`/`2-adic valuation` |
| **aperture-3 = norm-3 dilation** | `N(1+ω) = 3`, `arg(1+ω) = π/6` | easy — `OmegaEmbedding` + `norm` |

### 4.3 Cited facts (literature matches, NOT independently re-derived here)

| fact | source | status |
|---|---|---|
| XOR kernel `g[i⊕j]` = WHT = GFT of `(Z₂)³²` (Pontryagin duality) | `docs/surveys/spectral-graph-theory.md` | PROVEN (survey) |
| XOR kernel = WHT `H^⊗n`, matrix `(−1)^{x·y}`; DJ/BV/Simon domain | `docs/surveys/quantum-algorithms.md` | PROVEN (survey) |
| directed/complex generalization: circulant similarity + diagonal-unitary gauge = Fourier shift | `spectral-graph-theory.md` (gauge paper `2605.15863`) | PROVEN (survey) |
| `d >> 1` = 2-adic hierarchical RG blocking step (`G₃₂ = Z₂/2³²Z₂`) | `docs/surveys/renormalization-group.md` (via `AGENTS.md`) | PROVEN (survey) |
| `ℂ^{2³²}` = Cartan subalgebra of `Cℓ₀,₃₂`; Clifford is C*-algebra; Gottesman–Knill ⇒ present-but-inert | `docs/surveys/operator-algebras.md` | PROVEN (survey) |

**Note on the arXiv IDs** (`2605.15863`, `2604.20078`, etc.): they are quoted from the in-tree
survey write-ups; this task did **not** re-read the primary papers, so they are attributed to the
surveys, not independently verified.

---

## 5. Calibration summary (one line each)

| claim | verdict |
|---|---|
| `(−1)^popcount(i&j) = (−1)^{⟨i,j⟩}` = WHT entry | **DIRECT** (definition) |
| XOR kernel = WHT = graph Fourier transform of the hypercube | **DIRECT** (Pontryagin; survey PROVEN) |
| "cos θ ≡ (−1)^popcount(i&j)" — naming the ±1 entry a "cosine" | **OURS** (2-valued sign-only cos; the rebuild's reading) |
| parity (mod 2) = the sign factor of the Z₆ angle | **DIRECT** via `CrtHex` (`Z₆ ≅ Z₂ × Z₃`) |
| "parity ⇒ 60° rotation" (parity *alone* gives the angle) | **ANALOGY** — parity is one CRT coordinate, not the pair |
| "XOR kernel = the discrete cos *of the hex lattice*" | **SPECULATION/OURS** — it is the *sign* of the hex cos, not the 6-valued hex cos |
| `d >> 1` = 2-adic RG blocking step | **DIRECT** (survey PROVEN) |
| `d >> 1` = `×ω` or `÷ω` | **NO** — `ω` is a unit; `×ω` is TROT (rotation, norm 1), `d>>1` is a scale change |
| `d >> 1` ↔ trit-shift ÷3 / aperture-7 (`× (2+ω)`) | **ANALOGY** (÷3) / **DIRECT** (aperture-7 = `FractalRam.lean`) |
| barrel shift = a rotor / non-abelian gauge | **RETIRED** — the scale gauge `2^ℤ` is abelian |
| "the barrel shifter replaces transcendental functions" | **OURS** (hex: exact Z₆ arithmetic — true of TROT, a different object than TBARREL) |
| "hex addressing replaces the u32 XOR kernel" | **SPECULATION** — blocked in `proofs/INDEX.md` (B1 proved the bijection; the *replacement* is not established) |

### 5.1 The "bivector sign" phrase, corrected

`GA_INSTRUCTIONS.md` writes "parity as the bivector sign." In the GA split the parity `±1` is the
**scalar** part's sign (`cos θ = ±1`); the **bivector** is the sin/orientation half (`I·sin θ`),
which on the *undirected* hypercube is zero (characters are real) and only appears in the
*directed* (wedge) generalization. So "parity = bivector sign" is a loose OUR phrasing; the
clean statement is "parity = the sign of the scalar cos, and the sin/orientation half lives in
the directed wedge." **[OURS — wording; the underlying split is DIRECT (`DotWedge.lean`,
`spectral-graph-theory.md`).]**

---

## Sources

- `/home/ian/opencode/parser/english/docs/surveys/spectral-graph-theory.md` — XOR = GFT of the
  hypercube; wedge = non-Hermitian; band gap = ridge (not Cheeger).
- `/home/ian/opencode/parser/english/docs/surveys/operator-algebras.md` — ℂ^{2³²} = Cartan
  subalgebra of Cℓ₀,₃₂; Clifford = C*-algebra.
- `docs/GA_INSTRUCTIONS.md` — the `TXOR`/`TBARREL` tier-2 spec (this survey's subject).
- `proofs/lean-src/hexagon/Hexagon/{CrtHex,Rotation,Conventions,OmegaEmbedding,Conjugate,
  DotWedge,Bijection,FractalRam,Haar}.lean` — the in-tree proofs cited in §4.1.
- `docs/compute/trit_tricks.md` — the bit-trick ↔ trit-trick catalog (rows 1–6, 10).
- `docs/TERNARY_COMPUTE_SURVEY.md` — the trit-tricks hypothesis and the `(−1)^popcount` anchor.
- `AGENTS.md` (this project) + `ox alpha.md` — the proven-identities ledger and the
  `renormalization-group` / `quantum-algorithms` survey summaries (§4.3).
- `survey/hexigon_lens.md`, `survey/SYNTHESIS.md` (Q1), `survey/agents_graph.md` (N123→N80) — the
  Eisenstein-vs-hypercube ANALOGY and the "barrel shifter"/"ring" homonym and abelian-gauge
  retirements.

## TODO / not covered / caveats

1. **The `n mod 6 = (S mod 2, t₀)` balanced-ternary instance is not yet in Lean.** It is the
   single highest-value proof target for this survey (§4.2) — it *is* the ternary CRT bridge the
   whole argument rides on, and it is currently asserted in `trit_tricks.md`, not proved.
2. **The WHT / popcount-parity Lean targets are open.** No `Walsh.lean` / `Hypercube.lean` exists
   in `Hexagon/`; the "XOR kernel = WHT" identity is cited, not formalized. A `Fin (2ⁿ)` Walsh
   character + orthogonality file would close the DIRECT core.
3. **The hex "discrete cos" is not defined as a first-class object.** The 6-valued cosine
   `Re(ωᵏ) ∈ {1, ±1/2, −1}` (and its integer `dot`/a-coordinate variant) has no in-tree theorem
   connecting it to `CrtHex`'s `Z₂ × Z₃` decomposition. This is the gap between "XOR parity = the
   sign factor" (stated here) and a *proved* "hex cos ≅ Z₂ × Z₃" theorem.
4. **"Hex addressing replaces the u32 XOR kernel" stays SPECULATION and BLOCKED** (`proofs/INDEX.md`
   row "hex ↔ u32"; `Bijection.lean` proved only the bijection, which *enables* testing the
   replacement, not the replacement itself). Nothing in this survey un-blocks it.
5. **arXiv IDs quoted secondhand.** `2605.15863`, `2604.20078`, etc. come from the survey
   write-ups; the primary papers were not re-read for this task. Verify before citing them
   outside the repo.
6. **Not covered:** the Tier-3 instructions (`TSPINOR`, `THODGE`, `TGRAD`); the sin/wedge
   "discrete trig" beyond the undirected cos; the directed complex spectrum (the `spectral-graph`
   survey's stated next test); any energy/area costing of a physical `TXOR`/`TBARREL` datapath
   (the `TMUL`-style `yosys` measurement was **not** run here).
