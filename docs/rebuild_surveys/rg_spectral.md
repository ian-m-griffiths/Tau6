# RG + Spectral-Graph-Theory — 2-pass survey, calibrated to the Tau (Eisenstein/ternary) lattice

**2026-08-29.** Two-pass deep-dive of the rebuild's two survey write-ups,
`renormalization-group.md` and `spectral-graph-theory.md` (source:
`/home/ian/opencode/parser/english/docs/surveys/`), calibrated against OUR lattice
(`CrtHex.lean` Z₆ ≅ Z₂ × Z₃, `Bijection.lean` hex ↔ u32, `FractalRam.lean` 7ⁿ, and the
barrel/TROT distinction in `xor_barrel.md`).

Calibration legend (repo standard, mark at mapping time):

- **DIRECT** — measured, proved (`lake build` green), or a textbook identity. Cite the file/theorem.
- **ANALOGY** — structural resemblance, not identity. The shapes match; the objects differ.
- **OURS** — our design claim; follows from DIRECT but is not independently established.
- **SPECULATION** — untested hypothesis; never stated as fact.

---

## Pass 1 — MAP (source claims, description-only, with the sources' own verdicts)

### 1.1 `renormalization-group.md` (159 papers → 34 conceptual; the p-adic/RG/DFT survey)

