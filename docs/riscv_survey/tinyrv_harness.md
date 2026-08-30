# tinyrv harness — exact API + memory model

Survey of the `tinyrv` RISC-V emulator installed at
`venv/lib/python3.13/site-packages/tinyrv/` (files: `__init__.py`, `common.py`,
`opcodes.py`, `sim.py`, `system.py`, `user.py`, `fpu.py`, `dump.py`).

Verified with a runnable example: `scripts/tinyrv_hello.py`
(`venv/bin/python scripts/tinyrv_hello.py` → prints `RESULT: PASS`).

Package layout:

- `tinyrv/__init__.py` does `from .sim import *` and `from .dump import decoder`,
  so `import tinyrv` exposes `sim`, `decode`, `decoder`, `Trap`, `iregs`, `csrs`,
  `zext`/`sext`/`xfmt`, `customs`, `rvop`, etc.
- `sim.py` — the CPU core (`class sim`).
- `system.py` — `class virt(sim)`: a qemu-`virt`-like machine (RAM at `0x80000000`,
  UART/CLINT/PLIC, DTB). Booting a *raw* image is `virt(image_bytes, ram_size, xlen=…)`.
- `user.py` — `elf_runner` / `load_elf`: ELF loading via `lief`, plus a minimal
  linux-user syscall layer (`ecall` = syscalls, semihosting, HTIF `tohost`).
- `dump.py` — `rvsplitter`/`decoder`: disassembles a raw `.bin` or hex words.
- `opcodes.py` — auto-generated decode tables (`mask_match_rv32`/`rv64`) + `csrs` map.
- `common.py` — `decode()`, `rvop`, register-name lists, `customs` map.

---

## (a) Minimal working code (load + run + read back)

tinyrv's core `sim` has **no binary/ELF loader** — you write raw bytes straight
into physical memory with `copy_in` and point `pc` at them. (ELF support is a
separate layer in `user.py`, not needed for a bare program.)

```python
import struct
from tinyrv import sim

# hand-assembled RV32I words (little-endian)
prog = [
    0x000012B7,  # lui   t0, 0x1       -> t0 = 0x1000
    0x00A00513,  # addi  a0, x0, 10    -> a0 = 10
    0x00B50593,  # ... (etc.)
]

vm = sim(xlen=32)                     # 1. instantiate (default xlen is 64!)
vm.copy_in(0x0000, struct.pack(f"<{len(prog)}I", *prog))  # 2. load bytes
vm.pc = 0x0000                        # 3. set program counter
vm.run(limit=100, trace=False)        # 4. execute (self-loop halts it)

# 5. read back
vm.x[10]          # integer register a0 (list-like: vm.x[i], vm.x[vm.A0])
vm.load("I", 0x1020)   # 32-bit unsigned load from memory
vm.copy_out(0x1020, 4) # raw bytes back
vm.pc                  # where it stopped
```

Key API facts:

- **Instantiate** `sim(xlen=32, trap_misaligned=True)`. `xlen` **defaults to 64**
  — pass `xlen=32` for RV32I. `trap_misaligned` defaults `True`.
- **Load**: `copy_in(addr, bytes)` (also `copy_out(addr, nbytes) -> bytearray`).
  There is no `load_binary` on the core `sim`; `system.virt` takes raw
  `image` bytes (RAM at `0x80000000`), `user.elf_runner` takes an ELF file.
- **Run**: `step(trace=True)` executes one instruction;
  `run(limit=0, bpts=set(), trace=True)` loops. See the halt semantics in (d).
- **Registers**: `vm.x[i]` (int regs, index 0..31, `x[0]` hard-wired 0),
  `vm.f` (float regs), `vm.csr[i]` (4096 CSR slots). Convenience names exist:
  `vm.x[vm.A0]`, `vm.csr[vm.MSTATUS]`, etc. (set via `setattr` of `iregs` +
  `csrs` names uppercased).
- **Memory**: `load(fmt, addr, fallback=0, notify=True)`,
  `store(fmt, addr, data, notify=True, cond=True)`, `copy_in`/`copy_out`,
  `mem_pages` (the raw dict), `pa(addr, access)`, `page_and_offset(addr)`,
  `page_and_offset_iter(addr, nbytes, doffset=0)`.

---

## (b) Memory representation; `load`/`store`; address translation

### Physical memory = sparse dict of bytearrays, little-endian

- `self.mem_pages` is a `collections.defaultdict(functools.partial(bytearray, 2<<20+2))`.
  Because `+` binds tighter than `<<` in Python, `2<<20+2` is `2 << 22` =
  **8,388,608 bytes (8 MiB)** per backing `bytearray` — an over-allocation of the
  comment's intent ("2-byte overlap for loading unaligned 32-bit opcodes").
