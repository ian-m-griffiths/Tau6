# RV32I Core Survey — Base for Hex-Addressed Memory + "Xlattice" GA Co-Processor

**Phase 4 hardware reconnaissance.** Goal: pick a small, simple, well-documented open-source
RISC-V core that we can (a) hang a *custom hex-addressed memory subsystem* off, and (b) attach a
*custom geometric-algebra ("Xlattice") co-processor* to. We explicitly prefer **minimal + easy-to-hook
over fast**. No big out-of-order monsters.

Numbers below are quoted from each project's own README/datasheet (primary sources) and reflect the
*latest public data* at time of survey. LUT/kGE figures vary with configuration and tool/device; treat
them as order-of-magnitude, not precise.

---

## Comparison table

| Core | ISA coverage | Area / f<sub>max</sub> | License | Memory interface (hex-MMU hook) | Custom-instruction support | Complexity / LOC |
|------|--------------|------------------------|---------|---------------------------------|----------------------------|------------------|
| **[PicoRV32](https://github.com/YosysHQ/picorv32)** | RV32I base; opt. `M`, `C`; RV32E config | 750–2000 LUTs; 250–450 MHz (Xilinx 7-series) | ISC | Native valid/ready port + look-ahead; also `picorv32_axi` (AXI4-Lite) and `picorv32_wb` (Wishbone) master variants | **PCPI** co-processor port (non-branching instrs; M-ext itself is built on it) | **Single `picorv32.v`** (~2k lines) + `picosoc` example; excellent README |
| **[SERV](https://github.com/olofk/serv)** | RV32I (+ Zicsr, M-mode); opt. `M` via MDU lib | 125 LUT (Artix-7) / 198 (iCE40) / 2.1 kGE (CMOS) | ISC | Wishbone B4 (via Servant SoC); one serialized bus | None built-in (decode must be modified) | ~a few Verilog files; gate-accurate manual; FuseSoC |
| **[VexRiscv](https://github.com/SpinalHDL/VexRiscv)** | RV32I `[M][A][F[D]][C]` | 504 LUT @ 243 MHz (small RV32I) → 2883 LUT (linux RV32IMA), Artix-7 | MIT | AXI4, Avalon, Wishbone (plugin-selectable); opt. TCM | **Plugin system** — add instrs via a Scala plugin (documented `SimdAdd` example); plugins can halt stages, emit exceptions, inject decode, jump PC | SpinalHDL generator (Scala→Verilog); needs sbt/JVM; well documented |
| **[NEORV32](https://github.com/stnolting/neorv32)** | RV32 `I`/`E` + `M`/`A`/`C`/`B`/`U` + `Zfinx`/`Zicsr`/`Zicntr`/`Zifencei`/`Zicond` (all configurable) | ≈2300 LUTs / 1000 FF @ 130 MHz (Cyclone IV; full RTOS-capable `rv32imc` CPU+peripherals+mem) | BSD-3-Clause | **Wishbone (XBUS) + AXI4 bridge**, plus internal PIB; documented "add custom hardware" flow | **CFU (Xcfu)** — up to 4 opcodes, R-type & I-type, C intrinsics; plus CFS for memory-mapped accelerators | Modular VHDL SoC (CPU separable); self-contained; datasheet + user guide; passes RISC-V ACTs |
| **[Ibex](https://github.com/lowRISC/ibex)** | RV32IMC + `B`/`Zb`/`Zc` (RV32E "micro" config) — *not RV32I-only* | 16.85 kGE ("micro" RV32EC) → 66 kGE (maxperf+pmp); ~15–30 kGE commercial | Apache-2.0 | Separate I/D ports + TL-UL adapter; `simple_system` shows a simple bus | No first-class custom-instruction port | SystemVerilog, production-grade, multi-file, heavily verified |
| **[DarkRISCV](https://github.com/darklife/darkriscv)** | RV32I/E (+ opt. `M` mul-only; opt. 16×16 MAC + DBNZ) | 850–1500 LUTs; up to 250 MHz (KU040), 100 MHz (Spartan-6) | BSD | Simple Harvard bus; opt. DarkBridge / caches / SDRAM | Fixed MAC/DBNZ only — no generic co-processor port | Compact Verilog; lightweight docs/verification |
| **[Rocket (lite)](https://github.com/chipsalliance/rocket-chip)** | RV32/RV64; `I/M/A/C/F/D` configurable (in-order 5-stage) | Large for this class (tens of kGE even "lite") — not minimal | Apache-2.0 (+ BSD-licensed Berkeley components) | TileLink (AXI4/AHB/APB converters); real *paged* MMU (not a clean hex-hook) | **ROCC** co-processor interface (the classic) | Chisel generator + Chipyard/Diplomacy ecosystem; heavy |

---

## Per-core notes

### PicoRV32 — the minimal reference
The canonical "small RISC-V" core. One Verilog file you copy into your project. The
[native memory interface](https://github.com/YosysHQ/picorv32#picorv32-native-memory-interface) is a
dead-simple `mem_valid/mem_ready/mem_addr/mem_wdata/mem_wstrb/mem_rdata` port (plus a look-ahead port),
which is *trivial* to sit in front of a hex-addressed MMU. It also ships `picorv32_axi` (AXI4-Lite) and
`picorv32_wb` (Wishbone) master variants so we aren't forced into a bespoke bus. Custom instructions go
through the [PCPI](https://github.com/YosysHQ/picorv32#pico-co-processor-interface-pcpi) port — the M
extension is literally implemented as PCPI cores (`picorv32_pcpi_mul/div`). Caveat: PCPI is *non-branching
only*, has no memory access of its own, and times out to an illegal-instruction trap after 16 cycles unless
the co-processor asserts `pcpi_wait`.

### SERV — smallest, but the wrong tool here
Award-winning bit-serial core (125 LUTs on Artix-7), ISC, with an unusually good
[gate-accurate manual](https://serv.readthedocs.io/). Wishbone B4 via the Servant SoC. But it is
*bit-serial* (~32+ cycles/instruction) and has **no custom-instruction interface** — a GA co-processor
would mean hacking the decode of a single-file core, and the serial bus would bottleneck a co-processor
that wants wide operand bandwidth. Great for a sensor controller; poor base for a compute co-processor.

### VexRiscv — the most flexible plugin hook
A SpinalHDL (Scala) *generator*, not a fixed core: everything (PC manager, regfile, hazard, decoder,
bus) is a plugin. Smallest config is 504 LUTs @ 243 MHz on Artix-7; buses are AXI4/Avalon/Wishbone via
plugin. [Custom instructions](https://github.com/SpinalHDL/VexRiscv#add-a-custom-instruction-to-the-cpu-via-the-plugin-system)
are first-class: a documented `SimdAddPlugin` shows how to add an opcode, read `rs1/rs2`, and write `rd`,
and plugins can also halt stages / emit exceptions / jump the PC — enough to wire a blocking co-processor.
Cost: a JVM/sbt/SpinalHDL toolchain and a code-generation step; the "core" is not a file you read directly.

### NEORV32 — batteries-included, still small, clean CFU
A customizable *microcontroller SoC* (VHDL, BSD-3) whose CPU is a small multi-cycle in-order core.
The [Custom Functions Unit (CFU)](https://stnolting.github.io/neorv32/#_custom_functions_unit_cfu)
(`Xcfu` extension) is a purpose-built custom-instruction path: up to four opcodes (custom-0/custom-1
reserved by RISC-V for exactly this, plus op-32/op-imm-32), **R-type** (two sources `rs1`/`rs2` +
`funct7`/`funct3`) and **I-type** (one source + 12-bit immediate) formats, multi-cycle completion with a
timeout, and C [intrinsics](https://github.com/stnolting/neorv32/blob/main/sw/lib/include/neorv32_intrinsics.h).
There is also a separate "Custom Functions Subsystem" (CFS) for *memory-mapped* accelerators, and the
external bus is Wishbone (XBUS) with an AXI4 bridge — a natural place for a hex-addressed memory subsystem.
Reference size: a full RTOS-capable `rv32imc_Zicsr_Zicntr` CPU + peripherals + memories ≈ 2300 LUTs / 1000 FF
@ 130 MHz on Cyclone IV (CPU core alone is smaller). Passes the official RISC-V ACTs.

### Ibex — production-quality, but not custom-instruction-friendly
Rock-solid SystemVerilog (Apache-2.0), 2- or 3-stage, RV32IMC(+B), 16.85–66 kGE, heavily verified and
tape-out proven. But it deliberately targets *fixed* ISA configs; there is no clean decode-hook/co-processor
port for a GA accelerator, and integration is via TL-UL adapters rather than a single flat port. Better for a
trusted embedded controller than for DIY ISA extension.

### DarkRISCV — tiny but hand-rolled
Compact Verilog (BSD), 850–1500 LUTs, simple Harvard bus. It has *some* custom ops (16×16 MAC, DBNZ) but they
are baked-in rather than a generic co-processor interface, and the project is a one-person "written in a night"
effort with lighter documentation/verification than the others.

### Rocket (lite) — the classic ROCC, but far from minimal
Rocket is in-order (BOOM is the OoO one), but even a "lite" RV32 tile is tens of kGE and drags in the whole
Chisel/Diplomacy/Chipyard generator stack. Its [ROCC interface](https://chipyard.readthedocs.io/en/1.7.0/Customization/RoCC-Accelerators.html)
is *the* canonical RISC-V custom-coprocessor mechanism, but the memory side is TileLink + a real paged MMU —
replacing that with a bespoke hex MMU is the opposite of "easy to hook". Rule out for this project.

---

## Also considered (minimal RV32I + custom-instruction hooks)

- **Hummingbird E203** ([Nuclei `e203_hbirdv2`](https://github.com/riscv-mcu/e203_hbirdv2)) — RV32IMAC,
  Verilog, Apache-2.0, with the **NICE** (Nuclei Instruction Co-unit Extension) interface for custom
  instructions. Good custom-instruction support but a fuller SoC than we need.
- **CV32E40P** (PULP RI5CY, [OpenHW](https://docs.openhwgroup.org/projects/cv32e40p-user-manual/)) —
  RV32IMC + `Xpulp` custom ops + a dedicated *coprocessor interface* (used for its FPU), Apache-2.0 WITH
  SHL-2.1. Strong hook, but larger and more complex than the minimal class.
- **FemtoRV32** ([Bruno Levy](https://github.com/BrunoLevy/learn-fpga)) — tiny educational RV32I, MIT,
  a few hundred LUTs, simple bus; minimal docs and no custom-instruction interface.
- **SCR1** (Syntacore) — RV32I/E[MC], SystemVerilog, small, optional AXI/AHB-Lite; no clean custom-instr port.

---

## Recommendation

**Base core: [NEORV32](https://github.com/stnolting/neorv32).**

NEORV32 is the best single base for our purpose because it is the only candidate that is simultaneously
*small and in-order* (≈2300 LUTs for a complete RTOS-capable CPU+peripherals, CPU core alone smaller) while
providing **both** of the two hooks we actually need, as first-class, documented features rather than
afterthoughts: (1) the **CFU custom-instruction unit** (`Xcfu`) — a purpose-built decode-and-execute hook
with R-type (`rs1`/`rs2`/`funct7`/`funct3`) and I-type formats, multi-cycle completion with timeout, and C
intrinsics, which is exactly the operand-forwarding + result handshake a geometric-algebra accelerator wants —
plus an optional memory-mapped "Custom Functions Subsystem" if the Xlattice unit needs its own address space;
and (2) a **Wishbone (XBUS) external bus with an AXI4 bridge**, a simple, standard, documented memory port that
we can put a custom hex-addressed MMU directly behind without fighting a page-based MMU or a generator stack.
It is BSD-3-Clause, written in platform-independent VHDL (with an auto-generated Verilog conversion), fully
self-contained, carries best-in-class documentation (datasheet + user guide + tutorials), and passes the
official RISC-V architectural test suite — so we inherit a verified base and spend our effort on the Xlattice
co-processor and the hex memory, not on the CPU. The trade-offs (VHDL rather than Verilog, multi-cycle
0.33–0.95 CoreMark/MHz) are the right ones to accept under "prefer minimal + easy-to-hook over fast."

**Runner-up:** [VexRiscv](https://github.com/SpinalHDL/VexRiscv) if the team strongly prefers a
Verilog-adjacent flow and wants the most *programmable* plugin-based custom-instruction hook (at the cost of a
SpinalHDL/sbt code-generation step); **[PicoRV32](https://github.com/YosysHQ/picorv32)** as the
absolute-minimum fallback — a single Verilog file with a trivially-wrapable native memory port and a PCPI
co-processor port, accepting that PCPI is non-branching-only and has no memory access of its own.

---

## Sources

- PicoRV32 README (ISA/config, 750–2000 LUTs & 250–450 MHz, ISC, native/axi/wb memory, PCPI): <https://github.com/YosysHQ/picorv32>
- SERV README (125/198 LUT, 2.1 kGE, ISC, Wishbone via Servant): <https://github.com/olofk/serv> · user manual <https://serv.readthedocs.io>
- VexRiscv README (area/fmax table, MIT, AXI4/Avalon/Wishbone, plugin custom-instruction example): <https://github.com/SpinalHDL/VexRiscv>
- NEORV32 README + datasheet (BSD-3, CFU/Xcfu, XBUS Wishbone + AXI4 bridge, 2300 LUTs/130 MHz, ACT results): <https://github.com/stnolting/neorv32> · <https://stnolting.github.io/neorv32>
- Ibex README (configs 16.85–66 kGE, CoreMark/MHz, RV32IMC+B, Apache-2.0): <https://github.com/lowRISC/ibex>
- DarkRISCV README (RV32I/E, 850–1500 LUTs, 250 MHz, BSD, Harvard bus + MAC/DBNZ): <https://github.com/darklife/darkriscv>
- Rocket Chip (in-order, TileLink, ROCC) + RoCC accelerator guide: <https://github.com/chipsalliance/rocket-chip> · <https://chipyard.readthedocs.io/en/1.7.0/Customization/RoCC-Accelerators.html>
- CV32E40P user manual (coprocessor interface, Xpulp, license): <https://docs.openhwgroup.org/projects/cv32e40p-user-manual/>
- Hummingbird E203 (NICE custom-instruction interface): <https://github.com/riscv-mcu/e203_hbirdv2>
