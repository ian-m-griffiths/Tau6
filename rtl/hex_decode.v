// ============================================================================
// hex_decode.v — the hex MMU decode direction (Phase 4): u32 -> cell (a,b).
//
//   (a, b) = eisensteinOfNat addr = ( signUnfold (unpair addr).1,
//                                     signUnfold (unpair addr).2 )
//
// Szudzik unpair needs one integer square root (isqrt) — the ONE non-trivial op in
// the whole datapath (hex_mmu.md §2).  This uses the restoring shift-and-subtract
// isqrt (no multiplier, ~16 serial stages), exactly the "isqrt (serial ~16 cyc, or
// comb.)" the design calls for.
//
// Every primitive mirrors a PROVED Lean theorem (Hexagon/Bijection.lean):
//   isqrt        <-> mathlib Nat.sqrt
//   szudzik_unpair <-> Nat.unpair   (toNat_ofNat / ofNat_toNat round-trip)
//   signUnfold   <-> Bijection.signUnfold
//
// Verilog-2001; synthesizable; self-contained.
// ============================================================================

`timescale 1ns/1ps

// ----------------------------------------------------------------------------
// hex_decode: u32 physical address -> Eisenstein cell (a, b).
// ----------------------------------------------------------------------------
module hex_decode (
  output wire signed [15:0] a,
  output wire signed [15:0] b,
  input  wire [31:0]        addr
);
  // isqrt: floor(sqrt(n)) for a 32-bit n -> 16-bit, restoring shift-and-subtract.
  function [15:0] isqrt;
    input [31:0] n;
    reg [31:0] rem;
    reg [15:0] root;
    reg [47:0] tmp;
    integer i;
    begin
      rem = n;
      root = 16'd0;
      for (i = 15; i >= 0; i = i - 1) begin
        root = root << 1;
        tmp = {16'd0, (root << 1) | 17'd1} << (2 * i);   // (2*root+1) << (2i)
        if (rem >= tmp[31:0]) begin
          rem = rem - tmp[31:0];
          root = root | 16'd1;
        end
      end
      isqrt = root;
    end
  endfunction

  // sign_unfold: N -> Z, inverse of sign_fold.  n even : n/2 ; n odd : -(n+1)/2
  function signed [15:0] sign_unfold;
    input [15:0] n;
    reg [16:0] v;
    begin
      v = {1'b0, n};
      if (v[0])  // odd
        sign_unfold = -$signed((v + 17'd1) >> 1);
      else
        sign_unfold = $signed(v >> 1);
    end
  endfunction

  // szudzik_unpair: inverse of szudzik_pair (mathlib Nat.unpair).
  //   s = isqrt n ;  n - s^2 < s ? (n - s^2, s) : (s, n - s^2 - s)
  // returns the two folds {fx, fy} packed 16+16 in a 32-bit word.
  function [31:0] szudzik_unpair;
    input [31:0] n;
    reg [15:0] s;
    reg [31:0] s2, diff, diff2;
    begin
      s = isqrt(n);
      s2 = {16'd0, s} * s;
      diff = n - s2;
      diff2 = diff - s;
      if (n < s2 + s)
        szudzik_unpair = {s, diff[15:0]};   // (fx, fy) = (diff, s)
      else
        szudzik_unpair = {diff2[15:0], s};  // (fx, fy) = (s, diff - s)
    end
  endfunction

  wire [31:0] p = szudzik_unpair(addr);
  wire [15:0] fx = p[15:0];
  wire [15:0] fy = p[31:16];
  assign a = sign_unfold(fx);
  assign b = sign_unfold(fy);
endmodule
