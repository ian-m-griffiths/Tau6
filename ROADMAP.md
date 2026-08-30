# ROADMAP — what to check / formalise / test / build next (2026-08-28)

Principle: **borrow, don't trust.** Every claim we adopt from the literature (or from our
own intuition) gets a VERIFY step — a Lean proof, a Rust test, a `yosys`/`iverilog` check,
or an `ngspice` run — before it's trusted. Calibrate DIRECT/ANALOGY/OURS/SPECULATION at the
moment of adoption, never after.

Six arcs. Each has parallelizable steps (marked ⟂). Lean steps each own ONE file; build with
targeted `lake build <Module>`.

---

## A. Measure-theoretic foundation (why "counts" is the primitive)

Confirmed by the measure-theory synthesis (12/18 DIRECT). The flag theorem to prove:

- ⟂ **A1. Z₆ Haar / measure-preservation on ℤ[ω]** — the counting measure is invariant under
  the Z₆ unit action (isotropy); finite-group Haar `µ(E)=|E|/6` on Z₆. → `Hexagon/Haar.lean`
- ⟂ **A2. χ² gauge-invariance** — `ring² = Σ(O−E)²/E` is invariant under the [count]→[prob]
  rescale `E ↦ E/T`. → `Hexagon/ChiSquareGauge.lean`
- ⟂ **A3. min+max=sum + energy-is-a-valuation** — our per-trit energy is a lattice valuation
  (monotone + modular); Lemma 212 (`min+max=sum`, the `tadd1` identity). → `Hexagon/ValuationEnergy.lean`
- **A4. Radon–Nikodym `δ = dμ_obs/dμ_null`** — the fold as a density on the finite pair space.
  → extend `Registers.lean`/`Residual.lean` (harder; needs mathlib `MeasureTheory`).
- **A5. dyadic-Lebesgue construction** (Banica Prop 6.19) — "Lebesgue = renormalized counting"
  as a Lean construction. Flagship, longer-term.

## B. Ternary / energy math (why ternary saves energy)

Confirmed: gate algebra, trit code, radix economy, Eisenstein energy. OURS: the free null.

- ⟂ **B1. Zipf-weighted energy theorem** — under a geometric/power-law trit distribution
  (0 dominates), expected energy ≪ the uniform 2/3. Ian's "small numbers outweigh big."
  → `Hexagon/ZipfEnergy.lean`
- ⟂ **B2. Radix economy** — `log₂3 ≈ 1.585` bits/trit; ternary is the densest integer radix.
  → `Hexagon/RadixEconomy.lean` (needs `Real.log`; may be fiddly)
- **B3. `√N ≤ wtHex ≤ N`** (Eisenstein codes paper Thm 11) — hex weight bound. → `Hexagon/WeightHex.lean`
- **B4. Signature.lean** — prove what distinguishes the four signatures (`i²=−1,+1,0,ω`):
  unit groups Z₄ / (hyperbolic) / {±1} / Z₆; which have zero divisors. → `Hexagon/Signature.lean`

## C. RTL verification (does the circuit compute right)

- **C1. PDR/MaxSAT formal verification of `cpu.v`** with `11`=don't-care (2105.09169 + 1502.05748).
  Needs `symbiyosys` (+ boolector, present). Verify the ternary adder/ALU against the Lean spec.
- **C2. `yosys` equivalence/property checks** on `tadd1` vs its 27-row truth table (the TB already
  proves it functionally; C1 makes it a proof).

## D. RTL extension (make the circuit real)

- ⟂ **D1. Ternary D-latch/FF** (2211.12176 App A.3) — the sequential cell our binary-FF RTL lacks.
- ⟂ **D2. 3-operand balanced-adder + base-3 function indexing** (Automated_synthesis paper).
- **D3. Ternary instruction encoding** — make the instruction words ternary, not binary-host.
- **D4. `tmul_trits` optimization** (dominates area) + write-masking + fractal-RAM (7ⁿ) in RTL.

## E. Circuit / energy validation (real watts, real transfer)

- **E1. `ngspice` netlist for the AC-polarity cell + 2-diode receiver** — measure `∫V·I` per
  push/pull/null transfer; validate "null ≈ free" and the energy-ratio claim. (Check ngspice.)
- **E2. `yosys` power pass** (PDP methodology from 2211.04542) — watts/instruction baseline.

## F. Documentation / publishing

- ⟂ **F1. The survey as a publishable doc** — merge `docs/synthesis/` into a single
  "isomorphic gauge variants of standard math" write-up (the thing experts read in a week).
- ⟂ **F2. The Rust→rebuild wiring patch** — apply `patches/` on the rebuild machine + add the
  `eisenstein.rs` drop-in.
- **F3. Stale AGENTS.md notes** — depth-2 tested, `deriving Fintype` broken, etc.

---

## Execution order (batches)

- **Batch 1 (parallel Lean, "verify the borrowed claims"):** A1, A2, A3, B1 — the four
  cleanest, highest-value proofs (launch now).
- **Batch 2 (parallel):** B2, B4, D1, D2, F1 — radix economy, signatures, ternary FF, 3-op adder,
  the publishable doc.
- **Batch 3 (harder / tooling):** A4, A5, B3, C1 — Radon–Nikodym, dyadic-Lebesgue, hex weight,
  PDR/MaxSAT (install symbiyosys first).
- **Batch 4 (circuit/energy):** E1, E2, D3, D4 — ngspice, Yosys power, ternary ISA encoding,
  tmul optimization.

Run batches in order; within a batch, everything is ⟂-parallel. As each settles, slot the next
queued item into the freed slot (BACKLOG.md is the queue).
