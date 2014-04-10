`timescale 1ns/1ps
module memory(
	input clka,
	input rsta,
	input ena, 
	input wea,
	input[13:0] addra,
	input [63:0] dina,
	output reg [63:0] douta
);
	
	reg [63:0] mem[0:16383];
	integer i;
	
	assign read=ena&wea;
	assign write=ena&(~wea);
	always@(posedge clka) begin
	    if (read)
	      douta <= mem[addra];
	     else if (write)
	       mem[addra] <= dina;
	end
	
	initial begin
      //$readmemb("DM.txt", mem); // DM.mif is memory file
      for (i=0;i<16384;i=i+1)
         mem[i]=0;
   end
	
	
	endmodule