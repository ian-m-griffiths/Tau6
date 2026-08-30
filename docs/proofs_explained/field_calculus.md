# Field Calculus & the Causal Lattice — a human-readable reading of the Lean proofs

These two modules (`CausalLattice.lean`, `FieldCalculus.lean`) are the *field-theory*
corner of the Hexagon proofs. Together they give the engine its actual workload:

- **`CausalLattice.lean`** proves that the hex grid ℤ[ω] is an isotropic, skew-symmetric,
  conserved causal lattice — the flow/curl/divergence structure of temporal precedence.
- **`FieldCalculus.lean`** proves the **field-calculus round-trip** — the `TGRAD`/`TRECON`
  pair from `rtl/grad_recon.v` — plus the 6-point Laplacian and the `TRELAX` heat step.

The two files are deliberately kept distinct: `CausalLattice`'s `curl` takes a **two-argument
wedge weight** `w : Eisenstein → Eisenstein → ℤ` (it is a *circulation* of directed edges),
while `FieldCalculus`'s `curl6` takes a **scalar field** `f : Eisenstein → ℤ` (it is a
*gradient-computed skew grade*). They meet at the same idea — divergence and curl are the
scalar and bivector grades of one derivative — but on different input types.

Both files carry the calibration label **DIRECT** (finite arithmetic over 6 ring cells,
order theory, skew-symmetric algebra), and both are **PROVED — zero `sorry`**.

---

# 1. `CausalLattice.lean` — the hex causal lattice

## What it proves

The file's header ("Idea history") says this module replaces the Wolfram-Physics "diamond
lattice" motif (`a→b, a→c, b&c→f`) with the **hexagonal** lattice ℤ[ω], and reframes "causal
structure" as **temporal precedence** — the wedge `O_ab − O_ba` — explicitly *not* a finished
causal arrow (a Rung-1 association: an orientation signal, never an arrow). It proves the four
facts Ian chose for the framing:

| Theorem | Plain-English statement |
|---|---|
| `causal_isotropy` | **Isotropy.** Every cell `z` has exactly **6** distinct unit-neighbors (`(neighbors z).card = 6`). The six Z₆ units act freely by translation. |
| `causal_skew` | **Skew.** The wedge is antisymmetric: `wedge O a b = − wedge O b a`. Reversing a directed edge negates it — this *is* the curl/circulation content of temporal precedence. |
| `diamond_balance` | **Conservation.** The center's causal outflow is exactly cancelled by the 6 ring cells' backflow: `flow w 0 + Σ_{u∈units} w u 0 = 0`. The discrete `Σ(O−E)=0` at the pod. |
| `pod_is_causal_diamond` | **Diamond.** The pod (center + 6 ring) has exactly **7** cells, and it is Z₆-invariant: rotating by any unit permutes the 6 directions back to themselves. |
| `causal_diamond_norm_le_one` | The causal diamond is exactly the set of cells at causal distance ≤ 1: every pod cell has `norm ≤ 1`. |

It also *defines* (not just proves) the two field operators at a cell:

- `flow w z = Σ_{u∈units} w z (z+u)` — the **divergence**: net wedge flowing OUT along the
  6 unit directions (positive = source, negative = sink). This is the rebuild's
  `flow(w) = Σ_nb wedge(w, nb)`.
- `curl w z = w z (z+ω) + w z (z+ω²) − w z (z−ω) − w z (z−ω²)` — the **circulation**: the
  bivector-weighted (Im) sum over the 4 non-real directions; the two ±1 (pure-Re) directions
  drop out.

## Why

The causal lattice is the *topology* the field calculus runs on. Before you can talk about a
gradient or a divergence you have to know the grid is a **regular, directionally-consistent**
place: every cell has the same 6 neighbors (isotropy), every directed edge has a well-defined
orientation with a clean reverse (skew), and every source is matched by a sink so nothing is
created or destroyed (conservation). The pod (center + 6 ring = the closed radius-1 ball) is
the causal diamond: the common cause and its common effects, the minimal neighborhood where
the balance can even be stated. If any of these four failed, the "field" would be ill-defined
— divergence would leak, curl would not be a proper rotation, and the round-trip in
`FieldCalculus` would have no geometry underneath it.

