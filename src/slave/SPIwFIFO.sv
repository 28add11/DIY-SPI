`timescale 1ns / 1ps
/*
// The core of the SPI slave module.
// Currently just mode 0, echoing back the received data.
*/


module SPIwithFIFO #(
	parameter WIDTH = 8,
	parameter TxFIFODepth = 8,
	parameter RxFIFODepth = 8,
	parameter defaultTXdata = {WIDTH{1'b0}} // Default TX data to send when not writing
	)(
	input clk,
	input rst_n,
    input CS_n,
    input SCLK,
    input MOSI,
    output MISO,
	output [WIDTH - 1:0] RXdata,
	input readEn,
	output RXFIFOempty,
	output RXFIFOfull,
	output TXFIFOempty,
	output TXFIFOfull,
	input [WIDTH - 1:0] TXdata,
	input writeEn
    );
    
	logic CS_nHist; // For falling edge detection (start new transaction)

	logic CS_nFallingEdge;
	assign CS_nFallingEdge = {CS_nHist, CS_n} == 2'b10;

    logic [WIDTH - 1:0] shiftIn;
    logic [WIDTH - 1:0] shiftOut;
    
    assign MISO = shiftOut[WIDTH - 1];
    
    logic [$clog2(WIDTH):0] rxBitCount; // Use extra top bit as a flag for if we've commited the value to the FIFO
	logic [$clog2(WIDTH):0] txBitCount;
    logic prevSCLK;
    
	logic shiftInFull; // Data recive done signal
    assign shiftInFull = rxBitCount == (1 << $clog2(WIDTH));
	logic shiftOutEmpty; // Data send done signal
	assign shiftOutEmpty = txBitCount == 0;

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

	localparam IDLE = 2'b00;
	localparam WAIT_FOR_DATA = 2'b01;
	localparam LOAD_DATA = 2'b10;

	logic readTXFIFO;
	logic [WIDTH - 1:0] TXFIFOdata;
	logic [1:0] TXFIFOReadState;

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
    
    always @ (posedge clk) begin
		CS_nHist <= CS_n;

		if (~rst_n) begin
			shiftIn <= 0;
			shiftOut <= defaultTXdata;
			rxBitCount <= 0;
			txBitCount <= (1 << $clog2(WIDTH));
			prevSCLK <= 0;
			writeRXFIFO <= 1'b0;
			readTXFIFO <= 1'b0;
			TXFIFOReadState <= IDLE;
		end else begin

		// State machine for reading TX FIFO
		case (TXFIFOReadState)
			IDLE: begin
				if (shiftOutEmpty && ~TXFIFOempty && ~CS_nFallingEdge) begin // CS_n check is to avoid double driving, even though it should never really happen
					readTXFIFO <= 1'b1;
					txBitCount <= (1 << $clog2(WIDTH));
					TXFIFOReadState <= WAIT_FOR_DATA;
				end else readTXFIFO <= 1'b0;
			end
			WAIT_FOR_DATA: begin
				TXFIFOReadState <= LOAD_DATA;
				readTXFIFO <= 1'b0;
			end
			LOAD_DATA: begin
				shiftOut <= TXFIFOdata;
				TXFIFOReadState <= IDLE;
			end
			default: TXFIFOReadState <= IDLE;
		endcase

		if (shiftInFull && ~RXFIFOfull && ~CS_nFallingEdge) begin
			writeRXFIFO <= 1'b1;
			rxBitCount <= 0;
		end else begin
			writeRXFIFO <= 1'b0;
		end

    	if (CS_nFallingEdge) begin // Chip becomes selected
    		prevSCLK <= 0;
    		rxBitCount <= 0;
			txBitCount <= (1 << $clog2(WIDTH));

		end else begin
    		prevSCLK <= SCLK;
    		if ({prevSCLK, SCLK} == 2'b01) begin // Rising edge - Data in
    			shiftIn <= {shiftIn[WIDTH - 2:0], MOSI};
    			rxBitCount <= rxBitCount + 1'd1;
    			
    		end else if ({prevSCLK, SCLK} == 2'b10) begin // Falling edge - data out
    			shiftOut <= {shiftOut[WIDTH - 2:0], 1'b0};
				txBitCount <= txBitCount - 1'd1;
    		end
    	end
		end
    end
    
endmodule
