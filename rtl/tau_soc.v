// ============================================================================
// tau_soc.v — the Tau SoC top-level: PicoRV32 (binary RV32I core) + registered
// memory + the Xlattice co-processor on the PCPI port.
//
// This is the "full processor" assembly in pure Verilog: a real binary RISC-V core
// executing a program, with the ternary/hex Xlattice ops as custom-0 instructions via
// the PCPI co-processor port.  The hex MMU (hex_pod_addr) is a memory-mapped peripheral
// (the next wiring step); here the CFU + memory are assembled and simulated first.
//
//   PicoRV32 (picorv32/picorv32.v, cloned) — the binary core (compute stays binary)
//   registered memory (256 words)         — program + data
//   picorv32_pcpi_xlattice                — the Xlattice co-processor (custom-0)
//
// Verilog-2001; synthesizable.
// ============================================================================

`timescale 1ns/1ps

module tau_soc (
  input  wire clk,
  input  wire resetn,
  output wire trap
);
  // ---- PicoRV32 core ---------------------------------------------------------
  wire mem_valid, mem_instr;
  wire mem_ready;
  wire [31:0] mem_addr, mem_wdata;
  wire [3:0]  mem_wstrb;
  wire [31:0] mem_rdata;

  wire        pcpi_valid;
  wire [31:0] pcpi_insn, pcpi_rs1, pcpi_rs2;
  wire        pcpi_wr, pcpi_wait, pcpi_ready;
  wire [31:0] pcpi_rd;

  picorv32 #(.ENABLE_PCPI(1)) u_core (
    .clk(clk), .resetn(resetn), .trap(trap),
    .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
    .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb), .mem_rdata(mem_rdata),
    .pcpi_valid(pcpi_valid), .pcpi_insn(pcpi_insn),
    .pcpi_rs1(pcpi_rs1), .pcpi_rs2(pcpi_rs2),
    .pcpi_wr(pcpi_wr), .pcpi_rd(pcpi_rd),
    .pcpi_wait(pcpi_wait), .pcpi_ready(pcpi_ready),
    .irq(32'd0)
  );

  // ---- registered memory (word-addressed, 256 words; PicoRV32's model) -------
  reg [31:0] memory [0:255];
  initial $readmemh("rtl/program_tau.hex", memory);

  reg        ram_ready;
  reg [31:0] ram_rdata;
  always @(posedge clk) begin
    ram_ready <= 0;
    if (mem_valid && !mem_ready && mem_addr < 1024) begin
      ram_ready <= 1;
      ram_rdata <= memory[mem_addr >> 2];
      if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
      if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
      if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
      if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
    end
  end

  // ---- hex MMU peripheral (memory-mapped at 0x1000) --------------------------
  wire        mmu_ready;
  wire [31:0] mmu_rdata;
  hex_mmu_periph u_mmu (
    .clk(clk), .resetn(resetn),
    .mem_valid(mem_valid), .mem_addr(mem_addr),
    .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
    .mem_rdata(mmu_rdata), .mem_ready(mmu_ready));

  // ---- field-calculus accelerator (memory-mapped at 0x2000) ------------------
  wire        field_ready;
  wire [31:0] field_rdata;
  hex_field_accel u_field (
    .clk(clk), .resetn(resetn),
    .mem_valid(mem_valid), .mem_addr(mem_addr),
    .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
    .mem_rdata(field_rdata), .mem_ready(field_ready));

  // ---- ternary transport link (memory-mapped at 0x3000) ----------------------
  wire        link_ready;
  wire [31:0] link_rdata;
  ternary_link_periph u_link (
    .clk(clk), .resetn(resetn),
    .mem_valid(mem_valid), .mem_addr(mem_addr),
    .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
    .mem_rdata(link_rdata), .mem_ready(link_ready));

  assign mem_ready = (mem_addr >= 32'h0000_3000) ? link_ready :
                     (mem_addr >= 32'h0000_2000) ? field_ready :
                     (mem_addr >= 32'h0000_1000) ? mmu_ready : ram_ready;
  assign mem_rdata = (mem_addr >= 32'h0000_3000) ? link_rdata :
                     (mem_addr >= 32'h0000_2000) ? field_rdata :
                     (mem_addr >= 32'h0000_1000) ? mmu_rdata : ram_rdata;

  // ---- the Xlattice co-processor (custom-0 via PCPI) -------------------------
  picorv32_pcpi_xlattice u_pcpi (
    .pcpi_valid(pcpi_valid), .pcpi_insn(pcpi_insn),
    .pcpi_rs1(pcpi_rs1), .pcpi_rs2(pcpi_rs2),
    .pcpi_wr(pcpi_wr), .pcpi_rd(pcpi_rd),
    .pcpi_wait(pcpi_wait), .pcpi_ready(pcpi_ready));
endmodule
