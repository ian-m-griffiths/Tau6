# The Hex MMU — the hex↔u32 address bijection as a RISC-V MMU

**Status:** DESIGN (2026-08-29). The math it rests on is PROVED; the MMU wiring is a
proposed integration, not yet built.

**Calibration.** Every claim below is labeled by how it is supported:
- **DIRECT** — proven in `proofs/lean-src/hexagon/Hexagon/*.lean` and mirrored in
  `rust-mirror/src/bijection.rs`.
- **STANDARD** — RISC-V privileged-architecture facts, stated from the spec
  (`docs/riscv spec/riscv-privileged.pdf`); no prior subagent wrote
  `docs/riscv_survey/privileged.md`, so §4 states the satp/PMA facts itself.
- **DESIGN** — the integration proposal (the hex region as a PMA region), which is
  the untested part.

**One-line thesis.** A contiguous physical-address range (a **PMA region**) is
reinterpreted as a hexagonal lattice of Eisenstein cells `(a,b) ∈ ℤ[ω]`, each cell
named by a u32 via the *proven* bijection `eisensteinToNat : Eisenstein ≃ Fin (2³²)`.
The "hex MMU" is the address-generation unit that (de)codes that bijection and walks
the 6 Z₆ unit directions — and it is built entirely out of cheap binary integer ops.

---

## 1. The address format

A **hex address** is a cell `(a,b)` — an Eisenstein integer `a + bω` with `ω = e^(iπ/3)`,
`ω² = ω − 1` (`Hexagon.Eisenstein`, `Hexagon/Conventions.lean`). Its **u32 representation**
is

```
u32 addr = eisensteinToNat (a, b) = toNat (a, b) = Nat.pair (signFold a) (signFold b)
```

### Encode — cell `(a,b)` → u32

1. **signFold** each coordinate `ℤ → ℕ` (`Hexagon.signFold`):
   `fold(z) = if z < 0 then 2·|z| − 1 else 2·|z|`
   (so `0, 1, −1, 2, −2, … ↦ 0, 1, 2, 3, 4, …`).
2. **Szudzik-pair** the two folds (`Nat.pair`, mathlib):
   `pair(x,y) = if x < y then y² + x else x² + x + y`.
3. The result is the u32 address.

### Decode — u32 → cell `(a,b)`

1. **Szudzik-unpair** (`Nat.unpair`, mathlib), via floor square root `s = ⌊√n⌋`
   (`Nat.sqrt`):
   `unpair(n) = if n − s² < s then (n − s², s) else (s, n − s² − s)`.
2. **signUnfold** each component `ℕ → ℤ` (`Hexagon.signUnfold`):
   `unfold(n) = if n even then n/2 else −(n+1)/2`  (division in ℕ, then cast).

So

```
eisensteinOfNat n = ( signUnfold (Nat.unpair n).1, signUnfold (Nat.unpair n).2 )
```

### The u32 box (exactly what fits)

`toNat_lt_two_pow_32` (`Hexagon/Bijection.lean`) proves: for coordinates in the box
`−2¹⁵ ≤ a, b ≤ 2¹⁵−1`, the address is `< 2³²`; `toNat_fin` places it in `Fin (2³²)`.
The box is **exact** — two u16 sign-folds fill u32 tightly:

```
(2¹⁶−1)² + (2¹⁶−1) + (2¹⁶−1) = 2³²−1 = u32::MAX  →  decodes to the corner (−2¹⁵, −2¹⁵)
```

(Why Szudzik and not Cantor: Cantor `(x+y)(x+y+1)/2 + y` needs 33 bits for two u16s;
Szudzik packs them into exactly 32. `pair_lt_two_pow_32` / `signFold_lt` back this.)

**Round-trip facts (DIRECT):** `signFold_signUnfold`, `signUnfold_signFold`,
`toNat_ofNat`, `ofNat_toNat`, `hexPairEquiv` (`ℤ × ℤ ≃ ℕ`), `toNat_bijective`,
`eisensteinEquiv` (`Eisenstein ≃ ℕ`), `eisensteinToNat_eisensteinOfNat`,
`eisensteinOfNat_eisensteinToNat` — all in `Hexagon/Bijection.lean`.

**Worked numbers** (hand-checked against `rust-mirror` tests):

