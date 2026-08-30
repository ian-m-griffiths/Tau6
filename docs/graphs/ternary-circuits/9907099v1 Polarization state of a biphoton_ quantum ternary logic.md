# Polarization state of a biphoton: quantum ternary logic
Burlakov, Chekhova, Karabutova, Klyshko & Kulik (Moscow State University), arXiv:quant-ph/9907099v1 (1999). A physical, experimentally demonstrated ternary logic basis: the polarization state of a *biphoton* (two correlated photons from SPDC) is a three-component state, proposed as "ternary analogs of two-state quantum systems (qubits)". The three basis states are realized and switched among each other with retardation plates — all transformations reversible and number-preserving. The value lives in the **polarization direction**, not in any level.

## 1. Node inventory (id | type | name | one-line | location)

| id | type | name | one-line | location |
|----|------|------|---------|----------|
| N1 | CONCEPT | biphoton | two correlated photons from collinear frequency-degenerate spontaneous parametric down-conversion (SPDC) | Abstract, §1 |
| N2 | DEFINITION | three-component polarization state | `Ψ = c1|2,0⟩ + c2|1,1⟩ + c3|0,2⟩`, Σ|ci|² = 1, polarization vector `e = (c1,c2,c3)` (|Nx,Ny⟩ = Nx photons in x-pol mode, Ny in y-pol) | §1 eq (1),(2) |
| N3 | CLAIM | biphoton = ternary analog of qubit | assign digits 0,1,2 to the three basis states; n-element register covers 3ⁿ states instead of 2ⁿ | §1 |
| N4 | CONCEPT | SU(3) vs realized SU(2) | arbitrary transformations of e are 8-parameter SU(3); linear lossless elements (retardation plates, rotators) realize only a 3-parameter SU(2) subset that preserves the polarization degree P | §1 |
| N5 | RESULT | the P = 0 basis | `Ψ± = (|2,0⟩ ± |0,2⟩)/√2`, `Ψ0 = |1,1⟩` — all three have P = 0 and can be transformed into each other using **only** retardation plates | §1 eq (3) |
| N6 | METHOD | experiment | Mach–Zehnder + LiIO3 SPDC, λ/2 and λ/4 plates, polarizing beamsplitters, coincidence counting `G(2)xy ~ |c2|²` | §1, Fig 1 |
| N7 | RESULT | demonstrated switching | Ψ− → Ψ0 (λ/2 plate, φ=π, χ=π/8), Ψ+ → Ψ0 (λ/4 plate, φ=0, χ=π/4), Ψ− → Ψ+ (π phase shift); all reversible, high-visibility nonclassical interference (90%) | §1, Figs 2–4 |
| N8 | RESULT | number preservation | retardation plates leave the biphoton number invariant — basis for "biphoton communication systems" (single spatial mode, optical fiber) | §1 |
| N9 | CLAIM | biphotons are not wavepackets | flux so low (~hundreds s⁻¹) that biphotons almost never overlap, yet they still interfere — a |2,0⟩+|0,2⟩ state is produced by two *independent* type-I states | §1 |
| N10 | CONCEPT | Bell-state structure | Ψ± correspond to Bell states (|HH⟩±|VV⟩)/√2, Ψ0 to (|HV⟩+|VH⟩)/√2; single spatial mode removes the path-equalization requirement of [10] | §1 |

## 2. Edge inventory (src→tgt | type | calibration | evidence)

| src→tgt | type | calibration | evidence |
|---------|------|-------------|----------|
| N1→N2 | derives-from | — | the biphoton's state is the 3-term superposition (1) |
| N2→N3 | supports | — | three basis states ⇒ "ternary" register capacity 3ⁿ vs 2ⁿ |
| N3→N4 | requires | — | the state space's transformation group is what makes ternary logic *doable* |
| N4→N5 | derives-from | — | because full SU(3) is not reachable with plates, they find the P = 0 basis that *is* |
| N5→N6 | requires | — | the experiment is built to realize and verify the P = 0 basis |
| N6→N7 | derives-from | — | the measured coincidence rates demonstrate the transitions |
| N7→N8 | supports | — | reversibility + number preservation ⇒ communication use |
| N9→N7 | supports | — | interference despite non-overlap validates the state description |
| N10→N5 | analog-of | — | "the Bell states of [10] correspond to Ψ±, … Ψ0" — same states, relabeled |
| N10→N8 | supports | — | single spatial mode (a single mode, not two arms) is the practical advantage |

