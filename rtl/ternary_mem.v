// ============================================================================
// ternary_mem.v — ternary MEMORY: register file + the 11=NEVER canary + trit
// packing.  Purely additive: does NOT modify ternary_ff.v / cpu.v; this file
// reuses the sequential cells from ternary_ff.v and adds the storage-side
// blocks the memory survey (docs/compute/storage.md) identifies as the cheapest
// wins for a 2-bit-per-trit architecture.
//
// /// DESIGN REFERENCE — docs/compute/storage.md (the memory-cell survey):
// ///   §0   the 2-bit-per-trit encoding is "ours (B)": 2'b01=+1, 2'b00=0,
// ///        2'b10=-1, 2'b11=NEVER — a standard binary cell, NOT a 3-level
// ///        cell; the 26% density overhead it pays is the whole problem.
// ///   §6.1 the 11=NEVER canary [OURS, exact]: in a 2-bit code with 3 valid +
// ///        1 forbidden word, a single-bit upset lands in the forbidden word
// ///        with probability 1/3, and 1/3 is the maximum any 3-valid-1-invalid
// ///        2-bit code can achieve.  `01->11` and `10->11` are detectable;
// ///        `01->00/00->01/00->10/10->00` are silent value corruption.  Binary
// ///        gives 0% detection without a parity bit.  So 11=NEVER is a free,
// ///        asymmetric SEU canary — a detector that flags ANY 2'b11 trit on a
// ///        read or a write.
// ///   §6.3 trit-packing [DIRECT combinatorics, OURS framing]: `11` is the
// ///        headroom that lets trits pack tighter than 2 bits/trit:
// ///        `3^4=81  <= 2^7=128` => 4 trits in 7 bits (12.5% saving over 8),
// ///        `3^5=243 <= 2^8=256` => 5 trits in 8 bits (20% saving over 10).
// ///        As the block grows the packing approaches log2(3) ~= 1.585 bits/
// ///        trit — recovering most of the 26% overhead of encoding (B) in bulk.
// ///   §7.3 the cheapest next win is trit-packing, "not a new cell".
// ///   The counting bounds are proved in proofs/lean-src/hexagon/Hexagon/
// ///   TritPacking.lean (four_trits_fit_seven_bits, five_trits_fit_eight_bits);
// ///   the 11=NEVER state is proved unreachable-by-encode in TernaryCell.lean
// ///   (encode_never_both).  THIS file supplies the concrete bijection the
// ///   counting bound leaves open: the base-3 positional code below.
// ///
// /// PACKING BIJECTION (the one detail the survey does not fix — OURS):
// ///   digit_i = trit_i + 1  in {0,1,2}  ( -1->0, 0->1, +1->2 )
// ///   packed  = sum_i digit_i * 3^i    (trit 0 = least significant, weight 1)
// ///   4 trits: packed = d0 + 3*d1 + 9*d2 + 27*d3        (0..80,  7 bits)
// ///   5 trits: packed = d0 + 3*d1 + 9*d2 + 27*d3 + 81*d4 (0..242, 8 bits)
// ///   decode is the inverse: successive /3, %3 to recover each digit, then
// ///   digit -> trit.  Every packed value 0..3^n-1 is a valid n-trit word and
// ///   no 2'b11 is ever produced by encode (the canary's job is the write/read
// ///   DATA path, which a packer must never feed).
// ============================================================================

