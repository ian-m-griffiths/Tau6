# tinyrv internals — exact hook points for hex memory + Xlattice custom extension

**Survey date:** 2026-08-29 (integration map for `docs/TAU_RISCV_PLAN.md` Phase 1–2).

**Source:** `venv/lib/python3.13/site-packages/tinyrv/` (package version installed in this repo).

tinyrv is ~1,000 lines of Python (excluding the auto-generated `opcodes.py`, which is
582 KB of one-line dicts). It is a *single-file* core simulator: `sim.py` holds the
memory, register file, CSRs, MMU, and the entire instruction set as `_<name>` methods.
Everything else is a thin wrapper.

| file | role |
|---|---|
| `__init__.py` | re-exports `sim.*` + `dump.decoder` |
| `common.py` (47 ln) | `decode`, `rvop`, `iregs`/`fregs`, **`customs`**, `zext/sext/xfmt` |
| `opcodes.py` (9 ln, auto-gen) | `opcodes` table, `arg_bits`, `csrs`, `mask_match_rv32/64` |
| `sim.py` (353 ln) | `class sim`: memory, MMU, regfile, CSRs, all op handlers, dispatch |
| `system.py` (234 ln) | `class virt(sim)`: qemu-style "virt" machine + UART/CLINT/PLIC MMIO |
| `user.py` (192 ln) | `class elf_runner(sim)`: ELF loader, linux syscalls, semihosting, HTIF |
| `fpu.py` (238 ln) | IEEE-754 soft-float (`f32`, `f64`) |
| `dump.py` (19 ln) | `rvsplitter`/`decoder`: disassembler over a binary/hex blob |

---

## 1. The memory model

### 1.1 Representation — a sparse dict of 2 MiB `bytearray` pages

`sim.py:50` (inside `sim.__init__`):

```python
self.pc, self.x, self.f, self.csr, self.lr_res_addr, self.cycle, self.plevel, self.mem_psize, self.mem_pages = 0, self.rvregs(self.xlen, self), self.rvfregs(64, self), self.rvcsrs(self.xlen, self), -1, 0, 3, 2<<20, collections.defaultdict(functools.partial(bytearray, 2<<20+2))  # 2-byte overlap for loading unaligned 32-bit opcodes
```

- `self.mem_psize = 2<<20` → `2**21` = **2 MiB** page size.
- `self.mem_pages` is a `collections.defaultdict` whose factory is
  `functools.partial(bytearray, 2<<20+2)` → each page is a `bytearray` of
  `2**21 + 2 = 2_097_154` bytes (the `+2` is overlap for reading a 4-byte opcode that
  straddles a page boundary — see the trailing comment).
- Flat, byte-addressable, lazily allocated (a page materialises on first touch).
  **There is no memory class** — it is literally a dict keyed by page-aligned address.
- **No MMIO, no base-address notion in the core.** The core `sim` only knows this dict;
  devices are bolted on by the `virt` subclass via the `notify_*` hooks (§2.4).

### 1.2 The address → (page, offset) mapping — the single lowest-level seam

`sim.py:79`:

```python
def page_and_offset(self, addr): return self.mem_pages[addr&~(self.mem_psize-1)], addr&(self.mem_psize-1)
```

Key = `addr & ~(2**21 - 1)` (page-aligned), offset = `addr & (2**21 - 1)`. This is the
**one function every memory access eventually passes through** — data loads/stores,
instruction fetch, page-table (PTE) reads/writes, and bulk `copy_in`/`copy_out`.

### 1.3 `load` / `store` — widths and endianness

`sim.py:107-124`:

```python
def store(self, format, addr, data, notify=True, cond=True):
    if not cond: return
    try: addr = self.pa(addr, access='w')
    except Trap as t: self.mtrap(t.tval, t.cause); return
    if self.trace_log is not None: self.trace_log.append(f'{xfmt(struct.calcsize(format)*8, data)}->mem[{xfmt(self.xlen, addr)}]')
    if self.trap_misaligned and addr&(struct.calcsize(format)-1) != 0: self.mtrap(addr, 6)
    else: struct.pack_into(format, *self.page_and_offset(zext(self.xlen,addr)), data)
    if notify: self.notify_stored(zext(self.xlen,addr))
def load(self, format, addr, fallback=0, notify=True):
    if self.trap_misaligned and addr&(struct.calcsize(format)-1) != 0: self.mtrap(addr, 4); return fallback
    if zext(self.xlen, addr) & (1<<63): self.mtrap(addr, 5); return fallback
    addr = zext(self.xlen, addr)
    try: addr = self.pa(addr, access='r')
    except Trap as t: self.mtrap(t.tval, t.cause); return fallback
    if notify: self.notify_loading(addr)
    data = struct.unpack_from(format, *self.page_and_offset(addr))[0]
    if self.trace_log is not None: self.trace_log.append(f'mem[{xfmt(self.xlen, addr)}]->{xfmt(struct.calcsize(format)*8, data)}')
    return data
```

