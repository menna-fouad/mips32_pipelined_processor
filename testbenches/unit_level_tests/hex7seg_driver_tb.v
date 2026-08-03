module hex7seg_driver_tb;
    localparam PERIOD = (2 ** 14) * 10;

    reg clk = 0;
    reg [31:0] value = 0;
    wire [7:0] an;
    wire [6:0] seg;

    always #5 clk = ~clk;

    hex7seg_driver driver (
        .clk(clk),
        .value(value),
        .seg(seg),
        .an(an)
    );

    initial begin
        $dumpfile("hex7seg_driver_tb.wdb");
        $dumpvars(0, hex7seg_driver_tb);
    end

    function [6:0] segments (input [3:0] dgt);
        case (dgt)
            4'h0: segments = 7'b1000000;
            4'h1: segments = 7'b1111001;
            4'h2: segments = 7'b0100100;
            4'h3: segments = 7'b0110000;
            4'h4: segments = 7'b0011001;
            4'h5: segments = 7'b0010010;
            4'h6: segments = 7'b0000010;
            4'h7: segments = 7'b1111000;
            4'h8: segments = 7'b0000000;
            4'h9: segments = 7'b0010000;
            4'hA: segments = 7'b0001000;
            4'hB: segments = 7'b0000011;
            4'hC: segments = 7'b1000110;
            4'hD: segments = 7'b0100001;
            4'hE: segments = 7'b0000110;
            4'hF: segments = 7'b0001110;
            default: segments = 7'b1111111;
        endcase
    endfunction

    task check(input [2:0] active_digit);
        reg [6:0] exp_seg;
        reg [7:0] exp_an;
        begin
            #1; // let the just-completed edge settle

            exp_seg = segments(value[active_digit * 4 +: 4]);
            exp_an = 8'b11111111;
            exp_an[active_digit] = 1'b0;

            if (an !== exp_an) begin
                $display("FAILED an | time=%0d | active_digit=%0d expected=%b got=%b", $time, active_digit, exp_an, an);
            end
            if (seg !== exp_seg) begin
                $display("FAILED seg | time=%0d | active_digit=%0d value=%h expected=%b got=%b", $time, active_digit, value, exp_seg, seg);
            end
            if (an === exp_an && seg === exp_seg)
                $display("PASSED | time=%0d | active_digit=%0d value=%h an=%b seg=%b", $time, active_digit, value, an, seg);
        end
    endtask

    integer i, j;
    reg [31:0] test_values [0:3];
    reg [3:0] digit;
    integer seed = 42;

    initial begin
        test_values[0] = 32'h00000000;
        test_values[1] = 32'hFFFFFFFF;
        test_values[2] = 32'h12345678;
        test_values[3] = 32'hDEADBEEF;

        // general test cases
        for (i = 0; i < 4; i = i + 1) begin
            value = test_values[i];
            for (j = 0; j < 10; j = j + 1) begin
                #($unsigned($random(seed)) % (PERIOD * 3)); // wait a random time between 0 and 3 clock periods
                digit = ($time / PERIOD) % 8;
                check(digit);
            end
        end
        $finish;
    end
endmodule