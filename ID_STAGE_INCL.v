module ID_STAGE_PIP_INCL(
    input clock,
    input [31:0] PC_ID_in,
    input [31:0] instruction_ID_in,
    input regWrite,
    input [31:0] dataWrite,
    input [4:0] writeReg,

    output [7:0] controls,
    output [31:0] readDataA_ID_out,
    output [31:0] readDataB_ID_out,
    output [31:0] imm_ID_out,
    output reg [2:0] funct3_ID_out,
    output reg [6:0] funct7_ID_out,
    output reg [4:0] rd_ID_out,

    output reg [31:0] PC_IFID_out
);

    CONTROL control_gen(
        instruction_ID_in[6:0],
        controls
    );

    IMME_GEN generator(
        instruction_ID_in,    
        imm_ID_out        
    );

    REG_FILE registers_file(
        clock,
        regWrite,
        instruction_ID_in[19:15],
        instruction_ID_in[24:20],
        writeReg,
        dataWrite,
        readDataA_ID_out,
        readDataB_ID_out
    );

    /* Pipeline Register IF/ID */
    always @(posedge clock)
    begin
        funct3_ID_out <= instruction_ID_in[14:12];
        funct7_ID_out <= instruction_ID_in[31:25];
        rd_ID_out <= instruction_ID_in[11:7];

        PC_IFID_out <= PC_ID_in;
    end

endmodule


////////////////////////  CONTROL  ////////////////////////
module CONTROL(
    input [6:0] opcode,
    output reg [7:0] control        // regWrite, memToReg, branch, memRead, memWrite, ALUop, ALUsrc
);

    always @(opcode)
        case(opcode)
            7'b_0110011: control <= 8'b_10000100;       /* R-format */
            7'b_0000011: control <= 8'b_11010001;       /* ld format */
            7'b_0100011: control <= 8'b_00001001;       /* sd format */
            7'b_1100011: control <= 8'b_00100010;       /* beq format */
            default: control <= 8'b_xxxxxxxx;           /* invalid */
        endcase
endmodule

////////////////////////  REGISTER FILES  ////////////////////////
module REG_FILE(
    input clock,
    input regWrite,
    input [4:0] readReg1,
    input [4:0] readReg2,
    input [4:0] writeReg,
    input [31:0] writeData,
    
    output [31:0] readData1,
    output [31:0] readData2
);

    reg[31:0] readData1, readData2;
    reg[31:0] RegFile[0:31];

    always @(posedge clock)
        if(regWrite == 1)
            RegFile[writeReg] <= writeData;
        
    always @(readReg1)
        readData1 <= (readReg1 != 0) ? RegFile[readReg1] : 0;
    always @(readReg2)
        readData2 <= (readReg2 != 0) ? RegFile[readReg2] : 0;
endmodule

////////////////////////  IMMEDIATE GENERATOR  ////////////////////////
module IMME_GEN(
    input clock,
    input [31:0] instruction, 
    output [31:0] out
);

    reg [31:0] imm_out;
    
    wire [6:0] opcode;
    wire [2:0] funct3;

    assign out = imm_out;
    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];

    always @(posedge clock)
        case(opcode)
            /* I-format */
            7'b_0010011: imm_out <= { {20{instruction[31]}}, instruction[31:20]};
            /* I-format load */
            7'b_0000011: imm_out <= { {20{instruction[31]}}, instruction[31:20]};
            /* S-format */
            7'b_0100011: imm_out <= { {20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            /* B-format */
            7'b_1100011: imm_out <= { {20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], {1'b_0}};
            /* U-format */
            7'b_0110111: imm_out <= {instruction[31:12], {12{1'b_0}}};
            /* J-format */
            7'b_1101111: imm_out <= { {12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:25], instruction[24:21], {1'b_0}};
            default: imm_out <= 32'b_x;
        endcase
endmodule



////////////////////////  TESTBENCH  ////////////////////////
`timescale 1ns / 1ps

module testbench;
    reg clock;
    reg [31:0] PC_in;
    reg [31:0] instruction_in;
    reg regWrite;
    reg [31:0] dataWrite;
    reg writeReg;
    
    wire [7:0] controls;
    wire [31:0] readDataA_out;
    wire [31:0] readDataB_out;
    wire [31:0] imm_out;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rd;
    
    wire [31:0] PC_PIP_out;
    wire [31:0] instruction_out;
    
    always #5 clock = (~clock);
    always #10
    begin
        PC_in = PC_in + 1;
    end
    
    initial
    begin
        #0
        clock <= 1'b_0;
        PC_in <= 1'b_0;
        instruction_in <= 32'h_00008093;
        regWrite <= 1'b_0;
        dataWrite <= 32'b_0;
        writeReg <= 1'b_0;
        #10
        instruction_in <= 32'h_0020891B;
        #10
        instruction_in <= 32'h_03E28513;
        #10
        instruction_in <= 32'h_0010A0A3;
        #10
        instruction_in <= 32'h_07618413;
        #10
        instruction_in <= 32'h_03E28513;
        #10
        instruction_in <= 32'h_0030A283;
        #5
        $finish;
    end
    
    ID_STAGE_PIP_INCL id_stage(
        clock,
        PC_in,
        instruction_in,
        regWrite,
        dataWrite,
        writeReg,

        controls,
        readDataA_out,
        readDataB_out,
        imm_out,
        funct3,
        funct7,
        rd,

        PC_PIP_out,
        instruction_out
    );
    
endmodule
