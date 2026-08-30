#!/usr/bin/env python3
"""
tau_energy_search.py — the combinatorial compiler v0 for the Tau Architecture.

Finds the MINIMUM-ENERGY gate-level ternary netlist that realises a GIVEN truth
table, where "energy" is TOTAL CHANNEL-ACTIVATION energy (the project's settled
fair-fight idea: null is ~free, +/-1 costs ~1, so a gate whose output is
null-heavy is cheap).

  * trit = {-1, 0, +1} (Python ints).  Encoding (rtl/ternary_gates.v):
      01=+1 (push), 00=0 (null), 10=-1 (pull), 11=NEVER.  The search works on
      ints; the wire encoding is documented, not simulated.
  * gate = a function on 1-2 trits.  The enumeration library is the RTL cell set
      projected to 1-2 inputs:  tneg, cyc, tand, tor, tmul, cons, tsum.
        tsum(a,b) = (a+b) mod 3 (balanced)   = tadd1(a,b,0).sum   ("ternary XOR")
        cons(a,b) = a if a==b else 0         = tadd1(a,b,0).cout  (the half-adder carry)
      tadd1 (3-input full adder) and mux3 (4-input 3:1 mux) are kept as *model*
      cells (printed in the cell table / used for the MUX) but are NOT in the
      1-2-input enumeration.
  * cost model (transport.py CORRECTION 1):  E_+/-1 = 1.20 pJ, E_null = 0.05 pJ.
      node_cost(output_truth_table) = E_static + sum over every input row of
          (E_+/-1 if output trit != 0 else E_null).
      Netlist cost = sum of node_cost over all its gate outputs.  Because a
      node's cost depends only on its OUTPUT function's null fraction, "null-heavy
      = cheap" is exact: the search is a weighted (energy) exact synthesis.
  * search = level-by-level exact synthesis (Dijkstra-like DP over the reachable
      function set) with branch-and-bound: once a solution of cost C is known,
      any gate placement whose cost is already >= C is cut (it can only get more
      expensive).  Running the SAME enumeration with pruning on/off measures the
      search-space reduction "weighted logic" buys.

HONESTY (see --report): this cost model is CHANNEL ACTIVATION only.  It does NOT
include the per-gate 2-threshold receiver tax (measured 2.54x) or the null rail
(the third decision a direction receiver cannot emit), which are exactly what
make the real mod-3 sum land at the project's settled 1.42x/bit wall.  So the
search finds the *structural* minimum, not a device that beats the wall.  The
E_static knob is where that omitted overhead lives.

Run:  python3 scripts/tau_energy_search.py            # demo targets + netlists
      python3 scripts/tau_energy_search.py --report   # + honest per-bit comparison
      python3 scripts/tau_energy_search.py --max-depth 3 --no-tsum   # e.g. show ⊕ irreducible
"""

from __future__ import annotations

import argparse
import itertools
import math
from dataclasses import dataclass
from typing import Callable, Optional

# ----------------------------------------------------------------------------
# energy constants — EASY TO CHANGE.  Grounded in transport.py CORRECTION 1.
# ----------------------------------------------------------------------------
E_PLUSMINUS = 1.20        # pJ per +/-1 channel activation (a push or a pull)
E_NULL = 0.05             # pJ per null ("~free", not exactly 0 — transport.py)
E_STATIC = 0.0            # pJ per gate static overhead (the receiver/null-rail knob)

BITS_PER_TRIT = math.log2(3.0)                     # 1.58496... bits of info per trit
# settled verdicts, quoted from the project (NOT invented here):
TAX_2THRESHOLD = 2.0 * math.log(2.0) / math.log(3.0)   # 1.262x/bit  (ThresholdLowerBound.lean)
SETTLED_MOD3_PER_BIT = 1.42                            # measured ⊕ vs binary FA (tsum_cell.md §5, 567/399)
SETTLED_MOD3_VS_XOR = 2.33                             # measured ⊕ vs binary XOR2 (tsum_cell.md §5)

TRITS = (-1, 0, +1)


# ----------------------------------------------------------------------------
# 1. trits and gates
# ----------------------------------------------------------------------------
def bal_mod3(s: int) -> int:
    """Reduce s to the balanced residue in {-1,0,+1} (maps 2->-1, -2->+1, 3->0, ...)."""
    r = s % 3
    return r if r <= 1 else r - 3


