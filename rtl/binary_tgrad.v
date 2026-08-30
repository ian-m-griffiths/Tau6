// ============================================================================
// binary_tgrad.v -- TGRAD as a BINARY reduction (plain 2's-complement adders).
//
// The HYBRID cut: the field store keeps its ternary-encoded values (2 bits/trit,
// 01=+1 / 00=0 / 10=-1, the repo's one-hot-per-direction code), but the TGRAD
// div/curl reduction is done in BINARY, on signed 2's-complement integers,
// because a binary full adder is measured at 1.92x the energy / 3.31x the
// transistors / 4.33x the area of the balanced-ternary tadd1 (trelax_measured.md,
// word_fairfight.txt).  The reduction itself is the SAME 6 signed adds in both
// bases (emulation_field.md §0); only the per-adder cost differs.
//
// TGRAD spec (grad_recon.v L25-33):  div  = F0 - F2 - F3 + F5
//                                     curl = F1 + F2 - F4 - F5
// (Re(ω^k) and Im(ω^k) coefficients of the 6-neighbor sum Σ_k ω^k·F_k).  The
// CENTER cell drops out (Σ_k ω^k = 0, the additive gauge), so `c` is accepted
// for drop-in interface parity with tgrad_cell and ignored.
//
// WORD / WIDTH.  Each field value is 6 trits (12 bits), |F| <= 364.  div/curl
// each sum 4 signed terms so |div|,|curl| <= 4*364 = 1456 < 2048 = 2^11, which
// fits a signed 12-bit word (BW = 12) -- the same "12-bit signed adds" width
// emulation_field.md §0 assigns to the binary TGRAD.  Lossless at full range.
//
// STRUCTURE.  6 x t2b (converters.v, the O(n) ternary->signed value decode that
// already sits on the hybrid boundary) + 6 signed adds (a 3-adder tree for div,
// a 3-adder tree for curl -- exactly mirroring tgrad_cell's u_d01/u_d23/u_div
// and u_c01/u_c23/u_cur).  The decode is the one-time boundary conversion; the
// REDUCTION -- the thing being compared against the ternary tadd tree -- is the
// 6 signed adds.
//
// Verilog-2001; depends on t2b from rtl/converters.v.  No trit gates, no
// carry-free negation tricks: all arithmetic is plain 2's-complement.
// ============================================================================

`timescale 1ns/1ps

module binary_tgrad #(
  parameter NTRITS = 6
) (
  output wire signed [11:0]     div,    // scalar / source grade  (2's-complement)
  output wire signed [11:0]     curl,   // bivector / skew grade  (2's-complement)
  input  wire [2*NTRITS-1:0]    c,      // center (additive gauge; drops out of ∇)
  input  wire [12*NTRITS-1:0]   nb      // 6 neighbors F0..F5; nb[0] at bits[2*NTRITS-1:0]
);
  localparam W   = NTRITS;   // field width, trits
  localparam BW  = 12;       // binary output width (signed; |div|,|curl| <= 1456)
  localparam EXT = BW - 10;  // sign-extension pads for the 10-bit t2b decode

  // ---- decode each 6-trit balanced value -> signed binary (repo's t2b) ------
  // t2b yields a signed 10-bit 2's-complement integer in [-364, +364].
  wire [9:0] f0b, f1b, f2b, f3b, f4b, f5b;
  t2b u_f0 (.t(nb[0*2*W +: 2*W]), .v(f0b));
  t2b u_f1 (.t(nb[1*2*W +: 2*W]), .v(f1b));
  t2b u_f2 (.t(nb[2*2*W +: 2*W]), .v(f2b));
  t2b u_f3 (.t(nb[3*2*W +: 2*W]), .v(f3b));
  t2b u_f4 (.t(nb[4*2*W +: 2*W]), .v(f4b));
  t2b u_f5 (.t(nb[5*2*W +: 2*W]), .v(f5b));

  // ---- sign-extend the decoded values to BW bits ----------------------------
  wire signed [BW-1:0] f0 = {{EXT{f0b[9]}}, f0b};
  wire signed [BW-1:0] f1 = {{EXT{f1b[9]}}, f1b};
  wire signed [BW-1:0] f2 = {{EXT{f2b[9]}}, f2b};
  wire signed [BW-1:0] f3 = {{EXT{f3b[9]}}, f3b};
  wire signed [BW-1:0] f4 = {{EXT{f4b[9]}}, f4b};
  wire signed [BW-1:0] f5 = {{EXT{f5b[9]}}, f5b};

  // ---- div = F0 - F2 - F3 + F5  (Re coefficients: +1,0,-1,-1,0,+1) : 3 adds --
  wire signed [BW-1:0] d01 = f0 - f2;
  wire signed [BW-1:0] d23 = f5 - f3;
  assign div  = d01 + d23;

  // ---- curl = F1 + F2 - F4 - F5 (Im coefficients: 0,+1,+1,0,-1,-1) : 3 adds --
  wire signed [BW-1:0] c01 = f1 + f2;
  wire signed [BW-1:0] c23 = f4 + f5;
  assign curl = c01 - c23;

endmodule
