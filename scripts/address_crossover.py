#!/usr/bin/env python3
"""Address-space crossover curve: ternary (base-3) vs binary (base-2) symbol counts.

Pure-stdlib, exact integer arithmetic.  No floating point is used to *compute*
trits or bits; the only floats printed are display ratios and the reference
constant ``log2(3)`` (via the stdlib ``math`` module).

Definitions (the task's own formulas)
-------------------------------------
    trits(N) = ceil(log_3 N) = smallest k with 3^k >= N
     bits(N) = ceil(log_2 N) = smallest j with 2^j >= N

Both are exact here:
    bits(N)  = (N - 1).bit_length()                       # exact, no floats
    trits(N) = bisect_right(POW3, N - 1)                  # exact, precomputed 3^k

Calibration
-----------
DIRECT  -- the ceiling formulas and every integer power inequality printed below;
           they are recomputed exactly by this script and cross-checked against
           the checked Lean theorems in ``proofs/lean-src/hexagon/Hexagon/``.
DERIVED -- "first crossover N", "tie points", and every range below are the exact
           output of those formulas, not asserted in advance.

Note on the brief's "(answer: N=5)".  Under exact ceiling arithmetic the first N
with trits(N) < bits(N) is **N = 3** (1 trit < 2 bits).  N = 5 is the first N of
the *permanent* win region: every N >= 5 has trits < bits (N = 4 ties).  Both are
printed and labelled so the two cannot be conflated; the Lean "capacity crossover"
(n = 2 trits, 9 cells > 8 cells = 3 bits) is a third, distinct framing.
"""

from __future__ import annotations

import math
from bisect import bisect_right

MAX_N: int = 1 << 32  # the u32 box: 4,294,967,296


def _powers_of_three(upper: int) -> list[int]:
    """Return [3^0, 3^1, ..., 3^k] with 3^k being the first power > upper."""
    pows: list[int] = [1]
    p = 1
    while p <= upper:
        p *= 3
        pows.append(p)
    return pows


POW3: list[int] = _powers_of_three(MAX_N)  # [3^0 .. 3^21]; 3^21 = 10,460,353,203


def trits(n: int) -> int:
    """ceil(log_3 n) for n >= 1, exactly (integer ceiling via precomputed powers)."""
    if n < 1:
        raise ValueError("n must be >= 1")
    return bisect_right(POW3, n - 1)


def bits(n: int) -> int:
    """ceil(log_2 n) for n >= 1, exactly: (n-1).bit_length()."""
    if n < 1:
        raise ValueError("n must be >= 1")
    return (n - 1).bit_length()


def symbol_pair(n: int) -> tuple[int, int]:
    """(trits, bits) for n items, exact."""
    return trits(n), bits(n)


def ratio(n: int) -> float | None:
    """bits/trits for n items; None at n=1 (0/0)."""
    t, b = symbol_pair(n)
    if t == 0:
        return None
    return b / t


# --------------------------------------------------------------------------- #
# Full-range crossover structure (analytic; piecewise-constant functions)
# --------------------------------------------------------------------------- #

def crossover_ranges() -> tuple[list[tuple[int, int, int, int]], list[tuple[int, int, int, int]]]:
    """Partition [1, 2^32] into (lo, hi, trits, bits) cells by symbol count.

    Returns (win_ranges, tie_ranges).  A cell with trits < bits is a ternary WIN;
    trits == bits is a TIE; trits > bits should never occur (and is asserted empty).
    """
    max_trits = trits(MAX_N)
    max_bits = bits(MAX_N)
    wins: list[tuple[int, int, int, int]] = []
    ties: list[tuple[int, int, int, int]] = []
    loses: list[tuple[int, int, int, int]] = []

    for k in range(max_trits + 1):
        lo_k = 1 if k == 0 else 3 ** (k - 1) + 1
        hi_k = 3 ** k
        for j in range(max_bits + 1):
            lo_j = 1 if j == 0 else 2 ** (j - 1) + 1
            hi_j = 2 ** j
            lo = max(lo_k, lo_j)
            hi = min(hi_k, hi_j)
            if lo > hi:
                continue
            cell = (lo, hi, k, j)
            if k < j:
                wins.append(cell)
            elif k == j:
                ties.append(cell)
            else:
                loses.append(cell)

    assert not loses, f"ternary should never need more symbols than binary: {loses}"
    return wins, ties


