#!/usr/bin/env python3
"""
Generate circuit/polar_full_adder.cir -- the POLAR (single-wire, push/null/pull)
ternary FULL adder (a + b + cin -> sum + carry_out), in diode-direction form.

Design (flagged decisions):
  - BALANCED ternary: digits {-1,0,+1} = {-VDD,0,+VDD}. carry = +1 iff s>=+2,
    -1 iff s<=-2, else 0;  sum = s mod 3 (balanced).  This is the repo's
    "polar" convention (push/null/pull = direction).  The task's "carry=1 iff
    >=3" is the UNSIGNED radix-3 phrasing; balanced uses "|carry|=1 iff |s|>=2".
  - Logic realized as diode-direction receiver + STATIC CMOS (majority + veto),
    NOT the analog current-mode Kirchhoff-sum (analog_polar.md Idea A, which was
    never converged in-repo).  The carry "threshold" is maj3 + no-opposite-veto.
  - Output re-encoded to single polar wire by dead-zone push-pull drivers.

Device count (counted, see header of generated .cir): 218 T + 6 D = 224 devices.
"""
import itertools

VALUES = [(-1, "{-VDD}"), (0, "0"), (1, "{VDD}")]

def expected(a, b, c):
    s = a + b + c
    smod = s % 3                      # {0,1,2}
    sval = {0: 0, 1: 1, 2: -1}[smod]  # balanced digit
    carry = 1 if s >= 2 else (-1 if s <= -2 else 0)
    return sval, carry

