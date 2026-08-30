// ============================================================================
// hex_field_accel.v — the field-calculus accelerator (TGRAD / TRECON / TRELAX)
// as a memory-mapped peripheral: the engine's "grad F = J" + its two inverses in
// the full processor.
//
// The core writes a scalar field into the CELL STORE (a 64-cell RAM), writes the pod
// CENTER address, and reads back the geometric derivative (div, curl) — all in
// hardware: hex_pod_addr (isotropic lookup) -> cell store (gather) -> tgrad_cell
// (div/curl).  On top of TGRAD sit the two field ops the engine actually iterates:
//
//   TRECON  = the canonical gauge-fixed ∇⁻¹ section: given (div, curl) it places
//             div on the ω⁰ neighbor, curl on the ω¹ neighbor, and zeroes the rest
//             (F2=F3=F4=F5=0, center=0).  ∇(TRECON J) = J identically; the round
//             trip TRECON(TGRAD F) = F holds when F is already in canonical gauge.
//   TRELAX  = one heat-equation relaxation step: u' = u/3 + (Σ 6 neighbors)/9
//             (the α=2/3 folded Laplacian form; the 1/3, 1/9 are free ternary
//             right-shifts, so the whole update is ONE balanced add).
//
//   BASE+0x00 .. BASE+0xFC   cell store (write/read a field value, 24-bit ternary)
//   BASE+0x100               write: pod center address (cell index)
//   BASE+0x104               read : div   (8 trits, balanced ternary)
//   BASE+0x108               read : curl  (8 trits)
//   BASE+0x10C               read : TRECON overflow flag (1 iff div/curl ∉ 6 trits)
//   BASE+0x110               read : TRELAX u'  (relaxed center, 6 trits)
//   BASE+0x114               write: TRECON — store the reconstruction into the pod cells
//   BASE+0x118               write: TRELAX — step the center cell in place (u <- u')
//
// WORD / ENCODING.  Field values are 12 trits = 24 bits, balanced ternary
// (2 bits/trit, 01=+1, 00=0, 10=-1, 11=NEVER).  Software encodes/decode: enc(3)=0x004,
// enc(9)=0x010.  The cell ADDRESS (center, pod) is a plain binary cell index, NOT
// ternary — addressing is the 3ⁿ namespace, values are the ternary field.
//
// Verilog-2001; synthesizable; depends on hex_pod_addr.v (+ encode/decode),
// grad_recon.v (tgrad_cell + trecon_cell) and trelax.v.
// ============================================================================

`timescale 1ns/1ps

module hex_field_accel #(
  parameter [31:0] BASE = 32'h0000_2000
) (
  input  wire        clk,
  input  wire        resetn,
  input  wire        mem_valid,
  input  wire [31:0] mem_addr,
  input  wire [31:0] mem_wdata,
  input  wire [3:0]  mem_wstrb,
  output reg  [31:0] mem_rdata,
  output reg         mem_ready
);
  reg [23:0] cells [0:63];
  reg [31:0] center;
  integer i;

  // ---- the isotropic pod lookup + gather + TGRAD -----------------------------
  wire [223:0] pod;
  hex_pod_addr u_pod (.pod(pod), .center(center));

  wire [11:0] F0 = cells[pod[ 63:32]][11:0];   // w^0 neighbor
  wire [11:0] F1 = cells[pod[ 95:64]][11:0];   // w^1
  wire [11:0] F2 = cells[pod[127:96]][11:0];   // w^2
  wire [11:0] F3 = cells[pod[159:128]][11:0];  // w^3
  wire [11:0] F4 = cells[pod[191:160]][11:0];  // w^4
  wire [11:0] F5 = cells[pod[223:192]][11:0];  // w^5
  wire [11:0] cc = cells[pod[ 31: 0]][11:0];   // center

  wire [15:0] div, curl;
  tgrad_cell #(.NTRITS(6)) u_tgrad (
    .div(div), .curl(curl),
    .c(cc),
    .nb({F5, F4, F3, F2, F1, F0}));

  // ---- TRECON: gauge-fixed ∇⁻¹ of the current (div, curl) --------------------
  wire [71:0] nb_rec;    // 6 recovered neighbors F0'..F5' (12 bits each)
  wire [11:0] c_rec;     // recovered center (canonical gauge: 0)
  wire        ofit;      // 1 iff div or curl doesn't fit 6 trits
  trecon_cell #(.NTRITS(6)) u_trecon (
    .nb_rec(nb_rec), .c_rec(c_rec), .ofit(ofit),
    .div(div), .curl(curl));

  // ---- TRELAX: one heat step on the center cell ------------------------------
  wire [11:0] u_new;
  trelax_cell #(.NTRITS(6)) u_trelax (
    .u_new(u_new),
    .u(cc),
    .nb({F5, F4, F3, F2, F1, F0}));

  // ---- memory-mapped interface ----------------------------------------------
  wire        hit     = mem_valid && (mem_addr >= BASE) && (mem_addr < BASE + 32'h11C);
  wire [31:0] off     = mem_addr - BASE;
  wire        is_cell = off < 32'h100;
  wire [7:0]  cidx    = off[7:0];

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      for (i = 0; i < 64; i = i + 1) cells[i] <= 24'b0;
      center    <= 32'd0;
      mem_ready <= 1'b0;
      mem_rdata <= 32'd0;
    end else begin
      mem_ready <= hit;
      if (hit && (mem_wstrb != 4'd0)) begin
        if (is_cell)                     cells[cidx >> 2] <= mem_wdata[23:0];  // write a field value
        else case (cidx)
          8'h00: center <= mem_wdata;                       // write center (0x100)
          8'h14: begin                                     // TRECON store (0x114)
            cells[pod[ 31: 0]] <= c_rec;                    // center' = 0
            cells[pod[ 63:32]] <= nb_rec[11:0];             // F0' = div
            cells[pod[ 95:64]] <= nb_rec[23:12];            // F1' = curl
            cells[pod[127:96]] <= nb_rec[35:24];            // F2' = 0
            cells[pod[159:128]] <= nb_rec[47:36];           // F3' = 0
            cells[pod[191:160]] <= nb_rec[59:48];           // F4' = 0
            cells[pod[223:192]] <= nb_rec[71:60];           // F5' = 0
          end
          8'h18: cells[pod[31:0]] <= u_new;                 // TRELAX step (0x118)
          default: ;
        endcase
      end
      if (hit && (mem_wstrb == 4'd0)) begin
        if (is_cell)             mem_rdata <= {8'b0, cells[cidx >> 2]};
        else case (cidx)
          8'h04:  mem_rdata <= {16'b0, div};
          8'h08:  mem_rdata <= {16'b0, curl};
          8'h0C:  mem_rdata <= {31'b0, ofit};
          8'h10:  mem_rdata <= {20'b0, u_new};
          default: mem_rdata <= 32'd0;
        endcase
      end
    end
  end
endmodule
