# Native multi-valued / 3-state devices — literature survey

**Purpose:** `polar_gates.md` settled the CMOS question — native single-wire polar
ternary (push = +V, null = 0, pull = −V) *loses* on plain 2-level MOSFETs, because a
MOSFET gate is a binary threshold: it distinguishes 2 levels, not 3, so every gate pays
a 2-sense-amp demux + push-pull driver tax (9–11× transistors, 5–14× energy per bit).
Its own verdict names the exit:

> "Ternary compute is a **transistor-technology bet** (a device that thresholds 3 states
> natively, e.g. multi-Vt / CNTFET / memristor), not a CMOS cell-topology bet."

This document surveys the **devices** that could make that bet — the physical structures
that natively produce 3 distinguishable, stable states — and ranks the candidates for a
*native polar ternary transistor* (one device whose transfer characteristic is genuinely
3-valued, so the demux+re-encode tax disappears).

**Calibration key** (applied per claim, per the learning-method rule "calibrate at
mapping time"):

- **DIRECT** — the device's *physics itself* yields ≥3 distinguishable/stable states in
  a single structure, and/or the ternary/multi-valued-logic mechanism is demonstrated in
  the cited literature without conceptual stretch.
- **ANALOGY** — 3 states emerge, but by *combining multiple 2-level devices* or via a
  supporting load/selector, not from a single device's intrinsic characteristic; or the
  map to "a single 3-state polar transistor" requires reinterpretation.
- **SPECULATION** — the leap to a fab-ready native polar ternary transistor is plausible
  but *not yet demonstrated*; unproven.

The honest headline, up front: **no device in the literature is a drop-in
"one transistor → three rail voltages" part.** Every candidate is one of (a) several
2-level devices with *tuned thresholds* (multi-Vt CNTFET, independent-gate FinFET), (b) a
single device with intrinsic multi-state physics but non-CMOS / lab-only (RTD, SET, QCA),
or (c) a passive 2-terminal device that stores 3 states but cannot restore them (memristor,
MTJ). The survey below separates which of these is *closest* to the native polar part we want.

---

## 1. Summary table

Energy and area are reported as **order-of-magnitude / qualitative** unless a specific
citable number exists. Do not treat blank-ish cells as precise engineering figures — the
per-device sections and the caveats section state exactly what is and isn't established.

| Device | Mechanism (how 3 states arise) | Energy / switch | Area / size | Maturity | Ternary / MVL track record | Calibration |
|---|---|---|---|---|---|---|
| **Resonant-tunneling diode (RTD) / MOBILE** | Negative differential resistance (NDR) folds the I–V curve; a series RTD load + driver gives multiple load-line intersections = multiple stable voltages | ~fJ-range at ps switching; fastest solid-state device (THz oscillation) | mesa diode ~µm²; a MOBILE gate = 2–3 RTDs + 1–2 HEMTs | Lab / III-V fab (InP, InGaAs, InAs/AlSb); NOT CMOS | Strong — Waho multilevel threshold logic, "ultrafast ternary quantizer", 10-GHz MVL quantizers | **DIRECT** (intrinsic multi-state NDR physics) / ANALOGY (it's a diode+load, not a transistor) |
| **Multi-threshold CNTFET** | CNT bandgap ∝ 1/diameter → chirality sets Vt; transistors of 2–3 chirality = 2–3 thresholds; standard ternary inverter maps 3 rails natively | near-ballistic transport; sub-fJ claimed at device level (not a settled fab number) | CNT channel ~nm; gate uses 4–6 CNTFETs | Lab; CMOS-compatible CNFET µproc demonstrated (RV16X-NANO 2019); NOT mainstream | Very strong — Lin/Kim/Lombardi gates & arithmetic, Raychowdhury/Roy voltage-mode MVL, ternary SRAM | **DIRECT** for the multi-Vt mechanism / ANALOGY for "one native-3-state device" |
| **Single-electron transistor (SET)** | Coulomb blockade quantizes island charge n, n+1, n+2… → discrete conductance oscillations = intrinsic multi-valued | ultra-low (single-electron, ~e²/2C per event) but slow & cryogenic | island ~nm | Lab; reliable operation cryogenic; room-temp needs sub-10 nm islands | Yes — multi-valued cells, TG-SET (3-gate) ternary multiplier, SET+MOSFET hybrid | **DIRECT** physics (charge quantization) / SPECULATION for fab |
| **Memristor (RRAM)** | Multi-level resistance via filament/interface history → ≥3 distinguishable, non-volatile resistance states | pJ–sub-pJ writes reported (device-dependent) | 2-terminal cell ~few nm–µm² | Mature for memory (RRAM in production) | Yes — MTL, ZnO 3-valued multiplier, Łukasiewicz logic, CNTFET+memristor gates | **DIRECT** for storage / ANALOGY for logic (passive, needs restore) |
| **Independent-gate FinFET (multi-gate "3-point")** | Two independently-driven gates → one device with 3 distinct drive-current states (both-off / one-on / both-on) | CMOS-like (fJ–sub-fJ) | one fin, two gate contacts | **Mainstream production** (FinFET 22 nm and below) | Yes — ternary gates, ternary SRAM, TCAM cells | **DIRECT** (single device, 3 states, in production) |
| **Quantum-dot (QCA, ternary)** | Electron population arrangement in a dot cell; 3-electron / 8-dot cell → 3 minimum-energy configurations | theoretically near-Landauer (no current flow); clocking energy unresolved | cell ~tens of nm (molecular) | Lab; metal-dot at mK; molecular proposed | Yes — ternary QCA, ternary memorizing cell, ternary T flip-flop | **DIRECT** physics / SPECULATION for any practical fab |
| **Spintronic (MTJ / domain-wall / skyrmion)** | MTJ = 2 states (P/AP); 3+ states via stacked/multi-domain cells; non-volatile | fJ writes; read via TMR | MTJ ~tens of nm | MRAM in production (2-level); multi-level demonstrated | Yes — ternary flip-flop, spintronic ternary logic-in-memory | **DIRECT** for memory / ANALOGY for logic (2-terminal) |
| **Ferroelectric FET (FeFET)** | Partial ferroelectric polarization → multiple threshold voltages in ONE device (non-volatile multi-Vt) | CMOS-like; write via polarization switching | ~CMOS transistor + HfO₂-based FE layer | R&D; HfO₂/CMOS-compatible, entering foundry programs | Multi-level demonstrated; ternary less mature | **DIRECT** (one device, multiple native thresholds) / emerging |
| **Josephson junction (superconducting)** | Quantized flux / RSFQ pulses → discrete states; ternary cryogenic memory | extremely low (aJ–fJ) but 4 K cryostat dominates | junction ~µm² | Lab/fab (quantum-computing infrastructure) | Proposed — ternary cryogenic memory cells | **SPECULATION** for a room-temp processor |

---

## 2. Per-device detail

### 2.1 Resonant-tunneling diode (RTD) — the NDR device

**Physics.** An RTD is a double-barrier quantum well (e.g. InGaAs/InAlAs on InP, or
InAs/AlSb). Electrons tunnel *resonantly* when their energy aligns with a quasi-bound
state in the well, so the I–V curve rises to a **peak**, then **falls** as bias detunes
the resonance — negative differential resistance (NDR). NDR is the *generic* ingredient
for multi-stability: a load line (resistor, or a second RTD) intersecting a folded
(peak/valley) I–V curve can cross it at **more than two points**, each intersection a
stable bias point = a distinct voltage level. This is the *only* device in the survey
whose single-device I–V is intrinsically non-monotonic, which is why it keeps appearing
in MVL.

**MOBILE (monostable–bistable transition logic element).** Maezawa & Mizutani (1993)
showed the canonical circuit: a *load* RTD in series with a *driver* RTD (with FET
inputs). The driver's peak current is modulated by the input(s); when the driver peak
current exceeds the load's, the output snaps between the two stable points — a
monostable↔bistable transition that is a thresholding gate. Multiple-input RTDs turn this
into a multi-input threshold gate; Waho et al. (1998) built HEMT+RTD circuits with
"multiple thresholds and multilevel output" and an explicit **ternary quantizer**
(Itoh & Waho, "ultrafast ternary quantizer"; 10-GHz MVL quantizers). So RTDs are the
longest-established *native* MVL/ternary device family.

**Energy / speed.** RTDs are the fastest solid-state electronic devices: sub-ps switching
and THz-range oscillation are documented (antimonide RTDs toward ~1.9 THz). Gate-level
energy is ~fJ-scale and "low-power" relative to same-era CMOS at GHz — but a *single
settled* "J/switch" figure does not exist because it is a III-V circuit family, not a
standard-cell number. Treat energy as "fJ-range at ps switching; not a PDK number".

**Area / maturity.** An RTD is a small mesa (µm²); a MOBILE gate is 2–3 RTDs + 1–2 HEMTs,
so it *can* be denser than a CMOS gate for the same logic function. But it is III-V,
MBE-grown, and outside the CMOS roadmap — lab/niche-fab (NTT, and earlier Raytheon/TI
work), no modern high-volume path.

**Ternary verdict.** Strong, genuine, and old. **DIRECT** on "intrinsic multi-state
physics"; **ANALOGY** on "native polar *transistor*" — an RTD is a 2-terminal diode with
a negative-resistance region, not a 3-terminal gain device; to make it a "transistor" you
need a gate (resonant-tunneling *transistor*, RTT) or co-integrated FETs, and even then it
does not by itself produce the clean push/null/pull rail convention.

### 2.2 Multi-threshold CNTFET — the canonical ternary transistor

**Physics.** A semiconducting single-wall carbon nanotube has a bandgap that scales as
1/diameter, and the chirality (n,m) fixes the diameter. So *choosing the nanotube* fixes
the threshold voltage Vt of the resulting FET. A ternary gate is then built exactly like
CMOS — but from CNTFETs of **two (or three) different chiralities**, i.e. two (or three)
native thresholds. The **standard ternary inverter (STI)** uses 2 n-type + 2 p-type
CNTFETs with two threshold voltages to map input {0, Vdd/2, Vdd} → output {Vdd, Vdd/2, 0}
directly: the middle rail is produced by the *threshold structure itself*, not by a
sense-amp+driver. That is precisely the "device that thresholds 3 states natively" the
polar-gate report gestures at — the 2-threshold demux is folded into the transistor
thresholds instead of bolted on as sense amps.

**Track record.** Lin, Kim & Lombardi (IEEE Trans. Nanotechnology 2011) gave the canonical
CNTFET ternary gate and arithmetic-circuit designs; their earlier MWSCAS 2009 paper
introduced the gate; they also designed a CNTFET ternary SRAM/memory cell (2012).
Raychowdhury & Roy (IEEE TNANO 2005) laid out carbon-nanotube *voltage-mode multi-valued
logic* (including ternary) — the foundational MVL-CNTFET reference. There is a large
follow-on literature (low-power ternary multipliers, CNTFET+RRAM hybrid ternary gates).

**Energy / area.** CNTFETs promise near-ballistic transport and low subthreshold swing;
device-level "sub-fJ" switching is *claimed* in modeling literature, but there is no
settled foundry number (the technology isn't in a PDK). Area: the channel is ~nm-scale,
but a ternary gate is 4–6 CNTFETs (not one), so the "native" win is the *removed
receiver*, not a 1-transistor gate.

**Maturity.** Lab, but with a real milestone: Hills et al. (2019, *Nature*) built
RV16X-NANO, a 16-bit RISC-V microprocessor from 14,000+ complementary CNFETs in a
CMOS-compatible flow. Still research-fab (MIT/SkyWater), not high-volume, with chirality
purity / placement / yield as open problems.

**Ternary verdict.** The single most-cited "native ternary transistor" in the literature.
**DIRECT** on the mechanism we actually need (multi-Vt native thresholds eliminating the
receiver tax); **ANALOGY** on "one device = 3 states" — it is still *several* 2-level
transistors with *tuned* thresholds, and controlling chirality at scale is the unproven
part (→ SPECULATION on manufacturability).

### 2.3 Single-electron transistor (SET)

**Physics.** A SET is a small conducting island between source/drain, reached through two
tunnel junctions, with a gate capacitively coupled to the island. When the charging
energy E_C = e²/2C exceeds kT, **Coulomb blockade** forbids more than one excess electron;
gate voltage shifts the island potential, so island occupancy advances in *integer steps*
n → n+1 → n+2…, and the conductance oscillates (Coulomb oscillations, period e/C_g). The
**quantization of charge is the multi-valued state**: occupancy is a discrete variable,
not a continuum — an intrinsically multi-level transistor. A **three-gate SET (TG-SET)**
gives three independent control inputs, used directly for ternary logic.

**Track record.** Yes: multi-valued logic cells from single-electron devices (U. Windsor
thesis); a "ternary multiplier of multigate SET using a 3-T gate" (IEEE 2010); and
SET+MOSFET hybrid MVL circuits (for gain/restoration, since a bare SET has low gain).

**Energy / area.** Single-electron = the lowest-charge switch (aJ and below are
physically available); but device capacitance must be ~aF for room temperature, implying
~nm islands, and reliable operation is mostly cryogenic. Speed is modest and fan-out/restoration
needs hybrid MOSFETs.

**Maturity / verdict.** Lab. **DIRECT** on "intrinsic discrete states" (the closest
thing to a device whose *states are quantized by nature*); **SPECULATION** on fab — no
high-volume path, cryogenic or ultra-scaled, and the polar-rail voltage convention would
still need translation to charge number.

### 2.4 Memristor (RRAM)

**Physics.** A memristor's resistance is a function of the *history* of applied
voltage/current: filament formation/dissolution (oxygen vacancies, metal ions) or
interface barriers move the device between resistance levels. By controlling the
write/compliance current, **≥3 distinguishable, non-volatile resistance states** are
routinely demonstrated — 3 states is not a physics stretch, it's a programming choice.

**Track record.** Strukov et al. (Nature 2008) "the missing memristor found" (TiO₂) is
the anchor. Ternary/multi-valued logic is an active literature: "MTL: Memristor Ternary
Logic Design" (Luo et al.); a univariate ternary logic and three-valued multiplier in a
nano-columnar ZnO memristor (RSC Adv. 2019); "Realization of Ternary Łukasiewicz Logic
using BiFeO₃-based memristive devices"; and CNTFET+memristor hybrid ternary gates
(Microelectronics Journal).

**Energy / area.** RRAM writes are pJ-to-sub-pJ (device-dependent; this is memory-class
energetics). Cell is a 2-terminal device at few-nm–µm², and RRAM is *in production* as
non-volatile memory — the most mature device in this list for the *storage* half.

**Verdict.** **DIRECT** for non-volatile 3-state storage (3 states = 3 resistances);
**ANALOGY / SPECULATION** for a *transistor* — a memristor is passive, has no gain, so a
logic gate still needs a driver/selector/restore stage, i.e. it can *hold* the trit but
not *restore and fan it out* without the same tax polar_gates.md measured. It is a
promising *memory* element, not a native *logic transistor*.

### 2.5 Independent-gate FinFET (multi-gate "3-point")

**Physics.** A FinFET's channel fin is wrapped by the gate; an **independent-gate (IG)
FinFET** splits the gate into a front gate and a back gate with separate contacts. Because
drain current is controlled by *two* independent voltages, a *single* device can sit in
**three distinct drive states** (both gates off / one gate on / both gates on) — the
"3-point" device. A single IG-FinFET is therefore a genuine *single-transistor* ternary
primitive (3 current states), and it needs no exotic material: it is the standard
multi-gate transistor that already exists at 22 nm and below.

**Track record.** Used for ternary TCAM cells (asymmetric TCAM via FinFET, IEEE 2014;
power-gated TCAM storage), for ternary gates ("A novel FinFET-based approach for the
realization of ternary gates"), and for ternary SRAM cells. The 3-state behaviour here is
real, demonstrated, and on the manufacturing roadmap.

**Energy / area.** CMOS-class: fJ-to-sub-fJ switching at advanced nodes; area ~ a normal
FinFET (one fin, two gate contacts). This is the *only* candidate whose energy/area/maturity
numbers are solid standard-cell facts, because it is ordinary production silicon.

**Verdict.** **DIRECT** — a single production device with 3 drive states, no exotic
physics, no new fab. The honest caveat: the 3 states are *current* levels; converting to
the push/null/pull *voltage* rails still needs a load/resistor network (3 current states
→ 3 rail voltages), and the independent-gate structure costs some drive strength vs a
tied-gate FinFET. But it is the closest thing to a "native polar ternary transistor" that
can be taped out *today*.

### 2.6 Quantum-dot cellular automata (ternary QCA)

**Physics.** A QCA cell confines a fixed number of electrons in quantum dots; the
electrons adopt the minimum-energy arrangement under mutual Coulomb repulsion. Binary QCA
uses 2 electrons/4 dots (2 diagonal states). **Ternary QCA** uses 3 electrons in an 8-dot
cell → **three** minimum-energy configurations. Encoding is by *charge position*, with
ideally no current flow (information moves by Coulomb field, not charge transport).

**Track record.** Sabbaghi-Nadooshan et al. ("Computing with multi-value logic in quantum
dot cellular automata", Springer); "The Ternary Quantum-dot Cellular Automata Memorizing
Cell"; and 2025 ternary QCA reversible T flip-flop designs.

**Energy / maturity.** Theoretically near-Landauer (no dissipative charge flow); but
metal-dot demonstrations are at mK, molecular QCA is proposed-not-built, and the *clocking*
energy (the adiabatic 4-phase clock that drives QCA) is unresolved. Very early lab.

**Verdict.** **DIRECT** physics (three genuinely stable, *native* configurations — the
cleanest "3 native states" in the survey); **SPECULATION** for any fab: no manufacturable
implementation, no voltage rails, no integration path.

### 2.7 Spintronic (MTJ / domain-wall / skyrmion)

**Physics.** A magnetic tunnel junction is two ferromagnetic layers separated by a barrier;
its resistance depends on relative magnetization (parallel = low R, antiparallel = high R)
— two states, non-volatile, read by tunneling magnetoresistance (TMR). **Three+ states**
come from *stacking* MTJs, from multi-domain/domain-wall structures, or from multi-level
MRAM cells — i.e. multi-valued by composition, not by a single junction's intrinsic
physics.

**Track record.** MRAM (2-level) is in production (Everspin, and embedded MRAM at TSMC/
Samsung). Ternary is demonstrated: "High-Performance Spintronic Nonvolatile Ternary
Flip-Flop and Universal Shift Register" (IEEE TVLSI 2021) and "Ternary computing using a
novel spintronic multi-operator logic-in-memory architecture" (2025).

**Verdict.** **DIRECT** for non-volatile 3-state *memory*; **ANALOGY** for a logic
*transistor* — an MTJ is 2-terminal (a resistive element read by a CMOS access
transistor), so a spintronic "ternary gate" is really CMOS + multi-state resistor, and
write energy is asymmetric/relatively high. Strong as a storage adjunct, weak as the
native logic device.

### 2.8 Ferroelectric FET (FeFET)

**Physics.** A FeFET places a ferroelectric (doped-HfO₂ class, e.g. HZO) in the gate
stack. Partial switching of the ferroelectric polarization shifts the transistor's
threshold voltage continuously, so **one transistor holds multiple native threshold
states** (multi-level, non-volatile). This is the *only* device where "multiple
thresholds in a single transistor" is literally true rather than "several transistors of
different thresholds".

**Track record.** Multi-level FeFET is an active device field (US 11,430,510 multi-level
FeFET; FeFET CAM/RAM integration). Ternary *logic* on FeFET is less developed than
multi-level *memory* — a gap, not a refutation.

**Maturity.** R&D, but the HfO₂-based ferroelectric is CMOS-compatible and entering
foundry programs (embedded non-volatile memory). Closer to fab than RTD/SET/QCA, further
than FinFET.

**Verdict.** **DIRECT** on "one device, multiple native thresholds" (exactly the
"multi-Vt in one transistor" ideal), **SPECULATION** on a mature ternary-logic PDK — the
multi-level threshold *distribution* (variability) and endurance are the open questions.

### 2.9 Josephson junction (superconducting)

**Physics.** Superconducting Josephson circuits quantize magnetic flux and use single-flux
quantum (SFQ) voltage pulses; the discrete flux/phase states are naturally multi-valued.
Ternary cryogenic memory cells have been proposed (APS March Meeting 2019), and RSFQ has
inherently pulse-based MVL flavours.

**Maturity.** Lab/niche-fab, but note that superconducting-qubit fabrication has built
large Josephson-junction fabs — so this is a *real* fab family, just cryogenic (4 K).

**Verdict.** **SPECULATION** for a room-temperature polar ternary processor: the physics
is native-multi-valued, the energy per switch is tiny, but the 4 K cryostat dominates any
system-level energy accounting. Relevant only if Tau goes cryogenic.

---

## 3. The 2–3 most promising candidates for a native polar ternary transistor

Ranked against Tau's actual constraint — the demux+re-encode tax must disappear because
the *device* thresholds 3 states, and the result must be fabricable, not a physics demo.

### (1) Independent-gate FinFET — **DIRECT**

The only candidate that is (a) a *single* physical device with 3 distinguishable drive
states, and (b) **in mainstream production today** (FinFET 22 nm and below). No new
material, no new physics, no cryostat — the "3-point" is a wiring choice (two gate
contacts). Ternary SRAM/TCAM/gate demonstrations exist. The tax it removes is exactly the
one `polar_gates.md` measured: with a device that has 3 intrinsic states, the 2-sense-amp
demux is gone. Caveat (honest, not disqualifying): the 3 states are *current* states; the
push/null/pull *voltage* rails still need a passive load to convert current → voltage, and
independent gating trades some drive strength. Net: **DIRECT** and the pragmatic front-runner.

### (2) Multi-threshold CNTFET — **DIRECT** (mechanism) / **ANALOGY** (single-device)

The canonical "native ternary transistor" of the literature (Lin/Kim/Lombardi;
Raychowdhury/Roy). The standard ternary inverter *is* a native 3-rail gate — the middle
rail is produced by tuned thresholds, not by a receiver. It eliminates the receiver tax at
the mechanism level, which is exactly what Tau needs. But the honesty clause: it is 4–6
CNTFETs of 2–3 chiralities, **not one device**, and chirality-controlled placement at
scale is still unproven (SPECULATION on manufacturability, despite RV16X-NANO). Best
*cadence* answer; not a "one transistor" answer.

### (3) RTD / resonant-tunneling (NDR) — **DIRECT** (physics) / **ANALOGY** (as a transistor)

The only device whose *single-device I–V is intrinsically non-monotonic* — NDR is the one
mechanism that gives multiple stable points from one structure, and it has the oldest,
richest MVL/ternary record (Waho's multilevel/ternary quantizers). If "native" means
"the physics yields 3 states from one structure," RTD is the purest. The catch: it is a
III-V **diode** (or a gated RTT), not a CMOS transistor, so it is **ANALOGY** as a
"polar transistor" and off the CMOS road. Keep it as the *physics reference* for what a
native 3-state I–V looks like.

**Honourable mention — Ferroelectric FeFET:** the one device where "multiple thresholds
in a *single* transistor" is literally true, and the HfO₂ material is CMOS-compatible
(→ DIRECT in principle). It is held back only by maturity (multi-level *memory* is far
ahead of ternary *logic*, and threshold variability/endurance are open). Watch it, but it
is not yet a logic PDK. **SPECULATION** for now.

**Deliberately ranked lower, with reason:**

- **Memristor & spintronic MTJ** — genuine 3-state *storage* (DIRECT), but they are
  passive 2-terminal devices with no gain; a "ternary gate" made from them re-pays the
  restore/driver tax. They are *memory* answers, not *transistor* answers.
- **SET & QCA** — the cleanest *native* discrete states (DIRECT physics), but cryogenic /
  non-manufacturable (SPECULATION). Excellent as physics intuition, not as a device bet.
- **Josephson** — native multi-valued and low-energy, but 4 K (SPECULATION for a room-temp
  processor).

---

## 4. TODO / not covered / caveats

**What I could not pin down (needs deeper digging, not invented here):**

1. **A single settled "energy per switch" number for RTD/MOBILE, CNTFET, and SET.** The
   literature reports device-level *claims* (sub-fJ CNTFET, aJ-scale SET, fJ-range RTD)
   that are process- and bias-dependent; there is no standard-cell-equivalent figure. To
   put numbers in the summary table I would need to pull the specific measurement papers
   (Waho's power measurements, the CNTFET circuit simulations' energy tables) and
   normalize them — a follow-up pass.
2. **Area numbers for anything non-CMOS.** RTD/MOBILE gate areas, CNTFET ternary gate
   areas, and SET cell areas are reported in individual papers in µm² but I did not
   extract and cross-check them; the table reports mechanism-level size qualitatively.
3. **The independent-gate FinFET "3-point → push/null/pull" voltage conversion** is
   asserted from the device's 3 current states, but I did not find a paper that *measures*
   a single IG-FinFET as a complete 3-rail ternary inverter with the exact −V/0/+V
   convention. The ternary-SRAM/TCAM papers use the 3 states for *storage*, not
   necessarily as a restoring logic inverter. This is the highest-value follow-up: does a
   single IG-FinFET actually close the loop as a native polar inverter, or does it still
   need a companion load to set the rails?
4. **FeFET ternary *logic*** (vs multi-level *memory*) is thin. I did not find a canonical
   "ternary inverter on a single FeFET" paper; the multi-level FeFET literature is memory-
   oriented. Worth a dedicated search before ranking FeFET above FinFET/CNTFET.
5. **Spintronic and QCA numbers** (write energy, clocking energy) are from memory/estimate
   and not cross-checked against primary measurement papers in this pass.

**Conceptual caveats (the honest frame):**

- **"Native" has two different meanings and I used both deliberately.** (i) *Native
  states* = a single structure with 3 intrinsic stable states (RTD, SET, QCA, FeFET,
  IG-FinFET current states). (ii) *Native thresholding* = transistors whose thresholds are
  *tuned* to 3 rails so no receiver is needed (multi-Vt CNTFET). Tau's polar-gate report
  gestures at the second; this survey ranks both, and they do not imply each other.
- **No candidate is a true "one transistor → three rail voltages" drop-in.** The survey's
  honest conclusion is that the closest *production* answer (IG-FinFET) still needs a
  current→voltage load, and the closest *single-device* answers (RTD, SET, QCA, FeFET) are
  non-CMOS or immature. I did not find a device that makes the demux+driver tax vanish
  *and* is on a PDK today.
- **Energy comparisons across physics families are apples-to-oranges.** fJ/switch only
  means the same thing *within* CMOS; RTD/SET/QCA energetics include clocking, cryostat,
  or III-V integration overheads that are not in the per-switch number. Treat the summary
  column as rank-of-magnitude, not a spec sheet.
- **The polar (−V/0/+V) convention is a *Tau* framing, not a literature one.** The cited
  papers overwhelmingly use *unipolar* ternary {0, Vdd/2, Vdd}. Mapping their "middle
  rail" to Tau's "null at 0 V between +V and −V" is my translation (a level shift, not a
  change in physics) and should be re-verified against any specific device's operating
  point.
- **Calibration is against the *device's* physics, not against the lattice math.** None of
  the AGENTS.md lattice concepts (residual, ring, wedge) appear here; if a later pass wants
  to map "3 native states" to the lattice's 3 axes, that is a *separate* analogy and was
  not done here.

**What needs deeper digging next:**

- Extract and normalize the *actual* energy/area measurement tables from: Waho et al.
  1998 (RTD multilevel), Lin/Kim/Lombardi 2011 (CNTFET), the TG-SET papers, and the MTL
  memristor paper — to replace qualitative cells with cited numbers.
- Find/confirm a *single-device* IG-FinFET ternary inverter measurement (not SRAM/TCAM).
- FeFET ternary logic literature (dedicated search).
- Decide explicitly whether Tau's bet is (a) a *restoring logic transistor* (→ FinFET/
  CNTFET/FeFET) or (b) a *non-volatile 3-state memory + CMOS logic* hybrid (→ memristor/
  MTJ), because the two lead to different device shortlists.
- Sanity-check the RTD "THz/ps" claims against a specific source (the THz-oscillator
  review) before quoting in any quantitative gate-energy comparison.

---

## 5. References

**RTD / MOBILE / MVL**

- Maezawa, K., & Mizutani, T. (1993). "A new resonant tunneling logic gate employing
  monostable–bistable transition." *Jpn. J. Appl. Phys.* 32, L42–L44. (MOBILE)
- Waho, T., Chen, K. J., & Yamamoto, M. (1998). "Resonant-tunneling diode and HEMT logic
  circuits with multiple thresholds and multilevel output." *IEEE J. Solid-State Circuits*
  33(2), 268–274. ([HKUST record](https://researchportal.hkust.edu.hk/en/publications/resonant-tunneling-diode-and-hemt-logic-circuits-with-multiple-th/))
- Itoh, T., & Waho, T. "Ultrafast ternary quantizer using resonant tunneling devices."
  ([Semantic Scholar](https://www.semanticscholar.org/paper/Ultrafast-ternary-quantizer-using-resonant-devices-Itoh-Waho/bd507be6db7789f9b1d8382a3a562610aff5970d))
- "10-GHz operation of multiple-valued quantizers using resonant-tunneling devices."
  *IEICE Trans.* ([record](https://globals.ieice.org/en_transactions/information/10.1587/e82-d_5_949/_p))
- "A novel functional logic circuit using resonant-tunneling devices for multiple-valued
  logic applications." ([record](https://acnpsearch.tweb-dev.unibo.it/singlejournalindex/4657095))
- "InP-based high-performance MOBILEs using integrated multiple-input resonant-tunneling
  devices." IEEE Electron Device Lett. (DOI 10.1109/55.485189)
- "Frequency limitations of resonant-tunnelling diodes in sub-THz and THz oscillators and
  detectors." *J. Infrared Millim. Terahertz Waves* (2019).
  ([Springer](https://link.springer.com/article/10.1007/s10762-019-00573-5))

**CNTFET ternary / MVL**

- Lin, S., Kim, Y.-B., & Lombardi, F. (2011). "CNTFET-based design of ternary logic gates
  and arithmetic circuits." *IEEE Trans. Nanotechnology* 10(2), 217–225.
  ([Semantic Scholar](https://www.semanticscholar.org/paper/CNTFET-Based-Design-of-Ternary-Logic-Gates-and-Lin-Kim/de4a090635bb42a377e22c99c0f31b75b08ff68a))
- Lin, S., Kim, Y.-B., & Lombardi, F. (2009). "A novel CNTFET-based ternary logic gate
  design." *IEEE MWSCAS*.
  ([IEEE](https://ieeexplore.ieee.org/document/5236063))
- Raychowdhury, A., & Roy, K. (2005). "Carbon-nanotube-based voltage-mode multiple-valued
  logic design." *IEEE Trans. Nanotechnology* 4(2), 168–179.
  ([IEEE](https://ieeexplore.ieee.org/document/1405993))
- Lin, S., Kim, Y.-B., & Lombardi, F. (2012). "Design of a ternary memory cell using
  CNTFETs." *IEEE Trans. Nanotechnology*.
  ([ACM/IEEE](https://dl.acm.org/doi/abs/10.1109/TNANO.2012.2211614))
- Hills, G., et al. (2019). "Modern microprocessor built from complementary carbon
  nanotube transistors." *Nature* 572, 595–602. (RV16X-NANO)

**SET**

- "Design of multi-valued logic cells using single-electron devices." Univ. of Windsor
  thesis. ([scholar.uwindsor.ca](https://scholar.uwindsor.ca/etd/5743/))
- "Ternary multiplier of multigate single electron transistor: design using 3-T gate."
  IEEE (2010). ([IEEE](https://ieeexplore.ieee.org/document/5524397))
- "Multi-valued logic circuits using hybrid circuit consisting of three-gate
  single-electron transistors (TG-SETs) and MOSFETs."

**Memristor**

- Strukov, D. B., Snider, G. S., Stewart, D. R., & Williams, R. S. (2008). "The missing
  memristor found." *Nature* 453, 80–83.
- Luo, L., Dong, Z., Hu, X., Wang, L., & Duan, S. "MTL: Memristor Ternary Logic Design."
  (DOI 10.1142/S0218127420502223)
  ([zbMATH](https://zbmath.org/1466.94061))
- "A univariate ternary logic and three-valued multiplier implemented in a nano-columnar
  crystalline zinc oxide memristor." *RSC Adv.* (2019).
  ([RSC](https://pubs.rsc.org/en/content/articlehtml/2019/ra/c9ra04119b))
- "Realization of Ternary Łukasiewicz Logic using BiFeO₃-based Memristive Devices."
  ([Semantic Scholar](https://www.semanticscholar.org/paper/Realization-of-Ternary-%C5%81ukasiewicz-Logic-using-Liu-Zhao/56a21208da8c07a76a15029aa861e3c0dd69df3b))
- "Memristor-CNTFET based ternary logic gates." *Microelectronics Journal*.
  ([ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S002626921730558X))

**FinFET (independent-gate / TCAM / ternary)**

- "Design of asymmetric TCAM (ternary content-addressable memory) cells using FinFET."
  IEEE (2014). ([IEEE](https://ieeexplore.ieee.org/document/7031172))
- "Design of Ternary Content-Addressable Memories with Dynamically Power-gated Storage
  Cells Using FinFETs."
- "A novel FinFET based approach for the realization of ternary gates."
  ([Aminer](https://www.aminer.cn/pub/6228a0a95aee126c0f359be2/a-novel-finfet-based-approach-for-the-realization-of-ternary-gates))

**QCA (ternary)**

- Sabbaghi-Nadooshan, R., et al. "Computing with multi-value logic in quantum dot
  cellular automata." Springer.
- "The Ternary Quantum-dot Cellular Automata Memorizing Cell."
  ([infona](https://www.infona.pl/resource/bwmeta1.element.ieee-art-000005076411))
- "Efficient Design of Ternary Reversible T Flip-Flop Using Quantum Dot Cellular
  Automata" (2025). ([jyu.fi](https://jyx.jyu.fi/handle/123456789/98269))

**Spintronic**

- "High-Performance Spintronic Nonvolatile Ternary Flip-Flop and Universal Shift
  Register." *IEEE TVLSI* (2021).
  ([ACM/IEEE](https://dl.acm.org/doi/abs/10.1109/TVLSI.2021.3055983))
- "Ternary computing using a novel spintronic multi-operator logic-in-memory
  architecture." (2025).
  ([ScienceDirect](https://www.sciencedirect.com/science/article/pii/S2590123025000994))

**Ferroelectric**

- "Multi-level ferroelectric field-effect transistor devices." US Patent 11,430,510.
  ([Justia](https://patents.justia.com/patent/11430510))

**Superconducting**

- "Ternary and higher order classical cryogenic memory cells." APS March Meeting 2019.
  ([APS](https://meetings.aps.org/Meeting/MAR19/Session/Y08.6))

---

*Every quantitative anchor in this file is either a Tau measurement already on record
(`polar_gates.md`, `gate_energy.md`: 32–37 fJ/toggle binary, 62–183 fJ/toggle ternary on
sky130 0–1 V) or a widely documented fact (Landauer kT·ln2 ≈ 2.9 zJ at 300 K; RTD THz
oscillation; RRAM in production; FinFET at 22 nm). No device energy/area number was
invented; where the literature has no settled number, the cell says so explicitly.*
