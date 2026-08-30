# Balanced-Ternary Truth Tables — the useful gate reference

**2026-08-29 — ground-up batch 1, the "enumerate every useful gate" item.** Companion to
`../gates.md` (the gate survey), `minimal_gates.md` (the minimal complete set), and
`polar_gates.md` / `gate_energy.md` (the measured cells). This file is the *truth-table
reference*: every useful balanced-ternary logic function, its 3×3 (or 3×) table, whether it is
balanced, and whether it is derivable from each of the two canonical generating systems.

**Scope.** Full counts stated (27 unary, 19 683 binary), but the *content* is the useful
balanced subset over `{−1, 0, +1}`. Nothing here is invented: every table is written out from
first principles and every derivability claim is a one-line invariant argument (§3) or an
explicit expression (§5–§6). Where a claim rests on the repo's cells or the literature rather
than on a bare computation, it is tagged.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — definition or first-principles derivation; a truth table, a count, or a
  derivability/non-derivability argument verified by direct computation on this page.
- **ANALOGY** — the *name* or *role* parallels something (Boolean NAND/NOR, Łukasiewicz L₃),
  but the mapping is a translation, not an identity.
- **SPECULATION** — editorial/selection judgment or an unmeasured hardware claim, flagged as such.

---

## 1. Conventions — how to read every table

**Value set.** A trit is `T = {−1, 0, +1}`, written `−`, `0`, `+`. Balanced: the three values are
symmetric about 0. `−1 ≡ 2 (mod 3)` and `+1 ≡ 1 (mod 3)`, so `(T, ⊕, ⊗) ≅ F₃`, the field of
order 3 [DIRECT — `minimal_gates.md` §1].

**Truth-table convention.** For a binary gate the table is `table[row = x][column = y] = f(x,y)`,
with rows and columns ordered `−, 0, +`. For a unary gate the table lists the output for input
`−`, then `0`, then `+`, in that order.

**Balanced (definition).** A ternary function is *balanced* iff uniform balanced input maps to
uniform balanced output — equivalently, iff every output value occurs equally often in its truth
table (a unary is balanced iff it is a permutation of `{−,0,+}`; a binary is balanced iff each of
`−,0,+` appears **3 times** in its 9-entry table; a 3-input function iff each appears **9 times**
in its 27-entry table). **[DIRECT — this is the Boolean "balanced truth table" notion lifted to
radix 3; it is the property "balanced inputs → balanced outputs".]**

**Two generating systems (the derivability question).**

- **K-basis — the order/lattice system** `K = {negation, min, max}`. This is Kleene's strong
  three-valued logic (K₃), the ternary twin of `{AND, OR, NOT}`. It generates the **lattice /
  regular fragment** — it cannot make the cyclic or field structure (see §3).
- **F-basis — the field system** `F = {negation, mod-3 sum ⊕, mod-3 product ⊗}`. This is the
  finite-field pair F₃, the ternary twin of `{XOR, AND}` over F₂. With **one nonzero constant**
  it generates *every* function (universal); without any nonzero constant it generates exactly the
  functions that vanish at the all-zero input (§3).

In the notes below, **"K: yes"** means derivable from `{¬, min, max}` *without* constants;
**"K: yes + const"** means a constant (0 for the clamps/consensus) must be supplied; **"K: no"**
means not derivable even with constants. **"F: yes"** means derivable from `{¬, ⊕, ⊗}` with no
constant (0 is free, `0 = x⊕¬x`); **"F: yes + const"** means one nonzero constant must be seeded.

---

## 2. Totals

| arity | inputs | total functions | balanced functions | notes |
|---|---|---|---|---|
| unary | 1 | **3³ = 27** | **6** (the permutations S₃) | 3 constants + 6 permutations + 18 non-bijective detectors/clamps |
| binary | 2 | **3⁹ = 19 683** | **1680** = 9!/(3!·3!·3!) | the useful subset is §5 |
| majority | 3 | 3²⁷ = 7 625 597 484 987 | — | only the median is covered (§6) |
| n-ary | n | 3^(3ⁿ) | 3ⁿ!/(3!·…·3!) generalizes | — |

