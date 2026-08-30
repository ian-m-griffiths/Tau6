# proofs/ — the Hexagon Lattice formal-verification ledger

Lean 4 + mathlib formal proofs for the hexagon-lattice plan
(`/home/ian/dsh/projects/lattice/HEXAGON_LATTICE_PLAN.md`).

**What this is:** the *idea-history ledger* for the Eisenstein ℤ[ω] / 60°-triangle /
balanced-ternary claims — every theorem file carries provenance (which chat, which
line), status, and a DIRECT / ANALOGY / SPECULATION calibration label. This is the
append-only-ledger discipline (AGENTS.md rule) applied to proofs: the proof ledger
outlives every agent.

**Layout**
- `lean-src/` — the drop-in Lean project (contract files; see SETUP.md to build)
- `AGENTS.md` — instructions for the proving agent(s)
- `INDEX.md` — claim → file → status ledger
- `.env` — prover secrets (gitignored; DEEPSEEK_API_KEY set 2026)
- `results/` — prover run outputs (gitignored, created by runs)

**Status (2026-08-29):** `lake build` GREEN — **8746 jobs, zero `sorry`**, toolchain
v4.33.1, all 40 theorem files proved (T0–T6 + the gauge/residual/measure/energy/
RAM-geometry/radix/GA batches). See `INDEX.md` for the claim→file→status ledger and
`../docs/FINAL_VERDICT.md` for the consolidated truth. (The earlier "no theorem proved
yet" line here was stale.)
