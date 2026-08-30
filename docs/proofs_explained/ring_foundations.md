# Ring Foundations — the Lean proofs, explained for non-Lean readers

This document explains nine Lean modules in `proofs/lean-src/hexagon/Hexagon/`.
Together they formalize the *Eisenstein integers* — the number system `a + bω` that
sits underneath the hex lattice — and then connect that number system to the two
big ideas of the project: **balanced ternary addressing** (the 7-cell hexagon) and
the **lattice residual math** (`O − E`, `ring²`, `wedge`) used by the memory engine.

Every theorem below is restated in plain English. Lean names are shown in code font
only as a key back to the source file; the prose is self-contained.

---

## 1. Conventions.lean — defining the Eisenstein integers

**Provenance (header):** Ian (2026) "einstein triangles of 60 degrees";
`hexigon_conversation.md` L10005–10105 (the bijection) and L11544 (Eisenstein
magnitude/angle form); `ox alpha.md` TODO #16 "Gauge-int / Eisenstein lattice";
plan §3. Calibration: **DIRECT** (standard ring theory).

### What it proves

This file *defines* the object every later module works with, and proves its two
founding facts:

* **`mul_comm` (T0)** — proves that multiplication in the Eisenstein integers is
  commutative: `x * y = y * x` for all `x, y`. In other words, the order in which you
  multiply two lattice numbers does not matter.
* **`norm_mul` (T1)** — proves that the norm is multiplicative: `N(x * y) = N(x) * N(y)`,
  where `N(a + bω) = a² + ab + b²`. Multiplying two numbers multiplies their "sizes".

The file also **defines** (rather than proves) the number system itself:

* `Eisenstein` is a pair of integers `(a, b)` meaning `a + bω`, with `ω = e^(iπ/3)`,
  a 60° rotation (so `ω² = ω − 1`).
* Its multiplication rule is `(a+bω)(c+dω) = (ac − bd) + (ad + bc + bd)ω`.
* The **norm** is `N(a+bω) = a² + ab + b²` — the squared distance from the origin in
  the hex lattice (see Gauge.lean for why this is literally an *area*).

The header notes one careful design choice, stated here in plain terms: the authors
could have defined `Eisenstein` as a plain pair of integers, but pairs inherit the
"componentwise" product where `(1,0)·(0,1) = (0,0)` — two nonzero things multiplying
to zero (a *zero divisor*). That is **not** the ω-multiplication the lattice needs, so
a dedicated type is used instead.

### Why

`ω = e^(iπ/3)` is a sixth of a full turn, so multiplying by `ω` rotates a lattice point
by 60°. A number system closed under this rotation is exactly what makes the hex lattice
*algebraic*: every lattice point becomes a number, and geometry (rotation, distance) can
be read off the arithmetic. The norm `a² + ab + b²` is the fundamental length measure of
this lattice, and its multiplicativity (`N(xy) = N(x)N(y)`) is the property that later
powers the whole Euclidean-division argument (EuclideanDomain.lean).

### The method

* `mul_comm`: expand both sides to integer coordinates, then `ext <;> ring` — a
  coordinate-by-coordinate ring-simplification (a mechanical identity check).
* `norm_mul`: expand both sides into a single polynomial and close with `ring_nf`
  (a normalization tactic for polynomial/ring identities).

### Step-by-step (both theorems are short)

**`mul_comm`:** (1) break `x` and `y` into their coordinate pairs `(a,b)` and `(c,d)`;
(2) write both `x * y` and `y * x` in the explicit ω-multiplication formula;
(3) note the two results differ only by commuting `*`/`+` on integers — closed by `ring`.

**`norm_mul`:** (1) substitute the multiplication formula into `N(x * y)`, producing one
big polynomial in `a,b,c,d`; (2) expand `N(x) * N(y)` into the same polynomial;
(3) `ring_nf` confirms the two polynomials are identical, so the norm is multiplicative.

---

## 2. SevenHex.lean — the 7-hex ↔ balanced-ternary bijection