The two counts the task asks for, stated plainly: **27 unary functions (3³)** and **19 683 binary
functions (3⁹)**. The balanced ones are a thin slice: **6 of 27** unary, **1680 of 19 683**
binary. **[DIRECT — combinatorial count; 1680 = multinomial(9; 3,3,3).]**

---

## 3. The one structural fact that organizes everything

Two generating systems, and they are *not* the same strength. This is the fact every derivability
note in §5–§6 reduces to.

### 3.1 The field basis is universal (with a constant)

Every function `f : F₃ⁿ → F₃` is a polynomial in `⊕` and `⊗` with constant coefficients —
Lagrange interpolation over F₃, using `x³ = x` (Fermat). Hence `{⊕, ⊗} + one nonzero constant`
generates **all 27 unary and all 19 683 binary functions**. Without a nonzero constant, a
polynomial has zero constant term, i.e. `f(0,…,0) = 0`. So in the field basis:

> a function is derivable with **no constant** iff `f(0,…,0) = 0`; otherwise it needs **one
> nonzero constant** (`+1` suffices, since `0 = x⊕¬x` and `−1 = ¬(+1)` are then free).

Also, **negation is not primitive in F**: `−x = x ⊕ x` (since `2 = −1` in characteristic 3), so
`¬` is *derivable* from `⊕` alone. **[DIRECT — `minimal_gates.md` §1.]**

### 3.2 The Kleene basis is the regular fragment (never universal)

`{¬, min, max}` generates exactly the *regular* functions — the functions monotone in the
**information order** `0 ⊑ −1`, `0 ⊑ +1` (0 is "unknown", `±1` are "known"). Two quick facts
prove the boundary:

1. `¬`, `min`, `max` are all **regular** (monotone in `⊑`), and regularity is preserved by
   composition. Hence every K-term is regular.
2. Every K-term maps `{−1,+1}` inputs to `{−1,+1}` outputs (all three ops close `{−,+}`). So
   no K-term, **without a constant**, ever outputs `0` on a nonzero input.

Consequences used throughout:

- `min`, `max`, `¬`, `NAND`, `NOR` are primitive/derivable in K — and so is **`⊗`**:
  `x⊗y = (x∧y) ∨ (¬x∧¬y)` (§5.7, DIRECT, verified entry-by-entry below).
- `⊕` (and hence `⊖`, `¬⊕`) is **not** regular (e.g. `(0,+) ⊑ (+,+)` but `⊕(0,+) = +` and
  `⊕(+,+) = −`, and `+ ⊑ −` is false), so it is **not derivable from K even with constants**.
  This is the one irreducible gap: the mod-3 sum is the genuinely *new* operation the field basis
  adds. **[DIRECT — counterexample verified.]**
- `consensus`, `x⁺`, `x⁻` are regular but output `0` on nonzero inputs, so they need the
  **constant 0** (which `{¬,min,max}` alone cannot produce, since `0` would have to appear at
  input `+1`, and `{−,+}` is closed).
- `is-zero` and the sign detectors are **not regular**, so they are outside K even with constants.

**[DIRECT — the "K = regular fragment" characterization is the standard Kleene-clone result;
the specific per-gate claims in §5–§6 are verified here, not quoted.]**

---

## 4. Unary gates (27 total; the useful 17 below)

Output string is `[f(−), f(0), f(+)]`. "Balanced" = permutation of `{−,0,+}`.

### 4.1 Constants

| gate | `[f(−),f(0),f(+)]` | balanced | K | F | calibration |
|---|---|---|---|---|---|
| const −1 | `− − −` | no | no (needs const) | yes + const | DIRECT |
| const 0 | `0 0 0` | no | no (needs const) | yes (`x⊕¬x`, free) | DIRECT |
| const +1 | `+ + +` | no | no (needs const) | yes + const | DIRECT |

The constants are physically free in the repo's one-hot encoding (`+1=2'b01`, `0=2'b00`,
`−1=2'b10`) [DIRECT — `gates.md` §1]. In F, `0 = x⊕¬x = x⊕(x⊕x)` is derivable, but **no nonzero
constant is** — one must be seeded (§3.1).

