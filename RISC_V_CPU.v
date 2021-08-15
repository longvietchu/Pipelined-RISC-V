module CPU(
    input clock,
    input writeInput,

    output reg [31:0] PC
);

    assign PC <= PC_IFtoID;

    // From IF
    wire [31:0] PC_IFtoID;
    wire [31:0] instruct_IFtoID;

    // From ID
    wire [7:0] controls_IDtoEX;
    wire [31:0] readDataA_IDtoEX;
    wire [31:0] readDataB_IDtoEX;
    wire [31:0] imm_IDtoEX;
    wire [2:0] funct3_IDtoEX;
    wire [6:0] funct7_IDtoEX;
    wire [4:0] rd_IDtoEX;
    wire [31:0] PC_IDtoEX;

    // From EX
    wire [31:0] PC_branch_EXtoIF;
    wire zero_EXtoMEM;
    wire [31:0] ALU_EXtoMEM;
    wire [1:0] ctrl_WB_EXtoMEM;      // regWrite, memToReg
    wire [2:0] ctrl_M_EXtoMEM;       // branch, memRead, memWrite
    wire [31:0] readDataB_EXtoMEM;
    wire [4:0] rd_EXtoMEM;

    // From MEM
    wire [31:0] readData_MEMtoWB;
    wire PC_scr_MEMtoIF;
    wire [1:0] ctrl_WB_MEMtoWB;      // regWrite, memToReg
    wire [31:0] ALU_MEMtoWB;
    wire [4:0] rd_MEMtoID;

    // From WB
    wire [31:0] dataWrite_WBtoID;


    IF_STAGE if_module(
        .clock (clock),                         

        .PC_src (PC_scr_MEMtoIF),               
        .PC_write (writeInput),                  // From module input
        .PC_branch (PC_branch_EXtoIF),          

        .PC_IF_out (PC_IFtoID),                 
        .instruction_IF_out (instruct_IFtoID)   
    );

    ID_STAGE_PIP_INCL id_module(
        .clock (clock),

        .PC_ID_in (PC_IFtoID),                  
        .instruction_ID_in (instruct_IFtoID),   
        .regWrite (ctrl_WB_MEMtoWB[1]),         
        .dataWrite (dataWrite_WBtoID),          
        .writeReg (rd_MEMtoID),                 

        .controls (controls_IDtoEX),            
        .readDataA_ID_out (readDataA_IDtoEX),   
        .readDataB_ID_out (readDataB_IDtoEX),   
        .imm_ID_out (imm_IDtoEX),               
        .funct3_ID_out (funct3_IDtoEX),         
        .funct7_ID_out (funct7_IDtoEX),         
        .rd_ID_out (rd_IDtoEX),                 

        .PC_IFID_out (PC_IDtoEX)                
    );

    EX_STAGE_PIP_INCL ex_module(
        .clock (clock),                         

        .controls (controls_IDtoEX),            
        .PC_EX_in (PC_IDtoEX),                  
        .imm_EX_in (imm_IDtoEX),                
        .readDataA_EX_in (readDataA_IDtoEX),    
        .readDataB_EX_in (readDataB_IDtoEX),    
        .funct3_EX_in (funct3_IDtoEX),          
        .funct7_EX_in (funct7_IDtoEX),          

        .rd_IDEX_in (rd_IDtoEX),                

        .PC_branch_EX_out (PC_branch_EXtoIF),   
        .zero_EX_out (zero_EXtoMEM),            
        .ALU_EX_out (ALU_EXtoMEM),              

        .control_WB_IDEX_out (ctrl_WB_EXtoMEM), 
        .control_M_IDEX_out (ctrl_M_EXtoMEM),   
        .readDataB_IDEX_out (readDataB_EXtoMEM),
        .rd_IDEX_out (rd_EXtoMEM)               
    );

    MEM_STAGE_PIP_INCL mem_module(
        .clock (clock),                         

        .control_M_in (ctrl_M_EXtoMEM),         
        .zero_MEM_in (zero_EXtoMEM),            
        .ALU_result_in (ALU_EXtoMEM),           
        .writeData_MEM_in (readDataB_EXtoMEM),  

        .control_WB_EXMEM_in (ctrl_WB_EXtoMEM), 
        .rd_EXMEM_in (rd_EXtoMEM),              

        .readData (readData_MEMtoWB),           
        .PC_scr_MEM_out (PC_scr_MEMtoIF),       

        .control_WB_EXMEM_out (ctrl_WB_MEMtoWB),
        .ALU_result_MEM_out (ALU_MEMtoWB),      
        .rd_EXMEM_out (rd_MEMtoID)              
    );

    WB_STAGE_PIP_INCL wb_module(
        .clock (clock),                         

        .control_WB_in (ctrl_WB_MEMtoWB),       
        .readData_WB_in (readData_MEMtoWB),     
        .ALU_result_WB_in (ALU_MEMtoWB),        

        .writeData_WB_in (dataWrite_WBtoID)     
    );

endmodule