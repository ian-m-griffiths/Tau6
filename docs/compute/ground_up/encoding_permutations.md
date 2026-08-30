# Encoding Permutations — can ANY encoding break the 1.26× compute floor?

**2026-08-29 — Tau Architecture, the assumption-permutation pass.** ONE job: take the
*encoding* assumptions — how a trit is drawn on wire(s), where the null sits, whether the
signal is a level/a direction/a time/a phase — and permute every one, bloodily, looking for
a variant that makes **ternary compute ≤ binary per bit**. The floor under attack is the
settled verdict: **1.26× = 2·ln2/ln3 = 2/log₂3**, which `ThresholdLowerBound.lean` and
`meta_math.md` §2 both claim is **representation-independent**.

This file is a *permutation audit*: it does not re-run netlists and does not re-prove Lean.
Every number is read from the existing corpus (`fair_binary.md`, `tsum_cell.md`,
`radix_lower_bound.md`, `meta_math.md`, `gate_area.md`, `analog_polar.md`,
`differential_noise.md`) or is exact arithmetic on those numbers. It adds **one genuinely
new permutation** (block coding, §6.1) that the corpus flagged but never computed.

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured/proved in-repo, or a textbook arithmetic identity.
- **ANALOGY** — structural parallel, not identity.
- **OURS** — this audit's synthesis/design claim, following from DIRECT but not independently established.
- **SPECULATION** — untested hypothesis, flagged as such.

---

## 0. The one-line answer, up front

**No permutation breaks the floor — but the *reason* the floor survives is narrower than
the corpus states, and there is exactly one encoding that gets *under 1.26×* (never under
1.0×).** Three facts, all DIRECT/arithmetic:

1. **No single-trit encoding reduces the read below 2 binary decisions.** One yes/no test
   distinguishes at most 2 alternatives; naming 1 of 3 states needs `⌈log₂3⌉ = 2`. This is
   an information-theoretic floor, invariant under *every* drawing of the constellation
   (level, direction, one-hot, differential, sign+magnitude, PWM, phase). `meta_math.md` §2
   is right. **[DIRECT — counting identity; `⌈log₂3⌉ = 2`.]**
2. **The only thing under 1.26× is a *block* code** — packing `k` trits as one word — which
   pushes the decision cost toward `⌈k·log₂3⌉/k·log₂3` → **1.0× from above** (best small case
   `k = 5`: 3⁵ = 243 ≈ 2⁸ → **1.0095×**). It never reaches or crosses 1.0, because
   `⌈x⌉ ≥ x` always. So ternary *approaches* binary's floor in the limit but never beats it.
   **[DIRECT arithmetic; the hardware cost is OURS/SPECULATION.]**
3. **The measured compute gap (3.4–33×) is ~26× larger than the 1.26× floor** (the floor is
   3.8% of the full-swing gap, `radix_lower_bound.md` §2.3). The encoding does **not** decide
   compute in practice — swing² (7.8×), dead-zone crowbar (6.8×), and the receiver (2.54×)
   do, and no encoding permutation touches those. **[DIRECT on the factors; OURS on the
   "encoding doesn't decide it" framing.]**

The verdict that survives: **ternary compute never beats binary per bit under any encoding;
the 1.26× is representation-independent for single symbols, relaxes toward 1.0× only via
block coding, and the only under-floor mechanism is a *native 3-way device* (not an
encoding) whose honest cost is ~1.5–2×, not 0.63×.**

---

## 1. The two axes — what "the encoding" can and cannot move

Every encoding question in this file collapses to **two independent axes**, and the corpus
has repeatedly blurred them (`meta_mishandled.md` §6 is the one place it is kept straight):

| axis | what it measures | can an *encoding* move it? |
|---|---|---|
| **decision COUNT** | how many binary discriminations to name one symbol (`⌈log₂b⌉`) | **NO** — fixed at 2 for a single trit, `3 ≠ 2^k` |
| **decision QUALITY** | margin (`V_swing/4` vs full), reference (ground vs bandgap), null (saddle vs dead-zone), DC balance, wire count | **YES** — this is the entire content of every permutation below |

