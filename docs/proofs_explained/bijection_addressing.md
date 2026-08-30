# How a Hex Address Fills 32 Bits — the Addressing Proofs, Explained

This document explains six Lean proof modules in the Hexagon project, in plain
English for readers who don't read Lean. Together they establish the addressing
machinery that underlies the hex-lattice/ternary project: how a hexagonal grid of
cells gets *numbers* as addresses, how those numbers fill the 32-bit space exactly,
and how the hex coordinate system relates to (and refines) the binary XOR-kernel
address the project started from.

The files live in `proofs/lean-src/hexagon/Hexagon/`. Each section names the
theorems by their actual names in the source, states what they prove in words, and
gives the intuition and the proof strategy.

> **Reading convention.** Throughout, "**DIRECT**" is a calibration label the
> project attaches to each claim: it means the theorem is standard mathematics
> (finite case analysis, ring algebra, modular arithmetic) rather than an analogy
> or speculation. Where a claim is still **SPECULATION**, the file says so explicitly
> and does *not* claim to prove it. The document below preserves that distinction
> faithfully.

---

## 1. `Bijection.lean` — a hex cell is a number

### What it proves

The file proves that the infinite hexagonal grid of cells — written as **axial
coordinates** `(a, b)`, i.e. pairs of integers, equivalently **Eisenstein
integers** `a + bω` — is in *one-to-one correspondence* with the natural numbers
`0, 1, 2, …`. Every cell gets a unique number, and every number names a unique
cell. The main results:

- **`signFold_signUnfold`** — folding an integer `z` to a natural and then
  unfolding recovers `z` exactly (fold has a right inverse).
- **`signUnfold_signFold`** — unfolding a natural and then folding recovers the
  natural exactly (fold has a left inverse). Together these say **fold is a
  bijection** between integers and naturals.
- **`toNat_ofNat` / `ofNat_toNat`** — the two directions of the full
  address map round-trip: encoding a cell to a number and decoding it back gives
  the same cell, and vice versa.
- **`hexPairEquiv`** — the packaged bijection `ℤ × ℤ ≃ ℕ` (axial coordinates ≃ naturals).
- **`toNat_bijective`** — the address function `toNat` is a genuine bijection.
- **`eisensteinToNat` / `eisensteinOfNat` / `eisensteinEquiv`** — the same
  bijection stated for **Eisenstein integers** `ℤ[ω] ≃ ℕ`.
- **`pair_lt_two_pow_32`** — two values each below `2¹⁶` pack into a number below `2³²`.
- **`signFold_lt`** — a coordinate inside the box `−2¹⁵ … 2¹⁵−1` folds below `2¹⁶`.
- **`toNat_lt_two_pow_32`** — any cell whose two coordinates lie in that box gets
  an address below `2³²` (it *fits in a 32-bit unsigned integer*).
- **`toNat_fin`** — that address is a valid value of the bounded type `Fin (2³²)`.

### Why

The project's original addressing kernel was a **u32 XOR kernel**: an address is a
32-bit integer and operations run on it by bit-twiddling. The idea on the table was
that "hex addressing *replaces* the u32 XOR kernel." Before anyone could evaluate
that idea, someone had to actually *define* a way to turn a hex cell into a
32-bit number — and prove it's well-behaved (one-to-one, no collisions, no gaps).
This file is that first step: the bijection itself. The header is careful to say
the *bijection* is **DIRECT** (standard), while the *upgrade claim* that hex
addressing *replaces* the XOR kernel stays **SPECULATION** and is not proved here.

A crucial design detail: the whole 32-bit space is used *exactly*. Two 16-bit
sign-folds pack into a u32 with no waste. The corner case is the headline: the
cell `(−2¹⁵, −2¹⁵)` encodes to `2³²−1` — the very maximum of a `u32` — and nothing
overflows. This matches the `to_u32 : (i64, i64) → u32` function in the Rust mirror
`rust-mirror/src/bijection.rs`.

### The method

