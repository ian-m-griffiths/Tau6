#!/usr/bin/env python3
"""
fairfight.py — the Phase 6 fair-fight: the whole Tau Architecture thesis in one table.

Each number is grounded in a verified artifact (not asserted):
  * address density  : TritPacking.lean (2^n < 3^n) + Bijection.lean + NAMESPACE_TABLE.md
  * transport        : FINAL_VERDICT.md + circuit/ENERGY_RESULTS.md (ngspice) + transport.py
  * compute          : ThresholdLowerBound.lean (2*ln2/ln3 ~= 1.26x) + FINAL_VERDICT.md

The one-line answer: ternary wins on NAMES (exponentially) and the WIRE (a small real
factor); it loses on the ALU (a bounded factor) — and the engine computes on addresses,
not bits, so the loss is irrelevant to the engine's actual workload.

Run:  python3 scripts/fairfight.py
"""
from __future__ import annotations
import math

LOG2_3 = math.log2(3.0)


def address_density(n: int) -> tuple[float, float, float]:
    """(3^n, 2^n, (3/2)^n) for n symbols."""
    return 3.0 ** n, 2.0 ** n, (3.0 / 2.0) ** n


def main() -> int:
    print("Tau Architecture — the fair fight (grounded numbers)")
    print("=" * 70)

    # ---- axis 1: the address space (the win) ---------------------------------
    print("\n[1] NAMESPACE — how many names n symbols distinguish   [PROVED, exponential]")
    print(f"    a trit = {LOG2_3:.4f} bits ;  n trits carry {LOG2_3:.4f}*n bits")
    print("    n symbols | 3^n (ternary) | 2^n (binary) | (3/2)^n")
    for n in (8, 16, 32, 48, 64):
        t, b, r = address_density(n)
        print(f"    {n:>9} | {t:>14.4e} | {b:>12.4e} | {r:.3e}")
    _, _, r64 = address_density(64)
    print(f"    at n=64: (3/2)^64 = {r64:.3e} names per binary name   (TritPacking.lean)")
    # the concrete operand: a 12-trit word vs a 12-bit word, same symbol count
    print(f"    a 12-trit word = 3^12 = {3**12:,} names ; a 12-bit word = 2^12 = {2**12:,}")
    print(f"      -> {3**12 / 2**12:.1f}x more names per symbol (36.9% fewer symbols to name the same space)")

    # ---- axis 2: transport (the win, conditional) -----------------------------
    print("\n[2] TRANSPORT — wire energy per bit   [MEASURED, ngspice; FINAL_VERDICT]")
    b_nat, b_low, t_champ = 0.512, 0.216, 0.081   # pJ/bit
    print(f"    binary natural single-ended : {b_nat} pJ/bit")
    print(f"    binary matched low-swing    : {b_low} pJ/bit")
    print(f"    ternary champion (null-hvy) : {t_champ} pJ/bit")
    print(f"    win = {b_nat / t_champ:.2f}x vs natural, {b_low / t_champ:.2f}x vs low-swing")
    print("    HONEST: radix-agnostic (low-swing is shared with binary); the free null")
    print("            saving is CONDITIONAL on null-heavy data (at uniform, ternary ~ties).")

    # ---- axis 3: compute (the honest loss) -------------------------------------
    print("\n[3] COMPUTE — the 2-threshold tax   [PROVED, ThresholdLowerBound.lean]")
    tax = 2 * math.log(2) / math.log(3)
    print(f"    (b-1)/ln b is minimized at b=2; ternary pays {tax:.3f}x/bit")
    print("    measured diode gate: 3.4-4.9x worse (FINAL_VERDICT); the ALU is NOT the win.")

    # ---- the verdict -----------------------------------------------------------
    print("\n" + "=" * 70)
    print("VERDICT (one sentence):")
    print("  ternary buys NAMES exponentially (proved), moves BITS cheaper by a small")
    print("  real factor (measured, radix-agnostic), and computes MORE EXPENSIVELY by")
    print("  a bounded factor no native device removes (measured + proved).")
    print("  The engine computes on ADDRESSES, not bits -> the compute loss is irrelevant")
    print("  to its workload; the wins (address space + wire) are exactly where it lives.")
    print("=" * 70)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
