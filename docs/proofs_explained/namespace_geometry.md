# The Geometry Modules — what the Lean proofs actually say

This document explains eight Lean proof modules from
`proofs/lean-src/hexagon/Hexagon/`. They are the **geometry cluster** of the Tau
Architecture: the set of proofs that establish *how ternary (3-valued) memory can be
laid out on a hexagonal lattice, addressed like a rectangle, and rotated/translated
uniformly*. Every theorem named below is a real, machine-checked statement from the
files (all eight files are status **PROVED**, zero `sorry`).

They are written for a reader who has never seen Lean. "Proved" means exactly what it
says: Lean has checked the claim against the rules of logic, leaving no unproven step.

---

## Shared vocabulary (read this first)

A few objects recur across all eight files. They are defined in the supporting files
`Conventions.lean`, `Rotation.lean`, `SevenHex.lean`, and `PolarGate.lean`.

- **Trit** — a ternary digit. It can hold three values: balanced `−1`, `0`, `+1`.
  In `PolarGate.lean` a trit is stored on `Fin 3` (the numbers 0, 1, 2) with the
  residue convention: digit `0` = balanced `0`, digit `1` = `+1`, digit `2` = `−1`.
  The function `tritInt` reads a digit back to its balanced integer value.

- **Bit** — a binary digit, two values `0` and `1`.

- **Eisenstein integer** (`Eisenstein`, in `Conventions.lean`) — a pair of integers
  `(a, b)` representing the lattice point `a + b·ω`, where `ω = e^(iπ/3)` is a
  60° rotation (so `ω² = ω − 1`). This is the standard way to give coordinates to a
  **hexagonal grid**: each pair `(a, b)` is one hex cell.

- **Norm** — `norm(a,b) = a² + ab + b²`. It is the squared distance from the origin,
  and it is multiplicative (`norm(x·y) = norm x · norm y`). A hex cell's "ring" is
  its norm.

- **Units** — the six cells at norm 1, i.e. the six directions a step away from any
  cell: `1, −1, ω, −ω, ω², −ω²`. They form the six-way rotation group `Z₆` (rotation
  by multiples of 60°).

- **The 7-hex / the pod** — the center cell plus its six neighbors: seven cells
  total. This is the fundamental "cell cluster" of the architecture.

- **Balanced ternary triple** — three integers `(q, r, s)` each in `{−1, 0, 1}`
  satisfying `q + r + s = 0`. There are exactly 7 such triples (`SevenHex.lean`),
  and they biject to the 7 cells.

---

## 1. `TritPacking.lean` — how many trits fit in how many bits

*Provenance (file header):* from the ternary-memory survey. A trit carries
`log₂ 3 ≈ 1.585` bits of information, so it always takes fewer trits than bits to
encode the same number of states. The naive 2-bit-per-trit code is the upper bound;
ternary is strictly denser than binary per symbol. Calibration label: **DIRECT**
(counting argument).

### What it proves

- `four_trits_fit_seven_bits` — `3⁴ ≤ 2⁷`, i.e. `81 ≤ 128`. Four trits can be packed
  into seven bits.
- `five_trits_fit_eight_bits` — `3⁵ ≤ 2⁸`, i.e. `243 ≤ 256`. Five trits pack into
  eight bits.
- `three_pow_le_two_pow_two_mul` — for **every** `n`, `3ⁿ ≤ 2^(2n)`. Any `n` trits
  fit in `2n` bits (the 2-bit-per-trit code is always sufficient).
- `two_pow_le_three_pow` — for every `n`, `2ⁿ ≤ 3ⁿ`.
- `three_pow_gt_two_pow` — for every `n > 0`, `2ⁿ < 3ⁿ`. **Ternary is strictly
  denser than binary per symbol.**

### Why

This is the *counting* foundation of the whole "ternary wins" story. A symbol (trit
or bit) is a *namespace*: `n` trits open `3ⁿ` addresses, `n` bits open `2ⁿ`. Because
`3ⁿ` grows faster than `2ⁿ`, the ternary namespace wins **exponentially** — the ratio
`3ⁿ/2ⁿ = (3/2)ⁿ` compounds by a factor of 3/2 for every extra symbol. The concrete
packing facts (`81 ≤ 128`, `243 ≤ 256`) are the practical translations a hardware
designer cares about: the two near-tight block codes that actually get built.

