# The mod-3 sum (⊕) in diode-direction form — the null rail, measured

**2026-08-29, ngspice 44.2, measured. Netlist: `circuit/tsum_cell.cir` (exit 0, no
warnings, no DC shorts — held-null idle ≈ 1.2×10⁻¹⁷ J / 75 ns).**

**Calibration legend** (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured (this run's `circuit/tsum_cell.log`) or counted from the netlist.
- **ANALOGY** — structural parallel, not identity.
- **OURS** — design claim / interpretation supported by DIRECT but not itself measured.
- **SPECULATION** — untested hypothesis, flagged as such.

---

## 0. One-line answer

**The mod-3 sum *is* buildable in diode-direction form — but only by adding the one piece the
direction receiver cannot produce: an explicit null rail `NOT(push OR pull)`.** The cell costs
**88 devices (84 T + 4 D)** and **898 fJ/toggle** (cheapest null↔+1 toggle) / **1494 fJ/toggle**
(full +1↔−1 swing), and it resolves **all 9 input pairs correctly** with a clean null return
(0.069 V at the null checkpoint). That is **7–22× the devices and 7–17× the energy** of the other
diode-direction gates, and — per output bit — **≈1.4× a binary full adder's energy / ≈2× its
devices** (or ≈2.3× energy / ≈6× devices against the true 2-input analog, binary XOR). **So `⊕` is
the wall in the way the docs predicted — but a bounded wall, not the 4.9–14.3× energy catastrophe
of the sense-amp receiver: the diode receiver + a *static* null detector removes that, and what
remains is the intrinsic cost of a third decision the direction receiver does not natively make.**

---

## 1. Why the null rail is the gap (and what this cell adds)

The diode-direction receiver (`dd_recv`, `circuit/diode_gates.cir`) splits one polar wire into two
rails: `rA` fires on push (0 → +0.76 V), `rB` fires on pull (0 → −0.76 V), and **neither** fires
on null (no current → free). That is exactly enough for the lattice gates (`NOT`/`NAND`/`NOR`/`MIN`/
`MAX`, measured 54.2–122.2 fJ/toggle): their output branches are conditions on *push* (gates the
elevated-Vt `N_HI`) and on *pull* (gates the elevated-Vt `P_HI`), so they never need the null as an
input.

The mod-3 sum is different. It is the F₃ **field** addition (truth_table.md §5.5), and its one-hot
push/pull equations are

```
sum.push = (pull_a & pull_b) | (null_a & push_b) | (push_a & null_b)
sum.pull = (push_a & push_b) | (null_a & pull_b) | (pull_a & null_b)
```

Four of the six terms contain **`null_a` or `null_b` as an explicit operand** — e.g. `sum=+1` for
`(0, +1)` and `(−1, −1)` must distinguish *null* from *+1* and *−1*. The direction receiver emits
null only as the joint **absence** of its two rails; there is no `null` rail to feed the logic.
That is the single gap `diode_gates.md` §7 declared ("not tractable in pure diode form"), and it is
the same reason `⊕` is irreducible: it is not regular (truth_table.md §3.2), so `{NOT,NAND,NOR}`
cannot generate it.

This cell closes the gap with a **static null-rail detector** — `z = NOT(p OR n)` — built from
restored push/pull signals, **not** from a 0-V comparator. Because the restore stages use the
elevated-Vt dead zone, the null is a *dead zone between two hard thresholds*, not a saddle: no
clock, no sense amp, no metastable-null shoot-through.

---

## 2. The cell

```
[polar wire] → [dd_recv: rA=rA push rail, rB=pull rail]          (passive, null free)
            → [restore: p = +VDD iff push, n = +VDD iff pull]     (elevated-Vt, dead zone)
            → [null rail: z = NOT(p OR n)]                        ← the new piece
            → [sum logic: sp = (na&nb)|(za&pb)|(pa&zb),           (static CMOS, 60 T)
                          sn = (pa&pb)|(za&nb)|(na&zb)]
            → [driver: wout = +VDD on sp, -VDD on sn, 0 on null]  (dead-zone push-pull)
```

Per input, the receiver (`t_recv`) is:

- **push restore** — `PMOS1(g=rA, src=+VDD)` is ON when `rA < +0.6 V` (not push), `N_HI(g=rA,
  src=−VDD)` is ON when `rA > +0.4 V` (push). The gap 0.4…0.6 V means the pair is **complementary
  with no overlap**, so there is no static contention and the held-null idle stays ≈0. `p =
  NOT(midp)` restores the push condition to full swing.
- **pull restore** — `P_HI(g=rB, src=+VDD)` ON when `rB < −0.4 V` (pull), `NMOS1(g=rB, src=−VDD)`
  ON when `rB > −0.6 V` (not pull); same complementary no-overlap structure → `n = +VDD iff pull`.
- **null rail** — `z = NOR(p, n)`, a static NOR₂.

The sum logic is the 6-term boolean form of the header, in static CMOS on ±VDD rails. The output
driver is `polar_gates.cir`'s dead-zone push-pull (`gp = NOT sp`, `gn = sn`).

**Device count (DIRECT, counted from the netlist):**

| stage | devices |
|---|---|
| 2 × `t_recv` (2 D + 8 T each) | 4 D + 16 T |
| sum logic (6 × and₂ = 36 T, 2 × or₃ = 24 T) | 60 T |
| output (`inv` + driver) | 4 T |
| **total** | **84 T + 4 D = 88** |

**The multi-Vt ask is unchanged from `diode_gates.cir`.** Only the *elevated-|Vt|* dead-zone
devices (`N_HI`/`P_HI`, |Vt|=1.4 V) are added to standard CMOS; no low-Vt flavor is required. The
two hard thresholds (the "two decision boundaries" of `device_physics.md` Law 1) live in the
receiver's restore stages, and the null rail is the third decision those two boundaries imply.

---

## 3. Method (fair-fight honesty, same rules as `diode_gates.cir`)

- **Rails:** everything on ±VDD = ±1.0 V. Binary `0=−1 V, 1=+1 V`; ternary `−1=−1 V, 0=0 V,
  +1=+1 V`. Same rails, same common mode.
- **Real output driver** (elevated-Vt/standard push-pull, V·I counted over a **full output cycle**:
  assert + release). No ideal current sources.
- **Real (passive) receiver:** the next stage's diode rectifier is an explicit load the output
  driver must charge; it has no supply, so its energy is already inside `E_gate`.
- **Inputs are ideal voltage sources** (previous stage abstracted) — the standing convention.
- **LEVEL=1 models, no body diodes, no mismatch** — generous to ternary (2 boundaries = 2× the
  offset budget). Schottky rectifier (`TT=1p`) and small `CJO=2f`, both load-bearing (§8).
- **Toggles:** cheapest ternary toggle (null↔+1, half swing) *and* the full +1↔−1 swing are both
  measured and reported separately. Binary toggles the full ±1 V.
- **Device counting:** "diode" = rectifier (D); "transistor" = MOSFET. Keepers (R,C) passive.

---

## 4. Measured results

### 4.1 Truth table — all 9 input pairs (DIRECT)

| a \ b | −1 | 0 | +1 |
|---|---|---|---|
| **−1** | **+0.996** ✓ (+1) | **−0.996** ✓ (−1) | **0.000** ✓ (0) |
| **0** | **−0.996** ✓ (−1) | **0.000** ✓ (0) | **+0.996** ✓ (+1) |
| **+1** | **0.000** ✓ (0) | **+0.996** ✓ (+1) | **−0.996** ✓ (−1) |

`tt1…tt9` read at 130 ns: the three nonzero values are ±0.996 V, the three zero values are exactly
0.000 V. The wrap is correct in both directions (`−1 ⊕ −1 = +1`, `+1 ⊕ +1 = −1`) and the null-null
case stays 0. Null return: the cheapest-toggle instance returns to **0.069 V** at the 110 ns
checkpoint — cleanly below the ~0.4 V dead-zone trip.

### 4.2 Energy per toggle and idle (DIRECT)

| cell | devices | E/toggle (cheapest) | E/toggle (full swing) | held-null idle / 75 ns |
|---|---:|---:|---:|---:|
| **binary XOR2** (2-input analog) | 14 T | 243 fJ | — | 2.5 aJ |
| **binary full adder** (sum+carry) | 46 T | 798 fJ | — | 7.5 aJ |
| **tsum (mod-3 sum)** | **88** (84 T + 4 D) | **898 fJ** | **1494 fJ** | **11.7 aJ** |

E/toggle = full-cycle energy ÷ 2 (one assert + one release). The ternary cheapest toggle is
null↔+1 (output swings 0↔+1 V, `0⊕x=x`); the full swing +1↔−1 costs **1.66×** the cheapest toggle
(1494/898) — below the 2× a pure wire-swing argument predicts, because internal switching of the
60-T sum logic dominates the wire. The held-null idle (output null, inputs held) is **1.2×10⁻¹⁷ J**
over 75 ns — the diode receiver's "free null" survives the null-rail detector: the null is a dead
zone, not a 0-V saddle, so it draws no static current.

### 4.3 Device and energy context vs the other diode gates (DIRECT)

| gate | devices | E/toggle |
|---|---:|---:|
| dd_not | 4 | 54.2 fJ |
| dd_nand / dd_nor | 8 | 60.8 / 58.6 fJ |
| dd_min / dd_max | 12 | 122.2 / 109.4 fJ |
| **tsum (this cell)** | **88** | **898 fJ** |

The sum is **7–22× the devices and 7–17× the energy** of the lattice gates. That gap *is* the cost
of the null rail plus the six-term field logic — it is the quantitative face of "`⊕` is the one
irreducible op" (`synth_logic.md` §1.2).

---

## 5. Fair fight vs binary

Three reference points, two of which are this harness (same LEVEL=1, same ±1 V rails, same load),
one from `docs/compute/gate_area.md`:

| ternary | binary reference | energy/toggle | **energy/bit** | devices |
|---|---|---:|---:|---:|
| tsum (cheapest) | full adder (2 cells / 33.78 µm²) | 898 / 798 = **1.13×** | 567 / 399 = **1.42×** | 88 vs 2 cells |
| tsum (cheapest) | XOR2 (2-input analog) | 898 / 243 = **3.70×** | 567 / 243 = **2.33×** | 88 vs 14 T |
| tsum (full swing) | full adder | 1494 / 798 = **1.87×** | 943 / 399 = **2.36×** | — |

Per-bit = E/toggle ÷ output width: ternary ÷1.585 (one trit), binary FA ÷2 (sum + carry), XOR2 ÷1.

**Read it honestly.** The task's reference is the **binary full adder** (2 cells / 33.78 µm²). By
that measure the diode-direction sum is **1.13× the energy per toggle and 1.42× per bit** on the
cheapest toggle — *not* a 5–14× loss. But the binary FA in this harness is 46 T and toggles **two
full-swing outputs** while the ternary cheapest toggle swings **one half-swing output**, so the
per-bit ratio (1.42×) is the honest number and it already includes that favor to ternary. Against
the true 2-input analog — **binary XOR** (one output, one bit) — the ternary sum is **2.33× energy
per bit and ~6× devices**. On device count alone the sum is ~2× a canonical ~28-T binary FA (or
~3–4× the sky130 2-cell FA), and 6× a binary XOR.

**The headline is not "ternary wins".** It is: the null rail forces a 3-level re-quantization per
input (the receiver) that the simple diode gates avoid, and the six-term field logic on top of it
makes `⊕` the only ternary gate whose per-bit energy (1.4–2.4×) and device count (2–6×) land
*above* binary rather than at the 0.5–1× of the lattice gates. The 4.9–14.3× sense-amp catastrophe
is gone; a real but bounded penalty remains, and it is intrinsic to the third decision.

---

## 6. The honest verdict — is ⊕ the wall?

**Yes, `⊕` is the wall — but the wall is ~2× per bit, not ~10×, and it is a *measurement* wall,
not a *tractability* wall.** Three calibrated claims:

1. **The null rail is irreducible, and it is what makes ⊕ special (OURS → DIRECT).** The direction
   receiver cannot emit `NOT(push OR pull)`; any cell that does must re-quantize the wire with two
   thresholds (Law 1). This cell does that statically (2 complementary restore pairs + a NOR per
   input), so the null rail costs ≈ the receiver's 10 T + 2 D per input. There is no known way to
   get the third decision for less than ~2 thresholds — that is the information tax, not a tuning
   gap. **[OURS — the "2 thresholds minimum" reading of `device_physics.md`; DIRECT — the receiver
   count.]**

2. **The sense-amp tax is gone; the diode receiver's free null survives (DIRECT).** Held-null idle
   = 1.2×10⁻¹⁷ J/75 ns, and the null returns cleanly (0.069 V). `polar_gates.cir`'s metastable-null
   shoot-through and clocked-receiver supply do not appear. The whole 4.9–14.3× gap in
   `polar_gates.md` was a receiver artifact, exactly as `diode_gates.md` concluded for the lattice
   gates — and it holds for the sum too.

3. **What remains is a ~2× energy / ~2–6× device penalty (DIRECT, measured).** 898 fJ/toggle,
   88 devices, vs 798 fJ / 46 T for the binary FA and 243 fJ / 14 T for binary XOR. Per bit the
   sum is 1.42–2.33× binary energy. This is the *area* story of `gate_area.md` (`tadd1` = 4.33× a
   binary FA) finally given an energy number, with the caveat that this cell's 88 devices include
   the polar-wire receiver + driver that `gate_area.md`'s pure 2-wire synthesis does not.

**So: can `⊕` be made competitive? Not with this receiver — and the reason is structural.** The
null rail is a third decision, and the direction receiver gives two decisions for free but not the
third. The only paths that could break the ~2× are the ones already named in the corpus and still
unmeasured here: (a) the **signed-current form** (`analog_polar.md` Idea A) where the KCL sum is
free and only the ±2→∓1 wrap is a 2-threshold decision — the sum construction, which is where this
cell spends 60 T, vanishes; and (b) a **native 3-state device** that thresholds three states on one
wire (`device_circuit.md`). Both are flagged in §8, not measured here.

---

## 7. Calibration ledger

| claim | calibration |
|---|---|
| Truth table: all 9 pairs correct (±0.996 V / 0.000 V) | **DIRECT** — `tsum_cell.log` tt1…tt9 |
| Null return 0.069 V at 110 ns (dead zone ~0.4 V) | **DIRECT** — `tsum_cell.log` vw3_f |
| E/toggle 898 fJ (cheapest), 1494 fJ (full swing) | **DIRECT** — `tsum_cell.log` ept_t3/t4 |
| Binary FA 798 fJ/toggle (46 T), XOR2 243 fJ/toggle (14 T) | **DIRECT** — `tsum_cell.log` ept_fa/xor2 |
| Held-null idle 1.2×10⁻¹⁷ J / 75 ns | **DIRECT** — `tsum_cell.log` eq_t3 |
| Device count 84 T + 4 D = 88 | **DIRECT** — counted from the netlist |
| Per-bit ratios 1.42× (vs FA), 2.33× (vs XOR2) | **DIRECT** — arithmetic on the above |
| "The null rail needs ≥2 thresholds (Law 1)" | **OURS** — `device_physics.md` §2.3; the receiver's 2-boundary structure is DIRECT |
| "The 4.9–14.3× sense-amp loss is gone" | **OURS/ANALOGY** — supported by DIRECT idle ≈0; not re-run here |
| The 60-T sum logic would collapse in signed-current form (KCL free) | **OURS** — `analog_polar.md` Idea A; not measured |
| Area equivalence of 88 devices (~2× a 28-T FA; ~3–4× the 2-cell sky130 FA) | **SPECULATION** — device count is DIRECT, µm² is not synthesized |

---

## 8. TODO / not covered / caveats

1. **The signed-current form (analog_polar.md Idea A) is still unmeasured.** It is the single most
   promising way past the wall: the KCL sum (`σ = I_a + I_b`) is free, so the 60-T sum logic of this
   cell disappears and only the ±2→∓1 wrap (two current thresholds at ±1.5·I₀) + the output
   quantizer remain. Expected ~30–45 T, but current mirrors/comparators were **not** converged
   here (the deliverable is the diode-direction cell). This is the concrete next netlist.
2. **The toggle is the *cheapest* ternary toggle (null↔+1).** Binary toggles the full ±1 V. The
   full-swing ternary toggle (1494 fJ) is 1.66× the cheapest, which moves the per-bit ratio vs the
   FA from 1.42× to 2.36×. Which is "right" depends on data statistics (null-heavy favors ternary),
   as in `diode_gates.md` §TODO 2. The full-swing number is reported here; do not quote 1.42× as
   the headline without it.
3. **The binary FA in this harness is 46 T (unoptimized NAND/NOR), not the ~28-T canonical or the
   sky130 2-cell FA.** The 1.42× per-bit energy is against that inflated FA; against the true
   2-input analog (binary XOR, 14 T / 1 cell) the ratio is 2.33× energy / ~6× devices. The area
   reference stays `gate_area.md`'s measured `tadd1` = 25 cells / 146.39 µm² = 4.33× the binary FA
   — that is the *logic-only* floor, and this cell's 88 devices add the polar receiver + driver on
   top.
4. **The elevated-|Vt| dead zone and the Schottky/CJO assumptions are inherited from
   `diode_gates.cir` §6 and remain unverified in a PDK.** LEVEL=1 has no subthreshold leakage, so
   the ~0.4 V dead-zone margin and the "held-null idle ≈0" are model artifacts; silicon's floor is
   leakage, not zero. The rail floor (rA ≈ 0.76 V) sits against the 0.4 V `N_HI` threshold with
   ~0.3 V margin — process offset (σ 5–20 mV) eats a chunk of it, and mismatch halves the 2-boundary
   budget (two thresholds = 2× the offset budget vs binary's one).
5. **No body diode / no mismatch / no leakage modeled.** A real elevated-Vt device at the 0.4 V
   dead-zone margin pays costs this netlist does not. Same caveat class as every fair fight in
   `circuit/`.
6. **The null-return speed is Schottky- and margin-limited (inherited).** No sweep over (Vt,
   R_keeper, CJO, TT) was done; the operating point here is one point. The 0.069 V null at the
   110 ns checkpoint is one sample, not a timing closure.
7. **The 3-input balanced full adder (sum + carry, `tadd1`) is not built.** This cell is the 2-input
   mod-3 sum with the carry *dropped*. The carry (`σ≥2 → +1`, `σ≤−2 → −1`) is the next cell and is
   where the wrap decision that the signed-current form keeps explicit would resurface; it is
   unmeasured here.
8. **`gate_area.md`'s `tadd1` (25 cells) is the *2-wire combinational* synthesis, not the polar-wire
   cell.** Comparing this cell's 88 devices to 25 cells is apples-to-oranges (this cell includes the
   receiver + driver + diode interface). The doc states both; the honest "wall" number is the
   per-bit energy (1.42–2.33×) plus the device count (88), not a single µm².

*Every number above is measured by `circuit/tsum_cell.cir` (ngspice 44.2) or counted from its
netlist; nothing is invented.*
