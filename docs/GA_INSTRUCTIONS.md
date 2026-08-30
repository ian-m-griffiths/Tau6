# GA Instructions on the Eisenstein Engine

**2026-08-29.** Candidate geometric-algebra instructions for the ternary processor, surveyed
from the rebuild (`/home/ian/opencode/parser/english/`) GA corpus (spinors, rotors, wedge,
Clifford, XOR-kernel). Calibration: DIRECT/ANALOGY/OURS/SPECULATION.

## The alignment (why this fits)

The rebuild's GA-native rotor generator: **"walk = R[next] = R[current]·R[step] — one multiply
per step; all geometric operations collapse to the geometric product."** And the geometric
product of two complex numbers **is** the Eisenstein multiply. So:

| GA object | Eisenstein primitive | status |
|---|---|---|
| geometric product `ab = a·b + a∧b` | `TMUL` (Eisenstein multiply) | ✅ in RTL |
| scalar part `a·b` (dot, cos θ) | `TNORM` (the norm / real part) | ✅ in RTL |
| bivector/rotor `Iθ` (rotation) | `TROT` (Z₆, 60°) | ✅ in RTL |

The engine already *has* the geometric product. The gap is the **scalar/bivector split** and
the **discrete trig**.

## Candidate instructions (tiered)

### Tier 1 — the decomposition (cheap, core, Lean-provable)

1. **`TCONJ`** — conjugate `a+bω ↦ (a+b)−bω` (the coordinate mirror; `ω̄ = 1−ω`). Needed for the
   dot/wedge projections. *Rebuild:* the `count↔prob` gauge / `δ` fold uses the conjugate implicitly.
2. **`TWEDGE`** — the **skew part** `a∧b = Im(a·b̄)` = the signed area / curl / circulation. This is
   the rebuild's *core object* (`wedge = O_ab − O_ba`, the arrow-of-time / irreversibility). *Note:
   the GA survey retired "wedge = bivector area" — the wedge is the SKEW part, uniquely determined by
   its curl (Hestenes-Sobczyk).*
3. **`TDOT`** — the **symmetric part** `a·b = Re(a·b̄)` = cos θ = correlation / topic alignment.
   *Rebuild:* the "cosine" axis.

### Tier 2 — the discrete trig / scale (the "bit tricks")

4. **`TXOR`** — the **XOR kernel** `cos θ ≡ (−1)^popcount(i & j)`: parity as the bivector sign. The
   graph Fourier transform of the hypercube; the barrel shifter replaces transcendental functions.
   *Rebuild:* the rotor kernel `G[d] = cos θ`; `d >> 1` = RG flow.
5. **`TBARREL`** — the **barrel shift / ring-band shift** `d >> 1` (the renormalization-group /
   scale-change primitive). *Rebuild:* ring-band traversal, the multifractal cascade.

### Tier 3 — the higher-grade (speculative, higher cost)

6. **`TSPINOR`** — the **spinor** `ψ = ρ^{1/2}e^{Iβ/2}R` ("weighted rotor = scale × rotation
   instruction", Lasenby). The grade-0 rotor fix `ψ=(α+βI)U` (Hestenes-Sobczyk Eq. 8.11) — replaces
   the rebuild's *inert* grade-0 rotor `exp(r_bwd−r_fwd)` with a genuine even-grade rotor.
7. **`THODGE`** — the **Hodge dual** `I·v` (the bivector acts as the imaginary unit, a 90° rotation
   *outside* Z₆) = the dimensional transition vector↔bivector.
8. **`TGRAD`** — the **geometric derivative** `∇F = J` (invertible, one equation; div and curl are
   separately non-invertible). *Rebuild:* formalizes "residual = ∇F, recovery = the directed integral".

## What's already proved in our Lean (the foundation)

- `Rotation.lean` — the Z₆ units / 60° rotor (`TROT`'s algebra).
- `Conventions.lean` — the Eisenstein multiply + norm (`TMUL`/`TNORM`'s algebra).
- `Residual.lean` — `wedge_antisymm`, `sum_residual_eq_zero` (the wedge as skew, the telescope).
- `CrtHex.lean` — `Z₆ ≅ Z₂×Z₃` (the sign × 3-cycle = the spinor's grade structure).
- `OmegaEmbedding.lean` — `ω = e^{iπ/3}` (the geometric product is the complex product).

## The one-liner

**The geometric product is already the multiply; add the conjugate + the dot/wedge split + the
XOR kernel, and the engine speaks the rebuild's GA natively.** Tier 1 (conj/dot/wedge) is cheap and
Lean-provable now; Tier 2 (XOR/barrel) is the discrete-trig bridge to the rebuild's kernel; Tier 3
(spinor/Hodge/grad) is the long pole.
