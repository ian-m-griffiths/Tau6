# ∇F = J — GA Maxwell, one equation, mapped to the residual lattice

**2026-08-29 — research/analysis doc (not a proof, not a measurement).** Surveys the
geometric-algebra (GA) statement of Maxwell's equations — `∇F = J`, one equation — and maps
it to the rebuild's residual `r = O−E`, the wedge, and the divergence. Builds on the
rebuild's own `geometric_algebra.md` survey finding ("`∇F = J` is INVERTIBLE — the geometric
derivative has a multivector Green's function, div and curl don't, separately") and on the
Lean ledger (`Residual.lean`, `DotWedge.lean`, `OmegaEmbedding.lean`).

> **STATUS UPDATE (2026-08-29):** the field-calculus datapaths are now **BUILT and
> iverilog-verified** — `rtl/grad_recon.v` (`tgrad_cell` = ∇F → div⊕curl, `trecon_cell` =
> the canonical ∇⁻¹ section) and `rtl/trelax.v` (`trelax_cell` = one heat step), both green
> (28 checks + 7/7). Earlier "unbuilt" notes in this file are superseded. See
> `docs/compute/CPU_INTEGRATION.md` §2 for the wiring + the gauge caveat.

**Calibration legend (repo-wide, unchanged):** **DIRECT** = proved/measured/classical
theorem; **ANALOGY** = structural resemblance, not an identity; **OURS** = our design claim
following from DIRECT; **SPECULATION** = untested hypothesis, flagged.

---

## 0. TL;DR (the verdict up front)

`∇F = J` is the **spacetime-algebra (STA) form of all four Maxwell equations in one line**:
the geometric derivative `∇` (one operator) acting on the electromagnetic field bivector `F`
equals the charge-current vector `J`. Its geometric-product split `∇F = ∇·F + ∇∧F` is
exactly the standard four-equation set: `∇·F = J` is Gauss + Ampère–Maxwell (the **source**
sector), `∇∧F = 0` is Gauss-for-magnetism + Faraday (the **source-free** sector). **DIRECT,
classical theorem** (Hestenes 1966; Hestenes–Sobczyk 1984; Doran–Lasenby 2003).

The invertibility is real and **DIRECT** in the continuum: `∇` is a first-order "square root
of the wave operator" (`∇² = □`), so it has a clean single inverse — a multivector Green's
function (the Cauchy kernel), the same structure that makes complex analysis' Cauchy formula
work. `div` and `curl` separately are **not** invertible (each kills half the field), which
is the whole reason Helmholtz needs *both* plus boundary data.

Mapped to our lattice the verdict is more careful:

- **`r = O−E` as "the field F"** — **ANALOGY**, with a **DIRECT core**. F is a *bivector*
  over spacetime; our residual is a *signed scalar per directed edge*. What is **DIRECT** is
  the decomposition: the directed edge splits `sym ⊕ skew` (`sym_plus_skew`, proved), and
  that is the scalar⊕bivector (dot⊕wedge) split of a grade-mixed field (`gp_decomp`,
  `wedge_antisymm` in `DotWedge.lean`, proved).
- **The wedge as "the curl"** — **DIRECT at the algebra level**: wedge = the skew part = the
  curl/circulation (Hestenes–Sobczyk "a skew transformation is determined by its curl";
  `wedge_antisymm` + `wedge_eq_residual_skew` proved). Our wedge is the *scalar* skew of a
  transition matrix, **not** a grade-2 bivector *area* — the V3 "wedge = |a∧b|" mapping is
  retired.
- **The divergence as "the source"** — **come-to-terms first**: there are *two* divergence-like
  objects in the rebuild and only one is the Maxwell "source". See §2.3.
- **`J` in our setup** — **OURS**: `J = div r(a) = Σ_b O(a,b) − f(a)` (the node's net
  "unexplained outflow" / semantic charge). It is **zero on a column-balanced lattice** — the
  invariant the rebuild enforces — so the residual field is **source-free** (`∇∧F = 0`-like),
  and `Σ_a div r(a) = 0` is the already-proved `sum_residual_eq_zero` (global charge
  conservation). The χ²/surprise is **not** `J`; it is the field's *magnitude* (energy-density
  analog).

