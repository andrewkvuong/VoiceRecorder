`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:38:04 09/13/2017 
// Design Name: 
// Module Name:    GlyphGen 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module GlyphGen16b(
	input clk,						// system clock
	//input [7:0] sw,				// to control color
	input req,						// to indicate a row and column to prepare are ready
	input [9: 0] in_col, 		// [0,639] (640px) width
	input [8: 0] in_row, 		// [0,479] (480px) height
	input [15:0] data_read, 	// incoming data from memory
	output reg [7: 0] color,	// color to display
	output reg [ADDR_WIDTH - 1:0] addr 		// address to request from memory; width depends on how many words of memory are stored
	);

	parameter ADDR_WIDTH = 15;
	parameter C_START = 0; 		// beginning of memory the characters to draw are stored
	parameter G_START = 8192;  // beginning of memory the glyphs corresponding to chars are stored
	
	initial color = 0;
	initial addr = 0;
	
	reg [1:0] state = 0;
	reg [9:0] raw_col = 0;
	reg [8:0] raw_row = 0;
	reg [7:0] char_color = 0;
	
	wire [6:0] glyph_col; 					// [0,79] 80 glyphs per row
	wire [5:0] glyph_row; 					// [0,59] 60 rows per screen
	wire [2:0] col_in_glyph;				// [0,7], left = 0
	wire [2:0] row_in_glyph;				// [0,7], top = 0
	
	wire [7:0] char_val;	  					// from data_read
	wire [15:0] glyph_word; 				// from memory
	
	wire pix_fill;								// glyph bit is set to 1
	
	assign glyph_col = raw_col[9:3]; 	// raw_col / 8 -- 640 / 8 = 80 glpyhs per row
	assign glyph_row = raw_row[8:3];		// raw_row / 8 -- 480 / 8 = 60 rows per screen
	assign col_in_glyph = raw_col[2:0]; // raw_col % 8 -- each glyph is 8 pix wide
	assign row_in_glyph = raw_row[2:0]; // raw_row % 8 -- each glyph is 8 pix tall
	 
	assign char_val = data_read[7:0];	
	assign glyph_word = data_read;
	
	assign pix_fill = data_read[ {~raw_row[0], raw_col[2:0]} ]; // select the correct bit in the glyph
	
	// Determine which address to request from memory
	always@(*)
	begin
		case(state)
			0 	: addr = 0;
				// character address, based on the glyph location in 80x40 grid
			1  : addr = {2'd0, raw_row[8:3], raw_col[9:3]}; //C_START + {glyph_row, glyph_col}; 
				// glyph address, based on which word needs to be read from memory
			2	: addr = 15'h2000 + {5'd0, data_read[7:0], raw_row[2:1]}; //[13:0]; // TODO might need to be fixed to ADDR_WIDTH
			3  : addr = 0; 
			default 	  
				: addr = 0;
		endcase
	end
	
	// State machine - determines which color to output
	always@(posedge clk)
	begin
		case(state)
			0 : // ready
				if(req)
				begin
					state <= 1;
					raw_col <= in_col;
					raw_row <= in_row;
					color <= color;
				end
			1 : // prep_char
				state <= 2;
			2 : // prep_glyph
			
			begin
				state <= 3;
				char_color <= data_read[15:8];	// latch the color for use in next cycle
			end
			3 : // prep_color
			begin
				state <= 0;
				color <= pix_fill ? char_color //& sw 
										: 8'd0;	// fill in the foreground or background color
			end
		endcase
	end	
		
endmodule
