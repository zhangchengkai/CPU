`include "constant.v"

module decode(
    input clk,
    input rst,
    input rdy,

    //fetcher
    input [`DATA_WIDTH] in_fetcher_instr,
    input [`DATA_WIDTH] in_fetcher_pc,
    input in_fetcher_jump_ce,

    //communicate with register for value
    output [`REG_TAG_WIDTH] out_reg_tag1,
    input [`DATA_WIDTH] in_reg_value1,
    input [`ROB_TAG_WIDTH] in_reg_robtag1,
    input in_reg_busy1,

    output [`REG_TAG_WIDTH] out_reg_tag2,
    input [`DATA_WIDTH] in_reg_value2,
    input [`ROB_TAG_WIDTH] in_reg_robtag2,
    input in_reg_busy2,

    //update register renaming
    output reg [`REG_TAG_WIDTH] out_reg_destination,
    output [`ROB_TAG_WIDTH] out_reg_rob_tag,

    //get free rob entry tag
    input [`ROB_TAG_WIDTH] in_rob_freetag,

    //communicate with rob for commited value
    output [`ROB_TAG_WIDTH] out_rob_fetch_tag1,
    input [`DATA_WIDTH] in_rob_fetch_value1,
    input in_rob_fetch_ready1,

    output [`ROB_TAG_WIDTH] out_rob_fetch_tag2,
    input [`DATA_WIDTH] in_rob_fetch_value2,
    input in_rob_fetch_ready2,

    //enable rob to store 
    output reg [`DATA_WIDTH] out_rob_destination,
    output reg [`INSIDE_OPCODE_WIDTH] out_rob_op,
    output out_rob_jump_ce,

    //enable rs to stroe
    output reg [`ROB_TAG_WIDTH] out_rs_rob_tag,
    output reg [`INSIDE_OPCODE_WIDTH] out_rs_op,
    output reg [`DATA_WIDTH] out_rs_value1,
    output reg [`DATA_WIDTH] out_rs_value2,
    output reg [`ROB_TAG_WIDTH] out_rs_tag1,
    output reg [`ROB_TAG_WIDTH] out_rs_tag2,
    output reg [`DATA_WIDTH] out_rs_imm,
    //for rs and rob
    output [`DATA_WIDTH] out_pc,

    //enable slb to store
    output reg [`ROB_TAG_WIDTH] out_slb_rob_tag,
    output reg [`INSIDE_OPCODE_WIDTH] out_slb_op,
    output reg [`DATA_WIDTH] out_slb_value1,
    output reg [`DATA_WIDTH] out_slb_value2,
    output reg [`ROB_TAG_WIDTH] out_slb_tag1,
    output reg [`ROB_TAG_WIDTH] out_slb_tag2,
    output reg [`DATA_WIDTH] out_slb_imm
);
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] fun3;
    wire [6:0] fun7;
    parameter LUI = 7'b0110111,AUIPC = 7'b0010111,JAL = 7'b1101111,JALR = 7'b1100111,
    B_TYPE = 7'b1100011,LI_TYPE = 7'b0000011,S_TYPE = 7'b0100011,AI_TYPE = 7'b0010011,R_TYPE = 7'b0110011;

    assign opcode = in_fetcher_instr[`OPCODE_WIDTH];
    assign fun3 = in_fetcher_instr[14:12];
    assign fun7 = in_fetcher_instr[24:20];
    assign rd = in_fetcher_instr[11:7];

    //logic
    assign out_reg_tag1 = in_fetcher_instr[19:15];
    assign out_reg_tag2 = in_fetcher_instr[24:20];
    assign out_rob_fetch_tag1 = in_reg_robtag1;
    assign out_rob_fetch_tag1 = in_reg_robtag2;
    assign out_reg_rob_tag = in_rob_freetag;
    assign out_pc = in_fetcher_pc;
    assign out_rob_jump_ce = in_fetcher_jump_ce;

    wire [`DATA_WIDTH] value1;
    wire [`DATA_WIDTH] value2;
    wire [`ROB_TAG_WIDTH] tag1;
    wire [`ROB_TAG_WIDTH] tag2;
    assign value1 = (in_reg_busy1 == `FALSE) ? in_reg_value1 : 
                    (in_rob_fetch_ready1 == `TRUE) ? in_rob_fetch_value1 : 
                    `ZERO_DATA;
    assign value2 = (in_reg_busy2 == `FALSE) ? in_reg_value2 : 
                    (in_rob_fetch_ready2 == `TRUE) ? in_rob_fetch_value2 : 
                    `ZERO_DATA;
    assign tag1 = (in_reg_busy1 == `FALSE) ? `ZERO_TAG_ROB :
                  (in_rob_fetch_ready1 == `TRUE) ? `ZERO_TAG_ROB : 
                  in_reg_robtag1;
    assign tag2 = (in_reg_busy2 == `FALSE) ? `ZERO_TAG_ROB :
                  (in_rob_fetch_ready2 == `TRUE) ? `ZERO_TAG_ROB : 
                  in_reg_robtag2;
    always @(*) begin
        out_rob_destination <= `ZERO_TAG_REG;
        out_rob_op <= `NOP;
        out_rs_rob_tag <= `ZERO_TAG_ROB;
        out_rs_op <= `NOP;
        out_rs_imm <= `ZERO_DATA;
        out_slb_op <= `NOP;
        out_slb_imm <= `ZERO_DATA;
        out_slb_rob_tag <= `ZERO_TAG_ROB;
        out_reg_destination <= `ZERO_TAG_REG;
        out_rs_value1 <= `ZERO_DATA;
        out_rs_value2 <= `ZERO_DATA;
        out_rs_tag1 <= `ZERO_TAG_ROB;
        out_rs_tag2 <= `ZERO_TAG_ROB;
        out_slb_value1 <= `ZERO_DATA;
        out_slb_value2 <= `ZERO_DATA;
        out_slb_tag1 <= `ZERO_TAG_ROB;
        out_slb_tag2 <= `ZERO_TAG_ROB;

        if(rst == `FALSE && rdy == `TRUE) begin
            case (opcode)
                LUI : begin
                end
                AUIPC : begin
                end
                JAL : begin
                end
                JALR : begin
                end
                B_TYPE : begin
                end
                LI_TYPE : begin
                end
                S_TYPE : begin
                end
                AI_TYPE : begin
                end
                R_TYPE : begin
                end
            endcase
        end
    end
endmodule