// ============================================================================
// cpu_tb.v — testbench for the naive balanced-ternary CPU.
//
// Strategy: three layers of checks, each independent of the layer below it.
//   1. Per-trit unit tests: tneg / tand / tor / tmul / tadd1 against a
//      plain-integer model (the 27-entry full-adder truth table, min/max,
//      sign product).  Includes the headline example +1 + +1 = -1 carry +1.
//   2. Word-level cell cross-checks: tadd_trits / tmul_trits / tnorm_trits
//      over all (a,b) in [-8..8]^2 against integer arithmetic.
//   3. CPU program run: the DUT executes the hardcoded program while a
//      reference model (plain integer ALU mirroring the ISA) steps in
//      lockstep; every register is compared after every instruction.  Final
//      state is also asserted against hand-computed constants.
//
// The program image built here must match rtl/program.hex (checked by the
// testbench itself), so the hex file is the single source of truth.
// ============================================================================

`timescale 1ns/1ps

module cpu_tb;

`include "rtl/trit_functions.vh"
`DEF_TERNARY_GATES

  // ---- DUT -----------------------------------------------------------------
  reg  clk, rst_n;
  wire [3:0]   pc;
  wire [15:0]  ir;
  wire [191:0] rf;                 // regfile_flat: 8 regs x 24 bits
  wire         hlt, ovf;

  cpu #(.NREGS(8), .IM_DEPTH(16)) u_cpu (
    .clk(clk), .rst_n(rst_n), .pc(pc), .ir(ir),
    .regfile_flat(rf), .hlt(hlt), .ovf(ovf)
  );

  // ---- word-level cells under test -----------------------------------------
  reg  [11:0] ta, tbv;
  wire [11:0] tadd_sum;
  wire [1:0]  tadd_cout;
  wire [23:0] tmul_prod;
  wire [11:0] tnorm_n;
  wire        tnorm_ofit;
  tadd_trits  #(.NTRITS(6)) u_tadd  (.sum(tadd_sum), .cout(tadd_cout),
                                     .a(ta), .b(tbv), .cin(2'b00));
  tmul_trits  #(.NTRITS(6)) u_tmul  (.prod(tmul_prod), .a(ta), .b(tbv));
  tnorm_trits #(.NTRITS(6)) u_tnorm (.n(tnorm_n), .ofit(tnorm_ofit),
                                     .a(ta), .b(tbv));

  // ---- program image + reference model --------------------------------------
  reg [15:0] hex_mem [0:15];
  reg [15:0] program [0:15];
  integer    prog_len;
  reg signed [31:0] mreg [0:7][0:1];   // model registers: [reg][0]=a, [reg][1]=b
  integer    mpc, st;
  integer    errors;
  integer    mi, i;
  reg [23:0] r1_after_tadd;            // snapshot of r1 right after TADD 1+1

  // build the program image (must equal rtl/program.hex)
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

  // one reference-model step (plain integer mirror of the ISA)
  task model_step;
    reg [3:0] mop;
    reg [2:0] mrd, mra, mrb, mk_;
    integer a, b, c, d, n;
    begin
      mop = program[mpc][15:12];
      mrd = program[mpc][11:9];
      mra = program[mpc][8:6];
      mrb = program[mpc][5:3];
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
          mreg[mrd][0] = $signed(program[mpc][8:0]);
          mreg[mrd][1] = 0;
        end
        4'h5: begin
          // TMUL: Eisenstein multiply (a+bw)(c+dw), w^2 = w-1
          //   A = a*c - b*d,  B = a*d + b*c + b*d  (values fit 6 trits here)
          a = mreg[mra][0]; b = mreg[mra][1];
          c = mreg[mrb][0]; d = mreg[mrb][1];
          mreg[mrd][0] = a*c - b*d;
          mreg[mrd][1] = a*d + b*c + b*d;
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

  task print_digits;   // 6-trit field as 1/0/T characters, low trit first
    input [11:0] f;
    integer j;
    begin
      $write("  digits(lo->hi): ");
      for (j = 0; j < 6; j = j + 1) begin
        case (f[j*2 +: 2])
          2'b01: $write("1 ");
          2'b10: $write("T ");
          default: $write("0 ");
        endcase
      end
      $write("\n");
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
      if (st == 1) r1_after_tadd = rf[1*24 +: 24];   // snapshot TADD 1+1 result
      $display("step %2d: pc=%0d op=%h rd=r%0d ra=r%0d rb=%0d -> r%0d = (%2d, %2d)",
               st, pc, program[mpc][15:12], program[mpc][11:9],
               program[mpc][8:6], program[mpc][5:3],
               program[mpc][11:9],
               tfvaln(rf[program[mpc][11:9]*24 +: 12], 6),
               tfvaln(rf[program[mpc][11:9]*24 + 12 +: 12], 6));
      mpc = mpc + 1;
      st = st + 1;
    end
  end

  always #5 clk = ~clk;

  // ---- unit tests -----------------------------------------------------------
  task run_unit_tests;
    integer ai, bi, ci, s;
    reg [1:0] va, vb, vc, esum, ecout;
    reg [3:0] got;              // tadd1 returns {cout, sum}: 4 bits!
    integer ea, eb;
    begin
      errors = 0;               // fresh count for the unit-test layers
      $display("======================================================");
      $display("LAYER 1: per-trit gate unit tests (vs integer model)");
      $display("======================================================");

      // tneg
      if (tneg(2'b01) !== 2'b10) begin $display("FAIL tneg(+1)"); errors = errors + 1; end
      if (tneg(2'b10) !== 2'b01) begin $display("FAIL tneg(-1)"); errors = errors + 1; end
      if (tneg(2'b00) !== 2'b00) begin $display("FAIL tneg(0)");  errors = errors + 1; end
      $display("tneg : +1<->-1, 0->0   %s", errors ? "FAIL" : "OK");

      // tand / tor over all 9 pairs, plus the min/max duality tneg(tor(tneg b, tneg a))
      for (ai = 0; ai < 3; ai = ai + 1)
        for (bi = 0; bi < 3; bi = bi + 1) begin
          va = trit_of(ai - 1); vb = trit_of(bi - 1);
          ea = ai - 1; eb = bi - 1;
          if (tand(va, vb) !== trit_of(ea < eb ? ea : eb)) begin
            $display("FAIL tand(%0d,%0d)", ea, eb); errors = errors + 1;
          end
          if (tor(va, vb) !== trit_of(ea > eb ? ea : eb)) begin
            $display("FAIL tor(%0d,%0d)", ea, eb); errors = errors + 1;
          end
          if (tand(va, vb) !== tneg(tor(tneg(vb), tneg(va)))) begin
            $display("FAIL tand/tor duality (%0d,%0d)", ea, eb); errors = errors + 1;
          end
        end
      $display("tand : min over 9 pairs (lattice meet)  %s", errors ? "FAIL" : "OK");
      $display("tor  : max over 9 pairs (lattice join)  %s", errors ? "FAIL" : "OK");

      // tmul over all 9 pairs (sign product)
      for (ai = 0; ai < 3; ai = ai + 1)
        for (bi = 0; bi < 3; bi = bi + 1) begin
          va = trit_of(ai - 1); vb = trit_of(bi - 1);
          ea = ai - 1; eb = bi - 1;
          got = tmul(va, vb);
          if (got !== trit_of(ea * eb)) begin
            $display("FAIL tmul(%0d,%0d): got %b want %b", ea, eb, got, trit_of(ea * eb));
            errors = errors + 1;
          end
        end
      $display("tmul : trit x trit sign product, 9 pairs  %s", errors ? "FAIL" : "OK");

      // tadd1: all 27 (a, b, cin) triples vs the integer digit-sum rule
      for (ai = 0; ai < 3; ai = ai + 1)
        for (bi = 0; bi < 3; bi = bi + 1)
          for (ci = 0; ci < 3; ci = ci + 1) begin
            va = trit_of(ai - 1); vb = trit_of(bi - 1); vc = trit_of(ci - 1);
            s = (ai - 1) + (bi - 1) + (ci - 1);
            if (s >= 2)      begin esum = trit_of(s - 3); ecout = 2'b01; end
            else if (s <= -2) begin esum = trit_of(s + 3); ecout = 2'b10; end
            else             begin esum = trit_of(s);     ecout = 2'b00; end
            got = tadd1(va, vb, vc);
            if (got[3:2] !== ecout || got[1:0] !== esum) begin
              $display("FAIL tadd1(%0d,%0d,%0d): got cout=%b sum=%b want cout=%b sum=%b",
                       ai-1, bi-1, ci-1, got[3:2], got[1:0], ecout, esum);
              errors = errors + 1;
            end
          end
      $display("tadd1: all 27 (a,b,cin) triples checked  %s", errors ? "FAIL" : "OK");
      got = tadd1(2'b01, 2'b01, 2'b00);
      $display("headline: tadd1(+1, +1, 0) -> sum %s, carry %s   (expect -1, +1)",
               got[1:0] == 2'b10 ? "-1" : "?", got[3:2] == 2'b01 ? "+1" : "?");

      $display("======================================================");
      $display("LAYER 2: word-level cell cross-checks (a,b in [-8..8]^2)");
      $display("======================================================");
      for (ea = -8; ea <= 8; ea = ea + 1)
        for (eb = -8; eb <= 8; eb = eb + 1) begin
          ta = enc6(ea); tbv = enc6(eb); #1;
          if (tfvaln(tadd_sum, 6) !== ea + eb || tadd_cout !== 2'b00) begin
            $display("FAIL tadd_trits(%0d,%0d): got %0d cout %b", ea, eb,
                     tfvaln(tadd_sum, 6), tadd_cout);
            errors = errors + 1;
          end
          if (tfvaln(tmul_prod, 12) !== ea * eb) begin
            $display("FAIL tmul_trits(%0d,%0d): got %0d want %0d", ea, eb,
                     tfvaln(tmul_prod, 12), ea * eb);
            errors = errors + 1;
          end
          if (tfvaln(tnorm_n, 6) !== ea*ea + ea*eb + eb*eb || tnorm_ofit !== 1'b0) begin
            $display("FAIL tnorm_trits(%0d,%0d): got %0d ofit %b", ea, eb,
                     tfvaln(tnorm_n, 6), tnorm_ofit);
            errors = errors + 1;
          end
        end
      $display("tadd_trits  : 289 pairs vs integer add      %s", errors ? "FAIL" : "OK");
      $display("tmul_trits  : 289 pairs vs integer product  %s", errors ? "FAIL" : "OK");
      $display("tnorm_trits : 289 pairs vs integer norm     %s", errors ? "FAIL" : "OK");
      $display("  (each cell is also exercised again through the CPU below)");
    end
  endtask

  // ---- main flow -------------------------------------------------------------
  initial begin
    $dumpfile("rtl/cpu_tb.vcd");
    $dumpvars(0, cpu_tb);

    // build program image and cross-check it against rtl/program.hex
    program[0]  = mk_ldi(3'd0, 9'sd1);
    program[1]  = mk(4'h0, 3'd1, 3'd0, 3'd0);
    program[2]  = mk(4'h2, 3'd2, 3'd1, 3'd3);
    program[3]  = mk(4'h2, 3'd3, 3'd1, 3'd1);
    program[4]  = mk(4'h0, 3'd1, 3'd1, 3'd2);
    program[5]  = mk(4'h1, 3'd4, 3'd3, 3'd2);
    program[6]  = mk_ldi(3'd5, 9'sd2);
    program[7]  = mk_ldi(3'd6, 9'sd1);
    program[8]  = mk(4'h3, 3'd7, 3'd5, 3'd6);
    program[9]  = mk(4'h3, 3'd6, 3'd5, 3'd5);
    program[10] = mk(4'h2, 3'd6, 3'd6, 3'd5);
    program[11] = mk(4'h2, 3'd7, 3'd7, 3'd2);
    program[12] = mk(4'h0, 3'd6, 3'd6, 3'd7);
    program[13] = mk(4'h5, 3'd6, 3'd6, 3'd7);
    program[14] = mk(4'h2, 3'd7, 3'd7, 3'd4);
    program[15] = 16'hF000;    // HLT
    prog_len    = 16;
    $readmemh("rtl/program.hex", hex_mem);
    for (i = 0; i < 16; i = i + 1) begin
      if (hex_mem[i] !== program[i]) begin
        $display("ERROR: program.hex[%0d] = %h, TB-built = %h (mismatch!)",
                 i, hex_mem[i], program[i]);
        errors = errors + 1;
      end
    end

    run_unit_tests();

    $display("======================================================");
    $display("LAYER 3: CPU program run (reference model lockstep)");
    $display("======================================================");
    errors = 0;                      // layer 3 has its own error count
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
    $display("final registers (a, b) and packed 24-bit words:");
    for (mi = 0; mi < 8; mi = mi + 1)
      $display("  r%0d = (%3d, %3d)   packed %24b",
               mi, tfvaln(rf[mi*24 +: 12], 6), tfvaln(rf[mi*24 + 12 +: 12], 6),
               rf[mi*24 +: 24]);

    $display("r1 right after TADD 1+1 (= 2, balanced \"1T\"):");
    print_digits(r1_after_tadd[11:0]);
    $display("final r6 b-field (= 35 from TMUL (5-5w)(-7+7w) = 35w):");
    print_digits(rf[6*24 + 12 +: 12]);

    // hand-computed final-state assertions
    if (tfvaln(rf[0*24 +: 12], 6) !==  1 || tfvaln(rf[0*24 + 12 +: 12], 6) !== 0) begin
      $display("ERROR final r0"); errors = errors + 1; end
    if (tfvaln(rf[1*24 +: 12], 6) !==  0 || tfvaln(rf[1*24 + 12 +: 12], 6) !== 0) begin
      $display("ERROR final r1"); errors = errors + 1; end
    if (tfvaln(rf[2*24 +: 12], 6) !== -2 || tfvaln(rf[2*24 + 12 +: 12], 6) !== 0) begin
      $display("ERROR final r2"); errors = errors + 1; end
    if (tfvaln(rf[3*24 +: 12], 6) !==  0 || tfvaln(rf[3*24 + 12 +: 12], 6) !== 2) begin
      $display("ERROR final r3"); errors = errors + 1; end
    if (tfvaln(rf[4*24 +: 12], 6) !==  2 || tfvaln(rf[4*24 + 12 +: 12], 6) !== 2) begin
      $display("ERROR final r4"); errors = errors + 1; end
    if (tfvaln(rf[5*24 +: 12], 6) !==  2 || tfvaln(rf[5*24 + 12 +: 12], 6) !== 0) begin
      $display("ERROR final r5"); errors = errors + 1; end
    if (tfvaln(rf[6*24 +: 12], 6) !==  0 || tfvaln(rf[6*24 + 12 +: 12], 6) !== 35) begin
      $display("ERROR final r6"); errors = errors + 1; end
    if (tfvaln(rf[7*24 +: 12], 6) !==  7 || tfvaln(rf[7*24 + 12 +: 12], 6) !== 0) begin
      $display("ERROR final r7"); errors = errors + 1; end
    if (ovf !== 1'b0) begin $display("ERROR: unexpected overflow flag"); errors = errors + 1; end
    if (st  !== 16)   begin $display("ERROR: expected 16 executed steps, got %0d", st);
                             errors = errors + 1; end

    // headline checks
    $display("headline TNORM(2,1) = 7 : r7 = (%0d, %0d)  %s",
             tfvaln(rf[7*24 +: 12], 6), tfvaln(rf[7*24 + 12 +: 12], 6),
             (tfvaln(rf[7*24 +: 12], 6) === 7) ? "OK" : "FAIL");
    $display("headline TROT k=3 (w^3 = -1) : r2 = %0d  %s",
             tfvaln(rf[2*24 +: 12], 6),
             (tfvaln(rf[2*24 +: 12], 6) === -2) ? "OK" : "FAIL");
    $display("headline TMUL (5-5w)(-7+7w) = 35w : r6 = (%0d, %0d)  %s",
             tfvaln(rf[6*24 +: 12], 6), tfvaln(rf[6*24 + 12 +: 12], 6),
             (tfvaln(rf[6*24 +: 12], 6) === 0 &&
              tfvaln(rf[6*24 + 12 +: 12], 6) === 35) ? "OK" : "FAIL");

    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — ternary datapath verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
