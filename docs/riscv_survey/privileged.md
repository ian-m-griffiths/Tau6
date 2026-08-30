# RISC-V Privileged Architecture — Memory Subsystem Facts

Source: `docs/riscv spec/riscv-privileged.pdf`
Spec: *The RISC-V Instruction Set Manual, Volume II: Privileged Architecture*, **Version 20260120 (Official Release, 2026-01-20)**.
All section numbers below are from that document. RVWMO's authoritative definition lives in **Volume I** (unprivileged); it is cross-referenced where used.

---

## 1. The CSR model, and `satp`

### CSR model (§2, "Control and Status Registers")

- CSRs are accessed via the **SYSTEM major opcode**, split into (a) atomic read-modify-write CSR instructions and (b) all other privileged instructions (§2 preamble, p. 13).
- The privileged architecture **requires the Zicsr extension**; which other privileged instructions are required depends on the feature set (§2).
- **§2.1** "CSR Address Mapping Conventions" defines the 12-bit CSR address space encoding (read/write vs read-only, privilege level of access).
- **§2.2** "CSR Listing" enumerates currently allocated CSRs: unprivileged (§2.2.1), supervisor-level (§2.2.2), hypervisor/VS (§2.2.3), machine-level (§2.2.4), and indirect Smcsrind mappings (§2.2.5).
- CSR field types: **WPRI** (Reserved Writes Preserve values, Reads Ignore values) §2.3.1; **WLRL** (Write/Read Only Legal Values) §2.3.2; **WARL** (Write Any values, Reads Legal values) §2.3.3.

### `satp` — Supervisor Address Translation and Protection (§12.1.11, pp. 124–126)

- CSR number **0x180**, listed as "Supervisor address translation and protection" (§2.2.2 listing, p. 17 of the CSR table).
- `satp` is an **SXLEN-bit read/write register** that "controls supervisor-mode address translation and protection." It holds:
  1. **PPN** — physical page number of the **root page table** = "its supervisor physical address divided by 4 KiB";
  2. **ASID** — address space identifier, "facilitates address-translation fences on a per-address-space basis";
  3. **MODE** — "selects the current address-translation scheme."

**Field layout (SXLEN=32)** — Figure 63:

| Bits | Field | Width |
|------|-------|-------|
| 31   | MODE (WARL) | 1 |
| 30:22 | ASID (WARL) | 9 |
| 21:0 | PPN (WARL) | 22 |

**Field layout (SXLEN=64)** — Figure 64 (for MODE = Bare, Sv39, Sv48, Sv57):

| Bits | Field | Width |
|------|-------|-------|
| 63:60 | MODE (WARL) | 4 |
| 59:44 | ASID (WARL) | 16 |
| 43:0 | PPN (WARL) | 44 |

- **Why PPN not PA:** "Storing a PPN in satp, rather than a physical address, supports a physical address space larger than 4 GiB for RV32." The `satp.PPN` field may not be able to hold all physical page numbers; platform standards may constrain it (§12.1.11).
- ASID and root-page-table base share one CSR so they "can be changed **atomically** on a context switch."
- **ASID width:** `ASIDLEN` (implemented ASID bits) is UNSPECIFIED and may be zero; least-significant bits implemented first. Max `ASIDMAX` = **9 for Sv32**, **16 for Sv39/Sv48/Sv57**.
- `satp` is **active** "when the effective privilege mode is S-mode or U-mode"; the translation algorithm may only begin from `satp` while it is active.
- Writing an **unsupported MODE** makes the entire write a no-op ("the entire write has no effect; no fields in satp are modified").

### `satp.MODE` encodings — Table 40

**SXLEN=32:**

| Value | Name | Description |
|-------|------|-------------|
| 0 | Bare | No translation or protection |
| 1 | Sv32 | Page-based 32-bit virtual addressing (§12.3) |

**SXLEN=64:**

