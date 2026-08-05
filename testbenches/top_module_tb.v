`timescale 1ns/1ps
module top_module_tb;
    initial begin
        $dumpfile("simulation/top_module_tb.wdb");
        $dumpvars(0, top_module_tb);
    end

    localparam DIV_BITS = 3;
    localparam DEBOUNCE_BITS = 6;

    reg clk_100mhz = 0;
    reg btnC;
    reg btnU;
    reg [15:0] sw;
    // sw[1:0] = which value to show on the 7-seg display

    wire [15:0] led;
    wire [7:0] an;
    wire [6:0] seg;

    reg [31:0] exp_final_pc = {{22{1'd0}}, 10'd13};
    reg [31:0] exp_final_instr = 32'hFC000000;
    reg [31:0] exp_final_alu_out = 32'd0;
    reg [31:0] exp_final_halted = 32'd1;

    always #5 clk_100mhz = ~clk_100mhz; // every half period (5ns) the clock toggles

    top_nexys_a7 top_module (
        .clk_100mhz(clk_100mhz),
        .btnC(btnC),
        .btnU(btnU),
        .sw(sw),
        .led(led),
        .an(an),
        .seg(seg)
    );

    initial begin
        btnU = 0;
        btnC = 0;
        sw = 16'h0000; // default: show PC on 7-seg
        #150;

        // "nonsense": glitchy press, bouncing before it settles high
        btnC = 1; #7;
        btnC = 0; #4;
        btnC = 1; #9;
        btnC = 0; #3;
        btnC = 1; #6;
        btnC = 0; #2;

        // stabilize high - hold well past the debounce window
        btnC = 1;
        #((2**DEBOUNCE_BITS + 15) * 10);
        // if (reset !== 1'b1) begin
            // $display($time, " reset is not set to 1");
            // $finish;
        // end else begin
            // $display($time, " reset is set to 1");
        // end

        wait (led[0] == 1'b1); #1;

        if (led[10:1] !== exp_final_pc) begin
            $display("FAILED | Expected PC = %0h Got = %0h", exp_final_pc, led[10:1]);
        end else begin
            $display("PASSED | Expected PC = %0h Got = %0h", exp_final_pc, led[10:1]);
        end

        if (led[0] !== 1'b1) begin
            $display("FAILED | Expected led[0] (halted signal) = 1 Got = ", led[0]);
        end else begin
            $display("PASSED | Expected led[0] (halted signal) = 1 Got = ", led[0]);
        end

/*
        sw[1:0] = 2'b00; #20;
        if (top_module.display_value !== exp_final_pc) begin
            $display("FAILED | sw=00 (PC) | Expected = %0h display_value=%h", exp_final_pc, top_module.display_value);
        end else begin
            $display("PASSED | sw=00 (PC) | Expected = %0h display_value=%h", exp_final_pc, top_module.display_value);
        end

        sw[1:0] = 2'b01; #20;
        if (top_module.display_value !== exp_final_instr) begin
            $display("FAILED | sw=01 (instr) | Expected = %0h display_value=%h", exp_final_instr, top_module.display_value);
        end else begin
            $display("PASSED | sw=01 (instr) | Expected = %0h display_value=%h", exp_final_instr, top_module.display_value);
        end

        sw[1:0] = 2'b10; #20;
        if (top_module.display_value !== exp_final_alu_out) begin
            $display("FAILED | sw=10 (alu_out) | Expected = %0h display_value=%h", exp_final_alu_out, top_module.display_value);
        end else begin
            $display("PASSED | sw=10 (alu_out) | Expected = %0h display_value=%h", exp_final_alu_out, top_module.display_value);
        end

        sw[1:0] = 2'b11; #20;
        if (top_module.display_value !== exp_final_halted) begin
            $display("FAILED | sw=11 (halted) | Expected = %0h display_value=%h", top_module.display_value, exp_final_halted);
        end else begin
            $display("PASSED | sw=11 (halted) | Expected = %0h display_value=%h", top_module.display_value, exp_final_halted);
        end
*/

        $finish;
    end

    // Safety timeout in case halt never happens
    initial begin
        #2_000_000;
        $display($time, " TIMEOUT - processor never halted");
        $finish;
    end
endmodule