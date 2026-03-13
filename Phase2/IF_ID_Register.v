module IF_ID(
    input clk,
    input reset,
    input IF_ID_Write,
    input IF_ID_Flush,        // new signal for branch flush
    input [31:0] instr_in,
    input [63:0] pc_in,
    output reg [31:0] instr_out,
    output reg [63:0] pc_out
);

always @(posedge clk or posedge reset) begin

    if(reset) begin
        instr_out <= 0;
        pc_out <= 0;
    end

    else if(IF_ID_Flush) begin
        instr_out <= 32'b0;   // insert NOP
        pc_out <= 0;
    end

    else if(IF_ID_Write) begin
        instr_out <= instr_in;
        pc_out <= pc_in;
    end

end

endmodule