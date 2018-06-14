`timescale 1ns / 1ps

module VGATest(
	input clk,
	input[7:0] nextRGB2,
	output reg[7:0] rgb,
	output reg hsync,
	output reg vsync,
	output[8:0] RGBRow,
	output[9:0] RGBCol,
	output req
    );

	// Counters for pixels, rows, and columns
	reg[1:0] pixelCounter;
	reg[9:0] colCounter; // 0-799
	reg[9:0] rowCounter; // 0-524
	
	// Wires for the values of the counters, updated every clock cycle when values change 
	wire[9:0] nextRowCounter;
	wire[1:0] nextPixelCounter;
	wire[9:0] nextColCounter;
	wire rowEnd;
	wire colEnd;
	wire pixelEnd;
	wire nextHSync;
	wire nextVSync;
	wire[7:0] nextRGB;
	wire visible;
	
	// Get the row and col of the visible region.
	assign RGBRow = rowCounter[8:0] - 8'd34;
	assign RGBCol = colCounter - 9'd47;
	
	// Increment pixel counter to to update pixels every 4 cycles for 25 MHz.
	assign nextPixelCounter = pixelCounter + 1'b1;
	assign pixelEnd = pixelCounter == 3;
	
	// Increment the column when the pixel changes. Column resets every 800 pixels.
	assign nextColCounter = !pixelEnd ? colCounter : !colEnd ? colCounter + 1'b1 : 1'b0;   
	assign colEnd = pixelEnd && colCounter == 799; 
	
	// Increment the row when the pixel changes and the column ends. Row resets every 640 pixels.
	assign nextRowCounter = !colEnd ? rowCounter : !rowEnd ? rowCounter + 1'b1 : 1'b0;   
	assign rowEnd = colEnd && rowCounter == 524; 
	
	// Set the boolean if the currently inside the visible region.
	assign visible = nextRowCounter > 32 && nextRowCounter < (525-12) && nextColCounter > 47 && nextColCounter < (800-112);
	assign req = RGBRow < 480 && RGBCol < 640 && pixelEnd ?
						1'b1 : 1'b0;
						
	// If inside of the visible region use the RGB generated otherwise set the value to 0.
	assign nextRGB = visible ? 
					 nextRGB2 : 1'b0;
					 
	// Update the hysnc and vsync at ends
	assign nextHSync = nextColCounter > (799-96) ? 1'b0 : 1'b1;
	assign nextVSync = nextRowCounter > (524-2) ? 1'b0 : 1'b1;
	
	initial begin
		pixelCounter = 0;
		colCounter = 0;
		rowCounter = 0;
		rgb = 0;
		hsync = 1;
		vsync = 1;
	end
	
	// Update the output values with the values on the wires
	always@(posedge clk) begin
		pixelCounter <= nextPixelCounter;
		colCounter <= nextColCounter;
		rowCounter <= nextRowCounter;
		
		hsync <= nextHSync;
		vsync <= nextVSync;
		if(pixelEnd)
			rgb <= nextRGB;
		
	end
endmodule
