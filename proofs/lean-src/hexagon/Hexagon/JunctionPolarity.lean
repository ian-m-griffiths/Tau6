/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.TernaryCell
import Hexagon.Conventions

/-!
# Junction polarity — the one-hot channel model of a balanced trit

**Idea history:** Ian (2026): a P-channel and an N-channel share a middle node; each conducts
only under its own polarity, so current flows one direction or the other or not at all.
Negation = swap which channel you drive = FREE (a wire relabel / field-polarity flip, no
energy). The ternary cell (`TernaryCell.lean`) already records the 2-bit one-hot-per-direction
encoding onto two wires; this file factors out the *channel* (push/pull) and models the trit as
the one-hot sum `Option Channel` (`none` = null, `some .push`/`some .pull` = exactly one channel
energized), so "at most one channel active" holds **by construction**, and the `(1,1)` state is
unrepresentable rather than merely excluded.

**Calibration:** DIRECT — finite combinatorics; the channel sum below is balanced addition
`Z/3` on the trit set `{push=+1, null=0, pull=−1}`.

**Status:** PROVED (2026-08-29) — `lake env lean Hexagon/JunctionPolarity.lean` green,
zero `sorry`. See the summary comment at the foot of the file.
-/

namespace Hexagon
namespace JunctionPolarity

/-- An anti-polar channel: `push` sources current, `pull` sinks it — the two rails of a
junction's middle node. Each conducts only under its own polarity. -/
inductive Channel where
  | push
  | pull
  deriving DecidableEq, Repr

-- `deriving Fintype` is broken in this toolchain for a bare inductive (see `TernaryCell.lean`),
-- so `Channel` gets an explicit instance:
instance : Fintype Channel :=
  ⟨({.push, .pull} : Finset Channel), by intro x; cases x <;> simp⟩

instance : Inhabited Channel := ⟨.push⟩

namespace Channel

/-- Negation of a channel: push ↔ pull. -/
def neg (c : Channel) : Channel :=
  match c with
  | .push => .pull
  | .pull => .push

/-- Channel negation is an involution. -/
theorem neg_neg (c : Channel) : neg (neg c) = c := by
  cases c <;> rfl

end Channel

/-- A trit as the one-hot sum `Unit ⊕ Channel`: `none` = null (no channel), `some .push` =
push active, `some .pull` = pull active. At most one channel is on *by construction*. -/
abbrev Trit := Option Channel

namespace Trit

/-- The null trit: neither channel energized. -/
def null : Trit := none

/-- The push trit: the push channel energized. -/
def push : Trit := some Channel.push

/-- The pull trit: the pull channel energized. -/
def pull : Trit := some Channel.pull

/-- Negation: swap push ↔ pull (flip which rail is driven); null is fixed. -/
def neg (t : Trit) : Trit :=
  match t with
  | none => none
  | some c => some (Channel.neg c)

/-- Negation is an involution. -/
theorem neg_neg (t : Trit) : neg (neg t) = t := by
  cases t with
  | none => rfl
  | some c => cases c <;> rfl

/-- Negation fixes null. -/
theorem neg_null : neg null = null := rfl

/-- The 2-wire physical encoding: push → `(true,false)` = 01, pull → `(false,true)` = 10,
null → `(false,false)` = 00. The `(true,true)` = 11 state is NEVER produced. -/
def encode (t : Trit) : Bool × Bool :=
  match t with
  | none => (false, false)
  | some .push => (true, false)
  | some .pull => (false, true)

/-- Activation energy = number of energized wires. -/
def energy (t : Trit) : ℕ :=
  (if (encode t).1 then 1 else 0) + (if (encode t).2 then 1 else 0)

/-! ## 1. The single-activation invariant -/

/-- SINGLE-ACTIVATION: no trit ever drives both channels — the `11 = NEVER` exclusion. -/
theorem encode_never_both (t : Trit) : encode t ≠ (true, true) := by
  cases t with
  | none => decide
  | some c => cases c <;> decide

/-- Null is "both wires off": `encode null = 00`. -/
theorem encode_null : encode null = (false, false) := rfl

/-- The converse: the ONLY trit with both wires off is null — so "null = both off", exactly. -/
theorem null_iff_off (t : Trit) : encode t = (false, false) ↔ t = null := by
  constructor
  · intro h
    cases t with
    | none => rfl
    | some c => cases c <;> simp [encode] at h
  · intro h
    subst h
    rfl

