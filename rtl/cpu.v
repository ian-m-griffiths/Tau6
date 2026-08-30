// ============================================================================
// cpu.v — naive single-cycle balanced-ternary CPU (the FIRST Verilog CPU).
//
// Honest MVP: one instruction per clock, fetch -> decode -> execute all
// combinational within the cycle, register write at the rising edge.  No
// pipeline, no stalls, no forwarding — dependencies simply work because every
// instruction reads the register state from the previous cycle.
//
// ----------------------------------------------------------------------------
// WORD: 12 trits = 24 bits = lattice point a + b*w (Eisenstein integer Z[w])
//   bits [11:0]  = a, 6 trits, balanced signed in [-364, +364]
//   bits [23:12] = b, 6 trits, balanced signed in [-364, +364]
//   (ternary_gates.v header; TERNARY_PROCESSOR.md sec.2.2)
//
// ISA (16-bit instructions, binary host encoding — the trit data path is what
// this proves; the instruction words are plain binary):
//   {op[3:0], rd[2:0], ra[2:0], rb[2:0]}
//   LDI rd,#imm  -> {4'h4, rd[2:0], imm[8:0]}   imm = 9-bit two's complement
//
//   op   name    semantics
//   0    TADD    rd = ra + rb            (coefficient-wise balanced add)
//   1    TSUB    rd = ra - rb            (negate rb by digit-swap, then add —
//                                          negation is carry-free [DIRECT])
//   2    TROT    rd = w^k * ra, k = rb   (Z6 gauge change; Gauge.lean
//                                          omegaPow / units_eq_omega_pow)
//   3    TNORM   rd = N(a_ra, a_rb) = a^2 + ab + b^2 (Gauge.lean norm_eq_det)
//                -> scalar in the a-field, b-field cleared
//   4    LDI     rd = (imm, 0)           (9-bit two's complement -> balanced)
//   5    TMUL    rd = ra * rb            (Eisenstein lattice multiply, w^2=w-1:
//                (a+bw)(c+dw) = (ac-bd) + (ad+bc+bd)w via 3 products, tmul_eisen_trits;
//                low 6 trits of A -> a-field, low 6 trits of B -> b-field,
//                ovf = 1 when A or B is wider than 6 trits)
//
//   GA (geometric-algebra) ops — docs/GA_INSTRUCTIONS.md, cells in ga_ops.v.
//   z = ra = (a,b), w = rb = (c,d); conj(u,v) = (u+v, -v), omega_bar = 1-w.
//   6    TCONJ   rd = conj(ra)           (a+b, -b)  [Conjugate.lean]; single
//                operand — rb field is ignored.  a+b may overflow 6 trits.
//   7    TDOT    rd = dot(ra,rb)         scalar Re(z*conj w) = ac+ad+bd
//                -> a-field, b cleared  [DotWedge.lean].  (NOT symmetric:
//                dot_swap; the raw Re(z*conj w) is half-integral.)
//   8    TWEDGE  rd = wedge(ra,rb)       skew Im(z*conj w) = bc-ad
//                -> a-field, b cleared  [DotWedge.lean; wedge_antisymm].
//   9    TSYMDOT rd = symdot(ra,rb)      N(z+w)-N(z)-N(w) = 2ac+ad+bc+2bd
//                -> a-field, b cleared  [SymDot.lean; the TRUE symmetric
//                integer correlation — polarization of the norm].
//                (symdot = 2*dot + wedge, so dot/wedge/symdot share one
//                4-product cell ga_split_trits.)
//   F    HLT     stop the clock-free PC
//
// TROT k (Gauge.lean rep L47 / omegaPow L65-76), on (a,b) = (ra_a, ra_b):
//   k=0: ( a,      b   )     w^0 = 1
//   k=1: ( -b,   a+b  )     w^1 = w
//   k=2: ( -(a+b), a  )     w^2 = w-1
//   k=3: ( -a,    -b  )     w^3 = -1     (negation)
//   k=4: (  b,  -(a+b))     w^4 = -w
//   k=5: ( a+b,  -a  )     w^5 = -w^2
//   each is a negate and/or an add — no multiplies ("cheap gauge change").
//
// STATUS: `ovf` latches any coefficient overflow (carry out of a 6-trit field,
// or a TROT a+b overflow, or a TNORM/TMUL/TDOT/TWEDGE/TSYMDOT result wider than
// 6 trits) AND the 11=NEVER canary — tregfile_2r1w flags any forbidden 2'b11
// trit on the write or read paths (storage.md §6.1).  The test program never
// overflows; overflow is flagged, not trapped.
//
// STORAGE: the register file is now TERNARY — tregfile_2r1w (rtl/ternary_mem.v),
// a 2-read-port + 1-write-port 12-trit word array with the 11=NEVER canary,
// replacing the plain binary reg array.  cpu.v now requires rtl/ternary_mem.v
// and rtl/ternary_ff.v in its compile list (see yosys_report.sh / testbenches).
//
// TRIT ENCODING / Lean proof citations: see ternary_gates.v header
//   (TernaryCell.lean: encode_never_both, energy_le_one, null_is_free).
// ============================================================================