## The method

All four facts are **finite arithmetic over the 6 units** (the Finset `units` is literally the
6-element set `{±1, ±ω, ±ω²}`). The proofs lean on:

- `Finset.sum_congr rfl` — to replace each summand with an equal one, keeping the finite sum
  indexed by the same 6 units;
- `Finset.sum_neg_distrib` — to pull a minus sign out of a finite sum (this is the whole
  "backflow negates outflow" mechanism);
- `omega` — to close the component-wise integer arithmetic of `0 + u = u` and `u = 0`;
- `decide` / `fin_cases` — to exhaust the finitely many units;
- previously-proved lemmas `neighbors_card`, `wedge_antisymm`, `pod_card`,
  `units_rotate_invariant`, `pod_norm_le_one` from `HexIsotropy`, `Residual`, `Pod`, `Rotation`.

There is no analysis, no topology, no induction — it is all "the 6-element set has these
properties" checked by simplification.

## Step-by-step: `diamond_balance` (the conservation fact)

This is the most important theorem in the file, and it is worth walking through line by line.

The statement, read literally:

```
diamond_balance (w) (hskew : ∀ a b, w a b = - w b a) :
    flow w 0 + Σ_{u∈units} w u 0 = 0
```

Read it as: *"if the wedge is skew, then the total flow out of the center plus the total
backflow from the ring into the center is zero."*

The proof body:

1. **Unfold `flow`.** `flow w 0` becomes `Σ_{u∈units} w 0 (0 + u)` — the sum of the wedge
   along each directed edge pointing OUT of the center.

2. **Simplify `0 + u = u`.** A subgoal `hzero` rewrites `Σ w 0 (0+u)` to `Σ w 0 u`. This is
   done with `Finset.sum_congr rfl` (same index set) and, per term, `rcases u with ⟨ua, ub⟩`
   followed by `omega` to show the integer components add to themselves. This is pure
   bookkeeping — "the edge from 0 in direction u is just the edge to u."

3. **The skew hypothesis turns backflow into negative outflow.** A subgoal `hback` uses
   `Finset.sum_congr rfl` with `hskew u 0` to rewrite each `w u 0` (the ring pointing back
   at the center) as `- w 0 u`, then `Finset.sum_neg_distrib` to pull the sign out:

   ```
   Σ_{u∈units} w u 0  =  Σ_{u∈units} (- w 0 u)  =  - Σ_{u∈units} w 0 u
   ```

   This is the entire physical content: **the backflow is the negative of the outflow**,
   because each directed edge and its reverse carry opposite wedge values.

4. **`ring` closes it.** After the rewrites the goal is

   ```
   Σ w 0 u + (- Σ w 0 u) = 0
   ```

   which `ring` proves by integer cancellation.

The point: conservation is not *asserted* — it is *derived from skewness*. The single
hypothesis `hskew` (the wedge is antisymmetric) is what makes the pod balance. That is the
discrete statement of `Σ(O−E)=0`: the common cause (center) and common effects (ring) cancel
because every out-edge has an anti-parallel in-edge.

## Step-by-step: the other three (briefly)

- **`causal_isotropy`** is one line: `neighbors_card z`, itself proved in `HexIsotropy.lean`
  by `Finset.card_image_of_injective` (translation by a unit is injective) plus `units_card = 6`.
  The 6 neighbors are *distinct* precisely because `z + u = z` forces `u = 0`, and `0` is not a
  unit (`no_fixed_point`).

- **`causal_skew`** is one line: it *restates* `Lattice.wedge_antisymm` (from `Residual.lean`)
  specialized to `Eisenstein`. The residual module already proved the wedge `O(a,b) − O(b,a)`
  is skew for any type; this just instantiates it at the hex lattice.

- **`pod_is_causal_diamond`** proves two things at once: `pod.card = 7` (the closed radius-1
  ball has center + 6 ring cells) and `units.image (fun v => u * v) = units` (rotating the 6
  directions by any unit u permutes them). Both are finite checks (`pod_card`, `decide`);
  the second is the Z₆-invariance that makes "the diamond" a rotationally symmetric object.
  `causal_diamond_norm_le_one` then pins the diamond to *exactly* the cells of norm ≤ 1.

