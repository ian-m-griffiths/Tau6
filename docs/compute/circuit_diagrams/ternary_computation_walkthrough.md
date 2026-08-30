# What Ternary Computation Looks Like, at the Transistor Level: a balanced-ternary addition

**A transistor-level walkthrough of the balanced-ternary full adder (`tadd1`), traced case by
case and worked on a real example.**

**Sources:** `rtl/trit_functions.vh` (the `tadd1` truth table + boolean form — the single source of
truth), `rtl/ternary_gates.v` (the trit encoding), `docs/compute/gate_area.md` (measured per-gate
area), `docs/compute/ground_up/tsum_cell.md` (measured transistor-level sum cell).

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`): **DIRECT** — read off the RTL truth
table / encoding, or measured by the yosys/ngspice runs cited. **DERIVED** — a faithful re-statement
of DIRECT material in transistor terms, but *not itself a built netlist*. (The 3-input `tadd1` cell
has **not** been built at the transistor level — `tsum_cell.md` §8.7 — so every "push/pull line
energizes" statement below is DIRECT at the *encoding + truth-table* level, and DERIVED only at the
physical-PMOS/NMOS-conduction level. The flag sits on each claim.)

---

## 0. What a trit *is*, physically

Before any addition happens, fix what "a trit" is. It is **not** a 3-level voltage. It is **two
wires, one-hot per direction** (DIRECT, `rtl/ternary_gates.v` L9–21):

```
value    bits     energized wire
-----    ----     ---------------
  +1     2'b01    push line energized
   0     2'b00    NEITHER line energized (null — free, no current)
  -1     2'b10    pull line energized
  11     2'b11    BOTH — never produced (a reusable don't-care)
```

Read that once and hold onto it, because it is the whole trick: **a trit's value is *which line is
energized*, not *how high a voltage is*.** `+1` is "the push rail is high". `−1` is "the pull rail
is high". `0` is "neither rail is high" — and that null costs **zero energy** because no line is
driven (`TernaryCell.lean` `energy .zero = 0`, `null_is_free`; DIRECT). There is no "0 V rail" to
keep charged; 0 is the *absence* of both directions.

Consequence at the transistor level: every trit input to a gate arrives as two binary wires —
`push` and `pull` — and the gate's job is to compute, for each output trit, whether its `push` wire
or its `pull` wire (or neither) should be energized.

---

## 1. The balanced carry rule, at the transistor level

### 1.1 The rule as arithmetic

Balanced ternary's digits are `{T, 0, 1}` (`T = −1`, the bar-1). When two digits add past ±1, the
overflow *wraps* instead of only pushing one way. The three half-adder rules (DIRECT,
`rtl/trit_functions.vh` L30):

```
  1 + 1 =  2  →  write down T (−1), carry +1     ("1T": 1·3 + (−1)·1 = 2)
  T + T = −2  →  write down 1 (+1), carry −1     ("T1": (−1)·3 + 1·1 = −2)
  1 + T =  0  →  write down 0 ( 0), carry  0     ("00": cancel)
```

(Notation: in `"1T"` the **left** symbol is the carry-out that goes to the next higher position, the
**right** symbol is the digit written at *this* position. So `1+1` produces carry `1`, sum `T` — the
RTL header states it directly as `+1+1 = −1 carry +1` and `−1−1 = +1 carry −1`, L30, L50–51.)

The full-adder form (DIRECT, `trit_functions.vh` L44–47) — with `s = a + b + cin` the digit sum and
`p = #(+1 inputs)`, `n = #(−1 inputs)`:

```
carry +1  ⇔  s ≥ +2   ⇔  p ≥ 2 AND n == 0
carry −1  ⇔  s ≤ −2   ⇔  n ≥ 2 AND p == 0
carry  0  ⇔  −1 ≤ s ≤ +1

sum +1  ⇔  s ∈ {+1, −2}     (i.e. s ≡ +1 mod 3)
sum −1  ⇔  s ∈ {−1, +2}     (i.e. s ≡ −1 mod 3)
sum  0  ⇔  s ∈ {0, ±3}      (i.e. s ≡  0 mod 3)
```

The sum is exactly **s mod 3, re-expressed in balanced digits**; the carry is the **±3 overflow**.
That is the elegant core, and it is symmetric by construction: the carry +1 rule and the carry −1
rule are the *same* sentence with `push↔pull` (and `+↔−`) swapped.

### 1.2 The rule as a transistor vote

