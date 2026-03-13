`timescale 1ns/1ps
`include "DataMem.v"

module DataMem_tb;
    reg clk, reset;
    reg  [63:0] address, write_data;
    reg  MemRead, MemWrite;
    wire [63:0] read_data;
    DataMem dut(
        .clk(clk), .reset(reset),
        .address(address), .write_data(write_data),
        .MemRead(MemRead), .MemWrite(MemWrite),
        .read_data(read_data));

    always #5 clk = ~clk;
    task check;
        input [63:0] got, expected;
        input [63:0] addr;
        begin
            if (got === expected)
                $display("PASS | addr=%0d data=%016h", addr, got);
            else
                $display("FAIL | addr=%0d expected=%016h got=%016h", addr, expected, got);
        end
    endtask
    task do_write;
        input [63:0] addr, data;
        begin
            address = addr; write_data = data;
            MemWrite = 1; MemRead = 0;
            @(posedge clk); #1;
            MemWrite = 0;
        end
    endtask
    task do_read;
        input [63:0] addr;
        begin
            address = addr;
            MemRead = 1; MemWrite = 0;
            @(posedge clk); #1;
            #1;
        end
    endtask
    initial begin
        clk = 0; reset = 1;
        address = 0; write_data = 0;
        MemRead = 0; MemWrite = 0;

        @(posedge clk); @(posedge clk); #1;
        reset = 0; #1;

        $display("VCD info: dumpfile datamem_tb.vcd opened for output.");

        do_read(64'd0);
        check(read_data, 64'h0, 64'd0);
        MemRead = 0;

        do_read(64'd100);
        check(read_data, 64'h0, 64'd100);
        MemRead = 0;

        do_write(64'd0, 64'hDEADBEEFCAFEBABE);
        do_read(64'd0);
        check(read_data, 64'hDEADBEEFCAFEBABE, 64'd0);
        MemRead = 0;

        do_write(64'd16, 64'h0102030405060708);
        do_read(64'd16);
        check(read_data, 64'h0102030405060708, 64'd16);
        MemRead = 0;

        do_read(64'd17);
        check(read_data, 64'h0203040506070800, 64'd17);
        MemRead = 0;

        do_write(64'd50, 64'hAAAAAAAAAAAAAAAA);
        do_write(64'd50, 64'h5555555555555555);
        do_read(64'd50);
        check(read_data, 64'h5555555555555555, 64'd50);
        MemRead = 0;

        do_write(64'd1016, 64'hCAFEBABEDEADBEEF);
        do_read(64'd1016);
        check(read_data, 64'hCAFEBABEDEADBEEF, 64'd1016);
        MemRead = 0;

        do_write(64'd1017, 64'hDEADDEADDEADDEAD);
        do_read(64'd1017);
        check(read_data, 64'h0, 64'd1017);
        MemRead = 0;

        reset = 1;
        @(posedge clk); @(posedge clk); #1;
        reset = 0; #1;
        do_read(64'd0);
        check(read_data, 64'h0, 64'd0);
        MemRead = 0;

        do_read(64'd1016);
        check(read_data, 64'h0, 64'd1016);
        MemRead = 0;

        do_write(64'd200, 64'hFFFFFFFFFFFFFFFF);
        address = 64'd200; MemRead = 0; MemWrite = 0; #1;
        check(read_data, 64'h0, 64'd200);

        do_write(64'd10, 64'h000000000000000F);
        do_read(64'd10);
        check(read_data, 64'h000000000000000F, 64'd10);
        MemRead = 0;

        do_write(64'd34, 64'hFFFFFFFFFFFFFFFB);
        do_read(64'd34);
        check(read_data, 64'hFFFFFFFFFFFFFFFB, 64'd34);
        MemRead = 0;

        do_write(64'd300, 64'hFFFFFFFFFFFFFFFF);
        do_write(64'd300, 64'h0000000000000000);
        do_read(64'd300);
        check(read_data, 64'h0000000000000000, 64'd300);
        MemRead = 0;
        $finish;
    end
endmodule