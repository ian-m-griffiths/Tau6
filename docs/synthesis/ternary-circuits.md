# SYNTHESIS — Ternary Circuits (19 papers → our ternary design)

How the ternary-circuit literature validates / corrects / extends OUR design. Corpus:
`docs/graphs/ternary-circuits/` (19 graphs). Our design: cell = one-hot-per-direction
(`01`=push, `00`=null, `10`=pull, `11`=NEVER), energy ≤1 line, null free, avg 2/3 vs binary 1
(proved, `TernaryCell.lean`); RTL = `tneg/tand/tor/tmul/tadd1` + TADD/TSUB/TROT/TNORM
(`rtl/`); Lean ledger `proofs/INDEX.md`.

## 1. The verdict

| Category | What the literature says |
|---|---|
| **CONFIRMED** | Our gate algebra, our 2-bit trit code (down to the forbidden `11`), our balanced carry, radix economy log₂3, the Eisenstein/hex energy advantage, and the 3-operand balanced-adder strategy are all independently re-derived — in some cases bit-for-bit (sections 2). |
| **CORRECTED** | "Ternary saves energy" is conditional, not universal: naive 3-level design is an energy *liability* (2211.04542 divider transistors), not every ternary gate family wins on PDP (2211.12176 AND/OR lose), binary beats ternary for non-power-of-3 symbol counts (1807.06419), and hex density cuts both ways (2412.18328). "Symmetric ternary" is ambiguous (cyclic Z₃ in 2305.04115 vs our reflection); most quantum/mod-3 papers are *unbalanced* {0,1,2} — our balanced convention must be re-asserted at every citation. And every physical "middle state" in the corpus is driven or parasitic — the strongest correction to any "3 states per device is free" reading (section 3). |
| **OURS** | The **energy-free null** (`00` = no energized line, energy 0, Lean-proved) — no paper has it; their middle states cost energy or are epistemic placeholders. Also ours: the one-hot-per-direction code as a *proved* energy bound, Z₆ gauge-as-cheap-integer-rotation (TROT), 7-hex↔balanced-ternary bijection, fractal RAM 7ⁿ, and the residual/wedge math behind the machine (sections 3). |

## 2. The confirmed core — DIRECT mappings

### 2a. The gate algebra: MVL min/max/neg = our `tand`/`tor`/`tneg`
- **2309.01615** (memristor-CMOS): TMIN/TMAX (Table 1) = our `tand`/`tor`; STI (−1↔1, 0→0, Table 2) = our `tneg` — **same digit set {−1,0,+1}, same truth tables**, `rtl/trit_functions.vh`.
- **1807.06419** (Kak): Table 6 NOT/AND=min/OR=max on {−1,0,1} — "their Table 6 IS our gate library".
- **2211.04542** (thesis): TAND=min, TOR=max, STI Ā=2−A on {0,1,2} = our gates under the affine relabel {0,1,2}→{−1,0,+1}.
- **2211.12176** (TLG): AND=min / OR=max / STI via threshold logic — same functions.
- **1502.05748** (M-semantics): ∧=min, ∨=max, ¬=negation over an ordered value set — "their M restricted to 3 values is exactly our gate set".
- **2111.01558** (magnonic): T-OR = max of inputs — same operation, unbalanced values.
- **2305.04115**: ALPHA/BETA = min/max (DIRECT shape, 0<1<2 order) + a functional-completeness theorem for a 4-op set (ANALOGY — we could mirror it for {tneg,tand,tor,tmul,tadd1}).

### 2b. The memristor-CMOS arithmetic tables = our `tadd1`/`tmul`
- **2309.01615** Table 7: HA-C carry rule (carry −1 only at (−1,−1), +1 only at (1,1)) = our `tadd1` balanced carry (`s≤−2 → cout −1; s≥2 → cout +1`); MUL = sign product with 0-absorb = our `tmul`. **Fabricated silicon**: the paper's §6 chips are proof the gate set we synthesize in Verilog matches real hardware.
- **2211.12176**: our `tadd1` IS a ternary threshold gate — `sgn(Σwᵢxᵢ+ε)+1` is exactly the s≥2/s≤−2 digit-sum threshold; their XOR = mod-3 sum (ANALOGY: they drop the carry, we keep the balanced ±1 carry).
- **2204.01000**: ripple half/full-adder + partial-product multiplier structure (DIRECT architecture; ANALOGY digit convention: their unbalanced mod-3 vs our balanced).

