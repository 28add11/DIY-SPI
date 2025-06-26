`timescale 1ns / 1ps
/*
// Clock prescaler for SPI master module.
// Simply counts then toggles.
*/

module clkPrescale (
		input clk,
		input rst_n,
		input prescaleEn,
		input [7:0] prescale1,
		input [7:0] prescale2,
		output SCKTick
	);

	logic [7:0] count1, count2;
	logic SCKTickReg;

	assign SCKTick = SCKTickReg;

	always @(posedge clk) begin
		if (~rst_n) begin
			count1 <= 0;
			count2 <= 0;
			SCKTickReg <= 0;
		end else begin
		
		if (~prescaleEn) begin
			count1 <= 0;
			count2 <= 0;
			SCKTickReg <= 0;
		end else begin

			if (count1 == prescale1) begin // 512 counts for 1 clock cycle
				count1 <= 0;

				if (count2 == prescale2) begin
					count2 <= 0;
					SCKTickReg <= 1;
				end else begin
					SCKTickReg <= 0;
					count2 <= count2 + 1;
				end

			end else begin
				SCKTickReg <= 0;
				count1 <= count1 + 1;
			end

			

		end
		end
	end
	
endmodule
