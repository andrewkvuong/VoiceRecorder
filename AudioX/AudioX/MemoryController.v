`timescale 1ns / 1ps

module MemoryController(
	input core_clk,
	input req,
	input[23:0] core_addr,
	input[15:0] core_write_data,
	input core_write_enable,
	output reg[15:0] core_read_data,
	output reg hold_core,
	
	// To board
	inout[15:0] cellular_data,
	output reg cellular_we,
	output reg cellular_oe,
	output reg[23:0] cellular_addr,
	output reg cellular_cs,
	output reg cellular_adv,
	
	// To Graphics module
	input vga_clk,
	input [13:0] addr_vga_to_mem,
	output [15:0] data_mem_to_vga	,
	
	
	// To audio module
	input [23:0] addr_audio_to_mem,
	output reg [15:0] data_mem_to_audio,
	input [15:0] audio_data_to_mem,
	input audio_req,
	input audio_we,
	output reg audio_data_ready,
	
	// to IO module
	input [13:0] addr_IO_to_mem,
	output [15:0] data_mem_to_IO,
	input [15:0] IO_data_to_mem,
	input IO_we
   );
	 
	initial cellular_addr = 26'd0;
	
	// Wires for block ram data and we
	reg[15:0] savedWriteData;
	wire block_we;
	wire block2_we;
	wire[15:0] block_data;
	wire[15:0] block2_data;
	
	// Modify core address for second RAM
	wire[25:0] core_addr_RAM2;
	assign core_addr_RAM2 = core_addr - 26'h4000;
	
	assign block_we = ((state < 2 || state == 11) || audio_req_reg) && core_write_enable && ~cellularReq && ~block2 ? 1'b1 : 1'b0;
	assign block2_we =((state < 2 || state == 11) || audio_req_reg) && core_write_enable && ~cellularReq && block2 ? 1'b1 : 1'b0;
	
	BlockRam _BlockRam(.addra(addr_vga_to_mem), .dina(16'd0), .wea(1'b0), .clka(vga_clk), .douta(data_mem_to_vga),
							 .addrb(core_addr[13:0]), .dinb(core_write_data), .web(block_we), .clkb(core_clk), .doutb(block_data));
							 
	AudioRam _AudioRam(.addra(core_addr_RAM2[13:0]), .dina(core_write_data), .wea(block2_we), .clka(core_clk), .douta(block2_data),
							 .addrb(addr_IO_to_mem[13:0]), .dinb(IO_data_to_mem), .web(IO_we), .clkb(core_clk), .doutb(data_mem_to_IO));
	

	// If cellular_we is active, assign the write line.
	assign cellular_data = (state > 1 && state != 11) && ~cellular_we ? savedWriteData : 16'bz;
	
	 
	// Registers to latch values from outside
	reg cellularReq;
	reg core_we;
	reg audio_req_reg;
	reg block2;
	reg block2_ret;
	 
	// State 0: Block Ram Ready
	// State 1: Cellular Ram Ready
	// State 11: Cellular RAM for audio
	reg[3:0] state = 0;
	always@(*)begin
		hold_core = 1'b1;
		core_read_data = 0;
		cellularReq = 0;
		audio_data_ready = 0;
		data_mem_to_audio = 0;
		block2 = 0;
		
		// don't hold core if the audio is using cellular ram.
		if(audio_req_reg) begin
			hold_core = 1'b0;
		end
		
		//If in state where data is ready and ready to issue next request
		if(state == 0 || state == 1 || state == 11 || audio_req_reg) begin	
			hold_core = 1'b0;
			
			// Return Data
			if(state == 1) begin
				core_read_data = cellular_data;
			end
			else if(block2_ret) begin
				core_read_data = block2_data;
			end
			else begin
				core_read_data = block_data;
			end
			
			if(state == 11) begin
				data_mem_to_audio = cellular_data;
				audio_data_ready = 1;
			end
			
			// Check if we should go to block RAM or cellular RAM.
			if(core_addr > 26'h7FFF && !audio_req) begin
					cellularReq = 1'b1;
			end
			else if(core_addr > 26'h3FFF) begin
					block2 = 1;
			end
			else begin
					cellularReq = 1'b0;
			end
		end
	end
	 
	always@(posedge core_clk)begin
		if(block2) begin
			block2_ret <= 1'b1;
		end
		else
			block2_ret <= 0;
		case(state) 
			0: begin
				cellular_oe <= 1; // Turn both off
				cellular_cs <= 1;
				cellular_we <= 1;
				cellular_adv <= 1;
				audio_req_reg <= 0;
				if(block2) begin
					block2_ret <= 1'b1;
				end
				else
					block2_ret <= 0;
				if((req && cellularReq) || audio_req) begin
					if(audio_req) begin
						audio_req_reg <= 1;
						cellular_addr <= addr_audio_to_mem;
						core_we <= audio_we;
						savedWriteData <= audio_data_to_mem;
						cellular_oe <= audio_we;
					end
					else begin
						audio_req_reg <= 0;
						cellular_addr <= core_addr;
						core_we <= core_write_enable;
						savedWriteData <= core_write_data;
						cellular_oe <= core_write_enable;
					end
					state <= 4'd2;
					cellular_we <= 1'b1; // Turn write enable off 
					cellular_cs <= 1'b0;
					cellular_adv <= 0;
				end
			end
			1: begin
				cellular_oe <= 1; // Turn both off
				cellular_cs <= 1;
				cellular_we <= 1;
				cellular_adv <= 1;
				audio_req_reg <= 0;
				if(block2) begin
					block2_ret <= 1'b1;
				end
				else
					block2_ret <= 0;
				if((req && cellularReq) || audio_req) begin
					if(audio_req) begin
						audio_req_reg <= 1;
						cellular_addr <= addr_audio_to_mem;
						core_we <= audio_we;
						savedWriteData <= audio_data_to_mem;
						cellular_oe <= audio_we;
					end
					else begin
						audio_req_reg <= 0;
						cellular_addr <= core_addr;
						core_we <= core_write_enable;
						savedWriteData <= core_write_data;
						cellular_oe <= core_write_enable;
					end
					state <= 4'd2;
					cellular_we <= 1'b1; // Turn write enable off 
					cellular_cs <= 1'b0;
					cellular_adv <= 0;
				end
				else begin
					state <= 4'd0;
				end
			end
			11: begin
				cellular_oe <= 1; // Turn both off
				cellular_cs <= 1;
				cellular_we <= 1;
				cellular_adv <= 1;
				audio_req_reg <= 0;
				if(block2) begin
					block2_ret <= 1'b1;
				end
				else
					block2_ret <= 0;
				if((req && cellularReq) || audio_req) begin
					if(audio_req) begin
						audio_req_reg <= 1;
						cellular_addr <= addr_audio_to_mem;
						core_we <= audio_we;
						savedWriteData <= audio_data_to_mem;
						cellular_oe <= audio_we;
					end
					else begin
						audio_req_reg <= 0;
						cellular_addr <= core_addr;
						core_we <= core_write_enable;
						savedWriteData <= core_write_data;
						cellular_oe <= core_write_enable;
					end
					state <= 4'd2;
					cellular_we <= 1'b1; // Turn write enable off 
					cellular_cs <= 1'b0;
					cellular_adv <= 0;
				end
				else begin
					state <= 4'd0;
				end
			end
			2: begin
				state <= state + 1'b1;
				cellular_we <= !core_we;
			end
			3:
				state <= state + 1'b1;
			4:
				state <= state + 1'b1;
			5:
				state <= state + 1'b1;
			6:
				state <= state + 1'b1;
			7:
				state <= state + 1'b1;
			8:
				state <= state + 1'b1;
			9:
				state <= state + 1'b1;
			10: begin
				if(audio_req_reg)
					state <= 11;
				else
					state <= 1;
				end
		endcase
	end


endmodule
