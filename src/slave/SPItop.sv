`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/14/2025 10:54:48 AM
// Design Name: 
// Module Name: SPItop
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


module SPItop(
	input clk,
    input CS_n,
    input SCLK,
    input MOSI,
	output [7:0] num,
    output MISO
    );
    
    logic [7:0] shiftIn;
    logic [7:0] shiftOut;
    logic [7:0] data;
    
    assign num = data;
    
    assign MISO = shiftOut[7];
    
    logic [2:0] bitCount;
    logic full;
    logic prevSCLK;
    
    assign full = bitCount == 3'd0;
    
    always @ (posedge clk) begin
    	// Echo
    	if (full) begin
    		shiftOut <= shiftIn;
    		data <= shiftIn;
    	end
    
    	if (CS_n) begin // Chip is not selected
    		prevSCLK <= 0;
    		bitCount <= 3'b0;
    	end else begin
    	
    		prevSCLK <= SCLK;
    		if ({prevSCLK, SCLK} == 2'b01) begin // Rising edge - Data in
    			shiftIn <= {shiftIn[6:0], MOSI};
    			bitCount <= bitCount + 1'd1;
    			
    		end else if ({prevSCLK, SCLK} == 2'b10) begin // Falling edge - data out
    			shiftOut <= {shiftOut[6:0], 1'b0};
    		end
    	end
    end
    
endmodule
