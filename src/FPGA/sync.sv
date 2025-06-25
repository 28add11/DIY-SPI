`timescale 1ns / 1ps

module sync #(
		parameter WIDTH = 1
	)(
		input clk,
		input [WIDTH - 1:0] in,
		output [WIDTH - 1:0] out
	);

	logic [WIDTH - 1:0] inSync1, inSync2;
	assign out = inSync2;
	
	always @(posedge clk) begin
		inSync1 <= in;
		inSync2 <= inSync1;
	end
	
endmodule
