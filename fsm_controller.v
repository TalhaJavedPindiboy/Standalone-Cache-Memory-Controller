`timescale 1ns / 1ps
module fsm_controller(
    input wire clk,
    input wire reset,
    input wire valid, write_en,
    output reg busy, ready,
    input wire hit,
    output reg cpu_write_en, mem_allocate_en,  
    input wire mem_ready,
    output reg mem_read_en,
    output reg mem_write_en
);
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] COMPARE = 2'b01;
    localparam [1:0] ALLOCATE = 2'b10;
    localparam [1:0] WRITE_MEM = 2'b11;
    
    
    reg [1:0] cur_state, nxt_state;
    reg busy_nxt;
    reg ready_nxt;
    
    always @(*)begin
        nxt_state = cur_state;
        
        cpu_write_en = 1'b0;
        mem_allocate_en = 1'b0;
        mem_read_en = 1'b0;
        mem_write_en = 1'b0;
        
        busy_nxt  = busy;
        ready_nxt = ready;
        
        case(cur_state)
            IDLE:begin
                ready_nxt = 1'b1;
                busy_nxt = 1'b0;
                
                if(valid)begin
                    ready_nxt = 1'b0;
                    busy_nxt = 1'b1;
                    nxt_state = COMPARE;
                end
            end
            COMPARE:begin
                if(hit && !write_en)begin
                    nxt_state = IDLE;
                end
                else if (hit && write_en)begin
                    cpu_write_en = 1'b1;
                    nxt_state = WRITE_MEM;
                end
                else if (!hit)begin
                    nxt_state = ALLOCATE;
                end
            end
            ALLOCATE:begin
                mem_read_en = 1'b1;
                if(mem_ready)begin
                    mem_allocate_en = 1'b1;
                    nxt_state = COMPARE;
                end
            end
            WRITE_MEM :begin
                mem_write_en = 1'b1;
                
                if(mem_ready)begin
                    nxt_state = IDLE;
                end
            end
        endcase
    end
    
    
    always @(posedge clk) begin
        
        if (reset) begin
            cur_state <= IDLE;
            busy      <= 1'b0;
            ready     <= 1'b0;
        end
        else begin
            cur_state <= nxt_state;
            busy      <= busy_nxt;
            ready     <= ready_nxt;
        end
    end
endmodule