**The one-line verdict:** `∇F = J`'s invertibility is a **cited continuum theorem** (DIRECT),
its four-equation split is a **cited theorem** (DIRECT), and its *discrete* echo in our lattice
is the **telescope + sign-collapse pair**: the full signed residual is losslessly invertible
(`O = r + E`), while the surprise/χ² register is a *provably lossy projection*
(`surprise_sign_collapse`, proved). The "`∇` instruction = lossless reconstruction" is
**OURS/SPECULATION** — a coherent design hypothesis on a DIRECT foundation, not yet built,
not yet costed.

---

## 1. What `∇F = J` is (plain English)

### 1.1 The geometric derivative — one operator, all four equations

In geometric algebra there is one derivative, the **vector derivative** `∇` (Hestenes'
"geometric derivative"; sometimes written `□` in STA). It acts by the *geometric product*
rather than by a fixed scalar/vector recipe:

```
∇F  =  ∇·F   +   ∇∧F
       (inner /   (outer /
        "dot")    "wedge")
```

The geometric product of the derivative with a field `F` *naturally* falls into two grades:
the **inner product** `∇·F` (same/lower grade — the "divergence" part) and the **outer
product** `∇∧F` (higher grade — the "curl" part). You do not get to choose between "div" and
"curl"; the single `∇` hands you both, already separated by grade.

The electromagnetic field is a **bivector** `F` (in 3D, `F = E + iB`; in STA it is the Faraday
bivector). The charge–current is a **vector** `J` (the 4-current). Then:

```
∇F = J          (one equation)
⟺  ∇·F = J      (the source equations:  Gauss's law,   Ampère–Maxwell)
    ∇∧F = 0      (the source-free equations: Gauss-for-magnetism, Faraday)
```

That is the entire claim of "one equation = all four Maxwell equations." It is not a
compression trick; it is the statement that in the geometric algebra, the four equations are
the *grade components* of a single vector-derivative equation. **DIRECT** — this is the
standard STA formulation (Hestenes 1966; Hestenes–Sobczyk 1984; Doran–Lasenby 2003 §7.1).

*(Conventions and units vary — natural units `c=1` vs explicit `μ₀ε₀`, the `γ₀` metric sign,
`F = E + IB` vs `F = B + IE`. The grade structure above is convention-independent; do not
quote specific signs/units without pinning the convention.)*

### 1.2 The invertibility — a Green's function, in plain terms

The deep fact the rebuild's survey flagged: **`∇` is invertible; `div` and `curl` are not.**

Why, in plain terms:

