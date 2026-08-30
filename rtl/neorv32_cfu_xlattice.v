// ============================================================================
// neorv32_cfu_xlattice.v — the Xlattice CFU adapter for the NEORV32 CFU port.
//
// Wraps rtl/xlattice_cfu.v behind the EXACT NEORV32 Custom Functions Unit interface
// (grounded from neorv32/rtl/core/neorv32_cpu_alu_cfu.vhd, cloned this session):
//
//   clk_i, rstn_i          global control
//   start_i                start trigger (single-shot); inst_i is a full R-type word
//   inst_i[31:0]           the FULL instruction word (the CFU decodes it itself)
//   rs1_i / rs2_i          the 32-bit register operands (low 24 bits = the 12-trit word)
//   result_o / valid_o     the 32-bit result + done flag
//
// The Xlattice ops are combinational, so valid_o follows start_i (single-cycle CFU; the
// NEORV32 XTEA example is multi-cycle because it is iterative — ours is not).
//
// Decode (per docs/riscv_survey/xlattice_encoding.md): funct7 = inst_i[31:25],
// funct3 = inst_i[14:12]; the 12-trit word is the low 24 bits of rs1/rs2.
//
// This is the module NEORV32's CFU port instantiates (VHDL<->Verilog glue or the
// auto-Verilog conversion is the remaining SoC-level wiring).
//
// Verilog-2001; synthesizable.
// ============================================================================

`timescale 1ns/1ps

module neorv32_cfu_xlattice (
  input  wire        clk_i,
  input  wire        rstn_i,
  input  wire        start_i,
  input  wire [31:0] inst_i,
  input  wire [31:0] rs1_i,
  input  wire [31:0] rs2_i,
  output wire [31:0] result_o,
  output wire        valid_o
);
  wire [6:0] funct7 = inst_i[31:25];
  wire [2:0] funct3 = inst_i[14:12];
  wire [23:0] z = rs1_i[23:0];
  wire [23:0] w = rs2_i[23:0];

  wire [23:0] rd;
  wire        ovf;
  xlattice_cfu u_cfu (
    .rd(rd), .ovf(ovf),
    .funct7(funct7), .funct3(funct3),
    .z(z), .w(w));

  assign result_o = {8'b0, rd};   // zero-extend the 24-bit word to 32
  assign valid_o  = start_i;      // combinational: result valid in the start cycle
endmodule