### 4.2 The symmetry group — the 6 balanced permutations (S₃)

| gate | `[f(−),f(0),f(+)]` | balanced | K | F | calibration |
|---|---|---|---|---|---|
| **identity** | `− 0 +` | **yes** | yes | yes | DIRECT |
| **negation** (tneg / STI) | `+ 0 −` | **yes** | yes (primitive) | yes (primitive; = `x⊕x`) | DIRECT — free wire swap in the repo, 0.00 µm² |
| **cycle +1** (successor, ROTATE) | `0 + −` | **yes** | no (not regular) | yes + const (`x⊕+1`) | DIRECT — the 3-cycle of `2305.04115`; our `tadd1(x,+1,0).sum` |
| **cycle −1** (predecessor) | `+ − 0` | **yes** | no | yes + const (`x⊕−1`) | DIRECT |
| **swap 0↔+** (fix −) | `− + 0` | **yes** | no | yes + const (`¬x ⊕ +1`) | DIRECT |
| **swap −↔0** (fix +) | `0 − +` | **yes** | no | yes + const (`¬x ⊕ −1`) | DIRECT |

`S₃ = D₃` is generated by one reflection (negation) + one 3-cycle (cycle ±1); the two swaps are
the "selective negation" transpositions. The cycles are *the* missing ingredient from K: min/max/
neg are all monotone-or-antitone in the trit order and cannot rotate. **[DIRECT — `gates.md` §2.]**

### 4.3 Detectors and clamps (the 8 non-bijective useful ones)

| gate | `[f(−),f(0),f(+)]` | balanced | K | F | calibration |
|---|---|---|---|---|---|
| **is-zero** | `− + −` | no | no (not regular) | yes + const (`x⊗x ⊕ +1`) | DIRECT |
| **is-nonzero** | `+ − +` | no | no | yes + const (`¬(x⊗x) ⊕ −1`) | DIRECT — = `¬is-zero` |
| **is-positive** | `− − +` | no | no | yes + const | DIRECT |
| **is-negative** | `+ − −` | no | no | yes + const | DIRECT |
| **positive part** `x⁺ = max(x,0)` | `0 0 +` | no | yes + const 0 (`x∨0`) | yes (`max` is F-polynomial, §3.1) | DIRECT |
| **negative part** `x⁻ = min(x,0)` | `− 0 0` | no | yes + const 0 (`x∧0`) | yes | DIRECT |
| **magnitude** `|x| = max(x,−x)` | `+ 0 +` | no | yes (`x∨¬x`) | yes (`x⊗x`) | DIRECT — `x² = |x|` over F₃ |
| **negated magnitude** `−|x| = min(x,−x)` | `− 0 −` | no | yes (`x∧¬x`) | yes (`¬(x⊗x)`) | DIRECT |

**The "sign-of" detector — come-to-terms.** In balanced ternary the *sign* of a value is the
value itself: `sign(−1)=−1, sign(0)=0, sign(+1)=+1`. So **sign-of = identity**, and there is no
distinct "signum" function (unlike binary/real logic where sign maps to a smaller set). The useful
*detectors* are the ones in the table — `is-positive`, `is-negative`, `is-zero` — plus the
magnitude `|x|`. **[DIRECT — consequence of the balanced representation; this is the one place the
"balanced" choice collapses two Boolean concepts into one.]**

`is-zero` is the workhorse: it reads `+` exactly on `0` and `−` on `±1`. In the field it is
`z(x) = x⊗x ⊕ +1` (uses the constant `+1`, since `z(0)=+1 ≠ 0`). `is-nonzero = ¬is-zero`.
**[DIRECT.]**

---

## 5. Binary gates (19 683 total; the useful subset below)

Convention: rows = `x`, columns = `y`, both ordered `−, 0, +`. "Balanced" = each output occurs 3
times in the 9 entries.

### 5.1 min — AND / meet `∧`

| ∧ | − | 0 | + |
|---|---|---|---|
| − | − | − | − |
| 0 | − | 0 | 0 |
| + | − | 0 | + |

