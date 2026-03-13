module control_mux(

    input ControlMux,     // from hazard detection unit

    input RegWrite_in,
    input MemRead_in,
    input MemWrite_in,
    input MemtoReg_in,
    input Branch_in,
    input ALUSrc_in,
    input [1:0] ALUOp_in,

    output reg RegWrite_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg MemtoReg_out,
    output reg Branch_out,
    output reg ALUSrc_out,
    output reg [1:0] ALUOp_out
);

always @(*) begin

    if(ControlMux) begin
        // Insert bubble (NOP)
        RegWrite_out = 0;
        MemRead_out  = 0;
        MemWrite_out = 0;
        MemtoReg_out = 0;
        Branch_out   = 0;
        ALUSrc_out   = 0;
        ALUOp_out    = 2'b00;
    end
    else begin
        // Normal control signals
        RegWrite_out = RegWrite_in;
        MemRead_out  = MemRead_in;
        MemWrite_out = MemWrite_in;
        MemtoReg_out = MemtoReg_in;
        Branch_out   = Branch_in;
        ALUSrc_out   = ALUSrc_in;
        ALUOp_out    = ALUOp_in;
    end

end

endmodule