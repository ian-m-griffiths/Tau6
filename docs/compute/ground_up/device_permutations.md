# Device permutations — does ANY device configuration make ternary ≤ binary?

**2026-08-30 — Tau Architecture, assumption-permutation pass.** ONE question, asked
bloody-mindedly: *take the DEVICE assumption as the free variable, vary it across every
mechanism the corpus knows, and see whether any configuration pushes balanced-ternary
compute below binary per bit — i.e. whether the 2-threshold tax can be escaped by device
choice rather than by code choice.*

**Ground truth read first:** `device_physics.md` (3-minima requirement, Landauer),
`native_device_aat.md` (AAT/AFE verdict), `analog_polar.md` (current-mode verdict),
`diode_gates.md` (direction receiver), `meta_transistor.md` (the code-vs-device reframe),
`gates.md` (gate survey), `fair_binary.md` (honest binary baseline), `radix_lower_bound.md`
(the Π-factor decomposition), `meta_math.md` (the representation-independent 1.26×).

**Calibration legend** (house standard):

- **DIRECT** — measured/proved in-repo, or a citable literature/textbook identity.
- **ANALOGY** — structural resemblance, not identity.
- **OURS** — our design claim; follows from DIRECT but not independently established.
- **SPECULATION** — untested hypothesis, or an order-of-magnitude estimate with no cited source.

---

## 0. The blunt verdict, first

**No device permutation puts ternary ≤ binary per bit.** I tried the four the brief named
(diode-direction, FET-polarity, multi-threshold, anti-ambipolar) plus four of my own
(heterogeneous per-function devices, data-gated event null, charge/current domain,
superconducting flux). Every device either (a) **pays the 2-threshold tax by construction**
(two comparators / two dead-zone devices / two wires — measured 1.21× to 3.5× per bit), or
(b) is a **genuine 1-measurement device** (AAT / SET / RTD / AFE / RFET) that resolves three
states in one read **but is unfabricable at VLSI and/or energy-losing and/or memory-only**.
The `0.63× = 1/log₂3` "native floor" is flattery: it assumes a 1-measurement device that
costs exactly like one binary threshold, and no such device exists — the honest native floor
is **~1.5–2× per bit**, and every demonstrated "native" device sits above it. The 2-threshold
tax survives every device permutation, exactly as the project's measurements say.

The one genuine sub-floor result I found is a **cheat, and I report it as such**: the
2-wire static-CMOS *negation* gate measures **1.21× per bit** — slightly *below* the 1.26×
decision-count floor — because its per-decision energy is cheaper than the floor's "1 decision
= 1 full binary op" idealization. It is still **above binary (1.0×)**, so it does not flip the
verdict; it just means the floor is a lower bound on the *decision count*, not on every
realized *energy*. **[DIRECT numbers; OURS reading of why 1.21 < 1.26.]**

---

## 1. The floor being attacked, and the only way under it

Two bounds, exactly 2× apart, and the whole device question lives between them
(`radix_lower_bound.md` §1):

| model | measurements `m(3)` | cost per bit | meaning |
|---|---|---|---|
| **binary substrate** (2-level device reads 3 states) | 2 | **1.26×** (`2/log₂3 = 2·ln2/ln3`) | ternary 26% *worse* per bit — proved, representation-independent |
| **native 3-state** (1 device, 1 read) | 1 | **0.63×** (`1/log₂3`) | ternary 37% *cheaper* — *iff* the one read costs like one binary threshold |

**[DIRECT — `ThresholdLowerBound.lean` for 1.26×; `meta_math.md` §2 shows it is the same
number in all three costings (thresholds, binary decisions, 2-cell erasure `k_B T ln 4`).
The 0.63× is arithmetic; the "one read ≈ one binary threshold" premise is the MODEL.]**

The escape condition (`meta_math.md` §6 T-new-2): ternary beats binary per bit **iff** a
single native 3-way discrimination costs **< 1.262×** a single binary discrimination. Every
permutation below is tested against exactly that inequality. The floor is *not* about energy
per se — it is about the **decision count `⌈log₂3⌉ = 2`**: one yes/no answer cannot name one
of three states, and re-encoding as sign×magnitude (`push/null/pull`) only relabels the two
decisions (sign + presence), never reduces them. **[DIRECT — `meta_math.md` §2, §4.]**

---

