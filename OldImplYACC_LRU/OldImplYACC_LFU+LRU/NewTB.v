`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   09:08:59 11/06/2018
// Design Name:   mainMod
// Module Name:   D:/XilinxProjs/YACC/NewTB.v
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

module NewTB;

	// Inputs
	reg clock;
	reg [31:0] address;
	
	integer file_outputs; // var to see if file exists 
	integer scan_outputs; // captured text handler
	integer count;	

	// Instantiate the Unit Under Test (UUT)
	mainMod uut (
		.clock(clock), 
		.address(address)
	);
	
	initial
	begin
		//open the data Memory file
		file_outputs = $fopen("C:/Users/Dell/Desktop/PENandithaMam/twolfAddress.txt", "r"); //Opening text file
		if (file_outputs == 0) begin             // If outputs file is not found
      $display("data_file handle was NULL"); 
      $finish;
		end
	end

	initial begin
		// Initialize Inputs
		clock = 1;
		address = 0;
	end
	
	initial begin
		forever #0.001 clock=~clock;
	end
	initial begin
	 for(count=0;count<=482823;count=count+1)begin
			#0.002 $fseek(file_outputs,((8*count)+(2*(count-1))),0);
		
		   scan_outputs = $fscanf(file_outputs, "%h\n", address);     //Outputs line text	
			$display ($time, "Address: %h count=%d Entry=%d",address,count,uut.enter);
		 end
	end
      
endmodule