| # | Claim | Rebuild's own verdict |
|---|---|---|
| RG1 | The bit-shift `d >> 1` **IS** the 2-adic hierarchical RG blocking step: `G₃₂ = Z₂/2³²Z₂`, truncation map `Λ_{l,l−1}` (drop LSB) = the barrel shift; the XOR kernel `g[i⊕j]` is the ultrametric (Dyson-type) kernel on `(Z₂)³²`. Block = common prefix ⇒ one decimation = one exact step. | **PROVEN** (strongest match; p-adic paper 2601.19070) |
| RG2 | `ρ(w)` (surviving fraction per band) = a density of states `μ(λ)`, NOT a running coupling / anomalous dimension. The anomalous dim is the *signal-induced change* `ΔD`. | **ANALOGY** (correct object = density) |
| RG3 | band gap = fixed point / critical point | **SPECULATION (retracted)** |
| RG4 | band gap = Wilson sharp cutoff `Λ_cutoff` | **ANALOGY** (defensible) |
| RG5 | the `p ∈ {1,2,4,8}` sweep = an RG flow | **ANALOGY** (scale sweep, no renormalization; "M5 RG flow" over-claims) |
| RG6 | "multifractal = monofractal + time dilation" | **SPECULATION** (it's a subordination/gauge of RG time) |
| RG7 | band-gap pruning = monotone RG flow (a c/F-theorem) | **SPECULATION** (no β-function, no Zamolodchikov metric) |
| RG8 | "least squares = least action" | **PROVEN** as an *identity* (`log∏ = Σlog`), NOT an irreversibility theorem |
| RG9 | ring bands = the RG scale shells (`t = log₂ rank`) | **PROVEN** (structural) |
| RG10 | Data Field Theory's "dimensional phase transition": propagator = eigenvalue spectrum; signal changes canonical dimension `D`; detection = `D` crossing 4 | **UNPROVEN here**, flagged as "the untapped gift" |

### 1.2 `spectral-graph-theory.md` (32 papers; Laplacian/GSP/non-Hermitian/Szegedy)

| # | Claim | Rebuild's own verdict |
|---|---|---|
| S1 | The XOR kernel `g[i⊕j]` **IS** the graph Fourier transform of the hypercube `(Z₂)³²`: Cayley group → Walsh characters → WHT = group Fourier transform; any ⊕-translation-invariant kernel is diagonalized by it (Pontryagin duality). | **PROVEN** |
| S2 | The directed/complex generalization: similarity to a circulant makes eigenvectors the Fourier characters; a diagonal-unitary gauge = a **Fourier shift**. Real WHT = undirected GFT; wedge generalizes to complex characters (phase winding). | **PROVEN** (gauge paper 2605.15863) |
| S3 | The wedge `O_ab − O_ba` = the skew part = the **non-Hermitian** (complex-eigenvalue) content. `Δ = D − (A+Aᵀ)` annihilates `A − Aᵀ`; real skew ⇒ purely imaginary eigenvalues = rotation. | **PROVEN** (2607.18473, 2608.01766) |
| S4 | "flux = derivative" = the incidence/commutator `[L_x, A]_{ij} = (x_i − x_j) A_{ij}`; `Δ = K†K` (div∘grad). | **PROVEN (recast)** |
| S5 | "band gap = spectral gap λ₂ (Cheeger)" | **RETIRED** → ridge sparsification (2604.20078): `d_eff(γ) = Σ λ_i/(λ_i+γ)`; pruning = soft-threshold below the noise floor |
| S6 | "ring band = eigenvalue band"; "eigenbasis = Laplacian eigenvectors" | **ANALOGY** (ring is a χ² divergence; the cosine/Hessian eigenbasis lives on a *different* kernel) |
| S7 | eigenbasis clusters/separates domains | **PROVEN** (functional — spectral clustering) |

---

## Pass 2 — LENS (calibrate every claim against OUR lattice)

### 2.0 The central lens move: "PROVEN there" is against **their** base-2 lattice, not ours

Both surveys' PROVEN verdicts are self-assessed against the **rebuild's** object: the co-occurrence
residual graph on the Boolean hypercube `(Z₂)³²`, XOR kernel, u32 address space, 2-adic valuation.
Our object is the **Eisenstein integer lattice** `ℤ[ω]` (ω = e^{iπ/3}), balanced ternary (3-state,
digits {−1,0,+1}), the Z₆ unit group, and the 7ⁿ fractal hex RAM. Every "Boolean hypercube / XOR /
2-adic / WHT" identity assumes **base-2**; the Eisenstein thread is precisely the *non-binary*
generalization. So the calibration is not "PROVEN ⇒ we can cite it as a Tau theorem" — it is
"PROVEN in a base-2 frame ⇒ for us it is an ANALOGY to be instantiated on Z₃/Z₆, except where our
own Lean already proves the ternary statement directly."

Concretely, the three loads the surveys carry break down as:

| Load | Base-2-only content | What generalizes to ternary | Our verdict |
|---|---|---|---|
| barrel shift `d >> 1` | 2-adic truncation on `Z₂/2³²Z₂`; XOR kernel as ultrametric kernel | p-adic blocking for any prime p → **trit-shift ÷3** (3-adic); hex self-similar **aperture-7** (base-7 fractal) | see Q1 |
| XOR kernel / WHT | Walsh characters of `(Z₂)ⁿ`; 2-valued `±1`; `(−1)^popcount` | parity = the **Z₂ sign factor** of the **Z₆** angle (CRT); the full hex GFT is **6-valued**, not 2-valued | see Q2 |
| wedge = skew = non-Hermitian | skew part of a real adjacency on the hypercube | `wedge z w = (z·conj w).b` — **already** the anti-symmetric skew in our lattice; the imaginary/rotational half in the ℂ embedding | **DIRECT** (transfer is clean) |

---

## Q1 — Is the barrel-shift RG base-2-only, or does it generalize to ternary?

**Answer: the *theorem as proved* is base-2-only; the *construction* generalizes, and both ternary
instantiations are our ANALOGY (trit-shift ÷3) or our DIRECT combinatorics (aperture-7) — not the
source's theorem.**

1. **As stated, `d >> 1` = the 2-adic RG blocking step is base-2-only.** It is a statement about
   `p = 2`: `G₃₂ = Z₂/2³²Z₂`, the XOR/ultrametric kernel on `(Z₂)³²`, `d >> 1 = Λ_{l,l−1}`. It does
   **not** transfer to ternary as a theorem — it would be a category error to cite it as one.

2. **The generic p-adic construction (2601.19070) is for any prime p**, so the RG *blocking concept*
   generalizes, one instance per base. `p = 3` is prime ⇒ `Z₃` is a field ⇒ the 3-adic hierarchy is
   clean:
   - **trit-shift ÷3** = drop the least-significant trit of `d = i ⊞ j` (mod-3 addition, GF(3)) —
     the exact ternary analog of `d >> 1 = ⌊d/2⌋`. One trit-shift zooms 3× in scale vs binary's 2×,
     so `log₃` vs `log₂` = `1/1.585 ≈ 0.63×` fewer shifts to span the same ring range.
     **[ANALOGY for the RG label; DIRECT for the arithmetic `⌊d/3⌋` and for `log₃ < log₂`.]**
   - **aperture-7** (`× (2+ω)`, `N(2+ω) = 7`; drop a base-7 digit) = the hex lattice's *own*
     self-similar refinement (H3 / DGGS aperture-7). This is **already DIRECT-proved** in
     `FractalRam.lean` (`parent` = drop the last base-7 digit, `child` = append one of 7 digits,
     `parent_fiber_card`, `level_succ_card`). It is "the hex analog of `d >> 1`" in the sense of
     *drop the least-significant digit* — but it is a **2D fractal refinement**, not a 1D p-adic
     decimation. Do not equate the two.

3. **The barrel/TROT distinction (come-to-terms — the single most important trap).** `ω` is a unit
   (`N(ω) = 1`), so `×ω` / `÷ω` are **rotations by ±60°** — norm-preserving — which is `TROT`
   (`(a,b) ↦ (−b, a+b)`, `Rotation.lean`). They are **not** scale changes. The ternary barrel shift
   is therefore **trit-shift ÷3** (or aperture-7), **never** `×ω`. `TBARREL` (RG scale) and `TROT`
   (rotation) sit on different axes. (Also retired: "barrel shift = a rotor" — the scale gauge
   `3^ℤ`/`2^ℤ` is abelian; see `xor_barrel.md` §3.3.)

Bottom line for Q1: base-2-only as a *theorem*; generalizes as a *construction* to trit-shift ÷3
(3-adic, ANALOGY) and aperture-7 (base-7 fractal, DIRECT-proved); and it is a **scale** change,
never the Z₆ rotation.

---

## Q2 — Is the XOR kernel's parity the Z₂ SIGN of the Z₆ angle? The ternary instantiation.

**Answer: yes — the parity is exactly the `Z₂` factor (the sign ±1) of the `Z₆ ≅ Z₂ × Z₃` angle, and
it is *half* the bridge, not the whole angle.**

`CrtHex.lean` proves the CRT bijection `Fin 6 ≃ Fin 2 × Fin 3`, `n ↦ (n mod 2, n mod 3)`, with inverse
`(a,b) ↦ 3a + 4b (mod 6)` (`mod6_iff_mod2_mod3`, `modPair_bijective`, `crtInv`). The six units are
`±1 · {1, ω, ω²}` (`signCycleMul_surjective`/`_injective`). So the Z₆ angle decomposes as:

```
n mod 2  =  sign (∈ {±1})      ← the parity / XOR-kernel half
n mod 3  =  cycle (∈ {1,ω,ω²}) ← the mod-3 half
```

- **Parity = the Z₂ sign factor** — DIRECT (via `CrtHex`).
- **"parity alone ⇒ a 60° rotation"** — **ANALOGY**. Parity is one CRT coordinate; it cannot
  distinguish `ω` (60°) from `ω²` (120°), or `+ωᵏ` from `−ωᵏ`'s *magnitude* direction. It is the
  sign of the unit, not the pair.
- **"XOR kernel = the discrete cos *of the hex lattice*"** — **SPECULATION/OURS**. The hex lattice's
  own discrete cosine is **6-valued**: `Re(ωᵏ) ∈ {1, 1/2, −1/2, −1}` (the ℂ embedding of
  `OmegaEmbedding.lean`). The XOR kernel's `±1` captures the **sign** of that cosine (the mod-2
  factor) and collapses the four intermediate angles to nothing.