**The 1.26× lives on the COUNT axis.** Every encoding permutation in §2–§5 is therefore an
attempt to *smuggle quality gains into a count reduction* — to make one of the two decisions
so cheap that it stops counting. The honest result, worked through case by case, is that the
quality gains are real (direction read is robust, null-as-absence is free *energetically*,
ground is the free reference) **but none of them deletes a decision**. **[OURS — the
two-axis frame; each leg is DIRECT as cited below.]**

The per-bit read cost of any single-trit encoding is therefore

```
C = 2 decisions / log₂3 bits = 2·ln2/ln3 = 1.262×  binary
```

and the only question any permutation can answer is *how much worse than the bare floor* the
secondary costs make it. **[DIRECT — `ThresholdLowerBound.lean` at b=3; `meta_math.md` §2
shows `b−1 = ⌈log₂b⌉` coincide exactly at b=3.]**

---

## 2. Item 1 — the four bit/level encodings

### 2.1 One-hot 2-bit (push/pull/null: `01=+1, 00=0, 10=−1, 11=NEVER`)

**The assumption:** a trit is *two wires*, one-hot-per-direction. This is the current
compute representation (`rtl/trit_functions.vh`, `TernaryCell.lean`).

**Read cost:** 2 decisions — read wire A ("push?"), read wire B ("pull?"); null = neither.
Exactly `⌈log₂3⌉ = 2`, no more, no less. **But each decision is at FULL binary margin**, not
the halved 3-level margin, because each wire carries only 2 states. This is why the 2-wire
*emulation* gates lose only **1.2–3.1×** (`gate_energy.md`) while the single-wire *level*
gates lose **4.9–14.3×** — the 2-wire form dodges the 3-level SNR tax entirely. **[DIRECT —
`gate_area.md` §1; `meta_mishandled.md` §6.2.]**

