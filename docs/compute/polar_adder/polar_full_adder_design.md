# Polar ternary FULL adder — from half-adder + carry-in (unbalanced 0/1/2)

**2026-08-30 — the "do more for input carry" part of Ian's polar-ternary adder.**
Companion to `polar_half_adder_design.md` (the sibling file that documents the
half-adder). This file turns the 2-input half-adder into the 3-input full adder:
two half-adders + a one-gate carry merge.

**Digit convention (unbalanced ternary, NOT balanced):** each trit is a magnitude
`0 / 1 / 2` on a single polar wire (push = a level, null = 0, pull = the other
level). This is Ian's crossbar convention, not the balanced `{−1,0,+1}` 2-wire
encoding used elsewhere in `docs/compute/`.

**Half-adder spec (given):** `sum = (a + b) mod 3`, `carry = 1 iff a + b ≥ 3`.
Physical form: a 3×3 crossbar (9 intersections), OR-grouped by sum residue, with
`carry = two_two` — the OR of the three wrap intersections where `a + b ≥ 3`,
namely cells `(1,2)`, `(2,1)`, `(2,2)`.

---

## 1. The full-adder structure: two half-adders + one OR merge

The full adder adds three trits — two operands `a, b` and a carry-in `cin` — and
produces a sum trit and a carry-out bit:

```
total     = a + b + cin
sum       = total mod 3
carry_out = 1 iff total ≥ 3
```

The composition uses exactly the half-adder twice, with a single OR to merge the
two carries:

```
            a ──┐
                ├─► HALF1 (a,b) ──► s1 = (a+b) mod 3
            b ──┘            └────► c1 = 1 iff a+b ≥ 3

        s1 ──┐
             ├─► HALF2 (s1,cin) ──► sum  = (s1+cin) mod 3
      cin ──┘              └──────► c2 = 1 iff s1+cin ≥ 3

        carry_out = c1 OR c2
```

**Why this is correct** — the arithmetic is a two-step carry-save:

1. `HALF1` splits the pair sum into a residue and a carry: `a + b = 3·c1 + s1`
   (because `s1 = (a+b) mod 3` and `c1 = ⌊(a+b)/3⌋`).
2. `HALF2` splits the rest: `s1 + cin = 3·c2 + sum`.
3. Substituting: `total = 3·c1 + s1 + cin = 3·(c1 + c2) + sum`.

Since `0 ≤ sum ≤ 2`, step 3 says `sum = total mod 3` exactly, and the **true**
ternary carry is the integer `c1 + c2 ∈ {0,1,2}`. The merge `carry_out = c1 OR c2`
is the **binary** carry — "did we overflow 2?" — and it equals `⌊total/3⌋` **only
when the true carry is at most 1**. That is always the case on a real ripple
chain (see §5), so for every reachable input the OR is exact.

**Why `c1` and `c2` never both fire on a valid chain.** If `c1 = 1` then `a+b ≥ 3`,
so `s1 = (a+b) mod 3 ∈ {0,1}`; with `cin ≤ 1` we get `s1 + cin ≤ 2 < 3`, so
`c2 = 0`. Therefore `c1 OR c2 = c1 + c2` on every reachable row — the OR is
equivalent to an integer add here, not a lossy clamp (the one exception is the
unreachable `cin = 2` corner, §5).

---

## 2. The ripple-carry chain

An N-trit ripple adder chains N full-adders least-significant trit first:

```
  a0 b0 ─► FA0 ─► sum0 ──┐ cout0
  a1 b1 ─► FA1 ─► sum1 ◄─┘ cin1 = cout0
  a2 b2 ─► FA2 ─► sum2 ◄── cin2 = cout1
   ...         ...
  a(N-1) b(N-1) ─► FA(N-1) ─► sum(N-1) ◄── cin(N-1) = cout(N-2)
                                         └──► final carry_out
```

- `cin0` is the external carry-in (0 for a plain add).
- Each stage's `cout_i = c1_i OR c2_i` feeds the next stage's `cin_{i+1}`.
- Because every `cout_i ∈ {0,1}` (a binary bit), the next stage's carry-in is
  **always 0 or 1** — never 2. This is the invariant that keeps the OR merge exact
  and keeps half the full-adder's theoretical input space unreachable (see §5).

The chain is **ripple-carry**: `FA_i` cannot settle until `cin_i = cout_{i-1}`
has propagated. Critical path = N carry links. It is the ternary analogue of a
binary ripple adder — same topology, one carry wire per trit, but the carry is a
"wrapped past 2" flag rather than a "wrapped past 1" flag.

---

## 3. Device count, and how it scales with word width

Counting in the **crossbar primitive** (what the half-adder spec is built from):
a "device" is one crossbar **junction** (memristor/diode cell) or one **OR gate**
(input fan-in noted).