Widths are expressed as Python `struct` format codes, chosen by each op handler:

| width | store handler | format | load handler | format |
|---|---|---|---|---|
| byte | `_sb` (`sim.py:137`) | `'B'` | `_lb` (`:141`)/`_lbu` (`:142`) | `'b'`/`'B'` |
| half | `_sh` (`:138`) | `'H'` | `_lh` (`:143`)/`_lhu` (`:146`) | `'h'`/`'H'` |
| word | `_sw` (`:139`) | `'I'` | `_lw` (`:144`)/`_lwu` (`:147`) | `'i'`/`'I'` |
| dword | `_sd` (`:140`) | `'Q'` | `_ld` (`:145`) | `'q'` |

- Signed `b/h/i/q`; unsigned `B/H/I/Q`. Size = `struct.calcsize(format)`.
- **Endianness = native** (`struct` default, no `<`/`>` prefix). On the little-endian
  hosts this repo runs on that is little-endian; note that the *disassembler* path
  (`dump.py:5,11`) uses explicit `'<H'`/`'<I'`, so instruction decode is hard-little-endian
  while data access is native-endian — a real inconsistency if hex memory ever moves to a
  big-endian host.
- Misaligned accesses trap (cause 6 store / 4 load) only when `trap_misaligned=True`
  (default in core `sim`, disabled by `virt` at `system.py:104` and by `elf_runner`
  default).
- `fallback` is the value returned on trap — used to leave `rd` unchanged on a faulting
  load.

### 1.4 Base address / MMIO — only in the `virt` subclass

`system.py:112-116`:

```python
self.ram_base = 0x8000_0000
self.clint_base, self.clint = 0x200_0000, clint(self)
self.plic_base, self.plic = 0xc00_0000, plic(self)
self.uart_base, self.uart = 0x1000_0000, uart8250(self)
```

MMIO is **not** a memory-map table in `sim`. Devices are Python objects (`uart8250`,
`plic`, `clint` in `system.py`) that get routed to from the `notify_*` hooks by address
comparison (§2.4). The flat byte page is still written first; the device is a side-channel
that *observes* the write or *injects* the read value.

---

## 2. Address translation

### 2.1 `pa` — virtual → physical (Sv32/Sv39)

`sim.py:80-106`. This is the real MMU.

```python
def pa(self, addr, access='w'):
    pl = (self.csr._csr[self.MSTATUS]>>11)&3 if self.plevel==3 and self.csr._csr[self.MSTATUS]&0x00020000 and access!='x' else self.plevel
    satp, sum_bit, mxr_bit = self.csr._csr[self.SATP], (self.csr._csr[self.MSTATUS]>>18)&1, (self.csr._csr[self.MSTATUS]>>19)&1
    if pl==3 or satp==0: return addr  # no virtual memory
    ...
    return (addr & (0xfff|superpage_mask)) | (pte<<2)&pte_paddr_mask
```

- Walks Sv32 (`xlen==32`) or Sv39 (`xlen==64`) page tables, raises `Trap` on fault.
- **If `pl==3` (machine mode) or `satp==0`, returns `addr` unchanged** — the critical
  early-out (`sim.py:83`). This is why the emulator runs flat out of the box.
- Reads/writes PTE entries through `self.page_and_offset(...)` directly (`sim.py:86,105`),
  i.e. page tables live in the *same* flat dict as data.
- `access` is `'w'`/`'r'`/`'x'` (determines fault cause 15/13/12 and which PTE bit is
  required).

### 2.2 `page_and_offset` / `page_and_offset_iter` / `copy_in` / `copy_out`

