# Trit Tricks — the balanced-ternary / hex-lattice analogs of the binary bit tricks

**2026-08-29 — Wave 1, subagent 3 (trit tricks) of the ternary-compute survey.** Companion to
`docs/TERNARY_COMPUTE_SURVEY.md` (the setup doc) and sibling to `control.md` (opcode encoding).

**Calibration legend** (the repo standard — mark at mapping time, verify later):

- **DIRECT** — measured, proved, or a textbook identity. Cite the number.
- **ANALOGY** — structural resemblance, not identity. The shapes match; the objects differ.
- **OURS** — our design claim; follows from DIRECT but is not independently established.
- **SPECULATION** — untested hypothesis; flagged as such, never stated as fact.

---

## 0. The cost model (read before the table)

### 0.1 The density argument

Every trit carries **log₂3 = 1.5849625… ≈ 1.585 bits** of information, vs 1 bit per binary
wire. This is the *radix economy* statement: the cost of representing a number in radix `b`
is `b/ln b` (digits × per-digit states per bit of information), minimized at `b = e ≈ 2.718`;
among integers, `b = 3` wins. **[DIRECT] — proved in `proofs/.../Hexagon/RadixEconomy.lean`
(`ternary_beats_binary`: `3/ln3 = 2.731 < 2/ln2 = 2.885`), and the survey cites it.**

Word-size consequences (all **[DIRECT]** arithmetic):

| word | range | bits of information | note |
|---|---|---|---|
| 6 trits | 729 = 3⁶ | 9.51 | the "tryte" group in the modern coinage |
| 12 trits | ±265 720 = (3¹²−1)/2 | 19.02 | our PoC word (packs exactly in 24 bits) |
| 18 trits | ±(3¹⁸−1)/2 | 28.53 | the **Setun** word size (1958, Brusentsov, Moscow State) |
| 40 trits | ±(3⁴⁰−1)/2 | 63.40 | between 2⁶³ and 2⁶⁴ |

### 0.2 Density is a *namespace* win, not automatically a *joules* win

The survey's Law 1 (receiver gauge-agnostic) says every ternary gate pays a **2-threshold
measurement tax** per cycle vs binary's 1. So "1.585× the information per wire" reduces
*wires-per-value* and *opcode/address namespace*, but it does **not** by itself reduce
*energy-per-operation* — the 2-threshold tax has to be beaten first, and the break-even is
**unmeasured**. **[OURS/SPECULATION] — the whole point of the survey is to measure it.**

### 0.3 The three cost levers a trit trick can pull

1. **Density** — one trit-op processes 1.585× the information of one bit-op (fewer ops per
   value for any *reduction*: digit-sum, parity, min/max).
2. **Fewer ops** — some tricks vanish entirely (negation is carry-free, sign is implicit,
   `abs` is tritwise), so the trick costs 1 op where binary costs 3–4.