### 2c. The trit encoding: PDR's 01X code and the thesis's "This Case Does Not Exist" = `encode_never_both`
- **2105.09169** §IV-D: 01X two-rail code `(v0,v1)`: 00=X, 10=0, 01=1, (1,1) explicitly forbidden — **literally our 2-bit trit code** (`00`=null, `01`=+1, `10`=−1, `11`=NEVER, `rtl/ternary_gates.v` header; `encode_never_both`, `TernaryCell.lean`). This is a *verification* paper: the code family was re-derived independently in formal-methods land.
- **2211.04542** Table 5.4: binary↔ternary converter rails `(O1a,O1b)`, `(1,1)` marked **"This Case Does Not Exist"** — the same engineering fact we prove in Lean, confirmed in CNFET-simulated hardware. Their trit→2-bit maps (0→00, 1→02, 2→20) are the same code family, different rail labels.
- **Automated_synthesis**: don't-care `x` in truth tables = our `11` slot ("identical concept: the unused state is free minimization material").
- **1502.05748**: K3-X don't-care = our `11`-as-don't-care role; their "0 omitted, equals its own negation" = our self-negating `00` (`tneg(00)=00`).

### 2d. The Eisenstein energy advantage: 2412.18328 Table IV = our `ternary_saves_third`
- **2412.18328** (THE key paper): Table IV — same-cardinality constellations, Eisenstein ≤ Gaussian average energy under Euclidean, squared-Euclidean AND hexagonal metrics. DIRECT at the geometric core (hex lattice needs ≤ square-lattice energy for the same symbol count — same fact as our T6 packing density τ/(4√3) ≈ 0.9069, `Packing.lean`); ANALOGY at the model level (their energy = ΣN(α) over signal points; ours = energized wires per trit). Either way: **external, citable evidence for `ternary_saves_third`**.
- Its ring machinery is our math in the 120° gauge: norm multiplicativity = T1 (`Conventions.lean`), six units Z₆ = T3a/T3b (`Rotation.lean`), ED/UFD = T5 (`EuclideanDomain.lean`), hex-distance weight = T4 (`GraphDistance.lean`), balanced smallest-norm representatives = our balanced trits / signed residual — all bridged by C1 (`ConventionBridge.lean`, φ(a,b)=(a,−b), 60°≅120° same ring).

### 2e. Radix economy log₂3 (1807.06419 + 2211.04542 + 2204.01000)
- **1807.06419**: E(b)=ln b/b maximized at b=e; b=3 is 0.5% off optimum (b=2 is 5.7% off); 1 trit = log₂3 ≈ 1.585 bits — the independent derivation for the STATE_NOTE "radix economy theorem" target.
- **2211.04542** §1.3: 2ⁿ=3ᵐ ⇒ n=1.585m; 12 bits → 7 trits = 41.7% fewer wires. **2204.01000** §A.2: ternary 37% more compact, n_m = n₂/log₂m — the same 1/log₂3 ≈ 0.63 identity.
- **2401.03521**: only n=2,3 phase alphabets have equal pairwise distance — ternary is the densest *symmetric* radix (ANALOGY: geometric optimality in phase space, complements the information-theoretic argument). Caveat from 1807.06419 itself: binary wins for non-power-of-3 symbol counts and near-2ⁿ ranges — radix economy is range/distribution-conditional, not a blanket win.

### 2f. Synthesis tooling: Automated_synthesis = our Yosys step; 3-operand `tadd1` validated
- **Automated_synthesis**: truth-table→netlist synthesizer (CNTFET/SPICE) = the ternary analogue of our `rtl/*.v` → yosys (~6–7K cells, 213 FFs) → iverilog pipeline — "the paper Ian flagged as maps to our Yosys step". Its canonical base-3 function indexing (19,683 two-input functions need names) is DIRECTLY adoptable as a naming standard our RTL lacks (we use 6 hand-named cells). **Its headline result: the 3-operand balanced full-adder (hybrid) beats 2-operand gate composition on power–delay product (1.10e-15 J vs 1.44e-15 J)** — independent confirmation that our `tadd1` (already a 3-operand cell, 27 reachable (a,b,cin) triples, `rtl/trit_functions.vh` lines 32–49) is the right architecture, and transistor count is not the figure of merit.
- **2211.04542**: binary↔ternary converter pair = our TCVT opcode + 2-diode receiver sketch (`TERNARY_PROCESSOR.md` §1.4/§2.2) (DIRECT function, ANALOGY implementation); its **88–99% PDP reduction** methodology is the measured-evidence playbook for our power pass (step 4c).

