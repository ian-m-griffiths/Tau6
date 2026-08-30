# Fundamental measure theory for lattice fluids with hard core interactions
Lafuente & Cuesta, arXiv:cond-mat/0205648v1 (2002). Rosenfeld's fundamental-measure (FM) density-functional theory, extended to **lattice** fluids: exact 1D hard-rod mixtures (additive & nonadditive), a 0D-cavities construction generating the d-dimensional functional, and applications to hard square/cube lattice gases.

## 1. Node inventory (id | type | name | one-line | location)

| id | type | name | one-line | location |
|----|------|------|---------|----------|
| N1 | CONCEPT | Rosenfeld FM theory | build the density functional on *geometrical* grounds; the ingredients classical approaches need as input become output | §1 |
| N2 | METHOD | Mayer-function decomposition | split the Mayer function into a sum of convolutions of one-particle measures, then define weighted densities from them | §1, eq before §2 |
| N3 | DEFINITION | weighted densities `n(k)(s)` | `n(k)(s) = Σα ωα(k) ∗ ρα(s)` — density profile convolved with species kernels | §2.1 eq (2.22) |
| N4 | RESULT | exact 1D additive functional | `βF = βF_id + Σ_s [Φ0(n(1)) − Φ0(n(0))]` | §2.1 eq (2.26) |
| N5 | RESULT | exact 1D nonadditive functional | four weighted densities, `βF_ex = Σ Φ0(n1(1)) + Φ0(n0(1)) − Φ0(n1(0)) − Φ0(n0(0))`; first in the literature | §2.2 eq (2.30) |
| N6 | METHOD | zero-dimensional cavities method | extend the exact 0D functional to higher d, subtract the spurious terms so 0D cavities come out exact | §3 |
| N7 | DEFINITION | 0D excess free energy | `Φ0(η) = η + (1−η)ln(1−η)` for a cavity of mean occupancy η | §2.1 |
| N8 | RESULT | d-dim lattice FM functionals | (3.2)/(3.3): product of **difference operators** `Dk = Π Dki` applied to `Φ0` of weighted densities | §3 eq (3.2)/(3.3) |
| N9 | CLAIM | additive vs nonadditive is a parity effect | same-parity diameters ⇒ rank-one ⇒ additive; mixed parity ⇒ half-integer σ ⇒ nonadditive; **disappears in the continuum limit** | §2 |
| N10 | METHOD | nonadditive→additive mapping | double all diameters, restrict to even sites (infinite external field); nonadditive system = additive system in a field | §2.2 eq (2.27)–(2.29) |
| N11 | RESULT | applications | hard square lattice gas: 2nd-order fluid→columnar transition at ηc = 3−√5 ≈ 0.764; hard cube mixtures: rich smectic/columnar/solid phase diagrams | §4 |
| N12 | OPEN-QUESTION | lattice scaled-particle theory | lattice FM could guide a lattice analogue of scaled-particle theory (step (iii) of Rosenfeld's method) | §5 |
| N13 | METHOD | density as functional derivative | `ρα(s) = wα(s)/Ξ · ∂Ξ/∂wα(s)` — density profile from the grand partition function | §2 eq (2.6) |
| N14 | CLAIM | rank-one Boltzmann factor ⇔ solvability | the (α,s)-space operator `eαα′` has rank 1 in the additive case only | §2 |
| N15 | CONCEPT | cubic / translation symmetry | cavity relations and the `Tkj` operator factor per coordinate axis | §3.1–3.2 eq (3.19) |

## 2. Edge inventory (src→tgt | type | calibration | evidence)

| src→tgt | type | calibration | evidence |
|---------|------|-------------|----------|
| N2→N3 | derives-from | — | weighted densities are defined from the one-particle measures of the Mayer decomposition (§1, eq 2.22) |
| N13→N4 | derives-from | — | 1D functional obtained by solving (2.7)+(2.10) from the functional-derivative relation |
| N14→N4 | requires | — | additivity (rank-one) is what makes the exact solution possible (§2.1) |
| N7→N6 | requires | — | the 0D functional Φ0 is the seed object the cavities method extends |
| N6→N8 | derives-from | — | d-dim functionals are exactly the 0D functional with difference operators applied per axis (§3) |
| N15→N8 | supports | — | cubic symmetry lets the Tkj rule be applied axis-by-axis (§3.2) |
| N9→N10 | requires | — | the nonadditive case is *solved by* mapping to an additive system in a field |
| N10→N5 | derives-from | — | nonadditive functional = additive functional evaluated on the doubled/even-site profile |
| N4→N8 | analog-of | — | "the form of (2.26)/(2.30) suggests, by analogy with parallel hard cubes, the extension to higher dimensions" (§1, §3) |
| N8→N12 | supports | — | a lattice FM functional is a prerequisite for a lattice scaled-particle theory (§5) |
| N8→N11 | derives-from | — | the applications use the d-dim functionals |
| N8→N9 | supports | — | dimension-wise generalization keeps the additive/nonadditive split explicit |
| N2→N1 | instance-of | — | Mayer decomposition is the first step of Rosenfeld's original method (§1) |
| N6→N1 | instance-of | — | cavities method is the modern reformulation of FM theory (§1, §5) |

## 3. Counter-to / reversal edges

- **C1 — "A lattice FM theory is just the continuum one discretized" is FALSE.** §1: on a lattice there is *no* unique Mayer decomposition (several equally plausible decompositions of the Fourier transform — eqs in §1), and *no* scaled-particle theory exists. The naive discretization of Rosenfeld's method is infeasible; the lattice needs its own construction. (counter-to: continuum-assumption; the ambiguity is a **gauge freedom introduced by discreteness**.)
- **C2 — "The continuum limit captures all the physics" is FALSE.** §2: the additive/nonadditive distinction is a purely *integer-parity* effect (`σα = 2aα + ǫ`, ǫ ∈ {0,1}) that "disappears in the continuum limit" (§2). Discreteness creates genuinely new structure (half-integer σαα′ ⇒ nonadditive) with no continuum counterpart.
- **C3 — FM theory vs simulation on demixing.** §4.2: Dijkstra & Frenkel's simulations claim entropy-driven fluid–fluid demixing in the additive binary hard-cube mixture; the FM functional instead gives fluid–ordered-phase demixing. Claimed-vs-claimed disagreement, unresolved in-paper.

## 4. Map-to-current-system (lens) — MEASURE THEORY

| paper concept | our system | calibration | evidence |
|---------------|-----------|-------------|----------|
| occupancy density `ρα(s)` = **integer counts** on lattice sites (counting measure on Z^d) | our counting measure `E = f(a)f(b)/T`, raw integer counts; "counts, not probabilities" (STATE_NOTE) | **DIRECT** | both operate in the counting measure; normalization to η is done only at the boundary, same as our ratio display |
| **0D cavity** `Φ0(η)` = one scalar (mean occupancy) that generates the whole d-dim functional under difference operators | **one primitive** `r = O−E` and the register ladder `δ = r/E`, `z = √E·δ`, `s = E·δ²` (GAUGE_VARIANTS §1C) | **ANALOGY** | same shape: a single seed object read through operators produces the hierarchy; objects differ (free-energy functional vs residual register). "The 0D limit … seems to contain most of the information needed" (§5) ≈ our δ-invariant claim |
| **difference operator** `Dk` replaces the differential (discrete is primary, differential is the limit) | integer-only register: no division/sqrt/float; inverse-mult + shifts (LATTICE_MATH) | **ANALOGY** | same philosophical move (discrete object primary), different operator |
| **non-unique Mayer decomposition** — gauge freedom of the fundamental measures, fixed by the 0D-reduction constraint | gauge freedom: signature/register/convention gauges; the invariant δ fixes the gauge (GAUGE_VARIANTS §1) | **ANALOGY (supports Ian's thesis)** | discreteness ⇒ the decomposition is ambiguous ⇒ a constraint (0D exactness) selects the gauge. Direct *evidence* for "gauge becomes a natural and cheap INTEGER thing" (STATE_NOTE): counting creates gauge choices |
| **additive/nonadditive parity** (2a vs 2a+1 diameters) — integer structure invisible in the continuum | Z₆ units, mod-6 rotation, integer norm `N = a²+ab+b²` — structure that only exists in integer arithmetic | **ANALOGY** | both are integer-specific phenomena; different content (parity of diameters vs unit group), same moral: the counting measure is not an approximation, it *adds* structure |
| **translation invariance / cubic symmetry** of the lattice kernels | isotropy = Z₆: `norm_of_unit`, `norm_mul_unit` (Gauge.lean) | **ANALOGY** | paper's symmetry is hypercubic Z₂^d convolution kernels; ours is hexagonal Z₆ rotation; both are the invariance that makes the counting structure coherent |
| **one-particle measures** `ωα(k)` as convolution kernels | `E = f(a)f(b)/T` expected count; ring = Σ(O−E)²/E norm | **ANALOGY** | kernels are local *weighted-density windows*; ours is a product-of-marginals null — different objects |
| hard-core exclusion ⇒ at most one particle per cavity (0/1 occupancy) | ternary cell `11 = NEVER` state; band-gap cutoff | **SPECULATION** | the "one particle max" constraint resembles an exclusion/never edge, but no math connects them yet |
| grand potential from `Ξ = 1 + Tr w(I−ew)⁻¹` — operator form of the partition function | lattice-lookup / down operators as graph walks (O(degree) neighbor walk) | **SPECULATION** | paper's resolvent `(I−ew)⁻¹` is a path-sum; our walks are degree-limited — tempting but unproven |

## 5. One-liner

**Discreteness (the counting measure) is not an approximation: it creates new structure — integer-parity additivity classes and a gauge freedom in the fundamental measures — that must be fixed by a single 0D anchor; that is the same shape as our "one primitive `r = O−E`, every register a gauge variant of it" and direct supporting evidence for Ian's thesis that the counting measure is how the gauge becomes a cheap integer thing.**
