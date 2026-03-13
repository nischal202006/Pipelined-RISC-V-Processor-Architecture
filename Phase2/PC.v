module pc(
    input clk,
    input reset,
    input PCWrite,
    input [63:0] next_pc,
    output reg [63:0] pc
);

always @(posedge clk or posedge reset) begin

    if(reset)
        pc <= 0;

    else if(PCWrite)
        pc <= next_pc;

    else
        pc <= pc;  

end

endmodule