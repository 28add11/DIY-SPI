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
	input rst,
	input [1:0] sw,
	output [1:0] led,
    input CS_n,
    input SCLK,
    input MOSI,
    output MISO,
    output [6:0] seg,
    output dp,
    output [3:0] an
    );

	logic rst_n;
	safeReset synchReset (
		.clk(clk),
		.asyncR(~rst),
		.safeR(rst_n)
	);


	logic sCS_n, sSCLK, sMOSI, sSw0, sSw1;

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
	sync syncSw0 (
		.clk(clk),
		.in(sw[0]),
		.out(sSw0)
	);
	sync syncSw1 (
		.clk(clk),
		.in(sw[1]),
		.out(sSw1)
	);


	logic fullHist; // For rising edge detection (new sample)
	logic full, send, RXFIFOempty, RXFIFOfull, TXFIFOempty, TXFIFOfull;
	logic readRXFIFO;
	logic readRXFIFOReg;
	logic [7:0] noFIFOdata, FIFOdata, dataIn;
	logic [7:0] returnData;
	logic fifoMISO, noFIFOMISO;
	assign MISO = sSw0 ? fifoMISO : noFIFOMISO;

	assign readRXFIFO = readRXFIFOReg & ~RXFIFOempty;

	SPInoFIFO #(.WIDTH(8)) spi (
		.clk(clk),
		.rst_n(rst_n),
		.CS_n(sCS_n),
		.SCLK(sSCLK),
		.MOSI(sMOSI),
		.MISO(noFIFOMISO),
		.data(noFIFOdata),
		.full(full),
		.dataIn(returnData),
		.writeEn(send)
	);

	SPIwithFIFO fifoSPI (
		.clk(clk),
		.rst_n(rst_n),
		.CS_n(sCS_n),
		.SCLK(sSCLK),
		.MOSI(sMOSI),
		.MISO(fifoMISO),
		.RXdata(FIFOdata),
		.readEn(readRXFIFO),
		.RXFIFOempty(RXFIFOempty),
		.RXFIFOfull(RXFIFOfull),
		.TXFIFOempty(TXFIFOempty),
		.TXFIFOfull(TXFIFOfull),
		.TXdata(returnData),
		.writeEn(send)
	);

	// Using switch as selector for if we want to use the FIFO or not
	assign dataIn = sSw0 ? FIFOdata : noFIFOdata;
	assign returnData = dataIn; // Echo the input

	assign led[0] = sSw0 ? RXFIFOempty : 1'b0; 
	assign led[1] = sSw0 ? TXFIFOempty : 1'b0;

	always @(posedge clk) begin
		if (~sSw0) begin // No fifo

		fullHist <= full;

		if ({fullHist, full} == 2'b01) begin // Rising edge, pulse
			send <= 1'b1;
		end else begin
			send <= 1'b0;
		end

		end else begin // FIFO
			if (~RXFIFOempty) begin
				readRXFIFOReg <= 1'b1; // 1 cycle read latency, write after that to echo
				send <= 1'b0;
			end else if (~TXFIFOfull && readRXFIFOReg) begin
				readRXFIFOReg <= 1'b0;
				send <= 1'b1;
			end else begin
				send <= 1'b0;
				readRXFIFOReg <= 1'b0;
			end
		end
	end


	// 7-segment display decoder
	sevSeg display (
		.clk(clk),
		.num(dataIn),
		.seg(seg),
		.dp(dp),
		.an(an)
	);

endmodule
