# Ternary Ground-Up — the native-device search

**2026-08-29.** The compute verdict ("ternary loses on gates, 2–14×") was measured on
**2-level MOSFET defaults** (ngspice LEVEL=1, the sky130 *binary* standard-cell library).
A 2-level transistor cannot natively produce 3 states — which is exactly *why* every
polar gate paid a demux+driver tax at every boundary. **The native 3-state device was
never built.** This is the search for it, from the device up.

**Thesis (to test, not assume):** with a *native* 3-state device and the minimal gate
set, ternary compute is competitive or better. Candidate devices exist (RTD's
negative-differential resistance gives multiple stable states natively; multi-threshold
CNTFET; single-electron transistor). We have not measured any of them.

## The search space (the permutation list — keep adding)

1. **Device** — the native 3-state transistor: RTD, multi-threshold CNTFET, SET,
   memristor, multi-gate/FinFET 3-point, spintronic, quantum-dot, …
2. **Encoding** — how the 3 states live: voltage (±V,0) / current / charge / phase / spin.
3. **Logic** — the truth tables: 27 unary (3³), 19,683 binary (3⁹), the useful balanced
   subset (min, max, negation, mod-3 sum, mod-3 product, consensus, cycle).
4. **Gate topology** — per-gate minimal transistor realization on the native device.
5. **Minimal complete set** — {negation, mod-3 sum, mod-3 product} (the F₃ field pair),
   already known complete.
6. **Resting state** — null = 0 = *default = off*; power only on push/pull (Ian's rule:
   "null is the default, so power is used only when needed").
7. **Optimization** — V, I, R, and the *natural adiabatic artifacts* of the native device.
8. **Test & proof** — Lean: what a polar ternary gate *is* (semantics, truth tables,
   composition); ngspice: per-gate fair-fight test circuit.

## The method — exhaustion, 10 agents a batch

- **One agent = one angle** (never multi-task an agent). Multiple agents per *thing*,
  from different angles (device gets literature + physics + circuit).
- Every agent **ends with TODO / not-covered / caveats** — that list is the feedback
  that seeds the next batch.
- **Batch 1 (first layer):** device ×3, truth table, minimal set, Lean semantics,
  null-as-default, optimization n-gram, test-suite spec, meta-critique.
- **Batch 2:** spawned from the union of batch-1 TODO/caveats.
- **Curation → graph:** once enough layers are done, graph the results (typed
  nodes/edges) for the overview; then re-check findings against the graph.

## The feedback loop

Each batch produces `docs/compute/ground_up/<topic>.md` ending in a `## TODO / not
covered / caveats` section. Those sections are merged into the next batch's prompts —
that is the "function that processes the first layer."
