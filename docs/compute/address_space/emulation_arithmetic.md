# Emulation Arithmetic — the binary cost of the Tau arithmetic/GA ops

**2026-08-30.** The question, stated plainly: *on a binary machine, how many binary integer ops
(add / mul / negate) does each Tau operation cost to produce the same integer result?* This file
answers it with one table and, because the honest answer is short and unglamorous, says it in the
first block instead of burying it.

Calibration legend: **DIRECT** = read off the RTL / Lean source, verbatim; **DERIVED** = the
binary column, which is *not* a synthesis result — it is the same integer polynomial re-counted
over the same coefficients, because the algebra does not know the radix.

Sources: `rtl/cpu.v`, `rtl/ga_ops.v`, `rtl/tmul_opt.v`, `rtl/ternary_gates.v`,
`proofs/lean-src/hexagon/Hexagon/Conventions.lean` (`Mul` L50–51, `norm` L65),
`Conjugate.lean` (L27), `DotWedge.lean` (L32–35), `SymDot.lean` (L33),
`docs/GA_INSTRUCTIONS.md`. Overlaps with `eisenstein_free_ops.md` (the "is it easier" inventory)
and `operation_cost.md` (the address/sense-cost model); this file is the narrower
*arithmetic-vs-arithmetic* emulation table only.

---

## 0. The answer, up front

> **Ternary arithmetic is not cheaper to emulate in binary — it is the *same* op count over the
> same integers, and the only radix-specific deltas are (i) free negation (a wire swap vs
> two's-complement's invert+increment) and (ii) the balanced carry (no sign bit, no
> sign-extension). Every mul/add in the Eisenstein formulas costs exactly the same in binary as
> in ternary; nothing about the ternary datapath makes a multiply or an add go away.**

The reason is structural: every Tau op is an **integer polynomial in the four coefficients**
`a, b, c, d ∈ ℤ` (the word is one lattice point `(a,b) = a + bω`). The number of integer
add/mul/negate operations is fixed by *that polynomial*, not by whether the coefficients are
encoded as 6 balanced trits or as ~10 two's-complement bits. A binary ALU computing the same
polynomial does the same number of operations. The ternary advantage, where one exists, is
**sign handling**, never op count.

---

## 1. The cost model and units

Units are abstract integer operations on the coefficient datapath (a coefficient is a 6-trit
balanced integer in `[−364, 364]`):

- **M** = one scalar integer multiply (coefficient × coefficient)
- **A** = one scalar integer add *or* subtract (same class; a subtract is an add after a negate)
- **N** = one scalar integer negation (sign flip)

The two radix-dependent deltas (everything else is a tie):

| delta | ternary | binary |
|---|---|---|
| **negation** | `tneg`: flip `+1↔−1`, `0→0` — a two-wire swap, **0 gates, 0 carry** (`trit_functions.vh`, `gate_tneg` = 0 cells) | two's-complement `-x = ~x + 1`: bitwise NOT (the binary analog of the wire swap — free) **+ 1 increment** (a carry-in add) |
| **carry** | balanced, `±`-symmetric: no sign bit, no sign-extension on widening, `-z` and `z` symmetric | two's-complement: sign bit is a special asymmetric value; widening requires sign extension |

So in the table, the `M·A·N` counts are **identical** in both columns by construction (same
polynomial). The honest-note column records *where* a negation appears (that is where ternary
saves exactly one increment) and *where it doesn't* (that is where the two machines are tied,
op for op).

---

## 2. The table

Costs are in `M·A·N` units. "neg free" = the ternary `tneg` wire swap (0 gates); the binary `N`
costs ~1 increment (folded as an `A`). `z = (a,b)`, `w = (c,d)`.

| op | result (integer form) | native ternary (DIRECT) | binary emulation (DERIVED) | honest note |
|---|---|---|---|---|
| **TADD** | `(a+c, b+d)` | `0·2·0` | `0·2·0` | **Tie.** Two coefficient adds, identical. Balanced carry removes sign-extension, but the op count is equal. |
| **TSUB** | `(a−c, b−d)` | `0·2·2` (neg **free**) | `0·2·2` (neg ≈ `+1 A` each) | **The one clean ternary win.** Both do 2 adds + 2 negates; ternary negate is a 0-gate swap, binary pays invert+increment per negate. So ternary TSUB = 2 adds, binary = 2 adds + 2 increments. |
| **TMUL** | `(ac−bd) + (ad+bc+bd)ω` | `3·4·2` (Karatsuba) — see §3 | `3·4·2` (same Karatsuba) | **Tie.** Karatsuba is ring-agnostic (valid over any commutative ring, including binary ℤ). And the Eisenstein form is *not* a saving — see §4: it is **+1 add over complex multiply** (the `+bd` cross-term from `ω²=ω−1`). |
| **TNORM** | `a²+ab+b²` | `2·2·1` (opt `(a+b)²−ab`) — see §3 | `2·2·1` (same identity) | **Tie.** The `(a+b)²−ab = a²+ab+b²` identity is ring-agnostic; binary gets the same 3→2 product reduction. Only the final subtract's negate saves 1 increment. |
| **TCONJ** | `(a+b, −b)` | `0·1·1` (neg **free**) | `0·1·1` (neg ≈ `+1 A`) | **Near-tie.** 1 add + 1 negate both sides; the ternary edge is only the free `−b`. Note the `a+b` is a *real* add: Eisenstein conj costs +1 add over complex conjugation `(a,−b)`. |
| **TDOT** | `ac+ad+bd` | `3·2·0` | `3·2·0` | **Pure tie.** 3 muls + 2 adds, no negation anywhere. Identical op for op. |
| **TWEDGE** | `bc−ad` | `2·1·1` (neg **free**) | `2·1·1` (neg ≈ `+1 A`) | **Near-tie.** 2 muls + 1 sub both sides; the only ternary delta is the free negate inside the sub. |
| **TSYMDOT** | `2ac+ad+bc+2bd` | `4·5·0` (shared cell) — see §5 | `4·5·0` | **Pure tie.** 4 muls + 5 adds, no negation. Shares its 4 products with TDOT/TWEDGE in `ga_split_trits`, so its *marginal* cost is 5 adds — but that sharing is radix-independent too. |

