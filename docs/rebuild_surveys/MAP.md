# MAP — the master calibrated map (rebuild ⟷ ternary/Eisenstein lattice)

**Date:** 2026-08-29.
**Method:** the two-pass deep-dive. Pass 1 (MAP) = read the eight top-ranked rebuild
write-ups end-to-end and extract their *core claims*. Pass 2 (LENS) = re-check each claim
against **our** framework — the Eisenstein integer lattice ℤ[ω] (ω=e^{iπ/3}, 60°), balanced
ternary {−1,0,+1}, residual r=O−E (the field), wedge = skew/curl, geometric product =
Eisenstein multiply, field calculus ∇F=J invertible / ∇² heat — and calibrate at mapping time.

**Calibration convention** (identical to the rebuild's own, but *re-anchored to the ternary
lattice*, not to the rebuild's `(Z₂)³²` Boolean hypercube):

| Label | Meaning here |
|---|---|
| **DIRECT** | equation-level identity; holds for a 3-state / hex lattice too (radix-agnostic) |
| **ANALOGY** | same *shape*, different object — usually base-2-specific (XOR / 2-adic / hypercube) with a ternary twin that must be rebuilt |
| **OURS** | we derived / implemented / proved it independently — it is already in `proofs/` or the RTL |
| **SPECULATION** | unproven on both sides |

**The single load-bearing correction inherited from `REBUILD_SURVEY.md` §5:** every rebuild
claim was self-calibrated against *its* lattice (`(Z₂)³²`). A rebuild-DIRECT claim that rests on
the Boolean hypercube / XOR / 2-adic structure is at best an **ANALOGY** for us, not DIRECT. The
Eisenstein thread is precisely the *non-binary* generalization, and the rebuild itself marks it
"NEW/unbuilt". We have since built and proved it — see §3.

---

## 1. The lens (our side, in one block)

- **Ring:** ℤ[x]/(x²−x+1), ω=e^{iπ/3}, ω²=ω−1, norm `N(a+bω)=a²+ab+b²` (multiplicative). `proofs/…/Conventions.lean`.
- **Units:** exactly six, `Z₆` (rotation = mod-6 angle add); `Z₆ ≅ Z₂×Z₃` = sign × 3-cycle = the spinor's grade structure. `Rotation.lean`, `CrtHex.lean`.
- **Embedding:** ω ↦ e^{iπ/3} is an injective ring homomorphism → the 60° lattice. `OmegaEmbedding.lean`.
- **Residual / field:** stored primitive r = O−E (directional, signed); `Σ(O−E)=0`; wedge = `O_ab−O_ba` (skew/curl), `wedge_antisymm`. `Residual.lean`.
- **Geometric product = Eisenstein multiply:** `z·w̄` splits into scalar (dot) + skew (wedge); `gp_decomp`. The dot is the symmetric part, the wedge is the anti-symmetric part — *not* bivector area. `DotWedge.lean`, `SymDot.lean`, `Conjugate.lean` (TCONJ).
- **Gauge = the unit's quadratic form:** four signatures `i² ∈ {−1,+1,0,ω}` → unit counts 4/4/2/6, zero-divisor vs nilpotent split. `Signature.lean`. The fold δ=(O−E)/E is gauge-invariant; χ² is not. `ChiSquareGauge.lean`, `Registers.lean`, `Gauge.lean`.
- **Field calculus:** `∇F=J` invertible (TGRAD **built** — `rtl/grad_recon.v`, `tgrad_cell`/`trecon_cell`, iverilog-verified); div and curl separately non-invertible. GA Maxwell on the hex lattice.
- **The honest hardware verdict** (`FINAL_VERDICT.md`): ternary buys *names* exponentially (`3ⁿ` vs `2ⁿ`, proved), moves bits cheaper (~2.7–6.3×, measured), computes more expensively (~1.5–2× floor, measured). The memory-engine win is **addressing, not arithmetic**.
- **Open:** "hex lattice replaces the u32 XOR kernel" is still SPECULATION (blocked on the address-translation theorem; `proofs/INDEX.md`).

---

## 2. Per-doc core claims → ternary calibration (the deep pass)

### 2.1 `docs/surveys/chat-session-gauge-unification.md` (the Eisenstein climax)

The rebuild's 31-turn solo derivation. Core claims:

| # | Rebuild claim | Calibration vs ternary lattice |
|---|---|---|
| C1 | gauge = a **property of the unit's quadratic form** `i² ∈ {−1,+1,0,ω}` (Gaussian / null / dual / Eisenstein) | **OURS → already proved.** This is verbatim `Signature.lean` (`gaussianUnits_card`, `split_zero_divisor`, `dual_nilpotent`, `dualUnits_card`, `signatures_distinguished`). The rebuild calls it "NEW / a third gauge position / unbuilt"; we built it. |
| C2 | Eisenstein unit = the equilateral-triangle distortion; 60°; hexagonal norm is an integer alternative to "rings" | **OURS → already proved.** `Conventions.lean` (T0/T1), `Rotation.lean` (T3), `OmegaEmbedding.lean`, `SevenHex.lean` (T2). This *is* our foundation. |
| C3 | n-simplex Aₙ vs cubic Bₙ; the trivector = a quaternion (even subalgebra of Cℓ₀,₃) | **ANALOGY.** The "trivector = quaternion" claim generalizes cleanly: the *even subalgebra* of Cℓ₀,₂ ≅ ℂ is exactly the Eisenstein plane, and the even subalgebra of Cℓ₀,₃ ≅ ℍ is the quaternion. We have the grade structure (`CrtHex.lean` Z₆≅Z₂×Z₃) but the Aₙ simplex lattice is **not** built (only the cubic Bₙ blade-bitmask exists in the rebuild's `clifford.rs`). |
| C4 | "square binary" = the full integer geometric product `(ac−bd, ad+bc)`, scalar + bivector at once | **DIRECT, and realized.** The Eisenstein multiply *is* that product (`TMUL` in RTL; `gp_decomp` in Lean). The rebuild only had the scalar `cos²` LUT; we have the full product. |
| C5 | edge-as-primitive (difference, not node) | **DIRECT.** Our stored primitive is r=O−E, a signed directed edge difference. Radix-agnostic. |
| C6 | "least action requires a triangular/Eisenstein lattice" | **SPECULATION (both sides).** The through-line is a *motivation*, not a theorem. We have the constant-action level set (rebuild stat-mech/cybernetics) but no least-action⇒hex-lattice implication proved. Keep as an open "should test", not a Tau claim. |

**Verdict:** this doc is the bridge — the rebuild independently *derived our lattice* and then
left it unbuilt. Nearly every C1/C2/C4 claim it flags as "NEW" is **already a Lean theorem in
`proofs/`**. The residual gaps are C3 (Aₙ simplex) and C6 (least-action⇒hex).

### 2.2 `docs/surveys/gauge theory/` (14 files; read the three load-bearing)

**`gauge_on_graphs.md`** (Jiang — connection 1-forms / curvature on a directed graph):

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| G1 | connection `A(i,j)`, `A(j,i)=A(i,j)⁻¹`; gauge `gA = g(i)Ag(j)⁻¹`; abelian = the **ratio** | **ANALOGY.** The paper's connection is involutive (reversible); our residual `O_ab ≠ O_ba` is directional. The *reversible part* (correlation `(O−E)/√E`) maps; the wedge (irreversibility) has **no slot** in the paper — same as the rebuild found. Radix-agnostic split. |
| G2 | curvature = holonomy `F̃ = A(i,j)A(j,k)A(k,i)`; flat F=0 = no structure | **DIRECT, and *more natural for us*.** The curvature 2-form lives on **triangles (2-simplices)** — our lattice is literally triangular, so the triangle holonomy `F(i,j,k)` is a native 3-word statistic on the hex grid, not an add-on. Broken transitivity `A→B→C, A↛C` = a non-flat hex triangle. |
| G3 | global register (count→prob `E→E/T`) = a **trivial gauge**; density dilation `ρ(a)ρ(b)` = a **Weyl/conformal frame, not a gauge** | **DIRECT.** Radix-agnostic. We already proved the invariant core: `ChiSquareGauge.lean` (`fold_gauge_invariant`, `surprise_scales`). The "redundancy that changes the prediction is not a redundancy" argument carries verbatim. |
| G4 | gauge-invariant DOF = cyclomatic number `|E|−|V|+1` (cycles carry all content) | **DIRECT.** Purely graph-theoretic, radix-agnostic. Computable on our hex word-graph. |
| G5 | Yang–Mills action `½⟨F,F⟩` (triangles) ≃ ring² = Σ(O−E)²/E (edges) | **ANALOGY.** Same shape (quadratic deviation from flat), different simplex dimension. On our lattice the *triangle* version becomes the natural objective — a NEW gauge-invariant loss we can define directly. |
| G6 | Weitzenböck `Δ_A = B_A + Ric + F` (graph Ricci ↔ gauge curvature) | **SPECULATION.** No graph-Ricci object on either side; untested link between ring (χ²) and Forman-Ricci. |

**`why_gauge.md`** (Gomes — philosophy of gauge):

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| W1 | physical state `[ϕ]=M/G`; invariant core δ=(O−E)/E; representatives = the registers δ·E^p | **DIRECT.** Radix-agnostic. δ = the invariant, registers = gauge-related descriptions. Proved in `Registers.lean` / `ChiSquareGauge.lean`. |
| W2 | **rigid** (global rescale) vs **malleable** (local per-node) symmetry; gauge proper = malleable | **DIRECT.** The count→probability rescale is rigid; our density dilation is the malleable (frame) piece. Same two-bucket sort for a 3-state table. |
| W3 | "why gauge" = to **couple subsystems** (gluing via transition functions) | **ANALOGY, tight.** Maps to cross-band/cross-source comparability; objects differ (physical states vs co-occurrence edges). Radix-agnostic. |
| W4 | keep the redundant gauge potentials (don't collapse to the surprise) | **DIRECT.** This is the formal justification for storing `{O_ab, O_ba, f(w), T}` primitives — same decision we make on the ternary side. |

**`geometric_algebra.md`** (Lasenby–Doran–Gull GTG):

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| A1 | geometric product `ab = a·b + a∧b`; `a·b=½(ab+ba)`, `a∧b=½(ab−ba)` | **DIRECT.** The three-axis split *is* the GP decomposition. For us: `z·w̄ = dot + wedge`, proved (`DotWedge.lean` `gp_decomp`, `SymDot.lean`). The scalar is `Re`, the wedge is the skew/ω-coefficient. |
| A2 | rotor `R = exp((m∧n/|m∧n|)θ/2)`, **even-grade**; acts double-sidedly `a↦RaR̃` | **DIRECT (algebra), ANALOGY (group).** Our rotor is the **Z₆ unit rotation** (TROT, `Rotation.lean`) — a genuine *discrete* even-grade rotor that *acts*. The continuum Lie-group rotor is the ANALOGY; the discrete Z₆ rotor is the object we actually run. |
| A3 | rotor = gauge transformation; **bivector = the gauge field** (connection); the two have *different* transformation laws | **ANALOGY.** Relocates the wedge to the field-strength/curl side (not the transformation side). On our lattice: TROT = the (discrete) rotor/gauge-transformation; TWEDGE = the skew field-strength. The `Ω×Ω` nonlinear term is absent on both sides. |
| A4 | spinor ψ = even-subalgebra element; observables `M=ψΓψ̃` double-sided | **DIRECT.** `ψ=(α+βI)U` is exactly our spinor fix; the grade structure is `Z₆≅Z₂×Z₃` (`CrtHex.lean`). |
| A5 | time reversal = a discrete reflection that is **not** a gauge transformation; carries direction | **DIRECT.** The sign of O−E (three-state: −1/0/+1) is our discrete, non-gauge, direction-carrying invariant. On the ternary side the **null (0)** is a genuinely new middle state the binary sign lacks. |

### 2.3 `docs/surveys/renormalization-group.md`

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| R1 | the bit-shift `d>>1` **IS** the 2-adic hierarchical RG blocking step; `G₃₂ = Z₂/2³²Z₂`; XOR kernel = the ultrametric Dyson kernel | **ANALOGY (base-2-specific).** This is the rebuild's *strongest literature theorem*, and it is an identity on `(Z₂)³²` only. We have **no** barrel shifter and no XOR kernel. The *structure* (coarse-grain = drop the least-significant digit) generalizes: dropping a **trit** = base-3 blocking, dropping a **hex digit** = base-7 blocking (`FractalRam.lean` already proves the 7ⁿ/7↔1 parent-child structure). The 2-adic/Dyson-ultrametric *theorem* does not transfer; a *base-3/base-7 hierarchical-RG theorem* is **NEW** and unproved. |
| R2 | `ρ(w)` = a spectral density of states `μ(λ)`, not a running coupling | **DIRECT.** Radix-agnostic re-labeling of our ring-band survival fraction. |
| R3 | "band gap = fixed point", "p-sweep = RG flow" are over-claims (band gap = a Wilson cutoff; p-sweep = persistence diagnostic) | **DIRECT correction.** Applies verbatim to our ternary tables. |
| R4 | DFT's "dimensional phase transition" (spectral dimension D crossing 4) = the signal detector | **ANALOGY / actionable.** Radix-agnostic in principle; the empirical spectrum (ring bands) is the same object for a 3-state table. Needs a hex-lattice spectral-dimension estimator — not yet built. |

### 2.4 `docs/surveys/spectral-graph-theory.md`

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| S1 | XOR kernel `g[i⊕j]` IS the graph Fourier transform (Walsh–Hadamard) of the hypercube; Pontryagin duality | **ANALOGY (base-2-specific).** The characters of `(Z₂)ⁿ` are Walsh functions; the characters of **our** lattice are those of ℤ[ω] / Z₆ / the hex torus — a *different* GFT. The *shape* "kernel diagonalized by the group's characters" transfers; the Walsh basis does not. The hex-lattice GFT is **NEW**. |
| S2 | wedge `O_ab−O_ba` = the skew / non-Hermitian part; real skew matrix ⇒ purely imaginary eigenvalues = rotation | **DIRECT.** Radix-agnostic. Diagonalize the non-symmetric hex adjacency, read Im(Λ) as the wedge — identical recipe on a 3-state table. |
| S3 | "band gap = spectral gap λ₂ (Cheeger)" retired → **ridge sparsification** `d_eff(γ)=Σλ_i/(λ_i+γ)` | **DIRECT.** Radix-agnostic technique. |
| S4 | flux = incidence commutator `[L_x,A]_{ij}=(x_i−x_j)A_{ij}` | **DIRECT.** Radix-agnostic recast of the residual difference. |

### 2.5 `docs/surveys/operator-algebras.md`

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| O1 | Clifford algebra = C*-algebra (Bott); rotor sandwich = inner *-automorphism | **DIRECT.** Radix-agnostic algebra facts. Cℓ₀,₂ is a C*-algebra too; the rotor sandwich is an inner automorphism. |
| O2 | the grade-0 "rotor" `exp(r_bwd−r_fwd)` is inert (a scalar commutes with everything) | **DIRECT correction — already fixed on our side.** Our rotor is the Z₆ unit (even-grade in the discrete sense), and it *acts*. This is the one place we are *ahead* of the rebuild's own survey. |
| O3 | `ℂ^{2³²}` = the Cartan subalgebra inside Cℓ₀,₃₂; the conditional expectation onto it = decoherence | **ANALOGY (base-2-specific).** The *specific* 2³²-dimensional Boolean hypercube claim does not transfer. The *structure* does: the **even subalgebra of Cℓ₀,₂ ≅ ℂ** is exactly the Eisenstein plane — a commutative Cartan inside the noncommutative quaternions Cℓ₀,₂. Our "Cartan inclusion" is ℂ ⊂ Cℓ₀,₂, not ℂ^{2³²} ⊂ Cℓ₀,₃₂. This is a **NEW** clean statement (commutative Eisenstein = the even/rotor subalgebra; the full quaternion = scalar+bivector+… is the noncommutative envelope). |
| O4 | dual numbers ℂ[ε]/(ε²) = a nilpotent *second layer* (semisimple base + nilpotent tangent) | **DIRECT.** Radix-agnostic. We already proved `dual_nilpotent` + `dualUnits_card` (`Signature.lean`, the i²=0 signature). |
| O5 | Bogoliubov inequality = "physics = information" as a *theorem* | **SPECULATION / program.** We lack β (temperature/KMS state), dynamics (Liouvillian), and a bound — exactly as the rebuild does. Radix-agnostic, unbuilt on both sides. |
| O6 | anti-lattice = the **commutant** (operators outside the algebra), not the Hodge dual | **ANALOGY.** "What a source erases" = the commutant. Radix-agnostic; unproven on both sides. |

### 2.6 `docs/surveys/category-theory.md`

The single most transferable survey — category theory is radix-agnostic throughout.

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| K1 | wedge = the value of a **direction functor** (reflexive + transitive, NOT symmetric ⇒ a monoid = "keep the sign, drop symmetry") | **DIRECT.** For us the sign is *three-valued* (−1/0/+1), which makes the "direction" a genuine three-point monoid (attract / null / repel) rather than a two-point one. The categorical machinery transfers; the ternary null enriches it. |
| K2 | geometric product = the **mixor** of a linearly distributive category (scalar↔∧, bivector↔◦) | **DIRECT.** Radix-agnostic. Our `dot + wedge` split is the same two monoidal products. |
| K3 | residual edge = the internal hom of a **Lawvere metric space** (`Hom(a,b)` = surprise, converse-failure = wedge) | **DIRECT.** Radix-agnostic. |
| K4 | register shift = a **lossy adjunction** (frame dilation = not an isomorphism) | **DIRECT.** Radix-agnostic. Matches our frame-dilation result. |
| K5 | "geometric product = composition" retired (it is monoidal); "lattice IS a category" retired (it is a Lawvere metric space) | **DIRECT correction.** Same retirements hold verbatim on the ternary lattice. |

### 2.7 `docs/source_surveys/geometric_algebra.md` (+ Macdonald GA&GC reference)

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| A1 | spinor `ψ=(α+βI)U` (Hestenes–Sobczyk Eq. 8.11) = the exact grade-0 rotor fix | **DIRECT, and realized.** `U` = our Z₆ rotor, the grade structure is `Z₆≅Z₂×Z₃`. The rebuild *flagged* this fix; we *implemented* it. |
| A2 | wedge = the **skew part / curl**, NOT bivector area (retire V3 "wedge=|a∧b|") | **DIRECT.** `Residual.lean` `wedge_antisymm`; `DotWedge.lean`. The wedge is uniquely determined by its curl. |
| A3 | `∇F = J` is **invertible** (GA Maxwell, one equation); div and curl separately non-invertible | **DIRECT — and it is our TGRAD, now built.** "residual = ∇F, recovery = the directed integral" is exactly our field-calculus thread. On the hex lattice the geometric derivative is the discrete Eisenstein ∇; the Green's-function inverse is what makes reconstruction lossless. **Built** (`rtl/grad_recon.v`; TRECON is the canonical gauge-fixed section, not the full minimum-norm inverse — that needs ÷6). The algebra is Lean-provable. |
| A4 | MDD / torsion = the skew part of the *connection* — a DIFFERENT skew from the transition-matrix skew | **DIRECT (conceptual).** Torsion ≠ wedge-of-transition-matrix. Radix-agnostic; don't conflate the two skews. |

### 2.8 `docs/surveys/information-geometry.md` + `docs/source_surveys/information_geometry.md`

Information geometry is *entirely* radix-agnostic — probabilities and divergences on a 3-state
contingency table obey the same theorems.

| # | Claim | Calibration vs ternary lattice |
|---|---|---|
| I1 | flux `(O−E)²/E` = χ² = 2nd-order Taylor of KL (`χ² ≈ 2·KL` near null) | **DIRECT.** Same for a 3-state table. |
| I2 | "ring = Fisher information" is **INVERTED** (Fisher ∝ 1/freq; ring ∝ freq) | **DIRECT correction.** Fisher info is still ∝ 1/frequency on a 3-state table; the ring is still a χ² divergence. Retire identically. |
| I3 | "natural gradient = multiplicative L1" is **wrong** (scalar vs G⁻¹∇L; mirror-descent-shaped) | **DIRECT correction.** Same for us. |
| I4 | dually-flat θ/η structure + the **Legendre transform** = the home for the two bridges; ρ = a would-be mirror map | **DIRECT.** The missing Legendre piece is the same missing piece for our polarization/ratio gauge. |
| I5 | Crouzeix identity `∇²φ·∇²φ* = I` = the Legendre verifier | **DIRECT.** Radix-agnostic one-matrix test. |
| I6 | α=0 = self-dual Levi-Civita = *curved* sphere (α=±1 flat); Amari–Chentsov `C_ijk` (3rd-order symmetric) ≠ our wedge (2nd-order anti-symmetric) | **DIRECT.** Radix-agnostic; the wedge remains 2nd-order skewness-free. |

---

## 3. The master transfer table (roll-up)

### 3.1 DIRECT — transfers verbatim (radix-agnostic)

| Content | Source doc(s) | Already in our Lean/RTL? |
|---|---|---|
| geometric product = scalar + bivector; wedge = skew/curl not area | GA (GTG), source GA | ✅ `DotWedge.lean`, `SymDot.lean`, `Residual.lean` |
| spinor `ψ=(α+βI)U`; grade structure Z₆≅Z₂×Z₃ | source GA, GTG, operator-alg | ✅ `CrtHex.lean`, `Rotation.lean` |
| `∇F=J` invertible; div/curl separately non-invertible | source GA | ⬜ TGRAD — the long pole (Lean-provable) |
| wedge = direction functor (keep sign, drop symmetry) | category-theory | ✅ concept (`wedge_antisymm`); functor-type promotion unbuilt |
| geometric product = mixor of a linearly distributive category | category-theory | ⬜ (formal re-description, not yet done) |
| residual edge = internal hom of a Lawvere metric space | category-theory | ⬜ |
| register shift = lossy adjunction | category-theory | ⬜ |
| δ=(O−E)/E = gauge-invariant core; registers = gauge-related descriptions | why_gauge | ✅ `ChiSquareGauge.lean`, `Registers.lean` |
| global register = trivial gauge; density dilation = Weyl/conformal frame (not a gauge) | gauge_on_graphs, why_gauge | ✅ (`Gauge.lean`, `ChiSquareGauge.lean`) |
| cyclomatic number `|E|−|V|+1` = gauge-invariant DOF | gauge_on_graphs | ⬜ (compute on hex graph) |
| triangle holonomy `F(i,j,k)` = the 2-simplex curvature | gauge_on_graphs | ⬜ (**native** to the triangular lattice — high value) |
| wedge = non-Hermitian skew; Im(Λ) = rotation | spectral-graph-theory | ⬜ (directed-spectrum experiment) |
| ridge sparsification `d_eff(γ)` (not Cheeger λ₂) | spectral-graph-theory | ⬜ |
| flux = χ² = 2nd-order KL; Fisher-inversion + natural-gradient corrections | info-geometry | ⬜ (corrections adopted, not yet a χ² table) |
| dually-flat θ/η + Legendre transform = the mirror map | info-geometry | ⬜ (missing piece) |
| Clifford = C*-algebra; dual numbers = nilpotent second layer | operator-algebras | ✅ `Signature.lean` (`dual_nilpotent`) |
| gauge = the unit's quadratic form (four signatures) | chat-session | ✅ `Signature.lean` |
| edge-as-primitive (stored r=O−E) | chat-session, gauge | ✅ `Residual.lean` |

### 3.2 ANALOGY — base-2-specific, shape matches, object must be rebuilt

| Rebuild object (base-2) | Ternary twin (NEW / to rebuild) | Source doc |
|---|---|---|
| XOR kernel `g[i⊕j]` | hex/Eisenstein kernel (characters of ℤ[ω]/Z₆); the hex-lattice GFT | spectral-graph-theory, operator-alg |
| Walsh–Hadamard = GFT of `(Z₂)³²` | GFT of the hex lattice (a different character basis) | spectral-graph-theory |
| barrel shift `d>>1` = 2-adic RG blocking | base-3 / base-7 hierarchical RG (drop least-significant trit / hex digit); `FractalRam.lean` is the substrate | renormalization-group |
| `ℂ^{2³²}` = Cartan of Cℓ₀,₃₂ | ℂ (Eisenstein even subalgebra) = Cartan of Cℓ₀,₂ (quaternions) | operator-algebras |
| 2-adic ultrametric Dyson kernel | a base-3/base-7 ultrametric (unproved) | renormalization-group |
| rule 90 / XOR substrate (Wolfram) | Kleene ternary / mod-3 logic (`PolarGate.lean`) | mathematics (surv.), chat |
| binary sign ± (Booleanisation) | **ternary sign −1/0/+1** (the null is a genuinely new middle state) | logic, GTG time-reversal |

### 3.3 OURS — derived / implemented independently (already in the repo)

These are things the rebuild *flagged as needed* but did not build, which our project already
has proved in Lean or in the RTL — the clearest "we are ahead" rows:

| Object | Rebuild status | Our status |
|---|---|---|
| Eisenstein ring ℤ[x]/(x²−x+1), norm a²+ab+b² | "NEW / unbuilt" (chat survey) | ✅ PROVED `Conventions.lean` |
| the 6 units Z₆, 60° rotor | "NEW" | ✅ PROVED `Rotation.lean`, `OmegaEmbedding.lean` |
| the four gauge signatures i²∈{−1,+1,0,ω} | "NEW experiment `gauge-int`" (~100 lines, unbuilt) | ✅ PROVED `Signature.lean` |
| full integer geometric product (scalar + bivector at once) | "square binary" upgrade, scalar-only LUT | ✅ RTL `TMUL` + `gp_decomp` |
| the spinor's grade structure (sign × 3-cycle) | "the fix ψ=(α+βI)U, TODO #13" | ✅ PROVED `CrtHex.lean` |
| wedge = skew not area | flagged as a correction to *apply* | ✅ PROVED `Residual.lean` `wedge_antisymm` |
| dot/wedge split `z·w̄ = dot + wedge` | flagged | ✅ PROVED `DotWedge.lean` |
| conjugate (TCONJ) | used implicitly | ✅ PROVED `Conjugate.lean` |
| balanced-ternary gate semantics (Kleene / F₃) | absent (rebuild is binary) | ✅ PROVED `PolarGate.lean` |
| hex ↔ ℕ (u32) address bijection | "blocked on address-translation theorem" | ✅ PROVED `Bijection.lean` (replacement claim itself still SPECULATION) |
| hexagonal packing / disk / isotropy | absent | ✅ PROVED `Packing.lean` (partial), `HexDisk.lean`, `HexIsotropy.lean`, `Pod.lean` |

### 3.4 SPECULATION — unproven on both sides (do not promote to Tau claims)

| Claim | Source |
|---|---|
| "least action requires a triangular/Eisenstein lattice" (the chat climax) | chat-session |
| Weitzenböck `Δ_A = B_A + Ric + F` ⇒ ring (χ²) ↔ Forman-Ricci link | gauge_on_graphs |
| Bogoliubov bound (we lack β, dynamics, an inequality) | operator-algebras |
| anti-lattice = commutant (vs Hodge dual) | operator-algebras |
| "hex lattice replaces the u32 XOR kernel" (blocked on the address-translation theorem) | `proofs/INDEX.md` |
| DFT dimensional phase transition D crossing 4 = signal detector (hex estimator unbuilt) | renormalization-group |
| ring shift = a *full* RG flow (needs integrate-out + renormalize, base-3/base-7 form) | renormalization-group |
| superfluid-spacetime / "physics = information" as physics | operator-algebras |

---

## 4. What does NOT transfer (base-2-only, exclude)

Concretely **base-2-only** — no ternary twin without a genuinely new theorem:

1. **The XOR kernel `g[i⊕j]` and its parity identity `cosθ = (−1)^popcount(i&j)`.** Exclusive-or and popcount parity are binary operations; there is no three-state XOR. The replacement (mod-3 logic / hex addressing) is a *different* object, not a port.
2. **Walsh–Hadamard = GFT of `(Z₂)³²`.** The WHT basis is the binary hypercube's characters; our character group is ℤ[ω]/Z₆. The spectral-graph-theory "PROVEN" identity is *proven on the wrong group* for us.
3. **The 2-adic hierarchical RG / `G₃₂ = Z₂/2³²Z₂` / barrel shift `d>>1`.** 2-adic truncation is base-2; our coarse-graining is base-3 (trit drop) or base-7 (hex-digit drop). The *theorem* (`d>>1` = Λ) is base-2-only; the *idea* (drop LSB = block) generalizes.
4. **`ℂ^{2³²}` = Cartan of Cℓ₀,₃₂.** The 2³² dimension is the binary hypercube's; our Cartan is the 2D even subalgebra ℂ ⊂ Cℓ₀,₂.
5. **rule 90 / 60 / 30 = XOR cellular automata.** Binary CA identities; our ternary CA is Kleene/mod-3 (`PolarGate.lean`).
6. **"quantum-on-classical" BQP claims** (already refuted by the rebuild's own quantum-algorithms survey as a data-layout coincidence) — doubly excluded: base-2 *and* not a speedup.
7. **The u32 address space / POPCNT / barrel-shifter micro-optimizations** (`cosine.rs`, `simd.rs` SWAR int16). These are the rebuild's binary substrate; the ternary substrate is the balanced-trit / hex RAM (`TernaryCell.lean`, `FractalRam.lean`).

---

## 5. What is NEW on our side (absent from the rebuild)

The non-binary generalizations the rebuild itself named but never built, plus what it has no
slot for:

1. **The three-valued sign.** The rebuild's "sign(O−E)" is Boolean ±; ours is −1/0/+1, and the **0 (null)** is a real third state — the "free null" of the hardware verdict and a genuine middle direction in the direction-functor reading. No binary analog.
2. **The hex/Eisenstein GFT.** The graph Fourier transform of ℤ[ω]/Z₆ — the ternary replacement for the WHT. Unproved, unbuilt.
3. **Base-3 / base-7 hierarchical RG.** The ternary/hex analog of the 2-adic blocking theorem (`FractalRam.lean` gives the 7ⁿ substrate; the RG-flow theorem is unproved).
4. **The triangular holonomy as a native 2-simplex statistic.** The gauge survey's "curvature on triangles" is an *add-on* for a general graph but the *native geometry* for the hex lattice.
5. **The balanced-ternary gate algebra (Kleene / F₃).** `PolarGate.lean` — no rebuild counterpart (the rebuild has no ternary logic).
6. **The Cartan inclusion ℂ ⊂ Cℓ₀,₂.** The clean statement that the commutative Eisenstein plane is the even (rotor) subalgebra of the quaternion Clifford algebra — the ternary replacement for "ℂ^{2³²} = Cartan of Cℓ₀,₃₂".
7. **The honest radix verdict.** Names-exponentially / transport-cheaper / compute-pricier (`FINAL_VERDICT.md`) — a hardware reality check the rebuild (a binary software engine) never confronts.

---

## 6. One-sentence bottom line

**The rebuild's eight top write-ups split cleanly into three tiers against the ternary lattice:**
(i) *category theory, information geometry, and the gauge/philosophy pair transfer almost
verbatim* (radix-agnostic) — and we have already Lean-proved the gauge core; (ii) *geometric
algebra and operator algebras transfer at the algebra level but their binary-specific identities
(XOR kernel, WHT, 2-adic RG, ℂ^{2³²} Cartan, POPCNT substrate) are analogies whose ternary twins
(hex GFT, base-3/7 RG, ℂ⊂Cℓ₀,₂) are NEW and unproved*; (iii) *the chat-session's "Eisenstein /
gauge-as-unit / square-binary" climax — which the rebuild itself labels NEW/unbuilt — is precisely
our already-proved foundation (`Signature.lean`, `Conventions.lean`, `Rotation.lean`,
`DotWedge.lean`)*. The one genuinely new load-bearing thread on our side is the **field calculus
`∇F=J`** (TGRAD): the invertible geometric derivative that makes "residual = a field, recovery =
the directed integral" a theorem on the hex lattice rather than a table lookup.

---

## TODO / not covered / caveats

- **Only the `.md` write-ups were read end-to-end; the PDF papers were not opened.** Every
  "PROVEN" in the surveys is the rebuild's two-stage subagent's claim, quoted from the paper's
  write-up, not re-derived from the PDF. Before promoting any *equation* (e.g. the Weitzenböck
  formula, the p-adic block-spin Lemma 1, the Crouzeix identity) to a Tau claim, open the source
  PDF. Paths: `docs/renormalisation group - statistical feild theory/`, `docs/gauge theory/`,
  `docs/info_geometry/information_geometry/`, `docs/operator algebras/`.
- **`surveys/gauge theory/` remaining 11 files unread** (`approaches`, `foundations`,
  `gravitation`, `group_theory`, `higher_gauge`, `intro_1910`, `intro_9705`, `problem_of_gauge`,
  `teaching`, `tensor_gauge`, `geometric_gauge`). Only the three load-bearing ones were mapped.
  Batch-survey them if the gauge thread expands.
- **The `geometric_algebra` source survey is only 4 findings over 15 files.** The Macdonald GA&GC
  PDF (`info_geometry/gagc and stuff/`) is the reference text; it was characterized, not read.
  Re-read it as the algebra source if TSPINOR / TGRAD moves forward.
- **"DIRECT" here is still the rebuild's *self-assessed* DIRECT, re-anchored.** I did not
  re-verify the underlying math of any survey against the PDF; I only re-anchored the *calibration*
  to the ternary lattice. Anything marked DIRECT must still hit our "we should test" list before it
  becomes a Tau claim (same caveat as `REBUILD_SURVEY.md` §5).
- **`least-action ⇒ Eisenstein` (C6) is a motivation, not a theorem.** It is the most tempting
  over-claim in the whole corpus (the fluency trap). We have a constant-action *level set*
  (rebuild stat-mech/cybernetics) but no implication "least action forces a triangular lattice".
  Keep it explicitly SPECULATION.
- **The "hex replaces XOR kernel" replacement claim is still SPECULATION** in `proofs/INDEX.md`
  (blocked on the address-translation theorem), even though the *bijection* (`Bijection.lean`) is
  proved. Do not write the replacement as done.
- **Not re-surveyed here** (out of the 8-doc scope): statistical-mechanics, maximum-entropy,
  granger-transfer-entropy, multifractal-formalism, logic, quantum-algorithms, and the
  source_surveys (physics, cybernetics, mathematics, jacobian, shannon, etc.). Their one-line
  verdicts in `REBUILD_SURVEY.md` stand; a full ternary re-anchoring of those is the next batch.
- **Hardware vs math boundary.** `FINAL_VERDICT.md`'s energy numbers are ngspice measurements and
  Lean theorems about the *ternary device*, not about the Eisenstein *lattice math*. The MAP above
  concerns the lattice/math/GA layer; the device layer (transport/compute/namespace) is a separate
  verdict and should not be conflated with the algebraic DIRECT rows.