```python
# sim.py:68-72
def page_and_offset_iter(self, addr, nbytes, doffset=0):
    while nbytes > doffset:
        page, poffset = self.page_and_offset(zext(self.xlen, addr+doffset))
        yield page, poffset, doffset, min(nbytes-doffset, self.mem_psize - poffset + 2)  # 2 bytes more to fill overlap
        doffset += min(nbytes-doffset, self.mem_psize - poffset)
# sim.py:73-74
def copy_in(self, addr, bytes):
    for page, poffset, doffset, chunk in self.page_and_offset_iter(addr, len(bytes)): page[poffset:poffset+chunk] = bytes[doffset:doffset+chunk]
# sim.py:75-78
def copy_out(self, addr, nbytes):
    data = bytearray(nbytes)
    for page, poffset, doffset, chunk in self.page_and_offset_iter(addr, nbytes): data[doffset:doffset+chunk] = page[poffset:poffset+chunk]
    return data
```

- `page_and_offset_iter` is the only place that crosses page boundaries; it yields a
  `chunk` with `+2` overlap so an unaligned access at the tail of a page has 2 spare bytes
  (mirroring the `bytearray` `+2`).
- `copy_in`/`copy_out` are the bulk byte movers. They do **not** go through `pa()` (no MMU),
  and are used by: ELF loading (`user.py:16`), the bootloader stub (`user.py:61,73`), DTB
  placement (`system.py:137-138`), `sbrk`/`fstat` syscall buffers (`user.py:83`), `write`
  (`user.py:90`), and semihosting (`user.py:136`).

### 2.3 `notify_loading` / `notify_stored` — the device side-channel

`sim.py:57-58` (no-ops in the core):

```python
def notify_stored(self, addr): pass  # called *after* mem store
def notify_loading(self, addr): pass  # called *before* mem load
```

Semantics (see `load`/`store` in §1.3):
- `notify_loading(addr)` runs **before** the `struct.unpack_from` — a subclass can write
  the device's value into the flat page so the read picks it up.
- `notify_stored(addr)` runs **after** `struct.pack_into` — a subclass can read the just-
  written bytes out of the flat page and forward them to a device.

### 2.4 How `virt` implements MMIO on top of that

`system.py:170-180`:

```python
def notify_stored(self, addr):
    if addr >= self.ram_base: pass
    elif addr in range(self.clint_base, self.clint_base+self.clint.size): self.clint[addr-self.clint_base] = struct.unpack_from('Q', *self.page_and_offset(addr))[0]
    elif addr in range(self.uart_base, self.uart_base+self.uart.size): self.uart[addr-self.uart_base] = struct.unpack_from('B', *self.page_and_offset(addr))[0]
    elif addr in range(self.plic_base, self.plic_base+self.plic.size): self.plic[addr-self.plic_base] = struct.unpack_from('I', *self.page_and_offset(addr))[0]

def notify_loading(self, addr):
    if addr >= self.ram_base: pass
    elif addr in range(self.clint_base, self.clint_base+self.clint.size): struct.pack_into('Q', *self.page_and_offset(addr), self.clint[addr-self.clint_base])
    elif addr in range(self.plic_base, self.plic_base+self.plic.size): struct.pack_into('I', *self.page_and_offset(addr), self.plic[addr-self.plic_base])
    elif addr in range(self.uart_base, self.uart_base+self.uart.size): struct.pack_into('B', *self.page_and_offset(addr), self.uart[addr-self.uart_base])
```

This is the pattern to copy for a hex-addressed region: an address-range test that diverts
the access to a different backend. Note the device size (`size`) is declared per device
(`uart8250.size = 0x100`, `clint.size = 0x10000`, `plic.size = 0x600000`).

### 2.5 The single point where a virtual/physical address becomes a memory access

There is **not one** function, there are four paths that all bottom out in
`page_and_offset`:

| path | call sites |
|---|---|
| CPU data load/store | `load` `sim.py:115` / `store` `sim.py:107` → `pa()` → `page_and_offset()` |
| instruction fetch | `step` `sim.py:343` → `pa(pc,'x')` + `page_and_offset()` (bypasses `load`) |
| bulk copy (ELF/DTB/syscall) | `copy_in`/`copy_out` `sim.py:73-78` → `page_and_offset_iter` → `page_and_offset` (no `pa`) |
| page-table walk | `pa` itself `sim.py:86,105` → `page_and_offset` |

