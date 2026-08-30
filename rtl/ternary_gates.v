// ============================================================================
// ternary_gates.v — balanced-ternary gate library (naive MVP, combinational).
//
// First Verilog for the balanced-ternary processor.  No pipeline, no
// optimization: the goal is to prove the ternary logic computes correctly
// and synthesizes cleanly.
//
// ----------------------------------------------------------------------------
// 1. TRIT ENCODING — one-hot-per-direction (2 wires, 2 bits per trit)
// ----------------------------------------------------------------------------
// A trit is {pull, push}: the pull line and the push line of a 2-diode cell.
//
//     value    bits     energized wires
//     -----    ----     ---------------
//      +1      2'b01    push only
//       0      2'b00    neither (null — nothing energized)
//      -1      2'b10    pull only
//      11      2'b11    BOTH — never produced, a reusable don't-care state
//
// This is exactly the Lean-proved cell in
//   proofs/lean-src/hexagon/Hexagon/TernaryCell.lean :
//     encode            (L31) : .pos => (true,false), .zero => (false,false),
//                               .neg => (false,true)   -- one hot per direction
//     energy_le_one     (L54) : at most ONE line energized per state
//     null_is_free      (L51) : energy .zero = 0        (0 is "free")
//     energy_pos/neg    (L41,47): the two live states cost exactly 1 each
//     encode_never_both (L96) : encode t != (true,true) -- the 11 state is
//                               never produced (this RTL never emits 2'b11)
//     average_energy    (L65) : 2/3 of a wire per trit < 1 wire per binary
//                               bit (ternary_saves_third, L89)
//
// ----------------------------------------------------------------------------
// 2. WORD LAYOUT — a register is a lattice point a + b*w  (Eisenstein Z[w])
// ----------------------------------------------------------------------------
// Word = 12 trits = 24 bits (TERNARY_PROCESSOR.md sec.2.2: 12-trit word):
//     bits [11:0]  = coefficient a,  6 trits, balanced signed in [-364, +364]
//     bits [23:12] = coefficient b,  6 trits, balanced signed in [-364, +364]
// The 6+6 split is what makes the Z6 gauge ops (TROT) and the norm (TNORM)
// well-defined: every register is a lattice point, and TADD/TSUB are the
// coefficient-wise vector add (each field a real balanced ripple adder).
//
// ----------------------------------------------------------------------------
// 3. CELLS PROVIDED
// ----------------------------------------------------------------------------
// Per-trit (from trit_functions.vh, expand with `DEF_TERNARY_GATES):
//   tneg  — ternary invert (+1 <-> -1, 0 -> 0): a wire swap
//   tand  — min (the lesser trit)              [lattice meet]
//   tor   — max (the greater trit)             [lattice join]
//   tmul  — trit x trit product (sign product, null absorbs)
//   tadd1 — full-adder cell {cout, sum} with the balanced carry rule
//           (+1 + +1 = -1 carry +1;  -1 + -1 = +1 carry -1)
// Word-level (modules below):
//   tadd_trits  #(NTRITS)  — NTRITS-trit ripple-carry balanced adder
//   tmul_trits  #(NTRITS)  — NTRITS x NTRITS-trit shift-add multiplier
//   tnorm_trits #(NTRITS)  — N(a,b) = a^2 + ab + b^2
//                            (Gauge.lean `norm_eq_det`: the norm IS the
//                             determinant of the regular representation, the
//                             area scalar; Z6-invariant by norm_mul_unit)
// ============================================================================

`timescale 1ns/1ps

`include "rtl/trit_functions.vh"