### The method

Finite case analysis (`norm_num`/`decide`) for the two concrete facts; induction for
the general bounds.

### Step-by-step

**`three_pow_le_two_pow_two_mul` (the 2-bits-per-trit bound).** Induction on `n`.
Base `n = 0`: `3⁰ = 1 = 2⁰`. Step: assume `3ⁿ ≤ 2^(2n)`; then
`3^(n+1) = 3·3ⁿ ≤ 3·2^(2n) ≤ 4·2^(2n) = 2²·2^(2n) = 2^(2(n+1))`. The key move is
the "wasteful" step `3 ≤ 4`: multiplying by 4 (= two extra bits) rather than 3 is
exactly what gives the `2n` bound instead of a tighter one. The identity
`2 + 2n = 2(n+1)` is finished by `omega` (arithmetic bookkeeping).

**`three_pow_gt_two_pow` (strictly denser).** First prove the weak form
`two_pow_le_three_pow` by the same induction (step: `2·2ⁿ ≤ 3·3ⁿ` because `2 ≤ 3`
component-wise). Then the strict form splits on `n`. For `n = 0` the hypothesis
`0 < n` is impossible (`omega`). For `n = m+1`:
`2^(m+1) = 2·2^m ≤ 2·3^m < 3·3^m = 3^(m+1)` — the strict inequality is `2 < 3`
applied to the positive number `3^m`. Lean's `norm_num` discharges the concrete
`2 < 3` and `3 > 0` facts.

**`four_trits_fit_seven_bits` / `five_trits_fit_eight_bits`.** These are literal
integer computations: `norm_num` simply evaluates `3⁴ = 81`, `2⁷ = 128`, and
confirms `81 ≤ 128` (and similarly `243 ≤ 256`). No cleverness — just checking the
two headline packings hold.

---

## 2. `FewerTrits.lean` — ternary needs fewer symbols than binary

*Provenance (file header):* the "fewer symbols" theorem. For `k ≥ 3`, `k−1` trits
already encode `2^k` states — the *integer* form of the radix-economy win (the
real-number form `3/ln 3 < 2/ln 2` lives in `RadixEconomy.lean`). Calibration:
**DIRECT**.

### What it proves

- `two_pow_le_three_pow_pred` — for `k ≥ 3`, `2^k ≤ 3^(k−1)`. **`k−1` trits carry at
  least as many states as `k` bits.**
- `fewer_trits_than_bits` — for `k ≥ 3`, `k − 1 < k`. (Trivially, `k−1` symbols is
  strictly fewer than `k`.)
- `three_pow_div_two_pow_mono` — `3^(n+1)/2^(n+1) = (3/2)·(3ⁿ/2ⁿ)`. **The
  ternary-to-binary state ratio grows geometrically** — each extra symbol multiplies
  the advantage by 3/2.

### Why

`TritPacking` showed ternary is denser *per symbol* (`2ⁿ < 3ⁿ`). This file turns that
into the number a systems person asks: **how many symbols do I need to hit a given
address space?** The answer is `k` bits but only `⌈k·log₃ 2⌉` trits — about 63% as
many. For `k ≥ 3` the clean integer statement is `2^k ≤ 3^(k−1)`: drop just *one*
symbol when you switch to ternary and you *still* have at least as many addresses.
That one-symbol saving is the asymptotic 36.9% symbol reduction in disguise.

### The method

Induction (re-based at `k = 3`) plus `omega` for the trivial corollary; `field_simp`
for the ratio identity.

### Step-by-step