**Half-adder** (from the sibling spec):

| part | device | count |
|---|---|---|
| 3×3 crossbar | junction | **9** |
| OR-group by sum (residues 0, 1, 2) | 3-input OR | **3** |
| carry = OR of wrap cells `(1,2),(2,1),(2,2)` | 3-input OR | **1** |
| **half-adder total** | | **9 junctions + 4 ORs** |

**Full adder = 2 half-adders + carry merge:**

| part | device | count |
|---|---|---|
| HALF1 `(a,b)` | junctions + ORs | 9 + 4 |
| HALF2 `(s1,cin)` | junctions + ORs | 9 + 4 |
| carry merge `c1 OR c2` | 2-input OR | **1** |
| **full-adder total** | | **18 junctions + 9 ORs** |

**The doubling is exact on the junctions and near-exact on the ORs:**

| metric | half-adder | full-adder | ratio |
|---|---:|---:|---:|
| crossbar junctions | 9 | 18 | **2.00×** |
| OR gates | 4 | 9 | **2.25×** |
| primitive devices | 13 | 27 | **≈2.08×** |

The carry-in path costs a second, full 3×3 crossbar plus its OR grouping (the
`cin` operand needs its own 9 intersections against `s1`), and the only *extra*
logic beyond two half-adders is the single 2-input carry-merge OR. So a full
adder is **~2× the half-adder, plus one gate** — exactly as the task's honesty
clause requires.

**Word-width scaling (N-trit ripple adder):**

```
devices(N) = N × (18 junctions + 9 ORs)
            = 18N junctions + 9N ORs
```

The ripple itself adds **no logic devices** — the carry-out of stage `i` is a wire
to stage `i+1`'s `cin`. What it adds is **latency**: the carry propagates one
stage per link, so worst-case delay is `N` carry paths (vs the `O(1)` depth of a
carry-lookahead scheme, which would need extra "generate/propagate" OR logic per
stage and is not part of the ripple design). Latches/registers for a pipelined
adder are extra and not counted here.

**A ripple-specialization note (honesty):** in a ripple, `cin ∈ {0,1}` always, so
HALF2 only ever exercises 6 of its 9 intersections (the `cin = 2` row of its
crossbar is dead). A ripple-optimized full adder could drop that row to ~15
junctions per stage instead of 18, at the cost of no longer being a uniform,
reusable full-adder cell. The generic count above keeps all 9 for uniformity.

---

## 4. Complete truth table (27 rows)

`a, b, cin ∈ {0,1,2}`; `total = a + b + cin`; `sum = total mod 3`;
`carry = 1 iff total ≥ 3`. This is the reference table to check any ngspice
netlist against — sweep the three inputs over all 27 triples and assert `sum` and
`carry`.

| # | a | b | cin | total | sum | carry |
|---:|--:|--:|----:|------:|----:|:-----:|
| 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2 | 0 | 0 | 1 | 1 | 1 | 0 |
| 3 | 0 | 0 | 2 | 2 | 2 | 0 |
| 4 | 0 | 1 | 0 | 1 | 1 | 0 |
| 5 | 0 | 1 | 1 | 2 | 2 | 0 |
| 6 | 0 | 1 | 2 | 3 | 0 | 1 |
| 7 | 0 | 2 | 0 | 2 | 2 | 0 |
| 8 | 0 | 2 | 1 | 3 | 0 | 1 |
| 9 | 0 | 2 | 2 | 4 | 1 | 1 |
| 10 | 1 | 0 | 0 | 1 | 1 | 0 |
| 11 | 1 | 0 | 1 | 2 | 2 | 0 |
| 12 | 1 | 0 | 2 | 3 | 0 | 1 |
| 13 | 1 | 1 | 0 | 2 | 2 | 0 |
| 14 | 1 | 1 | 1 | 3 | 0 | 1 |
| 15 | 1 | 1 | 2 | 4 | 1 | 1 |
| 16 | 1 | 2 | 0 | 3 | 0 | 1 |
| 17 | 1 | 2 | 1 | 4 | 1 | 1 |
| 18 | 1 | 2 | 2 | 5 | 2 | 1 |
| 19 | 2 | 0 | 0 | 2 | 2 | 0 |
| 20 | 2 | 0 | 1 | 3 | 0 | 1 |
| 21 | 2 | 0 | 2 | 4 | 1 | 1 |
| 22 | 2 | 1 | 0 | 3 | 0 | 1 |
| 23 | 2 | 1 | 1 | 4 | 1 | 1 |
| 24 | 2 | 1 | 2 | 5 | 2 | 1 |
| 25 | 2 | 2 | 0 | 4 | 1 | 1 |
| 26 | 2 | 2 | 1 | 5 | 2 | 1 |
| 27 | 2 | 2 | 2 | 6 | 0 | 1 |

