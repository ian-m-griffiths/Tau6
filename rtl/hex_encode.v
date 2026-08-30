// ============================================================================
// hex_encode.v — the hex MMU's address-generation unit (Phase 4, first step).
//
// Implements the cell -> u32 ENCODE direction of docs/riscv_survey/hex_mmu.md §2:
//   u32 = eisensteinToNat(a, b) = Szudzik_pair(signFold a, signFold b)
// plus the 6-offset neighbor generator (the "cell cache" hop — hex_mmu.md §2/§3b).
//
// This is the cheap direction: compare + square + add, NO square root (the decode
// direction's isqrt is a separate module).  Every primitive mirrors a PROVED Lean
// theorem (proofs/lean-src/hexagon/Hexagon/Bijection.lean):
//   signFold     <-> Bijection.signFold     (signFold_signUnfold round-trip)
//   szudzik_pair <-> Bijection.toNat        (Nat.pair = Szudzik; toNat_ofNat)
//   the u32 box  <-> Bijection.toNat_lt_two_pow_32 / pair_lt_two_pow_32
//
// Coordinates are SIGNED 16-bit (the u32 box [-2^15, 2^15-1]^2); folds are 16-bit
// unsigned (0..65535); the pair is a full 32-bit (tight: u32::MAX = (65535)^2+65535+65535).
//
// Verilog-2001; synthesizable; self-contained.
// ============================================================================

`timescale 1ns/1ps

// ----------------------------------------------------------------------------
// hex_encode: Eisenstein cell (a,b) -> u32 physical address
//   addr = szudzik_pair(sign_fold(a), sign_fold(b))   (Bijection.eisensteinToNat)
// ----------------------------------------------------------------------------
module hex_encode (
  output wire [31:0] addr,
  input  wire signed [15:0] a,
  input  wire signed [15:0] b
);
  // sign_fold: Z -> N, 0,1,-1,2,-2,... |-> 0,1,2,3,4,...  (Bijection.signFold)
  function [15:0] sign_fold;
    input signed [15:0] z;
    reg [15:0] mag;
    reg [16:0] dbl;
    begin
      mag = z[15] ? (~z + 16'd1) : z;   // |z| (|−32768| = 32768 fits unsigned 16-bit)
      dbl = {1'b0, mag} << 1;           // 2*|z| in 17 bits (up to 65536)
      sign_fold = z[15] ? dbl[15:0] - 16'd1 : dbl[15:0];
    end
  endfunction

  // szudzik_pair: Szudzik pairing (Bijection.toNat / mathlib Nat.pair)
  //   x < y : y^2 + x ;  else : x^2 + x + y
  function [31:0] szudzik_pair;
    input [15:0] x, y;
    begin
      if (x < y)
        szudzik_pair = {16'd0, y} * y + x;
      else
        szudzik_pair = {16'd0, x} * x + x + y;
    end
  endfunction

  wire [15:0] fa = sign_fold(a);
  wire [15:0] fb = sign_fold(b);
  assign addr = szudzik_pair(fa, fb);
endmodule

// ----------------------------------------------------------------------------
// hex_neighbor: the 6-offset Z6 neighbor generator (hex_mmu.md §3b).
//   Given the resident cell (a,b) and a direction k in 0..5, outputs the neighbor
//   cell (a+da, b+db) and its re-encoded u32 address.  The hop itself is two adds;
//   the pair*fold re-encode only happens when crossing the hex<->binary boundary
//   (here it is always computed, for the testbench).
//
//   angle order (w^k): k=0 (1,0), k=1 (0,1), k=2 (-1,1), k=3 (-1,0), k=4 (0,-1), k=5 (1,-1)
// ----------------------------------------------------------------------------
module hex_neighbor (
  output wire signed [15:0] na,
  output wire signed [15:0] nb,
  output wire [31:0]        naddr,
  input  wire signed [15:0] a,
  input  wire signed [15:0] b,
  input  wire [2:0]         k
);
  function [15:0] sign_fold;
    input signed [15:0] z;
    reg [15:0] mag;
    reg [16:0] dbl;
    begin
      mag = z[15] ? (~z + 16'd1) : z;
      dbl = {1'b0, mag} << 1;
      sign_fold = z[15] ? dbl[15:0] - 16'd1 : dbl[15:0];
    end
  endfunction

  function [31:0] szudzik_pair;
    input [15:0] x, y;
    begin
      if (x < y)
        szudzik_pair = {16'd0, y} * y + x;
      else
        szudzik_pair = {16'd0, x} * x + x + y;
    end
  endfunction

  reg signed [15:0] da, db;
  always @(*) begin
    case (k)
      3'd0: begin da = 16'sd1;  db = 16'sd0;  end
      3'd1: begin da = 16'sd0;  db = 16'sd1;  end
      3'd2: begin da = -16'sd1; db = 16'sd1;  end
      3'd3: begin da = -16'sd1; db = 16'sd0;  end
      3'd4: begin da = 16'sd0;  db = -16'sd1; end
      3'd5: begin da = 16'sd1;  db = -16'sd1; end
      default: begin da = 16'sd0; db = 16'sd0; end
    endcase
  end

  assign na = a + da;
  assign nb = b + db;

  wire [15:0] fna = sign_fold(na);
  wire [15:0] fnb = sign_fold(nb);
  assign naddr = szudzik_pair(fna, fnb);
endmodule
