module ID_EX(

    input clk,
    input reset,
    input ID_EX_Flush,   // new signal for bubble

    input [63:0] pc_in,
    input [63:0] reg1_in,
    input [63:0] reg2_in,
    input [63:0] imm_in,

    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,

    input RegWrite_in,
    input MemRead_in,
    input MemWrite_in,
    input MemtoReg_in,

    output reg [63:0] pc_out,
    output reg [63:0] reg1_out,
    output reg [63:0] reg2_out,
    output reg [63:0] imm_out,

    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,

    output reg RegWrite_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg MemtoReg_out
);

always @(posedge clk or posedge reset) begin

    if(reset) begin
        pc_out <= 0;
        reg1_out <= 0;
        reg2_out <= 0;
        imm_out <= 0;
        rs1_out <= 0;
        rs2_out <= 0;
        rd_out <= 0;

        RegWrite_out <= 0;
        MemRead_out <= 0;
        MemWrite_out <= 0;
        MemtoReg_out <= 0;
    end

    else if(ID_EX_Flush) begin
        // insert bubble (NOP)
        RegWrite_out <= 0;
        MemRead_out  <= 0;
        MemWrite_out <= 0;
        MemtoReg_out <= 0;
    end

    else begin
        pc_out <= pc_in;
        reg1_out <= reg1_in;
        reg2_out <= reg2_in;
        imm_out <= imm_in;

        rs1_out <= rs1_in;
        rs2_out <= rs2_in;
        rd_out <= rd_in;

        RegWrite_out <= RegWrite_in;
        MemRead_out <= MemRead_in;
        MemWrite_out <= MemWrite_in;
        MemtoReg_out <= MemtoReg_in;
    end

end

endmodule