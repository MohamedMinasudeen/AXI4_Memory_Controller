# AXI4_Memory_Controller

AXI4-Lite compatible memory controller with Verilog testbench and simulation.

AXI4 (Advanced eXtensible Interface 4) is part of the AMBA protocol family developed by ARM. It’s a high-performance, high-frequency bus used in SoC (System on Chip) designs. It defines how different components (like CPUs, memory controllers, and peripherals) communicate.

# Key features
-  **Burst Transfers** — Multi-beat transfers (up to 256 beats supported)

-  **Pipelined Channels** — Independent read/write channels for high throughput

-  **Scalable Interface** — Modular Verilog design ideal for SoC integration

-  **Synthesizable RTL** — Fully compatible with synthesis tools

-  **Testbench Included** — Verilog testbench with simulation waveforms


##
# AXI Write Address Channel

| Port Name | Direction | Width       | Description                  |
| --------- | --------- | ----------- | ---------------------------- |
| ACLK      | Input     |   -       | Global clock                 |
| ARESETn   | Input     |   -       | Active-low synchronous reset |
| AWADDR    | Input     | ADDR\_WIDTH | Write address for the first data in a burst. |
| AWLEN   | Input     | 8 bits | Burst length (number of data transfers minus one). |
| AWSIZE   | Input     | 3 bits | Size of each data transfer in the burst (encoded, typically power-of-two bytes). |
| AWBURST  | Input     | 2 bits | Burst type (e.g., INCR, FIXED, WRAP). |
| AWVALID   | Input     | 1 bit       | Master signals when address/control info is valid |
| AWREADY   | Output    | 1 bit       | Slave signals ready to accept address/control info.  |

