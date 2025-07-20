`timescale 1ns/1ps

module simple_memory #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter MEM_DEPTH  = 1024
)(
  input  wire                      clk,
  input  wire                      rst,

  // Write interface
  input  wire                      write_en,
  input  wire [ADDR_WIDTH-3:0]     addr,       // Word address
  input  wire [DATA_WIDTH-1:0]     write_data,

  // Read interface
  output reg  [DATA_WIDTH-1:0]     read_data
);

  // Internal memory
  reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

  always @(posedge clk) begin
    if (write_en) begin
      mem[addr] <= write_data;
    end
    read_data <= mem[addr]; // Simple synchronous read
  end

endmodule
