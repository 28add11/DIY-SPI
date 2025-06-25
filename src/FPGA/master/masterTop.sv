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


module masterTop(
    input clk,
	input rst,
	output [1:0] led,
    output CS_n,
    output SCLK,
    output MOSI,
    input MISO,
	input [15:0] sw
    );

	logic rst_n;
	safeReset synchReset (
		.clk(clk),
		.asyncR(~rst),
		.safeR(rst_n)
	);

	logic sMISO;
	logic [15:0] swSync;

	// Input synchronizer
	sync syncMISO (
		.clk(clk),
		.in(MISO),
		.out(sMISO)
	);

	sync #(.WIDTH(16)) syncSW (
		.clk(clk),
		.in(sw),
		.out(swSync)
	);


	logic RXFIFOempty, RXFIFOfull, TXFIFOempty, TXFIFOfull;
	logic startTransaction;
	logic doneTransaction;
	logic writeTXFIFOReg;
	logic readRXFIFO, writeTXFIFO;
	logic [7:0] dataIn;
	logic [7:0] dataOut;

	assign writeTXFIFO = writeTXFIFOReg && ~TXFIFOfull;

	SPIMaster SPI (
		.clk(clk),
		.rst_n(rst_n),
		.CS_n(CS_n),
		.SCLK(SCLK),
		.MOSI(MOSI),
		.MISO(sMISO),
		.RXdata(dataIn),
		.readEn(readRXFIFO),
		.RXFIFOempty(RXFIFOempty),
		.RXFIFOfull(RXFIFOfull),
		.TXFIFOempty(TXFIFOempty),
		.TXFIFOfull(TXFIFOfull),
		.TXdata(dataOut),
		.writeEn(writeTXFIFO),
		.startTransaction(startTransaction),
		.doneTransaction(doneTransaction),
		.prescale1(swSync[7:0]),
		.prescale2(swSync[15:8])
	);

	logic dataGood;
	logic [7:0] RXDataCheck;
	logic [1:0] RXDataCheckState;
	logic [16:0] dataSendTimer; // Delay between transactions
	logic sendState;

	localparam IDLE = 1'b0;
	localparam SEND = 1'b1;

	localparam RXIDLE = 2'b00;
	localparam RXLOAD = 2'b01;
	localparam RXCHECK = 2'b10;

	assign led[0] = dataGood; 
	assign led[1] = 1'b0; // Because I am too lazy to change constraints file

	always @(posedge clk) begin
		if (~rst_n) begin
			dataGood <= 1'b1;
			dataOut <= 8'h00;
			writeTXFIFOReg <= 1'b0;
			readRXFIFO <= 1'b0;
			startTransaction <= 1'b0;
			dataSendTimer <= 0;
			sendState <= SEND; // Start with delay
			RXDataCheck <= 8'd0;
			RXDataCheckState <= RXIDLE;
		end else begin

		if (~TXFIFOfull) begin // Generate data
			writeTXFIFOReg <= 1'b1; // 1 cycle read latency, write after that to echo
		end else begin 
			writeTXFIFOReg <= 1'b0;
		end
		if (writeTXFIFO) begin // Signal, not reg to correctly handle end of data gen
			dataOut <= dataOut + 1; // Delay for 1 cycle
		end

		case (sendState) //Send data
			IDLE: begin
					if (~TXFIFOempty) begin
					startTransaction <= 1'b1;
					sendState <= SEND;
				end
			end
			SEND: begin
				startTransaction <= 1'b0;
				if (doneTransaction) begin
					dataSendTimer <= dataSendTimer + 1;
				end
				if (dataSendTimer == 17'h1FFFF) begin
					dataSendTimer <= 0;
					sendState <= IDLE;
				end
			end
			default: sendState <= IDLE;
		endcase

		case (RXDataCheckState)
			RXIDLE: begin
				if (~RXFIFOempty) begin // Read data and validate
					readRXFIFO <= 1'b1;
					RXDataCheckState <= RXLOAD;
				end
			end 
			RXLOAD: begin
				readRXFIFO <= 0;
				RXDataCheckState <= RXCHECK;
			end
			RXCHECK: begin
				if (dataIn != RXDataCheck) begin
					dataGood <= 1'b0;
				end else begin
					dataGood <= 1'b1;
				end
				RXDataCheck <= RXDataCheck + 1;
				RXDataCheckState <= RXIDLE;
			end
			default: RXDataCheckState <= RXIDLE;
		endcase
		

		end
	end

endmodule
