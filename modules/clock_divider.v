module clk_divider # (
    parameter DIV_BITS = 26 // 2^26 / 100e6 Hz ~= 0.67s half-period (~0.75 Hz toggle)
) (
    input  wire clk_in,
    output wire clk_out
);
    reg [DIV_BITS-1:0] counter = 0;
    always @(posedge clk_in) counter <= counter + 1'b1;
    assign clk_out = counter[DIV_BITS-1];
endmodule
