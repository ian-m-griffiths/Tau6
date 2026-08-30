# Junction Transport — the transport-side proofs, explained

This page explains four Lean modules in `proofs/lean-src/hexagon/Hexagon/`:

1. **`JunctionPolarity.lean`** — the *one-hot channel model* of a balanced trit.
2. **`JunctionEnergy.lean`** — the *normalized energy cost model* and the break-even null fraction.
3. **`JunctionMemory.lean`** — the *memory/energy bound* and the "information outruns activation cost" argument.
4. **`PolarTransport.lean`** — the *conversion-free* transport verdict.

They are the newest modules (this session) and they are the *transport* half of a two-sided
verdict: **ternary wins on transport, loses on compute** — and the transport win is **conditional**
(null-heavy data) **and conversion-free** (the wire already *is* binary).

Every theorem below is a real Lean statement, checked by `lake build` with **zero `sorry`**.
The headers of each file carry the provenance and calibration (all four are calibrated
**DIRECT** — finite combinatorics or ℚ algebra, no unproven physics imported).

---

## 1. JunctionPolarity.lean

### What it proves

A trit is modeled as `Trit := Option Channel`, where `Channel` is `push | pull`. So a trit is
either `none` (null — no channel driven) or `some push` / `some pull` (exactly one channel
driven). The main theorems:

| Theorem | Plain English |
|---|---|
| `encode_never_both` | No trit ever drives *both* wires: the code `(true, true)` = `11` is **never** produced. |
| `encode_null` / `null_iff_off` | Null is "both wires off" — and *only* null is both-wires-off (`encode t = 00 ⟺ t = null`). |
| `energy_le_one` | **At most one wire is ever on.** This is the "single-activation" invariant. |
| `energy_null` / `energy_push` / `energy_pull` | Null costs `0`; each active state costs `1`. |
| `energy_eq_zero_iff_null` | A trit costs zero energy **iff** it is null. |
| `balancedEquiv : Trit ≃ Hexagon.Trit` | The channel model is *exactly* the balanced trit `{push=+1, null=0, pull=−1}` (with both round-trips, plus injectivity and surjectivity). |
| `neg_neg` | Negation (swap push↔pull) is an involution. |
| `neg_encodes_swap` | Negation **is** a pure wire relabel: `encode (neg t) = (encode t).swap`. |
| `neg_energy` | **Negation is free** — it changes no activation energy. |
| `neg_toInt` / `neg_toEisenstein` | Negation is the balanced sign-flip (`−x`) on the integer and Eisenstein readings. |
| `sum_*` | The one-hot channel sum is balanced addition mod 3: `sum_push_pull` (opposites annihilate to null), `sum_push_push`/`sum_pull_pull` (balanced carry, +1+1 = −1), `sum_comm`, `sum_assoc`, `sum_neg`. It **is the group ℤ/3**. |

### Why

The "one-hot-per-direction" idea: a P-channel and an N-channel share a middle node, each
conducting only under its own polarity. If you record a trit as `Option Channel` instead of as
two independent booleans, then "at most one channel active" is **true by construction** — the
forbidden `(1,1)` state is *unrepresentable in the type*, not merely excluded by a side
condition. That is the cleanest possible statement of "ternary is cheap because you only ever
activate one channel." And because negation is just *which rail you drive*, flipping the sign
is a free relabeling, not a physical energy cost.

### The method

Pure finite case analysis. Because `Trit` has only three cases (`none`, `some push`,
`some pull`), almost every theorem closes with `cases t <;> decide` (or `rfl`). There is no
induction, no arithmetic library beyond `decide`/`norm_num` — the whole file is a statement
about three values. The one structural trick is *how the type is chosen*: `Option Channel`
has `2+1` inhabitants, so the bad `11` state cannot even be written down.

### Step-by-step (the important ones)

**`encode_never_both`.** The encoding is `push → 01`, `pull → 10`, `null → 00`. To prove no
trit maps to `11`, split on the three cases and `decide` each: `none` gives `(false,false)`,
`some push` gives `(true,false)`, `some pull` gives `(false,true)` — none equals
`(true,true)`. Three checks, done.

