`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.09.2025 17:52:23
// Design Name: 
// Module Name: rgb_combine
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


module rgb_combine(r_value,g_value,b_value,rgb_value);
input [7:0] r_value, g_value, b_value;
output [23:0] rgb_value;

assign rgb_value = {r_value, g_value, b_value};
endmodule
