#!/usr/bin/env bash
# ============================================================================
# gate_area.sh — per-gate AREA + cell-count benchmark: ternary vs binary.
#
# Synthesizes each gate in rtl/gate_area_cells.v IN ISOLATION (each gate is its
# own top module, so nothing is constant-folded or merged), maps it into the
# SkyWater 130nm standard-cell liberty with `abc -liberty`, and reports the
# real area (um^2) and cell count per gate.
#
#   ternary gates:  tneg (NOT), tmin (MIN), tmax (MAX), tadd1 (mod-3 sum)
#   binary gates:   NOT, NAND, NOR  (+ badd1 binary full adder as the honest
#                   reference counterpart of the ternary full-adder cell)
#
# Flow (per gate): read_verilog -> hierarchy -top <gate> -> proc -> opt
#                  -> flatten -> techmap -> abc -liberty <lib> -> stat -liberty
#
# LIBERTY DISCOVERY (same order as yosys_report.sh):
#   1. $LIBERTY env var   2. rtl/*.lib   3. ~/sky130*.lib etc.
#
# MUST run from lattice/ (not rtl/): the `include "rtl/..."` paths are
# parent-relative.  The script cd's there itself, so:
#     bash rtl/gate_area.sh
#
# Output: rtl/gate_area.txt (full log + parsed per-gate table + a TSV block)
#         + the table on stdout.
# ============================================================================

set -euo pipefail

PROJ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJ"
RTL="rtl"
OUT="$RTL/gate_area.txt"
CELLS="$RTL/gate_area_cells.v"
TMPD="$(mktemp -d /tmp/gate_area.XXXXXX)"
trap 'rm -rf "$TMPD"' EXIT

YOSYS="${YOSYS:-yosys}"

# ---------------------------------------------------------------------------
# Liberty discovery (mirrors yosys_report.sh)
# ---------------------------------------------------------------------------
find_real_lib() {
  local c
  for c in "${LIBERTY:-}" "$RTL"/*.lib "$HOME"/sky130*.lib "$HOME"/skywater*.lib \
           "$HOME"/asap7*.lib "$HOME"/osu*.lib; do
    [ -n "$c" ] && [ -f "$c" ] || continue
    if awk '/function[ \t]*:/ { if ($0 !~ /IQ/) f=1 } END { exit !f }' "$c"; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

LIB="$(find_real_lib)" || { echo "FATAL: no usable (combinational) liberty found" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Per-gate synthesis + parse
# ---------------------------------------------------------------------------
# gate name -> (verilog module, human description, family)
#  family: "t" = ternary, "b" = binary
declare -a GATES=(
  "gate_tneg|tneg|ternary NOT (negation)|t"
  "gate_tmin|tmin|ternary MIN (meet)|t"
  "gate_tmax|tmax|ternary MAX (join)|t"
  "gate_tadd1|tadd1|ternary mod-3 sum (full adder)|t"
  "gate_not|not|binary NOT|b"
  "gate_nand2|nand2|binary NAND|b"
  "gate_nor2|nor2|binary NOR|b"
  "gate_badd1|badd1|binary full adder (reference)|b"
)

synth_gate() {
  local mod="$1"
  $YOSYS -p "read_verilog $CELLS; hierarchy -top $mod; proc; opt; flatten; techmap; abc -liberty $LIB; stat -liberty $LIB" 2>&1
}

# Parse the `stat -liberty` block for one module into tab-separated fields:
#   module | area | cells | cell:count,cell:count,...
parse_stat() {
  local txt="$1" mod="$2"
  awk -v mod="$mod" '
    /Chip area for module/ {
      # line: "   Chip area for module '\mod': <number>"
      area=$NF; gsub(/[^0-9.]/,"",area); area=area+0
    }
    /Number of cells:/ { cells=$NF }
    /sky130_fd_sc_hd__/ && NF==2 { cell=$1; cnt=$2; breakdown=breakdown cell ":" cnt "," }
    END {
      gsub(/,$/,"",breakdown)
      printf "%s\t%.6f\t%d\t%s\n", mod, area, cells, breakdown
    }
  ' <<< "$txt"
}

{
  echo "========================================================================="
  echo "GATE-LEVEL AREA BENCHMARK  ($(date -u +%Y-%m-%dT%H:%MZ))"
  echo "yosys: $($YOSYS --version 2>&1 | head -1)"
  echo "liberty: $LIB"
  echo "cells: $CELLS"
  echo "========================================================================="
  echo ""
  echo "TSV summary (module<TAB>area_um2<TAB>cell_count<TAB>cell_breakdown):"
  echo ""

  for spec in "${GATES[@]}"; do
    mod="${spec%%|*}"
    rest="${spec#*|}"
    label="${rest%%|*}"
    rest="${rest#*|}"
    desc="${rest%%|*}"

    echo ""
    echo "======================================================================="
    echo "GATE: $mod  ($label — $desc)"
    echo "-----------------------------------------------------------------------"
    log="$(synth_gate "$mod")"
    echo "$log" | sed -n '/Printing statistics/,$p'
    row="$(parse_stat "$log" "$mod")"
    echo "-----------------------------------------------------------------------"
    echo "ROW: $row"
    printf '%s\n' "$row" >> "$TMPD/rows.tsv"
  done

  echo ""
  echo "========================================================================="
  echo "END OF LOG"
} | tee "$OUT"

# ---------------------------------------------------------------------------
# Summary table (stdout + appended to log)
# ---------------------------------------------------------------------------
echo ""
echo "========================================================================="
echo "SUMMARY — per-gate area (um^2) and cell count"
echo "========================================================================="
printf '%-14s %-28s %10s %8s   %s\n' "gate" "function" "area_um2" "cells" "cells used"
while IFS=$'\t' read -r mod area cells breakdown; do
  # pretty name
  case "$mod" in
    gate_tneg)  nm="tneg";     fn="ternary NOT";;
    gate_tmin)  nm="tmin";     fn="ternary MIN";;
    gate_tmax)  nm="tmax";     fn="ternary MAX";;
    gate_tadd1) nm="tadd1";    fn="ternary sum";;
    gate_not)   nm="not";      fn="binary NOT";;
    gate_nand2) nm="nand2";    fn="binary NAND";;
    gate_nor2)  nm="nor2";     fn="binary NOR";;
    gate_badd1) nm="badd1";    fn="binary FADD";;
    *)          nm="$mod";     fn="";;
  esac
  printf '%-14s %-28s %10.4f %8s   %s\n' "$nm" "$fn" "$area" "$cells" "${breakdown//,/ }"
done < "$TMPD/rows.tsv" | tee -a "$OUT"

echo ""
echo "Full log + TSV: $OUT"
echo "Gate RTL:       $CELLS"