def _tneg(x: int) -> int:
    return -x                       # wire swap


def _cyc(x: int) -> int:
    return bal_mod3(x + 1)          # -1->0->+1->-1  (the Z3 cycle)


def _tand(a: int, b: int) -> int:
    return min(a, b)                # lattice meet


def _tor(a: int, b: int) -> int:
    return max(a, b)                # lattice join


def _tmul(a: int, b: int) -> int:
    return a * b                    # sign product (null absorbs: 0*x = 0, +/-1*+/-1 = +/-1)


def _cons(a: int, b: int) -> int:
    return a if a == b else 0       # consensus: a when a==b, else null


def _tsum(a: int, b: int) -> int:
    return bal_mod3(a + b)          # mod-3 sum = F3 addition = "ternary XOR"


def _tadd1(a: int, b: int, cin: int) -> tuple[int, int]:
    """The RTL full-adder cell -> (sum, cout), balanced carry rule.
    (kept as a 3-input *model* cell; the enumeration uses its 2-input projections
    tsum = tadd1(a,b,0).sum and cons = tadd1(a,b,0).cout.)"""
    s = a + b + cin
    cout = 1 if s >= 2 else (-1 if s <= -2 else 0)
    return bal_mod3(s), cout


def _mux3(s: int, xm: int, x0: int, xp: int) -> int:
    """3:1 ternary mux: select trit s chooses among the three data inputs."""
    return xm if s == -1 else (x0 if s == 0 else xp)


@dataclass(frozen=True)
class Gate:
    name: str
    arity: int
    fn: Callable
    note: str = ""


# enumeration library (1-2 input gates), ordered cheap-first for pruning efficacy
GATES = [
    Gate("cons", 2, _cons, "consensus / half-adder carry (= tadd1 cout)"),
    Gate("tmul", 2, _tmul, "mod-3 product (sign product, null absorbs)"),
    Gate("tneg", 1, _tneg, "wire swap"),
    Gate("cyc",  1, _cyc,  "cycle -1->0->+1->-1"),
    Gate("tand", 2, _tand, "min (meet)"),
    Gate("tor",  2, _tor,  "max (join)"),
    Gate("tsum", 2, _tsum, "mod-3 sum (F3 add = ternary XOR = tadd1 sum)"),
]

# model cells that are NOT in the 1-2-input enumeration
MODEL_CELLS = [
    Gate("tadd1", 3, _tadd1, "balanced full adder -> (sum, cout)"),
    Gate("mux3",  4, _mux3,  "3:1 ternary mux (select s, data xm/x0/xp)"),
]


# ----------------------------------------------------------------------------
# 2. truth tables + the cost model
# ----------------------------------------------------------------------------
def combos(n: int) -> list[tuple[int, ...]]:
    return list(itertools.product(TRITS, repeat=n))


def truth_table(fn: Callable, arity: int) -> tuple[int, ...]:
    """The output trit for every input combination (length 3**arity)."""
    return tuple(fn(*v) for v in combos(arity))


def nonnull_count(tt: tuple[int, ...]) -> int:
    return len(tt) - tt.count(0)


def node_cost(tt: tuple[int, ...]) -> float:
    """Cost of one gate node = sum over its truth table of the output activation.
    Depends ONLY on the output function -> 'null-heavy output = cheap' is exact.
    Reads the module-level E_* constants (so --null-free / --static flags apply)."""
    nn = nonnull_count(tt)
    return E_STATIC + E_PLUSMINUS * nn + E_NULL * (len(tt) - nn)


def gate_intrinsic_energy(gate: Gate) -> float:
    """A cell's intrinsic energy over its OWN arity (for the cell-cost table)."""
    if gate.name == "tadd1":
        # two outputs (sum, cout) over all 27 input triples
        total = 0.0
        for a, b, c in combos(3):
            s, co = gate.fn(a, b, c)
            for o in (s, co):
                total += E_PLUSMINUS if o != 0 else E_NULL
        return E_STATIC + total
    return node_cost(truth_table(gate.fn, gate.arity))


# ----------------------------------------------------------------------------
# 3. the search: exact synthesis with branch-and-bound energy pruning
# ----------------------------------------------------------------------------
@dataclass
class Net:
    """One realised signal: its truth table + how it was built (a DAG node)."""
    fn: tuple[int, ...]
    gate: str = ""                 # leaf label ("x0", "0", "+1", "-1") or gate name
    inputs: tuple["Net", ...] = ()
    cost: float = 0.0


