# Meta-critique of the transistor/device analysis — what mechanism we missed

**2026-08-29.** This is the device-analysis meta-critique. It reads the four
transistor/device files (`device_literature.md`, `device_physics.md`, `device_circuit.md`,
`meta_critique.md`) against their **four headline conclusions** and answers one question:
*what native 3-state device or mechanism did we miss?*

Calibration legend (house standard, `docs/MAP_BRIEF.md`):

- **DIRECT** — measured/proved in-repo, or a citable literature/textbook identity.
- **ANALOGY** — parallel structure, not identity.
- **OURS** — our own design claim.
- **SPECULATION** — untested hypothesis, flagged.
- **DIRECT (domain history — verify citation)** — established engineering fact not yet
  backed by a paper in this repo (same convention `meta_critique.md` uses).

---

## 0. The blunt verdict, first

**Three of the four conclusions hold only because they are stated more broadly than the
evidence supports; the fourth is a category error.** The specific corrections:

1. **"No drop-in native 3-state device exists" — TRUE as "no *fabricable* native 3-state
   *restoring logic transistor* exists," FALSE as stated.** We missed a whole class of
   **single-device** native ternary primitives demonstrated post-2020: the
   **anti-ambipolar transistor (AAT)** — one transistor whose transfer curve is
   intrinsically non-monotonic (a hump), giving a near-perfect ternary inverter with **one
   device + one load resistor**. We also missed **anti-ferroelectric (AFE) HZO** — the one
   material where the "three free-energy minima" of `device_physics.md` §0 is *literally*
   true in a CMOS-compatible film. Neither is VLSI-fabricable today; both change what the
   sentence "no native device exists" is allowed to mean.
2. **"~1.5–2×/bit" — the number is ~robust, but its receiver assumption is unstated and one
   term is a code-convention artifact.** `device_circuit.md` §7.2 *already* deletes the
   sense amps, so the surviving 1.5–2× is the **3-level SNR penalty + the 2-threshold info
   cost**, not the receiver. A **direction/sign receiver (diode rectification)** changes the
   *energy* of the 2-threshold tax (passive vs clocked-active) but not the *information*
   count, and it is **not viable at 1 V** (a diode drop ≥ the swing). The `V_swing/2` SNR
   penalty is a property of the *unipolar* `{0, Vdd/2, Vdd}` code, not the *balanced*
   `{−V, 0, +V}` code — it only becomes true under the "equal total supply to binary"
   normalization. All three points need to be stated, none flips the verdict.
3. **"Depletion-mode multi-Vt is absent from foundries" — over-stated, and the requirement
   is self-inflicted.** Depletion devices *do* exist in BCD/high-voltage analog flows (not
   in digital standard cells — that half is TRUE). More importantly, the depletion
   requirement is an artifact of our **polar `−Vdd/0/+Vdd` convention with a literally
   driven 0 V rail**; the literature's unipolar `{0, Vdd/2, Vdd}` STI is **depletion-free**
   (enhancement-only, two Vt flavors) — it just re-introduces the mid-level shoot-through we
   were trying to kill. And **FDSOI back-bias** collapses our "4 threshold flavors = 4 fab
   steps" to **one device recipe + three well biases**. Depletion is a self-imposed
   trade, not a foundry wall.
4. **The 2-threshold tax is NOT "one device per threshold" — that is a category error.** The
   tax is a property of the **1-D ordered amplitude voltage code** (Law 1), not of "ternary"
   or of "a single device." A single device *can* resolve 3 states in one measurement when
   the states live in a **non-amplitude degree of freedom**: AAT (one non-monotonic
   transfer), SET (charge number), RTD/RTT (NDR branches), AFE (polarization minima), RFET
   (conduction polarity). `device_physics.md` already knows this (§2.2, §5.4); `meta_critique.md`
   then over-generalizes "2 thresholds" from the *code* to *any* ternary. The tax is
   **code-specific, not radix-specific.**

**Bottom line:** the program's *fabrication* verdict survives (no VLSI path to a native
ternary logic transistor — reaffirmed). The *device-physics* story was too narrow: it
conflated "no fabricable device" with "no native mechanism," and it mis-located the
2-threshold tax in the device when it is in the **code**. The single highest-value test is
the **anti-ambipolar single-device ternary inverter** — it is the cleanest live
counterexample to "one device per threshold," and it has been demonstrated, just not
fabricated.

