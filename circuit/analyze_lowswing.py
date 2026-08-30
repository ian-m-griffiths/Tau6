#!/usr/bin/env python3
"""Parse lowswing_sweep.log into the low-swing energy table.

The log is the concatenation of one ngspice run per sweep point; each
point's section begins with the echoed circuit title
    Circuit: * LSWSWEEP vd=<VDDR> mode=<FAIR|VTENG> vtd=<VTO> wp=<W>
which is how we split and recover the point's parameters. All .meas
values are lowercased by ngspice.

Energy convention (fair-fight, per point):
  E_wire_trit  = (e_drv_pa+|qg_pa|*VDDR + e_drv_na+|qg_na|*VDDR + 0)/3
                 (driver supply energy = line charge + channel loss,
                  plus driver gate charge; null adds ~0)
  E_iface_SA   = (e_rec_pa + e_rec_na + e_rec_nla)/3   (2x sense amp)
  E_iface_PA   = (e_rec_pb + e_rec_nb + e_rec_nlb)/3   (2x preamp+SA)
  E_trit       = E_wire_trit + chosen interface
  pJ/bit       = E_trit / log2(3) = /1.585
Resolution: latch differentials dA/dB at demux time; null baseline is
~+/-4 mV so >= 10 mV with correct sign = OK, 5-10 mV = MARGINAL, else FAIL.
"""
import re
import sys

MEAS_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([-0-9.eE+]+)")
BANNER_RE = re.compile(r"Circuit:\s*\*\s*lswsweep\s+vd=(\S+)\s+mode=(\S+)\s+vtd=(\S+)\s+wp=(\S+)", re.I)

def split_points(logpath):
    """Yield (params_dict, meas_dict) per sweep point."""
    params, meas = None, {}
    for line in open(logpath):
        bm = BANNER_RE.search(line)
        if bm:
            if params is not None:
                yield params, meas
            params = dict(vd=float(bm.group(1)), mode=bm.group(2),
                          vtd=float(bm.group(3)), wp=bm.group(4))
            meas = {}
            continue
        if params is None:
            continue
        m = MEAS_RE.match(line)
        if m:
            meas[m.group(1).lower()] = float(m.group(2))
    if params is not None:
        yield params, meas

LOG2_3 = 1.585

def trit(a, b, c=0.0):
    return (a + b + c) / 3.0

def classify(diff):
    if diff >= 0.010:
        return "OK"
    if diff >= 0.005:
        return "MAR"
    return "FAIL"

