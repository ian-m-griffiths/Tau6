# Einstein Calculus — calibrated analysis

**2026-08-29 — research/analysis doc (not a proof, not a measurement).** Explores Ian's
"Einstein calculus" idea against the residual math, the energy laws, and the existing
compute surveys. Calibration legend (repo-wide, unchanged): **DIRECT** = proved/measured/
classical theorem; **ANALOGY** = structural resemblance, not an identity; **OURS** = our
design claim following from DIRECT; **SPECULATION** = untested hypothesis, flagged.

---

## 0. TL;DR (the verdict up front)

"Einstein calculus" = the **discrete calculus carried by Eisenstein-integer (60° triangle)
vectors**: a *delta* (forward difference), a *sum-over-time* (telescoping / the discrete
Fundamental Theorem of Calculus), and an *acceleration* (second difference). Each piece is
**DIRECT, classical mathematics**, and three of the four building blocks are *already proved*
in `proofs/lean-src/hexagon/Hexagon/` or sitting in mathlib.

The **acceleration claim is half-right and half-over-claimed**:

- **Real:** "sum over time" is associative accumulation, and associative accumulation *does*
  parallelize — the parallel-prefix **scan** has O(log N) *depth* (latency) versus O(N)
  sequential. This is not new: the **Kogge–Stone adder (1973) is a hardware scan**, present
  in every modern ALU's carry chain, and GPU scan (CUB/Thrust) is a 30-year-old first-class
  primitive. Sparse/constant *higher differences* go further: a constant-acceleration
  trajectory has a **closed form** (`Σ(v₀ + ak) = N·v₀ + a·N(N−1)/2`), i.e. O(1) per segment.
- **Over-claimed:** O(log N) is *depth*, not *work* (work stays O(N); you pay in area/power).
  Scan parallelizes only **associative** operations — a general *nonlinear* recurrence
  `xₜ₊₁ = F(xₜ)` has a true serial dependency chain and does **not** scan-parallelize. So
  "accelerates multi-step/recurrent instructions" is true for the *linear/associative* class
  and false as a general statement.

**Verdict:** "Einstein calculus" is a **new *instruction abstraction*** (delta-encoded
Eisenstein accumulation + a scan/prefix primitive) layered on **existing, mature primitives**
(parallel-prefix scan / Kogge–Stone carry / GPU scan / differential coding). It is **NOT a new
class of hardware**. The "new class of hardware" claim is **SPECULATION** — a design
hypothesis, not a result — and it must survive the same honest costing the project already
applies to every datapath structure (a single Eisenstein multiply cost **+64.8% area**, per
`docs/compute/eisen_opcode.md`).

---

## 1. What "Einstein calculus" is — precise definition + come-to-terms

### 1.1 The three primitives (discrete calculus)

Ian's decomposition, made precise:

| Ian's phrase | Formal object | Definition | Discrete-calculus name |
|---|---|---|---|
| "relative deltas" | **forward difference** | `Δf(t) = f(t+1) − f(t)` | the **derivative** |
| "encoded as Einsteinian (60°) triangles" | **Eisenstein vector** | a delta is `a + bω`, `ω = e^{iπ/3}`, `ω² = ω−1` | the displacement in the 60° basis `{1, ω}` |
| "sum over time" | **telescoping sum** | `Σ_{t=0}^{N−1} Δf(t) = f(N) − f(0)` | the **integral** (discrete FTC) |
| "acceleration" | **second difference** | `Δ²f(t) = Δf(t+1) − Δf(t) = f(t+2) − 2f(t+1) + f(t)` | the **second derivative** |

**The "60° triangle" is the fundamental triangle** of the Eisenstein lattice: vertices
`{0, 1, ω}`, an equilateral triangle (all three sides have norm 1). A delta vector
`(a, b) = a·1 + b·ω` is a displacement expressed in that 60° basis — "encoding a delta as an
Einsteinian triangle" means "carrying the difference as an Eisenstein integer, whose
fundamental cell is the 60° triangle."

**The two classical anchors** (both DIRECT, both textbook):