| cell | fold | pair | u32 |
|---|---|---|---|
| `(0,0)` | `(0,0)` | `0` | `0` |
| `(1,0)` | `(2,0)` | `2²+2+0` | `6` |
| `(0,1)` | `(0,2)` | `2²+0` | `4` |
| `(1,1)` | `(2,2)` | `2²+2+2` | `8` |
| `(−1,−1)` | `(1,1)` | `1²+1+1` | `3` |
| `(−2¹⁵,−2¹⁵)` | `(65535,65535)` | `65535²+65535+65535` | `2³²−1` |

---

## 2. The datapath

The hex MMU implements exactly four integer primitives plus their composition. Every
one is cheap binary arithmetic; none needs ternary hardware.

| primitive | formula | ops | hardware | Lean / Rust twin |
|---|---|---|---|---|
| **signFold** `ℤ→ℕ` | `z<0 ? 2·\|z\|−1 : 2·\|z\|` | 1 cmp + 1 abs/neg + 1 shl + (1 sub) | ~3–4 gate levels, 1 cycle | `Hexagon.signFold` / `sign_fold` |
| **signUnfold** `ℕ→ℤ` | `n even ? n/2 : −(n+1)/2` | 1 and + 1 shr + (1 inc + 1 neg) | ~3–4 gate levels | `Hexagon.signUnfold` / `sign_unfold` |
| **Szudzik pair** | `a<b ? b²+a : a²+a+b` | 1 cmp + 1 mul + 1–2 add | 1 16×16 squarer + adder | `Nat.pair` (mathlib) / `pair` |
| **Szudzik unpair** | `s=⌊√n⌋; n−s²<s ? (n−s²,s) : (s,n−s²−s)` | 1 isqrt + 1 mul + 1 sub + 1 cmp + (1 sub) | 1 isqrt (serial ~16 cyc, or comb.) | `Nat.unpair` (mathlib) / `unpair` |
| **eisensteinToNat** | `pair(fold a, fold b)` | 2 fold + 1 pair | ≈ 2 cmp + 2 shl + 1 mul + ~3 add | `Hexagon.eisensteinToNat` / `to_u32` |
| **eisensteinOfNat** | `(unfold, unfold) ∘ unpair` | 1 unpair + 2 unfold | 1 isqrt + 1 mul + ~5 add/cmp/shift | `Hexagon.eisensteinOfNat` / `from_u32` |

**Cost asymmetry (the one real cost finding).** The *encode* direction (cell → u32 —
the load/store address) is a compare + square + add, **no sqrt**. The *decode* direction
(u32 → cell — needed for fault handlers, debug, or when the MMU only holds the u32) costs
one **integer square root** (`isqrt`) to unpair. That is the only non-trivial op in the
whole datapath, and it is still a small fixed-latency circuit (~16 serial shift-subtract
cycles, or a single-cycle combinational isqrt).

**Why the neighbor hop is nearly free.** If the MMU keeps the cell `(a,b)` resident (the
"cell cache" — the hex analog of a TLB entry), a step in direction `ωᵏ` is

```
(a,b) ← (a + Δa_k, b + Δb_k)          # two integer adds
```

and the u32 only needs re-encoding (`pair ∘ fold` = square + add) when the address crosses
the hex↔binary boundary (physical bus, page tables, DMA). Successive hops inside one
neighborhood therefore pay **zero** pairing. This is precisely the "neighborhood address
generation (the 6 Z₆ offsets of a cell) — i.e. a load/store path and an address unit" that
`docs/compute/CPU_INTEGRATION.md` §2 already names as the missing piece.

---

## 3. The Z₆ angle extraction and the neighbor offsets

There are **two distinct Z₆ uses**; keep them separate (conflating them is the main
over-claim to avoid).

### 3a. Address-decomposition Z₆ — `addr % 6` refines `addr % 2`

Read the u32 address itself as an integer. Its mod-6 residue is its **hex angle**; its
mod-2 residue is its **parity** (the XOR-kernel phase). `Hexagon/AddressTranslation.lean`
proves the refinement:

