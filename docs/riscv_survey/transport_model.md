# Ternary Transport Energy Model for tinyrv — Phase 3 design

**2026-08-29.** The design for `TAU_RISCV_PLAN.md` Phase 3: an energy model in the
tinyrv emulator that measures the ternary-transport win on real memory-access
patterns. This document specifies the *model* (formula + constants) and *how to
wire it into tinyrv's load/store path*. **No code yet** — this is the precise
spec the implementation follows.

Calibration legend (same discipline as `FINAL_VERDICT.md`):
**DIRECT** = measured (ngspice 44.2) or proved (Lean); **DERIVED** = back-solved
from two DIRECT numbers, flagged as such; **OURS** = our design assumption.

> **⚠️ Corrected numbers only.** The honest reference is **0.512 pJ/bit**
> (natural single-ended binary) / **0.216 pJ/bit** (matched low-swing binary) —
> NOT the 0.748 pJ/bit that `ENERGY_LAWS.md`'s leaderboard used. The champion is
> **0.081 pJ/bit** = **6.3× vs 0.512**, **2.67× vs 0.216**.
> Sources: `docs/FINAL_VERDICT.md` (transport row + correction 2),
> `docs/ENERGY_LAWS.md` (correction banner), `circuit/ENERGY_RESULTS.md`
> (lowswing + lowswing_resonant fair fights).

---

## 0. The settled numbers (read this first)

| symbol | value | meaning | calibration / source |
|---|---|---|---|
| `E_bin` | **0.512 pJ/bit** | natural single-ended binary, full swing | DIRECT — `FINAL_VERDICT.md` correction 2 |
| `E_bin_ls` | **0.216 pJ/bit** | matched low-swing binary (same lever, binary radix) | DIRECT — `FINAL_VERDICT.md` correction 2 |
| `E_ter` | **0.081 pJ/bit** | ternary champion (low-swing × LC-resonant), *uniform null* | DIRECT — `ENERGY_RESULTS.md` §low-swing×resonant, case B1 |
| `E_null` | **≈ 0.05 pJ/trit** | cost of a null trit (rail equalization + receiver), swing-independent | DIRECT — fair-fight caveat (b); restated in low-swing×resonant caveat |
| `E_±1_fair` | **1.20 pJ/trit** | a ±1 trit at the *full-swing fair-fight* point | DIRECT — `ENERGY_RESULTS.md` RESOLUTION note |
| `E_±1_champ` | **≈ 0.167 pJ/trit** | a ±1 trit at the *champion* point | DERIVED — see §1.4 |
| `log₂3` | **1.585** | bits per trit | proved — `RadixEconomy.lean` |
| `log₃2` | **0.6309** | trits per bit → **36.9% fewer symbols** | proved — `FINAL_VERDICT.md` namespace row |

The win factors, checked: 0.512 / 0.081 = **6.32×**; 0.216 / 0.081 = **2.67×**. ✓

---

## 1. The energy model

### 1.1 The formula

For one memory access of width `W` bits:

```
E_access(scheme, W) = E_per_word(scheme, W) × (1 + overhead)

E_per_word(scheme, W) = E_bit(scheme) × W
```

Total for a program:

```
E_total(scheme) = Σ over accesses  E_bit(scheme) × W_access × (1 + overhead)
                = (1 + overhead) × E_bit(scheme) × Σ W_access
```

`Σ W_access` is the **total number of data bits moved** by loads and stores
(call it `n_bits`). So the model collapses to a single scalar per scheme:

```
E_total(scheme) = E_bit(scheme) × n_bits × (1 + overhead)
```

**This is the whole trick.** The scheme enters *only* through `E_bit(scheme)`.
The traffic `n_bits` is identical for both schemes — that is the fair fight
(same program, same accesses; only the wire differs). The energy advantage is
therefore exactly the ratio of the per-bit constants:

```
E_bin / E_ter  =  0.512 / 0.081  =  6.3×   (vs natural binary)
E_bin_ls / E_ter  =  0.216 / 0.081  =  2.67×  (vs matched low-swing binary)
```

…modulated by the null fraction (§1.4), which is where the win *moves*.

### 1.2 `E_per_word` — bits per word

`W` is the access width in bits, taken from the RISC-V access:

