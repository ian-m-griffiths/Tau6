// ============================================================================
// picorv32_pcpi_xlattice_tb.v — testbench for the Xlattice co-processor on the
// PicoRV32 PCPI port.  Drives pcpi_valid/insn/rs1/rs2 and checks pcpi_rd/ready.
// Assembles the GA instructions per xlattice_encoding.md; operands are 12-trit
// words in the low 24 bits of rs1/rs2.
// ============================================================================
`timescale 1ns/1ps

module picorv32_pcpi_xlattice_tb;

  reg         valid;
  reg  [31:0] insn, rs1, rs2;
  wire        wr, ready, w_wait;
  wire [31:0] rd;
  picorv32_pcpi_xlattice u_cpu (
    .pcpi_valid(valid), .pcpi_insn(insn), .pcpi_rs1(rs1), .pcpi_rs2(rs2),
    .pcpi_wr(wr), .pcpi_rd(rd), .pcpi_wait(w_wait), .pcpi_ready(ready));

  integer errors;

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

  // custom-0 R-type: {funct7, rs2, rs1, funct3, rd, 0x0B}
  function [31:0] mk;
    input [6:0] f7; input [2:0] f3;
    begin mk = {f7, 5'd0, 5'd0, f3, 5'd0, 7'b0001011}; end
  endfunction

  task chk;
    input [255:0] msg;
    input [6:0] f7; input [2:0] f3;
    input integer za, zb, wa, wb;
    input integer exp_a;
    begin
      insn = mk(f7, f3);
      rs1  = {8'd0, enc(zb), enc(za)};
      rs2  = {8'd0, enc(wb), enc(wa)};
      valid = 1'b1; #1;
      if (!ready || dec(rd[11:0]) !== exp_a) begin
        errors = errors + 1;
        $display("FAIL: %0s  got %0d (ready=%b)  want %0d", msg, dec(rd[11:0]), ready, exp_a);
      end else
        $display("PASS: %0s  = %0d", msg, dec(rd[11:0]));
      valid = 1'b0;
    end
  endtask

  initial begin
    valid = 0; insn = 0; rs1 = 0; rs2 = 0; errors = 0;
    // z = 2+3w, w = 1-2w
    chk("TDOT = -8",      7'b0000100, 3'b000, 2, 3, 1, -2, -8);
    chk("TWEDGE = 7",     7'b0000101, 3'b000, 2, 3, 1, -2,  7);
    chk("TSYMDOT = -9",   7'b0000110, 3'b000, 2, 3, 1, -2, -9);

    if (errors == 0) $display("ALL ASSERTIONS PASSED — picorv32_pcpi_xlattice verified (PCPI port).");
    else $display("%0d FAILURES", errors);
    $finish;
  end

endmodule