**Table summary (the invariants to spot-check):**

- `sum` is uniform: each residue `0`, `1`, `2` appears **9 times** (27 ÷ 3).
- `carry = 1` in **17 of 27 rows**; `carry = 0` in **10 rows**. The 10 no-carry
  rows are exactly the triples with `a + b + cin ≤ 2`.
- The 18 carry rows break down by `total`: `total=3` → 7 rows, `total=4` → 6 rows,
  `total=5` → 3 rows, `total=6` → 1 row.

---

## 5. Honesty: the carry-in path doubles the logic, and two caveats

**1. ~2× is real and structural.** A 3-input full adder is not "a slightly bigger
half-adder" — it is a second, complete 3×3 crossbar that adds the carry-in to the
partial sum, plus its own OR grouping, plus one merge OR. The junctions double
(9 → 18), the OR gates go 4 → 9, and total primitive devices go 13 → 27
(≈2.08×). There is no way around this with the half-adder as the only building
block; the ~2× is the price of the third input, exactly as the binary full adder
is ~2× a binary half-adder.

**2. The `cin = 2` rows are unreachable — but they're listed anyway (rows 3, 6,
9, 12, 15, 18, 21, 24, 27).** A real ripple chain feeds `cin ∈ {0,1}` only
(every stage's carry-out is a single 0/1 bit), so 9 of the 27 rows can never
occur in operation. The task asked for the full 3×3×3 = 27-row table so the
ngspice model can be swept exhaustively, and it is complete above — but the
simulator should be told that the `cin = 2` quadrant is a "don't happen" region,
not a specification.

**3. The one row where the binary carry *clamps*: `(a,b,cin) = (2,2,2)` (row
27).** Here `total = 6`, and a full ternary carry would be `⌊6/3⌋ = 2` — but this
design's carry is defined as the binary flag "1 iff total ≥ 3", and `c1 = 1`
(from `2+2 = 4`) plus `c2 = 1` (from `s1+cin = 1+2 = 3`) OR together to **1, not
2**. That is consistent with the stated convention (`carry ∈ {0,1}`) and is
harmless in a ripple (the row is unreachable), but it must be recorded: **this is
a binary-carry full adder, not a ternary-carry one.** If Ian wants a carry that
can be 2 (to ripple a full trit of carry), the merge `c1 OR c2` must become the
integer sum `c1 + c2` and HALF2 must be able to carry 2 — a larger, different
design.

**4. Honest caveat on the OR-gate transistor price.** The device count above is in
*crossbar primitives* (junction + OR gate), matching the half-adder spec's own
units. If the OR groups are realized in the repo's native polar CMOS, each OR is
not free: the measured polar gates (`docs/compute/polar_gates.md`) put MIN/MAX at
44 T each, and the 2-threshold receiver tax applies per OR input. That transistor
figure is the *implementation* cost layered on top of the junction count, and it
is not folded into §3's primitive count (which is the structural doubling the
task asked for). The ~2× doubling of §3 is in crossbar/primitives; the CMOS
transistor story would scale both half- and full-adder proportionally, so the
~2× ratio survives the translation.

---

## 6. Verification pointers (for the ngspice model)

- Sweep `a, b, cin` over `{0,1,2}³` and assert `sum = (a+b+cin) mod 3` and
  `carry = (a+b+cin ≥ 3)` against §4's table, row by row.
- Separately check the composition: measure `s1`, `c1` (HALF1), `s2`, `c2`
  (HALF2), then `carry_out = c1 OR c2` — the two half-adders must agree with the
  sibling `polar_half_adder_design.md` truth table at their internal nodes.
- Pay attention to the null level on the carry wire: `carry = 0` must drive a
  clean null (not a marginal mid-rail), or the next stage's `cin` will be misread
  as a `1` — the meta-stable-null hazard already measured in
  `docs/compute/polar_gates.md`.
- For the ripple, chain two stages and verify the 9 "carry propagates" cases
  (`a+b ≥ 3` in the low stage while the high stage adds the resulting `cin = 1`).

---

## 7. One-line summary

**The full adder = 2 half-adders + 1 carry-merge OR = 18 junctions + 9 ORs
(≈2.08× the 9-junction + 4-OR half-adder); it implements `sum = (a+b+cin) mod 3`
and the binary `carry = (a+b+cin ≥ 3)` over the full 27-row truth table (sum
uniform 9/9/9; carry 17-on / 10-off); an N-trit ripple adder is N such cells
(18N junctions + 9N ORs) with no extra ripple logic, only N carry wires of
latency — and the only honesty asterisks are that `cin = 2` is unreachable in a
ripple and that `(2,2,2)` clamps a would-be carry-2 to 1.**
