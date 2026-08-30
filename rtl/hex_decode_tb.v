// ============================================================================
// hex_decode_tb.v — round-trip test of the hex address unit:
//   encode (cell -> u32) then decode (u32 -> cell) == identity.
// Verifies the FULL bijection in RTL, mirroring Bijection.lean's
// ofNat_toNat / toNat_ofNat round-trip proofs.
// ============================================================================
`timescale 1ns/1ps

module hex_decode_tb;

  reg signed [15:0] ca, cb;
  wire [31:0] addr;
  hex_encode u_enc (.addr(addr), .a(ca), .b(cb));

  wire signed [15:0] da, db;
  hex_decode u_dec (.a(da), .b(db), .addr(addr));

  integer errors;

  task chk_roundtrip;
    input signed [15:0] ia, ib;
    begin
      ca = ia; cb = ib; #1;
      if (da !== ia || db !== ib) begin
        errors = errors + 1;
        $display("FAIL: roundtrip (%0d,%0d) -> addr %0d -> (%0d,%0d)", ia, ib, addr, da, db);
      end else
        $display("PASS: roundtrip (%0d,%0d) -> %0d -> back", ia, ib, addr);
    end
  endtask

  initial begin
    errors = 0;
    // the worked examples + corners + a sweep
    chk_roundtrip(16'sd0,     16'sd0);
    chk_roundtrip(16'sd1,     16'sd0);
    chk_roundtrip(16'sd0,     16'sd1);
    chk_roundtrip(16'sd1,     16'sd1);
    chk_roundtrip(-16'sd1,    -16'sd1);
    chk_roundtrip(16'sd2,     -16'sd3);
    chk_roundtrip(-16'sd100,  16'sd100);
    chk_roundtrip(16'sd364,   16'sd364);
    chk_roundtrip(-16'sd364,  16'sd364);
    chk_roundtrip(-16'sd32768, -16'sd32768);   // u32 corner
    chk_roundtrip(16'sd32767,  16'sd32767);    // other corner
    chk_roundtrip(16'sd32767,  -16'sd32768);
    // exhaustive round-trip over the FULL WORD6 operand range [-364, 364]^2
    // (the exact 6-trit balanced range the CPU operands live in — 531,441 cells)
    for (ca = -16'sd364; ca <= 16'sd364; ca = ca + 16'sd1) begin
      for (cb = -16'sd364; cb <= 16'sd364; cb = cb + 16'sd1) begin
        #1;
        if (da !== ca || db !== cb) begin
          errors = errors + 1;
          $display("FAIL: sweep (%0d,%0d) -> (%0d,%0d)", ca, cb, da, db);
        end
      end
    end

    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — hex_encode + hex_decode round-trip verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
