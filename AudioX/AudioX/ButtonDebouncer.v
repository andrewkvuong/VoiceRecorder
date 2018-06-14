`timescale 1ns / 1ps

module ButtonDebouncer(input clk, input button, output reg debounced
    );

		reg[16:0] counter;
	reg[16:0] sampled;
	reg buttonPressed;

	always @ (posedge clk) begin
		debounced <= 0;
		counter <= counter + 1'b1;
		if(button)
			sampled <= sampled + 1'b1;
		if(counter == 100000) begin
			counter <= 0;
			sampled <= 0;
			if(sampled >= 50000 && buttonPressed == 0) begin
				debounced <= 1;
				buttonPressed <= 1;
			end
			else if(sampled < 50000 && buttonPressed == 1) begin
				debounced <= 0;
				buttonPressed <= 0;
			end
		end
	end

endmodule
