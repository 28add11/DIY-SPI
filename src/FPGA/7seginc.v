`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2024 09:13:19 PM
// Design Name: 
// Module Name: 7seginc
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


module sevSeg(
    input clk,
    input [7:0] num,
    output [6:0] seg,
    output dp,
    output [3:0] an
    );
    
    reg digit;
    reg [3:0] bcd;
    reg [15:0] refreshDelay;
    
    // Werid shift to fill end with 1s, as to keep lines high
    assign an = ~(4'b0001 << digit);
    assign seg = (bcd == 4'd0) ? 7'b1000000 :
                 (bcd == 4'd1) ? 7'b1111001 :
                 (bcd == 4'd2) ? 7'b0100100 :
                 (bcd == 4'd3) ? 7'b0000110 :
                 (bcd == 4'd4) ? 7'b0011001 :
                 (bcd == 4'd5) ? 7'b0010010 :
                 (bcd == 4'd6) ? 7'b0000010 :
                 (bcd == 4'd7) ? 7'b1111000 :
                 (bcd == 4'd8) ? 7'b0000000 :
                 (bcd == 4'd9) ? 7'b0010000 :
                 (bcd == 4'd10) ? 7'b0001000 :
                 (bcd == 4'd11) ? 7'b0000011 :
                 (bcd == 4'd12) ? 7'b1000110 :
                 (bcd == 4'd13) ? 7'b0100001 :
                 (bcd == 4'd14) ? 7'b0000110 :
                 (bcd == 4'd15) ? 7'b0001110 : 7'b0000000;
    assign dp = 1'b1;
                 
    always @(posedge clk) begin
        // Digit refresh logic and helps with debounce for register saving
        refreshDelay <= refreshDelay + 1;
        if (refreshDelay == 0) begin
            digit <= ~digit;
        end
        
        // Actually get digit from count
        bcd <= digit ? num[7:4] : num[3:0];
        
    end
    
endmodule
