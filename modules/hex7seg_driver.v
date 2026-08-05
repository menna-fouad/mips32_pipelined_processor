module hex7seg_driver (
    input  wire clk,     // 100 MHz board clock (refresh timing only, not the CPU clock)
    input  wire [31:0] value,
    output reg  [7:0]  an,      // anodes, active-low, an[0] = rightmost digit
    output reg  [6:0]  seg      // segments a..g, active-low (common-anode display)
);
    // ~763 Hz per-digit refresh -> whole 8-digit frame refreshes ~95 Hz, flicker-free
    reg [16:0] refresh_counter = 0;
    always @(posedge clk) refresh_counter <= refresh_counter + 1'b1;

    wire [2:0] digit_sel = refresh_counter[16:14];

    reg [3:0] nibble;
    always @(*) begin
        case (digit_sel)
            3'd0: nibble = value[3:0];
            3'd1: nibble = value[7:4];
            3'd2: nibble = value[11:8];
            3'd3: nibble = value[15:12];
            3'd4: nibble = value[19:16];
            3'd5: nibble = value[23:20];
            3'd6: nibble = value[27:24];
            3'd7: nibble = value[31:28];
            default: nibble = 4'h0;
        endcase
    end

    always @(*) begin
        an = 8'b11111111;
        an[digit_sel] = 1'b0; // drive exactly one digit's anode low at a time
    end

    always @(*) begin
        case (nibble)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
