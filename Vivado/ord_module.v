`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 12:10:11
// Design Name: 
// Module Name: ord_module
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


module ord_module(clk,ct,key,pt);
    input clk;
    input  [7:0] ct;
    input  [7:0] key;
    output [7:0] pt;

parameter iv1 = 4'ha;
parameter iv2 = 4'hb;

 wire [3:0] c1, c2;
 wire [3:0] k1, k2;
 wire [3:0] xl1,xl2,xl3,sl1,sl2;
 wire [3:0] xr1,xr2,xr3,sr1,sr2;
 wire [3:0] p1,p2;

 //Decompose:
 assign c1 = ct[3:0];
 assign c2 = ct[7:4];
 
 assign k1 = key[3:0];
 assign k2 = key[7:4];


//LHS Logic
assign xl1 = c1 ^ k1;
inv_s_box sbox1(xl1,sl1);
assign xl2 = sl1 ^ iv1 ^ iv2;
assign xl3 = xl2 ^ k2;
inv_s_box sbox2(xl3,sl2);

//RHS Logic
assign xr1 = c2 ^ k2;
inv_s_box sbox3(xr1,sr1);
assign xr2 = sr1 ^ iv1 ^ sl2;
assign xr3 = xr2 ^ k1;
inv_s_box sbox4(xr3,sr2);

//assigning output values
assign p1 = sl2;
assign p2 = sr2;

assign pt = {p1,p2};
endmodule