## 3. Counter-to / reversal edges

- **C1 — "Retardation plates implement arbitrary ternary transformations" is FALSE.** Only a 3-parameter SU(2) subset of the 8-parameter SU(3) is reachable with linear lossless elements; the polarization degree P is invariant. The workaround is to choose a *basis* (Ψ±, Ψ0) whose members all have P = 0 — then switching becomes possible. (counter-to: naive "any ternary gate is physically realizable".)
- **C2 — "The middle state is a 'zero' state" is FALSE in the energy sense.** Ψ0 = |1,1⟩ has one photon in each polarization mode — it is the *balanced* state (P = 0), not an empty/low-energy state. (counter-to, relevant to us: our null 00 carries no energy; their middle state carries a full photon pair's worth.)
- **C3 — "Biphotons are independent wavepackets" is FALSE (N9).** A type-II state is built from two independent type-I biphotons that essentially never overlap in space-time, yet interfere — the wavepacket picture fails for biphotons.

## 4. Map-to-current-system (lens) — TERNARY CIRCUITS

| paper concept | our system | calibration | evidence |
|---------------|-----------|-------------|----------|
| **Three-state system as "ternary analog of qubit"** — 3ⁿ states per n-register | our trit {−1,0,+1}: balanced ternary, 3 states per symbol, radix economy `log₂3 ≈ 1.585 bits/trit` (TERNARY_PROCESSOR §1.1; STATE_NOTE) | **DIRECT (math)** | both count the same thing — 3ⁿ vs 2ⁿ register capacity; the paper's state space is continuous (complex amplitudes), ours discrete (one-hot bits) |
| **The value is the polarization DIRECTION** (orientation of the state in SU(3)/mode space), not a level | **"polarity is the value"**: one-wire push/pull/null, receiver reads the *direction* of the excursion, not the voltage (TERNARY_PROCESSOR §1.2; plan §3) | **ANALOGY** | the same principle in a different medium — their value lives in the polarization *direction* of light, ours in the *direction* of a wire excursion; both reject level-encoding. This is Ian's polarity-as-value idea in *photons* (Yeom 2025 is the silicon instance) |
| **Reversible, number-preserving gates** (plates don't split pairs) | our energy claim: null = no electrons, ≤1 energized line per trit (TernaryCell.lean, PROVED; rtl/trit_functions.vh header) | **ANALOGY** | reversibility as an energy principle — theirs is lossless optics (no dissipation, no information lost), ours is "don't energize the line when you don't need to"; different mechanisms, same motivation |
| **SU(3) space, SU(2)-realizable subset** — the *cheap* transformations form a small subgroup | **Z₆ unit group / cheap gauge change**: six rotations `(a,b) → (−b, a+b)` etc., a negate+an add, no multiplies (Rotation.lean T3 PROVED; TERNARY_PROCESSOR §2.2 `TROT`) | **ANALOGY** | both: of all possible transformations, only a small, structured subgroup is cheaply realizable — theirs SU(2) ⊂ SU(3) by optics, ours Z₆ ⊂ GL(2,ℤ) by integer cost |
| **Ψ0 = |1,1⟩ as the intermediate/balanced state** | our null 00 (nothing energized) and the `11 = never` forbidden combination | **SPECULATION** | the paper's middle state is *energetically present* (one photon in each mode) — the opposite of our energy-free null; any mapping is by position-in-the-triad, not by physics (see C2) |
| **Bell-state entanglement of the pair** (bound two-photon correlation) | "entanglement = mutual prediction H(A\|B) + H(B\|A)" (AGENTS.md quantum table) | **SPECULATION** | a bound correlation in both, but the paper's is physical entanglement of photons; ours is a statistical co-prediction of words — tempting, unproven |
| **RTL reuse** | `rtl/` (ternary_gates.v, trit_functions.vh, cpu.v) | **NONE / OURS** | optics experiment — no gates, no energy model transferable to Verilog; it is external *validation of the polarity-as-value principle*, not a source of circuit design |

## 5. One-liner

**A real optical ternary logic basis whose value lives in the *polarization direction* of a biphoton — Ian's "polarity is the value" in photons — with demonstrated reversible switching between all three states and the honest finding that only an SU(2) subgroup of SU(3) is cheaply realizable (the same shape as our Z₆ "cheap gauge change"), but zero RTL transfer: the middle state carries energy (not our free null) and nothing here maps to gates.**