| Value | Name | Description |
|-------|------|-------------|
| 0 | Bare | No translation or protection |
| 1–7 | — | Reserved for standard use |
| 8 | Sv39 | Page-based 39-bit virtual addressing (§12.4) |
| 9 | Sv48 | Page-based 48-bit virtual addressing (§12.5) |
| 10 | Sv57 | Page-based 57-bit virtual addressing (§12.6) |
| 11 | Sv64 | Reserved for page-based 64-bit virtual addressing |
| 12–13 | — | Reserved for standard use |
| 14–15 | — | **Designated for custom use** |

- **Bare** = "supervisor virtual addresses are equal to supervisor physical addresses, and there is no additional memory protection beyond the physical memory protection scheme" (§12.1.11).
- To select Bare, software must write **zero to the remaining fields** (bits 30–0 when SXLEN=32; bits 59–0 when SXLEN=64).
- **Custom-use seams at the CSR level** (§12.1.11):
  - SXLEN=32: `satp` encodings with MODE=Bare **and** ASID[8:7]=3 are "designated for custom use"; Bare + ASID[8:7]≠3 are reserved for future standard use.
  - SXLEN=64: all MODE=**14–15** encodings are "designated for custom use"; Bare encodings are reserved for future standard use.
  - "The remaining MODE settings are reserved for future use and **may define different interpretations of the other fields in satp**."

---

## 2. Sv32 address translation (§12.3, pp. 130–135)

