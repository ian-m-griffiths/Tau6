# Physical-layer notes — receiver device choice (2026-08-28)

From Ian + a translated electronics note. Governs the "2-diode receiver" → real silicon.

## The rule: parallel MOSFETs, not parallel diodes

- **Parallel MOSFETs → `R_on / N`.** N matched devices give N parallel current paths; total
  on-resistance divides by N. MOSFET `R_on` has a *positive* temperature coefficient
  (hotter → more resistive), so the hotter device self-throttles — clean, no runaway.
  Engineering requirements: matched batch, per-gate series resistor (kill gate oscillation),
  symmetric layout for even current sharing.
- **Parallel diodes → thermal runaway.** PN-junction diodes have a *negative* temperature
  coefficient (hotter → lower `V_f` → hogs more current → hotter). The lower-`V_f` device
  steals current, overheats, and can cascade-fail. Ballast resistors mitigate but re-add loss.

## Consequence for the ternary cell

The receiver's forward/pull legs should be **MOSFET rectifiers** (diode-connected MOSFET, or a
synchronous rectifier), optionally **paralleled for low `R_on`**, NOT junction diodes. This
attacks both measured losses: the ~26% diode-`V_f` term (replaceable drop, self-balancing) and
the ~60% resistive term (parallel → `R/N`).

## Honest nuance

Our two legs are **antiparallel** (one forward, one reverse, sensing the two polarities), not
*parallel* — so the runaway-between-legs picture doesn't apply literally. But the forward leg
still benefits from the MOSFET swap for the same reason (lower, controllable drop, positive
temp coefficient). The `8f46b75b` experiment tests the transistor-as-diode version against the
5.36 pJ ideal-diode baseline.
