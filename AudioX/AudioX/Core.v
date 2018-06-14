`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:21:27 10/19/2017 
// Design Name: 
// Module Name:    Core 
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
module Core(
	input clk,
	input core_hold,
	output reg[23:0] addr, // Address
	input [15:0] read_data, // Data in and out
	output reg[15:0] write_data,
	output reg write_enable, // read/write enable active hi
	output reg req,
	input sw
    );
	 
	reg		   reg_write_enable;
	reg  [3:0] reg_read_index_1;
	reg  [3:0] reg_read_index_2;
	reg  [3:0] reg_write_index;
	reg [23:0] reg_write_data;
	wire [23:0] reg_read_data_1;
	wire [23:0] reg_read_data_2;
	
	RegFile _RegFile(.clk(clk),
						  .write_enable(reg_write_enable),
						  .read_index_1(reg_read_index_1),
						  .read_index_2(reg_read_index_2),
						  .write_index(reg_write_index),
						  .write_data(reg_write_data),
						  .read_data_1(reg_read_data_1),
						  .read_data_2(reg_read_data_2));
						  
	parameter ADD = 5'b00000;
	parameter SUB = 5'b00001;
	parameter CMP = 5'b00010;
	parameter AND = 5'b00011;
	parameter OR = 5'b00100;
	parameter XOR = 5'b00101;
	parameter MOV = 5'b00110;
	parameter BLT = 5'b00111;
	parameter BLTE = 5'b01000;
	parameter LOAD = 5'b01001;
	parameter STORE = 5'b01010;
	parameter JR = 5'b01011;
	parameter BE = 5'b01100;
	parameter BNE = 5'b01101;
	parameter SHIFTLI = 5'b01110;
	parameter SHIFTRI = 5'b01111;
	parameter INC = 5'b11111;
	parameter ADDI = 5'b10000;
	parameter SUBI = 5'b10001;
	parameter CMPI = 5'b10010;
	parameter ANDI = 5'b10011;
	parameter ORI = 5'b10100;
	parameter XORI = 5'b10101;
	parameter MOVI = 5'b10110;
	parameter LOADI = 5'b10111;
	parameter STOREI = 5'b11000;
	parameter JA = 5'b11001;
	parameter BEI = 5'b11010;
	parameter BNEI = 5'b11011;
	parameter BLTI = 5'b11100;
	parameter BLTEI = 5'b11101;
	parameter JS = 5'b11110;	
	
	parameter FETCH = 0;
	parameter FETCH2 = 1;
	parameter FETCH3 = 2;
	parameter FETCH4 = 3;
	parameter OPERATION = 4;
	parameter BRANCH = 5;
	parameter LOADSTATE = 6;
	parameter STORESTATE = 7;
	parameter I_OPERATION = 8;
	parameter I_BRANCH = 9;
	parameter I_LOAD = 10;
	parameter I_STORE = 11;
	parameter LOADSTATE2 = 12;
	parameter I_LOAD2 = 13;
	parameter STORESTATE2 = 14;
	reg[4:0] state = FETCH;
	
	reg[23:0] PC = 23'h8000;
	reg neg_flag = 0;
	reg zero_flag = 0;
	
	reg[4:0] OPCODE = 0;  
	reg[22:0] immd = 0;
	
	always @ (*) begin
		addr = 0;
		req = 1'b0;
		write_enable = 0;
		reg_write_data = 0;
		write_data = 0;
		reg_write_enable = 0;
		if(!core_hold)
			if(state == FETCH) begin
				req = 1'b1;
				addr = {2'd0, PC};
			end
			else if(state == FETCH2) begin
				//Do nothing
			end
			else if(state == FETCH3) begin
				req = 1'b1;
				addr = {2'd0, PC};
			end
			else if(state == FETCH4) begin
				//Do nothing
			end
			else if(state == OPERATION) begin
				reg_write_enable = 1'b1;
				case(OPCODE)
					ADD: begin
							reg_write_data = reg_read_data_1 + reg_read_data_2;
					end
					SUB: begin
							reg_write_data = reg_read_data_1 - reg_read_data_2;
					end
					CMP: begin
							reg_write_data = reg_read_data_1 - reg_read_data_2;
					end
					AND: begin
							reg_write_data = reg_read_data_1 & reg_read_data_2;
					end
					OR: begin
							reg_write_data = reg_read_data_1 | reg_read_data_2;
					end
					XOR: begin
							reg_write_data = reg_read_data_1 ^ reg_read_data_2;
					end
					MOV: begin
							reg_write_data = reg_read_data_2;
					end
					SHIFTLI: begin
							reg_write_data = reg_read_data_1 << reg_read_index_2;
					end
					SHIFTRI: begin
							reg_write_data = reg_read_data_1 >> reg_read_index_2;
					end
					INC: begin
							reg_write_data = reg_read_data_1 + 1'b1;
					end
				endcase
				if(OPCODE == CMP) begin
					reg_write_enable = 1'b0;
				end
			end
			else if(state == I_BRANCH) begin
				if(OPCODE == JS) begin
						reg_write_data = PC; // PC was incremented in FETCH
						reg_write_enable = 1;
				end
			end
			else if(state == LOADSTATE) begin
				req = 1'b1;
				addr = {2'b00, reg_read_data_2}; // Get addr from reg 2
			end
			else if(state == LOADSTATE2) begin
				reg_write_data = read_data; // Place data into reg 1 
				reg_write_enable = 1;
			end
			else if(state == I_LOAD) begin
				req = 1'b1;
				addr = {3'b000, immd};
			end
			else if(state == I_LOAD2) begin
				reg_write_data = read_data;
				reg_write_enable = 1;
			end
			else if(state == STORESTATE) begin
				req = 1'b1;
				write_enable = 1;
				addr = {2'b00, reg_read_data_2};
				write_data = reg_read_data_1[15:0];
			end 
			else if(state == STORESTATE2) begin
				// not needed?
			end
			else if(state == I_STORE) begin
				req = 1'b1;
				addr = {3'b00, immd};
				write_data = reg_read_data_1[15:0];
				write_enable = 1;
			end
			else if(state == I_OPERATION) begin
				reg_write_enable = 1'b1;
				case(OPCODE)
					ADDI: begin
							reg_write_data = reg_read_data_1 + immd;
					end
					SUBI:begin
							reg_write_data = reg_read_data_1 - immd;
					end
					CMPI: begin
							reg_write_data = reg_read_data_1 - immd;
					end
					ANDI: begin
							reg_write_data = reg_read_data_1 & immd;
					end
					ORI: begin
							reg_write_data = reg_read_data_1 | immd;
					end
					XORI: begin
							reg_write_data = reg_read_data_1 ^ immd;
					end
					MOVI: begin
							reg_write_data = immd;
					end
				endcase
				if(OPCODE == CMPI) begin
					reg_write_enable = 1'b0;
				end
			end
	end
	
	
	// Clock
	always @ (posedge clk) begin
		if(!core_hold)
			if(state == FETCH && sw) begin
				state <= FETCH2;
				PC <= PC + 1'b1;
			end
			else if(state == FETCH2) begin
					OPCODE = read_data[15:11];
					reg_read_index_1 <= read_data[10:7];
					reg_read_index_2 <= read_data[6:3];
					reg_write_index <= read_data[10:7];
					immd[22:16] <= read_data[6:0];
					if(OPCODE == INC || OPCODE <= MOV || OPCODE == SHIFTLI || OPCODE == SHIFTRI) begin
						state <= OPERATION;
					end
					else if(OPCODE[4] == 1'b1) begin // it's a 2-word instruction
						state <= FETCH3;
					end
					else if(OPCODE == LOAD) begin
						state <= LOADSTATE;
					end
					else if(OPCODE == STORE) begin
						state <= STORESTATE;
					end
					else begin
						state <= BRANCH;
					end
			end
			else if(state == OPERATION || state == I_OPERATION) begin
				if(reg_write_data == 0) begin
					zero_flag <= 1; 
				end
				else begin
					zero_flag <= 0;
				end
				
				if(reg_write_data[23] == 1'b1) begin
					neg_flag <= 1;
				end
				else begin
					neg_flag <= 0;
				end
				state <= FETCH;
			end
			else if(state == BRANCH) begin
				case(OPCODE)
					BLT: begin
						if(neg_flag) 
							PC <= reg_read_data_1;
					end
					BLTE: begin
						if(neg_flag || zero_flag) 
							PC <= reg_read_data_1;
					end
					JR: begin
						PC <= reg_read_data_1;
					end
					BE: begin
						if(zero_flag)
							PC <= reg_read_data_1;
					end
					BNE: begin
						if(!zero_flag) 
							PC <= reg_read_data_1;
					end
				endcase
				state <= FETCH;
			end 
			else if(state == I_BRANCH) begin
				case(OPCODE)
					BLTI: begin
						if(neg_flag) 
							PC <= immd;
					end
					BLTEI: begin
						if(neg_flag || zero_flag) 
							PC <= immd;
					end
					JA: begin
						PC <= immd;
					end
					JS: begin
						PC <= immd;
					end
					BEI: begin
						if(zero_flag)
							PC <= immd;
					end
					BNEI: begin
						if(!zero_flag) 
							PC <= immd;
					end
				endcase
				state <= FETCH;
			end
			else if(state == STORESTATE) begin
				state <= STORESTATE2;
			end
			else if(state == STORESTATE2) begin
				state <= FETCH;
			end
			else if(state == I_STORE) begin
				state <= FETCH;
			end
			else if(state == LOADSTATE) begin
				state <= LOADSTATE2;
			end
			else if(state == LOADSTATE2) begin
				state <= FETCH;
			end
			else if(state == I_LOAD) begin
				state <= I_LOAD2;
			end
			else if(state == I_LOAD2) begin
				state <= FETCH;
			end
			else if(state == FETCH3) begin
				state <= FETCH4;
				PC <= PC + 1'b1;
			end
			else if(state == FETCH4) begin
				immd[15:0] <= read_data;
				if(OPCODE <= MOVI) 
					state <= I_OPERATION;
				else if(OPCODE == LOADI)
					state <= I_LOAD;
				else if(OPCODE == STOREI)
					state <= I_STORE;
				else begin
					if(OPCODE == JS) 
						reg_write_index <= 4'd3;
					state <= I_BRANCH; 
				end
			end
	end
endmodule