| theorem | statement | meaning |
|---|---|---|
| `angle_refines_parity` | `n % 2 = (n % 6) % 2` | the Z₆ angle *subsumes* the binary parity (it is parity × a 3-cycle) |
| `hex_angle_assembly` / `crt_assembly` | `n % 6 = (3·(n%2) + 4·(n%3)) % 6` | CRT reassembly: angle = phase × 3-cycle, inverse `3a+4b` |
| `hex_ring_growth` | `hexDiskCard (r+1) = hexDiskCard r + 6(r+1)` | the hex "ring" analog of the binary `2^k` ring: `3r²+3r+1` |

So the existing XOR kernel's `(phase, ring)` decomposition — parity = `(-1)^popcount`,
ring = highest set bit / `d >> 1` RG flow — has a hex refinement: `(angle, ring)` =
`(addr % 6, hex-disk radius)`, and `angle_refines_parity` is the exact theorem that the
angle carries everything parity carried, plus the 3-cycle. `address_translation` bundles
all four facts.

**Calibration:** this is a statement about the address *integer's own* residue class, not
about which spatial neighbor is selected. It says "the Z₆ residue of the address refines
the Z₂ residue of the address." The spatial direction is §3b.

### 3b. Spatial Z₆ — the 6 unit offsets `ωᵏ`