| access | width `W` | `E_per_word` binary (0.512) | `E_per_word` ternary (0.081) |
|---|---|---|---|
| `lb`/`lbu`/`sb` | 8 | 4.10 pJ | 0.648 pJ |
| `lh`/`lhu`/`sh` | 16 | 8.19 pJ | 1.30 pJ |
| `lw`/`lwu`/`sw` | 32 | 16.4 pJ | 2.59 pJ |
| `ld`/`sd` | 64 | 32.8 pJ | 5.18 pJ |

(`E_per_word = E_bit × W`, before overhead.)

### 1.3 The per-symbol vs per-bit correction (the trap this doc exists to avoid)

Ternary energy is measured **per trit (per symbol)**; binary per **bit**. They
are different units and must not be divided against each other directly:

- `1 trit = log₂3 = 1.585 bits`. To carry `W` bits, ternary sends only
  `W × log₃2 = 0.6309 W` symbols — **36.9% fewer**.
- The champion is quoted both ways: **0.128 pJ/trit = 0.081 pJ/bit**
  (`0.128 ÷ 1.585 = 0.0808`).

Two **correct** and one **wrong** way to compute a ternary word cost:

| form | expression | result (W=64) | verdict |
|---|---|---|---|
| per bit | `E_bit_ter × W = 0.081 × 64` | 5.18 pJ | ✅ correct |
| per symbol | `E_trit_ter × (W × log₃2) = 0.128 × 40.38` | 5.17 pJ | ✅ correct (same, modulo integer-trit rounding) |
| per symbol, wrong unit | `0.128 × 64` | 8.19 pJ | ❌ overstates by 1.585× (treats a trit as a bit) |

The reciprocal trap: comparing `0.128 pJ/trit` directly to `0.512 pJ/bit` gives
a fake 4.0× win; the honest 6.3× uses `0.081 pJ/bit`. **The model stores
everything in pJ/bit and applies the ÷1.585 once, inside the constant.**

### 1.4 The null-fraction toggle

`E_ter = 0.081 pJ/bit` is a **uniform-data average**: balanced ternary has
`p_null = 1/3` (the digits {−1, 0, +1} equiprobable), and the measured B1 cycle
averages one null/reset per three phases. The "free null" is *conditional*:
a null trit costs ~0.05 pJ, a ±1 trit costs more, so the average energy is a
function of how many symbols are null.

Per-trit energy as a function of null fraction `p_null`:

```
E_trit(p_null) = (1 − p_null)·E_±1  +  p_null·E_null
E_bit(p_null)  = E_trit(p_null) / log₂3
```

Two calibrated operating points (both collapse to the headline at `p_null = 1/3`):

| operating point | `E_±1` | `E_null` | uniform `E_trit` (1/3) | uniform `E_bit` | calibration |
|---|---|---|---|---|---|
| **fair-fight full swing** | 1.20 pJ/trit | 0.05 pJ/trit | 0.817 pJ/trit | 0.515 pJ/bit | both **DIRECT** (`ENERGY_RESULTS.md` RESOLUTION) |
| **champion (low-swing × resonant)** | **0.167 pJ/trit** | 0.05 pJ/trit | 0.128 pJ/trit | **0.081 pJ/bit** | `E_null` DIRECT; `E_±1` **DERIVED** |

`E_±1_champ = 0.167` is **back-solved** from the two DIRECT anchors
(`E_trit(1/3) = 0.128` and `E_null = 0.05`):

```
E_±1 = (E_trit(1/3) − p_null·E_null) / (1 − p_null)
     = (0.128 − (1/3)·0.05) / (2/3)  =  0.167 pJ/trit
```

It is **not** a separate measurement, and it hides the push/pull asymmetry the
B1 row reports (push 0.192 pJ, pull ≈ 0 pJ, reset −0.069 pJ). Treat 0.167 as a
model constant with ±~20% slack, not a lab number. If a clean per-symbol split
at the champion corner is wanted, it needs its own ngspice probe (push-only and
pull-only runs at VLC=0.28, L=40 µH) — flagged as open work, not assumed here.

The toggle's behaviour (this is the whole "win appears / disappears" knob):