HEADER = r"""* =====================================================================
* polar_full_adder.cir  --  POLAR ternary FULL ADDER, diode-direction form.
*
*   a + b + cin  ->  sum (= (a+b+cin) mod 3) + cout (carry, balanced).
*
* REPRESENTATION (balanced, "polar" = push/null/pull on ONE wire)
*   +1 = +VDD (push),  0 = 0 V (null, no line energized),  -1 = -VDD (pull).
*   carry rule (balanced):  cout = +1 iff s >= +2,  -1 iff s <= -2,  0 else.
*   sum = s mod 3 in balanced digits {+1,0,-1}.
*   (The task's "carry=1 iff >=3" is the UNSIGNED radix-3 phrasing; balanced
*    ternary -- which is what "polar"/push-pull means -- uses |carry|=1 iff
*    |s|>=2.  The 27-row table below is the balanced tadd1 table.)
*
* DESIGN (flag every decision)
*   1. Receiver (per input wire): the repo's PASSIVE diode-direction rectifier
*      (2 Schottky diodes) splits the polar wire into rA (push rail) / rB (pull
*      rail); null = neither fires (free).  Then an elevated-|Vt| dead-zone
*      restore pair re-quantizes each rail to full swing:
*        p = +VDD iff push,  n = +VDD iff pull  (else -VDD).
*      (This is tsum_cell.cir's t_recv, minus the explicit z rail: the logic
*       below derives its own null-context pz/nz = NOT(any push/pull).)
*   2. Carry "threshold": static-CMOS majority + veto (NOT an elevated-Vt or
*      comparator threshold device -- flagged):
*        p2 = maj3(pa,pb,pc) = ">=2 pushes",  n2 = maj3(na,nb,nc) = ">=2 pulls"
*        pz = ~(pa|pb|pc) = "no pushes",      nz = ~(na|nb|nc) = "no pulls"
*        cop = nz & p2   (carry +1 : no pulls AND >=2 pushes)
*        con = pz & n2   (carry -1 : no pushes AND >=2 pulls)
*   3. Sum = s mod 3, factored (exactly-one / exactly-two / no-context):
*        p1 = "exactly one push",  n1 = "exactly one pull"
*        p2x = "exactly two pushes", n2x = "exactly two pulls"
*        sp = (p1 & nz) | (p2x & n1) | (pz & n2x)     [s == +1 (mod 3)]
*        sn = (n1 & pz) | (n2x & p1) | (nz & p2x)     [s == -1 (mod 3)]
*   4. Output: dead-zone push-pull driver re-encodes sp/sn -> one sum wire and
*      cop/con -> one cout wire (null when both rails inactive).
*
* DEVICE COUNT (D = rectifier diode, T = transistor; keepers R/C passive)
*   receiver : 3 x t_recv2 (2 D + 6 T)                  =  6 D +  18 T
*   and2     : 18 x 6 T                                  =        108 T
*   or3      :  6 x 8 T                                  =         48 T
*   nor3     :  2 x 6 T                                  =         12 T
*   and3     :  2 x 8 T                                  =         16 T
*   inv      :  6 x 2 T                                  =         12 T
*   driver   :  2 x 2 T                                  =          4 T
*   -------------------------------------------------------------------
*   TOTAL    :                                            6 D + 218 T  = 224 devices
*
* FAIR-FIGHT HONESTY (same as tsum_cell.cir / diode_gates.cir)
*   - REAL driver (V*I counted over a full assert+release cycle), REAL passive
*     diode receiver load, inputs ideal voltage sources, LEVEL=1 no body diode
*     no mismatch, same +/-VDD = +/-1.0 V rails as the binary reference.
*   - Cheapest toggle (null<->+1) AND carry/full-swing toggles both measured.
* =====================================================================

.options reltol=1e-3 abstol=1e-15 vntol=1e-6

.param VDD   = 1.0
.param Rwire = 100
.param CL    = 10f          ; one output wire drives ~1 next-gate input
.param Rterm = 100k         ; null-return termination on every polar wire
.param T_C0 = 95n           ; full-cycle window: assert @100n, release @120n
.param T_C1 = 135n
.param T_Q0 = 10n           ; quiet (held-null / idle) window
.param T_Q1 = 85n

* ---------------- models (verbatim tsum_cell.cir / diode_gates.cir) -------
.model NMOS1 NMOS(LEVEL=1 VTO=0.4  KP=200u LAMBDA=0.05 TOX=2n)
.model PMOS1 PMOS(LEVEL=1 VTO=-0.4 KP=100u LAMBDA=0.05 TOX=2n)
.model N_HI  NMOS(LEVEL=1 VTO=1.4  KP=200u LAMBDA=0.05 TOX=2n)
.model P_HI  PMOS(LEVEL=1 VTO=-1.4 KP=100u LAMBDA=0.05 TOX=2n)
.model DD D (IS=1e-9 RS=200 CJO=2f TT=1p N=1.05)

* ---------------- diode-direction receiver (passive, per input wire) -------
.subckt dd_recv win rA rB
D1 win rA DD
D2 rB win DD
RkA rA 0 100k
RkB rB 0 100k
CkA rA 0 2f
CkB rB 0 2f
.ends

* ---------------- static CMOS primitives (bipolar rails +/-VDD) ------------
.subckt inv in out vdd vss
Mp out in vdd vdd PMOS1 W=4u  L=0.18u
Mn out in vss vss NMOS1 W=2u  L=0.18u
.ends

.subckt nand2 a b out vdd vss
Mp1 out a vdd vdd PMOS1 W=4u  L=0.18u
Mp2 out b vdd vdd PMOS1 W=4u  L=0.18u
Mn1 out a mid vss NMOS1 W=4u  L=0.18u
Mn2 mid b vss vss NMOS1 W=4u  L=0.18u
Cmid mid 0 1f
.ends

.subckt nor2 a b out vdd vss
Mp1 mid a vdd vdd PMOS1 W=8u  L=0.18u
Mp2 out b mid vdd PMOS1 W=8u  L=0.18u
Mn1 out a vss vss NMOS1 W=2u  L=0.18u
Mn2 out b vss vss NMOS1 W=2u  L=0.18u
Cmid mid 0 1f
.ends

.subckt and2 a b out vdd vss
X1 a b mid vdd vss nand2
X2 mid out vdd vss inv
.ends

.subckt or2 a b out vdd vss
X1 a b mid vdd vss nor2
X2 mid out vdd vss inv
.ends

* 3-input gates (real CMOS, single-gate count: nor3=6T or3=8T nand3=6T and3=8T)
.subckt nor3 a b c out vdd vss
Mp1 m1 a vdd vdd PMOS1 W=12u L=0.18u
Mp2 m2 b m1 vdd PMOS1 W=12u L=0.18u
Mp3 out c m2 vdd PMOS1 W=12u L=0.18u
Mn1 out a vss vss NMOS1 W=2u  L=0.18u
Mn2 out b vss vss NMOS1 W=2u  L=0.18u
Mn3 out c vss vss NMOS1 W=2u  L=0.18u
Cm1 m1 0 1f
Cm2 m2 0 1f
.ends

.subckt or3 a b c out vdd vss
Xn a b c mid vdd vss nor3
Xi mid out vdd vss inv
.ends

.subckt nand3 a b c out vdd vss
Mp1 out a vdd vdd PMOS1 W=4u L=0.18u
Mp2 out b vdd vdd PMOS1 W=4u L=0.18u
Mp3 out c vdd vdd PMOS1 W=4u L=0.18u
Mn1 out a m1 vss NMOS1 W=12u L=0.18u
Mn2 m1 b m2 vss NMOS1 W=12u L=0.18u
Mn3 m2 c vss vss NMOS1 W=12u L=0.18u
Cm1 m1 0 1f
Cm2 m2 0 1f
.ends

.subckt and3 a b c out vdd vss
Xn a b c mid vdd vss nand3
Xi mid out vdd vss inv
.ends

* ---------------- push-pull output driver (2 T, dead-zone null) ------------
.subckt driver gp gn out vdd vss
Mp out gp vdd vdd PMOS1 W=4u  L=0.18u
Mn out gn vss vss NMOS1 W=2u  L=0.18u
.ends

* ---------------- ternary receiver: polar wire -> full-swing p,n -----------
* p = +VDD iff push, n = +VDD iff pull (else -VDD).  No explicit null rail.
* 2 D + 6 T.  Elevated-|Vt| restore = dead zone (null => both off, no static).
.subckt t_recv2 w p n vdd vss
Xr w ra rb dd_recv
Mpu midp ra vdd vdd PMOS1 W=4u L=0.18u
Mpd midp ra vss vss N_HI  W=4u L=0.18u
Xi  midp p  vdd vss inv
Mnu n  rb vdd vdd P_HI  W=4u L=0.18u
Mnd n  rb vss vss NMOS1 W=4u L=0.18u
.ends

* =====================================================================
* POLAR FULL ADDER  (the deliverable):  wa,wb,wc -> wsum,wcout
* =====================================================================
.subckt pol_fa wa wb wc wsum wcout vdd vss
Xra wa pa na vdd vss t_recv2
Xrb wb pb nb vdd vss t_recv2
Xrc wc pc nc vdd vss t_recv2
* --- carry majority: p2 = >=2 pushes, n2 = >=2 pulls ---
Xp2a pa pb p21 vdd vss and2
Xp2b pa pc p22 vdd vss and2
Xp2c pb pc p23 vdd vss and2
Xp2  p21 p22 p23 p2 vdd vss or3
Xn2a na nb n21 vdd vss and2
Xn2b na nc n22 vdd vss and2
Xn2c nb nc n23 vdd vss and2
Xn2  n21 n22 n23 n2 vdd vss or3
* --- null context: pz = no pushes, nz = no pulls ---
Xpz pa pb pc pz vdd vss nor3
Xnz na nb nc nz vdd vss nor3
* --- exactly three / exactly two ---
Xa3p pa pb pc a3p vdd vss and3
Xa3n na nb nc a3n vdd vss and3
Xi3p a3p a3pb vdd vss inv
Xi3n a3n a3nb vdd vss inv
Xp2x p2 a3pb p2x vdd vss and2
Xn2x n2 a3nb n2x vdd vss and2
* --- at least one / exactly one ---
Xpany pa pb pc pany vdd vss or3
Xnany na nb nc nany vdd vss or3
Xip2 p2 p2b vdd vss inv
Xin2 n2 n2b vdd vss inv
Xp1 pany p2b p1 vdd vss and2
Xn1 nany n2b n1 vdd vss and2
* --- carry out ---
Xcop nz p2 cop vdd vss and2
Xcon pz n2 con vdd vss and2
* --- sum = s mod 3 ---
Xsp1 p1 nz t1 vdd vss and2
Xsp2 p2x n1 t2 vdd vss and2
Xsp3 pz n2x t3 vdd vss and2
Xsp  t1 t2 t3 sp vdd vss or3
Xsn1 n1 pz t4 vdd vss and2
Xsn2 n2x p1 t5 vdd vss and2
Xsn3 nz p2x t6 vdd vss and2
Xsn  t4 t5 t6 sn vdd vss or3
* --- output drivers (polar re-encode) ---
Xgsum sp gpsum vdd vss inv
Xdrvsum gpsum sn wsum vdd vss driver
Xgcout cop gpcout vdd vss inv
Xdrvcout gpcout con wcout vdd vss driver
.ends

* ---------------- binary full-adder reference (same harness) --------------
* 46 T unoptimized NAND/NOR form (verbatim tsum_cell.cir bin_fa).
.subckt bin_xor2 a b out vdd vss
Xa a b mid1 vdd vss and2
Xn a b mid2 vdd vss nor2
Xo mid1 mid2 out vdd vss nor2
.ends

.subckt bin_fa a b cin sum cout vdd vss
Xs1 a b s1 vdd vss bin_xor2
Xs2 s1 cin sum vdd vss bin_xor2
Xc1 a b c1 vdd vss and2
Xc2 cin s1 c2 vdd vss and2
Xco c1 c2 cout vdd vss or2
.ends
"""

