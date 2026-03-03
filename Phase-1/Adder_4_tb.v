`timescale 1ns/1ps
`include "Adder_4.v"

module adder_4_tb;
    reg [63:0] pc_in;
    wire [63:0] pc_out;
    adder_4 uut (.pc_in(pc_in),.pc_out(pc_out));
    task check;
        input [63:0] expected;
        begin
            #10; 
            if (pc_out === expected)
                $display("PASS | pc_in=%h -> pc_out=%h", pc_in, pc_out);
            else
                $display("FAIL | pc_in=%h expected=%h got=%h", pc_in, expected, pc_out);
        end
    endtask

    initial begin
        $dumpfile("Adder_4_tb.vcd");
        $dumpvars(0, adder_4_tb);

        pc_in = 64'd0;
        check(64'd4);

        pc_in = 64'd100;
        check(64'd104);

        pc_in = 64'hFFFFFFFFFFFFFFFF;
        check(64'h0000000000000003);

        pc_in = 64'hFFFFFFFFFFFFFFFC;
        check(64'h0000000000000000);

        pc_in = 64'h00000000FFFFFFFC;
        check(64'h0000000100000000);

        pc_in = 64'h7FFFFFFFFFFFFFFC;
        check(64'h8000000000000000);

        pc_in = 64'hAAAAAAAAAAAAAAAA;
        check(64'hAAAAAAAAAAAAAAAE);
        $finish;
    end
endmodule