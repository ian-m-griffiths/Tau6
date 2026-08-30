// ============================================================================
// trelax_tb.v -- functional check of trelax_cell against hand-computed
// balanced-ternary relaxation values (alpha=2/3, F = 27u units).
//
// The update is  F' = F/3 + (sum of 6 neighbors)/9, implemented as
//   F>>1 trit  (drop lowest trit)  +  (sum>>2 trits)  (drop 2 lowest trits).
// All test vectors are chosen so the dropped trits are null (no rounding
// ambiguity): values are multiples of 9 or single low trits.
//
// Trit encoding: 2 bits/trit, one-hot: +1=2'b01, 0=2'b00, -1=2'b10.
// Word = 6 trits = 12 bits; trit i occupies bits [2i+1:2i] (push=bit 2i).
// ============================================================================
`timescale 1ns/1ps

module trelax_tb;
  reg  [11:0] u;
  reg  [71:0] nb;
  wire [11:0] u_new;

  trelax_cell #(.NTRITS(6)) dut (.u_new(u_new), .u(u), .nb(nb));

  integer errors;
  integer t;
  reg [11:0] expect;

  // local values (balanced trit one-hot bit patterns)
  localparam [11:0] T0    = 12'h000;  // 0
  localparam [11:0] T_P1  = 12'h001;  // +1   (trit0)
  localparam [11:0] T_M3  = 12'h008;  // -3   (trit1 = -1)
  localparam [11:0] T_P3  = 12'h004;  // +3   (trit1)
  localparam [11:0] T_P9  = 12'h010;  // +9   (trit2)
  localparam [11:0] T_M9  = 12'h020;  // -9   (trit2 = -1)
  localparam [11:0] T_P27 = 12'h040;  // +27  (trit3)
  localparam [11:0] T_M27 = 12'h080;  // -27  (trit3 = -1)

  task check;
    input [11:0] exp;
    begin
      #1;
      if (u_new !== exp) begin
        errors = errors + 1;
        $display("FAIL vec %0d: u=%h nb=%h -> got %h expect %h",
                 t, u, nb, u_new, exp);
      end else begin
        $display("OK   vec %0d: u=%h -> u_new=%h", t, u, u_new);
      end
    end
  endtask

  initial begin
    errors = 0; t = 0;

    // 1: spike center +27, ring 0 -> F' = 27/3 + 0 = 9
    t = 1; u = T_P27; nb = {6{T0}}; check(T_P9);
    // 2: center +27, ring all +27 -> F' = 9 + 162/9 = 27
    t = 2; u = T_P27; nb = {6{T_P27}}; check(T_P27);
    // 3: center -27, ring 0 -> F' = -9
    t = 3; u = T_M27; nb = {6{T0}}; check(T_M9);
    // 4: center 0, one neighbor +27 -> F' = 27/9 = 3
    t = 4; u = T0; nb = {T0,T0,T0,T0,T0,T_P27}; check(T_P3);
    // 5: center +9, ring all +9 -> F' = 3 + 54/9 = 9
    t = 5; u = T_P9; nb = {6{T_P9}}; check(T_P9);
    // 6: center 0, one neighbor +9 -> F' = 9/9 = 1
    t = 6; u = T0; nb = {T0,T0,T0,T0,T0,T_P9}; check(T_P1);
    // 7: center -9, ring 0 -> F' = -3
    t = 7; u = T_M9; nb = {6{T0}}; check(T_M3);

    if (errors == 0)
      $display("ALL ASSERTIONS PASSED -- trelax_cell verified.");
    else
      $display("%0d ASSERTIONS FAILED", errors);
    $finish;
  end
endmodule
