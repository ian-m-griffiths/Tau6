# The Tau6 Architecture

**A balanced-ternary processor on the Eisenstein integer lattice ℤ[ω]** (ω = e^(iπ/3),
the 60° hex grid). Formalized in Lean, built in Verilog, measured in ngspice — with the
honesty rule: *borrow, don't trust; verify like our own intuition.*

## Note from the human
I did the core initial math and idea, and an ai told me this was the einstine itegers while trying to figure out gauge theory
After realizing that Tau/6 is ternary * 2 it all sort of came together

This is a hobby project, now with lean proofs, and hardware description language and testing
This is a proof of concept only, write up by the AI, parts may be wrong, have not double checked

Enjoy :)

## The claim, honestly

> Ternary buys **names** exponentially (proved), moves **bits on a wire** cheaper by a
> small real factor (measured, radix-agnostic), and **computes** more expensively by a
> bounded factor no native device removes (measured + proved).

| axis | ternary vs binary | the honest number |
|---|---|---|
| **namespace** | `3ⁿ` (and `7ⁿ` hex) vs `2ⁿ` | `(3/2)ⁿ` → **1.86×10¹¹ at n=64**; 36.9% fewer symbols |
| **transport** | ~2.7–6.3× win | 0.081 pJ/bit = **6.3× vs 0.512**, **2.67× vs 0.216** |
| **compute** | ~1.5–3.5×/bit loss | **1.26× floor**, ~1.5–2× native, ~3.5× measured gate |

It is an **addressing machine**: the win is the `3ⁿ` namespace, not per-bit energy.
Per addressable symbol the net win is `(3/2)ⁿ / ~1.4×` — the exponential swamps the
linear tax. The one open wall is the mod-3 sum `⊕` (**1.42×/bit**), stated here rather
than hidden.

## What's here

| path | what | status |
|---|---|---|
| `docs/TAU_ARCHITECTURE.md` | the one-page story | the front-door narrative |
| `docs/FINAL_VERDICT.md` | the consolidated truth + the five corrections | authoritative numbers |
| `proofs/` | Lean 4 proofs (46 modules) | `lake build` green, 8753 jobs, **zero `sorry`** |
| `rtl/` | ternary CPU + GA ops + field calculus + memory + the **full SoC** (`tau_soc.v`) | testbenches green, yosys-mapped |
| `circuit/` | ngspice energy measurements (incl. the corrections) | fair-fight, real drivers/receivers |
| `docs/compute/` | gates, storage, arithmetic, field calculus, the hybrid cut, the polar-adder experiments | surveys + measured |
| `docs/circuit_diagrams/` | transistor-level schematics (ternary gate, full-adder comparison, power story) | human-readable |
| `docs/proofs_explained/` | every Lean theorem explained in plain English | what / why / method / step-by-step |

## Verify it yourself

```bash
# Lean (46 modules, zero sorry)
cd proofs/lean-src/hexagon && lake build            # "Build completed successfully (8753 jobs)"

# RTL (the 8 suites)
cd ../../.. && iverilog -o t.vvp \
  rtl/ternary_gates.v rtl/tmul_opt.v rtl/ga_ops.v \
  rtl/ternary_ff.v rtl/ternary_mem.v rtl/cpu.v rtl/cpu_ga_tb.v && vvp t.vvp
# → "ALL GA ASSERTIONS PASSED"

# area (yosys + sky130 liberty)
bash rtl/yosys_report.sh
```

## Status

This is a **working prototype + a proved mathematics library**, not a chip. The
`~0.06 mm²` yosys number is the *gate-area estimate* of the 8-register core — no pads,
routing, or memory macro. The honest build target is **ternary transport + binary
compute + cheap edge**, winning on the `3ⁿ` namespace (`docs/FINAL_VERDICT.md` §"What
we'd build").