**Recommendation for the hex region:** intercept at the two *data* choke points —
`load` (`sim.py:115`) and `store` (`sim.py:107`) — with a range check **after** `pa()`
(post-translation, so the hex window is a physical-address window, exactly like the
existing `clint/plic/uart` windows). To also cover ELF loading and syscall buffer copies,
add the same check to `copy_in`/`copy_out` (`sim.py:73-78`). Do **not** override
`page_and_offset` alone: it is also used for PTE reads and instruction fetch, which you
almost certainly want to stay flat. A clean alternative that matches the existing style is
a `hex` device object routed through `notify_loading`/`notify_stored`, but that still
round-trips through the flat bytearray, so for a *true* replacement the `load`/`store` +
`copy_in`/`copy_out` patch is the right seam.

---

## 3. Custom instructions

### 3.1 `customs` — the opcode → name table (already wired for custom-0/1/2/3)

`common.py:6`:

```python
customs={0b0001011: 'custom0', 0b0101011: 'custom1', 0b1011011: 'custom2', 0b1111011: 'custom3'}
```

This maps the low-7-bit opcode to a dispatch name. `0x0B` (custom-0), `0x2B` (custom-1),
`0x5B` (custom-2), `0x7B` (custom-3). **Verified:** there are no `custom*` entries in the
auto-generated `opcodes` table and no `0x0B`-opcode entries in `mask_match_rv32/64`, so the
only recognition of these four opcodes is this dict.

### 3.2 How `unimplemented` fires

`sim.py:338` + the dispatch line `sim.py:347`:

```python
def unimplemented(self, **_): print(f'\n{zext(64,self.op.addr):08x}: unimplemented: {zext(32,self.op.data):08x} {self.op}'); self.exitcode=77
...
    getattr(self, '_'+self.op.name, self.unimplemented)(**self.op.args)  # dynamic instruction dispatch
```

Every instruction is dispatched by name: `self._<op.name>` if it exists, else
`unimplemented`. Because `customs` already names a custom-0 word `'custom0'`, the dispatch
already tries `self._custom0` — **there is simply no such method yet**, so it falls through
to `unimplemented`. That is the entire "custom instruction" mechanism: it is convention,
not a dispatch table.

### 3.3 `hook_exec` / `hook_csr`

```python
# sim.py:337
def hook_exec(self): return True
# sim.py:53-56
def hook_csr(self, csr, reqval):
    if (csr>>8)&3 > self.plevel: self.mtrap(self.op.data, 2); return self.csr[csr]  # insufficient privilege
    elif (csr&0xc00)==0xc00: return self.csr[csr]  # read-only CSR
    else: return reqval
```

- `hook_exec` runs once per instruction in `step` (`sim.py:344`), after decode and before
  the `getattr(...)` dispatch; returning `False` skips execution of the current op. Subclass
  overrides: `virt.hook_exec` (`system.py:201`, checkpointing + interrupt injection + WFI)
  and `elf_runner.hook_exec` (`user.py:169`, time-store + `keep_running`).
- `hook_csr(csr, reqval)` is the single funnel for **every** CSR write — the return value is
  what actually gets stored. Subclass override `virt.hook_csr` (`system.py:182-185`) uses it
  to implement a mini console (`csr 0x139` writes a char, `csr 0x140` reads a key). **This
  is the seam for a custom CSR with side effects.**

### 3.4 Where to add a custom opcode handler (custom-0, opcode 0x0B)

Two options, from least to most invasive:

**Option A — a `_custom0` method that reads the raw word (zero decode changes).**
Because `decode` leaves `args={}` for custom words (see §4), the handler gets no keyword
args and must decode `self.op.data` itself:

```python
# add to a sim subclass:
def _custom0(self, **_):
    w = self.op.data
    rd, rs1, rs2 = (w>>7)&31, (w>>15)&31, (w>>20)&31
    funct3, funct7 = (w>>12)&7, (w>>25)&127
    self.pc += 4
    # ... Xlattice semantics on self.x[rd/rs1/rs2] ...
```

`self.op` is set in `step` before dispatch (`sim.py:343`), so `self.op.data`,
`self.op.addr`, `self.op.name` are all available.

**Option B — teach `decode` the custom format so `args`/disassembly work (recommended).**
Add a custom-format table and merge it into the decode loop (§4.2), or append entries to
`mask_match_rv32/64`. Then the handler looks like every other op:

```python
def _custom0(self, rd, rs1, rs2, funct3, funct7, **_): ...
```

