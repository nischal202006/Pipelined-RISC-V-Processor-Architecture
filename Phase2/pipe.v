`timescale 1ns/1ps
`define IMEM_SIZE 4096
// PC with PCWrite additional to sequential

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

// instruction_mem
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

// IF/ID register
module IF_ID(
    input clk,
    input reset,
    input IF_ID_Write,
    input IF_ID_Flush,        // for branch flush
    input [31:0] instr_in,
    input [63:0] pc_in,
    input predicted_taken_in,  // branch predictor prediction
    output reg [31:0] instr_out,
    output reg [63:0] pc_out,
    output reg predicted_taken_out
);

always @(posedge clk or posedge reset) begin

    if(reset) begin
        instr_out <= 0;
        pc_out <= 0;
        predicted_taken_out <= 0;
    end

    else if(IF_ID_Flush) begin
        instr_out <= 32'h00000033;   // This is for insert NOP (add x0, x0, x0)
        pc_out <= 0;
        predicted_taken_out <= 0;
    end

    else if(IF_ID_Write) begin
        instr_out <= instr_in;
        pc_out <= pc_in;
        predicted_taken_out <= predicted_taken_in;
    end

end

endmodule

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
    assign read_data1 = (read_reg1 == 5'b00000) ? 64'b0 :
                         (reg_write_en && write_reg != 5'b00000 && write_reg == read_reg1) ? write_data :
                         registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'b00000) ? 64'b0 :
                         (reg_write_en && write_reg != 5'b00000 && write_reg == read_reg2) ? write_data :
                         registers[read_reg2];
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


module control_unit(
    input [6:0] opcode,
    output reg Branch, MemRead, MemtoReg, 
    output reg [1:0] ALUOp, 
    output reg MemWrite, ALUSrc, RegWrite);
    localparam R_TYPE = 7'b0110011;  
    localparam I_TYPE = 7'b0010011;  
    localparam LOAD   = 7'b0000011;  
    localparam STORE  = 7'b0100011;  
    localparam BRANCH = 7'b1100011; 
    always @(*) begin
        Branch    = 1'b0;
        MemRead   = 1'b0;
        MemtoReg  = 1'b0;
        ALUOp     = 2'b00;
        MemWrite  = 1'b0;
        ALUSrc    = 1'b0;
        RegWrite  = 1'b0;
        case (opcode)
            R_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                ALUOp    = 2'b10;
                MemtoReg = 1'b0;   
            end
            I_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b11;
                MemtoReg = 1'b0;    
            end
            LOAD: begin
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                MemtoReg = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end
            STORE: begin
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 2'b00;
            end
            BRANCH: begin
               Branch = 1'b1;
               ALUOp  = 2'b01;
            end
        endcase
    end
endmodule
//This is ID/EX registor
module ID_EX(
    input clk,
    input reset,
    input ID_EX_Flush,

    input [63:0] pc_in,
    input [63:0] reg1_in,
    input [63:0] reg2_in,
    input [63:0] imm_in,

    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,

    input RegWrite_in,
    input MemRead_in,
    input MemWrite_in,
    input MemtoReg_in,
    input ALUSrc_in,
    input Branch_in,
    input [1:0] ALUOp_in,
    input [2:0] funct3_in,
    input funct7_5_in,

    output reg [63:0] pc_out,
    output reg [63:0] reg1_out,
    output reg [63:0] reg2_out,
    output reg [63:0] imm_out,

    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,

    output reg RegWrite_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg MemtoReg_out,
    output reg ALUSrc_out,
    output reg Branch_out,
    output reg [1:0] ALUOp_out,
    output reg [2:0] funct3_out,
    output reg funct7_5_out
);

always @(posedge clk or posedge reset) begin

    if(reset) begin
        pc_out <= 0;
        reg1_out <= 0;
        reg2_out <= 0;
        imm_out <= 0;
        rs1_out <= 0;
        rs2_out <= 0;
        rd_out <= 0;

        RegWrite_out <= 0;
        MemRead_out <= 0;
        MemWrite_out <= 0;
        MemtoReg_out <= 0;
        ALUSrc_out <= 0;
        Branch_out <= 0;
        ALUOp_out <= 2'b00;
        funct3_out <= 3'b000;
        funct7_5_out <= 0;
    end

    else if(ID_EX_Flush) begin
        RegWrite_out <= 0;
        MemRead_out  <= 0;
        MemWrite_out <= 0;
        MemtoReg_out <= 0;
        ALUSrc_out <= 0;
        Branch_out <= 0;
        ALUOp_out <= 2'b00;
        funct3_out <= 3'b000;
        funct7_5_out <= 0;
    end

    else begin
        pc_out <= pc_in;
        reg1_out <= reg1_in;
        reg2_out <= reg2_in;
        imm_out <= imm_in;

        rs1_out <= rs1_in;
        rs2_out <= rs2_in;
        rd_out <= rd_in;

        RegWrite_out <= RegWrite_in;
        MemRead_out <= MemRead_in;
        MemWrite_out <= MemWrite_in;
        MemtoReg_out <= MemtoReg_in;
        ALUSrc_out <= ALUSrc_in;
        Branch_out <= Branch_in;
        ALUOp_out <= ALUOp_in;
        funct3_out <= funct3_in;
        funct7_5_out <= funct7_5_in;
    end

end
endmodule

module immediate_gen(
    input [31:0] instr,
    output reg [63:0] immediate_val);
    localparam I_TYPE_ALU = 7'b0010011; 
    localparam I_TYPE_LD  = 7'b0000011;
    localparam S_TYPE     = 7'b0100011;
    localparam B_TYPE     = 7'b1100011;
    always @(*) begin
        case (instr[6:0])
            I_TYPE_ALU, I_TYPE_LD: begin
                immediate_val = {{52{instr[31]}},instr[31:20]};
            end
            S_TYPE: begin
                immediate_val = {{52{instr[31]}},instr[31:25],instr[11:7]};
            end
            B_TYPE: begin
                 immediate_val = {{52{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8]};
            end
            default: begin
                immediate_val = 64'b0;
            end
        endcase
    end
endmodule

module ALU_control(
    input  [1:0] ALUOp,
    input  funct7_5, 
    input  [2:0] funct3,
    output reg [3:0] ALUControl);

    always @(*) begin
        case (ALUOp)
            2'b00: begin
                ALUControl = 4'b0010; // ADD
            end
            2'b01: begin
                ALUControl = 4'b0110; // SUB
            end
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        if (funct7_5)
                            ALUControl = 4'b0110; // SUB
                        else
                            ALUControl = 4'b0010; // ADD
                    end
                    3'b111: begin
                        ALUControl = 4'b0000; // AND
                    end
                    3'b110: begin
                        ALUControl = 4'b0001; // OR
                    end
                    default: begin
                        ALUControl = 4'b0010; //default: ADD
                    end
                endcase
            end
             2'b11: begin
                case (funct3)
                    3'b000: ALUControl = 4'b0010; // ADDI → ADD
                    3'b111: ALUControl = 4'b0000; // ANDI → AND
                    3'b110: ALUControl = 4'b0001; // ORI  → OR
                    default: ALUControl = 4'b0010; // default ADD
                endcase
            end
            default: begin
                ALUControl = 4'b0010; // ADD
            end
        endcase
    end
endmodule

module add(input [63:0]r1,r2,output [63:0] rd,output flag,output cout);
    wire [63:0] r12,temp1,temp2;
    wire [64:0] carry;
    assign carry[0] = 1'b0;
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            xor (r12[i],r1[i],r2[i]);
            xor (rd[i],r12[i],carry[i]);
            and (temp1[i],r1[i],r2[i]);
            and (temp2[i],r12[i],carry[i]);
            or (carry[i+1],temp1[i],temp2[i]);
        end
    endgenerate
    xor (flag,carry[63],carry[64]);
    assign cout = carry[64];
endmodule

module sub(input [63:0]r1,r2,output [63:0] rd,output flag,cout);
    wire [63:0] r12,temp1,temp2,r2_comple;
    wire [64:0] carry;
    assign carry[0] = 1'b1;
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            not (r2_comple[i],r2[i]);
            xor (r12[i],r1[i],r2_comple[i]);
            xor (rd[i],r12[i],carry[i]);
            and (temp1[i],r1[i],r2_comple[i]);
            and (temp2[i],r12[i],carry[i]);
            or (carry[i+1],temp1[i],temp2[i]);
        end
    endgenerate
    xor (flag,carry[63],carry[64]);
    assign cout = carry[64];
endmodule

module Xor(input [63:0]r1,r2,output [63:0] rd,output flag);
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            xor (rd[i],r1[i],r2[i]);
        end
    endgenerate
    assign flag = 1'b0;
endmodule

module Or(input [63:0]r1,r2,output [63:0] rd,output flag);
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            or (rd[i],r1[i],r2[i]);
        end
    endgenerate
    assign flag = 1'b0;
endmodule

module And(input [63:0]r1,r2,output [63:0] rd,output flag);
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            and (rd[i],r1[i],r2[i]);
        end
    endgenerate
    assign flag = 1'b0;
endmodule

module sll(input [63:0] r1,output [63:0] rd);
    assign rd   = {r1[62:0], 1'b0}; 
endmodule

module alu_64_bit(input [63:0] input1,input2, input [3:0] control_signal,
                  output [63:0] result,output zero_flag);
    wire [63:0] add_res, sub_res, and_res, or_res;
    wire add_ov, sub_ov,add_car,sub_car;
    localparam  ADD_Oper  = 4'b0010,
                OR_Oper   = 4'b0001,
                AND_Oper  = 4'b0000,
                SUB_Oper  = 4'b0110;
    add  U_ADD  (.r1(input1), .r2(input2), .rd(add_res),  .flag(add_ov), .cout(add_car));
    sub  U_SUB  (.r1(input1), .r2(input2), .rd(sub_res),  .flag(sub_ov), .cout(sub_car));
    And  U_AND  (.r1(input1), .r2(input2), .rd(and_res),  .flag());
    Or   U_OR   (.r1(input1), .r2(input2), .rd(or_res),   .flag());
    reg [63:0] result_reg;
        always @(*) begin
        case (control_signal)
            ADD_Oper: result_reg = add_res;
            SUB_Oper: result_reg = sub_res;
            AND_Oper: result_reg = and_res;
            OR_Oper : result_reg = or_res;
            default:  result_reg = 64'b0;
        endcase
    end
    assign result     = result_reg;
    assign zero_flag  = ~(|result_reg);
endmodule
//Register EX/MEM
module EX_MEM(

    input clk,
    input reset,

    input [63:0] alu_result_in,
    input [63:0] write_data_in,

    input [4:0] rd_in,
    input [4:0] rs2_in,

    input RegWrite_in,
    input MemRead_in,
    input MemWrite_in,
    input MemtoReg_in,

    output reg [63:0] alu_result_out,
    output reg [63:0] write_data_out,

    output reg [4:0] rd_out,
    output reg [4:0] rs2_out,

    output reg RegWrite_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg MemtoReg_out
);

always @(posedge clk or posedge reset) begin

    if(reset) begin
        alu_result_out <= 0;
        write_data_out <= 0;
        rd_out <= 0;
        rs2_out <= 0;

        RegWrite_out <= 0;
        MemRead_out <= 0;
        MemWrite_out <= 0;
        MemtoReg_out <= 0;
    end
    else begin
        alu_result_out <= alu_result_in;
        write_data_out <= write_data_in;
        rd_out <= rd_in;
        rs2_out <= rs2_in;

        RegWrite_out <= RegWrite_in;
        MemRead_out <= MemRead_in;
        MemWrite_out <= MemWrite_in;
        MemtoReg_out <= MemtoReg_in;
    end

end

endmodule

module DataMem(
    input clk, reset,
    input [63:0] address, write_data,
    input MemRead, MemWrite,
    output [63:0] read_data);

    reg [7:0] memory [0:1023];
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 1024; i = i + 1)
                memory[i] <= 8'b0;
        end else if (MemWrite && address <= 1016) begin
            memory[address]   <= write_data[63:56];
            memory[address+1] <= write_data[55:48];
            memory[address+2] <= write_data[47:40];
            memory[address+3] <= write_data[39:32];
            memory[address+4] <= write_data[31:24];
            memory[address+5] <= write_data[23:16];
            memory[address+6] <= write_data[15:8];
            memory[address+7] <= write_data[7:0];
        end
    end
    assign read_data = (MemRead && address <= 1016) ?
        {memory[address],   memory[address+1], memory[address+2], memory[address+3],
         memory[address+4], memory[address+5], memory[address+6], memory[address+7]} :
        64'b0;
endmodule

module multiplexer(input [63:0] I1,I2,input S,output [63:0] mux_out);
    wire [63:0] temp1,temp2;
    wire not_S;
    not (not_S, S);
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            and (temp1[i],I1[i],not_S);
            and (temp2[i],I2[i],S);
            or  (mux_out[i],temp1[i],temp2[i]);
        end
    endgenerate
endmodule

module MEM_WB(

    input clk,
    input reset,

    input [63:0] mem_data_in,
    input [63:0] alu_result_in,

    input [4:0] rd_in,

    input RegWrite_in,
    input MemtoReg_in,

    output reg [63:0] mem_data_out,
    output reg [63:0] alu_result_out,

    output reg [4:0] rd_out,

    output reg RegWrite_out,
    output reg MemtoReg_out
);

always @(posedge clk or posedge reset) begin

    if(reset) begin
        mem_data_out <= 0;
        alu_result_out <= 0;
        rd_out <= 0;
        RegWrite_out <= 0;
        MemtoReg_out <= 0;
    end
    else begin
        mem_data_out <= mem_data_in;
        alu_result_out <= alu_result_in;
        rd_out <= rd_in;

        RegWrite_out <= RegWrite_in;
        MemtoReg_out <= MemtoReg_in;
    end

end

endmodule

module adder_4(input [63:0] pc_in,output [63:0] pc_out);
    wire [63:0] r2,r12,temp1,temp2;
    wire [64:0] carry;
    assign r2 = 64'd4;
    assign carry[0] = 1'b0;
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            xor (r12[i],pc_in[i],r2[i]);
            xor (pc_out[i],r12[i],carry[i]);
            and (temp1[i],pc_in[i],r2[i]);
            and (temp2[i],r12[i],carry[i]);
            or (carry[i+1],temp1[i],temp2[i]);
        end
    endgenerate
endmodule

module adder_branch(input [63:0]r1,r2,output [63:0] rd);
    wire [63:0] r12,temp1,temp2;
    wire [64:0] carry;
    assign carry[0] = 1'b0;
    genvar i;
    generate
         for (i = 0; i<64;i=i+1) begin
            xor (r12[i],r1[i],r2[i]);
            xor (rd[i],r12[i],carry[i]);
            and (temp1[i],r1[i],r2[i]);
            and (temp2[i],r12[i],carry[i]);
            or (carry[i+1],temp1[i],temp2[i]);
        end
    endgenerate
endmodule

module forwarding_unit(
    input EX_MEM_RegWrite,
    input MEM_WB_RegWrite,

    input [4:0] EX_MEM_Rd,
    input [4:0] MEM_WB_Rd,

    input [4:0] ID_EX_Rs1,
    input [4:0] ID_EX_Rs2,

    // Load->Store forwarding inputs
    input [4:0] EX_MEM_Rs2,
    input EX_MEM_MemWrite,

    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB,
    output reg [1:0] ForwardStore
);

always @(*) begin

    ForwardA = 2'b00;
    ForwardB = 2'b00;
    ForwardStore = 2'b00;

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

    // Store data forwarding (EX/MEM → MEM stage)
    if(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs2))
        ForwardStore = 2'b10;

    // Load->Store forwarding (MEM/WB → MEM stage store data)
    if(EX_MEM_MemWrite && MEM_WB_RegWrite && (MEM_WB_Rd != 0) &&
       (MEM_WB_Rd == EX_MEM_Rs2) &&
       !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == EX_MEM_Rs2)))
        ForwardStore = 2'b01;
end

endmodule

module control_mux(

    input ControlMux,     // from hazard detection unit

    input RegWrite_in,
    input MemRead_in,
    input MemWrite_in,
    input MemtoReg_in,
    input Branch_in,
    input ALUSrc_in,
    input [1:0] ALUOp_in,

    output reg RegWrite_out,
    output reg MemRead_out,
    output reg MemWrite_out,
    output reg MemtoReg_out,
    output reg Branch_out,
    output reg ALUSrc_out,
    output reg [1:0] ALUOp_out
);

always @(*) begin

    if(ControlMux) begin
        // Insert bubble (NOP)
        RegWrite_out = 0;
        MemRead_out  = 0;
        MemWrite_out = 0;
        MemtoReg_out = 0;
        Branch_out   = 0;
        ALUSrc_out   = 0;
        ALUOp_out    = 2'b00;
    end
    else begin
        // Normal control signals
        RegWrite_out = RegWrite_in;
        MemRead_out  = MemRead_in;
        MemWrite_out = MemWrite_in;
        MemtoReg_out = MemtoReg_in;
        Branch_out   = Branch_in;
        ALUSrc_out   = ALUSrc_in;
        ALUOp_out    = ALUOp_in;
    end

end

endmodule

module hazard_detection_unit(
    
    input ID_EX_MemRead,       // load instruction in EX stage
    input [4:0] ID_EX_Rd,      // destination register of load

    input [4:0] IF_ID_Rs1,     // source registers of next instruction
    input [4:0] IF_ID_Rs2,
    input [6:0] IF_ID_opcode,  // opcode of instruction in ID stage

    // Branch hazard inputs
    input Branch,              // branch in ID stage
    input EX_MEM_MemRead,      // load in MEM stage
    input [4:0] EX_MEM_Rd,     // destination of MEM stage instruction

    output reg PCWrite,
    output reg IF_ID_Write,
    output reg ControlMux     // used to insert bubble
);

always @(*) begin

    // normal execution
    PCWrite = 1;
    IF_ID_Write = 1;
    ControlMux = 0;

    
    if (ID_EX_MemRead && (ID_EX_Rd != 0) &&
       ((ID_EX_Rd == IF_ID_Rs1) ||
        (ID_EX_Rd == IF_ID_Rs2 && !(IF_ID_opcode == 7'b0100011 && ID_EX_Rd != IF_ID_Rs1)))) begin

        PCWrite = 0;       // stall PC
        IF_ID_Write = 0;   // stall IF/ID
        ControlMux = 1;    // insert bubble
    end

    // Branch hazard: LOAD in EX writes to branch source registers
    // (ALU producers in EX are now forwarded directly, no stall needed)
    if (Branch && ID_EX_MemRead && (ID_EX_Rd != 0) &&
       ((ID_EX_Rd == IF_ID_Rs1) || (ID_EX_Rd == IF_ID_Rs2))) begin

        PCWrite = 0;
        IF_ID_Write = 0;
        ControlMux = 1;
    end

    // Branch hazard: load in MEM writes to branch source registers
    if (Branch && EX_MEM_MemRead && (EX_MEM_Rd != 0) &&
       ((EX_MEM_Rd == IF_ID_Rs1) || (EX_MEM_Rd == IF_ID_Rs2))) begin

        PCWrite = 0;
        IF_ID_Write = 0;
        ControlMux = 1;
    end

end

endmodule

module alu_forward_mux(
    input [63:0] reg_data,
    input [63:0] mem_stage_data,
    input [63:0] wb_stage_data,
    input [1:0] select,
    output reg [63:0] out
);


always @(*) begin

    case(select)

        2'b00: out = reg_data;
        2'b10: out = mem_stage_data;
        2'b01: out = wb_stage_data;
        default: out = reg_data;

    endcase

end

endmodule

// 4-input branch forward mux (adds 2'b11 = EX ALU result)
module branch_forward_mux(
    input [63:0] reg_data,
    input [63:0] mem_stage_data,
    input [63:0] wb_stage_data,
    input [63:0] ex_alu_data,
    input [1:0] select,
    output reg [63:0] out
);

always @(*) begin
    case(select)
        2'b00: out = reg_data;
        2'b10: out = mem_stage_data;
        2'b01: out = wb_stage_data;
        2'b11: out = ex_alu_data;
    endcase
end

endmodule


module store_data_mux(
    input  [63:0] rs2_data,        // normal store data from ID/EX
    input  [63:0] ex_mem_result,   // forwarded result from EX/MEM
    input  [63:0] wb_data,         // forwarded result from MEM/WB (load->store)
    input  [1:0]  ForwardStore,    // 00=none, 10=EX/MEM, 01=MEM/WB
    output reg [63:0] mem_write_data   // data sent to DataMemory
);

always @(*) begin
    case (ForwardStore)
        2'b10:   mem_write_data = ex_mem_result;
        2'b01:   mem_write_data = wb_data;
        default: mem_write_data = rs2_data;
    endcase
end

endmodule


module branch_forwarding_unit(
    input EX_MEM_RegWrite,
    input MEM_WB_RegWrite,

    input [4:0] EX_MEM_Rd,
    input [4:0] MEM_WB_Rd,

    input [4:0] IF_ID_Rs1,
    input [4:0] IF_ID_Rs2,

    // EX stage ALU result forwarding (highest priority)
    input ID_EX_RegWrite,
    input ID_EX_MemRead,
    input [4:0] ID_EX_Rd,

    output reg [1:0] BranchForwardA,
    output reg [1:0] BranchForwardB
);

always @(*) begin

    BranchForwardA = 2'b00;
    BranchForwardB = 2'b00;

    // Forward from EX/MEM to branch comparator
    if (EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == IF_ID_Rs1))
        BranchForwardA = 2'b10;

    if (EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == IF_ID_Rs2))
        BranchForwardB = 2'b10;

    // Forward from MEM/WB to branch comparator (lower priority)
    if (MEM_WB_RegWrite && (MEM_WB_Rd != 0) &&
       !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == IF_ID_Rs1)) &&
       (MEM_WB_Rd == IF_ID_Rs1))
        BranchForwardA = 2'b01;

    if (MEM_WB_RegWrite && (MEM_WB_Rd != 0) &&
       !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == IF_ID_Rs2)) &&
       (MEM_WB_Rd == IF_ID_Rs2))
        BranchForwardB = 2'b01;

    // Forward from end-of-EX ALU result (highest priority, non-load only)
    if (ID_EX_RegWrite && !ID_EX_MemRead && (ID_EX_Rd != 0) && (ID_EX_Rd == IF_ID_Rs1))
        BranchForwardA = 2'b11;

    if (ID_EX_RegWrite && !ID_EX_MemRead && (ID_EX_Rd != 0) && (ID_EX_Rd == IF_ID_Rs2))
        BranchForwardB = 2'b11;

