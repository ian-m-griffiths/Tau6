# Minimal Functionally-Complete Gate Set for Balanced Ternary — and its Minimal Realization

**2026-08-29 — `docs/TERNARY_GROUND_UP.md` batch 1, item 5 ("minimal set").** Companion to
`../gates.md` (the gate survey this file tightens) and the not-yet-written
`device_circuit.md` (the native 3-state device search; flagged in §6 and the TODO tail).

**Calibration legend (house standard, `docs/MAP_BRIEF.md`):**

- **DIRECT** — measured or proved (our ngspice/yosys numbers, Lean proofs, or a citable
  literature number).
- **ANALOGY** — parallel structure, not an identity (e.g. CNTFET transistor counts ported to
  our device story).
- **OURS** — our design claim, carried from project files (RTL, Lean ledger).
- **SPECULATION** — untested hypothesis, flagged as such.

**One-line answer up front:** the minimal functionally-complete gate set is **two gates —
`{mod-3 sum, mod-3 product}` (our `{tadd1.sum, tmul}`) plus free constants** — and **negation
is NOT a third primitive**: in the field F₃, negation is derivable from the sum alone as
`−x = x ⊕ x` (mod 3). So the three-gate set `{negation, mod-3 sum, mod-3 product}` *reduces* to
two. The completeness is the one-line corollary of **Lagrange interpolation over the finite
field F₃** (every function F₃ⁿ→F₃ is a polynomial in `⊕` and `⊗`), and the minimality is a
two-line argument (neither `⊕` nor `⊗` generates the other; a single 2-input operation is
impossible by Martin 1954). The minimal *realization* is `{tadd1, tmul}` = **2 cells** on our
binary standard-cell flow (measured 146.39 µm² + ≈37 µm²), and **≈85 CNFETs** on the closest
native 3-state device in the corpus (`{⊕, ⊗}` = `{45, 40}` CNFETs, `2211.04542`); the true
single-wire native-device floor is **not yet measured** (`device_circuit.md` is the open batch-1
item that closes it).

---

## 1. The minimal complete set — and the reduction of negation

Balanced-ternary digits `{−1, 0, +1}` are the finite field **F₃** under the relabel
`{−1, 0, +1} ≅ {2, 0, 1} (mod 3)` [DIRECT — `docs/compute/gates.md` §4, §9]. The field
operations are

- **`⊕` (mod-3 sum)** = `a + b (mod 3)`, carry dropped — our `tadd1(x, y, 0).sum`.
- **`⊗` (mod-3 product)** = `a · b (mod 3)` = the sign product with 0 absorbing — our `tmul`.

**Theorem (minimal complete set).** `{⊕, ⊗}` together with the three constants `{−1, 0, +1}`
is functionally complete, and is minimal in this sense: dropping either operation loses
completeness, negation is *derivable* (not primitive), and no single 2-input operation suffices.

**The negation reduction (the headline of this file).** In characteristic 3, `2 = −1`, so
`2x = −x`, and `2x = x + x`. Hence

```
−x  =  x ⊕ x        (mod 3)      [no constant needed]
```

Check in balanced digits (using `tadd1.sum`, the carry *dropped*):

| x | x ⊕ x (mod 3) | carry of x+x | result as balanced digit |
|---|---|---|---|
| +1 | +1 + +1 = +2 ≡ **−1** | +1 | −1 ✓ (negation of +1) |
|  0 | 0 + 0 = 0 | 0 | 0 ✓ |
| −1 | −1 + −1 = −2 ≡ **+1** | −1 | +1 ✓ (negation of −1) |

So **`tneg(x) = tadd1.sum(x, x, 0)`** — the "sum" output of the existing full-adder cell with
both inputs tied to `x`. Equivalently (using the constant `−1`, which is also free):
`−x = x ⊗ (−1)`. **[OURS — direct corollary of the F₃ algebra; the derivation is 3 lines and is
reproduced/verified in §2, but it is *not* yet stated as a Lean theorem in the ledger. It should
be: a 1-line port of `tneg` as a derived, not primitive, cell.]**

Consequence: the naive `{negation, mod-3 sum, mod-3 product}` is **not** minimal — negation
costs one extra `⊕` (or one `⊗` with the constant `−1`), i.e. **zero new primitive gates**. The
only things that must be supplied are the two field operations and the constants. In our
one-hot encoding the constants are *physically free* — `+1 = 2'b01` and `−1 = 2'b10` are
rail ties, `0 = 2'b00` is nothing tied [DIRECT — `docs/compute/gates.md` §2, `rtl/trit_functions.vh`].

