`timescale 1ns / 1ps
module tb_direct_mapped_cache_thorough();

    reg clk, reset;
    
    reg valid, write_en;
    reg [31:0] address, write_data;
    wire busy, ready;
    wire [31:0] rdata;
    
    reg mem_ready;
    reg [127:0] mem_read_data;
    wire mem_read_en, mem_write_en;
    wire [127:0] mem_write_data;

    direct_mapped_cache DUT (
        .clk(clk),
        .reset(reset),
        .valid(valid),
        .write_en(write_en),
        .address(address),
        .write_data(write_data),
        .busy(busy),
        .ready(ready),
        .rdata(rdata),
        .mem_ready(mem_ready),
        .mem_read_data(mem_read_data),
        .mem_read_en(mem_read_en),
        .mem_write_en(mem_write_en),
        .mem_write_data(mem_write_data)
    );

    // ==========================================
    // 3. Clock Generation (10ns period)
    // ==========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        // $monitor prints automatically whenever any variable in the list changes.
        $monitor("Time=%0t | rdy:%b bsy:%b | Addr:%h | val:%b we:%b | hit:%b | rdata:%h | mem_read:%b mem_write:%b", 
                 $time, ready, busy, address, valid, write_en, 
                 DUT.internal_hit, rdata, mem_read_en, mem_write_en);
    end
    initial begin
        // Initialize Signals
        reset = 1;
        valid = 0;
        write_en = 0;
        address = 32'd0;
        write_data = 32'd0;
        mem_ready = 0;
        mem_read_data = 128'd0;

        // Apply Reset
        #15;
        reset = 0;
        $display("\n--- SYSTEM RESET COMPLETE ---");
        
        // Wait for the first negative edge to align all future stimulus
        @(negedge clk);

        // ---------------------------------------------------------
        // SCENARIO 1: Cold Read Miss
        // ---------------------------------------------------------
        $display("\n--- SCENARIO 1: COLD READ MISS ---");
        address = 32'h0000_0004;
        write_en = 0;
        valid = 1;
        
        wait(mem_read_en == 1'b1);
        @(negedge clk); // Drop valid cleanly away from the sampling edge
        valid = 0; 
        
        // Simulate memory latency safely using cycle counts
        repeat(3) @(negedge clk); 
        mem_read_data = 128'h44444444_33333333_22222222_11111111; 
        mem_ready = 1;
        
        @(negedge clk); // Hold for one full cycle
        mem_ready = 0;
        
        wait(ready == 1'b1);

        // ---------------------------------------------------------
        // SCENARIO 2: Read Hit
        // ---------------------------------------------------------
        $display("\n--- SCENARIO 2: READ HIT ---");
        @(negedge clk);
        address = 32'h0000_0004;
        write_en = 0;
        valid = 1;
        
        @(negedge clk);
        valid = 0;
        wait(ready == 1'b1);

        // ---------------------------------------------------------
        // SCENARIO 3: Write Hit (Write-Through test)
        // ---------------------------------------------------------
        $display("\n--- SCENARIO 3: WRITE HIT (WRITE-THROUGH) ---");
        @(negedge clk);
        address = 32'h0000_0008;
        write_data = 32'hDEADBEEF;
        write_en = 1;
        valid = 1;
        
        wait(mem_write_en == 1'b1);
        @(negedge clk);
        valid = 0;
        
        // Main memory write latency
        repeat(2) @(negedge clk); 
        mem_ready = 1; 
        
        @(negedge clk);
        mem_ready = 0;
        wait(ready == 1'b1);

        // ---------------------------------------------------------
        // SCENARIO 4: Read Hit (Post-Write)
        // ---------------------------------------------------------
        $display("\n--- SCENARIO 4: READ HIT (POST-WRITE) ---");
        @(negedge clk);
        address = 32'h0000_0008;
        write_en = 0;
        valid = 1;
        
        @(negedge clk);
        valid = 0;
        wait(ready == 1'b1);

        // ---------------------------------------------------------
        // SCENARIO 5: Conflict Miss (Eviction)
        // ---------------------------------------------------------
        $display("\n--- SCENARIO 5: CONFLICT MISS (EVICTION) ---");
        @(negedge clk);
        address = 32'h0000_0084;
        write_en = 0;
        valid = 1;
        
        wait(mem_read_en == 1'b1);
        @(negedge clk);
        valid = 0; 
        
        repeat(3) @(negedge clk);
        mem_read_data = 128'hDDDDDDDD_CCCCCCCC_BBBBBBBB_AAAAAAAA; 
        mem_ready = 1;
        
        @(negedge clk);
        mem_ready = 0;
        wait(ready == 1'b1);
        $display("\n--- ALL TESTS COMPLETED SUCCESSFULLY ---");
        #20;
        $finish;
    end
endmodule
