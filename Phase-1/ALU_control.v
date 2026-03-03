module ALU_control(
    input  [1:0] ALUOp,
    input  funct7_5, 
    input  [2:0] funct3,
    output reg [3:0] ALUControl);

    always @(*) begin
        case (ALUOp)
            2'b00: begin
                ALUControl = 4'b0010; // ADD
            end
            2'b01: begin
                ALUControl = 4'b0110; // SUB
            end
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (funct7_5)
                            ALUControl = 4'b0110; // SUB
                        else
                            ALUControl = 4'b0010; // ADD
                    end
                    3'b111: begin
                        ALUControl = 4'b0000; // AND
                    end
                    3'b110: begin
                        ALUControl = 4'b0001; // OR
                    end
                    default: begin
                        ALUControl = 4'b0010; //ADD
                    end
                endcase
            end
             2'b11: begin
                case (funct3)
                    3'b000: ALUControl = 4'b0010; // ADDI = ADD
                    3'b111: ALUControl = 4'b0000; // ANDI = AND
                    3'b110: ALUControl = 4'b0001; // ORI  = OR
                    default: ALUControl = 4'b0010; // ADD
                endcase
            end
            default: begin
                ALUControl = 4'b0010; // ADD
            end
        endcase
    end
endmodule