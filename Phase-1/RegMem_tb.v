`timescale 1ns/1ps
`include "RegMem.v"

module RegMem_tb;
    reg clk, reset;
    reg [4:0] read_reg1, read_reg2, write_reg;
    reg [63:0] write_data;
    reg reg_write_en;
    wire [63:0] read_data1, read_data2;
    RegMem uut (
        .clk(clk),
        .reset(reset),
        .read_reg1(read_reg1),.read_reg2(read_reg2),.write_reg(write_reg),
        .write_data(write_data),
        .reg_write_en(reg_write_en),
        .read_data1(read_data1),.read_data2(read_data2));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("RegMem_tb.vcd");
        $dumpvars(0, RegMem_tb);
        
        reset = 1;
        reg_write_en = 0;
        read_reg1 = 0;
        read_reg2 = 0;
        write_reg = 0;
        write_data = 0;
        #10;
        reset = 0;
        read_reg1 = 5'd1;
        #1;
        $display("RESET TEST: x1 = %h (expected 0)", read_data1);

        @(posedge clk);
        reg_write_en = 1;
        write_reg = 5'd1;
        write_data = 64'hDEAD_BEEF_CAFE_BABE;

        @(posedge clk);
        reg_write_en = 0;
        read_reg1 = 5'd1;
        read_reg2 = 5'd0;
        #1;
        $display("WRITE TEST: x1 = %h (expected DEAD_BEEF_CAFE_BABE)", read_data1);
        $display("WRITE TEST: x0 = %h (expected 0)", read_data2);

        @(posedge clk);
        reg_write_en = 1;
        write_reg = 5'd0;
        write_data = 64'hFFFF_FFFF_FFFF_FFFF;

        @(posedge clk);
        reg_write_en = 0;
        read_reg1 = 5'd0;
        #1;
        $display("x0 TEST: x0 = %h (expected 0)", read_data1);

        @(posedge clk);
        reg_write_en = 1; write_reg = 5'd2; write_data = 64'd10;
        @(posedge clk);
        write_reg = 5'd3; write_data = 64'd20;
        @(posedge clk);
        reg_write_en = 0;

        read_reg1 = 5'd2;
        read_reg2 = 5'd3;
        #1;
        $display("MULTI WRITE: x2 = %d (expected 10)", read_data1);
        $display("MULTI WRITE: x3 = %d (expected 20)", read_data2);

        read_reg1 = 5'd3;
        read_reg2 = 5'd3;
        #1;
        $display("DUAL READ: x3 = %d , %d (expected 20,20)",read_data1, read_data2);
        reset = 1; #10; reset = 0;
        read_reg1 = 5'd1;
        read_reg2 = 5'd2;
        #1;
        $display("RESET AFTER WRITE: x1=%h x2=%h (expected 0,0)",read_data1, read_data2);

        @(posedge clk);
        reg_write_en = 1;
        write_reg = 5'd5;
        write_data = 64'h1234_5678_9ABC_DEF0;
        @(posedge clk);
        reg_write_en = 0;
        read_reg1 = 5'd5;
        #1;
        $display("POST RESET WRITE: x5=%h (expected 123456789ABCDEF0)",read_data1);

        uut.dump_registers(42);
        $display("register_file.txt dumped (cycle_count = 42)");
        $finish;
    end
endmodule
