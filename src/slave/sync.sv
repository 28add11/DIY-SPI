`timescale 1ns / 1ps

module sync (
		input clk,
		input in,
		output out
	);

	logic inSync1, inSync2;
	assign out = inSync2;
	
	always @(posedge clk) begin
		inSync1 <= in;
		inSync2 <= inSync1;
	end
	
endmodule
