// ============================================================================
// xlattice_cfu_tb.v — testbench for rtl/xlattice_cfu.v (the Xlattice CFU datapath).
// Checks the GA opcode encodings against the cpu_ga_tb / xlattice.py values:
//   z = 2+3w, w = 1-2w : TCONJ conj z = (5,-3); TDOT = -8; TWEDGE = 7; TSYMDOT = -9.
// Operands are 24-bit 2-bit/trit words; the tb drives the balanced-integer pairs by
// encoding them with the s2t6-style balanced digit extraction.
// ============================================================================
`timescale 1ns/1ps

module xlattice_cfu_tb;

  reg  [6:0] f7;
  reg  [2:0] f3;
  reg  [23:0] z, w;
  wire [23:0] rd;
  wire        ovf;
  xlattice_cfu u_cfu (.rd(rd), .ovf(ovf), .funct7(f7), .funct3(f3), .z(z), .w(w));

  integer errors;

  // balanced integer -> 6-trit 2-bit/trit field (little-endian trits)
  function [11:0] enc;
    input integer v;
    integer r, d, j;
    begin
      r = v; enc = 12'b0;
      for (j = 0; j < 6; j = j + 1) begin
        d = r % 3;
        if (d == 2) begin enc[j*2 +: 2] = 2'b10; r = (r + 1) / 3; end
        else if (d == -2) begin enc[j*2 +: 2] = 2'b01; r = (r - 1) / 3; end
        else begin
          if (d == 1) enc[j*2 +: 2] = 2'b01;
          else if (d == -1) enc[j*2 +: 2] = 2'b10;
          r = r / 3;
        end
      end
    end
  endfunction

  // 2-bit/trit field -> balanced integer
  function integer dec;
    input [11:0] f;
    integer j, p;
    begin
      dec = 0; p = 1;
      for (j = 0; j < 6; j = j + 1) begin
        case (f[j*2 +: 2])
          2'b01: dec = dec + p;
          2'b10: dec = dec - p;
        endcase
        p = p * 3;
      end
    end
  endfunction

  task chk;
    input [255:0] msg;
    input [6:0] if7;
    input [2:0] if3;
    input integer za, zb, wa, wb;      // z = za+zb*w ; w = wa+wb*w
    input integer exp_a, exp_b;        // expected (a,b)
    input         exp_ovf;
    begin
      f7 = if7; f3 = if3;
      z = {enc(zb), enc(za)};
      w = {enc(wb), enc(wa)};
      #1;
      if (dec(rd[11:0]) !== exp_a || dec(rd[23:12]) !== exp_b || ovf !== exp_ovf) begin
        errors = errors + 1;
        $display("FAIL: %0s  got (%0d,%0d) ovf=%b  want (%0d,%0d) ovf=%b",
                 msg, dec(rd[11:0]), dec(rd[23:12]), ovf, exp_a, exp_b, exp_ovf);
      end else
        $display("PASS: %0s  = (%0d,%0d)", msg, dec(rd[11:0]), dec(rd[23:12]));
    end
  endtask

  initial begin
    errors = 0;
    // z = 2+3w, w = 1-2w
    chk("TCONJ  conj(2+3w) = (5,-3)", 7'b0000001, 3'b001, 2, 3, 0, 0,  5, -3, 0);
    chk("TDOT   dot = -8",            7'b0000100, 3'b000, 2, 3, 1, -2, -8, 0, 0);
    chk("TWEDGE wedge = 7",           7'b0000101, 3'b000, 2, 3, 1, -2,  7, 0, 0);
    chk("TSYMDOT symdot = -9",        7'b0000110, 3'b000, 2, 3, 1, -2, -9, 0, 0);
    // antisymmetry: wedge(w,z) = -7
    chk("TWEDGE antisymm = -7",       7'b0000101, 3'b000, 1, -2, 2, 3, -7, 0, 0);

    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — xlattice_cfu verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
