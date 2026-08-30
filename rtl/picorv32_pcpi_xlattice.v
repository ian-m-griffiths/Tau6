// ============================================================================
// picorv32_pcpi_xlattice.v — the Xlattice co-processor via PicoRV32's PCPI port.
//
// Pico Co-Processor Interface (PCPI), grounded from picorv32/picorv32.v (cloned this
// session): the core asserts pcpi_valid + pcpi_insn (the full custom instruction) +
// pcpi_rs1/rs2; the co-processor returns pcpi_rd (result) + pcpi_wr/ready (done).
// This is the SAME shape as NEORV32's CFU port, so the Xlattice core (xlattice_cfu)
// is core-agnostic — it plugs into both the NEORV32 CFU and the PicoRV32 PCPI.
//
// Handles custom-0 (opcode 0x0B) R-type; combinational, so pcpi_ready follows
// pcpi_valid in the same cycle (no pcpi_wait).
//
// Verilog-2001; synthesizable.
// ============================================================================

`timescale 1ns/1ps

module picorv32_pcpi_xlattice (
  input  wire        pcpi_valid,
  input  wire [31:0] pcpi_insn,
  input  wire [31:0] pcpi_rs1,
  input  wire [31:0] pcpi_rs2,
  output wire        pcpi_wr,
  output wire [31:0] pcpi_rd,
  output wire        pcpi_wait,
  output wire        pcpi_ready
);
  wire is_custom0 = pcpi_valid && (pcpi_insn[6:0] == 7'b0001011);   // custom-0
  wire [6:0] funct7 = pcpi_insn[31:25];
  wire [2:0] funct3 = pcpi_insn[14:12];
  wire [23:0] z = pcpi_rs1[23:0];
  wire [23:0] w = pcpi_rs2[23:0];

  wire [23:0] rd;
  wire        ovf;
  xlattice_cfu u_cfu (
    .rd(rd), .ovf(ovf),
    .funct7(funct7), .funct3(funct3),
    .z(z), .w(w));

  assign pcpi_rd    = {8'b0, rd};
  assign pcpi_wr    = is_custom0;
  assign pcpi_ready = is_custom0;
  assign pcpi_wait  = 1'b0;    // combinational: no wait cycles
endmodule
