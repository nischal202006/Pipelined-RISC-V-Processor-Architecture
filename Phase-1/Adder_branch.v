`timescale 1ns/1ps

module adder_branch(input [63:0]r1,r2,output [63:0] rd);
    wire [63:0] r12,temp1,temp2;
    wire [64:0] carry;
    assign carry[0] = 1'b0;
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            xor (r12[i],r1[i],r2[i]);
            xor (rd[i],r12[i],carry[i]);
            and (temp1[i],r1[i],r2[i]);
            and (temp2[i],r12[i],carry[i]);
            or (carry[i+1],temp1[i],temp2[i]);
        end
    endgenerate
endmodule