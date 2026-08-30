# Citations & provenance

## Honest provenance, up front

The **primary design** — balanced ternary over the Eisenstein hex lattice ℤ[ω], with
ternary used for transport and addressing and binary for compute — was **conceived before
the formal verification and cross-checking step**. The papers below were looked up during
the research process to *verify, cross-check, and calibrate* that idea — and, in many
cases, to *falsify* flattering versions of it. They **may or may not have influenced the
design**; where they did, it was usually to tell us where the idea *loses*, not where it
wins.

This was a **hobby research project** by a non-expert and an AI agent working together.
The proofs and RTL are our own verification of our own idea; the papers are the external
reality check. "Borrow, don't trust; verify like our own intuition."

## Directly relevant — ternary logic & circuits

| arXiv | title |
|---|---|
| 1309.2685 | Complete Valuations on Finite Distributive Lattices |
| 1502.05748 | A Multiple-Valued Logic Approach to the Design and Verification of Hardware Circuits |
| 1807.01863 | Quantum error-correcting code for ternary logic |
| 1807.06419 | On Ternary Coding and Three-Valued Logic |
| 1903.06044 | Lattice Valuations: a Generalisation of Measure and Integral |
| 2105.09169 | Generalization of Proof Obligations in PDR |
| 2111.01558 | Long-Time Memory and Ternary Logic Gate (multistable cavity magnonic) |
| 2204.01000 | Ternary Logic Design in Topological Quantum Computing |
| 2211.04542 | Multiple-Valued Logic Circuit Design and Data Transmission |
| 2211.12176 | Implementation and Applications of a Ternary Threshold Logic Gate |
| 2305.04115 | Symmetric Ternary Logic and Its Systematic Logic Composition Methodology |
| 2309.01615 | A balanced Memristor-CMOS ternary logic family and its application |
| 2401.03521 | Reversible ternary logic with Laguerre-Gaussian modes |
| 9907.099 | Polarization state of a biphoton: quantum ternary logic |

## Directly relevant — native ternary devices & transistors

Mostly surveyed to test "does a native 3-state device beat the 2-bit/trit cell?" —
the honest answer kept coming back *no*. See `docs/graphs/ternary-transistors/_SYNTHESIS.md`.

| arXiv | title |
|---|---|
| 1201.4071 | All-optical polariton transistor |
| 2308.00439 | Electrically-programmable frequency comb for quantum photonic circuits |
| 2404.03733 | Leveraging both faces of polar semiconductor wafers |
| 2411.16698 | Universal on-chip polarization handling with deep photonic networks |
| 2503.00347 | Electrically Reconfigurable Intelligent Optoelectronics in 2-D van der Waals Materials |
| 2504.02497 | An all-electrical scheme for valley polarization in graphene |
| 2506.08728 | Frequency as a Clock: graphene transistor dynamics |
| 2507.20235 | Emission enhanced exciton-polariton condensates with optical feedback |
| 2511.01699 | A Compact Model for Polar Multiple-Channel FETs (III-V nitride) |
| 2511.07830 | A Dual-Memory Ferroelectric Transistor (synaptic metaplasticity) |
| 2511.10964 | Tekum: Balanced Ternary Tapered Precision Real Arithmetic |

Plus the polar/trinary memristor audit — `docs/riscv_survey/polar_memristor.md`.

## Directly relevant — Eisenstein integers & the hex lattice

The mathematical foundation: the 60° lattice, its 6-fold symmetry, its density.

| arXiv | title |
|---|---|
| 0906.1249 | On the honeycomb conjecture and the Kepler problem |
| 0911.4106 | Revisiting the hexagonal lattice: on optimal lattice circle packing |
| 1007.2667 | On well-rounded sublattices of the hexagonal lattice |
| 1404.1312 | Lattices over Eisenstein Integers for Compute-and-Forward |
| 1410.5139 | Directional Scaling Symmetry: Square Triangular Lattices, Gaussian Eisenstein |
| 1902.03483 | An Euler phi function for the Eisenstein integers |
| 1903.06856 | An Extremal Property of the Hexagonal Lattice |
| 2208.06617 | Perfect Eisenstein integers |
| 2403.10530 | Hexagonal lattice based equal circle packing |
| 2403.14375 | Eisenstein integers and equilateral ideal triangles |
| 2410.02418 | Optimal Representations of Gaussian and Eisenstein Integers |
| 2412.18328 | On Codes over Eisenstein Integers |
| 2511.03353 | The hexagonal lattice is universally locally optimal |
| 2604.10137 | Finite-Blocklength Analysis of Alamouti Codes over Eisenstein Integers |
| 2605.16053 | Eisenstein circle packings and the Eisenstein Schmidt arrangement |

## Current-mode / multivalued-logic precedent (the polar adder)

The polar current-mode adder was independently re-derived here, but it has long precedent —
see `docs/compute/polar_adder/current_mode_literature.md`.

| source | title |
|---|---|
| K. Wayne Current, IEEE JSSC 1994 | current-mode multiple-valued logic (the textbook CM-MVL adder) |
| S. L. Hurst, IEEE TC 1984 | multiple-valued logic design |
| arXiv:2005.02678, 2101.01516, 2206.03252 | CNTFET ternary adder comparisons (ternary/binary ratio always > 1.585) |

## The RISC-V target

The SoC runs on PicoRV32 and targets NEORV32's CFU port. The RISC-V specification PDFs
(unprivileged, privileged, profiles, trace, debug) were consulted and are listed under the
RISC-V Foundation's license, not arXiv.

## Broader math corpus (explored, mostly tangential)

A large number of additional arXiv papers on the **gamma function, Kronecker limit
formula, Epstein zeta function, Dedekind eta function, Riemann/Hurwitz zeta, Dirichlet
L-functions, measure theory, and information geometry** were downloaded and read during
the broader research process. They informed the *surrounding mathematics* (the gauge
theory, the valuation/energy model, the χ² ring) but are **not** central to the ternary
design. They are listed by arXiv ID in the source tree under
`exclude/docs_papers/` (not vendored in this release), and the ones that actually shaped a
result are cited inline in `docs/` where used.

## What's our own

- The balanced-ternary-over-Eisenstein **design** and its honest verdict (compute stays
  binary; ternary wins transport + addressing).
- The **Lean formalization** (`proofs/`, 46 modules, zero `sorry`).
- The **RTL** (`rtl/`), the **ngspice measurements** (`circuit/`), and the **surveys**
  (`docs/graphs/`, `docs/riscv_survey/`, `docs/compute/`).