The six units of `ℤ[ω]` are `units = {⟨1,0⟩, ⟨−1,0⟩, ⟨0,1⟩, ⟨0,−1⟩, ⟨−1,1⟩, ⟨1,−1⟩}`
(`Hexagon/Rotation.lean`; `units_card` = 6, `units_closed_under_mul` = the Z₆ group).
A memory request to cell `(a,b)` with direction `ωᵏ` lands at `(a,b) + u_k` (component-wise
add — `Hexagon/Conventions.lean`'s `Add`), then re-encodes:

```
neighbor_addr(p, k) = eisensteinToNat ( a + Δa_k, b + Δb_k )
    where (a,b) = eisensteinOfNat p,  (Δa_k, Δb_k) = units[k]
```

The six offsets:

| k | unit ωᵏ | `(Δa, Δb)` | direction name | curl role (`CausalLattice.curl`) |
|---|---|---|---|---|
| 0 | `1`   | `(+1,  0)` | East        | — (pure Re, drops out) |
| 1 | `ω`   | `( 0, +1)` | North-East  | `+ w(z, z+⟨0,1⟩)` |
| 2 | `ω²`  | `(−1, +1)` | North-West  | `+ w(z, z+⟨−1,1⟩)` |
| 3 | `−1`  | `(−1,  0)` | West        | — (pure Re, drops out) |
| 4 | `−ω`  | `( 0, −1)` | South-West  | `− w(z, z+⟨0,−1⟩)` |
| 5 | `−ω²` | `(+1, −1)` | South-East  | `− w(z, z+⟨1,−1⟩)` |

(Recall `ω² = ω − 1 = ⟨−1, 1⟩`, `−ω² = ⟨1, −1⟩`; the two ±1 directions are the "pure Re"
axes and cancel out of the curl — the bivector `F1+F2−F4−F5` indexing in `rtl/grad_recon.v`.)

**Isotropy (DIRECT):** `CausalLattice.causal_isotropy` — every cell has exactly 6
unit-neighbors (the free Z₆ action); `units_rotate_invariant` / `pod_is_causal_diamond` —
rotation by any unit permutes the 6 directions, so the neighborhood is Z₆-invariant.

**Worked example — the 6 neighbors of address `6` (= cell `(1,0)`):**

| direction | neighbor cell | fold | u32 |
|---|---|---|---|
| `+1`   | `(2, 0)` | `(4,0)` → `4²+4+0` | `20` |
| `−1`   | `(0, 0)` | `(0,0)` | `0` |
| `+ω`   | `(1, 1)` | `(2,2)` → `4+2+2` | `8` |
| `−ω`   | `(1,−1)` | `(2,1)` → `4+2+1` | `7` |
| `+ω²`  | `(0, 1)` | `(0,2)` → `4+0` | `4` |
| `−ω²`  | `(2,−1)` | `(4,1)` → `16+4+1` | `21` |

So `neighbors(6) = {20, 0, 8, 7, 4, 21}` — non-contiguous in u32 space (the pairing is
deliberately *not* layout-preserving), but a 6-way neighborhood in cell space.

---

## 4. RISC-V privileged integration — the hex region is a PMA region

`docs/riscv_survey/privileged.md` was **not** written by any prior subagent, so the
relevant privileged facts are stated here (STANDARD, from `docs/riscv spec/riscv-privileged.pdf`):

- **PMA (Physical Memory Attributes).** The machine's physical address space is
  partitioned into *PMA regions* — platform-fixed ranges with attributes: main memory vs
  I/O; cacheability, coherence, idempotency, atomic (AMO) support for main memory; side
  effects / ordering for I/O. Software *discovers* PMAs (via `mconfigptr` / platform
  knowledge) and does **not** rewrite them at runtime.
- **PMP (Physical Memory Protection).** `pmpcfg*`/`pmpaddr*` grant/deny R/W/X per physical
  region (NAPOT / TOR / NA4 modes). PMP is *protection* (permission), orthogonal to PMA
  (attribute).
- **satp.** Supervisor address translation & protection. `satp.MODE` ∈ {Bare, Sv32, Sv39,
  Sv48, Sv57}; Bare = identity (VA = PA), SvNN = radix-tree page-table walk VA → PA. With
  SvNN, the PTW produces a **physical** address; PTE bits (V/R/W/X/U/G/A/D + PBMT/Svpbmt)
  carry *page* attributes that *overlay* PMA (a cacheable PMA page can be marked
  non-cacheable by its PTE; an I/O PMA cannot be made idempotent by a PTE).

**The design.** The hex reinterpretation is a property of the **physical** address, so it
belongs to the **PMA** layer — exactly the same category as "this range is I/O" — and is
neither a PTE/Svpbmt attribute nor a PMP permission. Concretely:

1. **Reserve a hex PMA region.** Declare a platform PMA entry: a contiguous physical range
   `[H_BASE, H_BASE + H_SIZE)` (H_SIZE ≤ 2³²; the natural choice is the full 4 GiB u32 box
   so `H_BASE + n` with `n ∈ Fin(2³²)` is cell `eisensteinOfNat n`). Its PMA type is
   "hex-cell main memory" (cacheable, idempotent, AMO-able — ordinary memory — *plus* the
   hex-interpretation flag).
2. **Compose with satp orthogonally.** Virtual→physical translation (SvNN) runs first and
   produces a u32 physical address `p`. The hex MMU then interprets `p − H_BASE` as a cell.
   The two layers are independent: *any* page can map a hex cell, and the hex semantics are
   invariant under which virtual page maps it — which is exactly why it is a PMA and not a
   PTE attribute.
3. **Two realizations, same math.**
   - **Minimum viable (software).** A RISC-V core already reads/writes the region as flat
     u32 memory. The kernel/compiler inlines `to_u32`/`from_u32` (`rust-mirror/src/bijection.rs`)
     and the 6-offset table for hex-structured load/store streams. No new hardware.
   - **Full realization (hardware).** The load/store unit gains a hex **address-generation
     unit**: a cell cache holding `(a,b)` for resident neighborhoods; per-hop it adds
     `(Δa_k, Δb_k)` and re-encodes `pair∘fold` only at the physical boundary. This is the
     "address unit" `CPU_INTEGRATION.md` §2 already calls for.
4. **Faults / discovery.** A faulting hex address decodes via `from_u32` (one isqrt) in the
   trap handler, mirroring how a PTW yields a physical address for `stval`. Software
   discovers the region's hex-ness from the platform PMA table (or a fixed convention), not
   from a CSR rewrite — consistent with PMA being platform-fixed.

---

## 5. Honest note — this is the ADDRESSING win, not an ALU

- **The win is the 3ⁿ namespace.** Hex cells (Eisenstein integers / balanced ternary)
  densify the *name* space: `CPU_INTEGRATION.md`'s scoreboard — "names/addresses: ternary
  wins exponentially, `(3/2)ⁿ`" — and the hex disk `3r²+3r+1` is the ring-count analog of
  the binary `2^k`. The hex MMU is the *address* realization of that: it names cells by
  Eisenstein integers and exposes the 6-way Z₆ neighborhood as integer offsets, so
  hex-structured computation addresses its natural unit (the cell, the pod) directly.
- **The mechanism is binary.** Every op in §2 — compare, shift, negate, square, add,
  isqrt — is ordinary binary integer arithmetic. The pairing arithmetic is the *cost* of
  the 3ⁿ namespace, paid in binary gates, not a ternary ALU. There is no ternary hardware
  anywhere on the address path (ternary belongs to *storage* — trits — and to the *compute*
  verdict, where it *loses* ~1.26–1.9× per bit).
- **Not an ALU, not a free lunch.** The bijection is **not** layout-preserving: hex
  neighbors are non-contiguous in u32 (see the `{20,0,8,7,4,21}` example), so a flat u32
  scan does *not* get hex locality for free — locality comes from walking the offset table,
  which is the point of the MMU. And `address % 6` / `% 2` (the angle/phase refinement,
  §3a) is a *structural decomposition of the address integer*, not a claim that
  `% 6` selects the spatial neighbor (§3b) — keep those two Z₆ uses distinct.
- **Still SPECULATION, not performance-proved.** `Hexagon/AddressTranslation.lean` proves
  the *structural* translation (angle ⊇ phase, address bijective, ring growth); it
  explicitly does **not** claim the hex kernel is performance-equivalent to the u32 XOR
  kernel. That comparison is the open item.

---

## Appendix A — theorem index (Lean → role in the MMU)

| theorem / def | file | backs |
|---|---|---|
| `signFold`, `signUnfold`, `signFold_signUnfold`, `signUnfold_signFold` | Bijection | the fold/unfold primitives (§2) |
| `toNat`, `ofNat`, `toNat_ofNat`, `ofNat_toNat`, `hexPairEquiv`, `toNat_bijective` | Bijection | the cell↔ℕ bijection (§1) |
| `eisensteinToNat`, `eisensteinOfNat`, `eisensteinEquiv` | Bijection | the u32 address itself (§1) |
| `pair_lt_two_pow_32`, `signFold_lt`, `toNat_lt_two_pow_32`, `toNat_fin` | Bijection | the u32 box is exact (§1) |
| `Nat.pair`, `Nat.unpair`, `Nat.sqrt`, `Nat.pairEquiv` | mathlib | Szudzik pairing + floor-sqrt unpair (§2) |
| `angle_refines_parity`, `hex_angle_assembly`, `address_translation` | AddressTranslation | angle refines parity (§3a) |
| `crt_assembly`, `val_crt`, `div3_truncation` | TernaryCrt | CRT inverse `3a+4b`; ÷3 = trit RG flow (§3a) |
| `hexDiskCard`, `hexDiskCard_succ` | HexDisk | ring growth `3r²+3r+1` (§3a) |
| `Eisenstein`, `norm`, `mul_comm`, `norm_mul` | Conventions | ω = e^(iπ/3), ω² = ω−1, additive offsets (§1, §3b) |
| `units`, `units_card`, `units_closed_under_mul` | Rotation | the 6 unit offsets, Z₆ group (§3b) |
| `flow`, `curl`, `causal_isotropy`, `causal_skew`, `diamond_balance`, `pod_is_causal_diamond` | CausalLattice | the 6-way neighborhood is isotropic + Z₆-invariant (§3b) |

## Appendix B — implementation checklist for the next phase

1. **Software twin (already done, reuse it):** `rust-mirror/src/bijection.rs` `to_u32` /
   `from_u32` are the reference encode/decode; the 200k-sample round-trip test is the
   acceptance test.
2. **Offset table as a constant:** emit the 6 `(Δa, Δb)` offsets from
   `Hexagon.units`; add a `neighbor_addr(p, k)` helper = `to_u32(a+Δa_k, b+Δb_k)`.
3. **Hardware address unit:** a cell-cache (TLB-like) of resident `(a,b)` + a
   `pair∘fold` encoder (1 squarer) + an `isqrt`-based `unpair` decoder for boundary
   crossings and faults. Verilog sketch lives alongside `rtl/ga_ops.v`.
4. **PMA entry:** reserve `[H_BASE, H_BASE+2³²)` in the platform PMA table as
   "hex-cell main memory"; document it next to the SvNN PTW so the compose order
   (translate → reinterpret) is explicit.
5. **Open (do not claim yet):** the performance comparison of the hex kernel vs the u32
   XOR kernel — the *structural* translation is proved; the *performance* equivalence is
   still SPECULATION.
