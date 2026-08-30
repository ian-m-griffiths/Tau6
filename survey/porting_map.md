# Porting Map — hexagon lattice (A) ⇄ rebuild (B)

Survey of what is worth PORTING between the two projects, calibrated at mapping time
(DIRECT = same math / ANALOGY = parallel structure / OURS = one side only / SPECULATION =
unproven). Inputs:

- **A** (this workspace): `proofs/INDEX.md`, `proofs/lean-src/hexagon/Hexagon/{Conventions,
  Gauge,EuclideanDomain,Residual,Rotation}.lean`, `rust-mirror/src/eisenstein.rs`,
  `TERNARY_PROCESSOR.md`, `LATTICE_MATH.md` (this workspace copy).
- **B** (rebuild, `/home/ian/opencode/parser/english/`): AGENTS.md canonical-truth section,
  `LATTICE_MATH.md` (workspace copy — B has no root copy), `docs/formal-notation.md`,
  `rust/lattice/src/{gauge.rs, gauge_int.rs, clifford.rs, isa.rs, statistics.rs,
  build/causal.rs, gen.rs}`.

Context that matters: `survey/SYNTHESIS.md` already established that the two projects are a
single thread — B's AGENTS.md "gauge = the unit" note (L2821–2844) and TODO #16
(`ox alpha.md` L3109, "Gauge-int / Eisenstein lattice — integer pair + Signature") are B's
own record of A's hexigon conversation. `gauge_int.rs` IS the TODO #16 proof-of-concept.
So the ports below are mostly *completion* of an already-open bridge, not new invention.

---

## The table