## 2. Permutation 1 — which read mechanism is cheapest: diode-direction vs FET-polarity vs multi-threshold vs anti-ambipolar

**The assumption being varied:** *the physical mechanism that performs the READ* — the act of
deciding "which of {−1, 0, +1} arrived." Binary's read is one threshold (one decision per bit).
Ternary's is two. The question is whether a different mechanism makes the two cheaper, or
collapses them to one.

### 2.1 Diode-direction (the current junction)

**Assumption.** Two passive diodes rectify push vs pull; null conducts through neither. Sign is
decided *by the junction's physics*, not by a comparator against a reference.

**Read-cost.** 2 diodes + 2 elevated-`|Vt|` dead-zone restore devices. **The null is genuinely
free to *hold*** — measured idle `1.5–3.8×10⁻¹⁹ J` over 75 ns, indistinguishable from noise
(`diode_gates.md` §3, DIRECT). **But the read is still two decisions**: which diode fired
(sign) + did anything fire at all (null-vs-active, the dead zone). The direction receiver
removed the *sense-amp* tax (the clocked 2×7-T comparator + metastable-null shoot-through) but
**not** the *information* tax — "3 ordered states still need 2 boundaries, still 2 devices per
polarity" (`diode_gates.md` §5, DIRECT measured for the removal, OURS for the boundary count).

**Measured read energy.** `dd_not` = 54.2 fJ/toggle (null↔+1) vs fair binary NOT 6.94 fJ →
**7.8×/toggle, 4.9×/bit**; full-swing +1↔−1 = 368.7 fJ → **33.5×/bit** (`fair_binary.md` §4,
DIRECT). The 7.8× is dominated by a **resistive null-return termination** (17.31 µA DC through
two 100 kΩ keepers — `lowswing_diode.md` §4, DIRECT), not by the diodes. The gate **dies at
VDD ≈ 0.82 V** (fixed `|Vt|`) or **0.40 V** (scaled `|Vt|`) because the diode forward drop
`Vf ≈ 0.24 V` is a fixed voltage that does not scale with swing (`lowswing_diode.md` §3,
DIRECT).

**Beats 1.26×? NO.** It gives a free null *hold*, not a free null *read*, and the read lands at
4.9×/bit (cheapest toggle), 3.5× at matched low swing. It is a **cheaper 2-decision read than
the sense amp** (4.9–14.3× → 3.4–4.9×), but it does not cross 1.0×, let alone 1.26×.

### 2.2 FET polarity (reconfigurable-polarity FET / RFET)

**Assumption.** The trit *is* the majority-carrier sign: n-conduction = push, off = null,
p-conduction = pull. One 3-terminal device whose conduction polarity *is* the answer.

**Read-cost.** Conceptually the best match to Tau ("polarity is value" — `meta_transistor.md`
§1.3, DIRECT mechanism). One device, one gate. **But** the null is the *off* state, and
distinguishing "off" from "n" and "p" still requires a **presence test** — a threshold on
conduction that no polarity mechanism supplies for free. So the read is **1 sign decision
(which polarity) + 1 presence decision (null-vs-conducting) = 2**, exactly the floor's count.
**[OURS — the sign decision is native, the null decision is not; the RFET's 3 states are
`n/off/p`, so "off" is the absence of conduction, and absence must be *measured*.]**

**Fabrication.** 2D (WSe₂ charge-trapping, black phosphorus) / SOI-Schottky — no VLSI path
(`meta_transistor.md` §1.3, DIRECT mechanism / SPECULATION fab). No switching energy, no
endurance of the polarity program published.

**Beats 1.26×? NO.** It is the *cleanest conceptual* device but does not reduce the decision
count below 2 (the null still needs a read), and it is unfabricable.

### 2.3 Multi-threshold CMOS (2 Vt → 3 driven levels)

**Assumption.** Two turn-on points on one amplitude axis give three driven levels.

**Read-cost.** **2 comparators = 2 thresholds — the tax in device form, by construction.**
Measured receiver tax **2.54×** (61.87 vs 24.35 fJ, two sense amps vs one — `gate_energy.md`,
DIRECT). FDSOI back-bias collapses "4 Vt flavors = 4 masks" to "1 recipe + back-bias"
(`meta_transistor.md` §1.4, DIRECT fab / OURS as a ternary cell), but it moves the
*fabrication* cost, not the *decision count*: the read is still two thresholds.