| `p_null` | fair-fight `E_bit` | vs 0.512 | champion `E_bit` | vs 0.512 | vs 0.216 |
|---|---|---|---|---|---|
| 0.00 (no nulls) | 0.757 | **1.48× WORSE** | 0.105 | 4.9× | 2.05× |
| 0.33 (uniform) | 0.515 | 1.00× (tie) | **0.081** | **6.3×** | **2.67×** |
| 0.50 | 0.394 | 1.30× | 0.0685 | 7.5× | 3.15× |
| 0.80 | 0.177 | 2.9× | 0.0463 | 11× | 4.7× |
| 1.00 (all null) | 0.0315 | 16× | 0.0315 | 16× | 6.9× |

### 1.5 The break-even theorem (the invariant form)

Lean-proved (`proofs/…/Hexagon/EnergyModel.lean`):

```
ternary beats binary  ⇔  p_null > 1 − E_binary / E_ternary
```

Against the naive 5.36 pJ/trit cell this is a *real* threshold — **77.8% nulls**,
i.e. a loss in practice (`ENERGY_RESULTS.md` §break-even). At the 0.562 pJ winner
and at the champion corner `E_ternary < E_binary`, so the RHS is negative and
**the win is unconditional — nulls are pure upside on top** — the same sentence
`ENERGY_RESULTS.md` uses.

### 1.6 `overhead`

`(1 + overhead)` covers the non-data cost of a transaction that our per-bit
constant does not already price: address/command bus energy, ECC, DRAM refresh,
bus turnaround, and (optionally) the PTE page-walk traffic (§2.4).

- **Default: `overhead = 0.10`** (i.e. +10%). Tunable; the model reports energy
  with and without it so the overhead never hides the transport signal.
- **Instruction fetch is NOT in overhead.** Fetch is a large, workload-dependent
  term and, crucially, it *bypasses tinyrv's `load`/`store` hooks* (§2.4). It is
  accounted separately: `E_fetch = E_bit(scheme) × 32 × n_instr × (1 + overhead)`
  (one 32-bit fetch per executed instruction), reported as its own axis so data
  transport and fetch never get conflated.

---

## 2. Wiring into tinyrv's load/store path

### 2.1 What actually happens on a load/store in tinyrv

Every architectural load/store funnels through exactly two methods of `sim`
(`venv/lib/python3.13/site-packages/tinyrv/sim.py`):

- **`store(format, addr, data, notify=True, cond=True)`** — `_sb/_sh/_sw/_sd`,
  the `c._sw/_sd/_swsp/_sdsp`, the FP stores, and the AMO stores all call it.
  `format` is a `struct` char (`'B'/'H'/'I'/'Q'`), so **the width is
  `struct.calcsize(format) × 8` bits** — available at this seam and nowhere else.
  `cond` (the conditional-store guard) and misalignment/trap handling decide
  whether a write actually lands.
- **`load(format, addr, fallback=0, notify=True)`** — every load variant calls it.
  Same width story (`'b'/'B'`, `'h'/'H'`, `'i'/'I'`, `'q'/'Q'` → 8/16/32/64 bits).

Two existing hooks fire around the access, but they receive **only the address,
not the width**:

- `notify_loading(addr)` — called *before* the read (`sim.py:121`).
- `notify_stored(addr)` — called *after* the write (`sim.py:114`).

`virt` overrides both to route **MMIO** (UART/CLINT/PLIC); `elf_runner` overrides
`notify_stored` for HTIF/tohost. These overrides must keep working.

### 2.2 The module

A small importable module — working name `transport_model.py` — with two objects:

```
class TransportModel:
    # constants (§0, §1): the scheme table, log2(3), log3(2), overhead, p_null
    def record(self, addr, width_bits, is_store) -> None      # accumulate one access
    def null_fraction(self, p_null) -> None                    # toggle §1.4
    def report(self) -> TransportReport                        # totals + per-axis
    # pure functions (no state) for the formulas:
    #   per_word(scheme, width_bits, p_null) -> pJ
    #   break_even(E_bin) -> p_null_threshold
```

`record` bins each access by `(is_store, width_bits)` and — for the null
fraction — optionally by whether the transferred payload is "null" (§4.3). The
scheme energies are computed *lazily at report time*, so the identical traffic
stream is priced under **binary** (0.512 and 0.216) **and** **ternary** (0.081)
in one pass. The ratio `E_binary_total / E_ternary_total` is the headline.

### 2.3 Where to hook it (the seam)

