module debounce_sync #(
    parameter DEBOUNCE_BITS = 17 // ~1.3ms @100MHz; raise for a "clean" hand-press step button
)(
    input  wire clk,
    input  wire raw_in,
    output reg  clean_out
);
    // Stage 1: two-flop synchronizer to pull the async pin into this clock domain
    reg sync0, sync1;
    always @(posedge clk) begin
        sync0 <= raw_in;
        sync1 <= sync0;
    end

    // Only accept a new level once it has been stable for 2^DEBOUNCE_BITS cycles
    reg [DEBOUNCE_BITS-1:0] count;
    initial clean_out = 1'b0;

    always @(posedge clk) begin
        if (sync1 != clean_out) begin
            count <= count + 1'b1;
            if (&count) begin
                clean_out <= sync1;
                count <= 0;
            end
        end else count <= 0;
    end
endmodule