1. **Discrete Fundamental Theorem of Calculus:** `Σ_{t=0}^{N−1} Δf(t) = f(N) − f(0)`.
   This *is* "sum over time = the integral." It is in mathlib as `Finset.sum_range_sub`.
2. **Newton's forward-difference formula:** `f(t) = Σ_k C(t, k)·Δᵏf(0)` — a function is
   recovered from *all* its higher differences at `t=0`. When the higher differences are
   **constant or sparse** (acceleration constant, jerk zero, …), the sequence is a
   low-degree polynomial and the whole segment collapses to a few coefficients. This is the
   *content* of "time-based function acceleration": sparse-higher-difference trajectories
   compress and telescope. **DIRECT** (classical finite-difference calculus).

### 1.2 Come to terms: three different "Einstein/Eisenstein" objects

`How to Read a Book` rule 4 (AGENTS.md): resolve the naming collision before mapping.
There are **three** objects here, two of which share a *name* and only one of which is Ian's
"calculus":

| Object | Author | What it is | Relevant? |
|---|---|---|---|
| **Einstein summation convention** | Albert Einstein (1916, GR) | tensor *index notation*: repeated up/down indices are summed over | ❌ a notation, not the calculus |
| **Eisenstein integers** `ℤ[ω]` | Gotthold Eisenstein (1844) | the 60° triangular lattice, `ω = e^{iπ/3}`, norm `a²+ab+b²`, units Z₆ | ✅ the "triangle" |
| **"Einstein calculus"** | Ian (2026) | discrete calculus on the Eisenstein lattice: delta + telescope + second difference | ✅ the subject of this doc |

**The disambiguation, in one line:** "Einstein calculus" is *Eisenstein* calculus (after
Gotthold Eisenstein, the 60°-lattice man) mis-spelled through Albert Einstein. The Einstein
*summation convention* has nothing to do with it except (a) the shared word "Einstein" and
(b) the shared word "sum."

**The one legitimate (ANALOGY) resonance, stated carefully:** the Einstein summation
convention *is* literally a "sum over an index," and its whole purpose is **coordinate
invariance** — contracted indices are the ones that transform away, leaving an invariant
object. Our project's gauge story is the same theme at the discrete level (`δ = O/E − 1` is
proved gauge-invariant; χ² is proved *not*, per `ChiSquareGauge.lean`). So "sum-over-time"
and "sum-over-index" both *end up at* invariants — but by different mechanisms (telescoping
cancellation vs. index contraction). **ANALOGY, not identity.**

### 1.3 The already-documented "Einstein triangle" collision (three senses)

The project has *already* disambiguated "Einstein triangle" as a **three-sense term**
(`survey/SYNTHESIS.md`, `survey/oxalpha_lens.md` TARGET 1, `survey/hexigon_lens.md`):

1. **The hexigon thread's sense** = the Eisenstein integer lattice `ℤ[ω]` (60° lattice). ←
   *this* is the sense "Einstein calculus" builds on.
2. **ox alpha.md's sense** = Ian's one-off *geometric-mean* triangle, used once (L4996) to
   compute the integer-safe polar ratio `(O−E)/E`; superseded by the marginal identity
   ("needs no Einstein triangle — just one global division", L5093). **Not** the lattice.
3. **"Einsteinian" elsewhere** = the test-only density-dilation frame `E·ρ(a)ρ(b)`
   (interchangeability proof; "do NOT productionize"). **Not** the lattice.

**Consequence for this doc:** "Einstein calculus" attaches to sense (1) — the Eisenstein
lattice — and is a *new* layer on top of it (the differential/integral structure), which the
surveys did not cover. It must not be read as senses (2) or (3).

---

## 2. The map to what we have (residual / wedge / Lagrangian)

### 2.1 Is `r = O − E` a delta?

**DIRECT for "delta = signed difference"; ANALOGY for "delta = time derivative."**

