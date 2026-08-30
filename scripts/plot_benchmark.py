#!/usr/bin/env python3
"""
plot_benchmark.py — render the per-operation benchmark chart (native ternary sense-cost)
from the corrected energy-address-bench.md numbers.

Run: venv/bin/python scripts/plot_benchmark.py
Output: docs/compute/address_space/benchmark_costs.png (+ .svg)
"""
from __future__ import annotations
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# (op, sense-cost in units 2(r+w)+0.5c, category)
#  red  = value-sensing compute -> binary beats ternary ~1.3-1.6x (read+write tax)
#  gray = tie (shared Szudzik / axial-coordinate binary gets it free)
#  green= where ternary genuinely wins (transport / free negation / pure namespace)
ops = [
    ("TGRAD", 19.0, "#c0392b"), ("TRELAX", 16.5, "#c0392b"), ("TRECON", 16.0, "#c0392b"),
    ("TMUL", 7.5, "#c0392b"), ("TADD", 6.5, "#c0392b"), ("TSUB", 6.5, "#c0392b"),
    ("TDOT", 6.5, "#c0392b"), ("TWEDGE", 6.5, "#c0392b"), ("TSYMDOT", 6.5, "#c0392b"),
    ("TNORM", 4.5, "#c0392b"), ("TCONJ", 4.5, "#c0392b"),
    ("TROT", 4.0, "#95a5a6"), ("LDI", 2.0, "#95a5a6"),
    ("ternary_link", 2.0, "#27ae60"),
    ("hex_encode", 0.0, "#95a5a6"), ("hex_decode", 0.0, "#95a5a6"),
    ("hex_neighbor", 0.0, "#95a5a6"), ("hex_pod_addr", 0.0, "#95a5a6"), ("HLT", 0.0, "#95a5a6"),
]

fig, ax = plt.subplots(figsize=(9, 7))
y = list(range(len(ops)))[::-1]
names = [o[0] for o in ops]
vals = [o[1] for o in ops]
cols = [o[2] for o in ops]

ax.barh(y, vals, color=cols, edgecolor="#333", height=0.7)
ax.set_yticks(y)
ax.set_yticklabels(names, fontsize=9)
ax.set_xlabel("native ternary sense-cost  (2(r+w) + 0.5·cheap)", fontsize=10)
ax.set_title("Tau per-operation cost — binary beats ternary ~1.3–1.6× on the red bars\n"
             "(the wins are on the green/gray bars: transport, free negation, pure namespace)", fontsize=10)
ax.grid(axis="x", alpha=0.3)
for yi, v in zip(y, vals):
    if v > 0:
        ax.text(v + 0.2, yi, f"{v:g}", va="center", fontsize=8, color="#333")

# legend
from matplotlib.patches import Patch
ax.legend(handles=[Patch(color="#c0392b", label="value-sensing → binary beats ~1.3–1.6× (read+write tax)"),
                   Patch(color="#95a5a6", label="tie (shared Szudzik / axial-coordinate binary gets it free)"),
                   Patch(color="#27ae60", label="ternary wins (transport 2.67–6.32×)")],
          loc="lower right", fontsize=8)

fig.tight_layout()
import os
os.makedirs("docs/compute/address_space", exist_ok=True)
fig.savefig("docs/compute/address_space/benchmark_costs.png", dpi=150)
fig.savefig("docs/compute/address_space/benchmark_costs.svg")
print("wrote docs/compute/address_space/benchmark_costs.png + .svg")