def _apply(gate: Gate, ins: list[tuple[int, ...]]) -> tuple[int, ...]:
    """Compose a gate over whole-truth-table inputs (all length 3**n)."""
    nrows = len(ins[0])
    if gate.arity == 1:
        f = ins[0]
        return tuple(gate.fn(f[i]) for i in range(nrows))
    f, g = ins[0], ins[1]
    return tuple(gate.fn(f[i], g[i]) for i in range(nrows))


def synthesize(target: tuple[int, ...], n_inputs: int, gates: list[Gate],
               max_depth: int = 3, prune: bool = True,
               constants: bool = False) -> tuple[float, Optional[Net], dict]:
    """Minimal-cost netlist for `target` (length 3**n_inputs), exact up to max_depth.

    Level-by-level DP over the reachable function set (a gate placement realises a
    NEW output function h from already-realised functions at added cost
    cost(f)+cost(g)+node_cost(h)); each function keeps only its cheapest netlist.
    Branch-and-bound: when a solution of cost C is known, any placement with
    cost >= C is cut (costs are non-negative, so it can never beat C).
    """
    signals: dict[tuple[int, ...], tuple[float, Net]] = {}
    for i in range(n_inputs):
        tt = tuple(v[i] for v in combos(n_inputs))
        signals[tt] = (0.0, Net(fn=tt, gate=f"x{i}", cost=0.0))
    if constants:
        for label, val in (("0", 0), ("+1", 1), ("-1", -1)):
            tt = tuple([val] * (3 ** n_inputs))
            signals[tt] = (0.0, Net(fn=tt, gate=label, cost=0.0))

    best_cost = float("inf")
    best_net: Optional[Net] = None
    stats = {"generated": 0, "per_level": []}

    rows = 3 ** n_inputs
    # Cheapest possible node = an all-null output (every non-null trit only adds).
    # An admissible lower bound, so we can cut BEFORE evaluating a gate.
    min_node = E_STATIC + E_NULL * rows

    for _depth in range(1, max_depth + 1):
        # pool sorted cheap-first so the branch-and-bound cuts a contiguous
        # (expensive) suffix of the pairing loops — this is the executable form of
        # "weighted logic decreases the search space".
        pool = sorted(signals.keys(), key=lambda f: signals[f][0])
        new: dict[tuple[int, ...], tuple[float, Net]] = {}
        for g in gates:
            if g.arity == 1:
                for f in pool:
                    cf = signals[f][0]
                    if prune and cf + min_node >= best_cost:
                        break                       # f only gets more expensive
                    stats["generated"] += 1
                    h = _apply(g, [f])
                    c = cf + node_cost(h)
                    if c < new.get(h, (float("inf"),))[0]:
                        new[h] = (c, Net(fn=h, gate=g.name, inputs=(signals[f][1],), cost=c))
            else:  # binary
                for f in pool:
                    cf = signals[f][0]
                    if prune and cf + min_node >= best_cost:
                        break
                    fnet = signals[f][1]
                    for g2 in pool:
                        cg2 = signals[g2][0]
                        if prune and cf + cg2 + min_node >= best_cost:
                            break                       # g2 only gets more expensive
                        stats["generated"] += 1
                        h = _apply(g, [f, g2])
                        c = cf + cg2 + node_cost(h)
                        if c < new.get(h, (float("inf"),))[0]:
                            new[h] = (c, Net(fn=h, gate=g.name,
                                             inputs=(fnet, signals[g2][1]), cost=c))
        for h, (c, net) in new.items():
            if c < signals.get(h, (float("inf"),))[0]:
                signals[h] = (c, net)
        stats["per_level"].append(len(new))
        if target in new and new[target][0] < best_cost:
            best_cost = new[target][0]
            best_net = new[target][1]

    if target in signals:
        return signals[target][0], signals[target][1], stats
    return float("inf"), None, stats