---

## 1. Attack 1 — did we miss a native 3-state mechanism?

### 1.1 The miss that matters: the anti-ambipolar transistor (AAT)

`device_literature.md` surveys nine families and **misses the one single-device mechanism
that directly answers "can one transistor resolve 3 states with free knees from band
structure."** An **anti-ambipolar transistor** has a *non-monotonic transfer characteristic*
— drain current **rises to a peak** at a specific gate voltage and **falls on both sides** —
the exact "hump" a ternary inverter wants, and it comes from **band alignment**, not from
two engineered thresholds.

**Physics.** The hump arises from a series/hetero-stack of an **n-type and a p-type channel**
(or a lateral homojunction): current flows only where the *two* carrier populations overlap
in gate-bias space, so the transfer function peaks and then rolls off in both directions.
In an inverter (device + one load resistor) this single non-monotonic transfer yields **three
distinguishable output levels from one 3-terminal device and one passive load.** No sense
amp, no second threshold flavor, no depletion device. **[DIRECT — the mechanism is band
alignment; it is the complement of ambipolar conduction, which is textbook.]**

**Track record (post-2020, this is what we missed).**

- "Near-Perfect Standard Ternary Inverter Based on MoTe₂ Homojunction Anti-Ambipolar
  Transistor" — a *single* anti-ambipolar device realizing a standard ternary inverter
  (STI). ([Scilit record](https://www.scilit.com/publications/ae4a2e81a6570548cab8599e9ceeea50))
- "Optically Controlled Ternary Logic Circuits Based on Organic Antiambipolar Transistors"
  (*Adv. Electron. Mater.* 2020). ([Wiley](https://advanced.onlinelibrary.wiley.com/doi/10.1002/aelm.202000940))
- "Multifunctional applications of 2D anti-ambipolar transistors: frequency doubling and
  multi-valued inverter design" (*Nanoscale*, 2025). ([PubMed](https://pubmed.ncbi.nlm.nih.gov/40740065/))

**Calibration.** **DIRECT** on mechanism *and* demonstration (one device, one load, three
levels, measured). **SPECULATION** on fab — 2D/organic materials, no VLSI path, same wall as
CNTFET but *fewer devices per gate*. This is the purest live counterexample to "one device
per threshold," and it is **absent from `device_literature.md`'s nine families.** It belongs
in the summary table as a tenth family.

### 1.2 The miss that makes "3 minima" literal: anti-ferroelectric (AFE) HZO

`device_physics.md` §0 defines a native 3-state device as a free-energy landscape `F(q)` with
**three minima separated by barriers ≫ kT**. It then lists NDR, multi-threshold, and charge
quantization as the ways to build it — and **misses the material whose Landau free energy is
already a triple well: the anti-ferroelectric.** A ferroelectric is `F(P) = αP² + βP⁴ + γP⁶`
with two minima (bistable). The **anti-ferroelectric** regime of the *same* Landau polynomial
gives a **double-hysteresis P–E loop = three stable polarization states**. **[DIRECT — the
6th-order Landau free energy with the AFE sign structure has 3 minima; standard ferroelectrics
textbook.]**

Why this matters: it is **Hf₀.₅Zr₀.₅O₂ (HZO)** — the *same* CMOS-compatible, foundry-adjacent
film family the FeFET section already praises — and it has been demonstrated as multi-level
memory:

- "Multipeak Coercive Electric-Field-Based Multilevel Cell Nonvolatile Memory With
  Antiferroelectric-Ferroelectric Field-Effect Transistors (FETs)", *IEEE TUFFC* 69(6) 2022.
  ([PubMed](https://pubmed.ncbi.nlm.nih.gov/35380960/))
- "Bilayer-Based Antiferroelectric HfZrO₂ Tunneling Junction With … Multilevel Nonvolatile
  Memory." ([Semantic Scholar](https://www.semanticscholar.org/paper/Bilayer-Based-Antiferroelectric-HfZrO2-Tunneling-Hsiang-Liao/f86b80c8b8ffaaebe812f76f20c0f816bd0eada4))

**Calibration.** **DIRECT** physics (3 native minima, room temperature, CMOS-compatible) and
**DIRECT** demonstration (multi-level memory). But — and this is the same wall — it is
**memory-class (passive/polarization storage), not a restoring logic transistor.** So it does
**not** overturn the "storage ≠ logic" split; it *strengthens* the storage half: the "3 native
stable states" ideal is not a fantasy, it is a **part** (an HZO AFE cell), it just cannot
restore and fan out. `device_literature.md` has FeFET (ferroelectric) but **not AFE**; the
distinction is exactly the difference between "2 minima" and "3 minima."

### 1.3 Reconfigurable-polarity FET (RFET) — we have it, and we under-weighted it

`meta_critique.md` §2/§3e lists "reconfigurable-polarity FET (Yeom 2025, black phosphorus)"
and correctly calls it "closest to our 'polarity is value.'" **But it is treated as a dead end
because it is 2D.** The point worth sharpening: an RFET's three states are **n-conduction / off
/ p-conduction** — i.e. the **sign of the trit is the sign of the majority carrier**, literally
Tau's "polarity is value." It is the *only* device family whose 3 states are the ±/0 *direction*
rather than 3 amplitudes. That is a conceptual match, not just a convenient one. Post-2020 it is
broader than one black-phosphorus paper:

- "Ternary Transistors With Reconfigurable Polarities" (Yeom et al., *Adv. Funct. Mater.* 2025).
- 2D polarity-controllable transistors for TCAM and reconfigurable logic (WSe₂ charge-trapping
  RFET, 2T-TCAM).
- "Non-Volatile Reconfigurable Four-Mode van der Waals Transistors" (2025).

**Calibration.** **DIRECT** mechanism + demonstrations; **SPECULATION** fab (2D/SOI-Schottky,
no VLSI). Same rank as CNTFET, and conceptually the *best* match to the polar convention.

### 1.4 FDSOI back-bias — the fabricable single-device multi-Vt we pointed at FinFET for

`device_literature.md` ranks **independent-gate FinFET** as the #1 fabricable candidate, but
IG-FinFET is being *displaced* by gate-all-around nanosheet. The **current** production
single-device multi-Vt answer is **FDSOI back-gate biasing**: GlobalFoundries **22FDX** and
Samsung **28FDSOI** are in production, and the back gate is a standard knob that shifts `Vt`
continuously. Consequence the corpus did not record:

> **`device_circuit.md` §1.1 charges "4 threshold flavors = 4 fabrication steps" (a chirality
> class per Vt). In FDSOI, the 4 flavors are ONE device recipe + 4 well/back-bias values —
> zero extra masks, zero extra material.** The "flavor count ≠ device count" cost the corpus
> flags as the real fabrication risk **collapses** on FDSOI.

**Calibration.** **DIRECT** — 22FDX back-bias is a production technology
([IEEE 22FDX analog back-bias designs](https://ieeexplore.ieee.org/document/9825362));
"back-bias = tunable Vt" is standard device physics. The *caveat stands*: it still gives **3
drive-current states, not 3 voltage rails** — the current→voltage load is still needed, exactly
as `device_literature.md` §2.5 says of the IG-FinFET. FDSOI moves the *fabrication* objection,
not the *topology* one.

### 1.5 Phase-change (PCM) — the second mature multi-level memory we omitted

`device_literature.md` covers memristor/RRAM but **not phase-change (PCM/3D XPoint)**. PCM is
*more* mature than RRAM for multi-level storage (MLC PCM shipped in production, Intel Optane).
**Calibration.** **DIRECT** storage; **ANALOGY** for logic — same passive/no-gain verdict as
memristor, same "memory answer, not transistor answer." Completeness only; it changes nothing.

---

## 2. Attack 2 — does the ~1.5–2×/bit figure assume a receiver a direction-based receiver would change?

**Short answer: the figure is ~robust, but for a reason the corpus did not state, and one of
its terms is a code-convention artifact.** Three corrections:

### 2.1 The 1.5–2× already deleted the sense amp — so "receiver" is not its load-bearing assumption

`device_circuit.md` §7.2 derives ~1.5–2× by *removing* the two clocked sense amps and the
re-encode driver, landing in the ½CV² class, then adding back **two terms**: the 3-level
**noise-margin (SNR) penalty** and the **2-threshold information cost**. So the figure does
**not** rest on the sense-amp receiver — attack 2's premise is half wrong. The surviving 1.5–2×
is *code physics*, not receiver overhead. **[DIRECT — read of `device_circuit.md` §7.2.]**

### 2.2 The direction/sign receiver (diode rectification) — real, but it is a 1950s answer, not a 2026 one

A direction receiver resolves `{−V, 0, +V}` by **sign + presence**, not by two amplitude
thresholds: an N-diode conducts for `+V`, a P-diode for `−V`, and **neither for 0 V** (the null
*is* the diode dead zone). This is **passive, clockless, comparator-bias-free** — it would, in
principle, cut the *active* energy of the receiver to near zero. This is **exactly what Setun
did** (ferrite cores + diode gates): the corpus's own `meta_critique.md` §3i cites Setun as the
"ternary without a native device" control but **never carried the diode receiver into the
device analysis.** **[DIRECT (domain history — verify citation) for Setun's diode logic;
DIRECT for the rectification mechanism.]**

**The blunt kill:** a diode forward drop is **0.3–0.7 V (Schottky → PN)**, which **≥ a 1 V
swing**. On Sky130-class 0–1 V rails the direction receiver **cannot resolve anything** — the
null dead zone swallows the entire signal. It worked on Setun's 1950s high-voltage discrete
logic and does not transfer to modern low-voltage CMOS. So:

- The direction receiver **does** change the receiver *energy* (the 2.54× measured tax is an
  **active-comparator** number, not a fundamental sign-detection number). **[DIRECT.]**
- It does **not** change the receiver *information* (sign+zero is still 2 decisions). **[DIRECT.]**
- It is **not usable at 1 V**, so the change is theoretical. **[DIRECT — arithmetic on diode
  drop vs swing.]**
- On **two wires** the direction code *is* the one-hot dual-rail already costed at **+26% area**
  (`gate_area.md`). So "direction-based" on modern CMOS = the 2-wire encoding we already priced.

### 2.3 The `V_swing/2` SNR penalty is a unipolar-code artifact, not a balanced-code fact

`device_physics.md` §2.3 and §5.3 assert "three levels in one swing sit `V_swing/2` apart →
~2× energy penalty." That is the **PAM-3 vs NRZ** argument and it is true **for the unipolar
`{0, Vdd/2, Vdd}` code**. For **balanced polar `{−V, 0, +V}`** the three levels sit at `−V, 0,
+V` — adjacent separation **V**, *identical to single-ended binary*, with the null at the
*center* (the most-robust point on the axis), not squeezed between two rails. **[DIRECT —
arithmetic.]**

The resolution (and the reason the corpus is *not* simply wrong): balanced polar requires a
**split ±V supply = twice the voltage domain** of binary. If you normalize to **equal total
supply swing** (the fair fight), the balanced gaps do collapse to `V_swing/2`. So the penalty
is real **iff** the energy budget is held equal to binary's — which is the correct normalization
and should be *stated*, not assumed. **The direction receiver is entangled with this**: a
bipolar ±code is *already* a differential/direction code, so "3-level PAM penalty" is the wrong
frame for it; the right frame is "bipolar NRZ + a center null," whose penalty is the **split
supply** (2× domain) rather than the **per-level margin** (which is not halved). **[OURS — the
re-framing; the arithmetic is DIRECT.]**

**Net on attack 2:** `~1.5–2×/bit` survives, but (a) it should be stated as "static multi-Vt,
*single-ended level receiver*, equal-supply fair fight"; (b) the 2-threshold tax splits into an
irreducible information cost (survives any receiver) and an implementation cost (the measured
2.54×, which a passive direction receiver would cut *if* it had the headroom — it doesn't at
1 V); (c) the `V_swing/2` term is a unipolar-code import and must be re-derived for the
balanced code before it is quoted. **None of this flips the verdict; all of it makes the verdict
defensible instead of hand-waved.**

---

## 3. Attack 3 — is depletion-mode multi-Vt still absent, and is there a depletion-free topology?

### 3.1 "Absent from foundries" — half true

- **TRUE for the flow Tau would use:** standard digital standard-cell PDKs (Sky130, 22FDX
  logic, TSMC digital) do **not** offer depletion-mode MOSFETs in the cell library.
  **[DIRECT (domain history — verify citation).]**
- **FALSE as an absolute:** depletion-mode NMOS **is** available in BCD / high-voltage /
  mixed-mode analog flows — e.g. Nuvoton's 0.5 µm 5 V mixed-mode process advertises depletion
  devices — and **native-VT (≈0 V)** and **low-VT** enhancement devices exist in many analog
  flows. **[DIRECT — the BCD depletion availability is a standard feature of power flows;
  the Nuvoton example is a foundry-service listing.]**

So the honest statement is: **"no depletion device in the digital standard-cell flow," not "no
depletion device anywhere."** That is still a real wall for a *logic* core (which must run on
standard cells), but it is not a physics wall.

### 3.2 The depletion requirement is self-inflicted by the polar convention

`device_circuit.md` §1.1 derives that the mid (0 V) output *requires* depletion devices
(`depN`/`depP`), because a FET with gate at 0 V cannot conduct to a 0 V source unless normally-on.
That derivation is correct **for our chosen convention `{−Vdd, 0, +Vdd}` with a literally
driven 0 V rail.** But the literature's **standard ternary inverter is depletion-free**: the
unipolar `{0, Vdd/2, Vdd}` STI (Lin/Kim/Lombardi CNTFET, and every multi-Vt CMOS ternary gate)
uses **two enhancement Vt flavors only**, because the mid level `Vdd/2` sits *above* the N-FET
threshold and *below* the P-FET threshold, so the mid level is produced by the *ratio* of two
on-enhancement devices — **at the cost of static shoot-through current at the mid level.**
**[DIRECT — the STI topology is `device_literature.md` §2.2; the shoot-through at the mid level
is the exact "meta-stable null" `polar_gates.md` measured.]**

So the trade is explicit and the corpus only recorded half of it:

| convention | mid level produced by | depletion needed? | static current at null? |
|---|---|---|---|
| **unipolar `{0, Vdd/2, Vdd}`** (literature STI) | ratio of two on-enhancement FETs | **no** | **yes** (shoot-through — the measured meta-stable null) |
| **balanced `{−Vdd, 0, +Vdd}`** (ours) | dedicated depletion window switch to 0 V | **yes** | **no** (dead zone, null driven) |

**The corpus traded shoot-through for depletion, and then declared depletion "the fabrication
killer" — without recording that the alternative (depletion-free) re-introduces the exact
shoot-through failure it was built to kill.** That is not a foundry wall; it is a *choice of
null convention*, and the choice is forced by the wire-side win (B1: null = 0 V = no drive on
the wire) that the gate side has to pay for. **[OURS — the two-sided framing; the two rows are
DIRECT.]**

### 3.3 Depletion-free multi-threshold topologies that dodge the trade

1. **FDSOI back-bias** (§1.4) — one enhancement device recipe, `Vt` shifted by well bias; the
   "mid detection" is a third back-bias value, not a depletion implant. **[DIRECT fab /
   OURS as a ternary cell.]**
2. **Current-mode MVL** — encode the trit as three *current* levels (`0, I, 2I`) and detect
   with a current mirror/current comparator; no rail-to-0-V conduction requirement, no
   depletion. `device_circuit.md` §11 already names this as unexamined. **[DIRECT literature /
   ANALOGY for our cells.]**
3. **Level-shifted source / self-referenced mid** — drive the mid from a `Vdd/2` (or split-rail
   `0 V` as *supply*, not as a *conducted rail*): if the null is a **supply rail** (ground in a
   split supply) reached through a normal enhancement pull-down whose *source* is at `−Vdd`
   rather than 0 V, the "depletion to 0 V" requirement disappears — at the cost of the split
   supply (§2.3). **[OURS — topology; the split-supply cost is DIRECT.]**
4. **AAT single-device inverter** (§1.1) — the mid level is the *peak* of a non-monotonic
   transfer, produced by band alignment with **zero** threshold flavors and **zero** depletion.
   **[DIRECT mechanism / SPECULATION fab.]**

**Net on attack 3:** "depletion absent" is true only for digital standard cells; depletion-free
topologies exist (unipolar STI, current-mode, FDSOI back-bias, AAT) but each re-pays a different
cost (shoot-through, split supply, or non-fabricable material). The corpus's framing of
depletion as *the* killer is **too narrow** — the real object is "how do we get a driven
0 V null without either a normally-on device or a shoot-through path," and **no topology known
today answers it on standard cells at 1 V.**

---

## 4. Attack 4 — is the 2-threshold tax "one device per threshold," or can one device resolve 3 states?

### 4.1 The category error

`meta_critique.md` §1 states the go/no-go as *"does any device resolve 3 states with fewer than
2 thresholding measurements"* and then asserts multi-Vt CMOS is "the 2-threshold tax in device
form." That collapses **two distinct claims**:

1. **The information claim (Law 1):** a 1-D *ordered amplitude* code `{−V < 0 < +V}` on one
   wire needs **2 decision boundaries** to resolve, whatever the device. **[DIRECT — this is
   about the code.]**
2. **The device claim:** a multi-Vt *amplitude* implementation needs **2 engineered threshold
   flavors** = 2 fabrication steps. **[DIRECT — this is about that one implementation.]**

These are **not the same**. A single device can resolve 3 states in **one** measurement when the
3 states live in a degree of freedom that is *not* amplitude on one wire:

| device | state variable | how many "thresholds" to read 3 states | fabricable? |
|---|---|---|---|
| **AAT** (§1.1) | one non-monotonic transfer hump | **1 device + 1 load**, no engineered Vt | no (2D/organic) |
| **SET** (`device_physics.md` §3) | integer island charge `n` | **1 read** (occupancy) | no (cryogenic) |
| **RTD / RTT** (`device_physics.md` §1) | which NDR branch | **1 device** (2 NDRs), load line does the rest | no (III-V) |
| **AFE HZO** (§1.2) | polarization minimum | **1 read** (P-E state) | memory-only |
| **RFET** (§1.3) | majority-carrier polarity | **1 device** (n/off/p) | no (2D/SOI) |
| **multi-Vt CMOS / CNTFET** | 2 engineered Vt on 1 amplitude axis | **2 thresholds** | **yes** (the only one) |

**The 2-threshold tax is a property of the *amplitude code on one wire*, not of "ternary" and
not of "a single device."** `device_physics.md` §2.2 and §5.4 *already say this* ("driven
levels vs self-held states"; "the advantage belongs to the mechanism, not the radix") — and
`meta_critique.md` then re-imports the amplitude-code tax as if it were radix-general. That is
the single biggest over-claim in the four files. **[OURS — the reframe; every row of the table
is DIRECT from the four files + §1.]**

### 4.2 "Knees free from band structure" — yes, and it is the AAT

Attack 4's specific phrasing — "a multi-threshold FET where the knees come free from band
structure" — has a **live, demonstrated answer**: the **anti-ambipolar transistor**. Its two
"knees" (the rise and fall of the hump) are set by the **band alignment of the n/p hetero- (or
homo-) junction**, not by any implanted threshold. One device, one gate, three current states,
no threshold engineering. **[DIRECT — §1.1 citations.]** The only reason it is not already
ranked #1 is that it is **not fabricable at VLSI** — which is a *manufacturing* objection, not a
*mechanism* objection. The corpus's "no native 3-state device exists" should have been written
"no *fabricable* native 3-state device exists; the *mechanism* exists and is called the
anti-ambipolar transistor."

---

## 5. Consolidated verdict table — what holds, what falls, what's new

| conclusion (source file) | verdict | the correction |
|---|---|---|
| "No drop-in native 3-state device exists" (`device_literature.md` §3) | **HOLDS** as "no *fabricable* native 3-state *restoring logic transistor*" / **FALLS** as stated | the *mechanism* exists: **AAT** (single-device, non-monotonic, demonstrated), **AFE HZO** (literal 3 minima, CMOS-compatible), **RFET** (n/off/p = the trit sign). Restate the claim precisely. |
| "Best native cell ≈ 1.5–2×/bit" (`device_circuit.md` §7.2) | **HOLDS** (approx) | restate the receiver (single-ended level, not sense-amp — already removed) and the supply normalization; the `V_swing/2` SNR term is unipolar-code-specific; the 2.54× receiver tax is an *active-comparator* number a direction receiver would cut *if it had 1 V headroom — it doesn't*. |
| "Depletion-mode multi-Vt absent from foundries" (`device_circuit.md` §1.1/TODO 2) | **HALF-HOLDS** | true for digital standard cells; false absolutely (BCD/analog flows have depletion). And the requirement is **self-inflicted** by the `{−V,0,+V}` driven-0V convention — the depletion-free unipolar STI exists but re-introduces null shoot-through; **FDSOI back-bias** collapses 4 Vt flavors to 1 recipe. |
| "2-threshold tax = one device per threshold" (`meta_critique.md` §1, §3e) | **FALLS** | category error — the tax is the *amplitude code*, not the radix or the device. Single devices resolve 3 states in one measurement (AAT, SET, RTD, AFE, RFET); multi-Vt CMOS is the *only fabricable* way and it is the only one that pays 2 thresholds. |
| "multi-Vt CMOS is the 2-threshold tax in device form" (`meta_critique.md` §3e) | **HOLDS, narrowed** | true *for the amplitude code Tau chose*; not true of ternary in general. |
| "no VLSI fab path for any native device" (`meta_critique.md` §3e) | **HOLDS, reaffirmed** | AAT/AFE/RFET/SET/RTD all confirm it; FDSOI is the *nearest* fabricable single-device multi-Vt but still needs a load. |
| "storage ≠ logic" split (memristor/MTJ/AFE/PCM = memory, no gain) | **HOLDS, strengthened** | AFE and PCM add two more mature 3-state *storage* devices; none restores/fans out. |

---

## 6. What to test next (ranked by information-per-effort)

1. **Anti-ambipolar single-device ternary inverter (AAT) — the falsifier of "one device per
   threshold."** Pull the MoTe₂-homojunction STI paper; extract its measured transfer curve,
   noise margin, and static current. The question: does the single non-monotonic transfer give
   three rails with **one device + one load**, and is the mid level in a *dead zone* (zero
   shoot-through, unlike the unipolar STI)? If yes, `meta_critique.md`'s A4 ("no device resolves
   3 states in <2 measurements") is **falsified in mechanism** and only the fab wall remains.
   Cost: one literature pull, no SPICE model needed. **[HIGHEST VALUE.]**
2. **FDSOI back-gated multi-Vt cell (GF 22FDX / 28FDSOI).** The fabricable version of the
   corpus's #1 IG-FinFET. Test: one FDSOI transistor, back-bias = the Vt knob, one load → 3
   rails; measure whether the mid level is shoot-through-free and what per-bit energy actually
   comes out — this replaces the **scaling-argument** 1.5–2× with a **measured** number.
   **[HIGH VALUE; requires an FDSOI PDK/model.]**
3. **AFE HZO 3-state cell.** Settle "is a 3-minimum landscape a part or a fantasy": measure
   endurance, variability, read-disturb of the 3rd state. Expectation: confirms it is a
   *storage* part (no gain) → closes the "3 native minima" question without touching the logic
   wall. **[MEDIUM; closes a physics question, not a fab one.]**
4. **Depletion-free STI shoot-through measurement.** Put a number on the trade §3.2: the
   unipolar `{0, Vdd/2, Vdd}` STI's mid-level static current vs the depletion-window cell's
   device cost. This is the *actual* fabrication decision, and it is currently unmeasured.
   **[MEDIUM; cheap, closes the "depletion killer" question.]**
5. **Direction/diode receiver headroom analysis.** Quantify "diode drop ≥ swing" as a hard
   `Vdd` floor; confirm the 2-wire dual-rail is the only modern direction code. **[LOW; mostly
   arithmetic, but it makes attack 2's answer defensible.]**

**Do NOT spend more agents on:** RTD/SET/QCA/Josephson fab paths (already killed, reaffirmed);
CNTFET/memristor re-surveys (verdicts already held); truth tables / minimal set (already done,
`meta_critique.md` §2). The one device *mechanism* question left open is the AAT — everything
else on the fab side is settled.

---

## TODO / not covered / caveats

1. **The AAT is a mechanism, not a part.** I verified existence + demonstrations (MoTe₂,
   organic, 2D anti-ambipolar) via search, but I did **not** read the primary MoTe₂ STI paper,
   so I cannot quote its measured noise margin, supply, or static current. Before any verdict
   is moved, pull the primary source and extract the numbers. The claim "one device + one load
   → 3 rails" is **DIRECT from the demonstration**, but "dead zone / no shoot-through at the
   mid level" is **OURS/SPECULATION** until the paper's transfer curve is read.
2. **AFE "3 minima" is the Landau 6th-order free energy — I did not reproduce the phase diagram.**
   The claim "AFE = 3 stable polarization states" is **DIRECT** (standard, and the 2022 TUFFC
   multipeak-coercive paper demonstrates multi-level), but I did not verify the barrier heights
   (≫kT) or endurance for the *3rd* state specifically. Flag for the AFE-cell agent.
3. **FDSOI back-bias as "1 recipe, N flavors" is a fabrication claim I did not verify against a
   specific PDK.** 22FDX back-bias exists (**DIRECT**, cited), but "the 4 Vt flavors of
   `device_circuit.md` §1.1 map to 4 well-biases with no extra masks" is **OURS/SPECULATION**
   until someone reads the 22FDX device-engineering manual.
4. **The diode-receiver headroom argument is arithmetic, not measured.** "0.3–0.7 V drop ≥ 1 V
   swing" is **DIRECT** arithmetic, but whether a *sub-threshold / diode-connected* FET or a
   Schottky contact on a specific PDK rescues it is unexamined. Do not claim "impossible"
   beyond the 1 V PN-diode case.
5. **Current-mode MVL is named, not analyzed.** §3.3 lists it as a depletion-free topology but
   does not cost it (current mirrors add their own static current and headroom). It is
   **ANALOGY/SPECULATION** here; a dedicated pass is needed before it is a real candidate.
6. **The `V_swing/2` re-derivation for the balanced code is flagged, not done.** §2.3 shows the
   arithmetic (balanced gaps = V, not V/2; the penalty is the split supply), but I did not
   recompute the energy-per-bit at equal total supply. That number is what "1.5–2×" should be
   replaced with.
7. **Setun's diode logic is domain history, not a repo citation** (same caveat `meta_critique.md`
   admits). The claim "Setun resolved sign+zero with passive diode gates" should be verified
   against a Setun source before §2.2 is quoted downstream.
8. **No new measurement was performed here.** Every number is from the four source files or
   from the cited post-2020 literature; the AAT/AFE/RFET/FDSOI additions are literature-backed
   mechanisms, not ngspice/yosys results. The compact-model gap (`meta_critique.md` A8) is
   untouched: we still cannot *simulate* any of these, only cite them.
9. **The go/no-go inequality stands, re-worded.** The correct program question is **not** "does
   a native 3-state device exist" (yes: AAT/AFE/RFET/SET/RTD) and **not** "can one device
   resolve 3 states" (yes: AAT). It is: *"does a fabricable device resolve 3 states cheaper
   than 2 CMOS thresholds **on Tau's chosen 1-D amplitude code**, or does a device change the
   code to a non-amplitude degree of freedom that is still fabricable?"* On current evidence
   the answer is still **no** — but it is now "no" for the *right reason*, not the broad one.

---

## In-tree anchors

- `device_literature.md` — the 9-family survey this file corrects (adds AAT/AFE/PCM, sharpens
  RFET, moves FDSOI alongside IG-FinFET).
- `device_physics.md` — §0 (3 minima), §2.2 (driven vs self-held), §5.4 (mechanism vs radix).
- `device_circuit.md` — §1.1 (4 Vt flavors / depletion), §7.2 (1.5–2× derivation), §11
  (pass-transistor / current-mode as unexamined).
- `meta_critique.md` — §1 (Law 1 / 2-threshold), §3e (fab path), §3i (Setun), A4.
- `docs/compute/polar_gates.md` / `gate_energy.md` / `gate_area.md` — the measured 2.54×
  receiver tax, meta-stable null, +26% dual-rail area.

*This is a meta-critique: it re-derives no measurement and adds no number beyond the cited
post-2020 demonstrations. The one claim that can change the program — the anti-ambipolar
single-device ternary inverter — is flagged as DIRECT-in-mechanism, SPECULATION-in-fab, and is
the thing to test first.*
