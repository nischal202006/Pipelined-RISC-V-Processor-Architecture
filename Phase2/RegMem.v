`timescale 1ns/1ps

module RegMem(
    input clk,reset,
    input [4:0] read_reg1,read_reg2,write_reg,
    input [63:0] write_data,
    input reg_write_en,
    output [63:0] read_data1,read_data2);
    reg [63:0] registers [0:31];
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 64'b0;
        end else if (reg_write_en && write_reg != 5'b00000) begin
            registers[write_reg] <= write_data;
        end
    end
    assign read_data1 = (read_reg1 == 5'b00000) ? 64'b0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'b00000) ? 64'b0 : registers[read_reg2];
    task dump_registers;
        input integer cycle_count;
        integer file_handle;
        integer j;
        begin
            file_handle = $fopen("register_file.txt", "w");
            for (j = 0; j < 32; j = j + 1) begin
                $fwrite(file_handle, "%016h\n", registers[j]);
            end
            $fwrite(file_handle, "%0d\n", cycle_count);
            $fclose(file_handle);
        end
    endtask

endmodule