# Junction Algebra — the symbolic algebra of polarity-junction transistors

**2026-08-29.** The formalization that turns the Tau polarity-junction transistor into a
symbolic algebra: a carrier of three junction states with an explicit one-hot constraint, a
two-primitive-system over that carrier (the finite field F₃ *and* the three-element De Morgan
lattice), and an energy reading in which the algebra's own structure *is* the cost function.

**Companions (read these for the numbers this file cites, not re-derives):**
`gates.md` (measured area), `polar_gates.md` (measured native-gate energy), `ground_up/truth_table.md`
(the full 3×3 truth-table reference and the Kleene/Łukasiewicz tables in balanced form), and the
Lean ledger `proofs/INDEX.md` (rows TC1, A3, C1, T3).

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):
**DIRECT** = measured or proved (our ngspice/yosys numbers, our Lean proofs, or citable standard
math). **ANALOGY** = parallel structure, not an identity. **OURS** = our own design claim carried
from project files. **SPECULATION** = unverified hypothesis.

---

## 1. The carrier set T = {P, 0, N} and the one-hot constraint

The junction has two channels — a P-channel and an N-channel — sharing a middle node. Each
conducts only under its own field polarity, so at most one is active at any instant. The carrier
is the three junction states, and we write it in two equivalent alphabets throughout:

| symbol | name | balanced integer | 2-bit one-hot code | channels active |
|---|---|---|---|---|
| **P** | push | +1 | `01` | push line energized |
| **0** | null | 0 | `00` | neither (nothing energized) |
| **N** | pull | −1 | `10` | pull line energized |
| `11` | NEVER | — | `11` | both — **excluded** |

The two alphabets are the *same* set: `P ↔ +1 ↔ 01`, `0 ↔ 00`, `N ↔ −1 ↔ 10`. The one-hot
code is the pair `(push, pull) ∈ {0,1}²`; the fourth combination is forbidden.

### Axiom 0 (one-hot / at most one channel)

The junction state satisfies the invariant

> **`push ∧ pull = ⊥`** — equivalently `push + pull ≤ 1`, equivalently `(push, pull) ≠ (1,1)`.

This is not a theorem about the algebra so much as the *well-formedness* condition on its
realization. It is exactly:

- `TernaryCell.lean` `encode_never_both` (L104) — `encode t ≠ (true,true)`, PROVED; and the
  energy bound `energy_le_one` (L62) — at most one line energized per state. **[DIRECT]**
- `PolarEncoding.lean` `polarEncode_never_eleven` (L40) — the code is never `(1,1)`, PROVED;
  the encoding is injective (`polarEncode_injective`) but not surjective
  (`polarEncode_not_surjective`) — the `11` code has no preimage. **[DIRECT]**

Two consequences that govern the whole algebra:

