# Ternary Compute Verdict — recalibrated (second pass)

> **⚠️ CORRECTION BANNER (2026-08-29):** this "second pass" verdict is itself superseded by
> `docs/FINAL_VERDICT.md` (the consolidated truth, same day, later). Two numbers here moved:
> transport settled at **2.67–6.3×** (0.081 pJ/bit = 6.3× vs 0.512 natural / 2.67× vs 0.216
> matched low-swing), not "~4.6×"; and compute settled at **~1.5–3.5×/bit LOSS** (measured
> diode gate 3.4–4.9× → ~3.5×), not the "0.48–0.97×/tie" below. Treat `FINAL_VERDICT.md` as
> authoritative.

**2026-08-29.** Supersedes the first-pass verdict. After the meta-critic + diode-gate pass,
the numbers are *more honest in both directions*. Calibration: measured (ngspice/yosys),
proved (Lean, `lake build` green 8741 jobs), or DIRECT/ANALOGY/OURS/SPECULATION.

## The recalibrated verdict

| layer | first-pass claim | recalibrated |
|---|---|---|
| **transport** | 9.2× win | **~4.6× win** (fair binary; the 9.2× was against a 2×-handicapped binary baseline) — *robust* |
| **compute** | 4.9–14.3× loss | **0.48–0.97×/bit** (null-heavy) → tie-to-2× (uniform), at 2–3× device count — *a tunable trade* |
| **floor** | "no fundamental win" | **1.26× fundamental** (the cost of `3 ≠ 2ᵏ`); the *above-floor* receiver tax was removable |

## What the second pass found (the three corrections)

1. **The wrong receiver.** The "gate loses" verdict compared a diode-*direction* wire against
   a sense-amp-*level* gate — two different objects. The correct diode receiver removes the
   sense-amp tax: null-idle ~0 (vs 1.9 pJ shoot-through), passive receiver (E_rec=0), and
   `dd_not`/`dd_nand`/`dd_min` land **0.48–0.97× binary per bit** on the null-heavy toggle.
2. **The flattered baseline.** Every "N× vs binary" was against ±1 V bipolar binary; binary's
   natural 1 V single-ended is ~2× cheaper, so the transport win is ~4.6×, not 9.2×.
3. **The category error.** "2-threshold tax = one device per threshold" is wrong — it's a
   property of the amplitude *code*, not the device; single devices (anti-ambipolar, RTD, SET,
   anti-ferroelectric) resolve 3 states in *one* measurement.

## The two surviving walls

1. **The 1.26× information floor** (`3 ≠ 2ᵏ`, `⌈log₂3⌉ = 2` decisions for 1.585 bits) —
   representation-independent, proved in `ThresholdLowerBound.lean` / argued in `meta_math.md`.
2. **The mod-3 sum `⊕`** — the one irreducible primitive (everything else is Kleene-derivable),
   and it is *not* diode-tractable (it needs a null rail `NOT(push OR pull)` the direction
   receiver doesn't produce). This is the single hardest open cell.

## The architecture decision (the two paths)

- **Path A (soft landing):** if the diode gate + a native `⊕` cell land ~1× binary, then
  binary-emulation-on-ternary is structurally free (the subset asymmetry), and adoption is
  near-zero friction. *Open — hinges on the `⊕` cell.*
- **Path B (transport-first):** if `⊕` stays ~2×, then keep the hybrid — **ternary transport
  + binary compute + cheap edge** — and win the communication fabric (a measured **~2.7–6.3×
  wire**, `FINAL_VERDICT.md` §transport) for distributed/memory-bound workloads, not raw
  compute. *This is the fallback, and it is already real.*

## The honest bottom line

The wire win is real and robust. The gate went from "clear loss" to "energy/area trade," and
its one hard wall is a *single primitive* (`⊕`), not the whole gate library. Ternary is not
"more expensive" in the way the first pass claimed — and not "cheaper everywhere" either. It
is **cheap on the wire, tradeable in the gate, with one open primitive.** The re-measurement
pass (fair binary + full-swing + the `⊕` cell) is the next, final, decisive step.