### 2g. The pure-math papers (1309.2685, 1903.06044, 2411.09383, 2510.04544): no RTL, but they legitimize the measure
- **1903.06044** (Westerbaan): measure AND integral are lattice valuations (monotone + modular into an ordered Abelian group). DIRECT: our per-trit energy (energized-line count on {push,pull}) is a counting valuation in exactly that sense; the min+max=sum identity (Lemma 212) is the arithmetic our `tadd1` sum/carry decomposition implicitly uses (a 1-line Lean port candidate, not in the ledger). Guardrail: their *additive* valuations are NOT our *multiplicative* norm N=a²+ab+b².
- **1309.2685** (Marigo): complete (bijective, join/meet-closed) valuations ⇔ dimension-≤2 posets with a two-order realizer. DIRECT on the "energy is a valuation" read; poses a testable question on our 7-hex↔balanced-ternary bijection (T2b/SevenHex) and 7ⁿ addressing (FR1) — do they satisfy complete-valuation closure? Small Lean theorem if true. "Complete" here ≠ measure-completeness (terminological collision).
- **2411.09383 / 2510.04544** (Böröczky et al.): GL(2,ℤ)-covariant valuations on lattice polygons are a *rich* family, while full invariance collapses to constants — "discreteness breaks uniqueness", the same moral as our counts-not-probabilities thesis; our Z₆ isotropy (G1) sits inside their GL(2,ℤ) as the finite hexagon-preserving subgroup. Ehrhart counting = the DIRECT anchor for integer counting. Warning kept: their τ is the golden ratio, not our 2π.

## 3. The critical distinction — the thing the literature does NOT have: our energy-free null

Every paper's "middle state" is a physical presence, a rail, or an epistemic placeholder:

| Paper | Their middle state | Why it costs energy / isn't a null |
|---|---|---|
| 2309.01615 (memristor-CMOS) | 0 = driven GND mid-level (−VDD/0/+VDD) | A level that must be generated and held — "opposite physical story: level-based vs polarity/AC-like". |
| Yeom 2025 (BP transistor) | Jmiddle ≈ 0.1 μA/μm **minority-carrier injection** | A real current, gate-independent but energetically present; **vanishes in ideal devices** (tBP < 8 nm ⇒ ternary reverts to binary) — the middle state is *parasitic, imperfect-device leakage*. Authors' own C2: "It is not our null (no electrons)." |
| 9907099 (biphoton) | Ψ0 = \|1,1⟩ (one photon per polarization mode) | Carries a **full photon pair's worth** of energy — the *balanced* state, not an empty one (C2: "our null 00 carries no energy; their middle state carries a full photon pair's worth"). |
| 2211.04542 (thesis) | logic-1 = Vdd/2 | Needs an external mid-rail; made internally with divider transistors it is a **static Vdd→GND path** — their own reversal: naive 3-level design is an energy *liability*. |
| 2211.12176 (TLG) | middle via sgn threshold | **Clocked, level-sensitive comparator** + a flip-flop per gate — why their AND/OR *lose* to CMOS. |
| 2111.01558 (magnonic) | input 0 = drive OFF; outputs = CMP frequency-shift levels | Closest cousin ("0 input costs no drive power") — but the output states 1,2 are distinguished by **how much microwave power is pumped in**, and the "memory" is a hysteresis basin that **decays in 5.11 s**. |
| 2401.03521 (LG modes) | [0, 2π/3, 4π/3] phase states | Three **equal-power phase states** — no null at all; its saving is Landauer reversibility (disjoint mechanism from our encoding density). |
| 1807.01863 (qutrit) / 2305.04115 | |0⟩,|1⟩,|2⟩ amplitudes / 0-as-bound | No null concept; their "superposition" state maps onto our *forbidden* `11`, not our `00`. |
| 1502.05748 (M-semantics) | 0 omitted from the value set | The sharpest inversion: M **deliberately drops 0** because "0 carries no magnitude information" — the literature's design philosophy treats 0 as worthless; ours makes 0 the information-carrying, zero-energy state. |