Translate "p ≥ 2 AND n == 0" into rail language. In the one-hot encoding, `p` is the number of
energized **push** lines across the three inputs, `n` the number of energized **pull** lines. So the
carry is a **2-of-3 majority vote on one direction, vetoed by any vote for the other direction**
(DERIVED from DIRECT `trit_functions.vh` L94–95):

```
cop (carry push)  fires  ⇔  at least TWO of {push_a, push_b, push_cin} are high
                            AND ZERO of {pull_a, pull_b, pull_cin} are high
con (carry pull)  fires  ⇔  at least TWO of {pull_a, pull_b, pull_cin} are high
                            AND ZERO of {push_a, push_b, push_cin} are high
```

Read the carry rule at the transistor level: **two energized lines in the same direction, and no
line in the opposite direction, is what trips the carry.** One push and one pull *cancel inside the
sum* and never reach the carry — that is the veto. This is why the carry is *symmetric and bounded*:
it is `+1`, `−1`, or `0`, and it can never exceed one trit in either direction, no matter how long
the ripple. There is no "carry the 2" runaway — the wrap absorbs it.

### 1.3 The key rows of the truth table

The full `tadd1` table is 27 reachable `(a,b,cin)` triples, grouped by digit sum (DIRECT,
`trit_functions.vh` L32–43). The rows that matter for intuition:

| s = a+b+cin | inputs (a,b,cin) | sum | carry | reads |
|---|---|---|---|---|
| **s = +3** | (+1,+1,+1) | 0 | +1 | 1+1+1 = 10 (carry 1, sum 0) |
| **s = +2** | (+1,+1,0) (+1,0,+1) (0,+1,+1) | **−1 (T)** | **+1** | 1+1 = 1T |
| **s = +1** | (+1,0,0) (0,+1,0) (0,0,+1); (−1,+1,+1) (+1,−1,+1) (+1,+1,−1) | +1 | 0 | single +1, or two +1 one −1 |
| **s = 0** | (0,0,0) (±1,∓1,0) and all balanced triples | 0 | 0 | **1+T = 00** (the cancel rows) |
| **s = −1** | (−1,0,0) (0,−1,0) (0,0,−1); (−1,−1,+1) (−1,+1,−1) (+1,−1,−1) | −1 | 0 | single −1, or two −1 one +1 |
| **s = −2** | (−1,−1,0) (−1,0,−1) (0,−1,−1) | **+1** | **−1** | T+T = T1 |
| **s = −3** | (−1,−1,−1) | 0 | −1 | T+T+T = T0 (carry −1, sum 0) |

The three half-adder rows (`s = +2`, `s = 0` with `(1,T,0)`, `s = −2`) are the entire point of the
balanced digit set: the two `±2` rows *wrap* (write the opposite-sign digit, carry the sign), and
the `s = 0` row *cancels* (write 0, carry 0). A binary adder has no analogue of the wrap — it just
has an ever-growing carry; a balanced adder's carry is a single signed trit.

---

## 2. The `tadd1` cell, traced case by case

### 2.1 The cell

`tadd1` takes three trits (`a`, `b`, `cin`) — six input wires — and produces two trits
(`cout`, `sum`) — four output wires (DIRECT, `trit_functions.vh` L86–108):

```
                          tadd1 :  (a, b, cin)  →  {cout, sum}
                          output trit = {pull, push} = {[1], [0]}

   a      a[0]=push ──┐
          a[1]=pull ──┤
   b      b[0]=push ──┤        ┌── CARRY: 2-of-3 vote, vetoed by the other sign ──┐
          b[1]=pull ──┼───────▶│  cop = ~an·~bn·~cn · (ap·bp | ap·cp | bp·cp)    │──▶ cout
   cin  cin[0]=push ──┤        │  con = ~ap·~bp·~cp · (an·bn | an·cn | bn·cn)    │
          cin[1]=pull ─┘        └──────────────────────────────────────────────────┘
                                ┌── SUM: s mod 3, re-balanced ────────────────────┐
                                │  sp = "s ≡ +1 mod 3"  =  s ∈ {+1, −2}          │──▶ sum
                                │  sn = "s ≡ −1 mod 3"  =  s ∈ {−1, +2}          │
                                └──────────────────────────────────────────────────┘

   (ap, an) = a[0], a[1];  (bp, bn) = b[0], b[1];  (cp, cn) = cin[0], cin[1]
   cout = {con, cop}   (pull, push)      sum = {sn, sp}   (pull, push)
```

The expanded sum terms (DIRECT, `trit_functions.vh` L96–105) are worth seeing once, because they
make the two *kinds* of `s ≡ +1` visible — a lone push, or a push-vs-pull count that nets to +1:

