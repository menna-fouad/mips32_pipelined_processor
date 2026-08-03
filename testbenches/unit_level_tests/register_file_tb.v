module register_file_tb;
    reg clk = 0;
    reg reg_write = 0;
    reg [4:0] rs_addr, rt_addr, wr_addr;
    reg [31:0] wr_data;
    wire [31:0] rs_data, rt_data;

    reg [31:0] shadow [0:31];

    always #5 clk = ~clk;

    register_file registers (
        .clk(clk),
        .reg_write(reg_write),
        .rs_addr(rs_addr),
        .rs_data(rs_data),
        .rt_addr(rt_addr),
        .rt_data(rt_data),
        .wr_addr(wr_addr),
        .wr_data(wr_data)
    );

    integer k;
    integer seed1 = 42, seed2 = 0, seed3 = 5, seed4 = 99;
    initial begin
        for (k = 0; k < 32; k = k + 1) begin
            registers.bram1[k] = k;
            registers.bram2[k] = k;
            shadow[k] = k;
        end

        #2;

        #10 rs_addr = 5'd3; rt_addr = 5'd3; wr_addr = 5'd3; wr_data = 32'hDEAD_BEEF; reg_write = 1'b1;
        check(rs_addr, rt_addr, wr_addr, wr_data, reg_write);
        
        #10 rs_addr = 5'd7; rt_addr = 5'd12; wr_addr = 5'd7; wr_data = 32'h1234_5678; reg_write = 1'b1;
        check(rs_addr, rt_addr, wr_addr, wr_data, reg_write);

        #10 rs_addr = 5'd9; rt_addr = 5'd20; wr_addr = 5'd20; wr_data = 32'hCAFE_F00D; reg_write = 1'b1;
        check(rs_addr, rt_addr, wr_addr, wr_data, reg_write);

        #5 rs_addr = 5'd3; rt_addr = 5'd3; wr_addr = 5'd3; wr_data = 32'hFFFF_FFFF; reg_write = 1'b1;
        check(rs_addr, rt_addr, wr_addr, wr_data, reg_write);

        for (k = 0; k < 10; k = k + 1) begin
            #5;
            rs_addr = $random(seed1) % 32;
            rt_addr = $random(seed2) % 32;
            wr_addr = $random(seed3) % 32;
            wr_data = $random(seed4);
            reg_write = ~reg_write;
            check(rs_addr, rt_addr, wr_addr, wr_data, reg_write);
        end
    end

    initial begin
        $dumpfile("register_file_tb.wdb");
        $dumpvars(0, register_file_tb);
        #600 $finish;
    end

    task check(
        input [4:0] rs, rt, write_addr,
        input [31:0] write_data,
        input write
    );
        reg [31:0] exp_rs, exp_rt, exp_wr;
        begin
            if (write && write_addr != 5'b0) shadow[write_addr] = write_data;

            exp_rs = (rs == write_addr && write && write_addr != 5'b0) ? write_data : shadow[rs_addr];
            exp_rt = (rt == write_addr && write && write_addr != 5'b0) ? write_data : shadow[rt_addr];
            exp_wr = shadow[write_addr];
            
            @(posedge clk); #1;
            if (rs_data != exp_rs)
                $display("FAILED rs | rs_addr = %0d expected = %0d got = %0d", rs, exp_rs, rs_data);
            if (rt_data != exp_rt)
                $display("FAILED rt | rt_addr = %0d expected = %0d got = %0d", rt, exp_rt, rt_data);
            if (registers.bram1[write_addr] != exp_wr)
                $display("FAILED write to BRAM1 | wr_addr = %0d expected = %0d got = %0d",
                        write_addr, exp_wr, registers.bram1[write_addr]);
            if (registers.bram2[write_addr] != exp_wr)
                $display("FAILED write to BRAM2 | wr_addr = %0d expected = %0d got = %0d",
                        write_addr, exp_wr, registers.bram2[write_addr]);
            if (rs_data == exp_rs && rt_data == exp_rt && 
                registers.bram1[write_addr] == exp_wr && registers.bram2[write_addr] == exp_wr)
                $display("PASSED | rs = %0d rt = %0d wr_addr = %0d wr_data = %0d write = %0d",
                        rs, rt, write_addr, wr_data, write);
        end
    endtask
endmodule