- `self.mem_psize = 2<<20` = **2,097,152 bytes (2 MiB)**. This is the real
  addressing granularity used by `page_and_offset`:
  ```python
  def page_and_offset(self, addr):
      return self.mem_pages[addr & ~(self.mem_psize-1)], addr & (self.mem_psize-1)
  ```
  i.e. keys are 2 MiB-aligned, offsets are `addr & 0x1FFFFF`. Each 2 MiB-aligned
  chunk lazily materializes an 8 MiB `bytearray`, so a 4-byte (or unaligned
  straddling) access never runs off the end.
- **Endianness is little-endian** throughout: memory is byte-addressable and all
  `load`/`store`/`copy_*`/instruction-fetch go through Python `struct` with native
  (`<`) byte order. Instruction words must be packed `<I`.

### `load` / `store`

```python
def store(self, format, addr, data, notify=True, cond=True):
    ... addr = self.pa(addr, access='w') ...
    struct.pack_into(format, *self.page_and_offset(zext(self.xlen,addr)), data)

def load(self, format, addr, fallback=0, notify=True):
    ... addr = self.pa(addr, access='r') ...
    return struct.unpack_from(format, *self.page_and_offset(addr))[0]
```

- `format` is a `struct` code: `'B'`/`'b'` (u8/i8), `'H'`/`'h'` (u16/i16),
  `'I'`/`'i'` (u32/i32), `'Q'`/`'q'` (u64/i64). Opcode handlers use the
  unsigned form for stores (`zext`) and let loads read the natural width.
- `load` applies sign convention of the `struct` code (`'i'` returns negative for
  `>= 0x80000000`); it returns `fallback` (and traps) on fault.
- `store` takes a **plain int** (`data`) and packs it into the selected width.
- `notify=True` triggers `notify_stored`/`notify_loading` hooks (used by
  `system.virt` to route MMIO: UART/CLINT/PLIC; `user.elf_runner` for `tohost`).
- `cond=False` on `store` makes it a no-op (used by `sc.w` when the reservation
  was lost).
- `load`/`store` honor `trap_misaligned` (raises/traps on unaligned address
  unless disabled).

### Address translation — `pa(addr, access='w'|'r'|'x')`

```python
def pa(self, addr, access='w'):
    pl = ... (MSTATUS.MPP if M-mode && MPRV && access!='x' else self.plevel)
    satp, sum_bit, mxr_bit = ...
    if pl==3 or satp==0: return addr          # <-- no virtual memory
    # else walk Sv32 (xlen==32, satp[31]) or Sv39 (xlen==64, satp[63:60]==8)
    #   -> page-table walk, PTE A/D update, permission checks, raise Trap(pfault)
    return (addr & 0xfff) | (pte<<2)&pte_paddr_mask
```

- By default the sim boots in **M-mode** (`plevel == 3`) with `satp == 0`, so
  **`pa` is the identity** (`return addr`) — bare-metal programs see flat
  physical memory. Virtual memory only engages when you lower privilege and set
  `satp`; then it does a real Sv32/Sv39 walk with A/D-bit updates
  (Svadu-style) and read/write/execute permission checks.
- `pa` raises `Trap(tval, cause)` on page fault (causes 12=x, 13=r, 15=w);
  `load`/`store` catch it and route to `mtrap`.

### `page_and_offset_iter`

```python
def page_and_offset_iter(self, addr, nbytes, doffset=0):
    while nbytes > doffset:
        page, poffset = self.page_and_offset(zext(self.xlen, addr+doffset))
        yield page, poffset, doffset, min(nbytes-doffset, self.mem_psize - poffset + 2)
        doffset += min(nbytes-doffset, self.mem_psize - poffset)
```

Yields `(page, poffset, doffset, chunk)` tuples so a multi-byte `copy_in`/`copy_out`
can be split at 2 MiB page boundaries (the `+2` headroom covers the straddling
case). Used internally by `copy_in`/`copy_out`.

---

## (c) Custom / unimplemented instruction dispatch

The fetch-execute loop is in `step()`:

```python
self.op = decode(struct.unpack_from('I', *self.page_and_offset(addr))[0], 0, self.xlen)
...
if self.hook_exec():
    self.cycle += 1; self.csr[self.MCYCLE] = ...
    if self.pc & (1<<63): self.mtrap(self.pc, 1)
    else: getattr(self, '_'+self.op.name, self.unimplemented)(**self.op.args)
```

- **Dispatch** is `getattr(self, '_' + op.name, self.unimplemented)(**op.args)`.
  Each opcode's Python handler is `sim._<name>` (e.g. `_addi`, `_lui`, `_sw`).
  `decode()` (in `common.py`) returns an `rvop` with `.name`, `.args`, `.addr`,
  `.data`, `.extension`.
- **`unimplemented(self, **_)`**: the fallback. It prints
  `"<addr>: unimplemented: <word> <op>"` and sets `self.exitcode = 77`
  (and does **not** advance `pc`, so `run()` terminates — pc is unchanged).
