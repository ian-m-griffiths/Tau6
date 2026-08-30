// ============================================================================
// ternary_link.v — the ternary transport link (Phase 4, transport side).
//
// The digital wire interface that embodies the transport win (FINAL_VERDICT
// ~2.7-6.3x): the NULL trit (00) costs ~0 on the wire — information by doing
// nothing.  This module measures that:
//
//   * trit_null_count : number of 00 (null) trits in a 12-trit word — the "free
//                       symbols" the transport energy model (scripts/transport.py)
//                       prices at ~0.05 pJ vs ~1.20 pJ for a +-1 toggle.
//   * trit_link_canary: 1 iff any trit is 2'b11 (the 11=NEVER SEU detector,
//                       storage.md §6.1 / TernaryCell.lean encode_never_both).
//
// The null count drives the transport energy: E = nulls*E_null + (12-nulls)*E_pm1.
// A null-heavy word (more 00) costs less — exactly the conditional win the model
// reports.  (The serial shift/clocking of the wire is standard plumbing; the analog
// layer is ngspice-measured.)
//
// 2-bit/trit code: 01=+1, 00=0 (null), 10=-1, 11=NEVER.
//
// Verilog-2001; synthesizable; self-contained.
// ============================================================================

`timescale 1ns/1ps

// ----------------------------------------------------------------------------
// trit_null_count: number of NULL trits (00) in a 12-trit (24-bit) word, 0..12.
// ----------------------------------------------------------------------------
module trit_null_count (
  output reg  [3:0] count,
  input  wire [23:0] word
);
  integer i;
  always @(*) begin
    count = 4'd0;
    for (i = 0; i < 12; i = i + 1)
      if (word[2*i +: 2] == 2'b00)
        count = count + 4'd1;
  end
endmodule

// ----------------------------------------------------------------------------
// trit_link_canary: 11=NEVER detector — 1 iff any trit of the word is 2'b11.
// A single-bit upset in a valid trit (01 or 10) lands in 11 with prob 1/3; this
// flags it (the asymmetric SEU canary of storage.md §6.1).
// ----------------------------------------------------------------------------
module trit_link_canary (
  output wire       flag,
  input  wire [23:0] word
);
  reg [11:0] bad;
  integer i;
  always @(*) begin
    bad = 12'b0;
    for (i = 0; i < 12; i = i + 1)
      bad[i] = word[2*i+1] & word[2*i];   // 11 = both rails energized
  end
  assign flag = |bad;
endmodule
