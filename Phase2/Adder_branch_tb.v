`timescale 1ns/1ps
`include "Adder_branch.v"

module adder_branch_tb;
    reg [63:0] r1;
    reg [63:0] r2;
    wire [63:0] rd;
    adder_branch uut (.r1(r1), .r2(r2), .rd(rd));
    task check;
        input [63:0] expected;
        begin
            #20; 
            if (rd === expected)
                $display("PASS | r1=%h r2=%h -> rd=%h", r1, r2, rd);
            else
                $display("FAIL | r1=%h r2=%h expected=%h got=%h", r1, r2, expected, rd);
        end
    endtask
    initial begin
        $dumpfile("Adder_branch_tb.vcd");
        $dumpvars(0, adder_branch_tb);

        r1 = 64'd1000; r2 = 64'd32;
        check(64'd1032);

        r1 = 64'd1000; r2 = 64'hFFFFFFFFFFFFFFF0;
        check(64'd984);

        r1 = 64'h0000000040000000; r2 = 64'd0;
        check(64'h0000000040000000);

        r1 = 64'hFFFFFFFFFFFFFFFF; r2 = 64'd1;
        check(64'h0000000000000000);

        r1 = 64'hAAAAAAAAAAAAAAAA; r2 = 64'h5555555555555555;
        check(64'hFFFFFFFFFFFFFFFF);

        r1 = 64'hAAAAAAAAAAAAAAAA; r2 = 64'h5555555555555556;
        check(64'h0000000000000000);

        r1 = 64'd4; r2 = 64'hFFFFFFFFFFFFFFE0; 
        check(64'hFFFFFFFFFFFFFFE4);
        $finish;
    end
endmodule