**What about `0`?** `0 = x ⊕ x ⊕ x` (since `3x = 0` in F₃), so the zero constant is itself
derivable from `⊕` alone. But **no nonzero constant is derivable from `⊕` and `⊗` alone**: any
polynomial with zero constant term evaluates to 0 at the all-zero input, so the constant `+1`
cannot be synthesized without at least one hardwired nonzero value. **[DIRECT — standard
finite-field algebra, one-line argument; §3.]** In hardware this is a non-issue — one rail tie
supplies `+1`, and `−1 = 1 ⊕ 1` follows.

---

## 2. The completeness argument — Lagrange interpolation over F₃

**[DIRECT — standard finite-field algebra; the theorem and the basis below are textbook
(polynomial functions over F_q are exactly the functions F_qⁿ → F_q, degree ≤ n(q−1)).]**

**Claim.** Every function `f : F₃ⁿ → F₃` is a polynomial in `⊕` and `⊗` with constant
coefficients.

**Step 1 — single variable (n = 1).** Over F₃, `x³ = x` for all `x` (Fermat: `x³ − x =
x(x−1)(x+1) ≡ 0`), so every unary function is a polynomial of degree ≤ 2. The Lagrange basis is

```
δ₀(x) = 1 − x²        = 1 − (x ⊗ x)      (indicator of x = 0)
δ₊(x) = −x² − x       = −(x⊗x) ⊕ (−x)    (indicator of x = +1)
δ₋(x) = −x² + x       = −(x⊗x) ⊕ x       (indicator of x = −1)
```

Verification (computed, digits 0/1/2):

| x | δ₀ | δ₊ | δ₋ |
|---|---|---|---|
| 0 | 1 | 0 | 0 |
| 1 | 0 | 1 | 0 |
| 2 | 0 | 0 | 1 |

Each `δ` is a polynomial in `⊕, ⊗` and constants. Hence any unary `g` satisfies
`g(x) = g(0)·δ₀(x) ⊕ g(+1)·δ₊(x) ⊕ g(−1)·δ₋(x)`.

**Step 2 — n variables.** For a point `a = (a₁,…,aₙ) ∈ F₃ⁿ`, set
`δ_a(x) = ∏ᵢ δ_{aᵢ}(xᵢ)` (a product of the single-variable indicators). Then
`δ_a(b) = 1` iff `b = a`, else `0`, so

```
f(x) = Σ_{a ∈ F₃ⁿ} f(a) · δ_a(x)
```

where the sum is `⊕` and each `δ_a` is a polynomial in `⊕` and `⊗`. ∎

**Why this is "the same as binary, one field up."** Binary completeness `{XOR, AND}` is exactly
this theorem over **F₂** (where `x² = x`, so the interpolation degree collapses and every
function is a Zhegalkin polynomial). Ternary completeness `{⊕, ⊗}` is the theorem over **F₃**.
Same one-line structure, three values. This is the formal reason the "natural" ternary
`{min, max, neg}` is *not* the twin of binary `{AND, OR, NOT}`: min/max generate the
*lattice* fragment (monotone in the order `−1 < 0 < +1`), which cannot produce the cyclic /
field structure that interpolation needs — the field pair `{⊕, ⊗}` is the actual twin.
**[DIRECT — `docs/compute/gates.md` §4; the incomplete-lattice point is its core correction.]**

---

## 3. Minimality — why exactly two operations, and no Sheffer stroke

Four separate facts pin the set down to exactly `{⊕, ⊗} + constants`. **[All DIRECT —
standard clone theory / finite-field algebra, except where flagged OURS.]**

1. **`⊗` is not derivable from `⊕`.** The functions generated by `⊕` and constants are the
   *affine* forms `c₀ ⊕ c₁x₁ ⊕ … ⊕ cₙxₙ`. The quadratic `x ⊗ y` is not affine, so `⊗` is
   outside that clone. Drop `⊗`, lose completeness.