**`energy_le_one`.** Energy is the *count of energized wires* (`1` per `true` coordinate).
Again split on the three cases: each state has at most one `true`, so energy ≤ 1. Combined
with `energy_eq_zero_iff_null`, this says: **the cost of a trit is exactly "is it active?"** —
`0` for null, `1` for either polarity. That single fact is reused everywhere downstream
(JunctionEnergy's closed form, JunctionMemory's expectation, PolarTransport's "null is free").

**`balancedEquiv` and `sum_assoc`.** `toBalanced`/`ofBalanced` give a two-way round-trip
between the channel model and `{pos, zero, neg}`. The `sum` operation is then checked to be
commutative and associative by exhaustive case analysis over all `3×3×3 = 27` triples (spelled
out explicitly). Together with `sum_neg` (every trit has an additive inverse — its negation),
this certifies that the one-hot channel algebra *is* the cyclic group ℤ/3: carry is built in
(`+1 + +1 = −1 mod 3`).

**One-line significance** (from the file): a balanced trit costs only the *presence* of one
energized channel — never two — and its sign is a free rail swap.

---

## 2. JunctionEnergy.lean

### What it proves

The *normalized* cost model behind `scripts/transport.py`. Costs are **ratios**, not pJ: a ±1
trit (one channel energized) costs `1`; a null trit costs `e` with `0 ≤ e < 1` (measured
`e = 0.05/1.20 = 1/24`; ideal `e = 0`). Main theorems:

| Theorem | Plain English |
|---|---|
| `junctionCost_*` | The per-trit cost function: `pos=1`, `neg=1`, `zero=e`. |
| `junctionCost_null_lt` | Null costs strictly less than a ±1 iff `e < 1`. |
| `wordEnergy_eq` | A 12-trit word with `n` nulls costs exactly `12 − n·(1−e)`: energy is **linear in the null count**, slope `−(1−e)`. |
| `junctionCost_negate` / `junctionCost_relabel` / `wordEnergy_negateWord` | Polarity is energy-free: negation, and *any* null-fixing relabel (the ℤ₂ group `{id, negate}`), changes no energy. |
| `three_pow_12_lt_two_pow_20` | `3¹² < 2²⁰`: a 12-trit word (3¹² values) fits in **20** bits. |
| `two_pow_19_lt_three_pow_12` | `2¹⁹ < 3¹²`: **19** bits do *not* suffice — so 20 bits is the minimal binary width. |
| `three_pow_17_lt_two_pow_27` | `3¹⁷ < 2²⁷`, i.e. `log₂ 3 < 27/17` — the tight upper bound on bits-per-trit. |
| `structural_win` | Null-heavy direction (a): if `nullCount > 2/(1−e)` (null fraction `> 1/(6(1−e))`), the word's energy is **strictly below** a 20-bit binary word's ideal energy. |
| `structural_win_free_null` | With a **free** null (`e=0`), **≥ 3 nulls** (null fraction ≥ 1/4) beats the 20-bit binary word. |
| `structural_win_measured_null` | With the **measured** null (`e=1/24`), **≥ 3 nulls** still beats it. |
| `ternary_wins_iff` | **The exact break-even.** For any `e < 1`, `c > 0`: ternary per-bit energy `< b` ⟺ `p > (1 − b·c)/(1 − e)`. |
| `breakEven_above_uniform` | With measured `b = 32/75`, `e = 1/24`, `c = log₂3 < 27/17`: the break-even null fraction is **strictly above 1/3**. |
| `at_uniform_not_cheaper` | At uniform traffic (`p = 1/3`) ternary per-bit is **strictly above** binary natural — **no win at uniform**. |
| `uniform_tie_gap` | The uniform-traffic excess over binary is `< 1/100` of a channel energization (≈ 0.003 pJ/bit, under 1%) — the honest "≈ ties". |
| `win_at_null_half` | At `p = 1/2` (genuinely null-heavy) ternary per-bit is **strictly below** binary natural. |
| `transport_saving_does_not_erase_compute` | The null-fraction saving touches **only** the transport term: the total-cost saving between two null fractions equals the transport saving exactly (the compute term is additive and null-invariant). |

### Why

This is the **honest caveat** attached to the transport thesis. The champion measurement
(0.081 pJ/bit vs 0.512 binary natural) is real, but the free-null saving is **conditional on
null-heavy data**. The file pins down exactly *how* conditional: the win is a two-sided
statement `ternary_wins_iff` whose threshold is `(1 − b·c)/(1 − e) ≈ 0.338`. At uniform traffic
(nulls = 1/3, i.e. one in three trits is null) the threshold has not been crossed, so ternary
only **≈ ties** binary (0.6% worse). The `transport_saving_does_not_erase_compute` theorem
is the boundary marker: whatever ternary loses on compute (the 2-threshold sensing cost, proved
≈ 1.26× worse in `ThresholdLowerBound.lean`) is *orthogonal* to what it wins on transport.

### The method

Staying in **ℚ** (the rationals). The only non-rational ingredient — `log₂ 3`, which is
irrational — is never computed; it is carried as a **hypothesis** on a parameter `c`, pinned by
the *exact integer facts* `2¹⁹ < 3¹²` (so `19/12 < c`) and `3¹⁷ < 2²⁷` (so `c < 27/17`). The
algebra is then `norm_num`/`nlinarith`/`ring`/`field_simp` throughout: word energy is a linear
form, and the break-even is a two-inequality `nlinarith` chase.

### Step-by-step (the important ones)

**`wordEnergy_eq` (the closed form).** Each trit's cost is `1 − (1−e)·[t = null]` (the null
indicator). Summing over 12 positions: `Σ 1 = 12` minus `(1−e)` times the *count* of nulls.
So `wordEnergy e w = 12 − nullCount·(1−e)`. The proof rewrites the sum pointwise, pulls the
constant `12` and the factor `(1−e)` out (`Finset.sum_sub_distrib`, `Finset.mul_sum`), and
converts the indicator sum into a cardinality (`Finset.sum_boole`). This single linear form is
the backbone of every downstream inequality.

