// ============================================================================
// ga_ops_tb.v — behavioral equivalence sweep for the exact-width GA cells
// (tconj / tdot / twedge / tsymdot in rtl/ga_ops.v).
//
// For every (a,b,c,d) quadruple in the sweep, each DUT output is decoded back
// to an integer and compared against the reference computed directly in the
// testbench from the Lean definitions:
//
//   TCONJ   conj(a,b) = (a+b, -b)                  (Conjugate.lean L27)
//   TDOT    dot  = (z * conj w).a = ac + ad + bd   (DotWedge.lean  L49)
//   TWEDGE  wedge= (z * conj w).b = bc - ad        (DotWedge.lean  L58)
//   TSYMDOT symdot = N(z+w) - N(z) - N(w)          (SymDot.lean    L33)
//           where N(x,y) = x^2 + x*y + y^2         (Conventions.lean L64-65)
//
// Sweep (the "stride + boundary + random" recipe):
//   1. BOUNDARY cross: a,b,c,d each over the 9 carry-threshold/extreme values
//      {-364,-40,-13,-1,0,1,13,40,364}  -> 9^4 = 6561 vectors.
//   2. STRIDE: co-prime diagonal sweep of 2000 points — each coordinate steps
//      through [-364,364] with strides 7/11/13/17 (mod 729), a space-filling
//      strided lattice over the interior.
//   3. RANDOM: 2000 uniform quadruples (seeded $dist_uniform, reproducible).
//
// 5 assertions per vector (tconj.a, tconj.b, dot, wedge, symdot).
// Run:
//   iverilog -g2001 -s ga_ops_tb rtl/tmul_opt.v rtl/ga_ops.v rtl/ga_ops_tb.v
// ============================================================================

