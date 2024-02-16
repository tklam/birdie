// http://www.asic-world.com/code/hdl_models/ram_sp_ar_sw.v
//-----------------------------------------------------
// Design Name : ram_sp_ar_sw
// File Name   : ram_sp_ar_sw.v
// Function    : Asynchronous read write RAM
// Coder       : Deepak Kumar Tala
//-----------------------------------------------------
module ram_sp_ar_sw #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 1 << ADDR_WIDTH
) (
    //--------------Input Ports-----------------------
    input wire clk,
    // Clock Input
    input wire[ADDR_WIDTH - 1:0] address,
    // Address Input
    //--------------Inout Ports-----------------------
    inout wire[DATA_WIDTH - 1:0] data,
    // Data bi-directional
    input wire cs,
    // Chip Select
    input wire we,
    // Write Enable/Read Enable
    input wire oe
);
    //--------------Internal variables----------------
    reg[DATA_WIDTH - 1:0] data_out;
    reg[DATA_WIDTH - 1:0] mem[0:RAM_DEPTH - 1];
    //--------------Code Starts Here------------------
    // Tri-State Buffer control
    // output : When we = 0, oe = 1, cs = 1
    assign data = (cs && oe && !we) ? data_out : 8'bz;
    // Memory Write Block
    // Write Operation : When we = 1, cs = 1
    always @(posedge clk) begin: MEM_WRITE
        if (cs && we)
            mem[address] = data;
    end

    // Memory Read Block
    // Read Operation : When we = 0, oe = 1, cs = 1
    always @(address, cs, we, oe) begin: MEM_READ
        if (cs && !we && oe)
            data_out = mem[address];
    end

endmodule