**`ternary_wins_iff` (the break-even algebra).** Ternary per-bit energy at null fraction `p`
is `((1−p) + p·e)/c` (fraction `p` null trits costing `e`, fraction `1−p` active costing `1`,
divided by the `c` bits per trit). Set this `< b` and solve for `p`:

```
((1−p) + p·e)/c < b
⟺  (1−p) + p·e < b·c          (c > 0, so division by c is order-preserving)
⟺  1 − b·c < p·(1−e)          (collect p-terms; e < 1 so 1−e > 0)
⟺  p > (1 − b·c)/(1−e)
```

Each step is a `div_lt_iff₀` (safe because denominators are positive) or `nlinarith`. The proof
is literally this chain in both directions — hence the `iff`.

**`breakEven_above_uniform` + `at_uniform_not_cheaper`.** Plug the measured values
`b = 32/75`, `e = 1/24` into the threshold: `(1 − b·c)/(1 − e)`. To show this exceeds `1/3`
*without* knowing `c` exactly, the file uses the hypothesis `c < 27/17` (from `3¹⁷ < 2²⁷`).
`breakEven_above_uniform` clears denominators and reduces to `nlinarith` on `23/72` vs `1 − b·c`;
`at_uniform_not_cheaper` does the mirror-image computation at `p = 1/3` (per-trit energy
`49/72`) and gets a strict `>`. The pair brackets the truth: **no win at 1/3, a strict win at
1/2** (`win_at_null_half`).

---

## 3. JunctionMemory.lean

### What it proves

Turns "we only energise half the RAM at once" into the memory-word setting: an `N`-trit word is
a sequence of one-hot channel states, active channels = non-null trits, information = `3ⁿ`
states = `N·log₂3` bits. Main theorems:

