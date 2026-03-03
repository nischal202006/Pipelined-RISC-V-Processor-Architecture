`timescale 1ns/1ps
`include "Immediate_gen.v"

module Immediate_gen_tb;
    reg  [31:0] instr;
    wire [63:0] immediate_val;
    immediate_gen uut (
        .instr(instr),
        .immediate_val(immediate_val));
    initial begin
        $dumpfile("Immediate_gen_tb.vcd");
        $dumpvars(0, Immediate_gen_tb);
        
        instr = 32'h7FF00093;  #1;  
        $display("I-type max  (+2047) = %0d", $signed(immediate_val));
        instr = 32'h80000093;  #1;  
        $display("I-type min  (-2048) = %0d", $signed(immediate_val));
      
        instr = 32'h7E12BFA3;  #1;  
        $display("S-type max  (+2047) = %0d", $signed(immediate_val));
        instr = 32'h8012B023;  #1;  
        $display("S-type min  (-2048) = %0d", $signed(immediate_val));
        
        instr = 32'h00000163;  #1;  
        $display("B-type min  (+1)    = %0d", $signed(immediate_val));
        instr = 32'hFE000FE3;  #1;  
        $display("B-type min  (-1)    = %0d", $signed(immediate_val));
        instr = 32'h7E001FE3;  #1; 
        $display("B-type max  (+2047) = %0d", $signed(immediate_val));
        instr = 32'h80000063;  #1;  
        $display("B-type min  (-2048) = %0d", $signed(immediate_val));
       
        instr = 32'h003100B3;  #1; 
        $display("R-type imm          = %0d", $signed(immediate_val));
        $finish;
    end
endmodule
