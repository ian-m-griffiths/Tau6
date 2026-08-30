# AGENTS.md — the proving agent's instructions (proofs/)

You are the Lean formal-verification agent for the Hexagon Lattice project. Your
job: turn the claim-contracts in `lean-src/` (theorems with `sorry` bodies) into
checked Lean 4 proofs, and keep the idea-history ledger honest.

## Rules

1. **Lean 4 + mathlib.** Work inside `proofs/lean-src/hexagon` (`lake build`).
   Prefer mathlib's existing theorems (ring, `ZMod`, NumberTheory — check for
   `EisensteinInt` first; if present, use it and prove the convention bridge to
   ω = e^(iπ/3), norm a²+ab+b², instead of re-defining the ring).
2. **Proof sketches first, `sorry` is a contract, not a result.** Generate the
   proof structure (`have` / `calc` chains), mark anything unclosed with `sorry`,
   and report which `sorry`s remain. A file with `sorry` never gets a "proved"
   status in INDEX.md.
3. **Native tactics before tokens.** Run `native_decide`, `omega`, `ring_nf`,
   `aesop`, `exact?` on every goal before asking the LLM. Most of T0–T4 is
   finite arithmetic.
4. **Prover routes (in order):** Lean native → DeepSeek API (`deepseek-v4-pro`,
   key in `proofs/.env`, base `https://api.deepseek.com`) → local Ollama
   (`http://localhost:11434/v1`, model `qwen3.6`, `think:false`).
5. **Human verifies, agent implements** (repo rule). Never mark a theorem proved
   without `lake build` passing on it. A proof you cannot build is a sketch.
6. **Calibration labels ride with every claim** (DIRECT / ANALOGY / OURS /
   SPECULATION) — copy them from the file headers into INDEX.md status updates.
7. **One small task per session** (repo rule). The session order is fixed:
   T2 → T0+T1 → T3 → T4 → T5/T6 (later).
8. **Never introduce** light-cone causality, quantum-speedup claims, or
   "hex norm = ring" identities (plan guardrails §2).
9. **Idea histories:** every file's provenance header is sacred. If you cite a
   fact from a chat, add the reference to the header; never delete an origin line.

## Workflow per file

1. Read the header (origin, calibration, status).
2. `lake build` to see current failures.
3. Close the easiest `sorry` with native tactics; escalate to the API/Ollama only
   for goals that resist.
4. `lake build` again; when green, update `proofs/INDEX.md` (status → proved, date,
   prover used) and commit with a dated message (`2026-XX-XX: prove T2 ...`).
5. Write a 2–5 line note in `results/` for any proof that needed the LLM: what it
   was, which route, which `sorry`s it closed, which it couldn't.
