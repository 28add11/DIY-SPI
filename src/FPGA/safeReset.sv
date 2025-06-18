`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2025 08:18:05 PM
// Design Name: 
// Module Name: SafeReset
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


module safeReset(
    input wire clk,
    input wire asyncR,
    output wire safeR
    );
    
    logic q1, q2;
    
    always @(posedge clk or negedge asyncR) begin
    	if (~asyncR) begin
    		q1 <= 1'b0;
 			q2 <= 1'b0;
 		end else begin
 			q1 <= 1'b1;
 			q2 <= q1; 
 		end
    end
    
    assign safeR = q2;
    
endmodule
