`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.09.2025 17:49:16
// Design Name: 
// Module Name: rgb_split
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


module rgb_split(rgb_value,r_value,g_value,b_value);
input [23:0] rgb_value;
output [7:0] r_value, g_value, b_value;

assign r_value = rgb_value [23:16];
assign g_value = rgb_value [15:8];
assign b_value = rgb_value [7:0];

endmodule
