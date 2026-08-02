module testbench2;
    initial begin
        $dumpfile("simulation/mips_test2.vcd");
        $dumpvars(0, testbench2);
        #600 $finish;
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
        $readmemh("testbenches/instructions/instructions2.mem", processor.memory.memory);

        for (k = 0; k < 32; k = k + 1) begin
            processor.registers.bram1[k] = k;
            processor.registers.bram2[k] = k;
        end

        #500;
        $display("MEM[120] = %0d", processor.memory.memory[120]);
        $display("MEM[121] = %0d", processor.memory.memory[121]);
        check();
    end

    task check();
    reg [31:0] expected;
        begin
            expected = processor.memory.memory[120] + 45;
            if (processor.memory.memory[121] != expected) begin
                $display("FAILED | Expected : %0d | Got : %0d",
                        expected, processor.memory.memory[121]);
            end else begin
                $display("PASSED | Expected : %0d | Got : %0d",
                        expected, processor.memory.memory[121]);
            end
        end
    endtask
endmodule