/-- Energy of the null state is zero (null is free). -/
theorem energy_null : energy null = 0 := by decide

/-- Energy of each single-active state is one. -/
theorem energy_push : energy push = 1 := by decide

/-- Energy of each single-active state is one. -/
theorem energy_pull : energy pull = 1 := by decide

/-- SINGLE-ACTIVATION (energy form): at most one wire is ever on. -/
theorem energy_le_one (t : Trit) : energy t ≤ 1 := by
  cases t with
  | none => decide
  | some c => cases c <;> decide

/-- A trit costs zero energy exactly when it is null; it costs 1 exactly when active. -/
theorem energy_eq_zero_iff_null (t : Trit) : energy t = 0 ↔ t = null := by
  constructor
  · intro h
    cases t with
    | none => rfl
    | some c => cases c <;> simp [energy, encode] at h
  · intro h
    subst h
    decide

/-! ## 2. The bijection to the balanced trit {−1, 0, +1} -/

/-- The balanced reading: push = +1, null = 0, pull = −1. -/
def toBalanced (t : Trit) : Hexagon.Trit :=
  match t with
  | none => Hexagon.Trit.zero
  | some .push => Hexagon.Trit.pos
  | some .pull => Hexagon.Trit.neg

/-- The inverse: recover the channel from the balanced trit. -/
def ofBalanced (b : Hexagon.Trit) : Trit :=
  match b with
  | Hexagon.Trit.zero => none
  | Hexagon.Trit.pos => some Channel.push
  | Hexagon.Trit.neg => some Channel.pull

/-- The channel model is equivalent to the balanced trit `{−1, 0, +1}`. -/
def balancedEquiv : Trit ≃ Hexagon.Trit where
  toFun := toBalanced
  invFun := ofBalanced
  left_inv := by
    intro t
    cases t with
    | none => rfl
    | some c => cases c <;> rfl
  right_inv := by
    intro b
    cases b <;> rfl

/-- Round-trip, one way: `ofBalanced (toBalanced t) = t`. -/
theorem ofBalanced_toBalanced (t : Trit) : ofBalanced (toBalanced t) = t :=
  balancedEquiv.left_inv t

/-- Round-trip, the other way: `toBalanced (ofBalanced b) = b`. -/
theorem toBalanced_ofBalanced (b : Hexagon.Trit) : toBalanced (ofBalanced b) = b :=
  balancedEquiv.right_inv b

/-- The channel→balanced map is injective. -/
theorem toBalanced_injective : Function.Injective toBalanced := balancedEquiv.injective

/-- ... and surjective: it is a genuine bijection. -/
theorem toBalanced_surjective : Function.Surjective toBalanced := balancedEquiv.surjective

/-- The balanced integer value: push = +1, null = 0, pull = −1. -/
def toInt (t : Trit) : ℤ :=
  match t with
  | none => 0
  | some .push => 1
  | some .pull => -1

/-- Negation is exactly the balanced sign-flip on the integer value. -/
theorem neg_toInt (t : Trit) : toInt (neg t) = -toInt t := by
  cases t with
  | none => rfl
  | some c => cases c <;> decide

/-- The balanced trit embedded on the real axis of the Eisenstein ring ℤ[ω]: `⟨+1,0⟩`,
`⟨0,0⟩`, `⟨−1,0⟩` — the balanced value carried inside the hex lattice. -/
def toEisenstein (t : Trit) : Eisenstein := ⟨toInt t, 0⟩

/-- Negation is exactly Eisenstein negation on the balanced axis. -/
theorem neg_toEisenstein (t : Trit) : toEisenstein (neg t) = -toEisenstein t := by
  cases t with
  | none => decide
  | some c => cases c <;> decide

/-! ## 3. Negation is free -/

/-- Negation swaps the two wires — it is a pure relabeling of which rail is driven. -/
theorem neg_encodes_swap (t : Trit) : encode (neg t) = (encode t).swap := by
  cases t with
  | none => rfl
  | some c => cases c <;> rfl

/-- FREE: negation changes no activation energy (it only relabels the driven rail). -/
theorem neg_energy (t : Trit) : energy (neg t) = energy t := by
  cases t with
  | none => decide
  | some c => cases c <;> decide

/-! ## 4. Null is the additive identity of the one-hot channel algebra -/