# ----------------------------------------------------------------------------
# netlist rendering + verification
# ----------------------------------------------------------------------------
def render_netlist(net: Net) -> tuple[list[str], str]:
    """Topological (dependency-first) print of a Net DAG."""
    order: list[Net] = []
    seen: set[int] = set()

    def dfs(n: Net) -> None:
        if id(n) in seen or not n.inputs:
            return
        seen.add(id(n))
        for i in n.inputs:
            dfs(i)
        order.append(n)

    dfs(net)
    label: dict[int, str] = {}
    for k, n in enumerate(order):
        label[id(n)] = f"n{k}"

    def nm(n: Net) -> str:
        return n.gate if not n.inputs else label[id(n)]

    lines = [f"  {label[id(n)]} = {n.gate}({', '.join(nm(i) for i in n.inputs)})"
             for n in order]
    return lines, nm(net)


def verify_net(net: Net, target: tuple[int, ...]) -> bool:
    """Re-compose the DAG and check it equals the target truth table."""
    cache: dict[int, tuple[int, ...]] = {}

    def eval_net(n: Net) -> tuple[int, ...]:
        if id(n) in cache:
            return cache[id(n)]
        if not n.inputs:
            return n.fn
        ins = [eval_net(i) for i in n.inputs]
        gname = n.gate
        gate = next(g for g in GATES if g.name == gname)
        cache[id(n)] = _apply(gate, ins)
        return cache[id(n)]

    return eval_net(net) == target


# ----------------------------------------------------------------------------
# 4. demo targets
# ----------------------------------------------------------------------------
def _neg_min(a: int, b: int) -> int:
    return -min(a, b)


def _neg_max(a: int, b: int) -> int:
    return -max(a, b)


def _imply(a: int, b: int) -> int:
    return max(-a, b)          # "a implies b" in the max/neg Kleene reading


# name, function, arity, is-required-by-spec, note
DEMO_TARGETS: list[tuple[str, Callable, int, bool, str]] = [
    ("mod-3 sum ⊕",       _tsum,   2, True,  "F3 field addition, the settled 1.42×/bit wall"),
    ("half-adder carry",  _cons,   2, True,  "= consensus(a,b) = tadd1(a,b,0).cout"),
    ("MIN",               _tand,   2, True,  "min (lattice meet)"),
    ("MAX",               _tor,    2, True,  "max (lattice join)"),
    ("consensus",         _cons,   2, True,  "a if a==b else 0"),
    # extra compound targets (2-input, need >=2 gates) — to exercise the pruning:
    ("neg-min (−min)",    _neg_min, 2, False, "tneg∘tand vs tor∘(tneg,tneg)"),
    ("neg-max (−max)",    _neg_max, 2, False, "tneg∘tor vs tand∘(tneg,tneg)"),
    ("imply (max(−a,b))", _imply,   2, False, "tor∘(tneg a, b) vs tneg∘tand∘(a,tneg b)"),
]


def constructive_mux3() -> list[tuple[str, Callable, list[str]]]:
    """A 3:1 mux (select s, data xm/x0/xp) built from the 1-2-input cells.

    Literal detectors (Dk(s)=+1 iff s==k, else 0), then a tmul gate per data
    input (null absorbs: selector 0 kills the data, selector +1 passes it), and
    the mod-3 sum of the three terms (0 is the additive identity, so the sum
    passes the one selected data input through unchanged):
        Dp = cons(s,+1);  Dn = tneg(cons(s,-1));  D0 = tsum(+1, tneg(tmul(s,s)))
        out = tsum(tsum(tmul(Dn,xm), tmul(D0,x0)), tmul(Dp,xp))
    (11 gates; constants +/-1 are free rail ties.  NOTE: a min/max "select" fails
    here because min(0,-1) = -1 leaks the negative data — only the null-absorbing
    tmul gives a true selector.)"""
    return [
        ("Dp",  _cons, ["s", "+1"]),
        ("cn",  _cons, ["s", "-1"]),
        ("Dn",  _tneg, ["cn"]),
        ("sq",  _tmul, ["s", "s"]),
        ("nsq", _tneg, ["sq"]),
        ("D0",  _tsum, ["+1", "nsq"]),
        ("tm",  _tmul, ["Dn", "xm"]),
        ("t0",  _tmul, ["D0", "x0"]),
        ("tp",  _tmul, ["Dp", "xp"]),
        ("m1",  _tsum, ["tm", "t0"]),
        ("out", _tsum, ["m1", "tp"]),
    ]