- `r(a,b) = O(a,b) − E(a,b)` is *literally* a difference (observed count minus the
  independence null). `Residual.lean` defines it as such, and proves it **telescopes**:
  `sum_residual_eq_zero` (`Σ_a Σ_b (O−E) = 0`), via the marginal identity `sum_E_row`
  (`Σ_b E(a,b) = f(a)`). That cancellation is a genuine discrete-FTC-shaped result —
  **DIRECT, PROVED.**
- But it telescopes over the **vocabulary index `b`** (each row's residual sums to zero), not
  over a **time axis**. The rebuild has no parametrized time; it has a *directional* axis
  `a → b`. The residual is a delta *from a null model*, not a forward difference *along a
  sequence*. So the specific claim "r = O−E **is** the derivative of the instruction stream"
  is **ANALOGY** — it needs the time axis that Ian's proposal *supplies*, and that the
  rebuild does not (yet) have.
- The *normalized* delta already exists and is proved: `δ = O/E − 1 = r/E`
  (`δ_eq_residual_div`, `Registers.lean`) — "relative delta" in exactly Ian's sense (a ratio,
  not an absolute), sitting in the register ladder raw/fold/z/surprise. **DIRECT, PROVED.**

### 2.2 Is the Lagrangian `L = T − V` summed over the phrase a "sum over time" = the action?

**DIRECT as our own defined correspondence; ANALOGY as physics.**

- The rebuild *already* defines `L(w) = ring/2 + log(f/T)` per word and **sums it over the
  phrase**, calling the sum the action (`AGENTS.md`: "The total action over a phrase IS the
  discrete integral — each bigram step contributes `ΔL = L(b) − L(a)`"). This is "sum over
  time" as a *defined* object in the project. **DIRECT** (it is our definition and our
  computation).
- The physics calibration stays as AGENTS.md already settled it: physical action is `∫L dt`
  with *stationarity* `δS = 0` (Euler–Lagrange); the rebuild's finding is **constant action =
  a level set** — coherent speech *keeps* `∫L` constant, it does **not** minimize it. "Least
  squares = least action" was **retired**. So "sum over time = the action" is **DIRECT** as
  *naming*, **ANALOGY** as *the variational principle*.
- The one thing to add for *this* doc: the rebuild's "sum over time" is **sequential** (walk
  the bigram chain, accumulate `L`). The acceleration claim (§3) is *precisely* the proposal
  to turn this sequential sum into a parallel scan. Nothing about the current implementation
  is parallel.

### 2.3 Is the wedge the "angular" part of the delta?

**DIRECT as the antisymmetric/skew part; ANALOGY for "angular = phase/rotation."**

- The wedge `O_ab − O_ba` is the **skew (antisymmetric) part** of the ordered bigram table,
  and it *is* the antisymmetric part of the residual too: `wedge_eq_residual_skew`
  (`r(a,b) − r(b,a) = O_ab − O_ba`, the E-terms cancel), plus the Helmholtz-style split
  `sym_plus_skew`. AGENTS.md states it directly: **"The wedge IS the anti-symmetric
  derivative."** **DIRECT, PROVED.**
- In the polar decomposition `(a·b)² + (a∧b)² = |a|²|b|²`, the wedge carries the
  `sin(θ)`/bivector part — that is the sense in which it is "angular." **DIRECT** as the
  antisymmetric component; **ANALOGY** if "angular" is read as a *continuous phase*: the
  wedge is an **orientation signal** (temporal precedence / curl), not a continuous angle,
  and AGENTS.md canonical truth says explicitly it is "NOT bivector area, NOT a causal arrow."

### 2.4 The map table

| Ian's "Einstein calculus" object | Our object | Calibration | Status |
|---|---|---|---|
| delta (difference) | `r = O−E` signed residual | DIRECT (a difference); the telescope `Σ(O−E)=0` PROVED | `Residual.lean` |
| *normalized* delta | `δ = r/E = O/E − 1` | DIRECT | `Registers.lean` |
| delta-as-time-derivative | (no time axis in the rebuild) | **ANALOGY** — the time axis is the missing ingredient | not yet formalized |
| angular part of the delta | wedge `O_ab − O_ba` = skew part | DIRECT (antisymmetry) / ANALOGY (phase) | `Residual.lean` `wedge_antisymm`, `Registers.lean` `wedge_eq_residual_skew` |
| sum over time = integral | `Σ L` over the phrase = action | DIRECT (our definition) / ANALOGY (variational principle) | AGENTS.md, constant-action finding |
| acceleration = second difference | "second-order pairs oscillate" (AGENTS.md) | ANALOGY (observation, not a formal second difference) | not formalized |