**Does it eliminate a decision?** No. It *wastes a state* instead (the 4th corner `11`), so
it carries `log₂3` bits on `2` wires = **0.79 bits/wire, a 26% wire loss** — the *state* waste
is paid in copper, not in decisions. **[DIRECT — `gate_area.md`; `meta_math.md` §2 "wasted
4th corner".]**

**Beats binary?** No. Ties the 1.26× decision floor, pays +26% wires on top.

### 2.2 Balanced 3-level (−V / 0 / +V), single wire (PAM-3)

**The assumption:** three *ordered* voltage levels on one wire. This is the model
`ThresholdLowerBound.lean` actually prices (`b−1` ordered thresholds).

**Read cost:** 2 thresholds (a flash/thermometer decoder against ±V/2), each at **halved
margin `V_swing/4`** (6.02 dB penalty → ~2× energy at fixed BER). **[DIRECT — `device_physics.md`
§2.3; `differential_noise.md` §2.]**

**Does it eliminate a decision?** No — it is the *definitional* 2-threshold case.

**Beats binary?** No. Ties the floor *and* pays the halved margin; the null sits at the
0 V comparator saddle (meta-stable, **1.9 pJ/toggle** shoot-through measured,
`polar_gates.md`). This is the *worst* of the single-trit encodings on the quality axis.

### 2.3 Unbalanced (0 / 1 / 2)

**The assumption:** the CNTFET/current-mode literature convention — three unsigned levels
`{0, I, 2I}` (or `{0, 1, 2}`).

**Read cost:** 2 thresholds — identical to PAM-3 (3 ordered levels, shifted reference).
**[ANALOGY — the unbalanced results are the literature's level-coded convention; the count
is the same arithmetic.]**

**Does it eliminate a decision?** No.

**Beats binary?** No — same floor as PAM-3, and it *loses* DC balance (mean ≠ 0), so it
forfeits the AC-coupling/offset-cancellation benefit that balanced `{−V,0,+V}` gets
(`differential_noise.md` §5). Strictly no better, one property worse.

### 2.4 2's-complement-style (and sign-extension)

**The assumption:** encode −1 as "the complement" so that negation = invert+1, sign is the
leading digit. Ternary analog = 3's-complement (`2 ≡ −1` in `{0,1,2}`), or the 2-bit map
`2'b10 = −1` with `2'b11` as the sign-extension don't-care.

**Read cost:** still 2 decisions. Complement/negation is a **gate** transformation (which
operation is cheap — balanced makes negation a free wire-swap, `gate_area.md` 0.00 µm²), not
a **read** transformation. Resolving which of 3 values is present still needs 2 binary
tests. **[OURS — the read/gate distinction; the "negation free in balanced" fact is DIRECT.]**

**Does it eliminate a decision?** No. The one genuinely useful 2's-complement property is
that the *sign alone* is recoverable in **1** decision (the top bit) — but that is a *partial*
read (it cannot distinguish null from the two outers), so it decodes nothing. Same as the
direction observation in §4. **[OURS.]**

**Beats binary?** No.

**Item-1 verdict.** All four tie at 1.26× *decisions/bit*. The cheapest *read* (decision
quality) is **one-hot** (2 decisions, each at full binary margin) — and it pays for that with
a 26% wire overhead, not a decision reduction. The cheapest *wire* is balanced single-wire
(1.585 bits/wire), and it pays for that with the halved margin. **None eliminates either of
the two decisions.** **[OURS synthesis; the per-encoding facts are DIRECT.]**

---

## 3. Item 2 — null placement

### 3.1 null = mid-level (voltage 0)

The PAM-3 null: a *driven or held* 0 V level. On the wire it is **not free** (a held 0 V is
a rail; only a *passive return-to-zero* makes it cheap). In the gate it is the **saddle** —
a level receiver's 0 V comparator sits exactly on it, producing the measured **1.9 pJ/toggle
shoot-through** (`polar_gates.md`). **[DIRECT — the shoot-through is measured; "held 0 V is
a rail" is DIRECT circuit fact.]**

**Read cost:** 2 ordered thresholds; null is the *most expensive* state to hold, not the
cheapest.

### 3.2 null = "no line energized" (the current choice)

The transport cell's null: **absence of drive**, data-bearing, costing ~**0.05 pJ** (24×
cheaper than a ±1 pulse). **[DIRECT — `ENERGY_RESULTS.md`.]** In the diode-direction receiver
null = "neither rail fired" — a **dead zone** a full diode-drop (`VTO ≈ 0.3 V`) *below* both
trip points, not a saddle. Measured held-null idle in the diode gate: **≈ 1.5×10⁻¹⁹ J ≈ 0 aJ**
(`diode_gates.log`, `tsum_cell.md` §4.2). **[DIRECT — both logs.]**

**Read cost:** still **2 decisions** — sign (which rail conducts) + presence ("did either
rail conduct?"). The null-placement makes the null *free energetically* (both on wire and at
gate idle), **but the null decision is still one of the two required discriminations**. The
null rail `NOT(push OR pull)` is, in `tsum_cell.md` §1's words, "the one piece the direction
receiver cannot produce" — the third decision those two boundaries imply. **[DIRECT —
`tsum_cell.md` §1/§6.]**

### 3.3 null = a specific symbol (assign null a dedicated 2-bit pattern)

E.g. `11 = null` instead of `NEVER`, or any other reserved code. Since one-hot *already*
assigns null the pattern `00`, this is the same 2-bit machinery: you still read 2 bits to
know which of 3 values you have. **No decision saved.** **[OURS — the permutation is a
relabeling.]**

**Item-2 verdict.** Null placement moves the *energy* and the *margin* of the null, not the
*decision count*. **"No line energized" is the only placement that makes the null free on
the wire AND free at gate-idle simultaneously** (DIRECT, both measured) — but it does not
make the null *free to read*: the null-vs-active distinction consumes one of the two
decisions regardless. There is no null placement that reduces 2 → 1. **[OURS synthesis;
component facts DIRECT.]**

