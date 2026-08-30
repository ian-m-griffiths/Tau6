// ============================================================================
// ga_ops.v — the geometric-algebra (GA) cells for the ternary CPU.
//
// The four Tier-1 GA instructions from docs/GA_INSTRUCTIONS.md, each with its
// Lean proof (proofs/lean-src/hexagon/Hexagon/):
//   TCONJ   Conjugate.lean   conj(a,b) = (a+b, -b)          (omega_bar = 1-w)
//   TDOT    DotWedge.lean    dot   z w = (z * conj w).a     = ac + ad + bd
//   TWEDGE  DotWedge.lean    wedge z w = (z * conj w).b     = bc - ad
//   TSYMDOT SymDot.lean      symdot z w = N(z+w)-N(z)-N(w)  = 2ac+ad+bc+2bd
//                             (the polarization of the norm; the TRUE symmetric
//                              correlation — the raw Re(z*conj w) is half-integral)
//
// where z = (a, b) = a + b*w and w = (c, d) = c + d*w (Eisenstein integers,
// w^2 = w - 1).  All values are balanced ternary, 2 bits/trit, NTRITS = 6
// coefficients in [-364, 364].
//
// WIDTHS (NTRITS = 6):
//   * scalar product a*c:  2*NTRITS = 12 trits (reuse tmul_sa from tmul_opt.v)
//   * dot   = 3 products    -> fits 2*NTRITS+1 = 13 trits (max 397488)
//   * wedge = 2 products    -> fits 2*NTRITS   = 12 trits (max 264992)
//   * symdot = 6 product terms -> fits 2*NTRITS+1 = 13 trits (max 794976)
//   The split cell computes in R = 2*NTRITS+2 = 14 trits of headroom so the
//   intermediate sums stay exact; the CPU keeps the low 6 trits and flags
//   overflow (same fit convention as TNORM/TMUL).
//
// Dependencies: tmul_sa / tadd_n / tsub_n live in tmul_opt.v (compiled in the
// same file list); tneg comes from trit_functions.vh via `DEF_TERNARY_GATES.
// ============================================================================

`timescale 1ns/1ps

`include "rtl/trit_functions.vh"