- Sign-fold `ℤ → ℕ` and its inverse: **finite case analysis** on parity/sign (`by_cases`),
  closed with `omega` (linear integer arithmetic).
- The pairing round-trips: **definitional rewriting** (`simp`) delegating to mathlib's
  already-proved `Nat.pair`/`Nat.unpair` bijection.
- The `2³²` bound: **nonlinear integer arithmetic** (`nlinarith`, `norm_num`, `omega`).

### Step-by-step (the important ones)

**1. `signFold` / `signUnfold` are mutual inverses.** A signed integer can be
"folded" onto the naturals by interleaving positives and negatives:
`0 ↦ 0, 1 ↦ 1, −1 ↦ 2, 2 ↦ 3, −2 ↦ 4, …` (formally `fold(z) = 2|z|` for `z ≥ 0`,
`2|z|−1` for `z < 0`). The proof shows:
- *Folding then unfolding gives back the original natural.* Split on whether `n` is
  even or odd. If even, unfold gives `n/2`, whose fold is `2·(n/2) = n`; if odd,
  unfold gives `−(n+1)/2`, whose fold is `2·((n+1)/2) − 1 = n` (using that for odd
  `n`, `(n+1)/2` is the right half).
- *Unfolding then folding gives back the original integer.* Split on whether `z < 0`.
  The negative branch shows `−(2|z|−1 + 1)/2 = −|z| = z`; the non-negative branch
  shows `(2|z|)/2 = |z| = z`.

**2. `toNat` / `ofNat` round-trip, i.e. `hexPairEquiv`.** The address of a cell
`(a, b)` is `pair(fold a, fold b)` using **Szudzik pairing** `pair(a,b) = b²+a`
when `a < b` and `a²+a+b` otherwise. Decoding is `(unfold (unpair n).1, unfold
(unpair n).2)`. Because each of the three ingredients (fold, pair, unfold/unpair)
is already a bijection, composing them and unpacking with `simp` closes both
round-trips in one line each. This is the "prefer mathlib's theorem" rule in
action: `Nat.pair` is already proved a bijection in mathlib, so the file does not
re-prove pairing.

**3. `toNat_lt_two_pow_32` (the u32 bound).** The key decision is *why Szudzik and
not Cantor*. The Cantor pairing `(a+b)(a+b+1)/2 + b` needs **33 bits** to hold two
16-bit coordinates, but Szudzik's `a²+a+b` fits them in **exactly** 32 bits. The
proof:
- First establish `signFold_lt`: a coordinate in `[−2¹⁵, 2¹⁵−1]` folds below `2¹⁶`
  (the fold sends exactly that box onto all of `[0, 2¹⁶−1]`).
- Then `pair_lt_two_pow_32`: given `x, y < 2¹⁶`, bound `pair x y < 2³²` by cases.
  In the `x < y` branch, `y² + x ≤ (2¹⁶−1)² + (2¹⁶−2) < 2³²`; in the other branch,
  `x² + x + y ≤ (2¹⁶−1)² + (2¹⁶−1) + (2¹⁶−1) = 2³²−1 < 2³²` (the `nlinarith`
  steps prove the inequalities, `norm_num` checks the constants).
- Chain the two: in-box coordinates ⇒ folded coords `< 2¹⁶` ⇒ paired address `< 2³²`.

**Provenance (header).** *"the SPECULATION 'hex addressing replaces the u32 XOR
kernel' (AGENTS.md §Quantum Properties; PROVER_NOTES 'Remaining' — 'blocked until
someone defines the bijection'); hexigon_conversation.md L10005–10105 (7-hex ↔
balanced ternary) — this file lifts that to a bijection of the *whole* lattice
`ℤ² ≃ ℕ`, so every hex cell … gets a natural-number address."*

---

## 2. `Registers.lean` — the register ladder (raw → fold → z → surprise)

### What it proves

