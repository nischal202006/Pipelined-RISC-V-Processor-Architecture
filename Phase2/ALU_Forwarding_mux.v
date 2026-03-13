`timescale 1ps/1ps

module alu_forward_mux(
    input [63:0] reg_data,
    input [63:0] mem_stage_data,
    input [63:0] wb_stage_data,
    input [1:0] select,
    output reg [63:0] out
);

always @(*) begin

    case(select)

        2'b00: out = reg_data;
        2'b10: out = mem_stage_data;
        2'b01: out = wb_stage_data;
        default: out = reg_data;

    endcase

end

endmodule