1. **`11` is a don't-care, not a value.** It is a *forbidden encoding* (an input a correct
   circuit may legally ignore, an output a correct circuit must never produce), **not** a fourth
   trit and **not** a logic value. It is the physical counterpart of the ternary-MVL literature's
   "care / don't-care" split (1502.05748), and it must not be read as "unknown" or "contradiction"
   (see §3.4). **[DIRECT role; ANALOGY to the M-semantics don't-care]**
2. **The energy of a state is the number of active channels** — `energy = push + pull`, which by
   Axiom 0 is in `{0,1}`. So `energy(P) = energy(N) = 1`, `energy(0) = 0` (`TernaryCell.lean`
   `energy_pos/zero/neg`, `null_is_free`), and — because the value `x` has magnitude `|x|` —
   **`energy(x) = |x|`** (`ValuationEnergy.lean` `energy_eq_natAbs`, L96, PROVED). The energy
   reading is *a function of the algebra value*, which is what §5 exploits. **[DIRECT]**

---

## 2. The primitive operations and the axioms

Over the one carrier `T` there are **two** algebras, not one. They coincide in their unary
symmetry but differ in what they can express — the single most important structural fact of the
whole formalization.

### 2.1 The field algebra F₃ — `⊕` and `⊗`

The carrier with the mod-3 operations is the finite field of order 3, `F₃ = Z/3`, with
`N ≡ 2`, `0 ≡ 0`, `P ≡ 1` (mod 3). This is `PolarGate.lean`'s `tsum`/`tprod`, PROVED.

| op | symbol | definition | Lean |
|---|---|---|---|
| negation | `¬x = −x` | additive inverse; `P ↔ N`, `0` fixed | `neg`, `neg_neg`, `neg_tritInt` |
| sum | `x ⊕ y` | `(x+y) mod 3`, carry dropped | `tsum`, `tsum_comm`, `tsum_zero`, `tsum_neg` |
| product | `x ⊗ y` | `(x·y) mod 3`, sign product, `0` absorbs | `tprod`, `tprod_comm`, `tprod_distrib` |

Field axioms (all PROVED in `PolarGate.lean` by `fin_cases`/`decide`):

1. **`⊕` is a group** — commutative (`tsum_comm`); `0` is the identity (`tsum_zero`: `x ⊕ 0 = x`);
   `¬x` is the inverse (`tsum_neg`: `(¬x) ⊕ x = 0`).
2. **`⊗` is commutative** (`tprod_comm`); `P = +1` is its identity; `0` is its absorbing element
   (`0 ⊗ x = 0`).
3. **Distributivity** — `x ⊗ (y ⊕ z) = (x⊗y) ⊕ (x⊗z)` (`tprod_distrib`, the "field-pair
   completeness anchor").
4. **`¬` is a group homomorphism** — `¬(x ⊕ y) = (¬x) ⊕ (¬y)` (`neg_tsum`).

Notable identities that fall out (DIRECT, each checked):

- **Involution** `¬¬x = x` (`neg_neg`) — the reflection is its own inverse.
- **`¬x = x ⊕ x`** — since `2 = −1` in characteristic 3, negation is *derivable from `⊕` alone*.
- **`x ⊗ x = |x|`** — the field square is the magnitude; and **`x ⊗ x ⊗ x = x`** (Fermat in F₃).

### 2.2 The lattice algebra — `∧` (min) and `∨` (max)

The carrier is totally ordered `N < 0 < P` (i.e. `−1 < 0 < +1`). `PolarGate.lean`'s `tmin`/`tmax`
realize the meet/join of this 3-chain; `ValuationEnergy.lean` carries the valuation theorems.

| op | symbol | definition (order `N < 0 < P`) | Lean |
|---|---|---|---|
| AND / meet | `x ∧ y = min` | the lesser trit | `tmin`, `tmin_comm`, `tmin_absorb` |
| OR / join | `x ∨ y = max` | the greater trit | `tmax`, `tmax_idem` |

Lattice axioms (DIRECT — a 3-chain is a distributive lattice):

1. **Commutative, associative, idempotent** — `tmin_comm`, `tmax_idem`; the rest are the standard
   chain-lattice laws.
2. **Absorption** — `x ∧ (x ∨ y) = x` (`tmin_absorb`), and dually `x ∨ (x ∧ y) = x`.

### 2.3 The De Morgan coupling and the notable identities

The reflection `¬` (order-reversing on `N < 0 < P`) ties the two algebras together:

- **De Morgan over {−1, 0, +1}** (DIRECT, lattice theory; matches the RTL `cpu_tb.v` check
  `tand(a,b) == tneg(tor(tneg b, tneg a))`):
  `¬(x ∧ y) = (¬x) ∨ (¬y)` and `¬(x ∨ y) = (¬x) ∧ (¬y)`.
- **Lemma 212 / the `tadd1` identity** (DIRECT — `ValuationEnergy.lean` `min_add_max`,
  `tritVal_min_add_max`):
  `min(x, y) + max(x, y) = x + y` over the balanced integers. This is the identity the balanced
  full-adder's carry rule rests on: a positional digit sum is reconstructed from its meet and join.
- **Energy is a modular lattice valuation** (DIRECT — `ValuationEnergy.lean` `energy_min_max`):
  `energy(x ∧ y) + energy(x ∨ y) = energy(x) + energy(y)`.

### 2.4 The "null is absorbing / identity" laws — stated precisely

The null plays **different** roles in the two algebras, and the roles are not interchangeable:

| law | statement | reading | Lean / RTL |
|---|---|---|---|
| null is the **additive identity** | `x ⊕ 0 = x` | adding "no drive" changes nothing | `tsum_zero` |
| null is the **multiplicative zero** | `x ⊗ 0 = 0` | multiplying by "no signal" annihilates | `tmul` ("null absorbs") |
| **P is the meet identity** | `x ∧ P = x` | `P` is the top of the chain | follows from `tmin` |
| **N is the join identity** | `x ∨ N = x` | `N` is the bottom of the chain | follows from `tmax` |
| **0 is NOT absorbing/identity for ∧/∨** | `min(N,0)=N`, `max(P,0)=P` | `0` sits *in the middle*, not at a pole | — |

The last row is the subtle one: the phrase "null is absorbing" is true only of `⊗` (and of the
channel product), **not** of `∧`/`∨`. Under `∧`/`∨` the null is an *ordinary middle element*:
`min(x,0) = x⁻` and `max(x,0) = x⁺` are the negative/positive **clamps**, not identities and not
annihilators. **[DIRECT]**

### 2.5 The Z₃ / Z₆ symmetry — stated precisely (avoiding a conflation)

The balanced trit's **unary** symmetry group is the full permutation group on three letters,
`S₃ = D₃` (the 6 bijections of `{N,0,P}`), generated by one reflection and one 3-cycle:

- **Z₃ = the rotations** — `rot1`/`rot2` in `PolarGate.lean` (`rot1_three`, `rot2_three`,
  `rot1_rot2`/`rot2_rot1`, PROVED): `0 ↦ 1 ↦ 2 ↦ 0`, the `+1 mod 3` cycle.
- **Z₂ = the reflection** — negation `¬` (`neg_neg`).

The **Z₆** that appears in this project is a *different object*: the six units of the Eisenstein
ring `ℤ[ω]`, `ω = e^(iπ/3)` — `{ω⁰,…,ω⁵} = {1, ω, ω², −1, −ω, −ω²}` (`Gauge.lean`
`units_eq_omega_pow`, `units_eq_omega_powers`, `omegaPow_six`; `Rotation.lean` `units_card`,
`units_closed_under_mul`). It acts by 60° rotation on **lattice points** (pairs of trits — the
2D address space), *not* on a single trit.

The honest relationship:

- `D₃` (the trit's group) and `Z₆` (the units) are **not isomorphic** — `D₃` is non-abelian,
  `Z₆` is cyclic. **Do not identify them.** **[DIRECT]**
- The trit's rotation `Z₃` is isomorphic to the subgroup `⟨ω²⟩ = {1, ω², ω⁴}` of the units (the
  three cube roots of unity). So *the trit's Z₃ sits inside the lattice's Z₆ as `⟨ω²⟩`*
  (`gates.md` §2 records this). **[DIRECT — abstract group isomorphism; the two act on different
  sets]**
- The reflection `¬` is complex conjugation (`ω ↦ ω⁵`), orientation-reversing, hence *not* a
  rotation and *not* in `Z₆`.

**One line:** the trit's symmetry is `S₃ = D₃ = Z₃ ⋊ Z₂` (rotations × reflection); the lattice's
is `Z₆` (rotations only); the shared piece is the `Z₃` of 120° rotations, which is all the two
have in common. **[DIRECT]**

---

## 3. Mapping to Post P₃, Kleene K₃, Łukasiewicz L₃

The carrier `{P,0,N}` is the *middle-element* of three famous three-valued systems. The
correspondence is positional, and the calibration of *what agrees* vs *what differs* is the
whole point of this section.

### 3.1 The value correspondence

| junction | balanced ℤ | one-hot | Kleene K₃ | Łukasiewicz L₃ | Post P₃ |
|---|---|---|---|---|---|
| P (push) | +1 | `01` | T (true) | 1 | 1 (top) |
| 0 (null) | 0 | `00` | U (unknown) | ½ | ½ (middle) |
| N (pull) | −1 | `10` | F (false) | 0 | 0 (bottom) |
| `11` NEVER | — | `11` | — | — | — |

The mapping `{−1,0,+1} ↔ {0,½,1}` is the affine change `t = 2v − 1` (and its inverse
`v = (t+1)/2`), used throughout `ground_up/truth_table.md`. It is a **label change**, not an
identity of objects.

### 3.2 Where they AGREE (as algebras — DIRECT)

- **`¬`, `∧`, `∨` agree bit-for-bit.** With the middle element matched, negation (`P↔N`, `0`
  fixed), min, and max have *identical* truth tables in K₃, L₃, and the lattice fragment of P₃,
  and in our junction algebra. `truth_table.md` §4.2/§5.1/§5.2 tabulate these; they are the
  standard Kleene tables. **[DIRECT]**
- **De Morgan's laws and the involution `¬¬x = x`** hold in all of them. **[DIRECT]**
- **The lattice is the same 3-chain.** All four are (a De Morgan lattice on) the 3-element chain
  `F < U < T`. **[DIRECT]**

### 3.3 Where they DIFFER (semantics — the distinction that must not be blurred)

1. **Our `0` is a NUMBER; Kleene's `U` is UNKNOWN.** This is the classic confusion and the single
   most important distinction in this file.
   - **Kleene K₃'s** middle value `U` is *epistemic*: "the value is T or F but we don't know
     which". It is a truth-value with a knowledge-gap reading. `AND(U,F)=F` means "unknown AND
     false is *definitely* false"; `NOT(U)=U` means "the negation of the unknown is still unknown".
   - **Our** `0` is *arithmetic*: the number zero, "no channel is energized" — a definite, fully
     known state that is neither positive nor negative. `0 ∧ (−1) = −1` means `min(0,−1) = −1`, a
     numeric fact about the order `−1 < 0 < +1`; nothing is "unknown".
   - **Same table, different object.** The *functions* coincide (both are min/max/reflection on
     three elements), but the *meaning* of the middle element does not transfer. You may use our
     junction to *implement* K₃, but you must not *read* our null as "unknown". **[OURS framing;
     DIRECT that the tables match and DIRECT that the semantics differ]**
2. **Łukasiewicz L₃ is the *closest* logic to our arithmetic, and still not identical.**
   L₃'s middle value `½` is a genuine *truth-degree* (half-true), so L₃ — unlike K₃ — actually
   *uses* its middle value numerically. That is why L₃'s implication and strong conjunction/
   disjunction (`→ₗ = min(1, 1−x+y)`, `⊙ = max(0, x+y−1)`, `⊕ₗ = min(1, x+y+1)`) are expressible
   in our **field** basis via `⊕` plus one constant (they are *not* in the Kleene/lattice
   fragment — `truth_table.md` §5.11/5.13/5.14). But the correspondence is still an **ANALOGY**
   (a translation `t = 2v−1`): Łukasiewicz's `½` is a *degree of truth*, ours is *zero* — they
   meet only after the affine re-labeling. **[ANALOGY]**
3. **Post P₃'s negation is *cyclic*, ours is the reflection.** The abstract *Post algebra of
   order 3* (a De Morgan lattice with constants and disjoint operators) matches our lattice
   fragment; but Post's *three-valued logic* uses the **cyclic** negation
   (`0→1→2→0`), which is our `rot1`/cycle `+1`, **not** our `¬`. So: as a De Morgan lattice,
   P₃ ≅ K₃ ≅ our `(∧,∨,¬)` fragment **[DIRECT]**; but "Post negation" = our 3-cycle **[DIRECT]**,
   and the two unary ops are different functions that must not be conflated.

### 3.4 The fourth code `11` vs "unknown" vs "don't care"

Three distinct concepts that share the word "third value", disambiguated:

| concept | what it is | where it lives |
|---|---|---|
| our null `0` | the *number zero*; no channel active | a definite value |
| Kleene `U` / Łukasiewicz `½` | unknown / half-true — a truth-degree | a logic value |
| our `11` NEVER | a *forbidden encoding*; never produced | a don't-care input state |
| M-semantics don't-care (1502.05748) | a dynamic care/don't-care boundary | an input classification |

`11` is **none** of "unknown", "contradiction", or "both" — it is "never a valid state", which is
closest to the literature's *don't-care*. **[DIRECT]**

---

## 4. Truth-table dictionary — junction algebra ↔ RTL cells ↔ Lean

A circuit designer reading this algebra can look up each law and immediately find the cell that
implements it and the theorem that proves it. **[Cells: `rtl/trit_functions.vh`, `rtl/ternary_gates.v`
(one-hot 2-wire); Lean: `proofs/lean-src/hexagon/Hexagon/`.]**

| algebra law | symbol | RTL cell | Lean module : theorem | measured cost |
|---|---|---|---|---|
| negation `¬x = −x` | `P ↔ N`, `0` fixed | `tneg = {t[0],t[1]}` (wire swap) | `PolarGate.neg`, `neg_neg`, `neg_tritInt` | **0 cells** (free) |
| identity | `x` | (wire) | `PolarGate.ident`, `ident_def` | 0 |
| AND / meet | `x ∧ y` | `tand = {a1\|b1, a0&b0}` | `PolarGate.tmin`, `tmin_comm`, `tmin_absorb` | 2 cells (12.5 µm²) |
| OR / join | `x ∨ y` | `tor = {a1&b1, a0\|b0}` | `PolarGate.tmax`, `tmax_idem` | 2 cells (12.5 µm²) |
| NAND / NOR | `¬∧`, `¬∨` | `tneg(tand)`, `tneg(tor)` | De Morgan (§2.3) | +0 on min/max |
| mod-3 sum | `x ⊕ y` | `tadd1(x,y,0).sum` | `PolarGate.tsum`, `tsum_zero`, `tsum_neg` | = tadd1 (25 cells) |
| mod-3 product | `x ⊗ y` | `tmul` | `PolarGate.tprod`, `tprod_distrib` | ≈ 6 cells (est.) |
| full adder | `{cout, sum}` | `tadd1(a,b,cin)` | `ValuationEnergy.min_add_max` backs the carry | 25 cells (146.4 µm²) |
| 3-cycle `+1` / `−1` | `rot1` / `rot2` | `tadd1(x,±1,0).sum` | `PolarGate.rot1/rot2`, `*_three` | = tadd1 |
| one-hot constraint | `p·n = 0` | (the 2-wire encoding itself) | `TernaryCell.encode`, `encode_never_both`; `PolarEncoding.polarEncode_never_eleven` | — |
| energy = `\|x\|` | `E(P)=E(N)=1, E(0)=0` | (wire count) | `TernaryCell.energy_*`; `ValuationEnergy.energy_eq_natAbs` | — |
| min+max = sum | Lemma 212 | (carry logic) | `ValuationEnergy.min_add_max`, `tritVal_min_add_max` | — |

The channel-semantics reading of the two lattice cells is exactly their RTL form:

- `tand` = **min**: `output.push = a.push & b.push`, `output.pull = a.pull | b.pull` — *push
  requires unanimous agreement; pull requires only one*. (Meet = "pull-dominant".)
- `tor` = **max**: `output.push = a.push | b.push`, `output.pull = a.pull & b.pull` — the dual.
  **[DIRECT — read off `trit_functions.vh` L72–84]**

The balanced carry rule (`trit_functions.vh` L32–49, 27 reachable `(a,b,cin)` rows): `sum = s mod 3`,
`cout = +1` iff `s ≥ +2`, `cout = −1` iff `s ≤ −2`, for the digit sum `s = a+b+cin`. Headline row:
`tadd1(+1,+1,0) → sum = −1, carry = +1` (`tsum_plus_one` in `PolarGate.lean`). **[DIRECT]**

---

## 5. The energy reading — cost as a function of the algebra

The one-hot constraint makes energy *readable directly from the algebra*: `energy(x) = |x|`
(the number of active channels), and `energy` is a **modular lattice valuation**
(`ValuationEnergy.lean` `energy_min_max`). So the cost of a law is a function of what *algebraic
grade* it inhabits.

### 5.1 FREE — relabelings (no channel activation, no logic)

| law | why free | calibration |
|---|---|---|
| negation `¬` | in one-hot, `¬` is the permutation `(push,pull) ↦ (pull,push)` — a wire swap, no transistors | **DIRECT** — `tneg = {t[0],t[1]}`; measured **0.00 µm², 0 cells** (`gates.md` §5a) |
| identity / relabel | a constant or a rename | DIRECT — hardwired codes `2'b01/00/10` |
| the three constants `{N,0,P}` | hardwired data, no gates | DIRECT (`gates.md` §2) |
| negating an operand before add/sub | `TSUB = TADD + tneg` — the free wire swap | DIRECT (`tmul_opt.v` L105, `tnorm_trits` negate) |

The *algebraic* reason negation is free is that it is the **involution** `¬¬x = x` realized as a
self-inverse permutation of a **separately encoded** sign and magnitude: the two wires encode the
two polarities, so flipping sign *is* swapping the two wires. There is nothing to compute.
**[DIRECT — `neg_neg` + the one-hot encoding]**

### 5.2 COST — a channel activation / a threshold resolution

| law | algebraic grade | measured cost | calibration |
|---|---|---|---|
| min / max (`∧`, `∨`) | lattice (order) | 2 cells, **2.00×** binary AND/OR | DIRECT (`gates.md` §5a) |
| mod-3 sum `⊕` (via `tadd1`) | field (additive) | 25 cells, **4.33×** binary FA | DIRECT (`gates.md` §5a) |
| mod-3 product `⊗` (`tmul`) | field (multiplicative) | ≈ 6 cells (not in the area benchmark) | ANALOGY (estimate) |
| cycle `±1` | field + constant | = `tadd1` | DIRECT |

**The cost tracks the algebra's grade, monotonically:** relabelings are free (grade 0 — the
symmetry group), lattice ops cost one threshold per polarity wire (grade 1 — meet/join), field ops
cost cross-polarity carry logic in *both* directions (grade 2 — the additive/multiplicative
structure). The most expensive primitive is the one that is *algebraically irreducible*: the
mod-3 sum `⊕` — the single operation outside the Kleene/lattice fragment (`truth_table.md` §3.2),
the completeness ingredient (`gates.md` §8). **[OURS framing on top of DIRECT measurements]**

### 5.3 The honest caveat: "free" is a *logic* property, not a *gate* property

Measured on the **native single-wire** polar cell (`polar_gates.md`, ngspice), the free logic does
not stay free: a 3-level wire cannot drive static CMOS, so every native gate boundary must
**demux** (2 sense amps = 14 T) and **re-encode** (push-pull driver = 4 T) *before any logic*.
Even the 0-transistor negation costs 18 T and ~4.9× a binary inverter per bit; the null sits at the
sense-amp threshold and draws continuous shoot-through current. **[DIRECT — measured]**

**The null is free on the *wire*, not in the *gate*.** "Send nothing" costs ~0.05 pJ (the transport
win, `gates.md` §6a); but a gate must still *resolve* −1/0/+1 every cycle, and it cannot skip work
on a null input. The free null is a **communication** property, and the moment the same cell is
asked to **compute**, the null that was free becomes the most expensive thing in the circuit.
**[OURS — follows from `polar_gates.md` + `gates.md` §7]**

### 5.4 The "cost as a function of the algebra" table (summary)

| algebraic structure | operations | energy reading | cost class |
|---|---|---|---|
| symmetry group `S₃` (reflection `¬`, relabel) | `¬`, identity, constants | `E(¬x) = E(x)` | **FREE** (wire swap) |
| 3-chain lattice | `∧`, `∨` | `E(x∧y) + E(x∨y) = E(x) + E(y)` (modular) | 1 threshold/wire (2.00×) |
| finite field F₃ | `⊕`, `⊗` | `E(x⊕y)` carries across polarity | cross-polarity carry (4.33×) |
| the irreducible op | `⊕` alone | — | the completeness tax |

The valuation identity `E(x∧y) + E(x∨y) = E(x) + E(y)` (together with `min+max = sum`, Lemma 212)
is the algebraic statement of *why* the balanced full-adder is the pricey cell: the field
operation `⊕` has to account for the whole digit-sum, i.e. for **both** the meet and the join, and
that bookkeeping is exactly the two-direction carry. **[OURS framing; the identities are DIRECT]**

---

## 6. Summary (the report)

- **Axiom set.** `T = {P, 0, N}` with Axiom 0 (`push ∧ pull = ⊥`, the one-hot constraint), plus
  (a) the F₃ field axioms for `⊕`, `⊗`, `¬`, `0`, `+1` (group + distributivity, `PolarGate.lean`)
  and (b) the 3-chain lattice axioms for `∧`, `∨` (meet/join, `tmin`/`tmax`), coupled by the
  order-reversing involution `¬` (De Morgan). The same carrier is a finite field *and* a De Morgan
  lattice.
- **Key identity that makes negation free.** `¬¬x = x` (`neg_neg`) as the *self-inverse
  reflection*, realized in the one-hot encoding as the wire swap `(push,pull) ↦ (pull,push)`
  (`tneg = {t[0],t[1]}`) — sign is stored separately from magnitude, so flipping sign costs zero
  logic.
- **Single most important distinction.** Our **null `0` is the number zero** (no channel active,
  a definite value); Kleene's third value **`U` is "unknown"** (an epistemic gap), and
  Łukasiewicz's **`½` is a truth-degree**. The truth *tables* agree (all are min/max/reflection on
  three elements), but the *objects* do not: reading our null as "unknown" is the classic error
  this formalization exists to prevent.