This file formalizes the project's "register stack" from the Rust rebuild's
`gauge.rs`: the same edge information is held at several levels — the **raw** rung
`E·δ`, the **fold** `δ`, the **z** rung `√E·δ`, and the **surprise** `E·δ²`. The
main results:

- **`δ_eq_residual_div`** — the fold `δ = O/E − 1` equals the residual `r = O − E`
  divided by the expected count `E` (the *Pearson residual* form).
- **`mul_delta_eq_residual`** — multiplying the fold by the expected count
  recovers the signed residual: `E·δ = r` (the raw rung is the residual itself).
- **`surprise_eq_delta_sq_mul_E`** — the surprise register is the square of the
  fold, rescaled by the expected count: `surprise = δ²·E`.
- **`E_nonneg`** — the expected count is always `≥ 0` (needed for the sign results below).
- **`surprise_nonneg`** — the surprise `r²/E` is always `≥ 0`.
- **`surpriseOf` / `surprise_sign_collapse`** — squaring **kills the sign**: the
  surprise of `r` equals the surprise of `−r`.
- **(the `example` witness)** — surprise is *not* symmetric in its pair: on a
  two-symbol vocabulary with one directed count `O(⊤,⊥) = 2` and all else zero,
  `surprise(⊤,⊥) = 9/2 ≠ 1/2 = surprise(⊥,⊤)`. An attractive pair can masquerade as
  repulsive (and vice versa) if you only keep the squared register.
- **`wedge_eq_residual_skew`** — the wedge `O(a,b) − O(b,a)` equals the skew of the
  residual `r(a,b) − r(b,a)` (the symmetric `E` terms cancel).
- **`sym_plus_skew`** — the observed table splits into its symmetric part plus its
  antisymmetric (wedge) part: `O(a,b) = (O(a,b)+O(b,a))/2 + (O(a,b)−O(b,a))/2`.

### Why

The rebuild computes a *ladder* of quantities from one primitive — the signed
residual `r = O − E` (observed minus expected co-occurrence count). The register
ladder is just the same number in different gauges: the fold `δ` re-centers the
multiplicative excess at 0, the raw rung re-multiplies it back to `r`, and the
surprise squares it. The point of *proving* the ladder relations is to settle a
flagged "PROVE-THE-MATH" item in `gauge.rs` and to make precise a subtle and
consequential fact: **squaring (the surprise/χ² register) discards the sign of the
residual**, so the sign — the difference between *attract* (`O < E`, repulsion) and
*repel* (`O > E`) — lives in the residual/fold register, not in the surprise
register. This matches the project-wide rule that the χ² magnitude is ORDER, not
surprise.

### The method

- Ladder identities: **field algebra** (`field_simp` + `ring`) over ℚ, where
  division by `E` is exact.
- Non-negativity: **`div_nonneg` / `sq_nonneg`** applied to the definition.
- Sign collapse: **`ring`** (a direct algebra simplification).
- Wedge = skew: **`ring`** plus the fact that `E` is symmetric in `a, b`.
- The asymmetry witness: **finite case analysis with `decide`/`norm_num`** on `Bool`.

### Step-by-step (the important ones)

**1. The ladder hangs together (`δ_eq_residual_div`, `mul_delta_eq_residual`,
`surprise_eq_delta_sq_mul_E`).** Unfolding the definitions, `δ = O/E − 1` and
`r = O − E`, so `δ = r/E` by `field_simp` (multiply through by the nonzero `E`).
Multiplying back, `E·δ = r`. Substituting `r = E·δ` into `surprise = r²/E` gives
`surprise = (E·δ)²/E = δ²·E`. The three one-line `field_simp`/`ring` proofs are
literally "clear denominators and expand." They show the four rungs are the same
object viewed through four gauge changes — no new information, just a change of
scale.

**2. Squaring collapses the sign (`surprise_sign_collapse`).** The surprise of a
signed residual `r` against an expected count `e` is `r²/e`. The surprise of `−r`
is `(−r)²/e = r²/e` — the same. This is why the surprise register can never tell
attraction from repulsion: the χ² magnitude records *how far* the count is from
expectation, but not *which direction*. The direction (the sign) is carried by the
residual register.

