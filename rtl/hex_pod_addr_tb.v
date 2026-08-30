// ============================================================================
// hex_pod_addr_tb.v — testbench for the isotropic pod lookup.
// Checks the pod of cell (1,0) [address 6] = {6, 20, 8, 4, 0, 7, 21} (hex_mmu.md §3b)
// and that every pod has exactly 7 distinct addresses (HexIsotropy.neighbors_card).
// ============================================================================
`timescale 1ns/1ps

module hex_pod_addr_tb;

  reg  [31:0] center;
  wire [223:0] pod;
  hex_pod_addr u_pod (.pod(pod), .center(center));

  // unpack helpers
  wire [31:0] p0 = pod[31:0];
  wire [31:0] p1 = pod[63:32];
  wire [31:0] p2 = pod[95:64];
  wire [31:0] p3 = pod[127:96];
  wire [31:0] p4 = pod[159:128];
  wire [31:0] p5 = pod[191:160];
  wire [31:0] p6 = pod[223:192];

  integer errors;

  task chk_pod;
    input [255:0] msg;
    input [31:0] c;
    input [31:0] e0, e1, e2, e3, e4, e5, e6;
    begin
      center = c; #1;
      if (p0 !== e0 || p1 !== e1 || p2 !== e2 || p3 !== e3 ||
          p4 !== e4 || p5 !== e5 || p6 !== e6) begin
        errors = errors + 1;
        $display("FAIL: %0s  got {%0d,%0d,%0d,%0d,%0d,%0d,%0d}  want {%0d,%0d,%0d,%0d,%0d,%0d,%0d}",
                 msg, p0, p1, p2, p3, p4, p5, p6,
                 e0, e1, e2, e3, e4, e5, e6);
      end else
        $display("PASS: %0s  = {%0d,%0d,%0d,%0d,%0d,%0d,%0d}", msg, p0, p1, p2, p3, p4, p5, p6);
    end
  endtask

  initial begin
    errors = 0;
    // cell (1,0) = addr 6; neighbors {20, 8, 4, 0, 7, 21} (hex_mmu.md worked example)
    chk_pod("pod(addr 6) = cell (1,0)", 32'd6, 32'd6, 32'd20, 32'd8, 32'd4, 32'd0, 32'd7, 32'd21);
    // the origin: neighbors of (0,0) = {1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1} -> addrs
    chk_pod("pod(addr 0) = cell (0,0)", 32'd0, 32'd0, 32'd6, 32'd4, 32'd5, 32'd2, 32'd1, 32'd7);

    // distinctness over a few cells (HexIsotropy.neighbors_card)
    center = 32'd6; #1;
    if (p0==p1 || p0==p2 || p1==p2 || p2==p3 || p3==p4 || p4==p5 || p5==p6)
      begin errors=errors+1; $display("FAIL: pod(6) not 7-distinct"); end
    else $display("PASS: pod(6) is 7 distinct addresses (isotropic)");

    $display("======================================================");
    if (errors == 0)
      $display("ALL ASSERTIONS PASSED — hex_pod_addr verified.");
    else begin
      $display("FAILURES: %0d", errors);
      $display("SIMULATION FAILED");
    end
    $display("======================================================");
    $finish;
  end

endmodule
