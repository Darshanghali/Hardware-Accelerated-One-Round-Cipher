//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.1 (win64) Build 2902540 Wed May 27 19:54:49 MDT 2020
//Date        : Sun Nov 16 18:54:41 2025
//Host        : LAPTOP-DAM1RJPD running 64-bit major release  (build 9200)
//Command     : generate_target ored_ip_wrapper.bd
//Design      : ored_ip_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ored_ip_wrapper
   (clk,
    out_ct,
    out_pt,
    rst);
  input clk;
  output [23:0]out_ct;
  output [23:0]out_pt;
  input rst;

  wire clk;
  wire [23:0]out_ct;
  wire [23:0]out_pt;
  wire rst;

  ored_ip ored_ip_i
       (.clk(clk),
        .out_ct(out_ct),
        .out_pt(out_pt),
        .rst(rst));
endmodule
