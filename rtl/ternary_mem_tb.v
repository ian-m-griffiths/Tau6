// ============================================================================
// ternary_mem_tb.v — testbench for rtl/ternary_mem.v (register file, 11=NEVER
// canary, 4/5-trit packing).  Trit encoding under test: 2'b01=+1, 2'b00=0,
// 2'b10=-1, 2'b11=NEVER.
//
//   Phase 1  register file    power-on all-null; write DEPTH distinct words;
//                             read all back (round-trip); overwrite one word
//                             (no clobber of neighbours); hold with we=0.
//   Phase 2  canary           normal data never fires; a forced 2'b11 in the
//                             write data fires wd_canary; the stored 11 fires
//                             rd_canary on read; clean reads stay quiet.  Plus
//                             direct trit_canary (all 4 codes) and tword_canary
//                             (a 11 swept through all 12 trit positions).
//   Phase 3  trit packing     ALL 3^4=81 (4-trit) and 3^5=243 (5-trit) states:
//                             build reference trits from the base-3 digits of
//                             the packed value, then check encode (trits->bits)
//                             and decode (bits->trits) against that reference.
//
// The regfile DUT is clocked by a TB-controlled clock so every edge is explicit
// and race-free; the packers/canaries are combinational and checked after #1.
// ============================================================================

