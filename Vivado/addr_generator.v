`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.08.2025 13:23:29
// Design Name: 
// Module Name: input_ram
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


module addr_generator(clk,rst,addr);
input clk,rst;
output reg [15:0] addr;

always @(posedge clk or posedge rst)
begin
       if(rst)
            addr<=16'd0;
       else 
            begin 
            if (addr == 16'd65535)
                addr<=addr;
            else 
                 addr<= addr+1'b1;     
            end
            
end
endmodule