def verify_coverage(wins: list[tuple[int, int, int, int]],
                    ties: list[tuple[int, int, int, int]]) -> None:
    """Assert the win+tie cells tile [1, MAX_N] exactly once each."""
    cells = sorted(wins + ties)
    total = 0
    prev_end = 0
    for lo, hi, _k, _j in cells:
        assert lo == prev_end + 1, f"gap or overlap at N={lo} (prev end {prev_end})"
        total += hi - lo + 1
        prev_end = hi
    assert total == MAX_N, f"coverage {total} != {MAX_N}"
    assert prev_end == MAX_N, f"top end {prev_end} != {MAX_N}"


def brute_force_check(limit: int) -> None:
    """Compare the analytic cells against a literal per-N scan over [1, limit]."""
    wins, ties = crossover_ranges()
    analytic: dict[int, tuple[int, int]] = {}
    for lo, hi, k, j in wins:
        for n in range(lo, min(hi, limit) + 1):
            analytic[n] = (k, j)
    for lo, hi, k, j in ties:
        for n in range(lo, min(hi, limit) + 1):
            analytic[n] = (k, j)
    for n in range(1, limit + 1):
        assert analytic[n] == symbol_pair(n), f"mismatch at N={n}"
    print(f"  brute-force cross-check over N = 1 .. {limit:,}: OK "
          f"({limit:,} points, analytic == per-N scan)")


# --------------------------------------------------------------------------- #
# Presentation helpers
# --------------------------------------------------------------------------- #

def fmt_range(lo: int, hi: int) -> str:
    if lo == hi:
        return f"{lo}"
    return f"{lo}..{hi}"


def fmt_ratio(b: int, t: int) -> str:
    if t == 0:
        return "—"
    return f"{b / t:.4f}"


