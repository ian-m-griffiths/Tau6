#!/usr/bin/env python3
"""Parse ternary_sweep.log into an energy table and report minimums.

ngspice lowercases meas names in the log, so everything is matched
case-insensitively. The key sanity check: an ultra-short / low-current pulse
may never forward-bias the receiver diode, leaving the asserted rail ~0 V.
Energy without signal is not a transfer, so we report:
  - min epush with railA >= 0.25 V  (README demux threshold, strict)
  - min epush with railA >= 0.10 V  (loose)
  - min raw epush                   (flagged if signal not asserted)
"""
import re
import sys

MEAS_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([-0-9.eE+]+)")

def parse(logpath):
    vals = {}
    with open(logpath) as f:
        for line in f:
            m = MEAS_RE.match(line)
            if m:
                vals[m.group(1).lower()] = float(m.group(2))
    return vals

def decode(inst):
    """X_<MOD>_<ip>_<pw>_<rw>_<cl> (lowercased) -> dict of levers."""
    parts = inst.split("_")
    # parts: ['x', 'id', '02', '05', '100', '05']  (meas prefix stripped already)
    mod, ip, pw, rw, cl = parts[1], parts[2], parts[3], parts[4], parts[5]
    ipv = {"02": "0.2m", "05": "0.5m", "10": "1m"}[ip]
    pwv = {"05": "0.5n", "10": "1n", "30": "3n", "100": "10n"}[pw]
    rwv = {"100": "100", "500": "500"}[rw]
    clv = {"05": "0.5p", "10": "1p"}[cl]
    dmod = "SCHOTTKY" if mod == "sc" else "IDEAL"
    return dict(diode=dmod, ip=ipv, pw=pwv, rw=rwv, cl=clv)

def inst_of(meas_name):
    # 'epush_x_id_02_05_100_05' -> 'x_id_02_05_100_05'
    return meas_name.split("_", 1)[1]

def main():
    vals = parse(sys.argv[1] if len(sys.argv) > 1 else "ternary_sweep.log")
    enull = vals.get("enull", float("nan"))
    print(f"null: enull = {enull:.3e} J   rails {vals.get('vra_null',0):.2e} / {vals.get('vrb_null',0):.2e} V")

    instances = sorted({inst_of(k) for k in vals if k.startswith("epush_")})
    epushes = []
    for inst in instances:
        epushes.append((vals["epush_" + inst], inst))

    def report(label, thr=None):
        cands = epushes if thr is None else [r for r in epushes if vals["vraa_" + r[1]] >= thr]
        b = min(cands, key=lambda r: r[0])
        v, inst = b
        lv = decode(inst)
        d = {k: vals.get(f"{k.lower()}_{inst}") for k in ("epush", "epull", "ecyc1", "ecyc2", "ecycT")}
        railA = vals["vraa_" + inst]
        railB = vals["vrab_" + inst]
        print(f"\n=== {label} ===")
        print(f"epush_min = {v*1e12:.4f} pJ   instance {inst}")
        print(f"  levers : diode={lv['diode']} IP={lv['ip']} PW={lv['pw']} RW={lv['rw']} CL={lv['cl']}")
        print(f"  signal : railA(max)={railA:.3f} V   railB(pull, min)={railB:.3f} V")
        print(f"  epull={d['epull']*1e12:.4f} pJ  ecyc1={d['ecyc1']*1e12:.4f} pJ  "
              f"ecyc2={d['ecyc2']*1e12:.4f} pJ (recycling)  ecycT={d['ecycT']*1e12:.4f} pJ")
        avg = (d["epush"] + d["epull"] + enull) / 3
        print(f"  vs binary 0.75 pJ/bit : push ratio {v/0.75e-12:.3f}   "
              f"per-symbol avg {(avg)*1e12:.4f} pJ ratio {avg/0.75e-12:.3f}")
        return v, inst

    report("MIN PUSH with railA >= 0.25 V (strict, README demux threshold)", thr=0.25)
    report("MIN PUSH with railA >= 0.10 V (loose)", thr=0.10)
    report("MIN PUSH raw (signal may not assert)")

    # best per diode model, rail-constrained
    print("\n=== BEST per diode model (railA >= 0.25 V) ===")
    for dmod in ("IDEAL", "SCHOTTKY"):
        cands = [r for r in epushes
                 if decode(r[1])["diode"] == dmod and vals["vraa_" + r[1]] >= 0.25]
        if not cands:
            print(f"{dmod:9s}: no combo reaches 0.25 V")
            continue
        b = min(cands, key=lambda r: r[0])
        print(f"{dmod:9s}: epush = {b[0]*1e12:.4f} pJ  railA={vals['vraa_'+b[1]]:.3f} V  @ {decode(b[1])}")

    # full table: all 96 combos, sorted by epush
    print("\n=== FULL GRID (sorted by epush) ===")
    print(f"{'diode':9s} {'IP':6s} {'PW':5s} {'RW':5s} {'CL':5s} {'epush':>9s} {'epull':>9s} "
          f"{'ecyc2':>9s} {'railA':>7s} {'railB':>7s}  ok(0.25)")
    for v, inst in sorted(epushes, key=lambda r: r[0]):
        lv = decode(inst)
        d = {k: vals.get(f"{k}_{inst}") for k in ("epull", "ecyc2")}
        railA = vals["vraa_" + inst]
        railB = vals["vrab_" + inst]
        ok = "Y" if railA >= 0.25 else "-"
        print(f"{lv['diode']:9s} {lv['ip']:6s} {lv['pw']:5s} {lv['rw']:5s} {lv['cl']:5s} "
              f"{v*1e12:9.4f} {d['epull']*1e12:9.4f} {d['ecyc2']*1e12:9.4f} "
              f"{railA:7.3f} {railB:7.3f}  {ok}")

if __name__ == "__main__":
    main()
