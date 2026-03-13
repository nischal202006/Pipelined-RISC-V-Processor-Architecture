`timescale 1ns/1ps
`include "PC.v"

module pc_tb;
    reg clk, reset;
    reg [63:0] pc_in;
    wire [63:0] pc_out;
    pc uut (
        .clk(clk),.reset(reset),
        .pc_in(pc_in),
        .pc_out(pc_out));
    initial clk = 0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("Pc_tb.vcd");
        $dumpvars(0, pc_tb);
        reset = 1;
        pc_in = 64'd0;
        #10;
        $display("After reset:       pc_out = %0d (expected 0)", pc_out);
       
        reset = 0;
        pc_in = 64'd4;
        #10;
        $display("PC+4:              pc_out = %0d (expected 4)", pc_out);
        
        pc_in = 64'd8;
        #10;
        $display("PC+4:              pc_out = %0d (expected 8)", pc_out);
        
        pc_in = 64'd12;
        #10;
        $display("PC+4:              pc_out = %0d (expected 12)", pc_out);
        
        pc_in = 64'd40;
        #10;
        $display("Branch to 40:      pc_out = %0d (expected 40)", pc_out);
       
        pc_in = 64'd44;
        #10;
        $display("PC+4 after branch: pc_out = %0d (expected 44)", pc_out);
        
        reset = 1;
        #10;
        $display("Mid-run reset:     pc_out = %0d (expected 0)", pc_out);
        
        reset = 0;
        pc_in = 64'd4;
        #10;
        $display("Resume after reset: pc_out = %0d (expected 4)", pc_out);
        $display("\nAll PC tests completed.");
        $finish;
    end
endmodule