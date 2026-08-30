// ============================================================================
// ternary_ff_tb.v — testbench for the ternary sequential cells in
// rtl/ternary_ff.v (tff_latch, tff_edge, tword_ff).
//
// Trit encoding under test: 2'b01 = +1, 2'b00 = 0 (null), 2'b10 = -1.
//
//   Phase 0  null reset     all three cells power on at the null trit
//                           (latch 2'b00, edge FF 2'b00, word FF 24'h000000)
//   Phase 1  latch          transparent while en=1 (d=+1 -> q=+1, etc.); once
//                           en drops, q HOLDS the last trit through d changes
//   Phase 2  edge FF        q updates ONLY on a positive clock edge; d changes
//                           between edges are ignored, and a negedge does not
//                           sample
//   Phase 3  word register  12-trit (24-bit) value sampled on posedge and
//                           held until the next edge (full-width pattern plus
//                           all +1 / all -1 / all-null words)
//
// The edge cells are driven by TB-controlled clocks (eclk / wclk) so every
// edge is explicit and race-free; the latch is level-sensitive on `en` only.
// ============================================================================

`timescale 1ns/1ps

module ternary_ff_tb;

  // ---- DUTs -----------------------------------------------------------------
  reg         en;
  reg  [1:0]  d;
  wire [1:0]  q_latch;
  reg  [23:0] wd;
  wire [23:0] wq;

  tff_latch u_latch (.d(d), .en(en), .q(q_latch));
  tff_edge  u_edge  (.clk(eclk), .d(d), .q(q_edge));
  tword_ff  u_word  (.clk(wclk), .d(wd), .q(wq));

  // TB-controlled clocks for the edge-triggered DUTs (start low, no free run)
  reg eclk, wclk;
  wire [1:0] q_edge;

  localparam [23:0] WORD_PAT = 24'b0110_0001_1000_0110_0001_1000; // +1,-1,0 x4

  integer errors;

  // ---- check helper ----------------------------------------------------------
  task check;
    input [8*48-1:0] msg;
    input [23:0] expected;
    input [23:0] actual;
    begin
      if (expected !== actual) begin
        errors = errors + 1;
        $display("FAIL: %0s  expected=%b  got=%b", msg, expected, actual);
      end else
        $display("PASS: %0s  (%b)", msg, actual);
    end
  endtask

  // one positive edge on signal s (posedge -> settle -> low again)
  `define PULSE(s) begin s = 1'b1; #1; s = 1'b0; #1; end

  // ---- stimulus --------------------------------------------------------------
  initial begin
    d = 2'b00; en = 1'b0; wd = 24'b0;
    eclk = 1'b0; wclk = 1'b0;
    errors = 0;

    $display("======================================================");
    $display("ternary FF testbench   (trit: 01=+1  00=0  10=-1)");
    $display("======================================================");

    // ---- Phase 0: power-on null reset ----------------------------------------
    #1;
    check("latch resets to null trit",        2'b00,       q_latch);
    check("edge FF resets to null trit",      2'b00,       q_edge);
    check("word FF resets to all-null word",  24'h000000,  wq);

    // ---- Phase 1: latch transparency + hold ----------------------------------
    d = 2'b01; en = 1'b1;              // d=+1, latch transparent
    #1;
    check("latch follows d=+1 (transparent)",   2'b01, q_latch);
    d = 2'b00;                         // still transparent
    #1;
    check("latch follows d=0 (transparent)",    2'b00, q_latch);
    d = 2'b10;                         // still transparent
    #1;
    check("latch follows d=-1 (transparent)",   2'b10, q_latch);
    en = 1'b0;                         // latch closed, holding -1
    d = 2'b01;                         // d changes underneath
    #1;
    check("latch HOLDS -1 past d=+1",          2'b10, q_latch);
    d = 2'b00;
    #1;
    check("latch HOLDS -1 past d=0",           2'b10, q_latch);
    d = 2'b10;
    #1;
    check("latch HOLDS -1",                    2'b10, q_latch);
    en = 1'b1;                         // re-open
    #1;
    check("latch re-opens to d=-1",            2'b10, q_latch);
    d = 2'b01;
    #1;
    check("latch follows d=+1 again",          2'b01, q_latch);

    // ---- Phase 2: edge-triggered FF ------------------------------------------
    // q_edge has seen no clock edge yet: reset null must be intact
    check("edge FF untouched by latch tests",  2'b00, q_edge);

    d = 2'b01;
    `PULSE(eclk)                       // posedge: sample +1
    check("edge FF samples d=+1",              2'b01, q_edge);
    d = 2'b10;                         // d changes BETWEEN edges
    #2;
    check("edge FF HOLDS through d change",    2'b01, q_edge);
    `PULSE(eclk)                       // next posedge: sample -1
    check("edge FF samples d=-1",              2'b10, q_edge);
    d = 2'b00;                         // d=null between edges
    #2;
    check("edge FF HOLDS (no edge)",           2'b10, q_edge);
    `PULSE(eclk)                       // posedge: sample null
    check("edge FF samples d=0 (null)",        2'b00, q_edge);

    // negedge must NOT sample: raise clock (posedge with d=00 keeps q=00),
    // change d while high, then fall the clock.  The #1 lets the posedge
    // commit BEFORE d moves, so the same-timestep d/edge race cannot occur.
    eclk = 1'b1;                       // posedge, d=00 -> q stays 00
    #1;
    d = 2'b01;                         // d=+1 while clock high
    #2;
    check("edge FF holds while clock high",    2'b00, q_edge);
    eclk = 1'b0;                       // NEGEDGE only
    #2;
    check("edge FF IGNORES negedge",           2'b00, q_edge);

    // ---- Phase 3: 12-trit word register --------------------------------------
    check("word FF untouched so far",          24'h000000, wq);
    wd = WORD_PAT;                     // 12 trits, MSB->LSB: +1,-1,0 x4
    `PULSE(wclk)
    check("word FF loads 12-trit pattern",     WORD_PAT, wq);
    wd = 24'b0;                        // change d, no edge
    #2;
    check("word FF HOLDS 12-trit pattern",     WORD_PAT, wq);
    `PULSE(wclk)
    check("word FF loads all-null word",       24'h000000, wq);
    wd = 24'b0101_0101_0101_0101_0101_0101;    // all +1 trits
    `PULSE(wclk)
    check("word FF loads all +1 trits",        wd, wq);
    wd = 24'b1010_1010_1010_1010_1010_1010;    // all -1 trits
    `PULSE(wclk)
    check("word FF loads all -1 trits",        wd, wq);

    // ---- summary --------------------------------------------------------------
    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — ternary sequential cells verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
