# STATE NOTE — resume here after the docs synthesis (written 2026-08-28, before the big batch)

Deep context-recovery note. Read this FIRST when resuming. Everything lives under
`/home/ian/dsh/projects/lattice/` unless a full path is given.

## Who & what this project is

Ian (the human) is building a **semantic-lattice memory engine** and, growing out of it, a
**balanced-ternary hex processor**. Ian is NOT a formal mathematician — he intuited the
structure from first principles ("einstein triangles of 60 degrees", "counts not
probabilities", "gauge = the unit"), and AI pointed out that the things he was thinking about
were already named complex math. The session's whole arc has been: *formalize those
intuitions in Lean, mirror them in Rust, then take them to hardware (Verilog → RTL → circuits).*

Working principles Ian cares about (honor these):
- **"Counts, not probabilities"** (his "absolute math" vs statistics-normalizing-to-1): stay
  in the counting measure (integers), display as ratios only at the boundary.
- **τ, not π** ("the base unit of rotation is a circle, not a semicircle").
- **Lean as guide rails**: the typechecker is the spec; proof = test; it made a "weeks-long"
  effort go in days. Subagents + depth-2 delegation are proven and preferred.
- **Parallelize** via background subagents (each owns ONE file; Lean agents use TARGETED
  `lake build <Module>` to avoid cross-file collisions).

## The math conventions (locked, do not change)

- **Eisenstein integers** `ℤ[ω]`, `ω = e^(iπ/3)` (60°), `ω² = ω − 1`, norm `N(a+bω) = a²+ab+b²`,
  units `Z₆ = ±1, ±ω, ±ω²`. Conjugate `a+bω̄ = (a+b) − bω`.
- **τ = 2π**; hex packing density `τ/(4√3) = π/(2√3) ≈ 0.9069`.
- **The 60° vs 120° convention**: 120° = `ω² = e^(2πi/3)`, same ring, isomorphism
  `φ(a,b) = (a,−b)` — PROVED (`ConventionBridge.lean`). The rebuild's `gauge_int.rs` used 120°
  (a self-inconsistent bug — its doc claimed "60°"); our patch fixes it.
- **Gauge-variant naming** (see `GAUGE_VARIANTS.md`): subscript = the signature/question.
  `i₋₁` (i²=−1, Gaussian/Z₄), `i₊₁` (i²=+1, split-complex), `i₀` (i²=0, dual), `i_ω` (i²=ω,
  Eisenstein/Z₆); `E₆₀`/`E₁₂₀`; `τ`/`π`; count `E` vs probability `p`; register rungs
  `r_raw`/`δ`/`z`/`χ²`; axes `⊥`(corr/surprise) `∧`(wedge) `‖`(polarization). Primitive
  `r = O − E` = "how much more/less did these co-occur than independent."
- **Trit encoding** (one-hot-per-direction, the ternary cell): 2 bits, `01`=+1(push),
  `00`=0(null), `10`=−1(pull), `11`=NEVER. Energy = # energized lines; `≤1` line, null=0,
  avg `2/3` vs binary `1` (saves 1/3). PROVED (`TernaryCell.lean`). Ian's refinement: the
  1/3 is a per-trit LOWER bound; radix economy (`log₂3≈1.585` bits/trit) + Zipf ("small
  numbers outweigh big", null dominates) make the real saving far larger — THIS IS THE NEXT
  THEOREM TO PROVE (Zipf-weighted energy).

## The current stack (all built & verified 2026-08-28)

1. **Lean proofs** — `proofs/lean-src/hexagon/Hexagon/` (14 files), `lake build` GREEN
   (8720 jobs, ZERO `sorry`). Build: `cd proofs/lean-src/hexagon && PATH="$HOME/.elan/bin:$PATH" lake build`.
   - Conventions (Eisenstein structure, CommRing ops, `mul_comm`, `norm_mul`)
   - SevenHex (7 cells, 7-hex↔balanced-ternary bijection)
   - Rotation (Z₆ units, hexDist metric, isNeighbor)
   - Packing (τ, density identity)
   - Euclidean (covering-radius `exists_near_int_pair`)
   - EuclideanDomain (**CommRing + EuclideanDomain → UFD** — the big theorem)
   - Gauge (isotropy: `norm_of_unit`, `norm_mul_unit`, `norm_eq_det`, `units_eq_omega_powers`)
   - Residual (rebuild: `sum_E_row` marginal, `sum_residual_eq_zero`, `wedge_antisymm`, χ²≥0)
   - Registers (δ fold, surprise=δ²·E, sign-collapse, sym+skew split)
   - ConventionBridge (60°≅120°, `phi_mul`/`norm_preserved`/`phi_phi`)
   - Bijection (hex↔ℕ/u32, Szudzik pairing, exact u32 box)
   - FractalRam (7ⁿ addressing, 7↔1 parent-child fiber bijection, level-1↔Fin7)
   - TernaryCell (energy ≤1 line, null free, avg 2/3, encode never-both/not-surjective)
   - GraphDistance (honeycomb `SimpleGraph.dist = hexDist`, both directions)
   - Ledger: `proofs/INDEX.md`. Tactics/gotchas: `proofs/PROVER_NOTES.md`.
2. **Rust** — `rust-mirror/` (41 `cargo test` green): `eisenstein.rs` (Eisenstein + Z₆),
   `bijection.rs` (u32 bijection), `ternary.rs` (12-opcode ISA emulator), `machine.rs`
   (cycle-accurate naive machine + polar-ternary transition energy; ~2.8 transitions/instr).
3. **Verilog** — `rtl/`: `ternary_gates.v`, `trit_functions.vh`, `cpu.v`, `cpu_tb.v`,
   `program.hex`, `cpu_tb.vcd`. `iverilog`+`vvp` all-assertions-pass; `yosys` ~6–7K cells,
   213 FFs. Naive single-cycle, TADD/TSUB/TROT/TNORM/LDI/HLT. Trit encoding cites TernaryCell.
4. **Patches** — `patches/`: `gauge_int_60deg.patch` (fix rebuild's 120°→60°, add
   `rotate(k mod 6)`), `isa_trot_tnorm.patch` (add TROT/TNORM to rebuild's `isa.rs`).
   Apply on the rebuild machine (`/home/ian/opencode/parser/english/rust/lattice/`, READ-ONLY
   from the sandbox). Rebuild is 34 modules, ~13.4K lines; `gauge_int.rs` was PoC/unintegrated.
5. **Docs** — `GAUGE_VARIANTS.md`, `TERNARY_PROCESSOR.md` (12-opcode ISA + polarity + fractal
   RAM), `HEXAGON_LATTICE_PLAN.md`, `BACKLOG.md`, `LATTICE_MATH.md`, `survey/` (SYNTHESIS.md,
   rebuild_map.md, porting_map.md, and the hexigon/ox-alpha/agents graphs+lens).

## The survey method (use it for the docs synthesis)

Graph-survey: **map** a source to a labeled relation graph (typed nodes + typed directed
edges, surface `counter-to`/reversal edges, calibrate DIRECT/ANALOGY/OURS/SPECULATION) →
**lens** pass (re-map the source against the current system's graph) → **synthesize**. This
is the project's own "convergence diamond" method; it's how we did hexigon/AGENTS/ox-alpha.

## THE CURRENT TASK (what I'm about to do)

Process `docs/measure theory/` (18 PDFs) and `docs/Ternary Circuts/` (~17 PDFs). For EACH
folder, for EACH document: **map-to-graph** + **map-to-current-system**, write each graph as
an `.md` file, THEN **synthesize** across the folder. PDFs need text extraction first
(`pdftotext` if available, else python). Ian's framing for why this batch:
- **measure theory** ↔ how we got to Eisenstein integers: "same things, gauge becomes a
  natural and cheap integer thing." (His "counts not probabilities" IS the counting measure
  vs the probability measure.)
- **ternary circuits** ↔ how to proceed on the hardware.
This is meant to *formalise around what we need* and surface next directions.

## Future directions (the "stack register" — pop these when ready)

- **Zipf-weighted energy theorem** (Lean): expected energy under a power-law/geometric trit
  distribution, showing the real saving >> the uniform 1/3. HIGH priority (Ian's insight).
- **Yosys power pass**: real watts/instruction (`synth` + a liberty file + `stat -power` or
  an ABC power estimate). The circuit synthesizes; now chart energy.
- **ngspice netlist**: the AC-polarity cell + 2-diode receiver, measure real ∫V·I per
  push/pull/null transfer (validates "null is ~free" + the energy-ratio claim).
- **RTL improvements**: `tmul_trits` dominates area (unoptimized shift-add); a ternary
  instruction encoding (currently binary-host); fractal-RAM (7ⁿ) in Verilog; write-masking.
- **Signature.lean**: formalize what distinguishes the four signatures (i²=−1,+1,0,ω) — they
  are NOT all isomorphic (isotropy holds only for the elliptic pair).
- **T6 geometric derivation**: circle-area ÷ fundamental-cell = τ/(4√3) (currently cited).
- **Rust→rebuild wiring**: `eisenstein.rs` as a drop-in (patch, sandbox read-only).
- **Radix economy theorem**: a trit = log₂3 ≈ 1.585 bits; ternary grows slower than binary.

## Meta (tooling facts)

- Lean v4.33.1 (mathlib); `elan`/`lake` at `~/.elan/bin`. `deriving Fintype` is BROKEN in
  this toolchain — hand-write the instance.
- The rebuild tree `/home/ian/opencode/parser/english/` is READ-ONLY from this sandbox
  (write to it fails). Emit patches, don't live-edit.
- Depth-2 subagent delegation WORKS (tested). Background subagents notify on settle; I am
  the scheduler. The `workflow` tool fans out agents with phases.
- EDA tools installed: `iverilog`, `vvp`, `gtkwave`, `yosys`, `boolector` (not verilator/symbiyosys).
- Ian's key papers to remember: "Codes over Eisenstein Integers" (arXiv:2412.18328, energy
  advantage), "Ternary Transistors With Reconfigurable Polarities" (2025, hardware exists),
  plus MVL-verification + measure-theory papers now in `docs/`.