**3. The Helmholtz split (`sym_plus_skew`).** Every ordered table entry decomposes
into a symmetric half (what `a` and `b` share, `(O(a,b)+O(b,a))/2`) and an
antisymmetric half (the skew/wedge, `(O(a,b)−O(b,a))/2`). `wedge_eq_residual_skew`
complements this by noting that subtracting the two directions cancels the
expected-count term (since `E(a,b) = E(b,a)`), so the wedge can be read off either
the observed counts or the residuals. This is the "wedge = the *skew part*" result,
citing `wedge_antisymm` from `Hexagon.Residual` rather than re-proving it.

**Provenance (header).** *"the rebuild's `gauge.rs` (register stack raw `E·δ`, fold
`δ`, z `√E·δ`, surprise `E·δ²`) and LATTICE_MATH.md; the porting map flagged this as
the top B→A formalization (settles gauge.rs's 'PROVE-THE-MATH #3' untested flag)."*

---

## 3. `ConventionBridge.lean` — the 60° and 120° Eisenstein conventions are the same ring

### What it proves

The project uses the Eisenstein integer `ω = e^(iπ/3)` at a **60°** angle (norm
`a² + ab + b²`), while the rebuild's `gauge_int.rs` uses `ω' = e^(2πi/3)` at
**120°** (norm `a² − ab + b²`). This file proves the two are *literally the same
ring*, just written with a different generator. The main results:

- **`mul120`** — the definition of multiplication in the 120° convention (using `ω'² = −ω'−1`).
- **`norm120`** — the 120° norm `a² − ab + b²`.
- **`phi_add`** — the map `φ(a,b) = (a, −b)` is additive: `φ(x+y) = φx + φy`.
- **`phi_mul`** — `φ` interchanges the 60° and 120° multiplications:
  `φ(x·y) = mul120(φx)(φy)`. **This is the crux.**
- **`phi_phi`** — `φ` is its own inverse: `φ(φx) = x` (hence `φ` is a bijection).
- **`norm_preserved`** — the norm is preserved under `φ`: `norm x = norm120 (φx)`.

### Why

Ian's note in the header: *"the 120 may be bad… I think it is just a normalisation
difference… would be great if it's all the same."* The worry was that two codebases
had settled on two different Eisenstein conventions, and one might be subtly wrong.
The bridge resolves it: because `ω' = ω² = ω − 1`, the rings `ℤ[ω]` and `ℤ[ω']`
are the *same* set of numbers, and the flip `φ(a,b) = (a, −b)` translates cleanly
between them while preserving all structure (addition, multiplication, and the
norm). The two conventions differ only by a change of basis, not in substance.

### The method

- Every theorem: **`rcases` (unpack coordinates) + `change` (expand the
  definitions) + `ext <;> ring`** — i.e. coordinate-wise polynomial identity
  checking. `phi_mul` is the same pattern applied to the multiplication table.

### Step-by-step (the important ones)

**1. `phi_mul` — the multiplication tables trade places.** Expand `x·y` in the 60°
convention: `(a+bω)(c+dω) = (ac−bd) + (ad+bc+bd)ω`. Apply `φ` (negate the `ω`
coefficient), and compare to the 120° product `mul120(φx)(φy)` computed with
`ω'² = −ω'−1`. The two come out equal after `ring` simplifies both polynomials.
This is the statement that "`ω ↦ −ω` sends the 60° multiplication to the 120°
multiplication," so nothing is lost in translation.

**2. `phi_phi` — φ is an involution.** Negating the second coordinate twice returns
the original element. An involution is automatically bijective, so `φ` is an
isomorphism of the underlying sets, and combined with `phi_add` + `phi_mul` it is a
*ring isomorphism*.

**3. `norm_preserved` — the norm survives.** `norm(a+bω) = a² + ab + b²`, while the
120° norm of `φ(a+bω) = a − bω'` is `a² − a·(−b) + (−b)² = a² + ab + b²`. `ring`
shows they are identical. So distances/energies computed in either convention agree.

