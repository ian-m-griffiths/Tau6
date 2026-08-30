#!/usr/bin/env python3
"""
plot_address_curves.py — render the Tau address-space crossover curves with matplotlib.

Three panels:
  1. symbol count : ⌈log₃N⌉ trits vs ⌈log₂N⌉ bits, stepped, x = log₂(N)
  2. symbol ratio : bits/trits → log₂3 ≈ 1.585 as N → ∞
  3. namespace    : (3/2)ⁿ explosion (log-y), the "3ⁿ vs 2ⁿ" headroom

Outputs: docs/compute/address_space/crossover_curves.png (+ .svg)

Run: venv/bin/python scripts/plot_address_curves.py
"""
from __future__ import annotations
import math
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def ilog3(n: int) -> int:
    t = 0
    p = 1
    while p < n:
        p *= 3
        t += 1
    return t


def ilog2(n: int) -> int:
    return (n - 1).bit_length()


# ---- data ------------------------------------------------------------------
# panel 1: sample the staircase at every point where a ceiling changes (2^k, 3^j)
N1 = sorted(set(range(1, 17)) | {2**k for k in range(1, 33)} | {3**j for j in range(1, 22)})
x1 = [math.log2(N) for N in N1]
trits = [ilog3(N) for N in N1]
bits = [ilog2(N) for N in N1]

# panel 2: ratio at the same sample points
ratio = [b / t if t else 0.0 for b, t in zip(bits, trits)]

# panel 3: (3/2)^n
ns = list(range(0, 65))
headroom = [(3 / 2) ** n for n in ns]

# ---- figure ----------------------------------------------------------------
fig, axs = plt.subplots(1, 3, figsize=(15.5, 4.6))
fig.suptitle("Tau address-space crossover — trits vs bits", fontsize=14, fontweight="bold")

# panel 1: symbol count
ax = axs[0]
ax.step(x1, bits, where="post", color="#3182bd", lw=2.2, label="bits = ⌈log₂N⌉")
ax.step(x1, trits, where="post", color="#c05621", lw=2.2, label="trits = ⌈log₃N⌉")
ax.set_xlabel("log₂(N)  (address size)")
ax.set_ylabel("symbols")
ax.set_title("Symbol count", fontsize=11)
ax.grid(alpha=0.3)
ax.legend(loc="upper left", fontsize=8)
ax.annotate("first win N=3\n(ties at 1,2,4)", xy=(math.log2(3), 1),
            xytext=(6, 8), fontsize=8, color="#444",
            arrowprops=dict(arrowstyle="->", color="#444", lw=0.8))

# panel 2: ratio
ax = axs[1]
ax.step(x1, ratio, where="post", color="#2f855a", lw=1.6)
ax.axhline(math.log2(3), color="#999", ls="--", lw=1.0, label="asymptote log₂3 ≈ 1.585")
ax.set_xlabel("log₂(N)")
ax.set_ylabel("bits / trits")
ax.set_title("Symbol ratio → 1.585", fontsize=11)
ax.grid(alpha=0.3)
ax.legend(loc="lower right", fontsize=8)
ax.set_ylim(0.9, 1.8)

# panel 3: namespace headroom
ax = axs[2]
ax.semilogy(ns, headroom, color="#805ad5", lw=2.2)
for n, lab in [(2, "2.25×"), (6, "11.4×"), (12, "130×"), (21, "4,988×"), (32, "4.3×10⁵"), (64, "1.86×10¹¹")]:
    ax.annotate(f"n={n}\n{lab}", xy=(n, (3/2)**n), xytext=(n + 2, (3/2)**n * 0.6),
                fontsize=7.5, color="#5b3fa8",
                arrowprops=dict(arrowstyle="->", color="#5b3fa8", lw=0.6))
ax.set_xlabel("n  (symbols)")
ax.set_ylabel("(3/2)ⁿ  (log)")
ax.set_title("Namespace headroom", fontsize=11)
ax.grid(alpha=0.3, which="both")

fig.text(0.5, 0.01,
         "ternary never needs more symbols than binary; ratio → log₂3 ≈ 1.585 (≈37% fewer); "
         "namespace (3/2)ⁿ explodes.  Lean: three_pow_gt_two_pow_succ · namespace_outruns_linear_cost",
         ha="center", fontsize=9, color="#555")

fig.tight_layout(rect=[0, 0.03, 1, 0.95])

import os
os.makedirs("docs/compute/address_space", exist_ok=True)
fig.savefig("docs/compute/address_space/crossover_curves.png", dpi=150)
fig.savefig("docs/compute/address_space/crossover_curves.svg")
print("wrote docs/compute/address_space/crossover_curves.png + .svg")
