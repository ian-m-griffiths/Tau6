#!/usr/bin/env python3
"""tinyrv RV32I smoke test.

Hand-assembles a tiny RV32I program (no external assembler), loads it into a
tinyrv simulator, runs it, and asserts the register/memory results against
hand-computed expectations.

Run from the repo root:  venv/bin/python scripts/tinyrv_hello.py
"""

import struct

from tinyrv import sim

# ---------------------------------------------------------------------------
# Hand-assembled RV32I program (little-endian 32-bit instruction words).
# Encoding details per instruction:
#   R-type: funct7[31:25] rs2[24:20] rs1[19:15] funct3[14:12] rd[11:7] opcode[6:0]
#   I-type: imm[31:20]     rs1[19:15] funct3[14:12] rd[11:7] opcode[6:0]
#   S-type: imm[11:5]      rs2[24:20] rs1[19:15] funct3[14:12] imm[4:0] opcode[6:0]
#   U-type: imm[31:12]     rd[11:7]   opcode[6:0]
# ---------------------------------------------------------------------------
# address   instruction               effect
PROGRAM = [
    0x000012B7,  # 0x0000  lui   t0, 0x1      t0 = 0x00001000
    0x00000317,  # 0x0004  auipc t1, 0x0      t1 = pc + 0 = 0x4
    0x00A00513,  # 0x0008  addi  a0, x0, 10   a0 = 10
    0x01400593,  # 0x000c  addi  a1, x0, 20   a1 = 20
    0x00B50633,  # 0x0010  add   a2, a0, a1   a2 = 30
    0x40A586B3,  # 0x0014  sub   a3, a1, a0   a3 = 10
    0x02C2A023,  # 0x0018  sw    a2, 0x20(t0) mem[0x1020] = 30
    0x0202A703,  # 0x001c  lw    a4, 0x20(t0) a4 = 30
    0x02D2A223,  # 0x0020  sw    a3, 0x24(t0) mem[0x1024] = 10
    0x00000063,  # 0x0024  beq   x0, x0, 0    self-loop (halt)
]

BASE = 0x0000  # program / pc start address


def main() -> int:
    # Instantiate an RV32 simulator (default xlen is 64; we want RV32I).
    vm = sim(xlen=32)

    # Load raw instruction bytes into memory (little-endian) and set the PC.
    image = struct.pack(f"<{len(PROGRAM)}I", *PROGRAM)
    vm.copy_in(BASE, image)
    vm.pc = BASE

    # Run. `run` stops when pc equals the just-executed instruction's address,
    # i.e. our `beq x0,x0,0` self-loop at 0x24 halts it.
    vm.run(limit=100, trace=False)

    # Hand-computed expectations.
    expected = {
        "x5  (t0)": (vm.x[5], 0x1000),
        "x6  (t1)": (vm.x[6], 0x0004),
        "x10 (a0)": (vm.x[10], 10),
        "x11 (a1)": (vm.x[11], 20),
        "x12 (a2)": (vm.x[12], 30),
        "x13 (a3)": (vm.x[13], 10),
        "x14 (a4)": (vm.x[14], 30),
        "mem[0x1020]": (vm.load("I", 0x1020), 30),
        "mem[0x1024]": (vm.load("I", 0x1024), 10),
        "pc": (vm.pc, 0x24),
    }

    # Report.
    print("tinyrv RV32I smoke test")
    print("-" * 44)
    print(f"{'field':<12} {'actual':>12} {'expected':>12}  result")
    print("-" * 44)
    all_pass = True
    for name, (actual, want) in expected.items():
        ok = actual == want
        all_pass &= ok
        print(f"{name:<12} {actual:>#12x} {want:>#12x}  {'PASS' if ok else 'FAIL'}")
    print("-" * 44)
    print("RESULT:", "PASS" if all_pass else "FAIL")
    return 0 if all_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
