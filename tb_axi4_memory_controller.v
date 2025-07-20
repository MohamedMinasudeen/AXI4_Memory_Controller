`timescale 1ns/1ps

module tb_axi4_memory_controller;

  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;
  parameter MEM_DEPTH  = 1024;
  parameter BURST_LEN  = 4;

  reg ACLK;
  reg ARESETn;

  // AXI Write Address Channel
  reg [ADDR_WIDTH-1:0] AWADDR;
  reg [7:0] AWLEN;
  reg [2:0] AWSIZE;
  reg [1:0] AWBURST;
  reg AWVALID;
  wire AWREADY;

  // AXI Write Data Channel
  reg [DATA_WIDTH-1:0] WDATA;
  reg WVALID, WLAST;
  wire WREADY;

  wire [1:0] BRESP;
  wire BVALID;
  reg BREADY;

  // AXI Read Address Channel
  reg [ADDR_WIDTH-1:0] ARADDR;
  reg [7:0] ARLEN;
  reg [2:0] ARSIZE;
  reg [1:0] ARBURST;
  reg ARVALID;
  wire ARREADY;

  wire [DATA_WIDTH-1:0] RDATA;
  wire RVALID, RLAST;
  reg RREADY;

  // Memory interface
  wire [ADDR_WIDTH-1:2] mem_addr;
  wire mem_write_en;
  wire [DATA_WIDTH-1:0] mem_write_data;
  wire [DATA_WIDTH-1:0] mem_read_data;

  // For checking data correctness
  reg [DATA_WIDTH-1:0] written_data [0:BURST_LEN-1];
  reg [DATA_WIDTH-1:0] read_data    [0:BURST_LEN-1];

  integer i;

  // Instantiate simple memory (your simple_memory module)
  simple_memory #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(MEM_DEPTH)
  ) u_mem (
    .clk(ACLK),
    .rst(~ARESETn),
    .write_en(mem_write_en),
    .addr(mem_addr),
    .write_data(mem_write_data),
    .read_data(mem_read_data)
  );

  // Instantiate Device Under Test (DUT)
  axi4_memory_controller #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_dut (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    .AWADDR(AWADDR),
    .AWLEN(AWLEN),
    .AWSIZE(AWSIZE),
    .AWBURST(AWBURST),
    .AWVALID(AWVALID),
    .AWREADY(AWREADY),
    .WDATA(WDATA),
    .WVALID(WVALID),
    .WLAST(WLAST),
    .WREADY(WREADY),
    .BRESP(BRESP),
    .BVALID(BVALID),
    .BREADY(BREADY),
    .ARADDR(ARADDR),
    .ARLEN(ARLEN),
    .ARSIZE(ARSIZE),
    .ARBURST(ARBURST),
    .ARVALID(ARVALID),
    .ARREADY(ARREADY),
    .RDATA(RDATA),
    .RVALID(RVALID),
    .RLAST(RLAST),
    .RREADY(RREADY),
    .mem_addr(mem_addr),
    .mem_write_en(mem_write_en),
    .mem_write_data(mem_write_data),
    .mem_read_data(mem_read_data)
  );

  // Clock generation (100MHz)
  initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;
  end

  // Waveform dump for simulation viewing
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_axi4_memory_controller);
  end

  // Task: AXI4 Write Burst
  task axi_write_burst(input [ADDR_WIDTH-1:0] start_addr, input integer burst_len);
    integer j;
    begin
      @(posedge ACLK);
      AWADDR  = start_addr;
      AWLEN   = burst_len - 1;
      AWSIZE  = 3'b010;  // 4 bytes data size
      AWBURST = 2'b01;   // INCR burst
      AWVALID = 1;
      while (!AWREADY) @(posedge ACLK);
      @(posedge ACLK);
      AWVALID = 0;

      for (j = 0; j < burst_len; j = j + 1) begin
        WDATA = $random;
        written_data[j] = WDATA;
        WVALID = 1;
        WLAST  = (j == burst_len - 1) ? 1 : 0;
        while (!WREADY) @(posedge ACLK);
        @(posedge ACLK);
        WVALID = 0;
        WLAST  = 0;
      end

      BREADY = 1;
      while (!BVALID) @(posedge ACLK);
      @(posedge ACLK);
      BREADY = 0;
    end
  endtask

  // Task: AXI4 Read Burst
  task axi_read_burst(input [ADDR_WIDTH-1:0] start_addr, input integer burst_len);
    integer j;
    begin
      @(posedge ACLK);
      ARADDR  = start_addr;
      ARLEN   = burst_len - 1;
      ARSIZE  = 3'b010; // 4 bytes data size
      ARBURST = 2'b01;  // INCR burst
      ARVALID = 1;
      while (!ARREADY) @(posedge ACLK);
      @(posedge ACLK);
      ARVALID = 0;

      j = 0;
      RREADY = 1;
      while (j < burst_len) begin
        @(posedge ACLK);
        if (RVALID) begin
          read_data[j] = RDATA;
          $display("Readback: Beat %0d, Data = 0x%08x", j, RDATA);
          j = j + 1;
        end
      end
      RREADY = 0;
    end
  endtask

  // Main test sequence
  initial begin
    // Initialize signals
    AWADDR = 0; AWLEN = 0; AWSIZE = 0; AWBURST = 0; AWVALID = 0;
    WDATA = 0; WVALID = 0; WLAST = 0;
    BREADY = 0;
    ARADDR = 0; ARLEN = 0; ARSIZE = 0; ARBURST = 0; ARVALID = 0;
    RREADY = 0;
    ARESETn = 0;

    // Reset pulse
    #20;
    @(posedge ACLK);
    ARESETn = 1;

    // Test 1: Write and read burst at address 0x10
    $display("\n--- Test 1: Write and Read burst at 0x10 ---");
    axi_write_burst(32'h10, BURST_LEN);
    axi_read_burst (32'h10, BURST_LEN);

    // Test 2: Back-to-back burst tests at different addresses
    $display("\n--- Test 2: Back-to-back bursts at 0x20 and 0x30 ---");
    axi_write_burst(32'h20, BURST_LEN);
    axi_read_burst (32'h20, BURST_LEN);
    axi_write_burst(32'h30, BURST_LEN);
    axi_read_burst (32'h30, BURST_LEN);

    // Test 3: Short burst (length 2)
    $display("\n--- Test 3: Short burst at 0x40 ---");
    axi_write_burst(32'h40, 2);
    axi_read_burst (32'h40, 2);

    $display("\nAll tests complete at time %0t", $time);
    #20 $finish;
  end

endmodule