**The ternary instantiation** (`xor_barrel.md` §2.2; the task's `n mod 6 = ((Σtᵢ) mod 2, t₀)`):

For a balanced-ternary number `n = Σ tᵢ 3ⁱ`, digits `tᵢ ∈ {−1, 0, +1}`:

```
n mod 3 = t₀                      (3ⁱ ≡ 0 (mod 3) for i ≥ 1)
n mod 2 = (Σ tᵢ) mod 2            (3ⁱ ≡ 1 (mod 2))
n mod 6 = ( (Σ tᵢ) mod 2 ,  t₀ )  (CRT; 2 and 3 coprime)
```

This is the hex-lattice analog of popcount parity: binary computes `popcount(i & j) mod 2` as a
second XOR-fold; balanced ternary reads the **sign of the balanced digit-sum** `S = Σ tᵢ =
#(+1) − #(−1)` (already signed) plus the least-significant trit `t₀`, and `n mod 6` falls out. Note
`S mod 2 = #(nonzero trits) mod 2` (since −1 ≡ +1 (mod 2)) — so the ternary "popcount parity" is
exactly the parity of the nonzero-trit count.

**Two convention caveats (flag before quoting):**

1. `t₀` in `n mod 3 = t₀` must be read as the **mod-3 residue** {0,1,2}, not the raw balanced digit:
   `−1 ↦ 2, 0 ↦ 0, +1 ↦ 1` (the `PolarGate`/`PolarEncoding` residue convention, "residue 0=0, 1=+1,
   2=−1"). The `CrtHex` pair `(n.val % 2, n.val % 3)` is on the **nonnegative angle index** `Fin 6`.
2. `Σ tᵢ` is an integer; `(Σ tᵢ) mod 2` is its parity — the *sign* of the sum (its ±) is a separate
   object and is **not** what mod 2 reads.

**Status:** the arithmetic is **DIRECT** (positional + CRT); the *Lean* statement
`n mod 6 = ((Σ tᵢ) mod 2, t₀)` is a **TARGET**, not yet in-tree (see Q3). It is currently asserted in
`docs/compute/trit_tricks.md` rows 1–2, not proved.

---

## Q3 — Which identities are Lean-provable on OUR lattice, vs cited base-2 facts?

### 3.1 Already proved in-tree (DIRECT, `lake build` green — `proofs/INDEX.md`)

| Exact statement | File / theorem |
|---|---|
| The CRT bijection `Fin 6 ≃ Fin 2 × Fin 3`, `n ↦ (n mod 2, n mod 3)`, inverse `(a,b) ↦ 3a+4b (mod 6)` | `CrtHex.lean`: `mod6_iff_mod2_mod3`, `modPair_bijective`, `crtInv` |
| `Z₆ ≅ Z₂ × Z₃`: every unit is `±1 · ωᵏ`; `sign × cycle → units` is surjective + injective | `CrtHex.lean`: `signCycleMul_surjective`, `signCycleMul_injective`, `signCycle_card` |
| There are exactly six units, closed under multiplication (the Z₆ group) | `Rotation.lean`: `units_card`, `units_closed_under_mul` |
| The wedge is anti-symmetric; Pythagorean energy `dot² + dot·wedge + wedge² = N(z)N(w)`; the dot is **not** symmetric (`dot z w = dot w z + wedge w z`) | `DotWedge.lean`: `wedge_antisymm`, `dot_sq_add_wedge_sq`, `dot_swap`, `gp_decomp`, `dot_self`, `wedge_self` |
| `ω = e^{iπ/3}` embeds `ℤ[ω]` as the 60° lattice (ring homomorphism, injective); `ω² = ω − 1` | `OmegaEmbedding.lean`: `phi_add`, `phi_mul`, `phi_injective`, `phi_omega`, `omega_sq_rel` |
| Conjugate `conj(a,b)=(a+b,−b)` is an involution; `z·conj z = N(z)` | `Conjugate.lean`: `conj_involutive`, `conj_norm`, `conj_mul`, `mul_conj_eq_norm` |
| hex ↔ ℕ address bijection (Szudzik pairing); exact u32 box `pair < 2³²` | `Bijection.lean`: `hexPairEquiv`, `toNat_bijective`, `eisensteinEquiv`, `toNat_lt_two_pow_32`, `toNat_fin` |
| The 7ⁿ fractal address space; each parent has exactly 7 children; `7·7ⁿ = 7ⁿ⁺¹`; level-1 ≃ `Fin 7` | `FractalRam.lean`: `fractalAddress_card`, `parent_fiber_card`, `level_succ_card`, `level_succ_card_fiber`, `levelOneEquiv` |
| Counting measure is Haar for the Z₆ action; normalized = uniform 1/6 | `Haar.lean`: `sum_invariant`, `measure_invariant_card`, `units_counting_normalized`, `unit_inv`, `mul_unit_bijective` |

These are the **ternary-native** analogues of the surveys' loads: the CRT gives the Z₆ = Z₂×Z₃ that
generalizes the XOR parity; `DotWedge.lean` gives the wedge = skew (S3/S4, transferred cleanly);
`FractalRam.lean` gives the aperture-7 form of "drop the least-significant digit" (RG1's *shape*).

### 3.2 Lean-provable but **not yet in-tree** (targets — all small, integer-native)

| Target theorem | Statement | Difficulty |
|---|---|---|
| **balanced-ternary CRT instance** (highest value) | `n mod 6 = ((Σ tᵢ) mod 2, t₀)` for `n = Σ tᵢ 3ⁱ`, `tᵢ ∈ {−1,0,+1}` (with the residue convention of Q2) | easy — `3ⁱ ≡ 1 (mod 2)`, `3ⁱ ≡ 0 (mod 3)`, CRT |
| **`n mod 3 = t₀`** | the LSB-trit read | easy — positional arithmetic |
| **`parity(n) = parity(Σ tᵢ)`** | ternary popcount parity = parity of the digit-sum (= parity of nonzero-trit count) | easy |
| **trit-shift ÷3 = 3-adic truncation** | drop the LSB trit = the projection on `Z₃`/`ZMod 3` (the ternary analog of `d >> 1`) | easy — `Nat`/`ZMod 3` |
| **popcount-parity identity** | `(−1)^popcount(i&j) = (−1)^{⟨i,j⟩}` (the WHT entry is the parity of the AND) | easy — `Nat.testBit` induction |
| **WHT = n-fold Hadamard** | `H = H₂^⊗n`, orthogonal up to scale `H·Hᵀ = 2ⁿ I` | moderate — Kronecker over `Fin (2ⁿ)` |
| **aperture-3 = norm-3 dilation** | `N(1+ω) = 3`, `arg(1+ω) = π/6` | easy — `OmegaEmbedding` + norm |
| **aperture-7 = norm-7 dilation** | `N(2+ω) = 7` (the multiplier behind `FractalRam`'s 7ⁿ) | easy — norm arithmetic |

Note the two targets that close the *ternary* side of the bridge (`n mod 6 = ((Σtᵢ) mod 2, t₀)` and
trit-shift ÷3) are **not** in `xor_barrel.md` §4.2 verbatim as a pair — §4.2 lists the CRT instance
and the *binary* `d >> 1` truncation map; the **trit-shift ÷3 truncation** is the natural ternary
twin and is added here as a target.

### 3.3 Cited base-2 facts (literature matches — NOT independently re-derived here)

| Fact | Source | Status |
|---|---|---|
| XOR kernel `g[i⊕j]` = WHT = GFT of `(Z₂)³²` (Pontryagin duality) | `spectral-graph-theory.md` | PROVEN there; base-2-only |
| directed/complex generalization: circulant similarity + diagonal-unitary gauge = Fourier shift | `spectral-graph-theory.md` (2605.15863) | PROVEN there; base-2-only |
| wedge = skew = non-Hermitian (complex eigenvalues; `Δ = D−(A+Aᵀ)` annihilates `A−Aᵀ`) | `spectral-graph-theory.md` (2607.18473, 2608.01766) | PROVEN there; **transfers cleanly** (our `wedge_antisymm`) |
| flux = incidence commutator `[L_x, A]` | `spectral-graph-theory.md` | PROVEN there (recast) |
| band-gap pruning = ridge sparsification (`d_eff(γ) = Σ λ_i/(λ_i+γ)`) | `spectral-graph-theory.md` (2604.20078) | PROVEN there; base-2 kernel |
| `d >> 1` = 2-adic hierarchical RG blocking step (`G₃₂ = Z₂/2³²Z₂`) | `renormalization-group.md` (2601.19070) | PROVEN there; base-2-only |
| `ℂ^{2³²}` = Cartan subalgebra of `Cℓ₀,₃₂`; Clifford = C*-algebra | `operator-algebras.md` | PROVEN there; base-2-only |

**arXiv IDs are secondhand** — quoted from the survey write-ups; the primary papers were not re-read
for this task. Verify before citing outside the repo.

---

## The calibrated master map (rebuild verdict → OUR verdict)

| Claim | Rebuild | Ours | Why |
|---|---|---|---|
| `d >> 1` = 2-adic RG blocking | PROVEN | **DIRECT there, base-2-only here** | theorem is about p=2; no ternary transfer |
| trit-shift ÷3 = the RG scale change | (n/a) | **ANALOGY** (3-adic) + DIRECT (`⌊d/3⌋`, `log₃<log₂`) | our instantiation of the p-adic construction |
| aperture-7 = hex self-similar scale | (n/a) | **DIRECT** (`FractalRam.lean`) | proved combinatorics; 2D refinement, not 1D p-adic |
| `×ω`/`÷ω` = the barrel shift | (tempting) | **NO — retired** | `ω` is a unit; `×ω` = TROT (rotation), not scale |
| barrel shift = a rotor | (n/a) | **RETIRED** | scale gauge `3^ℤ`/`2^ℤ` is abelian |
| XOR kernel = WHT = GFT of `(Z₂)³²` | PROVEN | **DIRECT there; base-2-only here** | Walsh characters of `(Z₂)ⁿ`, 2-valued |
| parity = the Z₂ sign of the Z₆ angle | (n/a) | **DIRECT** (`CrtHex` `Z₆ ≅ Z₂×Z₃`) | parity = `n mod 2` coordinate |
| "parity alone ⇒ 60° rotation" | (n/a) | **ANALOGY** | one CRT coordinate, not the pair |
| "XOR kernel = discrete cos of the hex lattice" | (n/a) | **SPECULATION/OURS** | hex cos is 6-valued; XOR is its sign |
| `n mod 6 = ((Σtᵢ) mod 2, t₀)` | (n/a) | **DIRECT** arithmetic, **TARGET** in Lean | asserted in `trit_tricks.md`, unproved |
| wedge = skew = non-Hermitian | PROVEN | **DIRECT — transfers cleanly** | our `wedge_antisymm` IS the skew part |
| flux = incidence commutator `[L_x,A]` | PROVEN (recast) | **ANALOGY** | our flux is `O−E` residual; the commutator is the *shape*, not the object |
| band gap = spectral gap λ₂ (Cheeger) | RETIRED | **retired, agree** | noise-floor cutoff, not algebraic connectivity |
| band-gap pruning = ridge sparsification | PROVEN | **ANALOGY** | `d_eff(γ)` is a base-2-kernel statement; the *soft-threshold* shape transfers |
| ring band = eigenvalue band | ANALOGY | **agree (ANALOGY)** | ring is a χ² divergence, not a Laplacian eigenvalue |
| band gap = RG fixed point / p-sweep = flow / monotone c-theorem | SPECULATION (retracted) | **retracted, agree** | no β-function / renormalization on our side either |
| multifractal = monofractal + dilation | SPECULATION | **agree (SPECULATION)** | subordination/gauge, not a collapse |

---

## TODO / not covered / caveats

1. **The ternary CRT instance `n mod 6 = ((Σ tᵢ) mod 2, t₀)` is not yet in Lean** — the single
   highest-value proof target of this survey. It *is* the ternary CRT bridge the whole argument
   rides on, and it is currently asserted in `docs/compute/trit_tricks.md` (rows 1–2), not proved.
2. **The trit-shift ÷3 = 3-adic truncation target is also open** — no `Trit.lean` / `ZMod 3`
   truncation file exists. It is the direct ternary twin of `d >> 1`, and it should be stated and
   proved before "barrel shift generalizes to ternary" can be upgraded from ANALOGY to DIRECT.
3. **The hex "discrete cos" is not a first-class object.** The 6-valued cosine `Re(ωᵏ) ∈
   {1, ±1/2, −1}` (and its integer `dot`/a-coordinate variant, offset from `Re` by `wedge/2` per
   `DotWedge.lean`) has no theorem connecting it to `CrtHex`'s `Z₂ × Z₃` decomposition. That gap
   separates "XOR parity = the sign factor" (stated here) from a *proved* "hex cos ≅ Z₂ × Z₃".
4. **The WHT / popcount-parity Lean targets are open** — no `Walsh.lean` / `Hypercube.lean` in
   `Hexagon/`. The "XOR kernel = WHT" identity is cited, not formalized.
5. **"Hex addressing replaces the u32 XOR kernel" stays SPECULATION and BLOCKED**
   (`proofs/INDEX.md` row B1): `Bijection.lean` proved the bijection, which *enables* testing the
   replacement, not the replacement. Nothing here un-blocks it.
6. **Base-2-only vs ternary is the governing split, not PROVEN vs ANALOGY.** The surveys' PROVEN
   verdicts are against the rebuild's `(Z₂)³²` object; they are PROVEN *there* and base-2-only
   *here*. The only loads that transfer **cleanly** to our lattice are the wedge = skew
   (`DotWedge.lean`) and the generic p-adic/fractal *shape* of coarse-graining; the XOR/WHT/2-adic
   *content* does not.
7. **arXiv IDs quoted secondhand.** `2601.19070`, `2605.15863`, `2607.18473`, `2608.01766`,
   `2604.20078` come from the survey write-ups; the primary papers were not re-read. Verify before
   citing them outside the repo.
8. **Not covered:** the Data Field Theory "dimensional phase transition" (RG10 — untapped in both
   the source and here, needs a spectral-dimension estimate on *our* ring bands); the directed
   complex spectrum (the spectral survey's stated next test — diagonalize the non-symmetric
   adjacency and read Im(Λ)); any energy/area costing of a physical `TXOR`/`TBARREL`/trit-shift
   datapath (no `yosys` measurement run here).
