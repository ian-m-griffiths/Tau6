#!/usr/bin/env bash
# ============================================================================
# word_fairfight.sh — WORD-LEVEL area benchmark: equal-information datapaths.
#
#   ternary 6 trits = 3^6 = 729 states  vs  binary 10 bits = 2^10 = 1024 states
#
# Synthesizes each word-level datapath IN ISOLATION (each is its own top
# module), maps it into the SkyWater 130nm high-density liberty with
# `abc -liberty`, and reports real area (um^2) + cell count — the exact flow of
# rtl/gate_area.sh.  It then normalizes area per STATE and per BIT:
#
#     states      = operand states        (3^6=729  |  2^10=1024)
#     state-pairs = states^2              (2 operands)
#     bits        = log2(state-pairs)     (total input information)
#     area/state  = area / state-pairs
#     area/bit    = area / log2(state-pairs)
#
# Datapaths:
#   wf_tadd6   — 6-trit ripple-carry adder (6 x tadd1)
#   wf_badd10  — 10-bit ripple-carry adder (10 x binary full adder)
#   wf_tmul6   — 6-trit multiplier (tmul_trits_opt, Karatsuba)
#   wf_tmul6_sa — 6-trit multiplier (tmul_sa, plain shift-add)  [bonus]
#   wf_bmul10  — 10-bit binary shift-add multiplier
#
# MUST run from lattice/ (not rtl/): the `include "rtl/..."` paths are
# parent-relative.  The script cd's there itself, so:
#     bash rtl/word_fairfight.sh
#
# Output: rtl/word_fairfight.txt (full log + parsed table + TSV)
#         + the summary table on stdout.
# ============================================================================

set -euo pipefail

PROJ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJ"
RTL="rtl"
OUT="$RTL/word_fairfight.txt"
CELLS="$RTL/word_fairfight_cells.v"
MULRTL="$RTL/tmul_opt.v"
TMPD="$(mktemp -d /tmp/word_fairfight.XXXXXX)"
trap 'rm -rf "$TMPD"' EXIT

YOSYS="${YOSYS:-yosys}"

# ---------------------------------------------------------------------------
# Liberty discovery (mirrors gate_area.sh / yosys_report.sh)
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
# Per-datapath synthesis + parse
# ---------------------------------------------------------------------------
# spec: module|nstates|human description
declare -a DATAPATHS=(
  "wf_tadd6|729|6-trit ripple-carry adder (6 x tadd1)"
  "wf_badd10|1024|10-bit ripple-carry adder (10 x binary FA)"
  "wf_tmul6|729|6-trit multiplier (tmul_trits_opt, Karatsuba)"
  "wf_tmul6_sa|729|6-trit multiplier (tmul_sa, plain shift-add)"
  "wf_bmul10|1024|10-bit binary shift-add multiplier"
)

synth_mod() {
  local mod="$1"
  $YOSYS -p "read_verilog $CELLS $MULRTL; hierarchy -top $mod; proc; opt; flatten; techmap; abc -liberty $LIB; stat -liberty $LIB" 2>&1
}

parse_stat() {
  local txt="$1" mod="$2"
  awk -v mod="$mod" '
    /Chip area for module/ { area=$NF; gsub(/[^0-9.]/,"",area); area=area+0 }
    /Number of cells:/ { cells=$NF }
    END { printf "%s\t%.6f\t%d\n", mod, area, cells }
  ' <<< "$txt"
}

# Normalization: given area + nstates, print state-pairs, bits, area/state, area/bit
normalize() {
  local area="$1" nstates="$2"
  awk -v area="$area" -v nstates="$nstates" '
    BEGIN {
      pairs = nstates * nstates;
      bits  = log(pairs) / log(2.0);
      printf "\t%d\t%.6f\t%.9f\t%.6f", pairs, bits, area/pairs, area/bits;
    }'
}

{
  echo "========================================================================="
  echo "WORD-LEVEL FAIR-FIGHT AREA BENCHMARK  ($(date -u +%Y-%m-%dT%H:%MZ))"
  echo "  6 trits (729 states)  vs  10 bits (1024 states)  — equal state count"
  echo "yosys: $($YOSYS --version 2>&1 | head -1)"
  echo "liberty: $LIB"
  echo "cells: $CELLS  (+ $MULRTL)"
  echo "========================================================================="
  echo ""
  echo "Normalization: state-pairs = states^2 (2 operands); bits = log2(state-pairs);"
  echo "  area/state = area / state-pairs;  area/bit = area / log2(state-pairs)."
  echo ""

  for spec in "${DATAPATHS[@]}"; do
    mod="${spec%%|*}"
    rest="${spec#*|}"
    nstates="${rest%%|*}"
    desc="${rest#*|}"

    echo ""
    echo "======================================================================="
    echo "DATAPATH: $mod  ($desc)"
    echo "-----------------------------------------------------------------------"
    log="$(synth_mod "$mod")"
    echo "$log" | sed -n '/Printing statistics/,$p'
    row="$(parse_stat "$log" "$mod")"
    area="$(awk -F'\t' '{print $2}' <<< "$row")"
    echo "-----------------------------------------------------------------------"
    printf 'ROW: %s%s\n' "$row" "$(normalize "$area" "$nstates")"
    printf '%s\t%s%s\n' "$row" "$nstates" "$(normalize "$area" "$nstates")" >> "$TMPD/rows.tsv"
  done

  echo ""
  echo "========================================================================="
  echo "END OF LOG"
} | tee "$OUT"

# ---------------------------------------------------------------------------
# Summary table (stdout + appended to log)
# ---------------------------------------------------------------------------
{
  echo ""
  echo "========================================================================="
  echo "SUMMARY — cells, area, area/state (per input state-pair), area/bit"
  echo "========================================================================="
  printf '%-14s %-8s %9s %11s %12s %10s %14s\n' \
    "datapath" "family" "cells" "area_um2" "state_pairs" "bits" "area_per_bit"
  while IFS=$'\t' read -r mod area cells nstates pairs bits aperstate aperbit; do
    case "$mod" in
      wf_tadd6)    fam="ternary";;
      wf_tmul6)    fam="ternary";;
      wf_tmul6_sa) fam="ternary";;
      wf_badd10)   fam="binary";;
      wf_bmul10)   fam="binary";;
      *)           fam="?";;
    esac
    printf '%-14s %-8s %9s %11.2f %12d %10.3f %14.6f\n' \
      "$mod" "$fam" "$cells" "$area" "$pairs" "$bits" "$aperbit"
    printf '      area/state = %.9f um2 per input state-pair\n' "$aperstate"
  done < "$TMPD/rows.tsv" | tee -a "$OUT"

  echo ""
  echo "Full log + TSV: $OUT"
  echo "Wrapper RTL:    $CELLS"
  echo "TSV columns: module  area_um2  cells  nstates  state_pairs  bits  area_per_state  area_per_bit"
}