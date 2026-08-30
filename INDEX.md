# Index — what this is, warts and all

## The short version

This is a **hobby research project** — a balanced-ternary processor on the Eisenstein
(60° hex) integer lattice, explored by **a non-expert and an AI agent working together**.
It is a *research process*, not a product. It contains real proofs, real Verilog, and real
ngspice measurements — but it is also full of dead ends, corrected mistakes, and honest
negative results. That is the point: here it is, warts and all.

The primary idea — **compute stays binary; ternary wins on transport (free null) and
addressing (the 3ⁿ hex namespace)** — was conceived first, then *verified* against the
literature and *falsified* where it didn't hold. Every flattering version of the idea was
tested, and most of them came back negative. The honest verdict is recorded, not hidden.

## What's actually here

| path | what it is | is it ours? |
|---|---|---|
| `proofs/` | Lean 4 formalization — the Eisenstein ring, the hex↔u32 bijection, the field calculus ∇F=J, the transport energy model, the proved 1.26× compute floor. 46 modules, `lake build` green, **zero `sorry`** | **yes** |
| `rtl/` | Verilog — ternary gate set, an 11-opcode ternary CPU, GA instructions, TGRAD/TRECON/TRELAX, the hex address unit, the ternary transport link, and a full binary-RISC-V SoC (`tau_soc.v`) | **yes** |
| `circuit/` | ngspice netlists — the ternary gate, the fair-fight baselines, the polar current-mode adder experiments | **yes** |
| `scripts/` | Python — emulators, the hex↔u32 bijection, the minimal-energy search, the plot generators | **yes** |
| `docs/` | the surveys, the verdicts, the circuit diagrams, the human-readable proof explanations | **yes** |
| `survey/` | the deep-dive method surveys (graph maps of the sources we read) | **yes** |

## What was tested, honestly

- **Compute**: binary beats ternary ~1.3–2× per operation (proved floor 1.26×, measured
  up to 2×). The ALU stays binary.
- **Transport**: polar ternary (push/pull/null, free null) wins ~2.7–6.3× — *conditional*
  on null-heavy data.
- **Addressing**: the hex 3ⁿ namespace beats 2ⁿ, crossover at n=2, then (3/2)ⁿ explodes.
- **Native ternary devices** (memristors, FeFETs, anti-ambipolar transistors, polar
  transistors): surveyed, and the answer is "no native 3-state device beats the 2-bit/trit
  cell." See `docs/graphs/ternary-transistors/_SYNTHESIS.md`.
- **The polar current-mode adder** (an independent re-derivation): it's a *cheaper ternary
  adder*, but not a binary-beater. Measured, not assumed. See
  `docs/compute/polar_adder/verdict.md`.

## The honest scoreboard

> Ternary wins where a value is **moved or named** (transport, addressing, geometry);
> binary wins where a value is **computed** (the ALU). The wins are exponential (`(3/2)ⁿ`);
> the loss is a constant (1.26×). The engine computes on addresses, not bits.

## Provenance

`CITATIONS.md` lists the arXiv papers that were looked up and what (if anything) they
influenced. The core design was conceived before the verification step; the papers were
the external reality check, and often the thing that said "no."

## License

MIT (`LICENSE`). Third-party cores (PicoRV32, NEORV32) are licensed separately
(`THIRD_PARTY.md`).
