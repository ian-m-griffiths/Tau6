// ============================================================================
// tau_field_tb.v — the first INTEGRATION test: compose the verified hex units into
// the field-calculus datapath (address -> memory -> compute), end to end.
//
//   hex_pod_addr (the isotropic lookup)  ->  7 flat addresses
//   hex_cell_store (a simple RAM)        ->  7 cell values  (F_k)
//   tgrad_cell (grad_recon.v)            ->  div, curl
//
// This is "TGRAD in hardware": given a center address, gather the 7-cell pod and
// compute the geometric derivative div/curl — the engine's actual workload, now as
// a composed datapath rather than three standalone modules.
//
// Verilog-2001; depends on rtl/hex_encode.v + rtl/hex_decode.v + rtl/hex_pod_addr.v
// + rtl/ternary_gates.v + rtl/grad_recon.v.
// ============================================================================
`timescale 1ns/1ps

module tau_field_tb;

  // ---- the hex cell store (a tiny RAM: flat u32 addr -> 24-bit cell word) ------
  reg [23:0] cells [0:63];
  integer i;

  // ---- the pod address generator ----------------------------------------------
  reg  [31:0] center;
  wire [223:0] pod;
  hex_pod_addr u_pod (.pod(pod), .center(center));

  // unpack the 7 pod addresses
  wire [31:0] p [0:6];
  genvar g;
  generate
    for (g = 0; g < 7; g = g + 1) begin : gen_p
      assign p[g] = pod[g*32 +: 32];
    end
  endgenerate

  // ---- gather the 7 cell values (F_k in angle order, tgrad convention) --------
  wire [11:0] F0 = cells[p[1]][11:0];
  wire [11:0] F1 = cells[p[2]][11:0];
  wire [11:0] F2 = cells[p[3]][11:0];
  wire [11:0] F3 = cells[p[4]][11:0];
  wire [11:0] F4 = cells[p[5]][11:0];
  wire [11:0] F5 = cells[p[6]][11:0];
  wire [11:0] cc = cells[p[0]][11:0];   // center value

  // ---- TGRAD: div/curl from the pod -------------------------------------------
  wire [15:0] div, curl;
  tgrad_cell #(.NTRITS(6)) u_tgrad (
    .div(div), .curl(curl),
    .c(cc),
    .nb({F5, F4, F3, F2, F1, F0}));

  integer errors;

  // balanced integer -> 6-trit 2-bit/trit field (matches cpu_ga_tb enc6)
  function [11:0] enc;
    input integer v;
    integer r, d, j;
    begin
      r = v; enc = 12'b0;
      for (j = 0; j < 6; j = j + 1) begin
        d = r % 3;
        if (d == 2) begin enc[j*2 +: 2] = 2'b10; r = (r + 1) / 3; end
        else if (d == -2) begin enc[j*2 +: 2] = 2'b01; r = (r - 1) / 3; end
        else begin
          if (d == 1) enc[j*2 +: 2] = 2'b01;
          else if (d == -1) enc[j*2 +: 2] = 2'b10;
          r = r / 3;
        end
      end
    end
  endfunction

  function integer dec;
    input [15:0] f;
    integer j, pv;
    begin
      dec = 0; pv = 1;
      for (j = 0; j < 8; j = j + 1) begin
        case (f[j*2 +: 2])
          2'b01: dec = dec + pv;
          2'b10: dec = dec - pv;
        endcase
        pv = pv * 3;
      end
    end
  endfunction

  initial begin
    errors = 0;
    for (i = 0; i < 64; i = i + 1) cells[i] = 24'b0;

    // load a field on the pod of cell (1,0)=addr 6: F0=+3 (cell (2,0)=addr 20), F1=+9 (cell (1,1)=addr 8)
    cells[6]  = enc(0);   // center (1,0) = 0
    cells[20] = enc(3);   // F0 = +3
    cells[8]  = enc(9);   // F1 = +9
    center = 32'd6;
    #1;
    $display("tau_field: TGRAD on pod(6) with F0=+3, F1=+9");
    $display("  div  = %0d  (expect 3)",  dec(div));
    $display("  curl = %0d  (expect 9)",  dec(curl));
    if (dec(div) !== 3 || dec(curl) !== 9) begin
      errors = errors + 1;
      $display("FAIL");
    end else
      $display("PASS — hex_pod_addr -> cell store -> tgrad_cell compose correctly.");

    // a second pod: uniform field -> zero gradient (the gauge)
    for (i = 0; i < 64; i = i + 1) cells[i] = enc(7);
    center = 32'd0;
    #1;
    if (dec(div) !== 0 || dec(curl) !== 0) begin
      errors = errors + 1; $display("FAIL: uniform field not zero gradient");
    end else
      $display("PASS — uniform field -> (div,curl)=(0,0) (the additive gauge).");

    if (errors == 0) $display("ALL ASSERTIONS PASSED — tau_field integration verified.");
    else $display("%0d FAILURES", errors);
    $finish;
  end

endmodule
