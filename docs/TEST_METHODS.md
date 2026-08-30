# Test Methods Ledger — used and new

**2026-08-29.** The verification toolbox, so every method is named, critiquable, and reusable.
Calibration: each method's *known failure mode* is listed — that's the cross-verification hook.

## Methods USED

1. **ngspice fair-fight** — real driver + real receiver, no ideal sources, `E = ∫V·I dt`, full
   rise/fall cycles (÷2 for per-toggle). *Failure mode:* assert-only flatters asymmetric gates
   ~2×; the `E_gate/E_rec` two-bucket split presupposes a sense-amp receiver.
2. **yosys + SkyWater liberty** — `abc -liberty` area synthesis. *Failure mode:* the liberty is
   a *binary* standard-cell library, so it measures emulated ternary, not native.
3. **Lean proofs** — `lake build` green, zero `sorry`. *Failure mode:* a theorem can be true
   math over a *priced model* (e.g. `(b−1)/ln b` assumes ordered levels + uniform threshold cost)
   while the model itself is the thing in question.
4. **Survey → lens → calibrate → synthesize** — the graph-survey method (map sources, calibrate
   DIRECT/ANALOGY/OURS/SPECULATION, synthesize). *Failure mode:* a first pass can miss the
   `counter-to` edge; needs the lens pass.
5. **Meta-critique** — assumption-hunt over the whole corpus. *Failure mode:* the critic itself
   can carry unstated assumptions (flagged as domain-knowledge needing re-citation).
6. **Synthesis** — merge 3 reports, find overlap/disagreement, rank the TODO. *Failure mode:*
   the "ranking" is OUR judgment, not measured.

## Methods NEW (from the second pass)

1. **Diode-direction receiver** — two antiparallel diodes (direction detection) instead of a
   sense-amp level comparator. Fixes the null meta-stability; the correct receiver for
   sign+magnitude polar ternary.
2. **Null-idle probe** — measure idle *current* over a hold window, not just toggle energy.
   Settles "null is free" vs "null shoots through."
3. **Fair binary baseline** — single-ended 0–1 V binary, not ±1 V bipolar. Removes the ~2×
   handicap from every "N× vs binary" number.
4. **Full-swing toggle** — measure +1↔−1, not just the cheapest null↔+1. Removes the
   "cheapest-toggle flatters ternary" bias.
5. **Cross-verification audit** — meta-meta: audit the *methods themselves* (are the
   measurements biased? are the proofs load-bearing?), not just the results.

## The failure-mode map (what each audit must check)

| method | the bias it can introduce |
|---|---|
| fair-fight | receiver choice (sense-amp vs diode) changes the whole verdict |
| yosys liberty | binary library ⇒ measures emulation, not native |
| Lean theorem | priced-model premise hides in the "math is true" wrapper |
| survey lens | first pass misses reversals; calibrate at map time, not after |
| normalization | "per bit" conflates per-wire / per-state / per-gate / per-joule-of-work |

**Cross-verification principle (the point of this ledger):** a conclusion is only as strong as
the *weakest method* it passes through. Every verdict above rests on at least one method with a
known failure mode — so the audits in the next pass target exactly those modes.