**Beats 1.26×? NO.** It *is* the 1.26× realized. It is, however, the **only fabricable**
read of the four.

### 2.4 Anti-ambipolar transistor (AAT)

**Assumption.** One device whose transfer curve is a non-monotonic hump — three output levels
from band alignment, two "knees" free of engineered thresholds.

**Read-cost.** **The only device in this permutation that collapses 2 thresholds → 1
measurement.** One hump, one read. **[DIRECT mechanism — `native_device_aat.md` §1.]** But the
middle state is a **resistive divider with both devices conducting** (static current), no AAT
paper reports a switching energy, and every demo is 14 V organic (nA) or 0.1–0.5 V at **1 Hz**
(pA–nA). The break-even is 11.0 fJ/toggle (`= 1.585 × 6.94`); every AAT is orders of magnitude
above it, on static current × slow switching, not `½CV²`. **[DIRECT numbers; `≫1.585×` bound is
OURS — `native_device_aat.md` §3.]**

**Beats 1.26×? NO.** It beats the *decision count* (1 read) but not the *cost* (≫ 1.26×, and
unfabricable). It is the purest live counterexample to "one device per threshold," and it still
loses on energy + fab.

**Permutation-1 verdict:** cheapest realized read is the diode-direction (passive, null-free
idle), and it is 3.4–4.9×/bit. The only 1-measurement read (AAT) is unfabricable and energy-
losing. **None gives a free null *read***; the diode gives a free null *hold* only.

---

## 3. Permutation 2 — heterogeneous devices (different transistors for push vs pull vs null)

**The principal's assumption:** *"complex transistors doing different things"* — use a
different device per function (a diode for direction, an elevated-|Vt| pair for the null
dead zone, standard CMOS for restore), and let each be optimal for its job.

**The honest finding: the corpus already built this, and it does not beat the uniform device.**
The diode-direction gate *is* the heterogeneous design — Schottky rectifier + elevated-`|Vt|`
NMOS/PMOS dead zone + standard CMOS restore (`diode_gates.md` §1). Its measured per-bit cost
(3.4–4.9×, cheapest toggle; 3.5× matched low swing) is **worse than the uniform 2-wire
static-CMOS emulation** (+21% negation / +45% min / +53% max / +214% sum — `gate_energy.md`,
DIRECT). So per-function device choice **loses to a uniform device** on the gate axis.

Why heterogeneity cannot win, stated precisely **[OURS on the mechanism; DIRECT on the numbers]:**

1. **Heterogeneity optimizes the *constant* of each decision, not the *number* of decisions.**
   A diode is a cheaper *sign* detector than a comparator; an elevated-|Vt| device is a cheaper
   *null* dead zone than a 0-V comparator. But three states still require **two** decisions, and
   two optimized decisions cost `2 × (cheap constant)`, which is still `> 1 × (binary constant)`
   once the diode drop + resistive termination are added. The measured result is exactly this:
   the diode gate traded the sense-amp tax (2.54×) for a diode-drop + termination tax (7.8×).
2. **The null rail is the wall, and heterogeneity does not supply it.** The mod-3 sum needs an
   explicit `null = NOT(push OR pull)` signal; the direction receiver emits null only as the
   *absence* of both rails. The `tsum_cell.md` cell pays **88 devices, 898 fJ/toggle, 1.42× a
   binary full adder per bit** to add that null rail (`tsum_cell.md` §5, DIRECT). No per-function
   device choice makes the third decision free — the third decision *is* the tax.
3. **Heterogeneity *adds* a fabrication ask, it does not remove one.** Elevated-|Vt| (multi-Vt
   process), Schottky (TT≈0), small CJO≈2fF — three asks binary does not carry
   (`diode_gates.md` §6, OURS/SPECULATION). A uniform device needs none of them.

**Beats 1.26×? NO.** Heterogeneous per-function devices are a real and measured *design space*
(the diode gate), and their best result (3.4–4.9×/bit) is above the uniform device's best
(1.21×/bit), above 1.0×, and above the 1.26× floor.

---

## 4. Permutation 3 — native 3-state storage (memristor / FeFET / AFE / AAT / RFET), honest energy/density/endurance

**The assumption being varied:** *the state is stored in a non-amplitude degree of freedom
(resistance, polarization, polarity), so three states are native — does that make the
storage/read axis beat binary?* This is the "0.63× native floor" question, tested honestly.

