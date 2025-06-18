`timescale 1ns / 1ps
/*
// The core of the SPI slave module.
// Currently just mode 0, echoing back the received data.
*/


module SPIFIFOtop#(
	parameter WIDTH = 8,
	parameter TxFIFODepth = 8,
	parameter RxFIFODepth = 8
	)(
	input clk,
    input CS_n,
    input SCLK,
    input MOSI,
	output [WIDTH - 1:0] data,
    output MISO
    );
    
    logic [WIDTH - 1:0] shiftIn;
    logic [WIDTH - 1:0] shiftOut;
    
    assign MISO = shiftOut[WIDTH - 1];
    
    logic [$clog2(WIDTH):0] bitCount; // Extra bit for full signal - Yes we could use 0 but that would fill FIFOs instantly
    logic full;
    logic prevSCLK;
    
    assign full = bitCount == {$clog2(WIDTH){1'b0}};
    
    always @ (posedge clk) begin
    	// Echo
    	if (full) begin
    		shiftOut <= shiftIn;
    		data <= shiftIn;
    	end
    
    	if (CS_n) begin // Chip is not selected
    		prevSCLK <= 0;
    		bitCount <= {$clog2(WIDTH){1'b0}};
    	end else begin
    	
    		prevSCLK <= SCLK;
    		if ({prevSCLK, SCLK} == 2'b01) begin // Rising edge - Data in
    			shiftIn <= {shiftIn[WIDTH - 2:0], MOSI};
    			bitCount <= bitCount + 1'd1;
    			
    		end else if ({prevSCLK, SCLK} == 2'b10) begin // Falling edge - data out
    			shiftOut <= {shiftOut[WIDTH - 2:0], 1'b0};
    		end
    	end
    end
    
endmodule
