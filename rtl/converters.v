// ============================================================================
// converters.v — the binary <-> balanced-ternary NUMERIC bridge (radix conversion).
//
// These are the *logical* converters (the "DAC"/"ADC" in the numeric sense), as
// distinct from the *physical* 2-threshold receiver (the analog flash-ADC front
// end already measured in circuit/ENERGY_RESULTS.md at ~50 fJ/trit).
//
// In our one-hot-per-direction trit code (01=+1, 00=0, 10=-1, 11=NEVER), a trit
// is ALREADY two binary wires, so the physical ternary<->binary boundary is free;
// the only real cost is the RADIX conversion between a binary integer and the
// balanced-ternary digit string. These two modules are that cost.
//
// TRIT ENCODING (rtl/trit_functions.vh):
//     2'b01 = +1, 2'b00 = 0, 2'b10 = -1, 2'b11 = NEVER (don't-care input)
// ============================================================================

`timescale 1ns/1ps

// ----------------------------------------------------------------------------
// b2t: 9-bit two's-complement signed -> 6-trit balanced signed integer.
// MSB-first balanced digit extraction (verbatim algorithm from cpu.v `s2t6`):
//   digit i (weight 3^i) is +1 iff the residual exceeds (3^i-1)/2, -1 below its
//   negation, else 0; then subtract digit*3^i (a constant add/sub — no multiply).
//   The residual stays bounded at every step, so all arithmetic is tiny (the
//   naive r/3 + r%3 loop would synthesize 32-bit shift-subtract dividers).
// ============================================================================
module b2t (
  input  wire [8:0]  v,   // signed two's complement, [-256, +255]
  output reg  [11:0] t    // 6 trits, 2 bits each
);
  integer r;
  always @(*) begin
    r = $signed(v);
    t = 12'b0;
    // digit 5: weight 243, threshold (3^5-1)/2 = 121
    if (r > 121)        begin t[10 +: 2] = 2'b01; r = r - 243; end
    else if (r < -121)  begin t[10 +: 2] = 2'b10; r = r + 243; end
    // digit 4: weight 81, threshold 40
    if (r > 40)         begin t[8  +: 2] = 2'b01; r = r - 81;  end
    else if (r < -40)   begin t[8  +: 2] = 2'b10; r = r + 81;  end
    // digit 3: weight 27, threshold 13
    if (r > 13)         begin t[6  +: 2] = 2'b01; r = r - 27;  end
    else if (r < -13)   begin t[6  +: 2] = 2'b10; r = r + 27;  end
    // digit 2: weight 9, threshold 4
    if (r > 4)          begin t[4  +: 2] = 2'b01; r = r - 9;   end
    else if (r < -4)    begin t[4  +: 2] = 2'b10; r = r + 9;   end
    // digit 1: weight 3, threshold 1
    if (r > 1)          begin t[2  +: 2] = 2'b01; r = r - 3;   end
    else if (r < -1)    begin t[2  +: 2] = 2'b10; r = r + 3;   end
    // digit 0: weight 1; residual is now in {-1, 0, +1}
    if (r == 1)         t[0  +: 2] = 2'b01;
    else if (r == -1)   t[0  +: 2] = 2'b10;
  end
endmodule

// ----------------------------------------------------------------------------
// t2b: 6-trit balanced signed integer -> 10-bit two's-complement signed.
// value = sum d_i * 3^i (range [-364, +364]); Horner form MSB-first:
//   r = 3*r + d_i   (the *3 is a shift+add, no multiplier)
// The 2'b11 NEVER code is decoded as 0 (don't-care input, never produced).
// ============================================================================
module t2b (
  input  wire [11:0] t,      // 6 trits, 2 bits each
  output reg  [9:0]  v       // signed two's complement
);
  integer i;
  reg signed [11:0] r;
  reg signed [2:0]  d;
  always @(*) begin
    r = 0;
    for (i = 5; i >= 0; i = i - 1) begin
      case (t[i*2 +: 2])
        2'b01: d = 3'sd1;
        2'b10: d = -3'sd1;
        default: d = 3'sd0;   // 00 (null) and 11 (NEVER, don't-care)
      endcase
      r = (r << 1) + r + d;   // 3*r + d
    end
    v = r[9:0];
  end
endmodule