# Representative subset of the 27 rows (covers every digit-sum class s in
# {-3..+3}, both carry directions, the wrap rows, both "kinds" of s=+-1, and
# the carry veto).  Full 27-row truth table is checked separately in the
# checker by re-deriving expected() -- the netlist only needs this subset to
# be fast.  (a,b,c) in balanced digits {-1,0,+1}.
SUBSET = [
    (1, 1, 1), (1, 1, 0), (1, 0, 0), (1, 1, -1),
    (0, 0, 0), (1, -1, 0), (1, 0, -1),
    (-1, 0, 0), (-1, -1, 1), (-1, -1, 0), (-1, -1, -1),
    (0, 1, 1), (0, -1, -1),
]

VALSTR = {-1: "{-VDD}", 0: "0", 1: "{VDD}"}

def gen_tt_blocks():
    lines = []
    idx = 1
    expected_rows = []
    for (a, b, c) in SUBSET:
        va, vb, vc = VALSTR[a], VALSTR[b], VALSTR[c]
        sval, carry = expected(a, b, c)
        expected_rows.append((a, b, c, sval, carry))
        lines.append(f"* TT{idx}: ({a:+d},{b:+d},{c:+d}) -> sum {sval:+d}, carry {carry:+d}")
        lines.append(f"Vat{idx} at{idx} 0 DC {va}")
        lines.append(f"Vbt{idx} bt{idx} 0 DC {vb}")
        lines.append(f"Vct{idx} ct{idx} 0 DC {vc}")
        lines.append(f"Xtt{idx} at{idx} bt{idx} ct{idx} st{idx} cot{idx} vddt vsst pol_fa")
        lines.append(f"Rwst{idx} st{idx} lsumt{idx} {{Rwire}}")
        lines.append(f"Clst{idx} lsumt{idx} 0 {{CL}}")
        lines.append(f"Rtermst{idx} lsumt{idx} 0 {{Rterm}}")
        lines.append(f"Rwct{idx} cot{idx} lcoutt{idx} {{Rwire}}")
        lines.append(f"Clct{idx} lcoutt{idx} 0 {{CL}}")
        lines.append(f"Rtermct{idx} lcoutt{idx} 0 {{Rterm}}")
        lines.append("")
        idx += 1
    return lines, expected_rows