// ----------------------------------------------------------------------------
// tconj_trits: Eisenstein conjugate conj(a,b) = (a+b, -b)  (TCONJ).
//   a_out = low NTRITS trits of (a + b);  b_out = -b (exact, carry-free).
//   ofit = 1 when a+b does NOT fit in NTRITS trits (|a+b| > (3^N-1)/2).
// ----------------------------------------------------------------------------
module tconj_trits #(parameter NTRITS = 6) (
  output reg  [2*NTRITS-1:0] a_out,      // (a+b) low NTRITS trits
  output reg  [2*NTRITS-1:0] b_out,      // -b
  output reg                 ofit,
  input       [2*NTRITS-1:0] a, b
);
  `DEF_TERNARY_GATES

  localparam SW = NTRITS + 1;            // a+b needs one extra trit of headroom

  wire [2*SW-1:0] sum;
  wire [1:0]      cs;
  tadd_n #(.NTRITS(SW)) u_sum (
    .sum(sum), .cout(cs),
    .a({{(2*(SW-NTRITS)){1'b0}}, a}),
    .b({{(2*(SW-NTRITS)){1'b0}}, b}),
    .cin(2'b00));

  integer i;
  always @(*) begin
    a_out = sum[2*NTRITS-1:0];
    ofit  = (sum[2*NTRITS +: 2] != 2'b00);   // the (NTRITS+1)-th trit must be null
    for (i = 0; i < NTRITS; i = i + 1)
      b_out[i*2 +: 2] = tneg(b[i*2 +: 2]);   // negation is a per-digit wire swap
  end
endmodule

// ----------------------------------------------------------------------------
// ga_split_trits: the scalar/bivector split of the geometric product.
//   Given z=(a,b), w=(c,d), computes (from 4 shared scalar products ac, ad,
//   bc, bd — the same 4 products the naive Eisenstein multiply uses):
//     dot    = ac + ad + bd            (= (z * conj w).a  — symmetric scalar)
//     wedge  = bc - ad                 (= (z * conj w).b  — anti-symmetric skew)
//     symdot = 2ac + ad + bc + 2bd     (= N(z+w) - N(z) - N(w)  — norm polarization)
//   All three returned FULL WIDTH in R = 2*NTRITS+2 trits (exact); the CPU
//   truncates to 6 trits and does its own fit check (trits 6..R-1 all null).
// ----------------------------------------------------------------------------
module ga_split_trits #(parameter NTRITS = 6) (
  output wire [2*(2*NTRITS+2)-1:0] dot,      // 2*NTRITS+2 trits (14 when NTRITS=6)
  output wire [2*(2*NTRITS+2)-1:0] wedge,
  output wire [2*(2*NTRITS+2)-1:0] symdot,
  input      [2*NTRITS-1:0] a, b, c, d
);
  `DEF_TERNARY_GATES

  localparam R  = 2*NTRITS + 2;          // accumulator trits (14)
  localparam PB = 4*NTRITS;              // product bits = 24 (12 trits)

  // the 4 scalar products (tmul_sa is the private shift-add multiplier)
  wire [PB-1:0] p_ac, p_ad, p_bc, p_bd;
  tmul_sa #(.NTRITS(NTRITS)) u_ac (.prod(p_ac), .a(a), .b(c));
  tmul_sa #(.NTRITS(NTRITS)) u_ad (.prod(p_ad), .a(a), .b(d));
  tmul_sa #(.NTRITS(NTRITS)) u_bc (.prod(p_bc), .a(b), .b(c));
  tmul_sa #(.NTRITS(NTRITS)) u_bd (.prod(p_bd), .a(b), .b(d));

  // zero-extend each product to the R-trit accumulator width
  wire [2*R-1:0] ac = {{(2*R-PB){1'b0}}, p_ac};
  wire [2*R-1:0] ad = {{(2*R-PB){1'b0}}, p_ad};
  wire [2*R-1:0] bc = {{(2*R-PB){1'b0}}, p_bc};
  wire [2*R-1:0] bd = {{(2*R-PB){1'b0}}, p_bd};

  // dot = ac + ad + bd
  wire [2*R-1:0] d1;
  tadd_n #(.NTRITS(R)) u_d1  (.sum(d1),   .cout(), .a(ac), .b(ad), .cin(2'b00));
  tadd_n #(.NTRITS(R)) u_dot (.sum(dot),  .cout(), .a(d1), .b(bd), .cin(2'b00));

  // wedge = bc - ad
  tsub_n #(.NTRITS(R)) u_wedge (.diff(wedge), .cout(), .a(bc), .b(ad));

  // symdot = ac + ac + ad + bc + bd + bd  (= 2ac + ad + bc + 2bd)
  wire [2*R-1:0] s1, s2, s3, s4;
  tadd_n #(.NTRITS(R)) u_s1 (.sum(s1), .cout(), .a(ac), .b(ac), .cin(2'b00));
  tadd_n #(.NTRITS(R)) u_s2 (.sum(s2), .cout(), .a(s1), .b(ad), .cin(2'b00));
  tadd_n #(.NTRITS(R)) u_s3 (.sum(s3), .cout(), .a(s2), .b(bc), .cin(2'b00));
  tadd_n #(.NTRITS(R)) u_s4 (.sum(s4), .cout(), .a(s3), .b(bd), .cin(2'b00));
  tadd_n #(.NTRITS(R)) u_sym (.sum(symdot), .cout(), .a(s4), .b(bd), .cin(2'b00));
endmodule

// ============================================================================
// Tier-1 GA instruction cells — EXACT-WIDTH ports (12-trit operands in,
// full-width signed result out), matching the Lean semantics verbatim.
//
// These are the modules requested as `tconj`/`tdot`/`twedge`/`tsymdot`: each
// takes two 12-trit Eisenstein operands z=a+b*w, w=c+d*w and returns the
// integer-exact result (NOT truncated to 6 trits — the norm/product of two
// 6-trit coefficients does not fit 6 trits).  They complement the split-cell
// (ga_split_trits) above, which is the CPU-side 4-product core; these expose
// the operations one-per-instruction.
//
//   tconj    TCONJ   conj(a,b) = (a+b, -b)              Conjugate.lean L27
//   tdot     TDOT    dot(z,w)  = (z * conj w).a         DotWedge.lean  L32
//   twedge   TWEDGE  wedge(z,w)= (z * conj w).b         DotWedge.lean  L35
//   tsymdot  TSYMDOT symdot    = N(z+w) - N(z) - N(w)   SymDot.lean    L33
//
// Result widths (tight, integer-exact):
//   tconj:  a_out = a+b (7 trits, |a+b| <= 728), b_out = -b (6 trits)
//   tdot / twedge / tsymdot: 13 trits (26 bits) each
//     |dot| <= 397488, |wedge| <= 264992, |symdot| <= 794976  <= (3^13-1)/2
// ============================================================================

// ----------------------------------------------------------------------------
// tnorm_full: exact N(a,b) = a^2 + a*b + b^2 in 2*NIN+1 trits (no truncation).
// Mirrors ternary_gates.v tnorm_trits but returns the whole value
// (Conventions.lean L64-65: N fits 2*NIN+1 trits for NIN-trit operands).
// ----------------------------------------------------------------------------
module tnorm_full #(parameter NIN = 6) (
  output wire [2*(2*NIN+1)-1:0] n,    // 2*NIN+1 trits, exact
  input  wire [2*NIN-1:0]       a, b  // NIN trits each
);
  localparam R = 2*NIN + 1;           // result trits (N always fits in here)

  wire [4*NIN-1:0] aa, ab, bb;        // three 2*NIN-trit products
  tmul_sa #(.NTRITS(NIN)) m_aa (.prod(aa), .a(a), .b(a));
  tmul_sa #(.NTRITS(NIN)) m_ab (.prod(ab), .a(a), .b(b));
  tmul_sa #(.NTRITS(NIN)) m_bb (.prod(bb), .a(b), .b(b));

  wire [2*R-1:0] aa_p = {{(2*R-4*NIN){1'b0}}, aa};   // zero-extend to R trits
  wire [2*R-1:0] ab_p = {{(2*R-4*NIN){1'b0}}, ab};
  wire [2*R-1:0] bb_p = {{(2*R-4*NIN){1'b0}}, bb};

  wire [2*R-1:0] s1, s2;
  tadd_n #(.NTRITS(R)) u_s1 (.sum(s1), .cout(), .a(aa_p), .b(ab_p), .cin(2'b00));
  tadd_n #(.NTRITS(R)) u_s2 (.sum(s2), .cout(), .a(s1),  .b(bb_p), .cin(2'b00));

  assign n = s2;
endmodule

// ----------------------------------------------------------------------------
// tconj — TCONJ.  conj(a,b) = (a+b, -b)  (Conjugate.lean L27, w_bar = 1 - w).
//   -b is the free wire-swap tneg; a+b is a zero-extended balanced ripple add.
// ----------------------------------------------------------------------------
module tconj (
  output wire [13:0] a_out,   // 7 trits: a + b   (may exceed the 6-trit range)
  output wire [11:0] b_out,   // 6 trits: -b
  input  wire [11:0] a, b     // 6 trits each
);
  genvar g;
  generate
    for (g = 0; g < 6; g = g + 1) begin : g_neg
      assign b_out[2*g]   = b[2*g + 1];
      assign b_out[2*g+1] = b[2*g];
    end
  endgenerate

  tadd_n #(.NTRITS(7)) u_add (
    .sum(a_out), .cout(),
    .a({{2{1'b0}}, a}),
    .b({{2{1'b0}}, b}),
    .cin(2'b00)
  );
endmodule

// ----------------------------------------------------------------------------
// tdot — TDOT.  dot(z,w) = (z * conj w).a = a*c + a*d + b*d  (DotWedge.lean L49).
// The raw a-coordinate of z * conj(w) (NOT symmetrized — that is the proven,
// non-symmetric `dot`; the symmetric correlation is TSYMDOT).
// ----------------------------------------------------------------------------
module tdot (
  output wire [25:0] d_out,   // 13 trits
  input  wire [11:0] a, b,    // z = a + b*w
  input  wire [11:0] c, d     // w = c + d*w
);
  localparam R = 13;

  wire [23:0] p_ac, p_ad, p_bd;   // 12-trit (6x6) products
  tmul_sa #(.NTRITS(6)) m_ac (.prod(p_ac), .a(a), .b(c));
  tmul_sa #(.NTRITS(6)) m_ad (.prod(p_ad), .a(a), .b(d));
  tmul_sa #(.NTRITS(6)) m_bd (.prod(p_bd), .a(b), .b(d));

  wire [2*R-1:0] p_ac_e = {{(2*R-24){1'b0}}, p_ac};   // zero-extend to 13 trits
  wire [2*R-1:0] p_ad_e = {{(2*R-24){1'b0}}, p_ad};
  wire [2*R-1:0] p_bd_e = {{(2*R-24){1'b0}}, p_bd};

  wire [2*R-1:0] s1;
  tadd_n #(.NTRITS(R)) u1 (.sum(s1),    .cout(), .a(p_ac_e), .b(p_ad_e), .cin(2'b00));
  tadd_n #(.NTRITS(R)) u2 (.sum(d_out), .cout(), .a(s1),     .b(p_bd_e), .cin(2'b00));
endmodule

// ----------------------------------------------------------------------------
// twedge — TWEDGE.  wedge(z,w) = (z * conj w).b = b*c - a*d  (DotWedge.lean L58).
// The raw b-coordinate (the skew/curl part); anti-symmetric (wedge_antisymm).
// ----------------------------------------------------------------------------
module twedge (
  output wire [25:0] w_out,   // 13 trits
  input  wire [11:0] a, b,
  input  wire [11:0] c, d
);
  localparam R = 13;

  wire [23:0] p_bc, p_ad;
  tmul_sa #(.NTRITS(6)) m_bc (.prod(p_bc), .a(b), .b(c));
  tmul_sa #(.NTRITS(6)) m_ad (.prod(p_ad), .a(a), .b(d));

  wire [2*R-1:0] p_bc_e = {{(2*R-24){1'b0}}, p_bc};
  wire [2*R-1:0] p_ad_e = {{(2*R-24){1'b0}}, p_ad};

  tsub_n #(.NTRITS(R)) u_sub (.diff(w_out), .cout(), .a(p_bc_e), .b(p_ad_e));
endmodule

// ----------------------------------------------------------------------------
// tsymdot — TSYMDOT.  symdot(z,w) = N(z+w) - N(z) - N(w)  (SymDot.lean L33),
// the symmetric polarization of the norm = 2*Re(z * conj w) = 2*dot + wedge.
// Computed faithfully as the norm polarization via full-width norms (N(z+w) in
// 15 trits, N(z)/N(w) in 13 trits, then two balanced subtractions).
// ----------------------------------------------------------------------------
module tsymdot (
  output wire [25:0] s_out,   // 13 trits
  input  wire [11:0] a, b,
  input  wire [11:0] c, d
);
  localparam RW = 15;         // internal safe width (trits)

  wire [13:0] ac, bd;         // z + w = (a+c, b+d), each 7 trits
  tadd_n #(.NTRITS(7)) u_ac (.sum(ac), .cout(), .a({{2{1'b0}}, a}), .b({{2{1'b0}}, c}), .cin(2'b00));
  tadd_n #(.NTRITS(7)) u_bd (.sum(bd), .cout(), .a({{2{1'b0}}, b}), .b({{2{1'b0}}, d}), .cin(2'b00));

  wire [2*RW-1:0] n_zw;       // N(z+w): 15 trits
  wire [25:0]     n_z, n_w;   // N(z), N(w): 13 trits
  tnorm_full #(.NIN(7)) u_nzw (.n(n_zw), .a(ac), .b(bd));
  tnorm_full #(.NIN(6)) u_nz  (.n(n_z),  .a(a),  .b(b));
  tnorm_full #(.NIN(6)) u_nw  (.n(n_w),  .a(c),  .b(d));

  wire [2*RW-1:0] n_z_e = {{(2*RW-26){1'b0}}, n_z};   // zero-extend to 15 trits
  wire [2*RW-1:0] n_w_e = {{(2*RW-26){1'b0}}, n_w};

  wire [2*RW-1:0] t1, t2;
  tsub_n #(.NTRITS(RW)) u1 (.diff(t1), .cout(), .a(n_zw), .b(n_z_e));
  tsub_n #(.NTRITS(RW)) u2 (.diff(t2), .cout(), .a(t1),   .b(n_w_e));

  assign s_out = t2[25:0];    // low 13 trits (top two trits are provably 0)
endmodule