`timescale 1ns/1ps

// ----------------------------------------------------------------------------
// trit_canary: the 11=NEVER single-bit-upset detector for ONE trit.
//   flag = 1 iff the 2-bit code is 2'b11 (both rails energized) — the state
//   encode never produces (TernaryCell.lean: encode_never_both).  Detects
//   01->11 and 10->11 flips; the null 00 has zero detection (both its flips
//   are valid codes) — the documented asymmetry of storage.md §6.1.
// ----------------------------------------------------------------------------
module trit_canary (
  input  wire [1:0] t,
  output wire       flag
);
  assign flag = t[1] & t[0];          // 11 = pull & push both asserted
endmodule

// ----------------------------------------------------------------------------
// tword_canary: word-wide 11=NEVER detector.  `bad[i]` marks trit i = 2'b11;
//   `flag` = |bad (any trit corrupted).  Combinational, placed on both the
//   read-data and write-data paths of the register file below.
// ----------------------------------------------------------------------------
module tword_canary #(
  parameter NTRITS = 12
) (
  input  wire [2*NTRITS-1:0] word,    // NTRITS trits, 2 bits each
  output reg  [NTRITS-1:0]   bad,     // per-trit 11 detect
  output wire                 flag    // any trit is 11
);
  integer i;
  always @* begin
    bad = {NTRITS{1'b0}};
    for (i = 0; i < NTRITS; i = i + 1)
      bad[i] = word[2*i+1] & word[2*i];
  end
  assign flag = |bad;
endmodule

// ----------------------------------------------------------------------------
// tregfile: ternary register file, DEPTH x (12 trits = 24 bits), built from an
// array of the EXISTING tword_ff word flip-flop (rtl/ternary_ff.v) — the cell
// ternary_ff.v was written to "replace the binary regfile regs" of cpu.v (its
// 8 x 24-bit regfile is exactly DEPTH=8 here).
//
//   Write: posedge-sampled.  Each tword_ff has no enable pin, so a feedback
//   mux gives it one: d = (we && wa==ROW) ? wd : own_q  (hold when not
//   selected).  Read: asynchronous (combinational mux off q_arr[ra]).
//   Canary: wd_canary flags a 2'b11 in the WRITE data; rd_canary flags a
//   2'b11 in the READ data — the two 11=NEVER detection points of §6.1.
//
//   Power-on: all registers null (tword_ff `initial q = 0`).  DEPTH must be a
//   power of two so $clog2 covers every address (8 by default, as in cpu.v).
// ----------------------------------------------------------------------------
module tregfile #(
  parameter DEPTH = 8                 // number of 12-trit registers (power of 2)
) (
  input  wire                    clk,
  input  wire                    we,         // write enable (posedge-sampled)
  input  wire [$clog2(DEPTH)-1:0] wa,       // write address
  input  wire [$clog2(DEPTH)-1:0] ra,       // read address (async)
  input  wire [23:0]             wd,        // write data (12 trits)
  output wire [23:0]             rd,        // read data
  output wire                    rd_canary, // 11 detected in read data
  output wire                    wd_canary  // 11 detected in write data
);
  localparam AW = $clog2(DEPTH);

  // the FF array: one existing tword_ff (12 trits = 24 bits) per register
  wire [23:0] q_arr [0:DEPTH-1];

  genvar r;
  generate
    for (r = 0; r < DEPTH; r = r + 1) begin : regs
      localparam [AW-1:0] ROW = r;
      // write-select feedback mux: load wd when this row is written, else hold
      wire [23:0] d_mux = (we && (wa == ROW)) ? wd : q_arr[r];
      tword_ff u_ff (.clk(clk), .d(d_mux), .q(q_arr[r]));
    end
  endgenerate

  assign rd = q_arr[ra];                // asynchronous read (combinational mux)

  // 11=NEVER canaries on the write path (wd) and read path (rd)
  tword_canary #(.NTRITS(12)) u_wd_can (.word(wd), .flag(wd_canary));
  tword_canary #(.NTRITS(12)) u_rd_can (.word(rd), .flag(rd_canary));
endmodule

// ----------------------------------------------------------------------------
// tregfile_2r1w: ternary register file, TWO read ports + ONE write port, with
// the 11=NEVER canary on all three ports.  This is the drop-in that wires the
// ternary memory into cpu.v (whose ALU reads ra and rb simultaneously every
// cycle, which the 1R1W `tregfile` above cannot do).
//
//   Storage: DEPTH x 24-bit (12-trit) words; synchronous write, async read.
//   Reset:   rst_n (async, active-low) clears every word to the null trit —
//            the reset pin ternary_ff.v deliberately left off, added here so
//            the regfile can live in cpu.v's rst_n domain (see ternary_ff.v
//            header "a reset pin can be added when this is wired into cpu.v").
//   Canary:  wd_canary / rd0_canary / rd1_canary fire on any 2'b11 trit on the
//            write / read-0 / read-1 paths respectively (storage.md §6.1).
//   q_flat:  flat view (DEPTH*24 bits) for testbenches == cpu.v regfile_flat.
//
//   Honest note: the storage cells are standard 2-bit registers, not 3-level
//   cells — the 2-bit-per-trit encoding IS a binary cell (storage.md §0).
//   The ternary value lives in the encoding + the canary, not the physical FF.
// ----------------------------------------------------------------------------
module tregfile_2r1w #(
  parameter DEPTH = 8
) (
  input  wire                     clk,
  input  wire                     rst_n,
  input  wire                     we,
  input  wire [$clog2(DEPTH)-1:0] wa,
  input  wire [$clog2(DEPTH)-1:0] ra0,
  input  wire [$clog2(DEPTH)-1:0] ra1,
  input  wire [23:0]              wd,
  output wire [23:0]              rd0,
  output wire [23:0]              rd1,
  output wire                     rd0_canary,
  output wire                     rd1_canary,
  output wire                     wd_canary,
  output wire [DEPTH*24-1:0]      q_flat
);
  localparam AW = $clog2(DEPTH);

  reg [23:0] q_arr [0:DEPTH-1];
  integer r;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (r = 0; r < DEPTH; r = r + 1)
        q_arr[r] <= 24'b0;
    end else if (we) begin
      q_arr[wa] <= wd;
    end
  end

  assign rd0 = q_arr[ra0];
  assign rd1 = q_arr[ra1];

  tword_canary #(.NTRITS(12)) u_rd0 (.word(rd0), .flag(rd0_canary));
  tword_canary #(.NTRITS(12)) u_rd1 (.word(rd1), .flag(rd1_canary));
  tword_canary #(.NTRITS(12)) u_wd  (.word(wd),  .flag(wd_canary));

  genvar g;
  generate
    for (g = 0; g < DEPTH; g = g + 1) begin : flat
      assign q_flat[g*24 +: 24] = q_arr[g];
    end
  endgenerate
endmodule

// ----------------------------------------------------------------------------
// pack4_trits: 4 trits (8 bits) -> 7 bits.  3^4 = 81 states in 2^7 = 128.
//   Base-3 positional: digit_i = trit_i+1 in {0,1,2}; packed = sum digit*3^i.
//   Output range 0..80 (never 81..127).  A 2'b11 input trit is a don't-care
//   (it should have been caught by the canary; here it decodes as digit 1).
// ----------------------------------------------------------------------------
module pack4_trits (
  input  wire [7:0] trits,             // 4 trits, trit i = bits [2i+1:2i]
  output reg  [6:0] packed
);
  function integer trit_to_digit;
    input [1:0] t;
    begin
      // push (t[0]) -> +1 -> digit 2 ; pull (t[1]) -> -1 -> digit 0 ;
      // neither -> 0 -> digit 1
      trit_to_digit = t[0] ? 2 : (t[1] ? 0 : 1);
    end
  endfunction

  always @* begin
    packed =        trit_to_digit(trits[1:0])
           +  3   * trit_to_digit(trits[3:2])
           +  9   * trit_to_digit(trits[5:4])
           + 27   * trit_to_digit(trits[7:6]);
  end
endmodule

// ----------------------------------------------------------------------------
// unpack4_trits: 7 bits -> 4 trits (8 bits).  Inverse of pack4_trits: recover
//   each base-3 digit by successive /3, %3.  Inputs 81..127 are out of range
//   (no valid 4-trit word); the result there is undefined.
// ----------------------------------------------------------------------------
module unpack4_trits (
  input  wire [6:0] packed,
  output reg  [7:0] trits
);
  function [1:0] digit_to_trit;
    input integer d;
    begin
      case (d)
        0: digit_to_trit = 2'b10;      // -1
        1: digit_to_trit = 2'b00;      //  0
        2: digit_to_trit = 2'b01;      // +1
        default: digit_to_trit = 2'b00; // unreachable for d in 0..2
      endcase
    end
  endfunction

  reg [1:0] t0, t1, t2, t3;
  integer p;
  always @* begin
    p  = packed;
    t0 = digit_to_trit(p % 3); p = p / 3;
    t1 = digit_to_trit(p % 3); p = p / 3;
    t2 = digit_to_trit(p % 3); p = p / 3;
    t3 = digit_to_trit(p % 3);
    trits = {t3, t2, t1, t0};
  end
endmodule

// ----------------------------------------------------------------------------
// pack5_trits: 5 trits (10 bits) -> 8 bits.  3^5 = 243 states in 2^8 = 256.
//   Same base-3 positional code with an 81-weight top digit; range 0..242.
// ----------------------------------------------------------------------------
module pack5_trits (
  input  wire [9:0] trits,             // 5 trits, trit i = bits [2i+1:2i]
  output reg  [7:0] packed
);
  function integer trit_to_digit;
    input [1:0] t;
    begin
      trit_to_digit = t[0] ? 2 : (t[1] ? 0 : 1);
    end
  endfunction

  always @* begin
    packed =        trit_to_digit(trits[1:0])
           +  3   * trit_to_digit(trits[3:2])
           +  9   * trit_to_digit(trits[5:4])
           + 27   * trit_to_digit(trits[7:6])
           + 81   * trit_to_digit(trits[9:8]);
  end
endmodule

// ----------------------------------------------------------------------------
// unpack5_trits: 8 bits -> 5 trits (10 bits).  Inverse of pack5_trits; inputs
//   243..255 are out of range and undefined.
// ----------------------------------------------------------------------------
module unpack5_trits (
  input  wire [7:0] packed,
  output reg  [9:0] trits
);
  function [1:0] digit_to_trit;
    input integer d;
    begin
      case (d)
        0: digit_to_trit = 2'b10;
        1: digit_to_trit = 2'b00;
        2: digit_to_trit = 2'b01;
        default: digit_to_trit = 2'b00;
      endcase
    end
  endfunction

  reg [1:0] t0, t1, t2, t3, t4;
  integer p;
  always @* begin
    p  = packed;
    t0 = digit_to_trit(p % 3); p = p / 3;
    t1 = digit_to_trit(p % 3); p = p / 3;
    t2 = digit_to_trit(p % 3); p = p / 3;
    t3 = digit_to_trit(p % 3); p = p / 3;
    t4 = digit_to_trit(p % 3);
    trits = {t4, t3, t2, t1, t0};
  end
endmodule
