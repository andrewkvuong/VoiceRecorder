`timescale 1ns / 1ps

module RegFile(
	input 		  clk,
	input 		  write_enable,
	input   [3:0] read_index_1,
	input   [3:0] read_index_2,
	input   [3:0] write_index,
	input  [23:0] write_data,
	output reg [23:0] read_data_1,
	output reg [23:0] read_data_2
    );

	reg [23:0] sp = 0;
	reg [23:0] fp = 0;
	reg [23:0] ra = 0;
	reg [23:0] a0 = 0;
	reg [23:0] a1 = 0;
	reg [23:0] m0 = 0;
	reg [23:0] m1 = 0;
	reg [23:0] rv = 0;
	reg [23:0] v0 = 0;
	reg [23:0] v1 = 0;
	reg [23:0] p0 = 0;
	reg [23:0] p1 = 0;
	reg [23:0] p2 = 0;
	reg [23:0] p3 = 0;
	reg [23:0] p4 = 0;
	
	always@(*) 
	begin
		case(read_index_1)
			0: read_data_1 = 0;
			1: read_data_1 = sp;
			2: read_data_1 = fp;
			3: read_data_1 = ra;
			4: read_data_1 = a0;
			5: read_data_1 = a1;
			6: read_data_1 = m0;
			7: read_data_1 = m1;
			8: read_data_1 = rv;
			9: read_data_1 = v0;
			10: read_data_1 = v1;
			11: read_data_1 = p0;
			12: read_data_1 = p1;
			13: read_data_1 = p2;
			14: read_data_1 = p3;
			15: read_data_1 = p4;
		endcase
	end
	
	always@(*) 
	begin
		case(read_index_2)
			0: read_data_2 = 0;
			1: read_data_2 = sp;
			2: read_data_2 = fp;
			3: read_data_2 = ra;
			4: read_data_2 = a0;
			5: read_data_2 = a1;
			6: read_data_2 = m0;
			7: read_data_2 = m1;
			8: read_data_2 = rv;
			9: read_data_2 = v0;
			10: read_data_2 = v1;
			11: read_data_2 = p0;
			12: read_data_2 = p1;
			13: read_data_2 = p2;
			14: read_data_2 = p3;
			15: read_data_2 = p4;
		endcase
	end
	
	always@(posedge clk)begin
		if(write_enable) begin
			case(write_index)
				1: sp <= write_data;
				2: fp <= write_data;
				3: ra <= write_data;
				4: a0 <= write_data;
				5: a1 <= write_data;
				6: m0 <= write_data;
				7: m1 <= write_data;
				8: rv <= write_data;
				9: v0 <= write_data;
				10: v1 <= write_data;
				11: p0 <= write_data;
				12: p1 <= write_data;
				13: p2 <= write_data;
				14: p3 <= write_data;
				15: p4 <= write_data;
		endcase
	end
	end

endmodule