- **Definition:** `min(x,y)` = lesser trit in the order `−1 < 0 < +1` (lattice *meet*).
- **Balanced:** no — counts `−:5, 0:3, +:1` (biased toward −).
- **Derivability:** K: yes (primitive). F: yes, no constant (`min(0,0)=0`, §3.1).
- **Calibration:** DIRECT — bit-identical to `2309.01615`/`2211.04542`/`1807.06419` and our
  `tand` [DIRECT — `gates.md` §3].

### 5.2 max — OR / join `∨`

| ∨ | − | 0 | + |
|---|---|---|---|
| − | − | 0 | + |
| 0 | 0 | 0 | + |
| + | + | + | + |

- **Definition:** `max(x,y)` = greater trit (lattice *join*).
- **Balanced:** no — `−:1, 0:3, +:5` (mirror of min).
- **Derivability:** K: yes (primitive). F: yes, no constant.
- **Calibration:** DIRECT.

### 5.3 NAND analogue — `¬(x∧y) = max(−x,−y)`

| NAND | − | 0 | + |
|---|---|---|---|
| − | + | + | + |
| 0 | + | 0 | 0 |
| + | + | 0 | − |

- **Balanced:** no — `+:5, 0:3, −:1`.
- **Derivability:** K: yes (`tneg∘tand`). F: yes, no constant (`¬min`, and min∈F).
- **Calibration:** **ANALOGY** — "NAND" in radix 3 has no canonical single meaning; this is the
  Kleene strong NAND (`¬(meet)`), the one the repo's `tnand` implements. A different "field NAND"
  would be `¬⊗`; see caveats. **[ANALOGY — naming; DIRECT — the table.]**

### 5.4 NOR analogue — `¬(x∨y) = min(−x,−y)`

| NOR | − | 0 | + |
|---|---|---|---|
| − | + | 0 | − |
| 0 | 0 | 0 | − |
| + | − | − | − |

- **Balanced:** no — `−:5, 0:3, +:1`.
- **Derivability:** K: yes (`tneg∘tor`). F: yes, no constant.
- **Calibration:** ANALOGY (naming) / DIRECT (table).

### 5.5 mod-3 sum `⊕` — balanced add, the ternary XOR

| ⊕ | − | 0 | + |
|---|---|---|---|
| − | + | − | 0 |
| 0 | − | 0 | + |
| + | 0 | + | − |

- **Definition:** `(x + y) mod 3`, carry dropped; single-trit digit sum. (`(−1)+(−1)=−2 ≡ +1`.)
- **Balanced:** **yes** — `−:3, 0:3, +:3`; it is a Latin square (the Cayley table of `(F₃,+)`).
- **Derivability:** K: **no** (not regular, §3.2 — the irreducible gap). F: yes (primitive).
- **Calibration:** DIRECT — `2211.12176` calls this "XOR"; our `tadd1(x,y,0).sum`.

### 5.6 mod-3 difference `⊖ = x⊕¬y`

| ⊖ | − | 0 | + |
|---|---|---|---|
| − | 0 | − | + |
| 0 | + | 0 | − |
| + | − | + | 0 |

- **Definition:** `(x − y) mod 3` = `x ⊕ (¬y)`.
- **Balanced:** **yes** — `−:3, 0:3, +:3` (Latin square).
- **Derivability:** K: no. F: yes, no constant.
- **Calibration:** DIRECT.

### 5.7 mod-3 product `⊗` — balanced multiply

| ⊗ | − | 0 | + |
|---|---|---|---|
| − | + | 0 | − |
| 0 | 0 | 0 | 0 |
| + | − | 0 | + |

- **Definition:** `x·y (mod 3)` = sign product with 0 absorbing. `(−1)(−1)=+1`, `(−1)(+1)=−1`.
- **Balanced:** **no** — `+:2, 0:5, −:2` (0 dominates; the zero-row/column is all 0).
- **Derivability:** F: yes (primitive). **K: yes — surprising and exact:**
  `x⊗y = (x∧y) ∨ (¬x∧¬y)`. Verified entry-by-entry: it reads `+` on `(−,−)` and `(+,+)`, `−` on
  `(−,+)` and `(+,−)`, and `0` whenever either input is `0`. So the *field product is inside the
  Kleene fragment* — it is `⊕`, not `⊗`, that the field basis genuinely adds. **[DIRECT — the
  identity is the one non-obvious line of this file; every entry checked.]**
