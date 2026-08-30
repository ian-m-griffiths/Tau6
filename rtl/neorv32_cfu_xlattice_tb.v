// ============================================================================
// neorv32_cfu_xlattice_tb.v — testbench for the Xlattice CFU adapter, driving the
// EXACT NEORV32 CFU port (start/inst/rs1/rs2 -> result/valid).
// Assembles the GA instructions per xlattice_encoding.md and checks the results.
// ============================================================================
`timescale 1ns/1ps

module neorv32_cfu_xlattice_tb;

  reg         clk, rstn, start;
  reg  [31:0] inst, rs1, rs2;
  wire [31:0] result;
  wire        valid;
  neorv32_cfu_xlattice u_cfu (
    .clk_i(clk), .rstn_i(rstn), .start_i(start),
    .inst_i(inst), .rs1_i(rs1), .rs2_i(rs2),
    .result_o(result), .valid_o(valid));

  integer errors;

  // balanced integer -> 6-trit 2-bit/trit field
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
    input [11:0] f;
    integer j, p;
    begin
      dec = 0; p = 1;
      for (j = 0; j < 6; j = j + 1) begin
        case (f[j*2 +: 2])
          2'b01: dec = dec + p;
          2'b10: dec = dec - p;
        endcase
        p = p * 3;
      end
    end
  endfunction

  // assemble a custom-0 R-type word: {funct7, rs2, rs1, funct3, rd, opcode=0x0B}
  function [31:0] mk;
    input [6:0] f7; input [2:0] f3;
    begin
      mk = {f7, 5'd0, 5'd0, f3, 5'd0, 7'b0001011};   // rs2/rs1/rd = 0 (unused in tb)
    end
  endfunction

  task chk;
    input [255:0] msg;
    input [6:0] f7; input [2:0] f3;
    input integer za, zb, wa, wb;
    input integer exp_a;
    begin
      inst = mk(f7, f3);
      rs1 = {8'd0, enc(zb), enc(za)};   // low 24 bits = {b-field, a-field}
      rs2 = {8'd0, enc(wb), enc(wa)};
      start = 1'b1; #1;   // check WHILE start is asserted (valid_o = start_i, combinational)
      if (!valid || dec(result[11:0]) !== exp_a) begin
        errors = errors + 1;
        $display("FAIL: %0s  got %0d (valid=%b)  want %0d", msg, dec(result[11:0]), valid, exp_a);
      end else
        $display("PASS: %0s  = %0d", msg, dec(result[11:0]));
    end
  endtask

  always #5 clk = ~clk;

  initial begin
    clk = 0; rstn = 0; start = 0; inst = 0; rs1 = 0; rs2 = 0;
    errors = 0;
    #1 rstn = 1;
    // z = 2+3w, w = 1-2w  (from cpu_ga_tb / xlattice.py)
    chk("TDOT = -8",      7'b0000100, 3'b000, 2, 3, 1, -2, -8);
    chk("TWEDGE = 7",     7'b0000101, 3'b000, 2, 3, 1, -2,  7);
    chk("TSYMDOT = -9",   7'b0000110, 3'b000, 2, 3, 1, -2, -9);

    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — neorv32_cfu_xlattice verified (NEORV32 CFU port).");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
