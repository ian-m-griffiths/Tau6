#!/usr/bin/env bash
# run_all.sh -- run both energy experiments and print the .meas summaries.
# Requires ngspice:  sudo apt install ngspice
set -euo pipefail
cd "$(dirname "$0")"

for f in ternary_cell.cir binary_baseline.cir; do
  log="${f%.cir}.log"
  echo
  echo "==================== $f ===================="
  ngspice -b "$f" > "$log" 2>&1
  # ngspice prints .meas results as "name = value" lines near the end of
  # batch output (some versions wrap them in a table); show both.
  if grep -qE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=' "$log"; then
    grep -E '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=' "$log"
  else
    echo "(no 'name = value' lines found; tail of log:)"
    tail -n 40 "$log"
  fi
done

echo
echo "==================== verdict (criteria in README.md) ===================="
echo "ternary:   epush epull enull ecyc1 ecyc2 ecycT   (J)"
echo "binary:    ecycle erise efall                     (J, expect ecycle ~= CL*Vdd^2)"
echo "null-is-free:       enull ~= 0 ?"
echo "recycling:          ecyc2 < epull ?"
echo "polarity-saves:     (epush+epull+enull)/3 < ecycle/2 ?"
