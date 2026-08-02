module testbench1;
    initial begin
        $dumpfile("simulation/mips_test1.vcd");
        $dumpvars(0, testbench1);
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
        $readmemh("testbenches/instructions/instructions1.mem", processor.memory.memory);
        
        for (k = 0; k < 32; k = k + 1) begin
            processor.registers.bram1[k] = k;
            processor.registers.bram2[k] = k;
        end

        #280;
        for (k = 0; k < 6; k = k + 1) begin
            $display("R%0d = %0d", k, processor.registers.bram1[k]);
        end
        check();
    end

    task check();
        reg [31:0] r1_add_r2, sum;
        begin
            r1_add_r2 = processor.registers.bram1[1] + processor.registers.bram1[2];
            sum = processor.registers.bram1[1] + processor.registers.bram1[2] + processor.registers.bram1[3];

            if (processor.registers.bram1[4] != r1_add_r2) begin
                $display("FAILED : Error computing R1 + R2 | Expected : %0d | Got : %0d",
                    r1_add_r2, processor.registers.bram1[4]);
            end else if (processor.registers.bram1[5] != sum) begin
                $display("FAILED : Error computing final sum | Expected : %0d | Got : %0d",
                    sum, processor.registers.bram1[5]);
            end else begin
                $display("PASSED : Computed correct sum | Expected : %0d | Got : %0d",
                    sum, processor.registers.bram1[5]);
            end
        end
    endtask
endmodule
