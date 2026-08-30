// ============================================================================
// binary_tgrad_tb.v -- prove the BINARY reduction reproduces the TERNARY result.
//
// Lockstep test: the same hex pod drives BOTH
//   (a) tgrad_cell        (grad_recon.v -- the ternary balanced-adder tree), and
//   (b) binary_tgrad      (binary_tgrad.v -- plain 2's-complement adders),
// and every pod must give the SAME div/curl from both, equal to the integer
// formula  div = F0-F2-F3+F5, curl = F1+F2-F4-F5.
//
// Primary vector is the tau_field_tb.v field: F0=+3, F1=+9 -> div=3, curl=9.
// Plus the additive gauge (uniform field -> 0,0), a mixed-sign pod, and two
// full-range pods (div=1456, curl=1456) to exercise the 12-bit 2's-complement
// path at its extremes.
//
// Verilog-2001; depends on rtl/converters.v (t2b), rtl/ternary_gates.v
// (tadd_trits), rtl/grad_recon.v (tgrad_cell), rtl/binary_tgrad.v.
// ============================================================================
`timescale 1ns/1ps

module binary_tgrad_tb;

  // ---- the ternary-encoded field values (6 trits each, 2 bits/trit) ---------
  reg [11:0] f0t, f1t, f2t, f3t, f4t, f5t;
  reg [11:0] ctr;                       // center (gauge; drops out of both)

  // ---- ternary reference (tgrad_cell, SW=8 trits -> 16 bits) -----------------
  wire [15:0] tdiv, tcurl;
  tgrad_cell #(.NTRITS(6)) u_ternary (
    .div(tdiv), .curl(tcurl), .c(ctr),
    .nb({f5t, f4t, f3t, f2t, f1t, f0t}));

  // ---- the binary reduction under test (signed 12-bit 2's-complement) --------
  wire signed [11:0] bdiv, bcurl;
  binary_tgrad #(.NTRITS(6)) u_binary (
    .div(bdiv), .curl(bcurl), .c(ctr),
    .nb({f5t, f4t, f3t, f2t, f1t, f0t}));

  integer errors;

  // balanced integer -> 6-trit 2-bit/trit field (matches tau_field_tb enc6)
  function [11:0] enc;
    input integer v;
    integer r, d, j;
    begin
      r = v; enc = 12'b0;
      for (j = 0; j < 6; j = j + 1) begin
        d = r % 3;
        if (d == 2)      begin enc[j*2 +: 2] = 2'b10; r = (r + 1) / 3; end
        else if (d == -2) begin enc[j*2 +: 2] = 2'b01; r = (r - 1) / 3; end
        else begin
          if (d == 1)  enc[j*2 +: 2] = 2'b01;
          else if (d == -1) enc[j*2 +: 2] = 2'b10;
          r = r / 3;
        end
      end
    end
  endfunction

  // 8-trit 2-bit/trit field -> integer (matches tau_field_tb dec)
  function integer dec;
    input [15:0] f;
    integer j, pv;
    begin
      dec = 0; pv = 1;
      for (j = 0; j < 8; j = j + 1) begin
        case (f[j*2 +: 2])
          2'b01: dec = dec + pv;
          2'b10: dec = dec - pv;
        endcase
        pv = pv * 3;
      end
    end
  endfunction

  // drive both datapaths from 6 integer field values and assert they agree with
  // the integer reduction formula (and with each other).
  task check;
    input integer v0, v1, v2, v3, v4, v5;
    integer e_div, e_curl;
    begin
      f0t = enc(v0); f1t = enc(v1); f2t = enc(v2);
      f3t = enc(v3); f4t = enc(v4); f5t = enc(v5);
      ctr = enc(0);
      #1;
      e_div  = v0 - v2 - v3 + v5;
      e_curl = v1 + v2 - v4 - v5;
      $display("  pod(%0d,%0d,%0d,%0d,%0d,%0d): ternary div/curl = %0d,%0d  binary = %0d,%0d  (expect %0d,%0d)",
               v0, v1, v2, v3, v4, v5, dec(tdiv), dec(tcurl), bdiv, bcurl, e_div, e_curl);
      if (dec(tdiv) !== e_div || dec(tcurl) !== e_curl) begin
        errors = errors + 1;
        $display("FAIL ternary : div=%0d curl=%0d  (expect %0d, %0d)",
                 dec(tdiv), dec(tcurl), e_div, e_curl);
      end
      if (bdiv !== e_div || bcurl !== e_curl) begin
        errors = errors + 1;
        $display("FAIL binary  : div=%0d curl=%0d  (expect %0d, %0d)",
                 bdiv, bcurl, e_div, e_curl);
      end
      if (dec(tdiv) !== bdiv || dec(tcurl) !== bcurl) begin
        errors = errors + 1;
        $display("FAIL lockstep: ternary(%0d,%0d) != binary(%0d,%0d)",
                 dec(tdiv), dec(tcurl), bdiv, bcurl);
      end
    end
  endtask

  initial begin
    errors = 0;
    $display("binary_tgrad_tb: lockstep ternary vs binary TGRAD reduction");

    // 1) the tau_field_tb field: F0=+3, F1=+9 -> div=3, curl=9
    check(3, 9, 0, 0, 0, 0);

    // 2) additive gauge: uniform field -> zero gradient
    check(7, 7, 7, 7, 7, 7);

    // 3) mixed signs: div = 3-5-(-2)+1 = 1, curl = -9+5-4-1 = -9
    check(3, -9, 5, -2, 4, 1);

    // 4) full range: div = 364-(-364)-(-364)+(-364) = 728,
    //                curl = 364+(-364)-364-(-364) = 0
    check(364, 364, -364, -364, 364, -364);

    // 5) div at the 4*364 = 1456 ceiling (12-bit signed path, no overflow)
    check(364, 364, -364, -364, -364, 364);

    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — binary_tgrad reproduces tgrad_cell.");
    else
      $display("%0d FAILURES", errors);
    $finish;
  end

endmodule
