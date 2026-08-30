# Namespace table — ternary vs binary symbol count

**2026-08-29.** The addressing win, tabled. Calibration: arithmetic (DIRECT) + the Lean proofs
in `proofs/lean-src/hexagon/Hexagon/` (`RadixEconomy.lean`, `TritPacking.lean`).

## Symbols needed to encode 2ᵏ states

| bits (k) | states (2ᵏ) | trits ⌈k·log₃2⌉ | trits/bits | symbol savings |
|---|---:|---:|---:|---:|
| 8 | 2.56×10² | 6 | 0.750 | 25.0% |
| 16 | 6.55×10⁴ | 11 | 0.688 | 31.2% |
| 24 | 1.68×10⁷ | 16 | 0.667 | 33.3% |
| 32 | 4.29×10⁹ | 21 | 0.656 | 34.4% |
| 40 | 1.10×10¹² | 26 | 0.650 | 35.0% |
| 48 | 2.81×10¹⁴ | 31 | 0.646 | 35.4% |
| 56 | 7.21×10¹⁶ | 36 | 0.643 | 35.7% |
| 64 | 1.84×10¹⁹ | 41 | 0.641 | 35.9% |
| 72 | 4.72×10²¹ | 46 | 0.639 | 36.1% |
| 80 | 1.21×10²⁴ | 51 | 0.638 | 36.3% |
| 88 | 3.09×10²⁶ | 56 | 0.636 | 36.4% |
| 96 | 7.92×10²⁸ | 61 | 0.635 | 36.5% |
| 104 | 2.03×10³¹ | 66 | 0.635 | 36.5% |
| 112 | 5.19×10³³ | 71 | 0.634 | 36.6% |
| 120 | 1.33×10³⁶ | 76 | 0.633 | 36.7% |
| 128 | 3.40×10³⁸ | 81 | 0.633 | 36.7% |

- **Asymptotic trits/bits** = `log₃2 = ln2/ln3 = 0.6309` → **36.9% fewer symbols**.
- **Namespace explosion** (n symbols fixed): `3ⁿ/2ⁿ = (3/2)ⁿ` → `1.86×10¹¹` at n = 64.
- **Headroom** (3^trits vs 2ᵏ at the rounded width) shrinks to ~1.30× at 128 bits — the
  rounding waste vanishes, leaving the clean 37% symbol saving.

## The three axes (reconciliation)

| axis | ternary vs binary | proof |
|---|---|---|
| namespace (n symbols fixed) | `(3/2)ⁿ` — exponential win | `TritPacking.lean` (`2ⁿ < 3ⁿ`) |
| radix economy (N states fixed) | `log₃N / log₂N = 0.631` — 37% fewer symbols | `RadixEconomy.lean` (`3/ln3 < 2/ln2`) |
| energy per bit (throughput) | ~1.26× worse on 2-level silicon | `ThresholdLowerBound.lean` + measured |

The first two are the **addressing** wins — the memory engine's axis. The third is the
**throughput** cost, a different question, and it never touches the symbol/namespace win.
