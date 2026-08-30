# Hexagon — the Eisenstein-lattice formal proofs

Lean 4 + mathlib formal verification for the **balanced-ternary processor on the
Eisenstein integers ℤ[ω]** (ω = e^(iπ/3), the 60° hex lattice — the unique
well-rounded planar lattice, A₂). This is the proof core of the Tau Architecture.

**Build status:** `lake build` → `Build completed successfully (8746 jobs)` — **zero
`sorry`**, all 40 files proved, mathlib pinned at `v4.33.1`.

## What is proved here

| theme | files | headline theorems |
|---|---|---|
| Eisenstein ring | `Conventions`, `EuclideanDomain`, `Rotation`, `Gauge`, `ConventionBridge` | ℤ[ω] is a Euclidean domain; norm N(a+bω)=a²+ab+b² is multiplicative; the units are exactly ±1,±ω,±ω² ≅ Z₆; 60° ≅ 120° convention |
| hex lattice | `SevenHex`, `GraphDistance`, `Packing`, `Pod`, `HexIsotropy`, `HexDisk`, `OffsetGrid`, `Bijection`, `FractalRam` | 7 hex cells; cube-coordinate max-norm = graph distance; the pod (norm≤1) is 7-of-9 axial states; fractal 7ⁿ addressing |
| ternary | `TernaryCell`, `PolarEncoding`, `PolarGate`, `TernaryCrt`, `FewerTrits`, `TritPacking` | 2-bit/trit encoding (01/00/10, 11=NEVER never produced); null is free; `2ⁿ < 3ⁿ`; 4 trits fit 7 bits, 5 trits fit 8 |
| radix economy | `RadixEconomy`, `RadixMin`, `ThresholdLowerBound`, `EnergyModel`, `EnergyVerdict`, `ValuationEnergy`, `ZipfEnergy` | `b/ln b` minimized at e (transport); `(b−1)/ln b` minimized at 2 (compute); the **2-threshold tax** — ternary is `2·ln2/ln3 ≈ 1.26×` worse per bit on compute |
| geometric algebra | `Conjugate`, `DotWedge`, `SymDot`, `OmegaEmbedding` | `conj(a,b)=(a+b,−b)`; raw `dot` is NOT symmetric (`dot_swap`); the symmetric correlation is the norm polarization `symdot = N(z+w)−N(z)−N(w)` |
| field calculus | `Residual`, `Registers`, `ChiSquareGauge`, `Haar` | Σ(O−E)=0 conservation; wedge = skew; δ gauge-invariance; Z₆ counting measure is invariant |

Every file carries a provenance header and a calibration tag (**DIRECT** / **ANALOGY** /
**OURS** / **SPECULATION**). The full claim→file→status ledger is `INDEX.md` in the parent
project.

## Build

```bash
lake update        # resolve mathlib (large first clone)
lake exe cache get # optional: precompiled mathlib oleans (~1 GB)
lake build         # "Build completed successfully (8746 jobs)"
```

## Calibration discipline

The honesty rule is *borrow, don't trust; verify like our own intuition*. A theorem is
never marked "proved" without `lake build` passing on it, and a claim is calibrated
**DIRECT** (proved/measured), **ANALOGY**, **OURS** (our framing), or **SPECULATION** at
the moment of adoption — never after. The most important *negative* result is
`ThresholdLowerBound.lean`: ternary **does not** beat binary per bit on compute; it wins
on **names** (`3ⁿ` vs `2ⁿ`) and **transport**, not arithmetic.