- **Calibration:** DIRECT.

### 5.8 negated sum `¬⊕ = ¬(x⊕y)`

| ¬⊕ | − | 0 | + |
|---|---|---|---|
| − | − | + | 0 |
| 0 | + | 0 | − |
| + | 0 | − | + |

- **Balanced:** **yes** (negation preserves the 3/3/3 counts of ⊕).
- **Derivability:** K: no. F: yes, no constant.
- **Calibration:** DIRECT.

### 5.9 consensus — the 2-input "agreement"

| c | − | 0 | + |
|---|---|---|---|
| − | − | 0 | 0 |
| 0 | 0 | 0 | 0 |
| + | 0 | 0 | + |

- **Definition:** `c(x,y) = x` if `x = y`, else `0`. (= `median(x, y, 0)`.)
- **Balanced:** no — `−:1, 0:7, +:1` (0 dominates).
- **Derivability:** K: yes **with constant 0** — `c(x,y) = (x∧y) ∨ (y∧0) ∨ (x∧0)` (median form;
  `0` cannot be produced by `{¬,min,max}` alone, §3.2). F: yes, no constant (`c(0,0)=0`).
- **Calibration:** DIRECT definition; **come-to-terms flag** — in binary "consensus" = majority =
  `xy∨xz∨yz`; in ternary MVL "consensus" is this 2-input *agreement* op. Different functions.
  **[DIRECT — `gates.md` §3 flags the collision; the table is standard MVL.]**

### 5.10 Kleene implication `→` = `¬x ∨ y = max(−x, y)`

| → | − | 0 | + |
|---|---|---|---|
| − | + | + | + |
| 0 | 0 | 0 | + |
| + | − | 0 | + |

- **Balanced:** no — `−:1, 0:3, +:5`.
- **Derivability:** K: yes (`tor(tneg(x), y)`). F: yes, no constant.
- **Calibration:** DIRECT (K₃ material implication). Distinguish from the Łukasiewicz form below:
  they differ **only at `(0,0)`** (Kleene → `0`, Łukasiewicz → `+`).

### 5.11 Łukasiewicz implication `→ₗ = min(+1, +1 − x + y)`

| →ₗ | − | 0 | + |
|---|---|---|---|
| − | + | + | + |
| 0 | 0 | + | + |
| + | − | 0 | + |

- **Balanced:** no — `−:1, 0:2, +:6`.
- **Derivability:** K: **no** (not regular: `(0,0) ⊑ (+,−)` but `→ₗ(0,0)=+` and `→ₗ(+,−)=−`).
  F: yes **+ const** (`→ₗ(0,0)=+1`; = `min(+1, +1⊕¬x⊕y)` needs the constant `+1`).
- **Calibration:** **ANALOGY** — the L₃ (Łukasiewicz) implication translated from `{0,½,1}` to
  `{−1,0,+1}` via `t = (v+1)/2`; the table is the translation, not a separate ternary primitive.

### 5.12 equality — the balanced XNOR analogue

| eq | − | 0 | + |
|---|---|---|---|
| − | + | − | − |
| 0 | − | + | − |
| + | − | − | + |

- **Definition:** `eq(x,y) = +1` if `x = y`, else `−1`.
- **Balanced:** no — `+:3 (diagonal), −:6`.
- **Derivability:** K: **no** (not regular: `(0,0)⊑(+,−)` but `eq(0,0)=+`, `eq(+,−)=−`). F: yes
  **+ const** — `eq(x,y) = +1 ⊕ ¬((x⊖y)⊗(x⊖y))` (since `(x−y)² = 0` iff `x=y`, else `1`).
- **Calibration:** ANALOGY (the ternary "equals" predicate; the balanced counterpart of Boolean
  XNOR). Note this is a *predicate* (outputs `±`), unlike `consensus` (outputs `x` or `0`).

### 5.13 Łukasiewicz strong conjunction `⊙ = max(−1, x + y − 1)` (t-norm)

