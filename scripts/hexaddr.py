#!/usr/bin/env python3
"""
hexaddr.py — the hex <-> u32 address bijection (Python mirror of the Lean proofs).

Ported 1:1 from proofs/lean-src/hexagon/Hexagon/Bijection.lean + AddressTranslation.lean
+ Rotation.lean (lake build green, zero sorry). Every function here corresponds to a
proved Lean theorem:

  signFold / signUnfold   <-> Bijection.signFold / signUnfold (round-trip proved)
  szudzik_pair / unpair   <-> Bijection.toNat  (Nat.pair = Szudzik)
  toNat / ofNat           <-> Bijection.toNat / ofNat  (bijection proved)
  eisensteinToNat/OfNat   <-> Bijection.eisensteinEquiv
  UNITS                   <-> Rotation.units  (the 6 Z6 units)
  angle_refines_parity    <-> AddressTranslation.angle_refines_parity

This is the building block for Phase 1 (hex-addressed memory in tinyrv): a hex address
is an Eisenstein cell (a, b), packed to a u32 by the Szudzik pairing; the Z6 angle
(mod 6) refines the binary parity (mod 2); the 6 unit offsets give the neighbor cells.

Run:  python3 scripts/hexaddr.py     (runs the self-tests)
"""
from __future__ import annotations
import math

# ---- the 6 Z6 units of Z[w] (Rotation.units) ---------------------------------
# (a, b) for 1, -1, w, -w, w^2=w-1, -w^2=1-w
UNITS: tuple[tuple[int, int], ...] = (
    (1, 0), (-1, 0), (0, 1), (0, -1), (-1, 1), (1, -1),
)

U32 = 1 << 32          # 2^32
U16 = 1 << 16          # 2^16
HALF = 1 << 15         # 2^15  (the coordinate box is [-2^15, 2^15-1])


def sign_fold(z: int) -> int:
    """Bijection.signFold: 0,1,-1,2,-2,... -> 0,1,2,3,4,..."""
    if z < 0:
        return 2 * abs(z) - 1
    return 2 * abs(z)


def sign_unfold(n: int) -> int:
    """Bijection.signUnfold: inverse of sign_fold."""
    if n % 2 == 0:
        return n // 2
    return -(n + 1) // 2


def szudzik_pair(a: int, b: int) -> int:
    """Bijection.toNat's pairing: Nat.pair (Szudzik), packs two u16 into one u32."""
    if a < b:
        return b * b + a
    return a * a + a + b


def szudzik_unpair(n: int) -> tuple[int, int]:
    """Inverse of szudzik_pair (Nat.unpair)."""
    s = math.isqrt(n)
    s2 = s * s
    if n < s2 + s:
        return (n - s2, s)
    return (s, n - s2 - s)


def to_nat(a: int, b: int) -> int:
    """Bijection.toNat (a,b) = pair (fold a) (fold b)."""
    return szudzik_pair(sign_fold(a), sign_fold(b))


def of_nat(n: int) -> tuple[int, int]:
    """Bijection.ofNat: inverse of to_nat."""
    x, y = szudzik_unpair(n)
    return (sign_unfold(x), sign_unfold(y))


def eisenstein_to_nat(a: int, b: int) -> int:
    """Bijection.eisensteinToNat: hex cell (a,b) -> natural/u32 address."""
    return to_nat(a, b)


def eisenstein_of_nat(n: int) -> tuple[int, int]:
    """Bijection.eisensteinOfNat: inverse."""
    return of_nat(n)


def angle(n: int) -> int:
    """The Z6 angle (AddressTranslation: address mod 6)."""
    return n % 6


def parity(n: int) -> int:
    """The XOR-kernel phase (address mod 2)."""
    return n % 2


def neighbor(cell: tuple[int, int], k: int) -> tuple[int, int]:
    """The k-th unit neighbor (CausalLattice: z + w^k)."""
    da, db = UNITS[k % 6]
    a, b = cell
    return (a + da, b + db)


def in_u32_box(a: int, b: int) -> bool:
    """Bijection.toNat_lt_two_pow_32: coordinates in [-2^15, 2^15-1] address < 2^32."""
    return (-HALF <= a <= HALF - 1) and (-HALF <= b <= HALF - 1)


# ---- self-tests ---------------------------------------------------------------
def _check(name: str, cond: bool) -> None:
    if not cond:
        raise AssertionError(f"FAIL: {name}")
    print(f"PASS: {name}")


def main() -> None:
    # signFold round-trip (Bijection: sign_unfold(sign_fold z) = z; sign_fold(sign_unfold n) = n)
    for z in range(-100, 101):
        _check(f"sign_unfold∘sign_fold({z})", sign_unfold(sign_fold(z)) == z)
    for n in range(0, 200):
        _check(f"sign_fold∘sign_unfold({n})", sign_fold(sign_unfold(n)) == n)

    # hex cell <-> address round-trip (Bijection round-trip, proved in Lean)
    for a in range(-40, 41):
        for b in range(-40, 41):
            n = eisenstein_to_nat(a, b)
            _check(f"of_nat∘to_nat({a},{b})", eisenstein_of_nat(n) == (a, b))

    # u32 bound: the box [-2^15, 2^15-1] addresses < 2^32 (Bijection.toNat_lt_two_pow_32)
    for a, b in ((-HALF, -HALF), (HALF - 1, HALF - 1), (0, 0), (HALF - 1, -HALF)):
        n = eisenstein_to_nat(a, b)
        _check(f"u32 box ({a},{b}) < 2^32", in_u32_box(a, b) and n < U32)

    # angle refines parity (AddressTranslation.angle_refines_parity)
    for n in range(0, 500):
        _check(f"parity({n}) == angle({n})%2", parity(n) == angle(n) % 2)

    # the 6 unit neighbors are distinct (HexIsotropy.neighbors_card)
    for a, b in ((0, 0), (5, -3), (100, 7)):
        nbrs = {neighbor((a, b), k) for k in range(6)}
        _check(f"6 distinct neighbors of ({a},{b})", len(nbrs) == 6)

    print("ALL PASSED — hexaddr.py")


if __name__ == "__main__":
    main()
