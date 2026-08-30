# Prover Notes — what Lean made easy, and the patterns that work

Lived notes from formalizing the Eisenstein-lattice core (2026-08-28). Append-only,
like everything else in this project.

## The one big realization (why this feels easy)

**Lean's typechecker is the guide rail.** A proof is a program; `lake build` checks it.
When something is wrong, you get a *precise* message (line, goal, what's missing) — no
silent wrong behavior. Code (Rust) defers correctness to tests you have to invent; **the
proof is the test**. That's the difference between "days figuring out how it works" and
"relatively simple guide rails": the feedback loop is instant and total.

The Rust mirror (`../rust-mirror/`) then gets the *performance*, because Lean's job is
correctness, not speed. Check in Lean, run in Rust — exactly the split you described.

## The design bug the prover caught (would have silently shipped in code)

`Eisenstein` was an `abbrev` for `ℤ × ℤ`. That silently inherited the *componentwise*
product ring, where `(1,0)·(0,1) = (0,0)` — **zero divisors**. Our ω-multiplication
`(a+bω)(c+dω) = (ac−bd) + (ad+bc+bd)ω` is a *different* ring on the same carrier. Code
would have happily compiled both and you'd never notice the wrong `*`. The prover forced
a `structure` (distinct type) so the ring's `*` is unambiguous. **This is the concrete
"prover > code alone" win.**

## Tactical patterns (so the next person/agent doesn't rediscover them)

Working, in this mathlib (v4.33.1):

- **Finite arithmetic** → `fin_cases h <;> ... <;> decide` (e.g. the 7-hex↔ternary
  bijection, the Z₆ units table). `decide` also proves `Finset.card` equalities.
- **Polynomial identities over ℤ** → `ring` / `ring_nf` (use `ring_nf` when `^` appears).
- **`|a+b| ≤ |a|+|b|`** → `abs_add_le` (NOT `abs_add` — that name doesn't exist here).
- **`|a-c| = |(a-b)+(b-c)|`** → `congrArg abs (by ring)` (`ring` can't see through `abs`).
- **`(√3)² = 3`** → `have h3 : (Real.sqrt 3)^2 = (3:ℝ) := Real.sq_sqrt (by norm_num)`
  then `nlinarith [h3]`.
- **`|x| ≤ 1/2` → `x² ≤ 1/4`** → `abs_le.mp` (get `-1/2 ≤ x ∧ x ≤ 1/2`) then `nlinarith`.

Gotchas (cost real time):

- **`ring`/`ring_nf`/`dsimp` will NOT unfold a *custom* `Mul`/`Add` instance on a
  structure.** They see `(x * y).a` as an opaque atom. Fix: `rcases` the operands, then
  `change Eisenstein.mk <explicit ℤ components> = Eisenstein.mk <...>`, then `ext <;> ring`.
- **`ofReal` distributes over `+`** under `simp`, breaking `Complex.normSq_add_mul_I`
  pattern matches. Needs an explicit `change`/`simpa` route (or the pure-ℝ route).
- **A `def mk` collides with a `structure`'s auto-generated `mk`.** Don't redefine it.
- **`abbrev` vs `structure`:** `abbrev` keeps the underlying type's instances (and their
  WRONG semantics for a custom operation). Use `structure` for a genuinely new object.
- **`norm` is ambiguous** (`Eisenstein.norm` vs the `‖·‖` notation) — write it qualified.

## The math conventions (lock these in)

- `ω = e^(iπ/3)`, `ω² = ω − 1`; `N(a+bω) = a² + ab + b²`; units = Z₆ = `±1, ±ω, ±ω²`.
- Conjugate `a+bω̄ = (a+b) − bω` (since `ω̄ = 1−ω`).
- **Covering radius of the hex lattice = `1/√3 < 1`** — this is *why* ℤ[ω] is a Euclidean
  domain (and thus a UFD). The rounding lemma `exists_near_int_pair` proves every plane
  point is within norm `< 1` of a lattice point (tight bound is `3/4`).
- **τ, not π** (Ian): `τ = 2π`, the full turn. Hex packing density `τ/(4√3) = π/(2√3)`.
- **Counts, not probabilities** ("absolute math"): stay in the counting measure (integers);
  ratios/geometry appear only at the display boundary.

## Done + gotchas from the parallel theorem agents (2026-08-28)

T4 (graph distance), T5 (CommRing + EuclideanDomain → UFD), Gauge (isotropy), and
Residual (rebuild identities) are all PROVED by parallel subagents. Gotchas they
surfaced (add to the list above):

- `simp [norm]` / `rw [norm]` collides with mathlib's `Norm.norm` → always write
  `Eisenstein.norm` (fully qualified).
- `field_simp` then `ring` fails on ℤ-cast polynomials → insert `push_cast` between them.
- `dsimp` won't reduce `if`s from context → use explicit `rw [if_pos h]` / `if_neg h`.
- `Std.Symm` / `Std.Irrefl` (SimpleGraph fields) take explicit binders; `Walk.rec`'s
  vertex binders are implicit.
- `simp [Matrix.det_fin_two]` silently does NOT apply → `rw` first.
- `Finset.sum_div` is stated `(∑f)/a = ∑(f/a)` → rewrite with `←`.
- `Nat.cast_sum` needs explicit `(s) (f)` args before `.symm`.
- Prefer an instance-free `omegaPow : ℕ → Eisenstein` over a `Pow` instance (avoids a
  later clash with the `Monoid`-derived `Pow` from `CommRing`).
- **`deriving Fintype` is BROKEN in this toolchain** (v4.33.1 + mathlib): the generated
  instance is ill-typed (`List.Nodup` supplied where `Multiset.Nodup` is required). Work
  around with an explicit `instance : Fintype T := ⟨{.a, .b, .c}, by intro x; cases x <;> simp⟩`.
- `rw [if_pos h]`/`rw [if_neg h]` fail on `if` conditions with unreduced `Fin` constructor
  projections and on dependent branches — use `simp [f, h]` or `dif_pos`/`dif_neg`.
- **No `∑ x in s` notation in this mathlib (v4.33.1)** — use `∑ x ∈ s, f x`.
- **A same-namespace redeclaration is rejected** — e.g. `Lattice.surprise` already existed
  in Registers.lean, so a new `surprise` in the same namespace must be renamed.
- **Plain `def`s are semireducible** → typeclass synthesis won't unfold them: `if p then ..`
  on a custom `def` predicate can't synthesize `Decidable`, and `by decide` fails on a goal
  headed by a custom `def`. Fix: define min/max by `cases`, prove custom-def props with
  `norm_num [defs]`.
- **Watch the ORDER for monotonicity**: `energy` (0 at null, 1 at polarities) is NOT monotone
  in the *balanced* order −1<0<+1 (it runs 1→0→1); it IS monotone in the *cost* order
  (null = bottom). Always sanity-check the order before asserting monotonicity.

## Remaining (not yet formalized)

- T6 geometric derivation + Thue optimality — cite, don't prove (out of scope for now).
- The hex↔u32 address bijection (the SPECULATION that hex addressing replaces the u32
  XOR kernel) — blocked until someone defines the bijection.
