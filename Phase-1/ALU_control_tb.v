`timescale 1ns/1ps
`include "ALU_control.v"

module ALU_control_tb;
    reg  [1:0] ALUOp;
    reg        funct7_5;
    reg  [2:0] funct3;
    wire [3:0] ALUControl;
    ALU_control uut (
        .ALUOp(ALUOp),
        .funct7_5(funct7_5),
        .funct3(funct3),
        .ALUControl(ALUControl));
    initial begin
        $dumpfile("ALU_control_tb.vcd");
        $dumpvars(0, ALU_control_tb);

        ALUOp = 2'b00; funct7_5 = 0; funct3 = 3'b000; #5;
        $display("ALUOp=00 -> %b (Expected 0010 ADD)", ALUControl);

        ALUOp = 2'b01; funct7_5 = 0; funct3 = 3'b000; #5;
        $display("ALUOp=01 -> %b (Expected 0110 SUB)", ALUControl);

        ALUOp = 2'b10; funct7_5 = 0; funct3 = 3'b000; #5;
        $display("R-ADD -> %b (Expected 0010)", ALUControl);

        ALUOp = 2'b10; funct7_5 = 1; funct3 = 3'b000; #5;
        $display("R-SUB -> %b (Expected 0110)", ALUControl);

        ALUOp = 2'b10; funct7_5 = 0; funct3 = 3'b111; #5;
        $display("R-AND -> %b (Expected 0000)", ALUControl);

        ALUOp = 2'b10; funct7_5 = 0; funct3 = 3'b110; #5;
        $display("R-OR  -> %b (Expected 0001)", ALUControl);

        ALUOp = 2'b11; funct7_5 = 0; funct3 = 3'b000; #5;
        $display("DEFAULT -> %b (Expected 0010 ADD)", ALUControl);
        $finish;
    end
endmodule