| Theorem | Plain English |
|---|---|
| `ternaryWord_card` | An `N`-trit word has exactly `3^N` distinct values. |
| `bitsOfWord_eq_log` / `bitsOfWord_gt_N` | The bit count is `log₂(3^N)`, which is **> N** bits (a trit carries more than one bit). |
| `activeChannels_le` | A word of `N` trits energizes **at most `N`** channels (each trit ≤ 1). |
| `word_never_both` | No trit in the word ever drives both wires (the `11` exclusion, per-position). |
| `tritProb_sum` | The iid null-fraction model (`p0` null, `(1−p0)/2` each polarity) is a genuine probability distribution. |
| `expectedActive_eq` | **Expected active channels = `N·(1 − p0)`.** |
| `expectedActive_lt_N` | Any positive null fraction (`p0 > 0`) ⇒ strictly fewer than `N` channels on average. |
| `expectedActive_anti_mono` | More nulls ⇒ fewer expected active channels. |
| `uniform_expectedActive` | At `p0 = 1/3`: expected active channels = **`2N/3`** (two-thirds lit, one-third free). |
| `champion_vs_lowswing` / `champion_vs_natural` / `transport_range` | The champion (0.081 pJ/bit) beats low-swing binary (0.216) by `8/3 ≈ 2.67×` and natural binary (0.512) by `512/81 ≈ 6.32×` — the "2.7–6.3× transport number". |
| `two_trit_break_even` | Fair-fight: 2 trits beat 3 binary-natural bits iff `p0 > 216/575 ≈ 0.376` (conservative; the true per-bit break-even is lower, `≈ 0.34`). |
| `ternary_more_states_per_rail` / `ternary_binary_rail_ratio` | Per rail, ternary gives `(3/2)^N` times the binary state count. |
| `binary_needs_more_bits` | `N` bits (`2^N` states) **cannot** hold the `3^N` states of an `N`-trit word. |
| `three_pow_gt_sq` | `3ⁿ > n²` for `n ≥ 1`: the ternary state count outruns any quadratic in the digit count. |
| `namespace_outruns_linear_cost` | **For every overhead rate `C` there is a word size `n` with `C·n < 3ⁿ`** — the exponential address space outruns linear per-read cost. |
| `three_pow_gt_two_pow_succ` | `2^(n+1) < 3^n` for all `n ≥ 2`: two-or-more trits address more cells than *one more* bit. |
| `three_pow_lt_two_pow_succ_one` | At `n = 1` it has *not* overtaken yet (`3¹ < 2²`), so the crossover is **exactly n = 2**. |

### Why

Two distinct claims are separated honestly. (1) **The energy claim**: if each trit energizes at
most one channel, an `N`-trit word energizes `≤ N` channels worst-case and `N·(1−p0)` in
expectation — for uniform traffic that's `2N/3`, i.e. "one-third of the rails are free." (2)
**The information claim**: the `3ⁿ` namespace is *exponential* in `n`, so it outruns any linear
(or even quadratic) activation/read overhead — the "compute on addresses, not bits" intuition.
The file is scrupulous that (1) is a *rail* count, not yet an energy bound; the fair *energy*
comparison is the measured 2.7–6.3× transport number, which is **conditional** on
`p0 > 216/575`.

### The method

Finite combinatorics plus **linearity of expectation over ℚ**. The one real induction is
`sum_prod_sum_linear`: the expectation `Σ_w (∏ a(wᵢ))·(Σ b(wᵢ))` factors over an iid product
distribution into `N·(Σ a·b)·(Σ a)^(N−1)`, proved by peeling off trit position 0 via the
coordinate equivalence `wordSuccEquiv` and the `Fin.prod_univ_succ`/`Fin.sum_univ_succ` lemmas.
`three_pow_gt_sq` uses strong induction on `n`; `three_pow_gt_two_pow_succ` uses
`Nat.le_induction` from `n = 2`.

### Step-by-step (the important ones)

**`expectedActive_eq` (linearity of expectation).** The expected number of active channels is
`Σ_w wordProb p0 w · (Σᵢ energy(wᵢ))`. Because `wordProb` is a product of iid per-trit
weights, `sum_prod_sum_linear` turns this into `N · (Σₜ tritProb p0 t · energy t) · (Σₜ
tritProb p0 t)^(N−1)`. The inner single-trit expectation is `(1−p0)` (the `neg` and `pos` terms
contribute `(1−p0)/2 · 1` each, the `zero` term contributes `p0 · 0`), and the total mass
`Σ tritProb p0 t = 1` — so the whole thing collapses to `N·(1−p0)`. No simulation: the
expectation is computed in closed form.

