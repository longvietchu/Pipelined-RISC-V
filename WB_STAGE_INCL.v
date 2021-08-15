module WB_STAGE_PIP_INCL(
    input clock,

    input [1:0] control_WB_in,
    input [31:0] readData_WB_in,
    input [31:0] ALU_result_WB_in,

    output reg [31:0] writeData_WB_out
);

    MUX data_mux(readData_WB_in, ALU_result_WB_in, control_WB_in[0], writeData_WB_out);

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