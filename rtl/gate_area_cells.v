// ============================================================================
// gate_area_cells.v — one wrapper module per gate, for the AREA benchmark.
//
// Each gate is its own top-level module with all I/O on ports, so yosys can
// synthesize it in isolation (nothing gets constant-folded or merged away).
//
// TRIT ENCODING (2 bits per trit, one-hot-per-direction — see trit_functions.vh):
//     2'b01 = +1   (bit[0] = push line)
//     2'b00 =  0   (null)
//     2'b10 = -1   (bit[1] = pull line)
//     2'b11 = NEVER (don't-care input)
//
// TERNARY gates (1 trit = 2 wires):
//   gate_tneg   NOT / negation        (+1 <-> -1, 0 -> 0): a wire swap
//   gate_tmin   MIN (lattice meet)    lesser trit, ordering -1 < 0 < +1
//   gate_tmax   MAX (lattice join)    greater trit
//   gate_tadd1  mod-3 sum (full-adder cell)  -> {cout, sum}, balanced carry
//
// BINARY gates (1 bit = 1 wire):
//   gate_not    NOT
//   gate_nand2  NAND
//   gate_nor2   NOR
//   gate_badd1  binary full adder  (EXTRA reference: the honest binary
//               counterpart of the ternary mod-3 sum / full-adder cell)
// ============================================================================

`timescale 1ns/1ps

`include "rtl/trit_functions.vh"

// ---------------------------------------------------------------------------
// Ternary gates
// ---------------------------------------------------------------------------

module gate_tneg (input [1:0] a, output [1:0] y);
  `DEF_TERNARY_GATES
  assign y = tneg(a);
endmodule

module gate_tmin (input [1:0] a, input [1:0] b, output [1:0] y);
  `DEF_TERNARY_GATES
  assign y = tand(a, b);
endmodule

module gate_tmax (input [1:0] a, input [1:0] b, output [1:0] y);
  `DEF_TERNARY_GATES
  assign y = tor(a, b);
endmodule

module gate_tadd1 (input [1:0] a, input [1:0] b, input [1:0] cin,
                   output [1:0] sum, output [1:0] cout);
  `DEF_TERNARY_GATES
  // tadd1 = {con, cop, sn, sp} -> cout = {con,cop} = [3:2], sum = {sn,sp} = [1:0]
  wire [3:0] r = tadd1(a, b, cin);
  assign cout = r[3:2];
  assign sum  = r[1:0];
endmodule

// ---------------------------------------------------------------------------
// Binary gates
// ---------------------------------------------------------------------------

module gate_not (input a, output y);
  assign y = ~a;
endmodule

module gate_nand2 (input a, input b, output y);
  assign y = ~(a & b);
endmodule

module gate_nor2 (input a, input b, output y);
  assign y = ~(a | b);
endmodule

// Binary full adder — the honest area counterpart of gate_tadd1 (a full adder
// that maps 2 operands + carry-in to a sum digit + carry-out).
module gate_badd1 (input a, input b, input cin, output sum, output cout);
  assign sum  = a ^ b ^ cin;
  assign cout = (a & b) | (a & cin) | (b & cin);
endmodule
