#!/usr/bin/env python3
"""
plot_cost_curves.py — the HONEST cost-vs-address-size curve (the one the symbol-count
chart doesn't show).  A trit is fewer symbols but costs 2x to read (2 thresholds) and
2 bits to store (2-bit/trit code), so the read-cost ratio is 2*ceil(log3 N) / ceil(log2 N)
-> 2/log2(3) = 1.26x: a CONSTANT loss, flat across all address sizes.

Run: venv/bin/python scripts/plot_cost_curves.py
Output: docs/compute/address_space/cost_curves.png (+ .svg)
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


N = sorted(set(range(1, 17)) | {2**k for k in range(1, 33)} | {3**j for j in range(1, 22)})
x = [math.log2(n) for n in N]
binary_cost = [ilog2(n) for n in N]        # 1 read per bit
ternary_cost = [2 * ilog3(n) for n in N]   # 2 reads per trit (2 thresholds)
ratio = [t / b if b else 0.0 for t, b in zip(ternary_cost, binary_cost)]

fig, axs = plt.subplots(1, 2, figsize=(12.5, 4.4))
fig.suptitle("Addressing COST vs address size — the honest curve (read cost, not symbol count)",
             fontsize=13, fontweight="bold")

ax = axs[0]
ax.step(x, ternary_cost, where="post", color="#c0392b", lw=2.2, label="ternary: 2·⌈log₃N⌉ (2 thresholds/trit)")
ax.step(x, binary_cost, where="post", color="#3182bd", lw=2.2, label="binary: ⌈log₂N⌉ (1 threshold/bit)")
ax.set_xlabel("log₂(N)  (address size)")
ax.set_ylabel("read cost (discriminations)")
ax.set_title("Read cost", fontsize=11)
ax.grid(alpha=0.3)
ax.legend(loc="upper left", fontsize=8)

ax = axs[1]
ax.step(x, ratio, where="post", color="#c0392b", lw=1.8)
ax.axhline(2 / math.log2(3), color="#999", ls="--", lw=1.0, label="asymptote 2/log₂3 ≈ 1.262×")
ax.set_xlabel("log₂(N)")
ax.set_ylabel("ternary / binary cost")
ax.set_title("Cost ratio → 1.26× (ternary LOSES, flat)", fontsize=11)
ax.grid(alpha=0.3)
ax.legend(loc="upper right", fontsize=8)
ax.set_ylim(0.9, 1.6)

fig.text(0.5, 0.01,
         "ternary wins on SYMBOL COUNT (1.585× fewer) but LOSES on COST (2× read tax): "
         "the two cancel to a flat 1.26× loss that does NOT improve with larger address sizes.",
         ha="center", fontsize=9, color="#555")
fig.tight_layout(rect=[0, 0.04, 1, 0.94])

import os
os.makedirs("docs/compute/address_space", exist_ok=True)
fig.savefig("docs/compute/address_space/cost_curves.png", dpi=150)
fig.savefig("docs/compute/address_space/cost_curves.svg")
print("wrote docs/compute/address_space/cost_curves.png + .svg")
