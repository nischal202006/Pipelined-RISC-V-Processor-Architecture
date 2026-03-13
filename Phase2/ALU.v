`timescale 1ns/1ps

module add(input [63:0]r1,r2,output [63:0] rd,output flag,output cout);
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
    xor (flag,carry[63],carry[64]);
    assign cout = carry[64];
endmodule

module sub(input [63:0]r1,r2,output [63:0] rd,output flag,cout);
    wire [63:0] r12,temp1,temp2,r2_comple;
    wire [64:0] carry;
    assign carry[0] = 1'b1;
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            not (r2_comple[i],r2[i]);
            xor (r12[i],r1[i],r2_comple[i]);
            xor (rd[i],r12[i],carry[i]);
            and (temp1[i],r1[i],r2_comple[i]);
            and (temp2[i],r12[i],carry[i]);
            or (carry[i+1],temp1[i],temp2[i]);
        end
    endgenerate
    xor (flag,carry[63],carry[64]);
    assign cout = carry[64];
endmodule

module Xor(input [63:0]r1,r2,output [63:0] rd,output flag);
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            xor (rd[i],r1[i],r2[i]);
        end
    endgenerate
    assign flag = 1'b0;
endmodule

module Or(input [63:0]r1,r2,output [63:0] rd,output flag);
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            or (rd[i],r1[i],r2[i]);
        end
    endgenerate
    assign flag = 1'b0;
endmodule

module And(input [63:0]r1,r2,output [63:0] rd,output flag);
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            and (rd[i],r1[i],r2[i]);
        end
    endgenerate
    assign flag = 1'b0;
endmodule

module sll(input [63:0]r1,r2,output [63:0] rd,output flag);
    wire [63:0] s1, s2, s4, s8, s16, s32;
    assign s1  = r2[0] ? {r1[62:0], 1'b0}     : r1;
    assign s2  = r2[1] ? {s1[61:0], 2'b00}    : s1;
    assign s4  = r2[2] ? {s2[59:0], 4'b0000}  : s2;
    assign s8  = r2[3] ? {s4[55:0], 8'b0}     : s4;
    assign s16 = r2[4] ? {s8[47:0], 16'b0}    : s8;
    assign s32 = r2[5] ? {s16[31:0], 32'b0}   : s16;
    assign rd = s32;
    assign flag = 1'b0;
endmodule


module alu_64_bit(input [63:0] input1,input2, input [3:0] control_signal,
                  output [63:0] result,output zero_flag);
    wire [63:0] add_res, sub_res, and_res, or_res;
    wire add_ov, sub_ov,add_car,sub_car;
    localparam  ADD_Oper  = 4'b0010,
                OR_Oper   = 4'b0001,
                AND_Oper  = 4'b0000,
                SUB_Oper  = 4'b0110;
    add  U_ADD  (.r1(input1), .r2(input2), .rd(add_res),  .flag(add_ov), .cout(add_car));
    sub  U_SUB  (.r1(input1), .r2(input2), .rd(sub_res),  .flag(sub_ov), .cout(sub_car));
    And  U_AND  (.r1(input1), .r2(input2), .rd(and_res),  .flag());
    Or   U_OR   (.r1(input1), .r2(input2), .rd(or_res),   .flag());
    reg [63:0] result_reg;
        always @(*) begin
        case (control_signal)
            ADD_Oper: result_reg = add_res;
            SUB_Oper: result_reg = sub_res;
            AND_Oper: result_reg = and_res;
            OR_Oper : result_reg = or_res;
            default:  result_reg = 64'b0;
        endcase
    end
    assign result     = result_reg;
    assign zero_flag  = ~(|result_reg);
endmodule