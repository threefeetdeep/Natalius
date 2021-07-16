`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 									PC STACK
//					(LIFO - last in, first out register array)
//////////////////////////////////////////////////////////////////////////////////
module LIFO(
    input clk,
	input rst,
    input wr_en,
    input rd_en,
    input [10:0] din,
    output [10:0] dout
    );


   // (*  RAM_STYLE="DISTRIBUTED" *)
   reg [3:0] stack_addr;	
   reg [10:0] stack [15:0];

   always@(posedge clk)
		if (rst)
			stack_addr<=0;
		else 
			 begin 
			  if (wr_en==0 && rd_en==1)  // remove item from stack
					if (stack_addr > 0)
						stack_addr <= stack_addr-1;
			  if (wr_en==1 && rd_en == 0)  // add item to stack (BEWARE: no overflow detection!!!)
					if (stack_addr<15)
						stack_addr <= stack_addr+1;
			 end
		
	always @(posedge clk)
      if (wr_en)
         stack[stack_addr] <= din;

   assign dout = stack[stack_addr];   

endmodule
