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

    initial begin
        $readmemh("regfile1.mem", bram1);
        $readmemh("regfile2.mem", bram2);
    end

    // BRAM 1: Handles Write (Port A) and Read rs (Port B)
    wire [31:0] rs_raw, rt_raw;
    reg  bypass_rs, bypass_rt;
    reg [31:0] wr_data_r;
    
    always @(posedge clk) begin
        bypass_rs <= reg_write && (wr_addr != 5'd0) && (wr_addr == rs_addr);
        bypass_rt <= reg_write && (wr_addr != 5'd0) && (wr_addr == rt_addr);
        wr_data_r <= wr_data;
    end
    
    // Unconditional read
    reg [31:0] rs_q, rt_q;
    always @(posedge clk) begin
        if (reg_write && (wr_addr != 5'd0)) begin
            bram1[wr_addr] <= wr_data;
            bram2[wr_addr] <= wr_data;
        end
        rs_q <= bram1[rs_addr];
        rt_q <= bram2[rt_addr];
    end
    
    always @(*) begin
        rs_data = bypass_rs ? wr_data_r : rs_q;
        rt_data = bypass_rt ? wr_data_r : rt_q;
    end
endmodule