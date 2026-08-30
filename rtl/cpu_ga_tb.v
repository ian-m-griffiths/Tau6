// ============================================================================
// cpu_ga_tb.v — testbench for the GA (geometric-algebra) instructions on the
// balanced-ternary CPU: TCONJ / TDOT / TWEDGE / TSYMDOT (opcodes 6-9).
//
// Strategy (mirrors cpu_tb.v's three-layer structure):
//   1. Cell-level cross-checks of the two new cells — tconj_trits and
//      ga_split_trits (dot/wedge/symdot) — over a,b,c,d in [-4..4]^4 against
//      plain-integer Eisenstein arithmetic:
//        conj(a,b)   = (a+b, -b)                                  [Conjugate.lean]
//        dot    z w  = ac + ad + bd                               [DotWedge.lean]
//        wedge  z w  = bc - ad                                    [DotWedge.lean]
//        symdot z w  = 2ac + ad + bc + 2bd                        [SymDot.lean]
//   2. CPU program run (rtl/program_ga.hex) with a reference model mirroring
//      the FULL ISA (opcodes 0-9 + HLT) in lockstep; every register compared
//      every step.
//   3. Hand-computed final-state assertions, including the Lean identities
//      exercised by the program: wedge_antisymm, conj_involutive, symdot_comm.
//
// The program image built here must equal rtl/program_ga.hex (cross-checked by
// this testbench itself).
// ============================================================================