| ⊙ | − | 0 | + |
|---|---|---|---|
| − | − | − | − |
| 0 | − | − | 0 |
| + | − | 0 | + |

- **Balanced:** no — `−:6, 0:2, +:1`.
- **Derivability:** K: no. F: yes **+ const** (`⊙(0,0)=−1`).
- **Calibration:** ANALOGY (L₃ t-norm in balanced form).

### 5.14 Łukasiewicz strong disjunction `⊕ₗ = min(+1, x + y + 1)` (t-conorm)

| ⊕ₗ | − | 0 | + |
|---|---|---|---|
| − | − | 0 | + |
| 0 | 0 | + | + |
| + | + | + | + |

- **Balanced:** no — `−:1, 0:2, +:6` (biased toward +; the De Morgan dual of `⊙`).
- **Derivability:** K: no (not regular: `(0,0)⊑(−,−)` but `⊕ₗ(0,0)=+`, `⊕ₗ(−,−)=−`). F: yes
  **+ const** (`⊕ₗ(0,0)=+1`).
- **Calibration:** ANALOGY (L₃ t-conorm `min(1,A+B)` in balanced form = `min(+1, x+y+1)`; equals
  `¬(¬x ⊙ ¬y)`, the De Morgan dual of the strong conjunction).

---

## 6. Majority / median (3-input)

`maj3(x,y,z) = median(x,y,z)` = the value occurring ≥ 2 times; when all three are distinct, the
median is `0`. Symmetric and idempotent. It is the ternary generalization of the Boolean majority
gate, and the closest ternary analogue of a Sheffer-style single higher-arity gate.

| x \ (y,z) | −− | −0 | −+ | 0− | 00 | 0+ | +− | +0 | ++ |
|---|---|---|---|---|---|---|---|---|---|
| − | − | − | − | − | 0 | 0 | − | 0 | + |
| 0 | − | 0 | 0 | 0 | 0 | 0 | 0 | 0 | + |
| + | − | 0 | + | 0 | 0 | + | + | + | + |

- **Balanced:** **no** — counts `−:7, 0:13, +:7` (median concentrates on 0: it returns 0 whenever
  the triple contains a 0 and not a two-way `±` tie). This corrects the tempting symmetry guess:
  negation-symmetry only forces `#− = #+`, it says nothing about `0`. **[DIRECT — counted above.]**
- **Derivability:** K: yes, no constant —
  `maj3 = (x∧y)∨(y∧z)∨(z∧x)` = `max(min(x,y), min(y,z), min(z,x))` (also the dual form
  `min(max(x,y), max(y,z), max(z,x))`). F: yes, no constant (`maj3(0,0,0)=0`).
- **Calibration:** DIRECT definition; **ANALOGY** for the "majority ↔ 3-carry cell" hardware
  mapping (`gates.md` §3 — the 3-operand carry is a threshold on the digit sum, close but not the
  value-median). **[ANALOGY — hardware role; DIRECT — the table and the K-expression.]**

---

## 7. Derivability + balance summary

| gate | K `{¬,min,max}` | F `{¬,⊕,⊗}` | balanced | counts |
|---|---|---|---|---|
| min ∧ | yes | yes | no | 5/3/1 |
| max ∨ | yes | yes | no | 1/3/5 |
| NAND | yes | yes | no | 5/3/1 |
| NOR | yes | yes | no | 1/3/5 |
| **⊕ mod-3 sum** | **no** | yes | **yes** | 3/3/3 |
| ⊖ mod-3 diff | no | yes | **yes** | 3/3/3 |
| ⊗ mod-3 product | **yes** `(x∧y)∨(¬x∧¬y)` | yes | no | 2/5/2 |
| ¬⊕ | no | yes | **yes** | 3/3/3 |
| consensus | yes + const 0 | yes | no | 1/7/1 |
| Kleene → | yes | yes | no | 1/3/5 |
| Łukasiewicz →ₗ | no | yes + const | no | 1/2/6 |
| eq (equality) | no | yes + const | no | 3/6 |
| ⊙ strong AND | no | yes + const | no | 6/2/1 |
| ⊕ₗ strong OR | no | yes + const | no | 1/2/6 |
| majority (3-in) | yes | yes | no | 7/13/7 |

