# The Heat Equation as a Computation — survey + map to the residual/energy

**2026-08-29 — research/analysis doc (not a proof, not a measurement).** Surveys the heat
equation `∂u/∂t = α∇²u` as a *type of computation* (Ian's intuition: "the heat equation is an
important type of computation"), and maps it to the Tau energy analysis. Calibration legend
(repo-wide, unchanged): **DIRECT** = proved/measured/classical theorem; **ANALOGY** = structural
resemblance, not an identity; **OURS** = our design claim following from DIRECT; **SPECULATION**
= untested hypothesis, flagged.

Read first: `docs/ENERGY_LAWS.md` (three laws; energy = dissipation), `docs/TERNARY_COMPUTE_VERDICT.md`
(the measured energy), `~/opencode/parser/english/docs/surveys/statistical-mechanics.md` (wedge =
antisymmetric = time irreversibility; fluctuation theorems; "least squares = least action" as a
large-deviation rate function), `~/opencode/parser/english/docs/source_surveys/physics_texts.md`
(Planck: wedge = *sign* of irreversibility).

---

## 0. TL;DR (the verdict up front)

The heat equation is the **relaxation/equilibration primitive**: it takes a field and repeatedly
replaces each point by the average of its neighbors, burning off gradient energy until the field
is **harmonic** (`∇²u = 0`) — the *smoothest* field matching the boundary data. "Solving the heat
equation" computes **the harmonic extension / the minimum-Dirichlet-energy interpolation of the
boundary values**: the boundary is the *input*, the interior equilibrium is the *output*. It is a
genuine computation because **the relaxation to equilibrium IS the solve** — no separate "solver"
is needed, the physics does it.

The map to us is real but **mostly ANALOGY, with one DIRECT spine**:

- `r = O − E` relaxing to 0 (`O → E`) has the *shape* of a diffusion (a field decaying toward its
  null, with a nonnegative functional decreasing monotonically) — **ANALOGY**, because the lattice
  has no parametrized time axis and no `∇²` operator running it; the relaxation is a statistical
  direction (measured `O` toward the independence null `E`), not a dynamical PDE.
- The "energy" we measured, `χ² = Σ(O−E)²/E`, **is** a dissipation (a monotone that hits zero at
  the null and decreases under relaxation) — **ANALOGY as an object** (it is a *divergence*, not a
  physical energy, per the statistical-mechanics survey), but it plays the heat-flow's
  `dE/dt ≤ 0` role exactly.
- `∇²` **is** the relaxation step *in the heat equation* (`u ← u + α∇²u`), and in GA `∇²` is the
  square of the geometric derivative — **DIRECT** (Hestenes). But *our* lattice does not yet have
  a `∇²`; the closest object is the Tier-3 `TGRAD` in `GA_INSTRUCTIONS.md`, which is **SPECULATION**.

The sharpest single result: **the two zeros in our canonical truth are the two endpoints of the
heat flow.** `O → E` (feedback equilibrium = noise) is the *uniform* fixed point (all structure
dissipated, `∇u = 0`); `div = 0` (topic center = max structure) is the *harmonic* fixed point
(`∇²u = 0` but `∇u ≠ 0`, structure preserved but smoothed). The heat equation names both — and
says they are the *same operator's* (`∇²`) two degenerate cases.

---

## 1. What the heat equation is, as a computation

### 1.1 The primitive (plain English)

`∂u/∂t = α∇²u`. Read it as an instruction: *"make each point move toward the average of its
surroundings."* In the discrete form the step is

```
u(x, t+dt) = u(x, t) + α·dt·∇²u(x, t)
```

and the discrete Laplacian is exactly a **neighbor average minus self**:

```
∇²u(x) ≈ (mean of u over neighbors of x) − u(x)
```

So one step is `u ← (1−α)u + α·(neighbor mean)` — a **damped local averaging**. Iterate it, and
the field **relaxes** to equilibrium. This is the same update as **Jacobi / Gauss–Seidel
relaxation**, used everywhere for solving elliptic PDEs, smoothing images, denoising, mesh
Laplacian smoothing, and graph diffusion. **DIRECT (classical, textbook).**

### 1.2 What "solving" it computes

Three equivalent answers, all DIRECT:

1. **The steady state.** At equilibrium `∂u/∂t = 0`, so `∇²u = 0` — the field is **harmonic**.
   A harmonic function is the unique field that is "as flat as possible" subject to its boundary
   values (mean-value property: `u(x)` = the average of `u` over any sphere centered at `x`).
2. **The minimum-Dirichlet-energy interpolation.** The heat equation is the **gradient flow**
   (steepest descent, in the L² metric) of the **Dirichlet energy**

   ```
   E[u] = ½ ∫ |∇u|² dV
   ```

   with `dE/dt = −∫(α∇²u)² dV ≤ 0`. The energy strictly decreases — it is **dissipated as heat** —
   until the harmonic minimum is reached. So *solving the heat equation = minimizing a quadratic
   energy by relaxation*.
3. **Boundary → interior propagation.** The boundary values are the *data*; the harmonic extension
   is the *computation*. In graph terms, fix some node values ("labels"), run the heat flow, and
   every unlabeled node converges to the weighted average of the labels — the same mechanism as
   label propagation and graph-based semi-supervised learning.

**Why it is "an important type of computation" (not just physics):** the relaxation *is* the
solver. The same `∇²` operator is the backbone of spectral graph theory (`L = D − A`, the graph
Laplacian), random-walk/PageRank diffusion, image/mesh smoothing, simulated annealing's
thermalization, resistive/analog network solvers, and — via Macroscopic Fluctuation Theory — the
most-likely-path variational principle of dissipative dynamics (see §3).

### 1.3 `∇²` in Geometric Algebra (the "square of the geometric derivative")

In GA the **geometric derivative** `∇` is a single **invertible** operator (`∇F = J`); its square
is the scalar Laplacian:

```
∇² = ∇∇   (the Laplacian)
```

The point already in our `GA_INSTRUCTIONS.md`: `div` and `curl` are *separately* non-invertible,
but `∇` itself is invertible — "residual = ∇F, recovery = the directed integral." So `∇²` is *not*
a new primitive beyond the geometric derivative; it is `∇` applied twice. **DIRECT (Hestenes /
GA textbook); as a Tau instruction, `TGRAD` is Tier-3 SPECULATION in `GA_INSTRUCTIONS.md`.**

---

## 2. The map to our lattice (residual / energy / Laplacian)

### 2.1 Is `r = O − E` relaxing to 0 a diffusion?

**ANALOGY — the shape is diffusion; the object is a statistical null, not a dynamical flow.**

- `r(a,b) = O(a,b) − E(a,b)` is a signed field over edges; its equilibrium is `O = E`
  (independence, the "noise" attractor in the canonical truth). The direction `O → E` is a
  *relaxation toward a null*, exactly the direction a diffusion points. The telescope
  `Σ_a Σ_b (O−E) = 0` (`sum_residual_eq_zero`, `Residual.lean`) is the conserved-charge condition
  the heat equation also satisfies (mass/energy conservation: `∫u` is constant under the heat
  flow with no-flux boundaries). **DIRECT for the telescope; ANALOGY for "diffusion".**
- **What is missing for it to be a literal diffusion:** a *time axis* and a *Laplacian operator*.
  The rebuild has a *directional* axis `a → b` (word order / precedence), not a parametrized time
  over which `O` flows; and there is no implemented `∇²` stepping `O` toward `E`. The "relaxation"
  is a *target direction* (measured vs. null), not a dynamical update. This is the *same* gap
  `docs/compute/einstein_calculus.md` flags for "delta = time derivative": the time axis is the
  missing ingredient.
- **Candidate time axes that would make it literal (SPECULATION):** the ring-band / RG shift
  (`d >> 1`, the barrel-shift "scale" axis), or the consolidation pass count. Either would supply
  the `t` in `∂r/∂t` — but neither is currently wired as one.

### 2.2 Is the "energy" we measured the dissipation (the heat)?

**ANALOGY as an object; the *role* is exact.**

- `χ² = Σ(O−E)²/E` is a **divergence**, not a physical energy. The statistical-mechanics survey is
  explicit: *"the flux `(O−E)²/E = χ²` is a relative surprise (distance from independence)"* and
  *"flux = EBM energy function — ANALOGY (divergence vs energy)."* So "χ² is heat" is **ANALOGY**.
- But the **role** is exactly the heat-flow's dissipation identity. Both are: (i) nonnegative,
  (ii) zero *at* the equilibrium (null), (iii) monotonically decreasing *toward* it under
  relaxation. The heat equation's `dE/dt = −∫(α∇²u)² ≤ 0` and our "`χ²` shrinks as `O → E`" are
  the *same accounting statement*: energy = dissipation, the only budget is the amount burned off
  on the way down. The one structural difference: χ² carries the `1/E` weighting (it is the
  *relative* surprise), whereas Dirichlet energy is unweighted `|∇u|²`. The `1/E` is a *gauge
  choice*, and the statistical-mechanics survey's PROVEN point is precisely that "least squares =
  least action" is the *quadratic large-deviation rate function* — the diffusion's rate function —
  not free energy.

- **Where the "heat" actually lives in our *hardware* (the DIRECT side):** `ENERGY_LAWS.md` Law 1
  says the *receiver* — the cost of resolving which state you're in — is the invariant energy
  floor, "the cost of extracting information," and it is the wall once the wire is cheap. This is
  *measurement dissipation*, the same second-law heat that the statistical-mechanics survey
  formalizes as "dissipation (heat) = entropy production `Σ ≥ 0`" (the C2 term, 2608.12791). So the
  plain-English claim **"energy = dissipation" is DIRECT in our measured system** (the receiver
  floor), and the heat equation is the *cleanest mathematical model of exactly that*: a monotone
  information-eliminating flow.

### 2.3 Is `∇²` the "relaxation step"?

**In the heat equation, yes — DIRECT. In our lattice, not yet — SPECULATION.**

- The discrete heat step `u ← u + α∇²u` shows `∇²` *is* the relaxation generator (each step adds
  a little of the local curvature back toward the mean). On a graph, `∇² → L = D − A`, and the
  step is `u ← (I − εL)u` — the **graph-diffusion / random-walk smoothing** step. **DIRECT.**
- What we have of a `∇²` today: (a) the **O(degree) neighbor walk** (`lattice-lookup`) — the raw
  "average over neighbors" skeleton a Laplacian needs; (b) the **Eisenstein lattice**, which makes
  the Laplacian a clean **6-point stencil** (sum over the Z₆ unit neighbors minus 6× center, §4);
  (c) `TGRAD` (`∇F = J`) as a **Tier-3 SPECULATION** in `GA_INSTRUCTIONS.md`. We do **not** have a
  `∇²` instruction, and claiming the lattice "runs" the heat equation is **SPECULATION**.
- The honest statement: **`∇²` is the relaxation step *in the theory we are borrowing*; the
  relaxation step *we actually run* is the residual/flux computation and the consolidate/down
  operations**, which *measure* the distance to the null rather than *stepping a field* toward it.

### 2.4 The two attractors = the two endpoints of the heat flow (the sharp result)

Canonical truth (AGENTS.md): *"attractor is two opposite zeros: feedback equilibrium `O→E` (noise)
vs topic center `div=0` (max structure)."* The heat equation gives a single operator with both as
degenerate cases:

| Heat-flow endpoint | Operator that vanishes | Lattice attractor |
|---|---|---|
| **Uniform equilibrium** (`u = const`, `∇u = 0`) — all structure dissipated | `∇u = 0` | `O → E` (noise: every edge at its independence null, nothing left) |
| **Harmonic equilibrium** (`∇²u = 0` but `∇u ≠ 0`) — structure preserved, interior smoothed | `∇²u = 0`, i.e. `div(∇u) = 0` | `div = 0` (topic center: max structure, the flow's divergence vanishes) |

**Calibration: ANALOGY (precise).** Our `O → E` is the *uniform* fixed point — running the
diffusion all the way to thermal death. Our `div = 0` is the *harmonic* fixed point — the flow
stops where its divergence vanishes, keeping the boundary structure. This is a genuinely useful
unpacking of "two opposite zeros," but it is a *mapping*, not an identity: our "div" is the
directed flux field's divergence, not the Laplacian's `∇²u = 0` in a continuous field.

---

## 3. "Least action = constant action" vs heat flow as variational relaxation

The task asks: *is the heat flow the steady-state / variational relaxation?* Answer: **yes, it is a
variational relaxation — but it is the gradient-flow kind, not the Hamilton "least action" kind,
and our "constant action" finding is the equilibrium it relaxes to, not the flow itself.**

1. **The heat flow is a minimization.** `u_t = −grad E[u]` (steepest descent of Dirichlet energy).
   It *minimizes* `E[u]` monotonically; the minimizer is the harmonic field. **DIRECT.**
2. **"Least action" in our corpus is a level set, not a minimization.** AGENTS.md canonical truth:
   *coherent speech keeps `∫L` constant (a level set), it does NOT minimize it* — "least squares =
   least action" is the **large-deviation rate function**, not free-energy minimization and not
   Euler–Lagrange (statistical-mechanics survey: PROVEN as rate function; "least action = minimize
   free energy" is **SPECULATION**).
3. **The clean reconciliation (no contradiction):** the heat flow's *fixed point* (`∇²u = 0`, the
   harmonic equilibrium) **is** the steady-state / the level set. "Constant action" is a statement
   about *where the flow stops* (the equilibrium surface); the heat equation is a statement about
   *how it gets there* (the dissipative relaxation). They are complementary, not competing.
4. **The Onsager / fluctuation-dissipation bridge (DIRECT, via the survey's MFT citation).**
   Macroscopic Fluctuation Theory (2608.12119, in the statistical-mechanics survey) makes "current
   statistics = minimize the dynamical action" a theorem: near equilibrium, the *most likely
   relaxation path* minimizes a quadratic action functional — the same shape as the Dirichlet
   energy. So **"heat flow = variational relaxation" is not an analogy; it is the large-deviation
   structure of dissipative dynamics.** Our "least squares = least action" (the quadratic rate
   function) *is* this object, one level up.
5. **Where the irreversibility lives (the wedge).** The diffusion operator `∇²` is *symmetric* — it
   smooths but has no arrow. The arrow of time is the **skew** part. Planck (physics_texts.md):
   *reversible ⟺ states "equivalent", irreversible ⟺ states "discriminate"* — the wedge is the
   *sign* of irreversibility, direction not amount; first law (symmetric, conservation) vs second
   law (skew, irreversibility). So in our terms: **`χ²` (symmetric sum) is the *amount* of heat
   dissipated; the wedge `O_ab − O_ba` (antisymmetric) is the *sign/direction* of that
   dissipation.** "Energy = dissipation" needs both — the second-law side is where the wedge and
   the fluctuation theorems (`p(q)/p(−q) = e^{Δβ·q}`, statistical-mechanics survey) live.

---

## 4. The "relaxation" instruction shape (concrete, Tau)

If the heat flow is a type of computation, what is its *instruction*? On the Eisenstein lattice it
has a very clean form — a **6-point stencil**, because each lattice point has exactly 6 unit
neighbors (the Z₆ group, `Rotation.lean`).

### 4.1 The discrete Laplacian on the Eisenstein lattice

```
∇²f(x) = Σ_{k=0}^{5} f(x + ωᵏ) − 6·f(x)        ωᵏ ∈ Z₆ = {1, ω, ω², ω³, ω⁴, ω⁵}
```

`(sum of the six unit neighbors) − 6·(center)` — the hex-disk Laplacian. **DIRECT (the standard
6-point stencil of the hexagonal lattice; the Z₆ units are `Rotation.lean` `units_card = 6`).**

### 4.2 One relaxation step

```
RELAX:  f(x) ← f(x) + (α/6)·( Σ_{k=0}^{5} f(x + ωᵏ) − 6·f(x) )
             = (1 − α)·f(x) + (α/6)·Σ_{k=0}^{5} f(x + ωᵏ)
```

i.e. **"move each value α of the way toward its local 6-neighbor mean."** `α ∈ [0,1]` is the
damping; `α=1` is a full Jacobi step (replace by the neighbor mean); `α→0` is no-op. Iterate until
the residual is flat: `|∇²f| < ε` (equivalently `div = 0`, the topic-center attractor).

### 4.3 The candidate instruction, piece by piece

| Piece | What it is | Calibration |
|---|---|---|
| Gather the 6 unit neighbors | the Z₆ rotor directions | **DIRECT** — `TROT` (`Rotation.lean`, Z₆ units) |
| Accumulate their mean | a 6-input average | **DIRECT** — ordinary accumulation (scan-able, see `einstein_calculus.md`) |
| Blend center with mean by `α` | the damped update `(1−α)f + (α/6)Σnb` | **DIRECT** — the standard relaxation update |
| The whole thing as a native `TRELAX` instruction | a hex-stencil relaxation primitive | **OURS / SPECULATION** — no such datapath measured; cost is the same stencil/neighbor-gather + receiver tax every ternary gate pays |

**What it buys (if it existed):** a native *analog-style* solver — "load field, relax, read the
harmonic extension" — for the class of computations that are *already* Laplacian-shaped: label
propagation, spectral clustering, smoothing, and (SPECULATION) running `O → E` as a *dynamical*
step instead of a *measured* distance. This is the "heat equation as a computation" made explicit.

**The honest cost (same as every Tau datapath idea):** a stencil op is an **area-for-latency**
trade — a 6-neighbor gather plus a blend, per node per step. `ENERGY_LAWS.md` is explicit that
parallelism can *duplicate* energy, not divide it, and every ternary gate pays the 2-threshold
receiver tax (`control.md`). Nothing here is free; it is only cheap *if* the relaxation, not the
measurement, is the bottleneck in a real workload — and that is unmeasured. **SPECULATION.**

---

## 5. Calibrated verdict

| Claim | Verdict |
|---|---|
| Heat equation = relaxation/equilibration primitive (neighbor-averaging) | **DIRECT** (classical) |
| "Solving" it = harmonic extension / min-Dirichlet-energy interpolation of boundary data | **DIRECT** (classical) |
| Heat flow = gradient flow of Dirichlet energy; `dE/dt = −∫(α∇²u)² ≤ 0`; energy = dissipation | **DIRECT** (classical identity) |
| `∇²` = square of the geometric derivative (GA) | **DIRECT** (Hestenes) |
| `∇²` is the relaxation step (`u ← u + α∇²u`) | **DIRECT** in the heat equation |
| Our lattice *runs* a `∇²` relaxation | **SPECULATION** (no `∇²`; `TGRAD` is Tier-3 spec) |
| `r = O − E` relaxing to 0 **is** a diffusion | **ANALOGY** (shape matches; no time axis, no operator) |
| `Σ(O−E) = 0` telescope = heat-flow conservation | **DIRECT** (telescope) / **ANALOGY** (as the conservation law) |
| `χ² = Σ(O−E)²/E` is the heat / dissipation | **ANALOGY** as object (it's a divergence); role exact |
| "energy = dissipation" in our hardware (receiver floor) | **DIRECT** (measured; `ENERGY_LAWS.md` Law 1) |
| `O → E` = uniform fixed point; `div = 0` = harmonic fixed point (two endpoints of heat flow) | **ANALOGY** (precise mapping, not identity) |
| Heat flow = variational relaxation | **DIRECT** (gradient flow) |
| …but "least action = constant action" is the *equilibrium level set*, not the flow | **DIRECT** (our finding) / consistent |
| "least action = least squares" as large-deviation rate function (the diffusion's rate function) | **PROVEN** (statistical-mechanics survey; MFT 2608.12119, SOC 2608.13500) |
| Wedge = sign (not amount) of the irreversibility = where the dissipation's *arrow* lives | **DIRECT** (Planck, physics_texts.md) |
| `TRELAX` — a native hex-stencil relaxation instruction | **OURS / SPECULATION** (unmeasured) |

**One-sentence bottom line:** the heat equation is the canonical **relaxation-to-equilibrium**
primitive — it *computes* the harmonic extension by burning off gradient energy, with
"energy = dissipation" literally true — and it maps onto our residual/energy story as a *sharp
analogy*: `O → E` is the uniform fixed point, `div = 0` is the harmonic fixed point, `χ²` plays the
dissipated heat, and the missing ingredients (a time axis + a `∇²`) are exactly what a native
`TRELAX` relaxation instruction would supply — but that instruction is SPECULATION until it is
measured the way TMUL and the receiver floor already were.

---

## TODO / not covered / caveats

- **No measured `∇²` / `TRELAX` datapath.** Every silicon-sounding claim above ("a native
  relaxation primitive is cheap/useful") is SPECULATION. To move it to OURS it needs the
  `eisen_opcode.md` treatment: synthesize the 6-neighbor stencil + blend in yosys, measure area /
  energy in ngspice, and report whether a relaxation step beats the *measurement* (flux) it would
  replace — remembering `ENERGY_LAWS.md`'s warning that parallelism can duplicate energy.
- **No time axis.** The single largest gap: `∂r/∂t` has no `t` in the rebuild. Whether the RG /
  ring-band shift (`d >> 1`) or the consolidation pass count is the right "time" is untested; until
  one is wired, "the residual is a diffusion" stays ANALOGY, not DIRECT.
- **`χ²` vs Dirichlet energy is not cleaned up.** `χ²` carries `1/E` weighting; Dirichlet energy is
  unweighted `|∇u|²`. Whether the `1/E` is a gauge (making χ² the *right* relative form of the
  rate function) or a category difference is open — it is the same "divergence vs energy" question
  the statistical-mechanics survey flagged as ANALOGY.
- **Fluctuation-theorem check not attempted.** The survey's highest-value experiment — does
  `P(wedge>0)/P(wedge<0) = e^{σ}` hold per edge — is the *heat-equation-adjacent* test of whether
  the dissipation is a bona fide entropy production. Not run; it is the thing that would upgrade
  "wedge = sign of irreversibility" from Planck's statement to a measured fluctuation theorem.
- **Landauer is not the floor here.** The receiver floor is ~28,000× *above* `kT ln 2`
  (`meta_assumptions.md`), so "energy = dissipation" in our system is *measurement* heat, not
  erasure heat. The heat-equation analogy does not change that; do not read this doc as a
  Landauer/adiabatic argument.
- **Not covered:** simulated annealing / Monte-Carlo thermalization as a *compute* primitive
  (the stochastic cousin of the heat flow), spectral-graph-theory specifics of `L = D − A` on the
  actual residual graph, and any *reversibility* audit of a `TRELAX` step (is a damped
  neighbor-average information-erasing? per `synth_design.md`'s per-gate Landauer audit question).

## Sources

**Project-internal (DIRECT / OURS / PROVED):**
- `docs/ENERGY_LAWS.md` — the three laws; receiver = invariant floor = "cost of extracting information."
- `docs/TERNARY_COMPUTE_VERDICT.md` — the measured energy (transport 4.6×, compute trade, 1.26× floor).
- `docs/GA_INSTRUCTIONS.md` — `∇F = J` (TGRAD, Tier-3), the dot/wedge/rotor split, Z₆ (`TROT`).
- `docs/compute/einstein_calculus.md` — the "delta = time derivative needs a time axis" gap; scan cost model.
- `docs/compute/ground_up/meta_math.md`, `meta_assumptions.md` — Landauer `kT ln N` radix-independence; receiver floor ≫ Landauer.
- AGENTS.md canonical truth — the two zeros (`O→E` noise vs `div=0` structure); "least action = constant action" (level set).
- `proofs/lean-src/hexagon/Hexagon/Residual.lean` (`sum_residual_eq_zero`, `wedge_antisymm`), `Registers.lean`, `Rotation.lean` (Z₆ units), `Conventions.lean` (Eisenstein, norm).
- `~/opencode/parser/english/docs/surveys/statistical-mechanics.md` — wedge = antisymmetry = time irreversibility; dissipation = entropy production `Σ ≥ 0` (2608.12791); "least squares = least action" as large-deviation rate function (MFT 2608.12119, SOC 2608.13500); "flux is a divergence, not an energy."
- `~/opencode/parser/english/docs/source_surveys/physics_texts.md` — Planck: wedge = *sign* of irreversibility (direction, not amount); first law = symmetric / second law = skew.

**External (DIRECT, classical — textbook, no invention):**
- The heat equation as gradient flow of Dirichlet energy and the identity `dE/dt = −∫(α∇²u)² ≤ 0`; the harmonic steady state and mean-value property. (L. C. Evans, *Partial Differential Equations*, Ch. 2/7.)
- The graph Laplacian `L = D − A` and graph diffusion `du/dt = −Lu`. (F. R. K. Chung, *Spectral Graph Theory*, 1997.)
- The GA Laplacian `∇² = ∇∇` as the square of the geometric/vector derivative. (D. Hestenes & G. Sobczyk, *Clifford Algebra to Geometric Calculus*, 1984; C. Doran & A. Lasenby, *Geometric Algebra for Physicists*, 2003.)
- The 6-point Laplacian stencil on the hexagonal/Eisenstein lattice — the standard discrete Laplacian on a 6-neighbor grid.
