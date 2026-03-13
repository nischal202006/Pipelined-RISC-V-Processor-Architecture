`timescale 1ns/1ps

module control_unit(
    input [6:0] opcode,
    output reg Branch, MemRead, MemtoReg, 
    output reg [1:0] ALUOp, 
    output reg MemWrite, ALUSrc, RegWrite
);
    localparam R_TYPE = 7'b0110011;  
    localparam I_TYPE = 7'b0010011;  
    localparam LOAD   = 7'b0000011;  
    localparam STORE  = 7'b0100011;  
    localparam BRANCH = 7'b1100011; 
    always @(*) begin
        Branch    = 1'b0;
        MemRead   = 1'b0;
        MemtoReg  = 1'b0;
        ALUOp     = 2'b00;
        MemWrite  = 1'b0;
        ALUSrc    = 1'b0;
        RegWrite  = 1'b0;
        case (opcode)
            R_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                ALUOp    = 2'b10;
                MemtoReg = 1'b0;   
            end
            I_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b10;
                MemtoReg = 1'b0;    
            end
            LOAD: begin
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                MemtoReg = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end
            STORE: begin
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end
            BRANCH: begin
               Branch = 1'b1;
               ALUOp  = 2'b01;
            end
        endcase
    end
endmodule