module main_memory(
    input clk,
    input reset,
    
    // Stage 1 - IF
    input [9:0] PC, // PC
    output reg [31:0] instruction, // Instruction fetched
    
    // --- Port B: Data Memory (Stage 4 - MEM) ---
    input write,
    input [9:0] addr, // Address from ALU Result
    input [31:0] data_in,   // Data to store
    output reg [31:0] data_out   // Data loaded (lw)
);
    (* ram_style = "block" *) reg [31:0] memory [0:1023]; // 1024 x 32-bit registers

    initial begin
        $readmemh("instructions.mem", memory);
    end

    // Fetch instruction at PC
    always @(posedge clk) begin
        if (!reset) instruction <= 32'b0; // or a NOP-equivalent opcode
        else instruction <= memory[PC];
    end

    // Read/Write (MEM Stage)
    always @(posedge clk) begin
        if (write) memory[addr] <= data_in;
        data_out <= memory[addr];
    end
endmodule