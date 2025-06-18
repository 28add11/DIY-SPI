`timescale 1ns / 1ps
/*
// The core of the SPI slave module.
// Currently just mode 0
*/


module SPItop #(
	parameter WIDTH = 8
	)(
	input clk,
	input rst_n,
    input CS_n,
    input SCLK,
    input MOSI,
    output MISO,
	output [WIDTH - 1:0] data,
	output full,
	input [WIDTH - 1:0] dataIn,
	input send
    );
    
    logic [WIDTH - 1:0] shiftIn;
    logic [WIDTH - 1:0] shiftOut;
    
    assign MISO = shiftOut[WIDTH - 1];
	assign data = shiftIn;
    
    logic [$clog2(WIDTH) - 1:0] bitCount; // Full signal uses zero because there is no memory to save it in time, so we keep it high
	// Does have issue of first transaction being full, but this is meant to be a base that ISNT actually used
    logic prevSCLK;
    
    assign full = bitCount == {$clog2(WIDTH){1'b0}};
    
    always @ (posedge clk) begin

		if (rst_n) begin
			shiftIn <= {WIDTH{1'b0}};
			shiftOut <= {WIDTH{1'b0}};
			bitCount <= {$clog2(WIDTH){1'b0}};
			prevSCLK <= 0;
		end else begin

		if (send) begin
			shiftOut <= dataIn;
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
    end
    
endmodule
