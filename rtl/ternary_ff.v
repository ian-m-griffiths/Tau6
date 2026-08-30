// ============================================================================
// ternary_ff.v — the missing SEQUENTIAL cell: ternary D-latch and edge-triggered
// flip-flop storage, per-trit (1 trit = 2 bits) and word-level (12 trits = 24
// bits).  Purely additive: does NOT modify cpu.v or ternary_gates.v; this file
// is the storage cell to be wired into cpu.v in a later step.
//
// /// DESIGN REFERENCE — the ternary D-latch of arXiv:2211.12176v1,
// /// "Implementation and Applications of a Ternary Threshold Logic Gate"
// /// (eess.SP, Nov 2022), Appendix A.3: a ternary TRANSPARENT LATCH with a
// /// clock — level-sensitive storage of a 3-valued signal (transparent while
// /// the clock/enable is asserted, holding the last trit otherwise).  Adapted
// /// here to this project's one-hot-per-direction trit encoding {neg,pos}
// /// (2 wires per trit): 2'b01 = +1 (push), 2'b00 = 0 (null), 2'b10 = -1
// /// (pull), 2'b11 = never produced (see ternary_gates.v header and the
// /// Lean proof citations there).
// ///
// /// WHY THIS FILE EXISTS — cpu.v has NO ternary sequential cell: every
// /// flip-flop it contains (pc, ir, hlt, ovf, and the 8 x 24-bit regfile —
// /// 213 of them) is a plain BINARY FF holding trit-encoded bits.  This file
// /// adds the missing trit-level storage primitives so the register file and
// /// control state can be built from ternary cells:
// ///
// ///   tff_latch  — 1-trit transparent D-latch (enable `en`), reset to null
// ///   tff_edge   — 1-trit positive-edge-triggered D flip-flop, reset to null
// ///   tword_ff   — 12-trit (24-bit) positive-edge-triggered register,
// ///                the word element that replaces the binary regfile regs
// ///
// /// Both FFs reset to the null trit 2'b00 (all 12 trits null for the word
// /// version).  The module port lists are kept reset-pin-free (power-on null
// /// via `initial`), mirroring the task spec; a synchronous/async reset pin
// /// can be added when this is wired into cpu.v's rst_n domain.
// ============================================================================

`timescale 1ns/1ps

// ----------------------------------------------------------------------------
// tff_latch: 1-trit ternary TRANSPARENT D-latch (App A.3 level-sensitive cell).
//   en=1 -> q transparently follows d (every d change propagates immediately)
//   en=0 -> q holds the last trit (reg retains; no enable feedback path)
//   Power-on reset: q = 2'b00 (null trit — nothing energized).
// ----------------------------------------------------------------------------
module tff_latch (
  input       [1:0] d,
  input             en,
  output reg  [1:0] q
);
  initial q = 2'b00;                    // reset to null trit

  // Level-sensitive: blocking assign keeps the latch transparent while en=1;
  // with en=0 the block never assigns and q retains its value (classic
  // transparent-latch inference; the 2'b11 input state is never produced).
  always @(en or d)
    if (en) q = d;
endmodule

// ----------------------------------------------------------------------------
// tff_edge: 1-trit positive-edge-triggered ternary D flip-flop.
//   q <= d sampled on posedge clk (nonblocking); q holds between edges.
//   Power-on reset: q = 2'b00 (null trit).
// ----------------------------------------------------------------------------
module tff_edge (
  input             clk,
  input       [1:0] d,
  output reg  [1:0] q
);
  initial q = 2'b00;                    // reset to null trit

  always @(posedge clk)
    q <= d;                             // nonblocking: edge-sampled copy
endmodule

// ----------------------------------------------------------------------------
// tword_ff: 12-trit (24-bit) positive-edge-triggered register.
//   The vector width of tff_edge, one per cpu.v regfile element: bits [11:0]
//   = a-field (6 trits), bits [23:12] = b-field (6 trits), the Eisenstein
//   lattice-point word layout of ternary_gates.v / cpu.v.
//   Power-on reset: q = 24'b0 (all 12 trits null).
// ----------------------------------------------------------------------------
module tword_ff (
  input             clk,
  input      [23:0] d,
  output reg  [23:0] q
);
  initial q = 24'b0;                    // reset to all-null word

  always @(posedge clk)
    q <= d;
endmodule
