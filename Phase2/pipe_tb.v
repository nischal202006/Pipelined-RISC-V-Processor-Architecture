`timescale 1ns/1ps
`include "pipe.v"

module pipe_tb; 
    reg clk;
    reg reset;
    integer cycle_count;
    pipeline uut (.clk(clk), .reset(reset));
    always #5 clk = ~clk;
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            if (cycle_count <= 2000) begin
                if (uut.instruction == 32'h00000000 &&
                    uut.pc_current !== 64'h0) begin
                  
                    $display("Pipeline execution complete at cycle %0d", cycle_count);
                    uut.RF.dump_registers(cycle_count);
                    $display("Total cycles: %0d", cycle_count);
                    #20 $finish;
                end
                $display("Cycle %3d | PC=%3d | IF_Instr=0x%08h | IF_ID_Instr=0x%08h | WB_rd=x%0d WB_data=0x%h WB_en=%b",
                    cycle_count,
                    uut.pc_current,
                    uut.instruction,
                    uut.IF_ID_instr,
                    uut.MEM_WB_rd,
                    uut.write_back_data,
                    uut.MEM_WB_RegWrite
                );
            end
        end
    end
    initial begin
        #1000000;
        $display("");
        $display("TIMEOUT: Force stop at cycle %0d", cycle_count);
        $display("--- Register dump at timeout ---");
        uut.RF.dump_registers(cycle_count);
        $display("No fixed-value checks were run (generic testbench mode).");
        $finish;
    end
    initial begin
        $dumpfile("pipe_tb.vcd");
        $dumpvars(0, pipe_tb);
        $display("Team: 'NRS i11 Processor'");
        $display("RISC-V 5-Stage Pipelined Processor Simulation");
        $display("");
        clk = 0;
        reset = 1;
        cycle_count = 0;
        #15;
        reset = 0;
        $display("Starting program execution");
        $display("");
    end
endmodule