For a multi-instruction "Xlattice" extension (TCONJ/TDOT/TWEDGE/TSYMDOT/TGRAD/TRELAX …),
Option B is the right shape: it makes `rvop.arg_str` render the operands and `rvop.valid()`
return `True`, and it gives per-mnemonic names instead of a single `custom0` bucket.

---

## 4. The instruction decode path

### 4.1 `decode` / `decoder` / `rvop` / `xfmt` / `mask_match_rv32`

`common.py:39-47`:

```python
@functools.lru_cache(maxsize=4096)
def decode(instr, addr=0, xlen=64):  # decodes one instruction
    o = rvop(addr=addr, data=instr, name=customs.get(instr&0b1111111,'UNKNOWN'), args={})
    for mask, m_dict in mask_match_rv64 if xlen==64 else mask_match_rv32:
        if op := m_dict.get(instr&mask, None):
            o.args = dict((vf, getter(instr)) for vf, getter in op['arg_getter'].items())
            [setattr(o,k,v) for k,v in (op|o.args).items()]
            break
    return o
```

Mechanics:

1. `name` is seeded from `customs.get(instr & 0x7F, 'UNKNOWN')` — so custom-0 already
   starts life named `'custom0'`.
2. It then scans `mask_match_rv64`/`mask_match_rv32` — a list of `(mask, {match_value: op_dict})`
   pairs. For each pair it computes `instr & mask` and looks the result up. First hit wins.
3. On a hit it builds `o.args` by running each `arg_getter` lambda over `instr`, and
   copies all of `op`'s metadata onto `o` (including `extension`, which is why `valid()`
   works for decoded ops).
4. **On a miss the loop never breaks** — the `rvop` keeps its seeded `name` and empty `args`.
   This is exactly the custom-0 path: name `'custom0'`, `args={}`, no `extension` ⇒
   `valid()` returns `False` (verified live: decode of a custom-0 word yields
   `name=custom0, args={}, valid()=False`).

`rvop` (`common.py:11-37`) is a generic attribute bag:
- `rvop.arg_str()` renders a readable operand string (loads/stores/CSRs/jumps/etc. by name).
- `rvop.valid()` returns `True` only if all `nz`/`n0`-prefixed args are non-zero **and**
  `hasattr(self,'extension')` — the latter is what makes an unmatched custom word "invalid".

`xfmt` (`common.py:9`) is just hex formatting: `xfmt(len, word)` → zero-padded hex of the
low `len` bits.

`decoder`/`rvsplitter` (`dump.py:4-12`) are the disassembler entry points over a file or a
list of hex words; `rvsplitter` reassembles 16/32-bit instructions (2 LSBs `11` ⇒ 32-bit).

`mask_match_rv32` (`opcodes.py:6`) and `mask_match_rv64` (`opcodes.py:8`) are the two
auto-generated lookup lists (44 entries in `rv32`). Each op's entry (e.g. `add`) is:

```python
{'extension': ['rv_i'], 'mask': 4261441663, 'match': 51, 'variable_fields': ['rd','rs1','rs2'],
 'name': 'add', 'arg_bits': {...}, 'arg_getter': {'rd': lambda x:(x>>7)&31, 'rs1': lambda x:(x>>15)&31, 'rs2': lambda x:(x>>20)&31}}
```

The `arg_getter` lambdas are the whole field-extraction story: a field name → bit slice of
the instruction word.

### 4.2 How to add a custom format

The decode loop is the single gate. To make an Xlattice mnemonic decode like a first-class
instruction:

- **Quickest:** intercept in `decode` before/after the `mask_match` loop with a custom
  table, e.g. after the loop: if `o.name` starts with `'custom'`, look up
  `(funct7, funct3)` in an Xlattice table, set `o.name`, `o.args`, and `o.extension=['xlattice']`.
- **Most idiomatic:** append your own `(mask, {match: op_dict})` tuples to `mask_match_rv32`
  and `mask_match_rv64` (or add a merged dict to `opcodes.opcodes`). `opcodes.py` is
  auto-generated by `tinyrv_opcodes_gen.py`, so either edit it in place and stop
  regenerating, or inject the entries at import time from your own module (cleaner — keeps
  the generated file pristine).

The instruction word for custom-0 uses the standard R-type layout:
`funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]=0x0B`.
The custom-0 namespace has 7 `funct7` bits × 8 `funct3` bits = plenty of encodings for the
Xlattice opcodes.

---

## 5. Register file and CSRs