Sv32 is the only paged scheme for SXLEN=32 (§12.1.11). "In this mode, supervisor and user virtual addresses are translated into supervisor physical addresses by traversing a **radix-tree page table**" (§12.3). It supports a **34-bit physical address space** (the resulting supervisor physical address is zero-extended to the platform's physical-address width).

### Virtual address layout — Figure 65 (32 bits)

| Bits | Field | Width |
|------|-------|-------|
| 31:22 | VPN[1] | 10 |
| 21:12 | VPN[0] | 10 |
| 11:0 | page offset | 12 |

"The 20-bit VPN is translated into a 22-bit physical page number (PPN), while the 12-bit page offset is untranslated."

### Physical address layout — Figure 66 (34 bits)

| Bits | Field | Width |
|------|-------|-------|
| 33:22 | PPN[1] | 12 |
| 21:12 | PPN[0] | 10 |
| 11:0 | page offset | 12 |

### Page tables and PTE format — Figure 67

- "Sv32 page tables consist of 2¹⁰ page-table entries (PTEs), each of four bytes." A page table is exactly one page (4 KiB) and must be **page-aligned**. The **root page table PPN is stored in `satp`** (§12.3.1).
- PTE (32 bits):

| Bits | Field | Width |
|------|-------|-------|
| 31:20 | PPN[1] | 12 |
| 19:10 | PPN[0] | 10 |
| 9:8 | RSW (reserved for supervisor software) | 2 |
| 7 | D (dirty) | 1 |
| 6 | A (accessed) | 1 |
| 5 | G (global) | 1 |
| 4 | U (user) | 1 |
| 3 | X (execute) | 1 |
| 2 | W (write) | 1 |
| 1 | R (read) | 1 |
| 0 | V (valid) | 1 |

- **Leaf detection:** "When all three [R, W, X] are zero, the PTE is a pointer to the next level of the page table; otherwise, it is a leaf PTE." Writable pages must also be readable (R=0 & W=1 reserved).
- R/W/X permission encoding — Table 41: `XWR` = 000 → pointer to next level; 001 → read-only; 011 → read-write; 100 → execute-only; 101 → read-execute; 111 → read-write-execute; 010 and 110 reserved.
- Faults: fetch → fetch page-fault; load/LR → load page-fault; store/SC/AMO → store page-fault.

### Page sizes

- **4 KiB pages** (leaf PTE at level 0, i.e. after two-level walk to VPN[0]).
- **Megapages: "Any level of PTE may be a leaf PTE, so in addition to 4 KiB pages, Sv32 supports 4 MiB megapages."** A megapage must be virtually **and** physically aligned to a 4 MiB boundary; otherwise page-fault. (§12.3.1)
  - **Note (correction to common shorthand):** Sv32 megapages are **4 MiB**, not 2 MiB. 2 MiB megapages appear in Sv39 (leaf at level 1). The 4 MiB figure follows directly from the layout: a level-1 leaf leaves VPN[0] (10 bits) untranslated → 2¹⁰ × 4 KiB = 4 MiB.

### Translation algorithm (§12.3.2, verbatim structure)

> A virtual address `va` is translated into a physical address `pa` as follows:
>
> 1. Let `a = satp.ppn × PAGESIZE`, and let `i = LEVELS−1`. (**For Sv32, PAGESIZE=2¹² and LEVELS=2.**) The satp register must be active, i.e., the effective privilege mode must be S-mode or U-mode.
> 2. Let `pte` be the value of the PTE at address `a + va.vpn[i] × PTESIZE`. (**For Sv32, PTESIZE=4.**) If accessing `pte` violates a PMA or PMP check, raise an access-fault exception …
> 3. If `pte.v=0`, or if `pte.r=0` and `pte.w=1`, or if any reserved bits/encodings are set, raise a page-fault exception.
> 4. Otherwise the PTE is valid. If `pte.r=1` or `pte.x=1`, go to step 5. Otherwise this PTE is a pointer to the next level: `i = i−1`; if `i<0` page-fault; else `a = pte.ppn × PAGESIZE` and go to step 2.
> 5. A leaf PTE has been reached. If `i>0` and `pte.ppn[i−1:0] ≠ 0`, this is a **misaligned superpage** → page-fault.
> 6–8. Check U/SUM/MXR, then R/W/X → page-fault/access-fault.
> 9. A/D bit handling (Svade raises page-fault; otherwise hardware sets A/D atomically).
> 10. **Success:** `pa.pgoff = va.pgoff`; if `i>0` (superpage) `pa.ppn[i−1:0] = va.vpn[i−1:0]`; `pa.ppn[LEVELS−1:i] = pte.ppn[LEVELS−1:i]`.

So for Sv32, a **4 KiB page** walks LEVEL 1 (VPN[1]) then LEVEL 0 (VPN[0]), producing PPN from two PTEs; a **4 MiB megapage** is a leaf at LEVEL 1 (VPN[1] PTE is a leaf), and VPN[0] (10 bits) passes through from VA to PA.

---

## 3. Physical Memory Attributes (PMA) and Physical Memory Protection (PMP)

### PMA (§3.6, pp. 64–69)

- **Definition:** "these properties and capabilities of each region of the machine's physical address space are termed **physical memory attributes (PMAs)**." (§3.6) They describe per-region: supported read/write/execute and access widths, atomic support, cacheability, coherence, and memory model.
- **PMA vs PMP:** "PMAs are inherent properties of the underlying hardware and rarely change during system operation. **Unlike physical memory protection values described in Section 3.7, PMAs do not vary by execution context.**" (§3.6)
- **How PMAs are declared:** "the attributes are known at system design time for each physical address region, and can be **hardwired into the PMA checker**. Where the attributes are run-time configurable, **platform-specific memory-mapped control registers** can be provided to specify these attributes at a granularity appropriate to each region on the platform." (§3.6)
- **PMA checker** is a separate hardware structure; "PMAs are checked for **any access to physical memory, including accesses that have undergone virtual to physical memory translation**." PMA violations manifest as instruction/load/store **access-fault** exceptions (distinct from page faults). (§3.6)
- PMA discovery is platform-specific: "many details are inherently platform-specific, as is the means by which software can learn the PMA values for a platform." (§3.6)

**Sub-categories (each its own PMA class):**

- **§3.6.1 Main Memory vs I/O:** "The most important characterization … is whether it holds regular main memory or I/O devices." Main memory has fixed required properties; "I/O devices can have a much broader range of attributes." Regions that don't fit regular main memory (e.g. scratchpad RAM) are categorized as I/O.
- **§3.6.2 Supported Access Type PMAs** — which access widths (8-bit … burst) and misaligned accesses are supported.
- **§3.6.3 Atomicity PMAs** — AMO levels: `AMONone`, `AMOSwap`, `AMOLogical`, `AMOArithmetic` (plus Zacas `AMOCASW/D/Q`); LR/SC reservability: `RsrvNone`, `RsrvNonEventual`, `RsrvEventual`.
- **§3.6.4 Misaligned Atomicity Granule PMA** — `MAGNN` natural-aligned power-of-two granule; accesses within a granule execute as one RVWMO memory operation.
- **§3.6.5 Memory-Ordering PMAs** — see below.
- **§3.6.6 Coherence and Cacheability PMAs** — coherence is a per-address property; cacheability is platform-level, managed by M-mode only, and "should not affect the software view … except for differences reflected in other PMAs."
- **§3.6.7 Idempotency PMAs** — main memory is idempotent; I/O idempotency specifiable per read/write; non-idempotent regions must not be speculatively or redundantly accessed.

### Can a region be a CUSTOM memory type / address interpretation? — YES (the seams)

The spec explicitly leaves room for a hex-addressed region (a physical address range whose interpretation differs from ordinary DRAM) in four independent places:

1. **PMA is platform-defined by design.** A PMA region is just "properties and capabilities of each region" fixed at design time or via platform-specific registers (§3.6). Nothing limits the set of region types; "many details are inherently platform-specific." A hex-addressed region is therefore legally a **custom PMA region** (its own address interpretation + memory-ordering/coherence/idempotency attributes), exactly like an I/O region or a scratchpad.
2. **`satp.MODE` custom encodings.** Table 40 designates MODE=14–15 (SXLEN=64) — and, for SXLEN=32, MODE=Bare + ASID[8:7]=3 — as "**designated for custom use**", and notes reserved MODE settings "may define different interpretations of the other fields in satp" (§12.1.11). This is the CSR-level seam for a **custom address-translation/interpretation scheme**.
3. **Svpbmt lets PTE bits override PMAs** (§12.8, "Page-Based Memory Types"): Sv39/48/57 leaf PTE bits 62–61 override the page's PMA (PMA / NC / IO / reserved). Crucially: "**Implementations may override additional PMAs not explicitly listed in Table 43**", and "**Future extensions may provide more and/or finer-grained control over which PMAs can be overridden**" (§12.8). This is the seam for a per-page **custom memory type**.
4. **Incoherent main memory has an "implementation-defined memory model"** (§3.6.5) — a custom region's ordering semantics are not forced into RVWMO/RVTSO.

### PMP (§3.7, pp. 70–74)

- **Purpose:** "An optional physical memory protection (PMP) unit provides per-hart machine-mode control registers to allow physical memory access privileges (**read, write, execute**) to be specified for each physical memory region." (§3.7)
- PMP values are checked **in parallel with** the PMA checks (§3.7).
- **Granularity** is platform-specific; the standard encoding supports regions as small as **4 bytes** (§3.7).
- **Scope:** "PMP checks are applied to all accesses whose effective privilege mode is S or U" — instruction fetches and data accesses in S/U, plus M-mode data accesses when `mstatus.MPRV=1` and MPP=S/U. Optionally they may also apply to M-mode accesses (via the lock bit). "PMP can grant permissions to S and U modes, **which by default have none**, and can revoke permissions from M-mode, **which by default has full permissions**." (§3.7)
- PMP violations are always trapped precisely.

**CSRs (§3.7.1):**

- "PMP entries are described by an 8-bit configuration register and one MXLEN-bit address register." Up to **64 entries**; implementations may implement **0, 16, or 64**, lowest-numbered first. All fields WARL; M-mode-only access.
- `pmpcfg0–pmpcfg15` hold `pmp0cfg–pmp63cfg` (RV32: 16 CSRs × 4 entries; RV64: 8 even-numbered CSRs × 8 entries; odd-numbered `pmpcfg1/3/…/15` illegal on RV64).
- `pmpaddr0–pmpaddr63`: RV32 encodes address bits **33:2** (34-bit PA); RV64 encodes bits **55:2** (56-bit PA).
- **Config register format** (8 bits) — Figure 34: bit 7 = **L** (lock), bits 6–5 = **A** (address-matching mode), bit 4 = 0 (reserved), bit 3 = **X**, bit 2 = **W**, bit 1 = **R**. R/W/X: "when set … permit read, write, and instruction execution"; R=0 & W=1 is reserved.

**Address matching (§3.7.1.1, Table 23):**

| A | Name | Description |
|---|------|-------------|
| 0 | OFF | Null region (disabled) |
| 1 | TOR | Top of range |
| 2 | NA4 | Naturally aligned four-byte region |
| 3 | NAPOT | Naturally aligned power-of-two region, ≥8 bytes |

- NAPOT encodes size in the low-order bits of `pmpaddr` (Table 24: `…y0`=NA4 4B, `…y01`=8B, `…y011`=16B, … up to 2^(XLEN+3)-byte ranges).
- TOR: entry i matches `pmpaddr[i-1] ≤ y < pmpaddr[i]` (entry 0 uses 0 as lower bound).

**Locking (§3.7.1.2):** L bit = locked; writes to that entry's cfg/addr ignored until reset. When L=1, R/W/X also enforced on **M-mode**; when L=0, M-mode matches succeed regardless of R/W/X.

**Priority (§3.7.1.3):** entries are "statically prioritized"; the **lowest-numbered matching entry** decides. The matching entry must match **all bytes** of the operation or it fails. If no entry matches: M-mode succeeds; S/U fails (when ≥1 entry implemented).

**PMP & paging (§3.7.2):** PMP checks apply to all physical accesses including **implicit page-table walks** (effective privilege S). After changing PMP settings, M-mode must execute **`SFENCE.VMA` with rs1=x0 and rs2=x0** to synchronize with the MMU/translation caches.

---

## 4. Memory ordering — RVWMO (base model)

The authoritative definition of **RVWMO ("RISC-V Weak Memory Ordering")** is **Volume I, Chapter 18** ("RVWMO Memory Consistency Model", v2.0); the privileged spec's §3.6.5 classifies which model a region obeys. RVWMO is a *weak* memory model defined in terms of a **global memory order** — "a total ordering of the memory operations produced by all harts"; any execution whose global memory order satisfies the model's constraints is legal (Vol. I §18.1). A memory operation is a load, a store, or both (an AMO), and every operation is **single-copy atomic**. Under RVWMO, a single hart's own code appears to execute in order, but another hart may observe that hart's operations in a different order, so cross-hart ordering requires explicit synchronization — the **`FENCE`** instruction and the **`.aq`/`.rl` (acquire/release)** annotations on atomics — enforced by the "Preserved Program Order" (PPO) rules over syntactic dependencies (address/data/control). **What a custom memory region must honor** (privileged spec §3.6.5): coherent main-memory regions are always **RVWMO or RVTSO**; **incoherent main memory has an implementation-defined memory model**; and I/O regions are either *relaxed* (ordered like RVWMO) or *strong* (program order, via numbered ordering channels 0 = point-to-point, 1 = global). So a hex-addressed custom region can declare itself relaxed/RVWMO-like, strongly-ordered-I/O, or implementation-defined — but whichever it declares, it must be single-copy-atomic per operation and must not expose speculative/redundant accesses if marked non-idempotent (§3.6.7).

---

## 5. M-mode vs S-mode (one line each)

- **M-mode (machine mode)** = highest, only *mandatory* privilege level (§1.2); "the only mode that has unfettered access to the whole machine" — it runs **without address translation** (accesses use machine-level physical addresses directly; `satp` is only "active" when the effective privilege mode is S or U, §12.1.11; `mstatus.MPRV` can temporarily switch the *effective* privilege for load/store emulation, §3.1.6.4).
- **S-mode (supervisor mode)** = "intended for conventional … operating system usage" (§1.2); its memory view is governed by **`satp`** — MODE=Bare gives an identity map (VA=PA) while any paged MODE (Sv32/Sv39/Sv48/Sv57) enables the page-table walk, and all resulting accesses are then filtered through PMP (§12.1.11, §3.7).
