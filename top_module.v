module top_nexys_a7 #(
    parameter DEBOUNCE_BITS = 6,
    parameter DIV_BITS = 3
) (
    input  wire clk_100mhz, // pin E3, onboard oscillator
    input  wire btnC, // reset button
    input  wire btnU, // multiplexed clock button
    input  wire [15:0] sw, // sw[15] = 1: normal clock, otherwise step clock
    // sw[1:0] = which value to show on the 7-seg display

    output wire [15:0] led,
    output wire [7:0] an,
    output wire [6:0] seg
);
    wire reset_clean;
    debounce_sync #(.DEBOUNCE_BITS(DEBOUNCE_BITS)) reset_db (
        .clk(clk_100mhz),
        .raw_in(btnC),
        .clean_out(reset_clean)
    );

    // wire step_clean;
    // debounce_sync #(.DEBOUNCE_BITS(DEBOUNCE_BITS)) step_db (
        // .clk(clk_100mhz),
        // .raw_in(btnU),
        // .clean_out(step_clean)
    // );
    
    wire slow_clk_raw;
    clk_divider #(.DIV_BITS(DIV_BITS)) divider (
        .clk_in(clk_100mhz),
        .clk_out(slow_clk_raw)
    );
    
    wire slow_clk;
    BUFG clk_bufg_inst (
        .I(slow_clk_raw),
        .O(slow_clk)
    );
    
    reg reset_sync = 1'b0;
    reg reset = 1'b0;
    always @(posedge slow_clk) begin
        reset_sync <= reset_clean;
        reset <= reset_sync;
    end

    // BUFGMUX (not a plain assign-mux) avoids the glitch pulses a combinational clock mux can produce on real silicon.
    // wire proc_clk;
    // BUFGMUX clk_mux (
        // .O(proc_clk),
        // .I0(step_clean),
        // .I1(slow_clk),
        // .S(sw[15])
    // );
    
    // Processor
    wire [9:0] dbg_pc;
    wire dbg_halted;
    wire [31:0] dbg_alu_out;
    wire [31:0] dbg_instr;
    
    MIPS32 processor (
        .clk(slow_clk),
        .reset(reset),
        .dbg_pc(dbg_pc),
        .dbg_halted(dbg_halted),
        .dbg_alu_out(dbg_alu_out),
        .dbg_instr(dbg_instr)
    );

    // LEDs: halt flag + current PC
    assign led[0] = dbg_halted;
    assign led[10:1] = dbg_pc;
    assign led[15:11] = 5'b0;

    // 7-segment: pick what to display with sw[1:0]
    reg [31:0] display_value;
    always @(*) begin
        case (sw[1:0])
            2'b00: display_value = {22'b0, dbg_pc}; // current PC
            2'b01: display_value = dbg_instr; // instruction retiring in WB
            2'b10: display_value = dbg_alu_out; // latest ALU result (EX/MEM)
            default: display_value = {31'b0, dbg_halted};
        endcase
    end

    hex7seg_driver display (
        .clk(clk_100mhz),
        .value(display_value),
        .an(an),
        .seg(seg)
    );
endmodule