end

endmodule


// 2-BIT BRANCH PREDICTOR (Mealy Machine)
// States: 00=Strongly NT, 01=Weakly NT(predict T), 10=Weakly T(predict NT), 11=Strongly T
// Prediction = LSB (output depends on state + last input transition)
// Weak states transition directly to the strong state matching the outcome

module branch_predictor(
    input clk,
    input reset,
    // IF stage lookup
    input [63:0] pc,
    output predict_taken,
    output [63:0] predicted_target,
    // ID stage update
    input update_en,           // branch resolved in ID
    input [63:0] update_pc,    // PC of the branch
    input actual_taken,        // actual branch outcome
    input [63:0] branch_target // computed branch target
);

    reg [1:0] counter [0:15];   // 2-bit state
    reg [63:0] target [0:15];   // stored branch target
    reg valid [0:15];           // entry valid

    wire [3:0] lookup_idx = pc[5:2];
    wire [3:0] update_idx = update_pc[5:2];

    // Mealy prediction: taken when LSB = 1 (states 01 and 11)
    assign predict_taken = valid[lookup_idx] & counter[lookup_idx][0];
    assign predicted_target = target[lookup_idx];

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                counter[i] <= 2'b00;
                target[i]  <= 64'b0;
                valid[i]   <= 1'b0;
            end
        end else if (update_en) begin
            valid[update_idx]  <= 1'b1;
            target[update_idx] <= branch_target;
            // Mealy state transitions
            case (counter[update_idx])
                2'b00: counter[update_idx] <= actual_taken ? 2'b01 : 2'b00;
                2'b01: counter[update_idx] <= actual_taken ? 2'b11 : 2'b00;
                2'b10: counter[update_idx] <= actual_taken ? 2'b11 : 2'b00;
                2'b11: counter[update_idx] <= actual_taken ? 2'b11 : 2'b10;
            endcase
        end
    end