tinyrv is installed as a read-only site-package; the model must subclass it, not
edit it. A `TransportCounted` mixin overrides `load`/`store` to capture the width
and delegate:

```
class TransportCounted:
    def store(self, fmt, addr, data, notify=True, cond=True):
        self._tx_pending = (struct.calcsize(fmt) * 8, True)
        return super().store(fmt, addr, data, notify=notify, cond=cond)
    def load(self, fmt, addr, fallback=0, notify=True):
        self._tx_pending = (struct.calcsize(fmt) * 8, False)
        return super().load(fmt, addr, fallback=fallback, notify=notify)
    def notify_loading(self, addr):   # record only if a real read landed
        super().notify_loading(addr)
        self._record_if_landed(addr, is_store=False)
    def notify_stored(self, addr):
        super().notify_stored(addr)
        self._record_if_landed(addr, is_store=True)
```

`_record_if_landed` consults the pending `(width, is_store)` and — for stores —
the fact that `notify_stored` only fires when `cond` was true and no trap/misalign
occurred (tinyrv already guarantees this: `notify_stored` sits after the pack on
line 114 and `notify_loading` after the fault checks on line 121). Concretely,
for `sim` and `virt`, `notify_*` firing *is* the "access landed" signal, so the
mixin records exactly what tinyrv notifies, now with width attached.

Then subclass the runners:

- **userspace**: `class counted_elf(TransportCounted, elf_runner)`.
- **system**: `class counted_virt(TransportCounted, virt)`.

MRO puts `TransportCounted` first so its `store`/`load`/`notify_*` wrap the
runner's, and the runner's `super().notify_*` MMIO routing still runs.

### 2.4 What must be excluded (or accounted separately)

The transaction stream is only honest if these are handled explicitly:

1. **MMIO, not transport.** `virt`'s UART/CLINT/PLIC traffic goes through the
   same `load`/`store` but is *not* the ternary wire we're modeling. Classify by
   address: only `addr >= ram_base` (0x80000000) counts as transport; MMIO
   accesses are recorded as a separate "not transport" counter and excluded from
   the energy.
2. **Instruction fetch bypasses `load`.** `sim.step` reads opcodes with
   `struct.unpack_from('I', …)` directly (`sim.py:343`), never through `load`.
   Fetch is ~1 × 32 bits per instruction and is a *majority* of total traffic on
   small loops — silently missing it would flatter the model. Count it as its
   own axis (§1.6), or add a hook at the fetch site (a one-line subclass override
   of `step`, or the existing `notify_loading` on the `pa(self.pc, access='x')`
   path).
3. **`copy_in`/`copy_out` bypass `load`/`store`.** ELF loading, the `write`
   syscall buffer, and `argv` packing use `copy_in`/`copy_out` (page-level
   copies). These are real memory traffic (bulk), uncounted by the hooks. For a
   microbenchmark this is a one-time setup cost; for a workload with `write`
   syscalls it must be added as a bulk-term (`E_bit × n_bytes × 8`).
4. **PTE page walks bypass `load`.** `pa()` reads page-table entries with
   `struct.unpack_from` directly (`sim.py:86`), not via `load`. With virtual
   memory on (Sv39/Sv32), each TLB miss is extra transport. tinyrv has no TLB
   (it walks every time), so this can dominate. **Recommendation for Phase 3:
   run bare-metal / M-mode with `satp=0`** (no paging) so the transport number is
   clean, and note paging as a separate follow-up.
5. **Internal `notify=False` accesses.** `elf_runner`'s HTIF ack
   (`store(..., notify=False)`) and `hook_exec`'s time-store use `notify=False`
   precisely to stay out of the notification path; the mixin respects that
   automatically (those accesses never hit `notify_*`). A couple of semihost
   reads call `self.load(...)` *without* `notify=False` (e.g. `elf_runner`
   `_ebreak`); they should be treated as harness bookkeeping, not workload
   transport — the address classifier (they touch the semihost arg block) or an
   explicit exclusion handles this.

### 2.5 The report

`report()` returns, for the recorded stream:

