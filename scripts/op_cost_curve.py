#!/usr/bin/env python3
"""
op_cost_curve.py — render one Tau operation's energy-cost-vs-word-width curve
(ternary vs binary), using a SHARED cost model so all 19 op charts are comparable.

Shared cost model (operand width n trits / n bits):
    cost(n)  =  (reads + writes) * SYMBOL_TAX * n   +   COMPUTE(n)
  where SYMBOL_TAX = 2 for ternary (2 thresholds to read/write a trit), 1 for binary;
  COMPUTE(n) is per-op (linear / quadratic / karatsuba / none), with ternary adder = 1.92x
  and ternary multiplier = 1.72x binary per bit (measured, word_fairfight.txt).

Usage (a subagent determines reads/writes/COMPUTE for its op, then calls):
    plot_op("TADD", reads=2, writes=1, compute=lambda n: (1.92*n, 1.00*n))
Output: docs/compute/address_space/op_charts/<OP>.png
"""
from __future__ import annotations
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def plot_op(name, reads, writes, compute, n_min=4, n_max=32,
            outdir="docs/compute/address_space/op_charts"):
    """compute(n) -> (ternary_compute, binary_compute) as functions of n."""
    ns = list(range(n_min, n_max + 1))
    tcost = [(reads + writes) * 2 * n + compute(n)[0] for n in ns]
    bcost = [(reads + writes) * 1 * n + compute(n)[1] for n in ns]
    ratio = [t / b if b else 0.0 for t, b in zip(tcost, bcost)]

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(9.5, 3.6))
    fig.suptitle(f"{name} — energy cost vs word width", fontsize=12, fontweight="bold")

    a1.plot(ns, tcost, color="#c0392b", lw=2, label="ternary")
    a1.plot(ns, bcost, color="#3182bd", lw=2, label="binary")
    a1.set_xlabel("word width n")
    a1.set_ylabel("cost (relative units)")
    a1.grid(alpha=0.3)
    a1.legend(fontsize=8)

    a2.plot(ns, ratio, color="#2c3e50", lw=2)
    a2.axhline(1.0, color="#999", ls="--", lw=0.8, label="tie (1.0)")
    a2.set_xlabel("word width n")
    a2.set_ylabel("ternary / binary")
    a2.grid(alpha=0.3)
    a2.legend(fontsize=8)
    a2.set_ylim(0, max(2.2, max(ratio) * 1.15))

    os.makedirs(outdir, exist_ok=True)
    out = os.path.join(outdir, f"{name.replace(' ', '_').replace('/', '_')}.png")
    fig.tight_layout(rect=[0, 0, 1, 0.93])
    fig.savefig(out, dpi=120)
    plt.close(fig)
    print(f"wrote {out}")
    return dict(name=name, ratio_at_n8=ratio[ns.index(8)], ratio_at_n32=ratio[-1],
                flat=(abs(ratio[-1] - ratio[ns.index(8)]) < 0.05))