**`two_pow_le_three_pow_pred`.** The statement is only for `k ≥ 3`, so first rewrite
`k` as `3 + d` (Lean's `Nat.exists_eq_add_of_le`). Now induct on `d`. Base `d = 0`:
`2³ = 8 ≤ 3² = 9` — the first place the inequality is true (`k = 3`). Step: assume
`2^(3+d) ≤ 3^(3+d−1)`; then
`2^(3+d+1) = 2·2^(3+d) ≤ 2·3^(3+d−1) ≤ 3·3^(3+d−1) = 3^(3+d)`. The step reuses the
same `2 ≤ 3` multiplier trick as `TritPacking`; `omega` handles the `−1`/`+1`
bookkeeping on the exponents.

**`three_pow_div_two_pow_mono`.** On rationals, expand `3^(n+1)/2^(n+1)` as
`(3·3ⁿ)/(2·2ⁿ)`, then cancel the shared `2ⁿ ≠ 0` (via `field_simp`) to leave exactly
`(3/2)·(3ⁿ/2ⁿ)`. This is the algebraic statement "the ratio compounds by 3/2".

**`fewer_trits_than_bits`.** `omega` closes `k − 1 < k` outright — it's the trivial
observation that "one fewer" really is fewer, needed only to package the win as
"fewer symbols" rather than "fewer-or-equal symbols".

---

## 3. `Pod.lean` — the 7-cell pod is exactly the radius-1 ball

*Provenance (file header):* Ian (2026-08-28): "a trit takes up one cell, then the
seven set count have 7 trits" and "if the ram needs a backup pod… six for
redundancy". The pod is the closed radius-1 ball: the center plus the 6 units.
Calibration: **DIRECT**.

### What it proves

- `pod` (definition) — the 7-hex pod = the center cell `⟨0,0⟩` together with the six
  units.
- `pod_card` — the pod has exactly **7** cells.
- `pod_mem_iff` — being in the pod means *exactly* being the center or a unit.
- `pod_norm_le_one` — every pod cell has norm `0` (center) or `1` (a unit), i.e.
  norm ≤ 1.
- `axialNine` (definition) + `axialNine_card` — the nine cells whose axial
  coordinates `(a,b)` each range over `{−1,0,1}` (`9 = 3²` states).
- `spare` (definition) + `spare_norm` — the two cells **outside** the pod,
  `(1,1)` and `(−1,−1)`, each have norm **3**.
- `axialNine_eq_pod_union_spare` — the 9 axial states split exactly as pod ∪ spare
  (7 + 2).
- `norm_le_one_iff_mem` — **`norm x ≤ 1 ⟺ x ∈ pod`.** This pins the pod to *exactly*
  7 of the 9 axial states.

### Why

The pod is the architectural "atom" of the hex memory: one cell plus its six
neighbors. The question is why there are *seven* and not nine. The nine axial states
`(a,b) ∈ {−1,0,1}²` are all the cells "one step or less" away in coordinate terms,
but two of them — `(1,1)` and `(−1,−1)` — are geometrically *farther* (norm 3, one
full ring out) than the other six (norm 1). The norm is what separates "inside the
pod" from "outside": inside means `a²+ab+b² ≤ 1`, and that selects exactly 7 cells,
leaving the two norm-3 corners as natural **carry / overflow states** — the cells a
computation "falls into" when it leaves the pod. That is the redundancy story: 7
data cells plus 2 spare states.

### The method

Finite arithmetic over 9 states (`decide`/`fin_cases`), with `nlinarith` to bound the
coordinates before the finite enumeration.

### Step-by-step

**`norm_le_one_iff_mem` (the characterization — the important one).** Split into two
directions.

*Forward* (`norm ≤ 1` ⇒ in the pod): write `x = (a,b)` and assume
`a² + ab + b² ≤ 1`. The goal is to show `a, b ∈ {−1, 0, 1}` so that a finite check
can finish. By contradiction, if `a` were `≥ 2` or `≤ −2`, use the algebraic identity
`4(a²+ab+b²) = 3a² + (2b+a)²` — a sum of squares, hence nonnegative — so
`a²+ab+b² ≥ 3a²/4 ≥ 3 > 1`, contradicting the assumption. The same argument with
`4(a²+ab+b²) = (2a+b)² + 3b²` rules out `|b| ≥ 2`. So both coordinates are in
`{−1,0,1}`. Now `fin_cases` enumerates all 9 combinations and `decide` checks each:
exactly the 7 pod cells have norm ≤ 1.

*Backward* (`x ∈ pod` ⇒ norm ≤ 1): by `pod_mem_iff`, either `x = (0,0)` (norm 0) or
`x` is a unit (norm 1); `pod_norm_le_one` already establishes this for the six units
by `fin_cases`/`decide`.

**`axialNine_eq_pod_union_spare`.** Pure enumeration: `decide` compares the two
finite sets element by element and confirms the 9 axial states are exactly the 7 pod
cells plus the 2 spare corners.

---

## 4. `HexIsotropy.lean` — every cell has the same 6 neighbors

*Provenance (file header):* Ian (2026-08-28): "ram lookup should be isotropic… up,
down, up-left, up-right, down-left, down-right". Calibration: **DIRECT** (a free
`Z₆` action).

