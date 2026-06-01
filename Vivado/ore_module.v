`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 11:48:02
// Design Name: 
// Module Name: ore_module
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

//module ore_module(clk,pt,ct);
//    input clk;
//    input [7:0] pt;
//    //input [7:0] key;
//    output [7:0] ct;
 
// parameter iv1 = 4'ha;
// parameter iv2 = 4'hb;
// parameter iv3 = 4'hc;
// parameter iv4 = 4'hd;
 
// parameter key1 = 8'haa;
// parameter key2 = 8'hbb;
 
// wire [3:0] p1, p2;
// wire [3:0] k1, k2,k3,k4;
// wire [3:0] sl1,sl2,xl1,xl2,xl3,sl1a,sl2a,xl1a,xl2a,xl3a;
// wire [3:0] sr1,sr2,xr1,xr2,xr3,sr1a,sr2a,xr1a,xr2a,xr3a;
// wire [3:0] c1,c2,c1a,c2a;
 
// //Decompose:first round
// assign p1 = pt[3:0];
// assign p2 = pt[7:4];
 
// assign k1 = key1[3:0];
// assign k2 = key1[7:4];
 

// //Logic- Left-side
// s_box sbox1 (p1, sl1);
// assign xl1 = k1 ^ sl1;
// assign xl2 = iv1 ^ xl1 ^ p2;
// s_box sbox2 (xl2, sl2);
// assign xl3 = k2 ^ sl2;
 
// //Logic- Right-side
// s_box sbox3 (p2, sr1);
// assign xr1 = k2 ^ sr1;
// assign xr2 = iv1 ^ xr1 ^ iv2;
// s_box sbox4 (xr2, sr2);
// assign xr3 = k1 ^ sr2;
 
// assign c1 = xl3;
// assign c2 = xr3;
 
 
 
 
 
// //second round 
// assign k3 = key2[3:0];
// assign k4 = key2[7:4];
 

// //Logic- Left-side
// s_box sbox5 (c1, sl1a);
// assign xl1a = k3 ^ sl1a;
// assign xl2a = iv3 ^ xl1a ^ c2;
// s_box sbox6 (xl2a, sl2a);
// assign xl3a = k4 ^ sl2a;
 
// //Logic- Right-side
// s_box sbox7 (c2, sr1a);
// assign xr1a = k4 ^ sr1a;
// assign xr2a = iv3 ^ xr1a ^ iv4;
// s_box sbox8 (xr2a, sr2a);
// assign xr3a = k3 ^ sr2a;
 
// //swapping
// assign c1a = xr3a;
// assign c2a = xl3a;
 
// //Concatenation for CT 
// assign ct = {c2a,c1a};
 
//endmodule






module ore_module(clk,pt,key,ct);
    input clk;
    input [7:0] pt;
    input [7:0] key;
    output [7:0] ct;
 
 parameter iv1 = 4'ha;
 parameter iv2 = 4'hb;
 
 
 wire [3:0] p1, p2;
 wire [3:0] k1, k2;
 wire [3:0] sl1,sl2,xl1,xl2,xl3;
 wire [3:0] sr1,sr2,xr1,xr2,xr3;
 wire [3:0] c1,c2;
 
 //Decompose:first round
 assign p1 = pt[3:0];
 assign p2 = pt[7:4];
 
 assign k1 = key[3:0];
 assign k2 = key[7:4];
 

 //Logic- Left-side
 s_box sbox1 (p1, sl1);
 assign xl1 = k1 ^ sl1;
 assign xl2 = iv1 ^ xl1 ^ p2;
 s_box sbox2 (xl2, sl2);
 assign xl3 = k2 ^ sl2;
 
 //Logic- Right-side
 s_box sbox3 (p2, sr1);
 assign xr1 = k2 ^ sr1;
 assign xr2 = iv1 ^ xr1 ^ iv2;
 s_box sbox4 (xr2, sr2);
 assign xr3 = k1 ^ sr2;
 
 assign c1 = xr3;
 assign c2 = xl3;

//swapping
assign ct = {c2,c1};

endmodule