| # | Port candidate | Direction | Calibration | What exactly to port | Where it lands | Why it's worth it |
|---|---|---|---|---|---|---|
| 1 | Mod-6 integer spinor (Z₆) | A → B | DIRECT (A proved) | `Rotation.lean` `angleAdd : Fin 6 → Fin 6 → Fin 6` + `Gauge.lean` `omegaPow`/`units_eq_omega_powers` + rust-mirror `Eisenstein::rotate(k: u8)` (k mod 6, 60° steps, ω⁶=1) — as a `rotate(k: u8)` on `GaugeInt` | `rust/lattice/src/gauge_int.rs` | gauge_int has only single-step `rotate()` (×ω, 120° under its convention) — no mod-6 orbit, no k-step. The Z₆ rotation is the "cheap gauge change" (TROT) and the even-grade fix ψ=(α+βI)U, all integer-only, and A already proved ω⁶=1, unit closure, norm isotropy (`norm_mul_unit`). |
| 2 | Eisenstein `mul`/`norm`/`conj` as integer-only primitives | A → B | DIRECT | `Conventions.lean` mul `(ac−bd, ad+bc+bd)`, norm `a²+ab+b²`, `star = (a+b) − bω`; rust-mirror i64 impl | `rust/lattice/src/gauge_int.rs` (`Signature::Eisenstein`, `mul`, `norm_sq`, `conjugate`) | gauge_int's Eisenstein is the **120° convention** (ω²=−ω−1, N=a²−ab+b²) — see collision C2. Port the 60° form (or an explicit `b ↦ −b` iso bridge) so B's integer Eisenstein matches A's proven one; `norm_mul` (T1, proved) justifies `norm_sq` multiplicativity as fact, not test. |
| 3 | Norm = det of the regular rep (the "area scalar") | A → B | DIRECT (A proved) | `Gauge.lean` `rep` + `norm_eq_det` (N(a,b) = det ![![a,−b],[b,a+b]]), `norm_of_unit` | doc-comment + `TNORM` rationale in `gauge_int.rs` / `isa.rs` / `gauge.rs` | B's gauge.rs calls E the "area" and gauge_int calls norm the "c edge" — both are intuitions; the proven `norm_eq_det` makes "value as its area" a theorem. Underpins TNORM ("N → scalar, Z₆-invariant") as DIRECT math, not a hunch. |
| 4 | TROT / TNORM opcodes | A → B | DIRECT math / SPECULATION as ISA | `TERNARY_PROCESSOR.md` §2.2 TROT (gauge change = ×ω^k, k∈0..5) and TNORM (N(a,b)=a²+ab+b² → scalar) as new `Op`s | `rust/lattice/src/isa.rs` (currently only LKP/FMT/DO/WEDGE/RING/DEC) | The two opcodes with proven math backing: TROT = port #1 as an instruction (angle-add mod 6), TNORM = port #3. Integer-only, 1–2 ALU ops each. Honest calibration: the opcode *encoding* stays a design sketch (TERNARY_PROCESSOR header says SPECULATION by construction); the Z₆/norm underneath is DIRECT. |
| 5 | Euclidean division, round-to-nearest in the (1,ω) basis | A → B | DIRECT math / SPECULATION as ISA | `EuclideanDomain.lean` `Div` instance (componentwise `round` of x·star(y)/N(y)) — the hex-lattice nearest-lattice-point rounding | reference doc for `TERNARY_PROCESSOR.md` TDIV/TMOD (§2.2: "divide, round-to-nearest", "symmetric modulus") | TDIV/TMOD claim "exact symmetric rounding to the balanced digit grid" — that rounding IS T5's quotient. A proved `norm_mod_lt` (remainder shrinks), the exact property a Euclidean TMOD wants. Port the *algorithm + proof reference*, not code. |
| 6 | Honeycomb metric ↔ `Hexagonal` NormForm | A → B | DIRECT | `Rotation.lean` `hexDist` (cube max-norm on q+r+s=0) with proved triangle inequality; `NormForm::Hexagonal = max(\|a\|,\|b\|,\|a+b\|)` is the same object restricted to the plane (s = −q−r) | property test + doc in `gauge_int.rs` | B's Hexagonal norm is A's T4 metric in 2D; A proved it is a metric (self/comm/triangle). Gives the NormForm a proved basis and a stronger test (mirror `hex_dist_metric` from rust-mirror). |
| 7 | Register ladder raw/fold/z/surprise + δ = O/E − 1 invariant | B → A | DIRECT | `gauge.rs` `Register` kp-pairs: raw = E·δ, fold = δ, z = E^(1/2)·δ, surprise = E·δ², δ = O/E − 1. Theorems: `r = E·δ`; surprise sign-collapse `surprise(−δ) = surprise(δ)`; scale-invariance `δ(cO,cE) = δ(O,E)`; `raw(cO,cE) = c·raw` | NEW `proofs/lean-src/hexagon/Hexagon/Registers.lean` (+ INDEX.md rows) | Locks the rebuild's single invariant in the ledger. The "the −1 in O/E−1 is the gauge normalisation" claim (gauge.rs L12–18) becomes a theorem; the sign-flip `E−O = −E·δ` is a corollary. Residual.lean has E and r already — this completes the ladder over ℚ. |
| 8 | Gauge transform table closure ("PROVE-THE-MATH #3") | B → A | DIRECT with caveat | `gauge.rs` `transform`/`delta_from`: prove transform(a→b→c) = transform(a→c) **on the sign-preserving registers** {Raw, Fold, Z}; prove Surprise is NOT injective (δ and −δ collide) so full-group closure fails | `Hexagon/Registers.lean` | gauge.rs's own test marks this "flagged as untested" and skips negative δ. Lean settles it: closure holds exactly on sign-preserving chains; the Surprise exception is the theorem's hypothesis, not a hack. Refines a claim B ships today. |
| 9 | Wedge = r_ab − r_ba (E cancels) + polarization skew | B → A | DIRECT | `statistics.rs` L11–13 comment: E is symmetric so wedge reduces to residual difference — formalize `(O_ab − E) − (O_ba − E) = O_ab − O_ba`; plus `polarization(a,b) = −polarization(b,a)` | extend `Hexagon/Residual.lean` | Residual.lean already has `wedge_antisymm`; the E-cancel identity is the missing 2-line lemma that B's whole `edge_stats` reconstruction depends on (it computes wedge from stored residuals only). Polarization skew is the third axis's one provable property. |
| 10 | Cross-gauge sums don't commute (GaugeSum) | B → A | DIRECT | `gauge.rs` `GaugeSum` claim: Σ Eᵢδᵢ ≠ Ē·Σδᵢ in general; equal iff E constant — formalize as a counterexample over ℚ | `Hexagon/Registers.lean` | The design rationale for "the gauge ID travels with the sum" (gauge.rs L28–31). A counterexample proof makes the non-commutation a theorem and pins down *when* it fails (non-constant E), which is the exact condition B's builders hit. |
| 11 | `surprise ≡ correlation²` | B → A | DIRECT | `statistics.rs` `surprise = r²/E`, `corr = r/√E` ⇒ `surprise = corr²` (trivial `ring`) | fold into #7 `Registers.lean` | One `ring` proof; ties the χ² register to the correlation register B already proves nonneg in `ringSq_nonneg`. |

---

## Do these first (top 3)

