# Real SkyWater 130nm Synthesis Results (2026-08-28)

Built the sky130_fd_sc_hd liberty from source and re-ran the yosys report with it.
All numbers below are REAL (µm², ns, mW) from the PDK liberty — no synthetic
unit-delay model.

## Liberty used
- `rtl/sky130_fd_sc_hd.lib` = `sky130_fd_sc_hd__tt_025C_1v80` (typical corner,
  25 °C, 1.8 V), 452 cells, 13 MB, compiled from the open-source characterization
  JSON via the official skywater-pdk converter + open_pdks staging.
- Full PDK staging with all 16 corners: `~/open_pdks/sky130/sky130A/libs.ref/sky130_fd_sc_hd/lib/`

## yosys report (`rtl/yosys_report.txt`, real-liberty flow)
- Design: cpu (single-cycle ternary CPU, 12-trit words, 2 bits/trit)
- Number of cells: 3970 (3748 sky130 cells + 213 regfile write-mux `$_MUX_` +
  imem ROM `$memrd`/`$meminit` + metadata)
- Sequential: 214 FFs (sky130_fd_sc_hd__dfrtp_1, async-reset DFF)
- **Chip area: 26,713.12 µm²**  (of which sequential: 5,355.14 µm² = 20.05%)
- Top cells: nand2_1 450, nor2_1 395, a21oi_1 278, o21ai_0 271, a22oi_1 207,
  nor3_1 157, nand3_1 133, dfrtp_1 214, and2_0 91 ...
- Note: the 213 `$_MUX_` write-mux cells + the imem ROM read port are counted as
  cells but NOT included in the area total (yosys `stat` has no area for them);
  a fully-mapped netlist (memory expanded, muxes mapped) measures
  **29,333 µm²** — the +9.8% is the regfile write-mux + ROM decode logic.

## Timing (OpenSTA 2.0.17 on the fully-mapped netlist, no wire load = ideal)
| Corner | Critical path | Fmax |
|--------|---------------|------|
| tt_025C_1v80 (typical) | 19.899 ns | **50.25 MHz** |
| ss_100C_1v40 (slowest) | 61.243 ns | **16.33 MHz** |
| ff_n40C_1v95 (fastest) | 11.59 ns | **86.3 MHz** |

Critical path: regfile write path (register write-enable mux chain, ~22 gate
levels), ending at a dfrtp_1. abc's own `stime` on the combinational cone gave
17.27 ns — consistent with the reg-to-reg 19.9 ns.

## Power (OpenSTA report_power, tt corner, 20 ns clock, default activity)
- Switching: 1.60 mW
- Leakage: 9.85 nW
- Internal (dynamic): not reported — this apt OpenSTA 2.0.17 build (2019) does
  not compute internal_power from the lib's power tables. The liberty DOES carry
  full internal_power + leakage data, so a newer OpenSTA/OpenROAD would add the
  internal term; switching dominates for this small combinational-heavy core.
- yosys 0.52 `stat -power` is NOT compiled into this build (rejected).

## Honest coverage
- REAL: area (µm²), cell count, FFs, critical path (ns) per corner, max clock
  frequency, switching + leakage power.
- STILL NEEDS A SEPARATE TOOL: full power (internal/dynamic term) — needs
  OpenSTA ≥ 2.x modern build or PowerScene; and the imem ROM read port should
  ideally be mapped to a real SRAM/ROM macro (OpenRAM) for a production number
  (here it's synthesized into logic: +~2.6k µm²).

## Build notes / gotchas
- Modern sky130_fd_sc_hd repo ships ONLY `timing/*.lib.json` (characterization),
  no compiled `.lib` — the compile step is `python -m skywater_pdk.liberty
  <libdir> all` from google/skywater-pdk (umbrella repo), which writes
  `timing/*.lib`. open_pdks' Makefile then consumes those.
- `./configure` hard-requires `magic` even for a lib-only build; installed the
  Ubuntu magic package locally (no root): `apt-get download magic`, extract,
  repath wrapper to `~/pdk-tools/magic/tcl` and `~/bin/magic`. GDS migration
  step still failed to run magic inside open_pdks (harmless for the lib).
- Configure flags used: `--enable-sky130-pdk --enable-sc-hd-sky130=$HOME/sky130-libs
  --with-sky130-variants=A --disable-gf180mcu-pdk --disable-<other sky130 libs>`
  (otherwise configure auto-downloads every library, GBs).