- `n_accesses`, `n_bits` (total, and per axis: loads / stores; per width 8/16/32/64).
- `n_fetch_bits`, `n_instr` (if fetch is counted).
- Per-scheme totals: `E_binary_natural`, `E_binary_lowswing`, `E_ternary(p_null)`.
- The ratio `E_binary_natural / E_ternary` and `E_binary_lowswing / E_ternary`.
- Per-axis breakdown (loads vs stores, and a per-width histogram) so the win can
  be attributed to *which* accesses carry it (pointer loads vs register spills).
- The same report with `overhead=0` and `overhead=0.10`, and a `p_null` sweep.

---

## 3. An honest note on WHEN the win materializes

The ternary transport win is **not** a blanket "3 is better than 2". It is two
separate levers with different conditions, per `FINAL_VERDICT.md` (transport row,
"radix-agnostic"):

1. **The low-swing × resonant lever (radix-agnostic).** This is *shared with
   binary* — matched low-swing binary already gets to 0.216 pJ/bit. Ternary's
   champion 0.081 stacks low swing *and* LC-resonant charge recovery, and wins
   **2.67×** over that matched binary at uniform null. This part is unconditional
   (no data dependence), but it is **not a ternary-specific win** — it is the
   price of *not also giving the binary wire the resonant lever*.
2. **The free null (ternary-specific, conditional).** Only balanced ternary has a
   data-bearing middle digit that costs ~0.05 pJ instead of a full swing. This
   helps **only on null-heavy / sparse data** (`meta_assumptions.md` A3). On
   dense, all-±1 data the null buys nothing and the ternary symbol cost (3-level
   SNR margin) is the thing you're paying for.

So the honest sentence for the model: **at uniform null the win is 6.3× / 2.67×;
it grows as `p_null` rises and shrinks as it falls, and at the full-swing
fair-fight point it actually inverts (1.48× worse at `p_null=0`) — the champion
corner keeps a smaller win even at `p_null=0` only because low-swing × resonant
is already below both binary references.** The model must expose `p_null` as a
first-class toggle so this is *visible*, not assumed.

The engine's real data is the reason this is interesting: pointer-heavy and
sparse/adjacency workloads are null-heavy (NULL terminators, sparse addresses,
empty edge lists), which is exactly the regime where the free null pays. §4
measures that rather than asserting it.

---

## 4. Fair-fight benchmark plan

### 4.1 The workload — the engine's actual memory pattern

The engine's core operation is a **graph walk**: `lattice-lookup` is an O(degree)
neighbor traversal over the `.latx` binary. The fair-fight workload mirrors that
pattern in RISC-V:

- **A. Pointer chase** (the primitive): follow a singly-linked list of `N` nodes
  scattered in memory; each step = one 64-bit pointer `ld` + a counter increment.
  Null-heavy via the NULL terminator and sparse heap addresses (a 64-bit heap
  pointer has 2–4 leading zero bytes).
- **B. Graph / adjacency walk** (the real thing): BFS or DFS over a node array
  `{id, next*, edges*[]}`; each hop = load the node, walk its edge list, follow
  an edge. Empty/short edge lists → NULL pointers → null-heavy traffic. This is
  the "lattice neighbor walk" in miniature.