endmodule


module pipeline(input clk, reset);

// IF STAGE

wire [63:0] pc_current;
wire [63:0] pc_next;
wire [63:0] pc_plus4;
wire [31:0] instruction;

wire PCWrite;
wire IF_ID_Write;
wire IF_ID_Flush;

pc PC(
    .clk(clk),
    .reset(reset),
    .PCWrite(PCWrite),
    .next_pc(pc_next),
    .pc(pc_current)
);

instruction_mem IM(
    .clk(clk),
    .reset(reset),
    .addr(pc_current),
    .instr(instruction)
);

adder_4 PC4(
    .pc_in(pc_current),
    .pc_out(pc_plus4)
);

// IF / ID REGISTER

wire [31:0] IF_ID_instr;
wire [63:0] IF_ID_pc;
wire IF_ID_predicted_taken;

IF_ID IFID(
    .clk(clk),
    .reset(reset),
    .IF_ID_Write(IF_ID_Write),
    .IF_ID_Flush(IF_ID_Flush),
    .instr_in(instruction),
    .pc_in(pc_current),
    .predicted_taken_in(bp_predict_taken),
    .instr_out(IF_ID_instr),
    .pc_out(IF_ID_pc),
    .predicted_taken_out(IF_ID_predicted_taken)
);


// ID STAGE