One reading of the table: **four of the eight ops (TADD, TMUL, TNORM, TDOT, TSYMDOT — five, in
fact) are op-count ties with zero ternary advantage in arithmetic; the other three (TSUB, TCONJ,
TWEDGE) differ from binary only by a negation each, i.e. one increment per negate.**

---

## 3. TMUL / TNORM: naive vs the RTL's actual form (DIRECT)

The RTL does *not* use the naive 4-product formulas; it uses two ring-agnostic identities that
work identically in binary. This is the specific trap to avoid when counting: **do not price the
binary machine at the naive formula while the ternary machine gets the optimized one.**

**TMUL** — `tmul_eisen_trits` (`tmul_opt.v` L193–235) uses Karatsuba:

```
A = ac − bd                      B = (a+b)(c+d) − ac
```

- `tmul_eisen_trits` (RTL, DIRECT): `3M + 2A + 2S` = `3·4·2` — 3 muls (`ac`, `bd`, `(a+b)(c+d)`),
  2 pre-adds (`a+b`, `c+d`), 2 subs (`A`, `B`).
- `tmul_eisen_naive` (RTL, DIRECT, the reference baseline): `4M + 2A + 1S` = `4·3·1` — 4 muls
  (`ac, ad, bc, bd`), 2 adds (`ad+bc`, `+bd`), 1 sub (`ac−bd`).

Both are valid in binary. Karatsuba trades **1 mul for 1 extra sub**; that trade is no more
ternary than it is binary.

**TNORM** — `tnorm_trits_opt` (`tmul_opt.v` L283–331) uses:

```
N(a,b) = (a+b)² − ab
```

- opt (RTL, DIRECT): `2M + 1A + 1S` = `2·2·1` — 2 muls (`(a+b)²`, `ab`), 1 pre-add (`a+b`),
  1 sub.
- `tnorm_trits` / `tnorm_full` (naive, DIRECT): `3M + 2A` = `3·2·0` — 3 muls (`a², ab, b²`),
  2 adds.

Again the 3→2 product reduction is a polynomial identity, not a ternary property.

---

## 4. The Eisenstein multiply is not a win over complex — it is +1 add (DIRECT)

The premise sometimes floated is that Eisenstein multiplication is *cheaper* than complex
multiplication. It is not. Comparing the naive 4-product forms over the same integer
coefficients:

| ring | relation | product | cost |
|---|---|---|---|
| complex `ℤ[i]` | `i² = −1` | `(a+bi)(c+di) = (ac−bd) + (ad+bc)i` | `4M + 1A + 1S` |
| Eisenstein `ℤ[ω]` | `ω² = ω−1` | `(a+bω)(c+dω) = (ac−bd) + (ad+bc+bd)ω` | `4M + 2A + 1S` |

The `ω² = ω−1` relation injects a `+bd` cross-term into the imaginary coefficient, costing **one
extra add**. So the honest comparison is *not* "Eisenstein ≈ complex"; it is "Eisenstein is
**1 add more expensive** than complex multiply." (The RTL's Karatsuba form `3M+2A+2S` exists for
*both* rings and does not change the ordering.) The ternary advantage in TMUL is therefore
exactly zero — the balanced-ternary digit (free negation, symmetric carry) is a *digit-encoding*
property, not a multiply-count property.

**Correction to the task brief:** the brief wrote `(ac−bd) + (ad+bc−bd)ω`. The `−bd` is a typo —
the correct coefficient is `ad+bc+bd` (`Conventions.lean` L50–51, `Conjugate.lean` L47–48,
`tmul_eisen_naive` L251–271). Similarly, the brief's "4 mul + 3 add + 1 sub" double-counts the
subtract; the naive form is `4M + 2A + 1S`.

---

## 5. The GA split cell: dot/wedge/symdot share 4 products (DIRECT)

`ga_split_trits` (`ga_ops.v` L76–115) computes all three of TDOT, TWEDGE, TSYMDOT from the *same*
four scalar products `ac, ad, bc, bd`:

- `dot   = ac + ad + bd`          → 2 adds over the products
- `wedge = bc − ad`               → 1 sub over the products
- `symdot = 2ac + ad + bc + 2bd`  → 5 adds (`ac+ac, +ad, +bc, +bd, +bd`)

So the **triple** costs `4M + 8A/S` in one cell, and each additional member after the first is
near-free (5 adds for symdot, 2 adds for dot, 1 sub for wedge). But this sharing is **radix
independent** — a binary ALU can compute `2ac+ad+bc+2bd` from the same 4 products with the same
5 adds (or via the `symdot = 2·dot + wedge` identity, `SymDot.lean` L57–58, at `4M + 4A + 1S`).
Nothing here is ternary-specific.

---

## 6. The one-line honest answer

> **Ternary arithmetic is *different*, not cheaper: every Tau op is the same integer polynomial
> with the same mul/add count whether the coefficients are balanced trits or two's-complement
> bits — the only genuine savings are free negation (a wire swap instead of invert+increment) and
> the symmetric balanced carry (no sign bit / no sign-extension), and Eisenstein multiply is
> actually one add *more* expensive than complex multiply, not less.**
