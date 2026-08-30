/-
Copyright (c) 2026 Ian Griffiths. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Griffiths
-/
import Hexagon.Conventions
import Hexagon.SevenHex
import Hexagon.Rotation
import Hexagon.Packing
import Hexagon.Euclidean
import Hexagon.GraphDistance
import Hexagon.EuclideanDomain
import Hexagon.Gauge
import Hexagon.Residual
import Hexagon.Bijection
import Hexagon.Registers
import Hexagon.ConventionBridge
import Hexagon.OmegaEmbedding
import Hexagon.FractalRam
import Hexagon.TernaryCell
import Hexagon.Haar
import Hexagon.ChiSquareGauge
import Hexagon.ValuationEnergy
import Hexagon.ZipfEnergy
import Hexagon.RadixEconomy
import Hexagon.RadixMin
import Hexagon.ThresholdLowerBound
import Hexagon.Signature
import Hexagon.EnergyModel
import Hexagon.WeightHex
import Hexagon.EnergyVerdict
import Hexagon.Pod
import Hexagon.HexIsotropy
import Hexagon.HexDisk
import Hexagon.OffsetGrid
import Hexagon.CrtHex
import Hexagon.PolarEncoding
import Hexagon.PolarGate
import Hexagon.TritPacking
import Hexagon.FewerTrits
import Hexagon.Conjugate
import Hexagon.DotWedge
import Hexagon.SymDot
import Hexagon.TernaryCrt
import Hexagon.CausalLattice
import Hexagon.AddressTranslation
import Hexagon.FieldCalculus
import Hexagon.JunctionPolarity
import Hexagon.JunctionEnergy
import Hexagon.JunctionMemory
import Hexagon.PolarTransport

/-!
# Hexagon lattice — umbrella module

The Eisenstein ℤ[ω] formalization (plan §3–§5): ring + norm (T0/T1), the 7-hex ↔
balanced-ternary bijection (T2), the Z₆ rotation group + cube distance (T3/T4).

**Idea history:** Ian (2026) "einstein triangles of 60 degrees" + the diamond motif
(`a→b, a→c, b&c→f`, "Diamonds All the Way Down", info-geometry docs 2026-08-05);
hexigon_conversation.md L10005–10105, L10179–10197, L11248, L11397–11399;
ox alpha.md TODO #16 (L3109); SYNTHESIS Q1/Q3/Q4; plan §2 guardrails.
-/