```
sp = (ap & ~bp & ~bn & ~cp & ~cn) | (bp & ~ap & ~an & ~cp & ~cn) | (cp & ~ap & ~an & ~bp & ~bn)
      └───────── s = +1, one push & two zeros ─────────┘
   | (ap & bp & cn) | (ap & cp & bn) | (bp & cp & an)
      └── s = +1, two pushes & one pull (2−1=+1) ──┘
   | (~ap & ~bp & ~cp & ((an & bn & ~cn) | (an & cn & ~bn) | (bn & cn & ~an)))
      └── s = −2, two pulls & one zero (sum wraps to +1) ──┘

sn = (an & ~bn & ~cn & ~ap & ~bp & ~cp) | (bn & ~an & ~cn & ~ap & ~bp & ~cp) | (cn & ~an & ~bn & ~ap & ~bp & ~cp)
      └───────── s = −1, one pull & two zeros ─────────┘
   | (ap & bn & cn) | (bp & an & cn) | (cp & an & bn)
      └── s = −1, two pulls & one push (1−2=−1) ──┘
   | (~an & ~bn & ~cn & ((ap & bp & ~cp) | (ap & cp & ~bp) | (bp & cp & ~ap)))
      └── s = +2, two pushes & one zero (sum wraps to −1) ──┘
```

Every output rail (`cop, con, sp, sn`) is a single boolean line — at the gate level, a static-CMOS
network over the six input rails; at the *encoding* level, those four lines group into two trits by
`{pull, push}`. "Which push/pull lines energize" is therefore a direct read: for each case, which of
the four output rails is driven to 1. (DERIVED: the physical PMOS/NMOS conduction of those four
networks; the measured silicon for the *2-input* sum is `tsum_cell.md` — 88 devices — and the
3-input `tadd1` transistor cell is still unbuilt, `tsum_cell.md` §8.7.)

### 2.2 Case `1 + 1` → sum T, carry 1

`a = +1 (push)`, `b = +1 (push)`, `cin = 0`. Two push rails energized, zero pull rails:

```
   a:  ap=1  an=0      b:  bp=1  bn=0      cin:  cp=0  cn=0

   cop = ~an(~bn)(~cn) · (ap·bp) = 1·1·1 · (1·1) = 1   ⇒  carry PUSH energizes   (cout = +1)
   con = ~ap · …                = 0                    ⇒  carry pull stays low

   sp  = ap&bp&cn(0) | ap&cp&bn(0) | bp&cp&an(0) | single-push terms(0) | ~ap…(0) = 0
   sn  = ~an&~bn&~cn · (ap&bp&~cp) = 1·1·1 · (1·1·1) = 1  ⇒  sum PULL energizes   (sum = −1)
```

Net: `cout = +1`, `sum = −1` — i.e. **"1T"**: the push line of the carry goes high, the pull line of
the sum goes high. Two pushes in, the vote trips `cop`, the wrap drives `sn`.

### 2.3 Case `T + T` → sum 1, carry T

`a = −1 (pull)`, `b = −1 (pull)`, `cin = 0`. The mirror image of the previous case:

```
   a:  ap=0  an=1      b:  bp=0  bn=1      cin:  cp=0  cn=0

   cop = ~an = 0                                          ⇒  carry push stays low
   con = ~ap(~bp)(~cp) · (an·bn) = 1·1·1 · (1·1) = 1      ⇒  carry PULL energizes   (cout = −1)

   sp  = ~ap&~bp&~cp · (an&bn&~cn) = 1·1·1 · (1·1·1) = 1  ⇒  sum PUSH energizes     (sum = +1)
   sn  = 0
```

Net: `cout = −1`, `sum = +1` — **"T1"**. The carry vote trips `con` (two pulls, no push), the wrap
drives `sp`. Every rail that was high in `1+1` is now its opposite — this symmetry is what makes the
carry rule "balanced".

### 2.4 Case `1 + T` → sum 0, carry 0

`a = +1 (push)`, `b = −1 (pull)`, `cin = 0`. One push and one pull — they cancel before any rail
fires:

```
   a:  ap=1  an=0      b:  bp=0  bn=1      cin:  cp=0  cn=0

   cop = ~bn = 0     (a pull exists → the carry vote is vetoed)   ⇒  carry push low
   con = ~bp = 0     (a push exists → vetoed)                      ⇒  carry pull low

   sp  = ap&bp(0) | ap&cp(0) | bp&cp(0) | single-push (ap&~bp=0)… = 0
   sn  = an&bn(0) | ap&bn&cn(0) | bp&an&cn(0) | … = 0              ⇒  sum null (neither rail)
```

