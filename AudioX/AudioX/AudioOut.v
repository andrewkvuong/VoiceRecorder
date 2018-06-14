`timescale 1ns / 1ps

module AudioOut(
	input clk,
	input start,
	input[7:0] mem_data_upper,
	input[4:0] mem_data_lower,
	output reg[23:0] addr,
	output data,
	output NC,
	output gain,
	output stop,
//	output[15:0] audio_data_to_mem,
//	output audio_we,
	output reg audio_req,
	input data_ready,
	output reg done,
	input[1:0] speed,
	input stopPlaying,
	input[23:0] stopPosition
    );

	assign NC = 0;
	assign gain = 1; // Think 0 is higher gain than 1?
	assign stop = start; // Turn off speaker if switch

	// Registers for data recieved from memory
	reg [7:0] data_saved_upper;
	reg [4:0] data_saved_lower;
		
	// Counter for clock
	reg[15:0] counter;
	
	initial addr = 24'h10000;
	
	always @ (*) begin
		audio_req = 0;
		if(counter == 0 && stop) begin
			audio_req = 1;
		end
	end
	
	//Sets data depending on the data
	wire[12:0] dataCompare;
	
	// Sets frequency of audio played
	wire[12:0] countLimit;

	// Check which speed flag is set and adjust PWM accordingly
	assign countLimit = (speed != 0) ? speed == 1 ? 13'd4096 : 13'd2048 : 13'd8191;
	assign dataCompare = (speed != 0) ? speed == 1 ? {data_saved_upper, data_saved_lower[4:1]} : {data_saved_upper, data_saved_lower[4:2]} : {data_saved_upper, data_saved_lower};
	
	// PWM send 1 while larger and 0 while smaller
	assign data = dataCompare > counter;
	
	always @ (posedge clk) begin
		counter <= counter + 1'b1;
		if(data_ready) begin
			data_saved_upper <= mem_data_upper;
			data_saved_lower <= mem_data_lower;
		end
		// Restart audio
		if(done == 1 && start) begin
			done <= 0;
			addr <= 24'h10000;
			counter <= 0;
		end
		// Stop playing audio
		if(stopPlaying) begin
			addr<= 24'h10000;
			counter <= 0;
		end
		else if(counter == countLimit) begin
			counter <= 0;
			addr <= addr + 1'b1;
			if(addr == stopPosition) begin
				addr <= 24'h10000;
				done <= 1;
			end
		end
	end

endmodule
