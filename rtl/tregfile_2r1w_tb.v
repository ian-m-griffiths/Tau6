// ============================================================================
// tregfile_2r1w_tb.v — focused check of the 2-read-port ternary register file
// (the module wired into cpu.v): async reset, independent 2-port read, write
// enable, and the 11=NEVER canary on all three ports.
//
// Trit encoding: 01=+1, 00=0, 10=-1, 11=NEVER.  Storage = 24-bit (12 trits).
// ============================================================================
`timescale 1ns/1ps

module tregfile_2r1w_tb;

  reg         clk, rst_n, we;
  reg  [2:0]  wa, ra0, ra1;
  reg  [23:0] wd;
  wire [23:0] rd0, rd1;
  wire        rd0_canary, rd1_canary, wd_canary;
  wire [191:0] q_flat;

  tregfile_2r1w #(.DEPTH(8)) u_rf (
    .clk(clk), .rst_n(rst_n), .we(we),
    .wa(wa), .ra0(ra0), .ra1(ra1), .wd(wd),
    .rd0(rd0), .rd1(rd1),
    .rd0_canary(rd0_canary), .rd1_canary(rd1_canary), .wd_canary(wd_canary),
    .q_flat(q_flat)
  );

  integer errors;

  task chk; input [8*48-1:0] msg; input [31:0] exp, got;
    begin
      if (exp !== got) begin
        errors = errors + 1;
        $display("FAIL: %0s  expected=%0d got=%0d", msg, exp, got);
      end else
        $display("PASS: %0s", msg);
    end
  endtask

  task pulse; begin clk = 1'b1; #1; clk = 1'b0; #1; end endtask

  // 12-trit word with 2'b11 in trit 0 (LSB) and trit 11 (MSB)
  localparam [23:0] BAD = 24'hC00003;

  initial begin
    clk = 1'b0; rst_n = 1'b0; we = 1'b0; wa = 3'b0; ra0 = 3'b0; ra1 = 3'b0; wd = 24'b0;
    errors = 0;

    // ---- reset clears everything --------------------------------------------
    wd = 24'hAAAAAA; wa = 3'd3; we = 1'b1; pulse; pulse;   // write while held in reset
    rst_n = 1'b1;                                          // release reset
    #1;
    ra0 = 3'd3; ra1 = 3'd0; #1;
    chk("async reset held (reg3 still null after reset)", 0, rd0);
    chk("reg0 null after reset", 0, rd1);

    // ---- write 3 distinct words, read both ports independently --------------
    we = 1'b1;
    wa = 3'd1; wd = 24'h555555; pulse;   // reg1 <- all +1
    wa = 3'd2; wd = 24'hAAAAAA; pulse;   // reg2 <- all -1
    wa = 3'd7; wd = 24'h492492; pulse;   // reg7 <- +1,0,-1 pattern
    we = 1'b0;
    #1;
    ra0 = 3'd1; ra1 = 3'd2; #1;
    chk("rd0 reads reg1 (all +1)", 24'h555555, rd0);
    chk("rd1 reads reg2 (all -1)", 24'hAAAAAA, rd1);
    ra0 = 3'd7; ra1 = 3'd7; #1;
    chk("both ports read reg7", 24'h492492, rd0);
    chk("rd1 reads reg7 too",     24'h492492, rd1);

    // ---- write enable gate ---------------------------------------------------
    we = 1'b0; wa = 3'd1; wd = 24'hFFFFFF; pulse;   // we=0: no write
    ra0 = 3'd1; #1;
    chk("we=0 holds reg1", 24'h555555, rd0);

    // ---- canary: forced 11 on write path ------------------------------------
    we = 1'b1; wa = 3'd0; wd = BAD; #1;
    chk("wd_canary fires on forced 11", 1, wd_canary);
    pulse; we = 1'b0; wd = 24'b0;          // actually store BAD in reg0
    ra0 = 3'd0; #1;
    chk("corrupted word stored verbatim", BAD, rd0);
    chk("rd0_canary fires on read", 1, rd0_canary);
    ra1 = 3'd0; #1;
    chk("rd1_canary fires on read", 1, rd1_canary);
    ra0 = 3'd1; #1;
    chk("clean read canary quiet", 0, rd0_canary);

    // ---- q_flat view ----------------------------------------------------------
    chk("q_flat[0] == corrupted reg0", BAD, q_flat[0*24 +: 24]);
    chk("q_flat[7] == pattern reg7", 24'h492492, q_flat[7*24 +: 24]);

    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — tregfile_2r1w verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