**Why our null-is-free is genuinely OURS, not a re-discovery.** (1) It is *proved at the encoding level*: `TernaryCell.lean` — `energy_le_one` (≤1 energized line), `null_is_free` (00 = no energized line, energy 0: information by doing nothing), `average_energy` (2/3 vs binary 1), `encode_never_both` / `not-surjective`. No corpus paper proves an energy bound on its middle state — they *measure* power, they never *prove* a null is free. (2) **Mechanism**: our 00 is the *absence of a drive* on a direction-encoded wire; every literature middle state is a presence (level, current, photon pair, rail). (3) Honest caveats, kept: the claim is *encoding-level* — the one-wire push/pull/null cell + 2-diode receiver (`TERNARY_PROCESSOR.md` §1.2/§1.4) is **ngspice-simulated and measured** (not fabricated in silicon) — `circuit/ENERGY_RESULTS.md`; the ∫V·I validation is DONE, not backlog. Yeom's C1 cuts against any "3 states per device is free" *physical* claim (a parasitic middle vanishes in ideal devices) — it does not touch our *chosen-encoding* claim, but it is the correction we must state whenever we say "null is free" to a hardware audience. The 1/3 saving is a per-trit lower bound; the Zipf-weighted-energy theorem is **proved** (`ZipfEnergy.lean`: expected energy = 1−P(null) < 2/3).

## 4. Top actionable next steps (ranked)