`timescale 1ns/1ps

`include "rtl/trit_functions.vh"

module cpu #(
  parameter NREGS        = 8,                // registers, each 12 trits (24 bits)
  parameter IM_DEPTH     = 16,               // instruction memory words
  parameter PROGRAM_FILE = "rtl/program.hex" // $readmemh image (GA tb overrides)
) (
  input  wire                clk,
  input  wire                rst_n,
  output reg  [3:0]          pc,
  output reg  [15:0]         ir,
  output wire [NREGS*24-1:0] regfile_flat,
  output reg                 hlt,
  output reg                 ovf
);

  `DEF_TERNARY_GATES

  // ---- storage ------------------------------------------------------------
  reg [15:0] imem    [0:IM_DEPTH-1];         // hardcoded program
  initial $readmemh(PROGRAM_FILE, imem);

  // ---- ternary register file (2R1W + 11=NEVER canary) — see ternary_mem.v ----
  // Replaces the plain binary reg array; each register is a 12-trit (24-bit)
  // word, 2 bits/trit (01=+1, 00=0, 10=-1, 11=NEVER — never produced).
  wire [23:0] rf_rd0, rf_rd1;
  wire        rf_wd_canary, rf_rd0_canary, rf_rd1_canary;

  // ---- combinational fetch (single-cycle: decode straight from imem[pc]) --
  wire [15:0] ifetch = imem[pc];
  wire [3:0]  iop    = ifetch[15:12];
  wire [2:0]  ird    = ifetch[11:9];
  wire [2:0]  ira    = ifetch[8:6];
  wire [2:0]  irb    = ifetch[5:3];
  wire [8:0]  iimm   = ifetch[8:0];

  // ---- operand fields (6-trit coefficients) -------------------------------
  wire [11:0] ra_a = rf_rd0[11:0];
  wire [11:0] ra_b = rf_rd0[23:12];
  wire [11:0] rb_a = rf_rd1[11:0];
  wire [11:0] rb_b = rf_rd1[23:12];

  // ---- coefficient adders (TADD/TSUB; op bit 0 selects subtract) ----------
  wire [11:0] add_a, add_b;
  wire [1:0]  cout_a, cout_b;
  tadd_trits #(.NTRITS(6)) u_addA (
    .sum(add_a), .cout(cout_a),
    .a(ra_a), .b(iop[0] ? fneg6(rb_a) : rb_a), .cin(2'b00));
  tadd_trits #(.NTRITS(6)) u_addB (
    .sum(add_b), .cout(cout_b),
    .a(ra_b), .b(iop[0] ? fneg6(rb_b) : rb_b), .cin(2'b00));

  // TROT helper: a+b of the SOURCE pair (needed for k = 1, 2, 5)
  wire [11:0] ab_sum;
  wire [1:0]  cout_ab;
  tadd_trits #(.NTRITS(6)) u_addAB (
    .sum(ab_sum), .cout(cout_ab), .a(ra_a), .b(ra_b), .cin(2'b00));

  // TNORM cell: N(a_ra, a_rb) = a^2 + ab + b^2 = (a+b)^2 - ab via 2 products
  // (tnorm_trits_opt from tmul_opt.v — drop-in for tnorm_trits, −9% area).
  wire [11:0] tnorm_n;
  wire        tnorm_ofit;
  tnorm_trits_opt #(.NTRITS(6)) u_tnorm (
    .n(tnorm_n), .ofit(tnorm_ofit), .a(ra_a), .b(rb_a));

  // TMUL cell: Eisenstein lattice-point multiply (a+bw)(c+dw) -> (A, B),
  //   w^2 = w-1:  A = ac - bd (12 trits),  B = (a+b)(c+d) - ac (13 trits).
  //   3 scalar products via Karatsuba (tmul_eisen_trits).  The 12-trit word
  //   holds only 6+6 trits, so the low 6 trits of each coefficient are stored
  //   and `tmul_ofit` flags any result wider than 6 trits (same fit-check
  //   convention as TNORM).
  wire [23:0] tmul_A;      // 12 trits
  wire [25:0] tmul_B;      // 13 trits
  wire        tmul_ofit = (|tmul_A[23:12]) | (|tmul_B[25:12]);
  tmul_eisen_trits #(.NTRITS(6)) u_tmul (
    .A_out(tmul_A), .B_out(tmul_B),
    .a(ra_a), .b(ra_b), .c(rb_a), .d(rb_b));

  // ---- GA cells ------------------------------------------------------------
  // TCONJ: conj(ra) = (ra_a + ra_b, -ra_b).  Single operand (rb ignored).
  wire [11:0] conj_a, conj_b;
  wire        conj_ofit;
  tconj_trits #(.NTRITS(6)) u_tconj (
    .a_out(conj_a), .b_out(conj_b), .ofit(conj_ofit),
    .a(ra_a), .b(ra_b));

  // TDOT / TWEDGE / TSYMDOT: the scalar/bivector split of z*conj w, computed
  // full-width (14 trits) from 4 shared products; keep low 6 trits + fit flag.
  wire [27:0] ga_dot, ga_wedge, ga_symdot;   // 14 trits each
  ga_split_trits #(.NTRITS(6)) u_ga (
    .dot(ga_dot), .wedge(ga_wedge), .symdot(ga_symdot),
    .a(ra_a), .b(ra_b), .c(rb_a), .d(rb_b));
  wire dot_ofit    = |ga_dot[27:12];     // any trit above position 5 set
  wire wedge_ofit  = |ga_wedge[27:12];
  wire symdot_ofit = |ga_symdot[27:12];

  // ---- ALU (combinational) ------------------------------------------------
  reg [23:0] wdata;
  reg        wovf;
  always @(*) begin
    wdata = 24'b0;
    wovf  = 1'b0;
    case (iop)
      4'h0, 4'h1: begin                       // TADD / TSUB
        wdata = {add_b, add_a};
        wovf  = |cout_a | |cout_b;
      end
      4'h2: begin                             // TROT: rd = w^k * ra
        case (irb[2:0])
          3'd0: wdata = {ra_b,             ra_a};        // w^0 = 1
          3'd1: wdata = {ab_sum,           fneg6(ra_b)}; // w^1: (-b, a+b)
          3'd2: wdata = {ra_a,             fneg6(ab_sum)};// w^2: (-(a+b), a)
          3'd3: wdata = {fneg6(ra_b),      fneg6(ra_a)}; // w^3: (-a, -b) = -1
          3'd4: wdata = {fneg6(ab_sum),    ra_b};        // w^4: (b, -(a+b))
          3'd5: wdata = {fneg6(ra_a),      ab_sum};      // w^5: (a+b, -a)
          default: wdata = 24'b0;
        endcase
        wovf = |cout_ab;                     // a+b may overflow 6 trits
      end
      4'h3: begin                             // TNORM: N -> a-field
        wdata = {12'b0, tnorm_n};
        wovf  = tnorm_ofit;
      end
      4'h4: begin                             // LDI: binary -> balanced
        wdata = {12'b0, s2t6(iimm)};
        wovf  = 1'b0;                        // [-128,127] always fits 6 trits
      end
      4'h5: begin                             // TMUL: Eisenstein multiply
        wdata = {tmul_B[11:0], tmul_A[11:0]};
        wovf  = tmul_ofit;
      end
      4'h6: begin                             // TCONJ: conj(ra)
        wdata = {conj_b, conj_a};
        wovf  = conj_ofit;
      end
      4'h7: begin                             // TDOT: Re(z * conj w) -> a-field
        wdata = {12'b0, ga_dot[11:0]};
        wovf  = dot_ofit;
      end
      4'h8: begin                             // TWEDGE: Im(z * conj w) -> a-field
        wdata = {12'b0, ga_wedge[11:0]};
        wovf  = wedge_ofit;
      end
      4'h9: begin                             // TSYMDOT: symdot -> a-field
        wdata = {12'b0, ga_symdot[11:0]};
        wovf  = symdot_ofit;
      end
      default: begin                          // HLT / unused opcodes: no write
        wdata = 24'b0;
        wovf  = 1'b0;
      end
    endcase
  end

  // ---- register write / PC (single-cycle) ---------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc  <= 4'h0;
      ir  <= 16'h0000;
      hlt <= 1'b0;
      ovf <= 1'b0;
    end else if (!hlt) begin
      ir  <= ifetch;
      ovf <= wovf | rf_rd0_canary | rf_rd1_canary | rf_wd_canary;
      if (iop == 4'hF) begin                 // HLT: freeze PC, no write
        hlt <= 1'b1;
      end else begin
        pc <= pc + 4'h1;                     // regfile write happens in u_regfile
      end
    end
  end

  // ---- ternary register file instantiation ----------------------------------
  // Write every active non-HLT cycle (identical to the old `regfile[ird] <=
  // wdata`); reads ra/irb are combinational.  regfile_flat comes from q_flat.
  tregfile_2r1w #(.DEPTH(NREGS)) u_regfile (
    .clk(clk), .rst_n(rst_n),
    .we(!hlt && (iop != 4'hF)),
    .wa(ird), .ra0(ira), .ra1(irb),
    .wd(wdata),
    .rd0(rf_rd0), .rd1(rf_rd1),
    .rd0_canary(rf_rd0_canary), .rd1_canary(rf_rd1_canary), .wd_canary(rf_wd_canary),
    .q_flat(regfile_flat)
  );

  // ---- local helpers -------------------------------------------------------
  // fneg6: negate a 6-trit field (digit-wise wire swap, carry-free)
  function [11:0] fneg6;
    input [11:0] w;
    integer i;
    begin
      for (i = 0; i < 6; i = i + 1)
        fneg6[i*2 +: 2] = tneg(w[i*2 +: 2]);
    end
  endfunction

  // s2t6: 9-bit two's complement -> 6-trit balanced signed integer.
  // Division-free (the naive r/3 + r%3 loop synthesises 32-bit shift-subtract
  // dividers — absurd area).  MSB-first balanced digit extraction: digit b_i
  // (weight 3^i) is +1 iff the residual exceeds half the sum of all LOWER
  // weights, (3^i-1)/2; -1 below its negation; else 0.  Then subtract b_i*3^i
  // (a constant add/sub — no multiplication).  The residual stays bounded at
  // every step (<= (3^i-1)/2 before digit i), so all arithmetic is tiny.
  function [11:0] s2t6;
    input [8:0] v;
    integer r;
    begin
      r = $signed(v);
      s2t6 = 12'b0;
      // digit 5: weight 243, threshold (3^5-1)/2 = 121
      if (r > 121)       begin s2t6[10 +: 2] = 2'b01; r = r - 243; end
      else if (r < -121) begin s2t6[10 +: 2] = 2'b10; r = r + 243; end
      // digit 4: weight 81, threshold 40
      if (r > 40)        begin s2t6[8 +: 2] = 2'b01;  r = r - 81;  end
      else if (r < -40)  begin s2t6[8 +: 2] = 2'b10;  r = r + 81;  end
      // digit 3: weight 27, threshold 13
      if (r > 13)        begin s2t6[6 +: 2] = 2'b01;  r = r - 27;  end
      else if (r < -13)  begin s2t6[6 +: 2] = 2'b10;  r = r + 27;  end
      // digit 2: weight 9, threshold 4
      if (r > 4)         begin s2t6[4 +: 2] = 2'b01;  r = r - 9;   end
      else if (r < -4)   begin s2t6[4 +: 2] = 2'b10;  r = r + 9;   end
      // digit 1: weight 3, threshold 1
      if (r > 1)         begin s2t6[2 +: 2] = 2'b01;  r = r - 3;   end
      else if (r < -1)   begin s2t6[2 +: 2] = 2'b10;  r = r + 3;   end
      // digit 0: weight 1; the residual is now in {-1, 0, +1}
      if (r == 1)        s2t6[0 +: 2] = 2'b01;
      else if (r == -1)  s2t6[0 +: 2] = 2'b10;
    end
  endfunction

endmodule