**The honest read-axis accounting.** A native 3-state cell stores `log₂3 = 1.585` bits in one
device — a genuine **density** win (fewer devices per bit). But the *read* of that cell is
still a discrimination among three states = **2 thresholds** (or a resistance/polarization
sense that costs ≥ a binary read), and the 3 levels sit closer together than binary's 2, so the
**SNR penalty applies** (`device_physics.md` §5.3). Per bit, the read cost is `2/log₂3 = 1.26×`
*at best*, and worse once variability/endurance are charged. **Density ≠ energy: the native
floor's 0.63× counts devices, not joules, and it silently drops the read's second threshold.**

Per-device honest ledger (all DIRECT from `native_device_aat.md` §2–4, `device_physics.md` §1–3,
`meta_transistor.md` §1.5 unless tagged):

| device | 3 states are | gain? | energy | endurance | read |
|---|---|---|---|---|---|
| **memristor / RRAM** | 3 resistance levels | no (passive) | write = set/reset; read = resistance sense | 10⁶–10¹², read-disturb, variability | 2-level sense ≥ binary read |
| **FeFET (ferroelectric FET)** | polarization shifts Vt | yes (gate) | write/read energy **NOT REPORTED** | >10⁵ cyc, >10⁴ s @ 65 °C | stored P read *by threshold* (2 levels) |
| **AFE HZO** | +P / 0 / −P | no (capacitor) / read-only (FET) | write is AFE↔FE cycling | 10⁸–10⁹ w/ recovery; fatigue is the AFE↔FE cycle | 1 ground state + 2 field-induced metastable |
| **AAT** | transfer hump | yes, but static-current mid | none reported | n/a (lab demo) | 1 measurement, ≫1.26× |
| **RFET** | n / off / p | yes | none reported | polarity-program endurance open | 1 sign + 1 presence = 2 |

**The calibration correction that matters** (`native_device_aat.md` §2.2): the AFE's "3
minima" is **OVERSTATED** — at zero field there is **one** ground state (`P = 0`); the `±P_r`
states are **field-induced metastable** FE remnants, not degenerate wells. A true static
triple-well needs FE+AFE *coupling* (Zeng 2024, 8 states — a capacitor, passive). So the
"native 3-state" ideal is a **memory part**, not a logic transistor, and its "3 states" are
one ground state plus two you have to *write and maintain*.

**Beats 1.26×? NO on the read axis.** Native 3-state storage buys **density** (1.585 bits/cell)
and nothing on the read-energy axis: the read is still ≥ 2 thresholds per cell, endurance and
variability are worse than CMOS, and every device lacks gain (storage ≠ logic) or is
unfabricable. The "0.63× native floor" is **flattery** — it is the density ceiling masquerading
as an energy floor. The honest native-device energy floor is **~1.5–2× per bit**
(`device_circuit.md` §7.2, OURS/ANALOGY), from the 3-level SNR penalty alone.

---

## 5. Permutation 4 — junction count: 1-junction polarity vs 2-junction complementary vs multi-terminal

**The assumption being varied:** *does adding terminals / conjugation reduce the 2-threshold
read?* (A 1-junction push/pull device, a 2-junction complementary pair, a multi-terminal
dual-gate / AAT / independent-gate stack.)

**The honest answer: no — except in exactly one case, and that case fails elsewhere.**
The 2-threshold tax is a property of the **1-D ordered amplitude code**, not of the junction
topology (`meta_transistor.md` §4.1, the category-error correction). Adding terminals changes
*which* physical knob encodes the state, not *how many* decisions name it:

| junction topology | device | read | reduces the 2-threshold read? |
|---|---|---|---|
| **1-junction polarity** | push/pull/null (the current junction) | which channel conducts + presence | **no** — 2 decisions (`junction_algebra.md` Axiom 0; `meta_math.md` §4) |
| **2-junction complementary** | CMOS inverter pair | 1 threshold | **yes for binary** (1 decision/bit) — but complementary gives only **2** states; there is no "3-junction complementarity" that yields 1 decision for 3 states |
| **multi-terminal, monotonic** | dual-gate FET, IG-FinFET, FDSOI back-bias | 2 thresholds (2 Vt) | **no** — moves the *fab* cost (1 recipe + back-bias) but the read is still 2 thresholds |
| **multi-terminal, non-monotonic** | AAT (series n/p stack) | 1 hump | **the only yes** — 1 measurement — but static-current mid + unfabricable |

