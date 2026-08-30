# Backlog — the work queue (append-only, oldest done first)

> **⚠️ CORRECTION BANNER (2026-08-29):** the "0.165 pJ adiabatic (4.5× win)" entry
> below is **retired** — `circuit/ENERGY_RESULTS.md` CORRECTION 2 showed the slow-ramp
> scheme was ~90–95% ideal-source flattery; the real-driver ramp is 3.5× WORSE than
> binary. The honest gate/fair-fight numbers live in `docs/FINAL_VERDICT.md` §compute.

One item per agent. As each background agent settles, the next item here gets an agent
slot. Mark items DONE with the date and the artifact.

## In flight (2026-08-28)

- (none)

## Queued (next slots, updated from the docs synthesis)

- [ ] Lean: Z₆ Haar / measure-preservation on ℤ[ω] (mathlib `MeasureTheory.count`) — the flag theorem.
- [ ] Lean: Radon–Nikodym `δ = dμ_obs/dμ_null` on the finite pair space; χ² scale-invariance under [count]→[prob].
- [ ] Lean: `√N ≤ wtHex ≤ N` (from 2412.18328 Thm 11) + `min+max=sum` port (1903.06044).
- [ ] Formal-verify `cpu.v` via PDR/MaxSAT with `11`=don't-care (boolector present).
- [ ] Add ternary D-latch/FF to `rtl/` (from 2211.12176 App A.3).
- [ ] Yosys power pass (PDP methodology from 2211.04542).
- [ ] Zipf-weighted energy theorem (small-numbers-outweigh-big).
- [ ] Circuit level: ngspice netlist for the AC-polarity cell + 2-diode receiver (energy/tests).
- [ ] RTL: Verilog/Chisel ternary gate library + Yosys/SymbiYosys synthesis (after the emulator).
- [ ] Rust `eisenstein.rs` → rebuild wiring patch (drop-in for `gauge_int.rs`).
- [ ] T6 geometric derivation of the packing density (circle ÷ fundamental cell = τ/(4√3)).
- [ ] Update the stale "depth-2 untested" note in AGENTS.md (depth-2 works, 2026-08-28).
- [ ] `Signature.lean` — formalize what distinguishes the four signatures (i²=−1,+1,0,ω).

## Done

- [DONE 2026-08-28] Energy experiments (ngspice, measured): naive 5.36 pJ (7× loss) →
  charge-transfer + paralleled N=4 MOSFET-diodes **0.562 pJ (1.33× win)**; adiabatic + high-Z
  **0.165 pJ (4.5× win, 5–20× slower)**; null free throughout. `circuit/ENERGY_RESULTS.md`.
- [DONE 2026-08-28] `Hexagon/EnergyModel.lean` — energy decomposition + break-even theorem
  (77.8% nulls at naive; unconditional win below E_binary).
- [DONE 2026-08-28] Batch 1 (measure/energy): `Haar`, `ChiSquareGauge`, `ValuationEnergy`,
  `ZipfEnergy` all PROVED (`proofs/INDEX.md` A1/A2/A3/B1z).
- [DONE 2026-08-28] Batch 2: `RadixEconomy` + `Signature` PROVED; ternary D-latch (`rtl/ternary_ff.v`
  25/25 assertions); `docs/PAPER.md` (the publishable write-up).
- [DONE 2026-08-28] Docs synthesis → `docs/graphs/` (37 graphs) + `docs/synthesis/` (measure-theory,
  ternary-circuits). Both theses CONFIRMED: counting-measure-is-base / probability=renormalized-counting
  (measure); gate-algebra/trit-code/radix/Eisenstein-energy confirmed but energy-free null is OURS (ternary).
- [DONE 2026-08-28] Verilog RTL → `rtl/` (ternary gates + naive single-cycle CPU + 3-layer
  self-checking testbench; iverilog all-pass, yosys ~6–7K cells, 213 FFs).
- [DONE 2026-08-28] Ternary cell energy + reuse → `Hexagon/TernaryCell.lean` (energy ≤1 line,
  null=0, avg 2/3 vs binary 1 → saves 1/3; encode never-both/not-surjective = the reusable
  overlap).
- [DONE 2026-08-28] Cycle-accurate naive CPU + hex RAM emulator → `rust-mirror/src/machine.rs`
  (cycles + polar-ternary transition energy; ~2.8 transitions/instr baseline; 41 tests green).
- [DONE 2026-08-28] Fractal hex RAM → `Hexagon/FractalRam.lean` (7ⁿ addressing, 7↔1
  parent-child fiber bijection, level-1 ↔ Fin 7; proved).
- [DONE 2026-08-28] Ternary ISA emulator → `rust-mirror/src/ternary.rs` (12 opcodes, 9
  implemented, 3 stubs; 29 cargo tests green).
- [DONE 2026-08-28] A→B patch: `gauge_int.rs` 60° + `rotate(k mod 6)` → `patches/` (verified
  `git apply --check`, 13 tests green in the standalone crate).
- [DONE 2026-08-28] A→B patch: TROT + TNORM in `isa.rs` → `patches/` (verified round-trip).
- [DONE 2026-08-28] Gauge-variant cheat-sheet → `GAUGE_VARIANTS.md` (324 lines: subscript
  naming convention, 10-variant table, ~26 typed edges, "what the sums mean", the method).
- [DONE 2026-08-28] hex↔u32 address bijection (Szudzik pairing, exact u32 box) → Lean
  `Bijection.lean` + Rust `bijection.rs` (13 tests green).
- [DONE 2026-08-28] Register ladder formalization → `Hexagon/Registers.lean`.
- [DONE 2026-08-28] 60°≅120° Eisenstein convention bridge → `Hexagon/ConventionBridge.lean`
  (same ring, φ(a,b)=(a,−b), norm preserved).
- [DONE 2026-08-28] Rebuild knowledge map → `survey/rebuild_map.md` (34 modules, ~13.4K
  lines; canonical math r=O−E, gauge=register=ring-shift; `gauge_int.rs` = PoC/unintegrated,
  mod-6 appears nowhere in the rebuild).
- [DONE 2026-08-28] Porting map → `survey/porting_map.md` (top 3: Registers.lean, align
  gauge_int.rs + mod-6 spinor, TROT/TNORM; top collision: "gauge" = 3 meanings; Eisenstein
  60° vs 120° mismatch).
- [DONE 2026-08-28] T0–T6 + Gauge + Residual all PROVED in Lean (`proofs/INDEX.md`).
- [DONE 2026-08-28] Rust mirror `eisenstein.rs` (6 property tests green).
- [DONE 2026-08-28] `TERNARY_PROCESSOR.md` (ternary ISA + polarity + fractal RAM spec).
- [DONE 2026-08-28] Depth-2 subagent delegation tested (works).
