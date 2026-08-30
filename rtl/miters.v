// Miters for formal (SAT) equivalence of the optimized modules vs originals.
// `invalid` flags any trit input in the forbidden 2'b11 state, so the proof
// covers exactly the reachable input space (the datapath never emits 2'b11).
`timescale 1ns/1ps
`include "rtl/trit_functions.vh"

module miter_tmul #(parameter NTRITS = 6) (
  input  [4*NTRITS-1:0] ai, bi,
  output wire diff, invalid
);
  wire [2*NTRITS-1:0] a = ai[2*NTRITS-1:0], b = bi[2*NTRITS-1:0];
  wire [4*NTRITS-1:0] po, pk;
  tmul_trits     #(.NTRITS(NTRITS)) u_o (.prod(po), .a(a), .b(b));
  tmul_trits_opt #(.NTRITS(NTRITS)) u_k (.prod(pk), .a(a), .b(b));
  assign diff = |(po ^ pk);
  wire [2*NTRITS-1:0] invb;
  genvar g;
  generate
    for (g = 0; g < 2*NTRITS; g = g + 1) begin : inv
      assign invb[g] = (a[2*g] & a[2*g+1]) | (b[2*g] & b[2*g+1]);
    end
  endgenerate
  assign invalid = |invb;
endmodule

module miter_tnorm #(parameter NTRITS = 6) (
  input  [4*NTRITS-1:0] ai, bi,
  output wire diff, invalid
);
  wire [2*NTRITS-1:0] a = ai[2*NTRITS-1:0], b = bi[2*NTRITS-1:0];
  wire [2*NTRITS-1:0] no, nk0, nk1;
  wire of_o, of_k0, of_k1;
  tnorm_trits     #(.NTRITS(NTRITS)) u_o  (.n(no),  .ofit(of_o),  .a(a), .b(b));
  tnorm_trits_opt #(.NTRITS(NTRITS), .USE_KARATSUBA(0)) u_k0 (.n(nk0), .ofit(of_k0), .a(a), .b(b));
  tnorm_trits_opt #(.NTRITS(NTRITS), .USE_KARATSUBA(1)) u_k1 (.n(nk1), .ofit(of_k1), .a(a), .b(b));
  assign diff = |((no ^ nk0) | (no ^ nk1) | {31'b0, (of_o ^ of_k0)} | {31'b0, (of_o ^ of_k1)});
  wire [2*NTRITS-1:0] invb;
  genvar g;
  generate
    for (g = 0; g < 2*NTRITS; g = g + 1) begin : inv
      assign invb[g] = (a[2*g] & a[2*g+1]) | (b[2*g] & b[2*g+1]);
    end
  endgenerate
  assign invalid = |invb;
endmodule

module miter_eisen #(parameter NTRITS = 6) (
  input  [4*NTRITS-1:0] ai, bi, ci, di,
  output wire diff, invalid
);
  wire [2*NTRITS-1:0] a = ai[2*NTRITS-1:0], b = bi[2*NTRITS-1:0];
  wire [2*NTRITS-1:0] c = ci[2*NTRITS-1:0], d = di[2*NTRITS-1:0];
  wire [4*NTRITS-1:0] ak, an;
  wire [4*NTRITS+1:0] bk, bn;
  tmul_eisen_trits #(.NTRITS(NTRITS)) u_k (.A_out(ak), .B_out(bk), .a(a), .b(b), .c(c), .d(d));
  tmul_eisen_naive #(.NTRITS(NTRITS)) u_n (.A_out(an), .B_out(bn), .a(a), .b(b), .c(c), .d(d));
  assign diff = |((ak ^ an) | (bk ^ bn));
  wire [2*NTRITS-1:0] invb;
  genvar g;
  generate
    for (g = 0; g < 2*NTRITS; g = g + 1) begin : inv
      assign invb[g] = (a[2*g] & a[2*g+1]) | (b[2*g] & b[2*g+1])
                     | (c[2*g] & c[2*g+1]) | (d[2*g] & d[2*g+1]);
    end
  endgenerate
  assign invalid = |invb;
endmodule

// miter_eisen_fit: the exact CPU TMUL datapath semantics — low NTRITS trits of
// each coefficient stored, plus the fit/overflow flag — checked against the
// naive reference with the identical truncation + flag.  Proves the opcode's
// combinational function bit-identical for every reachable input.
module miter_eisen_fit #(parameter NTRITS = 6) (
  input  [4*NTRITS-1:0] ai, bi, ci, di,
  output wire diff, invalid
);
  wire [2*NTRITS-1:0] a = ai[2*NTRITS-1:0], b = bi[2*NTRITS-1:0];
  wire [2*NTRITS-1:0] c = ci[2*NTRITS-1:0], d = di[2*NTRITS-1:0];
  wire [4*NTRITS-1:0] ak, an;
  wire [4*NTRITS+1:0] bk, bn;
  tmul_eisen_trits #(.NTRITS(NTRITS)) u_k (.A_out(ak), .B_out(bk), .a(a), .b(b), .c(c), .d(d));
  tmul_eisen_naive #(.NTRITS(NTRITS)) u_n (.A_out(an), .B_out(bn), .a(a), .b(b), .c(c), .d(d));

  // CPU TMUL store: a-field = A[low 6], b-field = B[low 6]; ovf = wider than 6
  wire of_k = (|ak[4*NTRITS-1:2*NTRITS]) | (|bk[4*NTRITS+1:2*NTRITS]);
  wire of_n = (|an[4*NTRITS-1:2*NTRITS]) | (|bn[4*NTRITS+1:2*NTRITS]);
  assign diff = |((ak[2*NTRITS-1:0] ^ an[2*NTRITS-1:0]) |
                  (bk[2*NTRITS-1:0] ^ bn[2*NTRITS-1:0])) | (of_k ^ of_n);

  wire [2*NTRITS-1:0] invb;
  genvar g;
  generate
    for (g = 0; g < 2*NTRITS; g = g + 1) begin : inv
      assign invb[g] = (a[2*g] & a[2*g+1]) | (b[2*g] & b[2*g+1])
                     | (c[2*g] & c[2*g+1]) | (d[2*g] & d[2*g+1]);
    end
  endgenerate
  assign invalid = |invb;
endmodule