---

# 2. `FieldCalculus.lean` — TGRAD / TRECON and the Laplacian

## What it proves

The header says this file formalizes the field-calculus pair from `rtl/grad_recon.v`, closing
the gap flagged in `docs/riscv_survey/xlattice_encoding.md` §4/§7 — that the TRECON canonical
section was an *OURS convention*, not yet a theorem.

Definitions (at the origin, ring cells = the 6 Z₆ units ωᵏ in angle order):

```
div  = F0 − F2 − F3 + F5      (Re coefficients  +1, 0, −1, −1, 0, +1 — the scalar/source grade)
curl = F1 + F2 − F4 − F5      (Im coefficients   0,+1, +1,  0, −1, −1 — the bivector/skew grade)
```

where `F_k = f(ωᵏ)` and `ω⁰=(1,0), ω¹=(0,1), ω²=(−1,1), ω³=(−1,0), ω⁴=(0,−1), ω⁵=(1,−1)`.

| Theorem | Plain-English statement |
|---|---|
| `trecon_roundtrip` | **The canonical round-trip.** Placing the source `(a,b)` on the two positive-axis ring cells `ω⁰=(1,0)` and `ω¹=(0,1)` and measuring div/curl gives `a` and `b` back exactly: `div6 (trecon a b) = a` and `curl6 (trecon a b) = b`. |
| `tgrad_trecon_tgrad` | **The gauge-invariant round-trip.** For *any* field, `TGRAD(TRECON(TGRAD f)) = TGRAD f`. TRECON is a section of ∇⁻¹ that reproduces exactly the gauge-invariant part of `f`. |
| `div_curl_shift_invariant` | **The center is the additive gauge.** Adding a constant `c` to the whole field leaves div and curl unchanged — the discrete echo of `Σ(O−E)=0`. |
| `lap_constant` | **The Laplacian of a constant is 0.** The uniform field is the heat equation's steady state: the 6 neighbors average back to the center. |
| `lap_add` | **The Laplacian is linear:** `Lap(f + g) = Lap f + Lap g`. |

Definitions:

- `div6 f = f⟨1,0⟩ − f⟨−1,1⟩ − f⟨−1,0⟩ + f⟨1,−1⟩` — the Re-weighted 6-neighbor sum (scalar grade).
- `curl6 f = f⟨0,1⟩ + f⟨−1,1⟩ − f⟨0,−1⟩ − f⟨1,−1⟩` — the Im-weighted 6-neighbor sum (bivector grade).
- `tgrad6 f = (div6 f, curl6 f)` — TGRAD at the origin, split into `div ⊕ curl`.
- `trecon d c = fun x => if x = ⟨1,0⟩ then d else if x = ⟨0,1⟩ then c else 0` — TRECON, the
  canonical gauge-fixed section of ∇⁻¹: the source is placed on ω⁰ and ω¹, everything else 0.