3. **The free null** — `0` is a real, data-bearing, *zero-energy* digit (proved:
   `TernaryCell.lean` `null_is_free`, `energy .zero = 0`; average 2/3 energized line vs
   binary's 1), and the `11 = NEVER` encoding leaves a spare don't-care state
   (`encode_not_surjective`). Masking *to* zero is a native state transition, not a reserved
   code.

The table below tags each trick with which lever(s) it pulls and whether the verdict is a
genuine win or just a rename.

### 0.4 Encoding note (do not misquote)

Canonical RTL trit encoding (`rtl/trit_functions.vh`, and the survey): **`01 = +1`, `00 = 0`,
`10 = −1`, `11 = NEVER`** (one-hot-per-direction: push / null / pull). The Rust emulator
(`rust-mirror/src/ternary.rs`) packs the *complementary* convention (`00 = −1, 01 = 0,
10 = +1`, `11` reserved). Both are in the tree; this is an **open inconsistency to reconcile**,
not a catalog claim. The math below is encoding-independent.

---

## 1. The two free primitives every trit trick rides on

**P1 — negation is carry-free.** In balanced ternary, `−x` is the per-trit swap `−1 ↔ +1`
(`0` stays `0`). One tritwise op, no carry chain, no `~x + 1`. **[DIRECT] — implemented
(`word_neg`, `Neg for Trit`) and tested; the survey lists TSUB = "negate (digit swap — carry-free)
then add".**

**P2 — sign lives in the digits.** There is no sign bit; the sign of `x` is the sign of its
most-significant non-null trit. `n mod 3` is the least-significant trit `t₀` (since `3ⁱ ≡ 0
(mod 3)` for `i ≥ 1`). **[DIRECT] — definitional.**

These two are the ternary answer to binary's "shift-left is ×2, `n&1` is parity" freebies —
and they are the *stronger* freebies, because they give you sign and mod-3 for free where
binary gives you neither.

---

## 2. The catalog

| # | bit trick | trit / hex analog | cost verdict | calibration |
|---|---|---|---|---|
| 1 | **popcount** — Hamming weight, `#(set bits)` | **balanced digit-sum** `S = Σ tᵢ = #(+1) − #(−1)` | Neutral on op count (both are a tree of adds), **richer**: the trit version is *signed* — it yields the "count of +1 minus −1" in one reduction, where binary popcount is unsigned and needs a second pass for sign | DIRECT (definition); "signed ⇒ more info/op" ANALOGY |
| 2 | **parity** — `(−1)^popcount(i&j)` (the bivector sign) | **sign of the balanced sum** `sign(S) ∈ {−,0,+}`; plus `parity(n) = parity(S)` because `3ⁱ ≡ 1 (mod 2)` | **Cheaper** — the sign is read straight off the same digit-sum reduction (popcount's parity needs a second XOR-fold). And the CRT pair `n mod 6 = (t₀, S mod 2)` gives the **Z₆ angle** for free | sign(S) DIRECT; `(−1)^popcount ≡` bivector sign **OURS** (runs in the rebuild); `parity(n)=parity(S)` DIRECT |
| 3 | **XOR** — GF(2) addition, carry-free; `i^j` the bivector generator | **mod-3 addition** (tritwise sum mod 3, carry discarded) = GF(3) addition; the **wedge** `O_ab − O_ba` is its signed/antisymmetric residue | **More info, not fewer gates**: a mod-3 sum is 3-valued and *signed* (the wedge carries orientation, XOR is unsigned), but the gate itself pays the 2-threshold tax. Density win on *information per op*, not on *energy per gate* | mod-3 add DIRECT (GF(3)); wedge = skew DIRECT (`wedge_antisymm` proved); **"wedge = bivector *area*" is RETIRED** (project canon — it's the skew, not the area) |
| 4 | **barrel shift / rotate** — circular bit rotation | **Z₆ rotation by ω** — `×ωᵏ`, angle-add mod 6; `×ω: (a,b) → (−b, a+b)` = a negate + an add, no multiplies | **Cheaper** — a 60° rotation (the action of `e^{iπ/3}`) is exact integer arithmetic, no transcendental, no twiddle; the six rotations are permutations of the pair coordinates | Z₆ units closed under mul = mod-6 add DIRECT (`Rotation.lean`); `TROT (a,b)→(−b,a+b)` DIRECT (implemented+tested); "replaces transcendentals" OURS |
| 5 | **mask / trim** — `x & mask`, `x & ((1<<k)−1)` | **null-to-zero** (set selected trits to `0`) via the min/max gates; trit-window extract | **Cheaper** — `0` is a real zero-energy state (proved `null_is_free`), so "zero out" is a native transition, not a reserved code; the `11=NEVER` spare state is free slack | null free DIRECT (`TernaryCell.lean`); min/max as ternary gates DIRECT (RTL `tand`/`tor`; Jones "Standard Ternary Logic"); "cheaper because null is real" OURS |
| 6 | **`d >> 1` RG flow** — ring-band shift, `d = i^j`, ring ÷2 per shift | **trit right-shift ÷3** — `d = i ⊞ j` (mod-3), ring ÷3 per trit-shift | **Fewer shifts** — one trit-shift zooms 3× in scale vs binary's 2×, so `log₃(range)` vs `log₂(range)` steps = a `1/1.585 ≈ 0.63×` reduction in shift count to span the same ring range | binary `d>>1` = ring×2 **OURS** (rebuild design, runs); ternary ÷3 = ring×3 ANALOGY; "fewer shifts" DIRECT (`log₃ < log₂`) |
| 7 | **sign()** — `(x>>31) \| (x!=0)` or `(x>0)−(x<0)` | **MS non-null trit** — read the highest `tᵢ ≠ 0` | **Cheaper** — no sign bit, no compare, no shift-mask; sign is implicit in the digits | DIRECT (balanced-ternary definition) |
| 8 | **abs()** — `(x^(x>>31))−(x>>31)`, 3–4 ops | **tritwise `\|·\|`** — replace every `−1` trit with `+1` | **Cheaper** — 1 op, tritwise, no carry, no branchless trick | DIRECT (definition) |
| 9 | **negate** — `~x + 1` (two's complement) | **tritwise swap** `−1 ↔ +1` | **Cheaper** — the single biggest native win: carry-free, 1 op vs `~x+1` | DIRECT (definition; implemented+tested) |
| 10 | **`n & 1`, `n & (n−1)`, ctz** — parity / clear-low-bit / trailing zeros | **`n mod 3 = t₀` (free)**, **`v₃(n)`** = position of lowest non-null trit = "trailing nulls"; **power-of-3 test** = "exactly one non-null trit" | **Cheaper where it matters** — divisibility by 3 (a hard binary op: divide, or magic-constant multiply) is *free* here, the exact mirror of `n&1` being free in binary. ctz ↔ `v₃` is a like-for-like swap | DIRECT (`3ⁱ ≡ 0 mod 3` for `i ≥ 1` ⇒ `n mod 3 = t₀`); "power-of-3 test" ANALOGY |
| 11 | **branchless min/max** — `x ^ ((x^y) & −(x<y))` | **min/max are primitive gates** (`tand` = min, `tor` = max), and `min + max = a + b` (the valuation identity behind `tadd1`) | **Cheaper** — min/max are the *native* balanced-ternary gate family (min/max/neg), single-level, and the identity `min+max = sum` is free (it's how the adder is built) | DIRECT (min/max/neg = the standard ternary gate set; `min_add_max` proved in `ValuationEnergy.lean`) |
| 12 | **×3 = x + (x<<1)** (shift-add) | **×3 = trit left-shift** (append `0`, free); **×2 = x + x**; **×(−1) = digit-swap** (free); **×ω = TROT** | **Symmetric inversion** — the free-shift multiplier swaps from 2 to 3. Binary pays for ×3 (shift+add); ternary pays for ×2 (add). Net neutral, but a *different* cheap set: ×3, ×(−1), ×ω are all cheap | DIRECT (positional arithmetic) |
| 13 | **bit-reversal** (radix-2 FFT) | **trit-reversal** (radix-3 FFT); **6-point DFT** on the hex lattice with **exact integer roots** ±1, ±ω, ±ω² | **Cheaper twiddles** — the sixth roots of unity are the units (exact integers), so a Z₆ transform has *no irrational* twiddle factors (no √3/2 in the core), same "trig → integer" win as #4 | units = exact sixth roots DIRECT (`Rotation.lean`); "exact twiddles ⇒ cheaper" OURS |
| 14 | **Gray code** `g = n ^ (n>>1)` | **balanced-ternary reflected Gray code** — adjacent codes differ in exactly one trit by ±1 | Neutral — the construction exists and transfers; not in our tree, no cost claim | ANALOGY (standard construction) |

**Required-by-brief rows are #1–6** (popcount, XOR, barrel shift, parity, mask/trim, `d>>1`).
Rows #7–14 are the same enumeration carried through the rest of the classic Hacker's-Delight /
Bit-Twiddling-Hacks list, for completeness.

---

## 3. The ranked native trit tricks (most promising, strongest wins first)

Ranking criterion: **native-win strength × relevance to the rebuild/processor × how little it
pays the 2-threshold tax.** Calibration tags are per-line.

1. **Free negation (digit-swap).** The foundational win: `−x` is 1 tritwise op, no carry.
   Every sign/abs/subtract/rotation trick below rides on it. **[DIRECT] — already in `word_neg`
   and `TSUB`.**
2. **`n mod 3 = t₀` — divisibility by 3 for free.** The exact mirror of binary's free `n&1`,
   but for a *non-power-of-2* divisor: what costs binary a divide (or a magic-constant
   multiply) is a register read here. Paired with `parity(n) = parity(digit-sum)` it yields
   `n mod 6` by CRT — the **Z₆ angle**, the object the whole hex layer runs on. **[DIRECT]
   for the identities; OURS for "this is the cheap addressing op."**
3. **Z₆ rotation by ω (TROT) — the barrel-shift analog.** "Trig becomes mod-6 integer
   arithmetic": `(a,b) → (−b, a+b)` is a negate + an add, no multiply, no `e^{iθ}`. It is
   already an opcode and already tested. **[DIRECT] math (`Rotation.lean`), OURS framing.**
4. **Sign of the balanced sum = the `(−1)^popcount` replacement.** The rebuild's anchor
   `cos θ ≡ (−1)^popcount(i&j)` becomes `sign(Σ tᵢ)` — the same reduction, but the trit sum is
   already signed, so the sign is a byproduct, not a second fold. **[DIRECT] mapping, OURS
   "it runs the rebuild cheaper."**
5. **Mod-3 addition / the signed wedge (XOR analog).** Carry-free GF(3) add; the residue
   skew `O_ab − O_ba` is the signed analog of the unsigned XOR. Wins on *information per op*,
   not per gate — flag that the 2-threshold tax applies. **[DIRECT] (`wedge_antisymm`), and
   the RETIRED caution below.**
6. **Free null for mask/trim + the `11=NEVER` spare state.** `0` is a real, zero-energy digit
   (proved `energy .zero = 0`, avg 2/3 line vs binary 1), so masking-to-zero is a native
   transition and the spare state is free slack. **[DIRECT] (`TernaryCell.lean`), OURS
   "cheaper than binary AND-masking."**
7. **min/max primitive gates + `min+max = sum`.** The balanced-ternary logic family (min/max/
   neg) is the natural gate set, and the valuation identity is how `tadd1` is built —
   min/max come essentially free alongside the adder. **[DIRECT] (`ValuationEnergy.lean`).**
8. **Trit-shift ÷3 = the RG flow (`d >> 1` analog).** One trit-shift moves 3× in scale vs 2×,
   so `log₃` vs `log₂` shift-count to span the same ring range (`0.63×` the shifts). **[DIRECT]
   for `log₃ < log₂`; the rebuild's `d>>1`=ring×2 is OURS, the ternary ÷3 is ANALOGY.**
9. **Tritwise `abs`.** 1 op vs binary's 3–4-op branchless sequence. **[DIRECT] definition.**
10. **Exact sixth-root twiddles (Z₆ / radix-3 transforms).** The units are the exact sixth
    roots of unity, so a 6-point transform needs no irrational twiddle factors — the same
    "trig → integer" win as the barrel shift, applied to the FFT. **[OURS/SPECULATION] — the
    exactness is DIRECT, the "cheaper transform" claim is untested.**

---

## 4. Honest negatives — what did *not* map (calibrate before quoting)

1. **Booth encoding already steals ternary's famous win.** Signed-digit recoding `{−1,0,+1}`
   is exactly what Booth encoding does to *binary* multiplication to cut partial products.
   So there is **no multiplication-partial-product density win left for ternary** — the win in
   ternary multiply is *symmetry*, not sparsity. **[DIRECT/ANALOGY — flagged in
   `TERNARY_PROCESSOR.md` §1.]**
2. **"wedge = bivector area" is RETIRED.** The wedge in this project is the *skew part*
   `O_ab − O_ba` (orientation / temporal precedence), **not** a geometric-algebra bivector
   *area*, and not a causal arrow. The task's phrase "the wedge bivector" is kept only as the
   *signed* analog of XOR — do not carry the area/causality reading. **[RETIRED — `docs/PAPER.md`
   and AGENTS.md canonical-truth section.]**
3. **Density ≠ per-op energy win.** `1.585` is bits-per-wire, a *bandwidth/namespace* number;
   per-gate energy still pays the 2-threshold receiver tax (Law 1). The break-even is the
   survey's open question, **not** settled by this catalog. **[OURS/SPECULATION.]**
4. **Hex addressing does not yet replace the u32 XOR kernel.** The hex↔u32 bijection is
   proved (`Bijection.lean`, Szudzik pairing), but "hex addressing *replaces* the u32 XOR
   kernel" remains **SPECULATION** — the replacement is what the bijection *enables testing*,
   not what it *establishes*. **[SPECULATION — `proofs/INDEX.md` rows B1 / "hex ↔ u32".]**

---

## 5. Numbers ledger (all DIRECT, for citation)

- `log₂ 3 = 1.5849625…` — bits per trit.
- `3/ln 3 = 2.731` vs `2/ln 2 = 2.885` vs `e = 2.718` — radix economy (minimized at `e`).
- `3⁶ = 729` (9.51 bits) · `3¹² = 531 441`, half-range `±265 720` (19.02 bits) · `3¹⁸ ≈ 3.87×10⁸`
  (28.53 bits, the Setun word) · `3⁴⁰ ≈ 1.216×10¹⁹` (63.40 bits, between 2⁶³ and 2⁶⁴).
- Hex packing density `π/(2√3) = 0.9069` (`τ/(4√3)` in the project's τ convention); hex
  covering radius `1/√3 ≈ 0.577 < 1` (why ℤ[ω] is a Euclidean domain); centered hexagonal
  numbers `3r²+3r+1 = 1, 7, 19, 37, 61, …`.
- Ternary cell energy: average `2/3` energized line vs binary `1`; null is `0` (proved
  `TernaryCell.lean`); comm floor `0.081 pJ/bit` (measured, `docs/ENERGY_LAWS.md`).

### Sources

- In-tree proofs: `proofs/lean-src/hexagon/Hexagon/{RadixEconomy,Rotation,HexIsotropy,Pod,
  Bijection,TernaryCell,ValuationEnergy}.lean` + `proofs/INDEX.md` (all `lake build` green).
- In-tree code: `rust-mirror/src/{ternary,eisenstein,bijection}.rs`, `rtl/trit_functions.vh`.
- Design context: `docs/TERNARY_COMPUTE_SURVEY.md`, `docs/ENERGY_LAWS.md`, `TERNARY_PROCESSOR.md`.
- External (standard): B. Hayes, *Third Base*, American Scientist 89(6):490–494 (2001) — the
  radix-economy / "ternary is nearest e" argument; Knuth, *TAOCP* vol. 2, balanced-ternary
  notation; the Setun computer (Brusentsov, 1958), 18-trit word ≈ 28.5 bits; D. W. Jones,
  "Standard Ternary Logic" (min/max/neg gate family); Uber H3 (aperture-7 hex hierarchy, the
  DGGS form of fractal-hex addressing).