**Provenance (header).** *"the rebuild's `gauge_int.rs` uses ω' = e^(2πi/3) (120°,
norm a²−ab+b²), while this project's `Conventions.lean` uses ω = e^(iπ/3) (60°, norm
a²+ab+b²). Ian (2026): 'the 120 may be bad… I think it is just a normalisation
difference… would be great if it's all the same.'"*

---

## 4. `OmegaEmbedding.lean` — the abstract ring really is the 60° hexagonal lattice

### What it proves

The Eisenstein ring `ℤ[ω]` is defined *abstractly* (a pair of integers with
`ω² = ω − 1`). This file proves that this abstract ring embeds into the complex
numbers **as the 60° lattice**: sending `ω ↦ e^(iπ/3) = 1/2 + (√3/2)i` places the
two basis vectors `1` and `ω` on the two unit vectors 60° apart — which is exactly
the hexagonal lattice. The main results:

- **`omegaC_eq`** — Euler's formula at `π/3`: `e^(iπ/3) = 1/2 + (√3/2)i`.
- **`omega_sq_rel`** — in ℂ, `ω² = ω − 1` (the Eisenstein defining relation is
  realized by the actual complex number).
- **`omegaC_re` / `omegaC_im`** — the real part is `1/2`, the imaginary part `√3/2`.
- **`phi_add`** — the embedding `φ(a+bω) = a + b·ω` is additive.
- **`phi_mul`** — `φ` is multiplicative (uses `omega_sq_rel`).
- **`phi_omega`** — the abstract generator `⟨0,1⟩` maps to `e^(iπ/3)`.
- **`phi_injective`** — `φ` is injective: `1` and `ω` are linearly independent over
  ℤ inside ℂ, so no two different Eisenstein integers collide.

### Why

The "diamond motif" and Ian's *"einstein triangles of 60 degrees"*: the project's
hexagon is genuinely the 60° lattice, and this file pins the abstract ring to the
concrete geometry. Once `φ` is a ring *homomorphism* (additive + multiplicative)
that sends `ω` to the right complex number and is injective, the abstract `ℤ[ω]`
**is** the hexagonal lattice in ℂ — the coordinates `(a, b)` are exactly the integer
combinations of the two 60°-separated unit vectors. This connects the algebra (the
ring, the norm) to the geometry (the actual hex tiling) without any hand-waving.

### The method

- `omegaC_eq`: **Euler's formula** (`Complex.exp_ofReal_mul_I`) + the known
  `cos(π/3) = 1/2`, `sin(π/3) = √3/2`.
- `omega_sq_rel`: **`norm_num` + `ring_nf`**, rewriting `√3` squared back to `3`.
- `phi_add` / `phi_mul`: **`push_cast` + `ring`/`ring_nf`**, with `phi_mul` using
  `omega_sq_rel` to reduce `ω²`.
- `phi_injective`: **`congrArg` on real and imaginary parts** + `mul_right_cancel₀`
  (divide by `√3/2 ≠ 0`) + `linarith`.

### Step-by-step (the important ones)

**1. `omega_sq_rel` — `ω² = ω − 1` is real.** First `omegaC_eq` computes
`e^(iπ/3) = 1/2 + (√3/2)i` by Euler's formula and the known trig values. Then
squaring it: `(1/2 + (√3/2)i)² = 1/4 − 3/4 + 2·(1/2)(√3/2)i = −1/2 + (√3/2)i`,
which is exactly `ω − 1 = (1/2 + (√3/2)i) − 1`. So the *abstract* rule `ω² = ω − 1`
is exactly what the *concrete* complex number satisfies — the two agree.

