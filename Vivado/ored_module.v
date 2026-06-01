`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 12:29:52
// Design Name: 
// Module Name: ored_module
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


module ored_module(clk,pt,key,ct,ot);
    input clk;
    input [7:0] pt;
    input [7:0] key;
    output wire [7:0] ct;
    output wire [7:0] ot;
    
    ore_module ore(clk,pt,key,ct);
    ord_module ord(clk,ct,key,ot);
    
endmodule
