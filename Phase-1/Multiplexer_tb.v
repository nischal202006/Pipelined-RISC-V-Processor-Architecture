`timescale 1ns/1ps
`include "Multiplexer.v"

module multiplexer_tb;
    reg [63:0] I1;
    reg [63:0] I2;
    reg S;
    wire [63:0] mux_out;
    multiplexer uut (
        .I1(I1), .I2(I2), 
        .S(S), 
        .mux_out(mux_out));
    task check;
        input [63:0] expected;
        begin
            #1;
            if (mux_out === expected)
                $display("PASS | S=%b I1=%h I2=%h -> out=%h", S, I1, I2, mux_out);
            else
                $display("FAIL | S=%b expected=%h got=%h", S, expected, mux_out);
        end
    endtask

    initial begin
        $dumpfile("multiplexer_tb.vcd");
        $dumpvars(0, multiplexer_tb);
        
        I1 = 64'h00000000000000AA; 
        I2 = 64'h00000000000000BB; 
        S = 0;
        check(64'h00000000000000AA);

        S = 1;
        check(64'h00000000000000BB);

        I1 = 64'h0; I2 = 64'h0; 
        S = 0; check(64'h0);
        S = 1; check(64'h0);

        I1 = 64'hFFFFFFFFFFFFFFFF; 
        I2 = 64'hFFFFFFFFFFFFFFFF; 
        S = 0; check(64'hFFFFFFFFFFFFFFFF);
        S = 1; check(64'hFFFFFFFFFFFFFFFF);

        I1 = 64'hAAAAAAAAAAAAAAAA; 
        I2 = 64'h5555555555555555;
        S = 0; check(64'hAAAAAAAAAAAAAAAA);
        S = 1; check(64'h5555555555555555);

        I1 = 64'hFFFFFFFFFFFFFFFF;
        I2 = 64'h0000000000000000;
        S = 1; check(64'h0000000000000000); 
        S = 0; check(64'hFFFFFFFFFFFFFFFF);
        $finish;
    end
endmodule