2. **`⊕` is not derivable from `⊗`.** With `⊗` and constants you get only *monomials*
   `c · x₁^e₁ ⋯ xₙ^eₙ` (no way to *add* two monomials without `⊕`). A monomial `c·x^a·y^b`
   evaluates to `c` at `(1,1)` and `c` at `(1,0)` unless `b=0` — but `x ⊕ y` evaluates to `2`
   at `(1,1)` and `1` at `(1,0)`. Contradiction. Drop `⊕`, lose completeness.

3. **One nonzero constant is required** (the "vanishes at origin" argument of §1). Constants
   are physically free, so this does not add a gate, but it must be stated for honesty.

4. **No single 2-input operation can replace the pair.** For radix ≥ 3 there is **no binary
   (2-ary) Sheffer function** — a single binary operation whose clone is the full clone does
   not exist. [DIRECT — Martin 1954, *The Sheffer functions of 3-valued logic*, JSL 19:45–51;
   cited in `docs/compute/gates.md` §4.] Hence *at least* two primitives are forced, and
   `{⊕, ⊗}` is a two-element complete set. (Sheffer functions *do* reappear at higher arity —
   e.g. a ternary majority/median or the 3-input "consensus-plus" of the MVL literature — but
   those are **more** expensive per gate than the field pair, so they are not "minimal
   realization".)

**Net:** the minimal complete set is **`{mod-3 sum, mod-3 product} + (free) constants`**, with
negation derived as `x ⊕ x`. This matches and tightens the gates survey's conclusion
("the minimal complete gate library is exactly two cells, `{tadd1, tmul}`" — `docs/compute/gates.md`
§8) by making the *negation-is-redundant* step explicit. **[OURS — the reduction; DIRECT — the
F₃ completeness it rests on.]**

### Alternative complete sets (for completeness of the survey, not minimality)

| set | complete? | calibration / source |
|---|---|---|
| `{⊕, ⊗, constants}` | ✅ **minimal (this file)** | DIRECT — Lagrange over F₃ |
| `{neg, ⊕, ⊗}` | ✅ but reducible (neg = x⊕x) | OURS — this file §1 |
| `{min, max, neg}` | ❌ lattice fragment | DIRECT — `gates.md` §4 |
| `{all 27 unary, min}` | ✅ Słupecki | DIRECT — Słupecki 1939 |
| `{ROTATE, ALPHA, BETA, GAMMA}` | ✅ 4 ops, unbalanced {0,1,2} | DIRECT — `2305.04115` |

The field pair is minimal in *both* senses that matter: fewest operations, and each operation is
the exact F₃ twin of a binary primitive (`⊕`↔XOR, `⊗`↔AND).

---

## 4. Minimal realization — on our cells, and on a native 3-state device

### 4a. Our measured realization (2-wire one-hot encoding, binary standard cells)

**[DIRECT — `docs/compute/gate_area.md` / `rtl/gate_area.txt` for `tadd1`; `tmul` area is an
estimate flagged as such in `gates.md` §3 — it is **not** in the gate_area benchmark.]**

| primitive | our cell | cells | area (µm²) | notes |
|---|---|---|---|---|
| constants {−1,0,+1} | rail ties / nothing | 0 | 0.0000 | `2'b10`, `2'b00`, `2'b01` |
| negation `−x` | `tadd1.sum(x,x,0)` **or** free wire swap | 0 (as `tneg`) | 0.0000 | wire swap `{t[0],t[1]}`; or one `⊕` |
| **`⊕` (mod-3 sum)** | `tadd1` (sum output) | **25** | **146.3904** | the expensive cell (4.33× a binary FA) |
| **`⊗` (mod-3 product)** | `tmul` = 4 AND2 + 2 OR2 | ≈6 | ≈37 | estimate; truth table = sign product |

The **minimal complete library on our flow is exactly two cells — `{tadd1, tmul}`** — total
**≈183 µm² / ≈31 cells**, with negation and constants free. This is the practical statement the
gates survey already reached; the only new fact here is that negation needs **no** separate cell
even when you *want* it (it is `tadd1.sum(x, x, 0)`, an existing cell with tied inputs).

### 4b. The literature's native-device realization (CNTFET / multi-Vt CMOS)

The **completeness-critical operator — `⊕` — is precisely the gate that wins on a native
3-state threshold device.** `2211.12176` (multi-Vt CMOS threshold-logic gate) measures its
ternary TLG against CMOS: **STI (negation), COMP, XOR (= mod-3 sum), and THA *beat* CMOS, while
AND/OR *lose*** (the clocked threshold gate carries a flip-flop that min/max gates don't
amortize). So the field pair `{⊕, ⊗}` is the right minimal set for the *device* too, not just
the math: the mod-3 sum is exactly the operation the native threshold device does cheaply.
**[DIRECT — `2211.12176` §7, Table 2–3.]**

Closest transistor counts in the corpus (CNTFET/HSPICE, **not** our silicon; `docs/compute/gates.md`
§5b):

| primitive | CNTFET count (best cited) | source |
|---|---|---|
| negation (STI) | 4 → **6** | `2211.04542` (level-coded; ours is 0, a wire swap) |
| **`⊕` (mod-3 sum)** | THA sum = **45** (half-adder, 85/90/**45**); 3-sum cell = **150** | `2211.04542` / `Automated_synthesis` |
| **`⊗` (mod-3 product)** | TMUL = **40** (61/60/**40**) | `2211.04542` |
| balanced full adder (⊕+carry, 3-in) | **118** (compound/hybrid) / 188 (non-compound) | `Automated_synthesis` |

So on the closest *native 3-state device in the corpus*, the minimal complete pair is
**`{⊕, ⊗} ≈ {45, 40} ≈ 85 CNFETs`**, with negation derived (one more `⊕`, or 6-CNFET STI) and
constants free. The `Automated_synthesis` headline reinforces the architecture: the **3-operand
hybrid full adder wins power–delay product over 2-operand composition** (1.10e-15 J vs
1.44e-15 J @ 500 MHz) — i.e. build `⊕` (and its carry) as one holistic 3-input cell, not a
chain of 2-input gates. Our `tadd1` is already exactly that 3-operand cell. **[DIRECT.]**

### 4c. The single-wire native-device floor (the honest open item)

What the whole `TERNARY_GROUND_UP.md` search is *for* is the case where a **trit is one wire
with three physically distinct states on one device** (not our 2-wire one-hot encoding, not
2-level MOSFETs). In that regime the 2-threshold tax that makes our `tadd1` 4.33× a binary FA
collapses — the gate stops being "demux + two binary thresholds" and becomes a single
3-state threshold network. The quantitative floor is **unmeasured**: `device_circuit.md` (the
native-device batch-1 item) does not exist yet, and the corpus has no RTD/SET/memristor gate
netlist to copy. What the corpus *does* establish, calibrated:

- **Existence:** a single 3-state transistor is fabricated (Yeom 2025, BP reconfigurable-polarity
  ternary transistor) — **but** its middle state is a parasitic minority-carrier current that
  *vanishes in ideal devices* (thinner BP → reverts to binary). The sharpest counter to any
  "3 states per device is free" reading. [DIRECT — Yeom 2025 graph; `docs/synthesis/ternary-circuits.md` §3.]
- **The `⊕` gate is the native winner** (multi-Vt CMOS TLG, `2211.12176`), so a native-device
  minimal library would center on a single **3-state sum/threshold cell** plus a **3-state
  product cell** — exactly two threshold networks. **[ANALOGY — device story ported from the
  level-coded literature to our field-pair minimality.]**
- **Speculative floor:** two cells (one per field op), each a pull-up/pull-down 3-state network
  following the Kim et al. static-gate methodology, with the 2-transistor STI inverter as the
  only "active" primitive and negation/constants free. **[SPECULATION — to be tested in
  `device_circuit.md` + ngspice.]**

---

## 5. Sources

**Ours (DIRECT, measured/proved):**
- `docs/compute/gates.md` + `docs/compute/gate_area.md` + `rtl/gate_area.txt` — the gate
  survey this file tightens; measured areas (`tneg` 0.00, `tadd1` 146.39 µm² / 25 cells).
- `rtl/trit_functions.vh` + `rtl/ternary_gates.v` — the cell equations used for `⊕`, `⊗`, `tneg`,
  `tadd1` (balanced carry, `s≥2 → cout +1`, `s≤−2 → cout −1`).
- `proofs/lean-src/hexagon/Hexagon/TernaryCell.lean` — `encode`, `null_is_free`,
  `encode_never_both`, `average_energy` (the 2-wire cell the realization is measured against).

**Literature (DIRECT citations, from `docs/graphs/ternary-circuits/`):**
- **Martin 1954**, *The Sheffer functions of 3-valued logic*, JSL 19:45–51 — no 2-ary Sheffer
  function for radix ≥ 3 (forces ≥ 2 primitives).
- **Słupecki 1939** — all unary + one essential binary is complete (the "more gates" baseline).
- `2305.04115` Kawashima — `{ROTATE, ALPHA, BETA, GAMMA}` complete (4-op alternative, unbalanced).
- `2211.12176` Unutulmaz & Ünsalan — multi-Vt CMOS TLG: XOR (= mod-3 sum), STI, THA *beat* CMOS;
  AND/OR lose (the "⊕ is the native winner" evidence).
- `2211.04542` Jaber thesis — CNFET transistor counts (STI 4–6, THA 45–90, TMUL 40–61).
- `Automated_synthesis` Risto et al. — 3-sum/3-carry = 150/50 tr; 3-operand hybrid FA = 118 tr,
  wins PDP (1.10e-15 J).
- `2309.01615` Wang et al. — fabricated balanced memristor-CMOS (TMIN/TMAX/STI/HA/MUL truth
  tables = our cells; level-coded, not our polarity).
- Yeom 2025 — single-device ternary transistor; middle state parasitic, vanishes in ideal devices.

**Standard algebra (DIRECT, no circuit corpus):** Lagrange interpolation over F_q (polynomial
functions = all functions F_qⁿ → F_q); Fermat `x³ = x` over F₃; `2 = −1` in char 3. The
negation reduction `−x = x ⊕ x` and the minimality (affine-vs-monomial, origin-vanishing) are
standard clone-theory observations stated here for F₃; the derivations are self-contained in §1–§3.

---

## TODO / not covered / caveats

1. **`device_circuit.md` is the missing sibling.** This file gives the minimal *set* (closed) and
   the minimal *realization* only down to (a) our measured 2-wire cells and (b) the corpus's
   CNTFET/multi-Vt numbers. The **single-wire native 3-state device floor is unmeasured** — the
   device batch-1 agent must produce it, then this file's §4c gets real numbers instead of
   "≈85 CNFETs / SPECULATION."
2. **No ngspice gate-energy number yet.** We have *area* for `tadd1` (146.39 µm²) but no
   measured joule/transition for `⊕`/`⊗` (the yosys power pass is still backlog,
   `docs/compute/gates.md` §6b). "Minimal realization" here is **area**, not energy.
3. **`tmul` area is an estimate** (≈6 cells / ≈37 µm²), not a gate_area.txt measurement. Promote
   it to measured.
4. **The negation reduction is not in the Lean ledger.** `tneg(x) = tadd1.sum(x,x,0)` (and
   `−x = x ⊗ (−1)`) is a 3-line corollary, but no `TernaryCell`/`Gates` theorem states it. Add
   it, so "negation is derived, not primitive" is proved rather than asserted.
5. **`x ⊕ x = −x` requires the carry to be *dropped*** (it uses only `tadd1.sum`, not the full
   `tadd1` `{cout,sum}`). Worth stating precisely because `tadd1` as a *positional* adder keeps
   the carry — the field `⊕` is the sum projection.
6. **"Minimal" is at the operation level, not the cost level.** `{⊕, ⊗}` is minimal in *gate
   count*; it is not the cheapest *area* pair — `⊕` is the 4.33× expensive cell. A cost-minimal
   (as opposed to gate-minimal) library might prefer the cheap-but-incomplete `{min,max,neg}`
   for the logic slice and pay for `⊕` only where the field structure is needed (`gates.md` §8).
7. **Unbalanced vs balanced is re-asserted per citation.** `2211.04542` runs on `{0,1,2}` with a
   driven mid-level; the "45/40 CNFET" numbers are **ANALOGY** to our balanced `{−1,0,+1}`. Do
   not quote them as balanced-native counts.
8. **No fabricated native-device *gate*** in the corpus realizes `⊕` and `⊗` on one wire; the
   closest is Yeom's single transistor (a *switch*, not a complete gate pair) and
   `2309.01615`'s memristor-CMOS (level-coded). The "two native 3-state threshold cells" floor
   is a **design target, not a result.**
9. **Martin 1954 kills only *2-ary* Sheffer functions.** Higher-arity single gates (3-input
   majority/median) are complete, so if a future device makes a 3-input median cheaper than
   `⊕`, the "minimal set" could shrink to one *gate class* — out of scope here, worth a
   follow-up.
