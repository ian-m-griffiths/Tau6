# Tau RISC-V — a ternary/hex-addressed RISC-V processor (the big plan)

**2026-08-29.** The roadmap from "we have the proofs and a toy datapath" to "we run
something useful." Not a ternary ALU — a **binary RISC-V core with a ternary/hex memory
subsystem + ternary transport + a geometric-algebra co-processor**.

## The honest thesis (read first, it governs everything)

Compute stays **binary**. Ternary wins in exactly two places — and they are not the ALU:

| where ternary goes | why | proof / number |
|---|---|---|
| **the address space** | `3ⁿ` names vs `2ⁿ` — the engine computes on *addresses* | `AddressTranslation.lean`, `TritPacking.lean`, `FractalRam.lean` — exponential |
| **the transport** | the wire is cheaper per bit | ngspice, ~2.7–6.3× |

A ternary **ALU** is the losing layer (`ThresholdLowerBound.lean`: 1.26×/bit, 2-threshold
tax) and we are **not building one**. The RISC-V integer core is stock binary; ternary
lives in the **MMU/address decoder**, the **memory interconnect**, and an optional
**Xlattice co-processor** for the GA/field-calculus ops we already proved + built.

## What is already in hand

- **Proofs** (`proofs/lean-src/hexagon/Hexagon/`, `lake build` green, zero `sorry`, 8748
  jobs): `CausalLattice` (hex causal lattice), `AddressTranslation` (hex↔u32, angle⊇parity),
  `Bijection` (Szudzik hex↔u32), `CrtHex` (Z₆≅Z₂×Z₃), `Conjugate`/`DotWedge`/`SymDot`
  (the GA ops), `Residual` (Σ(O−E)=0, wedge=skew), `TritPacking`/`FractalRam` (3ⁿ/7ⁿ).
- **RTL** (`rtl/`, 8 testbenches green, yosys-mapped): the 11-opcode ternary CPU, GA ops,
  field calculus (`grad_recon.v`, `trelax.v`), ternary memory (`tregfile_2r1w` + 11=NEVER
  canary). This is the *datapath proof*, not the product.
- **Spec**: `docs/riscv spec/` — `riscv-unprivileged.pdf` (the ISA + custom-0 encoding),
  `riscv-privileged.pdf` (the MMU/CSR — the addressing side we care about), plus iommu,
  plic, debug, trace.
- **Emulator**: `tinyrv` installed in `venv/` (RISC-V sim + assembler/disassembler).

## The tinyrv seams (where we plug in — already located)

| tinyrv hook | what it is | what we put there |
|---|---|---|
| `pa`, `page_and_offset`, `page_and_offset_iter` | address translation / MMU | the **hex MMU** = `eisensteinToNat` bijection |
| `load` / `store`, `notify_loading` / `notify_stored` | memory access path | the **ternary transport** model (energy) |
| `unimplemented`, `customs` | custom-instruction dispatch | the **Xlattice** extension (GA + field calculus) |
| `mask_match_rv32/64`, `opcodes`, `decode` | instruction encoding | the custom-0 opcode assignment |

## Phases

### Phase 0 — Recon & running (this week)
- [x] `pip install tinyrv` (done, `venv/`).
- [x] RISC-V spec located (`docs/riscv spec/`).
- [ ] tinyrv running a real RV32I program (hand-assemble a small loop, `sim.run`).
- [ ] A one-page "surface map": the base opcode table, the **custom-0** encoding space
  (riscv-unprivileged ch. 33), the CSR/`satp` MMU flow (privileged spec) — the three things
  we touch.
- **Deliverable**: a reproducible tinyrv harness + the surface map.

### Phase 1 — Hex-addressed memory (emulation)
- Replace tinyrv's flat byte-addressable memory with a **hex-addressed** memory: an
  address is an Eisenstein cell `(a, b)`; the `3ⁿ` namespace.
- Implement the hex MMU at the `pa` seam: `eisensteinToNat`/`eisensteinOfNat` (the
  `AddressTranslation` bijection) + the Z₆ angle (mod 6) + the hex-disk ring.
- Expose the `CausalLattice.flow`/`curl` as memory-aware ops (wedge along the 6 directions).
- **Measure**: address density — names per symbol `3ⁿ` vs `2ⁿ` (the `(3/2)ⁿ` curve).
- **Deliverable**: tinyrv + hex memory running a program whose addresses are hex cells;
  the density number.

### Phase 2 — Xlattice custom extension (emulation)
- Implement the GA ops (TCONJ/TDOT/TWEDGE/TSYMDOT) + field calculus
  (TGRAD/TRECON/TRELAX) as tinyrv `customs`, assigned into the **custom-0** opcode space.
- Write the Xlattice spec: opcode encodings + the register/width conventions (reuse the
  `cpu.v` ISA semantics, which are already Lean-proved).
- **Deliverable**: tinyrv + Xlattice running a GA/field-calculus workload; the Xlattice
  opcode spec.

### Phase 3 — Ternary transport (emulation + measurement)
- Model the wire energy in the `load`/`store` path (the 0.081 pJ/bit number, the ~2.7–6.3×
  vs fair binary).
- **Deliverable**: an energy model in the emulator; the measured transport win on a real
  memory access pattern.

### Phase 4 — Hardware (RTL)
- Hex address decoder / MMU (the `3ⁿ` namespace, `FractalRam` 7ⁿ) in Verilog.
- Ternary transport link controller (the wire) in Verilog.
- Attach to a stock binary RV32I core (or reuse `cpu.v` as the co-processor side).
- **Deliverable**: RTL hex MMU + transport, iverilog/yosys verified (same discipline as
  the existing 8 suites).

### Phase 5 — Lean proofs (the correctness story)
- The hex MMU satisfies the RISC-V memory model (address-translation correctness: every
  hex address is a valid u32 and round-trips — already `AddressTranslation`/`Bijection`;
  add the memory-consistency lemmas).
- The Xlattice extension semantics match the Lean specs (`PolarGate`, `DotWedge`,
  `SymDot`, `Residual`, `CausalLattice`).
- **Deliverable**: new Lean modules certifying the MMU + extension; `INDEX.md` updated.

### Phase 6 — Integration + fair-fight
- Wire emulator + RTL + proofs together; run a real workload end-to-end.
- The honest fair-fight: ternary (hex addressing + transport) vs binary RISC-V, measured
  on **address density** and **transport energy** — the two axes that matter.
- **Deliverable**: the "useful machine" + the honest scoreboard, compute explicitly
  binary.

## Milestones (the "run something useful" ladder)

1. tinyrv runs a real RV32I program (Phase 0).
2. tinyrv + hex memory runs a program with hex addressing (Phase 1).
3. tinyrv + Xlattice runs a GA/field-calculus workload (Phase 2).
4. RTL hex MMU + transport link, verified (Phase 4).
5. End-to-end fair-fight measurement (Phase 6).

## Honest caveats (baked in, not to be re-litigated later)

- **Compute stays binary.** The 1.26×/bit tax is real and the ALU is not where we win.
- **The wins are addressing + transport**, measured, not assumed. If Phase 1/3 don't show
  the density/energy win at scale, we stop and say so.
- **The mod-3 sum `⊕` (1.42×/bit)** is the one open wall *if* we ever want a native ternary
  ALU — this plan does not depend on it.
- This is a **long** project (weeks of emulation + RTL + proofs). The plan is staged so
  each phase has a checkable, honest deliverable before the next is funded.
