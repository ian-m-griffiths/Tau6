# Final Verdict — the consolidated truth

**2026-08-29.** One page. Folds the entire meta-critic + measurement pass (second pass,
`fair_binary`, `lowswing_diode`, `tsum_cell`, the four `meta_*` audits, the Lean audit, the
AAT deep-dive) into a single "here's what actually survives" document. Every number is
measured (ngspice 44.2) or proved (Lean, `lake build` green, zero `sorry`); every claim is
calibrated **DIRECT** (measured/proved) / **ANALOGY** / **OURS** / **SPECULATION** and cites
its source. Nothing here is new work; this file invents no numbers.

---

## The three axes

| axis | ternary vs binary | the honest number | proof / source | calibration |
|---|---|---|---|---|
| **namespace** | `3ⁿ` (and `7ⁿ` hex) vs `2ⁿ` | `(3/2)ⁿ` → **1.86×10¹¹ at n=64**; `log₃2 = 0.6309` → **36.9% fewer symbols** | `TritPacking.lean` (`2ⁿ < 3ⁿ`); `RadixEconomy.lean` (`3/ln3 < 2/ln2`); `FractalRam.lean` (7ⁿ) — `NAMESPACE_TABLE.md` | **DIRECT** (proved) — the *exponential* win |
| **transport** | ~2.7–6.3× win | champion 0.081 pJ/bit = **6.3× vs natural single-ended binary (0.512)**; **2.67× vs matched low-swing binary (0.216)** | `fair_binary.md` §3, §5 (ngspice) | **DIRECT** (measured). Radix-agnostic: the low-swing lever is shared with binary; the free null (~0.05 pJ) is real but *conditional on null-heavy data* (`meta_assumptions.md` A3) |
| **compute** | ~1.5–3.5×/bit loss | **1.26× floor** (`2/log₂3 = 2·ln2/ln3`, representation-independent); honest native floor **~1.5–2×**; measured diode gate **3.4–4.9×** (cheapest toggle) → **~3.5×** (matched low swing) | `meta_math.md` §2; `radix_lower_bound.md`; `fair_binary.md` §4; `lowswing_diode.md` §6; `tsum_cell.md` | **DIRECT** (measured + proved). *Bounded*: the 4.9–14.3× catastrophe was a receiver artifact; the 0.63× "win" was unphysical |

**Read the table as one sentence:** ternary buys *names* exponentially (proved), moves *bits on a wire* cheaper by a small real factor (measured, radix-agnostic), and *computes* more expensively by a bounded factor that no native device — including the AAT — removes (measured + proved).

---

## The one clean truth — names, not bits

The memory engine's win is **addressing, not arithmetic**. It buys **NAMES exponentially**:
`3ⁿ` names where binary fits `2ⁿ`. Per name (per addressable symbol), the net win is

```
(3/2)ⁿ / ~1.4×
```

where `~1.4×` is the measured per-symbol cost overhead of a ternary name over a binary one
(storage `≥1.05–1.47×`, `storage.md`; the mod-3 sum `⊕` at **1.42×/bit**, `tsum_cell.md`).
The exponential swamps the linear tax: at n=64, `(3/2)⁶⁴ = 1.86×10¹¹`, and `÷1.4` still leaves
~10¹¹. **The `3ⁿ` namespace is the engine's win; the per-bit energy story was always a
distraction.** (`NAMESPACE_TABLE.md`, `control.md` §3c, `meta_assumptions.md` A14.)

---

## The five corrections the meta-critics forced

1. **The wrong receiver (sense-amp vs diode).** The "compute loses" verdict compared a
   *diode-direction* wire against a *sense-amp level* gate — two different objects. The diode
   receiver kills the null shoot-through (~0 idle) and the clocked-receiver tax — but it does
   **not** flip the verdict: direction is still 2 decisions, and it adds a diode drop plus a
   resistive null-return termination (the 7.8× measured factor). `meta_mishandled.md`;
   `lowswing_diode.md` §4.

2. **The flattered binary baseline (0.748 → 0.512/0.216).** The transport reference was
   0.748 pJ/bit on a 1.5 pF load; the honest same-wire single-ended binary is **0.512** (full
   swing) / **0.216** (low swing). The "±1 V bipolar, halve every win" claim was **half-wrong**:
   transport was already single-ended; only the *gates* ran ±1 V (there the correction is
   **~7×**, not ~2×). `fair_binary.md` §1–§3; `audit_measurement.md` §3.

3. **The "three laws" were one priced model + one heuristic + one conflation.** Law 1
   (receiver gauge-agnostic) is a *measured heuristic* (13%→61%→67%); Law 2 (I²R) is a
   *measured heuristic*; Law 3 ("3 wins because nearest e") *conflates* a density fact with the
   free-null circuit fact. **None is a Lean theorem** — "proved in Lean" was laundering.
   `audit_proof.md` §2.4; `meta_assumptions.md` §7.2/A14.

4. **The 0.63× native floor was unphysical (~1.5–2× honest).** `0.63× = 1/log₂3` assumes a
   ternary toggle costs the *same* as a binary one; the 3-level SNR margin forces ~2×, so the
   honest floor is **~1.5–2×/bit**, not 0.63×. `radix_lower_bound.md` §3; `lowswing_diode.md` §6.

5. **The two escape hatches were red herrings.** Sign+magnitude still needs `⌈log₂3⌉ = 2`
   decisions (the 1.26× is *representation-independent* — `meta_math.md` §2). The AAT
   "complex transistor" *exists* and resolves 3 states in one measurement — but its middle
   state is a static-current divider and it costs **≫1.585×** a binary op, not ~1×
   (`native_device_aat.md` §0, §3).

---

## What we'd build

**Ternary transport + binary compute + cheap edge.** Keep the wire win (it's real and
measured, ~2.7–6.3×) and the free null on the link; keep the compute on binary standard cells
(the 2-bit encoding is the correct *binary-substrate* representation); win the memory engine on
the **`3ⁿ` namespace**, where the exponential is. The one hard wall — the mod-3 sum `⊕` — stays
open and decides whether compute ever goes native. This is `TERNARY_COMPUTE_VERDICT.md` Path B,
and it is already real.

---

## Open questions

- **The `⊕` cell.** The one irreducible primitive (everything else is Kleene-derivable). Measured
  **1.42–2.33×/bit** and 88 devices — a *bounded* wall, not the 4.9–14.3× catastrophe, but the
  null rail `NOT(push OR pull)` is a third decision the direction receiver cannot emit. The
  signed-current (KCL-free) form is the unmeasured escape. `tsum_cell.md`; `TERNARY_COMPUTE_VERDICT.md`.
- **The symmetric dot** (`TDOT`, `a·b = Re(a·b̄) = cos θ`). The scalar/symmetric half of the
  geometric product — the "cosine / topic-alignment" axis, separated from the skew wedge. Cheap
  and Lean-provable now; unbuilt. `GA_INSTRUCTIONS.md` §Tier 1.
- **The field-calculus `∇F = J` thread** (`TGRAD`). The geometric derivative as one invertible
  equation, where div and curl are separately non-invertible — "residual = ∇F, recovery = the
  directed integral." The long pole; formalizes the residual as a *field*, not a table.
  `GA_INSTRUCTIONS.md` §Tier 3.
