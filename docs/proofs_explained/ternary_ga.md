# Ternary Cell & Geometric-Algebra Proofs — Explained in Plain English

This document explains six Lean 4 modules in
`proofs/lean-src/hexagon/Hexagon/`. Each is a *checked* proof (`lake build`
green, zero `sorry`), but the theorems read like formal algebra. Here they are
translated into what they actually prove, why it matters for the Tau
Architecture, and how the proof works.

The six modules form one story:

1. **TernaryCell / PolarEncoding / PolarGate** — the *physical trit*: how a
   balanced ternary digit {−1, 0, +1} lives on two wires and does arithmetic.
2. **Conjugate / DotWedge / SymDot** — the *geometric algebra* on top of it: how
   the geometric product of two Eisenstein integers splits into a symmetric
   scalar (correlation) and a skew bivector (circulation).

---

## 1. TernaryCell.lean

### What it proves

The core claim: a **balanced ternary cell** encoded "one-hot-per-direction" onto
two wires is genuinely cheaper than binary. Concretely:

- `energy_pos`, `energy_zero`, `energy_neg`, `null_is_free` — the three states
  {+1, 0, −1} cost **1, 0, 1** energized lines respectively; the null (zero)
  state is free.
- `energy_le_one` — at most **one** line is ever energized per state (the whole
  point of "one-hot").
- `total_energy` — summed over all 3 trits, the total energy is **2**.
- `card_trit` — there are 3 trits.
- `average_energy` — therefore the average is **2/3** of a wire per trit.
- `binary_total_energy`, `card_bool_pair`, `binary_average_energy` — a uniform
  plain 2-bit binary word averages **1** energized wire per state (total 4 over
  4 states).
- `ternary_saves_third` — since 2/3 < 1, ternary uses **2/3** the energized lines
  of binary: a **1/3 saving**.
- `encode_never_both` — the encoding never produces the `(true, true)` "both
  lines on" state.
- `encode_injective` — the 3 trits map to 3 distinct wire-pairs.
- `encode_not_surjective` — but NOT onto all 4 wire-pairs: `(true, true)` has no
  preimage, so that state is **reusable / shareable**.

### Why

This is the physical layer of the Tau Architecture. The idea (Ian, 2026) is that
a trit is the *polarity/direction* of electrons: a push line and a pull line, with
at most one energized at a time. Because the "both on" state is never used, its
hardware can be **reused** (overlapped) — and because two of three states cost 1
line and one costs 0, the average static/transfer energy is lower than a plain
2-bit binary encoding. It's a concrete energy argument, not a metaphor.

### The method

Pure **finite case analysis**. Every theorem is a `decide` (or a `cases t <;>
decide`) over the finitely many values — Lean literally checks each of the 3 (or
4) cases. The one structural theorem, `encode_not_surjective`, is a short
contradiction: assume `(true, true)` has a preimage `t`, then `encode_never_both`
contradicts it. The averages use `norm_num` on rationals.

### Step-by-step (the two important theorems)

**`average_energy` (2/3 of a wire per trit).**
1. `total_energy` already says the sum over the 3 trits is 2, and `card_trit` says
   there are 3 trits.
2. Rewrite both into the fraction `2 / 3` over `ℚ`.
3. `norm_num` confirms the arithmetic. Done — the average is exactly 2/3.

**`encode_not_surjective` (the 4th state is free hardware).**
1. Suppose, for contradiction, that `encode` is surjective — every wire-pair is
   hit by some trit.
2. In particular, `(true, true)` is hit: there is a trit `t` with
   `encode t = (true, true)`.
3. But `encode_never_both t` says exactly that this never happens.
4. Contradiction — so the encoding is not surjective, and `(true, true)` is a
   "don't-care" state available for reuse.

---

## 2. PolarEncoding.lean

### What it proves

The *same* one-hot encoding, now given an explicit polar (sign + magnitude)
reading and a **decode round-trip**:

- `polarEncode_never_eleven` — the 2-bit code `(1,1)` is never produced. (Here
  the code is written in the conventional 2-bit notation the task brief uses:
  +1 → 01, 0 → 00, −1 → 10, with 11 = NEVER.)