### 5.1 Integer and FP register files

`common.py:4-5` (name tables), `sim.py:10-30` (accessors):

```python
iregs = 'zero,ra,sp,gp,tp,t0,t1,t2,fp,s1,a0,...,t6'.split(',')
fregs = 'ft0,...,ft11'.split(',')
```

- `self.x` is `rvregs` (`sim.py:10-16`): a 32-entry list; `__setitem__` ignores writes to
  index 0 (`zero`) and appends to `trace_log`. Read `self.x[rs1]`, write `self.x[rd]=v`.
- `self.f` is `rvfregs` (`sim.py:17-30`): `self.f.raw` is the 32-entry raw-int list;
  `self.f.s`/`self.f.d` are IEEE `float` views (32/64-bit); `self.f.raw_s`/`self.f.raw_d`
  are raw-int views with NaN-boxing semantics. FP ops read/write `self.f.s[rd]`,
  `self.f.d[rd]`, `self.f.raw[...]`.

A custom instruction reads/writes these exactly like the built-ins do:
`self.x[rd] = sext(self.xlen, self.x[rs1] + self.x[rs2])` etc.

### 5.2 CSRs

`sim.py:31-47` (`rvcsrs`), backed by a 4096-slot list:

```python
class rvcsrs:
    def __init__(self, xlen, sim): self._csr, self.xlen, self.sim = [0]*4096, xlen, sim
    def __getitem__(self, i):
        if i == self.sim.TSELECT: return 1  # ...
        elif i == self.sim.MISA: return (0x40000000 if self.sim.xlen==32 else 0x80000000_00000000) | 0b1000000101101
        else: return self._csr[i]
    def __setitem__(self, i, d):
        if   i == self.sim.FCSR:    ...  # FCSR/FFLAGS/FRM aliasing
        elif i == self.sim.FFLAGS:  ...
        elif i == self.sim.FRM:     ...
        else:
            if self.sim.xlen==64 and (i==self.sim.MSTATUS or i==self.sim.SSTATUS): d = d & ~0x100000000 | 0x200000000
            self._csr[i] = d
            for csr1, csr2, mask in [(MSTATUS,SSTATUS,...),(MIE,SIE,...),(MIP,SIP,...)]: ...  # mirroring
```

- `csrs` dict (`opcodes.py:5`) maps 451 CSR numbers → names (`1:'fflags'`, `3:'fcsr'`,
  `0x300:'mstatus'`, `0x301:'misa'`, `0x305:'mtvec'`, `0x341:'mepc'`, `0x342:'mcause'`,
  `0x343:'mtval'`, `0x302:'medeleg'`, `0x303:'mideleg'`, `0x304:'mie'`, `0x344:'mip'`,
  `0x180:'satp'`, `0xb00:'mcycle'`, `0x7a0:'tselect'`, …). It is used **only for naming**
  (trace strings + `rvop.arg_str`), never for gating access.
- `sim.py:51` creates convenience attributes for every ireg and every CSR name:
  `[setattr(self, n.upper(), i) for i, n in list(enumerate(iregs))+list(csrs.items())]` —
  hence `self.RA == 1`, `self.MSTATUS == 0x300`, `self.SATP == 0x180`, `self.MCYCLE == 0xb00`.

### 5.3 Adding a custom CSR

1. Pick an unused CSR address in the RISC-V custom ranges — read/write `0x7C0–0x7FF` or
   `0xBC0–0xBFF`, read-only `0xCC0–0xCFF`.
2. Access it directly: `self.csr[0x7C0]` already works (the `_csr` list is 4096 slots and
   `__getitem__`/`__setitem__` have no allow-list). `csrrw`/`csrrs`/`csrrc` instructions
   (`sim.py:181-186`) will read/write it transparently.
3. For a nice name in traces and disassembly, add the entry to the `csrs` dict
   (`opcodes.py:5`) — that also auto-creates the `self.MYCUSTOM` convenience attribute via
   `sim.py:51`.
4. For side effects (the console pattern), override `hook_csr` in the subclass
   (`system.py:182-185` shows the template) and intercept that CSR number before delegating
   to `super().hook_csr(csr, reqval)`.

---

## 6. Hook-point summary (the seams)