- `lap f z = (Σ_{u∈units} f(z+u)) − 6·f z` — the 6-point hex Laplacian (`rtl/trelax.v`'s `Σ_nb − 6u`).
- `trelax f z = (f z)/3 + (Σ_{u∈units} f(z+u))/9` — one heat step (over ℚ so the ÷3/÷9 are exact).

## Why

This is the *engine's actual workload* in provable form. The field calculus `∇F = J` is the
statement that a field on the hex lattice splits into a **divergence part** (source/sink, the
scalar grade) and a **curl part** (rotation, the bivector grade). The RTL pair `TGRAD`/`TRECON`
is the hardware realization: `TGRAD` computes that 6→2 split, and `TRECON` is the *inverse* —
reconstructing a field from its (div, curl) pair.

The subtlety that makes this a *theorem* rather than a convention: `∇` is a linear map from a
**6**-dimensional space of ring values down to a **2**-dimensional space `(div, curl)`. So it
has a **4-dimensional nullspace** (fields that are "pure gauge" — they carry no div and no curl,
so ∇ annihilates them). That means `∇⁻¹` does not exist: many fields share the same (div, curl).
`TRECON` is a *choice* of one such inverse — the **canonical gauge** — which pins everything
onto the two positive axes ω⁰ and ω¹ and sets the other four ring cells to zero. What Lean
proves is that this choice works: it reproduces the gauge-invariant data exactly.

## The method

The strategy is exactly what the header claims: **finite arithmetic over the 6 ring cells.**
The center value drops out of div and curl entirely (`Σ ωᵏ = 0` — the additive gauge). The
proofs use:

- `unfold` + `simp` — for `trecon_roundtrip`: expanding `div6`, `curl6`, and `trecon` turns
  the goal into `a − 0 − 0 + 0 = a` and `c + 0 − 0 − 0 = c`, which `simp` discharges directly.
  The four "0" terms are exactly the four ring cells that `trecon` leaves empty.
- `rw` of a round-trip result — for `tgrad_trecon_tgrad`: it *reuses* `trecon_roundtrip`
  (with `a := div6 f`, `b := curl6 f`) rather than recomputing.
- `simp` + `ring_nf` — for `div_curl_shift_invariant`: expanding and normalizing shows the
  added `c` terms cancel pairwise (`+c −c −c +c` and `+c +c −c −c`).
- `simp [Finset.sum_const, units_card]` — for `lap_constant`: the sum of 6 copies of `c` is
  `6·c`, so `6·c − 6·c = 0`. It uses `units_card = 6` from `Rotation.lean`.
- `rw [Finset.sum_add_distrib]; ring` — for `lap_add`: distributivity of the finite sum over
  `f + g`, then integer cancellation.

## Step-by-step: `trecon_roundtrip` (the canonical round-trip)

Statement: `div6 (trecon a b) = a ∧ curl6 (trecon a b) = b`.

This is the **exact** round-trip in canonical gauge — `TRECON(TGRAD f) = f` *for a field
supported on ω⁰ and ω¹*. The proof is the shortest possible: `unfold div6 curl6 trecon; simp`.

To see *why* it is trivial but meaningful, expand by hand:

`trecon a b` is the field that equals `a` at `⟨1,0⟩`, `b` at `⟨0,1⟩`, and `0` at the other four
ring cells (and 0 at the center, though the center is never read).

Now `div6` reads four specific cells:

```
div6 (trecon a b) = (trecon a b)⟨1,0⟩ − (trecon a b)⟨−1,1⟩ − (trecon a b)⟨−1,0⟩ + (trecon a b)⟨1,−1⟩
                  = a − 0 − 0 + 0
                  = a
```

The value `a` sits *only* on `ω⁰ = (1,0)`, which appears in div6 with coefficient **+1**; the
other three cells div6 reads (`ω², ω³, ω⁵`) are the ones trecon left empty. Similarly:

```
curl6 (trecon a b) = (trecon a b)⟨0,1⟩ + (trecon a b)⟨−1,1⟩ − (trecon a b)⟨0,−1⟩ − (trecon a b)⟨1,−1⟩
                   = b + 0 − 0 − 0
                   = b
```

The value `b` sits only on `ω¹ = (0,1)`, which curl6 reads with coefficient **+1**.

So the theorem says: **the two coefficients of TGRAD are a pair of "read heads"**, and TRECON
is a pair of "write heads" placed on exactly the two cells those read heads look at with
coefficient +1. Because the write positions and the read positions are aligned (both on the
positive real and positive imaginary axes), writing `(a,b)` and reading back yields `(a,b)`.
The "canonical gauge" *is* that alignment choice. `simp` proves it because after unfolding it
is just `a − 0 − 0 + 0 = a` — the four zeros are the four untouched cells.

## Step-by-step: `tgrad_trecon_tgrad` (the gauge-invariant round-trip)

Statement: `tgrad6 (trecon (div6 f) (curl6 f)) = tgrad6 f`, for **any** field `f`.

This is the theorem that matters most, and it generalizes `trecon_roundtrip` from "a field
supported on ω⁰,ω¹" to *every* field. It says: take an arbitrary field, compute its div and
curl, feed those two numbers into TRECON (which builds the *canonical* field with that same
div and curl), and compute TGRAD again — you get back the original `(div6 f, curl6 f)`.

Read carefully: it does **not** claim `trecon (div6 f) (curl6 f) = f`. It cannot, because ∇
throws away the 4-dimensional nullspace (gauge). What it claims is the *right* statement — the
round-trip is exact on the **gauge-invariant part**:

```
TGRAD (TRECON (TGRAD f)) = TGRAD f
```

i.e. `TRECON ∘ TGRAD` is the identity *on the image of TGRAD*. This is exactly the comment in
the source: *"∇ is a 6→2 linear map with a 4-dimensional nullspace, so TRECON is defined only
up to gauge; the canonical section reproduces exactly the gauge-invariant part."*

The proof is one reuse of the previous theorem:

```
unfold tgrad6
have h := trecon_roundtrip (div6 f) (curl6 f)   -- h.1 : div6 (trecon (div6 f) (curl6 f)) = div6 f
                                                 -- h.2 : curl6 (trecon (div6 f) (curl6 f)) = curl6 f
rw [h.1, h.2]
```

Unfolding `tgrad6` turns the goal into a pair of equations `div6 (…) = div6 f ∧ curl6 (…) = curl6 f`,
and `trecon_roundtrip` *is* exactly those two equations (with `a = div6 f`, `b = curl6 f`).
So the round-trip for arbitrary fields is *definitionally the round-trip for canonical fields*,
instantiated at the field's own div and curl. That is the payoff: one short theorem reduces the
whole inverse-reconstruction problem to the single alignment fact from `trecon_roundtrip`.

## Step-by-step: `div_curl_shift_invariant` (the additive gauge)

Statement: `div6 (fun x => f x + c) = div6 f ∧ curl6 (fun x => f x + c) = curl6 f`.

This proves the "center drops out" claim from the header. Add a constant `c` to the entire
field and compute div:

```
div6 (f + c) = (f⟨1,0⟩ + c) − (f⟨−1,1⟩ + c) − (f⟨−1,0⟩ + c) + (f⟨1,−1⟩ + c)
             = div6 f + (c − c − c + c)
             = div6 f
```

The four `c` terms cancel because div6 has **two +1 and two −1 coefficients** — a balanced
telescope. Curl is the same shape (`+c +c −c −c = 0`). The proof is one line:
`constructor <;> (simp [div6, curl6]; ring_nf)` — the `ring_nf` normalization discovers the
cancellation automatically.

The physical meaning: a constant offset in the field is invisible to the derivative. This is
the additive gauge freedom — the 1-dimensional "DC" nullspace of ∇ — and it is the discrete
echo of the conservation law `Σ(O−E)=0` proved in `CausalLattice.diamond_balance` and
`Residual.sum_residual_eq_zero`: a uniform background carries no divergence and no curl.

## Step-by-step: `lap_constant` (the steady state)

Statement: `lap (fun _ => c) 0 = 0` — the Laplacian of a constant field is zero.

```
lap (constant c) 0 = (Σ_{u∈units} c) − 6·c = 6·c − 6·c = 0
```

The proof: `unfold lap; simp [Finset.sum_const, units_card]`. `Finset.sum_const` turns a sum of
6 identical values into `6 * c`, and `units_card` supplies the `6`. This is the "0 = steady
state" theorem: because the 6 neighbors average back to the center, a uniform field is already
at equilibrium — the heat equation `u' = u + Lap u/9` leaves it fixed (`u' = u`), which is the
relaxation property the `TRELAX` comment points to.

---

# How the two modules fit together (the round-trip in one breath)

`CausalLattice` gives the **geometry and the conservation**: the 6-fold isotropic grid, the
skew wedge, the balanced pod. `FieldCalculus` gives the **operator and its inverse** on that
grid: `TGRAD = div ⊕ curl` reads a field, `TRECON` writes it back in canonical gauge, and the
round-trip `TGRAD(TRECON(TGRAD f)) = TGRAD f` is exact on the gauge-invariant part. The one
number that ties them: **6** — the six units, the six neighbors, the six-point Laplacian, and
the six ring cells that TGRAD reads and TRECON (mostly) zeroes. The whole field calculus is
finite arithmetic over those six directions, and that is why every proof closes with `simp`,
`ring`, or `decide`.