**2. `phi_mul` — the embedding respects multiplication.** Expand `φ((a+bω)(c+dω))`
using the abstract product `(ac−bd) + (ad+bc+bd)ω`, then expand `φ(x)·φ(y)` in ℂ.
The two differ only by an `ω²` term, which `omega_sq_rel` rewrites to `ω − 1`;
`ring` then closes the gap. This is the property that makes `φ` a *ring
homomorphism*, not just a map of sets.

**3. `phi_injective` — no collisions.** If `φ(a+bω) = φ(c+dω)`, take imaginary
parts: `b·(√3/2) = d·(√3/2)`. Since `√3/2 ≠ 0`, cancel it (`mul_right_cancel₀`) to
get `b = d`. Then take real parts: `a + b/2 = c + b/2`, so `a = c` (`linarith`).
Thus `(a,b) = (c,d)`. Intuitively: the real and imaginary coordinates give two
independent equations, because `1` and `ω` are not parallel — their images have
imaginary parts `0` and `√3/2`, and real parts `1` and `1/2`.

**Provenance (header).** *"Ian (2026) 'einstein triangles of 60 degrees'
(hexigon_conversation.md L10005–10105, L11544); the diamond motif."*

---

## 5. `FractalRam.lean` — the 7ⁿ fractal address space and its parent–child lookup

### What it proves

Hex "RAM" is a **fractal** address space: at each level a cell splits into 7
children (hexagonal aperture-7 subdivision, as in the H3/DGGS scheme), so there are
`7ⁿ` addresses at level `n`, and every address is its parent plus one of 7 digits.
The main results:

- **`FractalAddress n`** — a level-`n` address *is* a base-7 digit string of length
  `n` (formally a function from `n` digit positions to the 7 digits `Fin 7`).
- **`fractalAddress_card`** — there are exactly `7ⁿ` level-`n` addresses.
- **`parent` / `lastDigit` / `child`** — the operations: drop the last digit (parent),
  read the last digit, append a digit (child).
- **`parent_child`** — dropping the last digit of `child p d` returns `p`.
- **`child_lastDigit`** — the last digit of `child p d` is `d`.
- **`child_ext`** — two children of the same parent with equal last digits are equal.
- **`child_parent`** — `child (parent a) (lastDigit a)` reconstructs `a` (every
  address is its parent plus its own last digit).
- **`parentFiberEquiv`** — the set of children of a parent is in bijection with `Fin 7`.
- **`parent_fiber_card`** — each parent has **exactly 7 children**.
- **`level_succ_card`** — the growth law `7·7ⁿ = 7ⁿ⁺¹` (proved directly via counting).
- **`addressSigmaEquiv` / `level_succ_card_fiber`** — the same growth law proved
  *structurally*: level-`(n+1)` addresses are the disjoint union over parents of
  their 7-children fibers.
- **`levelOneEquiv` / `levelOne_card`** — level-1 addresses ≃ `Fin 7`, i.e. exactly
  7 of them, matching `hexCells_card = 7` in `SevenHex.lean` (the 7 cells of the
  unit hexagon).

### Why

Ian: *"ram has the hexagon and isomorphic lookup, can do the fractal addressing and
lookup."* The idea is that a hexagon-based memory/address scheme can do the same
"parent → child" navigation a binary RAM does (a byte splits into 2 bits of 8, or a
tree into 2 children), but with a **7-way** split that matches hex packing. Level 1
has 7 cells, level 2 has 49, level 3 has 343, and so on — `7ⁿ`. The theorems pin
down that this is a *clean* fractal: every parent has exactly 7 children, the count
grows by exactly ×7 per level, and the level-1 space is exactly the 7 cells of the
unit hexagon. "Isomorphic lookup" means the address↔cell correspondence is a
bijection (here via `parentFiberEquiv`, `levelOneEquiv`).

### The method

- Counting `7ⁿ`: **`Fintype.card_pi` / `Fintype.card_fin`** (a `simp`).
- Parent/child round-trips: **`funext` + `simp` / `by_cases` + `omega`** (index arithmetic).
- Fiber bijection and card: **`Fintype.card_congr`** against `Fin 7`.
- Growth law: **`pow_succ` + `Nat.mul_comm`**, and independently a **fiber-sum** via
  `Finset.sum_const`.

