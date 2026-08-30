// ============================================================================
// tmul_opt_tb.v — behavioral equivalence sweep for tmul_opt.v.
//
// PRIMARY CORRECTNESS EVIDENCE: formal SAT equivalence (rtl/miters.v +
// `sat -set invalid 0 -prove diff 0` in yosys) — proved bit-identical output
// for EVERY reachable input (no trit in the forbidden 2'b11 state):
//   miter_tmul   NTRITS = 2, 6, 9, 12   tmul_trits  vs tmul_trits_opt
//   miter_tnorm  NTRITS = 6, 9           tnorm_trits vs tnorm_trits_opt
//                                        (USE_KARATSUBA = 0 AND 1)
//   miter_eisen  NTRITS = 6, 9           tmul_eisen_trits vs tmul_eisen_naive
// This testbench is the BEHAVIORAL confirmation, over a sweep of (a,b) /
// (a,b,c,d) pairs (full-range stride + carry-boundary set + random), of:
//   * tmul_trits_opt == tmul_trits == a*b        (12-trit products)
//   * tnorm_trits_opt == tnorm_trits == a^2+ab+b^2   (n AND ofit)
//   * tmul_eisen_trits == tmul_eisen_naive == (A,B) = (ac-bd, ad+bc+bd)
// Run: iverilog -g2001 -s tmul_opt_tb rtl/ternary_gates.v rtl/tmul_opt.v rtl/tmul_opt_tb.v
// ============================================================================

