# ternary-transistors — folder synthesis (the "polar" hunt, all 11 papers)

**Question asked:** does any paper in `docs/ternery transistors/` (original 6 + `new/` 5) give a
**native 3-state transistor** useful to the Tau Architecture — a device whose intrinsic physics
produces a free null / push / pull triplet mapping onto the balanced-ternary trit without paying
the 2-threshold tax?

**Answer: no.** All eleven are negative. Not one gives a native push/pull/null transistor; most
don't even *claim* three states, and the two that come closest are negative examples that
confirm the trap.

## 1. Per-paper verdicts

| paper | what "polar/reconfigurable" means | verdict | nearest touchpoint |
|---|---|---|---|
| polariton transistor (1201.4071) | exciton-polariton | binary all-optical switch; spin σ± (±1) present but disabled | σ± = native ±1 → push/pull *if* harnessed (optical, cryo) |
| polar wafers "Dueltronics" (2404.03733) | crystal-face label (Ga vs N) | two 2-state devices on one wafer; not a trit | n+p push-pull = generic tri-state CMOS (OURS) |
| photonic polarization (2411.16698) | TE/TM optical polarization | binary photonic fabric; no trit | TE→/TM→ routing ≈ push/pull (ANALOGY) |
| valley polarization (2504.02497) | graphene K/K′ | binary transport axis | **null (η=0) still carries current — inverts free-null** |
| polar FET compact model (2511.01699) | polarization-induced 2DEG/2DHG | standard FET model; e/h pair charge-neutrality-locked | e/h formation costs band gap (2-threshold tax) |
| BJT basics | NPN/PNP complement | 2-state + analog active region | MOSFET gate ≈ free *input* null only |
| **frequency comb (2308.00439)** | plasmonic Fano tuning | photonic; QE is a two-level qubit; no transistor | none (no sign, no −1) |
| **reconfigurable 2D optoelectronics (2503.00347)** | analog *optical* tuning | review of gate-tuned optics, not a reconfigurable FET | signed photocurrent ±/0 (ANALOGY); null = fragile gate-bias crossing |
| **graphene clock dynamics (2506.08728)** | frequency/phase timing | timing/clock paper | **ambipolar e/Dirac/hole is background physics, never exploited as a trit** |
| **polariton feedback (2507.20235)** | optical gain feedback | photonic + 4 K; continuous gain; no sign | none (feedback only *adds*) |
| **dual-memory FeFET (2511.07830)** | ferroelectric polarization | analog reservoir/synaptic demo, not discrete storage | polarity sign → facilitation/depression (weak push/pull), **no held null** |

## 2. The meta-finding (why all eleven fail together)

1. **"Polar" / "reconfigurable" is a false-friend in every single paper.** It means a
   quasiparticle, a static crystal-face label, an optical basis, a valley, a carrier-gas
   induction mechanism, an analog optical tuning, a phase/frequency, an optical gain, or a
   ferroelectric polarization — **never a discrete signed trit.** The word flatters the
   hypothesis; the physics never delivers a direction-encoded third state.

2. **Every degree of freedom on offer is BINARY, not ternary** — spin σ±, TE/TM, K/K′, NPN/PNP,
   e/h, |e⟩/|g⟩, loop-direction, bistable memory. Adding one is a *third bit* (2ⁿ), never a
   *third value* (3ⁿ).

3. **Where a third state appears, it is analog, suppressed, or bolted-on** — BJT "active" is a
   continuum; the polariton device is tuned *away* from bistability; the polar FET *depletes*
   the hole gas; the FeFET's "multi-level" is never quantized; tri-state push/pull is generic
   CMOS, not device physics.

4. **"Free null" is transport-specific, and the new batch inverts it twice more.** Valley's
   null (η=0) still carries current; the 2D-optoelectronics "null" is a *fragile gate-bias
   crossing* between positive and negative regimes; the graphene Dirac point is a *finite-
   residual conductance minimum* (σ_res), not an open circuit. Our `null_is_free` (00 = nothing
   on the wire, 0.05 pJ) is a property of the *transport encoding*, not a universal law of
   3-state physics. Four of eleven papers now testify to that, in different languages.

5. **The 2-threshold tax reappears at band-gap scale** (3.44 eV to form the e/h pair) and the
   flattery trap is stated *verbatim* in the 2D-optoelectronics review: "5 states = 5 digital
   bits" is actually 5 analog levels ≈ **2.32 bits**. The FeFET reports zero storage metrics
   and its one energy number is ~5.5× *worse* than its own comparison.

## 3. The one honest pointer that survives all 11

**Graphene's ambipolar electron / Dirac / hole conductance** is the *closest thing to a native
trit anywhere in the folder* — off/n/p ≈ null/push/pull. But:

- no paper exploits it as a trit (it appears only as *background physics* in the clock paper);
- its "null" (the Dirac/charge-neutrality point) is a **finite-residual conductance minimum,
  not a free open state** — exactly the opposite of `null_is_free`;
- and the polar-FET paper shows the deeper obstruction: **charge neutrality locks electron and
  hole gases into an equal pair** (`q·ns = q·ps`), so {electron-only / hole-only / off} is not
  independently addressable.

So the honest spec of "what a native trit would actually be" is unchanged and now sharper:

> **A device that (a) independently gates electron-only / hole-only / off, (b) whose "off" is a
> genuinely high-impedance open (not a conductance minimum), and (c) reports storage
> energy/density/endurance/variability on the honest axis.**

No paper in this folder comes within (a), let alone (b) or (c).

## 4. Salvageable hooks (calibrated, cumulative across 11)

| id | hook | calibration | notes |
|---|---|---|---|
| H1 | polariton spin σ± = native ±1 | DIRECT / SPECULATION | optical + cryo, and explicitly disabled in the paper |
| H2 | MOSFET insulated gate = free *input* null | DIRECT / OURS | holds at the control terminal only; channel still leaks |
| H3 | break the charge-neutrality lock → native e/h/off trit | SPECULATION | the sharpest "what a native trit is" spec; nobody has done it |
| H4 | free-null is transport-specific (4 independent counter-examples) | DIRECT | the most valuable *negative* result of the whole survey |

## 5. Bottom line

`docs/ternery transistors/` — all eleven papers — contributes **nothing new** to the native-3-state
hunt. Every "polar"/"reconfigurable" lead is a false-friend; every device is binary-or-analog;
and the recurring genuine findings are *negative*: the free-null thesis is transport-specific
(inverted four times), and a real 3-state conduction device pays the 2-threshold tax at
band-gap scale.

**The Tau thesis stands unchanged, now with eleven more witnesses against the native-device
hope:** ternary wins on **addressing** (3ⁿ) and **transport** (null encoding on the wire), not
on native devices, not on compute. The most valuable thing this folder produced is a sharper
statement of the thing we'd need to see — H3 — which no paper provides.
