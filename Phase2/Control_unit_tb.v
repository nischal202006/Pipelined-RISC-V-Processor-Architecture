`timescale 1ns/1ps
`include "Control_unit.v"

module control_unit_tb;
    reg  [6:0] opcode;
    wire Branch, MemRead, MemtoReg;
    wire [1:0] ALUOp;
    wire MemWrite, ALUSrc, RegWrite;
    control_unit uut (
        .opcode(opcode),
        .Branch(Branch),.MemRead(MemRead),.MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),.ALUSrc(ALUSrc),.RegWrite(RegWrite));
    initial begin
        $dumpfile("Control_unit_tb.vcd");
        $dumpvars(0, control_unit_tb);

        opcode = 7'b0110011; #1;
        $display("R-TYPE   GOT | Br=%b MR=%b M2R=%b ALUOp=%b MW=%b ASrc=%b RW=%b",
                 Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);
        $display("R-TYPE   EXP | Br=0 MR=0 M2R=0 ALUOp=10 MW=0 ASrc=0 RW=1\n");

        opcode = 7'b0010011; #1;
        $display("I-TYPE   GOT | Br=%b MR=%b M2R=%b ALUOp=%b MW=%b ASrc=%b RW=%b",
                 Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);
        $display("I-TYPE   EXP | Br=0 MR=0 M2R=0 ALUOp=10 MW=0 ASrc=1 RW=1\n");

        opcode = 7'b0000011; #1;
        $display("LOAD     GOT | Br=%b MR=%b M2R=%b ALUOp=%b MW=%b ASrc=%b RW=%b",
                 Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);
        $display("LOAD     EXP | Br=0 MR=1 M2R=1 ALUOp=00 MW=0 ASrc=1 RW=1\n");

        opcode = 7'b0100011; #1;
        $display("STORE    GOT | Br=%b MR=%b M2R=%b ALUOp=%b MW=%b ASrc=%b RW=%b",
                 Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);
        $display("STORE    EXP | Br=0 MR=0 M2R=0 ALUOp=00 MW=1 ASrc=1 RW=0\n");

        opcode = 7'b1100011; #1;
        $display("BRANCH   GOT | Br=%b MR=%b M2R=%b ALUOp=%b MW=%b ASrc=%b RW=%b",
                 Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);
        $display("BRANCH   EXP | Br=1 MR=0 M2R=0 ALUOp=01 MW=0 ASrc=0 RW=0\n");

        opcode = 7'b1111111; #1;
        $display("INVALID  GOT | Br=%b MR=%b M2R=%b ALUOp=%b MW=%b ASrc=%b RW=%b",
                 Branch, MemRead, MemtoReg, ALUOp, MemWrite, ALUSrc, RegWrite);
        $display("INVALID  EXP | Br=0 MR=0 M2R=0 ALUOp=00 MW=0 ASrc=0 RW=0\n");
        $finish;
    end
endmodule
