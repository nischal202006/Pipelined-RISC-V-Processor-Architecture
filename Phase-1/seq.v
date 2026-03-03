`timescale 1ns/1ps
`define IMEM_SIZE 4096

module pc(input clk, reset, input [63:0] pc_in, output [63:0] pc_out);
    reg [63:0] pc_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_reg <= 64'd0;
        else
            pc_reg <= pc_in;
    end
    assign pc_out = pc_reg;
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

module seq(input clk, reset);
    wire [63:0] addr_in, addr_out, addr_next, addr_jump;
    wire [31:0] instruction;
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    wire [1:0] ALUOp;
    wire [63:0] read_r1, read_r2;
    wire [63:0] immediate,immediate_branch;
    wire [63:0] ALU_input_2, result_alu;
    wire [3:0] control_alu;
    wire Zero;
    wire [63:0] read_out;
    wire [63:0] write_reg;
    wire S_addr;

    pc u0(.clk(clk), .reset(reset),
        .pc_in(addr_in),
        .pc_out(addr_out));

    instruction_mem u1(.clk(clk), .reset(reset),
        .addr(addr_out),
        .instr(instruction));

    control_unit u2(.opcode(instruction[6:0]),
        .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite), .ALUSrc(ALUSrc), .RegWrite(RegWrite));

    RegMem u3(.clk(clk), .reset(reset),
        .read_reg1(instruction[19:15]),.read_reg2(instruction[24:20]),
        .write_reg(instruction[11:7]),
        .write_data(write_reg),.reg_write_en(RegWrite),
        .read_data1(read_r1),.read_data2(read_r2));

    immediate_gen u4(.instr(instruction),.immediate_val(immediate));

    multiplexer u_ALU(.I1(read_r2), .I2(immediate),.S(ALUSrc),.mux_out(ALU_input_2));

    ALU_control u6(.ALUOp(ALUOp),
        .funct7_5(instruction[30]),
        .funct3(instruction[14:12]),
        .ALUControl(control_alu));

    alu_64_bit u7(.input1(read_r1),.input2(ALU_input_2),
        .control_signal(control_alu),
        .result(result_alu),
        .zero_flag(Zero));

    DataMem u8(.clk(clk), .reset(reset),
        .address(result_alu),
        .write_data(read_r2),
        .MemRead(MemRead), .MemWrite(MemWrite),
        .read_data(read_out));

    multiplexer u_out(.I1(result_alu), .I2(read_out),.S(MemtoReg),.mux_out(write_reg));

    sll u11(.r1(immediate),.rd(immediate_branch));

    adder_branch u12(.r1(addr_out),.r2(immediate_branch),.rd(addr_jump));

    adder_4 u13(.pc_in(addr_out),.pc_out(addr_next));

    and(S_addr, Branch, Zero);

    multiplexer u_addr(.I1(addr_next), .I2(addr_jump),.S(S_addr),.mux_out(addr_in));
endmodule