/-- The one-hot channel sum: balanced addition `Z/3` on `{push=+1, null=0, pull=−1}`.
`push ∘ push = pull` (carry), `push ∘ pull = null` (cancellation), `null ∘ x = x`. -/
def sum (a b : Trit) : Trit :=
  match a, b with
  | none, b => b
  | a, none => a
  | some .push, some .push => some .pull
  | some .push, some .pull => none
  | some .pull, some .push => none
  | some .pull, some .pull => some .push

/-- Null is the left additive identity: `null ∘ x = x`. -/
theorem sum_null (t : Trit) : sum null t = t := rfl

/-- Null is the right additive identity: `x ∘ null = x`. -/
theorem sum_null_right (t : Trit) : sum t null = t := by
  cases t with
  | none => rfl
  | some c => cases c <;> rfl

/-- NONTRIVIAL: opposite polarities annihilate to null — `push ∘ pull = null`. -/
theorem sum_push_pull : sum push pull = null := rfl

/-- NONTRIVIAL: the balanced carry — `push ∘ push = pull` (+1 + +1 = −1 mod 3). -/
theorem sum_push_push : sum push push = pull := rfl

/-- NONTRIVIAL: the dual carry — `pull ∘ pull = push` (−1 + −1 = +1 mod 3). -/
theorem sum_pull_pull : sum pull pull = push := rfl

/-- The channel sum is commutative. -/
theorem sum_comm (a b : Trit) : sum a b = sum b a := by
  cases a with
  | none => cases b with
    | none => rfl
    | some cb => rfl
  | some ca => cases ca with
    | push => cases b with
      | none => rfl
      | some cb => cases cb <;> rfl
    | pull => cases b with
      | none => rfl
      | some cb => cases cb <;> rfl

/-- The channel sum is associative (the one-hot algebra is the group Z/3). -/
theorem sum_assoc (a b c : Trit) : sum (sum a b) c = sum a (sum b c) := by
  cases a with
  | none => rfl
  | some ca => cases ca with
    | push => cases b with
      | none => rfl
      | some cb => cases cb with
        | push => cases c with
          | none => rfl
          | some cc => cases cc <;> rfl
        | pull => cases c with
          | none => rfl
          | some cc => cases cc <;> rfl
    | pull => cases b with
      | none => rfl
      | some cb => cases cb with
        | push => cases c with
          | none => rfl
          | some cc => cases cc <;> rfl
        | pull => cases c with
          | none => rfl
          | some cc => cases cc <;> rfl

/-- Every trit has an additive inverse under `sum` — the negation above. -/
theorem sum_neg (t : Trit) : sum (neg t) t = null := by
  cases t with
  | none => rfl
  | some c => cases c <;> rfl

end Trit

end JunctionPolarity
end Hexagon

/-!
## Summary of what this module establishes

1. **Channel model.** `Channel` (push/pull) and `Trit := Option Channel` — the one-hot sum
   `{push, pull, none}` where at most one channel is active *by construction*.
2. **Single-activation.** `encode_never_both` (the `11 = NEVER` exclusion),
   `encode_null`/`null_iff_off` (null = both wires off, exactly), `energy_le_one` (at most one
   wire on), `energy_eq_zero_iff_null` (zero cost iff null).
3. **Bijection.** `balancedEquiv : Trit ≃ Hexagon.Trit` with both round-trips
   `ofBalanced_toBalanced`/`toBalanced_ofBalanced` and `toBalanced_injective`/`_surjective`.
4. **Negation is free.** `neg_neg` (involution), `neg_encodes_swap` (a pure wire relabel),
   `neg_energy` (activation energy unchanged), `neg_toInt`/`neg_toEisenstein` (the balanced
   sign-flip / Eisenstein negation).
5. **Null as additive identity.** `sum_null`/`sum_null_right`, plus the nontrivial identities
   `sum_push_pull` (opposites annihilate to null), `sum_push_push`/`sum_pull_pull` (balanced
   carry), `sum_comm`, `sum_assoc`, `sum_neg` (the channel algebra is the group Z/3).

**One-line significance:** a balanced trit costs only the *presence* of one energized channel —
never two — and its sign is a free rail swap, so "ternary is cheap because you only activate
one channel" is exactly the single-activation invariant `energy_le_one` plus the free negation
`neg_energy`.
-/
