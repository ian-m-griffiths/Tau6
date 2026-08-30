#!/usr/bin/env python3
"""
ternary_ops.py — the balanced-ternary / geometric-algebra ops (Python mirror of the
Lean proofs + RTL).

Ported 1:1 from:
  Conventions.lean  (Eisenstein add/mul/norm: w^2 = w - 1)
  Conjugate.lean    (conj(a,b) = (a+b, -b))
  DotWedge.lean     (dot = ac+ad+bd, wedge = bc-ad)
  SymDot.lean       (symdot = N(z+w)-N(z)-N(w) = 2ac+ad+bc+2bd)
  Gauge.lean        (rotate = w^k multiplication, the Z6 spinor)
  rtl/ga_ops.v      (the CPU's TCONJ/TDOT/TWEDGE/TSYMDOT)
  rtl/grad_recon.v  (TGRAD div/curl, TRECON canonical section)

These are the Xlattice custom-extension ops. Honest note carried over: these are
INTEGER/GEO ops — they are NOT where ternary wins (compute loses 1.26x/bit). They exist
to move the GA/field-calculus work next to the hex memory, not to speed arithmetic.

Run:  python3 scripts/ternary_ops.py    (runs the self-tests)
"""
from __future__ import annotations

# ---- Eisenstein integers (Conventions.lean) ----------------------------------
def eadd(z, w):
    return (z[0] + w[0], z[1] + w[1])


def eneg(z):
    return (-z[0], -z[1])


def esub(z, w):
    return (z[0] - w[0], z[1] - w[1])


def emul(z, w):
    """(a+bw)(c+dw) = (ac-bd) + (ad+bc+bd)w, since w^2 = w - 1."""
    a, b = z
    c, d = w
    return (a * c - b * d, a * d + b * c + b * d)


def enorm(z):
    """N(a+bw) = a^2 + ab + b^2 (Conventions.lean)."""
    a, b = z
    return a * a + a * b + b * b


def econj(z):
    """conj(a,b) = (a+b, -b)  (Conjugate.lean; w_bar = 1 - w)."""
    a, b = z
    return (a + b, -b)


# Z6 rotation (Gauge.lean units_eq_omega_powers): w^k * (a,b)
def erot(z, k):
    a, b = z
    k %= 6
    if k == 0:
        return (a, b)          # w^0 = 1
    if k == 1:
        return (-b, a + b)     # w^1 = w
    if k == 2:
        return (-(a + b), a)   # w^2 = w - 1
    if k == 3:
        return (-a, -b)        # w^3 = -1
    if k == 4:
        return (b, -(a + b))   # w^4 = -w
    return (a + b, -a)         # w^5 = 1 - w


# ---- the GA ops (ga_ops.v / DotWedge / SymDot) --------------------------------
def tdot(z, w):
    """dot(z,w) = (z * conj w).a = a*c + a*d + b*d  (raw, NOT symmetric)."""
    a, b = z
    c, d = w
    return a * c + a * d + b * d


def twedge(z, w):
    """wedge(z,w) = (z * conj w).b = b*c - a*d  (the skew / curl)."""
    a, b = z
    c, d = w
    return b * c - a * d


def tsymdot(z, w):
    """symdot(z,w) = N(z+w)-N(z)-N(w) = 2ac+ad+bc+2bd (the TRUE symmetric correlation)."""
    a, b = z
    c, d = w
    return 2 * a * c + a * d + b * c + 2 * b * d


# ---- field calculus (grad_recon.v) -------------------------------------------
# the 6 ring cells at w^k, k=0..5, in angle order
ANGLE_UNITS = ((1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1))


def tgrad(field):
    """TGRAD: field = (center, F0..F5); returns (div, curl).
    div  = F0 - F2 - F3 + F5   (Re / scalar / source)
    curl = F1 + F2 - F4 - F5   (Im / bivector / skew)
    The center drops out (sum w^k = 0): it is the additive gauge.
    """
    center, F = field
    F0, F1, F2, F3, F4, F5 = F
    div = F0 - F2 - F3 + F5
    curl = F1 + F2 - F4 - F5
    return (div, curl)


def trecon(div, curl):
    """TRECON: the canonical gauge-fixed section of grad^-1.
    F0'=div, F1'=curl, F2'=F3'=F4'=F5'=0, center'=0.  Exact integer round-trip in
    canonical gauge; up-to-gauge in general.
    """
    F = (div, curl, 0, 0, 0, 0)
    return (0, F)


# ---- self-tests (values from rtl/cpu_ga_tb.v + rtl/grad_recon_tb.v) ------------
def _check(name, cond):
    if not cond:
        raise AssertionError(f"FAIL: {name}")
    print(f"PASS: {name}")


def main():
    # conj(2+3w) = 5-3w
    _check("conj(2,3)=(5,-3)", econj((2, 3)) == (5, -3))
    # involution: conj(conj z) = z
    _check("conj involutive", econj(econj((2, 3))) == (2, 3))

    # dot / wedge / symdot for z=2+3w, w=1-2w  (cpu_ga_tb)
    z, w = (2, 3), (1, -2)
    _check("dot = -8", tdot(z, w) == -8)
    _check("wedge = 7", twedge(z, w) == 7)
    _check("symdot = -9", tsymdot(z, w) == -9)
    _check("wedge antisymm", twedge(w, z) == -twedge(z, w))
    _check("symdot comm", tsymdot(z, w) == tsymdot(w, z))

    # norm + mul (Eisenstein)
    _check("norm(2,3)=19", enorm((2, 3)) == 19)
    _check("(2+3w)(1-2w)=(8,-7)", emul(z, w) == (8, -7))
    _check("norm multiplicative", enorm(emul(z, w)) == enorm(z) * enorm(w))

    # TROT (Gauge.lean): w*(2+3w) = -3+5w
    _check("rot k=1 of (2,3) = (-3,5)", erot((2, 3), 1) == (-3, 5))
    _check("rot k=3 = negation", erot((2, 3), 3) == (-2, -3))
    _check("rot k=6 = identity", erot((2, 3), 6) == (2, 3))

    # TGRAD (grad_recon_tb): single ring cell at each unit
    for k, (div, curl) in enumerate([(1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)]):
        F = [0] * 6
        F[k] = 1
        _check(f"tgrad F{k}=1 -> ({div},{curl})", tgrad((0, tuple(F))) == (div, curl))
    # center drops out (gauge)
    _check("center is gauge", tgrad((27, (0, 0, 0, 0, 0, 0))) == (0, 0))
    # uniform field -> zero gradient
    _check("uniform -> 0", tgrad((0, (7, 7, 7, 7, 7, 7))) == (0, 0))

    # TRECON round-trip (canonical gauge)
    d, c = tgrad((0, (3, 9, 0, 0, 0, 0)))
    _check("trecon round-trip", trecon(d, c) == (0, (3, 9, 0, 0, 0, 0)))
    # gauge-invariant: tgrad(trecon(tgrad F)) == tgrad F
    field = (0, (3, -5, 2, 4, -1, 6))
    d, c = tgrad(field)
    _check("gauge-invariant round-trip", tgrad(trecon(d, c)) == (d, c))

    print("ALL PASSED — ternary_ops.py")


if __name__ == "__main__":
    main()
