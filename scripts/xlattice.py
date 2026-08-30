#!/usr/bin/env python3
"""
xlattice.py — the Xlattice custom-0 extension in tinyrv (Phase 2).

Subclasses tinyrv's `sim` and adds a `_custom0` handler that dispatches the 13
balanced-ternary / geometric-algebra ops defined in
docs/riscv_survey/xlattice_encoding.md (custom-0 = opcode 0x0B; funct3 = operand format,
funct7 = operation). The math is scripts/ternary_ops.py (mirror of the Lean + RTL); the
pod ops gather/scatter the 7-cell hex pod via scripts/hexaddr.py.

Word convention (spec §1): one Eisenstein word = one RV32 register, low 24 bits —
a = bits[11:0] (6 trits), b = bits[23:12] (6 trits), 2 bits/trit (01=+1, 00=0, 10=-1,
11=NEVER canary). WORD8 (TGRAD div/curl) = 8 trits/coeff = 16 bits each.

Honest note (spec §5): these are integer/geo ops; the ternary ALU is NOT where the win is.

Run:  venv/bin/python scripts/xlattice.py   (assembles + runs the GA program from cpu_ga_tb)
"""
from __future__ import annotations

from tinyrv import sim as SimBase
from ternary_ops import (tdot, twedge, tsymdot, tgrad, trecon,
                         emul, enorm, econj, erot, eadd, esub)
from hex_memory import ANGLE_UNITS

# ---- 2-bit/trit <-> balanced integer (mirrors TernaryCrt.val / cpu.v s2t6) ----
def _trit_value(t2: int) -> int:
    if t2 == 0b01:
        return 1
    if t2 == 0b10:
        return -1
    if t2 == 0b00:
        return 0
    raise ValueError("11=NEVER canary")  # forbidden state


def decode_field(bits: int, n_trits: int) -> int:
    """2-bit/trit field -> balanced integer (value = sum trit_i * 3^i)."""
    v = 0
    for i in range(n_trits):
        v += _trit_value((bits >> (2 * i)) & 0b11) * (3 ** i)
    return v


def encode_field(val: int, n_trits: int) -> int:
    """balanced integer -> 2-bit/trit field (low n trits; wraps if out of range)."""
    r = val
    bits = 0
    for i in range(n_trits):
        d = r % 3  # Python: non-negative residue 0/1/2
        if d == 2:          # -1
            bits |= 0b10 << (2 * i)
            r = (r + 1) // 3
        elif d == 1:        # +1
            bits |= 0b01 << (2 * i)
            r = (r - 1) // 3
        else:               # 0
            r //= 3
    return bits


def decode_word(x: int) -> tuple[int, int]:
    """RV32 register (24-bit word) -> (a, b) balanced integer pair."""
    return decode_field(x & 0xFFF, 6), decode_field((x >> 12) & 0xFFF, 6)


def encode_word(a: int, b: int) -> int:
    """(a, b) balanced integer pair -> 24-bit word (low 6 trits each)."""
    return encode_field(a, 6) | (encode_field(b, 6) << 12)


def fits6(v: int) -> bool:
    """6 balanced trits span [-364, 364] (the fit convention of cpu.v)."""
    return -364 <= v <= 364