Net: `cout = 0`, `sum = 0` — **"00"**. Neither output rail energizes; the null is the *free* output,
no line driven. The push and the pull have annihilated inside the cell, and the output trit is `00`,
costing nothing.

### 2.5 What the three traces show

| case | inputs (push,pull) | carry rails (con,cop) | sum rails (sn,sp) | reads |
|---|---|---|---|---|
| `1 + 1` | (1,0) (1,0) (0,0) | 0 **1** | **1** 0 | 1T — carry push, sum pull |
| `T + T` | (0,1) (0,1) (0,0) | **1** 0 | 0 **1** | T1 — carry pull, sum push |
| `1 + T` | (1,0) (0,1) (0,0) | 0 0 | 0 0 | 00 — nothing fires |

The carry output is a **majority-with-veto**; the sum output is a **mod-3 wrap**. Those two ideas —
a direction vote and a balanced wrap — are the entire full adder. There is no sign logic anywhere:
sign *is* the direction of the energized rail.

---

## 3. Worked example: `+3 + +9`

Work the ripple column by column so the computation is visible. Use three positions:

```
                 position (weight):      3²       3¹       3⁰
                                         9        3        1

   a = +3  =  1·3¹ + 0·3⁰              ( 0      +1        0 )
   b = +9  =  1·3²                     (+1       0        0 )

   +3  =  "10"₃        (trit at 3¹ is 1, at 3⁰ is 0)
   +9  = "100"₃        (trit at 3² is 1)
```

Ripple from the least-significant position (3⁰) upward, applying `tadd1` at each step (DIRECT —
each row is a truth-table lookup from §1.3):

```
   pos 3⁰:   a=0,  b=0,  cin=0   →   s=0     →   sum 0,  carry 0      (0 + 0)
   pos 3¹:   a=+1, b=0,  cin=0   →   s=+1    →   sum +1, carry 0      (1 + 0)
   pos 3²:   a=0,  b=+1, cin=0   →   s=+1    →   sum +1, carry 0      (0 + 1)
   final carry-out = 0

   result:  [ +1, +1, 0 ]₃  =  1·9 + 1·3 + 0·1  =  12    ✓  (+3 + +9 = +12)
```

Honest observation: `+3` and `+9` each hold a single `1` at *different* powers, so the columns never
overlap — **this example is carry-free** (each column has at most one nonzero digit; it is a
"combine", not a "carry"). It shows the ripple structure, but not the carry itself. To see the carry
that §1–2 are about, run `+3 + +3`:

```
   +3 + +3 = +6

   pos 3⁰:   a=0,   b=0,   cin=0   →   s=0      →   sum 0,  carry 0
   pos 3¹:   a=+1,  b=+1,  cin=0   →   s=+2     →   sum −1, carry +1     ← 1+1 = 1T, the wrap
   pos 3²:   a=0,   b=0,   cin=+1  →   s=+1     →   sum +1, carry 0      ← the carry lands here

   result:  [ +1, −1, 0 ]₃  =  1·9 − 1·3 + 0·1  =  6     ✓
```

Watch the carry: at `3¹` the two `+1`s produce `s=+2`, which wraps to `sum −1` and sends `carry +1`
leftward; that carry is exactly the `cin` of the next column, where it becomes the `+1` at `3²`.
This is the "1T" of §2.2 propagating — the reader can trace the energized push line of the `3¹`
carry becoming the energized push input of the `3²` column. And it is the *only* possible carry
height: balanced carry is `±1`, never more, so the ripple is provably bounded (DIRECT — the carry
can't exceed one trit because `|s| ≤ 3` and the wrap absorbs `±2`/`±3`).

---

## 4. What's elegant, and what it costs

### 4.1 Elegant

1. **Negation is free — literally 0 transistors.** `tneg` is a wire swap: `+1 ↔ −1`, `0 → 0`
   (DIRECT, `trit_functions.vh` L55–60). Synthesized: **0 cells, 0.0000 µm²** (DIRECT,
   `gate_area.md`). There is no two's-complement `~x + 1`, no borrow chain. Subtraction is `TSUB`
   = negate + add, so a subtractor is *the same adder with the input wires crossed*. This is the
   single biggest structural win, and every other win (rotation, compare, round-to-nearest)
   inherits from it.

2. **Symmetric carry.** The carry is `{+1, 0, −1}`, and the `+1` rule is the `−1` rule with
   `push↔pull` swapped (§1.2). A carry can go *left* as easily as *right*, so adding a large
   negative and a large positive number can shrink instead of overflow — there is no unsigned
   carry that only ever accumulates one way. The wrap (`±2 → ∓1 carry ±1`) is what makes the digit
   set *balanced* rather than merely ternary.

3. **No sign bit.** The sign of a number is the sign of its leading nonzero trit, and each digit
   *carries its own sign* in its rail direction. Nothing anywhere in the adder tracks "is this
   number negative" — the sign is implicit in which lines are energized. Compare, negate, and
   subtract all fall out of the same two rails with zero sign bookkeeping (DIRECT,
   `docs/compute/arithmetic.md` §1.2).

### 4.2 Costly

1. **Two thresholds per decision.** To resolve "is this trit −1, 0, or +1?" the cell must make
   *two* decisions where binary makes one: "is it push?" **and** "is it pull?" — with null as the
   joint absence of both. That third state is the expensive one: `null = NOT(push OR pull)` must be
   reconstructed from two hard thresholds, and it is exactly the piece the direction receiver does
   not produce for free (DIRECT, `tsum_cell.md` §1, §6.1). Measured: the balanced full adder is
   **4.33× a binary full adder's area** (25 cells / 146.39 µm² vs 2 cells / 33.78 µm²; DIRECT,
   `gate_area.md`) — the 2-threshold tax, in silicon.

