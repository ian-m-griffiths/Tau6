# Third-party dependencies

This project depends on two third-party hardware cores. They are **not vendored
in this repository** — clone them separately and place them at the expected
paths, under their own licenses:

| component | source | license | used by |
|---|---|---|---|
| **PicoRV32** | https://github.com/YosysHQ/picorv32 | ISC | `rtl/tau_soc.v` instantiates `picorv32/picorv32.v` |
| **NEORV32** | https://github.com/stnolting/neorv32 | BSD-3-Clause | `rtl/neorv32_cfu_xlattice.v` targets its CFU port |

All other code and documentation in this repository is MIT-licensed
(see `LICENSE`).

Note: `rtl/tau_soc.v` and its testbench read `picorv32/picorv32.v` and
`rtl/program_tau.hex` from the repository root, so clone PicoRV32 into a
top-level `picorv32/` directory before building the SoC.
