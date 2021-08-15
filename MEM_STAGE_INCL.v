module MEM_STAGE_PIP_INCL(
    input clock,
    input [2:0] control_M_in,
    input zero_MEM_in,
    input [31:0] ALU_result_in,
    input [31:0] writeData_MEM_in,

    input [1:0] control_WB_EXMEM_in,
    input [4:0] rd_EXMEM_in,

    output [31:0] readData,
    output reg PC_scr_MEM_out,

    output reg [1:0] control_WB_EXMEM_out,
    output reg [31:0] ALU_result_MEM_out,
    output reg [4:0] rd_EXMEM_out
);

    always @(posedge clock)
    begin
        PC_scr_MEM_out = zero_MEM_in & control_M_in[2];
        control_WB_EXMEM_out <= control_WB_EXMEM_in;
        ALU_result_MEM_out <= ALU_result_in;
        rd_EXMEM_out <= rd_EXMEM_out;
    end

    DATA_MEM mem(clock, control_M_in[0], control_M_in[1], ALU_result_in, writeData_MEM_in,
                    readData);

endmodule

////////////////////////  DATA MEMORY  ////////////////////////
module DATA_MEM(
    input clock,
    input MemWrite,
    input MemRead,
    input [31:0] address,
    input [31:0] writeData,
    output [31:0] readData
);

    reg [31:0] dataMem[0:63];

    assign readData = dataMem[address];

    always @(posedge clock)
        if(MemWrite)
            dataMem[address] <= writeData;

endmodule


////////////////////////  TEST BENCH  ////////////////////////
`timescale 1ns/1ps

module testbench;
    reg clock;
    reg [2:0] control_M_in;
    reg zero_MEM_in;
    reg [31:0] ALU_result_in;
    reg [31:0] writeData_MEM_in;

    reg [1:0] control_WB_EXMEM_in;
    reg [4:0] rd_EXMEM_in;
    reg [31:0] PC_branch_EXMEM_in;

    wire [31:0] readData;
    wire PC_scr_MEM_out;
    
    wire [1:0] control_WB_EXMEM_out;
    wire [31:0] ALU_result_MEM_out;
    wire [4:0] rd_EXMEM_out;

    always #5 clock = (~clock);

    initial begin
        clock <= 1'b_1;
        control_M_in <= 3'b_x;
        zero_MEM_in <= 1'b_1;
        ALU_result_in <= 32'b_0;
        writeData_MEM_in <= 32'b_0;
        control_WB_EXMEM_in <= 2'b_x;
        rd_EXMEM_in <= 5'b_01;
        PC_branch_EXMEM_in <= 32'b_0;
        
        #10
        zero_MEM_in <= 1'b_1;
        ALU_result_in <= 32'b_0;
        PC_branch_EXMEM_in <= 32'b_x;
        
        #10
        zero_MEM_in <= 1'b_x;
        ALU_result_in <= 32'b_x;
        writeData_MEM_in <= 32'b_x;
        rd_EXMEM_in <= 5'h_012;
        PC_branch_EXMEM_in <= 32'h_040;
        
        #10
        rd_EXMEM_in <= 5'h_0a;
        PC_branch_EXMEM_in <= 32'h_04;
        
        #10
        $finish;
    end

    MEM_STAGE_PIP_INCL mem_stage(
        clock,
        control_M_in,
        zero_MEM_in,
        ALU_result_in,
        writeData_MEM_in,

        control_WB_EXMEM_in,
        rd_EXMEM_in,
        PC_branch_EXMEM_in,

        readData,
        PC_scr_MEM_out,
        
        control_WB_EXMEM_out,
        ALU_result_MEM_out,
        rd_EXMEM_out
    );

endmodule