def main() -> None:
    print("=" * 78)
    print("ADDRESS-SIZE CROSSOVER CURVE — ternary (base-3) vs binary (base-2)")
    print(f"domain: N = 1 .. 2^32 = {MAX_N:,}   (trits = ceil(log3 N), bits = ceil(log2 N))")
    print("=" * 78)

    # --- 1. exact per-N formulas (demonstrated on small N) ----------------- #
    print("\n[1] Exact symbol counts for small N (trits, bits, ratio = bits/trits):")
    print(f"    {'N':>4}  {'trits':>5}  {'bits':>5}  {'ratio':>7}   relation")
    for n in range(1, 17):
        t, b = symbol_pair(n)
        rel = "TIE" if t == b else ("WIN " if t < b else "LOSE")
        print(f"    {n:>4}  {t:>5}  {b:>5}  {fmt_ratio(b, t):>7}   {rel}")

    # --- 2. full-range crossover structure --------------------------------- #
    wins, ties = crossover_ranges()
    verify_coverage(wins, ties)

    tie_ns = sorted({lo for lo, _hi, _k, _j in ties})
    win_ns = sorted({lo for lo, _hi, _k, _j in wins})
    first_win = win_ns[0]
    # permanent win region: first N such that all N' >= N (to MAX_N) are wins
    largest_tie = max(hi for _lo, hi, _k, _j in ties)
    permanent_start = largest_tie + 1

    print("\n[2] Exact crossover points over the full range N = 1 .. 2^32:")
    print(f"    first N with trits < bits          : N = {first_win} "
          f"(1 trit addresses 3 items vs 2 bits)      [DERIVED, exact]")
    print(f"    first N of the PERMANENT win region : N = {permanent_start} "
          f"(every N >= {permanent_start} wins; N = {largest_tie} ties)  [DERIVED, exact]")
    print(f"    tie points (trits == bits)          : N = {tie_ns}")
    print(f"    lose points (trits >  bits)         : none (⌈log3 N⌉ <= ⌈log2 N⌉ always)")
    print()
    print("    Closed form of the whole curve:")
    print("        trits < bits  <=>  N = 3  OR  N >= 5")
    print("        trits = bits  <=>  N in {1, 2, 4}")
    print("        trits > bits  <=>  never")

    print("\n    Tie cells (exact):")
    for lo, hi, k, j in sorted(ties):
        print(f"        N = {fmt_range(lo, hi):>6}   trits={k}  bits={j}  (tie)")

    print("\n    First 20 win cells (exact ranges), trits < bits:")
    for idx, (lo, hi, k, j) in enumerate(sorted(wins)[:20], start=1):
        print(f"        {idx:>2}.  N = {fmt_range(lo, hi):>12}   "
              f"trits={k:>2}  bits={j:>2}   ratio={fmt_ratio(j, k)}")
    print(f"        …  ({len(wins)} win cells total; they tile N=3 and all N >= 5)")

    print("\n    Boundary arithmetic that drives the curve:")
    print("        tie at N=1:  2^0 = 1 = 3^0     (0 symbols each)")
    print("        tie at N=2:  2^1 = 2, 3^1 = 3   (both need 1 symbol)")
    print("        WIN at N=3:  3^1 = 3 >= 3, 2^1 = 2 < 3  -> 1 trit vs 2 bits")
    print("        tie at N=4:  3^2 = 9, 2^2 = 4   (both need 2 symbols)")
    print("        WIN at N=5:  3^2 = 9 >= 5, 2^2 = 4 < 5  -> 2 trits vs 3 bits")

    # --- 3. asymptotic ------------------------------------------------------ #
    print("\n[3] Asymptotic ratio (bits/trits -> log2(3) as N -> oo):")
    log2_3 = math.log2(3)
    print(f"    limit  log2(3) = {log2_3:.12f}  (irrational; display value only)")
    print(f"    because  ceil(log2 N) / ceil(log3 N) -> log2 N / (log2 N / log2 3) = log2(3)")
    print()
    print("    Convergence from above (N = 3^k):")
    print(f"        {'k (trits)':>10}  {'bits = ceil(k*log2 3)':>24}  {'ratio bits/trits':>18}")
    for k in [1, 2, 3, 4, 6, 9, 12, 16, 20, 21]:
        b = bits(3 ** k)
        print(f"        {k:>10}  {b:>24}  {b / k:>18.4f}")
    print()
    print("    Convergence from below (N = 2^j):")
    print(f"        {'j (bits)':>10}  {'trits = ceil(j*log3 2)':>26}  {'ratio bits/trits':>18}")
    for j in [1, 2, 4, 8, 12, 16, 24, 32]:
        t = trits(2 ** j)
        print(f"        {j:>10}  {t:>26}  {j / t:>18.4f}")

    # --- 4. structure-size table ------------------------------------------- #
    structures: list[tuple[str, int]] = [
        ("pod (hex ball r=1)", 7),
        ("hex disk r=2", 19),
        ("hex disk r=3", 37),
        ("field store (8x8)", 64),
        ("word (3^12)", 3 ** 12),
        ("u32 box (2^32)", 1 << 32),
    ]
    print("\n[4] Actual Tau structure sizes — trits, bits, ratio:")
    print(f"    {'structure':<22}  {'N':>12}  {'trits':>5}  {'bits':>5}  "
          f"{'ratio b/t':>10}  {'3^trits':>12}  {'2^bits':>12}  {'saving':>7}")
    for name, n in structures:
        t, b = symbol_pair(n)
        saving = (b - t) / b * 100
        print(f"    {name:<22}  {n:>12,}  {t:>5}  {b:>5}  "
              f"{fmt_ratio(b, t):>10}  {3 ** t:>12,}  {2 ** b:>12,}  {saving:>6.1f}%")

    print("\n    Fine grid around each structure size (N-2 .. N+2):")
    for name, n in structures:
        print(f"      {name:<22} N={n:,}:")
        for m in range(max(1, n - 2), n + 3):
            if m > MAX_N:
                break
            t, b = symbol_pair(m)
            print(f"          N = {m:>12,}  trits={t:>2}  bits={b:>2}  ratio={fmt_ratio(b, t)}")

    # --- 5. calibration ----------------------------------------------------- #
    print("\n[5] Calibration:")
    print("    DIRECT   — every trits/bits value and range is the exact output of")
    print("               integer ceiling arithmetic (no floats in the computation);")
    print("               cross-checked against a literal per-N scan over [1, 2^20].")
    print("    DERIVED  — the 'first crossover' and 'tie points' labels are derived")
    print("               from those formulas, not asserted.")
    print("    NOTE     — the brief's '(answer: N=5)' is the PERMANENT-win start; the")
    print("               literal first strict win is N=3.  The Lean capacity crossover")
    print("               (three_pow_gt_two_pow_succ: 2^(n+1) < 3^n for n >= 2) is the")
    print("               n=2-trit point (9 cells > 8 cells = 3 bits) — a third framing.")

    brute_force_check(1 << 20)
    print("\nDone.")


if __name__ == "__main__":
    main()