wire Branch, MemRead, MemWrite, MemtoReg, ALUSrc, RegWrite;
wire [1:0] ALUOp;

control_unit CU(
    .opcode(IF_ID_instr[6:0]),
    .Branch(Branch),
    .MemRead(MemRead),
    .MemtoReg(MemtoReg),
    .ALUOp(ALUOp),
    .MemWrite(MemWrite),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite)
);

wire [63:0] reg_data1, reg_data2;

RegMem RF(
    .clk(clk),
    .reset(reset),
    .read_reg1(IF_ID_instr[19:15]),
    .read_reg2(IF_ID_instr[24:20]),
    .write_reg(MEM_WB_rd),
    .write_data(write_back_data),
    .reg_write_en(MEM_WB_RegWrite),
    .read_data1(reg_data1),
    .read_data2(reg_data2));

wire [63:0] imm;

immediate_gen IG(
    .instr(IF_ID_instr),
    .immediate_val(imm)
);

// HAZARD DETECTION

wire ControlMux;

hazard_detection_unit HDU(
    .ID_EX_MemRead(ID_EX_MemRead),
    .ID_EX_Rd(ID_EX_rd),
    .IF_ID_Rs1(IF_ID_instr[19:15]),
    .IF_ID_Rs2(IF_ID_instr[24:20]),
    .IF_ID_opcode(IF_ID_instr[6:0]),
    .Branch(Branch),
    .EX_MEM_MemRead(EX_MEM_MemRead),
    .EX_MEM_Rd(EX_MEM_rd),
    .PCWrite(PCWrite),
    .IF_ID_Write(IF_ID_Write),
    .ControlMux(ControlMux)
);