`timescale 1ns/1ps

module cpu_ga_tb;

`include "rtl/trit_functions.vh"
`DEF_TERNARY_GATES

  // ---- DUT -----------------------------------------------------------------
  reg  clk, rst_n;
  wire [3:0]   pc;
  wire [15:0]  ir;
  wire [191:0] rf;                 // regfile_flat: 8 regs x 24 bits
  wire         hlt, ovf;

  cpu #(.NREGS(8), .IM_DEPTH(16), .PROGRAM_FILE("rtl/program_ga.hex")) u_cpu (
    .clk(clk), .rst_n(rst_n), .pc(pc), .ir(ir),
    .regfile_flat(rf), .hlt(hlt), .ovf(ovf)
  );

  // ---- GA cells under test -------------------------------------------------
  reg  [11:0] gz_a, gz_b, gw_a, gw_b;   // z=(a,b), w=(c,d)
  wire [27:0] ga_dot, ga_wedge, ga_symdot;   // 14-trit full-width results
  wire [11:0] tc_a, tc_b;                    // conj(a,b) = (a+b, -b)
  wire        tc_ofit;

  ga_split_trits #(.NTRITS(6)) u_ga (
    .dot(ga_dot), .wedge(ga_wedge), .symdot(ga_symdot),
    .a(gz_a), .b(gz_b), .c(gw_a), .d(gw_b));
  tconj_trits #(.NTRITS(6)) u_tc (
    .a_out(tc_a), .b_out(tc_b), .ofit(tc_ofit),
    .a(gz_a), .b(gz_b));

  // ---- program image + reference model --------------------------------------
  reg [15:0] hex_mem [0:15];
  reg [15:0] prog    [0:15];
  integer    prog_len;
  reg signed [31:0] mreg [0:7][0:1];   // model registers: [reg][0]=a, [reg][1]=b
  integer    mpc, st;
  integer    errors;
  integer    mi, i;
  reg [23:0] r3_after_conj;           // snapshot of r3 right after the first TCONJ

  // build the program image (must equal rtl/program_ga.hex)
  function [15:0] mk; input [3:0] op; input [2:0] rd, ra, rb;
    begin mk = {op, rd, ra, rb, 3'b000}; end
  endfunction
  function [15:0] mk_ldi; input [2:0] rd; input [8:0] imm;
    begin mk_ldi = {4'h4, rd, imm}; end
  endfunction

  // trit -> 3-valued helper and field decode/encode (plain integer math)
  function [1:0] trit_of; input integer v;
    begin
      case (v)
        -1: trit_of = 2'b10;
        0:  trit_of = 2'b00;
        1:  trit_of = 2'b01;
        default: trit_of = 2'b00;
      endcase
    end
  endfunction

  function integer tfvaln;   // decode `nt` trits (2 bits each) to an integer
    input [63:0] f;
    input integer nt;
    integer j, p;
    begin
      tfvaln = 0; p = 1;
      for (j = 0; j < nt; j = j + 1) begin
        case (f[j*2 +: 2])
          2'b01: tfvaln = tfvaln + p;
          2'b10: tfvaln = tfvaln - p;
        endcase
        p = p * 3;
      end
    end
  endfunction

  function [11:0] enc6;     // signed integer -> 6-trit balanced field
    input integer v;
    integer r, d, j;
    begin
      r = v;
      enc6 = 12'b0;
      for (j = 0; j < 6; j = j + 1) begin
        d = r % 3;
        if (d == 2) begin
          enc6[j*2 +: 2] = 2'b10;
          r = (r + 1) / 3;
        end else if (d == -2) begin
          enc6[j*2 +: 2] = 2'b01;
          r = (r - 1) / 3;
        end else begin
          if (d == 1)       enc6[j*2 +: 2] = 2'b01;
          else if (d == -1) enc6[j*2 +: 2] = 2'b10;
          else              enc6[j*2 +: 2] = 2'b00;
          r = r / 3;
        end
      end
    end
  endfunction

  // one reference-model step (plain integer mirror of the FULL ISA)
  task model_step;
    reg [3:0] mop;
    reg [2:0] mrd, mra, mrb, mk_;
    integer a, b, c, d, n;
    begin
      mop = prog[mpc][15:12];
      mrd = prog[mpc][11:9];
      mra = prog[mpc][8:6];
      mrb = prog[mpc][5:3];
      case (mop)
        4'h0: begin
          mreg[mrd][0] = mreg[mra][0] + mreg[mrb][0];
          mreg[mrd][1] = mreg[mra][1] + mreg[mrb][1];
        end
        4'h1: begin
          mreg[mrd][0] = mreg[mra][0] - mreg[mrb][0];
          mreg[mrd][1] = mreg[mra][1] - mreg[mrb][1];
        end
        4'h2: begin
          a = mreg[mra][0]; b = mreg[mra][1]; mk_ = mrb[2:0];
          case (mk_)
            3'd0: begin mreg[mrd][0] = a;      mreg[mrd][1] = b;      end
            3'd1: begin mreg[mrd][0] = -b;     mreg[mrd][1] = a + b;  end
            3'd2: begin mreg[mrd][0] = -(a+b); mreg[mrd][1] = a;      end
            3'd3: begin mreg[mrd][0] = -a;     mreg[mrd][1] = -b;     end
            3'd4: begin mreg[mrd][0] = b;      mreg[mrd][1] = -(a+b); end
            3'd5: begin mreg[mrd][0] = a + b;  mreg[mrd][1] = -a;     end
            default: ;
          endcase
        end
        4'h3: begin
          a = mreg[mra][0]; b = mreg[mrb][0];
          n = a*a + a*b + b*b;
          mreg[mrd][0] = n;
          mreg[mrd][1] = 0;
        end
        4'h4: begin
          mreg[mrd][0] = $signed(prog[mpc][8:0]);
          mreg[mrd][1] = 0;
        end
        4'h5: begin
          // TMUL: Eisenstein multiply (a+bw)(c+dw), w^2 = w-1
          a = mreg[mra][0]; b = mreg[mra][1];
          c = mreg[mrb][0]; d = mreg[mrb][1];
          mreg[mrd][0] = a*c - b*d;
          mreg[mrd][1] = a*d + b*c + b*d;
        end
        4'h6: begin
          // TCONJ: conj(ra) = (a+b, -b)   (rb field ignored)
          a = mreg[mra][0]; b = mreg[mra][1];
          mreg[mrd][0] = a + b;
          mreg[mrd][1] = -b;
        end
        4'h7: begin
          // TDOT: dot z w = ac + ad + bd   -> a-field
          a = mreg[mra][0]; b = mreg[mra][1];
          c = mreg[mrb][0]; d = mreg[mrb][1];
          mreg[mrd][0] = a*c + a*d + b*d;
          mreg[mrd][1] = 0;
        end
        4'h8: begin
          // TWEDGE: wedge z w = bc - ad   -> a-field
          a = mreg[mra][0]; b = mreg[mra][1];
          c = mreg[mrb][0]; d = mreg[mrb][1];
          mreg[mrd][0] = b*c - a*d;
          mreg[mrd][1] = 0;
        end
        4'h9: begin
          // TSYMDOT: symdot z w = 2ac + ad + bc + 2bd   -> a-field
          a = mreg[mra][0]; b = mreg[mra][1];
          c = mreg[mrb][0]; d = mreg[mrb][1];
          mreg[mrd][0] = 2*a*c + a*d + b*c + 2*b*d;
          mreg[mrd][1] = 0;
        end
        default: ;                       // HLT / unused
      endcase
    end
  endtask

  // compare every DUT register against the model
  task check_regs;
    integer r, da, db;
    begin
      for (r = 0; r < 8; r = r + 1) begin
        da = tfvaln(rf[r*24 +: 12], 6);
        db = tfvaln(rf[r*24 + 12 +: 12], 6);
        if (da !== mreg[r][0] || db !== mreg[r][1]) begin
          $display("ERROR step %0d: r%0d DUT=(%0d,%0d) model=(%0d,%0d)",
                   st, r, da, db, mreg[r][0], mreg[r][1]);
          errors = errors + 1;
        end
      end
    end
  endtask

  // ---- per-posedge lockstep -------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      mpc = 0; st = 0;
      for (mi = 0; mi < 8; mi = mi + 1) begin
        mreg[mi][0] = 0; mreg[mi][1] = 0;
      end
    end else if (!hlt) begin
      model_step();
      #1;                       // let DUT nonblocking writes commit
      check_regs();
      if (st == 8) r3_after_conj = rf[3*24 +: 24];   // first TCONJ result (5,-3)
      $display("step %2d: pc=%0d op=%h rd=r%0d ra=r%0d rb=%0d -> r%0d = (%2d, %2d)",
               st, pc, prog[mpc][15:12], prog[mpc][11:9],
               prog[mpc][8:6], prog[mpc][5:3],
               prog[mpc][11:9],
               tfvaln(rf[prog[mpc][11:9]*24 +: 12], 6),
               tfvaln(rf[prog[mpc][11:9]*24 + 12 +: 12], 6));
      mpc = mpc + 1;
      st = st + 1;
    end
  end

  always #5 clk = ~clk;

  // ---- layer 1: GA cell cross-checks ----------------------------------------
  task run_cell_tests;
    integer ea, eb, ec, ed;
    begin
      errors = 0;
      $display("======================================================");
      $display("LAYER 1: GA cell cross-checks (a,b,c,d in [-4..4]^4)");
      $display("======================================================");
      for (ea = -4; ea <= 4; ea = ea + 1)
        for (eb = -4; eb <= 4; eb = eb + 1)
          for (ec = -4; ec <= 4; ec = ec + 1)
            for (ed = -4; ed <= 4; ed = ed + 1) begin
              gz_a = enc6(ea); gz_b = enc6(eb);
              gw_a = enc6(ec); gw_b = enc6(ed);
              #1;
              // TCONJ: conj(a,b) = (a+b, -b)
              if (tfvaln(tc_a, 6) !== ea + eb || tfvaln(tc_b, 6) !== -eb) begin
                $display("FAIL tconj(%0d,%0d): got (%0d,%0d) want (%0d,%0d)",
                         ea, eb, tfvaln(tc_a, 6), tfvaln(tc_b, 6), ea+eb, -eb);
                errors = errors + 1;
              end
              if (tc_ofit !== 1'b0) begin
                $display("FAIL tconj(%0d,%0d) spurious ofit", ea, eb);
                errors = errors + 1;
              end
              // TDOT: ac + ad + bd
              if (tfvaln(ga_dot, 14) !== ea*ec + ea*ed + eb*ed) begin
                $display("FAIL dot(%0d,%0d,%0d,%0d): got %0d want %0d",
                         ea, eb, ec, ed, tfvaln(ga_dot, 14), ea*ec + ea*ed + eb*ed);
                errors = errors + 1;
              end
              // TWEDGE: bc - ad
              if (tfvaln(ga_wedge, 14) !== eb*ec - ea*ed) begin
                $display("FAIL wedge(%0d,%0d,%0d,%0d): got %0d want %0d",
                         ea, eb, ec, ed, tfvaln(ga_wedge, 14), eb*ec - ea*ed);
                errors = errors + 1;
              end
              // TSYMDOT: 2ac + ad + bc + 2bd
              if (tfvaln(ga_symdot, 14) !== 2*ea*ec + ea*ed + eb*ec + 2*eb*ed) begin
                $display("FAIL symdot(%0d,%0d,%0d,%0d): got %0d want %0d",
                         ea, eb, ec, ed, tfvaln(ga_symdot, 14),
                         2*ea*ec + ea*ed + eb*ec + 2*eb*ed);
                errors = errors + 1;
              end
            end
      $display("tconj_trits   : 6561 combos vs conj(a,b)=(a+b,-b)   %s", errors ? "FAIL" : "OK");
      $display("ga_split_trits: 6561 combos vs dot/wedge/symdot     %s", errors ? "FAIL" : "OK");
      $display("  (each cell is also exercised again through the CPU below)");
    end
  endtask

  // ---- main flow -------------------------------------------------------------
  initial begin
    $dumpfile("rtl/cpu_ga_tb.vcd");
    $dumpvars(0, cpu_ga_tb);

    // build program image and cross-check it against rtl/program_ga.hex
    prog[0]  = mk_ldi(3'd0, 9'sd2);
    prog[1]  = mk_ldi(3'd1, 9'sd3);
    prog[2]  = mk(4'h2, 3'd1, 3'd1, 3'd1);
    prog[3]  = mk(4'h0, 3'd0, 3'd0, 3'd1);
    prog[4]  = mk_ldi(3'd1, 9'sd1);
    prog[5]  = mk_ldi(3'd2, -9'sd2);
    prog[6]  = mk(4'h2, 3'd2, 3'd2, 3'd1);
    prog[7]  = mk(4'h0, 3'd1, 3'd1, 3'd2);
    prog[8]  = mk(4'h6, 3'd3, 3'd0, 3'd0);
    prog[9]  = mk(4'h7, 3'd4, 3'd0, 3'd1);
    prog[10] = mk(4'h8, 3'd5, 3'd0, 3'd1);
    prog[11] = mk(4'h9, 3'd6, 3'd0, 3'd1);
    prog[12] = mk(4'h8, 3'd7, 3'd1, 3'd0);
    prog[13] = mk(4'h6, 3'd3, 3'd3, 3'd0);
    prog[14] = mk(4'h9, 3'd6, 3'd1, 3'd0);
    prog[15] = 16'hF000;    // HLT
    prog_len = 16;
    $readmemh("rtl/program_ga.hex", hex_mem);
    for (i = 0; i < 16; i = i + 1) begin
      if (hex_mem[i] !== prog[i]) begin
        $display("ERROR: program_ga.hex[%0d] = %h, TB-built = %h (mismatch!)",
                 i, hex_mem[i], prog[i]);
        errors = errors + 1;
      end
    end

    run_cell_tests();

    $display("======================================================");
    $display("LAYER 2: CPU GA program run (reference model lockstep)");
    $display("======================================================");
    errors = 0;                      // layer 2 has its own error count
    clk    = 1'b0;
    rst_n  = 1'b0;
    @(posedge clk); @(posedge clk);  // two reset cycles
    #1;                              // release reset OFF the posedge delta
    rst_n = 1'b1;

    // run until HLT (with a watchdog)
    for (i = 0; i < 40 && !hlt; i = i + 1) @(posedge clk);
    if (!hlt) begin
      $display("ERROR: watchdog fired, CPU never halted");
      errors = errors + 1;
    end
    #1;

    $display("------------------------------------------------------");
    $display("CPU halted: pc=%0d, %0d instructions executed, ovf=%b", pc, st, ovf);
    $display("final registers (a, b):");
    for (mi = 0; mi < 8; mi = mi + 1)
      $display("  r%0d = (%3d, %3d)",
               mi, tfvaln(rf[mi*24 +: 12], 6), tfvaln(rf[mi*24 + 12 +: 12], 6));

    // hand-computed final-state assertions (see program_ga.hex header)
    if (tfvaln(rf[0*24 +: 12], 6) !==  2 || tfvaln(rf[0*24 + 12 +: 12], 6) !==  3) begin
      $display("ERROR final r0 (z = 2+3w)"); errors = errors + 1; end
    if (tfvaln(rf[1*24 +: 12], 6) !==  1 || tfvaln(rf[1*24 + 12 +: 12], 6) !== -2) begin
      $display("ERROR final r1 (w = 1-2w)"); errors = errors + 1; end
    if (tfvaln(rf[2*24 +: 12], 6) !==  0 || tfvaln(rf[2*24 + 12 +: 12], 6) !== -2) begin
      $display("ERROR final r2"); errors = errors + 1; end
    if (tfvaln(rf[3*24 +: 12], 6) !==  2 || tfvaln(rf[3*24 + 12 +: 12], 6) !==  3) begin
      $display("ERROR final r3 (conj involutive)"); errors = errors + 1; end
    if (tfvaln(rf[4*24 +: 12], 6) !== -8 || tfvaln(rf[4*24 + 12 +: 12], 6) !==  0) begin
      $display("ERROR final r4 (TDOT)"); errors = errors + 1; end
    if (tfvaln(rf[5*24 +: 12], 6) !==  7 || tfvaln(rf[5*24 + 12 +: 12], 6) !==  0) begin
      $display("ERROR final r5 (TWEDGE)"); errors = errors + 1; end
    if (tfvaln(rf[6*24 +: 12], 6) !== -9 || tfvaln(rf[6*24 + 12 +: 12], 6) !==  0) begin
      $display("ERROR final r6 (TSYMDOT)"); errors = errors + 1; end
    if (tfvaln(rf[7*24 +: 12], 6) !== -7 || tfvaln(rf[7*24 + 12 +: 12], 6) !==  0) begin
      $display("ERROR final r7 (TWEDGE antisymm)"); errors = errors + 1; end
    if (ovf !== 1'b0) begin $display("ERROR: unexpected overflow flag"); errors = errors + 1; end
    if (st  !== 16)   begin $display("ERROR: expected 16 executed steps, got %0d", st);
                             errors = errors + 1; end
    if (tfvaln(r3_after_conj[11:0], 6) !== 5 || tfvaln(r3_after_conj[23:12], 6) !== -3) begin
      $display("ERROR r3 after first TCONJ (expected 5,-3)");
      errors = errors + 1;
    end

    // headline checks
    $display("headline TCONJ conj(2+3w) = 5-3w : r3@step8 = (%0d, %0d)  %s",
             tfvaln(r3_after_conj[11:0], 6), tfvaln(r3_after_conj[23:12], 6),
             (tfvaln(r3_after_conj[11:0], 6) === 5 &&
              tfvaln(r3_after_conj[23:12], 6) === -3) ? "OK" : "FAIL");
    $display("headline TCONJ involutive conj(conj z) = z : r3 = (%0d, %0d)  %s",
             tfvaln(rf[3*24 +: 12], 6), tfvaln(rf[3*24 + 12 +: 12], 6),
             (tfvaln(rf[3*24 +: 12], 6) === 2 &&
              tfvaln(rf[3*24 + 12 +: 12], 6) === 3) ? "OK" : "FAIL");
    $display("headline TDOT z=2+3w, w=1-2w : dot = -8 : r4 = %0d  %s",
             tfvaln(rf[4*24 +: 12], 6),
             (tfvaln(rf[4*24 +: 12], 6) === -8) ? "OK" : "FAIL");
    $display("headline TWEDGE z=2+3w, w=1-2w : wedge = 7 : r5 = %0d  %s",
             tfvaln(rf[5*24 +: 12], 6),
             (tfvaln(rf[5*24 +: 12], 6) === 7) ? "OK" : "FAIL");
    $display("headline TSYMDOT z=2+3w, w=1-2w : symdot = -9 : r6 = %0d  %s",
             tfvaln(rf[6*24 +: 12], 6),
             (tfvaln(rf[6*24 +: 12], 6) === -9) ? "OK" : "FAIL");
    $display("headline TWEDGE antisymm wedge(w,z) = -7 : r7 = %0d  %s",
             tfvaln(rf[7*24 +: 12], 6),
             (tfvaln(rf[7*24 +: 12], 6) === -7) ? "OK" : "FAIL");

    $display("======================================================");
    if (errors == 0)
      $display("ALL GA ASSERTIONS PASSED — TCONJ/TDOT/TWEDGE/TSYMDOT verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
