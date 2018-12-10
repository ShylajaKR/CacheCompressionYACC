`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:10:28 11/11/2018
// Design Name:   mainMod
// Module Name:   C:/Users/Dell/Desktop/YACC/manualTestBench.v
// Project Name:  YACC
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mainMod
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module manualTestBench;

	// Inputs
	reg clock;
	reg [31:0] address;

	// Instantiate the Unit Under Test (UUT)
	mainMod uut (
		.clock(clock), 
		.address(address)
	);

	initial begin
		// Initialize Inputs
		clock = 1;
		address = 0;
	end
	
	initial
	begin
	forever #1 clock=~clock;
	end
	
	initial
	begin
	#2 address=32'b000000000000000000000_000_01_000000;
	#2 address=32'b000000000000000000000_000_10_000000;
	#2 address=32'b000000000000000000000_000_11_000000;
	
	#2 address=32'b000000000000000000001_000_00_000000;
	#2 address=32'b000000000000000000001_000_01_000000;
	#2 address=32'b000000000000000000001_000_11_000000;
	#2 address=32'b000000000000000000001_000_10_000000;	
	#2 address=32'b000000000000000000010_000_11_000000;
	#2 address=32'b000000000000000000010_000_01_000000;
	//repeat
	#2 address=32'b000000000000000000001_000_00_000000;
	#2 address=32'b000000000000000000010_000_01_000000;
	
	#2 address=32'b000000000000000000000_001_01_000000;
	#2 address=32'b000000000000000000010_001_01_000000;
	#2 address=32'b000000000000000000010_001_01_000000;//repeat
	#2 address=32'b000000000000000000010_001_01_000000;
	#2 address=32'b000000000000000000010_001_11_000000;
	//repeat
	#2 address=32'b000000000000000000000_000_01_000000;
	#2 address=32'b000000000000000000000_000_11_000000;
	
	#2 address=32'b000000000000000000000_001_10_000000;
	#2 address=32'b000000000000000000000_001_00_000000;
	#2 address=32'b000000000000000000010_001_01_000000;
	#2 address=32'b000000000000000000010_001_01_000000;
	//repeat
	#2 address=32'b000000000000000000000_000_01_000000;
	#2 address=32'b000000000000000000000_000_11_000000;
	
	#2 address=32'b000000000000000000000_001_01_000000;
	#2 address=32'b000000000000000000000_000_10_000000;	
	end
      
endmodule

