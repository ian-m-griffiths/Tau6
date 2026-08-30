# Eisenstein Free Ops — a quantitative inventory of "structurally free / cheap" Tau operations

**2026-08-30.** The claim under test: *"a lot of operations in ternary and Einstein are
just easier to do."* This file makes that claim quantitative for the **address / geometry**
operations of the Eisenstein hex lattice. It says exactly which operations are FREE (0–1
address-op), which are CHEAP (a handful of mul/add), what BINARY computation each one
replaces, and — the honest part — where the "easier" claim is *false*.

**Grounding.** Every claim below cites a proven Lean theorem (`proofs/lean-src/hexagon/Hexagon/`)
and/or a synthesized RTL cell (`rtl/`). Notation: `ℤ[ω]`, `ω = e^{iπ/3}`, `ω² = ω − 1`,
`N(a+bω) = a² + ab + b²`, units `Z₆ = {±1, ±ω, ±ω²}`. A register is one lattice point
`(a, b) = a + bω`; `a, b` are 6-trit balanced coefficients (word = 12 trits = 24 bits).

---

## 0. The three honest facts up front

Before the per-op inventory, the three facts that calibrate everything:

1. **The saving is a *coordinate-system* win, not a *radix* win.** The big "rotation replaces
   trig" saving comes from representing lattice points in the Eisenstein basis `{1, ω}` (at 60°),
   where the 60° rotation matrix has `{0, ±1}` entries — **a binary CPU using the same axial
   coordinates gets the same saving.** What ternary adds on top is narrower (see #2).

2. **Ternary's own contribution is real but small and localized to sign.** `gate_tneg` synthesizes
   to **0 cells / 0.000 µm²** (`rtl/gate_area.txt`) — negation is literally a wire swap, not
   two's-complement's invert+increment. Balanced digits also remove the sign bit and the
   `±`-asymmetry. That is the honest ternary-specific win; it is not a general per-bit win.

3. **Ternary compute is a *measured loss*, not a win, everywhere else.** `ThresholdLowerBound.lean`
   proves binary minimizes thresholds-per-bit (`binary_min_threshold_per_bit`,
   `ternary_worse_than_binary`); the ratio is `ternary_binary_ratio = 2·ln2/ln3 ≈ 1.26×`. Measured
   (yosys/sky130, `rtl/word_fairfight.txt`): ternary adder ≈ **3.94×** and ternary multiplier ≈
   **1.72×** the binary area *per bit*. `rtl/README.md` records the mod-3 sum at ≈ **1.42×/bit**.

The operations below win by doing **fewer, simpler, integer-exact things** in the geometry/address
domain — not by cheaper per-bit arithmetic.

---

## 1. The FREE operations (0–2 address-ops, no multiplier)

### 1a. NEGATION — `-z = (-a, -b)`

- **(a) Eisenstein/ternary form.** `Neg` instance (`Conventions.lean` L45): componentwise
  negation. In balanced ternary this is **flip `+1 ↔ −1` per digit, `0 → 0`** — the `tneg`
  gate, a two-wire swap (`rtl/ternary_gates.v`, `cpu.v` `fneg6`). No carry, no borrow, no
  complement-then-increment.
- **(b) Binary equivalent.** Two's-complement negation: bitwise invert (free) **+ 1**
  (a full N-bit ripple increment = N binary full adders).
- **(c) Honest saving.** The increment. Negation is **0 address-ops**; the binary equivalent
  is **1 N-bit adder**. Measured: `gate_tneg` = 0 cells; one ternary `tadd1` cell = 146.39 µm²
  vs one binary FA = 33.78 µm² (`rtl/gate_area.txt`). Also structural: balanced ternary is
  `±`-symmetric, so `-z` and `z` have identical magnitude distributions (no sign-bit asymmetry,
  no sign-extension on negate).

> Calibration: the saving is *real but exactly one increment*. Negation was never expensive
> in binary; this is the smallest of the free ops, and it is the one true *radix* win (not a
> coordinate-system win).

### 1b. ROTATION by ωᵏ (60°·k) — the biggest single saving

- **(a) Eisenstein/ternary form.** `Gauge.lean` `units_eq_omega_pow` / `units_eq_omega_powers`
  (the six units are exactly `ω⁰…ω⁵`), `Rotation.lean` `units_card`, `units_closed_under_mul`
  (Z₆ group), `CrtHex.lean` `mod6_iff_mod2_mod3` (Z₆ ≅ Z₂×Z₃ = sign × 3-cycle). The concrete
  linear action (`cpu.v` TROT, `Gauge.lean` `omegaPow_zero…five`):

  | k | ωᵏ | (a, b) ↦ |
  |---|---|---|
  | 0 | 1  | `(a, b)` |
  | 1 | ω  | `(−b, a+b)` |
  | 2 | ω² | `(−(a+b), a)` |
  | 3 | −1 | `(−a, −b)` |
  | 4 | −ω | `(b, −(a+b))` |
  | 5 | −ω² | `(a+b, −a)` |

  Every entry is `{0, ±1}`-linear: one shared add `a+b` plus a free negate. k=0 and k=3 are
  pure wire permutations (0 adds). **No multiplier, no table, no trig.**
- **(b) Binary equivalent (Cartesian).** A 2D rotation matrix `x' = x cosθ − y sinθ`,
  `y' = x sinθ + y cosθ` = **4 multiplies + 2 adds**, and for θ = 60° the entries are
  `cos60° = ½` and `sin60° = √3/2` — **irrational**. An *exact* integer 60° rotation is not an
  integer operation at all in Cartesian coordinates: it needs floating point (rounding error)
  or a degree-2 field extension (ℚ(√3)), which *is* the Eisenstein structure wearing a disguise.
- **(c) Honest saving.** Against **Cartesian** binary: **4 mul + 2 add + irrational √3 → 1 add +
  0 mul** — and it is *structural*: `norm_mul_unit` / `norm_unit_mul` (`Gauge.lean`) prove the
  norm is unchanged, so rotation is an exact gauge change, not an approximation. Against the
  **fair axial-coordinate binary** (`emulation_geometry.md` §3), the rotation is **≈ a tie**:
  the same `{0,±1}` matrix is one add + a sign flip on both sides, and the only ternary-specific
  delta is the **free negate** (0 cells vs invert+increment) — *not* a 4× win.

> **Calibration (important).** This saving is **not uniquely ternary** — it is the *Eisenstein
> basis*. A binary ALU that stores `(a, b)` axial coordinates and applies the `{0, ±1}` matrix
> above gets the same 1-add rotation. The ternary-specific delta is only the free negate
> (no increment on the `−` entries). So: *"rotation is free" = "the hex lattice is the
> geometry"*, and only the sign-flips inside it are a radix bonus.

### 1c. NEIGHBOR — `hex_neighbor` = `+unit` (free address arithmetic)

- **(a) Eisenstein/ternary form.** `HexIsotropy.lean` `neighbors` (the 6 unit translations),
  `neighbors_card` (every cell has exactly 6 neighbors), `translate_injective`,
  `no_fixed_point`, `units_rotate_invariant` (the pod is rotation-invariant). In RTL
  (`rtl/hex_encode.v` `hex_neighbor`): `na = a + da`, `nb = b + db`, where `(da, db)` is one of
  the six unit offsets. **Two adds**, uniform across all six directions.
- **(b) Binary equivalent.** A square-grid neighbor is *also* two adds (`x±1, y` / `x, y±1`) —
  equally cheap. But a **hexagonal grid indexed on a rectangular array** needs the odd-r/odd-q
  *offset-row correction* (an extra conditional +add, or a cube-coordinate decode) because the
  rows are staggered. That special-casing disappears when the address *is* an Eisenstein integer.
- **(c) Honest saving.** No big op-count delta vs a square grid (both are 2 adds). The win is
  **uniformity/isotropy**: the same 2-add rule works for all 6 directions with no row-parity
  conditional, and `neighbors_card` guarantees the lookup is isotropic. The re-encode
  (`signFold` + Szudzik pair, `Bijection.lean` `toNat`) only fires at the hex↔binary boundary.

---

## 2. The CHEAP operations (a handful of mul/add — cheap, *not* free, and *not* cheaper than binary)

### 2a. CONJUGATE — `conj(a, b) = (a+b, −b)` (TCONJ)

- **(a) Eisenstein form.** `Conjugate.lean` `conj` (L27), `ω̄ = ω⁻¹ = 1 − ω`, so
  `conj(a,b) = (a+b, −b)`. One add + one free negate. Proved: `conj_involutive`, `conj_norm`,
  `conj_mul`, `mul_conj_eq_norm` (`z·z̄ = N(z)` — the fact the whole dot/wedge split runs on).
  RTL: `rtl/ga_ops.v` `tconj` = free `−b` wire swap + one `a+b` add.
- **(b) Binary equivalent.** Complex conjugation `(x, y) → (x, −y)` = **one negate**
  (one increment). *Slightly cheaper* than the Eisenstein version.
- **(c) Honest saving.** **None** (the Eisenstein form costs 1 add *more* than plain complex
  conjugation, because of the `ω̄ = 1−ω` coupling). Conjugate is "cheap" in the absolute sense
  (1 add, 0 mul) and is *necessary* — it is the projection onto the real axis that splits the
  geometric product — but it is not a *saving* over binary.

### 2b. NORM — `N = a² + ab + b²` (the distance/polarization measure)

- **(a) Eisenstein form.** `Conventions.lean` `norm` (L65), `norm_mul` (multiplicative).
  `Gauge.lean` `norm_eq_det`: **N is the determinant of the regular representation — the area
  scalar** — and `norm_of_unit` / `norm_mul_unit` / `norm_unit_mul` make it Z₆-invariant.
  Compute: 3 mul + 2 add naively (`rtl/ga_ops.v` `tnorm_full`), or 2 mul + 2 add via
  `(a+b)² − ab` (`cpu.v` `tnorm_trits_opt`, −9% area). One "dot-like" op.
- **(b) Binary equivalent.** Cartesian squared-length `x² + y²` = **2 mul + 1 add** — but it is
  *not* multiplicative, does *not* count hex rings, and is *not* an area in any natural sense.
  The exact Euclidean length needs a square root (irrational, floating point).
- **(c) Honest saving.** ~Tie on op count (N costs one extra cross-term for the non-orthogonal
  `{1, ω}` basis). The real gain is **qualitative**: `N` is an *exact integer* squared-distance
  that is multiplicative (`norm_mul`), counts the hexagonal rings (`N = 1, 3, 4, 7, 9, 12, …`
  are the lattice's squared-radius levels), and is the polarization measure. It replaces
  "2 mul + 1 add + a sqrt" with "2–3 mul + 2 add, exact".

### 2c. DOT / WEDGE / SYMDOT — the geometric product's scalar/bivector split (TDOT/TWEDGE/TSYMDOT)

- **(a) Eisenstein form.** `DotWedge.lean`: `dot z w = (z·conj w).a`, `wedge z w = (z·conj w).b`,
  with `gp_decomp` (`z·conj w = dot + wedge·ω`), `wedge_antisymm` (the skew/curl flips sign),
  `dot_self = N`, `wedge_self = 0`, and the Pythagorean identity `dot_sq_add_wedge_sq`
  (`dot² + dot·wedge + wedge² = N(z)·N(w)`). `SymDot.lean`: `symdot = N(z+w) − N(z) − N(w)`,
  `symdot_comm`, `symdot_eq_two_dot_add_wedge` (the clean *symmetric* integer correlation —
  the raw `dot` is *not* symmetric: `dot_swap : dot z w = dot w z + wedge w z`).
  RTL (`rtl/ga_ops.v` `ga_split_trits`): all three computed from **4 shared scalar products**
  `ac, ad, bc, bd` — the *same* 4 products the naive Eisenstein multiply uses. So the entire
  dot+wedge+symdot triple costs ≈ **one Eisenstein multiply** (4 mul + ~5 add), and `tdot` =
  3 mul + 2 add, `twedge` = 2 mul + 1 sub, `tsymdot` = 6 terms (or `2·dot + wedge`).
- **(b) Binary equivalent.** A 2D dot = 2 mul + 1 add; a 2D cross = 2 mul + 1 sub — so a
  dot+cross pair is 4 mul + 2 add, *roughly the same* as the Eisenstein triple. But the binary
  wedge/cross needs `sinθ` (floating point) unless you already have the coordinates, and there
  is no integer polarization identity.
- **(c) Honest saving.** ~Tie on op count (the 60° basis costs ~1.5× the products of an
  orthonormal 2D dot). The gain is **exactness and algebra**: the wedge is an *exact integer*
  skew/curl (no float `sinθ`), the dot/wedge/norm close under the *one* multiplicative identity
  (`dot_sq_add_wedge_sq`), and the symmetric `symdot` falls out of the same 4 products for free.

### 2d. The 7-cell POD — the isotropic radius-1 neighborhood

- **(a) Eisenstein form.** `Pod.lean`: `pod = {0} ∪ units`, `pod_card = 7`,
  `pod_norm_le_one`, `axialNine_eq_pod_union_spare` (the 9 axial `{-1,0,1}²` states split into
  the 7-cell pod + the two norm-3 carry states `(1,1), (−1,−1)`), and the pinned
  characterization `norm_le_one_iff_mem`. `HexIsotropy.lean` `units_rotate_invariant`: the pod
  is rotation-invariant. RTL (`rtl/hex_pod_addr.v`): decode center once, then 6× (2 adds) +
  re-encode — "the only arithmetic on the whole path is the single isqrt in the decode and the
  6 pair·fold re-encodes."
- **(b) Binary equivalent.** A 7-point stencil on a square array, with the hex neighbors in
  staggered/off-grid storage requiring index correction per row.
- **(c) Honest saving.** The pod is **free to enumerate** (it *is* the unit set), and the
  lookup is 12 adds + a boundary re-encode. The win is isotropy + rotation-invariance, not raw
  op count.

---

## 3. The honest caveat — address/geometry vs. per-bit READ

Every operation above is an **address / geometry** operation. They are cheap **because the
lattice IS the geometry**: the Z₆ rotations, the norm-as-area, the conjugate, and the 6-neighbor
pod are all native integer structure of `ℤ[ω]`. That is why "a lot of operations are just easier
to do" is *true* for the geometry/address layer.

It is **irrelevant — in fact mildly *negative* — for generic per-bit arithmetic**, and that line
must be drawn explicitly:

- **A stored-value READ still costs 2 thresholds per trit.** To distinguish the 3 levels
  `{−1, 0, +1}` you need `b − 1 = 2` thresholds; a binary bit needs 1. Per *bit* of information
  this is `2·ln2/ln3 ≈ 1.26×` (`ThresholdLowerBound.lean` `ternary_worse_than_binary`,
  `ternary_binary_ratio`; the file's "2-threshold tax"). `null_is_free` (`TernaryCell.lean`)
  says the *zero state* costs nothing to *hold*, but *reading* a trit is not free.
- **Ternary arithmetic is heavier per bit, measured.** `rtl/word_fairfight.txt`: 6-trit adder
  ≈ 50.98 µm²/bit vs 10-bit binary ≈ 12.95 µm²/bit (**≈ 3.94×**); multiplier ≈ 287.74 vs
  167.22 µm²/bit (**≈ 1.72×**). `rtl/README.md`: mod-3 sum ≈ 1.42×/bit. `rtl/README.md`
  caveat #1 says it plainly: **"Compute is a measured loss, not a win."**

So the "easier" claim decomposes into two statements of different truth values:

| claim | verdict |
|---|---|
| Hex/Eisenstein *geometry* (rotation, norm, conjugate, dot/wedge, neighbor, pod) is easier | **TRUE** — fewer, integer-exact ops; no trig/√3/sqrt/sin |
| Ternary *arithmetic* is easier than binary per bit | **FALSE** — 1.26× threshold tax, 1.42×/bit mod-3 sum, 3.94× adder area/bit |

The geometry win is real and radix-independent (binary axial coordinates capture most of it);
the radix win is real but narrow (free negation, symmetric ±, no sign bit).

---

## 4. The table

`address ops` = integer add/sub/negate on the axial pair; a "mul" is a scalar coefficient
multiply. Costs are for 6-trit coefficients.

| operation | ternary/Eisenstein cost (address ops) | binary equivalent | honest saving |
|---|---|---|---|
| **NEGATION** `-z` | **0** (wire swap, `gate_tneg` = 0 cells) | invert + increment (1 N-bit adder) | the increment; ± symmetric |
| **ROTATION** `ωᵏ` | **1 add + free negate** (k=0,3: 0 adds) | axial binary (a,b): 1 add + 2's-complement negate (≈ tie); Cartesian (x,y): 4 mul + 2 add + √3 (irrational → not exact in ℤ) | **≈ tie vs axial binary — the only ternary delta is the free negate** (`emulation_geometry.md` §3) |
| **NEIGHBOR** `+unit` | **2 adds**, uniform | square grid 2 adds (tie); hex-on-array needs odd-r/odd-q correction | the offset correction; isotropy |
| **CONJUGATE** `(a+b,−b)` | **1 add + free negate** | complex conj 1 negate | none (costs +1 add; needed for dot/wedge) |
| **NORM** `a²+ab+b²` | 2–3 mul + 2 add | Euclidean `x²+y²` 2 mul + 1 add (not multiplicative; +sqrt if exact) | ~tie; exact integer, multiplicative, ring-counting |
| **DOT** `(z·conj w).a` | 3 mul + 2 add | 2D dot 2 mul + 1 add | ~tie; exact integer scalar |
| **WEDGE** `(z·conj w).b` | 2 mul + 1 sub | 2D cross 2 mul + 1 sub (float sinθ) | ~tie; exact integer skew/curl |
| **SYMDOT** (polarization) | free with dot+wedge (same 4 products) | no integer analog | exact symmetric correlation for free |
| **POD** (7-cell) | free enum (Z₆+center); lookup 12 adds + re-encode | 7-pt stencil on square array | isotropy, rotation-invariance |

**Net:** the FREE tier is **negation, rotation, neighbor** (0–2 address-ops, no multiplier);
the CHEAP tier is **norm, conjugate, dot/wedge** (a handful of mul/add, ~tie with their binary
analogs but integer-exact and algebraically closed). The one op that replaces the most
*Cartesian* binary work is **rotation** — in Cartesian `(x,y)` it deletes a full trig rotation
matrix (and its √3 exactness problem) in favor of a `{0, ±1}` coordinate permutation; against
axial-coordinate binary it is **≈ a tie**, with only the free negate as the ternary-specific
delta.

---

## 5. One-liner

**These ops are genuinely easier — but because the hex lattice *is* the geometry, not because
ternary arithmetic is faster: rotation, negation, and neighbor are free-to-2-add address ops,
norm/conjugate/dot/wedge are a handful of exact integer mul/adds, and none of that buys back
the 1.26–3.94× per-bit cost of generic ternary arithmetic, which remains a measured loss.**
