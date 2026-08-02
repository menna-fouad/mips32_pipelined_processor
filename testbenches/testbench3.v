module testbench3;
    initial begin
        $dumpfile("simulation/mips_test3.vcd");
        $dumpvars(0, testbench3);
        #3000 $finish;
    end

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset;
    initial begin
        reset = 1'b1;
        #17 reset = 1'b0;
    end

    MIPS32 processor (
        .clk(clk),
        .reset(reset)
    );

    integer k;

    initial begin
        $readmemh("testbenches/instructions/instructions3.mem", processor.memory.memory);
        
        for (k = 0; k < 32; k = k + 1) begin
            processor.registers.bram1[k] = k;
            processor.registers.bram2[k] = k;
        end

        #2800;
        $display("MEM[200] = %0d", processor.memory.memory[200]);
        $display("MEM[198] = %0d", processor.memory.memory[198]);
        check();
    end

    task check();
    reg [31:0] expected;
        begin
            expected = 32'd3628800;
            if (processor.memory.memory[198] !== expected) begin
                $display("FAILED | Expected : %0d | Got : %0d",
                        expected, processor.memory.memory[198]);
            end else begin
                $display("PASSED | Expected : %0d | Got : %0d",
                        expected, processor.memory.memory[198]);
            end
        end
    endtask
endmodule