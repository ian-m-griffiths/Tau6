// ============================================================================
// tmul_opt.v — optimized balanced-ternary multiplier / norm for the ternary
// CPU.  Drop-in replacements for tmul_trits / tnorm_trits (ternary_gates.v)
// plus a Karatsuba Eisenstein lattice-point multiplier.
//
// The two algebraic identities used (integer-exact, no floats):
//
//   1. KARATSUBA FOR EISENSTEIN MULTIPLY (60-degree convention w^2 = w - 1):
//        (a + b*w)(c + d*w) = (a*c - b*d) + (a*d + b*c + b*d)*w
//        A = a*c - b*d
//        B = (a+b)(c+d) - a*c            (since (a+b)(c+d) - ac = ad+bc+bd)
//      => 3 scalar products (ac, bd, (a+b)(c+d)) + 2 subtractions, instead of
//      the naive 4 products (ac, ad, bc, bd).  See tmul_eisen_trits.
//
//   2. NORM IN 2 PRODUCTS:
//        N(a,b) = a^2 + a*b + b^2 = (a+b)^2 - a*b
//      => 2 scalar products (sq(a+b), ab) instead of the 3 (a^2, ab, b^2)
//      that tnorm_trits wraps.  See tnorm_trits_opt.
//
// tmul_trits_opt is the scalar Karatsuba multiplier (split the N-trit
// operands into low/high halves; 3 half-size products: p0 = lo*lo,
// p2 = hi*hi, p1 = (lo+hi)(lo+hi') minus p0, p2).  At NTRITS = 6 the leaf
// shift-add multipliers are already cheap (multiplying by a single trit
// never carries), so Karatsuba's added combine logic typically LOSES to the
// plain shift-add — the win here is in the norm's 3 -> 2 products.  The
// crossover word size is measured empirically (see the accompanying report).
//
// All widths: a coefficient is NTRITS trits = 2*NTRITS bits; a product is
// 2*NTRITS trits; the Eisenstein product's B coefficient needs 2*NTRITS+1
// trits (ad+bc+bd can reach 3*((3^N-1)/2)^2).
// ============================================================================

`timescale 1ns/1ps

`include "rtl/trit_functions.vh"

// ----------------------------------------------------------------------------
// tmul_sa: NTRITS x NTRITS-trit balanced shift-add multiplier (private copy
// of tmul_trits so this file is self-contained).  prod = a*b, exact in
// 2*NTRITS trits.
// ----------------------------------------------------------------------------
module tmul_sa #(parameter NTRITS = 6) (
  output reg  [4*NTRITS-1:0] prod,
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
// tadd_n: NTRITS-trit ripple-carry balanced adder, sum = a + b + cin.
// ----------------------------------------------------------------------------
module tadd_n #(parameter NTRITS = 6) (
  output reg  [2*NTRITS-1:0] sum,
  output reg  [1:0]          cout,
  input       [2*NTRITS-1:0] a, b,
  input       [1:0]          cin
);
  `DEF_TERNARY_GATES

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
// tsub_n: NTRITS-trit ripple subtract, diff = a - b.  Balanced negation is a
// free per-digit wire swap (tneg), so this is a negate + ripple add.
// ----------------------------------------------------------------------------
module tsub_n #(parameter NTRITS = 6) (
  output reg  [2*NTRITS-1:0] diff,
  output reg  [1:0]          cout,
  input       [2*NTRITS-1:0] a, b
);
  `DEF_TERNARY_GATES

  integer i;
  reg [1:0] c;
  reg [2*NTRITS-1:0] nb;
  always @(*) begin
    for (i = 0; i < NTRITS; i = i + 1)
      nb[i*2 +: 2] = tneg(b[i*2 +: 2]);
    c = 2'b00;
    for (i = 0; i < NTRITS; i = i + 1)
      {c, diff[i*2 +: 2]} = tadd1(a[i*2 +: 2], nb[i*2 +: 2], c);
    cout = c;
  end
endmodule

