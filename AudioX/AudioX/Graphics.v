`timescale 1ns / 1ps

module Graphics(
	input clk,
	input [15:0] data_mem_to_vga,
	output [13 : 0] addr_vga_to_mem,
	output hsync,
	output vsync, 
	output [7:0] color
   );
	
	
	wire req;
	wire[8:0] RGBRow;
	wire[9:0] RGBCol;
	wire[7:0] nextRGB2;
	rgbGen rgbGenerator(req, clk, RGBRow, RGBCol, nextRGB2, data_mem_to_vga, addr_vga_to_mem);
	VGATest vgaSignal(clk, nextRGB2, color, hsync, vsync, RGBRow, RGBCol, req);
	
endmodule
