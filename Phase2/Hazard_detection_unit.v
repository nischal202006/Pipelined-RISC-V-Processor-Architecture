module hazard_detection_unit(

    input ID_EX_MemRead,       // load instruction in EX stage
    input [4:0] ID_EX_Rd,      // destination register of load

    input [4:0] IF_ID_Rs1,     // source registers of next instruction
    input [4:0] IF_ID_Rs2,

    output reg PCWrite,
    output reg IF_ID_Write,
    output reg ControlMux     // used to insert bubble
);

always @(*) begin

    // Default (normal execution)
    PCWrite = 1;
    IF_ID_Write = 1;
    ControlMux = 0;

    // Load-use hazard condition
    if (ID_EX_MemRead &&
       ((ID_EX_Rd == IF_ID_Rs1) || (ID_EX_Rd == IF_ID_Rs2))) begin

        PCWrite = 0;       // stall PC
        IF_ID_Write = 0;   // stall IF/ID
        ControlMux = 1;    // insert bubble
    end

end

endmodule