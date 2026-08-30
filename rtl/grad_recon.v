// ============================================================================
// grad_recon.v -- TGRAD + TRECON : the field-calculus pair  ∇F = J  and  F = ∇⁻¹J
// as combinational balanced-ternary datapaths over the Z6 hex pod.
//
// SPEC (docs/compute/field_calculus/maxwell.md + synthesis.md, DotWedge.lean):
//   TGRAD  = the geometric derivative ∇ : a directed 6-neighbor sum over the
//            Z6 hex pod, split into div (scalar / source grade) and curl
//            (bivector / skew grade) -- the sym⊕skew (dot⊕wedge) split.
//   TRECON = the reconstruction ∇⁻¹ : the directed-integral / telescope inverse.
//
// THE FIELD.  A scalar field on the 7 cells of the hex pod (center + 6 ring).
// The 6 ring cells sit at the 6 unit directions  ω^k  (ω = e^(iπ/3), ω² = ω−1),
// the Z6 units of the Eisenstein ring ℤ[ω].  In the (a, b) Eisenstein basis the
// six units are (Conventions.lean / GA_INSTRUCTIONS.md):
//
//     k   ω^k         (a,b)        Re(ω^k)   Im(ω^k)
//    ------------------------------------------------
//     0    1          ( 1,  0)       +1         0
//     1    ω          ( 0,  1)        0        +1
//     2    ω−1        (−1,  1)       −1        +1
//     3   −1          (−1,  0)       −1         0
//     4   −ω          ( 0, −1)        0        −1
//     5    1−ω        ( 1, −1)       +1        −1
//
// TGRAD.  The discrete geometric derivative of the scalar field is the directed
// 6-neighbor sum   ∇F = Σ_k ω^k · F_k   (an Eisenstein vector).  Its two
// coordinates are the grade split:
//
//     div  = Σ_k Re(ω^k)·F_k =  F0 − F2 − F3 + F5     (scalar / source)
//     curl = Σ_k Im(ω^k)·F_k =  F1 + F2 − F4 − F5     (bivector / skew)
//
// The CENTER value does not appear: Σ_k ω^k = 0, so ∇ kills the additive
// constant (the gauge).  This is the discrete echo of Σ(O−E)=0 / the fact that
// div and curl of a scalar field are insensitive to the field's DC level.
//
// TRECON.  ∇⁻¹ : given the source J = (div, curl), recover the field.  Because
// ∇ is a 6 → 2 linear map, it has a 4-dimensional nullspace (the gauge), so the
// reconstruction is only defined UP TO GAUGE -- the honest statement demanded by
// synthesis.md §TODO #2 ("the discrete ∇⁻¹ has a gauge freedom").  This module
// implements ONE canonical section (right-inverse) of ∇:
//
//     F0' = div,  F1' = curl,  F2' = F3' = F4' = F5' = 0,  center' = 0
//
// i.e. the source is placed on the two positive-axis ring cells (ω⁰, ω¹) and
// every other gauge degree of freedom is zeroed.  This section is exact and
// integer (no division):  ∇(TRECON(div,curl)) = (div,curl)  identically.
// The gauge-invariant round trip is then
//
//     ∇(TRECON(∇F)) = ∇F      (the gradient of the reconstruction == the gradient)
//
// and for a field already in canonical gauge (F2=F3=F4=F5=0, center=0) the
// round trip is exact: TRECON(TGRAD(F)) = F.
//
// WORD / WIDTH.  NTRITS = 6 (12-bit coefficient; range ±364, same as trelax).
// div/curl each sum 4 signed terms of magnitude ≤ 364, so |div|,|curl| ≤ 1456,
// which fits SW = NTRITS+2 = 8 trits (±3280) -- the same safe width trelax.v
// uses for its 6-input reduction.  TGRAD is therefore lossless at full range.
// TRECON stores the low 6 trits of div/curl into F0'/F1' and raises `ofit` when
// div or curl does NOT fit 6 trits (reconstruction out of word range).
//
// DEVICE STRUCTURE (reuses the Z6 reduction of trelax.v: tadd_trits trees at
// SW = 8 trits).  TGRAD = 2 x (3 adders x 8 trits) = 48 tadd1.  TRECON = wires
// + a 4-trit fit check (no arithmetic).  TRECON is nearly free; TGRAD is the
// cost, ~1 adder-tree on top of trelax's reduction.
//
// Verilog-2001; depends on tadd_trits from rtl/ternary_gates.v and the tneg
// cell from rtl/trit_functions.vh.
// ============================================================================

`timescale 1ns/1ps

`include "rtl/trit_functions.vh"