def eval_steps(steps: list[tuple[str, Callable, list[str]]], primary: list[str]) \
        -> tuple[dict[str, tuple[int, ...]], float]:
    """Evaluate a named step list over all primary-input combos; return env + energy."""
    cs = combos(len(primary))
    env: dict[str, tuple[int, ...]] = {
        p: tuple(c[i] for c in cs) for i, p in enumerate(primary)
    }
    for label, val in (("+1", 1), ("-1", -1), ("0", 0)):
        env[label] = tuple([val] * len(cs))
    energy = 0.0
    for name, fn, args in steps:
        arg_tts = [env[a] for a in args]
        tt = tuple(fn(*[arg_tts[k][i] for k in range(len(args))]) for i in range(len(cs)))
        env[name] = tt
        energy += node_cost(tt)
    return env, energy


# ----------------------------------------------------------------------------
# 5. report helpers
# ----------------------------------------------------------------------------
def per_bit_costs(net_cost: float, n_inputs: int) -> tuple[float, float]:
    """(avg per-operation channel energy, per-bit) under uniform primary inputs."""
    per_op = net_cost / (3 ** n_inputs)
    return per_op, per_op / BITS_PER_TRIT


def print_cell_table() -> None:
    print("cell library (intrinsic energy over each cell's own truth table):")
    print("  " + "-" * 66)
    for g in GATES + MODEL_CELLS:
        e = gate_intrinsic_energy(g)
        rows = 3 ** g.arity
        nn = 0
        if g.name == "tadd1":
            nn = sum(1 for a, b, c in combos(3)
                     for o in g.fn(a, b, c) if o != 0)
        else:
            nn = nonnull_count(truth_table(g.fn, g.arity))
        print(f"  {g.name:>6}  ({g.arity}-in)  {rows:>3} rows  non-null {nn:>3}  "
              f"energy {e:7.3f} pJ   {g.note}")
    print("  " + "-" * 66)


def run_demo(max_depth: int, use_tsum: bool, constants: bool) -> list[dict]:
    print(f"energy model: E_+/-1 = {E_PLUSMINUS:.2f} pJ, E_null = {E_NULL:.2f} pJ, "
          f"E_static = {E_STATIC:.2f} pJ/gate")
    print(f"search: exact synthesis, max_depth = {max_depth}, "
          f"constants {'ON' if constants else 'OFF'}\n")

    gates = [g for g in GATES if use_tsum or g.name != "tsum"]
    rows: list[dict] = []
    for name, fn, arity, required, note in DEMO_TARGETS:
        target = truth_table(fn, arity)
        tag = "" if required else "  [extra]"
        print(f"TARGET: {name}{tag}   ({arity} inputs, {3 ** arity} rows)   — {note}")
        c_pr, net_pr, st_pr = synthesize(target, arity, gates, max_depth, prune=True,
                                         constants=constants)
        c_un, net_un, st_un = synthesize(target, arity, gates, max_depth, prune=False,
                                         constants=constants)
        if net_pr is None:
            reason = ("  (with tsum removed this reproduces the project's finding: ⊕ is "
                      "irreducible, {NOT,MIN,MAX,CONS,TMUL} cannot generate F3 addition)"
                      if name == "mod-3 sum ⊕" else "")
            print(f"  NOT realizable through depth {max_depth} in the current cell set.")
            print(f"{reason}\n")
            rows.append(dict(name=name, gates=None, cost=None,
                             explored_pruned=st_pr["generated"],
                             explored_unpruned=st_un["generated"], redux=None))
            continue
        assert c_pr == c_un, "pruning must not change the optimum"
        assert verify_net(net_pr, target), "internal error: netlist does not match target"
        lines, outname = render_netlist(net_pr)
        ngates = len(lines)
        print(f"  minimal netlist  (cost {c_pr:.3f} pJ, {ngates} gate"
              f"{'s' if ngates != 1 else ''}):")
        for ln in lines:
            print(ln)
        print(f"  out = {outname}")
        redux = st_un["generated"] / st_pr["generated"] if st_pr["generated"] else float("inf")
        print(f"  nodes explored — with energy pruning: {st_pr['generated']:>6}"
              f"   without: {st_un['generated']:>6}"
              f"   (reduction {redux:.1f}x)\n")
        rows.append(dict(name=name, gates=ngates, cost=c_pr,
                         explored_pruned=st_pr["generated"],
                         explored_unpruned=st_un["generated"], redux=redux))
    return rows