2. **Two wires per trit.** A trit is 2 bits: `log₂3 ≈ 1.585` bits of information carried on **2
   wires** = **0.792 bits/wire**, versus 1 bit/wire for binary (DIRECT, `gate_area.md`). The
   one-hot-per-direction code wastes 26% of the wires — on top of the per-gate area penalty. The
   2-wire encoding is what buys the free null and the free negation, but it is a real tax that the
   1.585-bit density does **not** pay back (no gate class in the measured library compensates;
   DIRECT, `gate_area.md` verdict).

### 4.3 The honest one-liner

Balanced ternary buys **free negation, a symmetric carry, and no sign logic** — all three are
consequences of one decision: *a digit is a direction, not a magnitude*. It pays for that decision
with **two thresholds and two wires per trit**. The full adder is the cleanest place to see both
sides at once: the carry is a one-line vote with a veto (§1.2), and the cell that computes it is
4.33× the binary cell that computes an unsigned carry (§4.2).

---

## Calibration ledger

| claim | calibration |
|---|---|
| Trit encoding `01=+1 / 00=0 / 10=−1 / 11=NEVER`, push/pull/null | **DIRECT** — `rtl/ternary_gates.v` L9–21; `TernaryCell.lean` |
| Null is free (0 = no energized line) | **DIRECT** — `TernaryCell.lean` `null_is_free`, `energy .zero = 0` |
| Balanced carry rule `s≥+2→+1`, `s≤−2→−1`, `sum = s mod 3` | **DIRECT** — `trit_functions.vh` L32–49 (27-row truth table) |
| `1+1 → sum −1 carry +1`, `−1−1 → sum +1 carry −1` | **DIRECT** — `trit_functions.vh` L30, L50–51 |
| `cop/con/sp/sn` boolean equations (the 4 output rails) | **DIRECT** — `trit_functions.vh` L94–106 |
| "Carry = 2-of-3 vote, vetoed by the other sign" | **DERIVED** — re-statement of DIRECT L94–95 in rail language |
| "Push/pull line energizes" per case (§2.2–2.4) | **DIRECT at encoding level** (truth table + L9–21); **DERIVED at transistor level** |
| Worked examples `+3 + +9 = +12`, `+3 + +3 = +6` | **DIRECT** — row-by-row truth-table lookups from §1.3 |
| `tneg` = 0 cells / 0.00 µm² | **DIRECT** — `gate_area.md` (yosys, sky130) |
| `tadd1` = 25 cells / 146.39 µm² = 4.33× binary FA | **DIRECT** — `gate_area.md` |
| 2 thresholds (the third decision, `null = NOT(p OR n)`) | **DIRECT/OURS** — `tsum_cell.md` §1, §6.1; `device_physics.md` Law 1 |
| 2 wires/trit = 0.792 bits/wire (26% wire waste) | **DIRECT** — `gate_area.md` (arithmetic on the encoding) |
| Carry is bounded at ±1 (no runaway) | **DERIVED** — immediate from `|s| ≤ 3` and the wrap rule (DIRECT) |
| The 3-input `tadd1` *transistor* cell exists | **NOT CLAIMED** — unbuilt (`tsum_cell.md` §8.7); measured transistor numbers are for the 2-input sum (88 devices) |
