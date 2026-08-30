#!/usr/bin/env python3
"""
namespace_plot.py — render the "names, not bits" thesis image: 3^n vs 2^n.

Pure-stdlib SVG (no matplotlib) so it runs anywhere. Outputs
docs/namespace_explosion.svg.

The one image that carries the whole Tau Architecture claim: two lines, both
exponential, but ternary's base is 3 and binary's is 2, so the gap itself grows
exponentially — (3/2)^n — reaching 1.86e11 at n = 64.
"""
import math

NMAX = 64
LOG3 = math.log10(3.0)
LOG2 = math.log10(2.0)

W, H = 920, 580
ML, MR, MT, MB = 78, 48, 58, 64
PX, PY = W - ML - MR, H - MT - MB

y_top = NMAX * LOG3           # ~30.536
y_max = math.ceil(y_top / 5) * 5


def xs(n):
    return ML + (n / NMAX) * PX


def ys(logv):
    return MT + (1 - logv / y_max) * PY


# polylines
def line(fn):
    pts = []
    for n in range(0, NMAX + 1):
        pts.append(f"{xs(n):.2f},{ys(fn(n)):.2f}")
    return " ".join(pts)


tern = line(lambda n: n * LOG3)
bina = line(lambda n: n * LOG2)

# ticks
def y_ticks():
    out = []
    for v in range(0, y_max + 1, 5):
        y = ys(v)
        lab = "1" if v == 0 else f"10^{v}"
        out.append(
            f'<line x1="{ML}" y1="{y:.2f}" x2="{W-MR}" y2="{y:.2f}" '
            f'stroke="#e2e2e2" stroke-width="1"/>'
        )
        out.append(
            f'<text x="{ML-8:.2f}" y="{y+4:.2f}" font-size="12" fill="#666" '
            f'text-anchor="end">{lab}</text>'
        )
    return "\n  ".join(out)


def x_ticks():
    out = []
    for n in range(0, NMAX + 1, 8):
        x = xs(n)
        out.append(
            f'<line x1="{x:.2f}" y1="{MT}" x2="{x:.2f}" y2="{H-MB}" '
            f'stroke="#e2e2e2" stroke-width="1"/>'
        )
        out.append(
            f'<text x="{x:.2f}" y="{H-MB+18:.2f}" font-size="12" fill="#666" '
            f'text-anchor="middle">{n}</text>'
        )
    return "\n  ".join(out)


gap64 = 3 ** NMAX / 2 ** NMAX  # 1.86e11

# annotation arrow at n = 64
ax = xs(NMAX)
ty = ys(NMAX * LOG3)
by = ys(NMAX * LOG2)
mid = (ty + by) / 2

svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="Helvetica, Arial, sans-serif">
  <rect x="0" y="0" width="{W}" height="{H}" fill="#ffffff"/>
  <text x="{ML}" y="30" font-size="20" font-weight="bold" fill="#111">Names: 3&#8319; vs 2&#8319; &#8212; the addressing win</text>
  <text x="{ML}" y="50" font-size="13" fill="#555">log&#8321;&#8320;(addressable names) vs number of symbols n &#8212; both exponential, but the gap grows as (3/2)&#8319;</text>

  {y_ticks()}
  {x_ticks()}

  <polyline points="{bina}" fill="none" stroke="#2b6cb0" stroke-width="2.5"/>
  <polyline points="{tern}" fill="none" stroke="#c05621" stroke-width="2.5"/>

  <text x="{xs(38)}" y="{ys(38*LOG2)-10:.2f}" font-size="13" fill="#2b6cb0">binary 2&#8319;</text>
  <text x="{xs(38)}" y="{ys(38*LOG3)+22:.2f}" font-size="13" fill="#c05621">ternary 3&#8319;</text>

  <line x1="{ax}" y1="{ty:.2f}" x2="{ax}" y2="{by:.2f}" stroke="#c05621" stroke-width="1.5" stroke-dasharray="4,3"/>
  <text x="{ax-8:.2f}" y="{mid+4:.2f}" font-size="14" font-weight="bold" fill="#c05621" text-anchor="end">3&#8319;/2&#8319; = 1.86&#215;10&#185;&#185; at n=64</text>

  <line x1="{ML}" y1="{H-MB}" x2="{W-MR}" y2="{H-MB}" stroke="#333" stroke-width="1.5"/>
  <line x1="{ML}" y1="{MT}" x2="{ML}" y2="{H-MB}" stroke="#333" stroke-width="1.5"/>
  <text x="{ML+PX/2:.2f}" y="{H-14}" font-size="12" fill="#333" text-anchor="middle">n (symbols per address)</text>
</svg>
"""

with open("docs/namespace_explosion.svg", "w") as f:
    f.write(svg)

print(f"wrote docs/namespace_explosion.svg  (gap at n=64 = {gap64:.3e})")