### What it proves

- `translate_injective` — translating by a fixed offset `z` is injective: if
  `z + u = z + v` then `u = v`. (Distinct units give distinct neighbors.)
- `neighbors` (definition) — the six neighbors of a cell = its six unit translations.
- `neighbors_card` — **every cell has exactly 6 distinct neighbors.** Isotropic
  lookup: no cell has a preferred or missing direction.
- `no_fixed_point` — a unit translation never sends a cell to itself: for `u ∈ units`,
  `z + u ≠ z`. (No zero-length "neighbor".)
- `units_rotate_invariant` — multiplying the units by a unit `u` permutes them:
  `{u·v : v ∈ units} = units`. **The pod is rotation-invariant** — turning the
  coordinate frame by any 60° gives back the same six directions.

### Why

A hex-memory address lookup should behave the same no matter which direction you
step in — there should be no "special" axis. Isotropy is what makes the lattice a
*lattice* rather than a skewed grid: the group of six rotations (`Z₆`) acts freely
and transitively on the six neighbor directions. The first three theorems establish
the *free* part (six distinct neighbors, none of them trivial). The last theorem
establishes the *rotation* part: the set of six directions is unchanged when you
rotate it — which is the mathematical content of "changing the angle of lookup at
the next fractal level doesn't change what you find."

### The method

Component-wise `omega` for injectivity, plus finite case analysis
(`decide`/`fin_cases`) over the six units.

### Step-by-step

**`translate_injective`.** If `z + u = z + v` as Eisenstein integers, then component
by component `z.a + u.a = z.a + v.a` and `z.b + u.b = z.b + v.b` (extracted with
`congrArg`). Subtracting `z` gives `u.a = v.a` and `u.b = v.b` (`omega`), so `u = v`.

**`neighbors_card`.** The neighbors are the *image* of the six units under the
translation map. Since translation is injective (`translate_injective`), the image
has as many elements as the source. Lean's `Finset.card_image_of_injective` turns
this into `(neighbors z).card = units.card`, and `units_card` (from `Rotation.lean`)
says `units.card = 6`.

**`units_rotate_invariant`.** There are only six units, so `fin_cases` tries all six
choices of `u`, and for each, `decide` checks the finite equality of the two six-
element sets. (More conceptually: the units are closed under multiplication — proved
as `units_closed_under_mul` in `Rotation.lean` — and multiplying by a fixed unit is
injective, so it permutes the finite set.)

---

## 5. `HexDisk.lean` — how many cells lie within distance `r`

*Provenance (file header):* Ian (2026-08-28): "grab by area, not just scalar and
offset". Calibration: **DIRECT** (the centered hexagonal number).

### What it proves

- `hexDiskCard` (definition) — `hexDiskCard r = 1 + 3·r·(r+1)`, the number of hex
  cells within hex-distance `r` of a center.
- `hexDiskCard_one` — radius 1 gives **7** (the pod).
- `hexDiskCard_two` — radius 2 gives **19**.
- `hexDiskCard_eq` — the closed form `1 + 3r(r+1) = 3r² + 3r + 1`.
- `hexDiskCard_succ` — each new ring adds `6(r+1)` cells:
  `hexDiskCard (r+1) = hexDiskCard r + 6(r+1)`.
- `hexDiskCard_quadratic` — `hexDiskCard r = 1 + 3r + 3r·r` (a restatement: it is
  exactly quadratic in `r`).

### Why