**Provenance (header):** `hexigon_conversation.md` L10005–10017 (3³ = 27 triples, the
constraint `q+r+s = 0` leaves exactly 7) and L10105 (the theorem statement: "Balanced
Ternary triples satisfying q+r+s=0 are bijective to the vertices of a hexagonal
tiling"); plan §3. Calibration: **DIRECT** — enumerated by hand in the thread; this
file ports it. (The *hardware* reading — one-wire push/pull/null, 2-diode receiver →
binary — is hex-mmu phase 3, recorded in the plan but **not** proved here.)

### What it proves

* **`hexCells_card` (T2a)** — proves that the unit hexagon has exactly 7 cells.
* **`balanced_iff_mem` (T2b)** — proves that, among all triples of integers each in
  `{-1, 0, 1}`, a triple is "balanced" (its three entries sum to zero) **if and only if**
  it is one of the 7 hex cells. This is the bijection: balanced-ternary triples ⇔ hex cells.

The 7 cells, in cube/axial coordinates `(q, r, s)`, are: the origin `(0,0,0)` and the six
neighbors `(1,0,−1), (0,1,−1), (−1,1,0), (−1,0,1), (0,−1,1), (1,−1,0)`. (Lean represents
the triple `(q,r,s)` as a nested pair, so the file reads the coordinates as `.1`, `.2.1`,
`.2.2` — a notation detail, not a mathematical one.)

### Why

A balanced-ternary "trit" has three digits `{−1, 0, 1}` ("push / null / pull" — the
one-wire signalling idea in the header). Three trits give `3³ = 27` triples, but the
constraint "the three digits sum to zero" cuts them down to exactly 7. Those 7 are
precisely a center plus its six neighbors — the cells of a hexagon. This is the bridge
between the project's **ternary hardware encoding** and its **hexagonal lattice geometry**:
the same 7 objects are both "the balanced ternary code of a cell" and "a vertex of the
hex tiling." It is the "one-page theorem" that ties the two halves of the project together.

### The method

* `hexCells_card`: `decide` — the compiler enumerates the finite set and counts it.
* `balanced_iff_mem`: break the triple into its three coordinates, then `fin_cases`
  on each of the three membership hypotheses (each coordinate is in a 3-element set),
  and `decide` every one of the `3×3×3 = 27` branches.

### Step-by-step (`balanced_iff_mem`)

(1) The theorem has two directions, but the proof works by **exhaustion**: take the triple's
three coordinates; (2) each coordinate is known to lie in `{-1, 0, 1}`, so split into the
27 possible triples; (3) on each branch, check whether "sums to zero" matches "is in the
list of 7 cells" — `decide` confirms the match on all 27. The 7 that sum to zero are
exactly the 7 listed cells.

---

## 3. Rotation.lean — the Z₆ rotation group and the hex distance

**Provenance (header):** `hexigon_conversation.md` L10179–10197 (rotation = permute
tuple indices, mod-6 arithmetic), L11248 ("trig becomes modulo arithmetic"),
L11397–11399 (60° basis → exact integer angles); plan §3; SYNTHESIS Q1. Calibration:
**DIRECT** (real math, integer-native). The Z₆ spinor is called out as the one DIRECT
bridge to the rebuild (the even-grade fix `ψ = (α+βI)U`, TODO #16).

### What it proves

* **`units_card` (T3a)** — proves there are exactly **six units** in `ℤ[ω]`:
  `±1, ±ω, ±ω²` — the six 60° rotations.
* **`units_closed_under_mul` (T3b)** — proves the six units are **closed under
  multiplication**: the product of any two units is again one of the six, so they form
  the cyclic group **Z₆** (the sixth roots of unity).
* A family of facts proving the **cube-coordinate max-norm distance** `hexDist` is a
  genuine metric: `hexDist_self` (distance to yourself is 0), `hexDist_comm` (symmetric),
  `hexDist_nonneg` (never negative), and `hexDist_triangle` (the triangle inequality —
  the shortest route through a third point is at least the direct distance).
* Supporting lemmas: `hexDist_le_iff` (the distance is ≤ `d` exactly when all three
  coordinate gaps are ≤ `d`), three `abs_*_sub_le_hexDist` bounds (each coordinate gap is
  ≤ the overall distance), and `isNeighbor_iff` (on balanced cells, "being neighbors" is
  exactly "being at max-norm distance 1").

Here `hexDist` is the "max of the three coordinate gaps" (Chebyshev/∞-norm) distance,
defined on the cube coordinates `(q,r,s)`. Note the header's status line: the *metric*
properties are proved here, but "graph distance = hexDist" is left open and is closed in
GraphDistance.lean.

### Why

The six units are the algebraic form of the hex lattice's **6-fold rotational symmetry**:
multiplying by `ω` turns the plane by 60°, so `ω⁶ = 1` and the six powers `1, ω, ω², …,
ω⁵` are exactly the six directions. Proving they form a group (closed, with 6 elements)
is what licenses "angles are just integers mod 6" — trigonometry becomes modular
arithmetic, with no floating point. The `hexDist` metric is the *distance function*
between cells that later (GraphDistance.lean) is shown to equal the hop-count on the
honeycomb graph — i.e. it is the right "how far apart are two addresses" measure, which
matters for the hex ↔ u32 address translation.

### The method

* `units_card`: `decide` (count the 6-element set).
* `units_closed_under_mul`: `fin_cases` on the two membership hypotheses (6×6 = 36 cases)
  then `decide` each product.
* The metric lemmas: `simp`/`dsimp` plus standard inequality facts — `abs_sub_comm`,
  `abs_nonneg`, `abs_add_le`, and `le_max_left`/`le_max_right` for the max.

### Step-by-step (`hexDist_triangle`, the most substantive proof here)

The triangle inequality says `hexDist a c ≤ hexDist a b + hexDist b c`. (1) Rewrite the
goal with `hexDist_le_iff`, reducing it to three separate coordinate claims;
(2) for each coordinate, e.g. the first, write `a.1 − c.1 = (a.1 − b.1) + (b.1 − c.1)`
(insert and subtract the middle point); (3) apply `abs_add_le` so the gap through `b`
splits into two gaps; (4) bound each of those two gaps by `hexDist a b` and
`hexDist b c` using the `abs_*_sub_le_hexDist` lemmas, and add. Repeat for the other two
coordinates. The whole proof is the classic "detour through the middle" argument,
repeated three times, once per coordinate.

---

## 4. Packing.lean — hexagonal packing density, stated in τ

**Provenance (header):** `hexigon_conversation.md` (packing/GR aside), plan §3
(packing density). Ian (2026): use **τ not π** — "the base unit of rotation is the
circle, not the half a circle." Calibration: **DIRECT** — a real-number identity.
The *optimality* (hexagonal packing is the densest circle packing) is **Thue / Fejes
Tóth — cited, not proved here**.

### What it proves

* **`hexPackingDensity_eq_tau_div` (T6)** — proves that the hexagonal-lattice circle
  packing density is the same whether written in π or in τ: `π/(2√3) = τ/(4√3)`,
  where `τ = 2π` is the "full-turn" constant.

The file also **defines** `tau := 2π` and `hexPackingDensity := π/(2√3)`. The header is
explicit that the *geometric derivation* of that density (circle area ÷ fundamental-cell
area) and Thue's *optimality* theorem are **deferred/cited**, not formalized here — this
module proves only the identity between the π-form and the τ-form.

### Why

The hex lattice is the densest way to pack circles in the plane (a classical fact the
header cites but does not re-prove). Stating that density in τ rather than π is a
convention choice that treats a full circle — not a semicircle — as the base unit of
rotation. This matches the project's "exact integer angles" philosophy (see Rotation.lean):
a full turn is `τ`, one sixth of a turn is `τ/6`, and clean constants like `τ/(4√3)`
encode the geometry without π's factor-of-2 clutter.

### The method

`rw` the two definitions (`hexPackingDensity`, `tau`) then `ring_nf` — substituting
`τ = 2π` and simplifying the fraction `2π/(4√3) = π/(2√3)`.

### Step-by-step

(1) Unfold both `hexPackingDensity` and `tau` to get the claim
`π/(2√3) = 2π/(4√3)`; (2) `ring_nf` cancels the common factor of 2. That is the entire
proof — it is a one-line algebraic identity, and its point is the *naming* (τ-form vs
π-form), not any deep geometry.

---

## 5. Euclidean.lean — the geometric crux: every point is near a lattice point

**Provenance (header):** plan §5 (ℤ[ω] is a Euclidean domain / UFD); mirrors mathlib's
`NumberTheory.Zsqrtd.GaussianInt` (which proves ℤ[i] Euclidean). Ian (2026): the
"measure" here is the *count* — "absolute math" (compute in the counting measure,
display as ratios), not the probability measure forcing everything into [0,1].
Calibration: **DIRECT** — classical.

### What it proves

* **`exists_near_int_pair` (T5b)** — proves the **covering-radius / rounding lemma**:
  for *any* two real numbers `α, β` (the coordinates of an arbitrary point in the
  `{1, ω}` basis), there exist integers `a, b` such that
  `(α−a)² + (α−a)(β−b) + (β−b)² < 1`. In plain English: **every point of the plane lies
  within norm strictly less than 1 of some lattice point.**

This is called the "geometric crux of the Euclidean algorithm": it is the guarantee that,
after rounding to the nearest lattice point, the leftover error is strictly smaller than
1 — the essential ingredient for division-with-remainder to terminate.

### Why

A *Euclidean domain* is a number system where you can divide with a remainder that is
strictly "smaller" than the divisor — the same long division you learned for integers.
For the Eisenstein integers, "smaller" means "smaller norm," and the norm is
`a² + ab + b²`. The rounding lemma proves that rounding a point to its nearest lattice
point always leaves an error of norm `< 1`, which is precisely what makes the quotient
choice work. It is the geometry behind "ℤ[ω] behaves like the integers for division,"
which in turn (EuclideanDomain.lean) makes ℤ[ω] a **unique factorization domain**.

### The method

Choose `a = round α`, `b = round β` (rounding to nearest integer). Set
`x = α − round α`, `y = β − round β` (the two rounding errors, each of absolute value
≤ 1/2). Bound `|x|, |y| ≤ 1/2`, then `|x+y| ≤ 1`; square these to get
`x² ≤ 1/4, y² ≤ 1/4, (x+y)² ≤ 1`; use the algebraic identity
`x² + xy + y² = ((x+y)² + x² + y²)/2`; and finish with `nlinarith` (a nonlinear
arithmetic tactic) on those bounds.

### Step-by-step

(1) Pick the witnesses: `round α` and `round β` (rounding is the whole construction);
(2) prove the two rounding errors `x, y` each satisfy `|x| ≤ 1/2` and `|y| ≤ 1/2`
(via the `abs_sub_round` fact that rounding moves you at most half a unit);
(3) combine to get `|x + y| ≤ 1`, and square each bound to `x² ≤ 1/4`,
`y² ≤ 1/4`, `(x+y)² ≤ 1`; (4) rewrite the target `x² + xy + y²` as
`((x+y)² + x² + y²)/2` (a pure algebraic identity); (5) feed the three squared bounds
to `nlinarith`, which concludes the sum is `< 1`. The inequality is strict because
`(x+y)² ≤ 1` combines with the strict half-bound behavior of the squares.

---

## 6. GraphDistance.lean — graph distance equals the coordinate max-norm

**Provenance (header):** plan §3; SYNTHESIS Q1 (the hex ↔ u32 address claim stays
SPECULATION until a provable address translation exists — T4 is its metric).
Calibration: **DIRECT** — real math, integer-native.

### What it proves

* **`honeycomb_dist_eq_hexDist` (T4)** — proves the **main theorem**: on balanced cells,
  the graph distance in the honeycomb graph **equals** the cube-coordinate max-norm
  distance `hexDist`. In plain English: the number of steps needed to walk from one hex
  cell to another along edges of the hexagonal grid is exactly the max of the three
  coordinate gaps. Shortest-path hop count and the coordinate distance are the same number.

It builds this from a chain of helpers, each of which is a proved fact:

* `hexDist_eq_zero_iff` — distance is 0 exactly when the two cells are the same cell.
* `max3_shift` (private) — if one coordinate gap is positive, another negative, and the
  three sum to zero (balance), then moving the positive gap down by 1 and the negative
  gap up by 1 lowers the max-norm by exactly 1.
* `step` / `balanced_step` / `adj_step` / `hexDist_step_decr` — a **greedy step** toward
  the target that (a) stays balanced, (b) is a valid edge of the honeycomb graph, and
  (c) reduces the distance by exactly 1.
* `walkOfLength` / `greedyWalk` / `greedyWalk_length` — repeating the greedy step builds
  an actual walk of length exactly `hexDist`.
* `hexDist_le_walk_length` — any walk of length `n` has `hexDist ≤ n` (each edge changes
  distance by at most 1).
* `honeycomb_dist_le_hexDist` and `honeycomb_dist_ge_hexDist` — the two inequalities
  whose conjunction is the equality.

### Why

This is the "T4 metric" that the header says SYNTHESIS Q1 needs before the hex ↔ u32
**address translation** can be claimed as proved rather than speculative. If "distance in
the lattice" (hop count along edges) coincides with a trivial formula (max of coordinate
gaps), then addressing cells by their cube coordinates *is* addressing them by metric
distance — coordinates become addresses, and walking the lattice is integer arithmetic.
The file is also the concrete payoff of Rotation.lean's `hexDist` metric: it upgrades
"a metric that exists" to "the metric that *is* the graph."

### The method

Two directions, by construction:

* **Upper bound** (`graph distance ≤ hexDist`): build an explicit walk with the greedy
  `step` function, `hexDist` steps long, and cite `SimpleGraph.dist_le`.
* **Lower bound** (`hexDist ≤ graph distance`): induction over walks (`Walk.rec`) using
  the triangle inequality (`hexDist_triangle`) plus the fact that every edge has
  `hexDist = 1`.

Working tactics: `omega` for the integer/coordinate bookkeeping, `simp`/`dsimp` for
unfolding definitions, `ring` for the small algebraic rewrites, and structural induction
for `walkOfLength` and `hexDist_le_walk_length`.

### Step-by-step (`honeycomb_dist_eq_hexDist` — the key theorem)

The proof is two inequalities glued by `le_antisymm`.

**Upper bound** (`honeycomb_dist_le_hexDist`): (1) construct `greedyWalk a b` by applying
`walkOfLength`, which inducts on the distance: at distance 0 the walk is empty; otherwise
take one greedy `step`, note it is an edge and drops the distance by exactly 1, and append
the (inductively built) rest of the walk; (2) `greedyWalk_length` shows this walk has
length exactly `hexDist a b`; (3) `SimpleGraph.dist_le` says the true shortest distance is
at most the length of any walk, so `dist ≤ hexDist`.

**Lower bound** (`honeycomb_dist_ge_hexDist`): (1) since `greedyWalk` reaches `b`, the two
cells are reachable, so there is a shortest walk of length exactly the graph distance;
(2) `hexDist_le_walk_length` says any walk of length `n` satisfies `hexDist ≤ n` — proved
by induction over walks: a walk of length 0 starts and ends at the same cell (distance 0),
and adding one edge (`hexDist = 1`) increases the distance bound by at most 1 via the
triangle inequality; (3) instantiate at `n = dist a b` to get `hexDist ≤ dist`.

Together the two bounds give equality: hop-count distance = coordinate max-norm distance.

---

## 7. EuclideanDomain.lean — ℤ[ω] is a Euclidean domain (hence a UFD)

**Provenance (header):** plan §5; mirrors mathlib `NumberTheory/Zsqrtd/GaussianInt.lean`.
Calibration: **DIRECT** — classical. Status note: everything is closed by the
`ext <;> ring` pattern; the division algorithm is "pure-ℝ" (quotient = componentwise
`round` in the `(1, ω)` basis), needing no ℂ embedding or `normSq` bridge.

### What it proves

* **`star_norm`** — conjugation preserves the norm: `N(a+bω̄) = N(a+bω)`, where the
  conjugate `star (a+bω) = (a+b) − bω`.
* **`star_mul_self`** — `x * star x = N(x)`: a number times its conjugate equals its norm
  (the complex-numbers fact `z·z̄ = |z|²`, adapted to this lattice).
* **`instCommRing`** (T5(1)) — proves the Eisenstein integers form a **commutative ring**:
  addition and multiplication satisfy all the ring axioms (associative, commutative, etc.).
* **`norm_nonneg`** — proves the norm `N(a+bω) = a² + ab + b²` is **never negative**.
* **`norm_eq_zero_iff`** — proves the norm is **zero exactly at zero**: `N(x) = 0 ⇔ x = 0`
  (the norm is *positive-definite*).
* **`norm_pos`** — proves any nonzero element has strictly positive norm.
* **`norm_mod_lt`** (T5's core) — proves the **division algorithm**: for any divisor
  `y ≠ 0`, the remainder satisfies `N(x % y) < N(y)` — the remainder is strictly smaller
  than the divisor.
* **`natAbs_norm_mod_lt`** and **`norm_le_norm_mul_left`** — the two supporting
  well-foundedness facts, re-stated over natural numbers.
* **`instance EuclideanDomain Eisenstein`** (T5(2)) — assembles everything into a
  full **Euclidean domain** instance for `ℤ[ω]`, from which Lean automatically obtains
  the **unique factorization domain (UFD)** property.

The quotient/remainder are defined explicitly: quotient = componentwise `round` of
`(x · star y) / N(y)`, remainder = `x − y · (x/y)` — exactly long division in the lattice.

### Why

This is the payoff of the whole number-system chain. A *Euclidean domain* is the setting
where division-with-smaller-remainder always works, and that in turn guarantees **unique
factorization** — every Eisenstein integer factors into "primes" (lattice primes) in
essentially one way. For the project this means the hex lattice has a genuine **prime
structure**: cells/elements can be factored, and "which lattice primes divide a number"
becomes meaningful — the algebraic foundation for treating lattice positions like integers
(and later, for gauge/address arithmetic). It mirrors what mathlib already does for the
Gaussian integers `ℤ[i]`, transplanted to the 60° lattice.

### The method

* Ring axioms: `ext <;> simp <;> ring` — expand coordinates and simplify each axiom.
* `norm_nonneg`: rewrite `a² + ab + b² = ((a+b)² + a² + b²)/2`, then `nlinarith` over the
  three nonnegative squares.
* `norm_eq_zero_iff`: force each square to be 0 (via `nlinarith` + `sq_nonneg`), then
  `sq_eq_zero_iff`.
* `norm_mod_lt`: the deep part — combine the proved `norm_mul` (T1), `star_mul_self`, and
  `exists_near_int_pair` (Euclidean.lean) via the key identity `N(x − y·q)·N(y) =
  N(x·star y − q·N(y))`, then clear the `N(y)` factor and use the rounding-error bound
  `< 1` to conclude `N(remainder) < N(y)`.

### Step-by-step (`norm_mod_lt`, the most important proof)

(1) Name `n = N(y)`, and write the quotient's integer coordinates via the round
definition. (2) Prove the **key identity**
`N(x − y·q)·N(y) = N(x·star y − q·N(y))`: multiply out, use `norm_mul` (the norm is
multiplicative) and `star_mul_self` (y·star y = N(y)), all purely algebraic.
(3) Cast to reals and factor the right-hand side as `(N(y))² · qr`, where `qr` is exactly
the "rounding error" quantity `(p/n − round(p/n))² + …` for the two coordinates
`p/n, s/n`. (4) Apply the covering-radius lemma `exists_near_int_pair` (from Euclidean.lean)
to conclude `qr < 1`. (5) Since `N(remainder)·N(y) = N(y)²·qr` and `N(y) > 0`, divide by
`N(y)` to get `N(remainder) = N(y)·qr < N(y)·1 = N(y)`. The `< 1` from the rounding lemma
is what makes the division terminate — this is the Euclidean algorithm in one theorem.

---

## 8. Gauge.lean — the norm is an area, invariant under the six rotations

**Provenance (header):** Ian (2026): "the math that gives us the isotropy, and lets us
encode the gauge and the value as its area as one number… {20,1} is {10,2} by area… the
gauge is just another number, giving cheap multiplication and gauge change." Calibration:
**DIRECT** — the norm is the determinant of the regular representation (an AREA), invariant
under the six units (the Z₆ rotations = isotropy).

### What it proves

* **`norm_of_unit` (T1b)** — proves **every unit has norm 1**: all six of
  `±1, ±ω, ±ω²` satisfy `N(u) = 1`.
* **`norm_mul_unit` (T1c) / `norm_unit_mul` (T1c′)** — proves the norm is **invariant
  under multiplying by a unit** (on either side): `N(x·u) = N(x)` and `N(u·x) = N(x)`.
  In plain English: rotating a lattice point by 60° (or any multiple) does **not** change
  its norm — the norm is *rotationally symmetric* ("isotropy").
* **`norm_eq_det` (T1d)** — proves the norm **is** the determinant of the "regular
  representation" — the matrix `[[a, −b], [b, a+b]]` describing how multiplication by
  `a+bω` acts on the basis `{1, ω}`. Since a determinant is a signed **area**, this is the
  precise sense in which the norm is an *area scalar*.
* **`units_eq_omega_pow` / `units_eq_omega_powers` (T1e)** — proves the six units are
  **exactly the six powers** `ω⁰, ω¹, …, ω⁵` (with `ω⁰ = 1, ω¹ = ω, ω² = ω−1,
  ω³ = −1, ω⁴ = −ω, ω⁵ = −ω²`). So multiplying by `ω` cycles through all six "gauges."
* **`omegaPow_six`** — proves `ω⁶ = 1`: the rotation cycle closes back to the identity.
* **`mul_omega_mem_units`** — proves multiplying any unit by `ω` gives another unit
  (the rotation action on the gauge stays within the gauge).

### Why

This is the "gauge" of the header: the six units are six equivalent *ways of writing the
same physical lattice point* (rotating the coordinate frame by 60°). The header's example
says `{20,1}` and `{10,2}` are "the same by area" — the norm (area) is the quantity that
stays fixed when you change gauge, so you can *encode the gauge and the value as one
number*. Proving the norm is unit-invariant and equals a determinant is what makes "the
gauge is just another number" rigorous: changing gauge is cheap multiplication by a unit,
and it never changes the area/norm. This is the algebraic version of the hex lattice's
6-fold symmetry — the six rotations leave the geometry untouched.

### The method

* `norm_of_unit`: `fin_cases` over the unit, `decide` each of the 6 cases.
* `norm_mul_unit` / `norm_unit_mul`: rewrite with `norm_mul` (T1) and `norm_of_unit`, then
  `ring` to drop the factor of 1.
* `norm_eq_det`: expand `Matrix.det_fin_two` on the 2×2 representation matrix and `ring`.
* `units_eq_omega_pow` and `omegaPow_six`: unfold the six `omegaPow` values, then `decide`.

### Step-by-step (`norm_eq_det`, the most illuminating proof)

(1) The regular representation records what multiplying by `x = a+bω` does to the basis
vectors: `1 ↦ (a, b)` and `ω ↦ (−b, a+b)` (using `ω² = ω − 1`), giving the matrix
`[[a, −b], [b, a+b]]`. (2) Its determinant (for a 2×2 matrix, `ad − bc`) is
`a·(a+b) − (−b)·b = a² + ab + b²`. (3) That is exactly the norm `N(x)`, so
`N(x) = det(rep x)` — the norm literally *is* the area scaling factor of the linear map
"multiply by x." This is why the norm is a signed area, and why it is unchanged by the six
rotations (rotation matrices have determinant 1).

---

## 9. Residual.lean — the memory engine's residual math

**Provenance (header):** the lattice rebuild (`LATTICE_MATH.md`, `AGENTS.md` canonical
truth): the stored primitive is the signed residual `r = O − E`, `E = f(a)f(b)/T` (the
independence null); three axes (correlation/surprise, wedge `O_ab−O_ba`, polarization);
`ring² = Σ(O−E)²/E` = a χ² divergence / L2 norm. `ox alpha.md` flagged the
column-balancing identity as the key bug fix ("forgot column balancing"). Calibration:
**DIRECT** — standard statistics / linear algebra.

### What it proves

This module switches from the hex lattice to the **lattice memory engine's** statistical
model: a finite vocabulary `V`, word frequencies `f : V → ℕ`, total count `T = Σ f`,
observed bigram counts `O : V × V → ℕ`, expected counts `E(a,b) = f(a)·f(b)/T`, residual
`r = O − E`. It proves four facts:

* **`wedge_antisymm` (3)** — proves the **wedge is skew (antisymmetric)**:
  `wedge(a,b) = −wedge(b,a)`, where `wedge(a,b) = O(a,b) − O(b,a)` is the difference
  between the two directions of an ordered bigram. Swapping the pair flips the sign.
* **`sum_E_row` (1)** — proves the **marginal / column-balancing identity**:
  `Σ_b E(a,b) = f(a)` (assuming `T ≠ 0`). In plain English: if you add up the *expected*
  counts along any row of the matrix, you recover the word's own frequency. This is the
  identity the header says `ox alpha.md` flagged as the key bug fix.
* **`sum_residual_eq_zero` (2)** — proves the **total residual is zero**:
  `Σ_a Σ_b (O(a,b) − E(a,b)) = 0`, given the observed row sums equal the frequencies and
  `T ≠ 0`. The sum of all signed residuals over the whole matrix cancels out to zero.
* **`ringSq_term_nonneg` (4a) / `ringSq_nonneg` (4)** — proves **ring² is nonnegative**:
  each term `(O − E)²/E` is ≥ 0 (a square divided by a nonnegative `E`), so the whole
  χ² divergence `ringSq = Σ_b (O−E)²/E` is ≥ 0.

### Why

These are the invariants that keep the memory engine's statistics sane. The **wedge** is
the engine's skew/direction measure (temporal precedence — which word tends to precede
which); its antisymmetry is what makes "direction" meaningful (reversing a directed edge
flips its sign). The **column-balancing identity** `Σ E = f` is the bookkeeping law that
the expected counts are calibrated to the observed frequencies — getting it wrong was the
actual bug the header references. **Total residual zero** says the null model is
mass-conserving: observed counts over- and under-shoot the expected counts in equal total
amount, so "surprise" is genuinely relative, not a bulk offset. **ring² ≥ 0** confirms the
χ² divergence is a genuine norm (an L2 magnitude — the header is careful it is *not*
Fisher information), so it can be used as a distance/energy without ever going negative.

### The method

* `wedge_antisymm`: unfold `wedge`, `ring` over the integer subtraction.
* `sum_E_row`: `Finset.sum` distributivity — factor `f(a)/T` out of the sum, then
  `Finset.sum_div` + `Finset.mul_sum`, and cancel `T` with `mul_div_cancel_right₀`.
* `sum_residual_eq_zero`: `Finset.sum_sub_distrib` to split the double sum, then show the
  `Σ O` and `Σ E` parts are both equal to `Σ f` (via the row-sum hypothesis and
  `sum_E_row`), and `ring`.
* `ringSq_term_nonneg` / `ringSq_nonneg`: `div_nonneg` + `sq_nonneg` + `mul_nonneg`
  (and `Finset.sum_nonneg` for the total).

### Step-by-step (`sum_residual_eq_zero`, the most substantive proof)

(1) The goal is `Σ_a Σ_b (O − E) = 0`. (2) First show `Σ_a Σ_b O = Σ_a f(a)`: summing
`O` over `b` inside row `a` gives `f(a)` by the hypothesis that observed row sums equal
frequencies. (3) Then show `Σ_a Σ_b E = Σ_a f(a)`: this is exactly `sum_E_row`, applied
row by row — each row of the expected matrix sums to `f(a)`. (4) Distribute the
subtraction (`sum_sub_distrib`) to write the whole double sum as
`(Σ O) − (Σ E)`; (5) substitute the two equalities and `ring` to get `Σ f − Σ f = 0`.
The moral: residual is a *deviation* from expectation, and both the observed and expected
mass are the same total `Σ f`, so the deviations must net to zero.