// CONTROL MUX 

wire RegWrite_c, MemRead_c, MemWrite_c, MemtoReg_c;
wire Branch_c, ALUSrc_c;
wire [1:0] ALUOp_c;

control_mux CMUX(
    .ControlMux(ControlMux),
    .RegWrite_in(RegWrite),
    .MemRead_in(MemRead),
    .MemWrite_in(MemWrite),
    .MemtoReg_in(MemtoReg),
    .Branch_in(Branch),
    .ALUSrc_in(ALUSrc),
    .ALUOp_in(ALUOp),

    .RegWrite_out(RegWrite_c),
    .MemRead_out(MemRead_c),
    .MemWrite_out(MemWrite_c),
    .MemtoReg_out(MemtoReg_c),
    .Branch_out(Branch_c),
    .ALUSrc_out(ALUSrc_c),
    .ALUOp_out(ALUOp_c)
);


// ID / EX REGISTER


wire [63:0] ID_EX_pc, ID_EX_reg1, ID_EX_reg2, ID_EX_imm;
wire [4:0] ID_EX_rs1, ID_EX_rs2, ID_EX_rd;
wire ID_EX_RegWrite, ID_EX_MemRead, ID_EX_MemWrite, ID_EX_MemtoReg;
wire ID_EX_ALUSrc, ID_EX_Branch;
wire [1:0] ID_EX_ALUOp;
wire [2:0] ID_EX_funct3;
wire ID_EX_funct7_5;

