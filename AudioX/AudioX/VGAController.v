`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CS3710 Fall 2017
// Engineer: Brett Loertscher
// 
// Create Date:    16:22:40 09/05/2017 
// Design Name: 
// Module Name:    VGAController 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: Handles the sync and color outputs to a 640x480 60Hz VGA monitor. 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module VGAController(
	input clk,
	input [7:0] in_color,
	output req,
	output [9:0] req_col,
	output [8:0] req_row,
	output reg hsync, // active low
	output reg vsync, // active low
	output reg [7:0] vgacolor // {2'b blue, 3'b green, 3'b red}
   );
	
	initial hsync = 1; 
	initial vsync = 1; 
	initial vgacolor = 0; 
	
	// Internal flip-flop signals
	reg [1:0] pix_ct; // Each pixel takes 4 clock cycles
	reg [9:0] col_ct; // Which pixel in the row - Each row takes 800 pixels
	reg [9:0] row_ct; // Which row in the frame - Each frame takes 525 rows
	
	initial pix_ct = 0;
	initial col_ct = 0;
	initial row_ct = 0;
	
	// Internal wire signals latched each posedge clk
	wire [1:0] next_pix_ct;
	wire [9:0] next_col_ct;
	wire [9:0] next_row_ct;
	wire next_pix_visible;
	wire next_hsync;
	wire next_vsync;
	wire [7:0] next_color;
	
	wire pix_end;
	wire line_end;
	wire frame_end;
	
	// These deal with signaling to the pixel generator the next pixel that needs to be shown
	wire [9:0] prep_col; // Don't need to worry about looking at 1 row ahead
	wire 		  prep_visible;
	
	assign pix_end = pix_ct == 3;
	assign line_end = pix_end && (col_ct == 799);
	assign frame_end = line_end && (row_ct == 524);
	
	// These deal with what is happening on the next 100MHz clock cycle
	assign next_pix_ct = pix_ct + 1'b1;
	assign next_col_ct = line_end ? 10'b0 : 
								pix_end ? col_ct + 1'b1 :
								col_ct;
	assign next_row_ct = frame_end ? 10'b0 : 
								line_end ? row_ct + 1'b1 :
								row_ct;
	assign next_pix_visible = next_col_ct >= (96 + 48) && // hsync + h back porch
									  next_col_ct < (800 - 16) && // h front porch
									  next_row_ct >= (2 + 33) &&  // vsync + v front porch
									  next_row_ct < (525 - 10); 	 // v back porch
											
	assign next_hsync = next_col_ct < 96 ? 1'b0 : 1'b1; // hsync pulse low for 96 pixels time
	assign next_vsync = next_row_ct < 2 ? 1'b0 : 1'b1;  // vsync pulse low for 2 rows time
	assign next_color = !next_pix_visible ? 8'b0 :  // if not in displayable area, output 0
							  !pix_end ? vgacolor : // if holding the pixel, shouldn't change color
							  in_color; // take input color 

	assign prep_col = next_col_ct + 1'b1;
	assign prep_visible = prep_col >= (96 + 48) && // hsync + h back porch
								 prep_col < (800 - 16) && // h front porch
								 next_row_ct >= (2 + 33) &&  // vsync + v back porch
								 next_row_ct < (525 - 10); 	 // v front porch
	// Module outputs				
	assign req_col = prep_visible ? {prep_col - (96 + 48)}[9:0] : 10'b0;
	assign req_row = prep_visible ? {next_row_ct - (2 + 33)}[8:0] : 9'b0;
	assign req = pix_end && prep_visible;

	
	always@(posedge clk)
	begin
		hsync <= next_hsync;
		vsync <= next_vsync;
		vgacolor <= next_color;
		pix_ct <= next_pix_ct;
		col_ct <= next_col_ct;
		row_ct <= next_row_ct;
	end
	
endmodule
