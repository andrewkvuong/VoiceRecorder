`timescale 1ns / 1ps

module MicModule_3(
	input sys_clk,
	input sdata,					// comes from ADC, might need to be an inout
	output reg cs_n, 				// goes to pad, initiates and ends SPI
	output reg sclk,				// goes to pad, syncs the data
	output reg [15:0] mic_to_mem_data, // Data to be written to memory

	output reg [23:0] mic_to_mem_addr,
	output reg mic_to_mem_we,
	output reg mic_to_mem_req,
	
	input start_sample,			// from audio controller, start recording
	output reg done_recording
   );

	parameter idle = 0;
	parameter first_cycle = 1;
	parameter receive_data = 2;
	parameter quiet_time = 3;
	parameter ST_WRITE_DATA = 4;
	parameter sample_rate_delay = 5;
	reg [3:0] state = 0;

	parameter AUDIO_START_ADDR = 24'h10000;
    parameter AUDIO_END_ADDR = 24'h160000;

	reg [15:0] sample_rate_counter = 0; 	// counts the number of cycles since start
	
	reg [2:0] sclk_div = 0;	// counts from 0-5 inclusive while transfer going on.
								// when == 3, sclk goes high and sdata is sampled.
								// when == 0, sclk goes low
	reg [3:0] sdata_ct = 0;
	reg [2:0] quiet_ct = 0;
	reg [23:0] next_addr = 0;

	initial cs_n = 1;			// active low
	initial sclk = 1;			// activates on negedge
	initial mic_to_mem_data = 0;
	initial done_recording = 0;

	always@(*) begin
		mic_to_mem_we = 0;
		mic_to_mem_req = 0;
		mic_to_mem_addr = 0;
		if(ST_WRITE_DATA) begin
			mic_to_mem_we = 1;
			mic_to_mem_req = 1;
			mic_to_mem_addr = next_addr;
		end
	end


	always@(posedge sys_clk)
	begin
		if(state != idle)
		begin
			sample_rate_counter <= sample_rate_counter + 1'b1;
		end
		
		if(state == idle)
		begin
			next_addr <= AUDIO_START_ADDR;
			done_recording <= 0;
			if(start_sample) 
			begin
				state <= first_cycle;
			end
		end
		
		if(state == first_cycle) // give 10ns from cs_n going low to sclk going low
		begin
			mic_to_mem_data <= 0;
			cs_n <= 0;
			state <= receive_data;
		end

		if(state == receive_data) // will be here for 16 sclk cycles, or 96 sys_clk cycles
		begin
			sclk_div <= sclk_div + 1'b1;
			if(sclk_div == 5)
			begin
				sclk_div <= 0;
			end

			if(sclk_div == 0)
			begin
				sclk <= 0;
			end
			if(sclk_div == 3)
			begin
				sclk <= 1;
				sdata_ct <= sdata_ct + 1'b1;

				if(sdata_ct < 15) // won't sample on 16th sclk cycle
				begin
					mic_to_mem_data <= { mic_to_mem_data[14:0], sdata };
				end

				// count how many samples we've taken - will take 15 samples (MSB never changes)
				if(sdata_ct == 15)
				begin
					sdata_ct <= 0;
					state <= quiet_time;
				end
			end
		end // of state receive_data

		// This is required by the microphone part - needs about 40 ns of quiet time
		if(state == quiet_time)
		begin
			sclk <= 1;
			cs_n <= 1;
			quiet_ct <= quiet_ct + 1'b1;
			if(quiet_ct == 4)
			begin
				quiet_ct <= 0;
				state <= ST_WRITE_DATA;
			end
		end

		if(state == ST_WRITE_DATA) begin
			state <= sample_rate_delay;
			next_addr <= next_addr + 1'b1;
			if(next_addr == AUDIO_END_ADDR) begin
				next_addr <= AUDIO_START_ADDR;
				done_recording <= 1;
				state <= idle;
			end
		end
		
		// At this point the mic is actually ready to sample again, but we'll have it 
		// wait for a time so that it samples at a more reasonable rate than 1 MHz. 
		if(state == sample_rate_delay)
		begin
			if(sample_rate_counter == 4096) // gives about 16 kHz sample rate
			begin
				sample_rate_counter <= 0;
				if(start_sample)
					state <= first_cycle;
				else 
					state <= idle;
			end
		end
	end

endmodule
