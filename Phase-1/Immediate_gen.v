module immediate_gen(
    input [31:0] instr,
    output reg [63:0] immediate_val);
    localparam I_TYPE_ALU = 7'b0010011; 
    localparam I_TYPE_LD  = 7'b0000011;
    localparam S_TYPE     = 7'b0100011;
    localparam B_TYPE     = 7'b1100011;
    always @(*) begin
        case (instr[6:0])
            I_TYPE_ALU, I_TYPE_LD: begin
                immediate_val = {{52{instr[31]}},instr[31:20]};
            end
            S_TYPE: begin
                immediate_val = {{52{instr[31]}},instr[31:25],instr[11:7]};
            end
            B_TYPE: begin
                 immediate_val = {{52{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8]};
            end
            default: begin
                immediate_val = 64'b0;
            end
        endcase
    end
endmodule