`timescale 1ns / 1ps
module data_path(
    input wire valid, cpu_write_en,mem_allocate_en, reset, clk,
    input wire [31:0] write_data, address,
    input [127:0] mem_read_data,
    
    output [127:0] mem_write_data,
    output hit,
    output reg [31:0] rdata
    );
 
    
    wire [1:0] tag;
    wire [2:0] index;
    wire [1:0] offset;
    assign tag = address[8:7];
    assign index = address[6:4];
    assign offset = address [3:2]; 
    
    reg [1:0] cache_tag [7:0];
    reg cache_valid [7:0];
    reg [127:0] cache_data [7:0];
    
    //Hit generator
    assign hit = (cache_valid[index] == 1'b1 && cache_tag[index] == tag) ? 1'b1 : 1'b0;
    assign  mem_write_data = cache_data[index];
    
    //read word
    always@(*)begin
        case(offset)
            2'b00: rdata = cache_data[index][31:0];
            2'b01: rdata = cache_data[index][63:32];
            2'b10: rdata = cache_data[index][95:64];
            2'b11: rdata = cache_data[index][127:96];
            default: rdata = 32'b0;
        endcase
    end
    
    
    integer i;
    always @(posedge clk or posedge  reset)begin
        if(reset)begin
            for(i=0; i<8; i=i+1)begin
                cache_data[i] <= 128'd0;
                cache_tag[i]<= 2'b00;
                cache_valid[i] <= 1'b0;
            end
        end
        
        else if(mem_allocate_en)begin
            cache_data[index]<=mem_read_data;
            cache_tag[index]<=tag;
            cache_valid[index]<=1'b1;
        end
        
        else if(cpu_write_en && hit)begin
            case(offset)
                    2'b00: cache_data[index][31:0]   <= write_data;
                    2'b01: cache_data[index][63:32]  <= write_data;
                    2'b10: cache_data[index][95:64]  <= write_data;
                    2'b11: cache_data[index][127:96] <= write_data;
            endcase
        end

    end
endmodule
