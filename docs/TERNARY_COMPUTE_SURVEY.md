# Ternary Compute Survey — full-ternary-internal vs binary emulation

**2026-08-29 — the setup doc for the next big program.** Defines the question, the
method, the component matrix, and the subagent fan-out. Calibration legend:
**DIRECT** = measured/proved; **ANALOGY** = structural resemblance, not identity;
**OURS** = our design claim; **SPECULATION** = untested hypothesis.

---

## The core question

Now that ternary **communication** wins (0.081 pJ/bit, null free), can we do ternary
**compute** internally — or should we emulate binary in ternary cells, or stay hybrid
(ternary datapath + binary control, which is where `cpu.v` is today)?

## The reframe (what last night taught us)

**Compute is not communication.** The null is free *on the wire* (nothing to transmit)
but *not in a gate* — a gate must still *resolve* "is this −1, 0, or +1?" every toggle.
By Law 1 (the receiver is gauge-agnostic), every ternary gate pays a **2-threshold**
measurement tax per cycle, forever; a binary gate pays **1 threshold**. So the question
sharpens to one inequality:

> **Does radix economy (3/ln3 ≈ 2.73, fewer symbols per unit of information) beat the
> per-gate receiver tax (2 thresholds vs 1)?**

The literature (already partially surveyed in `docs/synthesis/`) is *mixed* — ternary
circuits often lose on energy because the extra level costs more in the gates than the
radix economy saves. But we now have the fair-fight harness + the receiver-floor law, so
we can **measure** it instead of trusting it.

## The trit-tricks hypothesis (Ian, 2026-08-29)

> Einstein integers give **τ/6** (the six 60° units Z₆); ternary gives **3 states**; so
> every wire carries **log₂3 ≈ 1.585 bits** of density vs binary's 1. Binary has "bit
> tricks" — popcount, XOR, barrel shift, parity, mask. Ternary/hex should have **trit
> tricks** — and the density means more information per operation, so full ternary may be
> *cheaper in the end* despite the per-gate tax.

**Calibration: SPECULATION (to be tested).** But it has a real anchor: the rebuild already
runs on one trit trick — `cos θ ≡ (−1)^popcount(i&j)` (parity as the bivector sign) and the
barrel shifter replacing transcendentals ("trig becomes mod-6 arithmetic", `d >> 1` = RG
flow). The survey's job is to find *all* the trit analogs of the bit tricks and cost them.

## The component matrix (the "n-gon" of tradeoffs)

Axes per component: **energy · area · complexity · speed · native-benefit** (what ternary
gives *free* that binary doesn't).

| layer | components | status |
|---|---|---|
| **logic** | unary/binary ternary gates (neg, min, max, mod-3 sum), functional-completeness | to survey |
| **storage** | latch/FF ✅ (`ternary_ff.v`); **3-level SRAM/DRAM cell** | FF done; memory cell is the big open one |
| **arithmetic** | adder ✅ (PDR-verified), multiplier ✅ (−9% via norm identity), ALU/div/compare | mostly done |
| **control** | ternary opcodes vs binary-host encoding; decoder | to survey |
| **interface** | binary↔ternary converters (the emulation bridge, ADC/DAC at the edge) | to survey |

## The method — exhaust assumptions, then intuit the build

1. **Phase 0 — inventory** what we have (below), so nothing is re-derived.
2. **Phase 1 — per-component survey** (fan out): for each component, what methods exist,
   what are the energy/area/complexity/speed tradeoffs, what does ternary give natively.
3. **Phase 2 — similarity pass**: across all components, find what's *common* (the
   repeated costs — threshold count, receiver tax, voltage levels, don't-care states).
4. **Phase 3 — relation pass**: how each problem *relates* to the others (e.g. gate
   threshold cost ↔ memory-cell margin ↔ converter cost are all "measurement cost").
5. **Phase 4 — upper bounds → reduce**: establish the energy/area upper bound per
   component, rank the worst, and attack the top of the list.

The output is a **spectrum**: binary-emulated → hybrid → full-native-ternary, with the
measured break-even point between each step.

## What we already have (Phase 0 inventory — do NOT re-do)

- `rtl/cpu.v` ternary CPU: yosys 26,713 → **24,314 µm²** after the −9% tnorm optimization,
  50.3 MHz, 1.60 mW; PDR-verified `verify_tadd1` adder; `tmul_opt.v` (Karatsuba + norm
  identity, SAT-proved); `ternary_ff.v`; trit encoding `01=+1, 00=0, 10=−1, 11=NEVER`.
- `docs/synthesis/` — the 19-paper ternary-circuits literature survey (graph-mapped).
- `circuit/ENERGY_RESULTS.md` + `docs/ENERGY_LAWS.md` — the comm stack (0.081 pJ/bit) and
  the three laws (receiver gauge-agnostic · diagonal is I²R · 3 nearest e).
- `proofs/` — full build green (8734 jobs, zero sorry), incl. Pod / HexIsotropy / HexDisk
  / OffsetGrid (the geometry that underlies the addressing/isometry arguments).

## The subagent fan-out (ready to launch)

**Wave 1 — component survey (one research subagent each):**

1. **Ternary logic gates** — complete balanced-ternary gate sets (min/max/neg vs mod-3
   sum/consensus), functional completeness, transistor counts, energy/area vs binary,
   and the honest verdict on the 2-threshold tax.
2. **Ternary storage** — 3-level SRAM/DRAM cell designs, the `11=NEVER` don't-care encoding,
   margin/refresh tradeoffs, and whether the memory cell (not the gate) is the real wall.
3. **Trit tricks** — systematically enumerate the bit tricks (popcount, XOR, barrel shift,
   parity, mask, `d>>1` RG flow) and find each one's ternary/hex analog; cost them under
   the density argument.
4. **Binary↔ternary converters** — the ADC/DAC edge, what the emulation bridge costs in
   energy/area/latency, and where it flips the emulation-vs-native decision.
5. **Ternary control/instruction encoding** — 3-level opcodes vs binary-host encoding,
   decoder cost, and what the ISA gains from native ternary control.

**Wave 2 — similarity + relation (after Wave 1):**

6. **Similarity pass** — across all Wave-1 reports, extract the repeated costs (receiver
   tax, threshold count, voltage levels, don't-care reuse).
7. **Relation pass** — how each component's problem relates to the others (map the
   shared "measurement cost" structure; find the one or two levers that recur).

**Wave 3 — upper bounds → reduce:**

8. **Upper-bound tests** — per-component energy/area upper bounds (ngspice + yosys +
   SkyWater liberty), ranked.
9. **Reduce the worst** — targeted redesign of the top-cost component.

## The natural next (set up in parallel, ready to launch)

- **Receiver cheapening** (comm energy floor): wider input pairs / lower-Vt front end for
  the sense amp — the receiver is 2/3 of the 0.081 pJ/bit; this is the direct next lever.
  SPECULATION to test: *wider devices* (Ron÷N) help; *more amps* duplicate energy.
- **RTL Eisenstein-multiply opcode**: `tmul_eisen_trits` already gives −14.6% area at N=6
  but the CPU has no instruction for it — add the opcode, re-run yosys, measure.
