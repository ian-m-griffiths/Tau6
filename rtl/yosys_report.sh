#!/usr/bin/env bash
# ============================================================================
# yosys_report.sh — honest area / cell-count / critical-path report for the
# ternary CPU (rtl/cpu.v + rtl/ternary_gates.v + rtl/trit_functions.vh).
#
# Flow:  read_verilog -> hierarchy -top cpu -> proc -> opt -> techmap -> abc
#        -> dfflibmap -> stat -liberty <lib>
#
# LIBERTY DISCOVERY (in order):
#   1. $LIBERTY env var
#   2. rtl/*.lib
#   3. ~/sky130*.lib, ~/skywater*.lib, ~/asap7*.lib, ~/osu*.lib
#   4. bundled /usr/share/yosys/cells.lib  -- NOTE: DFF-only (no combinational
#      cells, no area/timing/power), so it can NOT map the CPU's logic.
#
# WHAT THE REPORT GIVES YOU, HONESTLY:
#   * EXACT cell count + FF count + per-module breakdown  (always; `stat`)
#   * AREA + CRITICAL PATH (as a *topological proxy*): when no real PDK
#     liberty exists, a synthetic UNIT-DELAY model is generated: every gate
#     costs 1 area unit and 1.0 delay unit, so abc's reported "delay = N"
#     equals the critical path in gate levels, and "area = M" equals cell
#     count (FFs at 3 each).  NOT real um^2 / ns — real numbers need a PDK
#     liberty (e.g. SkyWater 130nm).
#   * POWER: this yosys 0.52 build's `stat` has NO -power option, and no
#     liberty with power data is installed, so power cannot be estimated at
#     all.  Once a real liberty exists, run:
#        yosys -p "...; stat -liberty ~/sky130.lib -power"
#     on a yosys build that supports it (or feed the mapped netlist to
#     OpenSTA / a power tool).
#
# NOTE ON THE PIPELINE IN THE TASK: `abc` then `stat -liberty <lib>` does NOT
# give area — plain `abc` maps to yosys' internal gate library, so every cell
# is "unknown" to the liberty.  The correct sequence (used here) is
# `abc -liberty <lib>` (map INTO the liberty) then `stat -liberty <lib>`.
#
# Run from anywhere:  bash rtl/yosys_report.sh
# (the script cd's to the PARENT lattice/ dir itself — yosys must be run from
#  there because the `` `include "rtl/..." `` paths are parent-relative)
# Output: rtl/yosys_report.txt (+ a summary on stdout).
# ============================================================================

set -euo pipefail

PROJ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJ"
RTL="rtl"
OUT="$RTL/yosys_report.txt"
TMPD="$(mktemp -d /tmp/yosys_report.XXXXXX)"
trap 'rm -rf "$TMPD"' EXIT

YOSYS="${YOSYS:-yosys}"
UNIT_LIB="$TMPD/unit_delay.lib"

# abc script: the yosys default for -liberty (no -constr) + print_stats, which
# makes abc print  area = ... delay = ... lev = ...  for the mapped network.
ABC_PS="+strash; &get -n; &fraig -x; &put; scorr; dc2; dretime; strash; &get -n; &dch -f; &nf; &put; print_stats"

READ_CMD="read_verilog $RTL/ternary_gates.v $RTL/tmul_opt.v $RTL/ga_ops.v $RTL/cpu.v $RTL/ternary_ff.v $RTL/ternary_mem.v"
# NOTE: trit_functions.vh is a MACRO header — it is pulled in automatically by
# the `` `include "rtl/trit_functions.vh" `` inside the .v files, so it must
# NOT be read_verilog'd directly.  The includes are relative to the PARENT
# (lattice/) dir, so yosys MUST run from there — hence the `cd "$PROJ"` above.
# Equivalent one-liner (verified):
#   cd /home/ian/dsh/projects/lattice && yosys -p \
#     "read_verilog rtl/ternary_gates.v rtl/tmul_opt.v rtl/cpu.v rtl/ternary_ff.v; \
#      hierarchy -top cpu; proc; opt; techmap; abc; stat"