If memory is addressed by *area* ("grab everything within distance `r`"), the first
question is how many cells that is — the *capacity* of a radius-`r` neighborhood.
On a hex lattice the answer is the centered hexagonal number `3r² + 3r + 1`
(1, 7, 19, 37, …). Each concentric ring has `6k` cells, so the growth is quadratic,
not linear — the same way the area of a disk grows quadratically in its radius. This
is the hex analog of the binary `2^k`-ring growth: it tells you how an address space
expands as you widen the neighborhood. (The header notes the *lattice-count* version
— actually counting cells with `hexDist ≤ r` — is a stated future target, not yet in
this file.)

### The method

Pure algebraic rewriting (`ring`) of the closed form.

### Step-by-step

**`hexDiskCard_eq` / `hexDiskCard_quadratic`.** Unfold the definition
`1 + 3r(r+1)` and let `ring` expand/reassociate: `3r(r+1) = 3r² + 3r`, so the form
`3r² + 3r + 1` and the rearranged form `1 + 3r + 3r²` are equal. These are
identities, no induction needed.

**`hexDiskCard_succ`.** Compute `hexDiskCard (r+1) = 1 + 3(r+1)(r+2)` and
`hexDiskCard r + 6(r+1) = 1 + 3r(r+1) + 6(r+1)`; `ring` expands both to the same
polynomial. The statement says the *difference* between consecutive disks is
`6(r+1)` — the size of the `(r+1)`-th ring.

**`hexDiskCard_one` / `hexDiskCard_two`.** `decide` evaluates the formula at
`r = 1` and `r = 2`: `1 + 3·1·2 = 7` and `1 + 3·2·3 = 19`.

---

## 6. `OffsetGrid.lean` — the hex lattice is an offset square grid

*Provenance (file header):* Ian (2026-08-28): "a hexagon can be modeled by columns of
squares that are 0.5 off from each other… we can address as a rectangle".
Calibration: **DIRECT** (the standard "odd-r" offset-coordinate embedding).

### What it proves

- `offset` (definition) — the brick-wall embedding: axial `(a,b)` sits at square-grid
  `(col, row) = (2a + b, b)`. Adjacent rows shift by one column, so every other
  square is used, offset by one per row.
- `offsetInv` (definition) — the inverse on the image: from `(c, b)` with
  `c ≡ b (mod 2)`, recover `a = (c − b)/2`.
- `offset_injective` — the offset map is injective: the hex lattice embeds into the
  square grid with no collisions.
- `offset_image_iff` — **the image is exactly the checkerboard**: `(c, b)` is a hex
  cell if and only if `c % 2 = b % 2` (column and row have matching parity).
- `offset_offsetInv` — `offset` is a **right inverse** on the checkerboard: applying
  `offset` to `offsetInv(c, b)` returns `(c, b)`.
- `offsetInv_offset` — `offsetInv` is a **left inverse** on the hex side: every hex
  cell is recovered from its image. Together these make `offset` a **bijection onto
  the checkerboard** — *the hex grid IS the offset square grid.*

### Why

Hardware and software both like rectangles: a square grid is trivially addressable by
(row, column). A hex grid at first looks awkward, but it has a well-known trick — the
"brick wall" — where you squash each row half a cell sideways and pack the hexagons
onto a square grid, using only every *other* square (the ones whose row and column
share parity). The architecture's promise "we can address a hexagon as a rectangle"
is exactly the claim that this embedding is a genuine bijection: no two hex cells land
on the same square, and every used square corresponds to exactly one hex cell. This
is what lets a hex memory reuse ordinary rectangular addressing logic.

### The method

`omega` (linear integer arithmetic) for both the injectivity and the parity
round-trips.

### Step-by-step

**`offset_injective`.** Suppose `offset x = offset y`, i.e.
`(2a + b, b) = (2a' + b', b')`. The second component gives `b = b'`; the first gives
`2a + b = 2a' + b'`, and substituting `b = b'` leaves `2a = 2a'`, hence `a = a'`
(`omega`). So `x = y`.

