// ============================================================================
// ternary_link_periph.v — the ternary transport link, memory-mapped for the SoC.
//
// The digital side of the transport win (FINAL_VERDICT ~2.7-6.3x): on the wire the
// NULL trit (00) costs ~0 on the wire — information by doing nothing.  This
// peripheral measures that, IN HARDWARE, on every 12-trit word the core puts on the
// link.  It composes rtl/ternary_link.v (the null counter + 11=NEVER canary) with a
// latched "last word" register and a fixed-point transport-energy accumulator.
//
//   BASE+0x00   write: transmit a 24-bit ternary word (latch + measure)
//               read : the last transmitted word
//   BASE+0x04   read : null-trit count (0..12)  — the "free symbols" on the wire
//   BASE+0x08   read : active-trit count (12 − nulls)  — the ±1 toggles that cost
//   BASE+0x0C   read : 11=NEVER canary (1 iff any trit is 2'b11)
//   BASE+0x10   read : transport energy in centi-pJ (see below)
//
// ENERGY (fixed-point, centi-pJ).  Per-trit constants from the fair-fight operating
// point (scripts/transport.py, circuit/ENERGY_RESULTS.md CORRECTION 1):
//   E(±1) = 1.20 pJ,  E(null) = 0.05 pJ
// so for a 12-trit word, E_word = active*120 + nulls*5  (centi-pJ).  A null-heavy word
// (more 00) costs less — exactly the conditional win the model reports; a 12-null word
// is 60 centi-pJ vs 1440 centi-pJ for a 12-active word.  The 11=NEVER canary flags a
// single-bit upset that lands a valid trit (01/10) in the forbidden 11 state.
//
// 2-bit/trit code: 01=+1, 00=0 (null), 10=-1, 11=NEVER.
//
// Verilog-2001; synthesizable; depends on rtl/ternary_link.v.
// ============================================================================

`timescale 1ns/1ps

module ternary_link_periph #(
  parameter [31:0] BASE = 32'h0000_3000
) (
  input  wire        clk,
  input  wire        resetn,
  input  wire        mem_valid,
  input  wire [31:0] mem_addr,
  input  wire [31:0] mem_wdata,
  input  wire [3:0]  mem_wstrb,
  output reg  [31:0] mem_rdata,
  output reg         mem_ready
);
  reg [23:0] word;   // last transmitted word

  // ---- the transport link datapath (from rtl/ternary_link.v) ------------------
  wire [3:0] nulls;
  trit_null_count u_nc (.count(nulls), .word(word));
  wire flag;
  trit_link_canary u_cc (.flag(flag), .word(word));

  wire [3:0]  active = 4'd12 - nulls;
  // fixed-point energy: 120*active + 5*nulls  (centi-pJ; max 1440 fits 12 bits)
  wire [11:0] energy = (12'd120 * {8'b0, active}) + (12'd5 * {8'b0, nulls});

  // ---- memory-mapped interface ------------------------------------------------
  wire        hit  = mem_valid && (mem_addr >= BASE) && (mem_addr < BASE + 32'h14);
  wire [31:0] off  = mem_addr - BASE;
  wire [4:0]  cidx = off[4:0];

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      word      <= 24'b0;
      mem_ready <= 1'b0;
      mem_rdata <= 32'd0;
    end else begin
      mem_ready <= hit;
      if (hit && (mem_wstrb != 4'd0)) begin
        if (cidx == 5'h00) word <= mem_wdata[23:0];   // transmit a word
      end
      if (hit && (mem_wstrb == 4'd0)) begin
        case (cidx)
          5'h00: mem_rdata <= {8'b0, word};
          5'h04: mem_rdata <= {28'b0, nulls};
          5'h08: mem_rdata <= {28'b0, active};
          5'h0C: mem_rdata <= {31'b0, flag};
          5'h10: mem_rdata <= {20'b0, energy};
          default: mem_rdata <= 32'd0;
        endcase
      end
    end
  end
endmodule