---

## 4. Item 3 — differential / pair / sign+magnitude

### 4.1 Differential pair (two anti-polar lines carrying ±1)

True two-wire differential `{+V/−V, −V/+V, common-mode}` (MLT-3 over a pair). **Read cost:**
still 3 levels → 2 decisions. **And** it costs **2 wires/trit = 0.79 bits/wire — below
binary**, giving back the radix-economy transport win. The only gain is **CMRR**
(common-mode rejection), which is a *noise-floor* benefit, not a *spacing* benefit: the three
levels still sit `V_swing/4` apart, so the halved margin is untouched. **[DIRECT —
`differential_noise.md` §1–§4: MLT-3's margin is set by 3-level spacing, not balancing.]**

**Does it turn 2 thresholds into 1?** No. A differential receiver decides *direction*; the
null is "both wires at common mode", which is a **differential-mode amplitude** decision with
margin `V_diff/2` — still `V_swing/4`, still a second decision. **[OURS — `differential_noise.md`
§4.2.]**

**Beats binary?** No. Ties the floor on decisions, *loses* on wire count.

### 4.2 Single-line polarity (direction on one wire)

The transport cell: one wire, signed `±V`, read by two antiparallel diode legs. **Read cost:**
2 decisions (push-rail sign test + pull-rail sign test), null = neither. The sign decision is
made by **passive rectification** (junction physics, no comparator, no clock, no supply) — the
cheapest per-decision mechanism in the corpus — and the two outer symbols are maximally
separated (they live on *different rails*, `differential_noise.md` §3.3). But the **null
decision is still an amplitude/presence test**, and the *regeneration* (cross-coupled latch =
a measurement, `meta_math.md` §4.1) plus the **resistive null-return termination** (the
7.8× DC finding, `lowswing_diode.md` §4) are what actually set the measured 3.4–4.9× per
bit. **[DIRECT — `fair_binary.md` §4, `lowswing_diode.md` §4.]**

**Does it turn 2 into 1?** No. `meta_math.md` §4 and `radix_lower_bound.md` factor 7 are
explicit: direction *relabels* "level vs level" as "sign + presence", still 2 decisions,
×1.00.

**Beats binary?** No — and this is the *measured* answer: 3.4–4.9× per bit (cheapest toggle),
24–33× (full swing). **[DIRECT — `fair_binary.md` §4.]**

### 4.3 Sign + magnitude (sign rail + magnitude rail)

Two cells: one carries sign, one carries magnitude. **Read cost:** 2 decisions (sign + magnitude),
exactly the floor — and on the *erasure* side it is **worse**, because the 2-cell register has
**4 physical states** carrying `log₂3` bits, so erasing costs `k_B T ln 4` → **1.26× worse per
bit** (`meta_math.md` §3). **[DIRECT — arithmetic identity.]**

**Beats binary?** No — ties the read floor and loses 1.26× on erasure.

**Item-3 verdict.** No pair/direction/sign-magnitude variant reduces the decision count below
2, for the structural reason `3 ≠ 2^k`. Differential buys CMRR (real, noise-floor-only, at
the cost of a second wire); direction buys a robust/free sign read (real) but leaves the
null/presence decision; sign+magnitude buys nothing and pays the 4th-state erasure tax.
**[OURS synthesis; each leg DIRECT/OURS as tagged.]**

---

## 5. Item 4 — signal space: level vs direction vs time vs phase

| signal space | symbol = | read = | decisions/bit | where the 1.26× lives | under floor? |
|---|---|---|---|---|---|
| **level (PAM-3)** | 3 ordered voltages | 2 thresholds vs ±V/2 | 1.262 | the 2nd threshold; halved margin | no |
| **direction (polarity)** | sign of current/voltage + zero | rail-selection + presence | 1.262 | the null/amplitude decision | no |
| **time (PWM)** | 3 pulse widths / positions | 2 time-thresholds (or 1 integration + 2 crossings) | 1.262 | the 2nd time-threshold; plus slower symbol time | no |
| **phase/frequency (3-phase / ω)** | 3 phases `ω⁰,ω¹,ω²` | phase discriminator = 2 independent components | 1.262 | the 2nd independent phase component | no |

**The 1.26× lives in the same place in all four: the second of the two independent
discriminations required to name 1 of 3 equiprobable states.** Each space changes the
*physics* of a decision (a voltage compare vs a charge integration vs a phase difference vs a
width count), and therefore its *absolute* cost and its *noise*, but never the *count*. The
3-phase case is the most instructive: a 3-phase system carries **2 independent
line-to-line components** — three phases, two degrees of freedom — which is exactly why
`⌈log₂3⌉ = 2` and not 1. **[DIRECT for the count identity; ANALOGY for the 3-phase
2-of-3-degrees-of-freedom reading; OURS for "same place in all four".]**

**PWM/time is the only one that is *strictly worse* than the others at the same decision
count:** it spends symbol *time* on the extra level, so per-bit **time** cost rises even
before energy. Measured: PWM-5 ties/loses vs fair binary (0.93–1.29×,
`fair_binary.md` §3). **[DIRECT — the PWM-5 number is measured.]**

**Phase/frequency buys nothing on the read axis at all** — its win is *namespace* (3ⁿ on
ℤ[ω]) and the free rotation operator (×ω is the cycle), which are `gates.md` §2 gate/name
wins, not read wins. **[OURS — connects to `gates.md` §2; the namespace fact is DIRECT
(`FINAL_VERDICT.md`).]**

**Item-4 verdict.** No signal space gets under 1.26×, and none *eliminates* a decision; they
differ only in how expensive and how noisy each of the two decisions is.

---

## 6. My own permutations (beyond the brief's four)

### 6.1 Block coding — the one thing that gets under 1.26× (never under 1.0×)

**The assumption to permute:** the floor is quoted *per symbol*. Drop that; pack `k` trits
into one word and decode the word. The per-word decision cost is `⌈log₂(3^k)⌉` binary
decisions for `k·log₂3` bits, so:

| k (trits/word) | word states 3ᵏ | bits | decisions ⌈·⌉ | **decisions/bit** |
|---:|---:|---:|---:|---:|
| 1 | 3 | 1.585 | 2 | **1.262** |
| 2 | 9 | 3.170 | 4 | 1.262 |
| 3 | 27 | 4.755 | 5 | 1.052 |
| 4 | 81 | 6.340 | 7 | 1.104 |
| **5** | **243** | **7.925** | **8** | **1.0095** |
| 6 | 729 | 9.510 | 10 | 1.052 |
| 8 | 6561 | 12.680 | 13 | 1.025 |
| 10 | 59049 | 15.850 | 16 | **1.0095** |

**[DIRECT — exact arithmetic; computed here, extending the `meta_math.md` §TODO "block codes
amortize the waste differently" open item.]**

**What it does and does not do.** It *does* get under 1.26×: `k=5` is **1.0095×**, a 20×
shrink of the floor's overhead (1.262→1.010). It *does not* beat binary: `⌈x⌉ ≥ x` for every
`x`, so the ratio is **≥ 1.0 for every k** — ternary block codes approach binary's floor from
above and never cross it. And it is **radix-neutral**: binary packing has zero waste already
(`2^k` exact), so block coding only *removes* a ternary disadvantage, it creates no advantage.
The hardware price is real and uncounted: word-level decode needs the whole `k`-trit block
before emitting anything (latency), and the decoder is a `3^k`-way map (area) — a
throughput/area cost, not a free lunch. **[OURS/SPECULATION for the latency/area price; the
"never below 1.0" is DIRECT.]**

**Verdict on 6.1:** this is the *strongest* encoding permutation — it moves the number — but
it confirms the floor's direction rather than breaking it: the honest bound is
`⌈k·log₂3⌉/(k·log₂3) → 1⁺`, i.e. **"ternary can asymptotically match, never beat, binary per
decision."**

### 6.2 Redundant signed-digit (use the `11` corner as `−0`)

**The assumption to permute:** the 2-bit code *wastes* the 4th corner. Use it: `01=+1, 10=−1,
00=0, 11=−0` (a redundant zero). This is the signed-digit literature's actual trick
(Kawahito 1990). **[ANALOGY — cited in `analog_polar.md` §2.]**

**Read cost:** unchanged — 2 decisions; the information content is still `log₂3` bits (the
4th state is a *redundant copy* of 0, not a 4th value). The waste is converted from "unused
state" to "redundant state" — the *decision* count is untouched. **[OURS — arithmetic.]**

**What it buys:** carry-propagation-*free* addition (the sign of a partial sum is available
early) — a **gate/arithmetic** win, not a read win. Exactly the "negation/rotation is cheap"
class of balanced-ternary advantage. **[OURS.]**

**Beats binary on read?** No.

### 6.3 Charge-domain / packet encoding

Push = +Q packet, pull = −Q packet, null = no packet (the transport cell already *is* this,
`analog_polar.md` §1). **Read cost:** 2 decisions (sign of charge + presence); null is
natively free (no packet = no energy). Same floor, best null-freedom. No decision saved.
**[OURS/ANALOGY — the null-freedom is DIRECT; the "still 2 decisions" is the same count
argument.]**

### 6.4 Dual-rail current-mode differential (SCL)

Two anti-polar current rails, tail current. **Read cost:** 2 decisions, and it *adds* static
tail current in every state (including null), violating null-as-default *by construction*
(Current 1994, cited in `analog_polar.md` §2). Same floor, worse idle. **[DIRECT — the
idle-bias cost is the CMMVL literature's own admission.]**

**Beats binary?** No.

---

## 7. The ranked table — honest per-bit read cost

Primary key: **threshold decisions per bit** (binary = 1.000). Single-trit ternary encodings
all tie at 1.262; they are then ranked by their *secondary* costs (wire count, margin, null
freedom, extra time/energy). `→` = approaches from above.

| rank | encoding | decisions/bit | bits/wire | margin | null | beat binary's 1.0? |
|---:|---|---:|---:|---|---|---|
| 0 | **binary** (baseline) | **1.000** | 1.00 | full | — | *is* the floor |
| 1 | **ternary block code** (k=5…10) | **→1.0095** | 1.585·k/word | ~full (binary-decision decode) | n/a | **no — approaches, never crosses** |
| 2 | **one-hot 2-bit** (push/pull/null) | 1.262 | 0.79 | **full** (per-wire binary) | free (00) | no |
| 3 | **sign+magnitude direction** (1 wire, diode) | 1.262 | **1.585** | sign full; null halved | **free in gate (idle ≈0)** | no |
| 4 | **balanced 3-level PAM-3** (−V/0/+V) | 1.262 | 1.585 | **halved** (6.02 dB) | saddle (1.9 pJ) | no |
| 5 | **unbalanced {0,1,2}** | 1.262 | 1.585 | halved | level | no |
| 6 | **redundant signed-digit** (uses 11) | 1.262 | 0.79 | full | redundant 0 | no (buy: carry-free add) |
| 7 | **differential pair** (2 anti-polar lines) | 1.262 | **0.79** | halved + CMRR | = common mode | no (buy: CMRR only) |
| 8 | **PWM / time-domain** | 1.262 | 1.585 | halved | no pulse | no (adds time cost) |
| 9 | **3-phase / ω (Eisenstein)** | 1.262 | ~1.585 | halved | — | no (buy: namespace 3ⁿ) |

**Top:** block code (the only sub-1.26× entry, at 1.0095× but never ≤1.0), then one-hot and
direction (both *tie* the 1.262 floor with the best secondary profiles: full margin / best
wire). **Bottom:** differential pair (same decisions, loses wire economy) and PWM (same
decisions, adds symbol time); phase/ω ties them on read and wins nothing on that axis.

**[OURS — the ranking; every cell's number is DIRECT from the cited sections above.]**

---

## 8. Verdict — is the 1.26× representation-independent, or does an encoding break it?

**The floor survives every single-symbol permutation, and the one multi-symbol permutation
that moves the number moves it *toward* binary from above, not past it.** Three closing
claims:

1. **Representation-independent for single symbols — CONFIRMED, with a sharper mechanism.**
   `ThresholdLowerBound.lean`'s *conclusion* (binary minimizes decision-cost per bit, ternary
   1.26× worse) holds under every encoding tried here. Its *mechanism* (`b−1` ordered
   thresholds) is a special case of the correct count `⌈log₂b⌉`; the two coincide exactly at
   b=3 (`2 = 2`), which is why the file's b=2-vs-b=3 result is immune to the mechanism error
   (`meta_math.md` §1.3). No encoding can name 1 of 3 states in one binary test, because
   `3 ≠ 2^k`. **[DIRECT — `ThresholdLowerBound.lean`; `meta_math.md` §1.3/§2.]**
2. **The floor is a *per-symbol* floor, not a *per-bit* law.** Block coding (§6.1) relaxes it
   to `⌈k·log₂3⌉/(k·log₂3) → 1⁺`. So the honest theorem is: *ternary per-decision cost
   approaches binary's from above as the block grows, and equals it only in the limit* — it
   can **match**, never **beat**. The brief's "≤ binary" is answered **no**, with the block
   code as the sharpest near-miss. **[DIRECT arithmetic; OURS for the reframe.]**
3. **The only under-floor mechanism is a *device*, not an encoding.** A single native 3-way
   decision (SET Coulomb read, RTD load-line, AAT peak) is the sole path below 2 decisions —
   and its honest floor is **~1.5–2×** per bit, not the 0.63× that `1/log₂3` naïvely gives,
   because the 3-level SNR margin forces ~2× the toggle energy (`radix_lower_bound.md` §1/§3,
   `lowswing_diode.md` §6). No encoding reaches it; no fabricated device reaches it either.
   **[DIRECT for the arithmetic; the ~1.5–2× is OURS/ANALOGY per `device_circuit.md` §7.2.]**

**Bottom line:** I tried to break the floor by permuting the encoding — one-hot, 3-level,
unbalanced, 2's-complement, four null placements, differential/pair/sign+magnitude, level/
direction/time/phase, plus block codes, redundant signed-digit, charge-domain, and SCL. **I
did not break it.** The closest I got was the block code at **1.0095×** (k=5), which
approaches but never reaches binary. The 1.26× is representation-independent for single
symbols, degrades gracefully (not catastrophically) under block coding, and the measured
3.4–33× compute loss is dominated by swing² (7.8×), crowbar (6.8×), and receiver (2.54×)
factors that **no encoding permutation touches** — the floor is only 3.8% of the measured gap
(`radix_lower_bound.md` §2.3).

---

## 9. Calibration ledger

| claim | calibration |
|---|---|
| `⌈log₂3⌉ = 2`; no single binary test names 1 of 3 states | **DIRECT** — counting identity; `meta_math.md` §2 |
| 1.26× = 2/log₂3 = 2·ln2/ln3 | **DIRECT** — `ThresholdLowerBound.lean`, proved |
| `b−1 = ⌈log₂b⌉` exactly at b=3 (mechanism error immaterial at b=3) | **DIRECT** — `meta_math.md` §1.3 |
| one-hot: 2 decisions at full margin; 0.79 bits/wire (+26%) | **DIRECT** — `gate_area.md`, `meta_mishandled.md` §6 |
| 3-level margin `V_swing/4` (6.02 dB); ~2× energy at fixed BER | **DIRECT** — `device_physics.md` §2.3, `differential_noise.md` §2 |
| null-as-absence free on wire (0.05 pJ), idle ≈0 in diode gate | **DIRECT** — `ENERGY_RESULTS.md`, `diode_gates.log` |
| null-as-mid-level shoot-through 1.9 pJ/toggle | **DIRECT** — `polar_gates.md` |
| direction ≠ free: needs regeneration + null decision + V_d·I | **DIRECT/OURS** — `meta_math.md` §4; measured 2.54× (`gate_energy.md`) |
| differential pair: 2 wires = 0.79 bits/wire; CMRR ≠ spacing | **DIRECT** — `differential_noise.md` §1–§4 |
| sign+magnitude erasure `k_B T ln 4` = 1.26× worse/bit | **DIRECT** — `meta_math.md` §3 arithmetic |
| PWM-5 0.93–1.29× vs fair binary | **DIRECT** — `fair_binary.md` §3 |
| block-code table `⌈k·log₂3⌉/(k·log₂3)` | **DIRECT** — arithmetic computed here; the "≥1 for all k" is `⌈x⌉ ≥ x` |
| block-code latency/area cost | **OURS/SPECULATION** — uncounted |
| redundant signed-digit buys carry-free add, not read savings | **OURS/ANALOGY** — Kawahito 1990 via `analog_polar.md` §2 |
| native 3-way device floor 0.63× vs honest ~1.5–2× | **DIRECT** identity for 0.63×; **OURS/ANALOGY** for ~1.5–2× (`device_circuit.md` §7.2, `lowswing_diode.md` §6) |
| measured gap 3.4–33×; floor is 3.8% of it; swing² 7.8×, crowbar 6.8×, receiver 2.54× | **DIRECT** — `radix_lower_bound.md` §2, `fair_binary.md` §4 |
| "the 1.26× lives on the decision-count axis, encodings move only quality" | **OURS** — the two-axis frame; legs DIRECT |

---

## TODO / not covered / caveats

- **No new simulation, no new Lean.** This file permutes *encodings on paper*; the only new
  number is the block-code table (§6.1), which is exact arithmetic. The one experiment that
  would convert the block-code "near-miss" from a counting claim into a hardware claim is a
  word-level fair fight (`meta_mishandled.md` §9.6): a `k=5`-trit decode against 8 bits, to
  see whether the decode latency/area eats the 0.0095× it saves. **[SPECULATION.]**
- **The block code's decoder is uncosted.** `3^k`-way decode is exponential in k; k=5 (243
  states) is the practical sweet spot before the decoder area blows up. Whether 1.0095×
  survives the decoder is unmeasured and is the single honest remaining encoding lever.
- **The "full margin" credit to one-hot is margin-only.** One-hot pays it in *wires* (26%),
  and wire cost is not zero — `gate_area.md` counts it as the 2.00× MIN/MAX area. The ranking
  in §7 is per *decision*, and a per-*area* or per-*energy* ranking would reorder the top
  three; the decision floor is the invariant this file is testing.
- **`÷1.585` is uniform-source entropy.** Every per-bit number inherits the corpus convention
  (`audit_measurement.md` Bias 2b). Null-heavy traffic would lower ternary's *average* energy
  (the transport win), but the *decision count* — the floor under test — is occupancy-
  independent for the equiprobable codebook. A *shaped* (non-uniform) ternary code would
  change the per-symbol entropy and hence the per-bit constant, exactly as `meta_math.md`
  §TODO flags; out of scope here.
- **Adiabatic/reversible is untouched.** This file is about the *decision-count* floor in
  irreversible read. In the reversible regime the bound is a different statement and is
  genuinely open for both radices (`meta_math.md` §TODO).

*This file invents no measurement and no proof; the block-code table is the only new
computation, and it is exact arithmetic on `⌈log₂(3^k)⌉/(k·log₂3)`.*
