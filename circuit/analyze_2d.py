#!/usr/bin/env python3
"""Parse pwm5_2d.log: extract per-symbol energies, rails, margins, demux
for each control-block run (VARIANT A/A2/A3/B) and print fair-fight tables."""
import re

log = open("pwm5_2d.log").read()

# split on the VARIANT echo markers
sections = re.split(r"VARIANT ([A][23]?|[B])\s*:", log)
runs = {}
for i in range(1, len(sections), 2):
    label = sections[i].strip()
    body = sections[i + 1]
    meas = {}
    for name, val in re.findall(r"^([a-z0-9_]+)\s+=\s+([-\d.eE+]+)", body, re.M):
        meas[name] = float(val)
    runs[label] = meas

def pj(v): return v * 1e12

CASES = {1: "+H", 2: "+L", 3: "-L", 4: "-H", 5: "null"}
THRS = {"A": 0.18, "A2": 0.19, "A3": 0.157, "B": 0.095}
summary = {}
for label, meas in runs.items():
    thr = THRS.get(label, "?")
    print("=" * 78)
    print(f"RUN {label}   (THR={thr} V)")
    print("=" * 78)
    rows = []
    for k in [1, 2, 3, 4, 5]:
        e_drv = meas.get(f"e{k}_drv", 0)
        qg = meas.get(f"qg{k}", 0)
        e_rec = meas.get(f"e{k}_rec", 0)
        e_gate = abs(qg) * 1.0  # x VDDR
        e_sym = e_drv + e_gate + e_rec
        rows.append((CASES[k], e_drv, e_gate, e_rec, e_sym))
    avg = sum(r[4] for r in rows) / 5
    for name, d, g, r_, s in rows:
        print(f"  {name:5s} E_drv {pj(d):7.3f}  E_gate {pj(g):6.3f}  E_rec {pj(r_):6.3f}  E_sym {pj(s):7.3f} pJ")
    print(f"  avg = {pj(avg):.3f} pJ/symbol -> {pj(avg)/2.3219:.3f} pJ/bit")
    summary[label] = (pj(avg), pj(avg) / 2.3219)
    print("  --- (V,t) points + resolution (rail@eval, area, demux) ---")
    for k in [1, 2, 3, 4]:
        ra = meas.get(f"raila{k}e")
        rb = meas.get(f"railb{k}e")
        re_ = ra if ra is not None else rb
        pk = meas.get(f"raila{k}") if ra is not None else meas.get(f"railb{k}")
        area = meas.get(f"areaa{k}") if ra is not None else meas.get(f"areab{k}")
        dA, dB, dL = meas.get(f"da{k}", 0), meas.get(f"db{k}", 0), meas.get(f"dl{k}", 0)
        print(f"  {CASES[k]:5s} rail_peak {abs(pk)*1e3:7.1f} mV  rail@eval {abs(re_)*1e3:7.1f} mV  "
              f"area {abs(area)*1e12:6.3f} pV.s  dA {dA:+.3f} dB {dB:+.3f} dL {dL:+.3f}")
    print()

print("=" * 78)
print("Verdict table (pJ/bit)")
print("=" * 78)
print(f"  binary   0.748   (baseline)")
print(f"  ternary  0.515   (null-carrying)")
print(f"  PAM-4    0.401")
print(f"  PWM-5    0.550   (length-only, pwm5.cir)")
for label, (avg, bit) in summary.items():
    print(f"  PWM-5-2D {label:>3s}  {avg:6.3f} pJ/sym  {bit:6.3f} pJ/bit")
