`timescale 1ns/1ps
`define IMEM_SIZE 4096

module instruction_mem (
    input clk,reset,
    input [63:0] addr,
    output [31:0] instr);
    
    reg [7:0] instr_mem [0:`IMEM_SIZE-1];
    integer i;
    integer file_handle;
    initial begin
        for (i = 0; i < `IMEM_SIZE; i = i + 1) begin
            instr_mem[i] = 8'h00;
        end
        file_handle = $fopen("instructions.txt", "r");
        if (file_handle) begin
            $fclose(file_handle);
            $readmemh("instructions.txt", instr_mem, 0);
        end
    end
    assign instr = (addr+3<`IMEM_SIZE)?{instr_mem[addr],instr_mem[addr+1],instr_mem[addr+2],instr_mem[addr+3]} : 32'b0;
endmodule