// ----------------------------------------------------------------------------
// tgrad_cell -- TGRAD : discrete geometric derivative ∇F = (div, curl) = J.
// ----------------------------------------------------------------------------
module tgrad_cell #(
  parameter NTRITS = 6,
  parameter SW     = NTRITS + 2
) (
  output wire [2*SW-1:0]     div,    // scalar / source grade  (SW trits)
  output wire [2*SW-1:0]     curl,   // bivector / skew grade  (SW trits)
  input  wire [2*NTRITS-1:0] c,      // center (additive gauge; drops out of ∇)
  input  wire [12*NTRITS-1:0] nb     // 6 neighbors F0..F5; nb[0] at bits[2*NTRITS-1:0]
);
  `DEF_TERNARY_GATES
  localparam W = NTRITS;

  // ---- sign-extend each neighbor to SW trits (pad null trits on top) ----
  wire [2*SW-1:0] f0 = {{2*(SW-W){1'b0}}, nb[ 0*2*W +: 2*W]};
  wire [2*SW-1:0] f1 = {{2*(SW-W){1'b0}}, nb[ 1*2*W +: 2*W]};
  wire [2*SW-1:0] f2 = {{2*(SW-W){1'b0}}, nb[ 2*2*W +: 2*W]};
  wire [2*SW-1:0] f3 = {{2*(SW-W){1'b0}}, nb[ 3*2*W +: 2*W]};
  wire [2*SW-1:0] f4 = {{2*(SW-W){1'b0}}, nb[ 4*2*W +: 2*W]};
  wire [2*SW-1:0] f5 = {{2*(SW-W){1'b0}}, nb[ 5*2*W +: 2*W]};

  // balanced-ternary negate of an SW-trit word (per-trit wire swap, carry-free)
  function [2*SW-1:0] fnegW;
    input [2*SW-1:0] x;
    integer i;
    begin
      for (i = 0; i < SW; i = i + 1)
        fnegW[i*2 +: 2] = tneg(x[i*2 +: 2]);
    end
  endfunction

  // ---- div = F0 − F2 − F3 + F5  (Re coefficients: +1, 0, −1, −1, 0, +1) ----
  wire [2*SW-1:0] d01, d23;
  wire [1:0]      dc01, dc23, dc;
  tadd_trits #(.NTRITS(SW)) u_d01 (.sum(d01), .cout(dc01), .a(f0),        .b(fnegW(f2)), .cin(2'b00));
  tadd_trits #(.NTRITS(SW)) u_d23 (.sum(d23), .cout(dc23), .a(fnegW(f3)), .b(f5),        .cin(2'b00));
  tadd_trits #(.NTRITS(SW)) u_div (.sum(div), .cout(dc),    .a(d01),       .b(d23),       .cin(2'b00));

  // ---- curl = F1 + F2 − F4 − F5  (Im coefficients: 0, +1, +1, 0, −1, −1) ----
  wire [2*SW-1:0] c01, c23;
  wire [1:0]      cc01, cc23, cc;
  tadd_trits #(.NTRITS(SW)) u_c01 (.sum(c01),  .cout(cc01), .a(f1),        .b(f2),         .cin(2'b00));
  tadd_trits #(.NTRITS(SW)) u_c23 (.sum(c23),  .cout(cc23), .a(fnegW(f4)), .b(fnegW(f5)),  .cin(2'b00));
  tadd_trits #(.NTRITS(SW)) u_cur (.sum(curl), .cout(cc),    .a(c01),       .b(c23),        .cin(2'b00));

endmodule

// ----------------------------------------------------------------------------
// trecon_cell -- TRECON : reconstruction ∇⁻¹, the canonical (gauge-fixed) section.
// ----------------------------------------------------------------------------
module trecon_cell #(
  parameter NTRITS = 6,
  parameter SW     = NTRITS + 2
) (
  output reg  [12*NTRITS-1:0] nb_rec,  // 6 recovered neighbors F0'..F5' (W trits each)
  output reg  [2*NTRITS-1:0]  c_rec,   // recovered center (canonical gauge: 0)
  output reg                   ofit,    // 1 iff div or curl not representable in W trits
  input  wire [2*SW-1:0]      div,
  input  wire [2*SW-1:0]      curl
);
  localparam W = NTRITS;
  integer i;

  always @(*) begin
    // canonical gauge: source on the positive-axis cells ω⁰, ω¹; all else zero
    nb_rec = {12*NTRITS{1'b0}};
    nb_rec[0*2*W +: 2*W] = div [2*W-1:0];
    nb_rec[1*2*W +: 2*W] = curl[2*W-1:0];
    c_rec = {2*W{1'b0}};

    // fit check: any non-null trit above position W−1 in div or curl → overflow
    ofit = 1'b0;
    for (i = W; i < SW; i = i + 1) begin
      if (div [i*2 +: 2] != 2'b00) ofit = 1'b1;
      if (curl[i*2 +: 2] != 2'b00) ofit = 1'b1;
    end
  end
endmodule