| concern | exact seam | file:line |
|---|---|---|
| flat memory backing store | `self.mem_pages` dict + `self.mem_psize` | `sim.py:50` |
| address → (page,offset) (lowest level) | `page_and_offset` | `sim.py:79` |
| virtual → physical MMU | `pa` | `sim.py:80-106` |
| **CPU data load (choke point)** | `load` | `sim.py:115-124` |
| **CPU data store (choke point)** | `store` | `sim.py:107-114` |
| bulk byte copy (ELF/DTB/syscall) | `copy_in` / `copy_out` | `sim.py:73-78` |
| device/MMIO side-channel | `notify_loading` / `notify_stored` | `sim.py:57-58`, overridden `system.py:170-180`, `user.py:150-167` |
| instruction fetch | `step` | `sim.py:341-343` |
| custom-opcode name table | `customs` | `common.py:6` |
| instruction decode | `decode` | `common.py:40-47` |
| decode tables | `mask_match_rv32/64`, `opcodes` | `opcodes.py:6,8,3` |
| per-instruction pre-hook | `hook_exec` | `sim.py:337` (override `system.py:201`, `user.py:169`) |
| CSR write funnel | `hook_csr` | `sim.py:53-56` (override `system.py:182`) |
| op dispatch / fallback | `getattr(self, '_'+name, self.unimplemented)` | `sim.py:347` |
| "unknown instruction" | `unimplemented` | `sim.py:338` |
| integer regfile | `rvregs` → `self.x` | `sim.py:10-16` |
| FP regfile | `rvfregs` → `self.f` | `sim.py:17-30` |
| CSR file | `rvcsrs` → `self.csr` (`_csr=[0]*4096`) | `sim.py:31-47` |
| CSR names + convenience attrs | `csrs` dict + `setattr` loop | `opcodes.py:5`, `sim.py:51` |

---

## Conclusion — the two patches

**To add a hex-addressed memory region (Eisenstein cell `(a,b)`, `3ⁿ` namespace):**

1. Add a hex-memory backend (a class holding the cell → value store and the
   `eisensteinToNat`/`eisensteinOfNat` bijection).
2. Intercept the **data path** in `load` (`sim.py:115`) and `store` (`sim.py:107`): insert
   an address-range test immediately after `addr = self.pa(...)` (post-translation, physical
   window — mirroring how `virt` windows `clint/plic/uart` at `system.py:170-180`). Route
   in-range addresses to the hex backend; else fall through to the existing
   `page_and_offset`/`struct` code.
3. Mirror the same test in `copy_in`/`copy_out` (`sim.py:73-78`) so ELF loading, DTB
   placement, and syscall buffers can also land in hex cells.
4. Leave `pa` (`sim.py:80`) and instruction fetch (`sim.py:341-343`) alone — page tables and
   code should stay flat unless you deliberately want hex PTEs.
5. If you want a *shadow* MMIO device instead of a full replacement, the existing pattern is
   `notify_loading`/`notify_stored` (`sim.py:57-58` + `system.py:170-180`), but that still
   round-trips through the flat bytearray.

**To add a custom instruction (Xlattice, custom-0 opcode `0x0B`):**

1. The dispatch already reaches `self._custom0` (via `customs` at `common.py:6` + the
   `getattr` at `sim.py:347`). The *minimal* patch is a `_custom0` method that decodes
   `self.op.data` (funct7/funct3/rs1/rs2/rd) and implements the op — no decode changes.
2. For a real multi-op extension, teach `decode` (`common.py:40-47`) the custom format:
   after the `mask_match` loop, resolve `funct7/funct3` → mnemonic + `args` +
   `extension=['xlattice']` (or inject `(mask, {match: op_dict})` entries into
   `mask_match_rv32/64`). Then add `_<mnemonic>` methods with `(rd, rs1, rs2, funct3, ...)`
   signatures like every built-in op, and `rvop.arg_str`/`valid()` work for free.
3. Read/write registers via `self.x[i]` / `self.f.*` (§5.1); add custom CSRs by assigning
   into `self.csr[0x7C0..]` and (optionally) naming them in the `csrs` dict + overriding
   `hook_csr` for side effects (§5.3).

**Cross-check against the plan:** this confirms and tightens the four seams already listed in
`docs/TAU_RISCV_PLAN.md` — `pa`/`page_and_offset*` (hex MMU), `load`/`store` +
`notify_*` (ternary transport), `unimplemented`/`customs` (Xlattice), and
`mask_match_rv32/64`/`opcodes`/`decode` (custom-0 encoding).