def run_mux() -> dict:
    print("TARGET: 3:1 MUX  (4 inputs, 81 rows)  — select s, data xm/x0/xp -> x_s")
    # (a) as a primitive model cell
    e_prim = node_cost(truth_table(_mux3, 4))
    print(f"  as a primitive cell `mux3`: energy {e_prim:.3f} pJ "
          f"({nonnull_count(truth_table(_mux3, 4))}/81 rows non-null)")
    # (b) constructive netlist of 1-2-input cells (exhaustive 4-input search is 3^81 fns)
    steps = constructive_mux3()
    env, e_built = eval_steps(steps, ["s", "xm", "x0", "xp"])
    ok = env["out"] == truth_table(_mux3, 4)
    print(f"  as a 1-2-input-cell netlist (constructive, {len(steps)} gates): "
          f"energy {e_built:.3f} pJ   (verifies vs mux3 truth table: {'OK' if ok else 'FAIL'})")
    for nm_, fn_, args in steps:
        print(f"    {nm_:>3} = {getattr(fn_, '__name__', fn_)}({', '.join(args)})")
    print(f"  NOTE: exhaustive minimal-energy search over 4 inputs is 3^81 functions — "
          f"infeasible in pure Python, so this netlist is constructive, not search-minimal.\n")
    return dict(name="3:1 MUX (built)", gates=len(steps), cost=e_built)


def run_report(rows: list[dict], mux: dict) -> None:
    print("=" * 72)
    print("REPORT — honest per-bit cost vs the settled 2-threshold-tax verdict")
    print("=" * 72)
    print(f"binary channel baseline (this model): 1.20 pJ/bit  (a binary bit has no")
    print(f"free null, so each bit is one +/-1 channel).")
    print(f"2-threshold tax floor (ThresholdLowerBound.lean): {TAX_2THRESHOLD:.3f}x/bit")
    print(f"settled measured mod-3 sum ⊕: {SETTLED_MOD3_PER_BIT}x/bit vs binary FA "
          f"({SETTLED_MOD3_VS_XOR}x vs binary XOR2) — tsum_cell.md §5\n")

    print(f"{'target':<20}{'gates':>6}{'E_net pJ':>9}{'pJ/op':>8}{'pJ/bit':>8}"
          f"{'vs binary':>10}   honest note")
    print("-" * 84)
    for r in rows:
        if r["cost"] is None:
            print(f"{r['name']:<20}{'—':>6}{'—':>9}{'—':>8}{'—':>8}{'—':>10}   "
                  f"not realizable in cell set")
            continue
        per_op, per_bit = per_bit_costs(r["cost"], 2)
        ratio = per_bit / E_PLUSMINUS
        note = ""
        if r["name"] == "mod-3 sum ⊕":
            note = "channel model under-prices ⊕ (a false 'win')"
        elif r["name"] in ("half-adder carry", "consensus"):
            note = "null-heavy -> cheapest cell"
        print(f"{r['name']:<20}{r['gates']:>6}{r['cost']:>9.3f}{per_op:>8.3f}"
              f"{per_bit:>8.3f}{ratio:>10.2f}x   {note}")
    # the 3:1 MUX (constructive 11-gate netlist over 4 inputs)
    mux_op, mux_bit = per_bit_costs(mux["cost"], 4)
    print(f"{mux['name']:<20}{mux['gates']:>6}{mux['cost']:>9.3f}{mux_op:>8.3f}"
          f"{mux_bit:>8.3f}{mux_bit / E_PLUSMINUS:>10.2f}x   "
          f"constructive, not search-minimal")
    print()

    # reconcile the ⊕ channel model with the measured wall via the E_static knob
    mod3_cost = next((r["cost"] for r in rows if r["name"] == "mod-3 sum ⊕"), 7.35)
    per_op, per_bit = per_bit_costs(mod3_cost, 2)      # tsum cell, 6/9 non-null
    measured_per_op = 0.898                            # 898 fJ/toggle (tsum_cell.md §4.2)
    needed_static = measured_per_op - per_op
    print("Reconciling the model with the measured wall:")
    print(f"  ⊕ channel-model per-op energy  : {per_op:.3f} pJ  "
          f"({per_bit:.3f} pJ/bit -> {per_bit / E_PLUSMINUS:.2f}x binary)")
    print(f"  ⊕ measured per toggle (ngspice) : {measured_per_op:.3f} pJ  "
          f"(-> 0.567 pJ/bit = {SETTLED_MOD3_PER_BIT}x vs the binary FA)")
    print(f"  gap the channel model omits     : {needed_static:+.3f} pJ/gate "
          f"(= E_static that reproduces the measured toggle)")
    print(f"  -> that ~{needed_static * 1000:.0f} fJ/gate is the 2-threshold receiver "
          f"(measured 2.54x) + the null rail")
    print(f"     (the third decision a direction receiver cannot emit).")
    print()
    print("HONEST BOTTOM LINE:")
    print("  * The search minimizes STRUCTURAL channel-activation energy (null-heaviness).")
    print("  * It reproduces the known structural facts — ⊕ is one irreducible cell")
    print("    (no cheaper multi-gate decomposition through the searched depth), and the")
    print("    half-adder carry IS consensus — it does NOT invent a cheaper ⊕.")
    print("  * Under the channel-only model the null-heavy ⊕ *looks* 0.43x binary (a win);")
    print("    that apparent win is exactly the receiver/null-rail cost the model omits.")
    print("    Adding the E_static knob (%.2f pJ/gate) brings the model back to the"
          % needed_static)
    print(f"    settled {SETTLED_MOD3_PER_BIT}x/bit.  So: search found the structural min,")
    print("    it did NOT beat the 1.42x wall — that wall lives outside this cost model.")
    print("  * Energy pruning cut the explored nodes by the factors in the table above;")
    print("    for the primitive (depth-1) targets the win is re-proving the deep levels")
    print("    (which no cheaper netlist can use); for compound targets it also cuts the")
    print("    depth-3 proof that no cheaper 3-gate decomposition exists.")


