`timescale 1ns/1ns
module debounce_sync_tb;
    localparam DB_BITS = 3;
    localparam THRESHOLD = (2 ** DB_BITS); // number of consecutive cycles needed to latch new value

    reg clk = 0;
    reg raw_in = 0;
    wire clean_out;

    always #5 clk = ~clk;

    debounce_sync #(.DEBOUNCE_BITS(DB_BITS)) debounce (
        .clk(clk),
        .raw_in(raw_in),
        .clean_out(clean_out)
    );

    initial begin
        $dumpfile("debounce_sync_tb.wdb");
        $dumpvars(0, debounce_sync_tb);
    end

    task drive_for(input val, input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk); raw_in = val;
            end
        end
    endtask

    // Check clean_out against an expected value, log PASS/FAIL
    task expect_clean(input exp);
        begin
            #1; // let the just-completed edge settle
            if (clean_out !== exp) begin
                $display("FAILED | expected clean_out=%0d got=%0d\n", exp, clean_out);
            end else begin
                $display("PASSED | expected clean_out=%0d got=%0d\n", exp, clean_out);
            end
        end
    endtask

    initial begin
        // raw_in held high past threshold
        drive_for(1, THRESHOLD + 2);
        $display("1. stable-high latches");
        expect_clean(1'b1);

        // reset back to a known low baseline past threshold
        drive_for(0, THRESHOLD + 2);
        $display("2. stable-low latches back");
        expect_clean(1'b0);

        // raw_in glitches high for fewer cycles than threshold
        drive_for(1, THRESHOLD - 2);
        $display("3. short glitch to high ignored");
        expect_clean(1'b0);
        drive_for(0, 2); // drive 0 to reset counter

        // simulating pressing the button - several short pulses before settling high
        drive_for(1, 2);
        drive_for(0, 1);
        drive_for(1, 2);
        drive_for(0, 1);
        drive_for(1, 2);

        // none of those bursts alone reach THRESHOLD consecutive cycles, so still low
        $display("4. mid-bounce still low");
        expect_clean(1'b0);

        // now hold stable high long enough to latch
        drive_for(1, THRESHOLD + 2);
        $display("4.2. settles high after bounce");
        expect_clean(1'b1);

        // from high, drive low for a shorter period than threshold must be rejected
        drive_for(0, THRESHOLD - 2);
        $display("5. short dropout ignored, stays high");
        expect_clean(1'b1);
        drive_for(1, 2); // drive 1 to reset counter

        // Boundary test. New value must latch at THRESHOLD + 2:
        // 2 cycles for the synchronizer
        // THRESHOLD more cycles for the counter to reach all-ones.
        drive_for(0, THRESHOLD + 2); // reset to 0
        $display("6. reset value to be 0");
        expect_clean(1'b0);

        drive_for(1, THRESHOLD + 2 - 1);
        $display("6. one cycle short of latching new value");
        expect_clean(1'b0);

        drive_for(1, 1); // one more cycle completes THRESHOLD+2 cycles
        $display("6. drive one more cycle to latch new value");
        expect_clean(1'b1);

        $finish;
    end
endmodule