`timescale 1ns/1ps
module tmul_opt_tb;
`include "rtl/trit_functions.vh"
`DEF_TERNARY_GATES
  reg [63:0] tmp;
  reg [11:0] ta, tb, tc, td;
  wire [23:0] p_orig, p_opt;
  wire [11:0] n_orig, n_opt0, n_opt1;
  wire        of_orig, of_opt0, of_opt1;
  wire [23:0] ea_k, ea_n; wire [25:0] eb_k, eb_n;
  tmul_trits     #(.NTRITS(6)) u_o (.prod(p_orig), .a(ta), .b(tb));
  tmul_trits_opt #(.NTRITS(6)) u_k (.prod(p_opt),  .a(ta), .b(tb));
  tnorm_trits     #(.NTRITS(6)) u_no (.n(n_orig), .ofit(of_orig), .a(ta), .b(tb));
  tnorm_trits_opt #(.NTRITS(6), .USE_KARATSUBA(0)) u_nk0 (.n(n_opt0), .ofit(of_opt0), .a(ta), .b(tb));
  tnorm_trits_opt #(.NTRITS(6), .USE_KARATSUBA(1)) u_nk1 (.n(n_opt1), .ofit(of_opt1), .a(ta), .b(tb));
  tmul_eisen_trits #(.NTRITS(6)) u_ek (.A_out(ea_k), .B_out(eb_k), .a(ta), .b(tb), .c(tc), .d(td));
  tmul_eisen_naive #(.NTRITS(6)) u_en (.A_out(ea_n), .B_out(eb_n), .a(ta), .b(tb), .c(tc), .d(td));

  function [63:0] encN; input integer v; input integer nt;
    integer r, d, j;
    begin
      r = v; encN = 64'b0;
      for (j = 0; j < nt; j = j + 1) begin
        d = r % 3;
        if (d == 2) begin encN[j*2 +: 2] = 2'b10; r = (r + 1) / 3; end
        else if (d == -2) begin encN[j*2 +: 2] = 2'b01; r = (r - 1) / 3; end
        else begin
          if (d == 1) encN[j*2 +: 2] = 2'b01;
          else if (d == -1) encN[j*2 +: 2] = 2'b10;
          else encN[j*2 +: 2] = 2'b00;
          r = r / 3;
        end
      end
    end
  endfunction
  function integer tfvaln; input [63:0] f; input integer nt;
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
  function integer resmod; input integer v; input integer m;
    integer r;
    begin
      r = v % m;
      if (r > (m-1)/2) r = r - m;
      else if (r < -(m-1)/2) r = r + m;
      resmod = r;
    end
  endfunction
  integer err, cnt, i, j, a, b, c, d, nint, rexp, pint, eA, eB, seed;
  reg [31:0] bv [0:8];
  initial begin
    err = 0; cnt = 0;
    // ---- tmul + tnorm: stride-12 range + boundaries + random ----
    for (i = -364; i <= 364; i = i + 12) begin
      for (j = -364; j <= 364; j = j + 12) begin
        a = i; b = j;
        tmp = encN(a,6); ta = tmp[11:0]; tmp = encN(b,6); tb = tmp[11:0]; #1;
        pint = a*b; nint = a*a + a*b + b*b; rexp = resmod(nint, 729);
        if (p_orig !== p_opt || tfvaln(p_orig,12) !== pint) begin
          $display("TMUL FAIL a=%0d b=%0d orig=%0d opt=%0d want=%0d", a, b, tfvaln(p_orig,12), tfvaln(p_opt,12), pint); err = err + 1;
        end
        if (n_orig !== n_opt0 || n_orig !== n_opt1 || of_orig !== of_opt0 || of_orig !== of_opt1 ||
            tfvaln(n_orig,6) !== rexp || of_orig !== (nint > 364)) begin
          $display("TNORM FAIL a=%0d b=%0d n=%0d/%0d/%0d of=%b/%b/%b want n=%0d of=%b", a, b,
                   tfvaln(n_orig,6), tfvaln(n_opt0,6), tfvaln(n_opt1,6), of_orig, of_opt0, of_opt1, rexp, nint > 364); err = err + 1;
        end
        cnt = cnt + 1;
      end
    end
    $display("tmul/tnorm stride sweep: %0d vectors, %0d errors", cnt, err);
    seed = 5;
    for (i = 0; i < 2000; i = i + 1) begin
      a = $dist_uniform(seed, 0, 728) - 364;
      b = $dist_uniform(seed, 0, 728) - 364;
      tmp = encN(a,6); ta = tmp[11:0]; tmp = encN(b,6); tb = tmp[11:0]; #1;
      pint = a*b; nint = a*a + a*b + b*b; rexp = resmod(nint, 729);
      if (p_orig !== p_opt || tfvaln(p_orig,12) !== pint) begin
        $display("TMUL FAIL a=%0d b=%0d", a, b); err = err + 1;
      end
      if (n_orig !== n_opt0 || n_orig !== n_opt1 || of_orig !== of_opt0 || of_orig !== of_opt1 ||
          tfvaln(n_orig,6) !== rexp || of_orig !== (nint > 364)) begin
        $display("TNORM FAIL a=%0d b=%0d", a, b); err = err + 1;
      end
      cnt = cnt + 1;
    end
    $display("tmul/tnorm + random: %0d total vectors, %0d errors", cnt, err);
    // ---- eisen: boundary 9^4 + random ----
    bv[0]=-364; bv[1]=-40; bv[2]=-13; bv[3]=-1; bv[4]=0; bv[5]=1; bv[6]=13; bv[7]=40; bv[8]=364;
    cnt = 0;
    for (i = 0; i < 9*9*9*9; i = i + 1) begin
      a = bv[i % 9]; b = bv[(i/9) % 9]; c = bv[(i/81) % 9]; d = bv[(i/729) % 9];
      tmp = encN(a,6); ta = tmp[11:0]; tmp = encN(b,6); tb = tmp[11:0];
      tmp = encN(c,6); tc = tmp[11:0]; tmp = encN(d,6); td = tmp[11:0]; #1;
      eA = a*c - b*d; eB = a*d + b*c + b*d;
      if (ea_k !== ea_n || eb_k !== eb_n || tfvaln(ea_k,12) !== eA || tfvaln(eb_k,13) !== eB) begin
        $display("EISEN FAIL (%0d,%0d)x(%0d,%0d) A=%0d/%0d B=%0d/%0d want A=%0d B=%0d",
                 a,b,c,d, tfvaln(ea_k,12), tfvaln(ea_n,12), tfvaln(eb_k,13), tfvaln(eb_n,13), eA, eB); err = err + 1;
      end
      cnt = cnt + 1;
    end
    seed = 5;
    for (i = 0; i < 1000; i = i + 1) begin
      a = $dist_uniform(seed, 0, 728) - 364;
      b = $dist_uniform(seed, 0, 728) - 364;
      c = $dist_uniform(seed, 0, 728) - 364;
      d = $dist_uniform(seed, 0, 728) - 364;
      tmp = encN(a,6); ta = tmp[11:0]; tmp = encN(b,6); tb = tmp[11:0];
      tmp = encN(c,6); tc = tmp[11:0]; tmp = encN(d,6); td = tmp[11:0]; #1;
      eA = a*c - b*d; eB = a*d + b*c + b*d;
      if (ea_k !== ea_n || eb_k !== eb_n || tfvaln(ea_k,12) !== eA || tfvaln(eb_k,13) !== eB) begin
        $display("EISEN FAIL (%0d,%0d)x(%0d,%0d)", a,b,c,d); err = err + 1;
      end
      cnt = cnt + 1;
    end
    $display("eisen sweep: %0d vectors, %0d errors", cnt, err);
    if (err == 0) $display("LEAN SWEEP: ALL PASSED"); else $display("LEAN SWEEP: %0d FAILURES", err);
    $finish;
  end
endmodule
