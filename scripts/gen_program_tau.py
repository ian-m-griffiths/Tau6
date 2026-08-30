#!/usr/bin/env python3
"""
gen_program_tau.py — assemble the Tau SoC field-calculus + transport test program
into rtl/program_tau.hex (the image rtl/tau_soc.v $readmemh's).

The program drives every ternary subsystem through its memory-mapped peripheral:
  * TGRAD   (0x2000)  : write field F0=+3 (cell 20), F1=+9 (cell 8), center=6;
                        read div (+3), curl (+9).
  * TRECON  (0x2114)  : gauge-fixed ∇⁻¹ store; read back F0'=+3, F1'=+9 (round trip).
  * TRELAX  (0x2118)  : one heat step; center cell 6 -> +1 (sum/9 = 12/9 = 1).
  * ternary link (0x3000): transmit an all-null word (12 nulls, 60 centi-pJ) and a
                        one-active word (0x010: 11 nulls, 1 active, 175 centi-pJ).

Field values are BALANCED TERNARY (2 bits/trit): enc(+3)=0x004, enc(+9)=0x010,
enc(+1)=0x001.  Addresses (center=6, cell indices) are plain binary — addressing is
the 3^n namespace, values are the ternary field.

Results are stored to data RAM for the testbench to assert:
  mem[0x20]=div  0x24=curl  0x28=F0'  0x2C=F1'  0x30=ofit  0x34=center'
  0x38=nulls1    0x3C=ener1  0x40=nulls2  0x44=ener2

Run: python3 scripts/gen_program_tau.py
"""
from __future__ import annotations


def enc(v: int) -> int:
    """6-trit balanced-ternary encoder (2 bits/trit, 01=+1, 00=0, 10=-1)."""
    r = v
    out = 0
    j = 0
    while j < 6:
        d = r % 3
        if d == 2:
            out |= 0b10 << (2 * j)
            r = (r + 1) // 3
        elif d == -2:
            out |= 0b01 << (2 * j)
            r = (r - 1) // 3
        else:
            if d == 1:
                out |= 0b01 << (2 * j)
            elif d == -1:
                out |= 0b10 << (2 * j)
            r = r // 3
        j += 1
    return out


def lui(rd: int, imm20: int) -> int:
    return (imm20 << 12) | (rd << 7) | 0x37


def addi(rd: int, rs1: int, imm12: int) -> int:
    imm12 &= 0xFFF
    return (imm12 << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x13


def sw(rs2: int, rs1: int, imm12: int) -> int:
    imm12 &= 0xFFF
    return (((imm12 >> 5) & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) \
        | (2 << 12) | ((imm12 & 0x1F) << 7) | 0x23


def lw(rd: int, rs1: int, imm12: int) -> int:
    imm12 &= 0xFFF
    return (imm12 << 20) | ((rs1 & 0x1F) << 15) | (2 << 12) | ((rd & 0x1F) << 7) | 0x03


def beq(rs1: int, rs2: int, imm13: int) -> int:
    imm13 &= 0x1FFF
    b = ((imm13 >> 12) & 1) << 31
    b |= ((imm13 >> 5) & 0x3F) << 25
    b |= (rs2 & 0x1F) << 20
    b |= (rs1 & 0x1F) << 15
    b |= (0 << 12)
    b |= ((imm13 >> 1) & 0xF) << 8
    b |= ((imm13 >> 11) & 1) << 7
    return b | 0x63


def main() -> None:
    p: list[int] = []
    # --- TGRAD: field on pod(6), F0=+3 (cell 20), F1=+9 (cell 8) ---
    p.append(lui(1, 2))             # x1 = 0x2000 (field accel base)
    p.append(addi(2, 0, enc(3)))    # x2 = enc(+3) = 0x004
    p.append(sw(2, 1, 0x50))        # cells[20] = +3
    p.append(addi(2, 0, enc(9)))    # x2 = enc(+9) = 0x010
    p.append(sw(2, 1, 0x20))        # cells[8]  = +9
    p.append(addi(2, 0, 6))         # x2 = 6 (center ADDRESS, plain int)
    p.append(sw(2, 1, 0x100))       # center = 6
    p.append(lw(3, 1, 0x104))       # x3 = div
    p.append(lw(4, 1, 0x108))       # x4 = curl
    p.append(sw(3, 0, 0x20))        # mem[0x20] = div
    p.append(sw(4, 0, 0x24))        # mem[0x24] = curl
    # --- TRECON: gauge-fixed reconstruction, round trip ---
    p.append(lw(5, 1, 0x10C))       # x5 = ofit
    p.append(sw(5, 0, 0x30))        # mem[0x30] = ofit
    p.append(sw(0, 1, 0x114))       # TRECON store (value ignored)
    p.append(lw(6, 1, 0x50))        # x6 = cells[20] = F0'
    p.append(lw(7, 1, 0x20))        # x7 = cells[8]  = F1'
    p.append(sw(6, 0, 0x28))        # mem[0x28] = F0'
    p.append(sw(7, 0, 0x2C))        # mem[0x2C] = F1'
    # --- TRELAX: one heat step on the center cell ---
    p.append(sw(0, 1, 0x118))       # TRELAX step (value ignored)
    p.append(lw(8, 1, 0x18))        # x8 = cells[6] = center'
    p.append(sw(8, 0, 0x34))        # mem[0x34] = center'
    # --- ternary link: transport accounting ---
    p.append(lui(9, 3))             # x9 = 0x3000 (link base)
    p.append(addi(10, 0, 0))        # word = 0x000000 (12 nulls)
    p.append(sw(10, 9, 0x00))       # transmit
    p.append(lw(11, 9, 0x04))       # nulls (12)
    p.append(lw(12, 9, 0x10))       # energy (60)
    p.append(sw(11, 0, 0x38))       # mem[0x38] = nulls1
    p.append(sw(12, 0, 0x3C))       # mem[0x3C] = energy1
    p.append(addi(10, 0, 16))       # word = 0x000010 (trit2=+1: 11 nulls, 1 active)
    p.append(sw(10, 9, 0x00))       # transmit
    p.append(lw(13, 9, 0x04))       # nulls (11)
    p.append(lw(14, 9, 0x10))       # energy (175)
    p.append(sw(13, 0, 0x40))       # mem[0x40] = nulls2
    p.append(sw(14, 0, 0x44))       # mem[0x44] = energy2
    p.append(beq(0, 0, 0))          # spin forever

    with open("rtl/program_tau.hex", "w") as f:
        for w in p:
            f.write(f"{w & 0xFFFFFFFF:08x}\n")
    print(f"wrote rtl/program_tau.hex ({len(p)} instructions)")
    for i, w in enumerate(p):
        print(f"  {i:2d}: {w & 0xFFFFFFFF:08x}")


if __name__ == "__main__":
    main()
