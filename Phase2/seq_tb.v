`timescale 1ns/1ps
`include "seq.v"

module seq_tb;
    reg clk;
    reg reset;
    integer cycle_count;
    seq uut (.clk(clk), .reset(reset));
    always #5 clk = ~clk;
    always @(posedge clk) begin
        if (reset) begin
            cycle_count = 0;
        end else begin
            cycle_count = cycle_count + 1;
            if (cycle_count <= 100)
                $display("Cycle %0d: PC=%0d, Instr=0x%08h",cycle_count, uut.addr_out, uut.instruction);
            if (uut.instruction == 32'h00000000) begin
                $display("All Instruction are implimented,No of Cycles: %0d", cycle_count);
                uut.u3.dump_registers(cycle_count);
                #10 $finish;
            end
        end
    end
    initial begin
        #1000000;
        $display("TIMEOUT: Force stop at cycle %0d", cycle_count);
        uut.u3.dump_registers(cycle_count);
        $finish;
    end
    initial begin
        $dumpfile("seq_tb.vcd");
        $dumpvars(0, seq_tb);
        $display("Team: 'NRS i11 Processor' RISC-V Sequential Processor Simulation");
        clk = 0;
        reset = 1;
        cycle_count = 0;#12;
        reset = 0;
        $display("Reseted,Starting Program");
    end
endmodule