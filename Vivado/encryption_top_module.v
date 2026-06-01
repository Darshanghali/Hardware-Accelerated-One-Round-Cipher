`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.09.2025 12:56:41
// Design Name: 
// Module Name: encryption_top_module
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


module encryption_top_module(clk,pt,ct);
input clk;
input [23:0]pt;
output reg [23:0]ct;

//always @(*)
//begin 
//    assign ct = pt;
//end

//wire [7:0] ct1,ct2,ct3;
//assign ct1 = ct[7:0];
//assign ct2 = ct[15:8];
//assign ct3 = ct[23:16];

//encryption_top enc1(.clk(clk),.pt(ct1));
//encryption_top enc2(.clk(clk),.pt(ct2));
//encryption_top enc3(.clk(clk),.pt(ct3));
endmodule