1. **(a) Formal-verify the ternary RTL via PDR/MaxSAT with `11` = don't-care (2105.09169).** The paper's MS01X two-rail 01X encoding IS our trit code, so its SAT/MaxSAT lifting, PDR/IC3, and IGBG apply directly to `cpu.v`/`ternary_gates.v` — with the `tadd1` 27-reachable-triples don't-care space as free minimization. Design around its one trap: invariant-constrained transitions (write-masking, opcode legality) break left-totality and silently invalidate lifting — add self-loops/dead-end states (our `11` is the canonical dead-end). Complement with **1502.05748**'s M-style signed-magnitude test vectors in `cpu_tb.v` (distinct |values|; output magnitude = dynamic don't-care boundary) and its quality metric to rank RTL variants. Tooling present: `boolector` is installed; PDR itself is the gap.
2. **(b) Add the ternary D-latch/FF sequential cell (2211.12176 App. A.3).** Our CPU is sequential with **binary** FFs (213 per STATE_NOTE) — the paper's SR-latch-on-TLG circuit (and 2 cross-coupled STIs) is the missing ternary state element; a ternary FF would make TBR/TROT pipelines and the fractal-RAM addressing truly trit-native. Watch their failure mode: level-sensitive, clocked ⇒ synchronization overhead (why their AND/OR lost to CMOS).
3. **(c) Yosys power pass using the 88–99% PDP methodology (2211.04542).** Copy the thesis's recipe — sweep Vdd/temp/freq, compute power×delay (PDP), report per-gate — but on our synthesized cells: `yosys synth` + liberty + `stat -power` per STATE_NOTE. Their dual-supply trick (external mid-rail kills divider static power) is the design note to carry into the one-wire cell's driver sizing; their "transistor count is a proxy" caution (Automated_synthesis C3) says report PDP, not cells. ngspice on the 2-diode receiver then validates the null-free claim physically.
4. **(d) Lean candidate: √N ≤ wtHex ≤ N (2412.18328 Thm 11).** New theorem, **not** in `proofs/INDEX.md` — candidate: bound hexDist (T4, `GraphDistance.lean`) by √norm and norm, mirroring the paper's hexagonal-weight bound; would close the loop between our metric and the energy table, and it is the paper's one DIRECT item we lack.
5. **(e) Adopt the 3-operand balanced-adder strategy explicitly (Automated_synthesis).** `tadd1` already IS the 3-operand cell, and the paper proves hybrid (non-compound) wins PDP over 2-operand composition — promote this from implicit to documented design rule: build TADD/TSUB from 3-operand cells (and 3-input carry), never from 2-input gate chains; adopt its base-3 function indexing as our RTL naming standard.

## 5. The one-sentence synthesis

The ternary-circuit literature independently re-derives our gate algebra, our 2-bit one-hot trit code (down to the forbidden `11` state, re-discovered three times: PDR verification, CNFET converters, automated synthesis), and the radix-economy + Eisenstein energy case for balanced ternary — but every physical "middle state" it builds is a driven level, a parasitic current, or an epistemic placeholder, so our energy-free null (`00` = no energized line, Lean-proved) is the one thing the corpus confirms is missing; the immediate work is to verify our RTL with `11`-as-don't-care (PDR/MaxSAT), add the ternary D-latch, and run the PDP-style Yosys power pass.

## Appendix — the 19 papers at a glance

| Paper | Gives us | Calibration |
|---|---|---|
| 2412.18328 Codes over Eisenstein Integers | Table IV energy win = `ternary_saves_third`; whole ring machinery (norm, Z₆, ED, hex weight) = our proved math; √N≤wtHex≤N = new Lean candidate | DIRECT (geometry) / ANALOGY (energy model) |
| 2309.01615 Balanced Memristor-CMOS | TMIN/TMAX/STI = tand/tor/tneg; HA-C/MUL tables = tadd1/tmul; **fabricated** balanced-ternary silicon | DIRECT truth tables; ANALOGY encoding (driven levels) |
| 2105.09169 PDR proof-obligation generalization | 01X two-rail code = our trit code; PDR/MaxSAT recipe + invariant-trap warnings for verifying `cpu.v` | DIRECT (the step-4a blueprint) |
| 2211.04542 MVL for embedded systems | STI/TAND/TOR, two-rail-one-forbidden converter ("This Case Does Not Exist" = `encode_never_both`), 88–99% PDP methodology, dual-supply trick | DIRECT (code + playbook); ANALOGY (CNFET level-coding) |
| Automated_synthesis of ternary netlists | Truth-table→netlist = our Yosys step; base-3 function indexing; **3-operand hybrid FA beats 2-operand composition** = validates `tadd1` | DIRECT (tooling + strategy); ANALOGY (backend) |
| 2211.12176 Ternary threshold logic gate | tadd1 = threshold gate (sgn semantics); ternary D-latch/FF App. A.3 = missing sequential cell; AND/OR-lose caution | DIRECT (function); OURS (no ternary FF yet) |
| 1807.06419 On Ternary Coding | Radix economy E(b)=ln b/b, log₂3≈1.585; min/max/neg tables = our gates; honest binary-wins caveats | DIRECT (economy + tables); corrected (conditional) |
| 2204.01000 Ternary in topological QC | ω=e^{2πi/3} = our ω² (Z₃ ⊂ Z₆, C1-bridged); 37% compactness = radix economy; adder/multiplier structure | DIRECT (math); ANALOGY (unbalanced mod-3) |
| 1502.05748 MVL design & verification | M-semantics = our gate set; 0 self-negating = our 00; M-simulation algorithms = testbench technique; XOR-hard warning for `tmul_trits` | DIRECT (algebra + method); OURS (their 0-omission inverted) |
| 2305.04115 Symmetric ternary composition | Functional completeness of a small gate set; ROTATE = Z₃ ⊂ Z₆; "symmetric" = cyclic, not our reflection | ANALOGY / corrected (terminology) |
| 2401.03521 Reversible ternary with LG modes | Only n=2,3 equal-distance phase alphabets; trit alphabet = ⟨ω²⟩ ⊂ Z₆; Landauer story disjoint from ours | ANALOGY (geometry supports radix-3); OURS (null absent) |
| 2111.01558 Magnonic ternary memory | T-OR = max; "0 input = no drive" (closest cousin of free null); hysteresis memory decays 5.11 s | ANALOGY; corrected (memory not free) |
| 1807.01863 QEC for ternary logic | Shift error = Z₆ gauge rotation; `11` = superposition/error syndrome → assert no wire ever equals `11` in `cpu_tb.v` | DIRECT (encoding fact); ANALOGY (quantum machinery) |
| Yeom 2025 Ternary transistors | Fabricated polarity-reconfigurable device = silicon existence proof for direction-as-information; middle = parasitic minority current, vanishes in ideal devices | ANALOGY (plausibility); counter-to (middle not free) |
| 9907099 Biphoton ternary logic | Value = polarization direction (Ian's polarity-as-value in photons); SU(2)⊂SU(3) cheap-subgroup = our Z₆; Ψ0 carries a photon pair | ANALOGY; counter-to (middle not free) |
| 1309.2685 Complete valuations | Energy-as-counting-valuation legitimized; complete-valuation question for 7-hex / 7ⁿ bijections | DIRECT (valuation); SPECULATION (closure test) |
| 1903.06044 Lattice valuations | Measure & integral = valuations; min+max=sum (Lemma 212) underlies `tadd1`; counts-not-probabilities support | DIRECT (philosophy + lemma); no RTL |
| 2411.09383 / 2510.04544 Exponential valuations | GL(2,ℤ)-covariance ⊃ our Z₆; discreteness-breaks-uniqueness moral; τ-symbol collision warning | ANALOGY; no RTL |