| unary | K | F | balanced |
|---|---|---|---|
| identity | yes | yes | yes |
| negation | yes | yes | yes |
| cycle +1 / −1 | no | yes + const | yes |
| swap 0↔+ / −↔0 | no | yes + const | yes |
| const −1 / 0 / +1 | no | yes (+const, except 0 free) | no |
| is-zero / is-nonzero | no | yes + const | no |
| is-pos / is-neg | no | yes + const | no |
| x⁺ / x⁻ (clamps) | yes + const 0 | yes | no |
| \|x\| / −\|x\| | yes | yes | no |

**One-line reading.** The field basis is universal (with a constant) and the order basis is the
regular fragment. The **irreducible new operation is `⊕`** (mod-3 sum): it is the only useful gate
that is *not* in the Kleene fragment, and it is exactly the balanced, Latin-square operation the
field algebra needs. `⊗` is *not* new to the order basis (it is a min/max/neg expression), and
`min`/`max` are *not* new to the field basis (they are F₃-polynomials). The genuinely balanced
binary gates among the useful ones are `⊕`, `⊖`, and `¬⊕`. **[DIRECT — each cell verified
in §3–§6.]**

---

## TODO / not covered / caveats

1. **The full Post-lattice of radix-3 is not enumerated here.** "K = regular fragment" is used as
   the standard Kleene-clone characterization and is *verified gate-by-gate* in this file, but the
   complete clone lattice (which of the many intermediate clones sit between the regular fragment
   and the full clone, and their exact cardinalities) is out of scope. A clone-theory pass would
   make §3.2 a cited theorem rather than a per-gate invariant argument.
2. **"NAND/NOR analogue" is not unique in radix 3.** Only the Kleene strong forms are tabulated.
   The "field NAND" `¬⊗`, the "sum NAND" `¬⊕`, and the consensus-based variants are different
   functions with different costs; they are left to the gate-survey, not enumerated here.
3. **No circuit/energy numbers are claimed.** This is a pure truth-table reference. Area/energy
   (min/max = 2.00×, `⊕` = 4.33× a binary FA, etc.) live in `gates.md` / `gate_area.md` /
   `gate_energy.md` and are not re-derived.
4. **The balanced count (1680 binary) counts *output* balance only.** It does not assert anything
   about *which* balanced functions are cheap, Latin-square, or derivable from a small basis. The
   three balanced useful gates here (`⊕`, `⊖`, `¬⊕`) are a subset of the 1680; the rest are unnamed.
5. **`majority` is 3-input, not 2-input**, so it sits outside the "binary functions" framing the
   task's counts use. The 2-input "majority" is ill-defined on disagreement (which is why the
   2-input agreement op is `consensus`, a different function).
6. **The Łukasiewicz entries are translations.** `→ₗ`, `⊙`, `⊕ₗ` are the L₃ operators expressed in
   balanced coordinates via `t=(v+1)/2`; whether the processor wants them at all (vs Kleene's) is
   a logic-design choice, not settled here. Their "not regular" status is derived, but their
   *usefulness* in this architecture is SPECULATION (untested against the opcode set).
7. **Hardware-specific gates are omitted by design.** Carry (`tadd1.cout`), 1:3 decoders, 3:1
   multiplexers, comparison (`x⊖y` sign), and round-to-nearest are arithmetic/control primitives,
   not logic functions; they are covered in `arithmetic.md` / `control.md`, not this table.
8. **`swap` transpositions are named ad hoc.** The literature has no universal name ("cyclic
   negation", "half-negation" both appear). Their tables are DIRECT; their names are a
   come-to-terms risk.
9. **`x⁺`, `x⁻`, `|x|` are order-primitives, not field-primitives**, and the K-basis needs the
   constant 0 to build the clamps. That the field basis builds them without any constant is a
   consequence of §3.1 and is stated, but the *cheapest* realization is unmeasured (SPECULATION).

*Nothing in this file invents a truth table: each is the balanced function written out entry by
entry from its definition, and each derivability note reduces to §3.1 (field) or §3.2 (order).*