1. **`∇` is a first-order "square root."** Applying the vector derivative twice gives the
   wave operator: `∇² = □` (the d'Alembertian; in Euclidean space, the Laplacian). The
   equation `∇F = J` is therefore *first order*, and first-order square-root operators are
   the ones with a clean single inverse. This is exactly why the Dirac equation (a square
   root of the Klein–Gordon equation) is first order, and why complex analysis gets a
   Cauchy integral formula.

2. **The Green's function.** `∇` has a fundamental solution — a "Cauchy kernel"
   `G(x − x′)` with `∇G = δ` — so `F = ∫ G · J` recovers the field from its source, up to a
   homogeneous (monogenic) part fixed by boundary data. This is the *fundamental theorem of
   geometric calculus*: interior values are reconstructed from boundary values via the
   directed integral. **DIRECT, cited** (Hestenes–Sobczyk 1984; Macdonald, *Vector and
   Geometric Calculus*).

3. **`div` and `curl` alone are not invertible.** Each is a *grade projection* of `∇` and
   each throws away the other half: `div` annihilates the rotational part, `curl`
   annihilates the irrotational part. Reconstructing a field from `div` alone (or `curl`
   alone) is under-determined — infinitely many fields share a given divergence. Helmholtz's
   theorem needs `div` **and** `curl` **and** boundary conditions precisely because each
   alone has a nontrivial kernel.

**Plain analogy.** Think of a field as a photograph. `div` is the "how much light" channel
(brightness); `curl` is the "which way the edges turn" channel. Store only brightness and
you have thrown away all edge/contour structure — reconstructing gives a *grayscale blur*.
The geometric derivative stores brightness and edge-direction (and every higher grade)
**in one object**, so the reconstruction is *exact* — lossless. That is the entire
invertibility claim.

**Honest boundary caveat (pulled from our own Jacobian survey):** "invertible" here is
**local + boundary-data**, not global. The Jacobian-determinant survey (`jacobian-determinant-matrix.md`
Part 2) already corrected the naive `det ≠ 0 ⟺ invertible` claim: `det ≠ 0` buys only *local*
invertibility (IFT); *global* needs properness (Hadamard), and counterexamples fail by
"escape-to-infinity." The GA statement is the same shape: `∇F = J` inverts the field *on a
region, up to boundary values*, not "recover everything from `J` alone with no boundary
data." Do not over-claim "lossless" beyond that.

---

## 2. Map to the residual lattice

### 2.1 Is `r = O−E` the field `F`? — ANALOGY, with a DIRECT core

- **Grade mismatch (the honest part).** GA's `F` is a *bivector* field over a smooth
  spacetime. Our residual `r(a,b) = O(a,b) − E(a,b)` is a *signed rational scalar* on each
  directed edge `a → b` of a discrete graph (`Residual.lean`). A scalar-per-edge is not a
  bivector field. So "`r = F`" is **ANALOGY**, not an identity.

- **What is DIRECT:** the *decomposition* into scalar ⊕ bivector (dot ⊕ wedge). The observed
  directed table splits into symmetric + antisymmetric parts — `sym_plus_skew` (proved):

  ```
  O(a,b) = (O(a,b)+O(b,a))/2  +  (O(a,b)−O(b,a))/2
           symmetric (correlation)   skew (wedge / curl)
  ```

  and the same split holds for the residual itself (`wedge_eq_residual_skew`: the `E` terms
  cancel). This is the *lattice's* scalar⊕bivector decomposition of the field — the analog of
  `F = E + iB` with `E`-part = correlation and `B`-part = wedge. **DIRECT, PROVED.**
  Independently, on the Eisenstein ring, the geometric product `z·conj w` splits into dot
  (scalar) + wedge (bivector) — `gp_decomp`, `wedge_antisymm`, `dot_sq_add_wedge_sq` in
  `DotWedge.lean` (proved).

**Bottom line:** the *field-like object* in our lattice is the directed residual edge,
*read as a grade-mixed object*: scalar (correlation/surprise) ⊕ bivector (wedge/skew) ⊕
scale (polarization). The residual is not *literally* `F`, but its sym⊕skew decomposition is
*literally* the dot⊕wedge decomposition — that part is DIRECT and proved.

### 2.2 Is the wedge the curl? — DIRECT at the algebra level

Yes, with one guardrail.

- **DIRECT:** the wedge `O_ab − O_ba` is the **skew part**, and the skew part of a linear
  transformation is its **curl/circulation content** (Hestenes–Sobczyk: "a skew
  transformation is completely determined by its curl"). The antisymmetry
  `wedge(a,b) = −wedge(b,a)` is proved (`wedge_antisymm` in `Residual.lean`), and so is
  `wedge_self = 0` (no circulation on a single vector, `DotWedge.lean`). The Helmholtz-style
  `sym_plus_skew` is the "gradient part + curl part" decomposition of the field.

- **Guardrail (retired V3):** our wedge is the **scalar skew of a transition matrix**, NOT a
  grade-2 bivector *area*. The V3 "wedge = |a∧b|" mapping was retired; the wedge is an
  *orientation signal* (temporal precedence / circulation), not a causal arrow, not an area
  (`AGENTS.md` canonical truth; `geometric_algebra.md` survey). In GA terms our wedge is the
  **curl/circulation *content*** — the data that `∇∧F` carries — not the full bivector element
  itself.

### 2.3 Is the divergence the source? — come-to-terms first (two different objects)

The rebuild uses the word "divergence" for *two* different sums. They are not the same
thing, and only one is the Maxwell "source."

| Rebuild object | Definition | GA reading | Calibration |
|---|---|---|---|
| **Row-sum divergence** `div r(a)` | `Σ_b r(a,b) = Σ_b O(a,b) − f(a)` | the **source** `∇·F = J` (the field's divergence = the charge) | **Lean-provable identity**; reading is **OURS** |
| **Skew-flow** `flow(a)` (`curl_field.rs`) | `Σ_b (r(a,b) − r(b,a)) = Σ_b wedge(a,b)` | the **div-of-curl** (second-order: divergence *of the skew* = net circulation) | **implemented** (`curl-field` CLI); *calling it "divergence" is a name collision* |

- The **row-sum divergence** `div r(a) = Σ_b r(a,b)` is the field's natural divergence, and
  by `sum_E_row` (`Σ_b E(a,b) = f(a)`, proved) it equals the **row imbalance**
  `Σ_b O(a,b) − f(a)`. Under the column-balancing condition (`Σ_b O(a,b) = f(a)`, the exact
  invariant `ox alpha.md` flagged as the key bug fix), `div r = 0` **pointwise** — the
  residual field is **source-free / solenoidal**, the lattice analog of `∇∧F = 0`
  (Gauss-for-magnetism, "no net source"). And globally, `sum_residual_eq_zero` (proved) says
  `Σ_a div r(a) = 0` — **total charge is zero**, i.e. charge conservation.

- The **skew-flow** `flow(a) = Σ_b wedge(a,b)` is what the live `curl-field` CLI computes as
  its "divergence" (SOURCE/SINK/center; "critical points div=0 = topic centers"). This is the
  **divergence of the wedge field**, a *second-order* object (div-of-curl). In the continuum
  `div curl = 0` identically; on our graph with asymmetric residuals it is **not** identically
  zero, and its sign is exactly the temporal SOURCE/SINK arrow-of-time signal. **This is a
  real and useful object, but it is NOT the Maxwell source `J`** — it is one derivative
  deeper.

**Come-to-terms consequence:** when the task asks "is the divergence the source?", the honest
answer is: *the* **row-sum** divergence is the source (and it's zero on a balanced lattice);
the rebuild's *existing* "divergence" (`flow = Σ wedge`) is the **net circulation**, a
different grade, and should not be read as `J`.

### 2.4 What is `J` in our setup? — OURS

**`J` = the node-wise net residual = the row imbalance:**

```
J(a) = div r(a) = Σ_b (O(a,b) − E(a,b)) = Σ_b O(a,b) − f(a)
```

In words: the "charge" at a word `a` is how much more observed co-occurrence *out-flow* it
carries than its frequency predicts. It is:

- **Zero** on a column-balanced lattice (the rebuild's invariant) → the field is source-free.
- **Non-zero** only where the observed table `O` fails the marginal/row condition → that
  imbalance is the "unexplained mass" that a `∇`-inverse (a directed integral) would have to
  account for.

This is **OURS**: it is a *proposed* reading of a **Lean-provable identity** (see §5). It is
**not** a cited theorem that "the residual's row-sum is Maxwell's charge-current." And the
**χ²/surprise register is explicitly NOT `J`**: `ring² = Σ r²/E` is the field's *magnitude*
(the energy-density analog, `E²+B²`), a different grade — and it is a *lossy* projection
(sign-collapsed), as §3 shows.

---

## 3. What a `∇` (geometric derivative) instruction would do

### 3.1 The instruction shape (TGRAD)

Per `docs/GA_INSTRUCTIONS.md`, `TGRAD` is the Tier-3 "geometric derivative" candidate. On the
Eisenstein engine, its building blocks already exist or are cheap:

| GA primitive | Engine primitive | Status |
|---|---|---|
| geometric product | `TMUL` (Eisenstein multiply) | in RTL |
| conjugate | `TCONJ` | Lean-proved (`Conjugate.lean`) |
| scalar/bivector split | `TDOT`/`TWEDGE` | Lean-proved (`DotWedge.lean`) |
| rotation / bivector unit | `TROT` (Z₆, 60°) | in RTL |

A concrete `TGRAD` would be a **directed neighborhood sum with orientation**: for a field
`F` living on the edges of the hex lattice, `∇F` at a cell/vertex is the sum of `F` over the
surrounding edges, each term weighted by its orientation (the `ω`-rotor / conjugate of the
edge direction). The output is the two grade components already separated:

```
∇F = (Σ symmetric contributions)   ⊕   (Σ skew contributions)
     = div (scalar)                 ⊕   curl (bivector)
```

i.e. it reads the six neighbors of a hex cell, forms `z·conj w` per edge (`TMUL` + `TCONJ`),
and accumulates the `dot` part and the `wedge` part (`TDOT`/`TWEDGE`). This is a **small
parallel-prefix scan** over a 6-element neighborhood — the same primitive the
`einstein_calculus.md` doc already established as DIRECT (discrete FTC + Kogge–Stone scan).

### 3.2 Why invertible = "lossless reconstruction," not a lossy blur

The distinction is exactly the sign-collapse that is **already proved in our ledger**:

- **The full signed residual `r = O−E` is the lossless object.** It carries sym ⊕ skew, and
  it is recovered exactly: `O = r + E`, and the telescope `Σ r = 0` (`sum_residual_eq_zero`)
  closes. This is the discrete fundamental-theorem inverse: differentiate (store `r`), then
  integrate (sum / accumulate) to recover `O` — **no information lost**.

- **The surprise register `r²/E` is the lossy projection.** `surprise_sign_collapse` (proved,
  `Registers.lean`) shows `surprise(r) = surprise(−r)`: squaring **collapses the sign**, so an
  attract (`r < 0`) and a repel (`r > 0`) are indistinguishable. That is *exactly* the
  "div alone loses the rotational half" failure, made concrete: store only the magnitude and
  you have thrown away the direction — reconstruction is a blur.

So "lossless reconstruction" in our setting means precisely: **store the full geometric
derivative `∇F` (both grades), and the directed integral recovers `F` exactly; store only a
grade projection (div alone, curl alone, or surprise alone) and the recovery is under-determined
— a blur.** The `∇` instruction is the *differentiate* half; its inverse is the
*accumulate/scan* half (the "sum-over-time" primitive); the pair is lossless because the
discrete derivative and the discrete sum are exact inverses up to the boundary/initial value
(`Finset.sum_range_sub`, mathlib).

**Calibration of "lossless reconstruction for computation":**

| Claim | Calibration |
|---|---|
| `∇F = J` is invertible in the continuum (Green's function / Cauchy kernel) | **DIRECT** (cited theorem) |
| discrete derivative and discrete sum are exact inverses up to initial value (discrete FTC) | **DIRECT** (mathlib `sum_range_sub`) |
| the full signed residual is losslessly recoverable (`O = r + E`) | **DIRECT** (definition; telescope proved) |
| the surprise/χ² register is a lossy sign-collapsed projection | **DIRECT** (`surprise_sign_collapse`, proved) |
| "the residual *is* `∇F`" (so recovery = the `∇`-inverse) | **ANALOGY / OURS** (needs a defined `∇` on the lattice; time/direction axis supplied, not yet formalized) |
| a `TGRAD` instruction with an accumulate inverse gives lossless field reconstruction *in silicon* | **SPECULATION** (unbuilt, uncosted — cf. TMUL's +64.8% area) |

---

## 4. The calibrated map (everything in one table)

| GA Maxwell object | Lattice object | Calibration | Lean status |
|---|---|---|---|
| field `F` (bivector) | directed residual edge `r = O−E`, read grade-mixed (sym ⊕ skew) | **ANALOGY** (grade mismatch); sym⊕skew split **DIRECT** | `sym_plus_skew`, `wedge_eq_residual_skew` **proved** |
| scalar part (dot, `E`-like) | correlation / symmetric part | **DIRECT** (symmetric part) | `sym_plus_skew` **proved** |
| bivector part (curl, `B`-like) | wedge `O_ab − O_ba` = skew | **DIRECT** (skew = curl) | `wedge_antisymm`, `wedge_self` **proved** |
| geometric product `ab = a·b + a∧b` | `TMUL` = Eisenstein multiply; `z·conj w = dot + wedge` | **DIRECT** | `gp_decomp` **proved** |
| vector derivative `∇` | directed neighborhood sum (graph boundary/coboundary operator) | **OURS** (proposed discrete `∇`) | not yet formalized |
| `∇F = ∇·F + ∇∧F` | sym ⊕ skew (Helmholtz split of the edge) | **DIRECT** (algebra) | `sym_plus_skew` **proved** |
| source `J` (charge-current) | row imbalance `Σ_b O(a,b) − f(a)` = `div r(a)` | **OURS** (proposed reading) | **Lean-provable** (§5) |
| `∇∧F = 0` (source-free, Gauss-mag) | `div r = 0` under column-balancing | **ANALOGY** (reading) / **DIRECT** (identity) | follows from `sum_E_row` (§5) |
| charge conservation `Σ J = 0` | `Σ_a Σ_b (O−E) = 0` | **DIRECT** | `sum_residual_eq_zero` **proved** |
| field energy `E²+B²` | `ring² = Σ r²/E` (χ²) | **ANALOGY** (grade/units) | `ringSq`, `ringSq_nonneg` **proved** |
| invertibility (Green's function) | discrete FTC / telescope / `O = r + E` | **DIRECT** (cited) vs **DIRECT** (discrete FTC) | mathlib `sum_range_sub`; telescope proved |
| "lossless vs lossy" | sign collapse of surprise | **DIRECT** | `surprise_sign_collapse` **proved** |
| Hodge dual | anti-lattice (field correspondence, AGENTS.md) | **ANALOGY** | not formalized |

---

## 5. What's provable in Lean (exact statements)

### 5.1 Already proved (cite these, don't re-prove)

```lean
-- Residual.lean
theorem sum_E_row (f : V → ℕ) (a : V) (hT : T f ≠ 0) :
    (∑ b : V, E f a b) = (f a : ℚ)                    -- marginal / column balance
theorem sum_residual_eq_zero (f : V → ℕ) (O : V × V → ℕ) (hT : T f ≠ 0)
    (h_row : ∀ a, ∑ b, O (a, b) = f a) :
    (∑ a, ∑ b, (O (a, b) : ℚ) - E f a b) = 0          -- the telescope / charge conservation
theorem wedge_antisymm (V) (O : V × V → ℕ) (a b : V) :
    wedge V O a b = - wedge V O b a                    -- skew = curl is antisymmetric

-- Registers.lean
theorem wedge_eq_residual_skew (V) (O) (f) (a b) :
    (wedge V O a b : ℚ) = residual O f a b - residual O f b a   -- E cancels; wedge = skew of r
theorem sym_plus_skew (V) (O) (a b) :
    (O (a, b) : ℚ) = (O(a,b)+O(b,a))/2 + (O(a,b)-O(b,a))/2      -- Helmholtz split
theorem surprise_sign_collapse (r e : ℚ) :
    surpriseOf r e = surpriseOf (-r) e                -- the lossy projection, proved

-- DotWedge.lean  (Eisenstein ring)
theorem gp_decomp (z w : Eisenstein) : z * conj w = ⟨dot z w, wedge z w⟩
theorem wedge_antisymm (z w : Eisenstein) : wedge z w = - wedge w z
theorem dot_sq_add_wedge_sq (z w : Eisenstein) :
    dot z w ^ 2 + dot z w * wedge z w + wedge z w ^ 2 = norm z * norm w

-- OmegaEmbedding.lean  (the ℂ-embedding: geometric product = complex product)
theorem phi_mul (x y : Eisenstein) : phi (x * y) = phi x * phi y
theorem phi_injective : Function.Injective phi
```

### 5.2 New but routine (a candidate `Lattice/MaxwellMap.lean`)

The kernel of the mapping is the **source = row-imbalance** identity and its
**source-free-under-balancing** corollary. Both are `ring`/`simp`-grade from `sum_E_row`:

```lean
-- The node's "source" is the row imbalance:
--   div r(a) := Σ_b r(a,b) = (Σ_b O(a,b)) − f(a),  given T ≠ 0.
theorem div_residual_eq_row_imbalance (f : V → ℕ) (O : V × V → ℕ) (a : V) (hT : T f ≠ 0) :
    (∑ b : V, residual O f a b) = (∑ b : V, (O (a, b) : ℚ)) - (f a : ℚ) := by
  unfold residual
  simp_rw [Finset.sum_sub_distrib]
  rw [sum_E_row f a hT]
  ring

-- Source-free ⟺ column-balanced: div r(a) = 0 exactly when the observed row sum
-- equals the frequency (the ∇∧F = 0 / Gauss-for-magnetism analog).
theorem source_free_iff_row_balanced (f : V → ℕ) (O : V × V → ℕ) (a : V) (hT : T f ≠ 0) :
    (∑ b : V, residual O f a b) = 0 ↔ (∑ b : V, (O (a, b) : ℚ)) = (f a : ℚ) := by
  rw [div_residual_eq_row_imbalance f O a hT]
  constructor <;> intro h <;> linarith
```

This is the *only* genuinely new math the mapping needs, and it is mechanical. It proves: the
residual field's divergence **is** the row imbalance, and it vanishes **iff** the lattice is
column-balanced — the lattice statement of "the residual field is source-free."

### 5.3 NOT provable in Lean (keep out of the ledger)

- That `∇F = J` in STA is equivalent to the four Maxwell equations — a **cited continuum
  theorem** (Hestenes–Sobczyk; Doran–Lasenby), not a Lean statement (spacetime, vector
  derivative, smooth fields — all out of scope for the current discrete ledger).
- The continuum Green's-function invertibility (Cauchy kernel, fundamental theorem of
  geometric calculus) — **cited**, not Lean.
- "The residual *is* the electromagnetic field" / "the row imbalance *is* the charge-current"
  — **physical readings**, not theorems.
- Any `TGRAD` datapath cost (area/power/latency) — measured in yosys/ngspice, never
  `lake build`-proved (same rule as `eisen_opcode.md`'s TMUL +64.8% area).

---

## Sources

**Project-internal (DIRECT / OURS / PROVED):**
- `proofs/lean-src/hexagon/Hexagon/Residual.lean` — `r = O−E`, `E`, `sum_E_row`, `sum_residual_eq_zero`, `wedge_antisymm`, `ringSq_nonneg`.
- `proofs/lean-src/hexagon/Hexagon/Registers.lean` — `δ = r/E`, `wedge_eq_residual_skew`, `sym_plus_skew`, `surprise_sign_collapse`.
- `proofs/lean-src/hexagon/Hexagon/DotWedge.lean` — `gp_decomp`, `wedge_antisymm`, `dot_sq_add_wedge_sq`, `dot_swap`.
- `proofs/lean-src/hexagon/Hexagon/OmegaEmbedding.lean` — `phi_mul`, `phi_injective` (ℂ-embedding).
- `docs/GA_INSTRUCTIONS.md` — the `TGRAD`/`TCONJ`/`TDOT`/`TWEDGE` tier list.
- `docs/compute/einstein_calculus.md` — the discrete-FTC / scan framing this doc reuses.
- `LATTICE_MATH.md`, `AGENTS.md` (canonical truth: wedge = skew not area; ring = χ² not Fisher) — the guardrails.
- `/home/ian/opencode/parser/english/docs/source_surveys/geometric_algebra.md` — the `∇F = J` invertibility finding.
- `/home/ian/opencode/parser/english/docs/source_surveys/jacobian-determinant-matrix.md` — the det/curl split and the local-vs-global invertibility correction.
- `/home/ian/opencode/parser/english/docs/unified_field_map.md` — the field-correspondence table.

**External (DIRECT, classical — via the rebuild's GA corpus):**
- Hestenes, D. — *Space-Time Algebra* (1966). Origin of `∇F = J` in STA.
- Hestenes, D. & Sobczyk, G. — *Clifford Algebra to Geometric Calculus* (Springer, 1984). The vector derivative, its Green's function / Cauchy kernel, the fundamental theorem of geometric calculus.
- Doran, C. & Lasenby, A. — *Geometric Algebra for Physicists* (CUP, 2003). The `∇F = ∇·F + ∇∧F` split and the four-equation recovery.
- Macdonald, A. — *Vector and Geometric Calculus* and *Linear and Geometric Algebra* (free texts). The vector derivative on multivector fields.
- mathlib `Finset.sum_range_sub` — the discrete fundamental theorem of calculus (telescoping sum).

*(These are the sources the rebuild's `geometric_algebra.md` survey already lists; page-level
equation numbers are not reproduced here because the survey did not pin them — re-open the
tarballs if exact Eq. numbers are needed.)*

---

## TODO / not covered / caveats

- **Continuum vs discrete is the single biggest gap.** `∇F = J` and its Green's-function
  invertibility are **smooth-manifold theorems**; the lattice is **discrete**. The discrete
  echo (telescope + discrete FTC) is DIRECT but is a *different* theorem. Do not claim the
  continuum Green's function transfers automatically.
- **"Invertible" is local + boundary-data, not global.** Per our own Jacobian survey
  (`det ≠ 0` ⟹ local only; global needs properness / escape-to-infinity), `∇`'s inverse
  recovers a field *up to a monogenic part fixed by boundary values*. "Lossless reconstruction"
  must be read with that qualifier or it over-claims.
- **The `∇` on the lattice is not yet defined.** The discrete geometric-derivative
  (directed neighborhood sum / graph boundary operator, weighted by the `ω`-rotor) is
  **proposed**, not formalized. Until `TGRAD` and its accumulate-inverse are specified in the
  RTL, "the residual IS `∇F`" stays ANALOGY/OURS.
- **Two "divergence" objects.** This doc's §2.3 split (row-sum `div r` = the source vs
  `curl_field`'s `flow = Σ wedge` = the div-of-curl) is the come-to-terms that must precede
  any claim. The rebuild's existing "div=0 topic centers" refer to the *flow*, not to the
  row-sum source — do not conflate them.
- **`J` is a proposed reading, not measured.** "Row imbalance = semantic charge" is OURS; no
  experiment checks whether a column-balanced lattice has `div r = 0` in the *production*
  `.latx` (N17 rebuild as directional signed `.latx` is still the release gate — the three
  axes do not exist in the old symmetric libs yet).
- **`TGRAD` is uncosted.** Every datapath structure pays the ternary tax (TMUL was +64.8%
  area; a 6-neighbor scan is an adder tree). No area/power/latency number exists for the
  `∇`-instruction; treat "lossless reconstruction in silicon" as SPECULATION until measured.
- **Units/conventions unpinned.** The exact signs and units of `∇F = J` depend on the STA
  convention (metric sign, `c=1` vs explicit `μ₀ε₀`, `F = E+IB`). This doc states only the
  convention-independent grade structure.
- **Hodge dual / anti-lattice left as ANALOGY.** The AGENTS field-correspondence table maps
  "Hodge dual = anti-lattice," but no construction ties the anti-lattice to `∇`'s dual;
  leave unformalized.
