module DataMem(
    input clk, reset,
    input [63:0] address, write_data,
    input MemRead, MemWrite,
    output [63:0] read_data);

    reg [7:0] memory [0:1023];
    reg [63:0] read_data_reg;
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 1024; i = i + 1)
                memory[i] <= 8'b0;
            read_data_reg <= 64'b0;
        end else begin
            // Synchronous Write (Big-Endian) [cite: 106, 107]
            if (MemWrite && address <= 1016) begin
                memory[address]   <= write_data[63:56];
                memory[address+1] <= write_data[55:48];
                memory[address+2] <= write_data[47:40];
                memory[address+3] <= write_data[39:32];
                memory[address+4] <= write_data[31:24];
                memory[address+5] <= write_data[23:16];
                memory[address+6] <= write_data[15:8];
                memory[address+7] <= write_data[7:0];
            end
            
            // Synchronous Read (1-cycle latency) 
            if (MemRead && address <= 1016) begin
                read_data_reg <= {memory[address],   memory[address+1], memory[address+2], memory[address+3],
                              memory[address+4], memory[address+5], memory[address+6], memory[address+7]};
            end else begin
                read_data_reg <= 64'b0;
            end
        end
    end
    assign read_data = read_data_reg;
endmodule