# ---------------------------------------------------------------------------
# 1. Liberty discovery
# ---------------------------------------------------------------------------
find_real_lib() {
  local c
  for c in "${LIBERTY:-}" "$RTL"/*.lib "$HOME"/sky130*.lib "$HOME"/skywater*.lib \
           "$HOME"/asap7*.lib "$HOME"/osu*.lib; do
    [ -n "$c" ] && [ -f "$c" ] || continue
    # a usable (combinational) lib must define at least one output function
    # that is not just the FF state "IQ"; the bundled cells.lib is DFF-only.
    if awk '/function[ \t]*:/ { if ($0 !~ /IQ/) f=1 } END { exit !f }' "$c"; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

LIB=""
if REAL_LIB="$(find_real_lib)"; then
  LIB="$REAL_LIB"
  LIB_DESC="real liberty: $LIB"
else
  LIB_DESC="NO usable liberty found (bundled /usr/share/yosys/*.lib are DFF-only)"
fi

# ---------------------------------------------------------------------------
# 2. Synthetic UNIT-DELAY liberty (used only when no real lib exists)
# ---------------------------------------------------------------------------
gen_unit_lib() {
  local OUT="$1"
  {
    cat <<'EOF'
library(unit_delay) {
  cell(INV)   { area: 1; pin(A) { direction: input; }
    pin(Y) { direction: output; function: "!A"; rise_time: 1.0; fall_time: 1.0; } }
  cell(BUF)   { area: 1; pin(A) { direction: input; }
    pin(Y) { direction: output; function: "A"; rise_time: 1.0; fall_time: 1.0; } }
  cell(NAND2) { area: 1; pin(A) { direction: input; } pin(B) { direction: input; }
    pin(Y) { direction: output; function: "!(A&B)"; rise_time: 1.0; fall_time: 1.0; } }
  cell(NOR2)  { area: 1; pin(A) { direction: input; } pin(B) { direction: input; }
    pin(Y) { direction: output; function: "!(A|B)"; rise_time: 1.0; fall_time: 1.0; } }
  cell(AND2)  { area: 1; pin(A) { direction: input; } pin(B) { direction: input; }
    pin(Y) { direction: output; function: "A&B"; rise_time: 1.0; fall_time: 1.0; } }
  cell(OR2)   { area: 1; pin(A) { direction: input; } pin(B) { direction: input; }
    pin(Y) { direction: output; function: "A|B"; rise_time: 1.0; fall_time: 1.0; } }
  cell(XOR2)  { area: 2; pin(A) { direction: input; } pin(B) { direction: input; }
    pin(Y) { direction: output; function: "A^B"; rise_time: 1.0; fall_time: 1.0; } }
  cell(XNOR2) { area: 2; pin(A) { direction: input; } pin(B) { direction: input; }
    pin(Y) { direction: output; function: "!(A^B)"; rise_time: 1.0; fall_time: 1.0; } }
  cell(MUX2)  { area: 2; pin(A) { direction: input; } pin(B) { direction: input; } pin(S) { direction: input; }
    pin(Y) { direction: output; function: "(!S&A)|(S&B)"; rise_time: 1.0; fall_time: 1.0; } }
EOF
    # FF flavors: clk P->"C" / N->"!C"; rst P0=clear R, P1=preset R,
    # N0=clear !R, N1=preset !R; enable "-" / P="E" / N="!E"
    local clk rst en CK RS NAME ENAT ENABLE_PIN
    for clk in P N; do
      [ "$clk" = P ] && CK="C" || CK="!C"
      for rst in P0 P1 N0 N1; do
        case "$rst" in
          P0) RS='clear: "R";';  ;;
          P1) RS='preset: "R";'; ;;
          N0) RS='clear: "!R";'; ;;
          N1) RS='preset: "!R";'; ;;
        esac
        for en in - P N; do
          NAME="DFF_${clk}${rst}"
          ENAT=""
          ENABLE_PIN=""
          if [ "$en" = P ]; then
            NAME="DFFE_${clk}${rst}P"; ENAT='enable: "E";'
            ENABLE_PIN="    pin(E) { direction: input; }"
          elif [ "$en" = N ]; then
            NAME="DFFE_${clk}${rst}N"; ENAT='enable: "!E";'
            ENABLE_PIN="    pin(E) { direction: input; }"
          fi
          cat <<EOF
  cell($NAME) { area: 3;
    ff(IQ, IQN) { clocked_on: "$CK"; next_state: "D"; $RS $ENAT }
    pin(D) { direction: input; }
$ENABLE_PIN
    pin(R) { direction: input; }
    pin(C) { direction: input; clock: true; }
    pin(Q) { direction: output; function: "IQ"; rise_time: 1.0; fall_time: 1.0; } }
EOF
        done
      done
    done
    echo "}"
  } > "$OUT"
}

# ---------------------------------------------------------------------------
# 3. Run the synthesis and build the report
# ---------------------------------------------------------------------------
run_yosys() {   # run_yosys "<yosys commands>" "<section title>"
  local rc=0
  echo ""
  echo "======================================================================="
  echo "SECTION: $2"
  echo "-----------------------------------------------------------------------"
  $YOSYS -p "$1" 2>&1 || rc=$?
  echo "-----------------------------------------------------------------------"
  echo "(yosys exit code: $rc)"
  return 0
}

{
  echo "========================================================================="
  echo "TERNARY CPU SYNTHESIS REPORT  ($(date -u +%Y-%m-%dT%H:%MZ))"
  echo "yosys: $($YOSYS --version 2>&1 | head -1)"
  echo "design: $RTL/cpu.v (single-cycle, 12-trit words, 2 bits/trit encoding)"
  echo "liberty: $LIB_DESC"
  echo "========================================================================="

  if [ -n "$LIB" ]; then
    # ---- real liberty available: map into it, get area (+power cmd) ----
    run_yosys \
      "$READ_CMD; hierarchy -top cpu; proc; opt; flatten; techmap; abc -liberty $LIB; dfflibmap -liberty $LIB; stat -liberty $LIB" \
      "FLOW 1/2: abc -liberty <REAL LIB> + stat -liberty (real area)"
    echo ""
    echo "POWER: this yosys build ($($YOSYS --version 2>&1 | head -1)) rejects"
    echo "  'stat -power' (option not compiled in). With a liberty that carries"
    echo "  power data (e.g. sky130_fd_sc_hd) run, on a yosys that supports it:"
    echo "    yosys -p \"$READ_CMD; hierarchy -top cpu; proc; opt; flatten; techmap; abc -liberty $LIB; dfflibmap -liberty $LIB; stat -liberty $LIB -power\""
    echo "  (or export the mapped netlist and use OpenSTA/PowerScene.)"
  else
    # ---- no real lib: exact counts (plain abc) + unit-delay proxy ----
    echo ""
    echo "NOTE: no real PDK liberty is installed, so the numbers below are:"
    echo "  * EXACT cell/FF counts (from 'stat')"
    echo "  * AREA + CRITICAL PATH from a SYNTHETIC UNIT-DELAY model:"
    echo "    every gate = 1.0 area unit and 1.0 delay unit, so abc's"
    echo "    'area' ~= cell count and 'delay' = critical path in GATE LEVELS."
    echo "    Real um^2 / ns / frequency need a PDK liberty file."
    echo ""
    run_yosys \
      "$READ_CMD; hierarchy -top cpu; proc; opt; techmap; abc; stat" \
      "FLOW 1/3: plain abc + stat -- EXACT gate/FF counts (gate-count proxy)"
    gen_unit_lib "$UNIT_LIB"
    run_yosys \
      "$READ_CMD; hierarchy -top cpu; proc; opt; techmap; abc -liberty $UNIT_LIB -script \"$ABC_PS\"; dfflibmap -liberty $UNIT_LIB; stat -liberty $UNIT_LIB" \
      "FLOW 2/3: abc -liberty <unit-delay model> (non-flattened) -- per-submodule area/delay"
    run_yosys \
      "$READ_CMD; hierarchy -top cpu; proc; opt; flatten; techmap; abc -liberty $UNIT_LIB -script \"$ABC_PS\"; dfflibmap -liberty $UNIT_LIB; stat -liberty $UNIT_LIB" \
      "FLOW 3/3: abc -liberty <unit-delay model> (FLATTENED) -- true critical path"
    echo ""
    echo "POWER: NOT ESTIMATED -- no liberty with power data exists and this"
    echo "  yosys build ($($YOSYS --version 2>&1 | head -1)) lacks 'stat -power'."
    echo "  Once a real liberty (e.g. ~/sky130.lib) is provided, run:"
    echo "    yosys -p \"$READ_CMD; hierarchy -top cpu; proc; opt; flatten; techmap; abc -liberty ~/sky130.lib; dfflibmap -liberty ~/sky130.lib; stat -liberty ~/sky130.lib -power\""
    echo "  on a yosys with -power support (or export the netlist to OpenSTA)."
    echo ""
    echo "WHAT'S STILL NEEDED FOR REAL NUMBERS: a PDK liberty file"
    echo "  (e.g. SkyWater 130nm 'sky130_fd_sc_hd.lib' from the SKY130 PDK, or"
    echo "  ASAP7/OSU180) -- drop it into $RTL/ or set \$LIBERTY and rerun."
    echo "  With it you get: real area (um^2), per-gate timing arcs -> real"
    echo "  critical path in ns -> max clock frequency, and power."
  fi
  echo "========================================================================="
  echo "END OF REPORT"
} | tee "$OUT"

echo ""
echo "Report written to: $OUT"
