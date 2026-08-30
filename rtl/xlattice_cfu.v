// ============================================================================
// xlattice_cfu.v — the Xlattice co-processor datapath (Phase 4, integration seam).
//
// The combinational unit that a RISC-V core's custom-instruction port (e.g. NEORV32's
// CFU) instantiates: it decodes the custom-0 encoding from
// docs/riscv_survey/xlattice_encoding.md and computes the result using the ALREADY
// verified ternary cells (rtl/ga_ops.v).  This is the bridge between the binary core's
// custom-0 dispatch and the ternary datapath — the "co-processor" of the plan.
//
// Operands are 12-trit words (24 bits, 2 bits/trit, 01=+1/00=0/10=-1/11=NEVER);
// a-field = bits[11:0], b-field = bits[23:12].
//
// Implemented here (the pure-combinational scalar/GA subset — the pod ops TGRAD/TRELAX/
// TRECON need the hex-memory interface and are a separate unit):
//   TCONJ   funct3=001 funct7=0000001  rd = conj(z)  = (a+b, -b)
//   TDOT    funct3=000 funct7=0000100  rd = (dot, 0)  dot  = ac+ad+bd
//   TWEDGE  funct3=000 funct7=0000101  rd = (wedge,0) wedge= bc-ad
//   TSYMDOT funct3=000 funct7=0000110  rd = (symdot,0) symdot= 2ac+ad+bc+2bd
//
// Reuses rtl/ga_ops.v: tconj_trits (Conjugate.lean) + ga_split_trits (DotWedge/SymDot).
// Result is the low 6 trits per coefficient (the cpu.v fit convention); ovf latches any
// 6-trit overflow or an 11=NEVER canary.
//
// Verilog-2001; synthesizable.
// ============================================================================

`timescale 1ns/1ps

`include "rtl/trit_functions.vh"

module xlattice_cfu (
  output reg  [23:0] rd,      // result word (a-field = scalar for the GA ops)
  output reg         ovf,
  input  wire [6:0]  funct7,
  input  wire [2:0]  funct3,
  input  wire [23:0] z,       // rs1: operand z = (a,b)
  input  wire [23:0] w        // rs2: operand w = (c,d)
);
  `DEF_TERNARY_GATES

  wire [11:0] za = z[11:0],  zb = z[23:12];
  wire [11:0] wa = w[11:0],  wb = w[23:12];

  // ---- the verified GA cells (shared) ---------------------------------------
  wire [11:0] conj_a6;            // low 6 trits of a+b (tconj_trits stores 6 + ofit)
  wire [11:0] conj_b6;            // -b, 6 trits
  wire        conj_ofit;
  tconj_trits #(.NTRITS(6)) u_tconj (
    .a_out(conj_a6), .b_out(conj_b6), .ofit(conj_ofit),
    .a(za), .b(zb));

  wire [27:0] ga_dot, ga_wedge, ga_symdot;   // 14 trits each
  ga_split_trits #(.NTRITS(6)) u_ga (
    .dot(ga_dot), .wedge(ga_wedge), .symdot(ga_symdot),
    .a(za), .b(zb), .c(wa), .d(wb));

  // fit: any trit above position 5 set -> overflow
  wire dot_ofit    = |ga_dot[27:12];
  wire wedge_ofit  = |ga_wedge[27:12];
  wire symdot_ofit = |ga_symdot[27:12];

  always @(*) begin
    rd  = 24'b0;
    ovf = 1'b0;
    case ({funct3, funct7})
      10'b001_0000001: begin              // TCONJ
        rd  = {conj_b6, conj_a6};
        ovf = conj_ofit;
      end
      10'b000_0000100: begin              // TDOT -> a-field scalar
        rd  = {12'b0, ga_dot[11:0]};
        ovf = dot_ofit;
      end
      10'b000_0000101: begin              // TWEDGE
        rd  = {12'b0, ga_wedge[11:0]};
        ovf = wedge_ofit;
      end
      10'b000_0000110: begin              // TSYMDOT
        rd  = {12'b0, ga_symdot[11:0]};
        ovf = symdot_ofit;
      end
      default: begin                      // unimplemented / other ops
        rd  = 24'b0;
        ovf = 1'b0;
      end
    endcase
  end
endmodule
