# The Tau Architecture — one honest page

*A balanced-ternary processor on the Eisenstein integer lattice ℤ[ω], ω = e^(iπ/3).*

Every number below is **measured** (ngspice) or **proved** (Lean, `lake build` green,
zero `sorry`), and every claim carries its calibration tag:
**DIRECT** (measured/proved) / **ANALOGY** / **OURS** (our framing, not theirs) /
**SPECULATION**. This page is the front door; the audit behind it is
`docs/FINAL_VERDICT.md`.

---

## The claim, in one sentence

Ternary buys **names** exponentially (proved), moves **bits on a wire** cheaper by a
small real factor (measured, radix-agnostic), and **computes** more expensively by a
bounded factor no native device removes (measured + proved).

| axis | ternary vs binary | the honest number | calibration |
|---|---|---|---|
| **namespace** | `3ⁿ` (and `7ⁿ` hex) vs `2ⁿ` | `(3/2)ⁿ` → **1.86×10¹¹ at n=64**; `log₃2 = 0.6309` → **36.9% fewer symbols** | **DIRECT** (proved — `TritPacking.lean`, `RadixEconomy.lean`, `FractalRam.lean`) |
| **transport** | ~2.7–6.3× win | champion **0.081 pJ/bit = 6.3× vs natural single-ended binary (0.512)**; **2.67× vs matched low-swing binary (0.216)** | **DIRECT** (measured). Radix-agnostic: low-swing is shared with binary; the free null (~0.05 pJ) is real but *conditional on null-heavy data* |
| **compute** | ~1.5–3.5×/bit loss | **1.26× floor** (`2/log₂3`, representation-independent); honest native floor **~1.5–2×**; measured diode gate **3.4–4.9×** → **~3.5×** matched low-swing | **DIRECT** (measured + proved — `ThresholdLowerBound.lean`, `fair_binary` §4) |

**The one clean truth — names, not bits.** The architecture is an **addressing
machine**. It buys *names* exponentially where binary buys them linearly: per
addressable symbol the net win is `(3/2)ⁿ / ~1.4×`, and the exponential swamps the
linear tax. "The `3ⁿ` namespace is the engine's win; the per-bit energy story was
always a distraction."

---

## What is actually built (verified, not promised)

**Mathematics (Lean, 40 files, `lake build` green — 8746 jobs, zero `sorry`).** Eisenstein integers `ℤ[ω]` as a
Euclidean domain and the **unique well-rounded planar lattice** (A₂ — the densest
packing); geometric algebra over it (`conj`, raw `dot`, `wedge`, the symmetric
polarization `symdot = N(z+w)−N(z)−N(w)`); the six-fold gauge (units Z₆); the
**field calculus** `∇F = J` — the discrete gradient splits into div⊕curl, ∇² is the
6-point hex Laplacian, and ∇⁻¹ reconstructs up to gauge; plus the economic laws:
`(b−1)/ln b` is minimized at 2 (compute) and `b/ln b` at e (transport), and the
2-threshold lower bound that *forces* the compute verdict.

**Circuits (Verilog + iverilog + yosys, 8 suites green).** An 11-opcode
balanced-ternary CPU — TADD/TSUB/TROT/TNORM/LDI/TMUL + the GA ops
TCONJ/TDOT/TWEDGE/TSYMDOT — with a **ternary register file** carrying the 11=NEVER
single-bit-upset canary; the field-calculus datapaths TGRAD/TRECON/TRELAX (the
6-neighbor hex pod, `∇F = div⊕curl`); ternary memory with 4/5-trit packing
(`3⁴=81≤128`, `3⁵=243≤256`). yosys (real sky130 liberty): the core's logic area is
**~0.06 mm²** (a *gate-area* estimate of the 8-register core — not a chip; no pads,
routing, or memory macro).

**Independent convergence.** A separate memory-engine codebase (the "rebuild")
independently derived the *same* Eisenstein lattice from a different starting point
(statistical residuals) and labelled it "new/unbuilt." We had already Lean-proved
nearly all of it. When two unrelated paths land on the same structure, the structure
is real — **DIRECT** evidence, not OURs.

---

## What we did not hide — the five corrections

1. **Wrong receiver.** The "compute loses" verdict was first run diode-vs-sense-amp
   (two different objects). The diode-direction fix helps but **does not flip it**:
   still 2 decisions, plus a diode drop and resistive null-return (**7.8×** factor).
2. **Flattered binary baseline.** Transport's 0.748 pJ/bit reference was corrected to
   **0.512** (natural single-ended) / **0.216** (matched low-swing) — halving the
   headline from "9.2×" to **2.67–6.3×**.
3. **"Three laws" were not Lean theorems** — one priced model + two measured
   heuristics + a conflation; "proved in Lean" was laundering. Retired.
4. **The 0.63× native floor was unphysical** — it assumed a ternary toggle costs the
   same as binary; the 3-level SNR margin forces ~2×, so the honest floor is
   **~1.5–2×/bit**.
5. **Both escape hatches are red herrings.** Sign+magnitude still needs `⌈log₂3⌉ = 2`
   decisions (the 1.26× is representation-independent); the AAT "complex transistor"
   exists but its middle state is a static-current divider costing **≫1.585×**, not ~1×.

These are the point: the headline numbers survived because we hunted them, not because
we flattered them.

---

## What we would build

**Ternary transport + binary compute + cheap edge.** Keep the wire win (real, measured
~2.7–6.3×) and the free null on the link; keep compute on binary standard cells (the
2-bit/trit encoding *is* the correct binary-substrate representation); win the memory
engine on the **`3ⁿ` namespace**, where the exponential lives.

**The one open wall — the mod-3 sum `⊕` (1.42×/bit).** It is the single primitive
that decides whether compute ever goes native. It is stated here as the open problem,
not hidden — which is exactly what tells a reader where the next milestone is.
