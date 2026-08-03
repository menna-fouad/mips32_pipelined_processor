module clk_divider_tb;
    localparam DIV_BITS = 5;
    localparam PERIOD = (2 ** DIV_BITS) * 2;
    // slow clock toggles after 2 ** (DIV_BITS - 1) cycles
    // clock period of the slow clock is the clock period of the fast clock * number of cycles to toggle twice (reset)
    // therefore slow clock period = 2 ** (DIV_BITS - 1) * 2 * fast clock period = (2 ** DIV_BITS) * 2

    reg clk_in = 0;
    wire clk_out;

    always #1 clk_in = ~clk_in; // fast clock period of 2 units

    clk_divider #(.DIV_BITS(DIV_BITS)) divider (
        .clk_in(clk_in),
        .clk_out(clk_out)
    );

    initial begin
        $dumpfile("clk_divider_tb.wdb");
        $dumpvars(0, clk_divider_tb);
    end

    task check(input exp);
        begin
            #1; // let the just-completed edge settle
            if (clk_out !== exp) begin
                $display("FAILED | time = %0d | expected clk_out=%0d got=%0d\n", $time, exp, clk_out);
            end else begin
                $display("PASSED | time = %0d | expected clk_out=%0d got=%0d\n", $time, exp, clk_out);
            end
        end
    endtask

    integer k;
    integer seed = 42;
    reg expected;
    initial begin
        #(2 ** (DIV_BITS - 1) * 2); check(1'b1); // slow clock toggles after 2 ** (DIV_BITS - 1) cycles
        #(2 ** (DIV_BITS - 1) * 2); check(1'b0); // slow clock toggles again after 2 ** (DIV_BITS - 1) cycles

        // general test cases
        for (k = 0; k < 10; k = k + 1) begin
            #($unsigned($random(seed)) % (PERIOD * 3));
            expected = ($time % PERIOD) >= (PERIOD / 2);
            check(expected);
        end
        $finish;
    end
endmodule