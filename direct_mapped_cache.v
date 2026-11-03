`timescale 1ns / 1ps
module direct_mapped_cache (
    input wire clk, reset,
    input wire valid, write_en,
    input wire [31:0] address, write_data,
    output wire busy, ready,
    output wire [31:0] rdata,
    input wire mem_ready,
    input wire [127:0] mem_read_data,
    output wire mem_read_en, mem_write_en,
    output wire [127:0] mem_write_data);
    wire internal_hit;
    wire internal_cpu_write_en;
    wire internal_mem_allocate_en;


    data_path DP (
        .clk(clk),
        .reset(reset),
        
        .address(address),
        .write_data(write_data),
        .rdata(rdata),
        
        .mem_read_data(mem_read_data),
        .mem_write_data(mem_write_data),

        .hit(internal_hit),
        .cpu_write_en(internal_cpu_write_en),
        .mem_allocate_en(internal_mem_allocate_en)
    );

    fsm_controller FSM (
        .clk(clk),
        .reset(reset),        
        .valid(valid),
        .write_en(write_en),
        .busy(busy),
        .ready(ready),
        .mem_ready(mem_ready),
        .mem_read_en(mem_read_en),
        .mem_write_en(mem_write_en),
        .hit(internal_hit),
        .cpu_write_en(internal_cpu_write_en),
        .mem_allocate_en(internal_mem_allocate_en)
    );
endmodule