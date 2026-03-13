module forwarding_unit(
    input EX_MEM_RegWrite,
    input MEM_WB_RegWrite,

    input [4:0] EX_MEM_Rd,
    input [4:0] MEM_WB_Rd,

    input [4:0] ID_EX_Rs1,
    input [4:0] ID_EX_Rs2,

    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB,
    output reg ForwardStore
);

always @(*) begin

    ForwardA = 2'b00;
    ForwardB = 2'b00;
    ForwardStore = 0;

    // EX Hazard (EX/MEM → EX)
    if(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs1))
        ForwardA = 2'b10;

    if(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs2))
        ForwardB = 2'b10;

    // MEM Hazard (MEM/WB → EX)
    if(MEM_WB_RegWrite && (MEM_WB_Rd != 0) &&
       !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs1)) &&
       (MEM_WB_Rd == ID_EX_Rs1))
        ForwardA = 2'b01;

    if(MEM_WB_RegWrite && (MEM_WB_Rd != 0) &&
       !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs2)) &&
       (MEM_WB_Rd == ID_EX_Rs2))
        ForwardB = 2'b01;

    // Store data forwarding
    if(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs2))
        ForwardStore = 1;

end

endmodule