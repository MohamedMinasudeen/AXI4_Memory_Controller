`timescale 1ns/1ps

module axi4_memory_controller #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)(
  input  wire                   ACLK,
  input  wire                   ARESETn,

  // AXI Write Address Channel
  input  wire [ADDR_WIDTH-1:0] AWADDR,
  input  wire [7:0]            AWLEN,
  input  wire [2:0]            AWSIZE,
  input  wire [1:0]            AWBURST,
  input  wire                  AWVALID,
  output reg                   AWREADY,

  // AXI Write Data Channel
  input  wire [DATA_WIDTH-1:0] WDATA,
  input  wire                  WVALID,
  input  wire                  WLAST,
  output reg                   WREADY,

  // AXI Write Response Channel
  output reg [1:0]             BRESP,
  output reg                   BVALID,
  input  wire                  BREADY,

  // AXI Read Address Channel
  input  wire [ADDR_WIDTH-1:0] ARADDR,
  input  wire [7:0]            ARLEN,
  input  wire [2:0]            ARSIZE,
  input  wire [1:0]            ARBURST,
  input  wire                  ARVALID,
  output reg                   ARREADY,

  // AXI Read Data Channel
  output reg [DATA_WIDTH-1:0]  RDATA,
  output reg                   RVALID,
  output reg                   RLAST,
  input  wire                  RREADY,

  // External memory interface
  output reg  [ADDR_WIDTH-1:2] mem_addr,
  output reg                   mem_write_en,
  output reg  [DATA_WIDTH-1:0] mem_write_data,
  input  wire [DATA_WIDTH-1:0] mem_read_data
);

  // FSM States
  localparam S_IDLE        = 3'b000;
  localparam S_WRITE_ADDR  = 3'b001;
  localparam S_WRITE_DATA  = 3'b010;
  localparam S_WRITE_RESP  = 3'b011;
  localparam S_READ_ADDR   = 3'b100;
  localparam S_READ_WAIT   = 3'b101;
  localparam S_READ_DATA   = 3'b110;

  reg [2:0] state;
  reg [7:0] burst_len;
  reg [7:0] burst_cnt;
  reg [ADDR_WIDTH-1:2] addr_reg;

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      AWREADY        <= 0;
      WREADY         <= 0;
      BVALID         <= 0;
      BRESP          <= 0;
      ARREADY        <= 0;
      RVALID         <= 0;
      RLAST          <= 0;
      RDATA          <= 0;
      mem_addr       <= 0;
      mem_write_en   <= 0;
      mem_write_data <= 0;
      burst_cnt      <= 0;
      burst_len      <= 0;
      addr_reg       <= 0;
      state          <= S_IDLE;
    end else begin
      // Default values
      AWREADY        <= 0;
      WREADY         <= 0;
      ARREADY        <= 0;
      RVALID         <= 0;
      RLAST          <= 0;
      BVALID         <= 0;
      mem_write_en   <= 0;

      case (state)
        S_IDLE: begin
          if (AWVALID) begin
            AWREADY   <= 1;
            addr_reg  <= AWADDR[ADDR_WIDTH-1:2]; // Word address
            burst_len <= AWLEN;
            burst_cnt <= 0;
            state     <= S_WRITE_DATA;
          end else if (ARVALID) begin
            ARREADY   <= 1;
            addr_reg  <= ARADDR[ADDR_WIDTH-1:2];
            burst_len <= ARLEN;
            burst_cnt <= 0;
            state     <= S_READ_WAIT;
          end
        end

        S_WRITE_DATA: begin
          if (WVALID) begin
            WREADY         <= 1;
            mem_addr       <= addr_reg + burst_cnt;
            mem_write_en   <= 1;
            mem_write_data <= WDATA;
            burst_cnt      <= burst_cnt + 1;
            if (WLAST) begin
              state <= S_WRITE_RESP;
            end
          end
        end

        S_WRITE_RESP: begin
          BVALID <= 1;
          BRESP  <= 2'b00; // OKAY
          if (BREADY) begin
            state <= S_IDLE;
          end
        end

        S_READ_WAIT: begin
          state <= S_READ_DATA;
        end

        S_READ_DATA: begin
          if (RREADY || !RVALID) begin
            mem_addr <= addr_reg + burst_cnt;
            RDATA    <= mem_read_data;
            RVALID   <= 1;
            RLAST    <= (burst_cnt == burst_len);
            burst_cnt <= burst_cnt + 1;
            if (burst_cnt == burst_len) begin
              state <= S_IDLE;
            end
          end
        end
      endcase
    end
  end

endmodule