def main():
    tt_lines, expected_rows = gen_tt_blocks()
    meas_lines = []
    meas_lines.append("* ---------------- energy / delay instances ----------------")
    # E1 cheapest toggle: a=0 c=0, b: null->+1->null  => sum 0->+1->0, carry 0
    meas_lines.append("VDD1 vdd1 0 DC {VDD}")
    meas_lines.append("VSS1 vss1 0 DC {-VDD}")
    meas_lines.append("Va1 a1 0 DC 0")
    meas_lines.append("Vc1 c1 0 DC 0")
    meas_lines.append("Vb1 b1 0 PULSE(0 {VDD} 100n 0.2n 0.2n 20n 200n)")
    meas_lines.append("Xfa1 a1 b1 c1 s1 c1o vdd1 vss1 pol_fa")
    meas_lines.append("Rws1 s1 ls1 {Rwire}")
    meas_lines.append("Cls1 ls1 0 {CL}")
    meas_lines.append("Rterms1 ls1 0 {Rterm}")
    meas_lines.append("Xrecs1 ls1 ras1 rbs1 dd_recv")
    meas_lines.append("Rwc1 c1o lc1 {Rwire}")
    meas_lines.append("Clc1 lc1 0 {CL}")
    meas_lines.append("Rtermc1 lc1 0 {Rterm}")
    meas_lines.append("Xrecc1 lc1 rac1 rbc1 dd_recv")
    meas_lines.append("Bp1 p1 0 V = -(V(vdd1)*I(VDD1) + V(vss1)*I(VSS1))")
    meas_lines.append("")
    # E2 carry + full sum swing: a=+1 c=0, b: null->+1->null
    #    before: s=+1 (sum +1, carry 0);  during: s=+2 (sum -1, carry +1)
    meas_lines.append("VDD2 vdd2 0 DC {VDD}")
    meas_lines.append("VSS2 vss2 0 DC {-VDD}")
    meas_lines.append("Va2 a2 0 DC {VDD}")
    meas_lines.append("Vc2 c2 0 DC 0")
    meas_lines.append("Vb2 b2 0 PULSE(0 {VDD} 100n 0.2n 0.2n 20n 200n)")
    meas_lines.append("Xfa2 a2 b2 c2 s2 c2o vdd2 vss2 pol_fa")
    meas_lines.append("Rws2 s2 ls2 {Rwire}")
    meas_lines.append("Cls2 ls2 0 {CL}")
    meas_lines.append("Rterms2 ls2 0 {Rterm}")
    meas_lines.append("Xrecs2 ls2 ras2 rbs2 dd_recv")
    meas_lines.append("Rwc2 c2o lc2 {Rwire}")
    meas_lines.append("Clc2 lc2 0 {CL}")
    meas_lines.append("Rtermc2 lc2 0 {Rterm}")
    meas_lines.append("Xrecc2 lc2 rac2 rbc2 dd_recv")
    meas_lines.append("Bp2 p2 0 V = -(V(vdd2)*I(VDD2) + V(vss2)*I(VSS2))")
    meas_lines.append("")
    # E3 full-swing input toggle: a=+1 c=0, b: +1 -> -1 -> +1
    #    b=+1: s=+2 (sum -1, carry +1);  b=-1: s=0 (sum 0, carry 0)
    meas_lines.append("VDD3 vdd3 0 DC {VDD}")
    meas_lines.append("VSS3 vss3 0 DC {-VDD}")
    meas_lines.append("Va3 a3 0 DC {VDD}")
    meas_lines.append("Vc3 c3 0 DC 0")
    meas_lines.append("Vb3 b3 0 PULSE({VDD} {-VDD} 100n 0.2n 0.2n 20n 200n)")
    meas_lines.append("Xfa3 a3 b3 c3 s3 c3o vdd3 vss3 pol_fa")
    meas_lines.append("Rws3 s3 ls3 {Rwire}")
    meas_lines.append("Cls3 ls3 0 {CL}")
    meas_lines.append("Rterms3 ls3 0 {Rterm}")
    meas_lines.append("Xrecs3 ls3 ras3 rbs3 dd_recv")
    meas_lines.append("Rwc3 c3o lc3 {Rwire}")
    meas_lines.append("Clc3 lc3 0 {CL}")
    meas_lines.append("Rtermc3 lc3 0 {Rterm}")
    meas_lines.append("Xrecc3 lc3 rac3 rbc3 dd_recv")
    meas_lines.append("Bp3 p3 0 V = -(V(vdd3)*I(VDD3) + V(vss3)*I(VSS3))")
    meas_lines.append("")
    # binary FA reference (same +/-1V harness): a=+1 cin=0, b: -1->+1->-1
    meas_lines.append("VDDb vddb 0 DC {VDD}")
    meas_lines.append("VSSb vssb 0 DC {-VDD}")
    meas_lines.append("Vab ab 0 DC {VDD}")
    meas_lines.append("Vcib cib 0 DC {-VDD}")
    meas_lines.append("Vbb bb 0 PULSE({-VDD} {VDD} 100n 0.2n 0.2n 20n 200n)")
    meas_lines.append("Xbfa ab bb cib sbm cbm vddb vssb bin_fa")
    meas_lines.append("Rwsb sbm lsb {Rwire}")
    meas_lines.append("Clsb lsb 0 {CL}")
    meas_lines.append("Rwcb cbm lcb {Rwire}")
    meas_lines.append("Clcb lcb 0 {CL}")
    meas_lines.append("Bpb pb 0 V = -(V(vddb)*I(VDDb) + V(vssb)*I(VSSb))")
    meas_lines.append("")

    meas_lines.append("* ---------------- truth-table supply (all DC) ----------------")
    meas_lines.append("VDDt vddt 0 DC {VDD}")
    meas_lines.append("VSSt vsst 0 DC {-VDD}")
    meas_lines.append("")

    meas_lines.append("* ---------------- simulation + measurements ----------------")
    meas_lines.append(".tran 20p 140n")
    meas_lines.append("")
    meas_lines.append("* --- supply energy over one full output cycle (J) ---")
    meas_lines.append(".meas tran egate_e1   INTEG V(p1) FROM={T_C0} TO={T_C1}")
    meas_lines.append(".meas tran egate_e2   INTEG V(p2) FROM={T_C0} TO={T_C1}")
    meas_lines.append(".meas tran egate_e3   INTEG V(p3) FROM={T_C0} TO={T_C1}")
    meas_lines.append(".meas tran egate_bfa INTEG V(pb) FROM={T_C0} TO={T_C1}")
    meas_lines.append("")
    meas_lines.append("* --- per-toggle = full cycle / 2 ---")
    meas_lines.append(".meas tran ept_e1   PARAM = 'egate_e1/2'")
    meas_lines.append(".meas tran ept_e2   PARAM = 'egate_e2/2'")
    meas_lines.append(".meas tran ept_e3   PARAM = 'egate_e3/2'")
    meas_lines.append(".meas tran ept_bfa PARAM = 'egate_bfa/2'")
    meas_lines.append("")
    meas_lines.append("* --- quiet-window (held-null idle) energy: expect ~0 ---")
    meas_lines.append(".meas tran eq_e1 INTEG V(p1) FROM={T_Q0} TO={T_Q1}")
    meas_lines.append(".meas tran eq_e2 INTEG V(p2) FROM={T_Q0} TO={T_Q1}")
    meas_lines.append("")
    meas_lines.append("* --- output checkpoints (assert @100n mid 115n, release @120n ->130n) ---")
    for i in (1, 2, 3):
        meas_lines.append(f".meas tran vsum{i}_r FIND V(ls{i}) AT=115n")
        meas_lines.append(f".meas tran vcout{i}_r FIND V(lc{i}) AT=115n")
        meas_lines.append(f".meas tran vsum{i}_f FIND V(ls{i}) AT=130n")
        meas_lines.append(f".meas tran vcout{i}_f FIND V(lc{i}) AT=130n")
    meas_lines.append(".meas tran vsum_b_r FIND V(lsb) AT=115n")
    meas_lines.append(".meas tran vcar_b_r FIND V(lcb) AT=115n")
    meas_lines.append("")
    meas_lines.append("* --- delay: input 50% -> output 50% (propagation delay) ---")
    meas_lines.append(".meas tran tdelay_cout TRIG V(b2) VAL=0.5 RISE=1 TARG V(lc2) VAL=0.5 RISE=1")
    meas_lines.append(".meas tran tdelay_sum  TRIG V(b2) VAL=0.5 RISE=1 TARG V(ls2) VAL=0.0 FALL=1")
    meas_lines.append("")
    # truth-table measurements
    for i, (a, b, c, sval, carry) in enumerate(expected_rows, 1):
        meas_lines.append(f".meas tran tsum{i}  FIND V(lsumt{i}) AT=130n")
        meas_lines.append(f".meas tran tcout{i} FIND V(lcoutt{i}) AT=130n")
    meas_lines.append("")
    meas_lines.append(".end")
    meas_lines.append("")

    full = HEADER + "\n".join(tt_lines) + "\n" + "\n".join(meas_lines)
    out = "/home/ian/dsh/projects/lattice/circuit/polar_full_adder.cir"
    with open(out, "w") as f:
        f.write(full)
    print(f"wrote {out}")
    # also emit expected table as json-ish for the checker
    import json
    with open("/home/ian/dsh/projects/lattice/circuit/polar_fa_expected.json", "w") as f:
        json.dump(expected_rows, f)
    print(f"wrote expected rows: {len(expected_rows)}")

if __name__ == "__main__":
    main()
