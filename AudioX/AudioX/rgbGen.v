`timescale 1ns / 1ps

module rgbGen(
	input req,
	input clk,
	input[8:0] row,
	input[9:0] col,
	output reg[7:0] rgb,
	input[15:0] dataOut,
	output reg[13:0] addr
    );

	reg[1:0] state;
	reg[7:0] textColor;

	always @ (*) begin
			addr <= 0;
		// Retrieve the ascii code for gylph to be displayed
		if(state == 0) begin
			addr <= {1'b0, row[8:3], col[9:3]};
		end
		// Retrieve the gylph from memory to be displayed.
		if(state == 1) begin
			addr <= {4'd0, dataOut[7:0], row[2:1]} + 14'h2000;
		end
	end
	
	
	// Update color when request is high at posedge clock.
	always@(posedge clk) begin
		if(req) begin
				state <= 0;
		end
		// Display the text
		if(state < 3)
			state <= state + 1'b1;
		if(state == 2) begin
			if(dataOut[{~row[0], col[2:0]}])
				rgb = textColor;
			else
				rgb = 0;
		end
		if(state == 1) begin
			textColor = dataOut[15:8];
		end
	end
endmodule
