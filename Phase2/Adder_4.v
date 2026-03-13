`timescale 1ns/1ps

module adder_4(input [63:0] pc_in,output [63:0] pc_out);
    wire [63:0] r2,r12,temp1,temp2;
    wire [64:0] carry;
    assign r2 = 64'd4;
    assign carry[0] = 1'b0;
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            xor (r12[i],pc_in[i],r2[i]);
            xor (pc_out[i],r12[i],carry[i]);
            and (temp1[i],pc_in[i],r2[i]);
            and (temp2[i],r12[i],carry[i]);
            or (carry[i+1],temp1[i],temp2[i]);
        end
    endgenerate
endmodule