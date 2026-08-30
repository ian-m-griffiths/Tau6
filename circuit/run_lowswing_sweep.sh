#!/bin/bash
# =====================================================================
# run_lowswing_sweep.sh -- external driver-rail sweep of lowswing_sweep.cir
# (this ngspice-44.2 build has NO .step, verified; the fair-fight harness
#  ran its 16x16 sweep the same way: generate per-point copies, run each).
#
# Two passes:
#   PASS 1 (mode=FAIR)  : VTD=0.4, WP=11u FIXED  -- the fair-fight driver
#                         (real CMOS, VTO=+/-0.4, KP 200u/100u), partial
#                         powering: same driver, lower rail. Honest "what
#                         happens if you just lower the bus rail".
#   PASS 2 (mode=VTENG) : VTD=0.1, WP resized ~ 1/Vov^2 -- VT-engineered
#                         driver. Real low-swing links need low-VT devices
#                         (SLVS transmitters use 0.15-0.25 V Vt); with the
#                         fair-fight VTO=0.4 driver the push dies below
#                         VDDR ~ 0.5 V (Vov <= 0), so pass 2 is the only
#                         way to reach the user's low-swing steps. The
#                         RECEIVER devices are IDENTICAL in both passes
#                         (only the driver models change). LEVEL=1 has no
#                         subthreshold leakage: pass 2 below ~0.1 V
#                         overdrive is flattered -- flagged in the report.
#
# Output: lowswing_sweep.log (concatenated per-point ngspice logs; each
# point's section starts with "Circuit: * LSWSWEEP vd=.. mode=..").
# =====================================================================
set -u
cd "$(dirname "$0")"

MASTER=lowswing_sweep.cir
LOG=lowswing_sweep.log
TMPD=$(mktemp -d /tmp/lsws_XXXX)
trap 'rm -rf "$TMPD"' EXIT

PASS1_VDDR="1.0 0.9 0.8 0.75 0.7 0.65 0.6 0.5 0.45 0.4 0.35 0.3 0.27 0.2 0.15 0.1 0.05"
PASS2_VDDR="0.6 0.5 0.45 0.4 0.35 0.3 0.27 0.25 0.2 0.15 0.1 0.05"

: > "$LOG"

run_point() {
    local mode=$1 vd=$2 vtd=$3 wp=$4
    local name="lsws_${mode}_${vd}"
    local banner="* LSWSWEEP vd=${vd} mode=${mode} vtd=${vtd} wp=${wp}"
    sed -e "1s/.*/$banner/" \
        -e "s/^.param VDDR = .*/\.param VDDR = ${vd}/" \
        -e "s/^.param VTD  = .*/\.param VTD  = ${vtd}/" \
        -e "s/^.param WP   = .*/\.param WP   = ${wp}/" \
        "$MASTER" > "$TMPD/$name.cir"
    echo "=== running mode=${mode} vd=${vd} vtd=${vtd} wp=${wp} ==="
    if ngspice -b "$TMPD/$name.cir" >> "$LOG" 2>&1; then
        echo "    ok"
    else
        echo "    ** FAILED (exit $?) -- see log **"
    fi
}

# ---------- PASS 1: fair-fight driver, fixed width, rail swept ----------
echo "### PASS 1: FAIR-FIGHT DRIVER (VTD=0.4, WP=11u fixed)" >> "$LOG"
for vd in $PASS1_VDDR; do
    run_point FAIR "$vd" 0.4 11u
done

# ---------- PASS 2: VT-engineered driver, width rescaled to keep drive ----
# WP(VDR) = 11u * (0.6/Vov)^2  (Vov = VDR - VTD): keeps ~1 mA-class push so
# the line actually tracks the rail. Below Vov~0 the driver is off with any
# width -> keep 11u, the measurement reports the dead-driver wall honestly.
echo "### PASS 2: VT-ENGINEERED DRIVER (VTD=0.1, WP resized ~1/Vov^2)" >> "$LOG"
for vd in $PASS2_VDDR; do
    vov=$(awk -v v="$vd" 'BEGIN{print v-0.1}')
    wp=$(awk -v v="$vov" 'BEGIN{ if (v>0.03) printf "%.1fu", 11*(0.6/v)^2; else print "11u" }')
    run_point VTENG "$vd" 0.1 "$wp"
done

echo "### done. log: $LOG"