1. **B→A: `Hexagon/Registers.lean` (#7+#8+#10+#11)** — the register ladder, δ-invariance,
   and the transform-closure theorem with the Surprise caveat. Highest value-per-proof:
   it settles B's own "PROVE-THE-MATH #3 / flagged as untested" (gauge.rs L223–254), locks
   the rebuild's core invariant into the ledger, and needs only `ring`/`field_simp`-level
   tactics over ℚ. Update `proofs/INDEX.md` with new R2–R4 rows.
2. **A→B: align `gauge_int.rs` Eisenstein (#2+#1)** — resolve the 60° vs 120° divergence
   (add the `b ↦ −b` iso or adopt the 60° form), add `rotate(k mod 6)`, and cite the Lean
   theorems (`norm_mul`, `norm_eq_det`, `units_eq_omega_powers`) in doc comments. This is
   the one port that fixes an existing name collision in code, not just in prose.
3. **A→B: `TROT` + `TNORM` in `isa.rs` (#4)** — two new integer-only ops with proven math
   backing, ~30 lines. Do NOT add HEXLD/HEXST/NEIGH yet — they need the hex↔u32 address
   bijection (blocked, see D-list).

## Don't port (collisions / speculation)

- **D1 "hex norm = ring"** — explicitly FORBIDDEN by `proofs/AGENTS.md` guardrail 8. B's
  `ring = Σ(O−E)²/E` is a residual χ² norm; A's N(a,b) is an area form. Do not equate.
- **D2 Hex↔u32 address bijection / "hex replaces the XOR kernel"** — SPECULATION, BLOCKED
  in `INDEX.md` ("needs hex↔u32 address translation theorem first"). Therefore no
  HEXLD/HEXST/NEIGH, and no claim that A's lattice replaces B's `G[i⊕j]` u32 kernel.
- **D3 Minkowski/Null signatures** — A's isotropy theorems cover only the elliptic case
  (Gaussian/Eisenstein); `gauge_int.rs` itself asserts Minkowski's j and Null's ε are NOT
  isotropic. Do not port A's Gauge proofs onto them.
- **D4 Relativistic `c = L1/λ` invariant, quantum-superposition, light-cone causality** —
  retired/speculation in both projects; nothing to formalize, nothing to port.
- **D5 `quadrant` 2-bit sign separation** — trivial bit logic, no theorem content; keep
  OURS in B, don't formalize in A.

## Name collisions / over-claim risks (flagged)

- **C1 "gauge" (THE top collision)** — A: gauge = multiplication by a Z₆ unit (discrete
  rotation, norm-preserving — `Gauge.lean`). B has TWO gauges: `gauge.rs` Register = an R⁺
  scale in powers of E (continuous, δ-invariant — "gauge = register"), and `gauge_int.rs`
  Signature = the unit's multiplication table (A's meaning, per TODO #16). A's "gauge" and
  B's Signature agree; B's gauge.rs Register does NOT. Any sentence like "gauge change is a
  shift" is true for the Register meaning and false for the Z₆ meaning.
- **C2 Eisenstein 60° vs 120°** — A: ω=e^(iπ/3), N=a²+ab+b², star=(a+b)−bω. B `gauge_int`:
  ω=e^(2πi/3), N=a²−ab+b², conj=(a−b)−bω. Isomorphic via `b ↦ −b` but not drop-in code;
  `norm_mul`/`rotate`/`norm_sq` from A must be sign-adjusted before reuse. `Conventions.lean`
  header already anticipates this for mathlib (T-ISO bridge).
- **C3 "wedge"** — three meanings: skew residual O_ab−O_ba (A `Residual.lean` = B
  `statistics.rs`, DIRECT same), Clifford grade-raising blade wedge (B `clifford.rs`
  `wedge()`, different object), retired bivector-area (AGENTS.md). Do not conflate the
  clifford wedge with the residual wedge.
- **C4 "spinor"** — A: mod-6 integer rotation (Z₆). B: float even-grade `Rotor{f32,f32}`
  (`clifford.rs`), integer `GaugeInt` (`gauge_int.rs`), polar spinor `|a||b|(cosθ+I sinθ)`.
  A's spinor ↔ B's GaugeInt intent is the real bridge; clifford's Rotor is the float
  stand-in. Precision and convention differ; port #1 keeps them honest.
- **C5 "register"** — overloaded inside B alone: `gauge.rs` Register enum (4-rung ladder)
  vs LATTICE_MATH.md "Gauge = register = ring shift" (the d>>n exponent). A has no register
  concept; when porting #7 use B's enum meaning and say so.

## Bottom line

The two projects are one thread (SYNTHESIS.md, TODO #16). The ports worth doing are the
ones that *complete the existing bridge*: the integer Eisenstein/Z₆ primitives (A→B, #1–#3,
#6) and the formalized register-ladder invariant (B→A, #7–#11). Everything else is either
already proved on one side, or a SPECULATION the projects jointly guard against (D1–D4).
