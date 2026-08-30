// ============================================================================
// grad_recon_tb.v -- iverilog functional check of tgrad_cell + trecon_cell.
//
// Checks, against hand-computed balanced-ternary integers:
//   1. TGRAD correctness  -- div = F0−F2−F3+F5,  curl = F1+F2−F4−F5.
//   2. Round trip (canonical gauge)  -- TRECON(TGRAD(F)) = F  for fields
//      supported on ω⁰,ω¹ (F2=F3=F4=F5=0, center=0).
//   3. Gauge invariance  -- a constant shift of the field leaves div/curl
//      unchanged (the discrete Σ(O−E)=0 / additive-gauge conservation); a
//      uniform field has zero gradient.
//   4. Gauge-invariant round trip  -- TGRAD(TRECON(TGRAD(F))) == TGRAD(F) for a
//      general (non-canonical) field, and TRECON lands on the canonical rep.
//   5. TRECON direct  -- the canonical section, and the ofit fit check.
//
// Trit encoding: 2 bits/trit, one-hot: +1=2'b01, 0=2'b00, −1=2'b10.
// Word = 6 trits = 12 bits; trit i at bits [2i+1:2i].  div/curl = 8 trits.
// ============================================================================
`timescale 1ns/1ps

module grad_recon_tb;

  // ---- device under test ----
  reg  [11:0] c;           // center
  reg  [71:0] nb;          // 6 neighbors {F5,F4,F3,F2,F1,F0}, F0 at bits[11:0]
  wire [15:0] div, curl;   // 8-trit source
  wire [71:0] nb_rec;
  wire [11:0] c_rec;
  wire        ofit;

  tgrad_cell #(.NTRITS(6)) dut_grad (
    .div(div), .curl(curl), .c(c), .nb(nb));

  trecon_cell #(.NTRITS(6)) dut_recon (
    .nb_rec(nb_rec), .c_rec(c_rec), .ofit(ofit),
    .div(div), .curl(curl));

  // re-derivative of the reconstruction (for the gauge-invariant round trip)
  wire [15:0] div2, curl2;
  tgrad_cell #(.NTRITS(6)) dut_grad2 (
    .div(div2), .curl(curl2), .c(c_rec), .nb(nb_rec));

  // standalone trecon for direct gauge/ofit tests
  reg  [15:0] ddiv, dcurl;
  wire [71:0] dnb_rec;
  wire [11:0] dc_rec;
  wire        dofit;
  trecon_cell #(.NTRITS(6)) dut_recon_direct (
    .nb_rec(dnb_rec), .c_rec(dc_rec), .ofit(dofit),
    .div(ddiv), .curl(dcurl));

  // ---- helpers -------------------------------------------------------------
  integer errors;

  // 3^k
  function integer pow3;
    input integer k;
    integer j, p;
    begin
      p = 1;
      for (j = 0; j < k; j = j + 1) p = p * 3;
      pow3 = p;
    end
  endfunction

  // balanced-ternary encoder: integer v -> n-trit one-hot field (returns [15:0])
  function [15:0] enc;
    input integer v;
    input integer n;
    integer r, i;
    begin
      r = v;
      enc = 16'b0;
      for (i = n-1; i >= 0; i = i - 1) begin
        if (r > (pow3(i)-1)/2)       begin enc[i*2 +: 2] = 2'b01; r = r - pow3(i); end
        else if (r < -(pow3(i)-1)/2) begin enc[i*2 +: 2] = 2'b10; r = r + pow3(i); end
      end
    end
  endfunction

  function [11:0] enc6;
    input integer v;
    enc6 = enc(v, 6);
  endfunction

  function [15:0] enc8;
    input integer v;
    enc8 = enc(v, 8);
  endfunction

  // balanced-ternary decoder: n-trit one-hot field -> integer
  function integer dec;
    input [15:0] w;
    input integer n;
    integer i, acc;
    begin
      acc = 0;
      for (i = 0; i < n; i = i + 1)
        case (w[i*2 +: 2])
          2'b01: acc = acc + pow3(i);
          2'b10: acc = acc - pow3(i);
        endcase
      dec = acc;
    end
  endfunction

  // ---- stimulus helpers ----------------------------------------------------
  task apply_field;
    input integer f0, f1, f2, f3, f4, f5, fc;
    begin
      c  = enc6(fc);
      nb = {enc6(f5), enc6(f4), enc6(f3), enc6(f2), enc6(f1), enc6(f0)};
    end
  endtask

  // check TGRAD output vs expected integers (and echo)
  task chk_grad;
    input integer exp_div, exp_curl;
    begin
      #1;
      if (dec(div, 8) != exp_div || dec(curl, 8) != exp_curl) begin
        errors = errors + 1;
        $display("FAIL TGRAD: c=%h nb=%h -> div=%0d curl=%0d  expect div=%0d curl=%0d",
                 c, nb, dec(div, 8), dec(curl, 8), exp_div, exp_curl);
      end else begin
        $display("OK   TGRAD: div=%0d curl=%0d", exp_div, exp_curl);
      end
    end
  endtask

  // check TRECON(wired) output: expected 6 neighbors + center + ofit
  task chk_recon;
    input integer e0, e1, e2, e3, e4, e5, ec, eof;
    begin
      #1;
      if (dec(nb_rec[ 0*12 +: 12], 6) != e0 || dec(nb_rec[ 1*12 +: 12], 6) != e1 ||
          dec(nb_rec[ 2*12 +: 12], 6) != e2 || dec(nb_rec[ 3*12 +: 12], 6) != e3 ||
          dec(nb_rec[ 4*12 +: 12], 6) != e4 || dec(nb_rec[ 5*12 +: 12], 6) != e5 ||
          dec(c_rec, 6) != ec || ofit !== eof) begin
        errors = errors + 1;
        $display("FAIL TRECON: got (%0d,%0d,%0d,%0d,%0d,%0d) center=%0d ofit=%b  expect (%0d,%0d,%0d,%0d,%0d,%0d) center=%0d ofit=%b",
                 dec(nb_rec[0*12 +: 12],6), dec(nb_rec[1*12 +: 12],6),
                 dec(nb_rec[2*12 +: 12],6), dec(nb_rec[3*12 +: 12],6),
                 dec(nb_rec[4*12 +: 12],6), dec(nb_rec[5*12 +: 12],6),
                 dec(c_rec,6), ofit,
                 e0,e1,e2,e3,e4,e5, ec, eof);
      end else begin
        $display("OK   TRECON: (%0d,%0d,%0d,%0d,%0d,%0d) center=%0d ofit=%b",
                 e0,e1,e2,e3,e4,e5, ec, ofit);
      end
    end
  endtask

  // check gauge-invariant round trip: TGRAD(TRECON(TGRAD(F))) == TGRAD(F)
  task chk_roundtrip_identity;
    begin
      #1;
      if (div2 !== div || curl2 !== curl) begin
        errors = errors + 1;
        $display("FAIL roundtrip-identity: grad(recon(grad F))=(%0d,%0d) != grad F=(%0d,%0d)",
                 dec(div2,8), dec(curl2,8), dec(div,8), dec(curl,8));
      end else begin
        $display("OK   roundtrip-identity: grad(recon(grad F))=(%0d,%0d) == grad F",
                 dec(div,8), dec(curl,8));
      end
    end
  endtask

  // ---- run ----------------------------------------------------------------
  initial begin
    errors = 0;

    // ======================================================================
    // 1. TGRAD correctness (hand-computed).  center = 0 unless noted.
    // ======================================================================
    $display("-- TGRAD correctness --");
    apply_field( 1, 0, 0, 0, 0, 0, 0); chk_grad(  1,  0);   // F0=+1
    apply_field( 0, 1, 0, 0, 0, 0, 0); chk_grad(  0,  1);   // F1=+1
    apply_field( 0, 0, 1, 0, 0, 0, 0); chk_grad( -1,  1);   // F2=+1  (ω²=−a+b)
    apply_field( 0, 0, 0, 1, 0, 0, 0); chk_grad( -1,  0);   // F3=+1
    apply_field( 0, 0, 0, 0, 1, 0, 0); chk_grad(  0, -1);   // F4=+1
    apply_field( 0, 0, 0, 0, 0, 1, 0); chk_grad(  1, -1);   // F5=+1  (ω⁵=+a−b)
    apply_field( 3, 0, 0,-3, 0, 0, 0); chk_grad(  6,  0);   // +a dipole: F0=+3,F3=-3
    apply_field( 2, 4,-1, 5,-3, 2, 0); chk_grad(  0,  4);   // mixed
    apply_field(-9, 0, 0, 9, 0, 0, 0); chk_grad(-18,  0);   // −a dipole
    apply_field( 0, 0, 0, 0, 0, 0, 0); chk_grad(  0,  0);   // zero field
    apply_field( 0, 0, 0, 0, 0, 0, 27); chk_grad( 0,  0);   // center is gauge (drops out)
    apply_field(27,27,27,27,27,27, 0); chk_grad( 0,  0);    // uniform field -> zero grad
    apply_field( 364, 0,-364,-364, 0, 364, 0); chk_grad(1456, -728); // full-range (8 trits)

    // ======================================================================
    // 2. Round trip (canonical gauge): TRECON(TGRAD(F)) = F.
    // ======================================================================
    $display("-- round trip (canonical gauge) --");
    apply_field(   1,   0, 0, 0, 0, 0, 0); chk_grad( 1, 0); chk_recon(  1,  0, 0,0,0,0, 0, 0);
    apply_field(   3,   9, 0, 0, 0, 0, 0); chk_grad( 3, 9); chk_recon(  3,  9, 0,0,0,0, 0, 0);
    apply_field( -27,  13, 0, 0, 0, 0, 0); chk_grad(-27,13); chk_recon(-27, 13, 0,0,0,0, 0, 0);
    apply_field( 100,-200, 0, 0, 0, 0, 0); chk_grad(100,-200); chk_recon(100,-200,0,0,0,0, 0, 0);
    apply_field( 364,-364, 0, 0, 0, 0, 0); chk_grad(364,-364); chk_recon(364,-364,0,0,0,0, 0, 0);

    // ======================================================================
    // 3. Gauge invariance (additive gauge / Σ(O−E)=0 conservation).
    // ======================================================================
    $display("-- gauge invariance (constant shift is invisible to ∇) --");
    apply_field( 3,-5, 2, 4,-1, 6,  0); chk_grad( 3, -8);   // base field
    apply_field(10, 2, 9,11, 6,13,  7); chk_grad( 3, -8);   // same field +7 (center +7 too)
    apply_field( 7, 7, 7, 7, 7, 7,  7); chk_grad( 0,  0);   // the constant shift itself -> 0

    // ======================================================================
    // 4. Gauge-invariant round trip on a general (non-canonical) field.
    // ======================================================================
    $display("-- gauge-invariant round trip (general field) --");
    apply_field( 3,-5, 2, 4,-1, 6, 0);
    chk_grad( 3, -8);                       // grad F = (3, −8)
    chk_recon( 3, -8, 0, 0, 0, 0, 0, 0);    // TRECON lands on canonical rep
    chk_roundtrip_identity;                 // grad(recon(grad F)) == grad F

    // ======================================================================
    // 5. TRECON direct: canonical section + ofit fit check.
    // ======================================================================
    $display("-- TRECON direct (canonical section + fit check) --");
    ddiv = enc8(  13); dcurl = enc8( -9); #1;
    if (dec(dnb_rec[0*12 +: 12],6) != 13 || dec(dnb_rec[1*12 +: 12],6) != -9 ||
        dec(dnb_rec[2*12 +: 12],6) != 0  || dec(dnb_rec[3*12 +: 12],6) != 0  ||
        dec(dnb_rec[4*12 +: 12],6) != 0  || dec(dnb_rec[5*12 +: 12],6) != 0  ||
        dec(dc_rec,6) != 0 || dofit !== 0) begin
      errors = errors + 1;
      $display("FAIL TRECON-direct: (13,-9,0,0,0,0) center=0 ofit=0");
    end else $display("OK   TRECON-direct: (13,-9,0,0,0,0) center=0 ofit=0");

    ddiv = enc8( 364); dcurl = enc8(-364); #1;
    if (dec(dnb_rec[0*12 +: 12],6) != 364 || dec(dnb_rec[1*12 +: 12],6) != -364 || dofit !== 0) begin
      errors = errors + 1;
      $display("FAIL TRECON-direct: (364,-364) fits 6 trits, ofit should be 0");
    end else $display("OK   TRECON-direct: (364,-364) fits 6 trits, ofit=0");

    ddiv = enc8( 365); dcurl = enc8( 0); #1;    // 365 needs trit 6 -> overflow
    if (dofit !== 1) begin
      errors = errors + 1;
      $display("FAIL TRECON-direct: div=365 should set ofit=1");
    end else $display("OK   TRECON-direct: div=365 -> ofit=1");

    ddiv = enc8(   0); dcurl = enc8( 1456); #1; // 1456 needs trit 6 -> overflow
    if (dofit !== 1) begin
      errors = errors + 1;
      $display("FAIL TRECON-direct: curl=1456 should set ofit=1");
    end else $display("OK   TRECON-direct: curl=1456 -> ofit=1");

    if (errors == 0)
      $display("ALL ASSERTIONS PASSED -- tgrad_cell + trecon_cell verified.");
    else
      $display("%0d ASSERTIONS FAILED", errors);
    $finish;
  end
endmodule
