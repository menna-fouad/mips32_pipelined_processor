module MIPS32 # (
    // R-type instructions
    parameter [5:0] ADD = 6'b000000, SUB = 6'b000001, AND = 6'b000010, OR = 6'b000011,
    parameter [5:0] SLT = 6'b000100, MUL = 6'b000101, HLT = 6'b111111,

    // I-type instructions
    parameter [5:0] LW = 6'b001000, SW = 6'b001001,
    parameter [5:0] ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100,
    parameter [5:0] BNEQZ = 6'b001101, BEQZ = 6'b001110,

    // J-type instructions
    parameter [5:0] J = 6'b010000,

    // Instruction types
    parameter [2:0] R = 3'b000, I = 3'b001, LOAD = 3'b010, STORE = 3'b011, 
    parameter [2:0] BRANCH = 3'b100, JUMP = 3'b101, HALT = 3'b110
) (
    input clk1,
    input clk2
);
    reg [31:0] PC;
    reg [31:0] IF_ID_IR, IF_ID_NPC;
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_IMM;
    reg [31:0] EX_MEM_IR, EX_MEM_ALU_OUT, EX_MEM_B;
    reg EX_MEM_COND;
    reg [31:0] MEM_WB_IR, MEM_WB_ALU_OUT, MEM_WB_LMD;

    reg [2:0] ID_EX_TYPE, EX_MEM_TYPE, MEM_WB_TYPE;

    reg HALTED, TAKEN_BRANCH;

    reg [31:0] reg_file [0:31];
    reg [31:0] mem [0:1023];

    // Stage 1: Instruction Fetch (IF)
    always @(posedge clk1) begin
        if (!HALTED) begin
            if ((EX_MEM_IR[31:26] == BEQZ && EX_MEM_COND == 1'b1)
            ||  (EX_MEM_IR[31:26] == BNEQZ && EX_MEM_COND == 1'b0)
            ||  (EX_MEM_TYPE == JUMP)) begin
                TAKEN_BRANCH <= 1'b1;
                IF_ID_IR <= mem[EX_MEM_ALU_OUT];
                IF_ID_NPC <= EX_MEM_ALU_OUT + 1;
                PC <= EX_MEM_ALU_OUT + 1;
            end else begin
                TAKEN_BRANCH <= 1'b0;
                IF_ID_IR <= mem[PC];
                IF_ID_NPC <= PC + 1;
                PC <= PC + 1;
            end
        end
    end

    // Stage 2: Instruction Decode (ID)
    always @(posedge clk2) begin
        if (!HALTED) begin
            ID_EX_IR <= IF_ID_IR;
            ID_EX_NPC <= IF_ID_NPC;

            ID_EX_A <= reg_file[IF_ID_IR[25:21]];
            ID_EX_B <= reg_file[IF_ID_IR[20:16]];
            ID_EX_IMM <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};

            case (IF_ID_IR[31:26])
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

    // Stage 3: Execute (EX)
    always @(posedge clk1) begin
        if (!HALTED) begin
            EX_MEM_TYPE <= ID_EX_TYPE;
            EX_MEM_IR <= ID_EX_IR;
            EX_MEM_B <= ID_EX_B;

            case (ID_EX_TYPE)
                R : begin
                    case (ID_EX_IR[31:26])
                        ADD : EX_MEM_ALU_OUT <= ID_EX_A + ID_EX_B;
                        SUB : EX_MEM_ALU_OUT <= ID_EX_A - ID_EX_B;
                        AND : EX_MEM_ALU_OUT <= ID_EX_A & ID_EX_B;
                        OR  : EX_MEM_ALU_OUT <= ID_EX_A | ID_EX_B;
                        SLT : EX_MEM_ALU_OUT <= {31'b0, ID_EX_A < ID_EX_B};
                        MUL : EX_MEM_ALU_OUT <= ID_EX_A * ID_EX_B;
                        default : EX_MEM_ALU_OUT <= 32'hxxxxxxxx;
                    endcase
                end

                I : begin
                    case (ID_EX_IR[31:26])
                        ADDI : EX_MEM_ALU_OUT <= ID_EX_A + ID_EX_IMM;
                        SUBI : EX_MEM_ALU_OUT <= ID_EX_A - ID_EX_IMM;
                        SLTI : EX_MEM_ALU_OUT <= {31'b0, ID_EX_A < ID_EX_B};
                        default: EX_MEM_ALU_OUT <= 32'hxxxxxxxx;
                    endcase
                end

                LOAD, STORE : begin
                    EX_MEM_ALU_OUT <= ID_EX_A + ID_EX_IMM;
                end

                BRANCH : begin
                    EX_MEM_ALU_OUT <= ID_EX_NPC + ID_EX_IMM;
                    EX_MEM_COND <= (ID_EX_A == 0);
                end

                JUMP : begin
                    EX_MEM_ALU_OUT <= ID_EX_NPC + ID_EX_IMM;
                end

                default : EX_MEM_ALU_OUT <= 32'hxxxx;
            endcase
        end
    end

    // Stage 4: Memory Access (Mem)
    always @(posedge clk2) begin
        // MEM_WB_LMD
        if (!HALTED) begin
            MEM_WB_IR <= EX_MEM_IR;
            MEM_WB_TYPE <= EX_MEM_TYPE;

            case (EX_MEM_TYPE)
                R, I : MEM_WB_ALU_OUT <= EX_MEM_ALU_OUT;
                LOAD : MEM_WB_LMD <= mem[EX_MEM_ALU_OUT];
                STORE : if (!TAKEN_BRANCH) mem[EX_MEM_ALU_OUT] <= EX_MEM_B;
                default : ;
            endcase
        end
    end

    // Stage 5: Write back (WB)
    always @(posedge clk1) begin
        if (!TAKEN_BRANCH) begin
            case (MEM_WB_TYPE)
                R : if (MEM_WB_IR[15:11] != 0) reg_file[MEM_WB_IR[15:11]] <= MEM_WB_ALU_OUT;
                I : if (MEM_WB_IR[20:16] != 0) reg_file[MEM_WB_IR[20:16]] <= MEM_WB_ALU_OUT;
                LOAD : if (MEM_WB_IR[20:16] != 0) reg_file[MEM_WB_IR[20:16]] <= MEM_WB_LMD;
                HALT : HALTED <= 1'b1;
                default : ;
            endcase
        end
    end
endmodule