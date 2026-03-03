`timescale 1ns/1ps

module pc(input clk, reset, input [63:0] pc_in, output [63:0] pc_out);
    reg [63:0] pc_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_reg <= 64'd0;
        else
            pc_reg <= pc_in;
    end
    assign pc_out = pc_reg;
endmodule