class TauRiscv(SimBase):
    """tinyrv sim + the Xlattice custom-0 extension."""

    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.xlattice_ovf = False  # latched overflow / 11=NEVER canary flag
        self.hex_mem = {}          # cell (a,b) -> scalar word (the hex PMA region)
        self.hex_bits_moved = 0    # transport count for the hex cell store (7 x 32 bits/pod op)

    # -- register access in word (value) form ----------------------------------
    def _wa(self, r):
        return decode_word(self.x[r])[0]

    def _wb(self, r):
        return decode_word(self.x[r])[1]

    def _set_scalar(self, r, v):
        # scalar result -> a-field only, b cleared; latches ovf on out-of-range
        if not fits6(v):
            self.xlattice_ovf = True
        self.x[r] = encode_word(v, 0)

    def _set_word(self, r, a, b):
        if not (fits6(a) and fits6(b)):
            self.xlattice_ovf = True
        self.x[r] = encode_word(a, b)

    # -- pod gather/scatter (7 cells, angle order, over the hex cell store) -----
    # The hex MMU names cells by u32 (eisensteinToNat); the emulator stores them in a
    # cell-indexed store keyed by (a,b) — the hex PMA region is a distinct address space.
    # (The Szudzik-paired u32 addresses are NOT 4-byte-aligned, so they can't be tinyrv's
    # byte-addressed memory directly — the "not layout-preserving" caveat, hex_mmu.md §5.)
    def _pod_cells(self, center_cell):
        return [center_cell] + [(center_cell[0] + da, center_cell[1] + db)
                                for (da, db) in ANGLE_UNITS]

    def _gather_pod(self, center_cell):
        self.hex_bits_moved += 7 * 32
        return [self.hex_mem.get(c, 0) for c in self._pod_cells(center_cell)]

    def _scatter_pod(self, center_cell, values):
        self.hex_bits_moved += 7 * 32
        for c, v in zip(self._pod_cells(center_cell), values):
            self.hex_mem[c] = v

    # -- the custom-0 dispatcher ------------------------------------------------
    def _custom0(self, **_):
        ir = self.op.data
        f7 = (ir >> 25) & 0x7F
        rs2 = (ir >> 20) & 0x1F
        rs1 = (ir >> 15) & 0x1F
        f3 = (ir >> 12) & 0x7
        rd = (ir >> 7) & 0x1F

        def a(r): return self._wa(r)
        def b(r): return self._wb(r)
        def pair(r): return (a(r), b(r))

        if f3 == 0b000:  # R2: two Eisenstein operands
            z, w = pair(rs1), pair(rs2)
            if f7 == 0b0000000:   # TADD
                r = eadd(z, w)
            elif f7 == 0b0000001: # TSUB
                r = esub(z, w)
            elif f7 == 0b0000010: # TROT (rs2 low 3 bits = angle)
                r = erot(z, rs2 & 7)
            elif f7 == 0b0000011: # TMUL
                r = emul(z, w)
            elif f7 == 0b0000100: # TDOT -> a-field scalar
                self._set_scalar(rd, tdot(z, w)); self.pc += 4; return
            elif f7 == 0b0000101: # TWEDGE
                self._set_scalar(rd, twedge(z, w)); self.pc += 4; return
            elif f7 == 0b0000110: # TSYMDOT
                self._set_scalar(rd, tsymdot(z, w)); self.pc += 4; return
            else:
                return self.unimplemented()
            self._set_word(rd, r[0], r[1])
        elif f3 == 0b001:  # R1: one Eisenstein operand
            z = pair(rs1)
            if f7 == 0b0000000:   # TNORM -> a-field scalar
                self._set_scalar(rd, enorm(z))
            elif f7 == 0b0000001: # TCONJ
                self._set_word(rd, econj(z)[0], econj(z)[1])
            else:
                return self.unimplemented()
        elif f3 == 0b010:  # I: LDI rd, imm[11:0] (sign-extended -> balanced)
            imm = ir >> 20
            imm = imm | (~0xFFF if imm & 0x800 else 0)  # sign-extend 12-bit
            self._set_word(rd, imm, 0)
        elif f3 == 0b011:  # POD·rd: rd, rs1 = pod center cell (a,b) as a WORD6
            pod = self._gather_pod(decode_word(self.x[rs1]))
            if f7 == 0b0000000:   # TGRAD -> (div, curl) WORD8
                div, curl = tgrad((0, tuple(pod[1:])))
                self.x[rd] = encode_field(div, 8) | (encode_field(curl, 8) << 16)
            elif f7 == 0b0000001: # TRELAX -> u' (a-field scalar)
                u = pod[0]
                nb = pod[1:]
                # u' = u/3 + sum(nb)/9  (the alpha=2/3 heat step, trelax.v)
                self._set_scalar(rd, (u // 3) + (sum(nb) // 9))
            else:
                return self.unimplemented()
        elif f3 == 0b100:  # POD·wr: TRECON rd, rs1=J(WORD8), rs2=dest address
            j = self.x[rs1]
            div = decode_field(j & 0xFFFF, 8)
            curl = decode_field((j >> 16) & 0xFFFF, 8)
            rec = trecon(div, curl)  # (center, (F0..F5)) canonical section
            self._scatter_pod(decode_word(self.x[rs2]), [rec[0]] + list(rec[1]))
            self._set_scalar(rd, 0)  # status 0 = ok (ofit not yet modeled)
        else:
            return self.unimplemented()

        self.pc += 4


# ---- assembler helpers ---------------------------------------------------------
def _r(f7, f3, rd, rs1, rs2):
    return 0x0B | (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7)


def _i(imm, f3, rd, rs1):
    return 0x0B | ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7)


def LDI(rd, imm):
    return _i(imm, 0b010, rd, 0)


def TROT(rd, rs1, k):
    return _r(0b0000010, 0b000, rd, rs1, k)


def TADD(rd, rs1, rs2):
    return _r(0b0000000, 0b000, rd, rs1, rs2)


def TCONJ(rd, rs1):
    return _r(0b0000001, 0b001, rd, rs1, 0)


def TDOT(rd, rs1, rs2):
    return _r(0b0000100, 0b000, rd, rs1, rs2)


def TWEDGE(rd, rs1, rs2):
    return _r(0b0000101, 0b000, rd, rs1, rs2)


def TSYMDOT(rd, rs1, rs2):
    return _r(0b0000110, 0b000, rd, rs1, rs2)


def TGRAD(rd, rs1):
    return _r(0b0000000, 0b011, rd, rs1, 0)


def TRELAX(rd, rs1):
    return _r(0b0000001, 0b011, rd, rs1, 0)


def TRECON(rd, rs1, rs2):
    return _r(0b0000000, 0b100, rd, rs1, rs2)


def main():
    import struct
    # replicate cpu_ga_tb: z = 2+3w, w = 1-2w; TCONJ/TDOT/TWEDGE/TSYMDOT + identities
    prog = [
        LDI(1, 2), LDI(2, 3), TROT(2, 2, 1), TADD(1, 1, 2),     # r1 = (2,3) = z
        LDI(3, 1), LDI(4, -2), TROT(4, 4, 1), TADD(3, 3, 4),     # r3 = (1,-2) = w
        TCONJ(5, 1),                                              # r5 = (5,-3)
        TDOT(6, 1, 3), TWEDGE(7, 1, 3), TSYMDOT(8, 1, 3),        # -8, 7, -9
        TWEDGE(9, 3, 1),                                          # antisymm: -7
        TCONJ(5, 5),                                              # involution -> (2,3)
        TSYMDOT(8, 3, 1),                                         # symmetry -> -9
    ]
    vm = TauRiscv(xlen=32)
    vm.copy_in(0, struct.pack(f"<{len(prog)}I", *prog))
    vm.pc = 0
    vm.run(limit=len(prog), trace=False)

    def w(r): return decode_word(vm.x[r])
    checks = {
        "r1 = z = (2,3)":       w(1) == (2, 3),
        "r3 = w = (1,-2)":      w(3) == (1, -2),
        "TCONJ involutive = (2,3)": w(5) == (2, 3),
        "TDOT = -8":            w(6) == (-8, 0),
        "TWEDGE = 7":           w(7) == (7, 0),
        "TSYMDOT = -9":         w(8) == (-9, 0),
        "TWEDGE antisymm = -7": w(9) == (-7, 0),
    }
    allpass = True
    for name, ok in checks.items():
        allpass &= ok
        print(f"{'PASS' if ok else 'FAIL'}: {name}")
    # print register summary
    for r in (1, 3, 5, 6, 7, 8, 9):
        print(f"  x{r} = {w(r)}")
    print("RESULT:", "PASS" if allpass else "FAIL")
    return 0 if allpass else 1


if __name__ == "__main__":
    raise SystemExit(main())
