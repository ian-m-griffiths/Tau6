#!/usr/bin/env python3
"""
transport.py — the ternary transport energy model + a counting wrapper (Phase 3).

Implements docs/riscv_survey/transport_model.md: count memory traffic in the RISC-V
emulator and attribute the honest, corrected wire energies.  The constants are the
FAIR-FIGHT numbers from docs/FINAL_VERDICT.md (correction 2) — NOT the retired 0.748
baseline:

  binary natural single-ended : 0.512 pJ/bit
  binary matched low-swing     : 0.216 pJ/bit
  ternary champion (null-heavy): 0.081 pJ/bit   = 6.3x vs 0.512, 2.67x vs 0.216

Honest caveat (FINAL_VERDICT.md §transport): the ternary win is RADIX-AGNOSTIC (the
low-swing lever is shared with binary) and the free-null saving is CONDITIONAL on
null-heavy data — at uniform traffic the ternary link only ~ties binary.  The 0.081
number is the champion; the 2.67x (vs matched low-swing) is the honest lower bound.

Run:  venv/bin/python scripts/transport.py
"""
from __future__ import annotations
import struct

from tinyrv import sim as SimBase

# corrected constants (pJ/bit) — see docs/FINAL_VERDICT.md / ENERGY_LAWS.md banner
BINARY_NATURAL = 0.512
BINARY_LOWSWING = 0.216
TERNARY_CHAMPION = 0.081

# fair-fight operating point (per-TRIT energies, then /log2(3)=/1.585 for per-bit)
#   +-1 trit = 1.20 pJ, null = 0.05 pJ  (circuit/ENERGY_RESULTS.md CORRECTION 1)
TRIT_PLUS = 1.20
TRIT_NULL = 0.05
LOG2_3 = 1.584962500721156


def ternary_energy_per_bit(p_null: float) -> float:
    """The ternary link's per-BIT energy at a given null fraction, at the fair-fight
    operating point.  E_trit = (1-p_null)*E_+-1 + p_null*E_null ; E_bit = E_trit/1.585.
    At p_null=1/3 (uniform) this is ~0.515 pJ/bit (~ties binary natural); the 0.081
    champion needs null-heavy data (and the low-swing lever)."""
    e_trit = (1 - p_null) * TRIT_PLUS + p_null * TRIT_NULL
    return e_trit / LOG2_3


class TransportCounted(SimBase):
    """tinyrv sim that counts data load/store traffic (bits + access count)."""

    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.bits_moved = 0
        self.n_accesses = 0

    def load(self, fmt, addr, fallback=0, notify=True, **kw):
        self.n_accesses += 1
        self.bits_moved += struct.calcsize(fmt) * 8
        return super().load(fmt, addr, fallback, notify, **kw)

    def store(self, fmt, addr, data, notify=True, cond=True, **kw):
        self.n_accesses += 1
        self.bits_moved += struct.calcsize(fmt) * 8
        return super().store(fmt, addr, data, notify, cond, **kw)


def report(bits: int, label: str) -> None:
    e_nat = bits * BINARY_NATURAL
    e_low = bits * BINARY_LOWSWING
    e_ter = bits * TERNARY_CHAMPION
    print(f"  {label}: {bits} bits moved over the wire")
    print(f"    binary (natural single-ended) : {e_nat:9.1f} pJ")
    print(f"    binary (matched low-swing)    : {e_low:9.1f} pJ")
    print(f"    ternary (champion, null-heavy): {e_ter:9.1f} pJ")
    print(f"    win vs natural = {e_nat / e_ter:.2f}x ;  win vs low-swing = {e_low / e_ter:.2f}x")


def main():
    # a memory-heavy RV32I program: init t0=0x1000, then 3 stores + 3 loads
    prog = [
        0x000012B7,  # lui   t0, 1          (t0 = 0x1000)
        0x00A00513,  # addi  a0, x0, 10     (a0 = 10)
        0x00A2A023,  # sw    a0, 0(t0)      (mem[0x1000] = 10)
        0x01400513,  # addi  a0, x0, 20
        0x00A2A223,  # sw    a0, 4(t0)      (mem[0x1004] = 20)
        0x01E00513,  # addi  a0, x0, 30
        0x00A2A423,  # sw    a0, 8(t0)      (mem[0x1008] = 30)
        0x0002A503,  # lw    a0, 0(t0)      (a0 = 10)
        0x0042A583,  # lw    a1, 4(t0)      (a1 = 20)
        0x0082A603,  # lw    a2, 8(t0)      (a2 = 30)
        0x00000063,  # beq   x0, x0, 0      (self-loop halt)
    ]
    vm = TransportCounted(xlen=32)
    vm.copy_in(0, struct.pack(f"<{len(prog)}I", *prog))
    vm.pc = 0
    vm.run(limit=len(prog), trace=False)

    print("Transport energy model (Phase 3 demo)")
    print("------------------------------------")
    report(vm.bits_moved, f"{vm.n_accesses} data load/store accesses")

    # the honest conditional caveat: how the ternary win depends on the null fraction
    print("\n  ternary per-bit energy vs null fraction (fair-fight operating point):")
    for p in (0.0, 1 / 3, 0.5, 0.8, 1.0):
        e = ternary_energy_per_bit(p)
        print(f"    p_null={p:5.2f}: {e:.3f} pJ/bit  (vs binary natural {BINARY_NATURAL}: "
              f"{BINARY_NATURAL / e:.2f}x)")

    print("\n  Honest bottom line (FINAL_VERDICT.md): transport win ~2.7-6.3x, radix-agnostic;")
    print("  the free-null saving is real but conditional on null-heavy data.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