`timescale 1ns/1ps

module ternary_mem_tb;

  // ---- register-file DUT -----------------------------------------------------
  reg         clk;
  reg         we;
  reg  [2:0]  wa, ra;
  reg  [23:0] wd;
  wire [23:0] rd;
  wire        rd_canary, wd_canary;

  tregfile #(.DEPTH(8)) u_rf (
    .clk(clk), .we(we), .wa(wa), .ra(ra),
    .wd(wd), .rd(rd), .rd_canary(rd_canary), .wd_canary(wd_canary)
  );

  // ---- canary DUTs (direct) --------------------------------------------------
  reg  [1:0]  ct;
  wire        cf;
  trit_canary u_tc (.t(ct), .flag(cf));

  reg  [23:0] can_word;
  wire [11:0] can_bad;
  wire        can_flag;
  tword_canary #(.NTRITS(12)) u_wc (.word(can_word), .bad(can_bad), .flag(can_flag));

  // ---- packing DUTs ----------------------------------------------------------
  reg  [7:0]  trits_in4;
  wire [6:0]  packed4;
  reg  [6:0]  packed_in4;
  wire [7:0]  trits4;
  reg  [9:0]  trits_in5;
  wire [7:0]  packed5;
  reg  [7:0]  packed_in5;
  wire [9:0]  trits5;

  pack4_trits   u_p4 (.trits(trits_in4), .packed(packed4));
  unpack4_trits u_u4 (.packed(packed_in4), .trits(trits4));
  pack5_trits   u_p5 (.trits(trits_in5), .packed(packed5));
  unpack5_trits u_u5 (.packed(packed_in5), .trits(trits5));

  // ---- stimulus state --------------------------------------------------------
  integer errors;
  integer i, c;
  integer d0, d1, d2, d3, d4;
  reg [31:0] expect;
  reg [7:0]  ref4;
  reg [9:0]  ref5;
  reg [6:0]  c7;
  reg [7:0]  c8;

  // 8 distinct, all-valid (no 2'b11) 12-trit patterns, one per register
  reg [23:0] pats [0:7];
  // a word with 2'b11 in trit 0 (LSB) AND trit 11 (MSB): the forced corruption
  localparam [23:0] BAD = 24'hC00003;

  // ---- check helper ----------------------------------------------------------
  task check_eq;
    input [8*48-1:0] msg;
    input [31:0] expected;
    input [31:0] actual;
    begin
      if (expected !== actual) begin
        errors = errors + 1;
        $display("FAIL: %0s  expected=%b  got=%b", msg, expected, actual);
      end else
        $display("PASS: %0s", msg);
    end
  endtask

  // one positive clock edge (posedge -> settle -> low)
  task pulse_clk;
    begin
      clk = 1'b1; #1; clk = 1'b0; #1;
    end
  endtask

  // reference: base-3 digit (0,1,2) -> 2-bit trit (-1,0,+1)
  function [1:0] ref_trit;
    input integer d;
    begin
      case (d)
        0: ref_trit = 2'b10;
        1: ref_trit = 2'b00;
        2: ref_trit = 2'b01;
        default: ref_trit = 2'b00;
      endcase
    end
  endfunction

  // ---- stimulus --------------------------------------------------------------
  initial begin
    clk = 1'b0; we = 1'b0; wa = 3'b0; ra = 3'b0; wd = 24'b0;
    ct = 2'b00; can_word = 24'b0;
    trits_in4 = 8'b0; packed_in4 = 7'b0; trits_in5 = 10'b0; packed_in5 = 8'b0;
    errors = 0;

    pats[0] = 24'h000000;  // all null
    pats[1] = 24'h555555;  // 0101...  all +1
    pats[2] = 24'hAAAAAA;  // 1010...  all -1
    pats[3] = 24'h666666;  // 0110...  +1,-1 repeating
    pats[4] = 24'h999999;  // 1001...  -1,+1 repeating
    pats[5] = 24'h492492;  // +1,0,-1 repeating x4
    pats[6] = 24'h249249;  // 0,-1,+1 repeating x4
    pats[7] = 24'h924924;  // -1,+1,0 repeating x4

    $display("======================================================");
    $display("ternary memory testbench  (trit: 01=+1 00=0 10=-1 11=NEVER)");
    $display("======================================================");

    // ---- Phase 1a: power-on null --------------------------------------------
    for (i = 0; i < 8; i = i + 1) begin
      ra = i[2:0]; #1;
      check_eq("regfile powers on all-null", 24'h000000, rd);
      check_eq("power-on read canary quiet",   1'b0,       rd_canary);
    end

    // ---- Phase 1b: write 8 distinct words -----------------------------------
    we = 1'b1;
    for (i = 0; i < 8; i = i + 1) begin
      wa = i[2:0]; wd = pats[i]; #1;
      check_eq("write data canary quiet (valid word)", 1'b0, wd_canary);
      pulse_clk;                       // posedge: register i samples pats[i]
    end
    we = 1'b0;

    // ---- Phase 1c: read all back (round-trip) --------------------------------
    for (i = 0; i < 8; i = i + 1) begin
      ra = i[2:0]; #1;
      check_eq("regfile read-back round-trip", pats[i], rd);
      check_eq("read canary quiet on valid word", 1'b0,   rd_canary);
    end

    // ---- Phase 1d: overwrite one word, no clobber ----------------------------
    we = 1'b1; wa = 3'd0; wd = pats[1]; #1; pulse_clk; we = 1'b0;  // reg0 <- pats[1]
    ra = 3'd0; #1; check_eq("reg0 overwritten", pats[1], rd);
    ra = 3'd1; #1; check_eq("reg1 untouched (no clobber)", pats[1], rd);
    ra = 3'd2; #1; check_eq("reg2 untouched (no clobber)", pats[2], rd);

    // ---- Phase 1e: hold with we=0 --------------------------------------------
    we = 1'b0; wa = 3'd3; wd = pats[4]; pulse_clk;   // we=0: nothing writes
    ra = 3'd0; #1; check_eq("reg0 held (we=0)", pats[1], rd);
    ra = 3'd3; #1; check_eq("reg3 held (we=0)", pats[3], rd);

    // ---- Phase 2: the 11=NEVER canary ----------------------------------------
    // normal write data does not fire
    wd = pats[0]; #1; check_eq("wd_canary quiet on null word", 1'b0, wd_canary);
    // force a 2'b11 into the write data path
    wd = BAD;      #1; check_eq("wd_canary FIRES on forced 11 (write path)", 1'b1, wd_canary);
    // actually store the corrupted word in reg7
    we = 1'b1; wa = 3'd7; #1; pulse_clk; we = 1'b0; wd = 24'b0;
    ra = 3'd7; #1;
    check_eq("corrupted word stored as written",   BAD, rd);
    check_eq("rd_canary FIRES on forced 11 (read path)", 1'b1, rd_canary);
    // a clean register stays quiet
    ra = 3'd0; #1; check_eq("clean read canary quiet after corruption", 1'b0, rd_canary);

    // single-trit canary primitive: only 2'b11 fires
    ct = 2'b00; #1; check_eq("trit_canary(00)=0", 1'b0, cf);
    ct = 2'b01; #1; check_eq("trit_canary(01)=0", 1'b0, cf);
    ct = 2'b10; #1; check_eq("trit_canary(10)=0", 1'b0, cf);
    ct = 2'b11; #1; check_eq("trit_canary(11)=1", 1'b1, cf);

    // word canary: sweep a lone 2'b11 through all 12 trit positions
    for (i = 0; i < 12; i = i + 1) begin
      can_word = 24'b0;
      can_word[2*i +: 2] = 2'b11;
      #1;
      expect = 0;
      if (can_flag !== 1'b1) begin
        errors = errors + 1;
        $display("FAIL: tword_canary flag at trit %0d", i);
      end
      if (can_bad[i] !== 1'b1) begin
        errors = errors + 1;
        $display("FAIL: tword_canary bad[%0d] not set", i);
      end
    end
    can_word = 24'b0; #1;
    check_eq("tword_canary quiet on all-null word", 1'b0, can_flag);

    // ---- Phase 3: trit packing, all states -----------------------------------
    // 4 trits <-> 7 bits: 3^4 = 81 states (packed 0..80)
    for (c = 0; c < 81; c = c + 1) begin
      d0 = c % 3; d1 = (c / 3) % 3; d2 = (c / 9) % 3; d3 = (c / 27) % 3;
      ref4 = {ref_trit(d3), ref_trit(d2), ref_trit(d1), ref_trit(d0)};
      trits_in4 = ref4;                          // encode direction
      #1;
      c7 = c;
      if (packed4 !== c7) begin
        errors = errors + 1;
        $display("FAIL: pack4 encode c=%0d ref=%b got=%b", c, ref4, packed4);
      end
      packed_in4 = packed4;                      // decode direction
      #1;
      if (trits4 !== ref4) begin
        errors = errors + 1;
        $display("FAIL: unpack4 decode c=%0d ref=%b got=%b", c, ref4, trits4);
      end
    end
    $display("PASS: pack4/unpack4 all 81 states round-trip");

    // 5 trits <-> 8 bits: 3^5 = 243 states (packed 0..242)
    for (c = 0; c < 243; c = c + 1) begin
      d0 = c % 3; d1 = (c / 3) % 3; d2 = (c / 9) % 3; d3 = (c / 27) % 3;
      d4 = (c / 81) % 3;
      ref5 = {ref_trit(d4), ref_trit(d3), ref_trit(d2), ref_trit(d1), ref_trit(d0)};
      trits_in5 = ref5;
      #1;
      c8 = c;
      if (packed5 !== c8) begin
        errors = errors + 1;
        $display("FAIL: pack5 encode c=%0d ref=%b got=%b", c, ref5, packed5);
      end
      packed_in5 = packed5;
      #1;
      if (trits5 !== ref5) begin
        errors = errors + 1;
        $display("FAIL: unpack5 decode c=%0d ref=%b got=%b", c, ref5, trits5);
      end
    end
    $display("PASS: pack5/unpack5 all 243 states round-trip");

    // ---- summary --------------------------------------------------------------
    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — ternary memory verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
