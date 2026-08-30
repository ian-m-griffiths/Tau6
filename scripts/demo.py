#!/usr/bin/env python3
"""
demo.py — the "run something useful" end-to-end demonstration of the Tau RISC-V.

A field-calculus workload runs on the hex-addressed memory as Xlattice custom-0
instructions: differentiate a scalar field on a 7-cell hex pod (TGRAD -> div/curl),
reconstruct it (TRECON), and relax it (TRELAX) — the engine's actual "∇F=J" work —
with the transport energy counted and the honest scoreboard printed.

This ties Phases 1-3 together: the hex MMU (hexaddr/hex_memory), the Xlattice
extension (xlattice), and the transport model (transport).

Run:  venv/bin/python scripts/demo.py
"""
from __future__ import annotations
import struct
import sys
sys.path.insert(0, 'scripts')

from xlattice import TauRiscv, TGRAD, TRECON, TRELAX, LDI, decode_word, encode_word, decode_field
from hex_memory import ANGLE_UNITS
from transport import BINARY_NATURAL, BINARY_LOWSWING, TERNARY_CHAMPION, TransportCounted


class TauRiscvCounted(TauRiscv, TransportCounted):
    """Xlattice + transport counting (MRO: TauRiscv._custom0, TransportCounted.load/store)."""
    pass


def word8(div: int, curl: int) -> int:
    """pack a (div, curl) WORD8 pair (8 trits each, 16 bits each)."""
    return encode_field(div, 8) | (encode_field(curl, 8) << 16)


def main() -> int:
    vm = TauRiscvCounted(xlen=32)

    # ---- build a scalar field on the hex pod centered at cell (0,0) ----------
    # canonical gauge: F0=+3 on cell (1,0), F1=+9 on cell (0,1); everything else 0.
    # so TGRAD must give div=F0=3, curl=F1=9 (center + F2..F5 drop out).
    vm.hex_mem[(1, 0)] = 3
    vm.hex_mem[(0, 1)] = 9

    # ---- TGRAD x10, x0  (x0=0 -> pod center = cell (0,0)) ---------------------
    prog = [TGRAD(10, 0)]
    vm.copy_in(0, struct.pack(f"<{len(prog)}I", *prog))
    vm.pc = 0
    vm.run(limit=len(prog), trace=False)

    j = vm.x[10]
    div = decode_field(j & 0xFFFF, 8)
    curl = decode_field((j >> 16) & 0xFFFF, 8)
    print("Tau RISC-V — field calculus on the hex pod")
    print("------------------------------------------")
    print(f"  TGRAD: field {{F0=+3, F1=+9, rest 0}} -> div={div}, curl={curl}")
    print(f"    {'PASS' if (div, curl) == (3, 9) else 'FAIL'} (expect div=3, curl=9 — matches grad_recon_tb)")

    # ---- TRECON: reconstruct the canonical section (round-trip) ---------------
    prog = [TRECON(11, 10, 0)]     # rd=11 status, rs1=x10=(div,curl), rs2=x0=cell(0,0)
    vm.copy_in(0, struct.pack(f"<{len(prog)}I", *prog))
    vm.pc = 0
    vm.run(limit=len(prog), trace=False)
    rec = (vm.hex_mem.get((1, 0), 0), vm.hex_mem.get((0, 1), 0))
    print(f"  TRECON: reconstructed canonical section on w^0,w^1 = {rec}")
    print(f"    {'PASS' if rec == (3, 9) else 'FAIL'} (TRECON(TGRAD F) = F in canonical gauge)")

    # ---- TRELAX: one heat step toward the uniform (steady) state ---------------
    prog = [TRELAX(12, 0)]         # rd=12, rs1=x0=cell(0,0)  (u=0 center, nb=3+9)
    vm.copy_in(0, struct.pack(f"<{len(prog)}I", *prog))
    vm.pc = 0
    vm.run(limit=len(prog), trace=False)
    u = decode_word(vm.x[12])[0]
    # u' = u/3 + sum(nb)/9 = 0 + (3+9)/9 = 12/9 = 1  (integer div)
    print(f"  TRELAX: u' = {u}")
    print(f"    {'PASS' if u == 1 else 'FAIL'} (u' = 0/3 + (3+9)/9 = 1)")

    # ---- transport energy (the Phase 3 model, on this workload) --------------
    bits = vm.hex_bits_moved   # the hex pod gather/scatter traffic (3 ops x 7 cells x 32b)
    print("------------------------------------------")
    print(f"  hex-memory traffic: {bits} bits (3 pod ops x 7 cells x 32 bits)")
    print(f"    binary (natural 0.512 pJ/bit) : {bits * BINARY_NATURAL:7.1f} pJ")
    print(f"    binary (low-swing 0.216)       : {bits * BINARY_LOWSWING:7.1f} pJ")
    print(f"    ternary (champion 0.081)       : {bits * TERNARY_CHAMPION:7.1f} pJ")
    print(f"    win vs natural = {BINARY_NATURAL / TERNARY_CHAMPION:.2f}x, "
          f"vs low-swing = {BINARY_LOWSWING / TERNARY_CHAMPION:.2f}x")

    # ---- the honest scoreboard ------------------------------------------------
    print("------------------------------------------")
    print("  Honest scoreboard (FINAL_VERDICT.md):")
    print("    namespace : 3^n vs 2^n  -> (3/2)^n = 1.86e11 at n=64  [proved, exponential]")
    print("    transport : ~2.7-6.3x win  (radix-agnostic; free null conditional)  [measured]")
    print("    compute   : ~1.26-3.5x/bit LOSS  (2-threshold tax)  [proved + measured]")
    print("    -> compute stays binary; the win is the address space and the wire.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