**`namespace_outruns_linear_cost`.** The address space is `3ⁿ` (exponential in the digit
count); the read/activation overhead is `C·n` (linear). To show the exponential always wins,
first prove `three_pow_gt_sq` (`3ⁿ > n²`): base cases `n = 1, 2` by `norm_num`, then strong
induction using `(n+2)² ≤ 9n²` (true for `n ≥ 1`) and `9·3ⁿ = 3ⁿ⁺²`. Then for any `C`, take
`n = C` (or `n = 0` if `C = 0`): since `n ≥ 1`, `n² < 3ⁿ`, and `C·n = n² ≤ n² < 3ⁿ`. The
information grows faster than the overhead cost.

**`three_pow_gt_two_pow_succ` (the n = 2 crossover).** Claim: `2^(n+1) < 3^n` for all `n ≥ 2`.
Base `n = 2`: `2³ = 8 < 9 = 3²`. Step: `2^(n+2) = 2·2^(n+1) < 2·3ⁿ < 3·3ⁿ = 3^(n+1)` (using
the induction hypothesis and `3ⁿ > 0`). The companion `three_pow_lt_two_pow_succ_one`
(`3¹ = 3 < 4 = 2²`) shows the crossover is *exactly* at `n = 2`, not `n = 1`. This is why
"ternary only starts paying for its extra address space from 2 trits up."

---

## 4. PolarTransport.lean

### What it proves

The **conversion-free** transport claim, formalized. Polar ternary has exactly three states on
two wires (`01` push, `00` null, `10` pull); the fourth combination `11` can never happen. Main
theorems:

| Theorem | Plain English |
|---|---|
| `polarEncode_null/push/pull` | The three codes, by name: `00`, `01`, `10`. |
| `encodeWord_injective` | Pointwise polar encoding of a whole word is **injective**: two distinct ternary words become two distinct binary words — transport loses nothing. |
| `encodeWord_never_eleven` | No transported cell is ever `(1,1)` — the `11` state is unreachable. |
| `polarEncode_image` | **The image is exactly `{00, 01, 10}`**: the transport uses only 3 of the 4 two-bit patterns. |
| `wordEnergyJ_eq_nonNullCount` | **Null is free**: a word's transport energy equals its number of non-null trits. |
| `wordEnergy_zero_eq` | The balanced-trit form: at `e = 0`, a 12-trit word costs `12 − nullCount`. |
| `conversion_free_transport_win` | Null-heavy (`≥ 3` nulls) beats the 20-bit binary word carrying the same information — with **zero** conversion overhead. |
| `conversion_free_transport_win_measured` | The same at the measured null cost `e = 1/24`. |
| `ternaryPerBit_antitone` | `ternaryPerBit` is antitone in the null fraction: more nulls ⇒ less energy per bit. |
| `five_nulls_beat_binary_natural_perbit` | The `ternary_wins_iff` break-even (`≈ 0.338`) is below `5/12 ≈ 0.417`, so **5 nulls in 12** transports strictly cheaper *per bit* than measured binary natural. |
| `five_nulls_word_win` | Whole-word form: a 12-trit word with **≥ 5 nulls** beats the measured binary-natural word carrying the same `12·c` bits. |
| `ternary_no_worse_same_wires` | On the same 24 wires, a free-null ternary word never energizes more than the ideal 24-bit binary word (`≤ 12`). |
| `beats_binary_same_wires` | Any null at all makes it strictly cheaper than ideal 24-bit binary on the same wires. |
| `two_nulls_beat_24bit_binary_word` | At measured null cost vs measured binary natural on the same 24 wires, just **2 nulls** suffice. |

### Why

The principal's insight, made precise: because `polarEncode` maps a trit straight onto the
two-bit bus width **with no translation table, no isqrt, no decode at the transport/storage
layer**, "transport in ternary" *is* "transport a binary word." The encoding already *is*
binary, so the null-heavy saving is won **with zero conversion overhead**. And `00 = null =
nothing energized = free`, so the null state is free on the wire. The one honest boundary is
stated up front: the **ALU still pays** the one-hot → signed decode at the compute boundary
(`polarDecode`); the claim proved here is that the *wire* carries the 2-bit code with no
conversion overhead and the null is free on the wire.

