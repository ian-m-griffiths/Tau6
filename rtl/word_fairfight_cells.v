// ============================================================================
// word_fairfight_cells.v — word-level datapath wrappers for the WORD-LEVEL
// "fair fight" area benchmark (equal-information datapaths):
//
//     6 trits = 3^6 = 729 states   vs   10 bits = 2^10 = 1024 states
//
// Each datapath is its own top-level module with all I/O on ports, so yosys
// synthesizes it in isolation (nothing constant-folds or merges away), mapped
// into the SkyWater 130nm high-density library — the exact flow of
// rtl/gate_area.sh / rtl/yosys_report.sh.
//
// TRIT ENCODING (2 bits per trit, one-hot-per-direction — trit_functions.vh):
//     2'b01 = +1,  2'b00 = 0,  2'b10 = -1,  2'b11 = NEVER
//
//   wf_tadd6  — 6-trit ripple-carry balanced adder   (6 x tadd1)
//   wf_badd10 — 10-bit ripple-carry binary adder      (10 x binary full adder)
//   wf_tmul6  — 6-trit multiplier = tmul_trits_opt   (Karatsuba, as specified)
//   wf_tmul6_sa — 6-trit multiplier = tmul_sa        (plain shift-add, for the
//                 honest apples-to-apples vs the simple shift-add binary mult)
//   wf_bmul10 — 10-bit binary shift-add multiplier    (simple, combinational)
// ============================================================================

`timescale 1ns/1ps

`include "rtl/trit_functions.vh"

// ---------------------------------------------------------------------------
// Ternary: 6-trit ripple-carry balanced adder (6 x tadd1).
// ---------------------------------------------------------------------------
module wf_tadd6 (
  input  [11:0] a, b,
  input  [1:0]  cin,
  output [11:0] sum,
  output [1:0]  cout
);
  `DEF_TERNARY_GATES

  integer i;
  reg [1:0] c;
  always @(*) begin
    c = cin;
    for (i = 0; i < 6; i = i + 1)
      {c, sum[i*2 +: 2]} = tadd1(a[i*2 +: 2], b[i*2 +: 2], c);
    cout = c;
  end
endmodule

// ---------------------------------------------------------------------------
// Binary: full adder cell, then a 10-bit ripple-carry adder (10 x wf_badd1).
// ---------------------------------------------------------------------------
module wf_badd1 (input a, input b, input cin, output sum, output cout);
  assign sum  = a ^ b ^ cin;
  assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

module wf_badd10 (
  input  [9:0] a, b,
  input        cin,
  output [9:0] sum,
  output       cout
);
  wire [9:0] c;                       // inter-stage carries c[0]..c[8], c[9]=cout
  genvar i;
  generate
    for (i = 0; i < 10; i = i + 1) begin : fa
      if (i == 0)
        wf_badd1 u (.a(a[0]),  .b(b[0]),  .cin(cin),    .sum(sum[0]), .cout(c[0]));
      else
        wf_badd1 u (.a(a[i]),  .b(b[i]),  .cin(c[i-1]), .sum(sum[i]), .cout(c[i]));
    end
  endgenerate
  assign cout = c[9];
endmodule

// ---------------------------------------------------------------------------
// Ternary multiplier: 6-trit, tmul_trits_opt (Karatsuba) — the module the task
// names.  prod = a*b exact in 12 trits (24 bits).
// ---------------------------------------------------------------------------
module wf_tmul6 (
  input  [11:0] a, b,
  output [23:0] prod
);
  tmul_trits_opt #(.NTRITS(6)) u (.prod(prod), .a(a), .b(b));
endmodule

// ---------------------------------------------------------------------------
// Ternary multiplier (bonus): plain shift-add tmul_sa, the fair structural
// counterpart of the simple shift-add binary multiplier below.  (At N=6 the
// Karatsuba tmul_trits_opt is actually LARGER than this — see arithmetic.md —
// so this is measured too for honesty.)
// ---------------------------------------------------------------------------
module wf_tmul6_sa (
  input  [11:0] a, b,
  output [23:0] prod
);
  tmul_sa #(.NTRITS(6)) u (.prod(prod), .a(a), .b(b));
endmodule

// ---------------------------------------------------------------------------
// Binary multiplier: 10-bit x 10-bit -> 20-bit, simple combinational shift-add.
// prod = sum_{j=0..9} (a * b[j]) << j, accumulated by a ripple of 9 adds.
// (a * b[j] is a 10-bit AND; the partial product is shifted into place.)
// ---------------------------------------------------------------------------
module wf_bmul10 (
  input  [9:0] a, b,
  output reg [19:0] prod
);
  integer j;
  reg [19:0] acc;
  reg [9:0]  pp;
  always @(*) begin
    acc = 20'b0;
    for (j = 0; j < 10; j = j + 1) begin
      pp  = a & {10{b[j]}};                 // a * b[j], 10-bit digit product
      acc = acc + ({10'b0, pp} << j);       // shift into bit position j, add
    end
    prod = acc;
  end
endmodule
