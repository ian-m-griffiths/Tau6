// ============================================================================
// trit_functions.vh — the balanced-ternary cell set, as a Verilog-2001 macro.
//
// Verilog-2001 has no cross-module functions: subroutines are module-local.
// The single source of truth for the per-trit logic is therefore this macro:
// expand it inside any module with
//
//     `include "rtl/trit_functions.vh"
//     `DEF_TERNARY_GATES
//
// and that module gets private copies of the six cells.  (This is the classic
// Verilog-2001 "header library" idiom; yosys keeps only the cells that are
// actually called and prunes the rest.)  NOTE: the macro body must stay free
// of /* */ comments — Icarus' preprocessor mishandles them inside continued
// macros.  All documentation lives here and in ternary_gates.v's header.
//
// TRIT ENCODING — 2 bits per trit, one-hot-per-direction:
//     2'b01 = +1   (push line energized)
//     2'b00 =  0   (null: nothing energized)
//     2'b10 = -1   (pull line energized)
//     2'b11 = both — NEVER produced (don't-care input, never an output)
//   See the header of rtl/ternary_gates.v for the Lean proof citations.
//
// CELLS:
//   tneg  [1:0] (t)            ternary invert (+1<->-1, 0->0): wire swap
//   tmul  [1:0] (a, b)         trit x trit sign product, null absorbs
//   tand  [1:0] (a, b)         min (lesser trit), ordering -1 < 0 < +1
//   tor   [1:0] (a, b)         max (greater trit)
//   tadd1 [3:0] (a, b, cin)    full-adder cell -> {cout, sum}, balanced carry
//                              rule: +1+1 = -1 carry +1; -1-1 = +1 carry -1
//
// tadd1 TRUTH TABLE (27 reachable (a,b,cin) triples, grouped by digit sum
// s = a+b+cin; the cell is implemented as the boolean equations on the right):
//   s = -3: (-1,-1,-1)                        -> sum 0,  cout -1
//   s = -2: (-1,-1,0) (-1,0,-1) (0,-1,-1)     -> sum +1, cout -1
//   s = -1: (-1,0,0) (0,-1,0) (0,0,-1)        -> sum -1, cout 0
//           (-1,-1,+1) (-1,+1,-1) (+1,-1,-1)
//   s =  0: (0,0,0) (-1,+1,0) (+1,-1,0)       -> sum 0,  cout 0
//           (-1,0,+1) (+1,0,-1) (0,-1,+1) (0,+1,-1)
//   s = +1: (+1,0,0) (0,+1,0) (0,0,+1)        -> sum +1, cout 0
//           (-1,+1,+1) (+1,-1,+1) (+1,+1,-1)
//   s = +2: (+1,+1,0) (+1,0,+1) (0,+1,+1)     -> sum -1, cout +1
//   s = +3: (+1,+1,+1)                        -> sum 0,  cout +1
// Boolean form (p = number of +1 inputs, n = number of -1 inputs):
//   cout +1 <=> s >= 2 <=> p >= 2 and n == 0
//   cout -1 <=> s <= -2 <=> n >= 2 and p == 0
//   sum +1  <=> s in {1, -2};  sum -1 <=> s in {-1, 2}
// (An earlier case-on-integer-sum version synthesised a 4-bit adder plus a
// comparator per cell; the boolean form is the naive gate-level cell.)
// ============================================================================

`ifndef TRIT_GATES_MACRO_DEF
`define TRIT_GATES_MACRO_DEF
`define DEF_TERNARY_GATES \
function [1:0] tneg; \
  input [1:0] t; \
  begin \
    tneg = {t[0], t[1]}; \
  end \
endfunction \
\
function [1:0] tmul; \
  input [1:0] a, b; \
  begin \
    tmul = 2'b00; \
    if (a[0] & b[0])                       tmul = 2'b01; \
    else if (a[1] & b[1])                  tmul = 2'b01; \
    else if (a[0] & b[1] | a[1] & b[0])    tmul = 2'b10; \
  end \
endfunction \
\
function [1:0] tand; \
  input [1:0] a, b; \
  begin \
    tand = {a[1] | b[1], a[0] & b[0]}; \
  end \
endfunction \
\
function [1:0] tor; \
  input [1:0] a, b; \
  begin \
    tor = {a[1] & b[1], a[0] | b[0]}; \
  end \
endfunction \
\
function [3:0] tadd1; \
  input [1:0] a, b, cin; \
  reg ap, bp, cp, an, bn, cn; \
  reg cop, con, sp, sn; \
  begin \
    ap = a[0]; an = a[1]; \
    bp = b[0]; bn = b[1]; \
    cp = cin[0]; cn = cin[1]; \
    cop = ~an & ~bn & ~cn & ((ap & bp) | (ap & cp) | (bp & cp)); \
    con = ~ap & ~bp & ~cp & ((an & bn) | (an & cn) | (bn & cn)); \
    sp = (ap & ~bp & ~bn & ~cp & ~cn) | (bp & ~ap & ~an & ~cp & ~cn) \
       | (cp & ~ap & ~an & ~bp & ~bn) \
       | (ap & bp & cn) | (ap & cp & bn) | (bp & cp & an) \
       | (~ap & ~bp & ~cp & ((an & bn & ~cn) | (an & cn & ~bn) \
                           | (bn & cn & ~an))); \
    sn = (an & ~bn & ~cn & ~ap & ~bp & ~cp) | (bn & ~an & ~cn & ~ap & ~bp & ~cp) \
       | (cn & ~an & ~bn & ~ap & ~bp & ~cp) \
       | (ap & bn & cn) | (bp & an & cn) | (cp & an & bn) \
       | (~an & ~bn & ~cn & ((ap & bp & ~cp) | (ap & cp & ~bp) \
                           | (bp & cp & ~ap))); \
    tadd1 = {con, cop, sn, sp}; \
  end \
endfunction
`endif
