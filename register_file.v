module register_file (
    input clk,
    input reg_write,
    input [4:0] rs_addr,
    input [4:0] rt_addr,
    input [4:0] wr_addr,
    input [31:0] wr_data,
    output reg [31:0] rs_data,
    output reg [31:0] rt_data
);
    (* ram_style = "block" *) reg [31:0] bram1 [0:31];
    (* ram_style = "block" *) reg [31:0] bram2 [0:31];

    // BRAM 1: Handles Write (Port A) and Read rs (Port B)
    always @(posedge clk) begin
        if (reg_write && (wr_addr != 5'b0)) begin
            bram1[wr_addr] <= wr_data;
        end
        
        if (reg_write && (wr_addr != 5'b0) && (wr_addr == rs_addr))
            rs_data <= wr_data; // Forwarding
        else
            rs_data <= bram1[rs_addr];
    end

    // BRAM 2: Handles Write (Port A) and Read rt (Port B)
    always @(posedge clk) begin
        if (reg_write && (wr_addr != 5'b0)) begin
            bram2[wr_addr] <= wr_data;
        end
        
        if (reg_write && (wr_addr != 5'b0) && (wr_addr == rt_addr))
            rt_data <= wr_data; // Forwarding
        else
            rt_data <= bram2[rt_addr];
    end
endmodule