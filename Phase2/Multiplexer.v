`timescale 1ns/1ps

module multiplexer(input [63:0] I1,I2,input S,output [63:0] mux_out);
    wire [63:0] temp1,temp2;
    wire not_S;
    not (not_S, S);
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            and (temp1[i],I1[i],not_S);
            and (temp2[i],I2[i],S);
            or  (mux_out[i],temp1[i],temp2[i]);
        end
    endgenerate
endmodule