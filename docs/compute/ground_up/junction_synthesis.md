# Junction-polarity ternary — synthesis of the 17-agent fan-out

**The idea (Ian):** a trit is two *anti-polar* channels (P/N) sharing a middle node — only
one channel is ever energized (push **or** pull **or** neither = null). Negation = swap the
rails (free). Because null = "nothing energized," the more null-heavy the data, the cheaper;
so weight each gate by channel-activation energy, search for the minimal-energy netlist, and
memoize fragments so "each path exists once" — a combinatorial compiler. "Compute on
addresses, not bits."

## 1. What was PROVED (Lean, `lake build` 8752 jobs, zero `sorry`)

| theorem | statement |
|---|---|
| `energy_le_one` / `energy_eq_zero_iff_null` | a trit energizes **at most one** channel; null = both off |
| `balancedEquiv` | the one-hot channel model ≃ balanced trit {−1,0,+1} |
| `neg_energy` / `neg_encodes_swap` | negation is a **zero-energy** rail swap |
| `sum_null` / `sum_push_pull` / `sum_assoc` | null is the additive identity; the channel sum is Z/3 |
| `ternary_wins_iff` | the transport win holds **iff** null fraction `p > (1−b·c)/(1−e) ≈ 0.338` |
| `expectedActive N p0 = N·(1−p0)` | expected energized channels; uniform = 2N/3 |
| `three_pow_gt_two_pow_succ` | **2ⁿ⁺¹ < 3ⁿ for n ≥ 2** — the address crossover at the base of the lower power |
| `namespace_outruns_linear_cost` | ∀C, ∃n, C·n < 3ⁿ — exponential info outruns linear overhead |
| `three_pow_div_two_pow` | 3ⁿ/2ⁿ = (3/2)ⁿ |

## 2. What was MEASURED (ngspice + tools)

- `tau_energy_search.py` — exact minimal-energy netlist synthesis; energy-pruning cuts the
  search 10²–4500×; it finds the *structural minimum* (⊕ irreducible, carry = consensus) but
  does **not** beat the sensing wall (the channel model alone makes ⊕ look like a false
  0.43× "win"; the real 1.42×/bit lives in the omitted 2-threshold receiver).
- `circuit_memo.py` — 1497× fragment dedupe, but it is **functional hashing**, not the
  causal lattice: `lattice-lookup` returns co-occurrence-residual neighbors, the wrong query
  for functional overlap.
- **break-before-make** — the "6.8× crowbar" is **NOT shoot-through**. It decomposes to
  25.4 fJ intrinsic + 343.3 fJ **static null-return leakage** (scales with *hold time*, not
  swing). Break-before-make is flat and costs 2.97–8.79 pJ overhead (net −100 to −300×).
  **This corrects `fair_binary.md` §4's mechanism.** The fix is a non-leaky null return.
- **pre-bias** — net LOSS: leakage paid 100% of the time, burns the saving in ~1 clock
  period, and it's ~8–13× slower (near-threshold = weak drive).
- **wire geometry** — the R-vs-C "optimum" is a *delay* optimum, not energy; energy is
  monotonic (minimum legal width wins); parallel rails are strictly worse; heterogeneity is
  not an energy win.

## 3. The three sub-claims, adjudicated

1. **"A trit never energizes both rails"** — TRUE in steady state (proved), with the caveat
   that the *transient* cost is leakage, not shoot-through.
2. **"Null-heavy is cheaper than binary"** — CONDITIONAL (transport only, `p > 0.338`), and
   the low-swing lever is radix-agnostic.
3. **"Ternary logic ≤ binary"** — FALSE. The channel-activation saving is static/transport;
   the **sensing tax** (2 thresholds vs 1) is physical: `⌈log₂3⌉ = 2` decisions per trit,
   1.26× proved floor → 2.54× receiver → 3.4–4.9× gate. No encoding, device, or physical
   primitive reads a trit in ≤1 decision. **"The 3rd state is free to *represent*, never
   free to *read*."**

## 4. The one genuine correction

The compute-loss decomposition was previously "swing² 7.8×, crowbar 6.8×, receiver 2.54×."
The "crowbar" term was **misattributed**: it is hold-time leakage of the passive null
return, fixable with a non-leaky null return — not a fundamental transient. The corrected
decomposition is: swing² (½CV², shared with binary) + null-return leakage (fixable) + the
2.54× sensing tax (irreducible).

## 5. Bottom line

Ian's junction idea is **sound and now fully formalized**: the one-hot push/pull/null
encoding is proved to give a free null, free negation, at-most-one-channel activation, and
an exponential namespace (3ⁿ overtakes 2ⁿ⁺¹ at n=2, then (3/2)ⁿ). But it does **not** turn
ternary compute into a win — the sensing tax is a coding fact (`3 ≠ 2^k`) wearing a device
costume. The wins stay exactly where the thesis always said: **addressing (exponential) and
transport (free null), not the read.**

The deliverable that *is* new and useful: a **correctly-priced combinatorial compiler** —
it finds the structural minimum of the logic (null-heavy data + fragment reuse) and reports
the sensing tax as an additive invariant it cannot touch, so the honest product is "a
correctly priced netlist, not a winning one."