`timescale 1ns/1ps
module ga_ops_tb;
  // ---- DUTs ----
  reg  [11:0] A, B, C, D;
  wire [13:0] cj_a;        // tconj a-coordinate, 7 trits
  wire [11:0] cj_b;        // tconj b-coordinate, 6 trits
  wire [25:0] dt, wg, sd;  // tdot / twedge / tsymdot, 13 trits each

  tconj   u_conj  (.a_out(cj_a), .b_out(cj_b), .a(A), .b(B));
  tdot    u_dot   (.d_out(dt),    .a(A), .b(B), .c(C), .d(D));
  twedge  u_wedge (.w_out(wg),    .a(A), .b(B), .c(C), .d(D));
  tsymdot u_sym   (.s_out(sd),    .a(A), .b(B), .c(C), .d(D));

  // ---- trit <-> integer helpers (same balanced-digit code as tmul_opt_tb.v) ----
  reg [63:0] tmp;

  function [63:0] encN; input integer v; input integer nt;
    integer r, d, j;
    begin
      r = v; encN = 64'b0;
      for (j = 0; j < nt; j = j + 1) begin
        d = r % 3;
        if (d == 2)       begin encN[j*2 +: 2] = 2'b10; r = (r + 1) / 3; end
        else if (d == -2) begin encN[j*2 +: 2] = 2'b01; r = (r - 1) / 3; end
        else begin
          if (d == 1)      encN[j*2 +: 2] = 2'b01;
          else if (d == -1) encN[j*2 +: 2] = 2'b10;
          else             encN[j*2 +: 2] = 2'b00;
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

  function integer f_norm; input integer x, y;
    begin f_norm = x*x + x*y + y*y; end
  endfunction

  // ---- accounting + sweep sets ----
  integer npass, nfail, nvec, i, seed;
  integer bv [0:8];    // boundary values (carry thresholds + extremes)

  // ---- drive + check one (a,b,c,d) quadruple ----
  task check_quad;
    input integer a, b, c, d;
    integer ea, eb, ed, ew, es;   // expected (reference)
    integer ra, rb, rd, rw, rs;   // actual (decoded from DUT)
    begin
      tmp = encN(a,6); A = tmp[11:0];
      tmp = encN(b,6); B = tmp[11:0];
      tmp = encN(c,6); C = tmp[11:0];
      tmp = encN(d,6); D = tmp[11:0];
      #1;                                   // combinational settle

      ea = a + b;                           // Conjugate.lean: conj = <a+b, -b>
      eb = -b;
      ed = a*c + a*d + b*d;                 // DotWedge.lean: (z*conj w).a
      ew = b*c - a*d;                       // DotWedge.lean: (z*conj w).b
      es = f_norm(a+c, b+d) - f_norm(a, b) - f_norm(c, d);   // SymDot.lean

      ra = tfvaln({50'b0, cj_a}, 7);        // 7 trits
      rb = tfvaln({52'b0, cj_b}, 6);        // 6 trits
      rd = tfvaln({38'b0, dt},  13);        // 13 trits
      rw = tfvaln({38'b0, wg},  13);
      rs = tfvaln({38'b0, sd},  13);

      if (ra !== ea) begin
        $display("TCONJ.a FAIL (%0d,%0d): got %0d want %0d", a, b, ra, ea);
        nfail = nfail + 1;
      end else npass = npass + 1;

      if (rb !== eb) begin
        $display("TCONJ.b FAIL (%0d,%0d): got %0d want %0d", a, b, rb, eb);
        nfail = nfail + 1;
      end else npass = npass + 1;

      if (rd !== ed) begin
        $display("TDOT FAIL (%0d,%0d)x(%0d,%0d): got %0d want %0d", a,b,c,d, rd, ed);
        nfail = nfail + 1;
      end else npass = npass + 1;

      if (rw !== ew) begin
        $display("TWEDGE FAIL (%0d,%0d)x(%0d,%0d): got %0d want %0d", a,b,c,d, rw, ew);
        nfail = nfail + 1;
      end else npass = npass + 1;

      if (rs !== es) begin
        $display("TSYMDOT FAIL (%0d,%0d)x(%0d,%0d): got %0d want %0d", a,b,c,d, rs, es);
        nfail = nfail + 1;
      end else npass = npass + 1;

      nvec = nvec + 1;
    end
  endtask

  initial begin
    npass = 0; nfail = 0; nvec = 0;

    // ---- 1. boundary cross (carry thresholds + extremes), 9^4 vectors ----
    bv[0] = -364; bv[1] = -40; bv[2] = -13; bv[3] = -1; bv[4] = 0;
    bv[5] = 1;    bv[6] = 13;  bv[7] = 40;  bv[8] = 364;
    for (i = 0; i < 9*9*9*9; i = i + 1)
      check_quad(bv[i % 9], bv[(i/9) % 9], bv[(i/81) % 9], bv[(i/729) % 9]);
    $display("boundary cross : %0d vectors | pass=%0d fail=%0d", 9*9*9*9, npass, nfail);

    // ---- 2. stride: co-prime diagonal sweep, 2000 points over [-364,364]^4 ----
    for (i = 0; i < 2000; i = i + 1)
      check_quad(-364 + ((i*7)  % 729),
                 -364 + ((i*11) % 729),
                 -364 + ((i*13) % 729),
                 -364 + ((i*17) % 729));
    $display("stride sweep   : %0d vectors | pass=%0d fail=%0d", 2000, npass, nfail);

    // ---- 3. random uniform quadruples (seeded, reproducible) ----
    seed = 20260829;
    for (i = 0; i < 2000; i = i + 1)
      check_quad($dist_uniform(seed, 0, 728) - 364,
                 $dist_uniform(seed, 0, 728) - 364,
                 $dist_uniform(seed, 0, 728) - 364,
                 $dist_uniform(seed, 0, 728) - 364);
    $display("random         : %0d vectors | pass=%0d fail=%0d", 2000, npass, nfail);

    $display("--------------------------------------------------------------");
    $display("TOTAL: %0d vectors, %0d assertions PASSED, %0d FAILED", nvec, npass, nfail);
    if (nfail == 0) $display("GA OPS: ALL ASSERTIONS PASSED");
    else            $display("GA OPS: %0d FAILURES", nfail);
    $finish;
  end
endmodule
