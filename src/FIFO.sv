`timescale 1ns / 1ps
/*
// FIFO for SPI slave module.
// Uses BRAM inference for Xilinx 7-series FPGAs.
// If there is a more flexible definition of BRAM, let me know and I will implement it.
*/

module FIFO #(
	parameter WIDTH = 8,
	parameter DEPTH = 8
	)(
	input clk,
	input rst_n,
	input [WIDTH - 1:0] writeData,
	input writeEn,
	output [WIDTH - 1:0] readData,
	input readEn,
	output full,
	output empty
	);

	logic [WIDTH - 1:0] readDataReg;

	assign readData = readDataReg;
	
	// Use extra bit for full and empty detection
	// If they are totally equal then registers are empty
	// But if one wraps around then [$clog2(DEPTH) - 1:0] bits are equal and top bit is different
	logic [$clog2(DEPTH):0] readPtr, writePtr;
	logic [WIDTH - 1:0] mem [DEPTH - 1:0];

	assign full = (writePtr[$clog2(DEPTH) - 1:0] == readPtr[$clog2(DEPTH) - 1:0]) && (writePtr[$clog2(DEPTH)] != readPtr[$clog2(DEPTH)]);
	assign empty = writePtr == readPtr;

	always @(posedge clk) begin

		if (~rst_n) begin
			readPtr <= 0;
			writePtr <= 0;
			readDataReg <= 0;
		end else begin

		if (writeEn) begin // user's responsibility to not write when full
			writePtr <= writePtr + 1;
			mem[writePtr[$clog2(DEPTH) - 1:0]] <= writeData;
		end
		
		if (readEn) begin
			readPtr <= readPtr + 1;
			readDataReg <= mem[readPtr[$clog2(DEPTH) - 1:0]];
		end
		end
	end
	
endmodule