Both are compiled to RV64 and run under `counted_elf` (userspace, no paging,
deterministic). Prefer B for the headline (it is the engine's pattern); A is the
control that isolates pointer-load behaviour.

### 4.2 Protocol (the fair fight)

1. **Deterministic single run.** Run the workload once with the recorder on;
   collect the full transaction stream `(addr, width, is_store)` + instruction
   count. tinyrv is deterministic given the same binary/input.
2. **Trace once, price twice (three times).** Replay the *identical* stream
   through `TransportModel` under (a) binary natural 0.512, (b) binary low-swing
   0.216, (c) ternary 0.081. The only difference is the scheme — this is what
   makes it a fair fight rather than two different programs.
3. **Sweep `p_null`.** Re-price the ternary stream at `p_null ∈ {0, 1/3, 0.5,
   0.8, measured}` to show the win appear/grow and (at the full-swing point)
   disappear.
4. **Report.** Total pJ per scheme, pJ/instruction, pJ per MiB moved, the ratios,
   and the per-axis (load/store, width) breakdown — with and without fetch,
   with and without overhead.

### 4.3 Measuring the null fraction (not just assuming it)

The model's `p_null` is a hypothesis knob. To make it a *measurement*, define a
concrete proxy over the captured payloads:

- **Primary proxy:** `p_null ≈ fraction of zero-valued bytes` in the transferred
  words (for loads: the loaded word; for stores: the stored word). A pointer
  chase / sparse graph shows a high, *measurable* zero-byte fraction.
- **Honest caveat:** balanced-ternary "null" is the digit 0 *after* the binary→
  ternary re-encoding, which is encoding-dependent and not a byte identity. The
  zero-byte fraction is a *proxy*, calibrated as: uniform random binary bytes →
  ~1/256 zero bytes (≈ 0 nulls), a 64-bit heap pointer → ~2–4/8 zero bytes. State
  the proxy explicitly and report both `p_null` (assumed) and the measured
  zero-byte fraction side by side; do not let the proxy silently become the
  physics.

### 4.4 Success criteria (honest, checkable)

- The ratio reproduced from the model on uniform data equals **6.3× / 2.67×**
  (sanity check — it must, since traffic cancels).
- The *benchmark* answer is the ratio **on the measured traffic + measured null
  fraction**, split per axis. Expected: pointer loads dominate and are
  null-heavy, so the ternary win should sit *above* 2.67×; if it lands at or
  below 2.67×, the "null-heavy workload" premise is falsified and we say so
  (the model is built to let that falsification happen, not to be flattered).
- Fetch is reported separately; the honest transport claim is the **data-only**
  number, with fetch stated alongside.

---

## 5. What this model is and is not

**Is:** a per-access bookkeeping layer that prices an identical, measured traffic
stream under three link schemes, with the null fraction as an explicit,
sweepable condition. It reuses the measured constants verbatim and applies the
per-symbol→per-bit correction once.

**Is not / does not:**

- It does **not** model the `3ⁿ` addressing win (`TAU_RISCV_PLAN` Phase 1) — that
  is a different axis (`FINAL_VERDICT.md`: names, not bits).
- It does **not** model compute energy (binary ALU, out of scope).
- It does **not** model latency, bandwidth, or the LC cell's speed tax
  (~48–100 Mtrit/s, 5–10× slower than the fast low-swing cell) — it is
  energy-only.
- It does **not** include a clean per-symbol {±1, null} split at the champion
  corner; `E_±1_champ = 0.167 pJ/trit` is **derived**, not measured (§1.4), and
  is the one number that needs a follow-up ngspice probe before it is quoted as
  fact.
- The measured constants are LEVEL=1 ngspice models with the standard caveats
  (no device mismatch, no body diodes; real SA offsets σ≈5–20 mV push the
  practical low-swing floor up to ~0.22–0.35 pJ/bit, `ENERGY_RESULTS.md`
  §low-swing). The model should carry a "pessimistic" preset at that floor so
  the honest range (~0.08–0.35 pJ/bit) is visible, not just the champion.

---

## Appendix A — worked example (64-bit load, `p_null = 1/3`, overhead 0.10)

```
W = 64 bits
n_bits for this access = 64

binary natural:   0.512 × 64 = 32.77 pJ   → ×1.10 = 36.0 pJ
binary low-swing: 0.216 × 64 = 13.82 pJ   → ×1.10 = 15.2 pJ
ternary (uniform): 0.081 × 64 =  5.18 pJ   → ×1.10 =  5.70 pJ

ternary, per-symbol form (sanity check):
  64 bits × log₃2 = 40.38 trits;  0.128 pJ/trit × 40.38 = 5.17 pJ  ✓
  (41 integer trits × 0.128 = 5.25 pJ — the packing rounding, ≤2%.)
```

## Appendix B — the null-fraction formulas, collected

```
E_trit(p_null)  = (1 − p_null)·E_±1 + p_null·E_null
E_bit(p_null)   = E_trit(p_null) / log₂3            (log₂3 = 1.585)
E_total(scheme) = E_bit(scheme, p_null) × n_bits × (1 + overhead)
break-even:     p_null > 1 − E_binary / E_ternary   (EnergyModel.lean)

champion constants:  E_±1 ≈ 0.167 (DERIVED), E_null ≈ 0.05 (DIRECT),
                     E_bit(1/3) = 0.081 (DIRECT)
fair-fight constants: E_±1 = 1.20 (DIRECT), E_null = 0.05 (DIRECT),
                     E_bit(1/3) = 0.515 (DIRECT)
```