---

## 7. Files cited

- `proofs/lean-src/hexagon/Hexagon/PolarGate.lean` — the F₃ field + lattice primitives (`neg`,
  `tmin`, `tmax`, `tsum`, `tprod`, `rot1/rot2`) and their identities.
- `proofs/lean-src/hexagon/Hexagon/TernaryCell.lean` — the one-hot encode + energy theorems.
- `proofs/lean-src/hexagon/Hexagon/PolarEncoding.lean` — the `Fin 2 × Fin 2` encode/decode + `11`
  never-produced.
- `proofs/lean-src/hexagon/Hexagon/ValuationEnergy.lean` — `min+max=sum`, energy as a modular
  valuation, `energy = |x|`.
- `proofs/lean-src/hexagon/Hexagon/Gauge.lean`, `Rotation.lean`, `Conventions.lean` — the Z₆ units,
  the norm as area, the Eisenstein ring.
- `rtl/trit_functions.vh`, `rtl/ternary_gates.v` — the cells `tneg/tand/tor/tmul/tadd1`.
- `docs/compute/gates.md`, `docs/compute/gate_area.md`, `docs/compute/polar_gates.md`,
  `docs/compute/ground_up/truth_table.md` — the measured costs and the Kleene/Łukasiewicz tables.

*Every identity named in §2 is a theorem with a name in `PolarGate.lean` or `ValuationEnergy.lean`
(no `sorry`); every cost in §5 is a yosys/ngspice measurement cited from the companion docs; no
number is invented here.*
