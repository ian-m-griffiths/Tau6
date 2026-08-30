# SETUP — build the Lean project

> **Status 2026-08-28:** toolchain v4.33.1 IS installed; the project builds GREEN
> (verified in-sandbox with `ELAN_TOOLCHAIN=$(cat lean-toolchain)`). One fix needed
> on your machine: a stale elan override to v4.34.0-rc2 sits on the `hexagon/` dir —
> it forces a mathlib recompile that fails inside Batteries. See §1b. Rust 1.95,
> Python 3.13, git are present; network works.

## 1a. Lean toolchain (DONE on your machine — verify only)

```bash
export PATH="$HOME/.elan/bin:$PATH"
lean --version          # should print "Lean (version 4.33.1 ...)" — already installed
```

## 1b. THE FIX — remove the stale toolchain override (this was the build failure)

```bash
cd /home/ian/dsh/projects/lattice/proofs/lean-src/hexagon
elan override list      # you will see: leanprover/lean4:v4.34.0-rc2  (wrong)
elan override unset     # clear it — the project's own lean-toolchain (v4.33.1) takes over
lean --version          # now prints 4.33.1 inside this dir
```

Why: mathlib is pinned at **v4.33.1** (lakefile.toml + lean-toolchain) and the olean
cache matches v4.33.1. The override to v4.34.0-rc2 made `lake build` recompile all of
mathlib under the wrong compiler, failing inside `Batteries.Data.Float.Basic` /
`Batteries.Data.List.Basic` / `Mathlib.Tactic.Linter.Whitespace`. The override was
created by an earlier version of this file that pinned to mathlib *master's*
lean-toolchain — that was a mistake; the generated `lean-toolchain` is authoritative.
Escape hatch if you ever need a different toolchain for one command:
`ELAN_TOOLCHAIN=$(cat lean-toolchain) lake build`.

## 2. Project (already created — hexagon/ exists with the contract files dropped in)

```bash
cd /home/ian/dsh/projects/lattice/proofs/lean-src/hexagon
ls Hexagon.lean Hexagon/Conventions.lean Hexagon/SevenHex.lean Hexagon/Rotation.lean
```
(If re-creating from scratch: `lake new hexagon math` → copy the files from `lean-src/`
per the old instructions below.)

## 3. Deps + mathlib cache + build

```bash
lake update                     # resolves mathlib (first clone is large)
lake exe cache get              # downloads precompiled mathlib oleans (~1 GB, skips compiling)
lake build                      # builds the Hexagon library — GREEN as of 2026-08-28
```

Expected output: `Build completed successfully (8746 jobs)` — ZERO `sorry`. As of
2026-08-29 all 40 files are proved (the four early contracts `mul_comm`, `norm_mul`,
`balanced_iff_mem`, `units_closed_under_mul` are all closed). See `INDEX.md` for the
claim→file→status ledger.

## 4. Prover routes (two + one free)

| Route | Config | Use for |
|---|---|---|
| **DeepSeek API** (primary) | `base https://api.deepseek.com`, model **`deepseek-v4-pro`** (or `deepseek-v4-flash` for cheap sketches), key in `proofs/.env` (validated 2026: balance $235.40, models v4-flash / v4-pro / v4-flash-vision-exp) | the real proof work; v4-pro is the model that wrote the ox-alpha proofs |
| **Local Ollama** (fallback, free) | `base http://localhost:11434/v1`, model `qwen3.6` (or `qwen3:14b`); works from the sandbox, no key | proof *sketches* and review when the API is down or you want privacy; note qwen3 models think by default — set `think:false` for terse output |
| **Lean native tactics** (always on) | `by native_decide`, `omega`, `ring_nf`, `aesop`, `exact?` | closes the finite/arithmetic goals by itself — run these BEFORE spending tokens |

## 5. Running the proving agent

From the DeepSeek Harness: spawn a background agent per goal file with the prompt
in `AGENTS.md`, input = the `.lean` file with `sorry` placeholders, output written
to `proofs/results/<file>.out`. Human verifies invariants and closes `sorry`s that
the model cannot (repo rule: agents implement, human verifies). First goal to
throw at it: `Hexagon/SevenHex.lean` (T2 — the one-page bijection, already
enumeration-proved by hand).

## 6. Guardrails (never cross)

- Hex norm ≠ ring (χ²). The hexagon proofs live in a SEPARATE namespace from the
  rebuild's statistics; no identity may claim `max(|q|,|r|,|s|) = ring`.
- Do not introduce a "hexagonal causal lattice" / light-cone claim (Rung-1 only).
- No quantum-speedup statements (author: "just a suspicion, not a proof").
- Every file keeps its provenance header; `proofs/INDEX.md` is updated on every
  status change (proved / ported / stated-unproved).
