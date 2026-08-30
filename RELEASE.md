# Release Plan — the Tau Architecture

Goal: release an **honest** architecture, not a flattering one. The differentiator is
that every headline number survived our own audit (`docs/FINAL_VERDICT.md`), and the
compute loss is stated as a feature, not hidden. Checkboxes are current state; anything
`[ ]` is the remaining work. Principle throughout: **borrow, don't trust; verify like
our own intuition** — calibrate DIRECT / ANALOGY / OURS / SPECULATION at the moment of
adoption.

---

## Phase 0 — Truth pass (retire stale numbers, fix status drift)

- [x] `docs/FINAL_VERDICT.md` — consolidated truth + the five corrections.
- [x] `circuit/ENERGY_RESULTS.md` — CORRECTION 1 (receiver) + 2 (adiabatic) + PAM-4/5-symbol.
- [x] `docs/TAU_ARCHITECTURE.md` — the one-page honest story (this session).
- [x] `docs/compute/CPU_INTEGRATION.md` — circuit wiring ledger (this session).
- [x] `proofs/README.md` — un-staled ("no theorem proved yet" → green, zero sorry).
- [x] `docs/ENERGY_LAWS.md` — correction banner (9.2× → 6.3×/2.67×; 0.165 retired).
- [x] `BACKLOG.md` — correction banner (0.165 adiabatic retired).
- [ ] **Full audit:** grep every doc for the corpse numbers — `0.165`, `9.2×`, `1/10th`,
  `0.63× native floor`, "ternary = binary cost", "ring = Fisher info", "least squares =
  least action" — and add a correction pointer to `FINAL_VERDICT.md`. (Known leftovers:
  `docs/TERNARY_PROCESSOR.md`, `docs/TERNARY_COMPUTE_SURVEY.md`, `docs/REBUILD_SURVEY.md`,
  `hexigon_conversation.md`, `ox alpha.md`.)

## Phase 1 — Front door + quarantine

- [x] Top-level `README.md` — the front door (story, table, verify-it-yourself).
- [ ] **Quarantine non-release content:** move `hexigon_conversation.md` (538 KB),
  `ox alpha.md` (485 KB), `AGENTS.md` (192 KB workspace file), stray `b.v`/`tb.v`, and the
  `docs/` arXiv download library into a `raw/` or `notes/` dir excluded from the release
  tree (or a separate repo).
- [ ] Pick a license (suggest MIT for code + CC-BY for the write-ups; confirm with Ian).
- [ ] One-sentence "what this is NOT" disclaimer (working prototype + proved library,
  not a chip — no pads/routing/macro; compute is a trade-off).

## Phase 2 — Lean release (clean standalone repo)

- [x] `lake build` green — 8746 jobs, zero `sorry`, 40 files (verified this session).
- [x] `proofs/INDEX.md` — claim → file → status ledger (up to date).
- [ ] Confirm `lakefile.toml` + mathlib pin so a stranger can `lake build` from cold.
- [ ] `proofs/README.md` → rewrite as a public README (what's proved, the calibration
  legend, the T0–T6 + batches map), keeping the idea-history ledger as an appendix.
- [ ] Publish as `hexagon-lattice-lean` (or similar) with the zero-`sorry` claim front
  and center.

## Phase 3 — RTL release

- [x] 8 testbenches green (verified this session): `ternary_ff`, `trelax`,
  `ternary_mem`, `grad_recon`, `ga_ops` (52,805 assertions), `tregfile_2r1w`,
  `cpu_tb`, `cpu_ga_tb`.
- [x] yosys-mapped (sky130): CPU chip area **62,533.72 µm²**.
- [ ] `rtl/README.md` — the exact iverilog + yosys commands for all 8 suites, the ISA
  table (opcodes 0–9 + HLT), the 2-bit/trit encoding, and the 11=NEVER canary.
- [ ] Name the open wall in RTL terms: the mod-3 sum `⊕` (1.42×/bit) — the one gate to
  attack before compute goes native.

## Phase 4 — Demo / emulator showcase

- [ ] The `3ⁿ` vs `2ⁿ` namespace table (`docs/NAMESPACE_TABLE.md`) rendered as a plot —
  the one image that carries the whole thesis.
- [ ] A runnable emulator trace (the `rust-mirror`/naive emulator) showing a ternary
  program hitting the GA ops + field calculus, with a copy-paste run command.
- [ ] Optional: a 30-second "what survives" screen (the three-axis table).

## Phase 5 — The release artifact

- [ ] Tighten `docs/TAU_ARCHITECTURE.md` to external-audience voice (keep every tag).
- [ ] One release post: the honest claim + the five corrections as *evidence of rigor*
  (not as an apology) + "what we'd build" + the open wall.
- [ ] Link the independent-convergence fact (the "rebuild" independently derived the
  same Eisenstein lattice) — it is the strongest single piece of external validation.

## Phase 6 — Clean-room verification (borrow, don't trust, one last time)

- [ ] A **fresh agent** (no session context) re-runs, from `README.md` alone:
  `lake build`, the 8 iverilog suites, and `yosys_report.sh` — and reports any step that
  doesn't reproduce. Fix the docs until a stranger can reproduce every number.
- [ ] Cross-check every number in `TAU_ARCHITECTURE.md` against its cited source file
  (FINAL_VERDICT, ENERGY_RESULTS, the Lean theorems, the ngspice tables).

---

## Order of attack (this session → release day)

1. Finish Phase 0 audit (retire corpse numbers) — parallelizable subagents.
2. Phase 1 quarantine + license (Ian's call on license).
3. Phase 2/3 READMEs (one agent each, parallel).
4. Phase 4 plot + trace (one agent).
5. Phase 6 clean-room run (the final gate before anything ships).
