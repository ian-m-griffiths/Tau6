# Average Load of the Tau Engine's Address Space

**2026-08-30.** Given the actual, already-run workloads, how much of the hex
address space does the Tau engine *actually* touch per operation? This pins the
"average load" to the two concrete instruction streams — the SoC test program
(`scripts/gen_program_tau.py` → `rtl/program_tau.hex`, 35 RV32I instructions) and
the GA mix (`scripts/xlattice.py`, 15 custom-0 instructions) — and counts
hex addresses, trits of namespace, and peak-vs-average usage.

**Headline (one line).** The average Tau load lives in **7 cells (a single pod)
= 3 trits ≈ 27 names**, out of a **21-trit (10.5-billion-name) u32 box** — the
`3ⁿ` win is **~99.99999997 % unused headroom** in every workload that actually runs.

**Calibration legend.** Every claim is tagged:
- **DIRECT** — read verbatim from a file (an instruction count, a `reg [...] cells [0:63]`
  declaration, an energy constant).
- **DERIVED** — arithmetic on DIRECT numbers (an average, a `⌈log₃N⌉`, a fraction).
- **SPECULATION** — a judgment about what the numbers *mean* (e.g. "the engine is
  not address-space-bound"), clearly labeled as interpretation, not measurement.

---

## 0. The four layers of "address space"

The task's four terms map onto four *different* widths. Keeping them apart is the
whole job, because conflating them is what produces a "we use the full u32 box"
over-claim.

| layer | size | width (bits) | width (trits) | source |
|---|---|---|---|---|
| **hex cell (a,b)** | 2³² cells (a,b ∈ [−2¹⁵, 2¹⁵−1]) | 2 × 16 | — | DIRECT: `hexaddr.py` `HALF`, `in_u32_box` |
| **u32 box (3ⁿ namespace)** | 2³² = 4.295×10⁹ names | 32 | **21** (⌈log₃2³²⌉) | DIRECT: `NAMESPACE_TABLE.md` row "32 → 21 trits" |
| **7-cell pod** | 7 cells (center + 6 ωᵏ neighbors) | — | ⌈log₃7⌉ = 2 | DIRECT: `hex_pod_addr.v`, `pod()` in `hex_memory.py` |
| **64-cell field store** | 64 cells × 24-bit ternary | 6 (index) | **4** (⌈log₃64⌉) | DIRECT: `hex_field_accel.v` `reg [23:0] cells [0:63]` |

DERIVED (the widths): `⌈log₃2³²⌉ = ⌈32·log₃2⌉ = ⌈20.19⌉ = 21`; `⌈log₃64⌉ = 4`;
`⌈log₃7⌉ = 2`. The "3ⁿ namespace" of the thesis is realized concretely as the u32 box:
2³² binary names ≈ 21 trits (`3²¹ = 1.046×10¹⁰`, 2.44× the u32 box — DIRECT
`NAMESPACE_TABLE.md`). So "the 3ⁿ win" == "21 trits of headroom over 32 bits", and the
question is how many of those 21 trits the average load actually exercises.

---

## 1. The average instruction — the actual mixes

### 1a. The SoC field-calculus + transport mix (35 instructions)

DIRECT, counted from the `p.append(...)` sequence in `gen_program_tau.py` (and
byte-identical in `rtl/program_tau.hex`, 35 lines):

| op | count | fraction | hex cells touched (field store) |
|---|---:|---:|---:|
| `lui` (base setup) | 2 | 5.7 % | 0 |
| `addi` (constant) | 5 | 14.3 % | 0 |
| `beq` (spin) | 1 | 2.9 % | 0 |
| **pod write** — `sw cells[20], cells[8]` | 2 | 5.7 % | 1 each (2 total) |
| **center write** — `sw center=6` | 1 | 2.9 % | 0 (sets center *register*) |
| **div read** — `lw div` (triggers TGRAD) | 1 | 2.9 % | 7 (gather) |
| **curl read** — `lw curl` | 1 | 2.9 % | 0 (latched from div read) |
| ofit read — `lw ofit` | 1 | 2.9 % | 0 |
| **TRECON store** — `sw TRECON` | 1 | 2.9 % | 7 (scatter) |
| **pod read** — `lw cells[20], cells[8], cells[6]` | 3 | 8.6 % | 1 each (3 total) |
| **TRELAX step** — `sw TRELAX` | 1 | 2.9 % | 8 (7 gather + 1 write) |
| **link transmit** — `sw word` | 2 | 5.7 % | 0 (1 × 24-bit/12-trit word each) |
| link nulls read — `lw nulls` | 2 | 5.7 % | 0 |
| link energy read — `lw energy` | 2 | 5.7 % | 0 |
| data RAM store (results) — `sw mem[0x20..0x44]` | 10 | 28.6 % | 0 (binary RAM) |
| **total** | **35** | 100 % | **27** |

DIRECT sums:
- register-only (lui + addi + beq) = **8 / 35 = 22.9 %**.
- memory-touching (sw + lw) = **27 / 35 = 77.1 %** (17 stores + 10 loads).
- field-store cell accesses = 2 + 7 + 7 + 3 + 8 = **27**.

(The coincidence that both the bus-transaction count and the cell-access count are 27
is accidental — the div/curl/ofit reads add 3 bus transactions with 0 cells, while
TGRAD's 7-cell gather and TRELAX's 8-access step are single bus transactions. Both are
DERIVED from the table above; do not read them as the same metric.)

### 1b. The GA mix (15 instructions)

DIRECT, from the `prog` list in `xlattice.py` `main()`:

| op | count | fraction |
|---|---:|---:|
| `LDI` | 4 | 26.7 % |
| `TROT` | 2 | 13.3 % |
| `TADD` | 2 | 13.3 % |
| `TCONJ` | 2 | 13.3 % |
| `TDOT` | 1 | 6.7 % |
| `TWEDGE` | 2 | 13.3 % |
| `TSYMDOT` | 2 | 13.3 % |
| **total** | **15** | 100 % |

The GA triple (TDOT + TWEDGE + TSYMDOT) = **5 / 15 = 33.3 %**. Every op is a
register-register custom-0 instruction on the PCPI/CFU port (`xlattice.py` `_custom0`):
**zero hex cells, zero memory addresses** — only the 32×32-bit register file (5-bit
register index). This is the crucial negative result for the average-load question:
the geometric-algebra workload does **not** touch the 3ⁿ namespace at all.

---

## 2. Average addresses touched per operation

**Per op class** (DIRECT from `hex_field_accel.v` gather/scatter + `demo.py`'s
"3 pod ops × 7 cells × 32 bits"):

| op class | cells touched | bits moved (hex store) |
|---|---:|---:|
| pod op: **TGRAD** (gather) | 7 | 7 × 32 = 224 |
| pod op: **TRECON** (scatter) | 7 | 7 × 32 = 224 |
| pod op: **TRELAX** (gather+write) | 7 read + 1 write = 8 accesses (7 distinct) | 8 × 32 = 256 |
| scalar cell write / read | 1 | 32 |
| link transmit | 0 (1 × 24-bit word) | — |
| GA op (TDOT/TWEDGE/…) | 0 | — |

**Average over the 35-instruction SoC mix** (DERIVED):
- hex cells/instruction = 27 / 35 = **0.77 cells/instruction**.
- hex-memory traffic = 27 × 32 bits = 864 bits → **24.7 bits/instruction**.
- distinct cells in live use = **7** (the pod `{0, 4, 6, 7, 8, 20, 21}` — DIRECT from
  `hex_memory.py`: `neighbors(6) = {20, 8, 4, 0, 7, 21}`).

**Average over the 3-pod-op field-calculus demo** (`demo.py`) — the cleanest "engine"
load: **7 cells/pod-op, 224 bits/pod-op** (DIRECT from `demo.py` line 80:
"3 pod ops x 7 cells x 32 bits" = 672 bits).

**Average over the GA mix** (DERIVED): **0.0 cells/instruction** — the GA program's
address-space usage is identically zero.

**Peak concurrency**: a single pod op touches **7 cells at once** (TRELAX = 8 accesses).
That is the peak address footprint of any operation in the implemented workloads.

---

## 3. How much of the 3ⁿ namespace is actually exercised

**Trit widths in play** (DERIVED, `⌈log₃N⌉`):

| object | names N | width (trits) | note |
|---|---:|---:|---|
| live working set (addresses 0..21) | 22 | **3** (3³=27 ≥ 22) | the actual load |
| field store capacity | 64 | **4** (3⁴=81 ≥ 64) | `cells[0:63]` |
| u32 box (full 3ⁿ namespace) | 2³² | **21** | `NAMESPACE_TABLE.md` |

**Live cells vs available:**

| denominator | numerator | fraction |
|---|---:|---:|
| field store (64 cells) | 7 live | **10.9 %** |
| u32 box (2³² = 4.295×10⁹) | 7 live | **1.63×10⁻⁹** |
| u32 box | 22 addresses used | 5.12×10⁻⁹ |
| 3²¹ names (1.046×10¹⁰) | 27 names (=3³) | **2.58×10⁻⁹** |

**Peak vs average namespace:**
- **average** = 3 trits (the pod's addresses span 0..21 → 5 bits).
- **peak** = 3 trits too (the largest address any op touches is 21; a pod op never
  leaves the 5-bit range).
- **store capacity** = 4 trits (64 cells) — never even filled (7/64 used).
- **available** = 21 trits (the u32 box).

So **18 of the 21 trits are never exercised** — `3¹⁸ = 3.87×10⁸` × headroom in names.
The engine's average load uses **14.3 % of the trit *width*** (3/21) but only
**2.58×10⁻⁹ of the *names*** (27/1.046×10¹⁰), because the namespace is exponential.

---

## 4. The honest picture

**The engine is NOT address-space-bound — it is address-space-idle.** (SPECULATION,
but directly forced by the DERIVED numbers above.)

- Every implemented workload's working set is **one 7-cell pod = 3 trits**. The
  field-calculus demo (a), the SoC test (d), and the hexaddr neighbor walk (c) all
  live in addresses 0..21 — 5 bits, 3 trits. The 64-cell field store is only
  **10.9 % occupied**, and the field store itself is 4 trits vs the 21-trit u32 box.
- The GA mix (b) touches **zero** hex addresses — it is pure register-file compute,
  and `xlattice.py` is explicit that "the ternary ALU is NOT where the win is."
- The `3ⁿ`/`2ⁿ` exponential (1.86×10¹¹ at n=64, DIRECT `FINAL_VERDICT.md`/`NAMESPACE_TABLE.md`)
  is a **capacity** statement about the address *format*, not a **utilization** statement
  about the address *load*. The format can name 10.5 billion cells; no current workload
  names more than 22.

**What would actually fill the namespace** (SPECULATION): a real heat-equation solve —
`TAU_RISCV_STATUS.md`'s "TRELAX over a full field … cell-by-cell" — is the one
already-named workload that would grow the live set past one pod. Even that, at
64 cells it saturates the field store (4 trits); reaching the u32 box (21 trits)
would require a field store of 2³² cells, which does not exist in the current RTL
(`cells[0:63]` is hardwired to 64).

**Bottom line.** Under average load the engine touches **~0.77 hex cells/instruction**
(7 cells for each pod op, 0 for each GA/link/RAM op), which is **3 trits ≈ 27 names**
of a **21-trit ≈ 10.5-billion-name** namespace — **99.99999997 % of the 3ⁿ win is
unused headroom**, and the honest reading is that the addressing win is real but
**latent**: the current workloads are too small to spend it.

---

## Calibration summary

| claim | calibration |
|---|---|
| 35-instruction SoC mix, 27 memory ops, 8 register-only | DIRECT (`gen_program_tau.py`, `program_tau.hex`) |
| 15-instruction GA mix, 33.3 % TDOT/TWEDGE/TSYMDOT | DIRECT (`xlattice.py` `main()`) |
| pod op = 7 cells, 224 bits; TRELAX = 8 accesses | DIRECT (`demo.py`, `hex_field_accel.v`, `hex_pod_addr.v`) |
| field store = 64 cells × 24-bit ternary | DIRECT (`hex_field_accel.v` `cells[0:63]`) |
| live set = pod(6) = {0,4,6,7,8,20,21}, 7 cells, max 21 | DIRECT (`hex_memory.py` `neighbors(6)`) |
| 0.77 cells/instruction; 24.7 bits/instruction | DERIVED (27/35; 864/35) |
| widths 3 / 4 / 21 trits; 10.9 % / 1.6×10⁻⁹ fractions | DERIVED (⌈log₃N⌉; ratios) |
| "not address-space-bound; the 3ⁿ win is latent" | SPECULATION (interpretation of the above) |
