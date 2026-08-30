// ============================================================================
// hex_mmu_periph.v — the hex MMU as a memory-mapped peripheral (the "3^n namespace"
// exposed to a RISC-V core).  Write a center address to the BASE register; read the
// 7-cell pod (center + 6 Z6 neighbors) back from 7 consecutive words.
//
//   BASE+0  (write)  center address   ;  (read) center echo
//   BASE+4..BASE+24  pod[1]..pod[6]   (the 6 neighbors, angle order; 32-bit each)
//
// This is the isotropic lookup ("ram lookup should be isotropic", HexIsotropy.lean)
// as a bus peripheral — the addressing win the plan puts behind the memory port.
//
// Verilog-2001; synthesizable; depends on rtl/hex_pod_addr.v (+ encode/decode).
// ============================================================================

`timescale 1ns/1ps

module hex_mmu_periph #(
  parameter [31:0] BASE = 32'h0000_1000
) (
  input  wire        clk,
  input  wire        resetn,
  // PicoRV32-style memory port
  input  wire        mem_valid,
  input  wire [31:0] mem_addr,
  input  wire [31:0] mem_wdata,
  input  wire [3:0]  mem_wstrb,
  output reg  [31:0] mem_rdata,
  output reg         mem_ready
);
  reg  [31:0] center;
  wire [223:0] pod;
  hex_pod_addr u_pod (.pod(pod), .center(center));

  wire hit   = mem_valid && (mem_addr >= BASE) && (mem_addr < BASE + 28);
  wire [4:0] off = mem_addr[4:0] - BASE[4:0];   // 0,4,8,...,24

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      center    <= 32'd0;
      mem_ready <= 1'b0;
      mem_rdata <= 32'd0;
    end else begin
      mem_ready <= hit;
      if (hit && (mem_wstrb != 4'd0) && off == 0)
        center <= mem_wdata;                     // write the center
      if (hit && mem_wstrb == 4'd0) begin        // read the pod registers
        case (off)
          5'd0:  mem_rdata <= center;       // center echo (off=0 is also the write port)
          5'd4:  mem_rdata <= pod[ 63:32];  // pod[1] = w^0 neighbor
          5'd8:  mem_rdata <= pod[ 95:64];  // pod[2] = w^1 neighbor
          5'd12: mem_rdata <= pod[127:96];  // pod[3] = w^2 neighbor
          5'd16: mem_rdata <= pod[159:128]; // pod[4] = w^3 neighbor
          5'd20: mem_rdata <= pod[191:160]; // pod[5] = w^4 neighbor
          5'd24: mem_rdata <= pod[223:192]; // pod[6] = w^5 neighbor
          default: mem_rdata <= 32'd0;
        endcase
      end
    end
  end
endmodule