def main(argv: list[str] | None = None) -> int:
    global E_NULL, E_STATIC
    ap = argparse.ArgumentParser(description="minimal-energy ternary netlist search")
    ap.add_argument("--report", action="store_true",
                    help="add the honest per-bit comparison vs the 1.42x/bit verdict")
    ap.add_argument("--max-depth", type=int, default=3,
                    help="max gate depth for the exact search (default 3)")
    ap.add_argument("--no-tsum", action="store_true",
                    help="drop tsum from the library (shows ⊕ is irreducible)")
    ap.add_argument("--constants", action="store_true",
                    help="add free constants 0,+1,-1 to the search inputs")
    ap.add_argument("--null-free", action="store_true",
                    help="set E_null=0 (the literal '0 if null else E_+-1' cost)")
    ap.add_argument("--static", type=float, default=E_STATIC,
                    help="per-gate static energy (pJ) — the receiver/null-rail knob")
    args = ap.parse_args(argv)

    if args.null_free:
        E_NULL = 0.0
    E_STATIC = args.static

    print("Tau Architecture — combinatorial compiler v0 (minimal-energy netlists)")
    print("=" * 72)
    print_cell_table()
    print()
    rows = run_demo(args.max_depth, not args.no_tsum, args.constants)
    mux = run_mux()

    print("=" * 72)
    print("SUMMARY — minimal energy + search-space reduction")
    print("=" * 72)
    print(f"{'target':<20}{'gates':>6}{'energy pJ':>10}{'explored (pruned)':>18}"
          f"{'explored (unpruned)':>20}{'reduction':>10}")
    print("-" * 78)
    for r in rows:
        if r["cost"] is None:
            print(f"{r['name']:<20}{'—':>6}{'—':>10}{r['explored_pruned']:>18}"
                  f"{r['explored_unpruned']:>20}{'—':>10}")
        else:
            print(f"{r['name']:<20}{r['gates']:>6}{r['cost']:>10.3f}"
                  f"{r['explored_pruned']:>18}{r['explored_unpruned']:>20}"
                  f"{r['redux']:>9.1f}x")
    print(f"{'3:1 MUX (built)':<20}{mux['gates']:>6}{mux['cost']:>10.3f}"
          f"{'—':>18}{'—':>20}{'constructive':>10}")
    print()
    print("NOTE: 'explored (unpruned)' is the same enumeration with energy pruning OFF;")
    print("      both modes prove the same minimum, so the reduction is pure search-space")
    print("      win.  The unpruned number is dominated by re-proving the deep levels that")
    print("      the energy bound cuts away (no deeper netlist can beat a known cheap one).")

    if args.report:
        print()
        run_report(rows, mux)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
