module store_data_mux(
    input  [63:0] rs2_data,        // normal store data from ID/EX
    input  [63:0] ex_mem_result,   // forwarded result from EX/MEM
    input         ForwardStore,    // control signal from forwarding unit
    output [63:0] mem_write_data   // data sent to DataMemory
);

assign mem_write_data = (ForwardStore) ? ex_mem_result : rs2_data;

endmodule