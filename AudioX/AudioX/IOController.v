`timescale 1ns / 1ps

module IOController(
	input clk, 
	input[15:0] data_mem_audio,
	output reg[23:0] addr_audio_to_mem,
	output audio_data,
	output NC,
	output gain,
	output stop,
	output reg audio_we,
	output reg [15:0] audio_data_to_mem,
	output reg audio_req,
	input audio_data_ready,
	input[2:0] button,

	// Block RAM
	output reg[13:0] addr_IO_to_mem,
	output reg IO_we,
	output reg[15:0] IO_data_to_mem,
	input[15:0] data_mem_IO,

	input mic_sdata,					// Incoming serial data from microphone			
	output mic_cs_n,					// Outgoing signal to microphone to start communication
	output mic_sclk					// Outgoing serial clock to mic to regulate communication

						  
    );

	wire[2:0] button_d;

	ButtonDebouncer _ButtonDebouncer0(.clk(clk), .button(button[0]), .debounced(button_d[0]));
	ButtonDebouncer _ButtonDebouncer1(.clk(clk), .button(button[1]), .debounced(button_d[1]));
	ButtonDebouncer _ButtonDebouncer2(.clk(clk), .button(button[2]), .debounced(button_d[2]));


	// Signal start of audio
	reg speaker_start = 0;
	reg mic_start = 0;
	
	// Speed of audio playback
	reg[1:0] speed = 1;
	
	// Signal when audio is done
	wire audio_done;
	wire mic_done;

	// Wires for audio modules to memory
	wire[23:0] addr_speaker_to_mem;
	wire[23:0] addr_mic_to_mem;
	wire[15:0] mic_to_mem_data;
	wire speaker_req;
	wire mic_mem_req;
	
	// Signal for speaker to stop playing
	reg stopPlaying;
	reg[23:0] stopPosition = 23'h100000;

	AudioOut _AudioOut(.clk(clk),
							 .mem_data_upper(data_mem_audio[7:0]),
							 .mem_data_lower(data_mem_audio[15:11]),
							 .addr(addr_speaker_to_mem),
							 .data(audio_data),
							 .NC(NC),
							 .gain(gain),
							 .stop(stop),
							 .start(speaker_start),
							 .audio_req(speaker_req),
							 .data_ready(audio_data_ready),
							 .done(audio_done),
							 .speed(speed),
							 .stopPlaying(stopPlaying),
							 .stopPosition(stopPosition)
							 );
							 
	MicModule_3 _mic (
    .sys_clk(clk), 
    .sdata(mic_sdata), 
    .cs_n(mic_cs_n), 
    .sclk(mic_sclk), 
    .mic_to_mem_data(mic_to_mem_data), 
    .mic_to_mem_addr(addr_mic_to_mem), 
    .mic_to_mem_we(mic_to_mem_we), 
    .mic_to_mem_req(mic_to_mem_req), 
    .start_sample(mic_start), 
	 .done_recording(mic_done)
    );						 
							 
	reg[3:0] state = 0;

	
	// Count to wait for core to complete
	reg[6:0] waitingCount = 0;
	
	parameter IDLE = 0;
	parameter BUTTONUP = 1;
	parameter BUTTONDOWN = 2;
	parameter BUTTONSELECT = 3;
	parameter FETCHSELECT = 6;
	parameter DECODESELECT = 4;
	parameter PLAYAUDIO = 5;
	parameter STARTRECORD = 7;
	parameter STOPPLAY = 8;
	parameter STOPRECORD = 9;
	parameter WAITSTOP = 10;
	
	always@(*)begin
		IO_we = 0;
		addr_IO_to_mem = 0;
		IO_data_to_mem = 0;
		speaker_start = 0;
		mic_start = 0;
		addr_audio_to_mem = 0;
		audio_req = 0;
		audio_data_to_mem = 16'd0;
		audio_we = 1'b0;
		stopPlaying = 0;
	
		case(state)
			BUTTONUP: begin
				IO_we = 1;
				addr_IO_to_mem = 24'h3FFC; // Write button pressed
				IO_data_to_mem = 4;
			end
			BUTTONDOWN: begin
				IO_we = 1;
				addr_IO_to_mem = 24'h3FFC;
				IO_data_to_mem = 1;
			end
			BUTTONSELECT: begin
				IO_we = 1;
				addr_IO_to_mem = 24'h3FFC;
				IO_data_to_mem = 5;
			end
			FETCHSELECT: begin
					addr_IO_to_mem = 24'h3FFF; // Keep reading in this state. State will change after 128 cycles.
			end
			DECODESELECT: begin
				// DO NOTHING
			end
			PLAYAUDIO: begin
				speaker_start = 1; // keep playing audio while in this state
				addr_audio_to_mem = addr_speaker_to_mem;
				audio_req = speaker_req;
			end
			STARTRECORD: begin
				mic_start = 1;
				addr_audio_to_mem = addr_mic_to_mem;
				audio_req = mic_to_mem_req;
				audio_we = mic_to_mem_we;
				audio_data_to_mem = mic_to_mem_data;
			end	
			STOPPLAY: begin
				stopPlaying = 1; // Write flag to mem to tell core audio is done
				IO_we = 1;
				addr_IO_to_mem = 24'h3FFE;
				IO_data_to_mem = 0;
			end
			STOPRECORD: begin
				stopPlaying = 1;
				IO_we = 1;
				addr_IO_to_mem = 24'h3FFE;
				IO_data_to_mem = 0;
			end
			WAITSTOP: begin
				stopPlaying = 1;
			end
		endcase
	
	end
	
	always@(posedge clk) begin
		if(state == IDLE) begin
			if(button_d[0] == 1) begin
				state <= BUTTONUP;
			end
			else if(button_d[1] == 1) begin
				state <= BUTTONDOWN;
			end
			else if(button_d[2] == 1) begin
				state <= BUTTONSELECT;
			end
		end
		else if(state == BUTTONUP) begin
			state <= IDLE;
		end
		else if(state == BUTTONDOWN) begin
			state <= IDLE;
		end
		else if(state == BUTTONSELECT) begin
			state <= FETCHSELECT;
		end
		else if(state == FETCHSELECT) begin
			waitingCount <= waitingCount + 1'b1;
			if(waitingCount == 127) begin
				state <= DECODESELECT;
			end
		end
		else if(state == DECODESELECT) begin
			if(data_mem_IO == 1) begin
				//NORMAL
				speed <= 1;
				state <= PLAYAUDIO;
			end
			else if(data_mem_IO == 2) begin
				//SLOW
				speed <= 0;
				state <= PLAYAUDIO;
			end
			else if(data_mem_IO == 3) begin
				//FAST
				speed <= 2;
				state <= PLAYAUDIO;
			end
			else if(data_mem_IO == 4) begin
				//RECORD
				state <= STARTRECORD;
			end
			else begin
				state <= IDLE;
			end
		end
		else if(state == PLAYAUDIO) begin
			// Wait until done or stop signal and move state.
			if(button_d[2] == 1) begin
				state <= STOPPLAY;	
			end
			if(audio_done) begin
				state <= STOPPLAY; // Go back to idle once finished reading 
			end
		end
		else if(state == STARTRECORD) begin
			if(addr_mic_to_mem != 0) begin
				stopPosition <= addr_mic_to_mem;
			end
			if(button_d[2] == 1) begin
				state <= STOPRECORD;	
			end
			if(mic_done) begin
				state <= STOPRECORD; 
			end
		end
		else if(state == STOPRECORD) begin
			state <= WAITSTOP;
		end
		else if(state == STOPPLAY) begin
			state <= WAITSTOP;
		end
		else if(state == WAITSTOP) begin
			state <= IDLE;
		end
	
	end

endmodule
