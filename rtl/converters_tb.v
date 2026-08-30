// converters_tb.v — round-trip correctness sweep for b2t/t2b.
`timescale 1ns/1ps

module converters_tb;
  reg  [8:0] v;
  wire [11:0] t;
  wire [9:0]  vout;

  b2t u_b2t (.v(v), .t(t));
  t2b u_t2b (.t(t), .v(vout));

  integer i;
  reg fail;

  initial begin
    fail = 0;
    // exhaustive sweep over the full 9-bit signed range
    for (i = -256; i <= 255; i = i + 1) begin
      v = i[8:0];
      #1;
      if (vout[9:0] !== i[9:0]) begin
        $display("MISMATCH v=%0d -> t=%b -> vout=%0d", i, t, $signed(vout));
        fail = 1;
      end
    end
    if (fail) $display("FAIL");
    else $display("PASS: b2t/t2b round-trip exact over [-256,255]");
    $finish;
  end
endmodule