### Step-by-step (the important ones)

**1. `parentFiberEquiv` → `parent_fiber_card` — exactly 7 children each.** Fix a
parent `p`. Map each child of `p` to its last digit (a value in `Fin 7`), and map
each digit `d` back to `child p d` (which is a genuine child by `parent_child`).
The two directions compose: a child's last digit tells you which `d` produced it
(`child_parent`), and `child_lastDigit` recovers the digit. So the children of `p`
are in one-to-one correspondence with the 7 digits, hence there are exactly 7.
This is the hex analog of "a binary node has 2 children."

**2. `child_parent` — every address is determined by its parent and its last
digit.** Given a level-`(n+1)` address `a`, its parent is the first `n` digits and
its last digit is digit `n`. Reappending the last digit to the parent reproduces
`a` exactly. The proof is a `funext` over digit positions, splitting on whether the
position is `< n` (then it's the parent's digit) or `= n` (then it's the last
digit). This is the "no two addresses are the same parent-plus-digit" uniqueness
that makes the fractal non-overlapping.

**3. `level_succ_card_fiber` — the growth law, structurally.** Instead of just
computing `7·7ⁿ = 7ⁿ⁺¹`, this proof *shows why*: every level-`(n+1)` address is
exactly one parent plus one child-slot, so the level-`(n+1)` space is the disjoint
union of 7-slot fibers over all `7ⁿ` parents. Summing `7` over the `7ⁿ` parents
gives `7·7ⁿ`. This is the "fractal decomposition" — the counting law is a
consequence of the parent/child structure, not a separate fact.

**Provenance (header).** *"hexigon_conversation.md fractal memory 7ⁿ (L11971–12123);
DGGS / H3 aperture-7 (TERNARY_PROCESSOR.md); Ian (2026): 'ram has the hexagon and
isomorphic lookup, can do the fractal addressing and lookup.'"*

---

## 6. `AddressTranslation.lean` — the hex address refines the binary XOR-kernel address

### What it proves

This module assembles the previous pieces into the *address-translation* statement:
the hex coordinate decomposition faithfully translates — and strictly refines — the
binary XOR-kernel decomposition. The main results:

- **`angle_refines_parity`** — the parity of `n` (mod 2) equals the mod-2 residue of
  its hex angle (mod 6): `n % 2 = (n % 6) % 2`. **This is the one genuinely new
  theorem.**
- **`hex_angle_assembly`** — the hex angle (mod 6) is recovered from the parity
  (mod 2) and the 3-cycle (mod 3) by the CRT formula `n % 6 = (3·(n%2) + 4·(n%3)) % 6`.
- **`hex_address_bijective`** — the address map `eisensteinToNat` is a bijection
  (restating `Bijection.eisensteinEquiv`).
- **`hex_ring_growth`** — the hex disk grows as the centered hexagonal number
  `3r²+3r+1` (1, 7, 19, 37, …), each ring adding `6(r+1)` cells.
- **`address_translation`** — the conjunction of all four: angle ⊇ phase, angle =
  phase × 3-cycle (CRT), address bijection, ring growth.

### Why

The original u32 XOR kernel decomposes an address into two axes:
- **phase** = parity (`(−1)^popcount`, mod 2) — the angle/`cos` sign;
- **ring** = the highest set bit (`log₂ d`, `d >> 1` RG flow) — the scale/band.

The hex lattice replaces these with:
- **angle** = the Z₆ direction (mod 6) — which, by CRT `Z₆ ≅ Z₂ × Z₃`, **refines**
  parity (it *is* parity plus a 3-cycle);
- **ring** = the hex disk radius, with `3r²+3r+1` cells per disk, divided by 3
  (trit-shift) as the hex analog of the binary bit-shift RG flow.