**`offset_image_iff`.** *Forward:* if `(c, b) = (2a + b, b)` for some hex cell, then
`c = 2a + b`, so `c − b = 2a` is even, i.e. `c ≡ b (mod 2)`. *Backward:* given
`c ≡ b (mod 2)`, define `a = (c − b)/2` (the division is exact by the parity
hypothesis) and check `offset(a, b) = (2a + b, b) = (c, b)` — the `2·((c−b)/2) = c−b`
step is exactly where the parity hypothesis is used (`omega`).

**`offsetInv_offset` (round-trip on the hex side).** For `x = (a, b)`, compute
`offset x = (2a + b, b)`, then `offsetInv (2a+b) b` = `((2a+b−b)/2, b)` = `(a, b)`
since `(2a)/2 = a`. This is the left-inverse direction; combined with
`offset_offsetInv` (the right-inverse direction, the same arithmetic in reverse) it
makes `offset` a bijection onto the parity-matched squares.

---

## 7. `CrtHex.lean` — the six rotations split into sign × 3-cycle

*Provenance (file header):* Ian (2026): "the six units are ±1 times the three
rotations 1, ω, ω²". The Chinese Remainder Theorem `Z₆ ≅ Z₂ × Z₃` (2 and 3 are
coprime). Calibration: **DIRECT** (classical finite group theory / CRT).

### What it proves

- `sign` (definition) — the sign subgroup `{+1, −1}` (two elements).
- `cycle` (definition) — the 3-cycle subgroup `{1, ω, ω²}` (three elements).
- `sign_card` / `cycle_card` — there are 2 signs and 3 cycle elements.
- `sign_subset_units` / `cycle_subset_units` — both subgroups live inside the units.
- `signCycleMul` (definition) — the CRT map `(s, c) ↦ s · c` from `sign × cycle` into
  the units.
- `unitsSubtype_card` — there are 6 units (as a subtype).
- `signCycleMul_surjective` — **every unit is `±1` times a 3-cycle element.** The
  CRT map hits all six units.
- `signCycle_card` — `sign × cycle` has `2 × 3 = 6` elements.
- `signCycleMul_injective` — the CRT map is one-to-one (so it is a bijection).
- `modPair` / `crtInv` (definitions) — on the angle index: `n ↦ (n mod 2, n mod 3)`
  and its inverse `(a, b) ↦ 3a + 4b (mod 6)`.
- `mod6_iff_mod2_mod3` — the CRT bijection **`Fin 6 ≃ Fin 2 × Fin 3`**: an angle
  index `n : Fin 6` is determined by `n mod 2` (the sign) and `n mod 3` (the cycle).
- `modPair_bijective` — that index map is a bijection.

### Why