// ----------------------------------------------------------------------------
// tadd_trits: NTRITS-trit ripple-carry balanced adder (combinational).
// ----------------------------------------------------------------------------
module tadd_trits #(parameter NTRITS = 6) (
  output reg  [2*NTRITS-1:0] sum,
  output reg  [1:0]          cout,
  input       [2*NTRITS-1:0] a, b,
  input       [1:0]          cin
);
  `DEF_TERNARY_GATES

  // Ripple of identical tadd1 cells, unrolled by the constant-bound loop.
  // (Note: Icarus' parser rejects multiple continuous assignments to elements
  // of an unpacked wire array, so the carry is kept in a plain reg.)
  integer i;
  reg [1:0] c;
  always @(*) begin
    c = cin;
    for (i = 0; i < NTRITS; i = i + 1)
      {c, sum[i*2 +: 2]} = tadd1(a[i*2 +: 2], b[i*2 +: 2], c);
    cout = c;
  end
endmodule

// ----------------------------------------------------------------------------
// tmul_trits: NTRITS x NTRITS-trit balanced multiplier (shift-add, comb.).
//   prod = sum_j b_j * a * 3^j.  Each partial product b_j*a is digit-wise
//   (multiplying a whole balanced number by a SINGLE trit never carries, so
//   each partial product is just the digit products placed at positions
//   j..j+NTRITS-1).  The true product fits 2*NTRITS trits; we accumulate in a
//   (2*NTRITS+1)-trit register whose top trit is provably 0.
// ----------------------------------------------------------------------------
module tmul_trits #(parameter NTRITS = 6) (
  output reg  [4*NTRITS-1:0] prod,       // 2*NTRITS trits
  input       [2*NTRITS-1:0] a, b
);
  `DEF_TERNARY_GATES

  localparam ACCBITS = 2*(2*NTRITS+1);   // (2*NTRITS+1) trits of headroom
  reg [ACCBITS-1:0] acc, pp;
  reg [1:0] c;
  integer i, j;

  always @(*) begin
    acc = {ACCBITS{1'b0}};
    for (j = 0; j < NTRITS; j = j + 1) begin
      pp = {ACCBITS{1'b0}};
      for (i = 0; i < NTRITS; i = i + 1)
        pp[(i+j)*2 +: 2] = tmul(a[i*2 +: 2], b[j*2 +: 2]);
      // ripple-add partial product pp into acc over (2*NTRITS+1) trits
      c = 2'b00;
      for (i = 0; i < 2*NTRITS+1; i = i + 1)
        {c, acc[i*2 +: 2]} = tadd1(acc[i*2 +: 2], pp[i*2 +: 2], c);
    end
    prod = acc[4*NTRITS-1:0];
  end
endmodule

// ----------------------------------------------------------------------------
// tnorm_trits: N(a,b) = a^2 + ab + b^2  (Gauge.lean `norm_eq_det`).
//   |a|,|b| <= (3^NTRITS-1)/2, so N <= 3*((3^NTRITS-1)/2)^2 which fits in
//   2*NTRITS+1 trits.  The exact value is computed in 2*NTRITS+1 trits and
//   the low NTRITS trits are returned; `ofit` = 1 when N does NOT fit in
//   NTRITS trits (i.e. any trit above position NTRITS-1 is non-null).
// ----------------------------------------------------------------------------
module tnorm_trits #(parameter NTRITS = 6) (
  output reg              [2*NTRITS-1:0] n,
  output reg              ofit,
  input                   [2*NTRITS-1:0] a, b
);
  `DEF_TERNARY_GATES

  localparam RTRITS = 2*NTRITS + 1;      // N always fits in here

  wire [4*NTRITS-1:0]     aa, ab, bb;    // three 2*NTRITS-trit products
  tmul_trits #(.NTRITS(NTRITS)) m_aa (.prod(aa), .a(a), .b(a));
  tmul_trits #(.NTRITS(NTRITS)) m_ab (.prod(ab), .a(a), .b(b));
  tmul_trits #(.NTRITS(NTRITS)) m_bb (.prod(bb), .a(b), .b(b));

  wire [2*RTRITS-1:0] aa_p = {{(2*RTRITS-4*NTRITS){1'b0}}, aa};
  wire [2*RTRITS-1:0] ab_p = {{(2*RTRITS-4*NTRITS){1'b0}}, ab};
  wire [2*RTRITS-1:0] bb_p = {{(2*RTRITS-4*NTRITS){1'b0}}, bb};

  reg [2*RTRITS-1:0] s1, s2;
  reg [1:0] c;
  integer i;

  always @(*) begin
    // s1 = aa + ab  (ripple over RTRITS trits)
    c = 2'b00;
    for (i = 0; i < RTRITS; i = i + 1)
      {c, s1[i*2 +: 2]} = tadd1(aa_p[i*2 +: 2], ab_p[i*2 +: 2], c);
    // s2 = s1 + bb
    c = 2'b00;
    for (i = 0; i < RTRITS; i = i + 1)
      {c, s2[i*2 +: 2]} = tadd1(s1[i*2 +: 2], bb_p[i*2 +: 2], c);
    // fit check: trits NTRITS..RTRITS-1 must all be null
    ofit = 1'b0;
    for (i = NTRITS; i < RTRITS; i = i + 1)
      if (s2[i*2 +: 2] != 2'b00) ofit = 1'b1;
    n = s2[2*NTRITS-1:0];
  end
endmodule
