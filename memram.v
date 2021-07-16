`timescale 1ns / 1ps

`ifndef MEMRAM_V
`define MEMRAM_V

module memram(
    input clk,
    input [7:0] din,
    input [4:0] addr,
    output [7:0] dout,
    input we
    );

   //(* RAM_STYLE="DISTRIBUTED" *)
	reg [7:0] ram [31:0];

   always @(posedge clk)
      if (we)
         ram[addr] <= din;

   assign dout = ram[addr];   				

endmodule

`endif  // include guard