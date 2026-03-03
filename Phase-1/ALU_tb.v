`timescale 1ns/1ps
`include "ALU.v"

module alu_64_bit_tb;
    reg  [63:0] a, b;
    reg  [3:0]  control_signal;
    wire [63:0] result;
    wire        zero_flag;
    localparam ADD_Oper = 4'b0010,
               SUB_Oper = 4'b0110,
               AND_Oper = 4'b0000,
               OR_Oper  = 4'b0001;
    alu_64_bit uut(
        .input1(a),
        .input2(b),
        .control_signal(control_signal),
        .result(result),
        .zero_flag(zero_flag));
    task test;
        input [63:0] t_a, t_b, exp;
        input [3:0]  op;
        input        exp_zero;
        begin
            a = t_a;
            b = t_b;
            control_signal = op;
            #5;

            if (result == exp && zero_flag == exp_zero)
                $display("PASS | op=%b A=%h B=%h => %h Z=%b",
                          op, t_a, t_b, result, zero_flag);
            else begin
                $display("FAIL | op=%b A=%h B=%h", op, t_a, t_b);
                $display("Expected: %h Z=%b", exp, exp_zero);
                $display("Got:      %h Z=%b", result, zero_flag);
            end
        end
    endtask

    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, alu_64_bit_tb);

        test(64'd5, 64'd3, 64'd8, ADD_Oper, 0);
        test(64'hFFFFFFFFFFFFFFFF, 64'd1, 64'h0, ADD_Oper, 1);   // wrap
        test(64'h7FFFFFFFFFFFFFFF, 64'd1, 64'h8000000000000000, ADD_Oper, 0);
        test(64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555,
             64'hFFFFFFFFFFFFFFFF, ADD_Oper, 0);

        test(64'd10, 64'd4, 64'd6, SUB_Oper, 0);
        test(64'd1, 64'd1, 64'd0, SUB_Oper, 1);
        test(64'h0, 64'd1, 64'hFFFFFFFFFFFFFFFF, SUB_Oper, 0);
        test(64'h8000000000000000, 64'd1,
             64'h7FFFFFFFFFFFFFFF, SUB_Oper, 0);

        test(64'hFFFFFFFFFFFFFFFF, 64'h0,
             64'h0, AND_Oper, 1);
        test(64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555,
             64'h0, AND_Oper, 1);
        test(64'hDEADBEEFCAFEBABE, 64'hFFFFFFFF00000000,
             64'hDEADBEEF00000000, AND_Oper, 0);

        test(64'h0, 64'hFFFFFFFFFFFFFFFF,
             64'hFFFFFFFFFFFFFFFF, OR_Oper, 0);
        test(64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555,
             64'hFFFFFFFFFFFFFFFF, OR_Oper, 0);
        test(64'h00000000FFFFFFFF, 64'hFFFFFFFF00000000,
             64'hFFFFFFFFFFFFFFFF, OR_Oper, 0);

        test(64'h1234, 64'h5678, 64'h0, 4'b1111, 1);
        $finish;
    end
endmodule
