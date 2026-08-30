// ============================================================================
// junction_cell.v — the polarity-junction trit cell + active-channel energy
// counter (Tau Architecture).
//
// A trit is modeled as TWO anti-polar channels sharing a middle node: a push
// line and a pull line.  At most one channel is energized at a time:
//
//     value    bits {pull,push}    energized channels
//     -----    ----------------    ------------------
//      +1      2'b01               push only
//       0      2'b00               neither (null — "free", nothing energized)
//      -1      2'b10               pull only
//      NEVER   2'b11               BOTH — an SEU/error state, flagged, never
//                                  produced (TernaryCell.lean encode_never_both)
//
// The three modules here realize the cell's RTL contract:
//   * junction_trit  — decode a raw 2-bit trit, ENFORCE the one-hot invariant
//                      (the 11 state is normalized to "no valid channel" and
//                      flagged on `bad`), and expose push/pull/null/active.
//   * tneg_junction  — negation as a FREE wire swap (push <-> pull): no wire
//                      changes level, so it costs ZERO channel activations.
//   * active_count   — the energy counter: number of energized channels in a
//                      12-trit (24-bit) word, 0..12.  This is the logic-level
//                      analog of trit_null_count (rtl/ternary_link.v) but
//                      counting the ±1 rails instead of the 00 nulls.
//
// The "one channel per trit" saving: a 12-trit word is 24 wires, but a valid
// word energizes at most ONE of each trit's two rails — active_count never
// exceeds 12.  The null trits contribute 0, so the counter makes the
// conditional energy E = active*E_pm1 (nulls are free) directly measurable in
// simulation.
//
// Verilog-2001; synthesizable; self-contained (no includes).
// ============================================================================

`timescale 1ns/1ps

// ----------------------------------------------------------------------------
// junction_trit: 2-bit/trit polarity-junction cell.
//   t      : raw 2-bit trit {pull, push}
//   valid  : 1 iff t != 11 (a legal state)
//   bad    : 1 iff t == 11 (NEVER — both channels energized; the canary)
//   push   : 1 iff 01 (+1)
//   pull   : 1 iff 10 (-1)
//   null   : 1 iff 00 (0 — nothing energized)
//   active : 1 iff exactly one channel is energized (push | pull)
// ----------------------------------------------------------------------------
module junction_trit (valid, bad, push, pull, null, active, t);
  output wire       valid;
  output wire       bad;
  output wire       push;
  output wire       pull;
  output wire       null;
  output wire       active;
  input  wire [1:0] t;

  // 11 = both anti-polar rails on at once — the NEVER state.
  wire r_both = t[0] & t[1];

  assign bad    = r_both;
  assign valid  = ~bad;

  // Enforce the one-hot invariant.  The 11 state is normalized to "no valid
  // channel energized" (push = pull = active = 0) AND flagged on `bad`, so a
  // double-energized cell can never masquerade as a legal trit.
  assign push   = t[0] & ~t[1];     // 01
  assign pull   = t[1] & ~t[0];     // 10
  assign active = push | pull;      // exactly one channel on
  assign null   = valid & ~active;  // 00 only: 0 is "free" (no channel on)
endmodule

// ----------------------------------------------------------------------------
// tneg_junction: ternary negation as a WIRE SWAP, not a gate.
//
//   nt = {t[0], t[1]}   (push <-> pull exchanged; null stays fixed)
//
// This costs ZERO channel activations — no energy.  The junction cell's two
// anti-polar channels share a middle node; "negating" a trit only relabels
// which physical wire is the push line and which is the pull line.  No wire
// changes level, no transistor toggles, so the energized-channel count
// (active_count) is INVARIANT under negation.  (The null 00 is its own
// negation, and the NEVER 11 maps to 11 — still flagged, still bad.)
// ----------------------------------------------------------------------------
module tneg_junction (nt, t);
  output wire [1:0] nt;
  input  wire [1:0] t;

  assign nt = {t[0], t[1]};
endmodule

// ----------------------------------------------------------------------------
// active_count: number of ENERGIZED channels in a 12-trit (24-bit) word, 0..12.
//   A trit counts as active iff exactly one of its two rails is on (the ±1
//   states, 01 and 10).  00 (null) contributes 0 — that is the free-symbol
//   saving — and 11 (NEVER, both rails) contributes 0 but is flagged by the
//   canary (trit_link_canary in rtl/ternary_link.v, or junction_trit.bad),
//   never priced as a valid active channel.
// ----------------------------------------------------------------------------
module active_count (count, word);
  output reg  [3:0] count;
  input  wire [23:0] word;

  integer i;
  always @(*) begin
    count = 4'd0;
    for (i = 0; i < 12; i = i + 1)
      if (word[2*i] ^ word[2*i+1])      // exactly one rail energized
        count = count + 4'd1;
  end
endmodule
