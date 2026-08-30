// ============================================================================
// hex_pod_addr.v — the hex MMU's isotropic pod lookup (Phase 4, final primitive).
//
// Ian's "ram lookup should be isotropic ... up down up-left up-right down-left
// down-right" (HexIsotropy.lean: free Z6 action, 6 unit neighbors).  Given ONE flat
// u32 physical address (the pod center), return the 7-cell pod's addresses — the
// center plus its 6 Z6 unit neighbors, in angle order (w^0..w^5).
//
//   pod[0] = center            (address of cell (a,b))
//   pod[1..6] = the 6 neighbors (address of (a,b)+w^(k-1))
//
// This is the "cell cache" hop of hex_mmu.md §2: decode once, add the 6 offsets
// (two adds each), re-encode — the only arithmetic on the whole path is the single
// isqrt in the decode and the 6 pair* fold re-encodes.
//
// Reuses rtl/hex_decode.v + rtl/hex_encode.v (both already round-trip verified over
// the full WORD6 range).  Verilog-2001; synthesizable.
// ============================================================================

`timescale 1ns/1ps

module hex_pod_addr (
  output wire [223:0] pod,       // 7 flat addresses packed: pod[k] = bits [32k+31 : 32k]
  input  wire [31:0] center
);
  // decode the center once -> cell (a,b)
  wire signed [15:0] a, b;
  hex_decode u_dec (.a(a), .b(b), .addr(center));

  assign pod[31:0] = center;

  genvar k;
  generate
    for (k = 0; k < 6; k = k + 1) begin : gen_nbr
      wire signed [15:0] na, nb;
      wire [31:0] naddr;
      hex_neighbor u_n (.na(na), .nb(nb), .naddr(naddr), .a(a), .b(b), .k(k[2:0]));
      assign pod[(k + 1) * 32 +: 32] = naddr;
    end
  endgenerate
endmodule
