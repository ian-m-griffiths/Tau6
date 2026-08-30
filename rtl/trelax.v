// ============================================================================
// trelax.v -- TRELAX : one heat-equation relaxation step (the hex-disk
// Laplacian + damped update) as a combinational balanced-ternary datapath.
//
// ISA position (synthesis.md Tier 2): TRELAX = u <- u + alpha*Lap u, the
// relaxation/diffusion primitive.  This module is the per-cell datapath:
//    Lap u = sum of the 6 Z6 neighbors - 6*u
//    u'    = u/3 + (sum_nb)/9         [the alpha = 2/3 folded form:
//                                        u + (1/9)(sum_nb - 6u) = u/3 + sum_nb/9]
// Because 1/3 = 3^-1 and 1/9 = 3^-2 are ternary right-shifts (free wire
// re-wiring), the whole update is ONE balanced add on top of the sum.
//
// INPUTS: u  = center value (NTRITS trits = 2*NTRITS bits, one-hot per trit)
//         nb = 6 neighbor values, packed [6*NTRITS-1:0] (nb[0], nb[1], ...)
// OUTPUT: u_new = relaxed center value (NTRITS trits).
//
// WORD: NTRITS = 6 (the repo's 12-bit coefficient, fixed-point 3 int + 3
// frac trits, scale 3^3 = 27, range +/-13.48, resolution 1/27).  A 6-input
// sum of 6-trit values spans +/-2184, so the reduction tree runs at SW =
// NTRITS+2 = 8 trits (range +/-3280) -- the safe width.  The update add is
// back at NTRITS trits.
//
// DEVICE STRUCTURE (per cell): 5 x tadd_trits(SW=8) reduction adders +
// 1 x tadd_trits(NTRITS=6) update adder = 5*8 + 6 = 46 tadd1 full-adders.
// (For a normalized field |u| <= ~1.5 the sum fits 6 trits and the reduction
// could run at 6 trits -> 36 tadd1; the safe-width 46 is the full-range RTL.)
//
// Verilog-2001; depends on tadd_trits from rtl/ternary_gates.v.
// ============================================================================

`timescale 1ns/1ps

module trelax_cell #(parameter NTRITS = 6) (
  output wire [2*NTRITS-1:0] u_new,
  input  wire [2*NTRITS-1:0] u,
  input  wire [12*NTRITS-1:0] nb
);

  localparam W  = NTRITS;      // field width, trits
  localparam SW = NTRITS + 2;  // safe neighbor-sum width, trits

  // ---- zero-extend each 6-trit neighbor to SW trits (pad 2 null trits) ----
  wire [2*SW-1:0] n0 = {{2*(SW-W){1'b0}}, nb[ 0*2*W +: 2*W]};
  wire [2*SW-1:0] n1 = {{2*(SW-W){1'b0}}, nb[ 1*2*W +: 2*W]};
  wire [2*SW-1:0] n2 = {{2*(SW-W){1'b0}}, nb[ 2*2*W +: 2*W]};
  wire [2*SW-1:0] n3 = {{2*(SW-W){1'b0}}, nb[ 3*2*W +: 2*W]};
  wire [2*SW-1:0] n4 = {{2*(SW-W){1'b0}}, nb[ 4*2*W +: 2*W]};
  wire [2*SW-1:0] n5 = {{2*(SW-W){1'b0}}, nb[ 5*2*W +: 2*W]};

  // ---- neighbor-sum reduction tree: (n0+n1)+(n2+n3)+(n4+n5) then sum ----
  wire [2*SW-1:0] s01, s23, s45, s0123, sum;
  wire [1:0]      c01, c23, c45, c0123, csum;

  tadd_trits #(.NTRITS(SW)) u_a01 (.sum(s01), .cout(c01), .a(n0), .b(n1), .cin(2'b00));
  tadd_trits #(.NTRITS(SW)) u_a23 (.sum(s23), .cout(c23), .a(n2), .b(n3), .cin(2'b00));
  tadd_trits #(.NTRITS(SW)) u_a45 (.sum(s45), .cout(c45), .a(n4), .b(n5), .cin(2'b00));
  tadd_trits #(.NTRITS(SW)) u_a0123 (.sum(s0123), .cout(c0123), .a(s01), .b(s23), .cin(2'b00));
  tadd_trits #(.NTRITS(SW)) u_asum (.sum(sum), .cout(csum), .a(s0123), .b(s45), .cin(2'b00));

  // ---- update: u' = (u >> 1 trit) + (sum >> 2 trits), both back at W trits ----
  wire [2*W-1:0] u1 = {2'b00, u[2*W-1:2]};   // drop lowest trit, pad top null
  wire [2*W-1:0] s2 = sum[2*W+4-1:4];        // sum >> 2 trits (drop 4 bits)
  wire [1:0]     cu;
  tadd_trits #(.NTRITS(W)  ) u_au  (.sum(u_new), .cout(cu), .a(u1), .b(s2), .cin(2'b00));

endmodule
