#!/usr/bin/env python3
"""
Parse circuit/polar_full_adder.log and check the balanced ternary full-adder
truth table (sum = (a+b+cin) mod 3, carry = +1 iff s>=+2 / -1 iff s<=-2),
plus report energy (fJ) and delay.
"""
import json, re, sys

LOG = "/home/ian/dsh/projects/lattice/circuit/polar_full_adder.log"
EXP = "/home/ian/dsh/projects/lattice/circuit/polar_fa_expected.json"

expected_rows = json.load(open(EXP))   # list of [a,b,c,sval,carry]

def read_meas(log):
    m = {}
    for line in open(log):
        mm = re.match(r"^([\w.]+)\s*=\s*([-+0-9.eE]+)", line)
        if mm:
            name = mm.group(1)
            try:
                m[name] = float(mm.group(2))
            except ValueError:
                pass
    return m

m = read_meas(LOG)

def to_trit(v, tol=0.05):
    if abs(v) < tol:
        return 0
    if abs(v - 1.0) < tol:
        return 1
    if abs(v + 1.0) < tol:
        return -1
    return None

print("=== TRUTH TABLE (balanced, 13 representative rows of 27) ===")
ok = True
for i, (a, b, c, sval, carry) in enumerate(expected_rows, 1):
    got_sum = to_trit(m.get(f"tsum{i}"))
    got_car = to_trit(m.get(f"tcout{i}"))
    good = (got_sum == sval) and (got_car == carry)
    ok = ok and good
    mark = "OK " if good else "FAIL"
    print(f"  {mark} TT{i:2d} (a={a:+d},b={b:+d},cin={c:+d}): "
          f"sum={got_sum}(exp {sval:+d}) carry={got_car}(exp {carry:+d})  "
          f"[V={m.get('tsum'+str(i)):.3f},{m.get('tcout'+str(i)):.3f}]")
print(f"  >>> truth table {'ALL CORRECT' if ok else 'HAS FAILURES'}")

print("\n=== ENERGY (fJ; full cycle / 2 = per toggle) ===")
for key, label in [
    ("ept_e1",   "polar FA cheapest (b: null<->+1, a=c=0)"),
    ("ept_e2",   "polar FA carry + full sum swing (a=+1, b:0<->+1, c=0)"),
    ("ept_e3",   "polar FA full-swing input (a=+1, b:+1<->-1, c=0)"),
    ("ept_bfa",  "binary FA reference (same +/-1V harness, 46T)"),
]:
    v = m.get(key)
    if v is not None:
        print(f"  {key:10s} = {v*1e15:8.1f} fJ/toggle   [{label}]")

print("\n=== NULL-IDLE (quiet window 10-85 ns) ===")
print(f"  eq_e1 = {m.get('eq_e1', 0)*1e18:.3f} aJ  (all-null -> null; expect ~0)")
print(f"  eq_e2 = {m.get('eq_e2', 0)*1e15:.2f} fJ  (a=+1 held -> sum holds +1, Rterm leakage)")

print("\n=== DELAY (E2: input b 50% -> output 50%) ===")
for key, label in [("tdelay_cout", "carry 0->+1 (propagation)"),
                   ("tdelay_sum", "sum +1->-1 (propagation)")]:
    v = m.get(key)
    if v is not None:
        print(f"  {key:12s} = {v*1e9:6.2f} ns  [{label}]")
