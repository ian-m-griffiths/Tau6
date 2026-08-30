/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions
import Hexagon.SevenHex
import Hexagon.Rotation

/-!
# Hexagon lattice — umbrella module

The Eisenstein ℤ[ω] formalization (plan §3–§5): ring + norm (T0/T1), the 7-hex ↔
balanced-ternary bijection (T2), the Z₆ rotation group + cube distance (T3/T4).

**Idea history:** Ian (2026) "einstein triangles of 60 degrees" + the diamond motif
(`a→b, a→c, b&c→f`, "Diamonds All the Way Down", info-geometry docs 2026-08-05);
hexigon_conversation.md L10005–10105, L10179–10197, L11248, L11397–11399;
ox alpha.md TODO #16 (L3109); SYNTHESIS Q1/Q3/Q4; plan §2 guardrails.
-/
