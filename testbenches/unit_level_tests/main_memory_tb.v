module main_memory_tb;
    reg clk = 0;
    reg [9:0] PC = 0;
    wire [31:0] instruction;

    reg write = 0;
    reg [9:0] addr;
    reg [31:0] data_in;
    wire [31:0] data_out;

    reg [31:0] shadow [0:1023];

    always #5 clk = ~clk;

    main_memory memory (
        .clk(clk),
        .PC(PC),
        .instruction(instruction),
        .write(write),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    integer k;
    integer seed1 = 42, seed2 = 0, seed3 = 5, seed4 = 99;
    initial begin
        $readmemh("instructions.mem", shadow);
        for (k = 0; k < 1024; k = k + 1) begin
            if (memory.memory[k] === 32'hxxxxxxxx) begin
                memory.memory[k] = k;
                shadow[k] = k;
            end
        end

        #2 PC = 10'd3; addr = 10'd150; data_in = 32'hDEAD_BEEF; write = 1'b1;
        check(PC, write, addr, data_in);
        
        #10 PC = 10'd7; addr = 10'd200; data_in = 32'h1234_5678; write = 1'b0;
        check(PC, write, addr, data_in);

        #10 PC = 10'd2; addr = 10'd1003; data_in = 32'hCAFE_F00D; write = 1'b1;
        check(PC, write, addr, data_in);

        #10 PC = 10'd8; addr = 10'd26; data_in = 32'hFFFF_FFFF; write = 1'b0;
        check(PC, write, addr, data_in);
    end

    initial begin
        $dumpfile("main_memory_tb.vcd");
        $dumpvars(0, main_memory_tb);
        #600 $finish;
    end

    task check(
        input [9:0] prog_counter,
        input wr,
        input [9:0] address,
        input [31:0] d_in
    );
        reg [31:0] exp_data_out, exp_inst, exp_wr;
        begin
            if (wr) shadow[address] = d_in;
            exp_data_out = shadow[address];
            exp_inst = shadow[prog_counter];
            exp_wr = shadow[address];

            @(posedge clk); #1;
            if (exp_inst != instruction)
                $display("FAILED instruction | PC = %0d expected = %0d got = %0d", prog_counter, exp_inst, instruction);
            if (!wr && exp_data_out != data_out)
                $display("FAILED data_out | addr = %0d expected = %0d got = %0d", address, exp_data_out, data_out);
            if (memory.memory[address] != exp_wr)
                $display("FAILED write to memory | wr_addr = %0d expected = %0d got = %0d",
                        address, exp_wr, memory.memory[address]);
            if (exp_inst == instruction && memory.memory[address] == exp_wr &&
                (wr || exp_data_out == data_out))
                $display("PASSED | PC = %0d addr = %0d data_in = %0d data_out = %0d write = %0d",
                        PC, address, d_in, data_out, write);
        end
    endtask
endmodule