- **`hook_exec(self)`**: called *before* each instruction executes; default is
  `return True`. Return `False` to skip the instruction (and skip the cycle
  counter). `system.virt` overrides it for checkpoints/WFI/interrupts;
  `user.elf_runner` overrides it for `tohost` exit and wall-clock injection.
- **`customs`** (in `common.py`): maps the four custom opcode spaces to names,
  but only as the *default* `rvop.name` for the decode table:
  `{0b0001011:'custom0', 0b0101011:'custom1', 0b1011011:'custom2', 0b1111011:'custom3'}`.
  There are no `_custom0..3` handlers in `sim`, so a custom-space instruction
  decodes to `name='custom0'` and falls through to `unimplemented`. To handle a
  custom instruction, subclass `sim` and define `_custom0`/`_custom1`/etc.
- **`hook_csr(self, csr, reqval)`**: the CSR write hook — `_csrrw/_csrrs/...`
  route every write through it; override to implement custom CSRs (e.g.
  `system.virt` maps CSR `0x139` to console output). It returns the value to
  store.

---

## (d) Gotchas

1. **`xlen` defaults to 64.** `sim(xlen=32)` for RV32I. `virt`/`elf_runner`
   pick xlen from the image/ELF; the core `sim` does not.
2. **PC starts at 0.** `sim.pc = 0`. Set it to your base before `run()`.
3. **Boot mode is M-mode** (`plevel = 3`) with `MSTATUS = 0x6000` (FPU "active"),
   `satp = 0` → `pa` is the identity (flat physical addressing). No CSRs need to
   be initialized for a bare RV32I program. (`system.virt` sets up A0/A1/DTB and
   `pc = 0x80000000` itself.)
4. **Endianness is little-endian**; pack instruction words with `<I`. Register
   values are plain Python ints; `x[0]` is always 0.
5. **Halting / `run()` semantics.** `run(limit=0, bpts=set(), trace=True)` loops
   `step()` and breaks when `self.op.addr in bpts | {self.pc}` or the `limit`
   counter reaches 0. In practice a **self-loop** (`beq x0,x0,0` = `0x00000063`,
   or `jal x0,-4`) is the clean halt: after it, `pc == op.addr`, so `run` returns.
   (`ecall`/`ebreak` instead take the `mtrap` path and set `pc = mtvec`, which is
   `0` by default → re-runs from address 0, *not* a clean halt. Prefer the
   self-loop for a bare program.)
6. **`trap_misaligned=True` by default** on `sim` — an unaligned `lw`/`sw`
   traps (cause 4/6). `virt` and `elf_runner` disable it.
7. **`mem_psize` vs. backing `bytearray` size quirk.** Page granularity is
   `2<<20` = 2 MiB, but each materialized `bytearray` is `2<<20+2` = `2<<22` =
   8 MiB (operator precedence: `+` binds before `<<`). Harmless (it only
   over-allocates), but the comment's "2-byte overlap" is not what the code
   produces.
8. **Decode is a pure lookup** — `decode(instr, addr, xlen)` returns an `rvop`
   even for invalid/unknown words (with `name='UNKNOWN'` and empty args, or a
   custom-space name). Invalid words are caught at dispatch time by
   `unimplemented`, not at decode time.
9. **`run`/`step` print by default** (`trace=True`); pass `trace=False` for
   clean programmatic output. `trace_log` records register/CSR/memory side
   effects per instruction.
10. **`load` width vs. store width**: opcode handlers always `zext` before
    `store`, so store data must be a non-negative int of the right width; loads
    return whatever `struct` code you chose (`'i'` is signed, `'I'` unsigned).

---

## Hand-assembled program reference (used in the smoke test)

```text
addr    word        instruction          effect
0x0000  0x000012B7  lui   t0, 0x1        t0 = 0x00001000
0x0004  0x00000317  auipc t1, 0x0        t1 = pc + 0 = 0x4
0x0008  0x00A00513  addi  a0, x0, 10     a0 = 10
0x000c  0x01400593  addi  a1, x0, 20     a1 = 20
0x0010  0x00B50633  add   a2, a0, a1     a2 = 30
0x0014  0x40A586B3  sub   a3, a1, a0     a3 = 10
0x0018  0x02C2A023  sw    a2, 0x20(t0)   mem[0x1020] = 30
0x001c  0x0202A703  lw    a4, 0x20(t0)   a4 = 30
0x0020  0x02D2A223  sw    a3, 0x24(t0)   mem[0x1024] = 10
0x0024  0x00000063  beq   x0, x0, 0      self-loop (halt)
```

Verified results: `t0=0x1000`, `t1=0x4`, `a0=10`, `a1=20`, `a2=30`, `a3=10`,
`a4=30`, `mem[0x1020]=30`, `mem[0x1024]=10`, final `pc=0x24`.
