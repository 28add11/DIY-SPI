`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2025 03:11:43 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input clk,
    input CS_n,
    input SCLK,
    input MOSI,
    output MISO,
    output [6:0] seg,
    output dp,
    output [3:0] an
    );

	logic [7:0] num;
	logic sCS_n, sSCLK, sMOSI;

	// Input synchronizer
	sync syncCS (
		.clk(clk),
		.in(CS_n),
		.out(sCS_n)
	);
	sync syncSCLK (
		.clk(clk),
		.in(SCLK),
		.out(sSCLK)
	);
	sync syncMOSI (
		.clk(clk),
		.in(MOSI),
		.out(sMOSI)
	);



	SPItop spi (
		.clk(clk),
		.CS_n(sCS_n),
		.SCLK(sSCLK),
		.MOSI(sMOSI),
		.MISO(MISO),
		.num(num)
	);

	// 7-segment display decoder
	sevSeg display (
		.clk(clk),
		.num(num),
		.seg(seg),
		.dp(dp),
		.an(an)
	);

endmodule