ID_EX IDEX(
    .clk(clk),
    .reset(reset),
    .ID_EX_Flush(ControlMux | misprediction & Branch_c),

    .pc_in(IF_ID_pc),
    .reg1_in(reg_data1),
    .reg2_in(reg_data2),
    .imm_in(imm),

    .rs1_in(IF_ID_instr[19:15]),
    .rs2_in(IF_ID_instr[24:20]),
    .rd_in(IF_ID_instr[11:7]),

    .RegWrite_in(RegWrite_c),
    .MemRead_in(MemRead_c),
    .MemWrite_in(MemWrite_c),
    .MemtoReg_in(MemtoReg_c),
    .ALUSrc_in(ALUSrc_c),
    .Branch_in(Branch_c),
    .ALUOp_in(ALUOp_c),
    .funct3_in(IF_ID_instr[14:12]),
    .funct7_5_in(IF_ID_instr[30]),

    .pc_out(ID_EX_pc),
    .reg1_out(ID_EX_reg1),
    .reg2_out(ID_EX_reg2),
    .imm_out(ID_EX_imm),

    .rs1_out(ID_EX_rs1),
    .rs2_out(ID_EX_rs2),
    .rd_out(ID_EX_rd),

    .RegWrite_out(ID_EX_RegWrite),
    .MemRead_out(ID_EX_MemRead),
    .MemWrite_out(ID_EX_MemWrite),
    .MemtoReg_out(ID_EX_MemtoReg),
    .ALUSrc_out(ID_EX_ALUSrc),
    .Branch_out(ID_EX_Branch),
    .ALUOp_out(ID_EX_ALUOp),
    .funct3_out(ID_EX_funct3),
    .funct7_5_out(ID_EX_funct7_5)
);


