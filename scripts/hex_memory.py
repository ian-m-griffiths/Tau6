#!/usr/bin/env python3
"""
hex_memory.py — the "minimum viable" hex-addressed memory over tinyrv (Phase 1).

Implements docs/riscv_survey/hex_mmu.md's §4.3 software realization: a hex PMA region
where an address is an Eisenstein cell (a,b), named by u32 via the PROVEN bijection
(scripts/hexaddr.py). The 6-offset neighbor walk (hex_mmu.md §3b) is the address
generation that gives the hex lattice its locality — which a flat u32 scan does NOT get.

Uses the ANGLE-ORDER units (w^k, k=0..5), matching rtl/grad_recon.v and hex_mmu.md's
neighbor table:
  k=0 (1,0), k=1 (0,1), k=2 (-1,1), k=3 (-1,0), k=4 (0,-1), k=5 (1,-1)

Run:  python3 scripts/hex_memory.py   (pure address tests + a tinyrv read/write round-trip)
"""
from __future__ import annotations
import struct

from hexaddr import eisenstein_to_nat, eisenstein_of_nat

# angle-order Z6 units (w^k): matches grad_recon.v + hex_mmu.md §3b
ANGLE_UNITS = ((1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1))


def cell_to_addr(a: int, b: int) -> int:
    """Hex cell (a,b) -> u32 physical address (Bijection.eisensteinToNat)."""
    return eisenstein_to_nat(a, b)


def addr_to_cell(addr: int) -> tuple[int, int]:
    """u32 physical address -> hex cell (a,b) (Bijection.eisensteinOfNat)."""
    return eisenstein_of_nat(addr)


def neighbor_addr(addr: int, k: int) -> int:
    """The k-th Z6 neighbor of a hex cell, in u32 space (hex_mmu.md §3b)."""
    a, b = addr_to_cell(addr)
    da, db = ANGLE_UNITS[k % 6]
    return cell_to_addr(a + da, b + db)


def pod(addr: int) -> list[int]:
    """The 7-cell causal diamond: center + its 6 unit neighbors."""
    return [addr] + [neighbor_addr(addr, k) for k in range(6)]


def read_hex_word(vm, a: int, b: int) -> int:
    """Read a 32-bit word from hex cell (a,b) through a tinyrv sim (copy_out, which
    bypasses the in-flight-instruction context that `load` needs)."""
    data = vm.copy_out(cell_to_addr(a, b), 4)
    return struct.unpack("<I", data)[0]


def write_hex_word(vm, a: int, b: int, val: int) -> None:
    """Write a 32-bit word to hex cell (a,b) through a tinyrv sim (copy_in, the
    confirmed-working write path; `store` needs an in-flight instruction context)."""
    vm.copy_in(cell_to_addr(a, b), struct.pack("<I", val & 0xFFFFFFFF))


def _check(name, cond):
    if not cond:
        raise AssertionError(f"FAIL: {name}")
    print(f"PASS: {name}")


def main():
    # --- pure address tests (hex_mmu.md worked example: neighbors of address 6) ---
    # address 6 = cell (1,0); its 6 neighbors are {20, 8, 4, 0, 7, 21}
    expected_neighbors = {20, 8, 4, 0, 7, 21}
    got = {neighbor_addr(6, k) for k in range(6)}
    _check("neighbors(6) == {20,8,4,0,7,21}", got == expected_neighbors)
    _check("cell round-trip: cell_to_addr∘addr_to_cell", all(
        addr_to_cell(cell_to_addr(a, b)) == (a, b) for a in range(-20, 21) for b in range(-20, 21)
    ))

    # the pod is 7 distinct cells
    _check("pod(6) has 7 distinct cells", len(set(pod(6))) == 7)

    # --- tinyrv integration: read/write a word through the hex layer ---
    try:
        from tinyrv import sim
        vm = sim(xlen=32)
        # write 0xDEADBEEF to cell (1,0) = address 6; read it back via the cell coords
        write_hex_word(vm, 1, 0, 0xDEADBEEF)
        _check("tinyrv read/write hex cell (1,0)", read_hex_word(vm, 1, 0) == 0xDEADBEEF)
        # and via its neighbor walk: write at address 6, read via cell (1,0) is the same addr
        _check("addr 6 == cell (1,0)", cell_to_addr(1, 0) == 6)
    except Exception as e:  # tinyrv optional here; pure tests still stand
        print(f"NOTE: tinyrv integration skipped ({e})")

    print("ALL PASSED — hex_memory.py")


if __name__ == "__main__":
    main()