**[DIRECT mechanism for each row; the "no 3-state complementarity" point is OURS/ANALOGY.]**

The deep reason the junction count does not help: **complementarity (CMOS) is what buys
binary's 1-decision read — one device always off, so the read is "which one is on."** A
3-state generalization would need "exactly one of three devices on," but no 2-terminal
junction supplies a third *mutually-exclusive* conduction state — you get either 2 states
(complementary) or 3 states via 2 thresholds (multi-Vt) or 1 non-monotonic hump (AAT, which
needs a load and draws static current). The AAT is the lone device that turns "more terminals"
into "fewer decisions," and it is the lone device that is unfabricable and energy-losing.

**Beats 1.26×? NO.** Junction/terminal count is not the free variable; the **decision count**
is, and it is set by the code (`3 ≠ 2^k`), not by how many terminals carry it.

---

## 6. Four more permutations of my own (bloody-minded extras)

### 6.1 Data-gated event null (no-pulse = null, self-timed read)

**Assumption.** Re-encode null as *absence* and gate the receiver off when nothing arrives, so
the null's read cost → 0. **[`null_default.md` §3 — the scheme.]**

**Honest result.** This reduces the **average** cost under null-heavy data — it is exactly the
measured **transport win (2.7–6.3× vs fair binary)** — but it does **not** reduce the
*per-non-null* read: when a push/pull fires, two thresholds still resolve it, and the null
still must be *detected* as "no pulse" to arm the completion handshake. It is also
**radix-agnostic** (a binary link that idles pays ~0 too — `fair_binary.md` TODO #5). It breaks
the floor only on a *workload* basis, never on the read axis. **[DIRECT transport numbers;
OURS on the "workload not read" framing.]**

**Beats 1.26×? NO** (on the read axis it leaves the 2-threshold count untouched — `null_default.md`
TODO "does not touch the 2-threshold tax itself").

### 6.2 Charge / current domain (KCL-sum, current-null)

**Assumption.** Move the trit to signed current `{+I, 0, −I}`: the mod-3 sum is a free KCL
junction, and null = 0 A is a native dead zone. **[`analog_polar.md` — the survey.]**

**Honest result.** Two real wins (free sum, free null) and two surviving costs (the **wrap**
`σ = ±2 → ∓1` is still a 2-threshold measurement at `±1.5 I₀`; static current-mode draws tail
current in every state). It relocates the tax, does not remove it. **[DIRECT KCL; OURS on the
wrap being the tax.]** Not a floor-breaker.

### 6.3 Superconducting flux (phase-slip / RSFQ multi-level)

**Assumption.** Flux quantization gives native M-state minima (M flux states), the "M-stable"
row of `device_physics.md` §4.

**Honest result.** A genuine native-M-state mechanism — but **cryogenic**, and the read of M
states is still `⌈log₂M⌉` decisions. Out of scope in the corpus (`device_physics.md` §8 TODO),
and the win belongs to the *mechanism* (superconducting speed/energy), not to the radix.
**[SPECULATION — no number in-repo; flagged, not claimed.]** Not a floor-breaker on the read
axis.

### 6.4 Multi-trit block packing (code, not device)

**Assumption.** Pack 3 trits = 27 states (vs 5 bits = 32) to amortize the `0.415`-bit waste.

**Honest result.** This is a **code** change, not a device change, and it cannot help here: it
amortizes the *wasted state* (`3 ≠ 2^k`) across symbols but does not reduce the per-decision
floor below 2 for a single symbol, and the `11` canary state (`storage.md`) is already the
only free use of the fourth corner. **[`meta_math.md` §TODO; OURS.]** Out of the device
question's scope; noted only for completeness.

---

## 7. Ranked table — every device permutation, by read-cost per bit

Ordered by *how close to beating binary* (lower cost-per-bit = higher rank). "Read-cost vs
binary" is per bit, binary = 1.00×. Floor = 1.26× (2/log₂3); "0.63×" = flattery ceiling.

| rank | device / permutation | # decisions | read-cost vs binary (per bit) | fabricable? | verdict |
|---|---|---|---|---|---|
| 1 | **2-wire static CMOS, negation** (uniform) | 2 (2 sense amps) | **1.21×** (measured) | **yes** | closest, still above 1.0× |
| 2 | 2-wire static CMOS, min/max/sum | 2 | 1.45× / 1.53× / 3.14× | yes | the fabricable floor |
| 3 | **diode-direction (heterogeneous)** | 2 (diode + dead zone) | 3.4–4.9× (cheapest) / 3.5× (matched low swing) | partial (multi-Vt + Schottky ask) | free null *hold*, not *read* |
| 4 | **native 3-state storage** (memristor/AFE/FeFET) | 2 (sense) | ≥ 1.26× read; density 1.585×/cell | mem/AFE yes, no gain | density ≠ energy |
| 5 | **AAT** | **1** (hump) | ≫ 1.26× (no number; static current) | **no** | only 1-measurement device, loses on energy |
| 6 | **multi-threshold CMOS / FDSOI** | 2 | 2.54× receiver; ~1.5–2× floor | **yes** | the tax in device form |
| 7 | **RFET** | 2 (sign + presence) | unmeasured | no | best conceptual match, null still read |
| 8 | **SET** | 1 (occupancy) | aJ-scale, but ns–µs + cryo | no | thermodynamic existence proof only |
| 9 | **RTD (2-peak)** | 1 (load line) | ~ps, but DC-hungry (NDR active) | no | speed-dense, static-power-broken |

**[Calibration: rows 1–4 DIRECT (gate_energy.md, fair_binary.md, lowswing_diode.md,
native_device_aat.md); row 5 DIRECT mechanism + OURS bound (no switching energy exists);
rows 6–9 DIRECT from device_physics.md / meta_transistor.md, with the "unmeasured" and
"cryo" flags explicit.]**

**The table's top and bottom:** the top (closest to binary) is the **uniform 2-wire negation at
1.21×** — a binary-substrate result, *not* a native-device result. The bottom is the
**native-device family (AAT/SET/RTD)** — the only devices that reduce the decision count to 1,
and the only ones that are unfabricable and/or energy-losing. **The ranking inverts the
principal's intuition**: the more "native" the device, the further it is from beating binary,
because "native" moves the cost from the (cheap, fabricable) decision count to the (expensive,
non-fabricable) physics of the third state.

---

## 8. Verdict — does ANY device permutation make ternary ≤ binary?

**No. The 2-threshold tax survives every device permutation, exactly as the project's
measurements say, and the attempt to break it is a clean, honest failure.** Three calibrated
conclusions:

1. **The floor is a decision-count fact, not a device fact.** `⌈log₂3⌉ = 2` binary
   discriminations per trit = `2/log₂3 = 1.26×` per bit, and it is representation-independent
   (ordered levels, sign×magnitude, and 2-cell erasure all give the same number — `meta_math.md`
   §2, DIRECT). No junction topology, no per-function device mix, no storage degree of freedom
   changes the *count*. The only escape is a single native 3-way decision costing < 1.262× a
   binary threshold (`T-new-2`), and **no such device exists**: AAT/SET/RTD resolve 3 states in
   1 measurement but are unfabricable and energy-losing; AFE/RFET either lack gain or keep the
   null as a second decision.

2. **The "0.63× native floor" is flattery, and the permutation pass proves it from the inside.**
   `0.63× = 1/log₂3` assumes one read costing exactly like one binary threshold. Every candidate
   that *could* realize one read (AAT static-current mid, SET cryogenic, RTD DC-hungry, AFE
   memory-only) costs strictly more than that. The honest native floor is **~1.5–2× per bit**
   (`device_circuit.md` §7.2), and even that is optimistic — it omits the SNR penalty's exact
   curve and the native devices' own variability. **[OURS on the synthesis; each term DIRECT.]**

3. **The one sub-1.26× number (negation at 1.21×) is not a win and I will not dress it as one.**
   It is the *uniform 2-wire* gate, not a native device; it sits at 1.21× because the floor's
   "1 decision = 1 full binary op" idealization is slightly generous to binary. It is still
   **above 1.0×** — ternary negation loses to binary NOT even though the *logic* is a free wire
   swap, because the *read* is two thresholds. That single fact is the whole verdict in one
   sentence: **the device cannot be made cheap enough, because the cheapness was never in the
   device — it is in the code (`3 ≠ 2^k`), and the code is fixed.**

**Bottom line for the program:** ternary remains a **transport / representation economy**
(null-free wire, 1.585 bits/symbol), not a compute economy. The device permutation space is
now enumerated and closed: no diode, FET, multi-threshold, AAT, memristor, FeFET, AFE, RFET,
SET, RTD, junction topology, or heterogeneous mix puts ternary ≤ binary per bit on the read
axis. The 2-threshold tax is a coding fact wearing a device costume, and it survives every
costume change.

---

## 9. Calibration ledger (condensed)

| claim | calibration |
|---|---|
| floor 1.26× = 2/log₂3, representation-independent | DIRECT — `ThresholdLowerBound.lean`, `meta_math.md` §2 |
| escape condition: 1 native read < 1.262× binary | OURS (reframe of DIRECT counting) — `meta_math.md` T-new-2 |
| diode read 3.4–4.9×/bit (cheapest), 33.5× (full swing), 3.5× (low swing) | DIRECT — `fair_binary.md` §4, `lowswing_diode.md` §6 |
| diode null idle ≈ 0 (1.5–3.8e-19 J/75 ns); termination 17.3 µA | DIRECT — `diode_gates.md` §3, `lowswing_diode.md` §4 |
| 2-wire emulation +21%/+45%/+53%/+214% per bit; receiver 2.54× | DIRECT — `gate_energy.md` |
| AAT: 1 hump, mid = divider, no switching energy, 14 V / 1 Hz demos | DIRECT — `native_device_aat.md` §1, §3 |
| AFE "3 minima" = 1 ground + 2 field-induced (overstated as 3 wells) | DIRECT — `native_device_aat.md` §2.2 |
| SET aJ-zJ but cryo + ns–µs; RTD 1.5 ps but DC-hungry | DIRECT — `device_physics.md` §1, §3 |
| FDSOI back-bias = 1 recipe multi-Vt, still 2 thresholds | DIRECT fab / OURS cell — `meta_transistor.md` §1.4 |
| native-device energy floor ~1.5–2× per bit (not 0.63×) | OURS/ANALOGY — `device_circuit.md` §7.2, `lowswing_diode.md` §6 |
| heterogeneous (diode gate) loses to uniform (2-wire) | DIRECT numbers / OURS synthesis — §3 |
| junction count does not change decision count | OURS/ANALOGY — `meta_transistor.md` §4.1 |
| superconducting flux = native M-state, cryo, out of scope | SPECULATION — `device_physics.md` §8 TODO |

---

## TODO / not covered / caveats

1. **No new measurement and no new Lean work here.** Every number is read from the corpus
   (`gate_energy.md`, `fair_binary.md`, `lowswing_diode.md`, `diode_gates.md`, `tsum_cell.md`,
   `native_device_aat.md`, `device_physics.md`, `meta_math.md`). This is an *enumeration and
   evaluation* pass, not a simulation pass.
2. **The one experiment that could still overturn §8 is unrun.** `meta_math.md` E-new-1: a
   diode-only receiver (no sense amp) + a single null comparator, fair-fought at fixed BER.
   Its prediction is ≥ ~1.3× binary; if it *measured* ≤ 1.0×, sub-claim (c) of the principal's
   "one-channel" argument would reopen. Until then the 2.54× prior stands.
3. **The "1.21× < 1.26×" subtlety is stated but not reconciled against the theorem.** The floor
   is a *decision-count* lower bound; the 1.21× is a *realized energy* whose per-decision cost
   is slightly cheaper than the floor's idealization. A precise statement of "floor = lower
   bound on count, not on every energy" is worth one clean paragraph downstream; I have not
   formalized it.
4. **Reversible/adiabatic is untouched**, as in every sibling file. The Landauer leg is
   erasure-only; whether ternary composes with adiabatic logic differently than binary is open
   and could change the *energy* (not the *count*) in the reversible regime — for both radices.
5. **The RTD/SET/AAT "energy" cells are bounds, not measurements** — no switching energy exists
   for AAT (DIRECT absence), RTD is an order-of-magnitude estimate (SPECULATION), SET is the
   only near-Landauer number and it is cryo-bound (DIRECT).
6. **Mismatch/leakage/body-diode are absent** (LEVEL=1) everywhere the corpus measured — the
   ternary side is systematically *optimistic*, so every "3.4–4.9×" here is a floor, not a
   ceiling, on the honest loss.

*This file invents no number: it re-ranks the corpus's measured and proved ground truth across
the device-permutation axis. The conclusion — the 2-threshold tax survives every device — is a
synthesis, and every quantitative leg of it is DIRECT-cited above.*
