// ============================================================================
// junction_cell_tb.v — testbench for rtl/junction_cell.v.
// Verifies (a) the one-hot junction invariant, (b) free wire-swap negation,
// and (c) the active-channel energy counter, plus the 11=NEVER canary.
// ============================================================================
`timescale 1ns/1ps

module junction_tb;

  // ---- single-trit junction probe -------------------------------------------
  reg  [1:0] t;
  wire valid, bad, push, pull, null, active;
  junction_trit u_j (.valid(valid), .bad(bad), .push(push), .pull(pull),
                     .null(null), .active(active), .t(t));

  // ---- single-trit negation (reuses t as the input) -------------------------
  wire [1:0] nt_neg;
  tneg_junction u_neg (.nt(nt_neg), .t(t));

  // ---- 12-trit word under test ----------------------------------------------
  reg  [23:0] word;
  wire [3:0]  act;
  active_count u_act (.count(act), .word(word));

  // ---- the same word decoded through 12 junction cells: per-trit active bits
  //      + a word-level canary (OR of the 12 bad flags) ------------------------
  wire [11:0] j_valid, j_bad, j_push, j_pull, j_null, j_active;
  genvar g;
  generate
    for (g = 0; g < 12; g = g + 1) begin : gen_j
      junction_trit jt (.valid(j_valid[g]), .bad(j_bad[g]), .push(j_push[g]),
                        .pull(j_pull[g]), .null(j_null[g]), .active(j_active[g]),
                        .t(word[2*g +: 2]));
    end
  endgenerate
  wire word_canary = |j_bad;

  // ---- whole-word negation: 12 parallel wire swaps ---------------------------
  wire [23:0] nword;
  genvar h;
  generate
    for (h = 0; h < 12; h = h + 1) begin : gen_neg
      tneg_junction nj (.nt(nword[2*h +: 2]), .t(word[2*h +: 2]));
    end
  endgenerate
  wire [3:0] act_neg;
  active_count u_act_neg (.count(act_neg), .word(nword));

  integer errors;

  // ---- check one trit: decode + one-hot invariant ---------------------------
  task chk_trit;
    input [255:0] msg;
    input [1:0]   val;
    input         exp_valid, exp_bad, exp_push, exp_pull, exp_null, exp_active;
    begin
      t = val; #1;
      if (valid !== exp_valid || bad !== exp_bad || push !== exp_push ||
          pull !== exp_pull || null !== exp_null || active !== exp_active) begin
        errors = errors + 1;
        $display("FAIL: %0s  t=%2b  got v=%b b=%b push=%b pull=%b null=%b act=%b",
                 msg, val, valid, bad, push, pull, null, active);
      end else if (valid && (push + pull + null !== 1'b1)) begin
        errors = errors + 1;
        $display("FAIL: %0s  not one-hot (push+pull+null != 1)", msg);
      end else
        $display("PASS: %0s  t=%2b  push=%b pull=%b null=%b active=%b valid=%b",
                 msg, val, push, pull, null, active, valid);
    end
  endtask

  // ---- check negation: wire swap, null fixed --------------------------------
  task chk_neg;
    input [255:0] msg;
    input [1:0]   val;
    input [1:0]   exp;
    begin
      t = val; #1;
      if (nt_neg !== exp) begin
        errors = errors + 1;
        $display("FAIL: %0s  t=%2b neg=%2b want %2b", msg, val, nt_neg, exp);
      end else
        $display("PASS: %0s  t=%2b -> neg=%2b", msg, val, nt_neg);
    end
  endtask

  // ---- check a whole word: active_count == per-trit sum, canary -------------
  task chk_word;
    input [255:0] msg;
    input [23:0]  w;
    input [3:0]   exp_act;
    input         exp_canary;
    integer k, s;
    begin
      word = w; #1;
      s = 0;
      for (k = 0; k < 12; k = k + 1) s = s + j_active[k];
      if (act !== exp_act) begin
        errors = errors + 1;
        $display("FAIL: %0s  active_count=%0d want %0d", msg, act, exp_act);
      end else if (s !== exp_act) begin
        errors = errors + 1;
        $display("FAIL: %0s  per-trit active sum=%0d want %0d", msg, s, exp_act);
      end else if (word_canary !== exp_canary) begin
        errors = errors + 1;
        $display("FAIL: %0s  canary=%0b want %0b", msg, word_canary, exp_canary);
      end else
        $display("PASS: %0s  active_count=%0d (sum=%0d, canary=%0b)",
                 msg, act, s, word_canary);
    end
  endtask

  initial begin
    errors = 0;
    $display("==============================================================");
    $display("junction_cell.v — polarity-junction trit + active-channel energy");
    $display("==============================================================");

    // (1) every valid encoding -> exactly one active channel (or null); 11 -> canary
    $display("-- (1) one-hot junction invariant ------------------------------");
    chk_trit("+1 push ", 2'b01, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
    chk_trit(" 0 null ", 2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
    chk_trit("-1 pull ", 2'b10, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
    chk_trit("11 NEVER", 2'b11, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);

    // (2) negation = wire swap; null fixed; ZERO channel activations
    $display("-- (2) free wire-swap negation --------------------------------");
    chk_neg("neg +1 -> -1", 2'b01, 2'b10);
    chk_neg("neg  0 ->  0", 2'b00, 2'b00);
    chk_neg("neg -1 -> +1", 2'b10, 2'b01);

    // (3) active_count over known words
    $display("-- (3) active-channel energy counter ---------------------------");
    chk_word("all null       -> 0 active",  24'h000000, 4'd0,  1'b0);
    chk_word("all +1         -> 12 active", 24'h555555, 4'd12, 1'b0);
    chk_word("all -1         -> 12 active", 24'hAAAAAA, 4'd12, 1'b0);
    chk_word("+1,-1 alt      -> 12 active", 24'h666666, 4'd12, 1'b0);
    chk_word("+1,0,-1 repeat -> 8 active",  24'h492492, 4'd8,  1'b0);
    chk_word("forced 11 -> canary", 24'h000003, 4'd0, 1'b1);

    // (4) whole-word negation is energy-free (12 wire swaps)
    $display("-- (4) negation preserves energy -------------------------------");
    begin : neg_inv
      integer k;
      reg mism;
      mism = 1'b0;
      word = 24'h492492; #1;
      for (k = 0; k < 12; k = k + 1)
        if (nword[2*k +: 2] !== {word[2*k], word[2*k+1]})
          mism = 1'b1;
      if (mism) begin
        errors = errors + 1;
        $display("FAIL: whole-word negation is not a bit-swap");
      end else if (act_neg !== act) begin
        errors = errors + 1;
        $display("FAIL: negation changed active_count %0d -> %0d", act, act_neg);
      end else
        $display("PASS: 12 wire swaps; active_count %0d == neg %0d (ZERO energy)",
                 act, act_neg);
    end

    // energy accounting: one channel per trit means <= 12 of 24 wires live
    $display("--------------------------------------------------------------");
    $display("energy per 12-trit word (one channel per trit, 24 wires total):");
    $display("  all +-1 (12 active) : 12 energized channels  (dense data)");
    $display("  +1,0,-1 (8 active)  :  8 energized channels  (4 nulls free)");
    $display("  all null (0 active) :  0 energized channels  (the free-null win)");
    $display("  (active_count <= 12 always: at most ONE rail per trit lives)");

    $display("==============================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — junction_cell verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("==============================================================");
    $finish;
  end

endmodule
