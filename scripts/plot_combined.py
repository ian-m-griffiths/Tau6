#!/usr/bin/env python3
"""
plot_combined.py — the combined overlapping chart: one curve per Tau operation,
y = ternary's relative cost advantage = 1 − (ternary/binary), as word width n grows.
POSITIVE = ternary wins, NEGATIVE = binary wins, 0 = tie.

Run: venv/bin/python scripts/plot_combined.py
Output: docs/compute/address_space/combined_advantage.png (+ .svg)
"""
from __future__ import annotations
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# per-op: (reads, writes, compute=lambda n -> (ternary, binary)), and category
#  loss = binary wins, tie, win = ternary wins
ops = [
    ("TADD",    2, 1, lambda n: (1.92*n, 1.00*n), "loss"),
    ("TSUB",    2, 1, lambda n: (1.92*n, 1.00*n + 1.00*n), "loss"),
    ("TROT",    1, 1, lambda n: (0.0, 0.0), "loss"),
    ("TNORM",   1, 1, lambda n: (1.72*n*n, 1.00*n*n), "loss"),
    ("LDI",     0, 1, lambda n: (0.0, 0.0), "loss"),
    ("TMUL",    2, 1, lambda n: (1.72*n**1.585, 1.00*n**1.585), "loss"),
    ("TCONJ",   1, 1, lambda n: (1.92*n, 1.00*n + 1.00*n), "loss"),
    ("TDOT",    2, 1, lambda n: (1.72*n*n, 1.00*n*n), "loss"),
    ("TWEDGE",  2, 1, lambda n: (1.72*n*n, 1.00*n*n), "loss"),
    ("TSYMDOT", 2, 1, lambda n: (1.72*n*n, 1.00*n*n), "loss"),
    ("HLT",     0, 0, lambda n: (0.0, 0.0), "tie"),
    ("TGRAD",   7, 1, lambda n: (1.92*6*n, 1.00*6*n), "loss"),
    ("TRECON",  2, 7, lambda n: (0.0, 0.0), "loss"),
    ("TRELAX",  7, 1, lambda n: (1.92*6*n, 1.00*6*n + 2.5*n), "loss"),
    ("hex_encode",   0, 0, lambda n: (1.0*n*n, 1.0*n*n), "tie"),
    ("hex_decode",   0, 0, lambda n: (1.0*n*n, 1.0*n*n), "tie"),
    ("hex_neighbor", 0, 0, lambda n: (2.0*n, 3.0*n), "win"),
    ("hex_pod_addr", 0, 0, lambda n: (1.0*n*n + 12.0*n, 1.0*n*n + 18.0*n), "win"),
    ("ternary_link", 0, 0, lambda n: (0.394*n, 0.512*n), "win"),
]

ns = list(range(4, 33))
COL = {"loss": "#c0392b", "tie": "#95a5a6", "win": "#27ae60"}

fig, ax = plt.subplots(figsize=(12, 6.5))
for name, r, w, comp, cat in ops:
    adv = []
    for n in ns:
        tc = (r + w) * 2 * n + comp(n)[0]
        bc = (r + w) * 1 * n + comp(n)[1]
        adv.append(0.0 if bc == 0 else (1 - tc / bc) * 100)   # %: >0 ternary wins, <0 binary wins
    lw = 2.4 if cat == "win" else 1.1
    alpha = 1.0 if cat in ("win", "tie") else 0.45
    ls = "--" if cat == "tie" else "-"
    ax.plot(ns, adv, color=COL[cat], lw=lw, alpha=alpha, ls=ls, label=name if cat in ("win", "tie") else None)

ax.axhline(0, color="#333", lw=1.0)
ax.set_xlabel("word width n  (trits / bits)")
ax.set_ylabel("ternary relative advantage  (1 − ternary/binary, %)")
ax.set_title("Per-operation ternary cost advantage vs word width\n"
             "POSITIVE = ternary wins · NEGATIVE = binary wins · flat lines = no scaling advantage", fontsize=11)
ax.grid(alpha=0.3)
ax.set_ylim(-115, 45)

# annotate the wins
ax.text(18, 36, "ternary_link (transport, 50% null): +23% flat", color="#27ae60", fontsize=8)
ax.text(18, 31, "hex_neighbor: +33% flat", color="#27ae60", fontsize=8)
ax.text(18, 26, "hex_pod_addr: +23%→+12% (decaying)", color="#27ae60", fontsize=8)
# annotate the loss band
ax.text(4.3, -100, "13 ops: −50%…−100% (flat)", color="#c0392b", fontsize=8, fontweight="bold")

fig.tight_layout()
import os
os.makedirs("docs/compute/address_space", exist_ok=True)
fig.savefig("docs/compute/address_space/combined_advantage.png", dpi=150)
fig.savefig("docs/compute/address_space/combined_advantage.svg")
print("wrote docs/compute/address_space/combined_advantage.png + .svg")