A rotation by a multiple of 60° has two independent pieces: a **sign** (whether you
reflect through the origin — the `±` — captured by parity mod 2) and a **3-cycle**
(which of the three 120° positions `1, ω, ω²` you're at — captured mod 3). Because 2
and 3 are coprime, the Chinese Remainder Theorem says these two pieces *fully
determine* the angle and can be recovered independently: `Z₆ ≅ Z₂ × Z₃`. This
decomposition is what lets the architecture store a rotation as two cheap fields —
one bit of sign and one trit of cycle — instead of a single mod-6 counter, and
reassemble it with the formula `3a + 4b` (which is `a mod 2` and `b mod 3`).

### The method

Finite case analysis over 6 units and over `Fin 2 × Fin 3`, plus the finite
pigeonhole principle (surjective + equal cardinals ⇒ bijective).

### Step-by-step

**`signCycleMul_surjective`.** There are exactly six units, so `fin_cases` enumerates
them and, for each, exhibits the `(sign, cycle)` pair that multiplies to it:
`1 = +1·1`, `−1 = −1·1`, `ω = +1·ω`, `−ω = −1·ω`, `ω² = +1·ω²`, `−ω² = −1·ω²`.
Each case is closed by `decide` on the concrete multiplication.

**`signCycleMul_injective`.** Rather than check the 36 products directly, use the
finite pigeonhole principle: the map is *surjective*, and both its domain
(`sign × cycle`) and codomain (the units) have cardinality 6 (`signCycle_card` and
`unitsSubtype_card`). Lean's `Fintype.bijective_iff_surjective_and_card` converts
"surjective between two 6-element sets" into "bijective", and injectivity is the
first half of bijectivity.

**`mod6_iff_mod2_mod3` (the angle-index CRT).** Build the equivalence explicitly:
`toFun` = `n ↦ (n mod 2, n mod 3)`, `invFun` = `(a, b) ↦ (3a + 4b) mod 6`. The
left-inverse proof runs `fin_cases` over all six `n`; the right-inverse runs
`fin_cases` over all `2 × 3` pairs. (The reason `3a + 4b` works: mod 2, `3 ≡ 1` and
`4 ≡ 0`, so it returns `a`; mod 3, `3 ≡ 0` and `4 ≡ 1`, so it returns `b`.)

---

## 8. `TernaryCrt.lean` — a ternary number's angle is its parity and its last trit

*Provenance (file header):* the two "rebuild anchors" of the trit-tricks survey
(`docs/compute/trit_tricks.md`): (1) the ternary CRT instance — the "XOR → hex"
bridge — and (2) the trit-shift `÷3` truncation — the ternary analog of the binary
`d >> 1` renormalization-group flow. Calibration: **DIRECT** (classical modular
arithmetic, `2·3 = 6` coprime).

### What it proves

For a balanced-ternary digit list `ds` (little-endian: index `i` is the `3^i` place,
so `ds 0` is the least-significant trit), with `val ds = Σᵢ tritInt(ds i)·3^i` and
`digitSum ds = Σᵢ tritInt(ds i)`:

- `val_add_shift3` — the base-3 expansion: `val ds = tritInt(ds 0) + 3·val(shift3 ds)`.
  The whole value is the last trit plus 3 times the rest.
- `val_mod_three` — **`val ds mod 3` is the least trit** (`ds 0`), because
  `3^i ≡ 0 (mod 3)` for all `i ≥ 1`.
- `val_mod_two` — **`val ds mod 2` is the digit-sum parity**, because `3^i ≡ 1 (mod 2)`
  for all `i`.
- `modEq_six_of_two_three` (lemma) — congruent mod 2 and mod 3 ⇒ congruent mod 6
  (2 and 3 coprime).
- `crt_assembly` — the CRT inverse: `x % 6 = (3·(x % 2) + 4·(x % 3)) % 6`.
- `val_crt` — **the CRT assembly:** `val ds mod 6` is recovered from the digit-sum
  parity `digitSum ds % 2` and the least trit `tritInt(ds 0) % 3` via `3a + 4b`.
  A balanced-ternary number's `Z₆` angle is exactly `(t₀, S mod 2)`.
- `tritInt_eq_zero_of_dvd_three` (lemma) — a trit divisible by 3 is the null trit
  (the only multiple of 3 in `{−1, 0, +1}` is 0).
- `shift3_of_null` — if the least trit is null, `val(shift3 ds) = val ds / 3`.
- `div3_truncation` — **if `val ds` is a multiple of 3, dropping the least trit
  divides the value by exactly 3**: `val(shift3 ds) = val ds / 3`.

### Why

Two different "views" of a ternary number must agree. First: the architecture stores
a cell's *angle* as `n mod 6` (the `Z₆` rotation). This theorem says you don't need
to compute the full value to get the angle — the angle is entirely determined by two
cheap quantities: the **parity of the digit sum** (mod 2, the sign) and the **last
trit** (mod 3, the cycle). That is the ternary instantiation of `CrtHex`'s
`Z₆ ≅ Z₂ × Z₃` — the "XOR → hex" bridge, because parity (mod 2) is exactly what the
binary XOR kernel computes, and this shows it plus the last trit is enough to get the
full 6-way angle. Second: the trit-shift `÷3` is the ternary version of binary's
`d >> 1` (which halves a number / drops the least bit). Dropping the least trit
*divides by 3* — the base-3 renormalization step that moves a cell one ring inward.

### The method

Base-3 expansion splitting (`Fin.sum_univ_succ`), modular arithmetic via
`Int.ModEq` (with the CRT lift for coprime 2 and 3), and `ring` for the polynomial
identities.

### Step-by-step

**`val_add_shift3` (the base-3 expansion).** Split the sum over `Fin (n+1)` into its
first term (`i = 0`) and the rest (`i = k+1`) using `Fin.sum_univ_succ`. The first
term is `tritInt(ds 0)·3⁰ = tritInt(ds 0)`. Each remaining term
`tritInt(ds(k+1))·3^(k+1) = 3·(tritInt(ds(k+1))·3^k)`, so the whole tail is
`3 · val(shift3 ds)` after pulling the common factor 3 out with `Finset.mul_sum` and
`ring`. This mirrors the identity `x = x mod 3 + 3·(x / 3)` at the digit-list level.

**`val_mod_three`.** Substitute `val_add_shift3`: `val ds = t₀ + 3·(shifted)`. The
term `3·(shifted)` is divisible by 3, so it vanishes mod 3
(`Int.add_mul_emod_self_left`), leaving `val ds mod 3 = t₀ mod 3`.

**`val_mod_two`.** Each weight satisfies `3^i ≡ 1 (mod 2)` (3 is odd). By
`Int.ModEq.pow` and multiplication, each weighted term `tritInt(ds i)·3^i` is
congruent mod 2 to `tritInt(ds i)`, and `Int.ModEq.sum` adds these congruences across
all indices, giving `val ds ≡ digitSum ds (mod 2)`. So the parity of the value is the
parity of the balanced digit sum.

**`val_crt` (the CRT assembly).** Start from `crt_assembly (val ds)`, which says
`val ds % 6 = (3·(val ds % 2) + 4·(val ds % 3)) % 6`. Replace `val ds % 2` by
`digitSum ds % 2` (using `val_mod_two`) and `val ds % 3` by `tritInt(ds 0) % 3`
(using `val_mod_three`). The result is the headline identity. The supporting lemma
`modEq_six_of_two_three` is the CRT lift: if a number divides the difference in both
2 and 3, and 2, 3 are coprime, then 6 divides it (via `Nat.Coprime.mul_dvd_of_dvd_of_dvd`).

**`div3_truncation`.** Assume `3 ∣ val ds`. First show the least trit must be null:
from `val_add_shift3`, `3 ∣ val ds` and `3 ∣ 3·(shifted)` give
`3 ∣ (val ds − 3·(shifted)) = tritInt(ds 0)` (by `Int.dvd_sub`), and
`tritInt_eq_zero_of_dvd_three` forces `tritInt(ds 0) = 0`. Then `shift3_of_null`
applies: `val ds = 3·val(shift3 ds)`, so `val(shift3 ds) = val ds / 3` exactly.
Dropping the last trit divides by 3.

---

## How the eight fit together

These eight modules form one chain of reasoning about the hex memory's *geometry*:

1. **Why ternary at all** — `TritPacking` + `FewerTrits`: `2ⁿ < 3ⁿ`, and `k−1`
   trits already cover `2^k` states, so the ternary namespace wins exponentially.
2. **What the cell looks like** — `Pod`: the radius-1 neighborhood is exactly 7
   cells, with 2 spare norm-3 corners as carry states.
3. **What the neighborhood looks like from any cell** — `HexIsotropy`: every cell
   sees the same 6 directions, and the frame is rotation-invariant.
4. **How much a neighborhood holds** — `HexDisk`: the centered hexagonal number
   `3r² + 3r + 1` (quadratic area growth).
5. **How to address it** — `OffsetGrid`: the hex lattice is a bijection onto the
   checkerboard squares, so it can be addressed as a rectangle.
6. **How rotation is encoded** — `CrtHex` + `TernaryCrt`: the six-way angle is
   `Z₆ ≅ Z₂ × Z₃` — a sign (parity) times a 3-cycle (last trit) — reassembled by
   CRT as `3a + 4b`, with the trit-shift `÷3` as the base-3 renormalization step.

*Faithfulness note:* all theorem names, statements, tactic choices, and
origin/calibration labels above are taken directly from the file headers and bodies
of the eight modules and their support files (`Conventions`, `Rotation`,
`PolarGate`, `SevenHex`). Nothing here is conjectural; where a header explicitly
marks a claim as out of scope or a future target (e.g. `HexDisk`'s lattice-count
version), that deferral is stated as such.
