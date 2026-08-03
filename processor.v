module MIPS32 # (
    // R-type instructions
    parameter [5:0] ADD = 6'b000001, SUB = 6'b000010, AND = 6'b000011, OR = 6'b000100,
    parameter [5:0] SLT = 6'b000101, MUL = 6'b000110, HLT = 6'b111111,

    // I-type instructions
    parameter [5:0] LW = 6'b001000, SW = 6'b001001,
    parameter [5:0] ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100,
    parameter [5:0] BNEQZ = 6'b001101, BEQZ = 6'b001110,

    // J-type instructions
    parameter [5:0] J = 6'b010000,

    // NOP instruction
    parameter [5:0] NOP_INSTRUCTION = 6'b000000,

    // Instruction types
    parameter [2:0] R = 3'b000, I = 3'b001, LOAD = 3'b010, STORE = 3'b011, 
    parameter [2:0] BRANCH = 3'b100, JUMP = 3'b101, NOP = 3'b110, HALT = 3'b111
) (
    input clk,
    input reset,

    output [9:0] dbg_pc,
    output dbg_halted,
    output [31:0] dbg_alu_out,
    output [31:0] dbg_instr
);
    (* mark_debug = "true" *) reg [9:0] PC;
    reg [31:0] IF_ID_NPC;
    (* mark_debug = "true" *) wire [31:0] IF_ID_IR;
    
    (* mark_debug = "true" *) reg [31:0] ID_EX_NPC, ID_EX_IR, ID_EX_IMM;
    wire [31:0] ID_EX_A, ID_EX_B;

    (* mark_debug = "true" *) reg [31:0] EX_MEM_IR, EX_MEM_ALU_OUT, EX_MEM_B;
    reg EX_MEM_WRITE;
    
    (* mark_debug = "true" *) reg [31:0] MEM_WB_IR, MEM_WB_ALU_OUT;
    wire [31:0] MEM_WB_LMD;

    reg [2:0] ID_EX_TYPE, EX_MEM_TYPE, MEM_WB_TYPE;
    (* mark_debug = "true" *) reg HALTED, TAKEN_BRANCH;

    
    wire [9:0] INST_ADDR;
    assign INST_ADDR = (TAKEN_BRANCH ||  (EX_MEM_TYPE == JUMP)) ? EX_MEM_ALU_OUT[9:0] : PC;

    assign dbg_pc = PC;
    assign dbg_halted = HALTED;
    assign dbg_alu_out = EX_MEM_ALU_OUT;
    assign dbg_instr = MEM_WB_IR;

    main_memory memory (
        .clk(clk),
        .reset(reset),
        .PC(INST_ADDR),
        .instruction(IF_ID_IR),
        .write(EX_MEM_WRITE),
        .addr(EX_MEM_ALU_OUT[9:0]),
        .data_in(EX_MEM_B),
        .data_out(MEM_WB_LMD)
    );

    wire reg_write;
    assign reg_write = !reset && !HALTED && 
    ((MEM_WB_TYPE == R) || (MEM_WB_TYPE == I) || (MEM_WB_TYPE == LOAD));

    // Target register: rd for R-type, rt for I-type and LOADs
    wire [4:0] wr_addr;
    assign wr_addr = (MEM_WB_TYPE == R) ? MEM_WB_IR[15:11] : MEM_WB_IR[20:16];

    // Data source: LMD for LOADs, ALU output for R-type / I-type
    wire [31:0] wr_data;
    assign wr_data = (MEM_WB_TYPE == LOAD) ? MEM_WB_LMD : MEM_WB_ALU_OUT;

    register_file registers (
        .clk(clk),
        .reg_write(reg_write),
        .rs_addr(IF_ID_IR[25:21]),
        .rs_data(ID_EX_A),
        .rt_addr(IF_ID_IR[20:16]),
        .rt_data(ID_EX_B),
        .wr_addr(wr_addr),
        .wr_data(wr_data)
    );


    // Stage 1: Instruction Fetch (IF)
    always @(posedge clk) begin
        if (reset) begin
            PC <= 10'd0;
            IF_ID_NPC <= 32'd0;
        end else if (!HALTED && IF_ID_IR[31:26] != HLT) begin
            if (TAKEN_BRANCH ||  (EX_MEM_TYPE == JUMP)) begin
                IF_ID_NPC <= EX_MEM_ALU_OUT + 1;
                PC <= EX_MEM_ALU_OUT[9:0] + 1;
            end else begin
                IF_ID_NPC <= PC + 1;
                PC <= PC + 1;
            end
        end
    end

    // Stage 2: Instruction Decode (ID)
    always @(posedge clk) begin
        if (reset) begin
            ID_EX_IR <= 0;
            ID_EX_NPC <= 0;
            ID_EX_IMM <= 0;
            ID_EX_TYPE <= NOP;
        end else if (!HALTED && ID_EX_TYPE != HALT) begin
            ID_EX_IR <= IF_ID_IR;
            ID_EX_NPC <= IF_ID_NPC;

            ID_EX_IMM <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};

            if (TAKEN_BRANCH) ID_EX_TYPE <= NOP;
            else begin
                case (IF_ID_IR[31:26])
                    NOP_INSTRUCTION : ID_EX_TYPE <= NOP;
                    ADD, SUB, AND, OR, SLT, MUL : ID_EX_TYPE <= R;
                    ADDI, SUBI, SLTI : ID_EX_TYPE <= I;
                    LW : ID_EX_TYPE <= LOAD;
                    SW : ID_EX_TYPE <= STORE;
                    BEQZ, BNEQZ : ID_EX_TYPE <= BRANCH;
                    J : ID_EX_TYPE <= JUMP;
                    HLT : ID_EX_TYPE <= HALT;
                    default : ID_EX_TYPE <= HALT;
                endcase
            end
        end
    end

    // Stage 3: Execute (EX)
    always @(posedge clk) begin
        if (reset) begin
            EX_MEM_TYPE <= NOP;
            EX_MEM_IR <= 0;
            EX_MEM_ALU_OUT <= 0;
            EX_MEM_B <= 0;
            EX_MEM_WRITE <= 1'b0;
            TAKEN_BRANCH <= 0;
        end else if (!HALTED) begin
            EX_MEM_IR <= ID_EX_IR;
            EX_MEM_B <= ID_EX_B;
            TAKEN_BRANCH <= 0;

            if (TAKEN_BRANCH) begin
                // Instruction B is in EX right now! Kill it by converting to NOP.
                EX_MEM_TYPE <= NOP;
                EX_MEM_WRITE <= 1'b0;
                EX_MEM_IR <= 0;
                EX_MEM_ALU_OUT <= 0;
            end else begin
                EX_MEM_TYPE <= ID_EX_TYPE;
                EX_MEM_WRITE <= (ID_EX_TYPE == STORE);
                case (ID_EX_TYPE)
                    R : begin
                        case (ID_EX_IR[31:26])
                            ADD : EX_MEM_ALU_OUT <= ID_EX_A + ID_EX_B;
                            SUB : EX_MEM_ALU_OUT <= ID_EX_A - ID_EX_B;
                            AND : EX_MEM_ALU_OUT <= ID_EX_A & ID_EX_B;
                            OR  : EX_MEM_ALU_OUT <= ID_EX_A | ID_EX_B;
                            SLT : EX_MEM_ALU_OUT <= {31'b0, $signed(ID_EX_A) < $signed(ID_EX_B)};
                            MUL : EX_MEM_ALU_OUT <= ID_EX_A * ID_EX_B;
                            default : EX_MEM_ALU_OUT <= 32'h00000000;
                        endcase
                    end

                    I : begin
                        case (ID_EX_IR[31:26])
                            ADDI : EX_MEM_ALU_OUT <= ID_EX_A + ID_EX_IMM;
                            SUBI : EX_MEM_ALU_OUT <= ID_EX_A - ID_EX_IMM;
                            SLTI : EX_MEM_ALU_OUT <= {31'b0, $signed(ID_EX_A) < $signed(ID_EX_IMM)};
                            default: EX_MEM_ALU_OUT <= 32'h00000000;
                        endcase
                    end

                    LOAD, STORE : begin
                        EX_MEM_ALU_OUT <= ID_EX_A + ID_EX_IMM;
                    end

                    BRANCH : begin
                        EX_MEM_ALU_OUT <= ID_EX_NPC + ID_EX_IMM;
                        TAKEN_BRANCH <= (~ID_EX_IR[26] && (~|ID_EX_A)) || (ID_EX_IR[26] && (|ID_EX_A));
                    end

                    JUMP : begin
                        EX_MEM_ALU_OUT <= ID_EX_NPC + ID_EX_IMM;
                        TAKEN_BRANCH <= 1'b1;
                    end

                    default : EX_MEM_ALU_OUT <= 32'h00000000;
                endcase
            end
        end
    end

    // Stage 4: Memory Access (Mem)
    always @(posedge clk) begin
        // MEM_WB_LMD
        if (reset) begin
            MEM_WB_IR <= 0;
            MEM_WB_TYPE <= NOP;
            MEM_WB_ALU_OUT <= 0;
        end else if (!HALTED) begin
            MEM_WB_IR <= EX_MEM_IR;
            MEM_WB_TYPE <= EX_MEM_TYPE;
            MEM_WB_ALU_OUT <= EX_MEM_ALU_OUT;
            // memory handles reading to MEM_WB_LMD and writing EX_MEM_B to memory in case of a store instruction
        end
    end

    // Stage 5: Write back (WB)
    always @(posedge clk) begin
        if (reset) HALTED <= 1'b0;
        else if (MEM_WB_TYPE == HALT) HALTED <= 1'b1;
    end
endmodule