// ============================================================================
// hex_encode_tb.v — testbench for rtl/hex_encode.v (the hex MMU address unit).
// Checks the worked examples from docs/riscv_survey/hex_mmu.md §1/§3b against the
// proven bijection, plus the u32 box corner and the 6-neighbor set of cell (1,0).
// ============================================================================
`timescale 1ns/1ps

module hex_encode_tb;

  reg signed [15:0] a, b;
  wire [31:0] addr;
  hex_encode u_enc (.addr(addr), .a(a), .b(b));

  reg signed [15:0] ga, gb;
  reg [2:0] gk;
  wire signed [15:0] na, nb;
  wire [31:0] naddr;
  hex_neighbor u_nbr (.na(na), .nb(nb), .naddr(naddr), .a(ga), .b(gb), .k(gk));

  integer errors;

  task chk_addr;
    input [255:0] msg;
    input signed [15:0] ia, ib;
    input [31:0] want;
    begin
      a = ia; b = ib; #1;
      if (addr !== want) begin
        errors = errors + 1;
        $display("FAIL: %0s  got %0d want %0d", msg, addr, want);
      end else
        $display("PASS: %0s  = %0d", msg, addr);
    end
  endtask

  initial begin
    errors = 0;

    // hex_mmu.md §1 worked numbers
    chk_addr("(0,0)   -> 0",        16'sd0,     16'sd0,     32'd0);
    chk_addr("(1,0)   -> 6",        16'sd1,     16'sd0,     32'd6);
    chk_addr("(0,1)   -> 4",        16'sd0,     16'sd1,     32'd4);
    chk_addr("(1,1)   -> 8",        16'sd1,     16'sd1,     32'd8);
    chk_addr("(-1,-1) -> 3",        -16'sd1,    -16'sd1,    32'd3);
    // the u32 corner (Bijection.toNat_lt_two_pow_32 / pair_lt_two_pow_32)
    chk_addr("(-2^15,-2^15) -> 2^32-1", -16'sd32768, -16'sd32768, 32'hFFFFFFFF);
    chk_addr("(2^15-1, 2^15-1) corner", 16'sd32767, 16'sd32767, 32'hFFFE0000);

    // hex_mmu.md §3b: the 6 neighbors of cell (1,0) = {20, 0, 8, 7, 4, 21}
    ga = 16'sd1; gb = 16'sd0;
    for (gk = 0; gk < 6; gk = gk + 1) begin
      #1;
      $display("  neighbor k=%0d: cell=(%0d,%0d) addr=%0d", gk, na, nb, naddr);
    end
    // check the set {20,0,8,7,4,21} (address of each of the 6 neighbors)
    #1; gk = 3'd0; #1; if (naddr !== 32'd20) begin errors=errors+1; $display("FAIL k0"); end
        gk = 3'd1; #1; if (naddr !== 32'd8)  begin errors=errors+1; $display("FAIL k1"); end
        gk = 3'd2; #1; if (naddr !== 32'd4)  begin errors=errors+1; $display("FAIL k2"); end
        gk = 3'd3; #1; if (naddr !== 32'd0)  begin errors=errors+1; $display("FAIL k3"); end
        gk = 3'd4; #1; if (naddr !== 32'd7)  begin errors=errors+1; $display("FAIL k4"); end
        gk = 3'd5; #1; if (naddr !== 32'd21) begin errors=errors+1; $display("FAIL k5"); end

    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — hex_encode verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