- `polarEncode_injective` — the 3 valid trits map to 3 distinct codes.
- `polarEncode_not_surjective` — but not onto all 4 codes: `(1,1)` has no
  preimage (the "don't-care").
- `polarDecode_encode` — **round-trip**: `decode (encode t) = t` for every trit.
  Decode is a left-inverse of encode.

### Why

This is the polar view of a trit — a **sign** (−1/0/+1) and a **magnitude**
(energized-or-not). It matters because it fills the gap `TernaryCell.lean`
leaves: it *defines the decode*, the inverse that turns the 2-bit code back into
a trit. The `(1,1)` state falls through to some arbitrary branch, but because it
is never produced that choice is harmless (a genuine don't-care). The same
injective-but-not-surjective shape from `TernaryCell.lean` reappears, confirming
the two files agree.

### The method

`fin_cases` + `decide`. The trit is `Fin 3`, so `fin_cases t` splits into 0, 1, 2
and `decide` checks each. `polarEncode_not_surjective` is the same contradiction
as before (assume `(1,1)` has a preimage, contradict `polarEncode_never_eleven`).

### Step-by-step (the important theorem)

**`polarDecode_encode` (decoding recovers the trit).**
1. `fin_cases t` splits the goal into the three trits −1, 0, +1.
2. For each, `polarEncode t` is a concrete pair — e.g. for +1 it is `(0,1)`.
3. `polarDecode` of that concrete pair is exactly the trit back — e.g.
   `decode (0,1) = +1`.
4. `decide` checks each of the three equalities. Done.

---

## 3. PolarGate.lean

### What it proves

The full **gate semantics** of balanced ternary, on `Fin 3` as the field F₃ = Z/3.
Two families:

**Unary** (one trit in → one trit out):
- `neg_neg` — negation is an involution (double-negation is identity).
- `neg_tritInt` — `neg` is the balanced sign-flip: it negates the integer value.
- `ident_def` — the identity gate is the identity.
- `rot1_three`, `rot2_three` — `rot1` (add 1) and `rot2` (add 2) are **3-cycles**
  (order 3): applying either three times returns to the start.
- `rot2_rot1`, `rot1_rot2` — `rot1` and `rot2` are mutual inverses.

**Binary lattice** (two trits in → one out), `tmin` / `tmax`:
- `tmin_comm` — balanced min is commutative.
- `tmax_idem` — balanced max is idempotent.
- `tmin_absorb` — absorption: `min a (max a b) = a`.
- `tmin_neg_pos`, `tmax_neg_pos` — truth-table samples: min(−1,+1) = −1,
  max(−1,+1) = +1.

**Binary field** (the F₃ arithmetic), `tsum` / `tprod`:
- `tsum_comm`, `tprod_comm` — balanced sum and product are commutative.
- `tsum_zero` — 0 is the additive identity.
- `tsum_neg` — `neg t` is the additive inverse of `t`.
- `neg_tsum` — negation distributes over sum (a group homomorphism).
- `tprod_distrib` — **the field-pair completeness anchor**: product distributes
  over sum, which is what makes the carrier a field F₃.
- `tsum_plus_one`, `tsum_22` — truth-table samples: +1 + +1 = −1 (balanced carry),
  and 2 + 2 ≡ 1 (mod 3).

### Why

The balanced ternary gate of the hex architecture. Its unary part is the Z₆ hex
rotation restricted to the Z₃ subgroup (the two 3-cycles plus negation and
identity); its binary part is the balanced lattice (min/max) *and* the field
arithmetic of F₃ (sum/product). The distributivity law `tprod_distrib` is singled
out as the "field-pair completeness anchor" — it is what upgrades the carrier
from a bare set to the finite field F₃, on which all the later geometric-algebra
machinery (Conjugate, DotWedge) sits.

### The method

`fin_cases` + `decide` (+ `rfl` for the identity gate). The unary theorems split
over 3 cases; the binary theorems split over 3 × 3 = 9 cases; the distributivity
law splits over 3 × 3 × 3 = 27 cases — all brute-forced by `decide`. There is no
"clever" algebra; the value of the module is that the *definitions* (the residue
digit convention) are set up so that everything is literally true field
arithmetic.

> **Convention note (worth reading).** The file carefully flags that the digit
> mapping "0 = −1, 1 = 0, 2 = +1" from the task brief is *inconsistent* with the
> required identities (it would force `tsum t 0 = t` to fail). The consistent
> mapping — the one used here — is the **residue** mapping: digit `0` = balanced
> 0, `1` = +1, `2` = −1. Under it, `+`/`*`/`−` on `Fin 3` are exactly F₃, and
> `neg 1 = 2` reads "+1 flips to −1".

### Step-by-step (the two important theorems)

**`rot2_rot1` (rot2 inverts rot1).**
1. `fin_cases t` splits into the three digits 0, 1, 2.
2. `rot1` adds 1 and `rot2` adds 2; composed they add 3 ≡ 0 (mod 3).
3. `decide` checks `rot2 (rot1 t) = t` for each of the three digits. Done.

**`tprod_distrib` (the field-pair completeness anchor).**
1. `fin_cases` on `a`, `b`, `c` produces 27 concrete triples.
2. For each, `tprod a (tsum b c)` and `tsum (tprod a b) (tprod a c)` are computed
   as integers mod 3.
3. `decide` confirms they are equal in all 27 cases — distributivity holds, so
   the carrier is the field F₃.

---

## 4. Conjugate.lean

### What it proves

The **Eisenstein conjugate** `a+bω ↦ (a+b)−bω`, and its interaction with the norm
`N(a+bω) = a² + ab + b²`:

- `conj_involutive` — conjugating twice returns the original (it's an involution).
- `conj_norm` — conjugation **preserves the norm**: `N(conj z) = N z`.
- `conj_mul` — conjugation is a **ring automorphism**: `conj(z·w) = conj z · conj w`.
- `mul_conj_eq_norm` — the key fact: `z · conj z = ⟨N z, 0⟩`, i.e. a real scalar
  equal to the norm. This is what makes the dot/wedge split work.

### Why

The conjugate is the coordinate mirror `ω̄ = ω⁻¹ = 1 − ω`, where
`ω = e^(iπ/3)` (the 60° Eisenstein unit; `ω² = ω − 1`). In the standard
complex-conjugate story, `z·z̄` is the *real* squared modulus `|z|²`. Here the
same identity holds in the Eisenstein integers: multiplying an element by its
conjugate collapses the `ω` (bivector) part to zero and leaves the (always
nonnegative) norm. This is the geometric-algebra instruction `TCONJ`, and it is
the building block the dot/wedge split needs — you have to be able to conjugate
`w` before you can project `z·conj w` into its scalar and bivector parts.

### The method

`rcases` + `change` + `ext <;> ring`. Each theorem:
1. `rcases z with ⟨a, b⟩` (and `w with ⟨c, d⟩`) to expose the integer components.
2. `change` rewrites the abstract goal into explicit component arithmetic (the
   `Mul`/`norm` instances don't auto-unfold).
3. `ext <;> ring` proves the two component equalities by integer-ring rewriting.

### Step-by-step (the two important theorems)

**`conj_norm` (conjugation preserves the norm).**
1. Unpack `z = ⟨a, b⟩`.
2. `change` the goal into the concrete form
   `(a+b)² + (a+b)(−b) + (−b)² = a² + ab + b²`.
3. `ring_nf` expands and cancels; both sides are the same quadratic. Done.

**`mul_conj_eq_norm` (z·z̄ = N(z) — the key fact).**
1. Unpack `z = ⟨a, b⟩`.
2. `change` the multiplication `z * conj z` into its explicit components:
   `⟨a(a+b) − b(−b), a(−b) + b(a+b) + b(−b)⟩`.
3. The target is `⟨a²+ab+b², 0⟩` — the norm, with zero bivector part.
4. `ext <;> ring` shows the first coordinate equals `a²+ab+b²` and the second is
   0. So the product with the conjugate is purely scalar, and equals the norm.

---

## 5. DotWedge.lean

### What it proves

The **geometric product splits into a symmetric scalar (dot) and a skew bivector
(wedge)**. For Eisenstein elements `z, w`, define `dot z w` as the `a`-coordinate
and `wedge z w` as the `b`-coordinate of `z · conj w`. Then:

- `gp_decomp` — the geometric product decomposes exactly as
  `z · conj w = ⟨dot z w, wedge z w⟩` (scalar + bivector).
- `dot_swap` — **the honest subtlety**: the raw dot is *not* symmetric. Instead
  `dot z w = dot w z + wedge w z`. Swapping the arguments corrects the asymmetry
  by exactly the wedge. (The original `dot_comm` was FALSE — see below.)
- `wedge_antisymm` — the wedge is anti-symmetric: `wedge z w = − wedge w z`
  (the curl flips sign under swap).
- `dot_self` — `dot z z = N z`: the self-dot is the norm.
- `wedge_self` — `wedge z z = 0`: the self-wedge vanishes (one vector spans no
  area).
- `dot_sq_add_wedge_sq` — the Pythagorean identity:
  `dot² + dot·wedge + wedge² = N z · N w`, the full energy decomposition.

### Why

This is the geometric-product instruction pair `TDOT` / `TWEDGE`. In geometric
algebra the product `z·w̄` of two vectors carries a scalar part (the dot = how
much they **correlate** / align) and a bivector part (the wedge = how much they
**circulate** / curl). The lattice's own "correlation vs circulation" split —
symmetric surprise vs. skew temporal-precedence — is exactly this, on the
Eisenstein lattice. The rebuild's wedge is the **skew part** (Hestenes-Sobczyk:
"determined by its curl"), *not* the bivector area.

### The honest subtlety (read carefully)

The naive guess is that `dot` is symmetric (`dot z w = dot w z`). It is **not**.
Because `z·conj w`'s `a`-coordinate is `Re(z·w̄) − wedge/2` — a **half-integral**
quantity — the raw `a`-coordinate picks up a half-wedge's worth of the skew part.
The file even gives the counterexample: `z = ⟨1,0⟩`, `w = ⟨0,1⟩` gives
`dot z w = 1` but `dot w z = 0`. So the correct law is the *swap* law
`dot z w = dot w z + wedge w z`, which is exactly `dot_swap`. This is the module's
main contribution: it catches a false claim and replaces it with the true one.

### The method

`rcases` + `change` + `ring`, exactly as in `Conjugate.lean`. The Pythagorean
identity is different and elegant: it does *not* expand components. Instead it
uses that the norm is multiplicative (`norm_mul`) and conjugation preserves the
norm (`conj_norm`):
`N(z·conj w) = N z · N(conj w) = N z · N w`.

### Step-by-step (the three important theorems)

**`dot_swap` (the honest subtlety).**
1. Unpack `z = ⟨a, b⟩`, `w = ⟨c, d⟩`.
2. `change` both sides into explicit components: left is
   `a(c+d) − b(−d)`; right is `c(a+b) − d(−b) + [c(−b) + d(a+b) + d(−b)]`.
3. `ring` shows the equality. The extra `wedge w z` term on the right is exactly
   what repairs the asymmetry.

**`wedge_antisymm` (curl flips under swap).**
1. Unpack both elements.
2. `change` the goal into `a(−d) + b(c+d) + b(−d) = −[c(−b) + d(a+b) + d(−b)]`.
3. `ring` — the left is the negation of the right. The wedge changes sign.

**`dot_sq_add_wedge_sq` (the Pythagorean energy split).**
1. `dot² + dot·wedge + wedge²` is by definition `N(z·conj w)` (it's the norm of
   the element `⟨dot, wedge⟩ = z·conj w`).
2. `change` the goal to `N(z·conj w) = N z · N w`.
3. `rw [norm_mul, conj_norm]`: norm is multiplicative and conjugation preserves
   it, so `N(z·conj w) = N z · N(conj w) = N z · N w`. Done — no component
   grinding at all.

---

## 6. SymDot.lean

### What it proves

The **symmetric integer correlation** — the fix for the raw dot's asymmetry. It
is the **polarization of the norm**:

- `symdot_comm` — `symdot` IS symmetric: `symdot z w = symdot w z`. (This is the
  commutativity the raw `dot` failed to have.)
- `symdot_self` — `symdot z z = 2·N z` (the norm is quadratic, so
  `N(z+z) = N(2z) = 4·N(z)`).
- `symdot_eq_two_dot_add_wedge` — the bridge to `DotWedge.lean`:
  `symdot z w = 2·dot z w + wedge z w`, i.e. `2·Re(z·w̄)`.
- `symdot_nonneg` — `0 ≤ symdot z z`: the self-correlation is nonnegative.

### Why

`DotWedge.lean` discovered that the raw `dot` (the `.a` coordinate of `z·conj w`)
is not symmetric, because `Re(z·w̄)` is half-integral. The clean, **integer**,
**symmetric** correlation is the *polarization of the quadratic form N*:

```
symdot z w  =  N(z+w) − N(z) − N(w)  =  2·Re(z·w̄)  =  2·dot z w + wedge z w
```

Polarizing a quadratic form always yields a symmetric bilinear form — so
`symdot_comm` holds *by construction*, for free, where `dot_comm` failed. This is
the object you want when you need a correlation that is honest (integer-valued)
and symmetric (order-independent).

### The method

`rcases` + `change` + `ring` / `ring_nf`, plus `nlinarith` for the nonnegativity
argument. The nonnegativity proof is the one clever bit: it reduces to
`N = a²+ab+b² = ((a+b)² + a² + b²)/2 ≥ 0`, using `sq_nonneg` (squares are
nonnegative) and `nlinarith`.

### Step-by-step (the two important theorems)

**`symdot_comm` (symdot IS symmetric).**
1. Unpack `z = ⟨a, b⟩`, `w = ⟨c, d⟩`.
2. `change` both sides into the explicit polarization
   `(a+c)² + (a+c)(b+d) + (b+d)² − (a²+ab+b²) − (c²+cd+d²)` and its swap.
3. `ring` — the two expansions are identical. Symmetry falls out of the algebra.

**`symdot_eq_two_dot_add_wedge` (the bridge to DotWedge).**
1. Unpack both elements.
2. `change` the left (the polarization) and the right
   `2·(a(c+d) − b(−d)) + (a(−d) + b(c+d) + b(−d))` into explicit components.
3. `ring_nf` — both reduce to `2ac + ad + bc + 2bd`. This is the identity
   `symdot = 2·dot + wedge`, i.e. twice the real part of `z·w̄`.

---

## The thread that ties it together

1. **TernaryCell / PolarEncoding** establish the *carrier*: three balanced states
   on two wires, one-hot, with a free "don't-care" fourth state — injective but
   not surjective, and 1/3 cheaper in energized lines than binary.
2. **PolarGate** upgrades that carrier to the *field* F₃ — sum, product,
   distributivity — the arithmetic the rest of the stack computes in.
3. **Conjugate** provides the *mirror* (`ω̄ = 1 − ω`) and the key identity
   `z·z̄ = N(z)`.
4. **DotWedge** uses that mirror to *split the geometric product* into a scalar
   (dot = correlation) and a bivector (wedge = circulation), and honestly reports
   that the naive dot is half-integral and non-symmetric.
5. **SymDot** *repairs* that asymmetry with the polarization of the norm — the
   true integer, symmetric correlation.

The most important single theorem is **`gp_decomp` / `dot_sq_add_wedge_sq`** in
`DotWedge.lean` (with `SymDot`'s `symdot_eq_two_dot_add_wedge` as its symmetric
repair): it proves the geometric product `z·w̄` decomposes into a symmetric dot
(correlation) plus a skew wedge (circulation), whose squares satisfy the
Pythagorean energy identity `dot² + dot·wedge + wedge² = N(z)·N(w)`.
