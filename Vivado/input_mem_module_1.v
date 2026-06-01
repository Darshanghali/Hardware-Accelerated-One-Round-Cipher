`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.10.2025 22:21:58
// Design Name: 
// Module Name: input_mem_module
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


module input_mem_module_1 #(
    parameter DATA_WIDTH = 24,               // your data is 3 bytes (R,G,B) = 24 bits
    parameter ADDR_WIDTH = 16,               // 2^16 = 65536 locations
    parameter INIT_FILE  = "lena1.mem"
)(
    input  wire [ADDR_WIDTH-1:0] addr,       // address input
    input clk,
    output reg  [DATA_WIDTH-1:0] data       // data output
);

    // Memory declaration
   // reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] mem [0:65535];

    // Initialize memory with .mem file
    initial begin
        $readmemh(INIT_FILE, mem);
    end

    // Read operation
    always @(*) begin
        data = mem[addr];
    end

endmodule