// FORWARDING UNIT


wire [1:0] ForwardA, ForwardB;
wire [1:0] ForwardStore;

forwarding_unit FU(
    .EX_MEM_RegWrite(EX_MEM_RegWrite),
    .MEM_WB_RegWrite(MEM_WB_RegWrite),
    .EX_MEM_Rd(EX_MEM_rd),
    .MEM_WB_Rd(MEM_WB_rd),
    .ID_EX_Rs1(ID_EX_rs1),
    .ID_EX_Rs2(ID_EX_rs2),
    .EX_MEM_Rs2(EX_MEM_rs2),
    .EX_MEM_MemWrite(EX_MEM_MemWrite),
    .ForwardA(ForwardA),
    .ForwardB(ForwardB),
    .ForwardStore(ForwardStore)
);


// ALU FORWARD MUX


wire [63:0] ALU_in1;
wire [63:0] ALU_in2_pre;

alu_forward_mux FA(
    .reg_data(ID_EX_reg1),
    .mem_stage_data(EX_MEM_alu_result),
    .wb_stage_data(write_back_data),
    .select(ForwardA),
    .out(ALU_in1)
);

alu_forward_mux FB(
    .reg_data(ID_EX_reg2),
    .mem_stage_data(EX_MEM_alu_result),
    .wb_stage_data(write_back_data),
    .select(ForwardB),
    .out(ALU_in2_pre)
);

// ALU SRC MUX

wire [63:0] ALU_in2;

multiplexer ALUSRC(
    .I1(ALU_in2_pre),
    .I2(ID_EX_imm),
    .S(ID_EX_ALUSrc),
    .mux_out(ALU_in2)
);


// ALU


wire [3:0] ALUControl;
wire [63:0] ALU_result;
wire Zero;

ALU_control ALUCTRL(
    .ALUOp(ID_EX_ALUOp),
    .funct7_5(ID_EX_funct7_5),
    .funct3(ID_EX_funct3),
    .ALUControl(ALUControl)
);

alu_64_bit ALU(
    .input1(ALU_in1),
    .input2(ALU_in2),
    .control_signal(ALUControl),
    .result(ALU_result),
    .zero_flag(Zero)
);


// EX/MEM REGISTER


wire [63:0] EX_MEM_alu_result;
wire [63:0] EX_MEM_write_data;
wire [4:0] EX_MEM_rd;
wire [4:0] EX_MEM_rs2;
wire EX_MEM_RegWrite, EX_MEM_MemRead, EX_MEM_MemWrite, EX_MEM_MemtoReg;

EX_MEM EXMEM(
    .clk(clk),
    .reset(reset),
    .alu_result_in(ALU_result),
    .write_data_in(ALU_in2_pre),
    .rd_in(ID_EX_rd),
    .rs2_in(ID_EX_rs2),
    .RegWrite_in(ID_EX_RegWrite),
    .MemRead_in(ID_EX_MemRead),
    .MemWrite_in(ID_EX_MemWrite),
    .MemtoReg_in(ID_EX_MemtoReg),

    .alu_result_out(EX_MEM_alu_result),
    .write_data_out(EX_MEM_write_data),
    .rd_out(EX_MEM_rd),
    .rs2_out(EX_MEM_rs2),
    .RegWrite_out(EX_MEM_RegWrite),
    .MemRead_out(EX_MEM_MemRead),
    .MemWrite_out(EX_MEM_MemWrite),
    .MemtoReg_out(EX_MEM_MemtoReg)
);


