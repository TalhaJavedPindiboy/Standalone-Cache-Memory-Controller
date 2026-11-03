# Direct-Mapped Cache Controller in Verilog HDL

## Project Overview
This project implements a hardware direct-mapped cache controller in Verilog HDL using a modular architecture with a clean separation between the control unit (FSM) and the datapath[cite: 65, 76]. 

The controller interfaces a 32-bit processor port with a 128-bit wide main memory bus, managing cache hits, cold misses, 128-bit block allocations, and synchronous memory updates using a write-through and write-allocate policy[cite: 63, 65, 66, 71, 76]. 

The design is targeted for FPGA synthesis and verified using Xilinx Vivado (Artix-7 FPGA target) through both behavioral and post-synthesis timing simulations[cite: 71, 74].

---

## Architectural & Memory Specifications

* **Cache Organization:** Direct-mapped structure with 8 cache lines and a single tag comparator[cite: 63, 64].
* **Cache Line Size:** 128 bits (16 bytes), organized into four 32-bit words[cite: 63].
* **Main Memory Organization:** 32 memory lines (512 bytes / 32 blocks total)[cite: 63, 64].
* **Processor Interface:** 32-bit address, 32-bit data read/write bus[cite: 63, 65, 76].
* **Write Policy:** Write-through with write allocate (updates cache data and synchronously writes the updated 128-bit line to main memory)[cite: 66, 67, 71, 77].
* **Handshake Interface:** Protocol control using `valid`, `ready`, `busy`, and `hit` signals[cite: 65, 68, 76].

---

## Address Mapping & Partitioning

The 32-bit memory address is partitioned according to the direct-mapped cache geometry:

* **Unused Bits `[31:9]`:** Upper reserved bits[cite: 63].
* **Tag Bits `[8:7]` (2 bits):** Compared against the stored tag register for the selected line (5-bit memory block address minus 3-bit cache index = 2 tag bits)[cite: 63, 64, 75].
* **Index Bits `[6:4]` (3 bits):** Decodes and selects 1 of the 8 internal cache lines[cite: 63, 75].
* **Word Offset `[3:2]` (2 bits):** Selects 1 of 4 32-bit words from the 128-bit cache line[cite: 63, 75].
* **Byte Offset `[1:0]` (2 bits):** Selects the target byte inside the selected word[cite: 63].

---

## Hardware Modules

### 1. Top-Level Wrapper (`direct_mapped_cache.v`)
Structural interconnect that instantiates and connects the internal data path and FSM controller, routing external CPU and memory buses[cite: 76].

### 2. Datapath Unit (`data_path.v`)
* **Storage Arrays:** An 8-entry $\times$ 128-bit data array, an 8-entry $\times$ 2-bit tag array, and an 8-bit valid array[cite: 65, 75].
* **Hit Detection:** Combinational logic evaluating `hit = (cache_valid[index] && (cache_tag[index] == tag))`[cite: 65, 75].
* **Data Multiplexing & Slicing:** Multiplexes the requested 32-bit word onto `rdata` during read cycles based on `offset`[cite: 65, 75]. During CPU writes, it selectively updates only the addressed 32-bit word inside the 128-bit cache line[cite: 75].
* **Block Allocation:** Updates the entire 128-bit cache line from `mem_read_data`, stores the new tag, and asserts the valid bit when `mem_allocate_en` is active[cite: 75].

### 3. Control Unit (`fsm_controller.v`)
Coordinates cache operations via a 4-state Finite State Machine:
* **`IDLE` (`2'b00`):** Asserts `ready = 1` and `busy = 0` while waiting for CPU requests (`valid = 1`)[cite: 66, 68, 77].
* **`COMPARE` (`2'b01`):** Asserts `busy = 1` and evaluates `hit`[cite: 66, 77]. On a read hit, returns directly to `IDLE`[cite: 66, 77]. On a write hit, asserts `cpu_write_en = 1` and advances to `WRITE_MEM`[cite: 66, 77]. On any miss, transitions to `ALLOCATE`[cite: 66, 77].
* **`ALLOCATE` (`2'b10`):** Asserts `mem_read_en = 1` to fetch the missing 128-bit line from main memory[cite: 66, 77]. When acknowledged with `mem_ready = 1`, asserts `mem_allocate_en = 1` and returns to `COMPARE`[cite: 66, 77].
* **`WRITE_MEM` (`2'b11`):** Asserts `mem_write_en = 1` to write the updated 128-bit cache line to main memory[cite: 66, 77]. Transitions back to `IDLE` upon receiving `mem_ready = 1`[cite: 66, 77].

---

## Verification & Simulation Scenarios

The testbench (`tb_direct_mapped_cache.v`) evaluates the subsystem across standard memory access sequences with simulated memory latencies[cite: 78]:

1. **Cold Read Miss:** Initial access to empty address `0x00000004` results in a miss, triggering memory read assertion (`mem_read_en`), 128-bit block allocation (`0x44444444_33333333_22222222_11111111`), and extraction of word 1 (`0x22222222`)[cite: 72, 78].
2. **Read Hit:** Subsequent read to address `0x00000004` immediately returns `0x22222222` from the cache without accessing main memory (`mem_read_en = 0`)[cite: 72, 78].
3. **Write Hit (Write-Through):** Writing `0xDEADBEEF` to address `0x00000008` (word 2 of the allocated block) updates the targeted word in the cache line and synchronously writes through the modified 128-bit line to main memory (`mem_write_en = 1`)[cite: 73, 78].
4. **Read-After-Write Consistency:** Immediately reading address `0x00000008` returns `0xDEADBEEF` directly from cache, verifying internal data coherency[cite: 73, 78].
5. **Conflict Miss & Replacement:** Reading address `0x00000084` (which maps to index `3'b000` but has tag `2'b01` instead of `2'b00`) detects a conflict miss, evicts the existing line, fetches the new block (`0xDDDDDDDD_CCCCCCCC_BBBBBBBB_AAAAAAAA`), updates the tag, and returns word 1 (`0xBBBBBBBB`)[cite: 63, 73, 78].

---

## How to Run Simulation

1. Open **Xilinx Vivado** and create an RTL project targeting an FPGA device (e.g., `xc7a200tfbg676-2`)[cite: 74].
2. Add `direct_mapped_cache.v`, `data_path.v`, and `fsm_controller.v` as **Design Sources**[cite: 74].
3. Add `tb_direct_mapped_cache.v` as a **Simulation Source**[cite: 74].
4. Set `tb_direct_mapped_cache_thorough` as the top simulation module and execute **Run Behavioral Simulation**[cite: 74].
5. Monitor `address`, `valid`, `hit`, `busy`, `ready`, `rdata`, `mem_read_en`, and `mem_write_en` in the waveform viewer[cite: 78].