**Bottom line of §2:** the *delta* (and its normalized form, and its angular/skew part) is
**DIRECT and proved**; the *sum-over-time* is **DIRECT as our own definition but sequential**;
the *second difference / acceleration* is **not yet formalized** — it exists only as a prose
observation. The genuinely new thing Ian is proposing is **the time axis + the parallel
scan**, neither of which the rebuild has.

---

## 3. The acceleration claim — real technique vs speculation

The claim: a native "sum over time" (parallel prefix-sum / scan, O(log N) vs O(N) sequential)
accelerates multi-step/recurrent instructions. **Calibrated piece by piece.**

### 3.1 What is real (DIRECT precedent)

| Technique | Mechanism | Precedent | Calibration |
|---|---|---|---|
| **Parallel-prefix scan** | associative accumulation in O(log N) *depth*, O(N) *work* | Hillis & Steele (1986); Blelloch (1990) | DIRECT — classical, [CMU-CS-90-190](https://www.cs.cmu.edu/~scandal/papers/CMU-CS-90-190.html) |
| **Kogge–Stone adder** | a scan over carry bits — addition at O(log N) depth, not O(N) ripple | Kogge & Stone (1973), in every modern ALU | DIRECT — "sum → O(log N)" is *already in silicon*, 50 years old |
| **GPU scan** | `scan`/`inclusive_scan` as first-class device primitives | NVIDIA CUB / Thrust | DIRECT — production primitive |
| **Differential coding** | store the *delta*, reconstruct by accumulation | DPCM, delta-sigma modulation, video/audio codecs | DIRECT — "state → relative delta" is a mature signal-processing technique |
| **Neural ODE / reservoir** | parametrize the *derivative* `dh/dt = f(h,t)`, integrate (accumulate) | Chen et al. 2018 ([arXiv:1806.07366](https://arxiv.org/abs/1806.07366)) | ANALOGY — "learn the delta, integrate the state" is the same shape, different substrate |

**Reading:** the *primitive* Ian is gesturing at — delta-encode, then accumulate in
logarithmic depth — is **not new**. It is the Kogge–Stone adder, the GPU scan, and
differential coding, combined. The honest first sentence of any design claim must be: *"this
is a new way to package three mature techniques, not a new technique."*

### 3.2 The two honest caveats (where the claim over-reaches)

**Caveat 1 — O(log N) is *depth*, not *work*.** A scan still performs O(N) additions; it
just overlaps them. The win is *latency* (time-to-result), bought with *area and power*
(more adders in parallel). For the Tau architecture this is not a free lunch — it is exactly
the tension the project has already measured:

- `ENERGY_LAWS.md`: parallelism can *duplicate* energy, not divide it ("more sense amps would
  duplicate energy, not divide it").
- `eisen_opcode.md`: **one** Eisenstein multiply (TMUL) added **+64.8% area** to the core,
  and the 2-bits/trit encoding already pays 2.0–4.3× per gate over binary
  (`gate_area.md`). A scan unit is a *tree of adders* — it will be area-heavy, and every
  ternary gate pays the 2-threshold receiver tax (Law 1 reframe, `control.md`).

So "O(log N) acceleration" is real *latency* arithmetic, but the *cost* side (area, power,
receiver tax) is exactly what the project measures, and it is not zero.

**Caveat 2 — scan parallelizes only *associative* operations.** The prefix sum works because
`(+)` is associative. A general multi-step/recurrent instruction `xₜ₊₁ = F(xₜ)` with arbitrary
`F` has a **true serial dependency** and does **not** scan-parallelize. What *does* parallelize:

- accumulation (`x += aₜ`), and
- **linear recurrences** (`xₜ = Aₜ·xₜ₋₁ + bₜ`) — the general first-order linear recurrence is
  itself scan-able via a matrix-multiply scan (Blelloch's "scan higher-order recurrences").
  This is the IIR-filter / linear-dynamics class.

So the honest statement is: **a native sum-over-time accelerates the *linear/associative*
class of multi-step instructions** (accumulation, first-order linear recurrences, any
associative fold). It does **nothing** for a general nonlinear recurrent unit (e.g. an
unrolled neural-net cell with a nonlinearity), whose dependency chain stays serial. "Accelerates
multi-step/recurrent instructions" without that qualifier is **over-claimed**.

### 3.3 The strongest honest version (sparse higher differences)

There *is* a version of the claim that is stronger than O(log N), and it is the one worth
pursuing: **if the higher differences of the instruction sequence are sparse or constant,
the whole segment has a closed form.**

- Constant acceleration ⇒ the sum telescopes to a quadratic: `Σ_{k=0}^{N−1} (v₀ + a·k) =
  N·v₀ + a·N(N−1)/2` — O(1) to evaluate the entire segment, not O(log N) or O(N). (The
  underlying sum identity is mathlib's `Finset.sum_range_id`.)
- More generally, Newton's forward-difference formula recovers `f(t)` from `{Δᵏf(0)}`; if
  `Δᵏf ≡ 0` beyond some `k`, `f` is a degree-`(k−1)` polynomial. **This is the "time-based
  function acceleration" Ian is pointing at**, and it is real: *sequences whose acceleration
  (or higher differences) is cheap to describe are cheap to compute in bulk.*

**Calibration:** DIRECT (classical finite-difference calculus), and it gives a *compression*
win (encode a trajectory in a few coefficients) *on top of* the scan's *latency* win. This is
the honest, strong core of the idea.

### 3.4 Precedent table (real technique vs speculation)

| Claim | Calibration | Notes |
|---|---|---|
| Associative accumulation parallelizes to O(log N) depth | DIRECT | Hillis–Steele, Blelloch |
| This is already in silicon (carry = scan) | DIRECT | Kogge–Stone adder, every ALU |
| Delta-encode + accumulate is a mature technique | DIRECT | DPCM, delta-sigma, codecs |
| A native "sum-over-time" unit accelerates linear/associative recurrences | **OURS** (follows from DIRECT, unmeasured) | scan is sound; cost is area/power |
| It accelerates *general* (nonlinear) recurrent instructions | **SPECULATION → mostly false** | serial dependency chain persists |
| Sparse/constant higher differences give O(1) closed forms | DIRECT (math) | `sum_range_id`, Newton forward differences |
| …and therefore a delta-encoded Eisenstein instruction stream is faster *in silicon* | **SPECULATION** | no such datapath exists; area/energy unmeasured |
| "A new class of hardware" | **SPECULATION** (design hypothesis) | the primitive is 50 years old; only the encoding/lattice is new |

---

## 4. What's provable in Lean (exact statements)

The math is highly formalizable; the *silicon* claims are not. Statements are given in the
existing namespace style (`Lattice` for residual stuff, `Hexagon` for lattice stuff). Names
marked **[mathlib]** exist already and are importable.

### 4.1 Already proved (in the ledger)

```lean
-- Residual.lean
theorem sum_E_row (f : V → ℕ) (a : V) (hT : T f ≠ 0) :
    (∑ b : V, E f a b) = (f a : ℚ)                        -- marginal / column balance

theorem sum_residual_eq_zero (f : V → ℕ) (O : V × V → ℕ) (hT : T f ≠ 0)
    (h_row : ∀ a : V, ∑ b : V, O (a, b) = f a) :
    (∑ a : V, ∑ b : V, ((O (a, b) : ℚ) - E f a b)) = 0    -- the residual telescopes

theorem wedge_antisymm (V : Type) (O : V × V → ℕ) (a b : V) :
    wedge V O a b = - wedge V O b a                        -- the skew part is antisymmetric

-- Registers.lean
theorem δ_eq_residual_div (O : V × V → ℕ) (f : V → ℕ) (a b : V) (hE : E f a b ≠ 0) :
    δ O f a b = residual O f a b / E f a b                 -- normalized delta = r/E

theorem wedge_eq_residual_skew (V : Type) [Fintype V] (O : V × V → ℕ) (f : V → ℕ)
    (a b : V) :
    (wedge V O a b : ℚ) = residual O f a b - residual O f b a  -- wedge = skew of r

theorem sym_plus_skew (V : Type) (O : V × V → ℕ) (a b : V) :
    (O (a, b) : ℚ) = ((O (a, b) : ℚ) + (O (b, a) : ℚ)) / 2
                   + ((O (a, b) : ℚ) - (O (b, a) : ℚ)) / 2     -- Helmholtz split

-- Conventions.lean
theorem mul_comm (x y : Eisenstein) : x * y = y * x
theorem norm_mul (x y : Eisenstein) : norm (x * y) = norm x * norm y

-- Rotation.lean
theorem units_card : units.card = 6
theorem units_closed_under_mul (x y : Eisenstein) (hx : x ∈ units) (hy : y ∈ units) :
    x * y ∈ units
```

### 4.2 In mathlib already (import; the discrete calculus exists)

```lean
-- The discrete FTC / telescoping sum.  [mathlib: Finset.sum_range_sub]
-- ∑ i ∈ Finset.range n, (f (i + 1) - f i) = f n - f 0
-- (proved in Mathlib/Algebra/BigOperators/Group/Finset/Basic.lean, the
--  to_additive of the telescoping product)

-- The sequential scan recurrence.  [mathlib: Finset.sum_range_succ]
-- ∑ i ∈ Finset.range (n + 1), f i = (∑ i ∈ Finset.range n, f i) + f n

-- "Sum of a linear sequence is quadratic" — the constant-acceleration closed form.
-- [mathlib: Finset.sum_range_id]
-- ∑ i ∈ Finset.range n, i = n * (n - 1) / 2
```

The second of these (`sum_range_succ`) is *exactly* the sequential recurrence a scan
computes; the third (`sum_range_id`) is the discrete `∫ t dt = t²/2` behind the O(1)
constant-acceleration segment.

### 4.3 New but routine (a candidate `Hexagon/EinsteinCalculus.lean`)

```lean
namespace Hexagon
open Eisenstein

-- Forward difference (discrete derivative) of a lattice-valued instruction stream.
def fwdDiff (f : ℕ → Eisenstein) (t : ℕ) : Eisenstein := f (t + 1) - f t

-- Second difference (discrete acceleration).
def secondDiff (f : ℕ → Eisenstein) (t : ℕ) : Eisenstein := fwdDiff (fwdDiff f) t

-- T-Δ: the second difference is the difference of consecutive differences.
theorem secondDiff_eq_fwdDiff (f : ℕ → Eisenstein) (t : ℕ) :
    secondDiff f t = fwdDiff f (t + 1) - fwdDiff f t := rfl

-- T-Δ²: the second difference expands to f(t+2) − f(t+1) − (f(t+1) − f(t)).
theorem secondDiff_expand (f : ℕ → Eisenstein) (t : ℕ) :
    secondDiff f t = (f (t + 2) - f (t + 1)) - (f (t + 1) - f t) := by
  rw [secondDiff, fwdDiff, fwdDiff]

-- T-△: the delta is a lattice vector — the fundamental 60° triangle {0, 1, ω} is
-- equilateral (each side has norm 1), so a delta a·1 + b·ω is a 60°-basis displacement.
theorem fundamental_triangle_equilateral :
    norm (1 : Eisenstein) = 1 ∧ norm (⟨0, 1⟩ : Eisenstein) = 1 ∧
    norm ((1 : Eisenstein) - ⟨0, 1⟩) = 1 := by
  -- norm(a+bω) = a² + ab + b²; all three reduce by ring_nf/norm_num
  constructor <;> · simp [norm]

-- T-ΣΔ (the discrete FTC, specialized to Eisenstein-valued streams): the sum over time
-- of the deltas is the net displacement.  [follows from mathlib Finset.sum_range_sub]
theorem sum_fwdDiff (f : ℕ → Eisenstein) (N : ℕ) :
    ∑ t ∈ Finset.range N, fwdDiff f t = f N - f 0 := by
  simp [fwdDiff, Finset.sum_range_sub]

-- T-accel (constant acceleration ⇒ closed form): if the second difference is the
-- constant c, the cumulative sum of the first differences is linear in t.  This is the
-- O(1)-per-segment statement, resting on Finset.sum_range_id.
-- (Stated for a commutative monoid with nsmul; the Eisenstein structure needs its
--  AddCommGroup instance assembled first — deferred in Conventions.lean.)
```

**Honesty note:** the last statement (T-accel, constant acceleration ⇒ closed form) requires
a full `AddCommGroup` (or `Module`) instance on `Eisenstein`, which `Conventions.lean`
explicitly **deferred** ("the full `CommRing Eisenstein` typeclass instance is DEFERRED").
The *scalar* version over `ℤ`/`ℚ` is immediate via `Finset.sum_range_id` and the
`nat`-multiplication on any additive group; the *Eisenstein-vector* version waits on that
typeclass assembly. Neither is hard — both are `ring`/`simp`-grade.

### 4.4 NOT provable in Lean (silicon facts, keep out of the ledger)

The following are **circuit/silicon** claims, not math — they are measured (yosys/ngspice)
or simulated, never `lake build`-proved:

- **O(log N) *depth* / O(N) *work*** of a scan — a complexity statement about a circuit, not
  a Lean theorem (though its *soundness*, associativity, is Lean-provable, §4.2/§4.3).
- **Area/power cost** of a scan unit (adders tree, 2-threshold receiver tax per ternary gate).
- **"Faster in silicon"** for the delta-encoded Eisenstein instruction stream.
- **"A new class of hardware."**

Keep these in `docs/compute/` and `circuit/`, exactly as the repo already does for TMUL
(`eisen_opcode.md`) and the receiver floor (`ENERGY_LAWS.md`).

---

## 5. Calibrated verdict — new hardware class vs new instruction abstraction

**The verdict: a new *instruction abstraction* on existing primitives, not a new class of
hardware.**

| Level of the idea | What it is | Calibration |
|---|---|---|
| Discrete calculus (delta / telescope / second difference) | classical finite-difference math, the discrete FTC | **DIRECT** (and largely in mathlib) |
| "Delta = Eisenstein (60°) vector" | the residual/δ/lattice-vector encoding, connecting to hex addressing | **DIRECT** for the encoding math; **OURS** as a datapath design |
| "Sum over time = scan" | parallel-prefix accumulation | **DIRECT technique** — Kogge–Stone (1973), GPU scan (30 yrs) |
| "Acceleration = second difference, sparse ⇒ closed form" | finite-difference compression + telescoping | **DIRECT** (math), **OURS** (as a hardware encoding) |
| "Native sum-over-time accelerates multi-step/recurrent instructions" | a real but *qualified* claim (associative/linear class only; depth ≠ work) | **OURS** for the linear class; **false in general** |
| "A new class of hardware" | a design hypothesis | **SPECULATION** |

**What is genuinely new-ish (and worth testing):** the *encoding* — carrying instruction
state as **relative deltas expressed as Eisenstein lattice vectors**, with a **scan/prefix
primitive** doing the accumulation, on the existing balanced-ternary + hex-addressing
substrate. That is a **new instruction abstraction** (like SIMD, VLIW, or systolic dataflow
were at their inception — new *ways to express* computation on existing silicon), not a new
physical computing paradigm (like ternary itself, or reversible/adiabatic logic, which
change the *physics*).

**The test that would move it from SPECULATION to OURS** (mirroring how the project already
tests every idea):

1. **Define the delta-encoded instruction format** (what is the "state" `f(t)`, what is the
   delta register, is the delta signed or normalized — reuse `δ = r/E` vs `r`).
2. **Measure the scan unit** in yosys/ngspice exactly as `eisen_opcode.md` did for TMUL:
   area, depth, energy — and report whether O(log N) latency is worth the adder-tree area
   *after* the 2-threshold receiver tax.
3. **Bound the associative class** the scan actually accelerates (accumulation, linear
   recurrences) and say *which* multi-step instructions are in it and which (nonlinear
   recurrent cells) are not.
4. **Verify the closed-form win** for constant/sparse higher differences against real
   instruction streams — does the acceleration of real programs *stay constant/sparse*, or
   is that an idealized assumption?

Until those four are measured, the honest label is: **SPECULATION — a coherent design
hypothesis built on a DIRECT mathematical foundation (discrete FTC) and a DIRECT hardware
primitive (parallel-prefix scan), but with no measured datapath, no bounded applicability
class, and no cost model.**

---

## Sources

**Project-internal (DIRECT / OUR / PROVED):**
- `proofs/lean-src/hexagon/Hexagon/Residual.lean` — `r = O−E`, `sum_E_row`, `sum_residual_eq_zero`, `wedge_antisymm`.
- `proofs/lean-src/hexagon/Hexagon/Registers.lean` — `δ = r/E`, `wedge_eq_residual_skew`, `sym_plus_skew`.
- `proofs/lean-src/hexagon/Hexagon/Conventions.lean` — `Eisenstein`, `ω² = ω−1`, `norm = a²+ab+b²`, `mul_comm`, `norm_mul`.
- `proofs/lean-src/hexagon/Hexagon/Rotation.lean` — Z₆ units, `hexDist` metric.
- `docs/ENERGY_LAWS.md` — the three laws (receiver gauge-agnostic; parallelism duplicates energy).
- `docs/compute/eisen_opcode.md` — TMUL = +64.8% area, the honest costing method.
- `docs/compute/control.md` — ternary wins in datapath, costs in control; 2-threshold decode tax.
- `docs/compute/euler_constants.md` — the calibration ledger style this doc follows.
- `survey/SYNTHESIS.md`, `survey/oxalpha_lens.md`, `survey/hexigon_lens.md` — the "Einstein triangle" three-sense disambiguation.
- `LATTICE_MATH.md` — the residual/register/δ cheatsheet.

**External (DIRECT, classical):**
- Blelloch, G. — *Prefix Sums and Their Applications* (1990), [CMU-CS-90-190](https://www.cs.cmu.edu/~scandal/papers/CMU-CS-90-190.html).
- Hillis, W. D. & Steele, G. L. — *Data Parallel Algorithms*, CACM 29(12), 1986.
- Kogge, P. M. & Stone, H. S. — *A Parallel Algorithm for the Efficient Solution of a General Class of Recurrence Equations*, IEEE Trans. Computers C-22(8), 1973. (See [Wikipedia — Kogge–Stone adder](https://en.wikipedia.org/wiki/Kogge%E2%80%93Stone_adder).)
- Chen, R. T. Q., Rubanova, Y., Bettencourt, J., Duvenaud, D. — *Neural Ordinary Differential Equations*, NeurIPS 2018, [arXiv:1806.07366](https://arxiv.org/abs/1806.07366).
- [Wikipedia — Prefix sum](https://en.wikipedia.org/wiki/Prefix_sum) — scan, work-efficient scan, Hillis–Steele/Blelloch.
- [Wikipedia — Eisenstein integer](https://en.wikipedia.org/wiki/Eisenstein_integer) — ℤ[ω], norm, Z₆ units.
- [Wikipedia — Einstein notation](https://en.wikipedia.org/wiki/Einstein_notation) — the summation convention (disambiguated, §1.2).
- mathlib `Mathlib/Algebra/BigOperators/Group/Finset/Basic.lean` (`Finset.sum_range_sub`, the telescoping sum) and `Mathlib/Algebra/BigOperators/Intervals.lean` (`Finset.sum_range_id`), local checkout at `proofs/lean-src/hexagon/.lake/packages/mathlib/`.