### The method

Reuse, not re-derive. This module imports the injectivity/no-`11` facts from
`PolarEncoding.lean` (`polarEncode_injective`, `polarEncode_never_eleven`), the single-activation
and free-negation facts from `JunctionPolarity.lean`, and the whole energy machinery
(`wordEnergy_eq`, `ternary_wins_iff`, the measured constants) from `JunctionEnergy.lean`. Its
own new proofs are finite combinatorics (`fin_cases`) for the image, and ℚ algebra
(`nlinarith`/`norm_num`) for the per-bit and same-wires comparisons.

### Step-by-step (the important ones)

**`polarEncode_image` (conversion-free, precisely).** The claim is a two-way `iff`:
`(∃ t, polarEncode t = c) ↔ c = 00 ∨ c = 01 ∨ c = 10`. Forward: take any `t` with
`polarEncode t = c`, split `t` into its three cases (`fin_cases t`) and read off which of the
three codes it must be. Backward: each of the three codes is realized by the corresponding trit
(`1 ↦ 00`, `2 ↦ 01`, `0 ↦ 10`). The `11` pattern is simply absent from the list — which is the
whole point: the ternary word occupies a **proper subset** of binary word space, with a
don't-care state it never uses.

**`encodeWord_injective` + `encodeWord_never_eleven`.** Lifting `polarEncode` pointwise over
an `N`-trit word: injectivity is inherited coordinate-by-coordinate (two words equal after
encoding must agree at every position, by `polarEncode_injective`), and the no-`11` exclusion is
inherited at every position. Together they certify: **a ternary word on the bus is literally a
binary word** (injective, never using `11`), so transport needs no decode step.

**`five_nulls_beat_binary_natural_perbit` (the ≈ 0.338 break-even ⇒ k = 5).** The
`ternary_wins_iff` break-even null fraction is `(1 − b·c)/(1 − e) ≈ 0.338`, which sits below
`5/12 ≈ 0.417`. So with 5 nulls in a 12-trit word (null fraction `5/12`), the per-bit ternary
energy is strictly below the binary natural baseline `32/75`. The proof instantiates
`ternary_wins_iff` at `p = 5/12`, then clears denominators and reduces to `nlinarith` with the
rational bound `19/12 < c` (from `2¹⁹ < 3¹²`). The companion `five_nulls_word_win` turns this
per-bit statement into the whole-word statement `wordEnergy nullEnergy w < binaryNatural·(12·c)`.

**One-line significance** (from the file): the ternary transport wire carries the 2-bit polar
code with no translation (it already *is* binary), excludes `11` everywhere, and its null state
costs zero — so null-heavy ternary transport is cheaper than binary **and** conversion-free,
with the ALU decode confined to the compute boundary, never the wire.

---

## The verdict, in one paragraph

Across the four modules the session's conclusion is stated with full honesty. Ternary **wins on
transport**: a trit costs exactly one channel (never two — `energy_le_one`), its sign is a free
rail swap (`neg_energy`), the expected number of energized rails is `N·(1−p0)` — `2N/3` at
uniform traffic — and the encoding *is* binary (`polarEncode_image`, `encodeWord_injective`),
so the null-heavy saving is **conversion-free**. But the transport win is **conditional**:
`ternary_wins_iff` shows it exists only past a null fraction of `(1 − b·c)/(1 − e) ≈ 0.338`,
strictly above the uniform `1/3` — at uniform traffic ternary merely ≈ ties binary. And the
transport win does **not** erase the compute loss: `transport_saving_does_not_erase_compute`
keeps the two axes orthogonal, while `ThresholdLowerBound.lean` (`ternary_worse_than_binary`)
shows ternary compute pays ≈ 1.26× more per bit on the 2-threshold sensing cost. **Ternary
wins on transport, loses on compute; the transport win is conditional and conversion-free.**