def main():
    points = list(split_points(sys.argv[1] if len(sys.argv) > 1 else "lowswing_sweep.log"))
    print(f"parsed {len(points)} sweep points\n")

    rows = []
    for params, M in points:
        v = params["vd"]; m = params["mode"]
        g = lambda k: M.get(k, float("nan"))
        vdr = v
        wire_push = g("e_drv_pa") + abs(g("qg_pa")) * vdr
        wire_pull = g("e_drv_na") + abs(g("qg_na")) * vdr
        wire_trit = trit(wire_push, wire_pull)
        e_if_sa   = trit(g("e_rec_pa"), g("e_rec_na"), g("e_rec_nla"))
        e_if_pa   = trit(g("e_rec_pb"), g("e_rec_nb"), g("e_rec_nlb"))
        # resolution: channel A (SA) and B (preamp+SA), push and pull
        okA = g("da_pa") >= 0.010 and g("db_na") >= 0.010
        okB = g("da_pb") >= 0.010 and g("db_nb") >= 0.010
        if okA:
            e_if, rec = e_if_sa, "SA"
        elif okB:
            e_if, rec = e_if_pa, "preamp"
        else:
            e_if, rec = min(e_if_sa, e_if_pa), "NONE"
        e_trit = wire_trit + e_if
        rows.append(dict(
            vd=v, mode=m.upper(), vtd=params["vtd"], wp=params["wp"],
            line=g("lvl_pl_pa"), lpk=g("lvl_pa"),
            railA=g("raila_pl_pa"), railB=g("railb_pl_na"),
            pump=g("e_pump_pa")*1e12 + g("e_pump_na")*1e12,
            dApk=g("dapk_pa"), dBpk=g("dbpk_na"),
            wire=wire_trit*1e12, ifSA=e_if_sa*1e12, ifPA=e_if_pa*1e12,
            iface=e_if*1e12, rec=rec,
            total=e_trit*1e12, perbit=e_trit*1e12/LOG2_3,
            dApa=g("da_pa"), dBna=g("db_na"), dApb=g("da_pb"), dBnb=g("db_nb"),
            dAnla=g("da_nla"), dBnla=g("db_nla"),
            clsA=classify(g("da_pa")) + "/" + classify(g("db_na")),
            clsB=classify(g("da_pb")) + "/" + classify(g("db_nb")),
            ipk=abs(g("ipk_pa"))*1e3, ipkna=abs(g("ipk_na"))*1e3,
            didt=g("didt_pa")/1e6, didtna=g("didt_na")/1e6,
        ))

    # ---- tables per mode ----
    for mode in ("FAIR", "VTENG"):
        rs = [r for r in rows if r["mode"] == mode]
        rs.sort(key=lambda r: r["vd"])
        print(f"===== MODE {mode}  (VTD={rs[0]['vtd']}, driver W per point: {[r['wp'] for r in rs]}) =====")
        hdr = (f"{'vd':>5} {'line':>6} {'lpk':>6} {'railA':>6} {'railB':>6} {'pump':>6} | "
               f"{'wire':>7} {'ifSA':>6} {'ifPA':>6} {'iface':>6} {'tot':>6} {'pJ/b':>6} {'rec':>6} | "
               f"{'SAok':>6} {'PAok':>6} | {'ipk':>6} {'didt':>7} | {'dApa':>7} {'dBna':>7} "
               f"{'dApk':>7} {'dBpk':>7}")
        print(hdr)
        for r in rs:
            print(f"{r['vd']:5.2f} {r['line']:6.3f} {r['lpk']:6.3f} {r['railA']:6.3f} {r['railB']:6.3f} "
                  f"{r['pump']:6.3f} | {r['wire']:7.3f} {r['ifSA']:6.3f} {r['ifPA']:6.3f} "
                  f"{r['iface']:6.3f} {r['total']:6.3f} {r['perbit']:6.3f} {r['rec']:>6} | "
                  f"{r['clsA']:>6} {r['clsB']:>6} | {r['ipk']:6.3f} {r['didt']:7.1f} | "
                  f"{r['dApa']:7.4f} {r['dBna']:7.4f} {r['dApk']:7.4f} {r['dBpk']:7.4f}")
        print()

    # ---- summary per mode ----
    print("===== SUMMARY =====")
    for mode in ("FAIR", "VTENG"):
        rs = [r for r in rows if r["mode"] == mode]
        rs.sort(key=lambda r: r["vd"])
        ok = [r for r in rs if r["rec"] != "NONE"]
        if not ok:
            print(f"{mode}: no point resolves!")
            continue
        best = min(ok, key=lambda r: r["total"])
        sa_floor = min((r for r in rs if r["clsA"] == "OK/OK"), key=lambda r: r["vd"], default=None)
        pa_floor = min((r for r in rs if r["clsB"] == "OK/OK"), key=lambda r: r["vd"], default=None)
        print(f"{mode}: min-total @ vd={best['vd']:.2f}V  E_trit={best['total']:.3f} pJ  "
              f"= {best['perbit']:.3f} pJ/bit  receiver={best['rec']}")
        print(f"   SA-only resolves (OK/OK) down to vd={sa_floor['vd']:.2f}V "
              f"(railA={sa_floor['railA']:.3f}V, dA={sa_floor['dApa']:.4f}/dB={sa_floor['dBna']:.4f})"
              if sa_floor else "   SA-only: never OK/OK")
        print(f"   preamp+SA resolves (OK/OK) down to vd={pa_floor['vd']:.2f}V"
              if pa_floor else "   preamp+SA: never OK/OK")
        if sa_floor:
            base = max(rs, key=lambda r: r["vd"])  # mode's own full-swing reference
            sv = base["wire"] - sa_floor["wire"]    # pJ/trit saved down to the SA floor
            step = base["ifPA"] - base["ifSA"]      # cost of upgrading the receiver
            # swing step BELOW the SA floor: savings of one more step vs preamp cost
            below = [r for r in rs if r["vd"] < sa_floor["vd"] and r["clsB"] != "FAIL/FAIL"]
            print(f"   wire savings @ SA floor vs {base['vd']:.2f}V: {sv:.3f} pJ/trit; "
                  f"preamp step cost: {step:.3f} pJ/trit")
            if below:
                nxt = max(below, key=lambda r: r["vd"])
                stepgain = sa_floor["wire"] - nxt["wire"]  # extra wire saved by the first
                                                           # swing step BELOW the SA floor
                print(f"   below the floor ({nxt['vd']:.2f}V, needs preamp): one more step "
                      f"saves {stepgain:.3f} pJ wire but costs {step:.3f} pJ receiver -> "
                      f"{'still a WIN' if stepgain >= step else 'NET LOSS (receiver wall)'}")
    print()
    print("Resolution legend: OK>=10mV, MAR 5-10mV, FAIL<5mV or wrong sign; null baseline ~4mV.")

if __name__ == "__main__":
    main()
