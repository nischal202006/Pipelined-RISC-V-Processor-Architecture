`timescale 1ns/1ps
`include "Instruction_mem.v"

module instruction_mem_tb;
    reg clk, reset;
    reg [63:0] addr;
    wire [31:0] instr;
    instruction_mem uut(
        .clk(clk),.reset(reset),
        .addr(addr),
        .instr(instr));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("Instruction_mem_tb.vcd");
        $dumpvars(0, instruction_mem_tb);

        reset = 1;
        addr  = 0;
        #10;
        reset = 0;
        
        addr = 64'd0;
        @(posedge clk); #1;
        $display("addr 0   | GOT = %h | EXP = 00500113", instr);
       
        addr = 64'd4;
        @(posedge clk); #1;
        $display("addr 4   | GOT = %h | EXP = 00A00193", instr);
        
        addr = 64'd8;
        @(posedge clk); #1;
        $display("addr 8   | GOT = %h | EXP = 003100B3", instr);
       
        addr = 64'd32;
        @(posedge clk); #1;
        $display("addr 32  | GOT = %h | EXP = 0012B023", instr);
       
        addr = 64'd56;
        @(posedge clk); #1;
        $display("addr 56  | GOT = %h | EXP = 00A086B3", instr);

        addr = 64'd100;
        @(posedge clk); #1;
        $display("addr 100 | GOT = %h | EXP = 00000000", instr);

        reset = 1; #10; reset = 0;
        addr = 64'd0;
        @(posedge clk); #1;
        $display("after reset addr 0 | GOT = %h | EXP = 00500113", instr);
        $finish;
    end
endmodule
