`timescale 1ns / 1ps

module Top(
	input clk,
	output[23:0] MemAdr, // Address
	inout[15:0] MemDB, // Data in and out for ceulluar ram
	output MemWR, // read/write enable active low
	output MemOE, // Output buffer enable 
	output MemAdv, // Constant
	output MemClk, // Constant
	output RamCS, // Constant
	output RamCRE,  // Constant
	output RamUB,   // Constant
	output RamLB,   // Constant
	output FlashRp, // Constant
	output FlashCS,  // Constant
	
	input sw,
	output hsync,
	output vsync,
	output [7:0] vga_color,
	
	// Speaker
	output [3:0] JA,
	input [2:0] buttons,
	
	// Mic
	input SDATA,
	output SCLK,
	output CSN
   );
	 
	parameter ADDR_WIDTH = 24;
	
	// Core
	wire req;
	wire core_hold;
	
	wire[23:0] core_addr;
	wire[15:0] core_read_data;
	wire[15:0] core_write_data;
	wire write_enable;
	
	// VGA
	wire vga_clk;
	wire [15:0] data_mem_to_vga;
	wire [13:0] addr_vga_to_mem;

	assign vga_clk = clk;
	
	// Audio
	wire [15:0] data_mem_to_audio;
	wire [23:0] addr_audio_to_mem;
	wire audio_we;
	wire[15:0] audio_data_to_mem;
	
	// RAM Constants
	assign MemClk = 0; // Clock 
	assign RamCRE = 0; // active high
	assign RamUB = 0; // Upper bit enable. 
	assign RamLB = 0; // Lower bit enable.
	
	assign FlashRp = 1; 
	assign FlashCS = 1;
	
	// IO 
	wire audio_req;
	wire audio_data_ready;
	
	wire[13:0] addr_IO_to_mem;
	wire[15:0] data_mem_to_IO;
	wire[15:0] IO_data_to_mem;
	wire IO_we;
	
	
	MemoryController _MemoryController(
		.core_clk(clk),
		.cellular_data(MemDB),
		.cellular_we(MemWR),
		.cellular_oe(MemOE),
		.cellular_addr(MemAdr),
		.cellular_cs(RamCS),
		.cellular_adv(MemAdv),
		.req(req),
		.hold_core(core_hold),
		.core_addr(core_addr),
		.core_read_data(core_read_data),
		.core_write_data(core_write_data),
		.core_write_enable(write_enable),
		.vga_clk(vga_clk),
		.data_mem_to_vga(data_mem_to_vga),
		.addr_vga_to_mem(addr_vga_to_mem),
		.addr_audio_to_mem(addr_audio_to_mem),
		.data_mem_to_audio(data_mem_to_audio),
		.audio_data_to_mem(audio_data_to_mem),
		.audio_we(audio_we),
		.audio_req(audio_req),
		.audio_data_ready(audio_data_ready),
		.addr_IO_to_mem,
		.data_mem_to_IO,
		.IO_data_to_mem,
		.IO_we
		);
												  
	
	Core _Core(
		.clk(clk),
		.core_hold(core_hold),
		.addr(core_addr),
		.read_data(core_read_data),
		.write_data(core_write_data),
		.write_enable(write_enable),
		.req(req),
		.sw(sw)
		);
	 
				  
	Graphics _Graphics(
		.clk(vga_clk),
		.data_mem_to_vga(data_mem_to_vga), 
		.addr_vga_to_mem(addr_vga_to_mem),
		.hsync(hsync),
		.vsync(vsync),
		.color(vga_color)
		);
		
	IOController _IOController(
		.clk(clk), 
		.data_mem_audio(data_mem_to_audio),
		.addr_audio_to_mem(addr_audio_to_mem),
		.audio_data(JA[0]),
		.NC(JA[2]),
		.gain(JA[1]),
		.stop(JA[3]),
		.audio_we(audio_we),
		.audio_data_to_mem(audio_data_to_mem),
		.audio_req(audio_req),
		.audio_data_ready(audio_data_ready),
		.button(buttons),
		.addr_IO_to_mem(addr_IO_to_mem),
		.IO_we(IO_we),
		.IO_data_to_mem(IO_data_to_mem),
		.data_mem_IO(data_mem_to_IO),
		.mic_sdata(SDATA),					// Incoming serial data from microphone			
		.mic_cs_n(CSN),					// Outgoing signal to microphone to start communication
		.mic_sclk(SCLK)					// Outgoing serial clock to mic to regulate communication
		);
		
endmodule
