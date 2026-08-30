// ============================================================================
// verify_tadd1.sv — formal specification for the tadd1 balanced-ternary full
// adder (rtl/trit_functions.vh), driven by SymbiYosys (verify_tadd1.sby).
//
// WHAT IS PROVED (mode prove, property-directed reachability / induction):
//   For ALL 27 reachable input rows (a, b, cin) in {+1, 0, -1}^3, encoded as
//   {neg,pos}: 2'b01 = +1, 2'b00 = 0, 2'b10 = -1, the cell output
//   {cout,sum} = tadd1(a,b,cin) equals the balanced-ternary digit addition
//   per the 27-row truth table in trit_functions.vh (header L32-47).
//
// DON'T-CARE HANDLING (the "forbidden 11 doubles as a free value" trick):
//   2'b11 (both lines energized) is NEVER produced by the CPU
//   (trit_functions.vh L21; Lean proof encode_never_both).  The spec is
//   written as an IMPLICATION  (!inputs_valid || spec)  so the property is
//   only required on the 27 valid rows: the solver may use the 37 invalid
//   rows (any input == 2'b11) as completely free values.  No assumption
//   cells are used, so every engine sees exactly the same problem.
//
// SPEC, IN TWO INDEPENDENT FORMS (both asserted):
//   (A) direct transcription of the 27-row table, boolean form (header L44-47)
//       with s = digit-sum(a,b,cin):
//           cout = +1  <=>  s >=  2
//           cout = -1  <=>  s <= -2
//           sum  = +1  <=>  s in {+1, -2}
//           sum  = -1  <=>  s in {-1, +2}
//   (B) the balanced-carry invariant       s == 3*cout + sum
//       (the definition of a balanced-ternary full adder).
//   A third assertion states the "11 never leaks" invariant on the reachable
//   rows (implied by (A), since no table row outputs 2'b11; stated explicitly
//   so the claim is visible to the proof).
//
// NON-VACUITY: every one of the 27 rows has an explicit `cover property`, so
// the cover task proves the implication's antecedent is satisfiable on each
// row and the assertion is not vacuously true.
// ============================================================================

`include "trit_functions.vh"

// DUT wrapper: expose the tadd1 macro function as a module.
// res = {cout_neg, cout_pos, sum_neg, sum_pos}  (same packing as the function).
module tadd1_wrapper (
  input  [1:0] a, b, cin,
  output [3:0] res
);
  `DEF_TERNARY_GATES
  assign res = tadd1(a, b, cin);
endmodule

module tadd1_verify (
  input  [1:0] a, b, cin,
  output [3:0] res
);
  tadd1_wrapper dut (.a(a), .b(b), .cin(cin), .res(res));

  // ----- 2'b11 inputs are never produced -> don't-care (free) -----
  wire inputs_valid = (a != 2'b11) && (b != 2'b11) && (cin != 2'b11);

  // ----- digit values: bit0 = pos (+1), bit1 = neg (-1) -----
  int va, vb, vc, s;
  always_comb begin
    va = a[0] ?  1 : (a[1] ? -1 : 0);
    vb = b[0] ?  1 : (b[1] ? -1 : 0);
    vc = cin[0] ? 1 : (cin[1] ? -1 : 0);
    s  = va + vb + vc;                    // balanced digit sum in [-3, +3]
  end

  // ----- Spec (A): the 27-row truth table, boolean form -----
  logic cop_exp, con_exp, sp_exp, sn_exp;
  always_comb begin
    cop_exp = (s >=  2);                  // cout = +1
    con_exp = (s <= -2);                  // cout = -1
    sp_exp  = (s ==  1) || (s == -2);     // sum  = +1
    sn_exp  = (s == -1) || (s ==  2);     // sum  = -1
  end
  wire [3:0] exp_res = {con_exp, cop_exp, sn_exp, sp_exp};

  // ----- Spec (B): balanced-carry invariant  s == 3*cout + sum -----
  int cout_val, sum_val;
  always_comb begin
    cout_val = cop_exp ?  1 : (con_exp ? -1 : 0);
    sum_val  = sp_exp  ?  1 : (sn_exp  ? -1 : 0);
  end

  // ================= assertions (only required on the 27 valid rows) ========
  assert property (!inputs_valid || (res == exp_res));                       // (A)
  assert property (!inputs_valid || (s == 3*cout_val + sum_val));            // (B)
  // forbidden state 2'b11 never leaks into sum or carry on any valid row:
  assert property (!inputs_valid || ((res[1:0] != 2'b11) && (res[3:2] != 2'b11)));

  // ================= non-vacuity: cover all 27 rows explicitly ==============
  genvar g;
  generate
    for (g = 0; g < 27; g = g + 1) begin : gcov
      // decode g into three trits over {2'b00, 2'b01, 2'b10}
      localparam [1:0] ta = (g % 3 == 0) ? 2'b00 : (g % 3 == 1) ? 2'b01 : 2'b10;
      localparam [1:0] tb = ((g / 3) % 3 == 0) ? 2'b00 : ((g / 3) % 3 == 1) ? 2'b01 : 2'b10;
      localparam [1:0] tc = ((g / 9) == 0) ? 2'b00 : ((g / 9) == 1) ? 2'b01 : 2'b10;
      cover property (a == ta && b == tb && cin == tc);
    end
  endgenerate
endmodule
