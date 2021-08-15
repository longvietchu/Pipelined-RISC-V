module EX_STAGE_PIP_INCL(
    input clock,
    input [7:0] controls,
    input [31:0] PC_EX_in,
    input [31:0] imm_EX_in,
    input [31:0] readDataA_EX_in,
    input [31:0] readDataB_EX_in,
    input [2:0] funct3_EX_in,
    input [6:0] funct7_EX_in,

    input [4:0] rd_IDEX_in,

    output [31:0] PC_branch_EX_out,
    output zero_EX_out,
    output [31:0] ALU_EX_out,

    output reg [1:0] control_WB_IDEX_out,           // regWrite, memToReg
    output reg [2:0] control_M_IDEX_out,            // branch, memRead, memWrite
    output reg [31:0] readDataB_IDEX_out,
    output reg [4:0] rd_IDEX_out
);

    wire [3:0] ALU_ctrl;
    wire [31:0] mux_out_ALU_in;

    always @(PC_EX_in)
    begin
        control_WB_IDEX_out <= controls[7:6];
        control_M_IDEX_out <= controls[5:3];
        readDataB_IDEX_out <= readDataB_EX_in;
        rd_IDEX_out <= rd_IDEX_in;
    end

    ADDER add_pc(PC_EX_in, imm_EX_in, PC_branch_EX_out);

    MUX alu_mux(readDataB_EX_in, imm_EX_in, controls[0], mux_out_ALU_in);

    ALU_CONTROL alu_ctrl(clock, funct7_EX_in, funct3_EX_in, controls[2:1],
                            ALU_ctrl);

    ALU alu_cal(clock, readDataA_EX_in, mux_out_ALU_in, ALU_ctrl,
                            ALU_EX_out, zero_EX_out);


endmodule

////////////////////////  ADDER  ////////////////////////
module ADDER(
    input [31:0] inA,
    input [31:0] inB,
    output [31:0] out
);

    assign out = ADD(inA, inB);

    function [31:0] ADD;
        input [31:0] a;
        input [31:0] b;
        begin
            case(b[31])
                1'b_1: begin
                    b = ~b;
                    b = b + 1'b_1;
                    ADD = a - b;
                end
                default: ADD = a + b;
            endcase
        end
    endfunction
endmodule

////////////////////////  ALU  ////////////////////////
module ALU(
    input clock,
    input [31:0] input_A,
    input [31:0] input_B,
    input [3:0] ALU_control,
    output reg [31:0] ALU_result,
    output zero
);

    assign zero = (ALU_result == 1'b0) ? 1'b1 : 1'b0;
    always @(posedge clock)
        casex (ALU_control)
            4'b_0000: ALU_result <= input_A & input_B;
            4'b_0001: ALU_result <= input_A | input_B;
            4'b_0010: ALU_result <= ADD(input_A, input_B);
            4'b_0110: ALU_result <= input_A - input_B;
            default:  ALU_result <= 32'b_0;
        endcase

        function [31:0] ADD;
            input [31:0] a, b;
            begin
                casex (b[31])
                    1'b_1: begin
                        b = ~b;
                        b = b + 1'b_1;
                        ADD = a - b;
                    end
                default: ADD = a + b;
                endcase
            end
        endfunction
endmodule

////////////////////////  ALU CONTROL  ////////////////////////
module ALU_CONTROL(
    input clock,
    input [6:0] funct7,
    input [2:0] funct3,
    input [1:0] aluop,
    output reg [3:0] alucontrol
);

    // always @(aluop or funct7 or funct3)
    always @(posedge clock)
    case(aluop)                             // Since truth table contain 1X and X1, and 11 is not in used, set the
        2'b_00: alucontrol <= 4'b_0010;     // alucontrol with specific value.
        2'b_01: alucontrol <= 4'b_0110;
        2'b_10: case(funct3)
            3'b_111: alucontrol <= 4'b_0000;
            3'b_110: alucontrol <= 4'b_0001;
            3'b_000: case(funct7)
                7'b_0100000: alucontrol <= 4'b_0110;
                7'b_0000000: alucontrol <= 4'b_0010;
            endcase
            3'b_xxx: alucontrol <= 4'b_xxxx;
        endcase
        2'b_11: alucontrol <= 4'b_xxxx;
    endcase
endmodule

////////////////////////  MULTIPLEXOR  ////////////////////////
module MUX(
    input [31:0] inA,
    input [31:0] inB,
    input select,
    output [31:0] out
);

    assign out = (select == 1'b_1) ? inA : inB;
endmodule



`timescale 1ns / 1ps

module testbench;
    reg clock;
    reg [7:0] controls;
    reg [31:0] PC_EX_in;
    reg [31:0] imm_EX_in;
    reg [31:0] readDataA_EX_in;
    reg [31:0] readDataB_EX_in;
    reg [2:0] funct3_EX_in;
    reg [6:0] funct7_EX_in;
    
    reg [4:0] rd_IDEX_in;
    
    wire [31:0] PC_branch_EX_out;
    wire zero_EX_out;
    wire [31:0] ALU_EX_out;
    
    wire [1:0] control_WB_IDEX_out;
    wire [2:0] control_M_IDEX_out;
    wire [31:0] readDataB_IDEX_out;
    wire [4:0] rd_IDEX_out;
    
    always #5 clock = (~clock);
    always #10
    begin
        PC_EX_in = PC_EX_in + 32'h_01;
    end
    
    initial
    begin
        #0
        clock <= 1'b_1;
        PC_EX_in <= 32'h_00;
        controls <= 7'b_x;
        imm_EX_in <= 32'h_00;
        readDataA_EX_in <= 32'h_x;
        readDataB_EX_in <= 32'h_00;
        funct3_EX_in <= 3'h_0;
        funct7_EX_in <= 7'h_0;
        rd_IDEX_in <= 5'h_01;
        #10
        imm_EX_in <= 32'h_x;
        readDataB_EX_in <= 32'h_x;
        funct7_EX_in <= 7'h_0;
        rd_IDEX_in <= 5'h_12;
        #10
        imm_EX_in <= 32'h_003e;
        funct7_EX_in <= 7'h_01;
        rd_IDEX_in <= 5'h_0a;
        #10
        controls <= 7'h_09;
        imm_EX_in <= 32'h_01;
        funct3_EX_in <= 3'h_02;
        funct7_EX_in <= 7'h_0;
        rd_IDEX_in <= 5'h_01;
        #10
        $finish;
    end
    
    EX_STAGE_PIP_INCL ex_module(
        clock,
        controls,
        PC_EX_in,
        imm_EX_in,
        readDataA_EX_in,
        readDataB_EX_in,
        funct3_EX_in,
        funct7_EX_in,

        rd_IDEX_in,

        PC_branch_EX_out,
        zero_EX_out,
        ALU_EX_out,

        control_WB_IDEX_out,           // regWrite, memToReg
        control_M_IDEX_out,            // branch, memRead, memWrite
        readDataB_IDEX_out,
        rd_IDEX_out
);
    
endmodule