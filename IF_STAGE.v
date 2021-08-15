module IF_STAGE(
    input clock,
    input PC_src,
    input PC_write,
    input [31:0] PC_branch,

    output [31:0] PC_IF_out,
    output [31:0] instruction_IF_out
);

    wire [31:0] PC_mux_out;
    wire [31:0] PC_increased;

    PC programm_counter(clock, PC_write, PC_mux_out, PC_IF_out);

    INS_MEM instruct_memory(PC_IF_out, instruction_IF_out);

    ADDER add_PC(PC_IF_out, 32'b_0001, PC_increased);

    MUX mux_PC(PC_increased, PC_branch, PC_src, PC_mux_out);

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

////////////////////////  MUX  ////////////////////////
module MUX(
    input [31:0] inA,
    input [31:0] inB,
    input select,
    output [31:0] out
);

    assign out = (select == 1'b_1) ? inA : inB;
endmodule

////////////////////////  INSTRUCTION MEMORY  ////////////////////////
module INS_MEM(
    input [31:0] address,
    output [31:0] readData
);

    reg [31:0] insMem[0:63];

    initial $readmemh("instruction.dat", insMem);        // Read file in hexa

    assign readData = insMem[address];

endmodule


////////////////////////  PROGRAM COUNTER  ////////////////////////
module PC(
    input clock,
    input write,
    input [31:0] in,
    output reg [31:0] out
);

    initial out <= 32'b_0;

    always @(posedge clock)
    begin
        if(write == 1'b_0)          // If Write signal is not set, PC is zero
            out <= 32'b_0;
        else                        // Else, PC is the calculated PC output of Adder
            out <= in;
    end
endmodule



////////////////////////  TESTBENCH  ////////////////////////
`timescale 1ns/1ps

module testbench;
    reg clock;
    reg PC_src;
    reg PC_write;
    reg [31:0] PC_branch;
    
    wire [31:0] PC_IF_out;
    wire [31:0] instruction_IF_out;

    always #5 clock = (~clock);

    initial begin
        clock <= 1'b_1;
        PC_src <= 1'b_1;
        PC_write <= 1'b_0;
        PC_branch <= 32'b_0;
        #5
        PC_write <= 1'b_1;
        #50
        $finish;
    end

    IF_STAGE if_stage(
        clock,
        PC_src,
        PC_write,
        PC_branch,
        
        PC_IF_out,
        instruction_IF_out
    );

endmodule