// STORE FORWARD


wire [63:0] store_data;

store_data_mux SDMUX(
    .rs2_data(EX_MEM_write_data),
    .ex_mem_result(EX_MEM_alu_result),
    .wb_data(write_back_data),
    .ForwardStore(ForwardStore),
    .mem_write_data(store_data)
);


// DATA MEMORY

wire [63:0] mem_read;

DataMem DM(
    .clk(clk),
    .reset(reset),
    .address(EX_MEM_alu_result),
    .write_data(store_data),
    .MemRead(EX_MEM_MemRead),
    .MemWrite(EX_MEM_MemWrite),
    .read_data(mem_read)
);


// MEM/WB REGISTER


wire [63:0] MEM_WB_mem_data;
wire [63:0] MEM_WB_alu_result;
wire [4:0] MEM_WB_rd;
wire MEM_WB_RegWrite, MEM_WB_MemtoReg;

MEM_WB MEMWB(
    .clk(clk),
    .reset(reset),
    .mem_data_in(mem_read),
    .alu_result_in(EX_MEM_alu_result),
    .rd_in(EX_MEM_rd),
    .RegWrite_in(EX_MEM_RegWrite),
    .MemtoReg_in(EX_MEM_MemtoReg),

    .mem_data_out(MEM_WB_mem_data),
    .alu_result_out(MEM_WB_alu_result),
    .rd_out(MEM_WB_rd),
    .RegWrite_out(MEM_WB_RegWrite),
    .MemtoReg_out(MEM_WB_MemtoReg)
);


// WRITEBACK


wire [63:0] write_back_data;

multiplexer WBMUX(
    .I1(MEM_WB_alu_result),
    .I2(MEM_WB_mem_data),
    .S(MEM_WB_MemtoReg),
    .mux_out(write_back_data)
);

wire [1:0] BranchForwardA, BranchForwardB;


//
branch_forwarding_unit BFU(
    .EX_MEM_RegWrite(EX_MEM_RegWrite),
    .MEM_WB_RegWrite(MEM_WB_RegWrite),
    .EX_MEM_Rd(EX_MEM_rd),
    .MEM_WB_Rd(MEM_WB_rd),
    .IF_ID_Rs1(IF_ID_instr[19:15]),
    .IF_ID_Rs2(IF_ID_instr[24:20]),
    .ID_EX_RegWrite(ID_EX_RegWrite),
    .ID_EX_MemRead(ID_EX_MemRead),
    .ID_EX_Rd(ID_EX_rd),
    .BranchForwardA(BranchForwardA),
    .BranchForwardB(BranchForwardB)
);

wire [63:0] branch_rs1, branch_rs2;

branch_forward_mux BFA(
    .reg_data(reg_data1),
    .mem_stage_data(EX_MEM_alu_result),
    .wb_stage_data(write_back_data),
    .ex_alu_data(ALU_result),
    .select(BranchForwardA),
    .out(branch_rs1)
);

branch_forward_mux BFB(
    .reg_data(reg_data2),
    .mem_stage_data(EX_MEM_alu_result),
    .wb_stage_data(write_back_data),
    .ex_alu_data(ALU_result),
    .select(BranchForwardB),
    .out(branch_rs2)
);


wire actual_taken = Branch_c & (branch_rs1 == branch_rs2);
wire misprediction = !ControlMux & (
    (Branch_c & (IF_ID_predicted_taken != actual_taken)) |
    (!Branch_c & IF_ID_predicted_taken)
);

assign IF_ID_Flush = misprediction;

wire [63:0] imm_shifted;
wire [63:0] addr_jump;

sll BSLL(
    .r1(imm),
    .rd(imm_shifted)
);

adder_branch BRADD(
    .r1(IF_ID_pc),
    .r2(imm_shifted),
    .rd(addr_jump)
);

wire [63:0] IF_ID_pc_plus4;
adder_4 BRPC4(
    .pc_in(IF_ID_pc),
    .pc_out(IF_ID_pc_plus4)
);

wire bp_predict_taken;
wire [63:0] bp_predicted_target;

branch_predictor BP(
    .clk(clk),
    .reset(reset),
    .pc(pc_current),
    .predict_taken(bp_predict_taken),
    .predicted_target(bp_predicted_target),
    .update_en(Branch_c),
    .update_pc(IF_ID_pc),
    .actual_taken(actual_taken),
    .branch_target(addr_jump)
);

wire [63:0] correct_pc = actual_taken ? addr_jump : IF_ID_pc_plus4;

assign pc_next = misprediction   ? correct_pc :
                 bp_predict_taken ? bp_predicted_target :
                 pc_plus4;
endmodule