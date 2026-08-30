#!/usr/bin/env python3
"""
circuit_memo.py — "each path exists once": memoize ternary circuit fragments by
canonical truth-table signature, measure the dedupe ratio, and (optionally) store the
distinct signatures in the causal lattice via `lattice-cli down` / `lattice-lookup`.

WHAT THIS MEASURES (the honest scope)
-------------------------------------
We enumerate *syntactic* ternary circuit fragments — expression trees over a tiny cell
set — and count three levels of collapse:

  1. trees            →  distinct truth tables          (FUNCTIONAL hashing)
  2. distinct tables  →  tables modulo INPUT PERMUTATION (swap x,y)
  3. distinct tables  →  tables modulo FREE RENAMINGS    (permutation + negation of
                          inputs/output — free in ternary because negation is a wire swap)

Ratio 1 is the real synthesis win (it is ordinary functional hashing, the technique
ABC/fraig and every modern logic synthesizer use). Ratios 2–3 are the "permutation /
renaming blow-up" the Tau-architecture pitch is about — they are ONLY sound because the
renamings we quotient by are *free* in this cell set (negation = wire swap, input rewire
= free). They would NOT be sound for a cell library that is not negation-equivariant.

The causal-lattice part is a DEMO, not the measurement: we store each distinct canonical
signature as a lattice node (via `down`) and show `lattice-lookup` retrieves the
sub-fragment (overlap) edges. The dedupe ratio itself is computed in-process with a dict;
the lattice is only a content-addressable store here, and we say so explicitly.

Run:  python3 scripts/circuit_memo.py
      CIRCUIT_MEMO_NO_STORE=1 python3 scripts/circuit_memo.py   # skip lattice-cli
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys

# --------------------------------------------------------------------------- #
# 1. The ternary domain and the tiny cell set
# --------------------------------------------------------------------------- #

TRITS = (-1, 0, +1)
_TMAP = {-1: 0, 0: 1, +1: 2}          # for lexicographic comparison
_REVMAP = {0: "-", 1: "0", 2: "+"}    # human-readable key chars


def t_sum(a: int, b: int) -> int:
    """mod-3 sum (F3 addition) on balanced digits {-1,0,+1}: carry dropped."""
    r = (a + b + 3) % 3
    return r if r <= 1 else -1         # 0 -> 0, 1 -> +1, 2 -> -1


def t_mul(a: int, b: int) -> int:
    """mod-3 product (F3 multiplication) = sign product, 0 absorbs."""
    return a * b


# The minimal functionally-complete set is {sum, mul} + free negation + free constants
# (docs/compute/ground_up/minimal_gates.md). We add min/max (the K3 lattice fragment) so
# the enumeration also exercises the non-field fragment, which is where the permutation
# blow-up is most visible.
CELLS = {
    "c-1":  (0, lambda: -1),
    "c0":   (0, lambda: 0),
    "c+1":  (0, lambda: +1),
    "neg":  (1, lambda v: -v),
    "id":   (1, lambda v: v),
    "sum":  (2, t_sum),
    "mul":  (2, t_mul),
    "min":  (2, min),
    "max":  (2, max),
}
ARITY_0 = [n for n, (a, _) in CELLS.items() if a == 0]
ARITY_1 = [n for n, (a, _) in CELLS.items() if a == 1]
ARITY_2 = [n for n, (a, _) in CELLS.items() if a == 2]

# --------------------------------------------------------------------------- #
# 2. Truth tables
# --------------------------------------------------------------------------- #

# k = 2 inputs, index = (x+1)*3 + (y+1), x slow / y fast.
ASSIGN2 = [(x, y) for x in TRITS for y in TRITS]

_LEAF_TABLE = {
    "x":   tuple(x for (x, _) in ASSIGN2),
    "y":   tuple(y for (_, y) in ASSIGN2),
    "c-1": (-1,) * 9,
    "c0":  (0,) * 9,
    "c+1": (+1,) * 9,
}


def _apply2(op, l, r):
    return tuple(op(a, b) for a, b in zip(l, r))


def _apply1(op, t):
    return tuple(op(v) for v in t)


# --------------------------------------------------------------------------- #
# 3. Canonicalisation (the signature that collapses permutations / renamings)
# --------------------------------------------------------------------------- #

def _matrix(tt):
    """9-tuple -> 3x3 rows (row = x in {-1,0,+1}, col = y in {-1,0,+1})."""
    return [list(tt[0:3]), list(tt[3:6]), list(tt[6:9])]


def _flatten(m):
    return tuple(v for row in m for v in row)


def _transpose(m):
    return [[m[c][r] for c in range(3)] for r in range(3)]


def _encode(tt):
    """trits -> int tuple over {0,1,2} for lexicographic min."""
    return tuple(_TMAP[v] for v in tt)


def canonical_perm(tt):
    """Modulo input permutation (swap x,y) ONLY — no negation."""
    m = _matrix(tt)
    return min(_encode(_flatten(m)), _encode(_flatten(_transpose(m))))


def canonical(tt):
    """Modulo the free-renaming group G = (C2 swap) x (C2 neg-x) x (C2 neg-y) x (C2 neg-out).

    Only FREE operations are quotientable: swapping two input wires, negating an input
    wire (a wire cross), and negating the output (a wire cross). All are 0-cell / 0-energy
    in balanced ternary. |G| = 16 for k=2.
    """
    m = _matrix(tt)
    best = None
    for do_swap in (False, True):
        mm = _transpose(m) if do_swap else m
        for do_negx in (False, True):
            m1 = mm[::-1] if do_negx else mm                 # reverse rows
            for do_negy in (False, True):
                m2 = [row[::-1] for row in m1] if do_negy else m1   # reverse cols
                for do_negout in (False, True):
                    m3 = [[-v for v in row] for row in m2] if do_negout else m2
                    key = _encode(_flatten(m3))
                    if best is None or key < best:
                        best = key
    return best


def key_string(canon_tuple):
    """canonical int-tuple (0..2) -> a lattice-word string, e.g. 'f2:---+00++-'."""
    return "f2:" + "".join(_REVMAP[i] for i in canon_tuple)


# --------------------------------------------------------------------------- #
# 4. Enumerate all expression trees up to MAX_SIZE, evaluate + canonicalise
# --------------------------------------------------------------------------- #

MAX_SIZE = 6


def _enumerate_trees():
    """Memoised lists of expression trees (nested tuples) per size.

    An expression is a str (leaf name) or (cell_name, sub...) — a canonical prefix form.
    Leaves are the two inputs + the three constants.
    """
    by_size = {1: list(ARITY_0) + ["x", "y"]}
    for s in range(2, MAX_SIZE + 1):
        out = []
        for cell in ARITY_1:
            for e in by_size[s - 1]:
                out.append((cell, e))
        for cell in ARITY_2:
            for i in range(1, s - 1):          # children sizes i and s-1-i, both >= 1
                for l in by_size[i]:
                    for r in by_size[s - 1 - i]:
                        out.append((cell, l, r))
        by_size[s] = out
    return by_size


def _table(e, cache):
    """Evaluate an expression tree to its 9-tuple truth table (memoised by value)."""
    if e in cache:
        return cache[e]
    if isinstance(e, str):
        t = _LEAF_TABLE[e]
    else:
        cell = e[0]
        arity, fn = CELLS[cell]
        if arity == 1:
            t = _apply1(fn, _table(e[1], cache))
        else:
            t = _apply2(fn, _table(e[1], cache), _table(e[2], cache))
    cache[e] = t
    return t


def main() -> None:
    print("=" * 72)
    print("circuit_memo.py — Tau-architecture fragment memoization (dedupe) probe")
    print("=" * 72)
    print(f"cell set: {sorted(CELLS)}")
    print(f"inputs: x, y (k=2)   trits: {TRITS}   max tree size: {MAX_SIZE}")
    print()

    by_size = _enumerate_trees()
    tree_count = sum(len(v) for v in by_size.values())

    table_cache: dict = {}
    raw_counter: dict[tuple, int] = {}        # raw truth table -> #trees
    canon_counter: dict[tuple, int] = {}      # canonical sig  -> #trees
    perm_counter: dict[tuple, int] = {}       # perm-only sig   -> #trees
    canon_cache: dict[tuple, tuple] = {}      # raw table -> canonical sig
    edges: dict[tuple, dict[tuple, int]] = {}  # canonical parent -> {canonical child: count}

    def canon_of(tt):
        if tt not in canon_cache:
            canon_cache[tt] = canonical(tt)
        return canon_cache[tt]

    for size, exprs in by_size.items():
        for e in exprs:
            tt = _table(e, table_cache)
            raw_counter[tt] = raw_counter.get(tt, 0) + 1
            perm_counter[canonical_perm(tt)] = perm_counter.get(canonical_perm(tt), 0) + 1
            csig = canon_of(tt)
            canon_counter[csig] = canon_counter.get(csig, 0) + 1
            # sub-fragment containment edges (the "overlap" relation the lattice will hold)
            children = (e[1],) if (isinstance(e, tuple) and CELLS[e[0]][0] == 1) else \
                       (e[1], e[2]) if isinstance(e, tuple) else ()
            for c in children:
                ccsig = canon_of(_table(c, table_cache))
                edges.setdefault(csig, {}).setdefault(ccsig, 0)
                edges[csig][ccsig] += 1

    n_raw = len(raw_counter)
    n_perm = len(perm_counter)
    n_canon = len(canon_counter)
    n_edges = sum(len(v) for v in edges.values())

    print("— enumeration & collapse -------------------------------------------------")
    print(f"  syntactic trees enumerated        : {tree_count:>8,}")
    print(f"  distinct truth tables (functions) : {n_raw:>8,}   "
          f"compression {tree_count / n_raw:>7.1f}x   [FUNCTIONAL hashing]")
    print(f"  distinct modulo input permutation : {n_perm:>8,}   "
          f"compression {tree_count / n_perm:>7.1f}x   [permutation only]")
    print(f"  distinct canonical signatures     : {n_canon:>8,}   "
          f"compression {tree_count / n_canon:>7.1f}x   [permutation + free negation]")
    print(f"  distinct (parent,subfragment) edges: {n_edges:>7,}  (the stored overlap graph)")
    print()

    # The pure "permutation / renaming blow-up" micro-figure: how many distinct FUNCTIONS
    # collapse into one canonical node, averaged over the reachable orbit classes.
    orbit_sizes = [c for c in canon_counter.values()]
    print("— the orbit (renaming) collapse ------------------------------------------")
    print(f"  reachable functions: {n_raw}, collapsed to {n_canon} canonical classes")
    print(f"  mean {sum(orbit_sizes) / len(orbit_sizes):.2f} syntactic trees per class, "
          f"max {max(orbit_sizes)}")
    # how many distinct RAW tables land in one canonical class (the permutation/renaming win)
    raw_by_canon: dict[tuple, set] = {}
    for tt in raw_counter:
        raw_by_canon.setdefault(canon_of(tt), set()).add(tt)
    per_class_raw = [len(s) for s in raw_by_canon.values()]
    print(f"  distinct functions per canonical class: "
          f"mean {sum(per_class_raw) / len(per_class_raw):.2f}, max {max(per_class_raw)}")
    print()

    # Show a concrete orbit: x⊕y and its renamings all share one canonical node.
    _show_example_orbits()

    # k=3 permutation blow-up: S3 permutes the 3 inputs (6 renamings) of ONE fragment.
    _show_k3_permutation_orbit()

    # --------------------------------------------------------------------------- #
    # 5. Store in the causal lattice (optional, DEMO only)
    # --------------------------------------------------------------------------- #
    cli = _find_cli()
    if os.environ.get("CIRCUIT_MEMO_NO_STORE"):
        print("lattice store SKIPPED (CIRCUIT_MEMO_NO_STORE set). In-process dict is the "
              "authoritative dedupe measurement.")
        print()
        _final_verdict(tree_count, n_raw, n_perm, n_canon)
        return
    if cli is None:
        print("lattice-cli NOT FOUND on this machine — falling back to the in-process dict "
              "for dedupe (which is the real measurement anyway). The store/lookup below "
              "would be the only part that needs the binary.")
        print()
        _final_verdict(tree_count, n_raw, n_perm, n_canon)
        return
    _store_and_query(cli, canon_counter, edges)
    print()
    _final_verdict(tree_count, n_raw, n_perm, n_canon)


def _show_example_orbits() -> None:
    """Demonstrate that every renaming of one fragment lands on ONE canonical node."""
    print("— example: the orbit of  x ⊕ y  (mod-3 sum) ------------------------------")
    x = _LEAF_TABLE["x"]
    y = _LEAF_TABLE["y"]
    def _neg(tt): return tuple(-v for v in tt)
    variants = {
        "x⊕y":          _apply2(t_sum, x, y),
        "y⊕x (swap)":   _apply2(t_sum, y, x),
        "(-x)⊕y":       _apply2(t_sum, _neg(x), y),
        "x⊕(-y)":       _apply2(t_sum, x, _neg(y)),
        "-(x⊕y)":       _neg(_apply2(t_sum, x, y)),
        "-((-x)⊕(-y))": _neg(_apply2(t_sum, _neg(x), _neg(y))),
    }
    canon_keys = {key_string(canonical(tt)) for tt in variants.values()}
    for name, tt in variants.items():
        print(f"    {name:<16} -> canonical {key_string(canonical(tt))}")
    print(f"    {len(variants)} variants collapse to {len(canon_keys)} node(s): "
          f"{sorted(canon_keys)}")
    print()


def _show_k3_permutation_orbit() -> None:
    """The k! point, without enumerating 3^(3^3) functions: permuting the 3 inputs of ONE
    3-input fragment is a relabelling, so the S3 orbit (3! = 6 variants) collapses to one
    canonical signature. k=2 gave only 2x (the worst case); k=3 gives 6x, k=4 gives 24x."""
    import itertools

    assign3 = [(a, b, c) for a in TRITS for b in TRITS for c in TRITS]

    def idx3(a):
        return (a[0] + 1) * 9 + (a[1] + 1) * 3 + (a[2] + 1)

    # An ASYMMETRIC 3-input fragment: f(x,y,z) = min(max(x,y), z)  (z is special).
    def frag(x, y, z):
        return min(max(x, y), z)

    base = tuple(frag(*a) for a in assign3)

    def relabel3(tt, sigma):
        # g(x0,x1,x2) = f(x_sigma0, x_sigma1, x_sigma2)
        return tuple(tt[idx3(tuple(a[s] for s in sigma))] for a in assign3)

    def canon3(tt):
        perms = itertools.permutations((0, 1, 2))
        return min(relabel3(tt, sig) for sig in perms)

    orbit = {relabel3(base, sig) for sig in itertools.permutations((0, 1, 2))}
    canon_keys = {canon3(t) for t in orbit}
    print("— k=3 permutation blow-up (S3 has 3! = 6 elements) -----------------------")
    print(f"  fragment f(x,y,z)=min(max(x,y),z): S3 orbit has {len(orbit)} distinct tables")
    print(f"  (max is symmetric in x,y, so x<->y is a stabilizer: 6 / 2 = {len(orbit)}).")
    print(f"  All {len(orbit)} collapse to {len(canon_keys)} canonical node(s) under S3.")
    print("  (S_k scaling: k=2 -> 2x, k=3 -> 6x, k=4 -> 24x, k=5 -> 120x, ...)")
    print()


def _final_verdict(tree_count, n_raw, n_perm, n_canon) -> None:
    print("— verdict ----------------------------------------------------------------")
    print(f"  functional hashing alone: {tree_count:,} trees -> {n_raw:,} functions "
          f"({tree_count / n_raw:.1f}x)")
    print(f"  + permutation/renaming:  {n_raw:,} functions -> {n_canon:,} canonical "
          f"({n_raw / n_canon:.1f}x further)")
    print("  The dedupe is REAL and is just standard functional hashing; the lattice")
    print("  contributes the content-addressable STORE, not the compression itself.")
    print("=" * 72)


# --------------------------------------------------------------------------- #
# 6. lattice-cli integration (best-effort, headless)
# --------------------------------------------------------------------------- #

def _find_cli() -> str | None:
    for cand in (
        os.path.expanduser("~/opencode/lattice-memory/bin/lattice-cli"),
        os.path.expanduser("~/.opencode/lattice-memory/bin/lattice-cli"),
    ):
        if os.path.isfile(cand):
            return cand
    return shutil.which("lattice-cli")


def _store_and_query(cli, canon_counter, edges) -> None:
    import tempfile

    print("— storing distinct signatures in the causal lattice ----------------------")
    nodes: dict[str, dict] = {}
    for csig, count in canon_counter.items():
        k = key_string(csig)
        kids = {key_string(c): cnt for c, cnt in edges.get(csig, {}).items()}
        nodes[k] = {"id": k, "freq": count, "layer": 0, "edges": kids}

    with tempfile.TemporaryDirectory() as td:
        latx = os.path.join(td, "circuit_memo.latx")
        payload = json.dumps(nodes)
        try:
            r = subprocess.run(
                [cli, "down", "--latx", latx],
                input=payload, text=True, capture_output=True, timeout=120,
            )
        except (OSError, subprocess.TimeoutExpired) as e:
            print(f"  [fallback] `down` failed ({e}); using in-process dict only.")
            return

        if r.returncode != 0:
            print(f"  [fallback] `down` returned {r.returncode}: "
                  f"{r.stderr.strip()[:200]}; using in-process dict only.")
            return

        summary = " ".join(r.stdout.strip().splitlines())
        print(f"  stored {len(nodes):,} nodes via `down` -> {latx}")
        print(f"  ({summary})")

        # "find overlap" = lattice-lookup on a representative fragment returns its
        # sub-fragments (the containment edges we stored).
        for demo_word in _pick_demo_words(canon_counter):
            out = subprocess.run(
                [cli, "lattice-lookup", "-l", latx, "-w", demo_word],
                text=True, capture_output=True, timeout=120,
            )
            if out.returncode == 0 and out.stdout.strip():
                body = " | ".join(l.strip() for l in out.stdout.strip().splitlines())
                print(f"  lattice-lookup {demo_word:<12} -> {body}")
            else:
                print(f"  lattice-lookup {demo_word:<12} -> (no neighbors / not found)")


def _pick_demo_words(canon_counter) -> list[str]:
    """Return a few canonical keys, preferring high-multiplicity (re-derived) nodes."""
    order = sorted(canon_counter.items(), key=lambda kv: -kv[1])
    # find the canonical key of x⊕y and of a high-multiplicity node
    demos = [key_string(c) for c, _ in order[:2]]
    return demos


if __name__ == "__main__":
    main()
