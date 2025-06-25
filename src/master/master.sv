`timescale 1ns / 1ps
/*
// The core of the SPI slave module.
// Currently just mode 0, echoing back the received data.
*/


module SPIMaster #(
	parameter WIDTH = 8,
	parameter TxFIFODepth = 8,
	parameter RxFIFODepth = 8
	)(
	input clk,
	input rst_n,
    output CS_n,
    output SCLK,
    output MOSI,
    input MISO,
	output [WIDTH - 1:0] RXdata,
	input readEn,
	output RXFIFOempty,
	output RXFIFOfull,
	output TXFIFOempty,
	output TXFIFOfull,
	input [WIDTH - 1:0] TXdata,
	input writeEn,
	input startTransaction,
	output doneTransaction,
	input [7:0] prescale1,
	input [7:0] prescale2
	);

	logic [WIDTH - 1:0] shiftIn;
	logic [WIDTH - 1:0] shiftOut;
	logic chipSelect;
	logic SCLKReg;
    
	assign MOSI = shiftOut[WIDTH - 1];
	assign CS_n = chipSelect;
	assign SCLK = SCLKReg;
    
	logic [$clog2(WIDTH):0] bitCount; // Use extra top bit as a flag for if we've commited the value to the FIFO

	localparam IDLE = 3'b000;
	localparam START = 3'b001;
	localparam LOAD_FIFO_DATA = 3'b010;
	localparam SEND_DATA = 3'b011;
	localparam END_TRANSACTION = 3'b100;

	logic [2:0] transactionState;

	logic transactionDone;
	assign transactionDone = bitCount == (1 << $clog2(WIDTH));

	logic doneTransactionReg;
	assign doneTransaction = doneTransactionReg;

	logic writeRXFIFO;

	FIFO #(.WIDTH(WIDTH), .DEPTH(RxFIFODepth)) RXFIFO (
		.clk(clk),
		.rst_n(rst_n),
		.writeData(shiftIn),
		.writeEn(writeRXFIFO),
		.readData(RXdata),
		.readEn(readEn),
		.full(RXFIFOfull),
		.empty(RXFIFOempty)
	);
	
	logic readTXFIFO;
	logic [WIDTH - 1:0] TXFIFOdata;

	FIFO #(.WIDTH(WIDTH), .DEPTH(TxFIFODepth)) TXFIFO (
		.clk(clk),
		.rst_n(rst_n),
		.writeData(TXdata),
		.writeEn(writeEn),
		.readData(TXFIFOdata),
		.readEn(readTXFIFO),
		.full(TXFIFOfull),
		.empty(TXFIFOempty)
	);

	logic SCLKTick;
	logic enSCLK;

	clkPrescale prescaler (
		.clk(clk),
		.rst_n(rst_n),
		.prescaleEn(enSCLK),
		.prescale1(prescale1),
		.prescale2(prescale2),
		.SCLKTick(SCLKTick)
	);
    
    always @ (posedge clk) begin

		if (~rst_n) begin
			shiftIn <= 0;
			shiftOut <= 0;
			chipSelect <= 1'b1;
			SCLKReg <= 1'b0;
			enSCLK <= 1'b0;
			bitCount <= 0;
			writeRXFIFO <= 1'b0;
			readTXFIFO <= 1'b0;
			transactionState <= IDLE;
			doneTransactionReg <= 1;
		end else begin

		// State machine for SPI transaction
		case (transactionState)
			IDLE: begin
				if (startTransaction) begin
					readTXFIFO <= 1'b1;
					transactionState <= START;
					chipSelect <= 1'b0;
					doneTransactionReg <= 0;
				end
			end
			START: begin
				transactionState <= LOAD_FIFO_DATA;
				readTXFIFO <= 1'b0;
			end
			LOAD_FIFO_DATA: begin
				shiftOut <= TXFIFOdata;
				transactionState <= SEND_DATA;
				enSCLK <= 1'b1;
			end
			SEND_DATA: begin
				if (~transactionDone) begin
					if (SCLKTick) begin
						SCLKReg <= ~SCLKReg;
						if (SCLKReg) begin // Falling edge
							shiftOut <= {shiftOut[WIDTH - 2:0], 1'b0};
						end else begin // Rising edge
							shiftIn <= {shiftIn[WIDTH - 2:0], MISO};
							bitCount <= bitCount + 1'd1;
						end
					end

				end else begin // End transaction
					writeRXFIFO <= 1'b1;
					transactionState <= END_TRANSACTION;
				end
			end
			END_TRANSACTION: begin
				writeRXFIFO <= 1'b0;
				if (SCLKTick) begin // Falling edge
					chipSelect <= 1'b1;
					enSCLK <= 1'b0;
					SCLKReg <= 1'b0; // Reset SCLK
					shiftOut <= 0;
					bitCount <= 0;
					doneTransactionReg <= 1;
					transactionState <= IDLE;
				end
			end
			default: transactionState <= IDLE;
		endcase

		end
    end
    
endmodule