// ----------------------------------------------------------------------------
// tmul_trits_opt: NTRITS x NTRITS-trit balanced multiplier via Karatsuba.
//   Drop-in for tmul_trits (same ports, same exact 2*NTRITS-trit result).
//   Split:  a = a_hi*3^K + a_lo,  b = b_hi*3^K + b_lo,  K = NTRITS/2.
//     p0 = a_lo*b_lo            (K x K)
//     p2 = a_hi*b_hi            ((NTRITS-K) x (NTRITS-K))
//     p1 = (a_lo+a_hi)(b_lo+b_hi)          ((K+1) x (K+1))
//     z1 = p1 - p0 - p2  (= a_lo*b_hi + a_hi*b_lo, fits NTRITS trits)
//     prod = p0 + z1*3^K + p2*3^(2K)
//   Only NTRITS >= 2 is meaningful (K >= 1).
// ----------------------------------------------------------------------------
module tmul_trits_opt #(parameter NTRITS = 6) (
  output wire [4*NTRITS-1:0] prod,
  input      [2*NTRITS-1:0]  a, b
);
  `DEF_TERNARY_GATES

  localparam K  = NTRITS / 2;         // low-half trits (floor)
  localparam LH = NTRITS - K;         // high-half trits
  localparam S  = K + 1;              // trits of (lo + hi)
  localparam PW = 2*NTRITS;           // product trits

  wire [2*K-1:0]        a_lo = a[2*K-1:0];
  wire [2*LH-1:0]       a_hi = a[2*NTRITS-1:2*K];
  wire [2*K-1:0]        b_lo = b[2*K-1:0];
  wire [2*LH-1:0]       b_hi = b[2*NTRITS-1:2*K];

  // p0 = lo*lo (2K trits), p2 = hi*hi (2*LH trits)
  wire [4*K-1:0]        p0;
  wire [4*LH-1:0]       p2;
  tmul_sa #(.NTRITS(K))  u_p0 (.prod(p0), .a(a_lo), .b(b_lo));
  tmul_sa #(.NTRITS(LH)) u_p2 (.prod(p2), .a(a_hi), .b(b_hi));

  // s = a_lo + a_hi, t = b_lo + b_hi  (S trits each)
  wire [2*S-1:0] s, t;
  wire [1:0]     cs, ct;
  tadd_n #(.NTRITS(S)) u_s (
    .sum(s), .cout(cs),
    .a({{(2*(S-K)){1'b0}}, a_lo}),
    .b({{(2*(S-LH)){1'b0}}, a_hi}),
    .cin(2'b00));
  tadd_n #(.NTRITS(S)) u_t (
    .sum(t), .cout(ct),
    .a({{(2*(S-K)){1'b0}}, b_lo}),
    .b({{(2*(S-LH)){1'b0}}, b_hi}),
    .cin(2'b00));

  // p1 = s*t (2*S trits)
  wire [4*S-1:0] p1;
  tmul_sa #(.NTRITS(S)) u_p1 (.prod(p1), .a(s), .b(t));

  // z1 = p1 - p0 - p2, computed exactly in 2*S trits (true z1 fits NTRITS)
  wire [4*S-1:0] p0x = {{(4*(S-K)){1'b0}},  p0};
  wire [4*S-1:0] p2x = {{(4*(S-LH)){1'b0}}, p2};
  wire [4*S-1:0] z1a, z1;
  tsub_n #(.NTRITS(2*S)) u_z1a (.diff(z1a), .cout(), .a(p1), .b(p0x));
  tsub_n #(.NTRITS(2*S)) u_z1b (.diff(z1),  .cout(), .a(z1a), .b(p2x));

  // combine: prod = p0 + z1*3^K + p2*3^(2K) over PW trits (exact)
  // (zero-extend to the full product width first, then shift, so the
  //  concatenations stay valid for every NTRITS >= 2)
  wire [PW*2-1:0] p0c = {{(2*(PW-2*K)){1'b0}}, p0};
  wire [PW*2-1:0] z1ext = {{(2*PW-4*S){1'b0}}, z1};
  wire [PW*2-1:0] z1s = z1ext << (2*K);
  wire [PW*2-1:0] p2ext = {{(2*PW-4*LH){1'b0}}, p2};
  wire [PW*2-1:0] p2s = p2ext << (4*K);
  wire [PW*2-1:0] acc1, acc2;
  tadd_n #(.NTRITS(PW)) u_c1 (.sum(acc1), .cout(), .a(p0c), .b(z1s), .cin(2'b00));
  tadd_n #(.NTRITS(PW)) u_c2 (.sum(acc2), .cout(), .a(acc1), .b(p2s), .cin(2'b00));

  assign prod = acc2;
endmodule

// ----------------------------------------------------------------------------
// tmul_eisen_trits: Eisenstein lattice-point multiply (Karatsuba, identity 1).
//   (a + b*w)(c + d*w) -> (A, B),  w^2 = w - 1:
//     A = a*c - b*d              (fits 2*NTRITS trits)
//     B = (a+b)(c+d) - a*c       (fits 2*NTRITS+1 trits)
//   3 scalar products instead of 4.
// ----------------------------------------------------------------------------
module tmul_eisen_trits #(parameter NTRITS = 6) (
  output wire [4*NTRITS-1:0] A_out,      // 2*NTRITS trits
  output wire [4*NTRITS+1:0] B_out,      // 2*NTRITS+1 trits
  input      [2*NTRITS-1:0]  a, b, c, d
);
  `DEF_TERNARY_GATES

  localparam R  = 2*NTRITS + 1;          // B trits
  localparam SW = NTRITS + 1;            // sum trits

  // P1 = a*c, P2 = b*d  (2*NTRITS trits)
  wire [4*NTRITS-1:0] p1, p2;
  tmul_sa #(.NTRITS(NTRITS)) u_p1 (.prod(p1), .a(a), .b(c));
  tmul_sa #(.NTRITS(NTRITS)) u_p2 (.prod(p2), .a(b), .b(d));

  // sa = a+b, sc = c+d  (SW trits)
  wire [2*SW-1:0] sa, sc;
  wire [1:0]      csa, csc;
  tadd_n #(.NTRITS(SW)) u_sa (
    .sum(sa), .cout(csa),
    .a({{(2*(SW-NTRITS)){1'b0}}, a}),
    .b({{(2*(SW-NTRITS)){1'b0}}, b}),
    .cin(2'b00));
  tadd_n #(.NTRITS(SW)) u_sc (
    .sum(sc), .cout(csc),
    .a({{(2*(SW-NTRITS)){1'b0}}, c}),
    .b({{(2*(SW-NTRITS)){1'b0}}, d}),
    .cin(2'b00));

  // P3 = sa*sc  (2*SW trits; top trit provably 0)
  wire [4*SW-1:0] p3;
  tmul_sa #(.NTRITS(SW)) u_p3 (.prod(p3), .a(sa), .b(sc));

  // A = P1 - P2 (2*NTRITS trits, exact)
  tsub_n #(.NTRITS(2*NTRITS)) u_A (
    .diff(A_out), .cout(), .a(p1), .b(p2));

  // B = P3 - P1 over R trits (P3 truncated to its low R trits; exact)
  tsub_n #(.NTRITS(R)) u_B (
    .diff(B_out), .cout(),
    .a(p3[2*R-1:0]),
    .b({{(2*R-4*NTRITS){1'b0}}, p1}));
endmodule

// ----------------------------------------------------------------------------
// tmul_eisen_naive: reference Eisenstein multiply, the direct definition
//   A = a*c - b*d,  B = a*d + b*c + b*d   (4 scalar products).
//   Kept only as the synthesis-reference baseline for tmul_eisen_trits.
// ----------------------------------------------------------------------------
module tmul_eisen_naive #(parameter NTRITS = 6) (
  output wire [4*NTRITS-1:0] A_out,
  output wire [4*NTRITS+1:0] B_out,
  input      [2*NTRITS-1:0]  a, b, c, d
);
  `DEF_TERNARY_GATES

  localparam R = 2*NTRITS + 1;

  wire [4*NTRITS-1:0] p_ac, p_ad, p_bc, p_bd;
  tmul_sa #(.NTRITS(NTRITS)) u_ac (.prod(p_ac), .a(a), .b(c));
  tmul_sa #(.NTRITS(NTRITS)) u_ad (.prod(p_ad), .a(a), .b(d));
  tmul_sa #(.NTRITS(NTRITS)) u_bc (.prod(p_bc), .a(b), .b(c));
  tmul_sa #(.NTRITS(NTRITS)) u_bd (.prod(p_bd), .a(b), .b(d));

  tsub_n #(.NTRITS(2*NTRITS)) u_A (
    .diff(A_out), .cout(), .a(p_ac), .b(p_bd));

  wire [2*R-1:0] s1, s2;
  tadd_n #(.NTRITS(R)) u_b1 (
    .sum(s1), .cout(),
    .a({{(2*R-4*NTRITS){1'b0}}, p_ad}),
    .b({{(2*R-4*NTRITS){1'b0}}, p_bc}),
    .cin(2'b00));
  tadd_n #(.NTRITS(R)) u_b2 (
    .sum(s2), .cout(),
    .a(s1),
    .b({{(2*R-4*NTRITS){1'b0}}, p_bd}),
    .cin(2'b00));
  assign B_out = s2;
endmodule

// ----------------------------------------------------------------------------
// tnorm_trits_opt: N(a,b) = a^2 + a*b + b^2 via identity 2:
//   N = (a+b)^2 - a*b   (2 scalar products instead of 3).
//   Drop-in for tnorm_trits (same ports, same n/ofit semantics):
//     n    = low NTRITS trits of the exact N
//     ofit = 1 when N does NOT fit in NTRITS trits
//   USE_KARATSUBA selects tmul_trits_opt vs tmul_sa for the two products
//   (default 0: the plain shift-add is smaller at these word sizes).
// ----------------------------------------------------------------------------
module tnorm_trits_opt #(parameter NTRITS = 6, parameter USE_KARATSUBA = 0) (
  output reg  [2*NTRITS-1:0] n,
  output reg  ofit,
  input       [2*NTRITS-1:0] a, b
);
  `DEF_TERNARY_GATES

  localparam RTRITS = 2*NTRITS + 1;      // N always fits in here
  localparam SW     = NTRITS + 1;        // a+b trits

  // s = a + b (SW trits; |a|,|b| <= (3^N-1)/2 so |s| <= 3^N-1)
  wire [2*SW-1:0] s;
  wire [1:0]      cs;
  tadd_n #(.NTRITS(SW)) u_s (
    .sum(s), .cout(cs),
    .a({{(2*(SW-NTRITS)){1'b0}}, a}),
    .b({{(2*(SW-NTRITS)){1'b0}}, b}),
    .cin(2'b00));

  // p_sq = (a+b)^2 (2*SW trits),  p_ab = a*b (2*NTRITS trits)
  wire [4*SW-1:0]     p_sq;
  wire [4*NTRITS-1:0] p_ab;
  generate
    if (USE_KARATSUBA) begin : gk
      tmul_trits_opt #(.NTRITS(SW))     u_sq (.prod(p_sq), .a(s), .b(s));
      tmul_trits_opt #(.NTRITS(NTRITS)) u_ab (.prod(p_ab), .a(a), .b(b));
    end else begin : gs
      tmul_sa #(.NTRITS(SW))            u_sq (.prod(p_sq), .a(s), .b(s));
      tmul_sa #(.NTRITS(NTRITS))        u_ab (.prod(p_ab), .a(a), .b(b));
    end
  endgenerate

  // N = p_sq - p_ab over RTRITS trits (p_sq's top trit is provably 0)
  wire [2*RTRITS-1:0] p_sq_r = p_sq[2*RTRITS-1:0];
  wire [2*RTRITS-1:0] p_ab_r = {{(2*RTRITS-4*NTRITS){1'b0}}, p_ab};
  wire [2*RTRITS-1:0] n_full;
  wire [1:0]          cn;
  tsub_n #(.NTRITS(RTRITS)) u_sub (
    .diff(n_full), .cout(cn), .a(p_sq_r), .b(p_ab_r));

  // fit check: trits NTRITS..RTRITS-1 must all be null
  integer i;
  always @(*) begin
    ofit = 1'b0;
    for (i = NTRITS; i < RTRITS; i = i + 1)
      if (n_full[i*2 +: 2] != 2'b00) ofit = 1'b1;
    n = n_full[2*NTRITS-1:0];
  end
endmodule