The header is explicit about scope: this proves the *structural* half — that the
hex (angle, ring) decomposition carries everything the binary (phase, bit)
decomposition carried, plus a 3-cycle — but it does **not** claim the two kernels
are *performance*-equivalent. That remains **SPECULATION**.

### The method

- `angle_refines_parity`: **modular arithmetic** (`Int.modEq`, `dvd_trans` from `2 ∣ 6`).
- `hex_angle_assembly`: **the already-proved CRT assembly** `TernaryCrt.crt_assembly`.
- `hex_address_bijective`: **restating** `Bijection.eisensteinEquiv`.
- `hex_ring_growth`: **restating** `HexDisk.hexDiskCard_succ`.
- `address_translation`: **conjunction (`constructor`)** of the four.

### Step-by-step (the important ones)

**1. `angle_refines_parity` — the Z₆ angle subsumes parity.** A number's hex angle
is its residue mod 6. Because `n ≡ n % 6 (mod 6)` and `2` divides `6`, the same
congruence holds mod 2: `n ≡ n % 6 (mod 2)`, i.e. `n % 2 = (n % 6) % 2`. In words:
the binary phase bit is exactly the parity of the 6-way angle. The hex angle is
therefore *parity × a 3-cycle* — it carries the phase bit plus more information,
never less. This is the single new lemma of the file, proved with
`Int.modEq`/`dvd_trans` (a short chain: `n ≡ n%6 (mod 6)`, `2 ∣ 6`, hence
`n ≡ n%6 (mod 2)`).

**2. `hex_angle_assembly` — CRT rebuilds the angle.** Going the other way, the
mod-6 angle can be reconstructed from its two free residues — the parity (mod 2)
and the 3-cycle (mod 3) — using the Chinese Remainder inverse `3a + 4b`. This is
just `TernaryCrt.crt_assembly` restated: `Z₆ ≅ Z₂ × Z₃`. So "phase" and "3-cycle"
are independent, jointly-exhaustive coordinates of the angle.

**3. `address_translation` — the whole picture in one theorem.** The final theorem
conjoins four facts: (a) angle refines parity; (b) angle = phase × 3-cycle by CRT;
(c) the Eisenstein-address map is a bijection (same address space the XOR kernel
runs on); (d) the hex disk grows `3r²+3r+1` (the hex analog of the binary `2^k`
rings). The proof is a `constructor` chain invoking each of the four preceding
lemmas. The takeaway, in the header's own words: *"the hex layer therefore carries
everything the XOR kernel's two axes carried, plus the 3-cycle."*

**Provenance (header).** *"the SPECULATION 'hex addressing replaces the u32 XOR
kernel' (AGENTS.md §Quantum Properties, INDEX.md 'blocked on T4 + address-translation
theorem')."* … *"This module proves the *structural* half … (It does NOT claim the two
kernels are *performance*-equivalent; that stays SPECULATION.)"*

---

## How the six modules fit together

1. **`Bijection.lean`** gives every hex cell a unique 32-bit-sized number (the
   addressing bijection, with the u32 range bound).
2. **`Registers.lean`** explains the *gauges* the lattice stores on each edge
   (raw/fold/z/surprise) and, crucially, that squaring drops the sign.
3. **`ConventionBridge.lean`** + **`OmegaEmbedding.lean`** settle the algebra:
   the two Eisenstein conventions are the same ring, and that ring really is the
   60° hexagonal lattice in the complex plane.
4. **`FractalRam.lean`** gives the *fractal* address space (7 children per parent,
   `7ⁿ` cells) that makes hex addressing self-similar across scales.
5. **`AddressTranslation.lean`** ties it back to the original XOR kernel: the hex
   (angle, ring) decomposition refines the binary (phase, bit) decomposition.

Across all six, the calibration labels are **DIRECT** (standard math), and the one
claim that stays **SPECULATION** — that hex addressing *replaces* the u32 XOR kernel
in performance terms — is explicitly *not* proved by these files.
